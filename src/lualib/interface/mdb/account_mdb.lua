-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local cls_mng = require 'mc.class_mgnt'
local context = require 'mc.context'
local mc_utils = require 'mc.utils'
local utils_core = require 'utils.core'
local file_utils = require 'utils.file'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local skynet_ready, skynet = pcall(require, 'skynet')
local service = require 'account.service'
local enum = require 'class.types.types'
local config = require 'common_config'
local utils = require 'infrastructure.utils'
local file_proxy = require 'infrastructure.file_proxy'
local operation_logger = require 'interface.operation_logger'
local privilege = require 'domain.privilege'

local c_object = require 'mc.orm.object'
local manager_account_db_obj = c_object('ManagerAccountDB')
local ipmi_user_info_obj = c_object('IpmiUserInfo')
local snmp_user_info_obj = c_object('SNMPUserInfo')
local history_password_obj = c_object('HistoryPassword')
local account_backup_obj = c_object('AccountBackup')


-- ORM会尝试调用create_mdb_object将模型类上库
-- 手动实现用户的各模型类create_mdb_object, 避免刷日志
function manager_account_db_obj.create_mdb_object(value)
    return value
end
function ipmi_user_info_obj.create_mdb_object(value)
    return value
end
function snmp_user_info_obj.create_mdb_object(value)
    return value
end
function history_password_obj.create_mdb_object(value)
    return value
end
function account_backup_obj.create_mdb_object(value)
    return value
end

local INTERFACE_MANAGER_ACCOUNT<const> = 'bmc.kepler.AccountService.ManagerAccount'
local INTERFACE_SNMP_USER<const> = 'bmc.kepler.AccountService.ManagerAccount.SnmpUser'

local account_mdb = class()

function account_mdb:ctor(account_service, role_collection, task_manager, file_transfer)
    self.m_account_service = account_service
    self.m_account_collection = self.m_account_service.m_account_collection
    self.m_role_collection = role_collection
    self.task_manager = task_manager
    self.file_transfer = file_transfer
    self.m_accounts = {}
    self.m_mdb_cls = cls_mng("ManagerAccount")
    self.REMOTE_PUBLIC_KEY_IMPORT_REGEX = '^((https|sftp|nfs|cifs|scp)://.{1,1000}|' ..
        config.SHM_TMP_PATH .. '/.{1,251})$'
end

function account_mdb:regist_account_signals()
    self.m_new_unregist_handle = self.m_account_collection.m_account_added:on(function(...)
        self:new_account_to_mdb_tree(...)
    end)
    self.m_delete_unregist_handle = self.m_account_collection.m_account_removed:on(function(...)
        self:delete_account_from_mdb_tree(...)
    end)
    self.m_change_unregist_handle = self.m_account_collection.m_account_changed:on(function(...)
        self:account_mdb_update(...)
    end)
    self.m_snmp_info_changed_handle = self.m_account_collection.m_snmp_info_changed:on(function(...)
        self:snmp_info_mdb_update(...)
    end)

    self.m_role_collection.m_role_privilege_changed:on(function(...)
        self.m_account_collection:update_privileges()
    end)
    self.m_role_collection.m_role_removed:on(function(...)
        self.m_account_collection:update_role_after_removed(...)
    end)
end

-- 属性监听钩子
account_mdb.watch_property_hook = {
    LoginInterface = operation_logger.proxy(function(self, ctx, account_id, value)
        ctx.operation_log.params = { interface = table.concat(value, " ") }
        local old_interface_num = self.m_account_collection:get_login_interface(account_id)
        self.m_account_collection:set_login_interface(ctx, account_id, value)
        local new_interface_num = self.m_account_collection:get_login_interface(account_id)
        local change = utils.get_login_interface_or_rule_ids_change(old_interface_num,
            new_interface_num, utils.convert_num_to_interface_str)
        if not change then
            ctx.operation_log.operation = 'SkipLog'
        end
        ctx.operation_log.params.change = change
    end, 'LoginInterface'),
    LoginRuleIds = operation_logger.proxy(function(self, ctx, account_id, value)
        self.m_account_collection:set_login_rule_ids(ctx, account_id, value)
    end, 'LoginRule'),
    RoleId = operation_logger.proxy(function(self, ctx, account_id, value)
        self.m_account_collection:set_role_id(ctx, account_id, value)
    end, 'AccountRoleId'),
    UserName = operation_logger.proxy(function(self, ctx, account_id, value)
        self.m_account_collection:set_user_name(ctx, account_id, value)
    end, 'ChangeUserName'),
    Enabled = operation_logger.proxy(function(self, ctx, account_id, value)
        self.m_account_collection:set_enabled(account_id, value)
        local account = self.m_account_collection.collection[account_id]
        ctx.operation_log.params.state = value and 'Enable' or 'Disable'
        ctx.operation_log.params.name = account.m_account_data.UserName
        ctx.operation_log.params.id = account.m_account_data.Id
    end, 'AccountEnabled'),
    PasswordChangeRequired = operation_logger.proxy(function(self, ctx, account_id, value)
        ctx.operation_log.params = { state = value and 'Need' or 'No need' }
        self.m_account_collection:set_password_change_required(account_id, value)
    end, 'PasswordChangeRequired'),
    FirstLoginPolicy = operation_logger.proxy(function(self, ctx, account_id, value)
        self.m_account_collection:set_first_login_policy(ctx, account_id, value)
    end, 'FirstLoginPolicy')
}

function account_mdb:watch_account_property(account)
    -- 防止安全风险，此处不记录字段值
    account[INTERFACE_MANAGER_ACCOUNT].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the property(%s), sender is nil', name)
            return true
        end
        
        if not self.watch_property_hook[name] then
            log:error('change the property(%s), invalid', name)
            error(base_msg.InternalError())
        end
        log:info('change the property(%s)', name)
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_property_hook[name](self, ctx, account.Id, value)
        return true
    end)
end

function account_mdb:watch_account_snmp_property(snmp)
    -- 防止安全风险，此处不记录字段值
    snmp[INTERFACE_SNMP_USER].property_before_change:on(function(name, value, sender)
        -- 因为资源树的属性都是只读的，只能在account内部进行更新，因此sender都为nil。此处不进行属性值的校验，要在RPC函数里面进行校验
        if not sender then
            log:info('change the property(%s), value is changed by account service.', name)
            return true
        end
        return true
    end)
end

function account_mdb:new_account_to_mdb_tree(user_info, snmp_info, account_update_signal, snmp_update_signal)
    -- 以""标签用户名标识用户不存在
    if user_info.UserName == nil or user_info.UserName == "" then
        return
    end

    local account = service:CreateManagerAccount(tostring(user_info.Id), function(account)
        account.AccountType = tostring(user_info.AccountType)
        account.Id = user_info.Id
        account.UserName = user_info.UserName
        account.Enabled = user_info.Enabled
        account.Locked = user_info.Locked
        account.Deletable = user_info.Deletable
        account.PasswordChangeRequired = user_info.PasswordChangeRequired
        account.PasswordExpiration = user_info.PasswordExpiration
        account.RoleId = user_info.RoleId
        account.SshPublicKeyHash = user_info.SshPublicKeyHash
        account.LastLoginTime = user_info.LastLoginTime
        account.LastLoginIP = user_info.LastLoginIP
        account.LastLoginInterface = tostring(enum.LoginInterface.new(user_info.LastLoginInterface))
        account.FirstLoginPolicy = user_info.FirstLoginPolicy:value()
        account.LoginInterface = utils.convert_num_to_interface_str(user_info.LoginInterface, true)
        account.LoginRuleIds = utils.covert_num_to_login_rule_ids_str(user_info.LoginRuleIds)
        self:watch_account_property(account)
        if snmp_info ~= nil then
            account.AuthenticationProtocol = snmp_info.AuthenticationProtocol:value()
            account.EncryptionProtocol = snmp_info.EncryptionProtocol:value()
            account.SnmpEncryptionPasswordInitialStatus = snmp_info.SnmpEncryptionPasswordInitialStatus and
                    true or false
            self:watch_account_snmp_property(account)
        end
    end)
    self.m_accounts[user_info.Id] = account

    account_update_signal:on(function(property, value)
        self.m_accounts[user_info.Id][INTERFACE_MANAGER_ACCOUNT][property] = value
    end)
    snmp_update_signal:on(function(property, value)
        self.m_accounts[user_info.Id][INTERFACE_SNMP_USER][property] = value
    end)

    log:notice('user%s(%s) has been added to mdb.', tostring(user_info.Id), type(account))
end

function account_mdb:delete_account_from_mdb_tree(account_id)
    self.m_mdb_cls:remove(self.m_accounts[account_id])
    self.m_accounts[account_id] = nil
end

function account_mdb:account_mdb_update(account_id, property, value)
    if self.m_accounts[account_id] == nil then
        return
    end
    self.m_accounts[account_id][INTERFACE_MANAGER_ACCOUNT][property] = value
end

function account_mdb:snmp_info_mdb_update(account_id, property, value)
    if self.m_accounts[account_id] == nil then
        return
    end
    self.m_accounts[account_id][INTERFACE_SNMP_USER][property] = value -- 更新资源树
end

--- 校验远程/本地配置接口权限
local function _privilege_check(ctx, account_id, collection)
    local handler, handler_id = collection:get_account_by_name(ctx.UserName)
    -- telnet/带内ipmi/自己 鉴权通过
    if  ctx.UserName == config.TELNET_USER or
        ctx.ClientAddr == config.HOST_CHAN_IP or
        handler_id == account_id then
        return true, handler_id
    end

    -- 本地用户是否具有管理员权限
    if handler and handler:get_role_id() == enum.RoleType.Administrator:value() then
        return true, handler_id
    end

    -- 通过ctx.Privilege校验是否具有管理员权限
    if ctx.Privilege and
        utils.privilege_validator(privilege:num_to_array(ctx.Privilege), enum.PrivilegeType.UserMgmt) then
        return true, handler_id
    end
    return false, handler_id
end

function account_mdb:change_password(ctx, account_id, password)
    local privilege_ok, handle_account_id = _privilege_check(ctx, account_id, self.m_account_collection)
    if not privilege_ok then
        ctx.operation_log.operation = 'ConfigureSelfAuthFailed'
        ctx.operation_log.params.operation = 'change password'
        error(base_msg.InsufficientPrivilege())
    end
    self.m_account_service:set_account_password(ctx, handle_account_id, account_id, password)
    self:password_changed_signal_emit(account_id)
end

function account_mdb:change_snmp_password(ctx, account_id, password)
    if not _privilege_check(ctx, account_id, self.m_account_collection) then
        ctx.operation_log.operation = 'ConfigureSelfAuthFailed'
        ctx.operation_log.params.operation = 'change snmp password'
        error(base_msg.InsufficientPrivilege())
    end

    self.m_account_service:set_user_snmp_pwd(ctx, account_id, password)
    self:snmp_password_changed_signal_emit(account_id)
end

function account_mdb:_import_remote_ssh_public_key(ctx, account_id, path)
    local ok, uid, gid = pcall(utils_core.get_uid_gid_by_name, ctx.UserName)
    if not ok then
        log:error("get %s uid gid failed", ctx.UserName)
        uid = config.APACHE_UID
        gid = config.APACHE_GID
    end
    -- 远程文件，先生成任务，然后执行本地导入
    local file_trans_task_id, file_path = self.file_transfer:get_file_from_url(ctx, path, true)
    if skynet_ready == false then
        log:error("skynet is not ready, skip ssh import async task!")
        error(base_msg.InternalError())
    end
    local task_id = self.task_manager:create_ssh_import_task(account_id)
    skynet.fork_once(function ()
        local ok, err_msg = self.file_transfer:is_file_transfer_completed(file_trans_task_id)
        if ok then
            ok, err_msg = pcall(function (...)
                file_proxy.proxy_move(file_path, config.SSH_PUBLIC_KEY_PARSE_PATH, uid, gid)
                self.m_account_collection:import_ssh_public_key(ctx, account_id, config.SSH_PUBLIC_KEY_PARSE_PATH)
            end)
        end
        if not ok then
            log:error('file trans failed, skip import ssh public key!, %s', err_msg)
            self.task_manager:update_ssh_import_task(false, err_msg)
            return
        end
        self.task_manager:update_ssh_import_task(true, nil)
    end)
    return task_id
end

local function parse_content_with_type(user_name, type, content)
    local ok, uid, gid = pcall(utils_core.get_uid_gid_by_name, user_name)
    if not ok then
        log:error("get %s uid gid failed", user_name)
        uid = config.APACHE_UID
        gid = config.APACHE_GID
    end

    -- 若是URI类型则校验文件格式
    if type == "URI" then
        -- 本地文件路径场景，若非/tmp目录下，直接抛出失败，不能删除文件
        if string.sub(content, 1, 1) == '/' and
            file_utils.check_realpath_before_open_s(content, config.TMP_PATH) ~= 0 then
            log:error("invalid local file path")
            error(base_msg.PropertyValueFormatError('******', 'Content'))
        end

        -- 走到这里的只会是本地/tmp路径或者远程路径
        if string.sub(content, -4) ~= '.pub' or (string.sub(content, 1, 1) ~= '/' and #content > 1000) then
            -- 仅判断为文件时才删除
            if utils_core.is_file(content) then
                mc_utils.remove_file(content)
            end
            error(base_msg.PropertyValueFormatError('******', 'Content'))
        end
        -- 本地导入直接使用内部路径
        if string.sub(content, 1, 1) == '/' then
            file_proxy.proxy_move(content, config.SSH_PUBLIC_KEY_PARSE_PATH, uid, gid)
            content = config.SSH_PUBLIC_KEY_PARSE_PATH
        end

        return content
    end

    -- text类型先在本地生成文件
    file_proxy.proxy_delete(config.SSH_PUBLIC_KEY_PARSE_PATH)
    local ret = file_utils.check_realpath_before_open_s(config.SSH_PUBLIC_KEY_PARSE_PATH, config.SHM_TMP_PATH)
    if ret ~= 0 then
        log:error('the file path is invalid.')
        error(base_msg.PropertyValueFormatError('******', 'Content'))
    end

    local file = file_utils.open_s(config.SSH_PUBLIC_KEY_PARSE_PATH, 'w+b')
    if not file then
        log:error('open the file failed.')
        error(custom_msg.PublicKeyImportFailed())
    end

    file:write(content)
    file:close()

    file_proxy.proxy_delete(config.SSH_PUBLIC_KEY_TEMP_FILE)
    file_proxy.proxy_chown(config.SSH_PUBLIC_KEY_PARSE_PATH, uid, gid)
    return config.SSH_PUBLIC_KEY_PARSE_PATH
end

function account_mdb:import_ssh_public_key(ctx, account_id, type, content)
    -- 针对文本内容先转移到本地
    local path = parse_content_with_type(ctx.UserName, type, content)

    if not _privilege_check(ctx, account_id, self.m_account_collection) then
        ctx.operation_log.operation = 'ConfigureSelfAuthFailed'
        ctx.operation_log.params.operation = 'import ssh public key'
        mc_utils.remove_file(path)
        error(base_msg.InsufficientPrivilege())
    end

    local username = self.m_account_collection:get_account_by_account_id(account_id):get_user_name()
    ctx.operation_log.params = { name = username, id = account_id }
    -- 这个时候的path只会有远程路径或者内部路径
    if utils_core.g_regex_match(self.REMOTE_PUBLIC_KEY_IMPORT_REGEX, path) ~= true or
        #string.match(path, '[^/]+$') and #string.match(path, '[^/]+$') >= config.MAX_FILEPATH_LENGTH then
        log:error('import ssh public key failed, content format error.')
        error(base_msg.PropertyValueFormatError('******', 'Content'))
    end
    if string.sub(path, 1, 1) ~= '/' then
        return self:_import_remote_ssh_public_key(ctx, account_id, path)
    end
    -- 本地路径执行导入
    self.m_account_collection:import_ssh_public_key(ctx, account_id, path)
    -- 本地任务返回taskid为0
    return 0
end

function account_mdb:delete_ssh_public_key(ctx, account_id)
    if not _privilege_check(ctx, account_id, self.m_account_collection) then
        ctx.operation_log.operation = 'ConfigureSelfAuthFailed'
        ctx.operation_log.params.operation = 'delete ssh public key'
        error(base_msg.InsufficientPrivilege())
    end

    local username = self.m_account_collection:get_account_by_account_id(account_id):get_user_name()
    ctx.operation_log.params = { name = username, id = account_id }
    self.m_account_collection:delete_ssh_public_key(ctx, account_id)
end

function account_mdb:set_authentication_protocol(ctx, account_id, protocol, auth_password, encry_password)
    if not _privilege_check(ctx, account_id, self.m_account_collection) then
        ctx.operation_log.operation = 'ConfigureSelfAuthFailed'
        ctx.operation_log.params.operation = 'set authentication protocol'
        error(base_msg.InsufficientPrivilege())
    end

    protocol = enum.SNMPAuthenticationProtocols.new(protocol)
    self.m_account_service:set_user_auth_protocol(ctx, handle_account_id, account_id,
        protocol, auth_password, encry_password)
    self:password_changed_signal_emit(account_id)
end

function account_mdb:set_encryption_protocol(ctx, account_id, protocol)
    if not _privilege_check(ctx, account_id, self.m_account_collection) then
        ctx.operation_log.operation = 'ConfigureSelfAuthFailed'
        ctx.operation_log.params.operation = 'set encryption protocol'
        error(base_msg.InsufficientPrivilege())
    end

    protocol = enum.SNMPEncryptionProtocols.new(protocol)
    self.m_account_service:set_user_encrypt_protocol(ctx, account_id, protocol)
end

function account_mdb:check_login_rule(ip, username)
    local RO_COMMUNITY_ID<const> = 20
    local account_id
    if username == '<snmp_community>' then
        account_id = RO_COMMUNITY_ID
    else
        local account = self.m_account_service:get_account_data_by_name(username)
        account_id = account.Id
    end
    if not self.m_account_collection:check_login_rule(account_id, ip) then
        error(custom_msg.AuthorizationFailed())
    end
end

function account_mdb:password_changed_signal_emit(account_id)
    --- 传递给下游的方法需要去掉operationLog，否则在触发信号时会报错
    local temp_ctx = mc_utils.table_copy(context.get_context())
    temp_ctx.operation_log = nil
    context.with_context(temp_ctx, function()
        service:ManagerAccountsManagerAccountsPasswordChangedSignal(account_id)
    end)
end

function account_mdb:snmp_password_changed_signal_emit(account_id)
    --- 传递给下游的方法需要去掉operationLog，否则在触发信号时会报错
    local temp_ctx = mc_utils.table_copy(context.get_context())
    temp_ctx.operation_log = nil
    context.with_context(temp_ctx, function()
        service:ManagerAccountsManagerAccountsSnmpPasswordChangedSignal(account_id)
    end)
end

return singleton(account_mdb)
