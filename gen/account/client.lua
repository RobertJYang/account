-- Copyright (c) 2026 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local app_base = require 'mc.client_app_base'
local mdb_service = require 'mc.mdb.mdb_service'
local subscribe_signal = require 'mc.mdb.subscribe_signal'
local org_freedesktop_dbus = require 'sd_bus.org_freedesktop_dbus'

local match_rule = org_freedesktop_dbus.MatchRule
local get_non_virtual_interface_objects = mdb_service.get_non_virtual_interface_objects
local foreach_non_virtual_interface_objects = mdb_service.foreach_non_virtual_interface_objects

local CipherSuit = require 'account.json_types.CipherSuit'
local FileTransfer = require 'account.json_types.FileTransfer'
local Task = require 'mdb.bmc.kepler.TaskService.TaskInterface'
local Ipv4 = require 'account.json_types.Ipv4'
local Ipv6 = require 'account.json_types.Ipv6'
local Events = require 'account.json_types.Events'
local IpmiCore = require 'account.json_types.IpmiCore'
local EthernetInterfaces = require 'account.json_types.EthernetInterfaces'
local Account = require 'account.json_types.Account'
local CA = require 'account.json_types.CA'
local Certificate = require 'account.json_types.Certificate'
local CertificateService = require 'account.json_types.CertificateService'
local File = require 'account.json_types.File'
local ChannelNumberMapping = require 'account.json_types.ChannelNumberMapping'

---@class account_client: BasicClient
local account_client = class(app_base.Client)

function account_client:GetCipherSuitObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.Security.TlsConfig.CipherSuit', true)
end

function account_client:ForeachCipherSuitObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.Security.TlsConfig.CipherSuit',
        cb, true)
end

function account_client:GetFileTransferObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.FileTransfer', true)
end

function account_client:ForeachFileTransferObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.FileTransfer', cb, true)
end

function account_client:GetTaskObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.TaskService.Task', true)
end

function account_client:ForeachTaskObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.TaskService.Task', cb, true)
end

function account_client:GetIpv4Objects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.EthernetInterfaces.Ipv4', true)
end

function account_client:ForeachIpv4Objects(cb)
    return
        foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.EthernetInterfaces.Ipv4', cb, true)
end

function account_client:GetIpv6Objects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.EthernetInterfaces.Ipv6', true)
end

function account_client:ForeachIpv6Objects(cb)
    return
        foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.EthernetInterfaces.Ipv6', cb, true)
end

function account_client:GetEventsObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Systems.Events', true)
end

function account_client:ForeachEventsObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Systems.Events', cb, true)
end

function account_client:GetIpmiCoreObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.IpmiCore', true)
end

function account_client:ForeachIpmiCoreObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.IpmiCore', cb, true)
end

function account_client:GetEthernetInterfacesObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.EthernetInterfaces', true)
end

function account_client:ForeachEthernetInterfacesObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.EthernetInterfaces', cb, true)
end

function account_client:GetAccountObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.CertificateService.Certificate.Account', true)
end

function account_client:ForeachAccountObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.CertificateService.Certificate.Account',
        cb, true)
end

function account_client:GetCAObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.CertificateService.CA', true)
end

function account_client:ForeachCAObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.CertificateService.CA', cb, true)
end

function account_client:GetCertificateObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.CertificateService.Certificate', true)
end

function account_client:ForeachCertificateObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.CertificateService.Certificate', cb, true)
end

function account_client:GetCertificateServiceObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.CertificateService', true)
end

function account_client:ForeachCertificateServiceObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.CertificateService', cb, true)
end

function account_client:GetFileObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.Security.File', true)
end

function account_client:ForeachFileObjects(cb)
    return foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.Managers.Security.File', cb, true)
end

function account_client:GetChannelNumberMappingObjects()
    return get_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.IpmiService.ChannelNumberMapping', true)
end

function account_client:ForeachChannelNumberMappingObjects(cb)
    return
        foreach_non_virtual_interface_objects(self:get_bus(), 'bmc.kepler.IpmiService.ChannelNumberMapping', cb, true)
end

function account_client:OnCipherSuitPropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.Security.TlsConfig.CipherSuit')
end

function account_client:OnCipherSuitInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.Security.TlsConfig.CipherSuit')
end

function account_client:OnCipherSuitInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.Security.TlsConfig.CipherSuit')
end

function account_client:OnFileTransferPropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.FileTransfer')
end

function account_client:OnFileTransferInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.FileTransfer')
end

function account_client:OnFileTransferInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.FileTransfer')
end

function account_client:OnTaskPropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.TaskService.Task')
end

function account_client:OnTaskInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.TaskService.Task')
end

function account_client:OnTaskInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.TaskService.Task')
end

function account_client:OnIpv4PropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.EthernetInterfaces.Ipv4')
end

function account_client:OnIpv4InterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.EthernetInterfaces.Ipv4')
end

function account_client:OnIpv4InterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.EthernetInterfaces.Ipv4')
end

function account_client:OnIpv6PropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.EthernetInterfaces.Ipv6')
end

function account_client:OnIpv6InterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.EthernetInterfaces.Ipv6')
end

function account_client:OnIpv6InterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.EthernetInterfaces.Ipv6')
end

function account_client:OnEventsPropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Systems.Events')
end

function account_client:OnEventsInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Systems.Events')
end

function account_client:OnEventsInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Systems.Events')
end

function account_client:OnIpmiCorePropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.IpmiCore')
end

function account_client:OnIpmiCoreInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.IpmiCore')
end

function account_client:OnIpmiCoreInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.IpmiCore')
end

function account_client:OnEthernetInterfacesPropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.EthernetInterfaces')
end

function account_client:OnEthernetInterfacesInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.EthernetInterfaces')
end

function account_client:OnEthernetInterfacesInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.EthernetInterfaces')
end

function account_client:OnAccountPropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService.Certificate.Account')
end

function account_client:OnAccountInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService.Certificate.Account')
end

function account_client:OnAccountInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService.Certificate.Account')
end

function account_client:OnCAPropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService.CA')
end

function account_client:OnCAInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService.CA')
end

function account_client:OnCAInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService.CA')
end

function account_client:OnCertificatePropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService.Certificate')
end

function account_client:OnCertificateInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService.Certificate')
end

function account_client:OnCertificateInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService.Certificate')
end

function account_client:OnCertificateServicePropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService')
end

function account_client:OnCertificateServiceInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService')
end

function account_client:OnCertificateServiceInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.CertificateService')
end

function account_client:OnFilePropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.Security.File')
end

function account_client:OnFileInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.Security.File')
end

function account_client:OnFileInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.Managers.Security.File')
end

function account_client:OnChannelNumberMappingPropertiesChanged(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_properties_changed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.IpmiService.ChannelNumberMapping', {'External'})
end

function account_client:OnChannelNumberMappingInterfacesAdded(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_added(self:get_bus(), '/bmc', cb,
        'bmc.kepler.IpmiService.ChannelNumberMapping')
end

function account_client:OnChannelNumberMappingInterfacesRemoved(cb)
    self.signal_slots[#self.signal_slots + 1] = subscribe_signal.on_interfaces_removed(self:get_bus(), '/bmc', cb,
        'bmc.kepler.IpmiService.ChannelNumberMapping')
end

function account_client:SubscribeIpv4ChangedSignal(cb)
    local sig = match_rule.signal('ChangedSignal', 'bmc.kepler.Managers.EthernetInterfaces.Ipv4')
    self.signal_slots[#self.signal_slots + 1] = self:get_bus():match(sig, function(msg)
        cb(msg:read())
    end)
end

function account_client:SubscribeIpv6ChangedSignal(cb)
    local sig = match_rule.signal('ChangedSignal', 'bmc.kepler.Managers.EthernetInterfaces.Ipv6')
    self.signal_slots[#self.signal_slots + 1] = self:get_bus():match(sig, function(msg)
        cb(msg:read())
    end)
end

function account_client:SubscribeEthernetInterfacesActivePortChangedSignal(cb)
    local sig = match_rule.signal('ActivePortChangedSignal', 'bmc.kepler.Managers.EthernetInterfaces')
    self.signal_slots[#self.signal_slots + 1] = self:get_bus():match(sig, function(msg)
        cb(msg:read())
    end)
end

function account_client:SubscribeEthernetInterfacesNCSIInfoChangedSignal(cb)
    local sig = match_rule.signal('NCSIInfoChangedSignal', 'bmc.kepler.Managers.EthernetInterfaces')
    self.signal_slots[#self.signal_slots + 1] = self:get_bus():match(sig, function(msg)
        cb(msg:read())
    end)
end

function account_client:SubscribeEthernetInterfacesEthMacChangedSignal(cb)
    local sig = match_rule.signal('EthMacChangedSignal', 'bmc.kepler.Managers.EthernetInterfaces')
    self.signal_slots[#self.signal_slots + 1] = self:get_bus():match(sig, function(msg)
        cb(msg:read())
    end)
end

function account_client:ctor()
    self.signal_slots = {}
end

---@type account_client
return account_client.new('account')
