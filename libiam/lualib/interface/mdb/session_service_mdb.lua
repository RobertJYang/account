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
local session_service = require 'service.session_service'
local singleton = require 'mc.singleton'
local service = require 'iam.service'
local log = require 'mc.logging'
local iam_enum = require 'class.types.types'
local class = require 'mc.class'
local context = require 'mc.context'
local operation_logger = require 'interface.operation_logger'
local base_msg = require 'messages.base'

local INTERFACE_SESSION_SERVICE = 'bmc.kepler.SessionService'

local SessionServiceMdb = class()
function SessionServiceMdb:ctor(bus)
    self.m_session_service = session_service.get_instance()
    self.m_bus = bus
    self.mdb_session_services = {}
end

function SessionServiceMdb:init()
    self:new_session_service_to_mdb_tree()
end

function SessionServiceMdb:regist_session_service_signals()
    for _, session_collection in pairs(self.m_session_service.m_session_service_collection) do
        session_collection.m_update_session_service:on(function(...)
            self:session_service_changed(...)
        end)
    end
end

-- 属性监听钩子
SessionServiceMdb.watch_property_hook = {
    SessionTimeout =  operation_logger.proxy(function(self, ctx, session_type, value)
        -- 传入value单位秒，转分钟除以60
        if session_type == iam_enum.SessionType.Redfish then
            ctx.operation_log.params = { type = tostring(session_type), time = value, timeunit = 'seconds' }
        else
            ctx.operation_log.params = { type = tostring(session_type), time = value // 60, timeunit = 'minutes' }
        end
        self.m_session_service:set_session_timeout(ctx, session_type, value)
    end, 'SessionTimeout'),
    SessionMode = operation_logger.proxy(function(self, ctx, session_type, value)
        local session_mode = iam_enum.OccupationMode.new(value)
        local session_mode_name = session_mode == iam_enum.OccupationMode.Shared and 'share' or 'exclusive'
        ctx.operation_log.params = { type = tostring(session_type), mode = session_mode_name }
        self.m_session_service:set_session_mode(ctx, session_type, session_mode)
    end, 'SessionMode'),
    SessionMaxCount = operation_logger.proxy(function(self, ctx, session_type, value)
        ctx.operation_log.params = { count = value }
        if session_type ~= iam_enum.SessionType.KVM then
            log:error('only KVM can set session max count!')
            error(base_msg.InternalError())
        end
        self.m_session_service:set_session_max_count(ctx, session_type, value)
    end, 'SessionMaxCount')
}

function SessionServiceMdb:new_session_service_to_mdb_tree()
    -- 设置各种类型的SessionService
    local mdb_ss = {
        iam_enum.SessionType.GUI,
        iam_enum.SessionType.Redfish,
        iam_enum.SessionType.CLI,
        iam_enum.SessionType.KVM,
        iam_enum.SessionType.VNC,
        iam_enum.SessionType.VIDEO,
    }
    for _, enum in ipairs(mdb_ss) do
        local ss = service:CreateSessionService(tostring(enum))
        local info = self.m_session_service.m_session_service_collection[enum:value()]
        ss.SessionTimeout = info.m_session_service_config.SessionTimeout
        ss.SessionMode = info.m_session_service_config.SessionModeDB:value()
        ss.SessionMaxCount = info.m_session_service_config.SessionMaxCount
        ss.ServiceEnabled = info.m_session_service_config.ServiceEnabled
        self.mdb_session_services[tostring(enum)] = ss
        self:watch_session_service_property(enum, ss)
    end
end

function SessionServiceMdb:watch_session_service_property(session_type, mdb_ss)
    mdb_ss[INTERFACE_SESSION_SERVICE].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the session service property(%s) to value(%s), sender is nil', name, tostring(value))
            return true
        end

        if not self.watch_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('SessionServiceMdb: %s change the property(%s) to value(%s)', sender, name, value)
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_property_hook[name](self, ctx, session_type, value)
        return true
    end)
end

function SessionServiceMdb:session_service_changed(session_type, property, value)
    if self.mdb_session_services[tostring(session_type)] == nil then
        return
    end
    self.mdb_session_services[tostring(session_type)][INTERFACE_SESSION_SERVICE][property] = value
end

return singleton(SessionServiceMdb)
