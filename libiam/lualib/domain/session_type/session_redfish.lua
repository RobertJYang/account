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
local session_type = require 'domain.session_type.session_type'
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local base_msg = require 'messages.base'
local session = require 'domain.session'
local iam_enum = require 'class.types.types'
local custom_msg = require 'messages.custom'
local user_config = require 'user_config'
local SESSION_TIMEOUT_MIN<const> = 30 -- Redfish会话超时时间最短30秒
local SESSION_TIMEOUT_MAX<const> = 86400   -- Redfish会话超时时间最长86400秒(24h)
local REDFISH_INNER_SESSION_TIMEOUT<const> = 3600    -- 内部会话超时时长1小时

local RedfishSession = class(session_type)

function RedfishSession:ctor()
    self.timeout_min = 30 -- Redfish会话超时时间最短30秒
    self.timeout_max = 86400 -- Redfish会话超时时间最长86400秒(24h)
    self.m_inner_session_collection = {}
end

--- 创建会话
---@param account instance
---@param auth_type Enum
---@param ip string
---@return table
function RedfishSession:create_inner_session(account, auth_type, ip, inner_session_type, role_id)
    if self.m_inner_session_collection[inner_session_type] then
        return self.m_inner_session_collection[inner_session_type]
    end
    local new_session = session.new(account, self.m_session_service_config.SessionType,
        auth_type, ip, inner_session_type)
    new_session.m_role_id = role_id
    new_session.m_privilege = session.get_session_privilege(role_id):to_array()
    new_session.system_id = 0 --目前默认0
    self.m_inner_session_collection[inner_session_type] = new_session
    self.m_create_session:emit(new_session)
    return new_session
end

function RedfishSession:set_session_timeout(timestamp)
    if timestamp < SESSION_TIMEOUT_MIN or timestamp > SESSION_TIMEOUT_MAX then
        log:error('Redfish SessionTimeout(%d) is out of range', timestamp)
        error(base_msg.PropertyValueNotInList(timestamp, 'RedfishSessionTimeout'))
    end
    self.m_session_service_config.SessionTimeout = timestamp
    self.m_session_service_config:save()
end

function RedfishSession:set_session_max_count(max_count)
    if max_count < user_config.MIN_REDFISH_SESSION_COUNT or max_count > user_config.MAX_REDFISH_SESSION_COUNT then
        log:error("Number(%d) of sessions is out of range", max_count)
        error(custom_msg.PropertyValueOutOfRange(max_count, 'SessionMaxCount'))
    end
    self.m_session_service_config.SessionMaxCount = max_count
    self.m_session_service_config:save()
end

function RedfishSession:logout_security_log(user_name, ip)
    log:security('User %s(%s) logout successfully', user_name, ip)
end

function RedfishSession:validate_session(cur_session)
    -- 重置活跃时间
    cur_session.m_last_active_time = 0
    return cur_session.m_session_id
end

--- 根据Token获取会话
---@param token string
---@param csrf_token string
function RedfishSession:get_session_by_token(token, csrf_token)
    for _, session in pairs(self.m_session_collection) do
        if session.m_token == token and (not csrf_token or session.m_csrf_token == csrf_token) then
            return session
        end
    end
    for _, inner_session in pairs(self.m_inner_session_collection) do
        if inner_session.m_token == token then
            return inner_session
        end
    end
    return nil
end

--- 获取超时会话
function RedfishSession:get_timeout_session_list()
    local timeout_session_list = {}
    local session
    -- 内部会话超时时间一小时
    for index = #self.m_inner_session_collection, 1, -1 do
        session = self.m_inner_session_collection[index]
        session.m_last_active_time = session.m_last_active_time + 5
        if session.m_last_active_time > REDFISH_INNER_SESSION_TIMEOUT then
            table.insert(timeout_session_list, session)
        end
    end
    if self.m_session_service_config.SessionTimeout == 0 then
        return timeout_session_list
    end
    for index = #self.m_session_collection, 1, -1 do
        session = self.m_session_collection[index]
        -- 每5秒检查一次会话超时时间
        session.m_last_active_time = session.m_last_active_time + 5
        if session.m_last_active_time >= self:get_session_timeout() then
            table.insert(timeout_session_list, session)
        end
    end
    return timeout_session_list
end

function RedfishSession:delete_all_inner_session()
    if #self.m_inner_session_collection == 0 then
        return
    end
    for _, inner_session in pairs(self.m_inner_session_collection) do
        self:delete(inner_session.m_session_id)
    end
    log:notice("Delete all inner session successfully!")
end

function RedfishSession:delete_high_priv_inner_session(chan_role_tab)
    local role_name_tab = {
        [iam_enum.RedfishInnerSessionType.BMA:value()] = chan_role_tab.SMS,
        [iam_enum.RedfishInnerSessionType.HMM:value()] = chan_role_tab.ICMB
    }
    local chan_role_name
    for inner_session_type, inner_session in pairs(self.m_inner_session_collection) do
        chan_role_name = role_name_tab[inner_session_type] == 'User' and 'CommonUser' or
            role_name_tab[inner_session_type]
        if inner_session.m_role_id > iam_enum.RoleType[chan_role_name]:value() then
            log:notice("redfish inner session(%s)\'s privilege is lower than the channel requirement, " ..
                "kick session out", tostring(iam_enum.RedfishInnerSessionType.new(inner_session_type)))
            self:delete(inner_session.m_session_id)
        end
    end
end

--- 删除会话
---@param session_id string
function RedfishSession:delete(session_id)
    local session, index, is_inner_session = self:get_session_by_session_id(session_id)
    if not session then
        error(base_msg.NoValidSession())
    end
    if is_inner_session then
        table.remove(self.m_inner_session_collection, index)
    else
        table.remove(self.m_session_collection, index)
    end
    self.m_delete_session:emit(session_id)
    self:logout_security_log(session.m_username, session.m_ip)
end

--- 根据会话ID获取会话
---@param session_id any
function RedfishSession:get_session_by_session_id(session_id)
    for index, session in pairs(self.m_session_collection) do
        if session_id == session.m_session_id then
            return session, index, false
        end
    end
    for index, session in pairs(self.m_inner_session_collection) do
        if session_id == session.m_session_id then
            return session, index, true
        end
    end
end

return singleton(RedfishSession)
