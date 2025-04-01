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
end
