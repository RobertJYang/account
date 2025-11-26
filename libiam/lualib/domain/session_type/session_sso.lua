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
local session_class = require 'domain.session'
local class = require 'mc.class'
local log = require 'mc.logging'
local singleton = require 'mc.singleton'
local base_msg = require 'messages.base'
local iam_enum = require 'class.types.types'
local iam_core = require 'iam_core'

local SSOSession = class(session_type)

--- 创建会话
---@param account instance
---@param auth_type Enum
---@param ip string
---@return table
function SSOSession:create(account, auth_type, ip, browser_type)
    if not self:hava_free_session() then
        self:delete_all_session(iam_enum.SessionLogoutType.SessionRelogin, iam_enum.IpType.All)
    end
    local new_session = session_class.new(account, self:get_session_type(),
        auth_type, ip, browser_type, nil)
    new_session.m_csrf_token = ''
    new_session.system_id = 0 --目前默认0
    table.insert(self.m_session_collection, new_session)
    self.m_create_session:emit(new_session)
    return new_session
end

--- 删除所有会话，可以删除对应ip类型的会话
---@param logout_type Enum
function SSOSession:delete_all_session(logout_type, ip_type)
    for index = #self.m_session_collection, 1, -1 do
        local session = self.m_session_collection[index]
        if ip_type == iam_enum.IpType.All then
            self:delete(session.m_session_id, logout_type)
        elseif ip_type == iam_enum.IpType.V4 and iam_core.vos_ipv4_addr_valid_check(session.m_ip) == 0 then
            self:delete(session.m_session_id, logout_type)
        elseif ip_type == iam_enum.IpType.V6 and iam_core.vos_ipv6_addr_valid_check(session.m_ip) == 0 then
            self:delete(session.m_session_id, logout_type)
        else
            log:info('session is not match, skip delete, session_type: %s', tostring(session.m_session_type))
        end
    end
end

function SSOSession:delete(session_id, logout_type)
    local session, index = self:get_session_by_session_id(session_id)
    if not session then
        error(base_msg.NoValidSession())
    end
    table.remove(self.m_session_collection, index)
    self.m_delete_session:emit(session_id)
    if tostring(logout_type) == 'SessionTimeout' then
        log:notice('Destroy sso token due to overtime')
        return
    end
    log:notice('Destroy sso token successfully')
end

return singleton(SSOSession)
