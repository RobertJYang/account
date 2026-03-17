-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local skynet     = require 'skynet'
local class      = require 'mc.class'
local singleton  = require 'mc.singleton'
local log        = require 'mc.logging'
local mc_utils   = require 'mc.utils'
local signal     = require 'mc.signal'
local vos        = require 'utils.vos'
local utils_file = require 'utils.file'
local utils_core = require 'utils.core'
local config     = require 'user_config'
local ip_lock    = require 'ip_lock'

local AccessService = class()

-- 通过open的形式创建配置文件
local function create_access_file()
    local mode = mc_utils.S_IRUSR| mc_utils.S_IWUSR | mc_utils.S_IRGRP| mc_utils.S_IROTH
    -- 创建目录
    utils_core.mkdir_with_parents(config.IAM_SHM_PATH, mode)
    -- 创建文件
    local file = utils_file.open_s(config.ACCESS_CONFIG_FILE, "w+")
    if not file then
        log:error("create file failed")
        return
    end
    file:close()
    utils_core.chmod_s(config.ACCESS_CONFIG_FILE, mode)
end

local function write_access_config(_, inter_chassis_config)
    local total_config = ""

    if inter_chassis_config then
        total_config = total_config .. "\n" .. inter_chassis_config
    end

    local config_file = utils_file.open_s(config.ACCESS_CONFIG_FILE, "w+")
    mc_utils.close(config_file, pcall(config_file.write, config_file, total_config))
end

function AccessService:ctor(authentication, certificate_authentication)
    self.m_auth_service = authentication
    self.cert_auth_service = certificate_authentication
    self.m_ip_records = {}
end

function AccessService:init()
    if not vos.get_file_accessible(config.ACCESS_CONFIG_FILE) then
        create_access_file()
    end
    if not vos.get_file_accessible(config.IP_LOCK_PATH) then
        mc_utils.mkdir(config.IP_LOCK_PATH,
            mc_utils.S_IRWXU | mc_utils.S_IRGRP | mc_utils.S_IXGRP | mc_utils.S_IROTH | mc_utils.S_IXOTH)
        utils_core.chown_s(config.IP_LOCK_PATH, config.SECBOX_USER_UID, config.SNMPD_USER_GID)
    end

    self.m_auth_service.m_lock_threshold_changed:on(function()
        self:clean_ip_lock_status()
    end)

    self:ip_access_monitor()

    self.m_ip_locked_sig = signal.new()
end

function AccessService:clean_ip_lock_status()
    local res = ip_lock.clean_all_ip_fail_record(config.IP_LOCK_PATH)
    if res ~= 0 then
        log:error("clean ip fail lock record failed")
    end
end

function AccessService:check_ip_locked(ip)
    local duration, threshold, fail_interval = self.m_auth_service.m_auth_config:get_auth_lock_config()
    return ip_lock.get_one_ip_lock_status(config.IP_LOCK_PATH, ip, threshold, fail_interval, duration)
end

function AccessService:ip_access_monitor()
    local ip_lock_config
    local inter_chassis_config
    skynet.fork_loop({ count = 0}, function()
        log:notice("start ip access monitor")
        while true do
            -- 采集ip锁定限制
            ip_lock_config = self:get_ip_lock_access()

            -- 采集框内通信限制
            inter_chassis_config = self:get_inter_chassis_access()

            -- 写配置文件
            write_access_config(ip_lock_config, inter_chassis_config)

            -- 延时后置，确保起来能先刷新
            skynet.sleep(300)
        end
    end)
end

local function check_lock_changed(last_status, cur_status)
    if not last_status and cur_status then
        return 'locked'
    elseif last_status and not cur_status then
        return 'unlocked'
    end
    return nil
end

local function collect_ip_lock_access(records)
    local context = "# limit config from ip lock" .. '\n'
    for ip, record in pairs(records) do
        if record.lock_status then
            context = context .. "-:ALL:" .. ip .. "\n"
        end
    end
    return context
end

local state_changed_cb = {
    ['locked'] = function(self, ip)
        log:security("Ip (%s) locked", ip)
        self.m_ip_locked_sig:emit(ip)
    end,
    ['unlocked'] = function(self, ip)
        log:security("Ip (%s) unlocked", ip)
    end
}

function AccessService:get_ip_lock_access()
    -- duration 锁定时长，threshold 锁定次数，时间窗口 fail_interval
    local duration, threshold, fail_interval = self.m_auth_service.m_auth_config:get_auth_lock_config()
    local _, records = ip_lock.get_all_ip_lock_status(config.IP_LOCK_PATH, threshold, fail_interval, duration)
    local now = os.time()

    for _, record in pairs(records) do
        -- 文件系统有，内存中无，直接覆盖
        if not self.m_ip_records[record.ip] then
            self.m_ip_records[record.ip] = {
                ['lock_start_time']  = record.lock_start_time,
                ['last_lock_status'] = false,
                ['lock_status']      = record.lock_status,
                ['is_flush']         = true
            }
        else
            self.m_ip_records[record.ip].lock_start_time  = record.lock_start_time
            self.m_ip_records[record.ip].is_flush         = true
            self.m_ip_records[record.ip].last_lock_status = self.m_ip_records[record.ip].lock_status
            self.m_ip_records[record.ip].lock_status      = record.lock_status
        end
    end

    local check_time_interval
    local changed
    -- 到此时，内存中时已经完成整合后的最新结果
    for ip, _ in pairs(self.m_ip_records) do
        -- 未刷新的场景，说明内存有，文件系统没有，此时内存直接清理
        -- 如果内存中是锁定状态，记录解锁日志
        if not self.m_ip_records[ip].is_flush then
            if self.m_ip_records[ip].lock_status then
                log:security("Ip (%s) unlocked", ip)
            end
            self.m_ip_records[ip] = nil
            ip_lock.clean_ip_fail_record(config.IP_LOCK_PATH, ip)
            goto continue
        end

        -- 场景1：未锁定，使用 fail_interval 判断，已经过了时间范围就清理记录
        -- 场景2：已锁定，使用 duration 判断，已经过了锁定时长就清理记录并解锁
        check_time_interval = self.m_ip_records[ip].lock_status and duration or fail_interval
        if self.m_ip_records[ip].lock_start_time + check_time_interval < now then
            if self.m_ip_records[ip].last_lock_status then
                log:security("Ip (%s) unlocked", ip)
            end
            ip_lock.clean_ip_fail_record(config.IP_LOCK_PATH, ip)
            self.m_ip_records[ip] = nil
            goto continue
        end

        -- 还保留着记录的项将刷新标志置false，用于下一次轮询
        self.m_ip_records[ip].is_flush = false
        -- 判断锁定变化
        changed = check_lock_changed(self.m_ip_records[ip].last_lock_status, self.m_ip_records[ip].lock_status)
        if state_changed_cb[changed] then
            state_changed_cb[changed](self, ip)
        end
        if changed == 'unlocked' then
            ip_lock.clean_ip_fail_record(config.IP_LOCK_PATH, ip)
        end
        ::continue::
    end

    return collect_ip_lock_access(self.m_ip_records)
end

function AccessService:get_inter_chassis_access()
    return self.cert_auth_service:get_ip_access_config()
end

return singleton(AccessService)