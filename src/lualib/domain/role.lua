-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local signal = require 'mc.signal'
local base_msg = require 'messages.base'
local enum = require 'class.types.types'
local log = require 'mc.logging'
local mc_utils = require 'mc.utils'

-- 不可更改权限类型
local UNALTERABLE_PRIV<const> = {
    UserMgmt = true,
    ReadOnly = true,
    ConfigureSelf = true
}

local ASSIGNED_PRIV_TAB<const> = {
    ReadOnly = true,
    UserMgmt = false,
    ConfigureSelf = true,
    BasicSetting = true
}

local OEM_PRIV_TAB<const> = {
    PowerMgmt = true,
    SecurityMgmt = true,
    KVMMgmt = true,
    VMMMgmt = true,
    DiagnoseMgmt = true
}

local Role = class()

function Role:ctor(role_data)
    self.m_role_data = role_data
end

function Role:get_role_data()
    return self.m_role_data
end

function Role:get_role_name()
    return self.m_role_data.RoleName
end

function Role:get_privilege(privilege_type)
    return self.m_role_data[privilege_type]
end

function Role:set_privilege() end

function Role:get_privileges_str_tab()
    local privs_str = {}
    for _, value in pairs(enum.PrivilegeType) do
        if self.m_role_data[tostring(value)] then
            table.insert(privs_str, tostring(value))
        end
    end
    return privs_str
end


local BasicRole = class(Role)

function BasicRole:ctor(role_data)
    self.m_role_data = role_data
end

function BasicRole:set_privilege()
    log:error('set privilege failed, current role not support change privileges')
    error(base_msg.InsufficientPrivilege())
end


local CustomRole = class(Role)

function CustomRole:ctor(role_data)
    self.m_role_data = role_data
end

function CustomRole:set_privilege(privilege, value)
    self.m_role_data[privilege] = value
    self.m_role_data:save()
end


local RoleCollection = class()

function RoleCollection:ctor(db)
    local stmt_role = db:select(db.Role)
    self.m_roles_config = db:select(db.Roles):first()
    local role_collection = stmt_role:fold(function(role, acc)
        -- 对于CustomRole5~16角色，当前未开启ExtendedCustomRoleEnabled时不加载
        if role.Id:value() >= enum.RoleType.CustomRole5:value() and
            not self.m_roles_config.ExtendedCustomRoleEnabled then
            return
        end
        acc[role.Id:value()] = role.Id:value() <= enum.RoleType.Administrator:value() and
                               BasicRole.new(role) or CustomRole.new(role)
        return acc
    end, {})
    self.m_role_tab = stmt_role.table
    self.m_role_collection = role_collection
    self.m_roles_config_update = signal.new()
    self.m_role_privilege_changed = signal.new()
    self.m_role_added = signal.new()
    self.m_role_removed = signal.new()
end

--- 初始化所有角色对象上树
function RoleCollection:emit_init_role_signal()
    for role_id, role in pairs(self.m_role_collection) do
        -- 对于CustomRole5~16,未开启ExtendedCustomRoleEnabled时不上树
        if role_id >= enum.RoleType.CustomRole5:value() and not self.m_roles_config.ExtendedCustomRoleEnabled then
            goto continue
        end
        self.m_role_added:emit(role:get_role_data())
        ::continue::
    end
end

---通过id获取角色权限
---@param ids any
---@return table
function RoleCollection:role_to_string_table(ids)
    local res = {}
    if type(ids) ~= 'table' then
        res[1] = self:get_role_name_by_id(ids)
    else
        for _, v in ipairs(ids) do
            table.insert(res, self:get_role_name_by_id(v))
        end
    end
    return res
end

---获取所有角色信息
---@return table
function RoleCollection:get_all_role_names()
    local roles = {}
    for role_id, role in pairs(self.m_role_collection) do
        -- 对于CustomRole5~16,未开启ExtendedCustomRoleEnabled时不获取
        if role_id >= enum.RoleType.CustomRole5:value() and not self.m_roles_config.ExtendedCustomRoleEnabled then
            goto continue
        end
        roles[#roles+1] = role:get_role_name()
        ::continue::
    end
    return roles
end

---通过id获取角色数据
---@param role_id number
---@return table
function RoleCollection:get_role_data_by_id(role_id)
    local role = self.m_role_collection[role_id]
    if not role then
        return nil
    end
    return role:get_role_data()
end

---通过id获取角色名
---@param role_id number
---@return string
function RoleCollection:get_role_name_by_id(role_id)
    local role = self.m_role_collection[role_id]
    if not role then
        return nil
    end
    return role:get_role_name()
end

---通过角色名获取角色数据
---@param role_name string
---@return table
function RoleCollection:get_role_data_by_name(role_name)
    for _, role in pairs(self.m_role_collection) do
        if role:get_role_name() == role_name then
            return role:get_role_data()
        end
    end
    return nil
end

---通过角色名获取对应角色
---@param role_name string
---@return number
---@return table
function RoleCollection:get_role_by_name(role_name)
    for role_id, role in pairs(self.m_role_collection) do
        if role:get_role_name() == role_name then
            return role_id, role
        end
    end
    return nil, nil
end

---获取角色权限
---@param role_id number
---@param privilege_type string
---@return boolean
function RoleCollection:get_role_privilege(role_id, privilege_type)
    local role = self.m_role_collection[role_id]
    if not role then
        return nil
    end
    return role:get_privilege(tostring(privilege_type))
end

---设置角色权限
---@param ctx table
---@param role_id number
---@param privilege_type string
---@param privilege_value boolean
function RoleCollection:set_role_privilege(ctx, role_id, privilege_type, privilege_value)
    local role = self.m_role_collection[role_id]
    if not role then
        log:error('set role privilege failed, unknown role id')
        error(base_msg.PropertyValueNotInList(role_id, 'RoleId'))
    end
    privilege_type = tostring(privilege_type)
    ctx.operation_log.params = { state = privilege_value and "Enable" or "Disable", role_name = role:get_role_name(),
                                role = privilege_type }
    if not enum.PrivilegeType[privilege_type] then
        log:error('set role privilege failed, unknown privilege type : %s', privilege_type)
        error(base_msg.PropertyValueNotInList(privilege_type, 'PrivilegeType'))
    end
    if UNALTERABLE_PRIV[privilege_type] then
        log:error('set role privilege failed, %s is unalterable', privilege_type)
        error(base_msg.InsufficientPrivilege())
    end
    if role:get_privilege(privilege_type) == privilege_value then
        ctx.operation_log.operation = 'SkipLog'
        return
    end
    role:set_privilege(privilege_type, privilege_value)
    self.m_role_privilege_changed:emit(role_id)
end

---新建角色 -- 基于标准Redfish规范权限
---@param ctx table
---@param role_id number
---@param assigned_privs table
---@param oem_privs table
function RoleCollection:new_role(ctx, role_id, assigned_privs, oem_privs)
    if not self.m_roles_config.ExtendedCustomRoleEnabled then
        log:error('new role failed, operation not support')
        error(base_msg.ActionNotSupported('Create Custom Role'))
    end
    if role_id < enum.RoleType.CustomRole5:value() or
        role_id > enum.RoleType.CustomRole16:value() then
        log:error('new role failed, RoleId(%d) is not support', role_id)
        error(base_msg.PropertyValueNotInList(role_id, 'RoleId'))
    end
    if self.m_role_collection[role_id] ~= nil then
        log:error('new role failed, role already exists')
        error(base_msg.ResourceAlreadyExists())
    end
    local role_data = {
        PowerMgmt = false,
        SecurityMgmt = false,
        KVMMgmt = false,
        VMMMgmt = false,
        DiagnoseMgmt = false,
        UserMgmt = false,
        BasicSetting = false
    }
    for _, value in pairs(assigned_privs) do
        if not ASSIGNED_PRIV_TAB[value] then
            log:error('new role failed, privileges(%d) is not support', value)
            error(base_msg.PropertyValueNotInList(value, 'AssignedPrivileges'))
        end
        role_data[value] = true
    end
    for _, value in pairs(oem_privs) do
        if not OEM_PRIV_TAB[value] then
            log:error('new role failed, privileges(%d) is not support', value)
            error(base_msg.PropertyValueNotInList(value, 'OemPrivileges'))
        end
        role_data[value] = true
    end
    if not (role_data['ReadOnly'] and role_data['ConfigureSelf']) then
        log:error('new role failed, ReadOnly or ConfigureSelf is missing')
        error(base_msg.PropertyMissing('ReadOnly or ConfigureSelf privilege'))
    end
    -- Role Id持久化类型为枚举类
    role_data.Id = enum.RoleType.new(role_id)
    role_data.RoleName = tostring(enum.RoleType.new(role_id))
    local role_db = self.m_role_tab(role_data)

    self.m_role_collection[role_id] = CustomRole.new(role_db)
    self.m_role_added:emit(role_data)
end

---删除角色
---@param ctx table
---@param role_id number
function RoleCollection:delete_role(ctx, role_id)
    if not self.m_roles_config.ExtendedCustomRoleEnabled then
        log:error('new role failed, operation not support')
        error(base_msg.ActionNotSupported('Delete Custom Role'))
    end
    local role = self.m_role_collection[role_id]
    if not role then
        log:error('delete role failed, RoleId(%d) is not exist')
        error(base_msg.PropertyValueNotInList(role_id, 'RoleId'))
    end
    if role_id < enum.RoleType.CustomRole5:value() or
        role_id > enum.RoleType.CustomRole16:value() then
        log:error('delete role failed, RoleId(%d) is not support', role_id)
        error(base_msg.PropertyValueNotInList(role_id, 'RoleId'))
    end

    role.m_role_data:delete()
    self.m_role_collection[role_id] = nil
    self.m_role_removed:emit(mc_utils.table_copy(ctx), role_id)
end

---获取扩展自定义角色功能使能
---@return boolean
function RoleCollection:get_extended_custom_role_enabled()
    return self.m_roles_config.ExtendedCustomRoleEnabled
end

---设置扩展自定义角色功能使能
---@param value boolean
function RoleCollection:set_extended_custom_role_enabled(value)
    self.m_roles_config.ExtendedCustomRoleEnabled = value
    self.m_roles_config:save()
end

---清除所有扩展自定义角色
---@param ctx table
function RoleCollection:clear_extended_custom_role(ctx)
    for index = 9, 20 do
        if self.m_role_collection[index] ~= nil then
            self.m_role_collection[index].m_role_data:delete()
            self.m_role_collection[index] = nil
            self.m_role_removed:emit(mc_utils.table_copy(ctx), index)
        end
    end
end

return singleton(RoleCollection)
