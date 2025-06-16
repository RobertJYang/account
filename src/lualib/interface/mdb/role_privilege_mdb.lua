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
local cls_mng = require 'mc.class_mgnt'
local log = require 'mc.logging'
local context = require 'mc.context'
local c_object = require 'mc.orm.object'
local service = require 'account.service'
local privilege = require 'domain.privilege'
local base_msg = require 'messages.base'
local operation_logger = require 'interface.operation_logger'
local role_obj = c_object('Role')

-- ORM会尝试调用create_mdb_object将模型类上库
-- 手动实现用户的各模型类create_mdb_object, 避免刷日志
function role_obj.create_mdb_object(value)
    return value
end

local INTERFACE_ROLE<const> = 'bmc.kepler.AccountService.Role'
local INTERFACE_ROLES<const> = 'bmc.kepler.AccountService.Roles'

local role_privilege_mdb = class()

function role_privilege_mdb:ctor(role_collection)
    self.m_role_collection = role_collection
    self.m_role_privileges = {}
    self.m_mdb_cls = cls_mng("Role")
end

function role_privilege_mdb:init()
    self:new_roles_to_mdb_tree()
end

function role_privilege_mdb:regist_role_privilege_signals()
    self.m_new_unregist_handle = self.m_role_collection.m_role_added:on(function (...)
        self:new_role_to_mdb_tree(...)
    end)
    self.m_delete_unregist_handle = self.m_role_collection.m_role_removed:on(function (ctx, role_id)
        self:delete_role_from_mdb_tree(role_id)
    end)
    self.m_change_unregist_handle = self.m_role_collection.m_role_privilege_changed:on(function (...)
        self:role_privilege_mdb_update(...)
    end)
end

function role_privilege_mdb:new_roles_to_mdb_tree()
    local ex_role_enabled = self.m_role_collection:get_extended_custom_role_enabled()
    local cls_config = cls_mng('Roles'):get("/bmc/kepler/AccountService/Roles")
    cls_config[INTERFACE_ROLES].ExtendedCustomRoleEnabled = ex_role_enabled
    self:watch_roles_property(cls_config)
end

function role_privilege_mdb:new_role_to_mdb_tree(role_data)
    -- 资源写作接口角色路径以角色Id的枚举值拼接
    local role = service:CreateRole(tostring(role_data.Id:value()), function(role)
        role.Name = role_data.RoleName
        role.RolePrivilege = privilege.new_from_data(role_data):to_array()
    end)
    self.m_role_privileges[role_data.Id:value()] = role
end

function role_privilege_mdb:delete_role_from_mdb_tree(role_id)
    self.m_mdb_cls:remove(self.m_role_privileges[role_id])
    self.m_role_privileges[role_id] = nil
end

role_privilege_mdb.watch_property_hook = {
    ExtendedCustomRoleEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params.state = value and "Enable" or "Disable"
        self.m_role_collection:set_extended_custom_role_enabled(value)
        -- 关闭使能后需要清除CustomRole5~16
        if value == false then
            log:notice('delete custom roles 5 to 6, because the ExtendedCustomRoleEnabled is disabled')
            self.m_role_collection:clear_extended_custom_role(ctx)
        end
    end, 'SetExtendedCustomRoleEnabled')
}

function role_privilege_mdb:watch_roles_property(config)
    config[INTERFACE_ROLES].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the roles property(%s) to value(%s), sender is nil', name, tostring(value))
            return true
        end

        if not self.watch_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('change the property(%s) to value(%s)', name, tostring(value))
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_property_hook[name](self, ctx, value)
        return true
    end)
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
