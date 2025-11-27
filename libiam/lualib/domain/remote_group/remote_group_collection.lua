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
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local signal = require 'mc.signal'
local log = require 'mc.logging'
local remote_group_manager = require 'domain.remote_group.remote_group_manager'
local account_utils = require 'infrastructure.account_utils'
local iam_utils = require 'utils'
local iam_enum = require 'class.types.types'
local remote_group_config = require 'domain.remote_group.remote_group_config'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'

local function check_is_group_data_complete(group)
    if group.GroupType == nil then
        return false
    end
    if group.ControllerId == nil then
        return false
    end
    if group.ControllerInnerId == nil then
        return false
    end
    if group.Name == nil then
        return false
    end
    if group.UserRoleId == nil then
        return false
    end
    if group.PermitRuleIdsDB == nil then
        return false
    end
    if group.LoginInterfaceDB == nil then
        return false
    end

    return true
end

local RemoteGroupCollection = class()
function RemoteGroupCollection:ctor(db)
    self.db = db

    local stmt_groups = db:select(db.RemoteGroup)
    local m_db_remote_group_collection = stmt_groups:fold(function(group, acc)
        if not check_is_group_data_complete(group) then
            log:error("remote group data destoryed, now do delete remote group(%d)", group.Id)
            group:delete()
            return acc
        end
        acc[group.Id] = remote_group_manager.new(group)
        return acc
    end, {})
    self.m_db_remote_group_collection = m_db_remote_group_collection
    self.m_table_remote_group = stmt_groups.table
    self.m_remote_group_added = signal.new()
    self.m_remote_group_removed = signal.new()
    self.m_remote_group_changed = signal.new()
    self.m_remote_group_security_changed = signal.new()
end

function RemoteGroupCollection:get_remote_groups_in_controller(group_type, server_id)
    local len = 0
    local groups = {}

    for i = 1, remote_group_config.MAX_GROUP_COUNT do
        local group = self.m_db_remote_group_collection[i]
        if group and group:get_remote_group_type() == group_type and
            group:get_remote_group_controller_id() == server_id then
            groups[group:get_group().ControllerInnerId] = group
            len = len + 1
        end
    end

    return groups, len
end

function RemoteGroupCollection:find_unused_group_id()
    -- 此处可以直接使用self.m_db_remote_group_collection，前序调用已经保障了控制器下有空余的位置可以添加组
    -- 此处若存在某个组为空发生了长度截断，会返回当前长度+1，也就是被截断的索引id，是OK的
    for i = 1, #self.m_db_remote_group_collection do
        if self.m_db_remote_group_collection[i] == nil then
            return i
        end
    end
    return #self.m_db_remote_group_collection + 1
end

function RemoteGroupCollection:find_unused_controller_inner_id(groups)
    for i = 1, remote_group_config.MAX_GROUP_CNT_IN_CONTROLLER do
        if groups[i] == nil then
            return i
        end
    end
    error(base_msg.PropertyMemberQtyExceedLimit('RemoteGroup'))
end

local function check_controller_type_and_id(group_type, controller_id)
    if group_type == iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value() then
        -- LDAP域控制器共有6个
        if controller_id <= 0 or controller_id > remote_group_config.MAX_LDAP_COUNT then
            return false
        end
    elseif group_type == iam_enum.RemoteGroupType.GROUP_TYPE_KERBEROS:value() then
        -- Kerberos域控制器只有1个
        if controller_id ~= remote_group_config.MAX_Kerberos_COUNT then
            return false
        end
    else
        return false
    end

    return true
end

-- 设置远程组属性
function RemoteGroupCollection:setup_group_properties(group_type, group_in_server, group_name, SID, folder, role_id,
        permit_rule_ids, login_interface)
    group_in_server:set_remote_group_name(group_name)
    group_in_server:set_remote_group_sid(SID)
    group_in_server:set_remote_group_folder(folder)
    group_in_server:set_remote_group_role_id(role_id)
    group_in_server:set_remote_group_privilege(role_id)

    account_utils.check_login_rule_ids(permit_rule_ids)
    local login_rule_ids = account_utils.covert_login_rule_ids_str_to_num(permit_rule_ids)
    group_in_server:set_remote_group_permit_rule_ids(login_rule_ids)

    if not iam_utils.check_remote_group_interface_info(group_type, login_interface) then
        error(custom_msg.InvalidValue(table.concat(login_interface, " "), 'LoginInterface'))
    end
    local login_interface_num = iam_utils.cover_interface_str_to_num(login_interface)
    group_in_server:set_remote_group_login_interface(login_interface_num)
end

function RemoteGroupCollection:new_remote_group(ctx, group_type, controller_id, member_id, group_name, folder, SID,
                                                role_id, permit_rule_ids, login_interface)
    if not check_controller_type_and_id(group_type, controller_id) then
        log:error('Add RemoteGroup failed, Invalid GroupType Or ControllerId.')
        error(custom_msg.InvalidValue(controller_id, 'ControllerId'))
    end

    if member_id > remote_group_config.MAX_GROUP_CNT_IN_CONTROLLER then
        log:error('Add RemoteGroup failed, Invalid member_id.')
        error(custom_msg.InvalidValue(member_id, 'MemberId'))
    end

    local groups, len = self:get_remote_groups_in_controller(group_type, controller_id)
    -- 每个控制器下最多存在5个认证组
    if len >= remote_group_config.MAX_GROUP_CNT_IN_CONTROLLER then
        log:error('Add RemoteGroup failed, The number of RemoteGroup exceeds the limit.')
        error(base_msg.PropertyMemberQtyExceedLimit('RemoteGroup'))
    end

    -- 若允许增加，寻找可使用的group_id和controller_inner_id
    local group_id = self:find_unused_group_id()

    if groups[member_id] ~= nil then
        log:error('Add RemoteGroup failed, member_id is exists.')
        error(base_msg.ResourceAlreadyExists())
    end
    local controller_inner_id = member_id == 0 and self:find_unused_controller_inner_id(groups) or member_id
    local group_in_db =
    self.m_table_remote_group({ Id = group_id, GroupType = group_type, ControllerId = controller_id,
        SID = SID, UserRoleId = role_id, ControllerInnerId = controller_inner_id })
    local group_in_server = remote_group_manager.new(group_in_db)
    if not group_in_server then
        error(base_msg.InternalError())
    end

    local ok, err = pcall(function()
        self:setup_group_properties(group_type, group_in_server, group_name, SID, folder, role_id,
            permit_rule_ids, login_interface)
    end)
    if not ok then
        group_in_server.remote_group:delete()
        self.m_db_remote_group_collection[group_id] = nil
        error(err)
    end
    local mdb_id = string.format('%s%s_%s', group_type == 0 and 'LDAP' or 'KERBEROS',
                                controller_id, controller_inner_id)
    self.m_db_remote_group_collection[group_id] = group_in_server
    self.m_remote_group_added:emit(group_in_server:get_group())
    return mdb_id, group_id
end

function RemoteGroupCollection:delete_remote_group(ctx, mdb_id)
    local group_type, controller, controller_inner_id = string.match(mdb_id, "(%w+)(%d+)_(%d+)")
    local group_id = string.format('%s%s group%s', group_type, controller, controller_inner_id)
    ctx.operation_log.params = { group_id = group_id }
    -- controller 是从 mdb_id 中拆出来的，是个字符串形式，需要独立tonumber一下
    local group = self:get_remote_group_by_id(group_type, tonumber(controller), controller_inner_id)
    if not group then
        error(custom_msg.InvalidValue(controller_inner_id, 'MemberId'))
    end
    group_id = group:get_group().Id
    group.remote_group:delete()
    self.m_db_remote_group_collection[group_id] = nil

    self.m_remote_group_removed:emit(group_id)
    self.m_remote_group_security_changed:emit(group_id, mdb_id)
end

function RemoteGroupCollection:get_remote_group_by_id(group_type, controller, controller_inner_id)
    local real_group_type = group_type == 'LDAP' and iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value() or
                                    iam_enum.RemoteGroupType.GROUP_TYPE_KERBEROS:value()
    local groups = self:get_remote_groups_in_controller(real_group_type, controller)
    controller_inner_id = tonumber(controller_inner_id)
    return groups[controller_inner_id]
end

function RemoteGroupCollection:get_remote_group_type(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_type()
end

function RemoteGroupCollection:get_remote_group_controller_id(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_controller_id()
end

function RemoteGroupCollection:get_remote_group_controller_inner_id(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_controller_inner_id()
end

function RemoteGroupCollection:get_remote_group_sid(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_sid()
end

function RemoteGroupCollection:set_remote_group_sid(group_id, value)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    self.m_db_remote_group_collection[group_id]:set_remote_group_sid(value)
    self.m_remote_group_security_changed:emit(group_id, nil)
end

function RemoteGroupCollection:get_remote_group_name(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_name()
end

function RemoteGroupCollection:set_remote_group_name(group_id, value)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    self.m_db_remote_group_collection[group_id]:set_remote_group_name(value)
    self.m_remote_group_security_changed:emit(group_id, nil)
end

function RemoteGroupCollection:get_remote_group_domain(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_domain()
end

function RemoteGroupCollection:set_remote_group_domain(group_id, value)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    self.m_db_remote_group_collection[group_id]:set_remote_group_domain(value)
    self.m_remote_group_security_changed:emit(group_id, nil)
end

function RemoteGroupCollection:update_privilege(role_id)
    for id, group in pairs(self.m_db_remote_group_collection) do
        if group:get_role_id() == role_id then
            group:set_remote_group_role_id(iam_enum.RoleType.CommonUser:value())
            self.m_remote_group_changed:emit(id, 'UserRoleId', iam_enum.RoleType.CommonUser:value())
            self.m_remote_group_security_changed:emit(id, nil)
        end
    end
end

function RemoteGroupCollection:get_role_id(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_role_id()
end

function RemoteGroupCollection:set_remote_group_role_id(group_id, value)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    self.m_db_remote_group_collection[group_id]:set_remote_group_role_id(value)
    self.m_remote_group_security_changed:emit(group_id, nil)
end

function RemoteGroupCollection:get_remote_group_privilege(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_privilege()
end

function RemoteGroupCollection:set_remote_group_privilege(group_id, value)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    self.m_db_remote_group_collection[group_id]:set_remote_group_privilege(value)
    self.m_remote_group_security_changed:emit(group_id, nil)
end

function RemoteGroupCollection:get_remote_group_folder(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_folder()
end

function RemoteGroupCollection:set_remote_group_folder(group_id, value)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    self.m_db_remote_group_collection[group_id]:set_remote_group_folder(value)
    self.m_remote_group_security_changed:emit(group_id, nil)
end

function RemoteGroupCollection:get_remote_group_privilege_mask(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_privilege_mask()
end

function RemoteGroupCollection:set_remote_group_privilege_mask(group_id, value)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:set_remote_group_privilege_mask(value)
end

function RemoteGroupCollection:get_remote_group_permit_rule_ids(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_permit_rule_ids()
end

function RemoteGroupCollection:set_remote_group_permit_rule_ids(group_id, value)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    self.m_db_remote_group_collection[group_id]:set_remote_group_permit_rule_ids(value)
    self.m_remote_group_security_changed:emit(group_id, nil)
end

function RemoteGroupCollection:get_remote_group_login_interface(group_id)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    return self.m_db_remote_group_collection[group_id]:get_remote_group_login_interface()
end

function RemoteGroupCollection:set_remote_group_login_interface(group_id, value)
    if self.m_db_remote_group_collection[group_id] == nil then
        error(base_msg.InvalidIndex(group_id))
    end
    self.m_db_remote_group_collection[group_id]:set_remote_group_login_interface(value)
    self.m_remote_group_security_changed:emit(group_id, nil)
end

return singleton(RemoteGroupCollection)