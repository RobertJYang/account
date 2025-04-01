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
local enum = require 'class.types.types'
local service = require 'account.service'
local privilege = require 'domain.privilege'

local INTERFACE_ROLE = 'bmc.kepler.AccountService.Role'

local role_privilege_mdb = class()

function role_privilege_mdb:ctor(role_collection)
    self.m_role_collection = role_collection
    self.m_role_privileges = {}
end

function role_privilege_mdb:init()
    self:new_role_privilege_to_mdb_tree()
end

function role_privilege_mdb:regist_role_privilege_signals()
    self.m_change_unregist_handle = self.m_role_collection.m_role_privilege_changed:on(function (...)
        self:role_privilege_mdb_update(...)
    end)
end

function role_privilege_mdb:new_role_privilege_to_mdb_tree()
    -- 设置不同角色的九大权限
    local mdb_role = {
        enum.RoleType.NoAccess,
        enum.RoleType.CommonUser,
        enum.RoleType.Operator,
        enum.RoleType.Administrator,
        enum.RoleType.CustomRole1,
        enum.RoleType.CustomRole2,
        enum.RoleType.CustomRole3,
        enum.RoleType.CustomRole4,
    }
    for _, role_enum in ipairs(mdb_role) do
        local data = self.m_role_collection:get_role_data_by_id(role_enum:value())
        local role = service:CreateRole(tostring(role_enum:value()), function(role)
            role.Name = tostring(role_enum)
            role.RolePrivilege = privilege.new_from_data(data):to_array()
        end)
        self.m_role_privileges[role_enum:value()] = role
    end
end

function role_privilege_mdb:role_privilege_mdb_update(role_id)
    local mdb_obj = self.m_role_privileges[role_id]
    if not mdb_obj[INTERFACE_ROLE]["RolePrivilege"] then
        return
    end
    local data = self.m_role_collection:get_role_data_by_id(role_id)
    mdb_obj[INTERFACE_ROLE]["RolePrivilege"] = privilege.new_from_data(data):to_array()
end

return singleton(role_privilege_mdb)
