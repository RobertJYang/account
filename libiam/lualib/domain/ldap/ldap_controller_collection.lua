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
local ldap_controller = require 'domain.ldap.ldap_controller'
local signal = require 'mc.signal'
local log = require 'mc.logging'
local base_msg = require 'messages.base'

local LdapControllerCollection = class()

function LdapControllerCollection:ctor(db)
    local stmt_controller = db:select(db.LDAPController)

    local m_db_collection = stmt_controller:fold(function(controller, acc)
        acc[controller.Id] = ldap_controller.new(controller)
        return acc
    end, {})

    self.m_controller_collection = m_db_collection
    self.db = db

    self.m_ldap_crypt_password_update = signal.new()
    self.m_ldap_controller_added = signal.new()
    self.m_ldap_controller_changed = signal.new()
    self.m_controller_security_changed = signal.new()
end

function LdapControllerCollection:init()
    self.m_change_unregist_handle = self.m_ldap_crypt_password_update:on(function(...)
        log:info("update ldap bing dn crypt password after key change start")
        local skynet = require 'skynet'
        for _, controller in pairs(self.m_controller_collection)
        do
            local value = controller:get_ldap_controller_bind_dn_psw()
            if value ~= nil and #value ~= 0 then
                skynet.sleep(20)
                controller:update_ldap_controller_bind_dn_psw()
            end
        end
        log:info("update ldap bing dn crypt password after key change finished")
    end)
end

function LdapControllerCollection:get_controllers_by_domain(domain)
    local controllers = {}
    for _, controller in pairs(self.m_controller_collection) do
        if controller:get_ldap_controller_domain() == domain then
            controllers[controller:get_controller().Id] = controller
        end
    end

    return controllers
end


function LdapControllerCollection:get_ldap_controller_enabled(controller_id)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    return self.m_controller_collection[controller_id]:get_ldap_controller_enabled()
end

-- LDAP域控制器配置
function LdapControllerCollection:set_ldap_controller_enabled(controller_id, value)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    self.m_controller_collection[controller_id]:set_ldap_controller_enabled(value)
end

function LdapControllerCollection:get_ldap_controller_hostaddr(controller_id)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    return self.m_controller_collection[controller_id]:get_ldap_controller_hostaddr()
end

function LdapControllerCollection:set_ldap_controller_hostaddr(controller_id, value)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    self.m_controller_collection[controller_id]:set_ldap_controller_hostaddr(value)
    self.m_controller_security_changed:emit(controller_id)
end

function LdapControllerCollection:get_ldap_controller_port(controller_id)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    return self.m_controller_collection[controller_id]:get_ldap_controller_port()
end

function LdapControllerCollection:set_ldap_controller_port(controller_id, value)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    self.m_controller_collection[controller_id]:set_ldap_controller_port(value)
    self.m_controller_security_changed:emit(controller_id)
end

function LdapControllerCollection:get_ldap_controller_domain(controller_id)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    return self.m_controller_collection[controller_id]:get_ldap_controller_domain()
end

function LdapControllerCollection:set_ldap_controller_domain(controller_id, value)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    self.m_controller_collection[controller_id]:set_ldap_controller_domain(value)
    self.m_controller_security_changed:emit(controller_id)
end

function LdapControllerCollection:get_ldap_controller_folder(controller_id)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    return self.m_controller_collection[controller_id]:get_ldap_controller_folder()
end

function LdapControllerCollection:set_ldap_controller_folder(controller_id, value)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    self.m_controller_collection[controller_id]:set_ldap_controller_folder(value)
    self.m_controller_security_changed:emit(controller_id)
end

function LdapControllerCollection:get_ldap_controller_bind_dn(controller_id)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    return self.m_controller_collection[controller_id]:get_ldap_controller_bind_dn()
end

function LdapControllerCollection:set_ldap_controller_bind_dn(controller_id, value)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    self.m_controller_collection[controller_id]:set_ldap_controller_bind_dn(value)
    self.m_controller_security_changed:emit(controller_id)
end

function LdapControllerCollection:get_ldap_controller_bind_dn_psw(controller_id)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    return self.m_controller_collection[controller_id]:get_ldap_controller_bind_dn_psw()
end

function LdapControllerCollection:set_ldap_controller_bind_dn_psw(ctx, controller_id, value)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    ctx.operation_log.params = { id = controller_id }
    self.m_controller_collection[controller_id]:set_ldap_controller_bind_dn_psw(value)
    self.m_controller_security_changed:emit(controller_id)
end

function LdapControllerCollection:get_ldap_controller_cert_verify_enabled(controller_id)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    return self.m_controller_collection[controller_id]:get_ldap_controller_cert_verify_enabled()
end

function LdapControllerCollection:set_ldap_controller_cert_verify_enabled(controller_id, value)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    self.m_controller_collection[controller_id]:set_ldap_controller_cert_verify_enabled(value)
    self.m_controller_security_changed:emit(controller_id)
end

function LdapControllerCollection:get_ldap_controller_cert_verify_level(controller_id)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    return self.m_controller_collection[controller_id]:get_ldap_controller_cert_verify_level()
end

function LdapControllerCollection:set_ldap_controller_cert_verify_level(ctx, controller_id, value)
    if self.m_controller_collection[controller_id] == nil then
        error(base_msg.InvalidIndex(controller_id))
    end
    self.m_controller_collection[controller_id]:set_ldap_controller_cert_verify_level(ctx, value)
    self.m_controller_security_changed:emit(controller_id)
end

return singleton(LdapControllerCollection)