-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local test_target = require 'domain.session'
local iam_enum = require 'class.types.types'
local lu = require 'luaunit'
local utils_core = require 'utils.core'
local iam_utils = require 'infrastructure.iam_utils'
local base_msg = require 'messages.base'

function string.ends(String, End)
    return End == '' or string.sub(String, -string.len(End)) == End
end

function TestIam:test_session_new()
    local account_data = {
        UserName = "Administrator",
        Id = 2,
        LastLoginIP = "",
        LastLoginTime = 0,
        RoleId = 4,
        current_privileges = 0
    }
    local session = test_target.new(account_data, iam_enum.SessionType.Redfish, 'LocaliBMC', '192.168.2.2', 4, 0)
    local time = os.time()

    lu.assertEquals(session.m_session_type, iam_enum.SessionType.Redfish)
    lu.assertEquals(session.m_auth_type, 'LocaliBMC')
    lu.assertIsTrue(session.m_created_time <= time)
    lu.assertNotIsNil(session.m_token)
    lu.assertNotIsNil(session.m_csrf_token)
    lu.assertIsTrue(session.m_token ~= session.m_csrf_token)
    lu.assertEquals(#session.m_token, 64) -- token应该为64字节
end

-- 测试不同时区下字符串是否准确
function TestIam:test_session_time_zone()
    local tz_env = utils_core.getenv('TZ') ~= nil and utils_core.getenv('TZ') or ''
    utils_core.setenv('TZ', 'UTC-01:30', 1)
    local time_str = iam_utils.convert_time_to_str(os.time())
    lu.assertIsTrue(string.ends(time_str, '+01:30'))

    utils_core.setenv('TZ', 'UTC+11:50', 1)
    local time_str = iam_utils.convert_time_to_str(os.time())
    lu.assertIsTrue(string.ends(time_str, '-11:50'))
    -- 环境恢复
    utils_core.setenv('TZ', tz_env, 1)
end

-- 测试NewSession接口ExtraData参数合法性校验
function TestIam:test_new_session_extra_data_check()
    -- SessionMode参数不合法
    local extra_data = {SessionMode = 'a'}
    local ok, err = pcall(self.test_session_service.check_new_session_extra_data, self.test_session_service, extra_data)
    lu.assertIsFalse(ok)
    lu.assertEquals(err.name, base_msg.PropertyValueNotInListMessage.Name)
    extra_data.SessionMode = '2'
    ok, err = pcall(self.test_session_service.check_new_session_extra_data, self.test_session_service, extra_data)
    lu.assertIsFalse(ok)
    lu.assertEquals(err.name, base_msg.PropertyValueNotInListMessage.Name)
    extra_data.SessionMode = '1'
    ok, _ = pcall(self.test_session_service.check_new_session_extra_data, self.test_session_service, extra_data)
    lu.assertIsTrue(ok)
    -- BrowserType不合法
    extra_data.BrowserType = 'b'
    ok, err = pcall(self.test_session_service.check_new_session_extra_data, self.test_session_service, extra_data)
    lu.assertIsFalse(ok)
    lu.assertEquals(err.name, base_msg.PropertyValueNotInListMessage.Name)
    extra_data.BrowserType = '256'
    ok, err = pcall(self.test_session_service.check_new_session_extra_data, self.test_session_service, extra_data)
    lu.assertIsFalse(ok)
    lu.assertEquals(err.name, base_msg.PropertyValueNotInListMessage.Name)
    extra_data.BrowserType = '255'
    ok, _ = pcall(self.test_session_service.check_new_session_extra_data, self.test_session_service, extra_data)
    lu.assertIsTrue(ok)
end

-- 测试根据domain获取认证类型应符合预期
function TestIam:test_get_auth_type_by_domain_when_local_first()
    local domain = 'LocaliBMC'
    local auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'LocalFirst')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'Local')
    domain = 'AutomaticMatching'
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'LocalFirst')
    lu.assertEquals(#auth_type, 2)
    lu.assertEquals(tostring(auth_type[1]), 'Local')
    lu.assertEquals(tostring(auth_type[2]), 'ldap_auto_match')
    domain = ''
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'LocalFirst')
    lu.assertEquals(#auth_type, 2)
    lu.assertEquals(tostring(auth_type[1]), 'Local')
    lu.assertEquals(tostring(auth_type[2]), 'ldap_auto_match')
    domain = 'RemoteAutoMatching'
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'LocalFirst')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'ldap_auto_match')
end

function TestIam:test_get_auth_type_by_domain_when_disabled()
    local domain = 'LocaliBMC'
    local auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Disabled')
    lu.assertEquals(#auth_type, 0)
    domain = 'AutomaticMatching'
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Disabled')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'ldap_auto_match')
    domain = ''
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Disabled')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'ldap_auto_match')
    domain = 'RemoteAutoMatching'
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Disabled')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'ldap_auto_match')
end

function TestIam:test_get_auth_type_by_domain_when_enabled()
    local domain = 'LocaliBMC'
    local auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Enabled')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'Local')
    domain = 'AutomaticMatching'
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Enabled')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'Local')
    domain = ''
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Enabled')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'Local')
    domain = 'RemoteAutoMatching'
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Enabled')
    lu.assertEquals(#auth_type, 0)
end

function TestIam:test_get_auth_type_by_domain_when_fall_back()
    local domain = 'LocaliBMC'
    local auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Fallback')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'Local')
    domain = 'AutomaticMatching'
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Fallback')
    lu.assertEquals(#auth_type, 2)
    lu.assertEquals(tostring(auth_type[1]), 'ldap_auto_match')
    lu.assertEquals(tostring(auth_type[2]), 'Local')
    domain = ''
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Fallback')
    lu.assertEquals(#auth_type, 2)
    lu.assertEquals(tostring(auth_type[1]), 'ldap_auto_match')
    lu.assertEquals(tostring(auth_type[2]), 'Local')
    domain = 'RemoteAutoMatching'
    auth_type = self.test_session_service:get_auth_type_by_domain(domain, 'Fallback')
    lu.assertEquals(#auth_type, 1)
    lu.assertEquals(tostring(auth_type[1]), 'ldap_auto_match')
end