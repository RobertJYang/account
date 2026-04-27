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
local enum = require 'class.types.types'
local err = require 'account.errors'
local log = require 'mc.logging'
local utils = require 'infrastructure.utils'
local ipmi_cmds = require 'account.ipmi.ipmi'
local ipmi_types = require 'ipmi.types'
local account_service = require 'service.account_service'
local signal = require 'mc.signal'
local core = require 'account_core'
local account_collection = require 'domain.account_collection'
local global_account_config = require 'domain.global_account_config'
local err_cfg = require 'error_config'
local config = require 'common_config'
local custom_msg = require 'messages.custom'
local ipmi_running_record = require 'infrastructure.ipmi_running_record'
local base_msg = require 'messages.base'

local account_service_ipmi = class()

--  snmp团体名类型对应snmp用户Id
local COMMUNIT_ID<const> = {
    [enum.IpmiSNMPCommunity.Ro:value()] = 20,
    [enum.IpmiSNMPCommunity.Rw:value()] = 21
}

local LONG_COMMUNITY_ENABLED<const> = {
    [enum.IpmiLongCommunityEnabled.Disable:value()] = false,
    [enum.IpmiLongCommunityEnabled.Enable:value()] = true
}

-- IPMI命令中设置使能只有0与1两种状态，统一以该表为索引
local value_bool_map<const> = {
    [err_cfg.STATE_ENABLE] = true,
    [err_cfg.STATE_DISABLE] = false,
}

function account_service_ipmi:ctor()
    self.m_account_service = account_service.get_instance()
    self.m_account_config = global_account_config.get_instance()
    self.m_account_collection = account_collection.get_instance()
    self.m_update_config = signal.new()
    self.m_update_community = signal.new()
    self.m_ipmi_running_record = ipmi_running_record.get_instance()
end

function account_service_ipmi:init()
end

function account_service_ipmi:get_user_access(req, ctx)
    local ret, rsp = self.m_account_service:get_ipmi_user_access(req, ctx)
    rsp.CompletionCode = ret
    return rsp
end

function account_service_ipmi:set_password_compexity(req, ctx)
    self.m_account_service:set_ipmi_password_complexity(req, ctx)
    local rsp = ipmi_cmds.SetUserPassComplexity.rsp.new()
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.ManufactureId = utils.get_manufacture_id()
    return rsp
end

function account_service_ipmi:get_password_compexity(req, ctx)
    local control = self.m_account_service:get_ipmi_password_complexity(req, ctx)
    local rsp = ipmi_cmds.GetUserPassComplexity.rsp.new()
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.Control = control
    return rsp
end

function account_service_ipmi:set_user_interface(req, ctx)
    self.m_account_service:set_ipmi_login_interface(req, ctx)
    local rsp = ipmi_cmds.SetUserInterface.rsp.new()
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.ManufactureId = utils.get_manufacture_id()
    return rsp
end

function account_service_ipmi:set_user_snmp_v3_privacy_pwd(req, ctx)
    local rsp = ipmi_cmds.UserIpmiSetUserSNMPV3PrivacyPwd.rsp.new()
    rsp.ManufactureId = utils.get_manufacture_id()
    local ret = self.m_account_service:ipmi_set_user_snmp_v3_privacy_pwd(req, ctx)
    rsp.CompletionCode = ret
    return rsp
end

function account_service_ipmi:get_user_name(req, ctx)
    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    local account_id = req.UserId
    if account_id < self.m_account_config:get_min_user_num() or 
        account_id > self.m_account_config:get_max_user_num() then
        log:error("account id(%s) is illegal", account_id)
        error(err.invalid_data_field())
    end

    local rsp = ipmi_cmds.GetUserName.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    -- 当用户不存在时返回空字符串
    if self.m_account_collection.collection[account_id] == nil then
        rsp.UserName = ""
    else
        rsp.UserName = self.m_account_collection:get_user_name(account_id)
    end
    return rsp
end

function account_service_ipmi:get_account_interface(req, ctx)
    if req.ManufactureId ~= utils.get_manufacture_id() then
        log:error("ManufactureId is error")
        error(err.invalid_parameter())
    end
    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    local account_id = req.UserId
    utils.check_ipmi_account_id(account_id)
    local interface = self.m_account_collection:get_login_interface(account_id)

    local rsp = ipmi_cmds.GetAccountInterface.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.Interface = interface
    return rsp
end

--- 设置SNMP Configuration
---@param req any
---@param ctx any
function account_service_ipmi:set_snmp_configuration(req, ctx)
    local manufacture_id = req.ManufactureId
    local snmp_param = req.SNMPParameter
    local operation = req.BlockSelector
    local sub_operation = req.SubBlockSelector
    local len = req.Length
    local data = req.Data
    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    if not self:snmp_configuration_input_check(manufacture_id, snmp_param, operation) then
        error(err.un_supported())
    end
    if operation == enum.IpmiSNMPConfiguration.Community:value() then
        self:set_snmp_community(sub_operation, len, data, ctx)
    elseif operation == enum.IpmiSNMPConfiguration.LongCommunityEnabled:value() then
        self:set_snmp_long_community_enabled(sub_operation, len, data, ctx)
    end
    local rsp = ipmi_cmds.SetSNMPConfiguration.rsp.new()
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.CompletionCode = ipmi_types.Cc.Success
    return rsp
end

function account_service_ipmi:get_snmp_configuration(req, ctx)
    local manufacture_id = req.ManufactureId
    local snmp_param = req.SNMPParameter
    local block_sel = req.BlockSelector
    local sub_block_sel = req.SubBlockSelector
    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    if not self:snmp_configuration_input_check(manufacture_id, snmp_param, block_sel) then
        error(err.invalid_parameter())
    end
    local data = nil       -- 预置返回数据
    if block_sel == enum.IpmiSNMPConfiguration.Community:value() then
        data = self:get_snmp_community(sub_block_sel)
    else
        data = self:get_snmp_long_community_enabled()
    end
    local rsp = ipmi_cmds.GetSNMPConfiguration.rsp.new()
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.Length = #data
    rsp.Data = data
    return rsp
end

function account_service_ipmi:get_snmp_community(community_type)
    if community_type ~= enum.IpmiSNMPCommunity.Ro:value() and
        community_type ~= enum.IpmiSNMPCommunity.Rw:value() then
        log:error('Get snmp community failed, snmp community type is unsupport')
        error(err.un_supported())
    end
    local snmp_account = self.m_account_collection.collection[(COMMUNIT_ID[community_type])]
    local community = snmp_account:get_account_password()
    return community
end

function account_service_ipmi:get_snmp_long_community_enabled()
    local long_enabled = self.m_account_config:get_long_community_enabled() and
        enum.IpmiLongCommunityEnabled.Enable:value() or
        enum.IpmiLongCommunityEnabled.Disable:value()
    return string.char(long_enabled)
end

--- 查询\设置SNMPConfiguration属性参数检查
---@param manufacture_id any
---@param snmp_param any
---@param operation any
function account_service_ipmi:snmp_configuration_input_check(manufacture_id, snmp_param, operation)
    if manufacture_id ~= utils:get_manufacture_id() then
        log:error('Set snmp configuration failed, ManufactureId is unsupport')
        return false
    elseif snmp_param ~= 1 then
        log:error('Set snmp configuration failed, snmp parameter is unsupport')
        return false
    elseif operation ~= enum.IpmiSNMPConfiguration.Community:value() and
        operation ~= enum.IpmiSNMPConfiguration.LongCommunityEnabled:value() then
        log:error('Set snmp configuration failed, block selector data is unsupport')
        return false
    end
    return true
end

--- 设置snmp团体名
---@param community_type any
---@param community_len any
---@param community any
---@param ctx any
function account_service_ipmi:set_snmp_community(community_type, community_len, community, ctx)
    
    local account_id = nil

    if ctx.ChanType == enum.IpmiChannelType.IPMI_HOST:value() then 
        ctx.operation_log.operation = 'SkipLog'
        account_id = config.IPMI_ACCOUNT_ID
    else
        local account = self.m_account_service:get_account_data_by_name(ctx.session.user.name)
        account_id = account.Id
    end
    if not self:set_snmp_community_input_check(community_type, community_len, community) then
        ctx.operation_log.result = 'community_failed'
        error(err.invalid_parameter())
    end
    if community_type == enum.IpmiSNMPCommunity.Ro:value() then
        ctx.operation_log.params.com_type = 'Read-only'
    else
        ctx.operation_log.params.com_type = 'Read-Write'
    end
    self.m_account_service:set_account_password(ctx, account_id, COMMUNIT_ID[community_type], community)
    if community_len == 0 then
        ctx.operation_log.result = 'delete_success'
    else
        ctx.operation_log.result = 'community_success'
    end
    self.m_update_community:emit()
end

--- 设置snmp团体名参数检查
---@param community_type any
---@param community_len any
---@param community any
function account_service_ipmi:set_snmp_community_input_check(community_type, community_len, community)
    if community_type ~= enum.IpmiSNMPCommunity.Ro:value() and
    community_type ~= enum.IpmiSNMPCommunity.Rw:value() then
        log:error('Set snmp community failed, snmp community type is unsupport')
        return false
    elseif community_len ~= #community then
        log:error('Set snmp community failed, snmp community length is not correct')
        return false
    end
    return true
end

--- 设置snmp长密码使能状态
---@param sub_block any
---@param data_len any
---@param data any
---@param ctx any
function account_service_ipmi:set_snmp_long_community_enabled(sub_block, data_len, data, ctx)
    if sub_block ~= 0 or data_len ~= 1 or #data ~= 1 then
        ctx.operation_log.result = 'enabled_long_failed'
        log:info('Set SNMP long community enalbed failed, sub block selector or length is invalid')
        error(err.invalid_parameter())
    end
    data = string.byte(data)
    self.m_account_config:set_long_community_enabled(LONG_COMMUNITY_ENABLED[data])

    self.m_update_config:emit('LongCommunityEnabled', LONG_COMMUNITY_ENABLED[data])
    local operation = LONG_COMMUNITY_ENABLED[data] and 'Enable' or 'Disable'
    ctx.operation_log.params.operation = operation
    ctx.operation_log.result = 'enabled_long_success'
end

function account_service_ipmi:get_first_login_policy_by_id(req, ctx)
    local userid = req.UserId
    local policy = self.m_account_service:get_first_login_policy_by_id(userid)
    local ret_val = 0
    if policy == enum.FirstLoginPolicy.PromptPasswordReset then
        ret_val = string.char(err_cfg.STATE_DISABLE)
    elseif policy == enum.FirstLoginPolicy.ForcePasswordReset then
        ret_val = string.char(err_cfg.STATE_ENABLE)
    else
        log:error("invalid FirstLoginPolicy value(%s)", policy)
        error(base_msg.InternalError())
    end

    local rsp = ipmi_cmds.GetFirstLoginModifyPolicy.rsp.new()
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.Length = #ret_val
    rsp.Data = ret_val
    return rsp
end

function account_service_ipmi:get_history_password_count(req, ctx)
    local ret_val = string.char(self.m_account_config:get_history_password_count())
    local rsp = ipmi_cmds.GetHistoryPwdCheckCount.rsp.new()
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.Length = #ret_val
    rsp.Data = ret_val
    return rsp
end

function account_service_ipmi:get_weak_pwd_dictionary_enable(req, ctx)
    local ret_val = string.char(self.m_account_config:get_weak_pwd_dictionary_enable() and
        err_cfg.STATE_ENABLE or err_cfg.STATE_DISABLE)
    local rsp = ipmi_cmds.GetWeakPwdDictionaryEnabled.rsp.new()
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.Length = #ret_val
    rsp.Data = ret_val
    return rsp
end

function account_service_ipmi:get_emergency_login_account(req, ctx)
    local ret_val = string.char(self.m_account_config:get_emergency_account())
    local rsp = ipmi_cmds.GetEmergencyLoginAccount.rsp.new()
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.Length = #ret_val
    rsp.Data = ret_val
    return rsp
end

function account_service_ipmi:get_initial_password_prompt_enable(req, ctx)
    local state = self.m_account_config:get_initial_password_prompt_enable()
    local ret_val = string.char(state and err_cfg.STATE_ENABLE or err_cfg.STATE_DISABLE)

    local rsp = ipmi_cmds.GetInitialPasswordPromptEnable.rsp.new()
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.Length = #ret_val
    rsp.Data = ret_val
    return rsp
end

function account_service_ipmi:set_emergency_login_account(req, ctx)
    if req.Length ~= 0x01 or req.Length ~= #req.Data then
        log:error("Length(%d) of Data error", req.Length)
        error(err.invalid_parameter())
    end
    local account_id = string.byte(req.Data)
    if account_id ~= 0 and (account_id < 2 or account_id > 17) then
        log:error("Invalid account : %d", account_id)
        error(err.invalid_parameter())
    end
    if account_id == 0 then
        ctx.operation_log.result = 'remove'
    end
    self.m_account_service:set_emergency_account(ctx, account_id)
    self.m_account_service.m_config_changed:emit('EmergencyLoginAccountId', account_id)

    local rsp = ipmi_cmds.SetEmergencyLoginAccount.rsp.new()
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    return rsp
end

function account_service_ipmi:set_initial_password_prompt_enable(req, ctx)
    if req.Length ~= 0x01 or req.Length ~= #req.Data then
        log:error("Length(%d) of Data error", req.Length)
        error(err.invalid_parameter())
    end
    local data = string.byte(req.Data)
    local value
    if data == err_cfg.STATE_DISABLE then
        value = false
    elseif data == err_cfg.STATE_ENABLE then
        value = true
    else
        log:error("Invalid data : %d", data)
        error(err.invalid_parameter())
    end
    ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
    self.m_account_service:set_initial_password_prompt_enable(value)
    self.m_account_service.m_config_changed:emit('InitialPasswordPromptEnable', value)

    local rsp = ipmi_cmds.SetInitialPasswordPromptEnable.rsp.new()
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    return rsp
end

function account_service_ipmi:set_weak_pwd_dictionary_enable(req, ctx)
    local length = req.Length
    if length ~= 0x01 or length ~= #req.Data then
        log:error("Data input length error")
        error(err.invalid_parameter())
    end

    local control = string.byte(req.Data)
    if control > err_cfg.STATE_ENABLE or control < err_cfg.STATE_DISABLE then
        log:error("Control val input error")
        error(err.invalid_parameter())
    end
    ctx.operation_log.operation = "WeakPasswordDictionaryEnabled"
    local enable = value_bool_map[control]
    ctx.operation_log.params.state = enable and "Enable" or "Disable"
    self.m_account_config:set_weak_pwd_dictionary_enable(enable)
    self.m_account_service.m_config_changed:emit("WeakPasswordDictionaryEnabled", enable)

    local rsp = ipmi_cmds.SetWeakPwdDictionaryEnabled.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = utils.get_manufacture_id()
    return rsp
end

function account_service_ipmi:set_first_login_passwd_modify_policy(req, ctx)
    local length = req.Length
    if length ~= 0x01 or length ~= #req.Data then
        log:error("Length of Data error")
        error(err.invalid_parameter())
    end
    local control = string.byte(req.Data)
    if control > err_cfg.STATE_ENABLE or control < err_cfg.STATE_DISABLE then
        log:error("Control val input error")
        error(err.invalid_parameter())
    end
    local userid = req.UserId
    utils.check_ipmi_account_id(userid)
    ctx.operation_log.operation = "FirstLoginPolicy"
    local policy = control == 0x00 and enum.FirstLoginPolicy.PromptPasswordReset:value() or
        enum.FirstLoginPolicy.ForcePasswordReset:value()
    self.m_account_service.m_account_collection:set_first_login_policy(ctx, userid, policy)
    self.m_account_service.m_account_collection.m_account_changed:emit(userid, "FirstLoginPolicy", policy)

    local rsp = ipmi_cmds.SetFirstLoginModifyPolicy.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = utils.get_manufacture_id()
    return rsp
end

function account_service_ipmi:set_history_passwd_check_count(req, ctx)
    local length = req.Length
    if length ~= 0x01 or length ~= #req.Data then
        log:error("Length of Data error")
        error(err.invalid_parameter())
    end
    local data = string.byte(req.Data)
    ctx.operation_log.operation = 'HistoryPasswordCount'
    ctx.operation_log.params = { count = data }
    self.m_account_service:set_history_password_count(data)
    if data == 0 then
        ctx.operation_log.result = 'disable'
    end
    self.m_account_service.m_config_changed:emit('HistoryPasswordCount', data)

    local rsp = ipmi_cmds.SetHistoryPwdCheckCount.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = utils.get_manufacture_id()
    return rsp
end

function account_service_ipmi:set_account_name(req, ctx)
    local rsp = ipmi_cmds.SetUserName.rsp.new()
    self.m_ipmi_running_record:proxy(req, rsp, ctx, "set_account_name", function(req, ctx)
        return self.m_account_service:set_ipmi_user_name(req, ctx)
    end)
    return rsp
end

function account_service_ipmi:set_account_password(req, rsp, ctx)
    self.m_ipmi_running_record:proxy(req, rsp, ctx, "set_password", function(req, ctx, operation)
        return self.m_account_service:ipmi_set_account_password(req, ctx)
    end)
    return rsp
end

function account_service_ipmi:set_account_access(req, ctx)
    local rsp = ipmi_cmds.SetUserAccess.rsp.new()
    self.m_ipmi_running_record:proxy(req, rsp, ctx, "set_access", function(req, ctx)
        return self.m_account_service:set_ipmi_user_access(req, ctx)
    end)
    return rsp
end

function account_service_ipmi:set_vnc_password(req, ctx)
    local rsp = ipmi_cmds.SetVncPassword.rsp.new()
    local ret = err_cfg.USER_OPER_SUCCESS
    local handler_account_id
    if req.ManufactureId ~= utils.get_manufacture_id() then
        log:error("ManufactureId is error")
        error(err.invalid_parameter())
    end
    if req.Length ~= #req.Password or req.Length > 8 or #req.Password > 8 then
        log:error("Data input length error")
        error(custom_msg.IPMIInvalidCommand())
    end

    self.m_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)

    if ctx.ChanType == enum.IpmiChannelType.IPMI_HOST:value() then 
        ctx.operation_log.operation = 'SkipLog'
        handler_account_id = config.IPMI_ACCOUNT_ID
    else
        local account = self.m_account_service:get_account_data_by_name(ctx.session.user.name)
        handler_account_id = account.Id
    end

    if req.Length == 0x01 and string.byte(req.Password) == 0x00 then
        self.m_account_collection.collection[config.VNC_ACCOUNT_ID]:clear_vnc_password()
    else
        ret = self.m_account_service:set_account_password(ctx, handler_account_id,
            config.VNC_ACCOUNT_ID, req.Password)
    end
    rsp.CompletionCode = ret
    rsp.ManufactureId = utils.get_manufacture_id()
    return rsp
end

--- 设置用户密码前n字节比对信息
---@param req any
---@param ctx any
function account_service_ipmi:set_user_name_password_compared_info(req, ctx)
    local rsp = ipmi_cmds.SetUserPasswordCompareInfo.rsp.new()
    local ret = err_cfg.USER_OPER_SUCCESS

    if req.ManufactureId ~= utils.get_manufacture_id() then
        log:error("ManufactureId is error")
        error(custom_msg.IPMIInvalidCommand())
    end
    local enabled = req.CompareEnabled
    if enabled > err_cfg.STATE_ENABLE or enabled < err_cfg.STATE_DISABLE then
        log:error("Data input(%d) length error", enabled)
        error(custom_msg.IPMIInvalidCommand())
    end
    local length = req.CompareLength
    local enabled_bool = value_bool_map[enabled]
    ctx.operation_log.params.state = enabled_bool and "Enable" or "Disable"
    self.m_account_config:set_user_name_password_compared_length(length)
    self.m_account_service.m_config_changed:emit("UserNamePasswordPrefixCompareLength", length)
    local result, err = pcall(self.m_account_config.set_user_name_password_compared_enabled,
        self.m_account_config, enabled_bool)
    if not result then
        ctx.operation_log.result = 'enable_failed'
        log:error('%s username password check failed', enabled_bool and "Enable" or "Disable")
        error(err)
    end
    self.m_account_service.m_config_changed:emit("UserNamePasswordPrefixCompareEnabled", enabled_bool)
    rsp.CompletionCode = ret
    rsp.ManufactureId = utils.get_manufacture_id()
    return rsp
end

--- 获取用户密码前n字节比对信息
---@param req any
function account_service_ipmi:get_user_name_password_compared_info(req)
    if req.ManufactureId ~= utils.get_manufacture_id() then
        log:error("ManufactureId is error")
        error(custom_msg.IPMIInvalidCommand())
    end
    local rsp = ipmi_cmds.GetUserPasswordCompareInfo.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.CompareEnabled = self.m_account_config:get_user_name_password_compared_enabled() and
        err_cfg.STATE_ENABLE or err_cfg.STATE_DISABLE
    rsp.CompareLength = self.m_account_config:get_user_name_password_compared_length()
    return rsp
end

function account_service_ipmi:get_inter_chassis_role(req, ctx)
    if not self.is_support_inter_chassis_auth then
        error(base_msg.ActionNotSupported('get inter chassis account role'))
    end
    if req.ManufactureId ~= utils.get_manufacture_id() then
        log:error("ManufactureId is error")
        error(custom_msg.IPMIInvalidCommand())
    end
    local inter_chassis_account = self.m_account_collection.collection[config.INTER_CHASSIS_ACCOUNT_ID]
    local rsp = ipmi_cmds.GetInterChassisRoleId.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.Data = string.pack("B", inter_chassis_account:get_role_id())
    rsp.DataLength = 1
    return rsp
end

function account_service_ipmi:get_inter_chassis_interface(req, ctx)
    if not self.is_support_inter_chassis_auth then
        error(base_msg.ActionNotSupported('get inter chassis account login interface'))
    end
    if req.ManufactureId ~= utils.get_manufacture_id() then
        log:error("ManufactureId is error")
        error(custom_msg.IPMIInvalidCommand())
    end
    local inter_chassis_account = self.m_account_collection.collection[config.INTER_CHASSIS_ACCOUNT_ID]
    local rsp = ipmi_cmds.GetInterChassisRoleId.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.Data = string.pack("B", inter_chassis_account:get_interface())
    rsp.DataLength = 1
    return rsp
end

return singleton(account_service_ipmi)
