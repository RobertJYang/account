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
local log = require 'mc.logging'
local cls_mng = require 'mc.class_mgnt'
local context = require 'mc.context'
local mc_utils = require 'mc.utils'
local utils_core = require 'utils.core'
local file_utils = require 'utils.file'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local skynet_ready, skynet = pcall(require, 'skynet')
local config = require 'common_config'
local operation_logger = require 'interface.operation_logger'

local INTERFACE_ACCOUNT_SERVICE = 'bmc.kepler.AccountService'

local account_service_mdb = class()

function account_service_mdb:ctor(account_service, task_manager, file_transfer)
    self.m_account_service = account_service
    self.m_account_config = self.m_account_service.m_account_config
    self.file_transfer = file_transfer
    self.task_manager = task_manager
    self.REMOTE_WEAKPWD_DICT_IMPORT_REGEX = '^((https|sftp|nfs|cifs|scp)://.{1,1000}|' ..
        config.TMP_PATH .. '/.{1,251})$'
end

function account_service_mdb:regist_account_signals()
    self.m_new_unregist_handle = self.m_account_service.m_config_added:on(function(...)
        self:new_config_to_mdb_tree(...)
    end)
    self.m_change_unregist_handle = self.m_account_service.m_config_changed:on(function(...)
        self:config_mdb_update(...)
    end)
    self.m_config_change_unregist_handle = self.m_account_config.m_account_service_config_changed:on(function(...)
        self:config_mdb_update(...)
    end)
end

function account_service_mdb:init()
    local config_mdb = {}
    local global_config = self.m_account_config
    config_mdb.MaxPasswordLength = global_config.m_db_account_service.MaxPasswordLength
    config_mdb.MinPasswordLength = global_config.m_db_account_service.MinPasswordLength
    config_mdb.PasswordComplexityEnable = global_config.m_db_account_service.PasswordComplexityEnable
    config_mdb.InitialPasswordPromptEnable = global_config.m_db_account_service.InitialPasswordPromptEnable
    config_mdb.InitialPasswordNeedModify = global_config.m_db_account_service.InitialPasswordNeedModify
    config_mdb.InitialAccountPrivilegeRestrictEnabled =
        global_config.m_db_account_service.InitialAccountPrivilegeRestrictEnabled
    config_mdb.MaxPasswordValidDays = global_config.m_db_account_service.MaxPasswordValidDays
    config_mdb.MinPasswordValidDays = global_config.m_db_account_service.MinPasswordValidDays
    config_mdb.EmergencyLoginAccountId = global_config.m_db_account_service.EmergencyLoginAccountId
    config_mdb.InactiveDaysThreshold = global_config.m_db_account_service.InactiveDaysThreshold
    config_mdb.WeakPasswordDictionaryEnabled = global_config.m_db_account_service.WeakPasswordDictionaryEnabled
    config_mdb.SNMPv3TrapAccountId = global_config.m_db_account_service.SNMPv3TrapAccountId
    config_mdb.HistoryPasswordCount = global_config.m_db_account_service.HistoryPasswordCount
    config_mdb.MaxHistoryPasswordCount = global_config.m_db_account_service.MaxHistoryPasswordCount
    config_mdb.SNMPv3TrapAccountLimitPolicy = global_config.m_db_account_service.SNMPv3TrapAccountLimitPolicy
    config_mdb.HostUserManagementEnabled = global_config.m_db_account_service.HostUserManagementEnabled
    config_mdb.OSAdministratorPrivilegeEnabled = global_config.m_db_account_service.OSAdministratorPrivilegeEnabled
    config_mdb.UserNamePasswordPrefixCompareEnabled =
        global_config.m_db_account_service.UserNamePasswordPrefixCompareEnabled
    config_mdb.UserNamePasswordPrefixCompareLength =
        global_config.m_db_account_service.UserNamePasswordPrefixCompareLength
    self:new_config_to_mdb_tree(config_mdb)
end

-- 属性监听钩子
account_service_mdb.watch_property_hook = {
    PasswordComplexityEnable = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_account_config:set_password_complexity_enable(value)
    end, 'PasswordComplexityEnable'),
    InitialPasswordPromptEnable = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_account_service:set_initial_password_prompt_enable(value)
    end, 'InitialPasswordPromptEnable'),
    InitialPasswordNeedModify = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = (value and '' or 'not ') .. 'needs modify' }
        self.m_account_service:set_initial_password_need_modify(value)
    end, 'InitialPasswordNeedModify'),
    InitialAccountPrivilegeRestrictEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_account_service:set_initial_account_privilege_restrict_enabled(value)
    end, 'InitialAccountPrivilegeRestrictEnabled'),
    MaxPasswordValidDays = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { max_valid_days = value }
        self.m_account_service:set_max_password_valid_days(value)
    end, 'MaxPasswordValidDays'),
    MinPasswordValidDays = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { min_valid_days = value }
        self.m_account_service:set_min_password_valid_days(value)
    end, 'MinPasswordValidDays'),
    WeakPasswordDictionaryEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_account_config:set_weak_pwd_dictionary_enable(value)
    end, 'WeakPasswordDictionaryEnabled'),
    EmergencyLoginAccountId = operation_logger.proxy(function(self, ctx, value)
        self.m_account_service:set_emergency_account(ctx, value)
        if value == 0 then
            ctx.operation_log.result = 'remove'
        end
    end, 'EmergencyLoginAccountId'),
    SNMPv3TrapAccountId = operation_logger.proxy(function(self, ctx, value)
        self.m_account_service:set_snmp_v3_trap_account(ctx, value)
    end, 'SNMPv3TrapAccountId'),
    SNMPv3TrapAccountLimitPolicy = operation_logger.proxy(function(self, ctx, value)
        self.m_account_service:set_snmp_v3_trap_account_limit_policy(ctx, value)
    end, 'SNMPv3TrapAccountLimitPolicy'),
    InactiveDaysThreshold = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { threshold = value }
        self.m_account_service:set_inactive_time_threshold(value)
    end, 'InactiveDaysThreshold'),
    HistoryPasswordCount = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { count = value }
        self.m_account_service:set_history_password_count(value)
        if value == 0 then
            ctx.operation_log.result = 'disable'
        end
    end, 'HistoryPasswordCount'),
    MaxHistoryPasswordCount = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { count = value }
        self.m_account_service:set_max_history_password_count(value)
        if value == 0 then
            ctx.operation_log.result = 'disable'
        end
    end, 'MaxHistoryPasswordCount'),
    MinPasswordLength = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { length = value }
        self.m_account_config:set_password_min_length(value)
    end,'MinPasswordLength'),
    HostUserManagementEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_account_config:set_host_user_management_enabled(value)
    end,'HostUserManagementEnabled'),
    OSAdministratorPrivilegeEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_account_service:set_os_administrator_privilege_enabled(ctx, value)
    end,'OSAdministratorPrivilegeEnabled'),
    UserNamePasswordPrefixCompareEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_account_config:set_user_name_password_compared_enabled(value)
    end,'UserNamePasswordPrefixCompareEnabled'),
    UserNamePasswordPrefixCompareLength = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { length = value }
        self.m_account_config:set_user_name_password_compared_length(value)
    end,'UserNamePasswordPrefixCompareLength'),
    SNMPv3TrapAccountChangePolicy = operation_logger.proxy(function(self, ctx, value)
        self.m_account_config:set_snmp_v3_trap_account_change_policy(ctx, value)
        self.m_account_service.m_account_collection:update_deletable()
    end, 'SNMPv3TrapAccountChangePolicy'),
}

function account_service_mdb:watch_service_property(service)
    service[INTERFACE_ACCOUNT_SERVICE].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the account service property(%s) to value(%s), sender is nil', name, tostring(value))
            return true
        end

        if not self.watch_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('change the property(%s) to value(%s)', name, tostring(value))
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_property_hook[name](self, ctx, value)
        return true
    end)
end

function account_service_mdb:new_config_to_mdb_tree(user_config)
    local cls_config = cls_mng('AccountService'):get("/bmc/kepler/AccountService")
    cls_config[INTERFACE_ACCOUNT_SERVICE].MaxPasswordLength = user_config.MaxPasswordLength
    cls_config[INTERFACE_ACCOUNT_SERVICE].MinPasswordLength = user_config.MinPasswordLength
    cls_config[INTERFACE_ACCOUNT_SERVICE].PasswordComplexityEnable = user_config.PasswordComplexityEnable
    cls_config[INTERFACE_ACCOUNT_SERVICE].InitialPasswordPromptEnable = user_config.InitialPasswordPromptEnable
    cls_config[INTERFACE_ACCOUNT_SERVICE].InitialPasswordNeedModify = user_config.InitialPasswordNeedModify
    cls_config[INTERFACE_ACCOUNT_SERVICE].InitialAccountPrivilegeRestrictEnabled =
        user_config.InitialAccountPrivilegeRestrictEnabled
    cls_config[INTERFACE_ACCOUNT_SERVICE].MaxPasswordValidDays = user_config.MaxPasswordValidDays
    cls_config[INTERFACE_ACCOUNT_SERVICE].MinPasswordValidDays = user_config.MinPasswordValidDays
    cls_config[INTERFACE_ACCOUNT_SERVICE].EmergencyLoginAccountId = user_config.EmergencyLoginAccountId
    cls_config[INTERFACE_ACCOUNT_SERVICE].InactiveDaysThreshold = user_config.InactiveDaysThreshold
    cls_config[INTERFACE_ACCOUNT_SERVICE].WeakPasswordDictionaryEnabled = user_config.WeakPasswordDictionaryEnabled
    cls_config[INTERFACE_ACCOUNT_SERVICE].SNMPv3TrapAccountId = user_config.SNMPv3TrapAccountId
    cls_config[INTERFACE_ACCOUNT_SERVICE].SNMPv3TrapAccountLimitPolicy = user_config.SNMPv3TrapAccountLimitPolicy
    cls_config[INTERFACE_ACCOUNT_SERVICE].HistoryPasswordCount = user_config.HistoryPasswordCount
    cls_config[INTERFACE_ACCOUNT_SERVICE].MaxHistoryPasswordCount = user_config.MaxHistoryPasswordCount
    cls_config[INTERFACE_ACCOUNT_SERVICE].HostUserManagementEnabled = user_config.HostUserManagementEnabled
    cls_config[INTERFACE_ACCOUNT_SERVICE].OSAdministratorPrivilegeEnabled = user_config.OSAdministratorPrivilegeEnabled
    cls_config[INTERFACE_ACCOUNT_SERVICE].UserNamePasswordPrefixCompareEnabled =
        user_config.UserNamePasswordPrefixCompareEnabled
    cls_config[INTERFACE_ACCOUNT_SERVICE].UserNamePasswordPrefixCompareLength =
        user_config.UserNamePasswordPrefixCompareLength
    self:watch_service_property(cls_config)
end

function account_service_mdb:config_mdb_update(property, value)
    local cls_config = cls_mng('AccountService'):get("/bmc/kepler/AccountService")
    if cls_config[INTERFACE_ACCOUNT_SERVICE][property] == nil then
        return
    end
    cls_config[INTERFACE_ACCOUNT_SERVICE][property] = value
end

function account_service_mdb:_import_remote_weak_pwd_dictionary(ctx, path)
    -- 远程文件，先生成任务，然后执行本地导入
    local file_trans_task_id, file_path = self.file_transfer:get_file_from_url(ctx, path, true)
    if skynet_ready == false then
        log:error("skynet is not ready, skip weakpwd dict import async task!")
        error(base_msg.InternalError())
    end
    local task_id = self.task_manager:create_weakpwddic_import_task()
    -- 这里异步操作时，ctx已经被logger修改了，导致operationLog不存在，需要手动添加一份
    -- 远程任务，外部不打印日志，内部手动设置日志格式
    local dup_ctx = mc_utils.table_copy(ctx)
    ctx.operation_log = nil
    dup_ctx.operation_log.result = nil -- 直接走日志函数的参数打印
    skynet.fork_once(function ()
        local ok, err_msg = self.file_transfer:is_file_transfer_completed(file_trans_task_id)
        if ok then
            ok, err_msg = pcall(function (...)
                self.m_account_config:import_weak_pwd_dictionary(file_path)
            end)
        end
        if not ok then
            log:error('file trans failed, skip import weak pwd dict!, %s', tostring(err_msg))
            self.task_manager:update_weakpwddic_import_task(false, tostring(err_msg))
            -- 异步操作日志
            operation_logger.log(dup_ctx, 'fail')
            return
        end
        self.task_manager:update_weakpwddic_import_task(true, nil)
        operation_logger.log(dup_ctx, 'success')
    end)
    return task_id
end

function account_service_mdb:import_weak_pwd_dictionary(ctx, path)
    if utils_core.g_regex_match(self.REMOTE_WEAKPWD_DICT_IMPORT_REGEX, path) ~= true then
        log:error('import weak password dictionary failed, path invalid.')
        -- 避免在错误引擎中暴露路径敏感信息
        error(custom_msg.InvalidPath('******', 'Import Path'))
    end
    if string.sub(path, 1, 1) ~= '/' then
        return self:_import_remote_weak_pwd_dictionary(ctx, path)
    end
    -- 本地路径执行导入
    self.m_account_config:import_weak_pwd_dictionary(path)
    -- 本地任务返回taskid为0
    return 0
end

function account_service_mdb:_export_remote_weak_pwd_dictionary(ctx, path)
    -- 先导出到本地tmp目录后上传远程服务器
    file_utils.copy_file_s(config.WEAK_PWDDICT_FILE_PATH, config.WEAK_PWDDICT_FILE_EXPORT_PATH)
    local file_trans_task_id = self.file_transfer:upload_file_to_url(ctx,
        config.WEAK_PWDDICT_FILE_EXPORT_PATH, path)
    if skynet_ready == false then
        log:error("skynet is not ready, skip weakpwd dict export async task!")
        error(base_msg.InternalError())
    end
    local task_id = self.task_manager:create_weakpwddic_export_task()
    -- 这里异步操作时，ctx已经被logger修改了，导致operationLog不存在，需要手动添加一份
    -- 远程任务，外部不打印日志，内部手动设置日志格式
    local dup_ctx = mc_utils.table_copy(ctx)
    ctx.operation_log = nil
    dup_ctx.operation_log.result = nil -- 直接走日志函数的参数打印
    skynet.fork_once(function ()
        local ok, err_msg = self.file_transfer:is_file_transfer_completed(file_trans_task_id)
        mc_utils.remove_file(config.WEAK_PWDDICT_FILE_EXPORT_PATH)
        if not ok then
            log:error('file trans failed, skip export weak pwd dict!, %s', tostring(err_msg))
            self.task_manager:update_weakpwddic_export_task(false, tostring(err_msg))
            -- 异步操作日志
            operation_logger.log(dup_ctx, 'fail')
            return
        end
        self.task_manager:update_weakpwddic_export_task(true, nil)
        operation_logger.log(dup_ctx, 'success')
    end)
    return task_id
end

function account_service_mdb:export_weak_pwd_dictionary(ctx, path)
    -- 导出弱口令操作当path为空使用默认路径
    if #path == 0 then
        path = config.WEAK_PWDDICT_FILE_EXPORT_PATH
    end
    if not utils_core.g_regex_match(self.REMOTE_WEAKPWD_DICT_IMPORT_REGEX, path) then
        log:error('export weak password dictionary failed, path invalid.')
        -- 避免在错误引擎中暴露路径敏感信息
        error(custom_msg.InvalidPath('******', 'Export Path'))
    end
    -- 远程导入
    if string.sub(path, 1, 1) ~= '/' then
        return self:_export_remote_weak_pwd_dictionary(ctx, path)
    end
    -- 本地路径执行导出
    self.m_account_config:export_weak_pwd_dictionary(ctx, path)
    return 0
end

return singleton(account_service_mdb)
