-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
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
local base_msg = require 'messages.base'

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

-- 自定义角色导入前的预校验，支持新增和删除自定义角色
function RolePrivilegeProfile.import_precheck(profile_adapter, ctx, roles)
    for _, instance in ipairs(roles) do
        local instance_name = instance.Id.Value
        local role_id = enum.RoleType.new(instance_name):value()
        if type(role_id) ~= 'number' or role_id < enum.RoleType.CustomRole5:value() or
            role_id > enum.RoleType.CustomRole16:value() then
            log:error('process config failed, Invalid role name: %s', instance_name)
            error(base_msg.PropertyValueNotInList(role_id, 'RoleId'))
        end
        -- 配置导入存在用户，但是环境不存在，需要新建用户
        if profile_adapter.m_role_collection:get_role_data_by_id(role_id) == nil then
            profile_adapter.m_role_collection:new_role(ctx, role_id, {'ReadOnly', 'ConfigureSelf'}, {})
        end
    end
    return roles
end

-- 自定义角色导入前的过滤，移除已删除的自定义角色配置
function RolePrivilegeProfile.import_filter(profile_adapter, ctx, roles)
    return roles
end

return RolePrivilegeProfile