-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
--
-- Test passwords:[Admin@9000, Admin@90001234567891, Admin@900012345678912,
-- Admin@90001234567891, Admin@900012345678912]
local class = require 'mc.class'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local ipmi_types = require 'ipmi.types'
local enum = require 'class.types.types'
local ipmi_mds = require 'account.ipmi.ipmi'
local test_case_utils = require 'testcase_utils'

local PasswordValidatorIpmiCases = {}
PasswordValidatorIpmiCases.__index = PasswordValidatorIpmiCases

local PROP_NAME_POLICY  = 'Policy'
local PROP_NAME_PATTERN = 'Pattern'

local MANUFACTURE_ID = 0x0007db

local function get_ipmi_req(account_type)
    return {
        ManufactureId = MANUFACTURE_ID,   -- 厂商ID
        AccountType   = account_type,     -- 用户类型
        Reserved      = 0x00              -- 预留位
    }
end

local function set_ipmi_req(account_type, data)
    return {
        ManufactureId = MANUFACTURE_ID,   -- 厂商ID
        AccountType   = account_type,     -- 用户类型
        Reserved      = 0x00,             -- 预留位
        Length        = string.len(data), -- 数据长度
        Data          = data              -- 写入数据
    }
end

function PasswordValidatorIpmiCases.test_ipmi_set_policy_success(bus)
    -- 1、拿到默认值，恢复环境用
    local default_policy = test_case_utils.get_password_policy_property(bus, tostring(enum.AccountType.Local),
        PROP_NAME_POLICY)
    local default_pattern = test_case_utils.get_password_policy_property(bus, tostring(enum.AccountType.Local),
        PROP_NAME_PATTERN)

    -- 2、设置 policy 为 Default
    local set_policy_ipmi_req = set_ipmi_req(enum.AccountType.Local:value(), '\x01') -- 0x01 Default
    local rsp = test_case_utils.ipmi_test_tool_by_ipmitool(ipmi_mds.SetPasswordRulePolicy, set_policy_ipmi_req)
    assert(rsp.CompletionCode == ipmi_types.Cc.Success)
    assert(rsp.ManufactureId == MANUFACTURE_ID)

    -- 3、设置 pattern 后再设置 policy 为 Customized
    local custom_regex = '^ABC$'
    local set_pattern_ipmi_req = set_ipmi_req(enum.AccountType.Local:value(), custom_regex)
    rsp = test_case_utils.ipmi_test_tool_by_ipmitool(ipmi_mds.SetPasswordPattern, set_pattern_ipmi_req)
    assert(rsp.CompletionCode == ipmi_types.Cc.Success)
    assert(rsp.ManufactureId == MANUFACTURE_ID)

    set_policy_ipmi_req = set_ipmi_req(enum.AccountType.Local:value(), '\x02') -- 0x02 Customized
    rsp = test_case_utils.ipmi_test_tool_by_ipmitool(ipmi_mds.SetPasswordRulePolicy, set_policy_ipmi_req)
    assert(rsp.CompletionCode == ipmi_types.Cc.Success)
    assert(rsp.ManufactureId == MANUFACTURE_ID)

    -- 4、查看刚才设置的值
    local get_policy_ipmi_req = get_ipmi_req(enum.AccountType.Local:value())
    rsp = test_case_utils.ipmi_test_tool_by_ipmitool(ipmi_mds.GetPasswordRulePolicy, get_policy_ipmi_req)
    assert(rsp.CompletionCode == ipmi_types.Cc.Success)
    assert(rsp.ManufactureId == MANUFACTURE_ID)
    assert(rsp.Length == 1)
    assert(rsp.Data == '\x02')

    local get_pattern_ipmi_req = get_ipmi_req(enum.AccountType.Local:value())
    rsp = test_case_utils.ipmi_test_tool_by_ipmitool(ipmi_mds.GetPasswordPattern, get_pattern_ipmi_req)
    assert(rsp.CompletionCode == ipmi_types.Cc.Success)
    assert(rsp.ManufactureId == MANUFACTURE_ID)
    assert(rsp.Length == string.len(custom_regex))
    assert(rsp.Data == custom_regex)

    -- 5、恢复环境
    test_case_utils.set_password_policy_property(bus, tostring(enum.AccountType.Local),
        PROP_NAME_POLICY, default_policy)
    test_case_utils.set_password_policy_property(bus, tostring(enum.AccountType.Local), PROP_NAME_PATTERN,
        default_pattern)
end

function PasswordValidatorIpmiCases.test_ipmi_set_policy_with_invalid_param_should_fail(bus)
    -- 1、拿到默认值
    local default_policy = test_case_utils.get_password_policy_property(bus, tostring(enum.AccountType.Local),
        PROP_NAME_POLICY)

    -- 2、传入无效的 account_type: 4
    local set_policy_req = set_ipmi_req(4, '\x02') -- 0x01 Customized
    local _, rsp = test_case_utils.ipmi_test_tool_by_dbus_pcall(bus, ipmi_mds.SetPasswordRulePolicy,set_policy_req)
    assert(rsp == nil)

    -- 3、传入无效的数据长度
    set_policy_req = set_ipmi_req(enum.AccountType.Local:value(), '\x02') -- 0x01 Customized
    set_policy_req.Length = set_policy_req.Length + 1
    _, rsp = test_case_utils.ipmi_test_tool_by_dbus_pcall(bus, ipmi_mds.SetPasswordRulePolicy, set_policy_req)
    assert(rsp == nil)

    set_policy_req = set_ipmi_req(enum.AccountType.Local:value(), '\x01\x02') -- 无效数据 0x0102
    set_policy_req.Length = 1
    _, rsp = test_case_utils.ipmi_test_tool_by_dbus_pcall(bus, ipmi_mds.SetPasswordRulePolicy, set_policy_req)
    assert(rsp == nil)

    -- 4、查看policy设置失败，还是默认值
    local get_policy_req = get_ipmi_req(enum.AccountType.Local:value())
    rsp = test_case_utils.ipmi_test_tool_by_dbus(bus, ipmi_mds.GetPasswordRulePolicy, get_policy_req)
    assert(rsp.Length == 1)
    assert(string.byte(rsp.Data) == default_policy)
end

function PasswordValidatorIpmiCases.test_ipmi_set_pattern_with_invalid_param_should_fail(bus)
    -- 1、拿到默认值
    local default_pattern = test_case_utils.get_password_policy_property(bus, tostring(enum.AccountType.Local),
        PROP_NAME_PATTERN)

    -- 2、设置超长的正则(>255)
    local pattern = "^AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAA$"
    local set_pattern_req = set_ipmi_req(enum.AccountType.Local:value(), pattern)
    local _, rsp = test_case_utils.ipmi_test_tool_by_dbus_pcall(bus, ipmi_mds.SetPasswordPattern, set_pattern_req)
    assert(rsp == nil)

    -- 3、设置无效的正则(没有起始符或者结束符)
    pattern = "^AAAAA"
    set_pattern_req = set_ipmi_req(enum.AccountType.Local:value(), pattern)
    _, rsp = test_case_utils.ipmi_test_tool_by_dbus_pcall(bus, ipmi_mds.SetPasswordPattern, set_pattern_req)
    assert(rsp == nil)

    pattern = "AAAAA$"
    set_pattern_req = set_ipmi_req(enum.AccountType.Local:value(), pattern)
    _, rsp = test_case_utils.ipmi_test_tool_by_dbus_pcall(bus, ipmi_mds.SetPasswordPattern, set_pattern_req)
    assert(rsp == nil)

    -- 4、查看pattern设置失败，还是默认值
    local get_pattern_req = get_ipmi_req(enum.AccountType.Local:value())
    rsp = test_case_utils.ipmi_test_tool_by_dbus(bus, ipmi_mds.GetPasswordPattern, get_pattern_req)
    assert(rsp.Length == 0)
    assert(rsp.Data == default_pattern)
end

return PasswordValidatorIpmiCases