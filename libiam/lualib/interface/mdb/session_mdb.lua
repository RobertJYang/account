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
local sessions_service = require 'service.session_service'
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local service = require 'iam.service'
local role = require 'domain.cache.role_cache'
local iam_enum = require 'class.types.types'
local cls_mng = require 'mc.class_mgnt'
local iam_utils = require 'infrastructure.iam_utils'
local session_utils = require 'infrastructure.session_utils'

local INTERFACE_SESSION = 'bmc.kepler.SessionService.Session'

local SessionMdb = class()

function SessionMdb:ctor(bus)
    self.m_session_service = sessions_service.get_instance()
    self.m_role_collection = role.get_instance()
    self.m_bus = bus
    self.m_sessions = {}
    self.m_session_mdb_cls = cls_mng("Session")
end

function SessionMdb:regist_session_signals()
    for _, session_service in pairs(self.m_session_service.m_session_service_collection) do
        session_service.m_create_session:on(function(...)
            self:create_session_to_mdb_tree(...)
        end)
        session_service.m_delete_session:on(function(...)
            self:delete_session_from_mdb_tree(...)
        end)
    end

    self.m_role_collection.m_privilege_update_signal:on(function(...)
        self:session_mdb_update_role(...)
    end)
end

function SessionMdb:create_session_to_mdb_tree(info)
    local sessions = service:CreateSession(info.m_session_id, function(session)
        session.UserName = info.m_username
        session.AccountId = tostring(info.m_account_id)
        session.AccountPassword = "null"
        session.AuthType = info.m_auth_type:value()
        session.BrowserType = info.m_browser_type or 0
        session.SessionId = info.m_session_id
        session.SessionType = session_utils.convert_mdb_session_type(info)
        session.OemSessionType = info.m_oem_session_type and info.m_oem_session_type:value() or 0
        session.ClientOriginIPAddress = info.m_ip
        session.CreatedTime = iam_utils.convert_time_to_str(info.m_created_time)
        session.LastLoginIp = info.m_last_login_ip
        session.LastLoginTime = iam_utils.convert_time_to_str(info.m_last_login_time)
        session.Role = self.m_role_collection:role_to_string_table(info.m_role_id)
        session.Privileges = info.m_privilege
        session.SystemId = tonumber(info.system_id)
    end)
    table.insert(self.m_sessions, sessions)
end

function SessionMdb:delete_session_from_mdb_tree(session_id)
    for index, v in pairs(self.m_sessions) do
        if v.SessionId == session_id then
            self.m_session_mdb_cls:remove(self.m_sessions[index])
            table.remove(self.m_sessions, index)
            return
        end
    end
end

function SessionMdb:session_mdb_update_role(role_id, property, value)
    local role_type = tostring(iam_enum.RoleType.new(role_id))
    for _, v in pairs(self.m_sessions) do
        if v.Role[1] == role_type then
            v[INTERFACE_SESSION][property] = value
        end
    end
end

return singleton(SessionMdb)
