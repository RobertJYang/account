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
local remote_group_collection = require 'domain.remote_group.remote_group_collection'
local remote_groups_config = require 'domain.remote_groups_config'
local signal = require 'mc.signal'
local class = require 'mc.class'
local role = require 'domain.cache.role_cache'
local iam_enum = require 'class.types.types'
local utils = require 'utils'
local account_utils = require 'infrastructure.account_utils'
local log = require 'mc.logging'
local custom_msg = require 'messages.custom'

-- RemoteGroupService
local RemoteGroupService = class()

function RemoteGroupService:ctor(db)
    self.m_remote_group_collection = remote_group_collection.get_instance()
    self.m_remote_groups_config = remote_groups_config.get_instance()
    self.m_config_added = signal.new()
    self.m_config_changed = signal.new()
    self.m_rc = role.get_instance()
end

function RemoteGroupService:new_remote_group(ctx, group_type, controller_id, member_id, group_name, folder, SID,
        role_id, permit_rule_ids, login_interface)
    -- 新增远程用户组校验登录接口是否在允许范围内
    local interface_num = utils.cover_interface_str_to_num(login_interface)
    if not self.m_remote_groups_config:check_login_interface_is_allowed(interface_num) then
        log:error('LoginInterface is illegal, interface : %s', table.concat(login_interface, ', '))
        error(custom_msg.PropertyItemNotInList(
            '%LoginInterface:' .. table.concat(login_interface, " "), '%LoginInterface'))
    end
    local ret = self.m_remote_group_collection:new_remote_group(ctx, group_type, controller_id, member_id, group_name,
        folder, SID, role_id, permit_rule_ids, login_interface)
    local role_name = self.m_rc:get_role_name_by_id(role_id)
    local login_interface_str =table.concat(login_interface, " ")
    ctx.operation_log.params = { group_name = group_name, interface = login_interface_str, role_name = role_name }
    if group_type == iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value() then
        ctx.operation_log.result = 'ldap_success'
    else
        ctx.operation_log.result = 'kerberos_success'
        ctx.operation_log.params.SID = SID
    end
    return ret
end

function RemoteGroupService:get_allowed_login_interfaces()
    return self.m_remote_groups_config:get_allowed_login_interfaces()
end

function RemoteGroupService:set_allowed_login_interfaces(interface_num)
    self.m_remote_groups_config:set_allowed_login_interfaces(interface_num)
    self.m_config_changed:emit('AllowedLoginInterfaces',
        account_utils.convert_num_to_interface_str(interface_num, true))
end

return singleton(RemoteGroupService)