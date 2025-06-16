-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local login_mac_rule = require 'domain.login_rule.login_mac_rule'
local base_msg = require 'messages.base'

--- 当MAC规则不符合格式要求时，创建MAC规则实例失败
function TestAccount:test_when_mac_rule_is_not_match_format_should_new_instance_fail()
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_mac_rule.new(nil, '01.01.01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_mac_rule.new(nil, '1:01:01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_mac_rule.new(nil, '0g:01:01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_mac_rule.new(nil, '01.01.01.01.01.01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_mac_rule.new(nil, '1:01:01:01:01:01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_mac_rule.new(nil, '0g:01:01:01:01:01')
    end)
end

--- 当MAC规则不符合格式要求时，设置规则失败
function TestAccount:test_when_set_rule_is_not_match_format_should_set_fail()
    local test_mac_rule = login_mac_rule.new(nil, nil)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_mac_rule:set_rule('01.01.01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_mac_rule:set_rule('1:01:01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_mac_rule:set_rule('0g:01:01')
    end)

    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_mac_rule:set_rule('01.01.01.01.01.01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_mac_rule:set_rule('1:01:01:01:01:01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_mac_rule:set_rule('0g:01:01:01:01:01')
    end)
end

--- 当设置MAC规则为完整格式时，rule_type属性应设为INTEGRITY
function TestAccount:test_when_set_rule_integrity_should_get_rule_type_integrity()
    local test_mac_rule = login_mac_rule.new(nil, '01:01:01:01:01:01')
    lu.assertEquals(test_mac_rule.m_rule_type, 'INTEGRITY')
end

--- 当设置MAC规则为三段格式时，rule_type属性应设为THREE_SEGMENT
function TestAccount:test_when_set_rule_integrity_should_get_rule_type_three_segment()
    local test_mac_rule = login_mac_rule.new(nil, '01:01:01')
    lu.assertEquals(test_mac_rule.m_rule_type, 'THREE_SEGMENT')
end

--- 当MAC规则为null时，应该校验成功
function TestAccount:test_when_mac_rule_is_null_should_check_success()
    local test_mac_rule = login_mac_rule.new(nil, nil)
    local result = test_mac_rule:check_rule('source_mac')
    lu.assertEquals(result, true)
end

--- 当MAC规则为空串时，应该校验成功
function TestAccount:test_when_mac_rule_is_empty_string_should_check_success()
    local test_mac_rule = login_mac_rule.new(nil, '')
    local result = test_mac_rule:check_rule('source_mac')
    lu.assertEquals(result, true)
end

--- 登录IP为IPv6，应该校验成功
function TestAccount:test_when_source_mac_is_macv6_should_check_success()
    local test_mac_rule = login_mac_rule.new(nil, '01:01:01')
    local result = test_mac_rule:check_rule('0001:0001:0001:0000:0000:0000:0000:0000')
    lu.assertEquals(result, true)
    local result = test_mac_rule:check_rule('0fff:ffff:ffff:ffff:ffff:ffff:ffff:ffff')
    lu.assertEquals(result, true)
end

--- 登录IP不为IPv4格式，应该校验失败
function TestAccount:test_when_source_mac_is_not_macv4_should_check_fail()
    local test_mac_rule = login_mac_rule.new(nil, '01:01:01')
    local result = test_mac_rule:check_rule('0.1.1.1')
    lu.assertEquals(result, false)
    local result = test_mac_rule:check_rule('127.1.1.1')
    lu.assertEquals(result, false)
    local result = test_mac_rule:check_rule('1.256.1.1')
    lu.assertEquals(result, false)
end

--- 当MAC规则为完整格式时，获取不到MAC地址，应该校验失败
function TestAccount:test_when_can_not_get_mac_address_should_check_fail()
    local test_mac_rule = login_mac_rule.new(nil, '01:01:01')
    local result = test_mac_rule:check_rule('0.0.0.0')
    lu.assertEquals(result, false)
end

--- MAC规则和登录MAC一致，应该校验成功
function TestAccount:test_when_mac_rule_same_with_source_mac_should_check_success()
    local test_mac_rule = login_mac_rule.new(nil, '01:01:01')
    local result = test_mac_rule.compare_string_prefix('01:01:01:01:01:01', '01:01:01', 8)
    lu.assertEquals(result, true)

    local test_mac_rule = login_mac_rule.new(nil, '01:01:01:01:01:01')
    local result = test_mac_rule.compare_string_prefix('01:01:01:01:01:01', '01:01:01:01:01:01', 8)
    lu.assertEquals(result, true)
end

--- mac规则和登录mac不一致，应该校验失败
function TestAccount:test_when_mac_rule_diff_with_source_mac_should_check_fail()
    local test_mac_rule = login_mac_rule.new(nil, '01:01:01')
    local result = test_mac_rule.compare_string_prefix('02:01:02:01:02:03', '01:01:01', 13)
    lu.assertEquals(result, false)

    local test_mac_rule = login_mac_rule.new(nil, '01:01:01:01:01:01')
    local result = test_mac_rule.compare_string_prefix('01:01:01:01:02:03', '01:01:01', 13)
    lu.assertEquals(result, false)
end

