-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
--
-- Test passwords:[Admin@12345]
local enum = require 'class.types.types'
local test_case_utils = require 'testcase_utils'
local utils = require 'infrastructure.utils'
local config = require 'common_config'
local base_msg = require 'messages.base'

local InterChassisAccountCases = {}
InterChassisAccountCases.__index = InterChassisAccountCases

function InterChassisAccountCases.test_inter_chassis_account_mdb_init(bus)
    assert(test_case_utils.get_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'RoleId') ==
        enum.RoleType.Administrator:value())

    local intf = test_case_utils.get_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'LoginInterface')
    assert(utils.cover_interface_str_to_num(intf) ==
        enum.LoginInterface.Web:value() + enum.LoginInterface.Redfish:value() +
        enum.LoginInterface.SSH:value() + enum.LoginInterface.SFTP:value())

    local visible = test_case_utils.get_account_policy_property(bus, "InterChassis", "Visible")
    assert(visible == false)
end

local inter_chassis_excluded_prop = {
    ['LoginRuleIds'] = {'Rule1'},
    ['UserName'] = 'test',
    ['Enabled'] = false,
    ['PasswordChangeRequired'] = false,
    ['FirstLoginPolicy'] = enum.FirstLoginPolicy.ForcePasswordReset:value(),
}

function InterChassisAccountCases.test_set_inter_chassis_account_prop_forbid(bus)
    local ok, err
    -- 测试属性设置
    for prop, value in pairs(inter_chassis_excluded_prop) do
        ok, err = pcall(function()
            test_case_utils.set_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, prop, value)
        end)
        assert(not ok)
        assert(err.name == base_msg.ActionNotSupportedMessage.Name)
    end

    -- 测试修改密码
    ok, err = pcall(function()
        test_case_utils.call_account_change_pwd(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'Admin@12345')
    end)
    assert(not ok)
    assert(err.name == base_msg.ActionNotSupportedMessage.Name)

    -- 测试修改SNMP密码
    ok, err = pcall(function()
        test_case_utils.call_account_change_snmp_pwd(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'Admin@12345')
    end)
    assert(not ok)
    assert(err.name == base_msg.ActionNotSupportedMessage.Name)

    -- 测试修改SNMP鉴权算法
    ok, err = pcall(function()
        test_case_utils.call_account_set_authentication_protocol(bus, config.INTER_CHASSIS_ACCOUNT_ID, 3, 'Admin@12345', 'Admin@12345')
    end)
    assert(not ok)
    assert(err.name == base_msg.ActionNotSupportedMessage.Name)

    -- 测试修改SNMP加密算法
    ok, err = pcall(function()
        test_case_utils.call_account_set_encryption_protocol(bus, config.INTER_CHASSIS_ACCOUNT_ID, 2)
    end)
    assert(not ok)
    assert(err.name == base_msg.ActionNotSupportedMessage.Name)
end

function InterChassisAccountCases.test_recover_inter_chassis_account(bus)
    -- 记录默认值
    local default_role = test_case_utils.get_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'RoleId')
    local default_intf = test_case_utils.get_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'LoginInterface')

    -- 设置非默认值
    local public_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsd+y4lBfSA16TMIdWFJf9WCu5uUnWTHKRoEbYG3XNuBVCy9c+P87' ..
        '+eMBdE2rpNzL4WwckGmuTGot5Ode5UKP/hfVOes5meziyCw9YxxCni6yv/4+gefI7DPjqu74pOMdo7t0606eto17TzDo4c8tKg//5mt6Lh' ..
        '5RBUBYS2qHRts7xvttfvRTRcHWsNl0sb93P8js0w7pfxQCbxiY9iLGhxdqhhuvE28trGLYffUj7RTslwo5l+IhkoVD/Dm8BUodsHLexQ1d' ..
        'gl4/2NeKNJsIorQoCRuV3XTbcmC7o7WJ52d1hAV9b3rmflVPaVSoUqz6d20d6l5xBeNifZgl0eiir root@DESKTOP-UEELUSH'
    test_case_utils.set_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'RoleId', 2)
    test_case_utils.set_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'LoginInterface', {'Web'})
    test_case_utils.call_account_import_ssh_public_key(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'text', public_key)
    assert(test_case_utils.get_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'SshPublicKeyHash') ==
        'tUxpndtHEnwPnfHPXI+2XDaUoDpAMDJn1azS/+HfOaw')

    -- 触发还原
    local ok = pcall(function()
        test_case_utils.call_account_delete(bus, config.INTER_CHASSIS_ACCOUNT_ID)
    end)
    assert(ok)

    -- 检查是否还原
    assert(test_case_utils.get_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'RoleId') == default_role)
    local intf = test_case_utils.get_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'LoginInterface')
    assert(utils.cover_interface_str_to_num(intf) == utils.cover_interface_str_to_num(default_intf))
    assert(test_case_utils.get_account_property(bus, config.INTER_CHASSIS_ACCOUNT_ID, 'SshPublicKeyHash') == '')
end

return InterChassisAccountCases
