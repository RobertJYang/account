-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local signal = require 'mc.signal'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local enum = require 'class.types.types'
local utils = require 'infrastructure.utils'

local Role = class()

function Role:ctor(role_data)
    self.m_role_data = role_data
end

local RoleCollection = class()
function RoleCollection:ctor(db)
    local stmt_role = db:select(db.Role)
    local role_collection = stmt_role:fold(function(role, acc)
        acc[#acc + 1] = Role.new(role)
        return acc
    end, {})
    self.m_role_collection = role_collection
    self.m_role_privilege_changed = signal.new()
    self.m_privilege_update_signal = signal.new()
end

function RoleCollection:role_to_string_table(ids)
    local res = {}
    if type(ids) ~= 'table' then
        res[1] = self:get_role_data_by_id(ids).RoleName
    else
        for _, v in ipairs(ids) do
            self:get_role_data_by_id(v)
            table.insert(res, self:get_role_data_by_id(v).RoleName)
        end
    end
    return res
end

function RoleCollection:get_role_data_by_id(role_id)
    for _, v in ipairs(self.m_role_collection) do
        if v.m_role_data.Id[1] == role_id then
            return v.m_role_data
        end
    end
    error(custom_msg.AuthorizationFailed())
end

function RoleCollection:get_role_name_by_id(role_id)
    for _, v in ipairs(self.m_role_collection) do
        if v.m_role_data.Id[1] == role_id then
            return v.m_role_data.RoleName
        end
    end
    error(custom_msg.AuthorizationFailed())
end

function RoleCollection:get_role_data_by_name(role_name)
    for _, role in ipairs(self.m_role_collection) do
        if role.m_role_data.RoleName == role_name then
            return role.m_role_data
        end
    end
    return nil
end

function RoleCollection:set_role_privilege(ctx, role_id, privilege_type, privilege_value)
    -- 判断是否为自定义用户，当前只允许自定义用户修改
    local role_name = self:get_role_data_by_id(role_id).RoleName
    ctx.operation_log.params = { state = privilege_value and "Enable" or "Disable", role_name = role_name,
                                role = tostring(privilege_type) }
    local ban_role = {
        enum.RoleType.NoAccess,
        enum.RoleType.CommonUser,
        enum.RoleType.Operator,
        enum.RoleType.Administrator,
    }
    for _, enum in ipairs(ban_role) do
        if role_name == tostring(enum) then
            ctx.operation_log.operation = 'SkipLog'
            error(base_msg.InsufficientPrivilege())
        end
    end
    -- UserMgmt、ReadOnly、ConfigureSelf是禁止修改的权限
    if privilege_type == enum.PrivilegeType.UserMgmt or
        privilege_type == enum.PrivilegeType.ReadOnly or
        privilege_type == enum.PrivilegeType.ConfigureSelf then
        error(base_msg.InsufficientPrivilege())
    end

    -- 修改的值与原本一样则不修改
    local item = self:get_role_data_by_id(role_id)
    if item[tostring(privilege_type)] ~= privilege_value then
        item[tostring(privilege_type)] = privilege_value
        item:save()
        self.m_role_privilege_changed:emit(role_id)
        local priv = utils.cover_bool_to_privilege_table(item)
        -- 修改后刷新会话权限和用户当前权限
        self.m_privilege_update_signal:emit(role_id, "Privileges", priv)
    else
        ctx.operation_log.operation = 'SkipLog'
    end
end

function RoleCollection:get_role_privilege(role_id, privilege_type)
    local role_data = self:get_role_data_by_id(role_id)
    if not role_data then
        return nil
    end
    return role_data[tostring(privilege_type)]
end

return singleton(RoleCollection)
