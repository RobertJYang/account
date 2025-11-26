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
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local cls_mng = require 'mc.class_mgnt'
local log = require 'mc.logging'
local base_msg = require 'messages.base'
local context = require 'mc.context'
local operation_logger = require 'interface.operation_logger'
local ldap_config = require 'domain.ldap_config'

local PATH_LDAP<const> = '/bmc/kepler/AccountService/LDAP'
local INTERFACE_LDAP = 'bmc.kepler.AccountService.LDAP'

local LdapConfigMdb = class()

function LdapConfigMdb:ctor(bus)
    self.m_ldap_config = ldap_config.get_instance()
    self.m_bus = bus
    self.m_mdb_config = {}
end

function LdapConfigMdb:init()
    self:new_config_to_mdb_tree(self.m_ldap_config.m_config)
    self:regist_ldap_config_signals()
end

function LdapConfigMdb:regist_ldap_config_signals()
    self.m_change_config_handle = self.m_ldap_config.m_ldap_config_changed:on(function(...)
        self:config_mdb_update(...)
    end)
end

LdapConfigMdb.watch_config_property_hook = {
    Enabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enabled' or 'Disabled' }
        self.m_ldap_config:set_ldap_enabled(value)
    end, 'LdapEnabled')
}

function LdapConfigMdb:watch_config_property(service)
    service[INTERFACE_LDAP].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the ldap config property(%s) to value(%s), sender is nil', name, tostring(value))
            return true
        end

        if not self.watch_config_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('change the ldap config property(%s) to value(%s)', name, tostring(value))
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_config_property_hook[name](self, ctx, value)
        return true
    end)
end

function LdapConfigMdb:new_config_to_mdb_tree(ldap_config)
    local mdb_config = cls_mng('LDAP'):get(PATH_LDAP)
    mdb_config[INTERFACE_LDAP].Enabled = ldap_config.Enabled
    self:watch_config_property(mdb_config)
    self.m_mdb_config = mdb_config
end

function LdapConfigMdb:config_mdb_update(property, value)
    if self.m_mdb_config == nil then
        return
    end
    self.m_mdb_config[property] = value
end

return singleton(LdapConfigMdb)