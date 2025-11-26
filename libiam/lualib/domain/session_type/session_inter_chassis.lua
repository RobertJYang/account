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
local session_type = require 'domain.session_type.session_type'
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local custom_msg = require 'messages.custom'

local InterChassisSession = class(session_type)

function InterChassisSession:ctor()
    self.timeout_min = 300   -- 超时时间最短5分钟
    self.timeout_max = 28800 -- 超时时间最长480分钟
    self.max_session_count = 10 -- 最大会话数上限为10个
    self.min_session_count = 4  -- 最大会话数下限为4个
end

function InterChassisSession:get_max_session_timeout()
    return self.timeout_max
end

function InterChassisSession:get_min_session_timeout()
    return self.timeout_min
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
