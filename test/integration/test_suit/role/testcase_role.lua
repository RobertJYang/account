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
local enum = require 'class.types.types'
local test_case_utils = require 'testcase_utils'

local ASSIGNED_PRIV_TAB<const> = {'ReadOnly', 'ConfigureSelf', 'BasicSetting'}
local OEM_PRIV_TAB<const> = {'PowerMgmt', 'SecurityMgmt', 'KVMMgmt', 'VMMMgmt', 'DiagnoseMgmt'}

local RoleCases = {}
RoleCases.__index = RoleCases

function RoleCases.test_set_extended_custom_role_enabled(bus)
    local ex_state = test_case_utils.get_roles_property(bus, 'ExtendedCustomRoleEnabled')
    assert(ex_state == false)
    test_case_utils.set_roles_property(bus, 'ExtendedCustomRoleEnabled', true)
    assert(test_case_utils.get_roles_property(bus, 'ExtendedCustomRoleEnabled') == true)
    -- 开启使能后支持新增角色
    test_case_utils.call_new_role(bus, 9, ASSIGNED_PRIV_TAB, OEM_PRIV_TAB)
    assert(test_case_utils.get_role_property(bus, 9, 'Name') == 'CustomRole5')
    -- 关闭使能后应删除自定义角色5~16
    test_case_utils.set_roles_property(bus, 'ExtendedCustomRoleEnabled', false)
    local ok, _ = pcall(function ()
        return test_case_utils.get_role_property(bus, 9, 'Name')
    end)
    assert(not ok)
end

function RoleCases.test_new_role(bus)
    test_case_utils.set_roles_property(bus, 'ExtendedCustomRoleEnabled', true)
    local ok, _ = pcall(function ()
        test_case_utils.call_new_role(bus, 9, ASSIGNED_PRIV_TAB, OEM_PRIV_TAB)
    end)
    assert(ok)
    assert(test_case_utils.get_role_property(bus, 9, 'Name') == 'CustomRole5')
    -- 设置用户使用此角色
    test_case_utils.call_account_new(bus, 3, 'test3', 'Admin@90001', 9, {enum.LoginInterface.Web:value()}, 1)
    assert(test_case_utils.get_account_property(bus, 3, 'RoleId') == 9)
    -- 变更角色权限
    local priv = test_case_utils.get_account_property(bus, 3, 'Privileges')
    assert(#priv == 8)
    test_case_utils.call_set_privilege(bus, 9, enum.PrivilegeType.BasicSetting:value(), false)
    priv = test_case_utils.get_account_property(bus, 3, 'Privileges')
    assert(#priv == 7)
    -- 删除自定义角色后用户降级为普通用户
    test_case_utils.call_delete_role(bus, 9)
    assert(test_case_utils.get_account_property(bus, 3, 'RoleId') == 2)
    -- 恢复操作
    test_case_utils.set_roles_property(bus, 'ExtendedCustomRoleEnabled', false)
    test_case_utils.call_account_delete(bus, 3)
end

return RoleCases
