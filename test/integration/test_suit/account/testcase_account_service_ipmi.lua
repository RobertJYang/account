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
local json = require 'cjson'
local enums = require 'mc.ipmi.enums'

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

function AccountServiceIpmiCaes.test_ipmi_first_login_change_other_account_passwd_failed(bus)
    -- 先创建用户
    local interface = {[1] = 1, [2] = 2, [3] = 4, [4] = 8}
    test_case_utils.call_account_new(bus, 11, 'test11', 'Admin@90001', 4, interface, 2)
    test_case_utils.set_account_service_property(bus, "InitialAccountPrivilegeRestrictEnabled", true)

    local ipmi_req = {
        ManufactureId = MANUFACTURE_ID,             -- 厂商ID
        UserId        = 0x02,                       -- 用户ID
        Reserved1      = 0x00,                      -- 预留位
        PasswordSize  = string.len("Admin@90002"),  -- 密码长度
        Operation     = 0x02,                       -- 修改密码
        Reserved2     = 0x00,                       -- 预留位2
        PasswordData  = "Admin@90002"               -- 密码
    }

    local ctx = json.encode({ChanType = enums.ChannelType.CT_ME:value(),
            Instance = 0, session = {user = {name = 'test11', id = 11}}})
    local ok, rsp = test_case_utils.ipmi_test_tool_by_dbus_pcall(bus, ipmi_mds.SetAccountPassword, ipmi_req, ctx)
    assert(ok)
    assert(rsp.CompletionCode == ipmi_types.Cc.CommandNotAvailable)

    -- 恢复操作
    test_case_utils.set_account_service_property(bus, "InitialAccountPrivilegeRestrictEnabled", false)
    test_case_utils.call_account_delete(bus, 11)
end

return AccountServiceIpmiCaes