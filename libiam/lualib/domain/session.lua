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
local class = require 'mc.class'
local privilege = require 'domain.privilege'
local session_utils = require 'infrastructure.session_utils'
local iam_enum = require 'class.types.types'

local Session = class()
function Session:ctor(account_data, session_type, auth_type, ip, browser_type, sso_token)
    self.m_username = account_data.UserName
    self.m_account_id = account_data.Id
    self.m_auth_type = auth_type
    self.m_browser_type = browser_type
    self.m_token = session_utils.generate_token()
    self.m_csrf_token = session_utils.generate_token()
    self.m_session_id = session_utils.generate_session_id(self.m_token)
    self.m_session_type = session_type
    self.m_session_type_name = Session.session_type_name_map[session_type:value()]
    self.m_ip = ip
    self.m_created_time = os.time()
    self.m_last_login_ip = account_data.LastLoginIP
    self.m_last_login_time = account_data.LastLoginTime
    self.m_last_active_time = 0
    self.m_role_id = account_data.RoleId
    -- 缓存session对应9大权限信息
    self.m_privilege = account_data.current_privileges or Session.get_session_privilege(self.m_role_id):to_array()

    self.m_sso_token = sso_token
end

Session.session_type_name_map = {
    [iam_enum.SessionType.GUI:value()] = 'WEB',
    [iam_enum.SessionType.Redfish:value()] = 'Redfish',
    [iam_enum.SessionType.CLI:value()] = 'CLI',
    [iam_enum.SessionType.SSO:value()] = 'SSO',
    [iam_enum.SessionType.KVM:value()] = 'KVM',
    [iam_enum.SessionType.VNC:value()] = 'VNC',
    [iam_enum.SessionType.VIDEO:value()] = 'VIDEO'
}

-- 同时支持ids以单数字传入或过个role_id表传入
function Session.get_session_privilege(ids)
    local id_table = {}
    if type(ids) == 'number' then
        id_table[1] = ids
    else
        id_table = ids
    end
    return privilege.new_from_role_ids(id_table)
end

return Session
