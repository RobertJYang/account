-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local signal = require 'mc.signal'
local log = require 'mc.logging'
local mc_context = require 'mc.context'
local mdb_service = require 'mc.mdb.mdb_service'
local vos_utils = require 'utils.vos'
local utils_core = require 'utils.core'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local sqlite3 = require 'lsqlite3'
local enum = require 'class.types.types'
local err = require 'account.errors'
local ipmi_cmds = require 'account.ipmi.ipmi'
local client = require 'account.client'
local config = require 'common_config'
local err_cfg = require 'error_config'
local role_privilege_map = require 'models.role_privilege_map'
local kmc_client = require 'infrastructure.kmc_client'
local linux_account = require 'infrastructure.account_linux'
local account_backup_db = require 'infrastructure.account_backup_db'
local utils = require 'infrastructure.utils'
local file_proxy = require 'infrastructure.file_proxy'
local ipmi_channel_mappings = require 'domain.ipmi_channel_mappings'
local local_account = require 'domain.manager_account.local_account'
local ipmi_account = require 'domain.manager_account.ipmi_account'
local vnc_account = require 'domain.manager_account.vnc_account'
local oem_account = require 'domain.manager_account.oem_account'
local snmp_community = require 'domain.manager_account.snmp_community'
local inter_chassis_account = require 'domain.manager_account.inter_chassis_account'
local core = require 'account_core'
local cert_service_enum = require 'account.json_types.CertificateService'

local account_type_map = {
    [enum.AccountType.Local:value()] = local_account,
    [enum.AccountType.IPMI_INNER:value()] = ipmi_account,
    [enum.AccountType.VNC:value()] = vnc_account,
    [enum.AccountType.SnmpCommunity:value()] = snmp_community,
    [enum.AccountType.OEM:value()] = oem_account,
    [enum.AccountType.InterChassis:value()] = inter_chassis_account
}

local PATH_CERT_SERVICE = '/bmc/kepler/CertificateService'
local PATH_ACCOUT_CERT = '/bmc/kepler/AccountService/MultiFactorAuth/ClientCertificate/Certificates/%d'
local DEFAULT_MIN_USER_NUM = 2
local DEFAULT_MAX_USER_NUM = 17

local AccountCollection = class()
function AccountCollection:ctor(persist, db, global_account_config, role_collection, host_privilege_limit,
    password_validator_collection, account_policy_collection, ipmi_channel_config, linux_file_path)
    self.persist = persist
    self.db = db
    self.passwd_path = linux_file_path['passwd'] or config.PASSWD_FILE
    self.shadow_path = linux_file_path['shadow'] or config.SHADOW_FILE
    self.group_path = linux_file_path['group'] or config.GROUP_FILE
    self.ipmi_path = linux_file_path['ipmi'] or config.IPMI_FILE
    self.linux_files = {
        passwd_path = self.passwd_path,
        shadow_path = self.shadow_path,
        group_path = self.group_path,
        ipmi_path = self.ipmi_path
    }
    self.m_global_account_config = global_account_config
    self.m_rc = role_collection
    self.m_host_privilege_limit = host_privilege_limit
    self.password_validator_collection = password_validator_collection
    self.account_policy_collection = account_policy_collection
    self.ipmi_channel_config = ipmi_channel_config
    self.ipmi_channel_mappings = ipmi_channel_mappings.get_instance()
end

AccountCollection.operation_type_check = {
    LOCAL_AND_OEM = {
        [enum.AccountType.Local:value()] = true,
        [enum.AccountType.OEM:value()] = true
    },
    LOCAL_OR_VNC = {
        [enum.AccountType.Local:value()] = true,
        [enum.AccountType.VNC:value()] = true
    }
}

function AccountCollection:signals_init()
    self.m_account_added = signal.new()
    self.m_account_removed = signal.new()
    self.m_account_changed = signal.new()
    self.m_snmp_info_changed = signal.new()
    -- 四个文件信号标志位，用于刷新文件
    self.m_account_file_added = signal.new()
    self.m_account_file_removed = signal.new()
    self.m_account_file_flush = signal.new()
    self.m_account_file_changed = signal.new()
    self.m_account_ipmi_changed = signal.new()
    self.m_account_security_changed = signal.new() -- 某些涉及安全的属性变更，如用户名密码等，触发该信号需要清理用户会话
    self.m_ipmi_crypt_password_update = signal.new() -- 当kmc密钥更新时更新存储的密码密文
    -- 持久化属性信号
    self.m_account_permanent_changed = signal.new()
end

function AccountCollection:init_account_collection(db)
    local stmt_account = db:select(db.ManagerAccountDB)
    local stmt_snmp_info = db:select(db.SNMPUserInfo)
    local ipmi_user_info = db:select(db.IpmiUserInfo)
    local account_collection = stmt_account:fold(function(account, acc)
        if account.UserName == nil or account.Password == nil then
            log:error("account data destoryed, now do delete Account(%d)", account.Id)
            account:delete()
            return acc
        end
        local suc, ret = pcall(account_type_map[account.AccountType:value()].new,
            db, account, self.password_validator_collection:get_validator(account.AccountType:value()),
            self.ipmi_channel_config)
        if suc == true then
            acc[account.Id] = ret
            if self.persist then
                self.persist:per_save(sqlite3.UPDATE, 't_manager_account', {{"Id", account.Id}},
                    {['Password'] = {value = account.Password, persist_type = 'protect_power_off'}})
            end
        else
            log:error(ret)
        end
        return acc
    end, {})
    stmt_snmp_info:fold(function(snmp_info)
        if account_collection[snmp_info.AccountId] ~= nil then
            account_collection[snmp_info.AccountId]:init_snmp_user_info(snmp_info)
        else
            log:error('init snmp user failed! UserID: %d do not exist.', snmp_info.AccountId)
            snmp_info:delete()
        end
    end)
    ipmi_user_info:fold(function(ipmi_info)
        if account_collection[ipmi_info.AccountId] ~= nil then
            account_collection[ipmi_info.AccountId]:init_ipmi_user_info(ipmi_info)
        else
            log:error('init ipmi user failed! UserID: %d do not exist.', ipmi_info.AccountId)
            ipmi_info:delete()
        end
    end)
    for account_id, _ in pairs(self.ipmi_channel_config.collection) do
        if account_collection[account_id] == nil then
            self.ipmi_channel_config:delete(account_id)
        end
    end
    self.collection = account_collection

    self.m_table_account = stmt_account.table
    self.m_table_snmp = stmt_snmp_info.table
    self.m_table_ipmi_user = ipmi_user_info.table
end

function AccountCollection:init()
    self:signals_init()
    self:init_account_collection(self.db)
    -- 防止数据库不存在ipmi用户与snmp用户信息，将这两部分数据进行初始化
    self:init_ipmi_user_info()
    self:init_default_ipmi_channels()
    -- 执行数据同步
    self:sync_and_update_ipmi_channel_config()
    self:init_snmp_user_info()

    self.m_change_unregist_handle = self.m_ipmi_crypt_password_update:on(function(...)
        self:update_ipmi_crypt_passwd_after_key_change()
    end)
end

function AccountCollection:update_ipmi_crypt_passwd_after_key_change()
    log:info("update ipmi crypt password after key change start")
    local value
    for _, account in pairs(self.collection) do
        value = account.m_account_data.IpmiPassword
        if value and #value ~= 0 then
            account:update_ipmi_crypt_passwd()
        end
    end
    log:info("update ipmi crypt password after key change finished")
end

function AccountCollection:init_ipmi_user_info()
    local ipmi_in_db
    for account_id, collection in pairs(self.collection) do
        if collection.m_ipmi_user_info_data == nil then
            ipmi_in_db = self.m_table_ipmi_user({ AccountId = account_id, Use20BytesPasswd = 1, IsCallin = 0,
                IsEnableAuth = 1, IsEnableIpmiMsg = 1, IsEnableByPasswd = enum.IpmiUserEnableByPassword.Disable,
                Privilege0 = enum.IpmiPrivilege.RESERVED,
                Privilege1 = enum.IpmiPrivilege.RESERVED })
            collection:init_ipmi_user_info(ipmi_in_db)
        end
        collection:set_ipmi_user_privilege(role_privilege_map.role_to_privilege_map[collection:get_role_id()])
    end
end

function AccountCollection:init_default_ipmi_channels()
    log:notice("Checking and inserting default IPMI channel configurations for all accounts.")
    for account_id, collection in pairs(self.collection) do
        if account_id < self.m_global_account_config:get_min_user_num() or
            account_id > self.m_global_account_config:get_max_user_num() then
            goto continue
        end
        local role_id = collection.m_account_data.RoleId
        local ok, err = pcall(function()
            local existing_channels_map = {}
            self.db:select(self.db.IpmiChannelConfig)
                :where(self.db.IpmiChannelConfig.AccountId:eq(account_id))
                :fold(function(record)
                    existing_channels_map[record.ChannelNumber] = true
                end)
            for _, channel_num in ipairs(config.DEFAULT_CHANNELS_MAP) do
                if not existing_channels_map[channel_num] then
                    local new_channel_data = {
                        AccountId = account_id,
                        ChannelNumber = channel_num,
                        CallbackRestriction = 0,
                        LinkAuthenticationEnabled = true,
                        IpmiMessagingEnabled = true,
                        PrivilegeLimit = role_privilege_map.role_to_privilege_map[role_id],
                        SessionLimit = 0
                    }
                    self.db:insert(self.db.IpmiChannelConfig):value(new_channel_data):exec()
                end
            end
        end)
        if not ok then
            log:error("An error occurred while checking/inserting channel configs for AccountId %d: %s",
                account_id, tostring(err))
        end
        ::continue::
    end
end

function AccountCollection:init_snmp_user_info()
    local kmc_cli = kmc_client.get_instance()
    for account_id, account in pairs(self.collection) do
        if account.m_snmp_user_info_data == nil and
            self.operation_type_check.LOCAL_AND_OEM[account.m_account_data.AccountType:value()] then
            local ok, snmp_passwd = pcall(kmc_cli.decrypt_password, kmc_cli, account.m_account_data.IpmiPassword)
            if not ok then
                log:error('decrypt ipmi password failed')
                snmp_passwd = ''
            end
            local snmp_in_db = self.m_table_snmp({ AccountId = account_id,
                AuthenticationProtocol = enum.SNMPAuthenticationProtocols.SHA256,
                EncryptionProtocol = enum.SNMPEncryptionProtocols.AES128,
                SNMPPassword = snmp_passwd,
                SNMPKDFPassword = snmp_passwd,
                AuthenticationKey = '',
                EncryptionKey = '' })
            account:new_account_snmp_info(snmp_in_db)
        end
    end
end

function AccountCollection:emit_init_account_signal()
    for _, account in pairs(self.collection) do
        local account_data, snmp_data = account:get_account_data()
        self.m_account_added:emit(account_data, snmp_data,
            account.m_account_update_signal, account.m_snmp_update_signal)
    end
    -- 重启后更新用户当前权限
    self:update_privileges()
    self:update_deletable()
end

-- 获取用户详细数据 by 用户ID
-- 返回的data禁止save()
function AccountCollection:get_account_data_by_id(account_id)
    if self.collection[account_id] ~= nil then
        return self.collection[account_id]:get_account_data()
    end
    return nil, nil
end

-- 获取用户详细数据 by 用户名
-- 返回的data禁止save()
function AccountCollection:get_account_data_by_name(user_name)
    for _, v in pairs(self.collection) do
        if v:get_user_name() == user_name then
            return v:get_account_data()
        end
    end
    error(custom_msg.AuthorizationFailed())
end

function AccountCollection:get_account_by_name(user_name)
    for id, account in pairs(self.collection) do
        if account:get_user_name() == user_name then
            return account, id
        end
    end
    return nil
end

function AccountCollection:get_account_by_user_name(user_name)
    for id, account in pairs(self.collection) do
        if account:get_user_name() == user_name then
            return account, id
        end
    end
    return nil, nil
end

function AccountCollection:get_ipmi_account(user_name)
    local host_sms = self.collection[config.USER_NAME_FOR_BMA_ID]
    if user_name == host_sms:get_user_name() then
        return host_sms
    elseif user_name == config.USER_NAME_FOR_HMM then
        return ipmi_account:get_hmm_user()
    else
        return nil
    end
end

function AccountCollection:get_account_by_account_id(account_id)
    if self.collection[account_id] ~= nil then
        return self.collection[account_id]
    end
    error(err.invalid_account_id())
end

function AccountCollection:record_login_time_ip(account_id, ip, flush_flag)
    if not ip then
        log:notice('record last login ip failed, ip is invalid')
        return
    end
    local cur_timestamp = os.time()
    if self.collection[account_id] == nil then
        error(err.invalid_account_id())
    end
    self.collection[account_id]:record_login_time_ip(cur_timestamp, ip, flush_flag)
    self.m_account_changed:emit(account_id, "LastLoginTime", cur_timestamp)
    self.m_account_changed:emit(account_id, "LastLoginIP", tostring(ip))
end

function AccountCollection:record_last_login_interface(account_id, interface, flush_flag)
    local ok = pcall(function()
        enum.LoginInterface.new(interface:value())
    end)
    if not ok then
        log:notice('record last login interface failed, interface : %s', tostring(interface))
        return
    end
    if self.collection[account_id] == nil then
        error(err.invalid_account_id())
    end
    self.collection[account_id]:record_last_login_interface(interface, flush_flag)
    self.m_account_changed:emit(account_id, "LastLoginInterface",
        tostring(enum.LoginInterface.new(interface:value())))
end

function AccountCollection:get_last_login_info(account_id)
    if self.collection[account_id] == nil then
        error(err.invalid_account_id())
    end
    return self.collection[account_id].m_account_data.LastLoginTime,
        self.collection[account_id].m_account_data.LastLoginIP,
        self.collection[account_id].m_account_data.LastLoginInterface
end

function AccountCollection:check_username_exist(user_name)
    for _, v in pairs(self.collection) do
        if v:get_user_name() == user_name then
            return true
        end
    end
    log:error('User name(%s) is not found', user_name)
    return false
end

-- 获取新建用户时使用的用户id，创建OEM用户时id范围有可能会在2-17以外
function AccountCollection:get_valid_account_id(account_id, account_class)
    -- 判断Id是否存在
    if self.collection[account_id] ~= nil then
        error(custom_msg.PropertyValueError('Id'))
    end
    local min_id = account_class and account_class.MIN_USER_NUM or DEFAULT_MIN_USER_NUM
    local max_id = account_class and account_class.MAX_USER_NUM or DEFAULT_MAX_USER_NUM
    -- 新建id为0的用户时，返回第一个可用id
    if account_id == 0 then
        for id = min_id, max_id do
            if not self.collection[id] then
                return id
            end
        end
        error(base_msg.CreateLimitReachedForResource())
    end
    if account_id < min_id or account_id > max_id then
        log:error('Choosing id(%d) is invalid', account_id)
        error(custom_msg.PropertyValueOutOfRange(account_id, 'AccountId'))
    end
    return account_id
end

--- 新建用户
---@param ctx table 上下文信息
---@param account_info table 新建用户的信息表
---@param is_ipmi_or_snmp boolean 是否通过IPMI或SNMP接口新建用户
--- account_info中包含用户名字、用户id、角色id、可登录的接口、首次登录策略，以及是否为定制化用户等信息
function AccountCollection:new_account(ctx, account_info, is_ipmi_or_snmp)
    if not self.account_policy_collection:check_user_name(account_info.account_type, account_info.name) then
        log:error('Invalid name(%s) is not allowed', account_info.name)
        error(custom_msg.InvalidUserName())
    end
    local role_data = self.m_rc:get_role_data_by_id(account_info.role_id)
    if not role_data then
        log:error('new account failed, unknown role id')
        error(base_msg.PropertyValueNotInList(account_info.role_id, 'RoleId'))
    end
    -- AllowedLoginInterfaces仅限制本地用户
    if not account_info.oem and
        not self.account_policy_collection:
        check_login_interface_is_allowed(account_info.account_type,
        utils.cover_interface_enum_to_num(account_info.interface)) then
        local interfaces_str = utils.interface_enum_table_to_string(account_info.interface)
        log:error('LoginInterface is illegal, interface : %s', interfaces_str)
        error(custom_msg.PropertyItemNotInList('%LoginInterface:' .. interfaces_str, '%LoginInterface'))
    end
    -- account_info中包含oem值时意味着此时新建oem用户
    local account_class = account_info.oem and oem_account or local_account
    local account_id = self:get_valid_account_id(account_info.id, account_class)
    -- web端在没有勾选任何interface时 传入的interface为nil，特殊处理
    account_info.interface = account_info.interface and account_info.interface or {}
    -- 判断当前用户名是否被占用
    if self:check_username_exist(account_info.name) then
        error(base_msg.ResourceAlreadyExists())
    end
    account_info.id = account_id
    self:new_ccount_to_db_and_mdb(ctx, account_info, account_class, is_ipmi_or_snmp, true)
    return account_id
end

function AccountCollection:new_ccount_to_db_and_mdb(ctx, account_info, account_class, is_ipmi_or_snmp,
    is_password_validator)
    log:info("start to add new account to db and mdb")
    local account_type = account_info.oem and enum.AccountType.OEM:value() or enum.AccountType.Local:value()
    -- 将新用户加入db与mdb
    local account_in_db = self.m_table_account({ Id = account_info.id, UserName = account_info.name,
        RoleId = account_info.role_id })
    local account_in_server = account_class.new(self.db, account_in_db,
        self.password_validator_collection:get_validator(account_type), self.ipmi_channel_config)
    if not is_ipmi_or_snmp and is_password_validator then
        local ok, ret = pcall(function()
            -- 第三个参数为是否初始化优化，第四个参数为是否自己修改自己密码
            account_in_server:password_validator(ctx, account_info.name, account_info.password, true, false)
        end)
        if not ok then
            log:error('check conditon set passwd failed.')
            account_in_db:delete()
            account_in_server.m_history_password:delete()
            error(ret)
        end
    end
    local snmp_in_db = self.m_table_snmp({
        AccountId = account_info.id,
        AuthenticationProtocol = enum.SNMPAuthenticationProtocols.SHA256,
        EncryptionProtocol = enum.SNMPEncryptionProtocols.AES128,
        SNMPPassword = account_info.password,
        SNMPKDFPassword = account_info.password,
        AuthenticationKey = '',
        EncryptionKey = '',
        SnmpEncryptionPasswordInitialStatus = true
    })
    account_in_server:init_account(account_info)
    account_in_server:new_account_snmp_info(snmp_in_db)
    log:info("Add new account(name:%s|id:%d) to db finished", account_info.name, account_info.id)
    local ipmi_in_db = self.m_table_ipmi_user({
        AccountId = account_info.id,
        Use20BytesPasswd = 1,
        IsCallin = 0,
        IsEnableAuth = 1,
        IsEnableIpmiMsg = 1,
        IsEnableByPasswd = enum.IpmiUserEnableByPassword.Disable,
        Privilege0 = enum.IpmiPrivilege.RESERVED,
        Privilege1 = role_privilege_map.role_to_privilege_map[account_info.role_id]
    })
    account_in_server:init_ipmi_user_info(ipmi_in_db)
    self.collection[account_info.id] = account_in_server

    local account_data, snmp_data = account_in_server:get_account_data()

    self.m_account_added:emit(account_data, snmp_data,
        account_in_server.m_account_update_signal, account_in_server.m_snmp_update_signal)
    log:info("Add new account(name:%s|id:%d) to mdb finished", account_info.name, account_info.id)
    -- 添加至历史密码
    account_in_server.m_history_password:delete()
    account_in_server.m_history_password:insert(account_data.Password, account_data.KDFPassword,
        self.m_global_account_config:get_history_password_count())
    self.collection[account_info.id]:update_privileges()

    self:new_account_channel_config_to_db_and_mdb(account_info.id, account_info.role_id)

    -- 用户名或者密码为空的情形不允许设置到Linux系统-- ipmi增加用户时不带密码
    if not utils.str_is_empty(account_info.name) and not utils.str_is_empty(account_data.Password) then
        -- 将用户设置到linux系统
        -- 调整为信号量触发，将几个关键文件的读写操作解耦
        self.m_account_file_added:emit(account_info.id)
    end

    self.collection[account_info.id]:update_inactive_user_start_time(true)
    self:update_deletable()
    -- 密码最短使用时间不为0时，新建用户受此限制
    self:update_within_min_password_days_status()
end

function AccountCollection:new_account_channel_config_to_db_and_mdb(account_id, role_id)
    if account_id < self.m_global_account_config:get_min_user_num() or
        account_id > self.m_global_account_config:get_max_user_num() then
        return
    end
    local ipmi_channel_config_db = {}
    for _, channel_num in ipairs(config.DEFAULT_CHANNELS_MAP) do
        ipmi_channel_config_db.AccountId = account_id
        ipmi_channel_config_db.ChannelNumber = channel_num
        ipmi_channel_config_db.PrivilegeLimit = role_privilege_map.role_to_privilege_map[role_id]
        ipmi_channel_config_db.SessionLimit = 0
        ipmi_channel_config_db.CallbackRestriction = 0
        ipmi_channel_config_db.IpmiMessagingEnabled = true
        ipmi_channel_config_db.LinkAuthenticationEnabled = true
        self.ipmi_channel_config:insert(ipmi_channel_config_db, 0)
    end
end

function AccountCollection:change_snmp_v3_trap_account(delete_id)
    local change_id = config.MAX_INVALID_USER_ID
    local account_id
    for _, account in pairs(self.collection) do
        account_id = account.m_account_data.Id
        if ((account:check_is_enabled_admin() and account:get_password_valid_time() ~= 0) or
            self:check_is_emergency_user(account_id)) and
            account_id ~= delete_id and
            account_id <= change_id then
                change_id = account_id
        end
    end
    if not self.collection[change_id] then
        log:error('No valid account to be changed to snmp v3 trap account.')
            error(custom_msg.AccountForbidRemoved())
    end
    self.m_global_account_config:set_snmp_v3_trap_account(change_id)
end

--- 删除用户
---@param ctx table 上下文信息
---@param account_id number 用户ID
---@param validation_skipped boolean 是否是空定制化删除用户，若是，需要跳过部分校验来达到清除用户的效果
function AccountCollection:delete_account(ctx, account_id, validation_skipped)
    utils.queue(function()
        ctx.operation_log.params.id = account_id
        local account = self.collection[account_id]
        if not account then
            error(err.invalid_account_id())
        end
        ctx.operation_log.params.name = account:get_user_name()
        if not account:get_property_writable('UserNameWritable') then
            log:error('Delete account failed, account (user%d) is not writable.', account_id)
            error(custom_msg.AccountForbidRemoved())
        end
        if self:check_is_emergency_user(account_id) then
            log:error('Delete account failed, account (user%d) is emergency user.', account_id)
            error(custom_msg.AccountForbidRemoved())
        end
        if self:check_is_last_enabled_admin(account_id) then
            log:error('Delete account failed, account (user%d) is last enabled admin.', account_id)
            error(custom_msg.CannotDeleteLastAdministrator())
        end
        if account_id == self.m_global_account_config:get_snmp_v3_trap_account_id() and
            self.m_global_account_config:get_snmp_v3_trap_account_change_policy() == 0 and
            self.m_global_account_config:get_snmp_v3_trap_account_limit_policy() ~=
                enum.SNMPv3TrapAccountLimitPolicy.Modifiable:value() then
                log:error('Delete account failed, account (user%d) is snmp v3 trap account.', account_id)
                error(custom_msg.AccountForbidRemoved())
        elseif account_id == self.m_global_account_config:get_snmp_v3_trap_account_id() and
            self.m_global_account_config:get_snmp_v3_trap_account_change_policy() == 1 then
                self:change_snmp_v3_trap_account(account_id)
        end

        --判断该类型用户是否可被删除account_policy中的Deletable属性
        if not validation_skipped and
            not self.account_policy_collection:get_deletable(account.m_account_data.AccountType:value()) then
            log:error('Delete account failed, account (user%d) is not deletable.', account_id)
            error(custom_msg.AccountForbidRemoved())
        end

        local username = account:get_user_name()

        -- 清除历史密码
        account.m_history_password:delete()
        -- 清除通道配置
        self.ipmi_channel_config:delete(account_id)
        -- 将用户从db与mbd移除
        account.m_account_data:delete()
        account.m_snmp_user_info_data:delete()
        account.m_ipmi_user_info_data:delete()

        self.collection[account_id] = nil
        -- 将用户从linux系统移除
        -- 调整为信号量触发，将几个关键文件的读写操作解耦
        self.m_account_file_flush:emit()
        self.m_account_removed:emit(account_id, username)
        self:update_deletable()
        -- 删除账户后的信息清理(直接清理文件)
        file_proxy.proxy_delete(config.PAM_TALLY_LOG_DIR .. username)
        -- 删除客户端证书
        self:_delete_cert(ctx, account_id)
    end)
end

function AccountCollection:force_delete_account(ctx, account_id)
    local account = self.collection[account_id]
    local username = account:get_user_name()
    -- 将用户从linux系统移除
    -- 调整为信号量触发，将几个关键文件的读写操作解耦
    self.m_account_file_removed:emit(account_id)
    -- 清除历史密码
    account.m_history_password:delete()
    -- 将用户从db与mbd移除
    account.m_account_data:delete()
    account.m_snmp_user_info_data:delete()
    account.m_ipmi_user_info_data:delete()
    self.collection[account_id] = nil
    self.m_account_removed:emit(account_id, username)
    self:update_deletable()
    -- 删除账户后的信息清理
    core.reset_pam_tally(username, config.PAM_TALLY_LOG_DIR)
    -- 删除客户端证书
    self:_delete_cert(ctx, account_id)
end

function AccountCollection:set_login_interface(ctx, account_id, interface)
    local account = self.collection[account_id]
    if not account then
        error(err.invalid_account_id())
    end
    local user_name = account:get_user_name()
    ctx.operation_log.params.username = 'user(' .. user_name .. '|user'..account_id..')'
    if not utils.check_interface_info(interface) then
        log:error('LoginInterface is illegal!')
        error(custom_msg.PropertyItemNotInList('%LoginInterface:' .. table.concat(interface, " "), '%LoginInterface'))
    end
    -- 判断本地2-17用户要开启的登录接口是否在AllowedLoginInterfaces内
    local interface_num = utils.cover_interface_str_to_num(interface)
    local account_type = account:get_account_type():value()
    if account_type == enum.AccountType.Local:value() and
        not self.account_policy_collection:check_login_interface_is_allowed(account_type, interface_num) then
        log:error('LoginInterface is illegal, interface : %s', table.concat(interface, ', '))
        error(custom_msg.PropertyItemNotInList('%LoginInterface:' .. table.concat(interface, " "), '%LoginInterface'))
    end
    -- 判断要取消ipmi接口
    if account:is_delete_ipmi_interface(interface_num) then
        -- 清掉ipmi密码， ipmi密码设为空
        account.m_account_data.IpmiPassword = ""
        account.m_account_data:save()
    end
    account:set_login_interface(interface_num)
    self.m_account_ipmi_changed:emit(account_id)
    self.m_account_security_changed:emit(account_id, user_name)
    self.m_account_permanent_changed:emit(account_id, "LoginInterface")
end

function AccountCollection:get_login_interface(account_id)
    if self.collection[account_id] == nil then
        error(err.invalid_account_id())
    end
    return self.collection[account_id]:get_login_interface()
end

function AccountCollection:get_login_rule_ids(account_id)
    if self.collection[account_id] == nil then
        error(err.invalid_account_id())
    end
    return self.collection[account_id]:get_login_rule_ids()
end

function AccountCollection:set_login_rule_ids(ctx, account_id, login_rule_ids)
    local account = self.collection[account_id]
    local RO_COMMUNITY_ID = 20
    ctx.operation_log.params = { rule = table.concat(login_rule_ids, " ") }
    if not account then
        error(err.invalid_account_id())
    end
    local user_name = account:get_user_name()
    ctx.operation_log.params.username = account_id == RO_COMMUNITY_ID and 'SNMP Community string' or
        'user(' .. user_name .. '|user'..account_id..')'
    utils.check_login_rule_ids(login_rule_ids)
    local login_rule_ids_num = utils.covert_login_rule_ids_str_to_num(login_rule_ids)
    local old_permit_rule_num = self:get_login_rule_ids(account_id)
    account:set_login_rule_ids(login_rule_ids_num)
    self.m_account_ipmi_changed:emit(account_id)

    local new_permit_rule_num = self:get_login_rule_ids(account_id)
    local change = utils.get_login_interface_or_rule_ids_change(old_permit_rule_num,
        new_permit_rule_num, utils.covert_num_to_login_rule_ids_str)
    if not change then
        ctx.operation_log.operation = 'SkipLog'
    end
    ctx.operation_log.params.change = change
end

function AccountCollection:set_role_id(ctx, account_id, role_id, ipmi_privilege)
    local account = self.collection[account_id]
    if not account then
        error(err.invalid_account_id())
    end
    ctx.operation_log.params.name = account:get_user_name()
    ctx.operation_log.params.id = account:get_id()
    if not utils.check_role_id_info(role_id) then
        ctx.operation_log.params.role = 'Unknown'
        log:error('role id is illegal!')
        error(base_msg.PropertyValueNotInList('%RoleId:' .. 'Unknown', '%RoleId'))
    end
    local role_name = self.m_rc:get_role_name_by_id(role_id)
    if not role_name then
        ctx.operation_log.params.role = 'Unknown'
        log:error('role id is illegal!')
        error(base_msg.PropertyValueNotInList('%RoleId:' .. 'Unknown', '%RoleId'))
    end
    ctx.operation_log.params.role = role_name
    if enum.RoleType.Administrator:value() ~= role_id and self:check_is_last_enabled_admin(account_id) then
        ctx.operation_log.result = 'exclude_user_or_last_admin'
        log:error('Set RoleId failed, account (user%d) is last enabled admin.', account_id)
        error(base_msg.AccountNotModified())
    end
    if self:check_is_emergency_user(account_id) then
        ctx.operation_log.result = 'exclude_user_or_last_admin'
        log:error('Set RoleId failed, account (user%d) is emergency login user.', account_id)
        error(custom_msg.EmergencyLoginUser('RoleId'))
    end
    local userName = account:get_user_name()
    local privilege = ipmi_privilege or role_privilege_map.role_to_privilege_map[role_id]
    self.collection[account_id]:set_role_id(role_id)
    self.collection[account_id]:set_ipmi_user_privilege(privilege)
    -- 单通道场景下将通道权限与用户权限绑定
    local ipmi_channel_config_list
    if self.ipmi_channel_mappings.multi_channel_status == 0 and
        account_id >= self.m_global_account_config:get_min_user_num() and
        account_id <= self.m_global_account_config:get_max_user_num() then
        ipmi_channel_config_list = self.ipmi_channel_config:get(account_id, 1)
        ipmi_channel_config_list.PrivilegeLimit = privilege
        self.ipmi_channel_config.m_channel_config_changed:emit(account_id, 1, "PrivilegeLimit", privilege)
    end    
    self.m_account_changed:emit(account_id, "RoleId", role_id)
    self.m_account_permanent_changed:emit(account_id, "RoleId")
    self.m_account_security_changed:emit(account_id, userName)
    self:update_deletable()
    -- 调整为信号量触发，将几个关键文件的读写操作解耦
    self.m_account_file_changed:emit(account_id, userName)
end

-- IPMI与SNMP接口可以通过设置用户名来新建用户
local function ipmi_and_snmp_new_account(self, ctx, account_id, user_name)
    if ctx.Interface == nil then
        ctx.operation_log.operation = 'IpmiNewAccount'
    end
    local account_type = enum.AccountType.Local:value()
    -- 用户名特殊字符校验下沉
    if not self.account_policy_collection:check_user_name(account_type, user_name) then
        error(custom_msg.IPMIInvalidFieldRequest())
    end
    -- 判断用户是否已经存在
    if self:is_other_user_has_the_same_name(account_id, user_name) then
        error(base_msg.ResourceAlreadyExists())
    end
    -- 新增加用户,密码、角色采用默认值
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.SFTP, enum.LoginInterface.Web,
        enum.LoginInterface.SSH, enum.LoginInterface.Redfish, enum.LoginInterface.Local,
        enum.LoginInterface.SNMP }
    -- 如果当前限制了用户允许开启的登录接口(接口数<7), 机机接口新建用户登录接口使用AllowedLoginInterfaces支持的范围
    local allowed_login_interfaces = self.account_policy_collection:get_allowed_login_interfaces(account_type)
    if allowed_login_interfaces < config.DEFAULT_INTERFACES then
        interface = utils.convert_num_to_interface_str(allowed_login_interfaces)
    end
    local account_info = {
        ['id'] = account_id,
        ['name'] = user_name,
        ['password'] = '',
        ['role_id'] = enum.RoleType.NoAccess:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = account_type
    }
    -- 新建用户，第三个参数为true代表当前为IPMI与SNMP新建用户
    self:new_account(ctx, account_info, true)
    self:set_enabled(account_id, false)
    self.m_account_changed:emit(account_id, "Enabled", false)
    self.m_account_permanent_changed:emit(account_id, "Enabled")
end

function AccountCollection:set_user_name(ctx, account_id, user_name)
    ctx.operation_log.params = { id = account_id, name = user_name }
    utils.check_ipmi_account_id(account_id)
    local old_user_name = ''
    if self:check_user_id_exist(account_id) then
        old_user_name = self:get_user_name(account_id)
    end

    if old_user_name == '' and user_name ~= '' then
        ipmi_and_snmp_new_account(self, ctx, account_id, user_name)
    elseif old_user_name ~= '' and user_name ~= '' then
        ctx.operation_log.operation = 'ChangeUserName'
        ctx.operation_log.params.oldName = old_user_name
        -- 用户名特殊字符校验下沉
        if not self.account_policy_collection:check_user_name(enum.AccountType.Local:value(), user_name) then
            error(custom_msg.InvalidUserName())
        end
        -- 判断用户是否已经存在
        if self:is_other_user_has_the_same_name(account_id, user_name) then
            error(base_msg.ResourceAlreadyExists())
        end
        -- 判断SNMPTrapAccountChangePolicy是否为0，为0则保持原有策略
        if self.m_global_account_config:get_snmp_v3_trap_account_change_policy() == 0 then
            -- 装备定制化需要设置管理员用户名，跳过trap的限制
            if not core.is_manufacture_mode() and
                account_id == self.m_global_account_config:get_snmp_v3_trap_account_id() and
                self.m_global_account_config:get_snmp_v3_trap_account_limit_policy() ==
                    enum.SNMPv3TrapAccountLimitPolicy.NotModifiable:value() then
                log:error('Change account name failed, account (user%d) is snmp v3 trap account.', account_id)
                error(custom_msg.SNMPV3TrapUserNameCannotBeChanged())
            end
        end
        -- 修改用户
        self:change_user_name(account_id, user_name)
        self.m_account_changed:emit(account_id, "UserName", user_name)
        self.m_account_permanent_changed:emit(account_id, "UserName")
    elseif old_user_name ~= '' and user_name == '' then
        ctx.operation_log.operation = 'IpmiDeleteAccount'
        -- 删除用户
        self:delete_account(ctx, account_id)
    else
        -- 新旧名字都为空，这种场景不用报错，但是需要跳过打日志的操作
        ctx.operation_log.operation = 'SkipLog'
    end
end

function AccountCollection:change_user_name(account_id, user_name)
    if self.collection[account_id] == nil then
        error(err.invalid_account_id())
    end
    local account_type = self.collection[account_id]:get_account_type():value()
    if not self.account_policy_collection:check_user_name(account_type, user_name) then
        error(custom_msg.InvalidUserName())
    end
    local old_username = self.collection[account_id]:get_user_name()
    self.collection[account_id]:set_user_name(user_name)
    self.m_account_security_changed:emit(account_id, old_username)
    self.m_account_permanent_changed:emit(account_id, "UserName")
    local account = self.collection[account_id]
    -- 用户名修改，涉及到Linux账户修改，采用先删除再增加,当用户名及密码都设置后才允许将用户设置到Linux系统
    if not utils.str_is_empty(user_name) and not utils.str_is_empty(account.m_account_data.Password) then
        -- 将用户设置到linux系统
        -- 调整为信号量触发，将几个关键文件的读写操作解耦
        self.m_account_file_changed:emit(account_id, old_username)
    end
    local la = linux_account.new(self.linux_files, false)
    local home_path = la.home_dir:get(self.collection[account_id]:get_user_name())
    self.collection[account_id]:delete_ssh_public_key(home_path)

    account:update_inactive_user_start_time(true)
end

function AccountCollection:get_user_name(account_id)
    if account_id < self.m_global_account_config:get_min_user_num() or
        account_id > self.m_global_account_config:get_max_user_num() or
        self.collection[account_id] == nil then
        log:error("User id is illegal")
        error(err.invalid_data_field())
    end

    return self.collection[account_id]:get_user_name()
end

function AccountCollection:set_account_password(ctx, handler_account_id, account_id, pwd)
    local account = self.collection[account_id]
    if account == nil then
        log:error('account id [%d:%d] do not exist.', handler_account_id, account_id)
        ctx.operation_log.params.ret = err_cfg.USER_DONT_EXIST
        error(base_msg.InternalError())
    end
    account:password_validator(ctx, account:get_user_name(), pwd, false, handler_account_id == account_id)
    account:set_account_password(pwd, handler_account_id == account_id)
    self.m_account_security_changed:emit(account_id, account:get_user_name())
    self.m_account_permanent_changed:emit(account_id, "Password")
    -- 用户密码修改，涉及到Linux账户修改，采用先删除再增加
    if not utils.str_is_empty(account:get_user_name()) and
        not utils.str_is_empty(account.m_account_data.Password) then

        -- 调整为信号量触发，将几个关键文件的读写操作解耦
        self.m_account_file_changed:emit(account_id)
    end
    self:update_within_min_password_days_status()
end

-- 设置snmp加密密码
function AccountCollection:set_user_snmp_pwd(ctx, account_id, pwd)
    local account = self.collection[account_id]
    if not account then
        log:error('account id %d do not existt.', account_id)
        error(err.invalid_account_id())
    end
    account:check_conditions_set_snmp_passwd(ctx, pwd)
    account:set_user_snmp_pwd(pwd)
end

-- 设置鉴权算法属性
function AccountCollection:set_user_auth_protocol(account_id, auth_protocol)
    local account = self.collection[account_id]
    if not account then
        error(err.invalid_account_id())
    end
    -- 加密算法需要与鉴权算法对应:AES256仅只能搭配SHA256/SHA384/SHA512
    local encrypt_protocol = account.m_snmp_user_info_data.EncryptionProtocol
    local aes = enum.SNMPEncryptionProtocols.AES256
    if encrypt_protocol == aes and auth_protocol:value() < 4 then -- 4 为SHA256算法
        log:error('privacy protocol is AES256, auth protocol should be SHA256/SHA384/SHA512')
        error(custom_msg.PrivProtocolAes256NeedMatch())
    end
    account:set_user_auth_protocol(auth_protocol)
    self.m_snmp_info_changed:emit(account_id, "AuthenticationProtocol", auth_protocol:value())
end

-- 设置加密算法属性
function AccountCollection:set_user_encrypt_protocol(account_id, encrypt_protocol)
    local account = self.collection[account_id]
    if not account then
        error(err.invalid_account_id())
    end
    -- 加密算法需要与鉴权算法对应:AES256仅只能搭配SHA256/SHA384/SHA512
    local auth_protocol = account.m_snmp_user_info_data.AuthenticationProtocol:value()
    local aes = enum.SNMPEncryptionProtocols.AES256
    if encrypt_protocol == aes and auth_protocol < 4 then -- 4 为SHA256算法
        log:error('privacy protocol is AES256, auth protocol should be SHA256/SHA384/SHA512')
        error(custom_msg.PrivProtocolAes256NeedMatch())
    end
    self.collection[account_id]:set_user_encrypt_protocol(encrypt_protocol)
    self.m_snmp_info_changed:emit(account_id, "EncryptionProtocol", encrypt_protocol:value())
end

function AccountCollection:set_enabled(account_id, status)
    local account = self.collection[account_id]
    if not status and self:check_is_last_enabled_admin(account_id) then
        log:error('Disable account failed, account (user%d) is last enabled admin.', account_id)
        error(custom_msg.CannotDisableLastAdministrator())
    end
    if not status and self:check_is_emergency_user(account_id) then
        log:error('Disable account failed, account (user%d) is emergency login user.', account_id)
        error(custom_msg.EmergencyLoginUser('Enabled'))
    end
    local ret = account:set_enabled(status)
    self.m_account_ipmi_changed:emit(account_id)
    if status then
        account:update_inactive_user_start_time(true)
    end
    -- 修改属性后踢出会话
    self.m_account_security_changed:emit(account_id, account:get_user_name())
    return ret
end

function AccountCollection:set_password_change_required(account_id, required)
    if self.collection[account_id] == nil then
        error(err.invalid_account_id())
    end
    self.collection[account_id]:set_password_change_required(required)
end

function AccountCollection:set_first_login_policy(ctx, account_id, policy)
    if self.collection[account_id] == nil then
        error(err.invalid_account_id())
    end
    local account = self.collection[account_id]
    ctx.operation_log.params.name = account:get_user_name()
    if policy ~= enum.FirstLoginPolicy.PromptPasswordReset:value() and
        policy ~= enum.FirstLoginPolicy.ForcePasswordReset:value() then
        ctx.operation_log.params.policy = 'illegal policy'
        log:error("invalid first_login_policy: %d", policy)
        error(base_msg.PropertyValueNotInList('%FirstLoginPolicy:' .. 'Unknown', '%FirstLoginPolicy'))
    end
    ctx.operation_log.params.policy = policy == enum.FirstLoginPolicy.PromptPasswordReset:value() and
        'prompt' or 'force'
    self.collection[account_id]:set_first_login_policy(policy)
    self.collection[account_id]:update_privileges()
end

function AccountCollection:get_first_login_policy_by_id(id)
    local account = self:get_account_by_account_id(id)
    return account:get_first_login_policy()
end

--- 检查是否为逃生用户
---@param account_id number
---@return boolean
function AccountCollection:check_is_emergency_user(account_id)
    local emergency_user_id = self.m_global_account_config:get_emergency_account()
    return account_id == emergency_user_id
end

--- 检查是否为最后一个使能的管理员
---@param account_id number
---@return boolean
function AccountCollection:check_is_last_enabled_admin(account_id)
    local enabled_admin_num = self:get_enabled_admin_number()
    if enabled_admin_num > 1 then
        return false
    end
    -- 如果当前用户为仅有的使能的管理员
    if enabled_admin_num <= 1 and self.collection[account_id]:check_is_enabled_admin() then
        return true
    end
    return false
end

function AccountCollection:ipmi_set_user_access_input_check(req, ctx)
    local privilege = req.UserPrivilege
    local channel_number = (req.ChannelNumber == enum.IpmiChannel.PRSENT_CHAN_NUM:value() and
        ctx.chan_num or req.ChannelNumber)
    local account_id = req.UserId
    ctx.operation_log.params.channel_number = channel_number
    if privilege == 0 or
        ((privilege > enum.IpmiPrivilege.OEM:value()) and
            (privilege ~= enum.IpmiPrivilege.NO_ACCESS:value())) then
        log:error("privilege is error")
        ctx.operation_log.params.privilege = "illegal level"
        ctx.operation_log.result = 'no_user'
        error(custom_msg.IPMIOutOfRange())
    end
    ctx.operation_log.params.privilege = role_privilege_map.privilege_to_string_map[privilege]

    utils.check_ipmi_account_id(account_id)
    if not self.collection[account_id] then
        ctx.operation_log.result = 'no_user'
        error(custom_msg.IPMIOutOfRange())
    end
    ctx.operation_log.params.name = self:get_user_name(account_id)
    ctx.operation_log.params.id = account_id

    -- 通道校验
    channel_number = self.ipmi_channel_mappings:channel_number_translation(channel_number)
    if not channel_number then
        log:error("channel number(%s) is invalid", channel_number)
        error(custom_msg.IPMICommandCannotExecute())
    end
    local flag = 0
    for _, chan_num in ipairs(config.DEFAULT_CHANNELS_MAP) do
        if channel_number == chan_num then
            flag = 1
            break
        end
    end
    if flag == 0 then
        log:error("channel number(%s) is invalid", channel_number)
        error(custom_msg.IPMICommandCannotExecute())
    end
    -- 单通道场景下仅支持LAN1
    if self.ipmi_channel_mappings.multi_channel_status == 0 and
        channel_number ~= enum.IpmiChannel.LAN1_CHAN_NUM:value() then
        log:error("channel number(%s) is invalid", channel_number)
        error(custom_msg.IPMICommandCannotExecute())
    end
    if not req.SessionLimit or req.SessionLimit == "" then
        req.SessionLimit = string.pack(">B", 0)
    end
    if #req.SessionLimit ~= 0 and string.unpack(">B", req.SessionLimit) > 15 then
        log:error("sessionlimit is out of range")
        error(custom_msg.IPMIOutOfRange())
    end
end

function AccountCollection:check_ipmi_host_user_mgnt_enabled(ctx)
    local is_mgmt_enable = self.m_global_account_config:check_ipmi_host_user_mgnt_enabled(ctx)
    if is_mgmt_enable then
        log:debug("Check host user management success")
        return
    end
    log:error("Check host user management failed, channel_num: %s", ctx.chan_num)
    if ctx.operation_log then
        ctx.operation_log.result = 'user_mgnt_disabled'
    end
    error(err.host_user_management_diabled())
end

function AccountCollection:ipmi_set_user_access_restricted_scene_check(req, ctx)
    local privilege = req.UserPrivilege
    local account_id = req.UserId
    ctx.operation_log.params.id = account_id
    ctx.operation_log.params.privilege = role_privilege_map.privilege_to_string_map[privilege]
    -- 判断是否禁用带内用户管理
    self:check_ipmi_host_user_mgnt_enabled(ctx)
end

function AccountCollection:set_ipmi_user_access(req, ctx)
    self:ipmi_set_user_access_input_check(req, ctx)
    self:ipmi_set_user_access_restricted_scene_check(req, ctx)
    local account_id = req.UserId
    self.collection[account_id]:set_ipmi_user_access(req, ctx)
    -- 单通道场景下需要设置用户角色
    if self.ipmi_channel_mappings.multi_channel_status == 0 then
        local role_id = role_privilege_map.privilege_to_role_map[req.UserPrivilege]
        self:set_role_id(ctx, account_id, role_id, req.UserPrivilege)
        self.m_account_changed:emit(account_id, "RoleId", role_id)
    end    
end

function AccountCollection:get_enabled_user()
    local enabled = 0
    for _, value in pairs(self.collection) do
        if value:get_enabled() == true then
            enabled = enabled + 1
        end
    end
    return enabled
end

function AccountCollection:get_ipmi_user_access(user_id, chan_num)
    local rsp = nil
    if self.collection[user_id] == nil then
        rsp = self:get_ipmi_empty_user_access()
    else
        rsp = self.collection[user_id]:get_ipmi_user_access(user_id, chan_num)
    end
    return rsp
end

function AccountCollection:set_ipmi_user_use_20bytes_passwd(account_id, passwordlen)
    if self.collection[account_id] == nil then
        error(err.invalid_account_id())
    end
    self.collection[account_id]:set_ipmi_user_use_20bytes_passwd(passwordlen)
end

function AccountCollection:check_user_id_exist(account_id)
    if self.collection[account_id] == nil then
        return false
    else
        return true
    end
end

function AccountCollection:is_other_user_has_the_same_name(account_id, user_name)
    if user_name == '' then
        return false
    end
    for key, v in pairs(self.collection) do
        if key ~= account_id and v:get_user_name() == user_name then
            return true
        end
    end
    return false
end

function AccountCollection:check_password_valid_days()
    local max_password_valid_days = self.m_global_account_config:get_max_password_valid_days()
    local remain_days
    if max_password_valid_days == 0 then
        for id, account in pairs(self.collection) do
            if not self.operation_type_check.LOCAL_OR_VNC[account.m_account_data.AccountType:value()] then
                goto continue
            end
            account:update_password_expire_status(false)
            remain_days = account:calculate_password_valid_time()
            account:set_password_valid_time(remain_days)
            self.m_account_changed:emit(id, "PasswordExpiration", remain_days)
            ::continue::
        end
        return
    end

    local timestamp = os.time()
    for id, account in pairs(self.collection) do
        if not self.operation_type_check.LOCAL_OR_VNC[account.m_account_data.AccountType:value()] or
            self:check_is_emergency_user(id) then
            goto continue
        end
        remain_days = account:calculate_password_valid_time()
        -- 密码过期后强制用户修改密码并限制用户权限
        if remain_days <= 0 then
            account:update_password_expire_status(true)
            log:security("User (%s): password has expired", account:get_user_name())
            log:notice("User(%d) password has expired, valid start time : %s, current time : %s", id,
                account:get_password_valid_start_time(), timestamp)
        else
            account:update_password_expire_status(false)
        end
        account:set_password_valid_time(remain_days)
        self.m_account_changed:emit(id, "PasswordExpiration", remain_days)
        ::continue::
    end
end

function AccountCollection:update_within_min_password_days_status()
    local min_passwd_valid_days = self.m_global_account_config:get_min_password_valid_days()
    if min_passwd_valid_days == 0 then
        for _, account in pairs(self.collection) do
            account:set_within_min_password_days_status(false)
        end
        return
    end
    local limit = min_passwd_valid_days * config.DAY_SECOND_COUNT
    local timestamp = vos_utils.vos_get_cur_time_stamp()

    for _, account in pairs(self.collection) do
        if timestamp > account:get_password_valid_start_time() + limit then
            account:set_within_min_password_days_status(false)
        else
            account:set_within_min_password_days_status(true)
        end
    end
end

-- 更新所有用户的不活跃状态
function AccountCollection:update_inactive_status()
    local inactive_user_threshold = self.m_global_account_config:get_inactive_time_threshold()
    -- 禁用不活跃用户功能未开启(天数为0),不进行检查
    if inactive_user_threshold == 0 then
        log:debug("Don't need to disable users, Inactive user checking is disabled.")
        return
    end

    local limit = inactive_user_threshold * config.DAY_SECOND_COUNT
    local enabled_admin_num
    for _, account in pairs(self.collection) do
        enabled_admin_num = self:get_enabled_admin_number()
        account:update_inactive_status(enabled_admin_num == 1, limit)
    end
end

-- 定时写用户活动记录到flash
function AccountCollection:flash_user_inactive_start_time()
    local inactive_user_threshold = self.m_global_account_config:get_inactive_time_threshold()
    -- 如果禁用不活跃用户功能未开启则不写flash
    if inactive_user_threshold == 0 then
        log:debug('Inactive user checking is disabled.')
        return
    end
    for _, account in pairs(self.collection) do
        account:set_inactive_start_time(nil, true)
    end
end

function AccountCollection:flash_login_record()
    for _, account in pairs(self.collection) do
        if account.login_record_flush_flag then
            account:record_login_time_ip(nil, nil, true)
            account:record_last_login_interface(nil, true)
        end
    end
end

--- 设置指定用户密码起始时间
---@param timediff any
function AccountCollection:set_password_valid_start_time(account_id, timediff)
    self.collection[account_id]:set_password_valid_start_time(timediff)
end

---更新所有用户密码起始时间
---@param timediff number
function AccountCollection:update_all_password_valid_start_time(timediff)
    local cur_timestamp = vos_utils.vos_get_cur_time_stamp()
    local old_start_time
    for _, account in pairs(self.collection) do
        old_start_time = account:get_password_valid_start_time()
        cur_timestamp = timediff and timediff + old_start_time or cur_timestamp
        account:set_password_valid_start_time(cur_timestamp)
    end
end

---更新所有用户不活跃起始时间
---@param timediff number
function AccountCollection:update_inactive_start_time(timediff)
    local cur_timestamp = os.time()
    local threshold = self.m_global_account_config:get_inactive_time_threshold()
    -- 判断禁用不活跃用户功能是否开启, 0为未开启
    if threshold == 0 then
        log:debug('Skip update inactive time because inactive user checking is disabled.')
        return
    end

    local flash_flag = (not timediff or timediff < 0) and {true} or {false}
    local old_start_time
    for _, account in pairs(self.collection) do
        old_start_time = account:get_inactive_start_time()
        if type(old_start_time) == 'number' then
            cur_timestamp = timediff and timediff + old_start_time or cur_timestamp
            account:set_inactive_start_time(cur_timestamp, flash_flag[1])
        end
    end
end

function AccountCollection:enable_user_operation(account_id, enable)
    local ok, err = pcall(function()
        self:set_enabled(account_id, enable)
    end)
    if not ok then
        if err.name == custom_msg.InvalidPasswordMessage.Name then
            return err_cfg.USER_SET_PASSWORD_EMPTY
        elseif err.name == custom_msg.PasswordComplexityCheckFailMessage.Name then
            return err_cfg.USER_PASS_COMPLEXITY_FAIL
        elseif err.name == custom_msg.CannotDisableLastAdministratorMessage.Name then
            return err_cfg.UNKNOWN
        end
    end
    self.m_account_changed:emit(account_id, "Enabled", enable)
    self.m_account_permanent_changed:emit(account_id, "Enabled")
    return err_cfg.USER_OPER_SUCCESS
end

function AccountCollection:clean_all_user_lock_state()
    for _, account in pairs(self.collection) do
        local username = account:get_user_name()
        core.reset_pam_tally(username, config.PAM_TALLY_LOG_DIR)
    end
end

function AccountCollection:clean_unlock_user_lock_state()
    for _, account in pairs(self.collection) do
        local username = account:get_user_name()
        if account:get_account_status() == enum.UserLocked.USER_UNLOCK then
            core.reset_pam_tally(username, config.PAM_TALLY_LOG_DIR)
        end
    end
end

--- 检查用户登录规则
---@param account_id number
---@param ip string
function AccountCollection:check_login_rule(account_id, ip)
    if self:check_is_emergency_user(account_id) then
        return true
    end
    return self.collection[account_id]:check_login_rule(ip)
end

--- 获取用户snmpv3加密密码初始状态
---@param account_id number
function AccountCollection:get_account_snmp_privacy_pwd_init_status(account_id)
    local _, snmpInfo = self.collection[account_id]:get_account_data()
    return snmpInfo.SnmpEncryptionPasswordInitialStatus
end

--- 设置用户snmpv3加密密码初始状态
---@param account_id number
---@param status boolean
function AccountCollection:set_account_snmp_privacy_pwd_init_status(account_id, status)
    local account = self.collection[account_id]
    account:set_account_snmp_privacy_pwd_init_status(status)
    self.m_snmp_info_changed:emit(account_id, 'SnmpEncryptionPasswordInitialStatus', status)
end

--- 导入SSH公钥
---@param account_id number
---@param path string
function AccountCollection:import_ssh_public_key(ctx, account_id, path)
    local key_temp_file_path = table.concat({ config.SSH_PUBLIC_KEY_CONF_TEMP_FILE, '_', account_id })
    local hash_temp_file_path = table.concat({ config.SSH_PUBLIC_KEY_HASH_TEMP_FILE, '_', account_id })
    -- 导入路径校验
    if not utils.check_import_path(path, config.SHM_TMP_PATH) then
        log:error('file path is illegal!')
        error(custom_msg.PublicKeyImportFailed())
    end

    local la = linux_account.new(self.linux_files, false)
    local uid, gid = la:get_uid_gid(account_id, self.collection[account_id]:get_role_id())
    local home_path = la.home_dir:get(self.collection[account_id]:get_user_name())

    local ok, rsp = pcall(function()
        self.collection[account_id]:import_ssh_public_key(path, home_path, uid, gid)
    end)
    file_proxy.proxy_delete(path)
    file_proxy.proxy_delete(key_temp_file_path)
    file_proxy.proxy_delete(hash_temp_file_path)
    if not ok then
        error(rsp)
    end
end

--- 删除公钥
---@param account_id number
function AccountCollection:delete_ssh_public_key(ctx, account_id)
    local la = linux_account.new(self.linux_files, false)
    local home_path = la.home_dir:get(self.collection[account_id]:get_user_name())
    local ssh_path = table.concat({ home_path, config.SSH_PUBLIC_KEY_SUB_DIR_NAME }, '/')
    -- 公钥不存在, 删除失败
    if not vos_utils.get_file_accessible(ssh_path) then
        error(custom_msg.PublicKeyNotExist())
    end

    self.collection[account_id]:delete_ssh_public_key(home_path)
end

--- 更新所有用户的历史密码表
function AccountCollection:update_history_password_list()
    for _, account in pairs(self.collection) do
        account.m_history_password:update(account.m_account_data.Password, account.m_account_data.KDFPassword,
            self.m_global_account_config:get_history_password_count())
    end
end

--- 更新所有用户的当前拥有权限
function AccountCollection:update_privileges()
    for _, account in pairs(self.collection) do
        account:update_privileges()
    end
end

--- 角色移除后更新对应用户角色为CommonUser
function AccountCollection:update_role_after_removed(ctx, role_id)
    for account_id, account in pairs(self.collection) do
        if account:get_role_id() ~= role_id then
            goto continue
        end
        local common_user_id = enum.RoleType.CommonUser:value()
        ctx.operation_log.params = {}
        local ok, result = pcall(self.set_role_id, self, ctx, account_id, common_user_id)
        if not ok then
            log:error('update user(%d)\'s role to common user failed, err : %s', account_id, result)
        end
        ::continue::
    end
end

--- 更新用户是否可被删除
function AccountCollection:update_deletable()
    local enabled_admin_num = self:get_enabled_admin_number()

    for _, account in pairs(self.collection) do
        -- 用户集合是否只有一个使能用户作为参数传入，Account内部使用
        account:update_deletable(enabled_admin_num == 1)
    end
end

-- 用户不存在也要返回权限信息。用于开源标准组合命令ipmi user list
function AccountCollection:get_ipmi_empty_user_access()
    local rsp = ipmi_cmds.GetUserAccess.rsp.new()
    rsp.MaxUserNumber = self.m_global_account_config:get_max_user_num()
    rsp.Reserved = 0
    rsp.EnableStatus = 0
    rsp.EnabledUser = 1
    rsp.UserNumber = 1
    rsp.Reserved2 = 0
    rsp.ChaAccessMode = 0
    rsp.LinkAuthentication = 1
    rsp.IpmiMessaging = 1
    rsp.Reserved3 = 0
    rsp.PrivilegeLimit = enum.IpmiPrivilege.NO_ACCESS:value()
    return rsp
end


function AccountCollection:get_uid_gid_by_username(ctx, username)
    -- linux系统中的root用户名称为<su>，uid和gid都为0
    if username == config.TELNET_USER then
        return 0, 0
    end
    if config.ENABLE_GET_UID_GID_BY_PASSWD == false or config.ENABLE_GET_UID_GID_BY_PASSWD == 'false' then
        local acount = self:get_account_data_by_name(username)
        local la = linux_account.new(self.linux_files, false)
        return la:get_uid_gid(acount.Id, acount.RoleId)
    end
    -- bmc系统中的root用户存在linux中的名称为<root>，调用框架方法前做个转换
    username = username == config.ACTUAL_ROOT_USER_NAME and config.RESERVED_ROOT_USER_NAME or username
    local ok, uid, gid = pcall(utils_core.get_uid_gid_by_name, username)
    if not ok then
        error(custom_msg.UserNotExist(username))
    end
    return uid, gid
end

function AccountCollection:unlock_all_accounts_properties_writable(ctx)
    local properties_writable = {
        PasswordWritable = true,
        UserNameWritable = true,
        LoginInterfaceWritable = true,
        RoleIdWritable = true,
        EnabledWritable = true,
        LoginRuleIdsWritable = true,
        AuthenticationProtocolWritable = true,
        EncryptionProtocolWritable = true,
        SNMPPasswordWritable = true
    }
    for _, account in pairs(self.collection) do
        if not account:get_property_writable("UserNameWritable") then
            account:set_properties_writable(ctx, properties_writable)
        end
    end
end

function AccountCollection:set_account_property_writable(ctx, account_id, properties)
    ctx.operation_log.params.account_id = account_id
    local account = self.collection[account_id]
    if not account then
        log:error('User(%d) not exist', account_id)
        error(custom_msg.UserNotExist(string.format('User(%d)', account_id)))
    end
    account:set_properties_writable(ctx, properties)
end

function AccountCollection:get_account_property_writable(account_id)
    local account = self.collection[account_id]
    if not account then
        log:error('User(%d) not exist', account_id)
        error(custom_msg.UserNotExist(string.format('User(%d)', account_id)))
    end
    local properties_writable = {
        PasswordWritable = false,
        UserNameWritable = false,
        LoginInterfaceWritable = false,
        RoleIdWritable = false,
        EnabledWritable = false,
        LoginRuleIdsWritable = false,
        AuthenticationProtocolWritable = false,
        EncryptionProtocolWritable = false,
        SNMPPasswordWritable = false
    }
    local writable = false
    for property, _ in pairs(properties_writable) do
        writable = account:get_property_writable(property)
        properties_writable[property] = writable
    end
    return properties_writable
end

function AccountCollection:get_enabled_admin_number()
    local enabled_admin_num = 0
    for _, account in pairs(self.collection) do
        if account:check_is_enabled_admin() then
            enabled_admin_num = enabled_admin_num + 1
        end
    end
    return enabled_admin_num
end

function AccountCollection:get_snmp_keys(account_id)
    local auth_key = self.collection[account_id]:get_user_auth_ku()
    local encrypt_key = self.collection[account_id]:get_user_encrypt_ku()
    return auth_key, encrypt_key
end

function AccountCollection:_delete_cert(ctx, account_id)
    local path = string.format(PATH_ACCOUT_CERT, account_id)
    local is_exist
    local skynet = require 'skynet'
    -- 执行时间过长，采用协程执行
    skynet.fork_once(function()
        -- 资源树上树延迟，采取重试机制
        for i = 1,3 do
            is_exist = mdb_service.is_valid_path(client:get_bus(), path).Result
            if is_exist then
                break
            end
            skynet.sleep(20)
        end
        if is_exist then
            local obj = client:GetCertificateServiceObjects()[PATH_CERT_SERVICE]
            local dup_ctx = mc_context.new(ctx.Interface, ctx.UserName, ctx.ClientAddr)
            if obj then
                obj:DeleteCert(dup_ctx,
                    cert_service_enum.CertificateUsageType.ManagerAccountCertificate:value(), account_id)
            end
        end
    end
    )
end

function AccountCollection:set_os_administrator_privilege_enabled(ctx, status)
    self.m_host_privilege_limit:set_host_privilege_limited(ctx, status)
    self.m_global_account_config:set_os_administrator_privilege_enabled(status)
end

---设置用户锁定状态:解锁时清空用户pam锁定
---@param ctx table 上下文信息
---@param account_id number 用户ID
function AccountCollection:set_account_lock_state(ctx, account_id, lock_state)
    local account = self.collection[account_id]
    if not account then
        log:error("account id %s is not exist", account_id)
        error(custom_msg.UserNotExist("Id:" .. account_id))
    end
    local is_local_user = account:get_account_type():value() == enum.AccountType.Local:value() or
        account:get_account_type():value() == enum.AccountType.OEM:value()
    if not is_local_user then
        log:error("account id %s is not local account", account_id)
        error(custom_msg.UserNotExist("Id:" .. account_id))
    end
    local user_name = account:get_user_name()
    account:set_locked(lock_state)
    if not lock_state then
        core.reset_pam_tally(user_name, config.PAM_TALLY_LOG_DIR)
        account:set_account_status(enum.UserLocked.USER_UNLOCK)
    end
    self.m_account_changed:emit(account_id, "Locked", lock_state)
    self.m_account_ipmi_changed:emit(account_id)
    -- 锁定踢出会话
    if lock_state then
        self.m_account_security_changed:emit(account_id, user_name)
    end
    if ctx and ctx.operation_log then
        ctx.operation_log.params = { lock_state = lock_state and 'Lock' or 'Unlock',
            user_name = user_name, account_id = account_id }
    end
end

function AccountCollection:backup_account_info()
    self.account_db = account_backup_db.get_instance()
    self.account_db:clear()
    for _, account_info in pairs(self.collection) do
        if account_info.m_account_data.AccountType == enum.AccountType.Local then
            local account_data, ipmi_data, snmp_data = account_info:get_backup_info()
            self.account_db:new_data(account_info.m_account_data.Id, account_data, ipmi_data, snmp_data)
            log:notice("[Recover] backup account %s data", account_info:get_user_name())
        end
    end
end

-- 实现从IpmiUserInfo到IpmiChannelConfig的数据同步
function AccountCollection:sync_and_update_ipmi_channel_config()
    if not self.db or not self.db.IpmiUserInfo or not self.db.IpmiChannelConfig then
        log:warn("Database tables IpmiUserInfo or IpmiChannelConfig not found. Skipping sync.")
        return
    end

    local old_tbl = self.db.IpmiUserInfo
    local new_tbl = self.db.IpmiChannelConfig

    local query = self.db:select(old_tbl):where(old_tbl.IsSynced:eq(false))

    if not query or query == {} then
        return
    end

    query:fold(function(old_record)
        log:info("Syncing for AccountId: %s", old_record.AccountId)

        local data_to_update = {
            CallbackRestriction = old_record.IsCallin,
            LinkAuthenticationEnabled = (old_record.IsEnableAuth == 1),
            IpmiMessagingEnabled = (old_record.IsEnableIpmiMsg == 1),
            PrivilegeLimit = old_record.Privilege1:value()
        }

        local ok, err = pcall(function()
            self.db:update(new_tbl)
                :value(data_to_update)
                :where(new_tbl.AccountId:eq(old_record.AccountId),
                       new_tbl.ChannelNumber:eq(1)
                )
                :exec()

            self.db:update(old_tbl)
                :value({ IsSynced = true })
                :where(old_tbl.AccountId:eq(old_record.AccountId))
                :exec()
        end)

        if not ok then
            log:error("Failed to sync for AccountId: %s. Error: %s", old_record.AccountId, tostring(err))
        end
    end)

    log:notice("Data sync (Update Logic) from IpmiUserInfo to IpmiChannelConfig finished.")
end

return singleton(AccountCollection)
