-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 定制化操作时Ldap相关项

local account_utils = require 'infrastructure.account_utils'
local iam_enum = require 'class.types.types'
local VALUE_BOOLEN_MAP = {
    [0] = false,
    [1] = true
}

local BOOLEN_VALUE_MAP = {
    [true] = 1,
    [false] = 0
}

local INVALID_GROUP_ID<const> = -1

local LDAPCustomization = {}

LDAPCustomization.remote_group_create_map = {}

------------- LDAP Config Beg ----------------
function LDAPCustomization.convert_ldap_enable(custom_settings)
    return VALUE_BOOLEN_MAP[custom_settings['BMCSet_LDAPEnable'].Value]
end

function LDAPCustomization.set_ldap_enable(self, ctx, value)
    self.m_ldap_config:set_ldap_enabled(value)
    self.m_ldap_config.m_ldap_config_changed:emit('Enabled', value)
end

function LDAPCustomization.get_ldap_enable(self)
    local enabled = self.m_ldap_config:get_ldap_enabled()
    return BOOLEN_VALUE_MAP[enabled]
end
------------- LDAP Config End ----------------

------------- LDAP Controller Config Beg ----------------
function LDAPCustomization.set_ldap_host_addr(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_hostaddr(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'HostAddr', value)
end

function LDAPCustomization.get_ldap_host_addr(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_hostaddr(controller_id)
end

function LDAPCustomization.set_ldap_user_domain(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_domain(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'UserDomain', value)
end

function LDAPCustomization.get_ldap_user_domain(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_domain(controller_id)
end

function LDAPCustomization.set_ldap_port(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_port(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'Port', value)
end

function LDAPCustomization.get_ldap_port(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_port(controller_id)
end

function LDAPCustomization.set_ldap_cert_status(self, ctx, controller_id, value)
    value = VALUE_BOOLEN_MAP[value]
    self.m_ldap_controller_collection:set_ldap_controller_cert_verify_enabled(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'CertVerifyEnabled', value)
end

function LDAPCustomization.get_ldap_cert_status(self, controller_id)
    return BOOLEN_VALUE_MAP[self.m_ldap_controller_collection:get_ldap_controller_cert_verify_enabled(controller_id)]
end
------------- LDAP Controller Config End ----------------

------------- LDAP Remote Group Config Beg ----------------
function LDAPCustomization.set_ldap_group_name(self, ctx, custom_id, value)
    local id = self.m_remote_group_map[custom_id]
    -- 当前导入id 初始化时不存在，定制化含有组名-添加
    if id == INVALID_GROUP_ID and value ~= "" then
        LDAPCustomization.add_new_remote_group_prop(custom_id, "Name", value)
    elseif id == INVALID_GROUP_ID and value == "" then
        return
    elseif id ~= INVALID_GROUP_ID and value == "" then
        local mdb_id = string.format("LDAP%d_%d", custom_id & 0xf, (custom_id >> 4) + 1)
        self.m_remote_group_collection:delete_remote_group(ctx, mdb_id)
        self.m_remote_group_map[custom_id] = INVALID_GROUP_ID
    else
        self.m_remote_group_collection:set_remote_group_name(id, value)
        self.m_remote_group_collection.m_remote_group_changed:emit(id, 'Name', value)
    end
end

function LDAPCustomization.get_ldap_group_name(self, group_id)
    if group_id == INVALID_GROUP_ID then
        return ""
    end
    return self.m_remote_group_collection:get_remote_group_name(group_id)
end

function LDAPCustomization.set_ldap_group_permit_rule_ids(self, ctx, custom_id, login_rule_ids)
    local id = self.m_remote_group_map[custom_id]
    local rule_ids_str = account_utils.covert_num_to_login_rule_ids_str(login_rule_ids)
    if id == INVALID_GROUP_ID then
        LDAPCustomization.add_new_remote_group_prop(custom_id, "PermitRuleIds", rule_ids_str)
        return
    end
    self.m_remote_group_collection:set_remote_group_permit_rule_ids(id, login_rule_ids)
    self.m_remote_group_collection.m_remote_group_changed:emit(id, 'PermitRuleIds', rule_ids_str)
end

function LDAPCustomization.get_ldap_group_permit_rule_ids(self, group_id)
    if group_id == INVALID_GROUP_ID then
        return 0
    end
    return self.m_remote_group_collection:get_remote_group_permit_rule_ids(group_id)
end


function LDAPCustomization.set_ldap_group_login_interface(self, ctx, custom_id, login_interface_ids)
    local id = self.m_remote_group_map[custom_id]
    local login_interface_str = {}
    if login_interface_ids ~= 0 then
        login_interface_str = {
            [1] = (login_interface_ids & 1) ~= 0 and 'Web' or nil,
            [2] = (login_interface_ids & 8) ~= 0 and 'SSH' or nil,
            [3] = (login_interface_ids & 128) ~= 0 and 'Redfish' or nil
        }
    end
    if id == INVALID_GROUP_ID then
        LDAPCustomization.add_new_remote_group_prop(custom_id, "LoginInterface", login_interface_str)
        return
    end
    self.m_remote_group_collection:set_remote_group_login_interface(id, login_interface_ids)
    self.m_remote_group_collection.m_remote_group_changed:emit(id, 'LoginInterface', login_interface_str)
end

function LDAPCustomization.get_ldap_group_login_interface(self, group_id)
    if group_id == INVALID_GROUP_ID then
        return 0
    end
    return self.m_remote_group_collection:get_remote_group_login_interface(group_id)
end


function LDAPCustomization.set_ldap_group_folder(self, ctx, custom_id, value)
    local id = self.m_remote_group_map[custom_id]
    if id == INVALID_GROUP_ID then
        LDAPCustomization.add_new_remote_group_prop(custom_id, "Folder", value)
        return
    end
    self.m_remote_group_collection:set_remote_group_folder(id, value)
    self.m_remote_group_collection.m_remote_group_changed:emit(id, 'Folder', value)
end

function LDAPCustomization.get_ldap_group_folder(self, group_id)
    if group_id == INVALID_GROUP_ID then
        return ""
    end
    return self.m_remote_group_collection:get_remote_group_folder(group_id)
end

function LDAPCustomization.set_ldap_group_user_role_id(self, ctx, custom_id, value)
    local id = self.m_remote_group_map[custom_id]
    if id == INVALID_GROUP_ID then
        LDAPCustomization.add_new_remote_group_prop(custom_id, "UserRoleId", value)
        return
    end
    value = value == 0 and 2 or value
    self.m_remote_group_collection:set_remote_group_role_id(id, value)
    self.m_remote_group_collection:set_remote_group_privilege(id, value)
    self.m_remote_group_collection.m_remote_group_changed:emit(id, 'UserRoleId', value)
end

function LDAPCustomization.get_ldap_group_user_role_id(self, group_id)
    if group_id == INVALID_GROUP_ID then
        return 0
    end
    return self.m_remote_group_collection:get_role_id(group_id)
end

function LDAPCustomization.add_new_remote_group_prop(custom_id, prop, value)
    local group = LDAPCustomization.remote_group_create_map[custom_id]
    if group then
        group[prop] = value
    else
        LDAPCustomization.remote_group_create_map[custom_id] = {}
        LDAPCustomization.remote_group_create_map[custom_id][prop] = value
    end
end

function LDAPCustomization.create_remote_groups(self, ctx)
    for custom_id, group in pairs(LDAPCustomization.remote_group_create_map) do
        if not group.Name then
            goto continue
        end
        local group_id = (custom_id >> 4) + 1
        local controller_id = custom_id & 0xf
        self.m_remote_group_collection:new_remote_group(ctx, iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value(),
            controller_id, group_id, group.Name, group.Folder or "", "",
            group.UserRoleId or 2, group.PermitRuleIds or {}, group.LoginInterface or {})
        ::continue::
    end
    LDAPCustomization.remote_group_create_map = {}
end

return LDAPCustomization