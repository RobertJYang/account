-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
loadfile(os.getenv('CONFIG_FILE'), 't', {package = package, os = os})()
local lu = require 'luaunit'
local enum = require 'class.types.types'
local base_msg = require 'messages.base'

local function make_interface()
    local interface = {
        enum.LoginInterface.IPMI, enum.LoginInterface.Redfish, enum.LoginInterface.SFTP,
        enum.LoginInterface.SNMP
    }
    return interface
end

-- 新增测试用户
local function setup_account_data(ctx, account_collection, num)
    local account_info = {
        ['id'] = 8,
        ['name'] = "test8",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    for id = 3, num + 3 do
        account_info.id = id
        account_info.name = "test" .. tostring(id)
        account_collection:new_account(ctx, account_info, false)
    end
end

-- 删除测试用户
local function teardown_account_data(ctx, account_collection, num)
    for id = 3, num + 3 do
        if account_collection:get_account_data_by_id(id) then
            account_collection:delete_account(ctx, id)
        end
    end
end

-- 场景1：id不存在，但重名,重名用户不是trap v3用户（构造方法：删除3号用户，更改4号用户名为test3，恢复3号用户信息-> 改名、新建、删除） 
function TestAccount:test_when_id_not_exist_but_name_exist_then_recover_should_succcess()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 3)
    self.test_account_collection:backup_account_info()
    self.test_account_recover:delete_user(self.ctx, 3)
    local changename = 'test3'
    self.test_account_collection:set_user_name(self.ctx, 4, changename)
    self.test_account_recover:recover_account(self.ctx, 3, 0)

    -- 验证效果
    lu.assertIsNil(self.test_account_collection.collection[4])
    lu.assertNotIsNil(self.test_account_collection.collection[3])
    lu.assertEquals(self.test_account_collection:get_user_name(3), 'test3')

    -- 恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

-- 场景2：id不存在，但重名，且重名用户是trap v3用户（构造方法：删除3号用户，更改4号用户名为test3，将4号用户设置为trap v3用户，恢复3号用户信息 -> 改名、日志、新建、删除）
function TestAccount:test_when_id_not_exist_but_name_exist_and_trapv3_then_recover_should_succcess()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 3)
    self.test_account_collection:backup_account_info()
    self.test_account_recover:delete_user(self.ctx, 3)
    local changename = 'test3'
    self.test_account_collection:set_user_name(self.ctx, 4, changename)
    self.test_global_account_config:set_snmp_v3_trap_account(4)
    self.test_account_recover:recover_account(self.ctx, 3, 0)

    -- 验证效果
    lu.assertEquals(self.test_global_account_config:get_snmp_v3_trap_account_id(), 0)
    lu.assertIsNil(self.test_account_collection.collection[4])
    lu.assertNotIsNil(self.test_account_collection.collection[3])
    lu.assertEquals(self.test_account_collection:get_user_name(3), 'test3')

    --恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

-- 场景3：id不存在，不重名（构造方法：删除3号用户，恢复3号用户信息->新建、覆盖）
function TestAccount:test_when_id_not_exist_and_name_not_exist_then_recover_should_success()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 3)
    self.test_account_collection:backup_account_info()
    self.test_account_recover:delete_user(self.ctx, 3)
    self.test_account_recover:recover_account(self.ctx, 3, 0)

    -- 验证效果
    lu.assertNotIsNil(self.test_account_collection.collection[3])
    lu.assertEquals(self.test_account_collection:get_user_name(3), 'test3')

    -- 恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

-- 场景4：id存在，不重名(用户信息可能有变更），待恢复用户不是trap v3用户（构造方法：信息变更：更改3号用户首次登录策略为1,恢复3号用户信息->覆盖）
function TestAccount:test_when_id_exist_and_name_not_exist_then_recover_should_success()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 3)
    self.test_account_collection:backup_account_info()
    self.test_account_collection:set_first_login_policy(self.ctx, 3,
        enum.FirstLoginPolicy.PromptPasswordReset:value())
    self.test_account_recover:recover_account(self.ctx, 3, 0)

    -- 验证效果
    lu.assertNotIsNil(self.test_account_collection.collection[3])
    lu.assertEquals(self.test_account_collection:get_first_login_policy_by_id(3), enum.FirstLoginPolicy.ForcePasswordReset)

    -- 恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

-- 场景5：id存在，不重名(用户信息可能有变更），待恢复用户是trap v3用户（构造：信息变更：更改3号用户用户名为test9,设置3号用户为trap v3用户,恢复3号用户信息 -> 日志、覆盖) 
function TestAccount:test_when_id_exist_and_trapv3_and_name_not_exist_then_recover_should_success()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 3)
    self.test_account_collection:backup_account_info()
    local changename = 'test9'
    self.test_account_collection:set_user_name(self.ctx, 3, changename)
    self.test_global_account_config:set_snmp_v3_trap_account(3)
    self.test_account_recover:recover_account(self.ctx, 3, 0)

    -- 验证效果
    lu.assertEquals(self.test_account_collection:get_user_name(3), 'test3')
    lu.assertEquals(self.test_global_account_config:get_snmp_v3_trap_account_id(), 3)

    -- 恢复环境
    self.test_global_account_config:set_snmp_v3_trap_account(0)
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

-- 场景6：id存在，重名，重名用户不是trap v3用户，待恢复用户也不是trap v3用户（构造方法：更改3号用户名为test9,更改4号用户用户名为test3,恢复3号用户信息-> 改名、覆盖、删除）
function TestAccount:test_when_id_exist_and_name_exist_then_recover_should_success()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 3)
    self.test_account_collection:backup_account_info()
    local username_1 = 'test9'
    local username_2 = 'test3'
    self.test_account_collection:set_user_name(self.ctx, 3, username_1)
    self.test_account_collection:set_user_name(self.ctx, 4, username_2)
    self.test_account_recover:recover_account(self.ctx, 3, 0)

    -- 验证效果
    lu.assertNotIsNil(self.test_account_collection.collection[3])
    lu.assertEquals(self.test_account_collection:get_user_name(3), 'test3')
    lu.assertIsNil(self.test_account_collection.collection[4])

    -- 恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

-- 场景7：id存在，重名，重名用户不是trap v3用户，待恢复用户是trap v3用户(构造：更改3号用户名为test9,更改4号用户用户名为test3，设置3号用户为trap v3用户,恢复3号用户信息 -> 改名、日志、覆盖、删除）
function TestAccount:test_when_id_exist_and_name_exist_and_recover_trapv3_then_recover_should_success()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 3)
    self.test_account_collection:backup_account_info()
    local username_1 = 'test9'
    local username_2 = 'test3'
    self.test_account_collection:set_user_name(self.ctx, 3, username_1)
    self.test_account_collection:set_user_name(self.ctx, 4, username_2)
    self.test_global_account_config:set_snmp_v3_trap_account(3)
    self.test_account_recover:recover_account(self.ctx, 3, 0)

    -- 验证效果
    lu.assertEquals(self.test_account_collection:get_user_name(3), 'test3')
    lu.assertIsNil(self.test_account_collection.collection[4])

    -- 恢复环境
    self.test_global_account_config:set_snmp_v3_trap_account(0)
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

-- 场景8：id存在，重名，重名用户是trap v3用户（构造：更改3号用户名为test9,更改4号用户用户名为test3，设置4号用户为trap v3用户,恢复3号用户信息 -> 日志、改名、覆盖、删除）
function TestAccount:test_when_id_exist_and_name_exist_and_exist_trapv3_then_recover_should_success()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 3)
    self.test_account_collection:backup_account_info()
    local username_1 = 'test9'
    local username_2 = 'test3'
    self.test_account_collection:set_user_name(self.ctx, 3, username_1)
    self.test_account_collection:set_user_name(self.ctx, 4, username_2)
    self.test_global_account_config:set_snmp_v3_trap_account(4)
    self.test_account_recover:recover_account(self.ctx, 3, 0)

    -- 验证效果
    lu.assertEquals(self.test_account_collection:get_user_name(3), 'test3')
    lu.assertIsNil(self.test_account_collection.collection[4])
    lu.assertEquals(self.test_global_account_config:get_snmp_v3_trap_account_id(), 0)

    -- 恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

-- 场景9：id存在，从管理员恢复为非管理员，且无其他管理员(构造：新建3号用户时为非管理员，备份后更改为管理员，且为最后一个使能用户 -> 报错)
function TestAccount:test_when_id_exist_and_administrator_to_operator_and_is_the_last_admin_then_recover_should_fail()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 3)
    self.test_account_collection:backup_account_info()
    self.test_account_collection:set_role_id(self.ctx, 3, enum.RoleType.Administrator:value())
    self.test_account_collection:set_role_id(self.ctx, 2, enum.RoleType.Operator:value())

    -- 验证效果
    lu.assertErrorMsgContains(base_msg.ActionNotSupportedMessage.Name, function()
        self.test_account_recover:recover_account(self.ctx, 3, 0)
    end)

    -- 恢复环境
    self.test_account_collection:set_role_id(self.ctx, 2, enum.RoleType.Administrator:value())
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end

-- 备份后删除3号用户，再进行备份，恢复3号用户信息，应当失败
function TestAccount:test_backup_after_delete_then_recover_should_fail()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 2)
    self.test_account_collection:backup_account_info()
    self.test_account_recover:delete_user(self.ctx, 3)
    self.test_account_collection:backup_account_info()

    -- 验证效果
    lu.assertErrorMsgContains(base_msg.PropertyMissingMessage.Name, function()
        self.test_account_recover:recover_account(self.ctx, 3, 0)
    end)

    --恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 2)
end

-- 验证恢复用户信息后，用户权限恢复成功
function TestAccount:test_privilege_should_be_recovered_after_recover_account()
    -- 构造场景
    setup_account_data(self.ctx, self.test_account_collection, 2)
    self.test_account_collection:set_role_id(self.ctx, 3, enum.RoleType.Administrator:value())
    self.test_account_collection:backup_account_info()
    local privilege_1 = self.test_account_collection.collection[3].current_privileges
    self.test_account_collection:set_role_id(self.ctx, 3, enum.RoleType.CommonUser:value())
    local privilege_2 = self.test_account_collection.collection[3].current_privileges
    self.test_account_recover:recover_account(self.ctx, 3, 0)
    local privilege_3 = self.test_account_collection.collection[3].current_privileges

    -- 验证效果
    lu.assertEquals(privilege_1, privilege_3)
    lu.assertNotEquals(privilege_1, privilege_2)
    lu.assertNotEquals(privilege_2, privilege_3)

    -- 恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 2)
end