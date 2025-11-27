-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local session_class = require 'domain.session'
local class = require 'mc.class'
local signal = require 'mc.signal'
local log = require 'mc.logging'
local initiator = require 'mc.initiator'
local base_msg = require 'messages.base'
local iam_core = require 'iam_core'
local iam_enum = require 'class.types.types'

local SessionType = class()
function SessionType:ctor(session_service_db)
    self.m_session_collection = {}
    self.m_kvm_session_mode = {}
    self.m_session_service_config = session_service_db
    self.m_create_session = signal.new()
    self.m_delete_session = signal.new()
    self.m_update_session = signal.new()
    self.m_update_session_service = signal.new()
end

--- 创建会话
---@param account instance
---@param auth_type Enum
---@param ip string
---@return table
function SessionType:create(account, auth_type, ip, browser_type, sso_token)
    if not self:hava_free_session() then
        log:error("number of sessions exceeded limitd")
        error(base_msg.SessionLimitExceeded())
    end
    local new_session = session_class.new(account, self.m_session_service_config.SessionType,
        auth_type, ip, browser_type, sso_token)
    table.insert(self.m_session_collection, new_session)
    self.m_create_session:emit(new_session)
    return new_session
end

SessionType.logout_type_map_log = {
    SessionRelogin = 'User %s(%s) is forced to log out because the same user log in from another device',
    SessionTimeout = 'User %s(%s) logged out due to session timeout',
    SessionKickout = 'Kick user(username:%s|client type:%s|client IP:%s) out successfully',
    SessionLogout = 'User %s(%s) logout successfully',
    AccountConfigChange = 'User %s(%s) logged out due to user information change',
    BMCConfigChange = 'User %s(%s) logged out due to network configuration change'
}

--- 删除会话
---@param session_id string
function SessionType:delete(session_id)
    local session, index = self:get_session_by_session_id(session_id)
    if not session then
        error(base_msg.NoValidSession())
    end
    table.remove(self.m_session_collection, index)
    self.m_delete_session:emit(session_id)
    self:logout_security_log(session.m_username, session.m_ip)
end

--- 记录会话退出的操作日志
local function record_session_log_out_log(self, logout_type, del_session)
    local initiator_info = initiator.new(del_session.m_session_type_name, del_session.m_username, del_session.m_ip)
    if tostring(logout_type) == 'SessionKickout' then
        log:operation(initiator_info, 'iam', self.logout_type_map_log[tostring(logout_type)],
        del_session.m_username, tostring(del_session.m_session_type), del_session.m_ip)
    else
        log:operation(initiator_info, 'iam',
            self.logout_type_map_log[tostring(logout_type)], del_session.m_username, del_session.m_ip)
    end
end

--- 根据用户名删除会话
---@param username string
---@param logout_type Enum
function SessionType:delete_by_username(username, logout_type)
    local deleted_session_list = {}
    for index = #self.m_session_collection, 1, -1 do
        local session = self.m_session_collection[index]
        if username == session.m_username then
            table.remove(self.m_session_collection, index)
            self.m_delete_session:emit(session.m_session_id)
            record_session_log_out_log(self, logout_type, session)
            table.insert(deleted_session_list, session.m_session_id)
        end
    end
    return deleted_session_list
end

--- 根据域控制器和组信息删除对应远程会话
--- 需覆盖三种场景:
--- 1、LDAP使能关闭(不带controller_id和inner_id),都不匹配，踢出所有
--- 2、域控制器变更(仅有controller_id),只匹配controllerid
--- 3、组信息变更(controller_id和inner_id都有),都进行匹配
function SessionType:delete_remote_session(controller_id, inner_id, logout_type)
    local deleted_session_list = {}
    for index = #self.m_session_collection, 1, -1 do
        local session = self.m_session_collection[index]
        -- 只对存在remote_dict(远程会话标识)的会话进行处理
        if session.remote_dict then
            -- controller_id 包裹 inner_id，所以优先匹配 controller_id
            if controller_id and session.remote_dict.controller_id ~= controller_id then
                goto continue
            end

            if inner_id and (session.remote_dict.controller_inner_id & (0x1 << inner_id) == 0) then
                goto continue
            end

            -- 走到这里代表: 有且匹配 or 没有
            table.remove(self.m_session_collection, index)
            self.m_delete_session:emit(session.m_session_id)
            record_session_log_out_log(self, logout_type, session)
            table.insert(deleted_session_list, session.m_session_id)
        end
        ::continue::
    end
    return deleted_session_list
end

--- 删除所有会话，可以删除对应ip类型的会话
---@param logout_type Enum
function SessionType:delete_all_session(logout_type, ip_type)
    for index = #self.m_session_collection, 1, -1 do
        local session = self.m_session_collection[index]
        if ip_type == iam_enum.IpType.All or
            (ip_type == iam_enum.IpType.V4 and iam_core.vos_ipv4_addr_valid_check(session.m_ip) == 0) or
            (ip_type == iam_enum.IpType.V6 and iam_core.vos_ipv6_addr_valid_check(session.m_ip) == 0) then
            self:delete(session.m_session_id)
            record_session_log_out_log(self, logout_type, session)
        else
            log:info('session is not match, skip delete, session_type: %s', tostring(session.m_session_type))
        end
    end
end

function SessionType:delete_all_system_id_session(logout_type, ip_type, ctx)
    for index = #self.m_session_collection, 1, -1 do
        local session = self.m_session_collection[index]
        if (ip_type == iam_enum.IpType.All) or 
            (ip_type == iam_enum.IpType.V4 and iam_core.vos_ipv4_addr_valib_check(session.m_ip) == 0) or
            (ip_type == iam_enum.IpType.V6 and iam_core.vos_ipv6_addr_valib_check(session.m_ip) == 0) and 
            session.system_id == ctx.SystemId then
            self:delete(session.m_session_id)
            record_session_log_out_log(self, logout_type, session)
        else
            log:info('session is not match , skip delete, session_type: %s', tostring(session.m_session_type))
        end
    end
    
end

--- 根据Token获取会话
---@param token string
---@param csrf_token string
function SessionType:get_session_by_token(token, csrf_token)
    for _, session in pairs(self.m_session_collection) do
        if session.m_token == token and (session.m_csrf_token == csrf_token or csrf_token == nil) then
            return session
        end
    end
    return nil
end

--- 获取超时会话
function SessionType:get_timeout_session_list()
    local timeout_session_list = {}
    -- SessionTimeout为0时永不超时(KVM、VNC),直接返回
    if self.m_session_service_config.SessionTimeout == 0 then
        return timeout_session_list
    end
    for index = #self.m_session_collection, 1, -1 do
        local session = self.m_session_collection[index]
        -- 每5秒检查一次会话超时时间
        session.m_last_active_time = session.m_last_active_time + 5
        if session.m_last_active_time >= self:get_session_timeout() then
            table.insert(timeout_session_list, session)
        end
    end
    return timeout_session_list
end

--- 判断是否还有剩余创建会话数
function SessionType:hava_free_session()
    return #self.m_session_collection < self.m_session_service_config.SessionMaxCount
end

--- 根据会话ID获取会话
---@param session_id any
function SessionType:get_session_by_session_id(session_id)
    for index, session in pairs(self.m_session_collection) do
        if session_id == session.m_session_id then
            return session, index
        end
    end
    return nil
end

function SessionType:validate_session(cur_session)
    return cur_session.m_session_id
end

--- 设置会话服务最大会话数
---@param max_count number
function SessionType:set_session_max_count(max_count)
    self.m_session_service_config.SessionMaxCount = max_count
    self.m_session_service_config:save()
end

--- 获取会话服务最大会话数
function SessionType:get_session_max_count()
    return self.m_session_service_config.SessionMaxCount
end

--- 设置会话服务会话模式
---@param session_mode Enum
function SessionType:set_session_mode(session_mode)
    self.m_session_service_config.SessionModeDB = session_mode
    self.m_session_service_config:save()
end

--- 获取会话服务会话模式
function SessionType:get_session_mode()
    return self.m_session_service_config.SessionModeDB
end

--- 设置会话服务超时时间
---@param timestamp number
function SessionType:set_session_timeout(timestamp)
    if timestamp < self.timeout_min or timestamp > self.timeout_max or timestamp % 60 ~= 0 then
        log:error('SessionTimeout(%d) is out of range', timestamp)
        error(base_msg.PropertyValueNotInList(timestamp, 'SessionTimeout'))
    end
    self.m_session_service_config.SessionTimeout = timestamp
    self.m_session_service_config:save()
end

--- 获取会话服务超时时间
function SessionType:get_session_timeout()
    return self.m_session_service_config.SessionTimeout
end

--- 获取当前会话数量
function SessionType:get_session_count()
    return #self.m_session_collection
end

--- 记录登出安全日志
function SessionType:logout_security_log(user_name, ip) end

--- 获取当前会话类型
function SessionType:get_session_type()
    return self.m_session_service_config.SessionType
end

return SessionType
