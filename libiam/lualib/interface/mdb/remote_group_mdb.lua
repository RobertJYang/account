-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local skynet = require 'skynet'
local remote_group_collection = require 'domain.remote_group.remote_group_collection'
local remote_groups_config = require 'domain.remote_groups_config'
local account_utils = require 'infrastructure.account_utils'
local iam_utils = require 'utils'
local iam_service = require 'iam.service'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local class = require 'mc.class'
local cls_mng = require 'mc.class_mgnt'
local role = require 'domain.cache.role_cache'
local context = require 'mc.context'
local operation_logger = require 'interface.operation_logger'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local c_object = require 'mc.orm.object'
local remote_group = c_object('RemoteGroup')
-- ORM会尝试调用create_mdb_object将模型类上库
-- 手动实现create_mdb_object, 避免刷日志
function remote_group.create_mdb_object(_)
    return {}
end

local INTERFACE_REMOTE_GROUP<const> = 'bmc.kepler.AccountService.RemoteGroup'


local RemoteGroupMdb = class()

function RemoteGroupMdb:ctor(bus)
    self.remote_group_collection = remote_group_collection.get_instance()
    self.remote_groups_config = remote_groups_config.get_instance()
    self.m_bus = bus
    self.m_mdb_cls = cls_mng("RemoteGroup")
    self.m_groups = {}
    self.m_rc = role.get_instance()
end

function RemoteGroupMdb:init()
    local group_collection = self.remote_group_collection.m_db_remote_group_collection
    skynet.fork_once(function()
        for _, group in pairs(group_collection) do
            self:new_group_to_mdb_tree(group:get_group())
        end
    end)

    self:regist_remote_group_signals()
end

function RemoteGroupMdb:regist_remote_group_signals()
    self.m_new_unregist_handle = self.remote_group_collection.m_remote_group_added:on(function(...)
        self:new_group_to_mdb_tree(...)
    end)
    self.m_delete_unregist_handle = self.remote_group_collection.m_remote_group_removed:on(function(...)
        self:delete_group_from_mdb_tree(...)
    end)
    self.m_change_unregist_handle = self.remote_group_collection.m_remote_group_changed:on(function(...)
        self:group_mdb_update(...)
    end)
end

RemoteGroupMdb.watch_group_property_hook = {
    SID = operation_logger.proxy(function(self, ctx, group_id, value, remote_group_id)
        ctx.operation_log.params = { id = remote_group_id }
        self.remote_group_collection:set_remote_group_sid(group_id, value)
    end, 'SID'),
    Name = operation_logger.proxy(function(self, ctx, group_id, value, remote_group_id)
        ctx.operation_log.params = { id = remote_group_id, name = value }
        self.remote_group_collection:set_remote_group_name(group_id, value)
    end, 'RemoteGroupName'),
    UserRoleId = operation_logger.proxy(function(self, ctx, group_id, value, remote_group_id)
        ctx.operation_log.params.id = remote_group_id
        if not iam_utils.check_role_id_info(value) then
            ctx.operation_log.params.role_name = 'Unknown'
            log:error('role id is illegal!')
            error(base_msg.PropertyValueNotInList('%UserRoleId:' .. 'Unknown', '%UserRoleId'))
        end
        local role_name = self.m_rc:get_role_name_by_id(value)
        ctx.operation_log.params.role_name = role_name
        self.remote_group_collection:set_remote_group_role_id(group_id, value)
        self.remote_group_collection:set_remote_group_privilege(group_id, value)
    end, 'RemoteGroupRoleId'),
    Folder = operation_logger.proxy(function(self, ctx, group_id, value, remote_group_id)
        ctx.operation_log.params = { id = remote_group_id, folder = value }
        if value == '' then
            ctx.operation_log.result = 'clear'
        end
        self.remote_group_collection:set_remote_group_folder(group_id, value)
    end, 'RemoteGroupFolder'),
    PermitRuleIds = operation_logger.proxy(function(self, ctx, group_id, value, remote_group_id)
        ctx.operation_log.params = { username = remote_group_id, rule = table.concat(value, " ") }
        account_utils.check_login_rule_ids(value)
        local login_rule_ids = account_utils.covert_login_rule_ids_str_to_num(value)
        local old_permit_rule_num = self.remote_group_collection:get_remote_group_permit_rule_ids(group_id)
        self.remote_group_collection:set_remote_group_permit_rule_ids(group_id, login_rule_ids)
        local new_permit_rule_num = self.remote_group_collection:get_remote_group_permit_rule_ids(group_id)
        local change = account_utils.get_login_interface_or_rule_ids_change(old_permit_rule_num,
            new_permit_rule_num, account_utils.covert_num_to_login_rule_ids_str)
        if not change then
            ctx.operation_log.operation = 'SkipLog'
        end
        ctx.operation_log.params.change = change
    end, 'LoginRule'),
    LoginInterface = operation_logger.proxy(function(self, ctx, group_id, value, remote_group_id)
        ctx.operation_log.params = { username = remote_group_id, interface = table.concat(value, " ") }
        local group_type = self.remote_group_collection:get_remote_group_type(group_id)
        if not iam_utils.check_remote_group_interface_info(group_type, value) then
            error(custom_msg.PropertyItemNotInList('%LoginInterface:' .. table.concat(value, " "), '%LoginInterface'))
        end
        local login_interface_num = iam_utils.cover_interface_str_to_num(value)
        if not self.remote_groups_config:check_login_interface_is_allowed(login_interface_num) then
            log:error('LoginInterface is illegal, interface : %s', table.concat(value, ', '))
            error(custom_msg.PropertyItemNotInList(
                '%LoginInterface:' .. table.concat(value, " "), '%LoginInterface'))
        end
        local old_interface_num = self.remote_group_collection:get_remote_group_login_interface(group_id)
        self.remote_group_collection:set_remote_group_login_interface(group_id, login_interface_num)
        local new_interface_num = self.remote_group_collection:get_remote_group_login_interface(group_id)
        local change = account_utils.get_login_interface_or_rule_ids_change(old_interface_num,
            new_interface_num, account_utils.convert_num_to_interface_str)
        if not change then
            ctx.operation_log.operation = 'SkipLog'
        end
        ctx.operation_log.params.change = change
    end, 'LoginInterface')
}

function RemoteGroupMdb:watch_group_property(group_id, group, remote_group_id)
    group[INTERFACE_REMOTE_GROUP].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the ldap group property(%s) to value(%s), sender is nil', name, tostring(value))
            return true
        end
        if not self.watch_group_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end
        log:info('change the property(%s) to value(%s)', name, tostring(value))

        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_group_property_hook[name](self, ctx, group_id, value, remote_group_id)
        return true
    end)
end

function RemoteGroupMdb:new_group_to_mdb_tree(group)
    local mdb_id = string.format('%s%s_%s', group.GroupType == 0 and 'LDAP' or 'KERBEROS',
                                                            group.ControllerId, group.ControllerInnerId)
    local new_group_config = iam_service:CreateRemoteGroup(mdb_id, function(group_config)
        group_config.GroupType = group.GroupType
        group_config.ControllerId = group.ControllerId
        group_config.SID = group.SID
        group_config.Name = group.Name
        group_config.UserRoleId = group.UserRoleId
        group_config.Folder = group.Folder
        group_config.PermitRuleIds = account_utils.covert_num_to_login_rule_ids_str(group.PermitRuleIdsDB)
        group_config.LoginInterface = account_utils.convert_num_to_interface_str(group.LoginInterfaceDB, true)
        local remote_group_id = string.format('%s%s group%s', group.GroupType == 0 and 'LDAP' or 'Kerberos',
                                                            group.ControllerId, group.ControllerInnerId)
        self:watch_group_property(group.Id, group_config, remote_group_id)
    end)
    self.m_groups[group.Id] = new_group_config
end

function RemoteGroupMdb:delete_group_from_mdb_tree(group_id)
    self.m_mdb_cls:remove(self.m_groups[group_id])
    self.m_groups[group_id] = nil
end

function RemoteGroupMdb:group_mdb_update(groupId, property, value)
    if self.m_groups[groupId][property] == nil then
        return
    end
    self.m_groups[groupId][property] = value
end

return singleton(RemoteGroupMdb)