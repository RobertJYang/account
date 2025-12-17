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
local mc_utils = require 'mc.utils'
local log = require 'mc.logging'
local context = require 'mc.context'
local vos = require 'utils.vos'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local err = require 'account.errors'
local enum = require 'class.types.types'
local err_cfg = require 'error_config'
local config = require 'common_config'
local utils = require 'infrastructure.utils'
local privilege = require 'domain.privilege'
local trace = require 'telemetry.trace'
local core = require 'account_core'

-- AccountService
local AccountService = class()

function AccountService:ctor(global_account_config, account_collection, file_synchronization,
    role_collection, account_policy_collection)
    self.m_account_config = global_account_config
    self.m_account_collection = account_collection
    self.m_file_synchronization = file_synchronization
    self.m_rc = role_collection
    self.account_policy_collection = account_policy_collection
    self.m_config_added = signal.new()
    self.m_config_changed = signal.new()
end

--- 新建用户
---@param ctx table
---@param account_info table
--- account_info中包含用户名字、用户id、角色id、可登录的接口、首次登录策略，创建OEM用户时可能包含密码类型等信息
function AccountService:new_account(ctx, account_info, is_ipmi_or_snmp)
    local span = trace.start_span('account.AccountService.new_account', {})
    -- 如果机机接口新建用户开启所有登录接口且当前限制了用户允许开启的登录接口, 则限制新建用户登录接口为AllowedLoginInterfaces支持的范围
    local allowed_login_interfaces = self.account_policy_collection
        :get_allowed_login_interfaces(account_info.account_type)
    local cur_interface_num = utils.cover_interface_enum_to_num(account_info.interface)
    if (ctx.Interface == 'CLI' or ctx.Interface == 'Redfish') and
        allowed_login_interfaces < config.DEFAULT_INTERFACES and cur_interface_num == config.DEFAULT_INTERFACES then
        account_info.interface = utils.convert_num_to_interface_str(allowed_login_interfaces)
    end
    local role_name = self.m_rc:get_role_name_by_id(account_info.role_id)
    ctx.operation_log.params.name = account_info.name
    ctx.operation_log.params.id = account_info.id
    ctx.operation_log.params.role = role_name
    ctx.operation_log.params.interface = utils.interface_enum_table_to_string(account_info.interface)
    ctx.operation_log.params.first_login_policy = account_info.first_login_policy:value() ==
        enum.FirstLoginPolicy.PromptPasswordReset:value() and 'Prompt' or 'Force'
    local account_id = self.m_account_collection:new_account(ctx, account_info, is_ipmi_or_snmp)
    ctx.operation_log.params.id = account_id
    self.m_account_collection:check_password_valid_days()
    span:finish()
    return account_id
end

-- 获取用户详细数据 by 用户ID
-- 返回的data禁止save()
function AccountService:get_account_data_by_id(account_id)
    return self.m_account_collection:get_account_data_by_id(account_id)
end

-- 返回的data禁止save()
function AccountService:get_account_data_by_name(user_name)
    return self.m_account_collection:get_account_data_by_name(user_name)
end

function AccountService:get_id_by_user_name(ctx, user_name)
    if not self.account_policy_collection:check_user_name(enum.AccountType.Local:value(), user_name) then
        error(custom_msg.UserNotExist(user_name))
    end
    -- 上下文为：telnet的root用户、HOST、有UserMgm权限的用户，才允许获取user_name的account_id
    -- telnet协议下，操作用户为linux中内置的root用户，名字已被北向接口层包装成<su>
    local priv_ok
    if ctx.UserName == config.TELNET_USER or ctx.ClientAddr == config.HOST_CHAN_IP then
        priv_ok = true
    elseif ctx.Privilege then
        local handle_priv = privilege:num_to_array(ctx.Privilege)
        priv_ok = utils.privilege_validator(handle_priv, enum.PrivilegeType.UserMgmt)
    else
        local account = self.m_account_collection:get_account_by_name(ctx.UserName)
        if not account then
            error(custom_msg.UserNotExist(ctx.UserName))
        end
        priv_ok = (account:get_role_id() == enum.RoleType.Administrator:value())
    end

    if not priv_ok and ctx.UserName ~= user_name then
        log:error('User(%s) gets id by (%s) failed, because only administrator or account itself can get id by name',
            ctx.UserName, user_name)
        error(base_msg.InsufficientPrivilege())
    end
    local _, account_id = self.m_account_collection:get_account_by_name(user_name)
    if not account_id then
        error(custom_msg.UserNotExist(user_name))
    end
    return account_id
end

function AccountService:set_account_password(ctx, handler_account_id, account_id, pwd)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    ctx.operation_log.params.operate = 'Modify'
    ctx.operation_log.params.name = account.m_account_data.UserName
    ctx.operation_log.params.id = account_id
    self.m_account_collection:set_account_password(ctx, handler_account_id, account_id, pwd)
    self.m_account_collection:check_password_valid_days()
    return err_cfg.USER_OPER_SUCCESS
end

function AccountService:set_user_snmp_pwd(ctx, account_id, pwd)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    ctx.operation_log.params.name = account.m_account_data.UserName
    ctx.operation_log.params.id = account.m_account_data.Id

    local enabled = utils.check_login_interface_enabled(account:get_login_interface(),
        enum.LoginInterface.SNMP)
    if not enabled then
        error(err.un_supported())
    end
    self.m_account_collection:set_user_snmp_pwd(ctx, account_id, pwd)
    self.m_account_collection:set_account_snmp_privacy_pwd_init_status(account_id, false)
    account:set_user_ku(pwd, enum.SNMPKuType.Encryption)
end

-- 设置用户鉴权算法
function AccountService:set_user_auth_protocol(ctx, handler_account_id, account_id,
                                               auth_protocol, auth_passwd, encrypt_password)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    ctx.operation_log.params = { name = account.m_account_data.UserName, id = account_id }
    local enabled = utils.check_login_interface_enabled(account:get_login_interface(),
        enum.LoginInterface.SNMP)
    if not enabled then
        log:error('Account setting snmp auth protocol must support snmp login_interface')
        error(base_msg.InternalError())
    end
    -- 鉴权算法值在MD5至SHA512间，None为0
    if not enum.SNMPAuthenticationProtocols.is_enum(auth_protocol) or
        auth_protocol:value() == enum.SNMPAuthenticationProtocols.None:value() then
        log:error('set_user_authentication_protocol failed, protocol_num(%d) is wrong', auth_protocol:value())
        error(base_msg.InternalError())
    end
    ctx.operation_log.params.protocol = tostring(auth_protocol)
    if utils.str_is_empty(auth_passwd) or utils.str_is_empty(encrypt_password) then
        log:error('set_user_authentication_protocol failed, auth_passwd or encrypt_password is empty')
        error(base_msg.InternalError())
    end
    -- 鉴权密码、加密密码校验
    account:password_validator(ctx, account:get_user_name(), auth_passwd, false, handler_account_id == account_id)
    account:check_conditions_set_snmp_passwd(ctx, encrypt_password)

    -- 设置鉴权算法AuthenticationProtocol
    self.m_account_collection:set_user_auth_protocol(account_id, auth_protocol)

    -- 设置用户密码, 设置用户密码中会设置AuthenticationKey(AuthKu)
    self:set_account_password(ctx, handler_account_id, account_id, auth_passwd)

    -- 设置snmp加密密码, 设置加密密码中会设置EncryptionKey(EncryKu)
    self:set_user_snmp_pwd(ctx, account_id, encrypt_password)
end

-- 设置用户加密算法
function AccountService:set_user_encrypt_protocol(ctx, account_id, encrypt_protocol)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    ctx.operation_log.params = { id = account_id, name = account.m_account_data.UserName }
    local enabled = utils.check_login_interface_enabled(account:get_login_interface(),
        enum.LoginInterface.SNMP)
    if not enabled then
        error(err.invalid_parameter())
    end
    -- 鉴权算法值在DES至AES256间，None为0
    if not enum.SNMPEncryptionProtocols.is_enum(encrypt_protocol) or
        encrypt_protocol:value() == enum.SNMPEncryptionProtocols.None:value() then
        log:error('set_user_encryption_protocol failed, protocol_num(%d) is error', encrypt_protocol:value())
        error(err.invalid_parameter())
    end
    ctx.operation_log.params.protocol = tostring(encrypt_protocol)
    self.m_account_collection:set_user_encrypt_protocol(account_id, encrypt_protocol)
end

function AccountService:set_ipmi_password_complexity(req, ctx)
    local control = req.Control
    local manufacture_id = req.ManufactureId
    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    if manufacture_id ~= utils.get_manufacture_id() then
        ctx.operation_log.result = "failed"
        error(err:invalid_parameter())
    end
    if control > enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_STRONG_ENABLE:value() then
        ctx.operation_log.result = "failed"
        error(custom_msg.IPMIOutOfRange())
    end
    local lock = self.m_account_config:get_password_complexity_lock()
    if lock == true then
        if core.is_manufacture_mode() then
            log:notice("Skip checking password complexity check lock in manufacture mode")
        elseif control == enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_DISABLE:value() or
            control == enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_ENABLE:value() then
            error(custom_msg.PasswordForbidSetComplexityCheck())
        end
    end
    -- 如果为强制检查，则需要将设置锁定开关，且不允许修改
    if control == enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_STRONG_ENABLE:value() then
        ctx.operation_log.params = { state = 'Strong-Enable' }
        self.m_account_config:set_password_complexity_lock(true)
    else
        ctx.operation_log.params = { state = control == enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_ENABLE:value() and
            'Enable' or 'Disable' }
        self.m_account_config:set_password_complexity_lock(false)
    end
    if control == enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_STRONG_ENABLE:value() or
        control == enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_ENABLE:value() then
        self.m_config_changed:emit('PasswordComplexityEnable', true)
        self.m_account_config:set_password_complexity_enable(true)
    else
        self.m_config_changed:emit('PasswordComplexityEnable', false)
        self.m_account_config:set_password_complexity_enable(false)
    end
end

function AccountService:get_ipmi_password_complexity(req, ctx)
    local manufacture_id = req.ManufactureId
    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    if manufacture_id ~= utils.get_manufacture_id() then
        error(err:invalid_parameter())
    end
    local control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_DISABLE:value()
    local locked = self.m_account_config:get_password_complexity_lock()
    local enabled = self.m_account_config:get_password_complexity_enable()
    if locked == true then
        control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_STRONG_ENABLE:value()
    elseif locked == false and enabled == true then
        control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_ENABLE:value()
    end
    return control
end

function AccountService:set_initial_password_prompt_enable(enable)
    self.m_account_config:set_initial_password_prompt_enable(enable)
end

function AccountService:set_initial_account_privilege_restrict_enabled(enable)
    self.m_account_config:set_initial_account_privilege_restrict_enabled(enable)
    self.m_account_collection:update_privileges()
end

function AccountService:set_initial_password_need_modify(enable)
    self.m_account_config:set_initial_password_need_modify(enable)
    if not enable then
        self.m_account_config:set_initial_password_prompt_enable(enable)
        self.m_config_changed:emit('InitialPasswordPromptEnable', enable)
        self.m_account_config:set_initial_account_privilege_restrict_enabled(enable)
        self.m_config_changed:emit('InitialAccountPrivilegeRestrictEnabled', enable)
    end
    self.m_account_collection:update_privileges()
end


function AccountService:set_ipmi_user_access(req, ctx)
    self.m_account_collection:set_ipmi_user_access(req, ctx)
    return err_cfg.USER_OPER_SUCCESS
end

function AccountService:get_ipmi_user_access(req, ctx)
    local user_id = req.UserId
    local channel_number = (req.ChannelNumber == enum.IpmiChannel.PRSENT_CHAN_NUM:value() and
        ctx.chan_num or req.ChannelNumber)
    -- 用户ID有效性校验, 1是IPMI的保留用户
    if user_id < 1 or user_id > self.m_account_config:get_max_user_num() then
        log:error("User id is out of range")
        error(custom_msg.IPMIInvalidFieldRequest())
    end
    -- 通道校验,单通道场景下仅支持LAN1
    if self.m_account_collection.ipmi_channel_mappings.multi_channel_status == 0 and
        channel_number ~= enum.IpmiChannel.LAN1_CHAN_NUM:value() then
        log:error("channel number(%s) is invalid", channel_number)
        error(custom_msg.IPMICommandCannotExecute())
    end
    channel_number = self.m_account_collection.ipmi_channel_mappings:channel_number_translation(channel_number)
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

    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    local rsp = self.m_account_collection:get_ipmi_user_access(user_id, channel_number)
    return err_cfg.USER_OPER_SUCCESS, rsp
end

function AccountService:is_user_ipmi_interface_change_enable(old_interface, interface)
    local old = (old_interface & enum.LoginInterface.IPMI:value() == enum.LoginInterface.IPMI:value()) and
                    1 or 0
    local new = (interface & enum.LoginInterface.IPMI:value() == enum.LoginInterface.IPMI:value()) and 1 or 0
    if old == enum.IpmiInterfaceEnable.USER_LOGIN_INTERFACE_DISABLE:value() and
        new == enum.IpmiInterfaceEnable.USER_LOGIN_INTERFACE_ENABLE:value() then
        return true
    end
    return false
end

function AccountService:set_ipmi_login_interface(req, ctx)
    local manufacture_id = req.ManufactureId
    local account_id = req.UserId
    local login_interface = req.LoginInterface
    local operation = req.Operation
    local password_data = req.PasswordData
    local password_length = req.PasswordLength
    local account = self:get_account_data_by_id(account_id)
    if account == nil then
        log:error("invalid_parameter UserId: %s", tostring(account_id))
        error(err.invalid_data_field())
    end
    local user_name = account.UserName
    ctx.operation_log.params.username = 'user(' .. user_name .. '|user'..account_id..')'
    ctx.operation_log.params.id = account_id
    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    if manufacture_id ~= utils.get_manufacture_id() then
        error(err:invalid_parameter())
    end
    utils.check_ipmi_account_id(account_id)
    if operation ~= enum.IpmiOperPassword.IPMI_OPERATION_SET_PASSWORD:value() and
        operation ~= enum.IpmiOperPassword.IPMI_OPERATION_NOT_SET_PASSWORD:value() then
        error(err.invalid_data_field())
    end
    local old_interface = self.m_account_collection:get_login_interface(account_id) & 0xDF
    local old_interface_num = self.m_account_collection:get_login_interface(account_id)
    if self:is_user_ipmi_interface_change_enable(old_interface, login_interface) and
        operation ~= enum.IpmiOperPassword.IPMI_OPERATION_SET_PASSWORD:value() then
        error(err.un_supported())
    end
    if operation == enum.IpmiOperPassword.IPMI_OPERATION_SET_PASSWORD:value() and
        (string.len(password_data) ~= password_length) then
        error(err.invalid_data_field())
    end
    local flag = utils.ipmi_get_user_login_interface(login_interface)
    self.m_account_collection:set_login_interface(ctx, account_id, flag)
    self.m_account_collection.m_account_changed:emit(account_id, "LoginInterface", flag)
    local new_interface_num = self.m_account_collection:get_login_interface(account_id)
    local change = utils.get_login_interface_or_rule_ids_change(old_interface_num,
        new_interface_num, utils.convert_num_to_interface_str)
    if not change then
        ctx.operation_log.operation = 'SkipLog'
    end
    ctx.operation_log.params.change = change
end

local function inner_channel_check(chann_num)
    log:debug("the chann num is %s", tostring(chann_num))
    if (chann_num == enum.IpmiChannel.SYS_CHAN_NUM:value()) or
        (chann_num == enum.IpmiChannel.CPLDRAM_CHAN_NUM:value()) then
        return true
    end
    return false
end

local function get_ipmi_set_account_password_handler_id(req, ctx)
    if inner_channel_check(ctx.chan_num) then
        return config.IPMI_ACCOUNT_ID
    end
    if ctx.session and ctx.session.user then
        return ctx.session.user.id
    end
end

function AccountService:check_ipmi_password_privilege(handle_account_id, account_id)
    if handle_account_id > self.m_account_config:get_max_user_num() or
        handle_account_id < self.m_account_config:get_min_user_num() then
        return true
    end
    local handler_account = self.m_account_collection:get_account_by_account_id(handle_account_id)
    if handle_account_id == account_id then
        return true
    end
    -- 是首次登录，只可以修改自己密码
    if mc_utils.table_compare(handler_account.current_privileges,
        { tostring(enum.PrivilegeType.ConfigureSelf) }) then
        return false
    end

    if handler_account:get_role_id() ~= enum.RoleType.Administrator:value() then
        return false
    end

    return true
end

--- ipmi设置密码前，对请求提参数进行预校验
---@param req any
---@param ctx any
---@return integer
function AccountService:__ipmi_set_account_password_precheck(req, ctx)
    local operation = req.Operation
    if operation == enum.IpmiUserOperater.OPERATION_DISABLE_USER:value() then
        ctx.operation_log.params.operate = 'Disable'
    elseif operation == enum.IpmiUserOperater.OPERATION_ENABLE_USER:value() then
        ctx.operation_log.params.operate = 'Enable'
    elseif operation == enum.IpmiUserOperater.OPERATION_SET_PASSWD:value() then
        ctx.operation_log.params.operate = 'Modify'
    else
        error(custom_msg.IPMIOutOfRange())
    end

    utils.check_ipmi_account_id(req.UserId)

    -- 获取合法user id的用户名, 保证操作日志中包含用户名
    local account = self.m_account_collection:get_account_by_account_id(req.UserId)
    ctx.operation_log.params.name = account:get_user_name()

    if operation == enum.IpmiUserOperater.OPERATION_SET_PASSWD:value() then
        local user_password_size_1_5 = 16 -- IPMI1.5密码16位
        local user_password_size_2 = 20 -- IPMI2.0密码20位
        if ((req.PasswordSize == 0) and (string.len(req.PasswordData) ~= user_password_size_1_5)) or
        ((req.PasswordSize == 1) and (string.len(req.PasswordData) ~= user_password_size_2)) then
            error(custom_msg.IPMIRequestLengthInvalid())
        end
    end

    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
end

-- 函数中由于密码数据协议进行了补充0x00，因此去掉
function AccountService:ipmi_set_account_password(req, ctx)
    -- 预置操作日志配置，保证功能异常时返回日志记录正确性
    ctx.operation_log.params = { name = "", id = req.UserId, operate = '', ret = '' }
    self:__ipmi_set_account_password_precheck(req, ctx)
    local password_data = mc_utils.trim_tail_zero(req.PasswordData)
    local password_len = self:get_password_len(req.PasswordSize, password_data)
    local account = self.m_account_collection:get_account_by_account_id(req.UserId)
    local handler_user_id = get_ipmi_set_account_password_handler_id(req, ctx)
    if not handler_user_id then
        return err_cfg.USER_UNSUPPORT
    end
    if not self:check_ipmi_password_privilege(handler_user_id, account:get_id()) then
        error(err.un_supported())
    end
    if req.Operation == enum.IpmiUserOperater.OPERATION_SET_PASSWD:value() then
        local ret = self:set_account_password(ctx, handler_user_id, req.UserId, password_data)
        ctx.operation_log.params.ret = ret
        if ret ~= err_cfg.USER_OPER_SUCCESS then
            log:error('set password failed, ret[%d]', ret)
            return ret
        end
        self.m_account_collection:set_ipmi_user_use_20bytes_passwd(req.UserId, password_len)
        if config.ENABLE_UT then
            local service = require 'account.service'
            local temp_ctx = mc_utils.table_copy(context.get_context())
            temp_ctx.operation_log = nil
            context.with_context(temp_ctx, function()
                service:ManagerAccountsManagerAccountsPasswordChangedSignal(req.UserId)
            end)
        end
        return ret
    elseif req.Operation == enum.IpmiUserOperater.OPERATION_DISABLE_USER:value() then
        local ret = self.m_account_collection:enable_user_operation(req.UserId, false)
        if ret ~= err_cfg.USER_OPER_SUCCESS then
            ctx.operation_log.result = 'fail_ret'
            ctx.operation_log.params.ret = ret
        end
        return ret
    elseif req.Operation == enum.IpmiUserOperater.OPERATION_ENABLE_USER:value() then
        local ret = self.m_account_collection:enable_user_operation(req.UserId, true)
        if ret ~= err_cfg.USER_OPER_SUCCESS then
            ctx.operation_log.result = 'fail_ret'
            ctx.operation_log.params.ret = ret
        end
        return ret
    else
        error(err.un_supported())
    end
end

function AccountService:set_ipmi_user_name(req, ctx)
    local user_name = req.UserName
    local user_id = req.UserId
    -- 由于协议对用户名进行了填充0x00，因此去掉
    local ret = self.m_account_config:check_ipmi_host_user_mgnt_enabled(ctx)
    user_name = mc_utils.trim_tail_zero(user_name)
    if user_name == '' then
        ctx.operation_log.operation = "IpmiDeleteAccount"
        log:info("Delete user %d by IPMI ", user_id)
    end
    if not ret then
        log:error("Check host user management failed")
        ctx.operation_log.operation = 'user_mgnt_disabled'
        ctx.operation_log.params.id = user_id
        ctx.operation_log.params.name = user_name
        error(err.host_user_management_diabled())
    end

    utils.queue(function()
        local ok, err_code = pcall(function()
            self.m_account_collection:set_user_name(ctx, user_id, user_name)
        end)
        if not ok then
            if err_code.name == custom_msg.InvalidUserNameMessage.Name then
                error(custom_msg.IPMIInvalidFieldRequest())
            else
                error(err_code)
            end
        end
    end)

    self:check_user_time_info()
    return err_cfg.USER_OPER_SUCCESS
end

function AccountService:get_password_len(password_size, password_data)
    local user_password_size_1_5 = 16 -- IPMI1.5密码16位
    local user_password_size_2 = 20 -- IPMI2.0密码20位
    local password_len
    if (password_size == 1) and ((string.len(password_data) - 2) > user_password_size_2) then
        password_len = user_password_size_2
    elseif (password_size == 0) and ((string.len(password_data) - 2) > user_password_size_1_5) then
        password_len = user_password_size_1_5
    else
        password_len = string.len(password_data) - 2
    end
    return password_len
end

function AccountService:set_max_password_valid_days(max_age)
    local PROP_NOT_USE = 0 -- 设置为0代表该属性不生效
    local last_max_age = self.m_account_config:get_max_password_valid_days()

    self.m_account_config:set_max_password_valid_days(max_age)

    -- 如果原过期天数是0(无限期)，新过期天数非0，则需重置密码开始时间
    if last_max_age == PROP_NOT_USE and max_age ~= PROP_NOT_USE then
        self.m_account_collection:update_all_password_valid_start_time(nil)
    end

    self.m_account_collection:check_password_valid_days()
end

function AccountService:set_min_password_valid_days(min_age)
    self.m_account_config:set_min_password_valid_days(min_age)
    self.m_account_collection:update_within_min_password_days_status()
end

--- 设置逃生用户
---@param ctx table
---@param account_id number
function AccountService:set_emergency_account(ctx, account_id)
    if account_id ~= 0 then
        local account = self.m_account_collection:get_account_by_account_id(account_id)
        if not account then
            log:error("set_emergency_account failed, account_id %d does not exist.", account_id)
            error(custom_msg.InvalidUserName())
        end
        if account:get_role_id() ~= enum.RoleType.Administrator:value() or not account:get_enabled() then
            log:error("User%d's privilege or enable state error", account_id)
            error(custom_msg.EmergencyLoginUserSettingFail())
        end
        -- 更新新逃生用户的密码过期状态
        account:update_password_expire_status(false)
        ctx.operation_log.params = { name = account:get_user_name() }
    end

    local old_emergency_account_id = self.m_account_config:get_emergency_account()
    self.m_account_config:set_emergency_account(account_id)
    if old_emergency_account_id ~= 0 then
        self.m_account_collection:set_password_valid_start_time(old_emergency_account_id, os.time())
    end

    self.m_account_collection:update_deletable()
    self.m_account_collection:check_password_valid_days()
    self.m_file_synchronization:flush_account()
end

--- 设置SNMPv3Trap用户
---@param ctx table
---@param account_id number
function AccountService:set_snmp_v3_trap_account(ctx, account_id)
    local account = self.m_account_collection.collection[account_id]
    if not account then
        log:error("set SNMP v3 trap account failed, account_id %d does not exist.", account_id)
        error(custom_msg.InvalidUserName())
    end
    if account:get_role_id() == enum.RoleType.NoAccess:value() or account:get_password_valid_time() == 0 then
        log:error("set SNMP v3 trap account failed, account_id %d has no access rights or has expired.", account_id)
        error(custom_msg.V3UserNameNotUsed(account_id, 'SNMPv3TrapAccountId'))
    end

    self.m_account_config:set_snmp_v3_trap_account(account_id)
    self.m_account_collection:update_deletable()
end

--- 设置SNMPv3Trap用户修改策略
function AccountService:set_snmp_v3_trap_account_limit_policy(ctx, value)
    self.m_account_config:set_snmp_v3_trap_account_limit_policy(ctx, value)
    self.m_account_collection:update_deletable()
end

function AccountService:set_inactive_time_threshold(threshold)
    local PROP_NOT_USE = 0 -- 设置为0代表该属性不生效
    local old_threshold = self.m_account_config:get_inactive_time_threshold()
    if threshold == old_threshold then
        return
    end
    self.m_account_config:set_inactive_time_threshold(threshold)
    if old_threshold == PROP_NOT_USE and threshold ~= PROP_NOT_USE then
        self.m_account_collection:update_inactive_start_time(nil)
    end
    self.m_account_collection:update_inactive_status()
end

function AccountService:set_history_password_count(count)
    self.m_account_config:set_history_password_count(count)
    self.m_account_collection:update_history_password_list()
end

function AccountService:set_max_history_password_count(count)
    self.m_account_config:set_max_history_password_count(count)
end

local BASE_TIMESTAMP = 600 -- 10分钟600秒
local MAC_COUNT = 12 * 60 * 2 -- 最大循环计数
local MIN_SECOND_TO_RESET = 10 * 60 -- 判断跳变时间阈值
local MAX_TIME_ERROR_COUNT = 60 -- 2秒一次，60次为2分钟

local function user_time_monitor_func(self, skynet)
    log:notice('Start user time info monitor.')
    -- 0:初始化循环计数、当前时间、上次循环时间、时间异常次数
    local first_sync, loop_count, new_timestamp, last_timestamp, time_error_count, time_diff = true, 0, 0, 0, 0, 0

    -- 2min之后再开始用户检查
    skynet.sleep(2 * 60 * 100)

    while true do
        ::continue::
        -- 获取系统时间同步状态
        new_timestamp = vos.vos_get_cur_time_stamp()
        if new_timestamp < BASE_TIMESTAMP then
            time_error_count = time_error_count + 1
            -- 第一次要打印出来，之后每2分钟打印一次
            if time_error_count % MAX_TIME_ERROR_COUNT == 1 then
                log:error("now time(%s) is default time, account time info operation passed",
                os.date('%Y-%m-%d %H:%M:%S', new_timestamp))
            end
            skynet.sleep(200)
            goto continue
        end
        if first_sync then
            self:check_user_time_info()
            first_sync = false
            last_timestamp = new_timestamp
            skynet.sleep(500)
            goto continue
        end
        -- 时间间隔大于10分钟，更新密码起始时间
        time_diff = new_timestamp - last_timestamp
        if math.abs(time_diff) > MIN_SECOND_TO_RESET then
            self.m_account_collection:update_all_password_valid_start_time(time_diff)
            self.m_account_collection:update_inactive_start_time(time_diff)
        end
        -- 每隔5秒执行一次更新相关操作
        self:loop_update_operation()
        -- 间隔1小时将用户活动记录写flash
        if loop_count == MAC_COUNT / 2 or loop_count == MAC_COUNT then
            pcall(function ()
                self.m_account_collection:flash_user_inactive_start_time()
            end)
        end
        -- 间隔2小时检查用户:密码有效期/最短密码使用期/用户不活跃信息
        if loop_count == MAC_COUNT then
            self:check_user_time_info()
            loop_count = 0
        end
        last_timestamp = new_timestamp;
        loop_count = loop_count + 1;
        skynet.sleep(500)
    end
end

function AccountService:user_time_info_monitor()
    local skynet = require 'skynet'
    skynet.fork_loop({ count = 0 }, function()
        user_time_monitor_func(self, skynet)
    end)
end

function AccountService:check_user_time_info()
    self.m_account_collection:check_password_valid_days()
    self.m_account_collection:update_within_min_password_days_status()
    self.m_account_collection:update_inactive_status()
end

function AccountService:loop_update_operation()
    -- 每隔5秒检测一次用户是否需要刷新登录记录
    pcall(function ()
        self.m_account_collection:flash_login_record()
    end)
    -- 每隔5秒检测一次公私钥是否过期
    pcall(function()
        self.m_account_config:update_requested_key_pair(5)
    end)
end

function AccountService:ipmi_set_user_snmp_v3_privacy_pwd(req, ctx)
    local userId = req.UserId
    local pwdLength = req.PwdLength
    local operation = req.Operation
    local manufactureId = req.ManufactureId
    local passwordData = req.PasswordData
    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    if manufactureId ~= utils.get_manufacture_id() then
        error(err.invalid_parameter())
    end
    utils.check_ipmi_account_id(userId)
    local ret = self.m_account_collection:check_user_id_exist(userId)
    if not ret then
        log:error('user do not exist')
        return err_cfg.USER_DONT_EXIST
    end
    local handler_user_id = get_ipmi_set_account_password_handler_id(req, ctx)
    if not handler_user_id then
        return err_cfg.USER_UNSUPPORT
    end
    if not self:check_ipmi_password_privilege(handler_user_id, userId) then
        error(err.un_supported())
    end

    if operation ~= enum.IpmiSetUserSNMPV3PrivacyPwd.SET_PASSWORD:value() then
        log:error('operation code is out of range')
        error(err.value_out_of_range())
    end
    if pwdLength ~= #passwordData then
        log:error('password length is error')
        error(err.invalid_password_length())
    end

    self:set_user_snmp_pwd(ctx, userId, passwordData)
    log:info('Set snmp password initial status successfully')
    return err_cfg.USER_OPER_SUCCESS
end

function AccountService:get_first_login_policy_by_id(id)
    utils.check_ipmi_account_id(id)
    return self.m_account_collection:get_first_login_policy_by_id(id)
end

function AccountService:get_requested_public_key(usage_type)
    if usage_type ~= 1 then
        log:error('get request public key failed, unsupported key usage type : %d', usage_type)
        error(base_msg.PropertyValueTypeError(usage_type, "PublicKeyUsageType"))
    end
    local key_pair = self.m_account_config:get_web_requested_key_pair()
    return key_pair.PublicKey
end

function AccountService:set_os_administrator_privilege_enabled(ctx, status)
    self.m_account_collection:set_os_administrator_privilege_enabled(ctx, status)
end

return singleton(AccountService)
