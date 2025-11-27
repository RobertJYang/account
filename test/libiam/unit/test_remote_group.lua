-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local iam_enum = require 'class.types.types'
local iam_utils = require 'utils'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'


-- 测试增加、删除远程认证组
function TestIam:test_add_and_delete_remote_group_successful()
    local permit_rule_ids = {}
    local ldap_login_interface = {"Web", "SSH", "Redfish"}
    local krb_login_interface = {"Web", "Redfish"}

    -- 增加LDAP组
    local ldap_mdb_id, ldap_group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                                "Test", "aaa", "bbb", 2, permit_rule_ids, ldap_login_interface)
    -- 默认无认证组，自增ID为1
    lu.assertEquals(ldap_group_id, 1)
    lu.assertNotIsNil(self.test_remote_group_collection.m_db_remote_group_collection[ldap_group_id])
    local ldap_group = self.test_remote_group_collection.m_db_remote_group_collection[ldap_group_id]:get_group()
    lu.assertEquals(ldap_group.Name, "Test")
    lu.assertEquals(ldap_group.Folder, "aaa")
    lu.assertEquals(ldap_group.SID, "bbb")
    lu.assertEquals(ldap_group.UserRoleId, 2)
    lu.assertEquals(ldap_group.PermitRuleIdsDB, 0)
    lu.assertEquals(ldap_group.LoginInterfaceDB, 137) -- 10001001 对应十进制 137

    -- 指定创建该控制器内id为1的组，已存在组，预期失败
    lu.assertErrorMsgContains(base_msg.ResourceAlreadyExistsMessage.Name, function()
        self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 1, "Test", "aaa", "bbb", 2, {}, {})
    end)

    -- 增加Kerberos组
    local krb_mdb_id,krb_group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 1, 1, 0,
                                            "Test", "aaa", "bbb", 2, permit_rule_ids, krb_login_interface)
    -- 已有一个组，自增ID为2
    lu.assertEquals(krb_group_id, 2)
    lu.assertNotIsNil(self.test_remote_group_collection.m_db_remote_group_collection[krb_group_id])
    local krb_group = self.test_remote_group_collection.m_db_remote_group_collection[krb_group_id]:get_group()
    lu.assertEquals(krb_group.Name, "Test")
    lu.assertEquals(krb_group.Folder, "aaa")
    lu.assertEquals(krb_group.SID, "bbb")
    lu.assertEquals(krb_group.UserRoleId, 2)
    lu.assertEquals(krb_group.PermitRuleIdsDB, 0)
    lu.assertEquals(krb_group.LoginInterfaceDB, 129) -- 10000001 对应十进制 9 
    -- 删除远程认证组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
    lu.assertIsNil(self.test_remote_group_collection.m_db_remote_group_collection[ldap_group_id])
    self.test_remote_group_collection:delete_remote_group(self.ctx, krb_mdb_id)
    lu.assertIsNil(self.test_remote_group_collection.m_db_remote_group_collection[krb_group_id])
end

-- 测试增加组时传入非法的inner_id
function TestIam:test_add_remote_group_with_invalid_inner_id()
    -- 增加LDAP组
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 6, "Test", "aaa", "bbb", 2, {}, {})
    end)
end

-- 测试修改组名为不可见字符
function TestIam:test_modify_remote_group_name_invalid_charactor()
    -- 增加LDAP组
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 1, "\x00", "aaa", "bbb", 2, {}, {})
    end)
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 1, "\x1B", "aaa", "bbb", 2, {}, {})
    end)
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 1, "\x7F", "aaa", "bbb", 2, {}, {})
    end)
end

-- 测试一个域下新增6个ldap组
function TestIam:test_add_remote_group_exceeds_the_limit()
    for i = 1, 5 do
        self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0, "Test", "aaa", "bbb",
                                                           2, {}, {})
    end

    local groups, _ = self.test_remote_group_collection:get_remote_groups_in_controller(0, 1)
    -- 当前该域下应有5个组
    lu.assertEquals(#groups, 5)

    -- 该域下无法继续新增组
    lu.assertErrorMsgContains(custom_msg.PropertyMemberQtyExceedLimitMessage.Name, function()
        self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0, "Test", "aaa", "bbb",
                                                          2, {}, {})
    end)

    -- 清理用户组
    local ldap_mdb_id
    for i = 1, 5 do
        ldap_mdb_id = string.format('LDAP1_%s', i)
        self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
    end
end

-- 测试删除不存在的组
function TestIam:test_delete_invalid_remote_group()
    local unused_group_id = self.test_remote_group_collection:find_unused_group_id()
    local test_mdb_id = string.format('LDAP%s_1', unused_group_id)

    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        self.test_remote_group_collection:delete_remote_group(self.ctx, test_mdb_id)
    end)
end

-- 测试查找可用组id
function TestIam:test_get_unused_remote_group_id()
    for i = 1, 3 do
        self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0, "Test", "aaa", "bbb",
                                                           2, {}, {})
    end

    -- 删除id为2，组内序号为2的LDAP组，此时id 2空闲
    self.test_remote_group_collection:delete_remote_group(self.ctx, 'LDAP1_2')

    -- 期望找到的空闲id为2
    lu.assertEquals(self.test_remote_group_collection:find_unused_group_id(), 2)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, 'LDAP1_1')
    self.test_remote_group_collection:delete_remote_group(self.ctx, 'LDAP1_3')
end

-- 测试成功设置SID
function TestIam:test_set_remote_group_sid_success()
    -- 增加LDAP组
    local ldap_mdb_id, ldap_group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                                "Test", "aaa", "", 2, {}, {})
    -- 增加Kerberos组
    local krb_mdb_id, krb_group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 1, 1, 0,
                                                "Test", "aaa", "bbb", 2, {}, {})
    local ldap_group = self.test_remote_group_collection.m_db_remote_group_collection[ldap_group_id]
    local krb_group = self.test_remote_group_collection.m_db_remote_group_collection[krb_group_id]

    local sid = "test"
    -- LDAP组设置SID无效
    ldap_group:set_remote_group_sid(sid)
    lu.assertEquals(ldap_group:get_remote_group_sid(), '')

    krb_group:set_remote_group_sid(sid)
    lu.assertEquals(krb_group:get_remote_group_sid(), sid)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
    self.test_remote_group_collection:delete_remote_group(self.ctx, krb_mdb_id)
end

-- 测试传入SID为空或者空字符串
function TestIam:test_set_remote_group_sid_is_null()
    -- 增加Kerberos组
    local krb_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 1, 1, 0,
                                        "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local SID = nil
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        group:set_remote_group_sid(SID)
    end)

    SID = ''
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        group:set_remote_group_sid(SID)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, krb_mdb_id)
end

-- 测试传入SID包含空格
function TestIam:test_set_remote_group_sid_include_space()
    -- 增加Kerberos组
    local krb_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 1, 1, 0,
                                        "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local SID = "test a"
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        group:set_remote_group_sid(SID)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, krb_mdb_id)
end

-- 测试传入SID包含不可见字符
function TestIam:test_set_remote_group_sid_include_invisible_charactor()
    -- 增加Kerberos组
    local krb_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 1, 1, 0,
                                        "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local SID = "\x00"
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        group:set_remote_group_sid(SID)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, krb_mdb_id)
end

-- 测试成功设置Name
function TestIam:test_set_remote_group_name_success()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local name = "test"
    group:set_remote_group_name(name)
    lu.assertEquals(group:get_remote_group_name(), name)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试Name超长
function TestIam:test_set_remote_group_name_too_long()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    -- 256字符
    local name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ..
                 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ..
                 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ..
                 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ..
                 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    lu.assertErrorMsgContains(custom_msg.PropertyValueExceedsMaxLengthMessage.Name, function()
        group:set_remote_group_name(name)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试Name首尾包含空格
function TestIam:test_set_remote_group_name_include_space()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local name = " test"
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        group:set_remote_group_name(name)
    end)

    local name = "test "
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        group:set_remote_group_name(name)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试成功设置UserRoleId
function TestIam:test_set_remote_group_role_id_success()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local role_id = iam_enum.RoleType.Administrator:value()
    group:set_remote_group_role_id(role_id)
    lu.assertEquals(group:get_role_id(), role_id)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试UserRoleId越界
function TestIam:test_set_remote_group_role_id_invalid()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    -- role_id范围2~8，设置9越界
    local role_id = 9
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        group:set_remote_group_role_id(role_id)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试成功设置privilege
function TestIam:test_set_remote_group_privilege_success()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local role_id = iam_enum.RoleType.Administrator:value()
    group:set_remote_group_privilege(role_id)
    lu.assertEquals(group:get_remote_group_privilege(), role_id)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试privilege越界
function TestIam:test_set_remote_group_privilege_invalid()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    -- role_id范围2~8，设置9越界
    local role_id = 9
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        group:set_remote_group_privilege(role_id)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试成功设置Folder
function TestIam:test_set_remote_group_folder_success()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local folder = "test"
    group:set_remote_group_folder(folder)
    lu.assertEquals(group:get_remote_group_folder(), folder)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试Folder超长
function TestIam:test_set_remote_group_folder_too_long()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    -- 256字符
    local folder = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ..
                 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ..
                 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ..
                 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" ..
                 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    lu.assertErrorMsgContains(custom_msg.PropertyValueExceedsMaxLengthMessage.Name, function()
        group:set_remote_group_folder(folder)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试Folder首尾包含空格
function TestIam:test_set_remote_group_folder_include_space()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local folder = " test"
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        group:set_remote_group_folder(folder)
    end)

    local folder = "test "
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        group:set_remote_group_folder(folder)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试Folder首尾包含空格
function TestIam:test_set_remote_group_folder_include_invisible_charactor()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local folder = "\x00"
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        group:set_remote_group_folder(folder)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试成功设置PermitRuleIds
function TestIam:test_set_remote_group_permit_rule_ids_success()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    local ids = 7
    group:set_remote_group_permit_rule_ids(ids)
    lu.assertEquals(group:get_remote_group_permit_rule_ids(), ids)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试UserRoleId越界
function TestIam:test_set_remote_group_permit_rule_ids_invalid()
    -- 增加LDAP组
    local ldap_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    -- rule_ids范围0~7，设置8越界
    local ids = 8
    lu.assertErrorMsgContains(base_msg.InternalErrorMessage.Name, function()
        group:set_remote_group_permit_rule_ids(ids)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

-- 测试成功设置LoginInterface
function TestIam:test_set_remote_group_login_interface_success()
    -- 增加LDAP组
    local ldap_mdb_id, ldap_group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                                "Test", "aaa", "bbb", 2, {}, {})
    -- 增加Kerberos组
    local krb_mdb_id, krb_group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 1, 1, 0,
                                                "Test", "aaa", "bbb", 2, {}, {})
    local ldap_group = self.test_remote_group_collection.m_db_remote_group_collection[ldap_group_id]
    local krb_group = self.test_remote_group_collection.m_db_remote_group_collection[krb_group_id]

    local ldap_interface = 137 -- LDAP最大允许10001001 = 137
    local krb_interface = 129    -- KRB最大允许10000001 = 129
    ldap_group:set_remote_group_login_interface(ldap_interface)
    lu.assertEquals(ldap_group:get_remote_group_login_interface(), ldap_interface)
    krb_group:set_remote_group_login_interface(krb_interface)
    lu.assertEquals(krb_group:get_remote_group_login_interface(), krb_interface)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
    self.test_remote_group_collection:delete_remote_group(self.ctx, krb_mdb_id)
end

function TestIam:test_set_remote_group_krb_login_interface_invalid()
    -- 增加Kerberos组
    local krb_mdb_id, group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 1, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    -- 设置krb组不允许的接口Redfish
    local interface = {"SSH"}
    local interface_num = iam_utils.cover_interface_str_to_num(interface)

    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        group:set_remote_group_login_interface(interface_num)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, krb_mdb_id)
end

function TestIam:test_set_remote_group_ldap_login_interface_invalid()
    -- 增加LDAP组
    local ldap_mdb_id,group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 2, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]

    -- 设置krb组不允许的接口IPMI
    local interface = {"IPMI"}
    local interface_num = iam_utils.cover_interface_str_to_num(interface)

    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        group:set_remote_group_login_interface(interface_num)
    end)

    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end

function TestIam:test_set_remote_gorups_allowed_login_interfaces_success()
    -- 远程用户组支持接口:Web:1, SSH:8, Redfish:128
    self.test_remote_groups_config:set_allowed_login_interfaces(1)
    self.test_remote_groups_config:set_allowed_login_interfaces(8)
    self.test_remote_groups_config:set_allowed_login_interfaces(128)
    self.test_remote_groups_config:set_allowed_login_interfaces(9)
    self.test_remote_groups_config:set_allowed_login_interfaces(129)
    self.test_remote_groups_config:set_allowed_login_interfaces(136)
    self.test_remote_groups_config:set_allowed_login_interfaces(137)
end

function TestIam:test_set_remote_gorups_allowed_login_interfaces_invalid()
    -- 设置allowedLoginInterface为不支持的登录接口(0:全部关闭)
    lu.assertErrorMsgContains(custom_msg.ArrayPropertyInvalidItemMessage.Name, function()
        self.test_remote_groups_config:set_allowed_login_interfaces(0)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_remote_groups_config:set_allowed_login_interfaces(4)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_remote_groups_config:set_allowed_login_interfaces(5)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_remote_groups_config:set_allowed_login_interfaces(111)
    end)
end

function TestIam:test_update_remote_group_privilege()
    -- 增加LDAP组
    local ldap_mdb_id,group_id = self.test_remote_group_collection:new_remote_group(self.ctx, 0, 1, 0,
                                            "Test", "aaa", "bbb", 4, {}, {})
    local group = self.test_remote_group_collection.m_db_remote_group_collection[group_id]
    -- 更新role_id 4 -> 2
    self.test_remote_group_collection:update_privilege(4)
    lu.assertEquals(group:get_role_id(), 2)
    -- 清理用户组
    self.test_remote_group_collection:delete_remote_group(self.ctx, ldap_mdb_id)
end