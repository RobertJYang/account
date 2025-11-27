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
local lu = require 'luaunit'
local iam_enum = require 'class.types.types'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'


-- 测试Controller1
local TEST_CTL_ID = 1

function TestIam:test_ldap_controller_collection_init()
    -- 默认存在6个控制器
    lu.assertEquals(#self.test_ldap_controller_collection.m_controller_collection, 6)
end

-- 测试使能切换
-- 输入：boolean
-- 输出：成功
function TestIam:test_set_ldap_controller_enabled()
    local cur_enabled = self.test_ldap_controller_collection:get_ldap_controller_enabled(TEST_CTL_ID)
    -- 默认值为true
    lu.assertEquals(cur_enabled, true)

    self.test_ldap_controller_collection:set_ldap_controller_enabled(TEST_CTL_ID, false)
    cur_enabled = self.test_ldap_controller_collection:get_ldap_controller_enabled(TEST_CTL_ID)
    lu.assertEquals(cur_enabled, false)
end

-- 测试hostaddr成功设置
-- 输入：正常ip
-- 输出：成功
function TestIam:test_set_ldap_controller_hostaddr_success()
    local addr = '71.11.12.13'
    self.test_ldap_controller_collection:set_ldap_controller_hostaddr(TEST_CTL_ID, addr)
    local cur_addr = self.test_ldap_controller_collection:get_ldap_controller_hostaddr(TEST_CTL_ID)
    lu.assertEquals(cur_addr, addr)
end

-- 测试hostaddr异常输入-特殊字符
-- 输入：特殊字符
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_hostaddr_special_characters()
    local addr = '71.11.12\n13'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_hostaddr(TEST_CTL_ID, addr)
    end)
end

-- 测试hostaddr异常输入-无效ip
-- 输入：无效ip
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_hostaddr_invalid_ip()
    local addr = '71.11.12.1314'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_hostaddr(TEST_CTL_ID, addr)
    end)
end

-- 测试port成功设置
-- 输入：正常port
-- 输出：成功
function TestIam:test_set_ldap_controller_port_success()
    local cur_port = self.test_ldap_controller_collection:get_ldap_controller_port(TEST_CTL_ID)
    -- 默认值为636
    lu.assertEquals(cur_port, 636)

    -- 正常输入 635
    local port = 635
    self.test_ldap_controller_collection:set_ldap_controller_port(TEST_CTL_ID, port)
    cur_port = self.test_ldap_controller_collection:get_ldap_controller_port(TEST_CTL_ID)
    lu.assertEquals(cur_port, port)
    
end

-- 测试port异常输入-越界port
-- 输入：越界port
-- 输出：PropertyValueNotInList
function TestIam:test_set_ldap_controller_port_out_of_range()
    -- 越界输入 65536
    local port = 65536
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_port(TEST_CTL_ID, port)
    end)
end

-- 测试domain成功设置
-- 输入：正常domain
-- 输出：成功
function TestIam:test_set_ldap_controller_domain_success()
    local domain = 'it.bmctest.com'
    self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    local cur_domain = self.test_ldap_controller_collection:get_ldap_controller_domain(TEST_CTL_ID)
    lu.assertEquals(cur_domain, domain)
end

-- 测试domain异常输入-超长domain
-- 输入：超长domain
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_too_long()
    -- 超长域名(256字节)
    local domain = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.' ..
                   'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.' ..
                   'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.' ..
                   'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end

-- 测试domain异常输入-无效domain
-- 输入：两个.之间超过63个字符
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_too_long_between_two_charater()
        local domain = 'it.bmctestaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com'
        lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
            self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
        end)
end

-- 测试domain异常输入-无效domain
-- 输入：首个.之前超过63个字符
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_too_long_before_first_charater()
    local domain = 'bmctestaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end

-- 测试domain异常输入-无效domain
-- 输入：最后一个.之后超过63个字符
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_too_long_after_last_charater()
    local domain = 'it.bmctestaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end

-- 测试domain异常输入-存在. -之外的连接符
-- 输入：存在. -之外的连接符
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_invalid_connector()
    local domain = 'it.bmctest~com'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end

-- 测试domain异常输入-首位为.或-
-- 输入：首位为.或-
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_invalid_first_character()
    local domain = '.it.bmctest.com'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end

-- 测试domain异常输入-末位为-
-- 输入：末位为-
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_invalid_last_character()
    local domain = 'it.bmctest.com-'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end

-- 测试domain异常输入-有连续.
-- 输入：有连续.
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_continuous_point()
    local domain = 'it.bmctest..com'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end

-- 测试domain异常输入-没有.
-- 输入：没有.
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_none_point()
    local domain = 'itbmctestcom'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end

-- 测试domain异常输入-单段以.结尾
-- 输入：单段以.结尾
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_one_segment()
    local domain = 'itbmctestcom.'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end

-- 测试domain异常输入-分隔符.前不能为-
-- 输入：域名分隔符前为字符-
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_domain_minus_before_segment()
    local domain = 'itbmctestcom-.com'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_domain(TEST_CTL_ID, domain)
    end)
end
 
-- 测试domain成功设置
-- 输入：正常folder
-- 输出：成功
function TestIam:test_set_ldap_controller_folder_success()
    local folder = 'CN=Users'
    self.test_ldap_controller_collection:set_ldap_controller_folder(TEST_CTL_ID, folder)
    local cur_folder = self.test_ldap_controller_collection:get_ldap_controller_folder(TEST_CTL_ID)
    lu.assertEquals(cur_folder, folder)
end

-- 测试domain异常输入-超长folder
-- 输入：超长folder
-- 输出：PropertyValueNotInList
function TestIam:test_set_ldap_controller_folder_too_long()
    -- 超长输入(256字节)
    local folder = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' ..
                   'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' ..
                   'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' ..
                   'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_folder(TEST_CTL_ID, folder)
    end)
end

-- 测试bindDN成功设置
-- 输入：正常bindDN
-- 输出：成功
function TestIam:test_set_ldap_controller_bind_dn_success()
    local bind_dn = 'admintest'
    self.test_ldap_controller_collection:set_ldap_controller_bind_dn(TEST_CTL_ID, bind_dn)
    local cur_bind_dn = self.test_ldap_controller_collection:get_ldap_controller_bind_dn(TEST_CTL_ID)
    lu.assertEquals(cur_bind_dn, bind_dn)
end

-- 测试bindDN异常输入-超长bindDN
-- 输入：超长bindDN
-- 输出：PropertyValueNotInList
function TestIam:test_set_ldap_controller_bind_dn_too_long()
    local bind_dn = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' ..
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' ..
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' ..
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_bind_dn(TEST_CTL_ID, bind_dn)
    end)
end

-- 测试证书校验使能切换
-- 输入：boolean
-- 输出：成功
function TestIam:test_set_ldap_controller_cert_verify_enabled()
    local cur_enabled = self.test_ldap_controller_collection:get_ldap_controller_cert_verify_enabled(TEST_CTL_ID)
    -- 默认为false
    lu.assertEquals(cur_enabled, false)
    -- 正常输入
    local enabled = true
    self.test_ldap_controller_collection:set_ldap_controller_cert_verify_enabled(TEST_CTL_ID, enabled)
    cur_enabled = self.test_ldap_controller_collection:get_ldap_controller_cert_verify_enabled(TEST_CTL_ID)
    lu.assertEquals(cur_enabled, enabled)
end

-- 测试证书校验级别正常设置
-- 输入：iam_enum.LdapCertVerifyLevel.LDAP_OPT_X_TLS_DEMAND : 2
--       iam_enum.LdapCertVerifyLevel.LDAP_OPT_X_TLS_ALLOW : 3
-- 输出：成功
function TestIam:test_set_ldap_controller_cert_verify_level_success()
    local cur_level = self.test_ldap_controller_collection:get_ldap_controller_cert_verify_level(TEST_CTL_ID)
    -- 默认为2
    lu.assertEquals(cur_level, iam_enum.LdapCertVerifyLevel.LDAP_OPT_X_TLS_DEMAND:value())

    -- 正常输入 3
    local level = iam_enum.LdapCertVerifyLevel.LDAP_OPT_X_TLS_ALLOW:value()
    self.test_ldap_controller_collection:set_ldap_controller_cert_verify_level(self.ctx, TEST_CTL_ID, level)
    cur_level = self.test_ldap_controller_collection:get_ldap_controller_cert_verify_level(TEST_CTL_ID)
    lu.assertEquals(cur_level, level)
end

-- 测试证书校验级别异常输入
-- 输入：iam_enum.LdapCertVerifyLevel.LDAP_OPT_X_TLS_HARD : 1
-- 输出：PropertyValueNotInList
function TestIam:test_set_ldap_controller_cert_verify_level_invalid_level()
    local level = iam_enum.LdapCertVerifyLevel.LDAP_OPT_X_TLS_HARD:value()
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_cert_verify_level(self.ctx, TEST_CTL_ID, level)
    end)
end

-- 测试bindDN Password正常设置
-- 输入：正常密码
-- 输出：成功
function TestIam:test_set_ldap_controller_bind_dn_psw_success()
    -- 正常输入
    local psw = 'test'
    self.test_ldap_controller_collection:set_ldap_controller_bind_dn_psw(self.ctx, TEST_CTL_ID, psw)
    local cur_psw = self.test_ldap_controller_collection:get_ldap_controller_bind_dn_psw(TEST_CTL_ID)
    lu.assertEquals(cur_psw, self.test_ldap_controller_collection.m_controller_collection[TEST_CTL_ID].kmc_client:encrypt_password(psw))
end

-- 测试bindDN Password异常输入-超长密码
-- 输入：超长密码(大于20位)
-- 输出：PropertyValueExceedsMaxLength
function TestIam:test_set_ldap_controller_bind_dn_psw_too_long()
    local psw = 'aaaaaaaaaaaaaaaaaaaaa'
    lu.assertErrorMsgContains(custom_msg.PropertyValueExceedsMaxLengthMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_bind_dn_psw(self.ctx, TEST_CTL_ID, psw)
    end)
end

-- 测试bindDN Password异常输入-存在非法字符
-- 输入：存在非法字符
-- 输出：PropertyValueFormatError
function TestIam:test_set_ldap_controller_bind_dn_psw_invalid_character()
    local psw = 'test\n'
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        self.test_ldap_controller_collection:set_ldap_controller_bind_dn_psw(self.ctx, TEST_CTL_ID, psw)
    end)
end