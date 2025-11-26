-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local iam_enum = require 'class.types.types'
local err_config = require 'error_config'
local custom_msg = require 'messages.custom'

--- LDAP指定域认证应该成功
function TestIam:test_when_ldap_auth_should_success()
    local controller_id = 1
    local default_enabled = self.test_ldap_authentication.m_ldap_config:get_ldap_enabled()
    lu.assertEquals(default_enabled, true)

    self.test_ldap_controller_collection:set_ldap_controller_enabled(controller_id, true)
    self.test_ldap_controller_collection:set_ldap_controller_domain(controller_id, "bmcopenldap.com")
    self.test_ldap_controller_collection:set_ldap_controller_hostaddr(controller_id, '71.41.33.88')
    self.test_ldap_controller_collection:set_ldap_controller_folder(controller_id, 'OU=Users')

    local ldap_mdb_id, ldap_group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, controller_id, 0,
                                                "rAdmin", "OU=Role", "bbb", 2, {}, {"Web"})
    
    lu.assertEquals(ldap_mdb_id, 'LDAP1_1')
    lu.assertEquals(ldap_group_id, 1)
    self.test_ldap_authentication.m_ldap_config:set_ldap_enabled(false)
    lu.assertErrorMsgContains(custom_msg.AuthorizationFailedMessage.Name, function()
        self.test_ldap_authentication:ldap_authenticate("admintest", "123456", "127.0.0.1", 1, ldap_group_id)
    end)
    self.test_ldap_authentication.m_ldap_config:set_ldap_enabled(true)
    local group = self.test_ldap_authentication:ldap_authenticate("admintest", "123456", "127.0.0.1", 1, ldap_group_id)
    lu.assertEquals(group.UserName, "admintest@bmcopenldap.com")

    -- 恢复环境
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
    lu.assertIsNil(self.test_remote_group_collection.m_db_remote_group_collection[ldap_group_id])
end

function TestIam:test_when_ldap_auto_auth_should_success()
    local controller_id = 1
    local default_enabled = self.test_ldap_authentication.m_ldap_config:get_ldap_enabled()
    lu.assertEquals(default_enabled, true)

    self.test_ldap_controller_collection:set_ldap_controller_enabled(controller_id, true)
    self.test_ldap_controller_collection:set_ldap_controller_domain(controller_id, "bmcopenldap.com")
    self.test_ldap_controller_collection:set_ldap_controller_hostaddr(controller_id, '71.41.33.88')
    self.test_ldap_controller_collection:set_ldap_controller_folder(controller_id, 'OU=Users')
    local ldap_mdb_id, ldap_group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, controller_id, 0,
                                                "rAdmin", "OU=Role", "bbb", 2, {}, {"Web"})
    
    lu.assertEquals(ldap_mdb_id, 'LDAP1_1')
    lu.assertEquals(ldap_group_id, 1)
    self.test_ldap_authentication.m_ldap_config:set_ldap_enabled(false)
    lu.assertErrorMsgContains(custom_msg.AuthorizationFailedMessage.Name, function()
        self.test_ldap_authentication:ldap_authenticate_auto_match("admintest", "123456", "127.0.0.1")
    end)
    self.test_ldap_authentication.m_ldap_config:set_ldap_enabled(true)

    local group = self.test_ldap_authentication:ldap_authenticate_auto_match("admintest", "123456", "127.0.0.1")
    lu.assertEquals(group.UserName, "admintest@bmcopenldap.com")

    -- 恢复环境
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
    lu.assertIsNil(self.test_remote_group_collection.m_db_remote_group_collection[ldap_group_id])
end

function TestIam:test_valid_group_authenticate_empty_result()
    local controller_id = 1
    self.test_ldap_authentication.m_ldap_config:set_ldap_enabled(true)

    self.test_ldap_controller_collection:set_ldap_controller_enabled(controller_id, true)
    self.test_ldap_controller_collection:set_ldap_controller_domain(controller_id, "bmcopenldap.com")
    self.test_ldap_controller_collection:set_ldap_controller_hostaddr(controller_id, '71.41.33.88')
    self.test_ldap_controller_collection:set_ldap_controller_folder(controller_id, 'OU=Users')
    local ldap_mdb_id, ldap_group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, controller_id, 0,
                                                "rAdmin", "OU=Role", "bbb", 2, {}, {"Redfish"})
    -- 没有远程组可以通过
    lu.assertErrorMsgContains(custom_msg.NoAccessMessage.Name, function()
        self.test_ldap_authentication:ldap_authenticate("admintest", "123456", "127.0.0.1", 1, ldap_group_id)
    end)
    -- 恢复环境
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
    lu.assertIsNil(self.test_remote_group_collection.m_db_remote_group_collection[ldap_group_id])
end
