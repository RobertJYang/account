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
local base_msg = require 'messages.base'


function TestAccount:test_role_init()
    lu.assertNotIsNil(self.test_role_collection)
    lu.assertEquals(#self.test_role_collection.m_role_collection, 8)
end

function TestAccount:test_get_role_by_id()
    -- 获取管理员权限，验证用户管理使能
    local data = self.test_role_collection:get_role_data_by_id(4)
    lu.assertEquals(data.UserMgmt, true)
    -- 获取操作员权限，验证用户管理禁止
    data = self.test_role_collection:get_role_data_by_id(3)
    lu.assertEquals(data.RoleName, 'Operator')
    lu.assertEquals(data.UserMgmt, false)
    data = self.test_role_collection:get_role_data_by_id(0)
    lu.assertEquals(data.RoleName, 'NoAccess')
end

function TestAccount:test_get_role_string()
    lu.assertEquals(self.test_role_collection:role_to_string_table(4), { 'Administrator' })
    lu.assertEquals(self.test_role_collection:role_to_string_table({ 4, 3 }), { 'Administrator', 'Operator' })
end

function TestAccount:test_set_role_privilege()
    -- 设置自定义用户1的KVMMgmt权限为true
    self.test_role_collection:set_role_privilege(self.ctx, 5, enum.PrivilegeType.KVMMgmt, true)
    self.test_role_collection:set_role_privilege(self.ctx, 6, enum.PrivilegeType.PowerMgmt, true)
    local data = self.test_role_collection:get_role_data_by_id(5)
    local data1 = self.test_role_collection:get_role_data_by_id(6)
    lu.assertEquals(data.KVMMgmt, true)
    lu.assertEquals(data1.PowerMgmt, true)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_role_collection:set_role_privilege(self.ctx, 9, enum.PrivilegeType.KVMMgmt, true)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_role_collection:set_role_privilege(self.ctx, 5, 'UnknownPriv', true)
    end)
    lu.assertErrorMsgContains(base_msg.InsufficientPrivilegeMessage.Name, function()
        self.test_role_collection:set_role_privilege(self.ctx, 5, enum.PrivilegeType.UserMgmt, true)
    end)
    lu.assertErrorMsgContains(base_msg.InsufficientPrivilegeMessage.Name, function()
        self.test_role_collection:set_role_privilege(self.ctx, 4, enum.PrivilegeType.KVMMgmt, false)
    end)
end

function TestAccount:test_get_role_name_by_id()
    lu.assertEquals(self.test_role_collection:get_role_name_by_id(4), 'Administrator')
    lu.assertEquals(self.test_role_collection:get_role_name_by_id(2), 'CommonUser')
    lu.assertEquals(self.test_role_collection:get_role_name_by_id(0), 'NoAccess')
    lu.assertEquals(self.test_role_collection:get_role_name_by_id(5), 'CustomRole1')
    lu.assertIsTrue(self.test_role_collection:get_role_name_by_id(9) == nil)
end

function TestAccount:test_get_role_data_by_name()
    lu.assertNotIsNil(self.test_role_collection:get_role_data_by_name('Administrator'))
    lu.assertNotIsNil(self.test_role_collection:get_role_data_by_name('CommonUser'))
    lu.assertIsTrue(self.test_role_collection:get_role_data_by_name('CustomRole5') == nil)
end

function TestAccount:test_get_role_by_name()
    local id, role = self.test_role_collection:get_role_by_name('Administrator')
    lu.assertEquals(id, 4)
    lu.assertNotIsNil(role)
    id, role = self.test_role_collection:get_role_by_name('CommonUser')
    lu.assertEquals(id, 2)
    lu.assertNotIsNil(role)
    id, role = self.test_role_collection:get_role_by_name('CustomRole5')
    lu.assertIsTrue(id == nil and role == nil)
end

function TestAccount:test_get_role_privilege()
    lu.assertIsTrue(self.test_role_collection:get_role_privilege(4, 'UserMgmt'))
    lu.assertIsFalse(self.test_role_collection:get_role_privilege(2, 'UserMgmt'))
    lu.assertIsTrue(self.test_role_collection:get_role_privilege(9, 'ReadOnly') == nil)
end

function TestAccount:test_new_role()
    -- 未开启ExtendedCustomRoleEnabled无法新增
    lu.assertIsTrue(self.test_role_collection:get_extended_custom_role_enabled() == false)
    lu.assertErrorMsgContains(base_msg.InsufficientPrivilegeMessage.Name, function()
        self.test_role_collection:new_role(self.ctx, 9, {'ReadOnly', 'ConfigureSelf'}, {})
    end)
    self.test_role_collection:set_extended_custom_role_enabled(true)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_role_collection:new_role(self.ctx, 21, {'ReadOnly', 'ConfigureSelf'}, {})
    end)
    lu.assertErrorMsgContains(base_msg.PropertyMissingMessage.Name, function()
        self.test_role_collection:new_role(self.ctx, 9, {}, {})
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_role_collection:new_role(self.ctx, 21, {'ReadOnly', 'ConfigureSelf', 'UnknownPriv'}, {})
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_role_collection:new_role(self.ctx, 21, {'ReadOnly', 'ConfigureSelf'}, {'UnknownPriv'})
    end)
    self.test_role_collection:new_role(self.ctx, 9, {'ReadOnly', 'ConfigureSelf'}, {})
    lu.assertEquals(self.test_role_collection:get_role_name_by_id(9), 'CustomRole5')
    lu.assertErrorMsgContains(base_msg.ResourceAlreadyExistsMessage.Name, function()
        self.test_role_collection:new_role(self.ctx, 9, {'ReadOnly', 'ConfigureSelf'}, {})
    end)
    -- 恢复
    self.test_role_collection:set_extended_custom_role_enabled(false)
    self.test_role_collection:clear_extended_custom_role(self.ctx)
end

function TestAccount:test_delete_role()
    -- 未开启ExtendedCustomRoleEnabled无法删除
    lu.assertIsTrue(self.test_role_collection:get_extended_custom_role_enabled() == false)
    lu.assertErrorMsgContains(base_msg.InsufficientPrivilegeMessage.Name, function()
        self.test_role_collection:delete_role(self.ctx, 9)
    end)
    self.test_role_collection:set_extended_custom_role_enabled(true)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_role_collection:delete_role(self.ctx, 8)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_role_collection:delete_role(self.ctx, 9)
    end)
    -- 恢复
    self.test_role_collection:set_extended_custom_role_enabled(false)
end