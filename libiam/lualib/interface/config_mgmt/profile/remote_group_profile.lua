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
-- Description: 配置导入导出时远程控制组相关项

local custom_msg = require 'messages.custom'
local iam_utils = require 'utils'
local account_utils = require 'infrastructure.account_utils'
local iam_enum = require 'class.types.types'
local log = require 'mc.logging'

local RemoteGroupProfile = {}

RemoteGroupProfile.create_remote_group_collection = {}

local function get_group_log_id(self, id)
    local remote_group = self.m_remote_group_collection.m_db_remote_group_collection[id]
    if not remote_group then
        error(custom_msg.InvalidValue('Id', id))
    end
    return remote_group:get_group_log_id()
end

function RemoteGroupProfile.set_remote_group_id(self, _, group_id)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        RemoteGroupProfile.add_new_remote_group_prop(group_id, "Id", group_id)
    end
end

function RemoteGroupProfile.get_remote_group_id(self, group_id)
    local id = self.m_remote_group_id_collection[group_id]
    if not id or not self.m_remote_group_collection.m_db_remote_group_collection[id] then
        return nil
    end
    return group_id
end

function RemoteGroupProfile.set_remote_group_sid(self, ctx, group_id, value)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        RemoteGroupProfile.add_new_remote_group_prop(group_id, "SID", value)
        ctx.operation_log.operation = 'SkipLog'
        return
    end
    local group_log_id = get_group_log_id(self, id)
    ctx.operation_log.params = { id = group_log_id }
    self.m_remote_group_collection:set_remote_group_sid(id, value)
    self.m_remote_group_collection.m_remote_group_changed:emit(id, 'SID', value)
end

function RemoteGroupProfile.get_remote_group_sid(self, group_id)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        return nil
    end
    return self.m_remote_group_collection:get_remote_group_sid(id)
end

function RemoteGroupProfile.set_remote_group_name(self, ctx, group_id, value)
    local id = self.m_remote_group_id_collection[group_id]
    if not id and value ~= "" then
        RemoteGroupProfile.add_new_remote_group_prop(group_id, "Name", value)
        ctx.operation_log.operation = 'SkipLog'
    elseif id and value == "" then
        --del
        ctx.operation_log.operation = 'DeleteRemoteGroup'
        ctx.operation_log.params.group_id = group_id
        self.m_remote_group_collection:delete_remote_group(ctx, group_id)
        self.m_remote_group_id_collection[group_id] = nil
    elseif not id and value == "" then
        ctx.operation_log.operation = 'SkipLog'
        return
    else
        local group_log_id = get_group_log_id(self, id)
        ctx.operation_log.params = { id = group_log_id, name = value }
        self.m_remote_group_collection:set_remote_group_name(id, value)
        self.m_remote_group_collection.m_remote_group_changed:emit(id, 'Name', value)
    end
end

function RemoteGroupProfile.get_remote_group_name(self, group_id)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        return nil
    end
    return self.m_remote_group_collection:get_remote_group_name(id)
end

function RemoteGroupProfile.set_remote_group_role_id(self, ctx, group_id, value)
    local id = self.m_remote_group_id_collection[group_id]
    local role_id = iam_enum.RoleType[value]:value()
    if not id then
        RemoteGroupProfile.add_new_remote_group_prop(group_id, "UserRoleId", role_id)
        ctx.operation_log.operation = 'SkipLog'
        return
    end
    local group_log_id = get_group_log_id(self, id)
    ctx.operation_log.params.id = group_log_id
    ctx.operation_log.params.role_name = value
    self.m_remote_group_collection:set_remote_group_role_id(id, role_id)
    self.m_remote_group_collection:set_remote_group_privilege(id, role_id)
    self.m_remote_group_collection.m_remote_group_changed:emit(id, 'UserRoleId', role_id)
end

function RemoteGroupProfile.get_remote_group_role_id(self, group_id)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        return nil
    end
    local role_id = self.m_remote_group_collection:get_role_id(id)
    return tostring(iam_enum.RoleType.new(role_id))
end

function RemoteGroupProfile.set_remote_group_folder(self, ctx, group_id, value)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        RemoteGroupProfile.add_new_remote_group_prop(group_id, "Folder", value)
        ctx.operation_log.operation = 'SkipLog'
        return
    end
    local group_log_id = get_group_log_id(self, id)
    ctx.operation_log.params = { id = group_log_id, folder = value }
    if value == '' then
        ctx.operation_log.result = 'clear'
    end
    self.m_remote_group_collection:set_remote_group_folder(id, value)
    self.m_remote_group_collection.m_remote_group_changed:emit(id, 'Folder', value)
end

function RemoteGroupProfile.get_remote_group_folder(self, group_id)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        return nil
    end
    return self.m_remote_group_collection:get_remote_group_folder(id)
end

function RemoteGroupProfile.set_remote_group_permit_rule_ids(self, ctx, group_id, value)
    local id = self.m_remote_group_id_collection[group_id]
    account_utils.check_login_rule_ids(value)
    if not id then
        RemoteGroupProfile.add_new_remote_group_prop(group_id, "PermitRuleIds", value)
        ctx.operation_log.operation = 'SkipLog'
        return
    end
    local group_log_id = get_group_log_id(self, id)
    ctx.operation_log.params = { username = group_log_id, rule = table.concat(value, " ") }
    local login_rule_ids = account_utils.covert_login_rule_ids_str_to_num(value)
    local old_permit_rule_num = self.m_remote_group_collection:get_remote_group_permit_rule_ids(id)
    self.m_remote_group_collection:set_remote_group_permit_rule_ids(id, login_rule_ids)
    local new_permit_rule_num = self.m_remote_group_collection:get_remote_group_permit_rule_ids(id)
    local change = account_utils.get_login_interface_or_rule_ids_change(old_permit_rule_num,
        new_permit_rule_num, account_utils.covert_num_to_login_rule_ids_str)
    if not change then
        ctx.operation_log.operation = 'SkipLog'
    end
    ctx.operation_log.params.change = change
    self.m_remote_group_collection.m_remote_group_changed:emit(id, 'PermitRuleIds', value)
end

function RemoteGroupProfile.get_remote_group_permit_rule_ids(self, group_id)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        return nil
    end
    local rule_ids = self.m_remote_group_collection:get_remote_group_permit_rule_ids(id)
    return account_utils.covert_num_to_login_rule_ids_str(rule_ids)
end

function RemoteGroupProfile.set_remote_group_login_interface(self, ctx, group_id, value)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        RemoteGroupProfile.add_new_remote_group_prop(group_id, "LoginInterface", value)
        ctx.operation_log.operation = 'SkipLog'
        return
    end
    local group_log_id = get_group_log_id(self, id)
    ctx.operation_log.params = { username = group_log_id, interface = table.concat(value, " ") }
    local group_type = self.m_remote_group_collection:get_remote_group_type(id)
    if not iam_utils.check_remote_group_interface_info(group_type, value) then
        error(custom_msg.PropertyItemNotInList('%LoginInterface:' .. table.concat(value, " "), '%LoginInterface'))
    end
    local login_interface_num = iam_utils.cover_interface_str_to_num(value)
    local old_interface_num = self.m_remote_group_collection:get_remote_group_login_interface(id)
    self.m_remote_group_collection:set_remote_group_login_interface(id, login_interface_num)
    local new_interface_num = self.m_remote_group_collection:get_remote_group_login_interface(id)
    local change = account_utils.get_login_interface_or_rule_ids_change(old_interface_num,
        new_interface_num, account_utils.convert_num_to_interface_str)
    if not change then
        ctx.operation_log.operation = 'SkipLog'
    end
    ctx.operation_log.params.change = change
    self.m_remote_group_collection.m_remote_group_changed:emit(id, 'LoginInterface', value)
end

function RemoteGroupProfile.get_remote_group_login_interface(self, group_id)
    local id = self.m_remote_group_id_collection[group_id]
    if not id then
        return nil
    end
    local login_interface_num =  self.m_remote_group_collection:get_remote_group_login_interface(id)
    return account_utils.convert_num_to_interface_str(login_interface_num, true)
end

function RemoteGroupProfile.add_new_remote_group_prop(group_id, prop, value)
    local group = RemoteGroupProfile.create_remote_group_collection[group_id]
    if group then
        group[prop] = value
    else
        RemoteGroupProfile.create_remote_group_collection[group_id] = {}
        RemoteGroupProfile.create_remote_group_collection[group_id][prop] = value
    end
end

function RemoteGroupProfile.create_remote_groups(self, ctx)
    for group_id, group in pairs(RemoteGroupProfile.create_remote_group_collection) do
        if not group.Name then
            goto continue
        end
        local _, controller_id, inner_id = string.match(group_id, "(%w+)(%d+)_(%d+)")
        local ok, err = pcall(function()
            self.m_remote_group_collection:new_remote_group(ctx, iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value(),
                tonumber(controller_id), tonumber(inner_id), group.Name, group.Folder or "", group.SID or "",
                group.UserRoleId or 2, group.PermitRuleIds or {}, group.LoginInterface or {})
        end)
        if not ok then
            log:error("Add RemoteGroup %s failed, err = %s", group.Name, err.name)
            log:operation(ctx:get_initiator(), 'iam', 'Add RemoteGroup %s failed', group.Name)
        else
            log:operation(ctx:get_initiator(), 'iam', 'Add RemoteGroup(name:%s, login interface:%s, ' ..
                'userrole:%s)successfully', group.Name, table.concat(group.LoginInterface or {}, " "),
                tostring(iam_enum.RoleType.new(group.UserRoleId or 2)))
        end
        ::continue::
    end
    RemoteGroupProfile.create_remote_group_collection = {}
end

return RemoteGroupProfile