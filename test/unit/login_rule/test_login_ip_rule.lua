-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local login_ip_rule = require 'domain.login_rule.login_ip_rule'
local base_msg = require 'messages.base'
local enum = require 'class.types.types'

--- 当IP规则不符合格式要求时，创建IP规则实例失败
function TestAccount:test_when_ip_rule_is_not_match_format_should_new_instance_fail()
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_ip_rule.new(nil, '1.1000.1.1')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_ip_rule.new(nil, '1.a.1.1')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_ip_rule.new(nil, '1.a.1.1.')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_ip_rule.new(nil, '1.256.1.1')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_ip_rule.new(nil, '1.1.1.1/33')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_ip_rule.new(nil, 'fec0::75:1001::ff12')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_ip_rule.new(nil, 'fec0:75:1001::ff12/129')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_ip_rule.new(nil, 'fec0:75:1001::ff12/-1')
    end)
end

--- 当IP规则不符合格式要求时，设置规则失败
function TestAccount:test_when_set_rule_is_not_match_format_should_set_fail()
    local test_ip_rule = login_ip_rule.new(nil, nil)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_ip_rule:set_rule('source_ip')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_ip_rule:set_rule('1.1000.1.1')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_ip_rule:set_rule('1.a.1.1')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_ip_rule:set_rule('1.a.1.1.')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_ip_rule:set_rule('1.256.1.1')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_ip_rule:set_rule('1.1.1.1/33')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_ip_rule:set_rule('fec0::75:1001::ff12')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_ip_rule:set_rule('fec0:75:1001::ff12/129')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_ip_rule:set_rule('fec0::75:1001::ff12/-1')
    end)
end

--- 当设置IP规则为不带掩码格式时，rule_type属性应设为NO_MASK
function TestAccount:test_when_set_rule_without_mask_should_get_rule_type_no_mask()
    local test_ip_rule = login_ip_rule.new(nil, '76.76.16.198')
    lu.assertEquals(test_ip_rule.m_rule_type, enum.IpRuleType.NO_MASK)
end

--- 当设置IP规则为带掩码格式时，rule_type属性应设为MASK
function TestAccount:test_when_set_rule_with_mask_should_get_rule_type_mask()
    local test_ip_rule = login_ip_rule.new(nil, '76.76.16.198/1')
    lu.assertEquals(test_ip_rule.m_rule_type, enum.IpRuleType.MASK)
end

--- 当IP规则为null时，应该校验成功
function TestAccount:test_when_ip_rule_is_null_should_check_success()
    local test_ip_rule = login_ip_rule.new(nil, nil)
    local result = test_ip_rule:check_rule('source_ip')
    lu.assertEquals(result, true)
end

--- 当IP规则为空串时，应该校验成功
function TestAccount:test_when_ip_rule_is_empty_string_should_check_success()
    local test_ip_rule = login_ip_rule.new(nil, '')
    local result = test_ip_rule:check_rule('source_ip')
    lu.assertEquals(result, true)
end

--- 登录ip不为IPv4格式，应该校验失败
function TestAccount:test_when_source_ip_is_not_ipv4_should_check_fail()
    local test_ip_rule = login_ip_rule.new(nil, '76.76.16.198')
    local result = test_ip_rule:check_rule('0.1.1.1')
    lu.assertEquals(result, false)
    local result = test_ip_rule:check_rule('127.1.1.1')
    lu.assertEquals(result, false)
    local result = test_ip_rule:check_rule('1.256.1.1')
    lu.assertEquals(result, false)
end

--- 当IP规则为不带掩码格式时，ip规则和登录ip一致，应该校验成功
function TestAccount:test_when_ip_rule_is_same_with_source_ip_should_check_fail()
    local test_ip_rule = login_ip_rule.new(nil, '76.76.16.198')
    local result = test_ip_rule:check_rule('76.76.16.198')
    lu.assertEquals(result, true)
end

--- 当IP规则为不带掩码格式时，ip规则和登录ip不一致，应该校验失败
function TestAccount:test_when_ip_rule_is_diff_with_source_ip_should_check_fail()
    local test_ip_rule = login_ip_rule.new(nil, '76.76.16.198')
    local result = test_ip_rule:check_rule('76.76.16.197')
    lu.assertEquals(result, false)
end

--- 当IP规则为带掩码格式时，ip规则和登录ip属于同一子网，应该校验成功
function TestAccount:test_when_ip_rule_with_and_source_ip_belong_same_subnet_should_check_success()
    local test_ip_rule = login_ip_rule.new(nil, '219.218.44.123/23')
    local result = test_ip_rule:check_rule('219.218.45.34')
    lu.assertEquals(result, true)
end

--- 当IP规则为带掩码格式时，ip规则和登录ip不属于同一子网，应该校验失败
function TestAccount:test_when_ip_rule_with_and_source_ip_belong_same_subnet_should_check_fail()
    local test_ip_rule = login_ip_rule.new(nil, '219.218.44.123/24')
    local result = test_ip_rule:check_rule('219.218.45.34')
    lu.assertEquals(result, false)
end

-- 登录ip为IPv6，应该校验成功
function TestAccount:test_when_source_ip_is_ipv6_should_check_success()
    local test_ip_rule = login_ip_rule.new(nil, '76.76.16.198')
    local result = pcall(function ()
        test_ip_rule:set_rule('1000:0000:0000:0000:0000:0000:0000:0000')
    end)
    lu.assertEquals(result, true)
    lu.assertEquals(test_ip_rule:get_rule_type(), enum.IpRuleType.IPV6_NO_MASK)
    local result = test_ip_rule:check_rule('1000:0000:0000:0000:0000:0000:0000:0000')
    lu.assertEquals(result, true)
end

-- 登录ip为IPv6压缩格式，应该校验成功
function TestAccount:test_when_source_ip_is_ipv6_compress_should_check_fail()
    local test_ip_rule = login_ip_rule.new(nil, '76.76.16.198')
    local result = pcall(function ()
        test_ip_rule:set_rule('1000::')
    end)
    lu.assertEquals(result, true)
    lu.assertEquals(test_ip_rule:get_rule_type(), enum.IpRuleType.IPV6_NO_MASK)
    local result = test_ip_rule:check_rule('1000:0000:0000:0000:0000:0000:0000:0000')
    lu.assertEquals(result, true)
end

-- 登录ip为IPv6子网掩码，应该校验成功
function TestAccount:test_when_source_ip_is_ipv6_subnetmask_should_check_fail()
    local test_ip_rule = login_ip_rule.new(nil, '76.76.16.198')
    local result = pcall(function ()
        test_ip_rule:set_rule('1000::/128')
    end)
    lu.assertEquals(result, true)
    lu.assertEquals(test_ip_rule:get_rule_type(), enum.IpRuleType.IPV6_MASK)
    local result = test_ip_rule:check_rule('1000:0000:0000:0000:0000:0000:0000:0000')
    lu.assertEquals(result, true)
end

-- 登录规则为ipv6，且登录ip与登录规则不匹配应该校验失败
--- 当IP规则为不带掩码格式时，ip规则和登录ip不一致，应该校验失败
function TestAccount:test_when_ipv6_rule_is_diff_with_source_ip_should_check_fail()
    local test_ip_rule = login_ip_rule.new(nil, '1000::')
    local result = test_ip_rule:check_rule('1000:0000:0000:0000:0000:0000:0000:0001')
    lu.assertEquals(result, false)
end

--- 当IPV6规则为带掩码格式时，ip规则和登录ip属于同一子网，应该校验成功
function TestAccount:test_when_ipv6_rule_with_and_source_ip_belong_same_subnet_should_check_success()
    local test_ip_rule = login_ip_rule.new(nil, 'Fec0:75:1001::/48')
    local result = test_ip_rule:check_rule('Fec0:75:1001::1')
    lu.assertEquals(result, true)
end

--- 当IPV6规则为带掩码格式时，ip规则和登录ip不属于同一子网，应该校验失败
function TestAccount:test_when_ipv6_rule_with_and_source_ip_belong_same_subnet_should_check_fail()
    local test_ip_rule = login_ip_rule.new(nil, 'Fec0:75:1001::/48')
    local result = test_ip_rule:check_rule('Fec0:75:1002::')
    lu.assertEquals(result, false)
end



