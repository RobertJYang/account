-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2023. All rights reserved.
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
local user_config = require 'user_config'

local GUISession = class(session_type)

function GUISession:ctor()
    self.timeout_min = 300 -- web会话超时时间最短5分钟
    self.timeout_max = 28800 -- web会话超时时间最长480分钟
end

function GUISession:get_max_session_timeout()
    return self.timeout_max
end

function GUISession:get_min_session_timeout()
    return self.timeout_min
end

function GUISession:logout_security_log(user_name, ip)
    log:security('User %s(%s) logout successfully', user_name, ip)
end

function GUISession:set_session_max_count(max_count)
    if max_count < user_config.MIN_WEB_SESSION_COUNT or max_count > user_config.MAX_WEB_SESSION_COUNT then
        log:error("Number(%d) of sessions is out of range", max_count)
        error(custom_msg.PropertyValueOutOfRange(max_count, 'SessionMaxCount'))
    end
    self.m_session_service_config.SessionMaxCount = max_count
    self.m_session_service_config:save()
end

return singleton(GUISession)
