-- Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local session_type_class = require 'domain.session_type.session_type'
local session_class = require 'domain.session'
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local vos = require 'utils.vos'
local iam_core = require 'iam_core'
local iam_enum = require 'class.types.types'
local user_config = require 'user_config'

local InterChassisSession = class(session_type_class)

function InterChassisSession:ctor()
    self.timeout_min = 300   -- 超时时间最短5分钟
    self.timeout_max = 28800 -- 超时时间最长480分钟
    self.max_session_count = 10 -- 最大会话数上限为10个
    self.min_session_count = 4  -- 最大会话数下限为4个
    self.m_session_collection_gui = {}
    self.m_session_collection_map = {
        [iam_enum.SessionType.Redfish:value()] = self.m_session_collection,
        [iam_enum.SessionType.GUI:value()] = self.m_session_collection_gui
    }
end

--- 创建会话
---@param account instance
---@param auth_type Enum
---@param ip string
---@return table
function InterChassisSession:create(account, auth_type, ip, browser_type, session_type)
    if not self:hava_free_session() then
        log:error("number of sessions exceeded limitd")
        error(base_msg.SessionLimitExceeded())
    end
    local new_session = session_class.new(account, self.m_session_service_config.SessionType,
        auth_type, ip, browser_type, nil)
    session_type = session_type or iam_enum.SessionType.Redfish
    table.insert(self.m_session_collection_map[session_type:value()], new_session)
    self.m_create_session:emit(new_session)
    return new_session
end

--- 删除会话
---@param session_id string
function InterChassisSession:delete(session_id)
    local session, index, session_type = self:get_session_by_session_id(session_id)
    if not session then
        error(base_msg.NoValidSession())
    end

    session_type = session_type or iam_enum.SessionType.Redfish
    table.remove(self.m_session_collection_map[session_type:value()], index)
    self.m_delete_session:emit(session_id)
    self:logout_security_log(session.m_username, session.m_ip)
end

--- 根据用户名删除会话
---@param username string
---@param logout_type Enum
function InterChassisSession:delete_by_username(username, logout_type)
    local deleted_session_list = {}
    for _, session_collection in pairs(self.m_session_collection_map) do
        for index = #session_collection, 1, -1 do
            local session = session_collection[index]
            if username == session.m_username then
                table.remove(session_collection, index)
                self.m_delete_session:emit(session.m_session_id)
                table.insert(deleted_session_list, session.m_session_id)
            end
        end
    end
    return deleted_session_list
end

--- 根据IP删除会话
---@param ip string
---@param logout_type Enum
function InterChassisSession:delete_by_ip(ip, logout_type)
    local deleted_session_list = {}
    for _, session_collection in pairs(self.m_session_collection_map) do
        for index = #session_collection, 1, -1 do
            local session = session_collection[index]
            if ip == session.m_ip then
                table.remove(session_collection, index)
                self.m_delete_session:emit(session.m_session_id)
                table.insert(deleted_session_list, session.m_session_id)
            end
        end
    end
    return deleted_session_list
end

--- 删除所有会话，可以删除对应ip类型的会话
---@param logout_type Enum
---@param ip_type Enum
function InterChassisSession:delete_all_session(logout_type, ip_type)
    for _, session_collection in pairs(self.m_session_collection_map) do
        for index = #session_collection, 1, -1 do
            local session = session_collection[index]
            if ip_type == iam_enum.IpType.All or
                (ip_type == iam_enum.IpType.V4 and iam_core.vos_ipv4_addr_valid_check(session.m_ip) == 0) or
                (ip_type == iam_enum.IpType.V6 and iam_core.vos_ipv6_addr_valid_check(session.m_ip) == 0) then
                self:delete(session.m_session_id)
            else
                log:info('session is not match, skip delete, session_type: %s', tostring(session.m_session_type))
            end
        end
    end
end

function InterChassisSession:delete_all_system_id_session(logout_type, ip_type, ctx)
    for _, session_collection in pairs(self.m_session_collection_map) do
        for index = #session_collection, 1, -1 do
            local session = session_collection[index]
            if (ip_type == iam_enum.IpType.All) or 
                (ip_type == iam_enum.IpType.V4 and iam_core.vos_ipv4_addr_valib_check(session.m_ip) == 0) or
                (ip_type == iam_enum.IpType.V6 and iam_core.vos_ipv6_addr_valib_check(session.m_ip) == 0) and 
                session.system_id == ctx.SystemId then
                self:delete(session.m_session_id)
            else
                log:info('session is not match , skip delete, session_type: %s', tostring(session.m_session_type))
            end
        end
    end
end

--- 根据Token获取会话
---@param token string
---@param csrf_token string
---@param session_type Enum
function InterChassisSession:get_session_by_token(token, csrf_token, session_type)
    session_type = session_type or iam_enum.SessionType.Redfish
    for _, session in pairs(self.m_session_collection_map[session_type:value()]) do
        if session.m_token == token and (session.m_csrf_token == csrf_token or csrf_token == nil) then
            return session
        end
    end
    return nil
end

--- 根据会话ID获取会话
---@param session_id any
function InterChassisSession:get_session_by_session_id(session_id)
    for index, session in pairs(self.m_session_collection) do
        if session_id == session.m_session_id then
            return session, index, iam_enum.SessionType.Redfish
        end
    end

    for index, session in pairs(self.m_session_collection_gui) do
        if session_id == session.m_session_id then
            return session, index, iam_enum.SessionType.GUI
        end
    end
    return nil
end

--- 判断是否还有剩余创建会话数
function InterChassisSession:hava_free_session()
    return #self.m_session_collection + #self.m_session_collection_gui <
        self.m_session_service_config.SessionMaxCount
end

--- 根据ip获取对应session_type的会话
---@param ip string
---@param session_type Enum
function InterChassisSession:get_session_by_ip(ip, session_type)
    session_type = session_type or iam_enum.SessionType.Redfish
    for _, session in pairs(self.m_session_collection_map[session_type:value()]) do
        if session.m_ip == ip then
            return session
        end
    end
    return nil
end

--- 获取超时会话
function InterChassisSession:get_timeout_session_list(absolute_timeout)
    local timeout_session_list = {}
    local session_timeout = self.m_session_service_config.SessionTimeout

    local now = vos.vos_get_cur_time_stamp()
    local cur_session
    for _, session_collection in pairs(self.m_session_collection_map) do
        for index = #session_collection, 1, -1 do
            cur_session = session_collection[index]
            -- 每5秒检查一次会话超时时间
            cur_session.m_last_active_time = cur_session.m_last_active_time + 5
            if session_timeout ~= 0 and cur_session.m_last_active_time >= self:get_session_timeout() then
                table.insert(timeout_session_list, cur_session)
                goto continue
            end
            if absolute_timeout ~= 0 and cur_session.m_created_time < now - absolute_timeout then
                table.insert(timeout_session_list, cur_session)
            end
            ::continue::
        end
    end

    return timeout_session_list
end

function InterChassisSession:get_max_session_timeout()
    return self.timeout_max
end

function InterChassisSession:get_min_session_timeout()
    return self.timeout_min
end

--- 获取当前会话数量
function InterChassisSession:get_session_count()
    return #self.m_session_collection + #self.m_session_collection_gui
end

function InterChassisSession:logout_security_log(user_name, ip)
end

function InterChassisSession:set_session_max_count(max_count)
    if max_count < self.min_session_count or max_count > self.max_session_count then
        log:error("Number(%d) of sessions is out of range", max_count)
        error(custom_msg.PropertyValueOutOfRange(max_count, 'SessionMaxCount'))
    end
    self.m_session_service_config.SessionMaxCount = max_count
    self.m_session_service_config:save()
end

return singleton(InterChassisSession)
