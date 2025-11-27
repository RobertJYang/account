-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local iam_err = require 'iam.errors'
local iam_client = require 'iam.client'
local ipmi_cmds = require 'iam.ipmi.ipmi'
local utils = require 'utils'
local SessionService = require 'service.session_service'
local iam_enum = require 'class.types.types'
local err_cfg = require 'error_config'
local custom_msg = require 'messages.custom'
local ipmi_types = require 'ipmi.types'
local user_config = require 'user_config'

local INNER_SESSION_INFO = {
    [iam_enum.IpmiChannelType.IPMI_BMA:value()] = {
        UserName = user_config.USER_NAME_FOR_BMA,
        InnerSessionType = iam_enum.RedfishInnerSessionType.BMA:value(),
        ChannelName = 'SMS'
    },
    [iam_enum.IpmiChannelType.IPMI_SMM:value()] = {
        UserName = user_config.USER_NAME_FOR_HMM,
        InnerSessionType = iam_enum.RedfishInnerSessionType.HMM:value(),
        ChannelName = 'ICMB'
    }
}

local SessionIpmi = class()

function SessionIpmi:ctor()
    self.m_session_service = SessionService.get_instance()
end

-- 以下是ipmi接口入口
-- ipmi设置web会话超时
function SessionIpmi:set_web_timeout(req, ctx)
    local length = req.Length
    local property = 'SessionTimeout'
    ctx.operation_log.operation = property
    ctx.operation_log.params = { type = "WEB" }
    if length ~= 0x02 or length ~= #req.Data then
        log:error("Length of Data error")
        error(iam_err.invalid_parameter())
    end
    local data = string.unpack(">H", req.Data)
    local time = data * 60
    ctx.operation_log.params.time = data
    ctx.operation_log.params.timeunit = 'minutes'
    self.m_session_service:set_session_timeout(ctx, iam_enum.SessionType.GUI, time)
    local gui_session = self.m_session_service.m_session_service_collection[iam_enum.SessionType.GUI:value()]
    gui_session.m_update_session_service:emit(iam_enum.SessionType.GUI, property, time)

    local rsp = ipmi_cmds.SetWebTimeOut.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = req.ManufactureId
    return rsp
end

-- ipmi获取web会话超时
function SessionIpmi:get_web_timeout(req, ctx)
    local minute = self.m_session_service:get_session_timeout(iam_enum.SessionType.GUI) // 60
    local ret_val = string.pack(">H", minute)

    local rsp = ipmi_cmds.GetWebTimeOut.rsp.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.Length = #ret_val
    rsp.Data = ret_val
    return rsp
end

-- ipmi获取会话模式
function SessionIpmi:get_session_mode(req, ctx)
    local mode = self.m_session_service:get_session_mode(iam_enum.SessionType.new(req.SessionType)):value()
    local ret_val = string.pack(">B", mode)

    local rsp = ipmi_cmds.GetSessionMode.rsp.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.Length = 0x01
    rsp.Data = ret_val
    return rsp
end

-- ipmi获取会话超时时间
function SessionIpmi:get_session_timeout(req, ctx)
    local timeout = self.m_session_service:get_session_timeout(iam_enum.SessionType.new(req.SessionType))
    local ret_val = string.pack(">I4", timeout)
    if req.SessionType ~= iam_enum.SessionType.Redfish:value() then
        timeout = timeout // 60
        ret_val = string.pack(">H", timeout)
    end

    local rsp = ipmi_cmds.GetSessionTimeout.rsp.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.Length = #ret_val
    rsp.Data = ret_val
    return rsp
end

-- ipmi获取最大会话数
function SessionIpmi:get_session_max_count(req, ctx)
    local count = self.m_session_service:get_session_max_count(iam_enum.SessionType.new(req.SessionType))
    local ret_val = string.pack(">B", count)

    local rsp = ipmi_cmds.GetSessionMaxCount.rsp.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.Length = 0x01
    rsp.Data = ret_val
    return rsp
end

-- ipmi设置会话模式(VIDEO仅支持设置独占模式，SSO、KVM、VNC不支持设置会话模式)
function SessionIpmi:set_session_mode(req, ctx)
    local length = req.Length
    local session_mode = string.unpack(">B", req.SessionMode)
    local session_type = iam_enum.SessionType.new(req.SessionType)
    local mode = iam_enum.OccupationMode.new(session_mode)
    local mode_name = mode == iam_enum.OccupationMode.Shared and 'Share' or 'Exclusive'
    ctx.operation_log.params = { type = tostring(session_type), mode = mode_name }

    if length ~= #req.SessionMode then
        log:error("Length of Data error")
        error(custom_msg.IPMIRequestLengthInvalid())
    end
    if req.SessionType ~= iam_enum.SessionType.GUI:value() and
        req.SessionType ~= iam_enum.SessionType.Redfish:value() and
        req.SessionType ~= iam_enum.SessionType.VIDEO:value() then
        log:error("Session type(%d) is not supported", req.SessionType)
        error(custom_msg.IPMIInvalidCommandOnLun())
    end

    self.m_session_service:set_session_mode(ctx, session_type, mode)
    self.m_session_service.m_session_service_collection[session_type:value()].m_update_session_service:emit(
        session_type, 'SessionMode', mode:value())

    local rsp = ipmi_cmds.SetSessionMode.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = req.ManufactureId
    return rsp
end

-- ipmi设置会话超时
function SessionIpmi:set_session_timeout(req, ctx)
    local length = #req.SessionTimeout
    local session_type = iam_enum.SessionType.new(req.SessionType)
    local data
    ctx.operation_log.params = { type = tostring(session_type) }
    self:ipmi_set_session_config_input_check(req, length)
    if req.SessionType == iam_enum.SessionType.Redfish:value() then
        data = string.unpack(">I4", req.SessionTimeout)
        ctx.operation_log.params.time = data
        ctx.operation_log.params.timeunit = 'seconds'
        self.m_session_service:set_session_timeout(ctx, session_type, data)
        self.m_session_service.m_session_service_collection[session_type:value()].m_update_session_service:emit(
            session_type, 'SessionTimeout', data)
    else
        data = string.unpack(">H", req.SessionTimeout)
        ctx.operation_log.params.time = data
        ctx.operation_log.params.timeunit = 'minutes'
        local time = data * 60
        self.m_session_service:set_session_timeout(ctx, session_type, time)
        self.m_session_service.m_session_service_collection[session_type:value()].m_update_session_service:emit(
            session_type, 'SessionTimeout', time)
    end

    local rsp = ipmi_cmds.SetSessionTimeout.rsp.new()
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    rsp.ManufactureId = req.ManufactureId
    return rsp
end

-- ipmi获取认证token
function SessionIpmi:ipmi_get_auth_token(req, ctx)
    local rsp = ipmi_cmds.IpmiGetAuthToken.rsp.new()
    local inner_token
    local context_info = {}
    self:ipmi_get_auth_token_input_check(req, ctx, context_info)
    inner_token = self.m_session_service:get_redfish_inner_token(context_info)

    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.Token = inner_token
    rsp.End = 0
    return rsp
end

-- ipmi设置kvmkey
function SessionIpmi:ipmi_set_kvm_key(req, ctx)
    local secret_key = req.SecretKey
    local user_name = req.UserName
    local mode = iam_enum.OccupationMode.new(req.SessionMode)

    self:ipmi_set_kvm_key_input_check(req)

    local kvm_key = ''
    for index = 1, #secret_key do
        kvm_key = kvm_key .. string.format('%02x', string.byte(secret_key, index))
    end
    local ctx_set_kvm_key = {
        UserName = string.gsub(user_name, "%z*$", ""),
        ClientAddr = ctx.client.ip,
        Interface = 'IPMI'
    }
    self.m_session_service:set_kvm_key(ctx_set_kvm_key, kvm_key, mode)

    local rsp = ipmi_cmds.SetKvmKey.rsp.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    return rsp
end
-- ipmi接口结束

function SessionIpmi:verify_channel_privilege(chan_type, role_id)
    local ok, obj = pcall(function()
        return iam_client:GetIpmiCoreObjects()['/bmc/kepler/IpmiCore']
    end)
    -- 获取IpmiCore对象失败\无法获取通道权限属性\对应通道权限属性为空创建操作员权限
    if not ok or not obj or not obj['ChannelAccesses'] or
        not obj['ChannelAccesses'][INNER_SESSION_INFO[chan_type].ChannelName] then
        log:notice("Get channel valid privilege failed, set role to operator")
        return iam_enum.RoleType.Operator:value()
    end
    local chan_role_name = obj['ChannelAccesses'][INNER_SESSION_INFO[chan_type].ChannelName]
    chan_role_name = chan_role_name == 'User' and 'CommonUser' or chan_role_name
    if role_id > iam_enum.RoleType.Administrator:value() or
        role_id < iam_enum.RoleType.CommonUser:value() or
        iam_enum.RoleType[chan_role_name]:value() == iam_enum.RoleType.NoAccess:value() then
        log:error('Unsupport role id(%d) to create inner session', role_id)
        error(custom_msg.IPMICommandCannotExecute())
    end
    if role_id > iam_enum.RoleType[chan_role_name]:value() then
        log:notice('Unsupport to create role(%s) inner session, change role to channel access : %s',
            iam_enum.RoleType.new(role_id), chan_role_name)
        role_id = iam_enum.RoleType[chan_role_name]:value()
    end
    return role_id
end

-- ipmi获取带内token入参检查
function SessionIpmi:ipmi_get_auth_token_input_check(req, ctx, context_info)
    local ip_addr = req.IpAddress
    local ip_mode = req.IpMode
    local chan_type = ctx.ChanType
    local role_id = req.RoleId
    local session_type = req.SessionType
    if not INNER_SESSION_INFO[chan_type] then
        log:error("Chan type(%d) is not supported", chan_type)
        error(custom_msg.IPMIInvalidCommandOnLun())
    end
    -- inner_token只支持redfish类型会话
    if session_type ~= iam_enum.SessionType.Redfish:value() then
        log:error("Session type(%d) is not supported", session_type)
        error(custom_msg.IPMIInvalidCommandOnLun())
    end
    if ip_mode == iam_enum.IpMode.IPV4:value() then
        context_info.ip_addr = utils.ipv4_binary_to_string(ip_addr)
    elseif ip_mode == iam_enum.IpMode.IPV6:value() then
        context_info.ip_addr = utils.simplify_ipmi_ipv6_req(ip_addr)
    else
        log:error("Ip mode(%d) is not supported", ip_mode)
        error(custom_msg.IPMIOutOfRange())
    end
    context_info.role_id = self:verify_channel_privilege(chan_type, role_id)
    context_info.user_name = INNER_SESSION_INFO[chan_type].UserName
    context_info.inner_session_type = INNER_SESSION_INFO[chan_type].InnerSessionType
end

-- ipmi设置kvmkey入参检查
function SessionIpmi:ipmi_set_kvm_key_input_check(req)
    local reserved1 = req.Reserved1
    local offset = req.Offset
    local length = req.Length
    local reserved2 = req.Reserved2
    local mode = req.SessionMode
    -- 设置kvm key不涉及超长数据
    if reserved1 ~= 0x00 or offset ~= 0x00 then
        log:error('Set kvm key parameter invalid')
        error(custom_msg.IPMIRequestLengthLarge())
    end
    -- length及reserved2(module;Authentication key length)头部信息固定
    if length ~= 0x37 or reserved2 ~= 0x2400 then
        log:error('Set kvm key length invalid')
        error(custom_msg.IPMIRequestLengthInvalid())
    end
    -- 会话模式enum(Shared:0,Exclusive:1)
    if mode ~= 0x00 and mode ~= 0x01 then
        log:error('Set kvm key mode invalid')
        error(custom_msg.IPMIOutOfRange())
    end
end

-- ipmi设置会话配置入参检查
function SessionIpmi:ipmi_set_session_config_input_check(req, length)
    local session_type = req.SessionType
    if req.Length ~= length then
        log:error("Length of Data error")
        error(custom_msg.IPMIRequestLengthInvalid())
    end
    if session_type ~= iam_enum.SessionType.GUI:value() and session_type ~= iam_enum.SessionType.Redfish:value() and
        session_type ~= iam_enum.SessionType.KVM:value() and session_type ~= iam_enum.SessionType.VNC:value() and
        session_type ~= iam_enum.SessionType.VIDEO:value() then
        log:error("Session type(%d) is not supported", session_type)
        error(custom_msg.IPMIInvalidCommandOnLun())
    end
end

-- 销毁SSO会话
function SessionIpmi:delete_sso_session(req, ctx)
    local token_length = req.length
    local token = req.token

    -- 非IPMBETH通道发送过来的消息返回无效的命令
    if ctx.ChanType ~= iam_enum.IpmiChannelType.IPMI_SMM:value() then
        ctx.operation_log.result = 'ssoipmifail'
        log:error('Invalid channel(%s).', ctx.ChanType)
        error(custom_msg.IPMIInvalidCommand())
    end

    -- token长度验证
    if #token ~= token_length then
        ctx.operation_log.result = 'ssoipmifail'
        log:error('The length of token is not correct, length:%d, token length:%d!', #token, token_length)
        error(custom_msg.IPMIOutOfRange())
    end

    -- 获取session_id
    local ok, session_id = pcall(function()
        return self.m_session_service:validate_session(iam_enum.SessionType.SSO, token)
    end)
    if not ok then
        ctx.operation_log.result = 'ssoipmifail'
        log:error('Get sso session failed.err:%s', session_id)
        error(custom_msg.IPMICommandCannotExecute())
    end
    -- 销毁SSO会话
    local err
    ok, err = pcall(function() self.m_session_service:delete_session(ctx,
        session_id, iam_enum.SessionLogoutType.SessionLogout) end)
    if not ok then
        ctx.operation_log.result = 'ssoipmifail'
        log:error('Delete sso session failed.err info:%s', err)
        error(err)
    end
    local rsp = ipmi_cmds.DestorySSOToken.rsp.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    return rsp
end

return singleton(SessionIpmi)
