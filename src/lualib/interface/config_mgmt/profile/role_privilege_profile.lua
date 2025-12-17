-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 配置导入导出时权限配置相关项

local log = require 'mc.logging'
local error = require 'mc.error'
local account_enum = require 'class.types.types'
local custom_msg = require 'messages.custom'
local enum = require 'class.types.types'
local operation_logger = require 'interface.operation_logger'

local RolePrivilegeProfile = {}

function RolePrivilegeProfile.set_role_name(self, ctx, role_name)
    if not self.m_role_collection:get_role_data_by_name(role_name) then
        error(custom_msg.InvalidValue('Id', role_name))
    end
end

function RolePrivilegeProfile.get_role_name(self, role_name)
    if not self.m_role_collection:get_role_data_by_name(role_name) then
        return nil
    end
    return role_name
end

function RolePrivilegeProfile.set_user_mgmt(self, ctx, role_name, value)
    return
end

function RolePrivilegeProfile.get_user_mgmt(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.UserMgmt
    return self.m_role_collection:get_role_privilege(role_id, privilege_type)
end

function RolePrivilegeProfile.set_basic_setting(self, ctx, role_name, value)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.BasicSetting
    self.m_role_collection:set_role_privilege(ctx, role_id, privilege_type, value)
end

function RolePrivilegeProfile.get_basic_setting(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.BasicSetting
    return self.m_role_collection:get_role_privilege(role_id, privilege_type)
end

function RolePrivilegeProfile.set_kvm_mgmt(self, ctx, role_name, value)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.KVMMgmt
    self.m_role_collection:set_role_privilege(ctx, role_id, privilege_type, value)
end

function RolePrivilegeProfile.get_kvm_mgmt(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.KVMMgmt
    return self.m_role_collection:get_role_privilege(role_id, privilege_type)
end

function RolePrivilegeProfile.set_vmm_mgmt(self, ctx, role_name, value)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.VMMMgmt
    self.m_role_collection:set_role_privilege(ctx, role_id, privilege_type, value)
end

function RolePrivilegeProfile.get_vmm_mgmt(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.VMMMgmt
    return self.m_role_collection:get_role_privilege(role_id, privilege_type)
end

function RolePrivilegeProfile.set_security_mgmt(self, ctx, role_name, value)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.SecurityMgmt
    self.m_role_collection:set_role_privilege(ctx, role_id, privilege_type, value)
end

function RolePrivilegeProfile.get_security_mgmt(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.SecurityMgmt
    return self.m_role_collection:get_role_privilege(role_id, privilege_type)
end

function RolePrivilegeProfile.set_power_mgmt(self, ctx, role_name, value)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.PowerMgmt
    self.m_role_collection:set_role_privilege(ctx, role_id, privilege_type, value)
end

function RolePrivilegeProfile.get_power_mgmt(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.PowerMgmt
    return self.m_role_collection:get_role_privilege(role_id, privilege_type)
end

function RolePrivilegeProfile.set_diagnose_mgmt(self, ctx, role_name, value)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.DiagnoseMgmt
    self.m_role_collection:set_role_privilege(ctx, role_id, privilege_type, value)
end

function RolePrivilegeProfile.get_diagnose_mgmt(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.DiagnoseMgmt
    return self.m_role_collection:get_role_privilege(role_id, privilege_type)
end

function RolePrivilegeProfile.set_read_only(self, ctx, role_name, value)
    return
end

function RolePrivilegeProfile.get_read_only(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.ReadOnly
    return self.m_role_collection:get_role_privilege(role_id, privilege_type)
end

function RolePrivilegeProfile.set_configure_self(self, ctx, role_name, value)
    return
end

function RolePrivilegeProfile.get_configure_self(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    local privilege_type = account_enum.PrivilegeType.ConfigureSelf
    return self.m_role_collection:get_role_privilege(role_id, privilege_type)
end

-- 在前置校验中已经确保了角色增加或者删除，不需要在此处设置
function RolePrivilegeProfile.set_enabled_status(self, ctx, role_name, value)
    return
end

function RolePrivilegeProfile.get_enabled_status(self, role_name)
    local role_id = account_enum.RoleType[role_name]:value()
    return self.m_role_collection:get_role_data_by_id(role_id) ~= nil
end

-- 自定义角色导入前的预校验，支持新增和删除自定义角色
function RolePrivilegeProfile.import_precheck(profile_adapter, ctx, roles)
    local instance_name
    local role_id
    for _, instance in ipairs(roles) do
        if instance.Id.Import == false then
            goto continue
        end
        instance_name = instance.Id.Value
        role_id = enum.RoleType.new(instance_name):value()
        if role_id < enum.RoleType.CustomRole5:value() or
            role_id > enum.RoleType.CustomRole16:value() then
            -- 仅处理自定义角色5-16
            log:debug('process config skip, Role %s is not a custom role', instance_name)
            goto continue
        end
        if instance.EnabledStatus.Value == false then
            -- 删除自定义角色
            log:debug('process config delete, Role %s', instance_name)
            operation_logger.proxy(function(_, ctx)
                ctx.operation_log.params = {id = instance_name}
                profile_adapter.m_role_collection:delete_role(ctx, role_id)
            end, 'DeleteRole')(nil, ctx)
        else
            -- 配置导入存在角色，但是环境不存在，需要新建角色
            log:debug('process config add, Role %s', instance_name)
            if profile_adapter.m_role_collection:get_role_data_by_id(role_id) ~= nil then
                goto continue
            end
            operation_logger.proxy(function(_, ctx)
                ctx.operation_log.params = {id = instance_name}
                profile_adapter.m_role_collection:new_role(ctx, role_id, {'ReadOnly', 'ConfigureSelf'}, {})
            end, 'NewRole')(nil, ctx)
        end
        ::continue::
    end
end

-- 自定义角色导入前的过滤，移除已删除的自定义角色配置
function RolePrivilegeProfile.import_filter(profile_adapter, ctx, roles)
    local filtered_roles = {}
    local instance_name
    local role_id
    for _, instance in ipairs(roles) do
        instance_name = instance.Id.Value
        role_id = enum.RoleType.new(instance_name):value()
        if role_id >= enum.RoleType.CustomRole5:value() and
            role_id <= enum.RoleType.CustomRole16:value() then
            -- 仅自定义角色5-16需要判断，剩余角色均需要保留
            if instance.EnabledStatus.Value == true then
                filtered_roles[#filtered_roles+1] = instance
            end
        else
            -- 非自定义角色5-16，直接保留
            filtered_roles[#filtered_roles+1] = instance
        end
    end
    return filtered_roles
end

return RolePrivilegeProfile