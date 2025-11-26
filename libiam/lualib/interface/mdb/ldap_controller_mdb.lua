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
local ldap_controller_collection = require 'domain.ldap.ldap_controller_collection'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local base_msg = require 'messages.base'
local class = require 'mc.class'
local context = require 'mc.context'
local operation_logger = require 'interface.operation_logger'

local iam_service = require 'iam.service'
local INTERFACE_LDAP_CONTROLLER<const> = 'bmc.kepler.AccountService.LDAP.LDAPController'

local LdapControllerMdb = class()
function LdapControllerMdb:ctor(bus)
    self.m_ldap_controller_collection = ldap_controller_collection.get_instance()
    self.m_bus = bus
    self.m_controller = {}
end

function LdapControllerMdb:regist_ldap_controller_signals()
    self.m_new_controller_handle = self.m_ldap_controller_collection.m_ldap_controller_added:on(function(...)
        self:new_controller_to_mdb_tree(...)
    end)
    self.m_change_controller_handle = self.m_ldap_controller_collection.m_ldap_controller_changed:on(function(...)
        self:controller_mdb_update(...)
    end)
end

function LdapControllerMdb:init()
    local collection = self.m_ldap_controller_collection.m_controller_collection

    skynet.fork_once(function()
        for _, controller in pairs(collection) do
            self:new_controller_to_mdb_tree(controller:get_controller())
        end
    end)
    self:regist_ldap_controller_signals()
end

LdapControllerMdb.watch_controller_property_hook = {
    Enabled = operation_logger.proxy(function(self, ctx, controller_id, value)
        ctx.operation_log.params = { id = controller_id, state = value and 'Enabled' or 'Disabled' }
        self.m_ldap_controller_collection:set_ldap_controller_enabled(controller_id, value)
    end, 'LdapControllerEnabled'),
    HostAddr = operation_logger.proxy(function(self, ctx, controller_id, value)
        ctx.operation_log.params = { id = controller_id, addr = value }
        self.m_ldap_controller_collection:set_ldap_controller_hostaddr(controller_id, value)
    end, 'LdapControllerHostAddr'),
    Port = operation_logger.proxy(function(self, ctx, controller_id, value)
        ctx.operation_log.params = { id = controller_id, port = value }
        self.m_ldap_controller_collection:set_ldap_controller_port(controller_id, value)
    end, 'LdapControllerPort'),
    UserDomain = operation_logger.proxy(function(self, ctx, controller_id, value)
        ctx.operation_log.params = { id = controller_id, domain = value }
        self.m_ldap_controller_collection:set_ldap_controller_domain(controller_id, value)
    end, 'LdapControllerDomain'),
    Folder = operation_logger.proxy(function(self, ctx, controller_id, value)
        ctx.operation_log.params = { id = controller_id, folder = value }
        self.m_ldap_controller_collection:set_ldap_controller_folder(controller_id, value)
    end, 'LdapControllerFolder'),
    BindDN = operation_logger.proxy(function(self, ctx, controller_id, value)
        ctx.operation_log.params = { id = controller_id, bind_dn = value }
        self.m_ldap_controller_collection:set_ldap_controller_bind_dn(controller_id, value)
    end, 'LdapControllerBindDn'),
    CertVerifyEnabled = operation_logger.proxy(function(self, ctx, controller_id, value)
        ctx.operation_log.params = { id = controller_id, state = value and 'Enable' or 'Disable' }
        self.m_ldap_controller_collection:set_ldap_controller_cert_verify_enabled(controller_id, value)
    end, 'LdapControllerCertVerifyEnabled'),
    CertVerifyLevel = operation_logger.proxy(function(self, ctx, controller_id, value)
        ctx.operation_log.params = { id = controller_id, level = value }
        self.m_ldap_controller_collection:set_ldap_controller_cert_verify_level(ctx, controller_id, value)
    end, 'LdapControllerCertVerifyLevel')
}

function LdapControllerMdb:watch_controller_property(controller_id, controller)
    controller[INTERFACE_LDAP_CONTROLLER].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the ldap controller%s property(%s) to value(%s), sender is nil',
                tostring(controller_id), name, tostring(value))
            return true
        end
        
        if not self.watch_controller_property_hook[name] then
            log:error('change the ldap controller%s property(%s) to value(%s), invalid',
                tostring(controller_id), name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('change the ldap controller%s config property(%s) to value(%s)',
            tostring(controller_id), name, tostring(value))
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_controller_property_hook[name](self, ctx, controller_id, value)
        return true
    end)
end

function LdapControllerMdb:new_controller_to_mdb_tree(controller)
    local mdb_controller = iam_service:CreateLDAPController(tostring(controller.Id), function(controller_config)
        controller_config.Enabled = controller.Enabled
        controller_config.HostAddr = controller.HostAddr
        controller_config.Port = controller.Port
        controller_config.UserDomain = controller.UserDomain
        controller_config.Folder = controller.Folder
        controller_config.BindDN = controller.BindDN
        controller_config.CertVerifyEnabled = controller.CertVerifyEnabled
        controller_config.CertVerifyLevel = controller.CertVerifyLevel
        self:watch_controller_property(controller.Id, controller_config)
    end)
    self.m_controller[controller.Id] = mdb_controller
end

function LdapControllerMdb:controller_mdb_update(controllerId, property, value)
    if self.m_controller[controllerId] == nil then
        return
    end
    self.m_controller[controllerId][property] = value
end

return singleton(LdapControllerMdb)