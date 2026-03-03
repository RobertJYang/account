-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local class = require 'mc.class'
local enum = require 'class.types.types'
local config = require 'common_config'
local role_privilege_map = require 'models.role_privilege_map'
local account_linux = require 'infrastructure.account_linux'
local mc_utils = require 'mc.utils'
local file_utils = require 'utils.file'
local vos_utils = require 'utils.vos'
local utils_core = require 'utils.core'
local file_proxy = require 'infrastructure.file_proxy'
local trace = require 'telemetry.trace'

-- 文件同步管理，将passwd/shadow/group/ipmi几个文件的同步和刷新机制放在此处处理
local file_synchronization = class()
function file_synchronization:ctor(db, account_collection, account_linux_file_path, skynet_queue)
    self.db = db
    self.passwd_path = account_linux_file_path['passwd'] or config.PASSWD_FILE
    self.shadow_path = account_linux_file_path['shadow'] or config.SHADOW_FILE
    self.group_path = account_linux_file_path['group'] or config.GROUP_FILE
    self.ipmi_path = account_linux_file_path['ipmi'] or config.IPMI_FILE
    self.linux_files = {
        passwd_path = self.passwd_path,
        shadow_path = self.shadow_path,
        group_path = self.group_path,
        ipmi_path = self.ipmi_path
    }
    self.m_account_collection = account_collection
    self.m_linux_account_queue = skynet_queue
end

function file_synchronization:init()
    self:regist_file_sync_signals()
    self:init_tally_log()
    self:set_file_owner()
end

function file_synchronization:init_tally_log()
    file_proxy.proxy_mkdir(config.PAM_TALLY_LOG_DIR, mc_utils.S_IRWXU | mc_utils.S_IRWXG, config.SECBOX_USER_UID, config.APPS_USER_GID)
    file_proxy.proxy_chmod(config.PAM_TALLY_LOG_DIR, mc_utils.S_IRWXU | mc_utils.S_IRWXG)
    file_proxy.proxy_chown(config.PAM_TALLY_LOG_DIR, config.SECBOX_USER_UID, config.APPS_USER_GID)
end

function file_synchronization:regist_file_sync_signals()
    self.m_account_collection.m_account_file_added:on(function(...)
        self.m_linux_account_queue(self.add_user, self, ...)
    end)
    self.m_account_collection.m_account_file_removed:on(function(...)
        self.m_linux_account_queue(self.remove_user, self, ...)
    end)
    self.m_account_collection.m_account_file_flush:on(function(...)
        self.m_linux_account_queue(self.flush_account, self, ...)
    end)
    self.m_account_collection.m_account_file_changed:on(function(...)
        self.m_linux_account_queue(self.update_user, self, ...)
    end)
    self.m_account_collection.m_account_ipmi_changed:on(function(...)
        self.m_linux_account_queue(self.flush_ipmi, self, ...)
    end)
end

function file_synchronization:get_account_file_line(account_id, is_change_user, old_username)
    local account = self.m_account_collection.collection[account_id]
    local account_line = {
        user_name = account:get_user_name() == config.ACTUAL_ROOT_USER_NAME and
            config.RESERVED_ROOT_USER_NAME or account:get_user_name(),
        password = account:get_account_password(),
        id = account_id,
        role = account:get_role_id(),
        is_local_user = account:get_account_type():value() == enum.AccountType.Local:value() or
            account:get_account_type():value() == enum.AccountType.OEM:value() or
            account:get_account_type():value() == enum.AccountType.InterChassis:value(),
        user_enabled = account:get_enabled() and 1 or 0,
        privilege_num = role_privilege_map.role_to_privilege_map[account:get_role_id()],
        is_locked = account:get_locked() and 1 or 0,
        login_rule_ids_num = account:get_login_rule_ids(),
        login_interface_num = account:get_login_interface(),
        is_exclude_user = self.m_account_collection:check_is_emergency_user(account_id) and 1 or 0,
        is_password_expired = account:get_password_valid_time() == 0 and 1 or 0,
        is_change_user = is_change_user,
        old_username = old_username
    }
    return account_line
end

function file_synchronization:set_file_owner()
    local la = account_linux.new(self.linux_files, true, true)
    if file_proxy.proxy_access(config.PRESERVE_CONFIG_FILE, 0) then
        -- 修改文件属主权限确保能解压访问
        file_proxy.proxy_chown(config.PRESERVE_CONFIG_FILE, config.SECBOX_USER_UID, config.SECBOX_USER_GID)
        file_proxy.proxy_chmod(config.PRESERVE_CONFIG_FILE, mc_utils.S_IRUSR | mc_utils.S_IWUSR)
        -- 解压目录
        mc_utils.secure_tar_unzip(config.PRESERVE_CONFIG_FILE, config.SHM_PATH,
            config.FILE_MAX_SIZE, config.FILE_MAX_NUM)
        -- 删除原目录残留
        file_proxy.proxy_delete(config.DATA_HOME_PATH)
        -- 将解压后的目录移动到目标目录并赋权
        file_proxy.proxy_move(config.SHM_PATH .. '/home', config.PRESERVE_CONFIG_PATH,
            config.ROOT_USER_UID, config.ROOT_USER_GID)
        file_proxy.proxy_chmod(config.DATA_HOME_PATH,
            mc_utils.S_IRWXU | mc_utils.S_IRGRP | mc_utils.S_IXGRP | mc_utils.S_IROTH | mc_utils.S_IXOTH)
        -- 删除残留压缩包
        file_proxy.proxy_delete(config.PRESERVE_CONFIG_FILE)
    end
    for _, file_name in pairs(utils_core.dir(config.DATA_HOME_PATH)) do
        local ok, uid, gid = pcall(function()
            return self.m_account_collection:get_uid_gid_by_username(self.ctx, file_name)
        end)
        if not ok then
            log:error('file (%s) is not username file', file_name)
            goto continue
        end

        la:recover_file_owner(config.DATA_HOME_PATH, file_name, uid, gid)
        ::continue::
    end
end

function file_synchronization:add_user(account_id)
    local la = account_linux.new(self.linux_files, true)
    local cur_account = self:get_account_file_line(account_id, false)
    la:add_user(cur_account)
end

function file_synchronization:remove_user(account_id)
    local account = self.m_account_collection.collection[account_id]
    local user_name = account:get_user_name() == config.ACTUAL_ROOT_USER_NAME and
        config.RESERVED_ROOT_USER_NAME or account:get_user_name()
    local la = account_linux.new(self.linux_files, true)
    la:remove_user(user_name, account:get_role_id(), false)
end

function file_synchronization:update_user(account_id, old_username)
    local la = account_linux.new(self.linux_files, true)

    local cur_account

    -- 判断是否变更用户
    if old_username and old_username ~= '' then
        cur_account = self:get_account_file_line(account_id, true, old_username)
        la:remove_user(old_username, cur_account.role, true)
    else
        cur_account = self:get_account_file_line(account_id, false)
    end
    la:update_user(cur_account)
end

function file_synchronization:flush_ipmi(account_id)
    local account = self.m_account_collection.collection[account_id]
    local is_exclude_user = self.m_account_collection:check_is_emergency_user(account_id) and 1 or 0
    local user_name = account:get_user_name() == config.ACTUAL_ROOT_USER_NAME and
        config.RESERVED_ROOT_USER_NAME or account:get_user_name()
    local la = account_linux.new(self.linux_files, true)

    la:flush_ipmi_user_cfg(
        user_name,
        account_id,
        account:get_enabled() and 1 or 0,
        role_privilege_map.role_to_privilege_map[account.m_account_data.RoleId],
        account:get_locked() and 1 or 0,
        account:get_login_rule_ids(),
        account:get_login_interface(),
        is_exclude_user,
        account:get_password_valid_time() == 0 and 1 or 0
    )
end

-- 每次刷新时清理异常数据
local function clean_abnormal_data(la, user_map)
    -- passwd文件中有，但数据库中无的，删除（shadow和group文件由passwd文件驱动，不独立处理）
    for _, user in pairs(la.passwd_file.datas) do
        if user.user_id > config.LINUX_USER_ID_BASE and user.user_id < config.LINUX_USER_ID_MAX then
            if user_map[user.user_name] ~= true then
                la:remove_user(user.user_name, nil, false)
            end
        end
    end

    -- ipmi文件中有，但数据库中无的，删除
    for _, user in pairs(la.ipmi_file.datas) do
        if user_map[user.user_name] ~= true then
            la:remove_user(user.user_name, nil, false)
        end
    end
end

function file_synchronization:flush_account()
    local span = trace.start_span('account.file_synchronization.flush_account', {}, {kind = "Server"})
    local user_map = {}
    local la = account_linux.new(self.linux_files, false, true)
    la:ensure_system_base_user_exists()
    local account_type, cur_account
    for _, account in pairs(self.m_account_collection.collection) do
        account_type = account.m_account_data.AccountType:value()
        if not self.m_account_collection.operation_type_check.LOCAL_OEM_INTERCHASSIS[account_type] then
            goto continue
        end
        cur_account = self:get_account_file_line(account.m_account_data.Id, false)
        user_map[cur_account.user_name] = true
        la:update_user(cur_account)
        ::continue::
    end

    clean_abnormal_data(la, user_map)
    -- 手动写文件
    la:save(true)
    span:finish()
end

-- 账号监控，保证账号被同步到linux系统
function file_synchronization:account_monitor()
    local skynet = require 'skynet'
    skynet.fork_loop({ count = 0 }, function()
        log:info('Start account monitor.')
        while true do
            -- 等待5秒钟，保证account启动后，尽快同步
            skynet.sleep(500)
            self.m_linux_account_queue(self.flush_account, self)
            -- 等待55秒钟
            skynet.sleep(5500)
        end
    end)
end

return singleton(file_synchronization)
