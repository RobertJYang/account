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
local session = require 'domain.session'
local iam_enum = require 'class.types.types'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'

local VNCSession = class(session_type)

function VNCSession:ctor()
    self.timeout_min = 0 -- VNC会话超时时间最短0:永不超时
    self.timeout_max = 28800 -- VNC会话超时时间最长480分钟
end

function VNCSession:create(account, create_session_mode, ip)
    if not self:hava_free_session() then
        error(base_msg.SessionLimitExceeded())
    end
    -- 检查创建会话指定的会话模式
    self:session_mode_validator(create_session_mode)

    local new_session = session.new(account, self:get_session_type(),
        iam_enum.AccountType.Local, ip, nil, nil)
    new_session.m_csrf_token = ''

    new_session.m_session_mode = self:get_session_mode()
    new_session.system_id = 0 --目前默认0
    table.insert(self.m_session_collection, new_session)
    self.m_create_session:emit(new_session)
    return new_session
end

--- 会话模式校验
function VNCSession:session_mode_validator(mode)
    -- 当前为独占或指定创建独占会话，且已有vnc会话则不可创建
    if self:get_session_mode() == iam_enum.OccupationMode.Exclusive or
        mode == iam_enum.OccupationMode.Exclusive then
        if #self.m_session_collection ~= 0 then
            log:error('create %s mode failed, The vnc session is already exclusive', mode)
            error(custom_msg.SessionModeIsExclusive('VNC'))
        end
    end
    -- 会话模式不一致需修改
    if self:get_session_mode() ~= mode then
        self:set_session_mode(mode)
        self.m_update_session_service:emit(
            self:get_session_type(), 'SessionMode', mode:value())
    end
end

return singleton(VNCSession)
