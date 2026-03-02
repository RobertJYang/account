-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local signal = require 'mc.signal'
local log = require 'mc.logging'
local file_utils = require 'utils.file'
local base_msg = require 'messages.base'
local account_core = require 'account_core'
local login_rule_manager = require 'domain.login_rule.login_rule_manager'
local user_config = require 'common_config'
local file_proxy = require 'infrastructure.file_proxy'

local LoginRuleCollection = class()

function LoginRuleCollection:ctor(bus, db)
    local rule_db = db:select(db.LoginRule)
    local login_rule_collection = rule_db:fold(function(login_rule, acc)
        acc[login_rule.RuleId] = login_rule_manager.new(bus, login_rule)
        return acc
    end, {})

    self.m_table_login_rule = rule_db.table
    self.m_login_rule_collection = login_rule_collection
    self.m_login_rule_create = signal.new()
    self.m_login_rule_update = signal.new()
    self.file_path = account_core.format_realpath(user_config.LOGINRULE_FILE)
    self.tmp_file_path = account_core.format_realpath(user_config.TMP_LOGINRULE_FILE)
end

function LoginRuleCollection:init()
    -- 初始化时生成 /dev/shm/loginrules 文件
    local init_content = self:get_lines()
    local init_file, err = file_utils.open_s(self.file_path, 'w+')
    if not init_file then
        err = err:gsub(self.file_path, '') -- 过滤文件路径不要打印到日志中
        log:error(string.format('Open file loginrules error: %s', err))
        error(base_msg.InternalError())
    end
    init_file:write(init_content)
    init_file:close()
end

--- 初始化资源树
function LoginRuleCollection:init_login_rule_signal()
    -- 第一次升级需要初始化数据库和资源树
    if #self.m_login_rule_collection == 0 then
        for id = 1, 3 do -- 3个登录规则
            local login_rule_in_db = self.m_table_login_rule({
                RuleId = id, Enabled = false, IpRule = '', MacRule = '', TimeRule = '', Ipv6Rule = ''
            })
            local login_rule_in_manager = login_rule_manager.new(login_rule_in_db)
            self.m_login_rule_collection[id] = login_rule_in_manager
            self.m_login_rule_create:emit(login_rule_in_manager:get_login_rule())
        end
        return
    end

    for _, rule in pairs(self.m_login_rule_collection) do
        self.m_login_rule_create:emit(rule:get_login_rule())
    end
end

--- 设置规则X使能状态
---@param rule_id number
---@param enable boolean
function LoginRuleCollection:set_enable(rule_id, enable)
    self.m_login_rule_collection[rule_id]:set_enabled(enable)
    self:flush_loginrules_file()
end

function LoginRuleCollection:get_enabled(rule_id)
    return self.m_login_rule_collection[rule_id]:get_enabled()
end

--- 设置规则X的IP规则
---@param rule_id number
---@param ip_rule string
function LoginRuleCollection:set_ip_rule(rule_id, ip_rule)
    self.m_login_rule_collection[rule_id]:set_ip_rule(ip_rule)
    self:flush_loginrules_file()
end

function LoginRuleCollection:get_ip_rule(rule_id)
    return self.m_login_rule_collection[rule_id]:get_ip_rule()
end

--- 设置规则X的MAC规则
---@param rule_id number
---@param mac_rule string
function LoginRuleCollection:set_mac_rule(rule_id, mac_rule)
    self.m_login_rule_collection[rule_id]:set_mac_rule(mac_rule)
    self:flush_loginrules_file()
end

function LoginRuleCollection:get_mac_rule(rule_id)
    return self.m_login_rule_collection[rule_id]:get_mac_rule()
end

--- 设置规则X的TIME规则
---@param rule_id number
---@param time_rule string
function LoginRuleCollection:set_time_rule(rule_id, time_rule)
    self.m_login_rule_collection[rule_id]:set_time_rule(time_rule)
    self:flush_loginrules_file()
end

function LoginRuleCollection:get_time_rule(rule_id)
    return self.m_login_rule_collection[rule_id]:get_time_rule()
end

--- 根据login_rule_ids依次校验规则X
---@param login_rule_ids number
---@param ip string
function LoginRuleCollection:check_login_rule(login_rule_ids, ip)
    local ids = login_rule_ids and login_rule_ids or 0

    local rule
    local skip_num = 0
    for i = 1, user_config.LOGIN_RULE_COUNT do -- 最多使能3个登录规则
        -- 选择遍历该账户已配置的登陆规则
        if (ids >> (i - 1)) & 1 == 1 then
            rule = self.m_login_rule_collection[i]
            -- 若未使能，则跳过
            if not rule:get_enabled() then
                skip_num = skip_num + 1
                goto continue
            end
            -- 若单个规则已使能校验通过，直接通过
            if rule:check_login_rule(ip) then
                return true
            end
        else
            -- 对于未配置到用户的规则，直接跳过
            skip_num = skip_num + 1
        end
        ::continue::
    end

    -- 走到此处的场景：
    -- 1、全部登录规则未使能or未配置，被跳过了，对应 skip_num == user_config.LOGIN_RULE_COUNT
    -- 2、存在已使能且配置的规则，没有校验成功的，对应其他场景下的false
    return skip_num == user_config.LOGIN_RULE_COUNT and true or false
end

--- 根据数据库数据生成写入文件的content
function LoginRuleCollection:get_lines()
    local lines = {}
    for _, rule in pairs(self.m_login_rule_collection) do
        lines[#lines+1] = rule:data_to_line()
    end
    return table.concat(lines, '\n')
end

--- 基于数据库数据刷新 loginrules 文件
function LoginRuleCollection:flush_loginrules_file()
    local new_content = self:get_lines()

    -- 获取旧内容
    local cur_file, err = file_utils.open_s(self.file_path, 'r')
    if not cur_file then
        err = err:gsub(self.file_path, '') -- 过滤文件路径不要打印到日志中
        log:error(string.format('Open file loginrules error: %s', err))
        error(base_msg.InternalError())
    end
    local old_content = cur_file:read('*a')
    cur_file:close()

    -- 比对内容是否变更
    if old_content == new_content then
        return
    end

    -- 若无变更继续执行后续动作
    local tmp_file, tmp_err = file_utils.open_s(self.tmp_file_path, 'w+')
    if not tmp_file then
        tmp_err = tmp_err:gsub(self.tmp_file_path, '') -- 过滤文件路径不要打印到日志中
        log:error(string.format('Open file loginrules error: %s', tmp_err))
        error(base_msg.InternalError())
    end
    tmp_file:write(new_content)
    tmp_file:close()

    -- 执行替换动作
    file_proxy.proxy_move(self.tmp_file_path, self.file_path, user_config.SECBOX_USER_UID, user_config.SECBOX_USER_GID)
end

return singleton(LoginRuleCollection)
