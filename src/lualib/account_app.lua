-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local skynet = require 'skynet'
local class = require 'mc.class'
local log = require 'mc.logging'
local mc_admin = require 'mc.mc_admin'
local mdb_service = require 'mc.mdb.mdb_service'
local orm_object_manage = require 'mc.orm.object_manage'
local reboot = require 'mc.mdb.micro_component.reboot'
local utils_core = require 'utils.core'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local service = require 'account.service'
local enum = require 'class.types.types'
local ipmi_cmds = require 'account.ipmi.ipmi'
local config = require 'common_config'
local client = require 'account.client'
local kmc_client = require 'infrastructure.kmc_client'
local ipmi_running_record = require 'infrastructure.ipmi_running_record'
local host_privilege_limit = require 'infrastructure.host_privilege_limit'
local account_backup_db = require 'infrastructure.account_backup_db'
local db_upgrade = require 'infrastructure.db_upgrade'
local task_manager = require 'infrastructure.task_manager'
local file_transfer = require 'infrastructure.file_transfer'
local utils = require 'infrastructure.utils'
local login_rule_collection = require 'domain.login_rule.login_rule_collection'
local role_collection = require 'domain.role'
local global_account_config = require 'domain.global_account_config'
local account_recover = require 'service.account_recover'
local ipmi_channel_mappings = require 'domain.ipmi_channel_mappings'
local ipmi_channel_config = require 'domain.ipmi_channel_config'
local account_collection = require 'domain.account_collection'
local account_permanent_backup = require 'domain.account_permanent_backup'
local file_synchronization = require 'domain.file_synchronization'
local password_validator_collection = require 'domain.password_validator_collection'
local account_policy_collection = require 'domain.account_policy_collection'
local account_service = require 'service.account_service'
local local_authentication = require 'service.local_authentication'
local operation_logger = require 'interface.operation_logger'
local login_rule_mdb = require 'interface.mdb.login_rule_mdb'
local role_privilege_mdb = require 'interface.mdb.role_privilege_mdb'
local account_mdb = require 'interface.mdb.account_mdb'
local account_service_mdb = require 'interface.mdb.account_service_mdb'
local snmp_community_mdb = require 'interface.mdb.snmp_community_mdb'
local password_validator_mdb = require 'interface.mdb.password_validator_mdb'
local account_policy_mdb = require 'interface.mdb.account_policy_mdb'
local ipmi_channel_config_mdb = require 'interface.mdb.ipmi_channel_config_mdb'
local account_service_ipmi = require 'interface.ipmi.account_service_ipmi'
local password_validator_ipmi = require 'interface.ipmi.password_validator_ipmi'
local account_service_snmp = require 'interface.snmp.account_service_snmp'
local config_handle = require 'interface.config_mgmt.config_handle'
local core    = require 'account_core'
local queue = require 'skynet.queue'
-- 保底碎片回收策略5分钟一次即可
local INTERVAL = 5 * 60 * 100

local app = class(service)

local function update_config()
    -- 路径类地址转换为绝对路径
    local path_key = {
        ['TMP_PATH'] = true,
        ['SSH_PUBLIC_KEY_PARSE_PATH'] = true,
        ['SSH_PUBLIC_KEY_CONF_TEMP_FILE'] = true,
        ['SSH_PUBLIC_KEY_HASH_TEMP_FILE'] = true,
        ['DATA_HOME_PATH'] = true,
        ['SHM_PATH'] = true,
        ['SHM_TMP_PATH'] = true,
        ['LOGINRULE_FILE'] = true,
        ['TEMP_PAM_FAILLOCK'] = true,
        ['PAM_FAILLOCK'] = true,
        ['PAM_TALLY_LOG_DIR'] = true,
        ['WEAK_PWDDICT_FILE_SHM_PATH'] = true
    }
    for config_key, config_value in pairs(config) do
        local sn_value = skynet.getenv(config_key)
        if sn_value ~= nil then
            if path_key[config_key] then
                sn_value = core.format_realpath(sn_value)
            end
            log:info('Update user_config %s from %s to %s', config_key, config_value, sn_value)
            config[config_key] = sn_value
        end
    end
end

local function destroy_instance_cache()
    -- 单例对象，先销毁再创建
    kmc_client:destroy()
    ipmi_running_record.destroy()
    host_privilege_limit.destroy()
    account_backup_db.destroy()
    task_manager.destroy()
    file_transfer.destroy()
    utils.destroy()
    login_rule_collection.destroy()
    role_collection.destroy()
    global_account_config.destroy()
    account_collection.destroy()
end

-- 清理共享内存残留
local function remove_shm_data()
    -- account interface
    local account_shm_interface_table = {
        'bmc.kepler.AccountService'
    }
    for _, interface in pairs(account_shm_interface_table) do
        local ok, _ = pcall(mdb_service.remove_shm_objects, nil, 'bmc.kepler.account', interface)
        if not ok then
            log:error('Delete interface(%s) shm data failed.', interface)
        end
    end
end

function app:ctor()
    update_config()
    remove_shm_data()
    destroy_instance_cache()

    -- 持久化数据恢复注册
    self.db_upgrade = db_upgrade.new({['db'] = self.db, ['backup_db'] = self.local_db})
    -- 用户文件队列
    self.linux_account_queue = queue()
end

function app:patch()
    local snmp_patch = require 'patch.snmp_patch'
    snmp_patch.exec(self.persist, self.db)
end

function app:bmcuptime()
    local ret,uptime = pcall(utils_core.get_bmc_uptime)
    if not ret then
        return 0
    end
    if uptime < 90 then
        skynet.sleep((90 - uptime) * 100) -- account错峰启动,加速组件启动速度
    end
    return uptime
end

function app:skynet_service_init()
    self:bmcuptime()
    self.key_mgmt_client = kmc_client.new(self.bus, function(domain_id, new_key_id)
        if not self.service_ready then
            log:info("service is not ready")
            return false
        end
        local ret, err = pcall(function()
            self.account_collection.m_ipmi_crypt_password_update:emit()
        end)
        if not ret then
            log:error("update ciphertext after key change error, %s", err)
            return false
        end
        return true
    end)


    self.service_ready = self:service_init()

    -- 信号注册后需要将初始化中预加载的数据上树一次
    self.account_collection:emit_init_account_signal()

    -- 协程: linux用户同步，保证稳定性
    self.file_synchronization:account_monitor()

    -- 协程: 用户时间信息检查
    self.account_service:user_time_info_monitor()

    -- 注册ORM管理对象，支持无需主动save操作也可插入数据到数据库
    orm_object_manage.get_instance(self.db, self.bus):start()

    self:collection_garbage_init()

    -- 配置导入导出和定制化入口
    config_handle.new()

    self:monitor_ipmi_channel_num()
end

function app:init()
    log:notice("account class init start")
    app.super.init(self)

    -- 打补丁
    self:patch()
    self:check_dependencies()
    self:register_rpc_methods()
    -- 注册用户管理IPMI接口, IPMI接口耗时较长，协程注册
    skynet.fork_once(function()
        self:register_ipmi_methods()
    end)

    skynet.fork_once(function()
        self:skynet_service_init()
    end)

    log:notice("account class init end")
    return 0
end

local linux_file_path = {
    ['passwd'] = skynet.getenv('PASSWD_FILE'),
    ['shadow'] = skynet.getenv('SHADOW_FILE'),
    ['group'] = skynet.getenv('GROUP_FILE'),
    ['ipmi'] = skynet.getenv('IPMI_FILE')
}

function app:service_init()
    -- 基础设施
    log:notice("infrastructure init start")
    self.ipmi_running_record = ipmi_running_record.new()
    self.host_privilege_limit = host_privilege_limit.new()
    self.account_backup_db = account_backup_db.new(self.db)
    self.task_manager = task_manager.new(self.bus)
    self.file_transfer = file_transfer.new()
    self.utils = utils.new()
    log:notice("infrastructure init end, login rule init start")
    -- 登录规则
    self.login_rule_collection = login_rule_collection.new(self.bus, self.db)
    self.login_rule_mdb =login_rule_mdb.new(self.login_rule_collection)
    self.login_rule_mdb:regist_rule_signals()
    self.login_rule_collection:init_login_rule_signal()
    log:notice("login rule init end, role privilege init start")
    -- 角色权限
    self.role_collection = role_collection.new(self.db)
    self.role_privilege_mdb = role_privilege_mdb.new(self.role_collection)
    self.role_privilege_mdb:regist_role_privilege_signals()
    self.role_collection:emit_init_role_signal()
    log:notice("role privilege init end, account config init start")
    -- 用户配置
    self.global_account_config = global_account_config.new(self.db, self.file_transfer)
    self.password_validator_collection = password_validator_collection.new(self.db, self.global_account_config)
    self.account_policy_collection = account_policy_collection.new(self.db, self.global_account_config)
    log:notice("account config init end, account manager init start")
    -- 用户管理
    self.ipmi_channel_mappings = ipmi_channel_mappings.new()
    self.ipmi_channel_config = ipmi_channel_config.new(self.db)
    self.account_collection = account_collection.new(self.persist, self.db, self.global_account_config,
        self.role_collection, self.host_privilege_limit, self.password_validator_collection,
        self.account_policy_collection, self.ipmi_channel_config, linux_file_path, self.linux_account_queue)
    self.account_permanent_backup = account_permanent_backup.new(self.db, self.account_collection)
    log:notice("account manager init end, linux file manager init start")
    self:bmcuptime()
    -- 文件管理
    self.file_synchronization = file_synchronization.new(self.db, self.account_collection, linux_file_path,
        self.linux_account_queue)
    log:notice("linux file manager init end, account service init start")
    -- 用户服务
    self.account_service = account_service.new(self.global_account_config, self.account_collection,
        self.file_synchronization, self.role_collection, self.account_policy_collection)
    self.account_recover = account_recover.new(self.db, self.account_backup_db, self.account_service)
    self.local_authentication = local_authentication.new(self.account_collection, self.global_account_config)
    log:notice("account service init end, interface init start")
    -- 接口层
    self.account_mdb = account_mdb.new(self.account_service, self.role_collection, self.task_manager,
        self.file_transfer)
    self.account_mdb:regist_account_signals()
    self.account_service_mdb = account_service_mdb.new(self.account_service, self.task_manager, self.file_transfer)
    self.account_service_mdb:regist_account_signals()
    self.snmp_community_mdb = snmp_community_mdb.new(self.account_service)
    self.password_validator_mdb = password_validator_mdb.new(self.password_validator_collection)
    self.account_policy_mdb = account_policy_mdb.new(self.account_policy_collection)
    self.ipmi_channel_config_mdb = ipmi_channel_config_mdb.new(self.ipmi_channel_config)
    self.ipmi_channel_config_mdb:regist_channel_config_signals()
    self.account_service_ipmi = account_service_ipmi.new()
    self.password_validator_ipmi = password_validator_ipmi.new(self.password_validator_collection)
    self.account_service_snmp = account_service_snmp.new(self.account_service)
    log:notice("interface init end")
    return true
end

-- 依赖检查
function app:check_dependencies()
    if skynet.getenv('TEST_DATA_DIR') then
        return
    end
    local admin = mc_admin.new()
    admin:parse_dependency(utils_core.getcwd() .. '/mds/service.json')
    admin:check_dependency(self.bus)
end

function app:init_reboot()
    reboot.on_prepare(function(...)
        return self:on_reboot_prepare(...)
    end)
    reboot.on_action(function(...)
        return self:on_reboot_action(...)
    end)
    reboot.on_cancel(function(...)
        self:on_reboot_cancel()
    end)
end

function app:on_reboot_prepare()
    -- 重启前将用户不活动记录写到flash中
    for _, account in pairs(self.account_collection.collection) do
        pcall(function ()
            account:update_inactive_user_start_time(true)
            account:record_login_time_ip(nil, nil, true)
            account:record_last_login_interface(nil, true)
        end)
    end
    log:info('Key updating must be ok before reboot')
    while true do
        if self.key_mgmt_client.m_key_update_done ~= true then
            -- 继承v2，重启时密钥更新未完成，延时10ms
            skynet.sleep(1)
        end
        break
    end
    log:info('account has no extra preparation for reboot.')
    return 0
end

function app:on_reboot_action()
    log:info('account has no extra action for reboot.')
    return 0
end

function app:on_reboot_cancel()
    log:info('account has no extra cancel for reboot.')
end

function app:register_ipmi_methods()
    -- 注册设置用户权限
    self:register_ipmi_cmd(ipmi_cmds.SetUserAccess, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_account_access(req, ctx)
    end, 'IpmiSetUserAccess'))

    -- 注册获取用户权限
    self:register_ipmi_cmd(ipmi_cmds.GetUserAccess, function(req, ctx)
        return self.account_service_ipmi:get_user_access(req, ctx)
    end)

    -- 注册设置用户名
    self:register_ipmi_cmd(ipmi_cmds.SetUserName, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_account_name(req, ctx)
    end, 'ChangeUserName'))

    -- 注册获取用户名
    self:register_ipmi_cmd(ipmi_cmds.GetUserName, function(req, ctx)
        return self.account_service_ipmi:get_user_name(req, ctx)
    end)

    -- 注册设置口令复杂度
    self:register_ipmi_cmd(ipmi_cmds.SetUserPassComplexity, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_password_compexity(req, ctx)
    end, 'IpmiSetUserPassComplexity'))

    -- 注册获取口令复杂度
    self:register_ipmi_cmd(ipmi_cmds.GetUserPassComplexity, function(req, ctx)
        return self.account_service_ipmi:get_password_compexity(req, ctx)
    end)

    -- 注册设置用户接口
    self:register_ipmi_cmd(ipmi_cmds.SetUserInterface, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_user_interface(req, ctx)
    end, 'IpmiSetUserInterface'))

    -- 注册获取用户接口
    self:register_ipmi_cmd(ipmi_cmds.GetAccountInterface, function(req, ctx)
        return self.account_service_ipmi:get_account_interface(req, ctx)
    end)

    -- 注册支持设置SNMPV3密码功能
    self:register_ipmi_cmd(ipmi_cmds.UserIpmiSetUserSNMPV3PrivacyPwd, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_user_snmp_v3_privacy_pwd(req, ctx)
    end, 'ChangeAccountSnmpPwd'))

    -- 注册设置snmp团体名
    self:register_ipmi_cmd(ipmi_cmds.SetSNMPConfiguration, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_snmp_configuration(req, ctx)
    end, 'IpmiSetSNMPConfiguration'))

    -- 注册获取snmp团体名
    self:register_ipmi_cmd(ipmi_cmds.GetSNMPConfiguration, function(req, ctx)
        return self.account_service_ipmi:get_snmp_configuration(req, ctx)
    end)

    -- 注册设置Vnc密码
    self:register_ipmi_cmd(ipmi_cmds.SetVncPassword, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_vnc_password(req, ctx)
    end, 'ChangeVNCPwd'))

    -- 注册设置用户密码前n字节比对信息
    self:register_ipmi_cmd(ipmi_cmds.SetUserPasswordCompareInfo, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_user_name_password_compared_info(req, ctx)
    end, 'UserNamePasswordPrefixCompareInfo'))

    -- 注册获取用户密码前n字节比对信息
    self:register_ipmi_cmd(ipmi_cmds.GetUserPasswordCompareInfo, function(req, _)
        return self.account_service_ipmi:get_user_name_password_compared_info(req)
    end)

    -- 注册获取弱密码字典使能
    self:register_ipmi_cmd(ipmi_cmds.GetWeakPwdDictionaryEnabled, function(req, ctx)
        return self.account_service_ipmi:get_weak_pwd_dictionary_enable(req, ctx)
    end)

    -- 注册获取首次登录密码修改策略
    self:register_ipmi_cmd(ipmi_cmds.GetFirstLoginModifyPolicy, function(req, ctx)
        return self.account_service_ipmi:get_first_login_policy_by_id(req, ctx)
    end)

    -- 注册获取历史密码检查次数
    self:register_ipmi_cmd(ipmi_cmds.GetHistoryPwdCheckCount, function(req, ctx)
        return self.account_service_ipmi:get_history_password_count(req, ctx)
    end)

    -- 注册获取紧急登录用户
    self:register_ipmi_cmd(ipmi_cmds.GetEmergencyLoginAccount, function(req, ctx)
        return self.account_service_ipmi:get_emergency_login_account(req, ctx)
    end)

    -- 注册获取初始密码提示开关
    self:register_ipmi_cmd(ipmi_cmds.GetInitialPasswordPromptEnable, function(req, ctx)
        return self.account_service_ipmi:get_initial_password_prompt_enable(req, ctx)
    end)

    -- 注册设置弱密码字典使能
    self:register_ipmi_cmd(ipmi_cmds.SetWeakPwdDictionaryEnabled, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_weak_pwd_dictionary_enable(req, ctx)
    end, 'WeakPasswordDictionaryEnabled'))

    -- 注册设置首次登录密码修改策略
    self:register_ipmi_cmd(ipmi_cmds.SetFirstLoginModifyPolicy, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_first_login_passwd_modify_policy(req, ctx)
    end, 'FirstLoginPolicy'))

    -- 注册设置历史密码检查次数
    self:register_ipmi_cmd(ipmi_cmds.SetHistoryPwdCheckCount, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_history_passwd_check_count(req, ctx)
    end, 'HistoryPasswordCount'))

    -- 注册设置紧急登录用户
    self:register_ipmi_cmd(ipmi_cmds.SetEmergencyLoginAccount, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_emergency_login_account(req, ctx)
    end, 'EmergencyLoginAccountId'))

    -- 注册设置初始密码提示开关
    self:register_ipmi_cmd(ipmi_cmds.SetInitialPasswordPromptEnable, operation_logger.proxy(function(req, ctx)
        return self.account_service_ipmi:set_initial_password_prompt_enable(req, ctx)
    end, 'InitialPasswordPromptEnable'))

    -- 注册禁用用户
    self:register_ipmi_cmd(ipmi_cmds.DisableAccount, operation_logger.proxy(function(req, ctx)
        local rsp = ipmi_cmds.DisableAccount.rsp.new()
        req.Operation = enum.IpmiUserOperater.OPERATION_DISABLE_USER:value()
        return self.account_service_ipmi:set_account_password(req, rsp, ctx)
    end, 'IpmiAccountEnabled'))

    -- 注册使能用户
    self:register_ipmi_cmd(ipmi_cmds.EnableAccount, operation_logger.proxy(function(req, ctx)
        local rsp = ipmi_cmds.EnableAccount.rsp.new()
        req.Operation = enum.IpmiUserOperater.OPERATION_ENABLE_USER:value()
        return self.account_service_ipmi:set_account_password(req, rsp, ctx)
    end, 'IpmiAccountEnabled'))

    -- 注册设置用户密码
    self:register_ipmi_cmd(ipmi_cmds.SetAccountPassword, operation_logger.proxy(function(req, ctx)
        local rsp = ipmi_cmds.SetAccountPassword.rsp.new()
        req.Operation = enum.IpmiUserOperater.OPERATION_SET_PASSWD:value()
        return self.account_service_ipmi:set_account_password(req, rsp, ctx)
    end, 'ChangeAccountPwd'))

    self:register_ipmi_cmd(ipmi_cmds.GetPasswordRulePolicy, function(req, ctx)
        return self.password_validator_ipmi:get_policy(req, ctx)
    end)
    self:register_ipmi_cmd(ipmi_cmds.SetPasswordRulePolicy, operation_logger.proxy(function(req, ctx)
        return self.password_validator_ipmi:set_policy(req, ctx)
    end, 'PasswordPolicy'))

    self:register_ipmi_cmd(ipmi_cmds.GetPasswordPattern, function(req, ctx)
        return self.password_validator_ipmi:get_pattern(req, ctx)
    end)
    self:register_ipmi_cmd(ipmi_cmds.SetPasswordPattern, operation_logger.proxy(function(req, ctx)
        return self.password_validator_ipmi:set_pattern(req, ctx)
    end, 'PasswordPattern'))
end

function app:register_rpc_methods()
    -- 删除用户
    self:ImplManagerAccountManagerAccountDelete(operation_logger.proxy(function(obj, ctx)
        self.db_upgrade:check_trusted_partition_overrun()
        return self.account_collection:delete_account(ctx, obj.values.Id)
    end, 'DeleteAccount'))
    -- 修改用户密码
    self:ImplManagerAccountManagerAccountChangePwd(operation_logger.proxy(function(obj, ctx, ...)
        self.db_upgrade:check_trusted_partition_overrun()
        return self.account_mdb:change_password(ctx, obj.values.Id, ...)
    end, 'ChangeAccountPwd'))
    -- 修改用户snmp加密密码
    self:ImplManagerAccountManagerAccountChangeSnmpPwd(operation_logger.proxy(function(obj, ctx, ...)
        self.db_upgrade:check_trusted_partition_overrun()
        return self.account_mdb:change_snmp_password(ctx, obj.values.Id, ...)
    end, 'ChangeAccountSnmpPwd'))
    -- 导入ssh公钥
    self:ImplManagerAccountManagerAccountImportSSHPublicKey(operation_logger.proxy(function(obj, ctx, ...)
        return self.account_mdb:import_ssh_public_key(ctx, obj.values.Id, ...)
    end, 'ImportSSHPublicKey'))
    -- 删除ssh公钥
    self:ImplManagerAccountManagerAccountDeleteSSHPublicKey(operation_logger.proxy(function(obj, ctx, ...)
        return self.account_mdb:delete_ssh_public_key(ctx, obj.values.Id)
    end, 'DeleteSSHPublicKey'))
    -- 设置SNMP鉴权算法
    self:ImplManagerAccountSnmpUserSetAuthenticationProtocol(operation_logger.proxy((function(obj, ctx, ...)
        local account_id = string.match(obj.path, "/bmc/kepler/AccountService/Accounts/(%d+)")
        return self.account_mdb:set_authentication_protocol(ctx, tonumber(account_id), ...)
    end), 'SetAuthenticationProtocol'))
    -- 设置SNMP加密算法
    self:ImplManagerAccountSnmpUserSetEncryptionProtocol(operation_logger.proxy(function(obj, ctx, ...)
        local account_id = string.match(obj.path, "/bmc/kepler/AccountService/Accounts/(%d+)")
        return self.account_mdb:set_encryption_protocol(ctx, tonumber(account_id), ...)
    end, 'SetEncryptionProtocol'))
    self:ImplManagerAccountSnmpUserGetSnmpKeys(function(obj, ...)
        local account_id = string.match(obj.path, "/bmc/kepler/AccountService/Accounts/(%d+)")
        return self.account_collection:get_snmp_keys(tonumber(account_id))
    end)
    self:ImplRoleRoleSetRolePrivilege(operation_logger.proxy(function(obj, ctx, PrivilegeType, PrivilegeValue)
        local role_id = string.match(obj.path, "/bmc/kepler/AccountService/Roles/(%d+)")
        role_id = tonumber(role_id)
        PrivilegeType = enum.PrivilegeType.new(PrivilegeType)
        return self.role_collection:set_role_privilege(ctx, role_id, PrivilegeType, PrivilegeValue)
    end, 'SetRolePrivilege'))
    -- 添加新用户
    self:ImplManagerAccountsManagerAccountsNew(operation_logger.proxy(function(obj, ...)
        return self:NewAccount(...)
    end, 'NewAccount'))
    self:ImplManagerAccountsManagerAccountsGetIdByUserName(function(obj, ctx, UserName)
        UserName = UserName == config.RESERVED_ROOT_USER_NAME and config.ACTUAL_ROOT_USER_NAME or UserName
        return self.account_service:get_id_by_user_name(ctx, UserName)
    end)
    self:ImplManagerAccountsManagerAccountsGetUidGidByUserName(function(obj, ...)
        return self.account_collection:get_uid_gid_by_username(...)
    end)
    self:ImplLocalAccountAuthNLocalAccountAuthNGenRmcp20Code(function(obj, ctx, ...)
        return self.local_authentication:gen_rmcp20_auth_code(ctx, ...)
    end)
    self:ImplLocalAccountAuthNLocalAccountAuthNGenRmcp15Code(function(obj, ctx, ...)
        return self.local_authentication:gen_rmcp15_auth_code(ctx, ...)
    end)
    -- 导入弱口令字典文件
    self:ImplAccountServiceAccountServiceImportWeakPasswordDictionary(operation_logger.proxy(function(obj, ctx, ...)
        return self.account_service_mdb:import_weak_pwd_dictionary(ctx, ...)
    end, 'ImportWeakPasswordDictionary'))
    -- 导出弱口令字典文件
    self:ImplAccountServiceAccountServiceExportWeakPasswordDictionary(operation_logger.proxy(function(obj, ctx, ...)
        return self.account_service_mdb:export_weak_pwd_dictionary(ctx, ...)
    end, 'ExportWeakPasswordDictionary'))
    self:ImplSnmpCommunitySnmpCommunitySetRoCommunity(operation_logger.proxy(function(obj, ctx, RoCommunity)
        self.snmp_community_mdb:set_ro_community(ctx, RoCommunity)
    end, 'SetRoCommunity'))
    self:ImplSnmpCommunitySnmpCommunitySetRwCommunity(operation_logger.proxy(function(obj, ctx, RwCommunity)
        self.snmp_community_mdb:set_rw_community(ctx, RwCommunity)
    end, 'SetRwCommunity'))
    self:ImplSnmpCommunitySnmpCommunityGetSnmpCommunity(function(obj, ctx, ...)
        return self.snmp_community_mdb:get_snmp_community()
    end)
    -- 新建OEM用户方法作为中间步骤，不记录操作日志
    self:ImplManagerAccountsManagerAccountsNewOEMAccount(function(obj, ...)
        return self:NewOEMAccount(...)
    end)
    -- 设置属性可更改性作为中间步骤，不记录操作日志
    self:ImplManagerAccountsManagerAccountsSetAccountWritable(operation_logger.proxy(function(obj, ctx, ...)
        return self.account_collection:set_account_property_writable(ctx, ...)
    end, 'SetAccountWritable'))
    self:ImplManagerAccountsManagerAccountsGetAccountWritable(function(obj, ctx, ...)
        return self.account_collection:get_account_property_writable(...)
    end)
    self:ImplAccountServiceAccountServiceGetRequestedPublicKey(function(obj, ctx, ...)
        return self.account_service:get_requested_public_key(...)
    end)
    self:ImplManagerAccountsManagerAccountsSetAccountLockState(operation_logger.proxy(function(obj, ctx, ...)
        return self.account_collection:set_account_lock_state(ctx, ...)
    end, 'SetAccountLockState'))
    self:ImplManagerAccountManagerAccountSetLastLogin(function(obj, ctx, ip, interface)
        local account_id = tonumber(obj.values.Id)
        if ip ~= "" and string.len(ip) ~= 0 then
            self.account_collection:record_login_time_ip(account_id, ip, false)
        end
        if interface ~= "" and string.len(interface) ~= 0 then
            interface = enum.LoginInterface.new(interface)
            self.account_collection:record_last_login_interface(account_id, interface, false)
        end
        return 0
    end)
    -- 实现恢复指定用户的功能
    self:ImplAccountServiceAccountServiceRecoverAccount(operation_logger.proxy(function(obj, ctx, account_id, policy)
        ctx.operation_log.params = {id = account_id}
        return self.account_recover:recover_account(ctx, account_id, policy)
    end, 'RecoverAccount'))
    -- 本地用户认证
    self:ImplLocalAccountAuthNLocalAccountAuthNLocalAuthenticate(function(obj, ctx, user_name, password, ext_config)
        if ext_config['TestPassword'] then
            return self.local_authentication:test_ipmi_password(user_name, password)
        elseif ext_config['IpmiLocalAuth'] then
            return self.local_authentication:ipmi_local_authenticate(user_name, password)
        elseif ext_config['RecordOnly'] then
            return self.local_authentication:ext_record_operation(ctx, user_name, ext_config)
        end
        return self.local_authentication:authenticate(ctx, user_name, password, ext_config)
    end)
    self:ImplLocalAccountAuthNLocalAccountAuthNVncAuthenticate(function(obj, ctx, cipher_text, auth_challenge)
        return self.local_authentication:vnc_authenticate(ctx, cipher_text, auth_challenge)
    end)
    self:ImplRolesRolesNew(operation_logger.proxy(function(obj, ctx, role_id, assigned_privs, oem_privs)
        ctx.operation_log.params = {id = tostring(enum.RoleType.new(role_id))}
        self.role_collection:new_role(ctx, role_id, assigned_privs, oem_privs)
    end, 'NewRole'))
    self:ImplRoleRoleDelete(operation_logger.proxy(function(obj, ctx)
        local role_id = string.match(obj.path, "/bmc/kepler/AccountService/Roles/(%d+)")
        role_id = tonumber(role_id)
        ctx.operation_log.params = {id = tostring(enum.RoleType.new(role_id))}
        self.role_collection:delete_role(ctx, role_id)
    end, 'DeleteRole'))
end


function app:NewAccount(ctx, AccountId, UserName, Password, RoleId, Interface, FirstLoginPolicy)
    self.db_upgrade:check_trusted_partition_overrun()
    if string.upper(ctx.Interface) == "SNMP" then
        return self.account_service_snmp:new_account(ctx, AccountId, UserName)
    else
        local first_login_policy = enum.FirstLoginPolicy.new(FirstLoginPolicy:value())
        local account_info = {
            id = AccountId,
            name = UserName,
            password = Password,
            role_id = RoleId:value(),
            interface = Interface,
            first_login_policy = first_login_policy,
            is_pwd_encrypted = false,
            account_type = enum.AccountType.Local:value()
        }
        -- 第三个参数：非IPMI与SNMP接口新建用户
        return self.account_service:new_account(ctx, account_info, false)
    end
end

function app:NewOEMAccount(ctx, AccountId, UserName, Password, AccountInfo)
    self.db_upgrade:check_trusted_partition_overrun()
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    local account_info = {
        operation = AccountInfo.operation,
        id = AccountId,
        name = UserName,
        password = Password,
        role_id = tonumber(AccountInfo.role_id),
        interface = utils.oem_get_user_login_interface(tonumber(AccountInfo.interface)),
        first_login_policy = enum.FirstLoginPolicy.new(tonumber(AccountInfo.first_login_policy)),
        is_pwd_encrypted = tonumber(AccountInfo.is_pwd_encrypted) == 2 or false,
        oem = true,
        account_type = enum.AccountType.OEM:value()
    }
    if account_info.operation == 'New' then
        if self.account_collection.collection[AccountId] then
            log:info("OEM Account[%d] already exists, skip creating", AccountId)
            return AccountId
        end
        -- 第三个参数：非IPMI与SNMP接口新建用户
        return self.account_service:new_account(ctx, account_info, false)
    elseif account_info.operation == 'Verify' then
        local oem_account = self.account_collection.collection[account_info.id]
        if not oem_account then
            log:error('Invald id(%d)', account_info.id)
            error(base_msg.ActionParameterUnknown('VerifyOEMAccount', 'Id'))
        end
        oem_account:verify_account(account_info)
        return account_info.id
    end
end

function app:collection_garbage_init()
    skynet.fork_loop({ count = 0 }, function ()
        while true do
            skynet.sleep(INTERVAL)
            collectgarbage('collect')
        end
    end)
end

function app:monitor_ipmi_channel_num()
    client:OnChannelNumberMappingPropertiesChanged(function(...)
        self.ipmi_channel_mappings:on_channel_number_mappings_properties_changed(...)
    end)
    client:OnChannelNumberMappingInterfacesAdded(function(...)
        self.ipmi_channel_mappings:on_channel_number_mappings_interfaces_added(...)
    end)
    client:OnChannelNumberMappingInterfacesRemoved(function(...)
        self.ipmi_channel_mappings:on_channel_number_mappings_interfaces_removed(...)
    end)
end

return app