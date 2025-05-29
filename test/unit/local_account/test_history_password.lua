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
local enum = require 'class.types.types'
local history_password = require 'infrastructure.history_password'
local manager_account = require 'domain.manager_account.manager_account'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'

local function make_interface()
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
        enum.LoginInterface.SFTP, enum.LoginInterface.SNMP }
    return interface
end

--- 当设置历史密码数0->1, 历史密码表中每个用户都存了当前密码hash值
function TestAccount:test_when_set_hisotory_password_count_0_to_1_should_insert_current_password()
    self.test_account_service:set_history_password_count(1)
    for _, account in pairs(self.test_account_collection.collection) do
        if account.m_account_data.AccountType ~= enum.AccountType.Local then
            goto continue
        end

        local account_id = account.m_account_data.Id
        local history_password_list = self.db:select(self.db.HistoryPassword)
            :where(self.db.HistoryPassword.AccountId:eq(account_id)):all()
        lu.assertEquals(#history_password_list, 1)
        lu.assertEquals(history_password_list[1].Password, account.m_account_data.Password)
        lu.assertEquals(history_password_list[1].KDFPassword, account.m_account_data.KDFPassword)
        ::continue::
    end
    -- 恢复操作
    self.test_account_service:set_history_password_count(0)
end

--- 当设置历史密码数1->0, 应该清空历史密码表
function TestAccount:test_when_set_hisotory_password_count_1_to_0_should_clear_history_password()
    self.test_account_service:set_history_password_count(1)
    local history_password_list = self.db:select(self.db.HistoryPassword):all()
    lu.assertNotEquals(#history_password_list, 0)
    self.test_account_service:set_history_password_count(0)
    history_password_list = self.db:select(self.db.HistoryPassword):all()
    lu.assertEquals(#history_password_list, 0)
end

--- 当创建用户，应该保存历史密码
--- 当删除用户，应该删除历史密码
function TestAccount:test_when_new_account_should_insert_history_password()
    local account_id = 4
    self.test_account_service:set_history_password_count(1)
    local account_info = {
        ['id'] = account_id,
        ['name'] = "test4",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_service:new_account(self.ctx, account_info, false)
    local history_password_list = self.db:select(self.db.HistoryPassword)
        :where(self.db.HistoryPassword.AccountId:eq(account_id)):all()
    lu.assertEquals(#history_password_list, 1)
    self.test_account_collection:delete_account(self.ctx, account_id)
    history_password_list = self.db:select(self.db.HistoryPassword)
        :where(self.db.HistoryPassword.AccountId:eq(account_id)):all()
    lu.assertEquals(#history_password_list, 0)
    -- 恢复操作
    self.test_account_service:set_history_password_count(0)
end

--- 当对用户2插入历史密码时，数据库中应能查到该密码，且序号为1
function TestAccount:test_when_account_insert_history_password_should_find_in_db()
    self.test_global_account_config:set_history_password_count(2)
    local history_password_inst = self.test_account_collection.collection[2].m_history_password
    history_password_inst:insert('Paswd@9000', 'Paswd@9000',
        self.test_global_account_config:get_history_password_count())
    local history_password_list = history_password_inst:get()
    lu.assertEquals(#history_password_list, 2)
    lu.assertEquals(history_password_list[1].Password,
        '')
    lu.assertEquals(history_password_list[1].SequenceNumber, 2)
    -- 恢复操作
    self.test_global_account_config:set_history_password_count(0)
    history_password_inst:delete()
    history_password_list = history_password_inst:get()
    lu.assertEquals(#history_password_list, 0)
end

--- 当对用户2插入历史密码时，原来的历史密码序号自增1
function TestAccount:test_when_account_insert_history_password_should_sequence_add_1()
    local history_password_inst = history_password.new(self.db, 2)
    self.test_global_account_config:set_history_password_count(2)
    history_password_inst:insert('Paswd@9000', 'Paswd@9000',
        self.test_global_account_config:get_history_password_count())
    history_password_inst:insert('Paswd@90000', 'Paswd@90000',
        self.test_global_account_config:get_history_password_count())
    local history_password_list = history_password_inst:get()
    lu.assertEquals(#history_password_list, 2)
    lu.assertEquals(history_password_list[1].Password, 'Paswd@9000')
    lu.assertEquals(history_password_list[1].SequenceNumber, 2)
    -- 恢复操作
    self.test_global_account_config:set_history_password_count(0)
    history_password_inst:delete()
end

--- 当最大历史密码数为1，用户2插入两次历史密码时，数据库中该用户仅有一条密码
function TestAccount:test_when_count_is_1_account_insert_history_password_should_have_only_one_password()
    local history_password_inst = history_password.new(self.db, 2)
    self.test_global_account_config:set_history_password_count(1)
    history_password_inst:insert('Paswd@9000', 'Paswd@9000',
        self.test_global_account_config:get_history_password_count())
    history_password_inst:insert('Paswd@90000', 'Paswd@90000',
        self.test_global_account_config:get_history_password_count())
    local history_password_list = history_password_inst:get()
    lu.assertEquals(#history_password_list, 1)
    lu.assertEquals(history_password_list[1].Password, 'Paswd@90000')
    lu.assertEquals(history_password_list[1].SequenceNumber, 1)
    -- 恢复操作
    self.test_global_account_config:set_history_password_count(0)
    history_password_inst:delete()
end

--- 当密码不在历史密码表中，校验历史密码应该成功
function TestAccount:test_when_password_not_in_history_password_list_should_check_success()
    local history_password_inst = history_password.new(self.db, 2)
    self.test_global_account_config:set_history_password_count(1)
    local pass_1 = manager_account:crypt_password_by_random_salt('Paswd@9000')
    local pass_2 = manager_account:crypt_password_by_random_salt('Paswd@90000')
    history_password_inst:insert(pass_1, pass_1, self.test_global_account_config:get_history_password_count())
    history_password_inst:insert(pass_2, pass_2, self.test_global_account_config:get_history_password_count())
    local result = history_password_inst:check('Paswd@9000')
    lu.assertEquals(result, true)
    -- 恢复操作
    self.test_global_account_config:set_history_password_count(0)
    history_password_inst:delete()
end

--- 当密码在历史密码表中，校验历史密码应该失败
function TestAccount:test_when_passwords_in_history_password_list_should_check_fail()
    local history_password_inst = history_password.new(self.db, 2)
    self.test_global_account_config:set_history_password_count(2)
    local pass_1 = manager_account:crypt_password_by_random_salt('Paswd@9000')
    local pass_2 = manager_account:crypt_password_by_random_salt('Paswd@90000')
    history_password_inst:insert(pass_1, pass_1, self.test_global_account_config:get_history_password_count())
    history_password_inst:insert(pass_2, pass_2, self.test_global_account_config:get_history_password_count())
    local result = history_password_inst:check('Paswd@9000')
    lu.assertEquals(result, false)
    -- 恢复操作
    self.test_global_account_config:set_history_password_count(0)
    history_password_inst:delete()
end

--- 设置历史密码次数为5，修改6次密码成功
function TestAccount:test_when_history_password_count_5_set_passwords_6_should_check_success()
    local history_password_inst = history_password.new(self.db, 2)
    self.test_global_account_config:set_history_password_count(5)
    local pass_1 = manager_account:crypt_password_by_random_salt('Paswd@9000')
    local pass_2 = manager_account:crypt_password_by_random_salt('Paswd@9001')
    local pass_3 = manager_account:crypt_password_by_random_salt('Paswd@9002')
    local pass_4 = manager_account:crypt_password_by_random_salt('Paswd@9003')
    local pass_5 = manager_account:crypt_password_by_random_salt('Paswd@9004')
    local pass_6 = manager_account:crypt_password_by_random_salt('Paswd@9005')

    history_password_inst:insert(pass_1, pass_1, self.test_global_account_config:get_history_password_count())
    history_password_inst:insert(pass_2, pass_2, self.test_global_account_config:get_history_password_count())
    history_password_inst:insert(pass_3, pass_3, self.test_global_account_config:get_history_password_count())
    history_password_inst:insert(pass_4, pass_4, self.test_global_account_config:get_history_password_count())
    history_password_inst:insert(pass_5, pass_5, self.test_global_account_config:get_history_password_count())
    history_password_inst:insert(pass_6, pass_6, self.test_global_account_config:get_history_password_count())

    local result = history_password_inst:check('Paswd@9007')
    lu.assertEquals(result, true)
    -- 恢复操作
    self.test_global_account_config:set_history_password_count(0)
    history_password_inst:delete()
end

--- 当设置密码在历史密码中，应该设置失败
function TestAccount:test_when_set_password_in_history_password_should_set_fail()
    local account_id = 4
    local account_info = {
        ['id'] = account_id,
        ['name'] = "test4",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_service:new_account(self.ctx, account_info, false)
    self.test_account_service:set_history_password_count(2)
    self.test_account_collection:set_account_password(self.ctx, 2, account_id, "Paswd@9002")
    lu.assertErrorMsgContains(custom_msg.InvalidPasswordSameWithHistoryMessage.Name, function()
        self.test_account_collection:set_account_password(self.ctx, 2, account_id, "Paswd@9001")
    end)
    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, account_id)
    self.test_account_service:set_history_password_count(0)
end

--- 当设置历史密码数不在0-5之间，应该设置失败
function TestAccount:test_when_set_history_password_out_range_should_set_fail()
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_account_service:set_history_password_count(-1)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_account_service:set_history_password_count(6)
    end)
    self.test_account_service:set_history_password_count(0)
    lu.assertEquals(self.test_global_account_config:get_history_password_count(), 0)
end

--- 当设置历史密码数为5，连续设置5个不同密码应成功
function TestAccount:test_when_set_history_password_0_to_5_should_change_diff_password_success()
    local account_id = 4
    local account_info = {
        ['id'] = account_id,
        ['name'] = "test4",
        ['password'] = "Paswd@9000",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_service:new_account(self.ctx, account_info, false)
    self.test_account_service:set_history_password_count(5)
    local account
    for i = 1, 5 do
        self.test_account_collection:set_account_password(self.ctx, 2, account_id, "Paswd@900" .. i)
    end
    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, account_id)
    self.test_account_service:set_history_password_count(0)
end

-- 当设置历史密码数从2变为1，应将最老的记录删除掉，使用旧密码可修改成功
function TestAccount:test_when_set_history_password_2_to_1_should_change_same_password_success()
    local account_id = 4
    local account_info = {
        ['id'] = account_id,
        ['name'] = "test4",
        ['password'] = "Paswd@9000",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_service:new_account(self.ctx, account_info, false)
    self.test_account_service:set_history_password_count(2)
    self.test_account_collection:set_account_password(self.ctx, 2, account_id, "Paswd@9001")

    -- 设置回1后应将最老的历史记录清理掉，旧密码可用
    self.test_account_service:set_history_password_count(1)
    self.test_account_collection:set_account_password(self.ctx, 2, account_id, "Paswd@9000")
    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, account_id)
    self.test_account_service:set_history_password_count(0)
end

-- 关闭历史密码校验，修改一样的密码，能修改成功
function TestAccount:test_when_close_history_password_check_should_change_same_password_success()
    local account_id = 4
    local account_info = {
        ['id'] = account_id,
        ['name'] = "test4",
        ['password'] = "Paswd@9000",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_service:new_account(self.ctx, account_info, false)
    self.test_account_service:set_history_password_count(0)
    for _ = 1, 6 do
        self.test_account_collection:set_account_password(self.ctx, 2, account_id, "Paswd@9000")
    end
    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, account_id)
    self.test_account_service:set_history_password_count(0)
end

--- 当开启历史密码校验, 删除用户后，使用同样的id和密码创建用户应该创建成功
function TestAccount:test_when_delete_account_use_same_id_and_password_should_new_account_success()
    local account_id = 4
    self.test_account_service:set_history_password_count(1)
    local account_info = {
        ['id'] = account_id,
        ['name'] = "test4",
        ['password'] = "Paswd@9000",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    for _ = 1, 3 do
        self.test_account_service:new_account(self.ctx, account_info, false)
        self.test_account_collection:delete_account(self.ctx, account_id)
    end
    -- 恢复环境
    self.test_account_service:set_history_password_count(0)
end

--- 当创建新用户ID为3时，当历史密码表中已存在ID为3的脏数据，应先删除脏数据，再插入
function TestAccount:test_when_new_account_and_history_password_db_have_dirty_data_should_clear_it()

end

--- 当历史密码表中有SequenceNumber不为自增的脏数据，应不会导致后续插入异常及检查异常
function TestAccount:test_when_history_password_db_have_dirty_data_should_not_result_in_error()

end
