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
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local cls_mng = require 'mc.class_mgnt'
local class = require 'mc.class'
local context = require 'mc.context'
local base_msg = require 'messages.base'
local iam_enum = require 'class.types.types'
local iam_client = require 'iam.client'
local account_utils = require 'infrastructure.account_utils'
local privilege = require 'domain.privilege'
local session_service = require 'service.session_service'
local operation_logger = require 'interface.operation_logger'

local INTERFACE_SESSIONS = 'bmc.kepler.SessionService.Sessions'
local SESSIONS_MDB_PATH = '/bmc/kepler/SessionService/Sessions'

local SessionsMdb = class()
function SessionsMdb:ctor(bus)
    self.m_session_service = session_service.get_instance()
    self.m_bus = bus
end

function SessionsMdb:init()
    self:start_fructrl_properties_listenning()
    self:start_channel_privilege_listenning()
    self:register_sessions_signal()
end

function SessionsMdb:register_sessions_signal()
    -- 订阅网络模块ip变更信号
    iam_client:SubscribeIpv4ChangedSignal(function(...)
        self:ip_changed(true, ...)
    end)
    iam_client:SubscribeIpv6ChangedSignal(function(...)
        self:ip_changed(false, ...)
    end)

    local cls_sessions = cls_mng("Sessions"):get(SESSIONS_MDB_PATH)
    self:watch_sessions_property_hook(cls_sessions)
end

function SessionsMdb:watch_sessions_property_hook(sessions_obj)
    sessions_obj[INTERFACE_SESSIONS].property_before_change:on(function (name, value, sender)
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

function SessionsMdb:start_fructrl_properties_listenning()
    iam_client:OnFruCtrlPropertiesChanged(function(values)
        if (values.PowerState and values.PowerState:value() == 'OFF') or
            (values.SysResetDetected and values.SysResetDetected:value() == 1) then
                self.m_session_service:delete_inner_session_due_to_env_changed(1)
        end
    end)
end

function SessionsMdb:start_channel_privilege_listenning()
    iam_client:OnIpmiCorePropertiesChanged(function(values)
        local channel_access = values.ChannelAccesses:value()
        local ok, ret = pcall(function()
            -- ipmi通道权限控制变更
            self.m_session_service:delete_inner_session_due_to_env_changed(2, channel_access)
        end)
        if not ok then
            log:notice('ipmi channel accesses changed, delete inner session failed, error : %s', ret)
        end
    end)
end

-- 属性监听钩子
SessionsMdb.watch_property_hook = {
    ValidateSsoClient =  operation_logger.proxy(function(self, ctx, enabled)
        ctx.operation_log.params = { state = enabled and 'Enable' or 'Disable' }
        self.m_session_service:set_validate_sso_client_addr(enabled)
    end, 'ValidateSsoClient'),
    SsoEnabled =  operation_logger.proxy(function(self, ctx, enabled)
        ctx.operation_log.params = { state = enabled and 'Enable' or 'Disable' }
        self.m_session_service:set_sso_enabled(enabled)
    end, 'SsoEnabled')
}

-- ip变更后，踢出会话的业务处理
function SessionsMdb:ip_changed(is_ipv4)
    local ctx = nil -- 需要网络模块补充
    local ip_type = is_ipv4 and iam_enum.IpType.V4 or iam_enum.IpType.V6
    self.m_session_service:delete_all_session(ctx, iam_enum.SessionLogoutType.BMCConfigChange,
        iam_enum.SessionType.All, ip_type)
end

function SessionsMdb:new_session(ctx, user_name, password, type, domain, ip, extra_data)
    ctx.operation_log.params = { username = user_name, ip = ip }
    if type == iam_enum.SessionType.SSO:value() then
        ctx.operation_log.operation = 'NewSsoSession'
    end
    type = iam_enum.SessionType.new(type)
    return self.m_session_service:new_session(ctx, user_name, password, type, domain, ip, extra_data)
end

function SessionsMdb:new_session_by_sso(ctx, sso_token, session_type, session_mode)
    -- 初始化日志参数
    ctx.operation_log.params = { username = 'Unknown', ip = ctx.ClientAddr or '127.0.0.1', type = 'Unknown' }
    session_type = iam_enum.SessionType.new(session_type)
    session_mode = iam_enum.OccupationMode.new(session_mode)
    return self.m_session_service:new_session_by_sso(ctx, sso_token, session_type, session_mode)
end

-- 实现remote_console接口
function SessionsMdb:new_remote_console_session(ctx, token, session_type, session_mode)
    if ctx.SystemId == nil then
        ctx.SystemId = 1 --SystemId默认为1
    end
    ctx.operation_log.params = { username = ctx.UserName, ip = ctx.ClientAddr, systemid = ctx.SystemId }
    session_type = iam_enum.SessionType.new(session_type)
    session_mode = iam_enum.OccupationMode.new(session_mode)
    return self.m_session_service:new_remote_console_session(ctx, token, session_type, session_mode)
end

-- 新建vnc会话
function SessionsMdb:new_vnc_session(ctx, ciphertext, auth_challenge, session_mode)
    return self.m_session_service:new_vnc_session(ctx, ciphertext, auth_challenge, session_mode)
end

-- 设置KvmKey
function SessionsMdb:set_kvm_key(ctx, kvm_key, mode)
    mode = iam_enum.OccupationMode.new(mode)
    ctx.operation_log.params = { mode = tostring(mode) }
    self.m_session_service:set_kvm_key(ctx, kvm_key, mode)
end

--- 删除会话接口
function SessionsMdb:delete_session(ctx, session_id, clear_type)
    -- 查找待删除的会话
    local session = self.m_session_service:get_session_by_session_id(session_id)
    if not session then
        ctx.operation_log.result = tostring(clear_type)
        -- 北向已拦截，此处仅兜底措施避免极端场景出现
        ctx.operation_log.params = { username = 'UNKNOWN', ip = 'UNKNOWN', session_type = 'UNKNOWN' }
        error(self.m_session_service:check_session_error(session_id))
    end
    -- 外层会获取session，预设置ctx
    ctx.operation_log.result = tostring(clear_type)
    ctx.operation_log.params = { username = session.m_username,
        ip = session.m_ip, session_type = tostring(session.m_session_type_name) }

    -- 校验当前操作用户权限是否满足
    -- 踢出别人的会话是操作性行为，上下文必然有权限
    -- 踢出自己的会话无需校验权限（组件内调用delete_session接口时可能存在上下文无权限的场景）
    if ctx.UserName ~= session.m_username then
        -- 获取当前操作权限
        local handle_privilege = privilege:num_to_array(ctx.Privilege)
        if not account_utils.privilege_validator(handle_privilege, iam_enum.PrivilegeType.UserMgmt) then
            log:error('There was insufficient privilege to delete session')
            error(base_msg.InsufficientPrivilege())
        end
    end
    clear_type = iam_enum.SessionLogoutType.new(clear_type)
    self.m_session_service:delete_session(ctx, session_id, clear_type)
end

return singleton(SessionsMdb)
