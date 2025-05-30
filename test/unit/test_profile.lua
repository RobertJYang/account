-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local sqlite3 = require 'lsqlite3'
local profile_adapter = require 'interface.config_mgmt.profile.profile_adapter'
local mc_context = require 'mc.context'
local cjson = require 'cjson'
local enum = require 'class.types.types'

local function make_interface()
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
        enum.LoginInterface.SFTP, enum.LoginInterface.SNMP }
    return interface
end

-- 删除测试用户
local function teardown_account_data(ctx, account_collection, num)
    for id = 3, num + 3 do
        if account_collection:get_account_data_by_id(id) then
            account_collection:delete_account(ctx, id)
        end
    end
end

function TestAccount:test_when_import_account_config_then_add_user_should_success()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    local PROJECT_DIR = os.getenv('PROJECT_DIR')

    local file = io.open(PROJECT_DIR .. "/test/unit/test_data/config_add_user.json")
    lu.assertNotEquals(file, nil)
    local config_data = file:read("a")
    local object = cjson.decode(config_data).ConfigData
    -- 仅测试User
    object['UserRole'] = nil

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)
    lu.assertEquals(self.test_account_collection:get_user_name(3), 'test3')

    --恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

function TestAccount:test_when_import_account_config_then_delete_user_should_success()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    local PROJECT_DIR = os.getenv('PROJECT_DIR')

    local file = io.open(PROJECT_DIR .. "/test/unit/test_data/config_add_user.json")
    lu.assertNotEquals(file, nil)
    local config_data = file:read("a")
    local object = cjson.decode(config_data).ConfigData
    -- 仅测试User
    object['UserRole'] = nil

    -- 首先添加3号用户
    local interface = make_interface()
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)

    local test_account = self.test_account_collection.collection[3]
    lu.assertEquals(test_account.m_account_data.UserName, "test3")

    -- 使用配置导入删除用户
    object['User'][2]['UserName']['Value'] = ""
    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)
    test_account = self.test_account_collection.collection[3]
    lu.assertIsNil(test_account)
    --恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

function TestAccount:test_when_import_emergency_account_config_then_set_name_should_success()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    local PROJECT_DIR = os.getenv('PROJECT_DIR')

    local file = io.open(PROJECT_DIR .. "/test/unit/test_data/config_add_user.json")
    lu.assertNotEquals(file, nil)
    local config_data = file:read("a")
    local object = cjson.decode(config_data).ConfigData
    -- 仅测试User
    object['UserRole'] = nil

    -- 首先添加3号用户
    local interface = make_interface()
    local account_info = {
        ['id'] = 3,
        ['name'] = "test333",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    -- 设置3号用户为逃生用户
    self.test_account_service:set_emergency_account(self.ctx, 3)
    lu.assertEquals(self.test_global_account_config:get_emergency_account(), 3)

    -- 使用配置导入修改用户名
    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)
    local test_account = self.test_account_collection.collection[3]
    lu.assertEquals(test_account.m_account_data.UserName, "test3")

    -- 清除逃生用户
    self.test_account_service:set_emergency_account(self.ctx, 0)
    --恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

function TestAccount:test_when_import_account_config_then_change2operator_add3admin_should_success()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    local PROJECT_DIR = os.getenv('PROJECT_DIR')

    local file = io.open(PROJECT_DIR .. "/test/unit/test_data/config_add_user.json")
    lu.assertNotEquals(file, nil)
    local config_data = file:read("a")
    local object = cjson.decode(config_data).ConfigData
    -- 仅测试User
    object['UserRole'] = nil

    -- 使用配置导入修改2号用户为操作员，同时新增3号管理员
    object['User'][1]['UserRoleId']['Value'] = "Operator"
    object['User'][1]['Privilege']['Value'] = "Operator"
    local config_service = profile_adapter.new()
    local ok, ret = pcall(function ()
        config_service:on_import(ctx, object)
    end)
    lu.assertEquals(ok, false)
    lu.assertEquals(ret.name, 'CollectingConfigurationErrorDesc')
    local export_res = config_service:on_export(ctx)
    lu.assertEquals(export_res ~= nil, true)

    --恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

function TestAccount:test_when_add_custom_role_then_export_should_success()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    self.test_role_collection:set_extended_custom_role_enabled(true)
    self.test_role_collection:new_role(self.ctx, 9, {'ReadOnly', 'ConfigureSelf'}, {"SecurityMgmt"})
    local config_service = profile_adapter.new()
    local export_res = config_service:on_export(ctx)
    lu.assertEquals(export_res ~= nil, true)
    lu.assertEquals(export_res['UserRole'][9].Id == 'CustomRole5', true)
    --恢复环境
    self.test_role_collection:set_extended_custom_role_enabled(false)
    self.test_role_collection:clear_extended_custom_role(self.ctx)
end

function TestAccount:test_when_not_exist_custom_role_then_import_should_success()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    local PROJECT_DIR = os.getenv('PROJECT_DIR')

    local file = io.open(PROJECT_DIR .. "/test/unit/test_data/config_add_user.json")
    lu.assertNotEquals(file, nil)
    local config_data = file:read("a")
    local object = cjson.decode(config_data).ConfigData
    -- 仅测试UserRole
    self.test_role_collection:set_extended_custom_role_enabled(true)
    object['User'] = nil
    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local data = self.test_role_collection:get_role_data_by_id(9)
    lu.assertEquals(data.RoleName, 'CustomRole5')
    lu.assertEquals(data.ReadOnly, true)
    lu.assertEquals(data.BasicSetting, false)
    lu.assertEquals(data.UserMgmt, false)
    lu.assertEquals(self.test_role_collection:get_role_name_by_id(10), 'CustomRole6')
    lu.assertEquals(self.test_role_collection:get_role_name_by_id(11), 'CustomRole7')
    --恢复环境
    self.test_role_collection:set_extended_custom_role_enabled(false)
    self.test_role_collection:clear_extended_custom_role(self.ctx)
end

function TestAccount:test_when_exist_custom_role_then_delete_should_success()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    local PROJECT_DIR = os.getenv('PROJECT_DIR')

    local file = io.open(PROJECT_DIR .. "/test/unit/test_data/config_add_user.json")
    lu.assertNotEquals(file, nil)
    local config_data = file:read("a")
    local object = cjson.decode(config_data).ConfigData
    -- 仅测试UserRole
    self.test_role_collection:set_extended_custom_role_enabled(true)
    object['User'] = nil
    -- 首先添加自定义角色CostomRole5
    self.test_role_collection:new_role(self.ctx, 9, {'ReadOnly', 'ConfigureSelf'}, {"SecurityMgmt"})
    -- 再次导入配置，删除9号自定义角色
    object['UserRole'][2]['EnabledStatus']['Value'] = false
    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local data = self.test_role_collection:get_role_data_by_id(9)
    lu.assertEquals(data, nil)
    lu.assertEquals(self.test_role_collection:get_role_name_by_id(10), 'CustomRole6')
    lu.assertEquals(self.test_role_collection:get_role_name_by_id(11), 'CustomRole7')
    --恢复环境
    self.test_role_collection:set_extended_custom_role_enabled(false)
    self.test_role_collection:clear_extended_custom_role(self.ctx)
end
