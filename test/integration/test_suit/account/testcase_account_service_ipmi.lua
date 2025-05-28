-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
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

local MANUFACTURE_ID = 0x0007db

local AccountServiceIpmiCaes = {}
AccountServiceIpmiCaes.__index = AccountServiceIpmiCaes

function AccountServiceIpmiCaes.test_ipmi_delete_account(bus)
    -- 先创建用户
    local USER_ID<const> = 0x0a
    local interface = {[1] = 1, [2] = 2, [3] = 4, [4] = 8}
    test_case_utils.call_account_new(bus, 10, 'test10', 'Admin@90001', 4, interface, 1)

    local ipmi_req = {
        ManufactureId = MANUFACTURE_ID,         -- 厂商ID
        UserId        = USER_ID,                -- 用户ID
        Reserved      = 0x00,                   -- 预留位
        UserName      = string.rep('\0', 16)    -- 空名字删除
    }

    local rsp = test_case_utils.ipmi_test_tool_by_ipmitool(ipmi_mds.SetUserName, ipmi_req)
    assert(rsp.CompletionCode == ipmi_types.Cc.Success)
end

return AccountServiceIpmiCaes