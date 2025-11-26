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
local session = require 'domain.session'
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local iam_enum = require 'class.types.types'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'

local VideoSession = class(session_type)

function VideoSession:ctor()
    self.timeout_min = 0 -- VIDEO会话超时时间最短0:永不超时
    self.timeout_max = 28800 -- VIDEO会话超时时间最长480分钟
end

function VideoSession:create(account, auth_type, ip, create_session_mode, sso_token)
    if create_session_mode ~= iam_enum.OccupationMode.Exclusive then
        log:error('VIDEO Session only support Exclusive mode.')
        error(base_msg.PropertyValueNotInList(create_session_mode, 'SessionMode'))
    end
    if not self:hava_free_session() then
        error(base_msg.SessionLimitExceeded())
    end
    if #self.m_session_collection > 0 then
        log:error('create %s mode failed, The session is already exclusive', create_session_mode)
        error(custom_msg.SessionModeIsExclusive('VIDEO'))
    end

    local new_session = session.new(account, self:get_session_type(), auth_type, ip, nil, sso_token)
    new_session.m_csrf_token = ''
    new_session.system_id = 0 --目前默认0
    table.insert(self.m_session_collection, new_session)
    self.m_create_session:emit(new_session)
    return new_session
end

function VideoSession:set_session_mode(session_mode)
    if session_mode == iam_enum.OccupationMode.Shared then
        log:error('VIDEO Session only support Exclusive mode.')
        error(base_msg.PropertyValueNotInList(session_mode, 'SessionMode'))
    end
    self.m_session_service_config.SessionModeDB = session_mode
    self.m_session_service_config:save()
end

return singleton(VideoSession)
