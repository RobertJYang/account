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
local enum = require 'class.types.types'
local file_utils = require 'utils.file'
local test_case_utils = require 'testcase_utils'
local skynet = require 'skynet'
local account_core = require 'account_core'
local mc_context = require 'mc.context'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'

local AccountCases = {}
AccountCases.__index = AccountCases

function AccountCases.test_intf_get_account_by_id(bus)
    local UserName = test_case_utils.get_account_property(bus, 2, 'UserName')
    local RoleId = test_case_utils.get_account_property(bus, 2, 'RoleId')
    local FirstLoginPolicy = test_case_utils.get_account_property(bus, 2, 'FirstLoginPolicy')
    local SNMPAuthenticationProtocol = test_case_utils.get_snmp_property(bus, 2,
        'AuthenticationProtocol')
    local SNMPEncryptionProtocol = test_case_utils.get_snmp_property(bus, 2, 'EncryptionProtocol')

    assert(UserName == 'Administrator')
    assert(RoleId == 4)
    assert(FirstLoginPolicy == enum.FirstLoginPolicy.ForcePasswordReset:value())
    assert(SNMPAuthenticationProtocol == enum.SNMPAuthenticationProtocols.SHA256:value())
    assert(SNMPEncryptionProtocol == enum.SNMPEncryptionProtocols.AES128:value())
end

function AccountCases.test_account_mdb_init(bus)
    assert(test_case_utils.get_account_property(bus, 2, 'RoleId') == 4)
    assert(test_case_utils.get_snmp_property(bus, 2, 'AuthenticationProtocol') ==
        enum.SNMPAuthenticationProtocols.SHA256:value())
end

local function make_interface()
    local interface = {
        enum.LoginInterface.IPMI, enum.LoginInterface.Redfish, enum.LoginInterface.SFTP
    }
    return interface
end

-- 创建用户并检查用户属性
function AccountCases.test_new_account_and_check_account_properties(bus)
    local interface = {[1] = 1, [2] = 2, [3] = 4, [4] = 8}
    test_case_utils.call_account_new(bus, 3, 'test3', 'Admin@90001', 4, interface, 1)
    assert(test_case_utils.get_account_property(bus, 3, 'RoleId') == 4)
    assert(test_case_utils.get_account_property(bus, 3, 'PasswordChangeRequired') == true)
    -- 恢复操作
    test_case_utils.call_account_delete(bus, 3)
end

function AccountCases.test_new_account(bus)
    local interface = make_interface()
    assert(test_case_utils.call_account_new(bus, 3, 'test3', 'Admin@90', 4, interface, 1) == 3)
    assert(test_case_utils.get_account_property(bus, 3, 'RoleId') == 4)
    test_case_utils.call_account_delete(bus, 3)

    assert(test_case_utils.call_account_new(bus, 5, 'test5', 'Admin@90001234567891', 4, interface, 1) == 5)
    local ok, err = pcall(function()
        test_case_utils.call_account_new(bus, 4, 'test4', 'Admin@900012345678912', 4, interface, 1)
    end)
    assert(not ok)
    assert(err.name == custom_msg.InvalidPasswordLengthMessage.Name)

    ok, err = pcall(function()
        test_case_utils.call_account_new(bus, 4, 'test4', 'Admin@9', 4, interface, 1)
    end)
    assert(not ok)
    assert(err.name == custom_msg.PasswordComplexityCheckFailMessage.Name)

    -- 清理账户
    test_case_utils.call_account_delete(bus, 5)
end

--- 新建用户不指定id(id=0),应当添加成功
function AccountCases.test_new_account_without_account_id_should_success(bus)
    local interface = make_interface()
    local account_id = test_case_utils.call_account_new(bus, 0, 'test', 'Admin@900', 4, interface, 1)
    --  此时本地用户仅有2号Administrator，新增用户id应为3
    assert(account_id == 3)
    account_id = test_case_utils.call_account_new(bus, 0, 'test2', 'Admin@900', 4, interface, 1)
    --  再次不指定id添加用户，该用户id应为4
    assert(account_id == 4)
    --  恢复操作
    test_case_utils.call_account_delete(bus, 3)
    test_case_utils.call_account_delete(bus, 4)
end

--- 新建id为1的用户，应当创建失败
function AccountCases.test_new_account_with_id_eq_1_should_create_failed(bus)
    local interface = make_interface()
    local ok, err = pcall(function()
        test_case_utils.call_account_new(bus, 1, 'test', 'Admin@900', 4, interface, 1)
    end)
    -- 创建失败
    assert(not ok)
    assert(err.name == custom_msg.PropertyValueOutOfRangeMessage.Name)
end

--- 用户已满时不指定id创建用户，应当创建失败
function AccountCases.test_new_account_when_user_is_full_should_create_failed(bus)
    local interface = make_interface()
    -- 添加id:3-17的本地用户
    for i = 3, 17 do
        test_case_utils.call_account_new(bus, i, 'test' .. i, 'Admin@900', 4, interface, 1)
    end

    -- 不指定用户id添加用户
    local ok, err = pcall(function()
        test_case_utils.call_account_new(bus, 0, 'test123', 'Admin@900', 4, interface, 1)
    end)

    -- 创建失败
    assert(not ok)
    assert(err.name == base_msg.CreateLimitReachedForResourceMessage.Name)

    -- 恢复操作
    for i = 3, 17 do
        test_case_utils.call_account_delete(bus, i)
    end
end

function AccountCases.test_change_account_pwd(bus)
    -- 关闭历史密码校验
    test_case_utils.set_account_service_property(bus, 'HistoryPasswordCount', 0)
    test_case_utils.call_account_change_pwd(bus, 2, 'Admin@9000123')

    local ext_config = {
        ["RecordLoginInfo"]  = false,
        ["UpdateActiveTime"] = false,
        ["IsAuthPassword"]   = true
    }
    local ctx = mc_context.new('Web', 'Administrator', '127.0.0.1')
    local res = test_case_utils.call_local_authenticate(bus, ctx, 'Administrator', 'Admin@9000123', ext_config)
    assert(tonumber(res.Id) == 2)
    assert(res.UserName == 'Administrator')

    test_case_utils.call_account_change_pwd(bus, 2, 'Admin@90001234567891')
    local password_expired = test_case_utils.get_account_property(bus, 2, 'PasswordExpiration')
    assert(password_expired == 0xffffffff)
    local ok, err = pcall(function()
        test_case_utils.call_account_change_pwd(bus, 2, 'Admin@900012345678912')
    end)
    assert(not ok)
    assert(err.name == custom_msg.InvalidPasswordLengthMessage.Name)

    ok, err = pcall(function()
        test_case_utils.call_account_change_pwd(bus, 2, 'Admin@9')
    end)
    assert(not ok)
    assert(err.name == custom_msg.PasswordComplexityCheckFailMessage.Name)

    -- 恢复操作
    test_case_utils.call_account_change_pwd(bus, 2, 'Admin@9000')
end

function AccountCases.test_change_interface(bus)
    local old_interface = test_case_utils.get_account_property(bus, 2, 'LoginInterface')
    local interface_str = {'IPMI', 'Web'}
    test_case_utils.set_account_property(bus, 2, 'LoginInterface', interface_str)
    local changed_interface = test_case_utils.get_account_property(bus, 2, 'LoginInterface')
    assert(#changed_interface == #interface_str)
    -- 修改为不合法的interface时会阻止修改，因此会和原来保持一致
    local err_str = {'IPMI', 'Web', '64'}
    local ret = pcall(test_case_utils.set_account_property, bus, 2, 'LoginInterface', err_str)
    assert(not ret)
    local err_interface = test_case_utils.get_account_property(bus, 2, 'LoginInterface')
    assert(#err_interface == #changed_interface)
    test_case_utils.set_account_property(bus, 2, 'LoginInterface', old_interface)
end

--  新建用户，修改roleid为正常值应修改成功
function AccountCases.test_change_new_account_role_id_to_valid_value_should_success(bus)
    --  新建用户
    local interface = make_interface()
    test_case_utils.call_account_new(bus, 3, 'test3', 'Admin@90', 4, interface, 1)
    local old_roleid = test_case_utils.get_account_property(bus, 3, 'RoleId')
    assert(old_roleid == 4)
    test_case_utils.set_account_property(bus, 3, 'RoleId', 3)
    local changed_roleid = test_case_utils.get_account_property(bus, 3, 'RoleId')
    assert(changed_roleid == 3)
    test_case_utils.call_account_delete(bus, 3)
end

---  设置最后一个使能管理员角色为非管理员，应当设置失败
function AccountCases.test_when_set_last_enabled_admin_account_role_id_to_not_admin_should_failed(bus)
    local ok, err = pcall(test_case_utils.set_account_property, bus, 2, 'RoleId', 3)
    assert(not ok and err.name == base_msg.AccountNotModifiedMessage.Name)
    --  设置失败且用户2角色依然为管理员
    local err_roleid = test_case_utils.get_account_property(bus, 2, 'RoleId')
    assert(err_roleid == 4)
end

--- 设置用户使能成功
function AccountCases.test_when_set_account_enabled_shoule_set_success(bus)
    -- 创建用户3为管理员
    local account_id = 3
    test_case_utils.call_account_new(bus, account_id, 'test3', 'Admin@9000', 4,
        { enum.LoginInterface.Web:value() }, 1)
    local old_enabled = test_case_utils.get_account_property(bus, account_id, 'Enabled')
    assert(old_enabled == true)
    -- 修改用户3使能为false
    test_case_utils.set_account_property(bus, account_id, 'Enabled', false)
    local changed_enabled = test_case_utils.get_account_property(bus, account_id, 'Enabled')
    assert(changed_enabled == false)
    -- 恢复操作
    test_case_utils.set_account_property(bus, account_id, 'Enabled', old_enabled)
    test_case_utils.call_account_delete(bus, account_id)
end

---  禁用最后一个使能管理员角色为非管理员，应当禁用失败
function AccountCases.test_when_disable_last_enabled_admin_should_set_fail(bus)
    local ok, err = pcall(test_case_utils.set_account_property, bus, 2, 'Enabled', false)
    assert(not ok and err.name == custom_msg.CannotDisableLastAdministratorMessage.Name)
    --  设置失败且用户2仍然使能
    local enabled = test_case_utils.get_account_property(bus, 2, 'Enabled')
    assert(enabled == true)
end

--- 使能用户前检查密码是否满足复杂度，否则使能失败
function AccountCases.test_when_password_not_meet_complexity_shoule_enable_fail(bus)
    -- 关闭密码复杂度校验
    test_case_utils.set_account_service_property(bus, 'PasswordComplexityEnable', false)
    local account_id = 3
    test_case_utils.call_account_new(bus, account_id, 'test3', '123456789', 4,
        { enum.LoginInterface.IPMI:value() }, 1)
    test_case_utils.set_account_property(bus, account_id, 'Enabled', false)
    -- 开启密码复杂度校验
    test_case_utils.set_account_service_property(bus, 'PasswordComplexityEnable', true)
    local ok, err = pcall(test_case_utils.set_account_property, bus, account_id, 'Enabled', true)
    assert(not ok and err.name == custom_msg.PasswordComplexityCheckFailMessage.Name)
    -- 恢复操作
    test_case_utils.call_account_delete(bus, account_id)
end

function AccountCases.test_change_role_id(bus)
    -- 修改为不合法的role_id时会阻止修改，因此会和原来保持一致
    local ret = pcall(test_case_utils.set_account_property, bus, 2, 'RoleId', 10)
    assert(not ret)
    local err_roleid = test_case_utils.get_account_property(bus, 2, 'RoleId')
    assert(err_roleid == 4)
end

function AccountCases.test_change_user_name(bus)
    local interface = make_interface()
    test_case_utils.call_account_new(bus, 3, 'test3', 'Admin@9000', 4, interface, 1)
    assert(test_case_utils.get_account_property(bus, 3, 'RoleId') == 4)

    test_case_utils.set_account_property(bus, 3, 'UserName', 'test3_new')
    local changed_username = test_case_utils.get_account_property(bus, 3, 'UserName')
    assert(changed_username == 'test3_new')

    -- 恢复操作
    test_case_utils.call_account_delete(bus, 3)
end

function AccountCases.test_change_password_required(bus)
    local old_required = test_case_utils.get_account_property(bus, 2, 'PasswordChangeRequired')
    local new_requred = not old_required
    test_case_utils.set_account_property(bus, 2, 'PasswordChangeRequired', new_requred)
    local changed_required = test_case_utils.get_account_property(bus, 2, 'PasswordChangeRequired')
    assert(changed_required == new_requred)
    test_case_utils.set_account_property(bus, 2, 'PasswordChangeRequired', old_required)
end

function AccountCases.test_first_login_policy(bus)
    test_case_utils.set_account_property(bus, 2, 'FirstLoginPolicy', 2)
    local res = test_case_utils.get_account_property(bus, 2, 'FirstLoginPolicy')
    assert(res == 2)
end

function AccountCases.test_change_snmp_pwd(bus)
    local old_encrypt_ku = test_case_utils.get_snmp_key(bus, 2, 'EncryptionKey')
    assert(old_encrypt_ku)
    test_case_utils.call_account_change_snmp_pwd(bus, 2, 'Admin@9000123')
    local new_encrypt_ku = test_case_utils.get_snmp_key(bus, 2, 'EncryptionKey')
    assert(old_encrypt_ku ~= new_encrypt_ku)
    -- 恢复操作
    test_case_utils.call_account_change_snmp_pwd(bus, 2, 'Admin@9000')
end

function AccountCases.test_change_user_auth_protocol(bus)
    -- 关闭历史密码校验
    test_case_utils.set_account_service_property(bus, 'HistoryPasswordCount', 0)
    test_case_utils.call_account_set_authentication_protocol(bus, 2, enum.SNMPAuthenticationProtocols.SHA224:value(),
        'Admin@9000123', 'Admin@9000123')

    assert(test_case_utils.get_snmp_property(bus, 2, 'AuthenticationProtocol') == 3)
    assert(test_case_utils.get_snmp_key(bus, 2, 'AuthenticationKey') ==
               test_case_utils.get_snmp_key(bus, 2, 'EncryptionKey'))

    -- 恢复
    test_case_utils.call_account_set_authentication_protocol(bus, 2, enum.SNMPAuthenticationProtocols.SHA256:value(),
        'Admin@9000', 'Admin@9000')
end

function AccountCases.test_change_user_encrypt_protocol(bus)
    test_case_utils.call_account_set_encryption_protocol(bus, 2, enum.SNMPEncryptionProtocols.AES256:value())
    test_case_utils.call_account_set_encryption_protocol(bus, 2, enum.SNMPEncryptionProtocols.AES128:value())
end

-- --- 当创建用户时，应该创建用户根文件目录
-- --- 当删除用户时，应该删除用户根文件目录
function AccountCases.test_when_new_account_should_create_account_root_folder(bus)
    local root_folder_path =
        account_core.format_realpath(table.concat({ skynet.getenv('DATA_HOME_PATH'), 'test3' }, '/'))
    assert(file_utils.check_real_path_s(root_folder_path) == -1)
    test_case_utils.call_account_new(bus, 3, 'test3', 'Admin@9000', 4, make_interface(), 1)
    assert(file_utils.check_real_path_s(root_folder_path) == 0)
    test_case_utils.call_account_delete(bus, 3)
    assert(file_utils.check_real_path_s(root_folder_path) == -1)
end

--- 当没有ConfigureSelf权限用户，修改自身密码应该失败 (在框架层拦截)
--- 当有ConfigureSelf权限用户，修改自身密码应该成功
function AccountCases.test_when_account_have_config_self_privilege_should_change_self_password_success(bus)
    local account_id, role_id = 3, enum.RoleType.CustomRole1:value()
    test_case_utils.call_account_new(bus, account_id, 'test3', 'Admin@90000',
        role_id, { enum.LoginInterface.Web:value() }, 1)
    -- 修改自身密码
    local initial_context = test_case_utils.initiator
    local current_context = mc_context.new('IT', 'test3', '127.0.0.1')
    test_case_utils.initiator = current_context
    local ok, err = pcall(test_case_utils.call_account_change_pwd, bus, account_id, 'Admin@900000')
    test_case_utils.initiator = initial_context
    assert(ok and not err)
    -- 恢复操作
    test_case_utils.call_account_delete(bus, account_id)
end

--- 当非管理员用户修改其他用户密码，应该失败
function AccountCases.test_when_not_admin_account_should_change_other_password_fail(bus)
    local role_id = enum.RoleType.CustomRole1:value()
    test_case_utils.call_account_new(bus, 3, 'test3', 'Admin@90000',
        role_id, { enum.LoginInterface.Web:value() }, 1)
    test_case_utils.call_account_new(bus, 4, 'test4', 'Admin@90000',
        role_id, { enum.LoginInterface.Web:value() }, 1)
    -- 修改自身密码
    local initial_context = test_case_utils.initiator
    local current_context = mc_context.new('IT', 'test3', '127.0.0.1')
    test_case_utils.initiator = current_context
    local ok, err = pcall(test_case_utils.call_account_change_pwd, bus, 4, 'Admin@900000')
    test_case_utils.initiator = initial_context
    assert(not ok)
    assert(err.name == base_msg.InsufficientPrivilegeMessage.Name)
    -- 恢复操作
    test_case_utils.call_account_delete(bus, 3)
    test_case_utils.call_account_delete(bus, 4)
end

--- 当用户修改的密码中含有中文时，应该失败
function AccountCases.test_when_password_contains_chinese_should_change_fail(bus)
    local role_id = enum.RoleType.Administrator:value()
    test_case_utils.call_account_new(bus, 3, 'test3', 'Admin@90000',
        role_id, { enum.LoginInterface.Web:value() }, 1)
    local ok, err = pcall(test_case_utils.call_account_change_pwd, bus, 3, '中文damie@134')
    assert(not ok)
    assert(err.name == custom_msg.InvalidPasswordMessage.Name)
    -- 恢复操作
    test_case_utils.call_account_delete(bus, 3)
end

--- 当用户为逃生用户，Deletable属性应该为false
function AccountCases.test_when_account_is_emergency_account_should_deletable_is_false(bus)
    local account_id = 3
    test_case_utils.call_account_new(bus, account_id, 'test3', 'Admin@90000', 4,
        { enum.LoginInterface.Web:value() }, 1)
    test_case_utils.set_account_service_property(bus, 'EmergencyLoginAccountId', account_id)
    local deletable = test_case_utils.get_account_property(bus, account_id, 'Deletable')
    assert(deletable == false)
    -- 恢复操作
    test_case_utils.set_account_service_property(bus, 'EmergencyLoginAccountId', 0)
    test_case_utils.call_account_delete(bus, account_id)
end

--- 当snmpv3trap用户修改策略为1或者2时，用户为SNMPv3Trap用户，Deletable属性应该为false
--- 当snmpv3trap用户修改策略为0时，用户为SNMPv3Trap用户，Deletable属性应该为true
function AccountCases.test_when_account_is_snmp_v3_trap_account_should_deletable_is_false(bus)
    local origin = test_case_utils.get_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy')
    assert(origin == 2)
    local account_id = 3
    test_case_utils.call_account_new(bus, account_id, 'test3', 'Admin@90000', 4,
        { enum.LoginInterface.Web:value() }, 1)
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', account_id)
    local deletable = test_case_utils.get_account_property(bus, account_id, 'Deletable')
    assert(deletable == false)

    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy', 1)
    deletable = test_case_utils.get_account_property(bus, account_id, 'Deletable')
    assert(deletable == false)

    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy', 0)
    deletable = test_case_utils.get_account_property(bus, account_id, 'Deletable')
    assert(deletable == true)
    -- 恢复操作
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', 2)
    test_case_utils.call_account_delete(bus, account_id)
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy', origin)
end

--- 当用户为最后一个使能管理员，Deletable属性应该为false
function AccountCases.test_when_account_is_last_admin_account_should_deletable_is_false(bus)
    local deletable = test_case_utils.get_account_property(bus, 2, 'Deletable')
    assert(deletable == false)
end

--- 当用户不为（逃生用户/SNMPv3Trap用户/最后一个使能管理员），Deletable属性应该为true
function AccountCases.test_when_account_is_normal_should_deletable_is_true(bus)
    local account_id = 3
    test_case_utils.call_account_new(bus, account_id, 'test3', 'Admin@90000', 4, { enum.LoginInterface.Web:value() }, 1)
    local deletable = test_case_utils.get_account_property(bus, account_id, 'Deletable')
    assert(deletable == true)
    -- 恢复操作
    test_case_utils.call_account_delete(bus, account_id)
end

--- 当仅有一个管理员用户时不能删除该用户，新建一个管理员用户后旧的管理员用户应该可以删除
function AccountCases.test_when_new_second_administrator_should_first_administrator_is_deletable(bus)
    local deletable = test_case_utils.get_account_property(bus, 2, 'Deletable')
    assert(deletable == false)
    -- 创建用户3为管理员
    local second_adminaccount_id = 3
    test_case_utils.call_account_new(bus, second_adminaccount_id, 'test3', 'Admin@90000', 4,
        { enum.LoginInterface.Web:value() }, 1)
    -- 设置用户3为snmptrapv3用户
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', 3)
    deletable = test_case_utils.get_account_property(bus, 2, 'Deletable')
    assert(deletable == true)

    -- 恢复操作
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', 2)
    test_case_utils.call_account_delete(bus, second_adminaccount_id)
end

--- 当仅有一个管理员用户时不能删除该用户，设置其他用户为新管理员后旧的管理员用户应该可以删除
function AccountCases.test_when_set_seconde_administrator_should_first_administrator_is_deletable(bus)
    -- 创建用户3为非管理员
    local test_id = 3
    test_case_utils.call_account_new(bus, test_id, 'test3', 'Admin@90000', 3,
        { enum.LoginInterface.Web:value() }, 1)
    -- 设置用户3为snmptrapv3用户
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', 3)
    local deletable = test_case_utils.get_account_property(bus, 2, 'Deletable')
    assert(deletable == false)
    -- 将用户3修改为管理员
    test_case_utils.set_account_property(bus, test_id, 'RoleId', 4)
    deletable = test_case_utils.get_account_property(bus, 2, 'Deletable')
    assert(deletable == true)

    -- 恢复操作
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', 2)
    test_case_utils.call_account_delete(bus, test_id)
end

--- 当SNMPv3Trap用户修改策略变更为1时，SNMPv3Trap用户改名字应该成功，删除用户应该失败
function AccountCases.test_when_change_trap_limit_policy_to_1_should_rename_success_delete_fail(bus)
    local origin = test_case_utils.get_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy')
    assert(origin == 2)
    local account_id = 3
    test_case_utils.call_account_new(bus, account_id, 'test3', 'Admin@90000', 4, { enum.LoginInterface.Web:value() }, 1)
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', account_id)

    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy', 1)
    local ok = pcall(test_case_utils.set_account_property, bus, 3, 'UserName', 'test3_new')
    assert(ok == true)
    local err
    ok, err = pcall(test_case_utils.call_account_delete, bus, 3)
    assert(ok == false, err.name == custom_msg.AccountForbidRemovedMessage.Name)

    -- 恢复操作
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy', origin)
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', 2)
    test_case_utils.call_account_delete(bus, account_id)
end

--- 当SNMPv3Trap用户修改策略变更为0时，SNMPv3Trap用户改名字应该成功，删除用户应该成功
function AccountCases.test_when_change_trap_limit_policy_to_0_should_rename_success_delete_success(bus)
    local origin = test_case_utils.get_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy')
    assert(origin == 2)
    local account_id = 3
    test_case_utils.call_account_new(bus, account_id, 'test3', 'Admin@90000', 4, { enum.LoginInterface.Web:value() }, 1)
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', account_id)

    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy', 0)
    local ok = pcall(test_case_utils.set_account_property, bus, 3, 'UserName', 'test3_new')
    assert(ok == true)
    ok = pcall(test_case_utils.call_account_delete, bus, 3)
    assert(ok == true)

    -- 恢复操作
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy', origin)
    test_case_utils.set_account_service_property(bus, 'SNMPv3TrapAccountId', 2)
end

--- 当SNMPv3Trap用户修改策略为默认值2时，SNMPv3Trap用户改名字应该失败，删除用户应该失败
function AccountCases.test_when_trap_limit_policy_is_2_should_rename_fail_delete_success(bus)
    local origin_policy = test_case_utils.get_account_service_property(bus, 'SNMPv3TrapAccountLimitPolicy')
    assert(origin_policy == 2)
    local origin = test_case_utils.get_account_service_property(bus, 'SNMPv3TrapAccountId')
    assert(origin == 2)

    local ok, err = pcall(test_case_utils.set_account_property, bus, 2, 'UserName', 'test')
    assert(ok == false, err.name == custom_msg.SNMPV3TrapUserNameCannotBeChangedMessage.Name)
    ok, err = pcall(test_case_utils.call_account_delete, bus, 2)
    assert(ok == false, err.name == custom_msg.AccountForbidRemovedMessage.Name)
end

return AccountCases
