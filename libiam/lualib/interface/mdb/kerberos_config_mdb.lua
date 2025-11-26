-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
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
local log = require 'mc.logging'
local cls_mng = require 'mc.class_mgnt'
local context = require 'mc.context'
local operation_logger = require 'interface.operation_logger'
local base_msg = require 'messages.base'
local kerberos_config = require 'domain.kerberos_config'

local PATH_KERBEROS<const> = '/bmc/kepler/AccountService/Kerberos'
local INTERFACE_KERBEROS<const> = 'bmc.kepler.AccountService.Kerberos'

local KerberosConfigMdb = class()
function KerberosConfigMdb:ctor(bus)
    self.m_kerberos_config = kerberos_config.get_instance()
    self.m_bus = bus
    self.m_mdb_config = {}
end

function KerberosConfigMdb:init()
    self:new_config_to_mdb_tree(self.m_kerberos_config.m_config)
end

-- 属性监听钩子
KerberosConfigMdb.watch_property_hook = {
    Enabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enabled' or 'Disabled' }
        self.m_kerberos_config:set_enabled(value)
    end, 'KerberosEnabled'),
    Address = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { address = value }
        self.m_kerberos_config:set_address(value)
    end, 'KerberosAddress'),
    Port = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { port = value }
        self.m_kerberos_config:set_port(value)
    end, 'KerberosPort'),
    Realm = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { realm = value }
        self.m_kerberos_config:set_realm(value)
    end, 'KerberosRealm')
}

function KerberosConfigMdb:watch_config_property(config)
    config[INTERFACE_KERBEROS].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the kerberos config property(%s) to value(%s), sender is nil', name, tostring(value))
            return true
        end

        if not self.watch_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('change the kerberos config property(%s) to value(%s)', name, tostring(value))
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_property_hook[name](self, ctx, value)
        return true
    end)
end

function KerberosConfigMdb:new_config_to_mdb_tree(kerberos_config)
    local mdb_config = cls_mng('Kerberos'):get(PATH_KERBEROS)
    mdb_config[INTERFACE_KERBEROS].Enabled = kerberos_config.Enabled
    mdb_config[INTERFACE_KERBEROS].Address = kerberos_config.Address
    mdb_config[INTERFACE_KERBEROS].Port = kerberos_config.Port
    mdb_config[INTERFACE_KERBEROS].Realm = kerberos_config.Realm
    self:watch_config_property(mdb_config)
    self.m_mdb_config = mdb_config
end

function KerberosConfigMdb:import_key_table(path)
    self.m_kerberos_config:import_key_table(path)
end

return singleton(KerberosConfigMdb)
