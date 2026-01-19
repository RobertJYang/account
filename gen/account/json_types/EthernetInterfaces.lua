-- Copyright (c) 2026 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local validate = require 'mc.validate'
local utils = require 'mc.utils'
local mdb = require 'mc.mdb'

local EthernetInterfaces = {}

---@class EthernetInterfaces.Port
---@field Id integer
---@field EthId integer
---@field DeviceId integer
---@field DevicePortId integer
---@field Silkscreen string
---@field Type string
---@field AdaptiveFlag boolean
---@field LinkStatus string
---@field Mac string
local TPort = {}
TPort.__index = TPort
TPort.group = {}

local function TPort_from_obj(obj)
    return setmetatable(obj, TPort)
end

function TPort.new(Id, EthId, DeviceId, DevicePortId, Silkscreen, Type, AdaptiveFlag, LinkStatus, Mac)
    return TPort_from_obj({
        Id = Id,
        EthId = EthId,
        DeviceId = DeviceId,
        DevicePortId = DevicePortId,
        Silkscreen = Silkscreen,
        Type = Type,
        AdaptiveFlag = AdaptiveFlag,
        LinkStatus = LinkStatus,
        Mac = Mac
    })
end
---@param obj EthernetInterfaces.Port
function TPort:init_from_obj(obj)
    self.Id = obj.Id
    self.EthId = obj.EthId
    self.DeviceId = obj.DeviceId
    self.DevicePortId = obj.DevicePortId
    self.Silkscreen = obj.Silkscreen
    self.Type = obj.Type
    self.AdaptiveFlag = obj.AdaptiveFlag
    self.LinkStatus = obj.LinkStatus
    self.Mac = obj.Mac
end

function TPort:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPort.group)
end

TPort.from_obj = TPort_from_obj

TPort.proto_property = {
    'Id', 'EthId', 'DeviceId', 'DevicePortId', 'Silkscreen', 'Type', 'AdaptiveFlag', 'LinkStatus', 'Mac'
}

TPort.default = {0, 0, 0, 0, '', '', false, '', ''}

TPort.struct = {
    {name = 'Id', is_array = false, struct = nil}, {name = 'EthId', is_array = false, struct = nil},
    {name = 'DeviceId', is_array = false, struct = nil}, {name = 'DevicePortId', is_array = false, struct = nil},
    {name = 'Silkscreen', is_array = false, struct = nil}, {name = 'Type', is_array = false, struct = nil},
    {name = 'AdaptiveFlag', is_array = false, struct = nil}, {name = 'LinkStatus', is_array = false, struct = nil},
    {name = 'Mac', is_array = false, struct = nil}
}

function TPort:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Id', self.Id, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'EthId', self.EthId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'DeviceId', self.DeviceId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'DevicePortId', self.DevicePortId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Silkscreen', self.Silkscreen, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Type', self.Type, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'AdaptiveFlag', self.AdaptiveFlag, 'bool', false, errs, need_convert)
    validate.Optional(prefix .. 'LinkStatus', self.LinkStatus, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Mac', self.Mac, 'string', false, errs, need_convert)

    TPort:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPort.proto_property, errs, need_convert)
    return self
end

function TPort:unpack(_)
    return self.Id, self.EthId, self.DeviceId, self.DevicePortId, self.Silkscreen, self.Type, self.AdaptiveFlag,
        self.LinkStatus, self.Mac
end

EthernetInterfaces.Port = TPort

---@class EthernetInterfaces.SetChassisLanSubNetRsp
local TSetChassisLanSubNetRsp = {}
TSetChassisLanSubNetRsp.__index = TSetChassisLanSubNetRsp
TSetChassisLanSubNetRsp.group = {}

local function TSetChassisLanSubNetRsp_from_obj(obj)
    return setmetatable(obj, TSetChassisLanSubNetRsp)
end

function TSetChassisLanSubNetRsp.new()
    return TSetChassisLanSubNetRsp_from_obj({})
end
---@param obj EthernetInterfaces.SetChassisLanSubNetRsp
function TSetChassisLanSubNetRsp:init_from_obj(obj)

end

function TSetChassisLanSubNetRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetChassisLanSubNetRsp.group)
end

TSetChassisLanSubNetRsp.from_obj = TSetChassisLanSubNetRsp_from_obj

TSetChassisLanSubNetRsp.proto_property = {}

TSetChassisLanSubNetRsp.default = {}

TSetChassisLanSubNetRsp.struct = {}

function TSetChassisLanSubNetRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetChassisLanSubNetRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetChassisLanSubNetRsp.proto_property, errs, need_convert)
    return self
end

function TSetChassisLanSubNetRsp:unpack(_)
end

EthernetInterfaces.SetChassisLanSubNetRsp = TSetChassisLanSubNetRsp

---@class EthernetInterfaces.SetChassisLanSubNetReq
---@field ChassisLanSubNet string
local TSetChassisLanSubNetReq = {}
TSetChassisLanSubNetReq.__index = TSetChassisLanSubNetReq
TSetChassisLanSubNetReq.group = {}

local function TSetChassisLanSubNetReq_from_obj(obj)
    return setmetatable(obj, TSetChassisLanSubNetReq)
end

function TSetChassisLanSubNetReq.new(ChassisLanSubNet)
    return TSetChassisLanSubNetReq_from_obj({ChassisLanSubNet = ChassisLanSubNet})
end
---@param obj EthernetInterfaces.SetChassisLanSubNetReq
function TSetChassisLanSubNetReq:init_from_obj(obj)
    self.ChassisLanSubNet = obj.ChassisLanSubNet
end

function TSetChassisLanSubNetReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetChassisLanSubNetReq.group)
end

TSetChassisLanSubNetReq.from_obj = TSetChassisLanSubNetReq_from_obj

TSetChassisLanSubNetReq.proto_property = {'ChassisLanSubNet'}

TSetChassisLanSubNetReq.default = {''}

TSetChassisLanSubNetReq.struct = {{name = 'ChassisLanSubNet', is_array = false, struct = nil}}

function TSetChassisLanSubNetReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ChassisLanSubNet', self.ChassisLanSubNet, 'string', false, errs, need_convert)

    TSetChassisLanSubNetReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetChassisLanSubNetReq.proto_property, errs, need_convert)
    return self
end

function TSetChassisLanSubNetReq:unpack(_)
    return self.ChassisLanSubNet
end

EthernetInterfaces.SetChassisLanSubNetReq = TSetChassisLanSubNetReq

---@class EthernetInterfaces.NetworkFailoverRsp
---@field Result boolean
local TNetworkFailoverRsp = {}
TNetworkFailoverRsp.__index = TNetworkFailoverRsp
TNetworkFailoverRsp.group = {}

local function TNetworkFailoverRsp_from_obj(obj)
    return setmetatable(obj, TNetworkFailoverRsp)
end

function TNetworkFailoverRsp.new(Result)
    return TNetworkFailoverRsp_from_obj({Result = Result})
end
---@param obj EthernetInterfaces.NetworkFailoverRsp
function TNetworkFailoverRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TNetworkFailoverRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TNetworkFailoverRsp.group)
end

TNetworkFailoverRsp.from_obj = TNetworkFailoverRsp_from_obj

TNetworkFailoverRsp.proto_property = {'Result'}

TNetworkFailoverRsp.default = {false}

TNetworkFailoverRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TNetworkFailoverRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TNetworkFailoverRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNetworkFailoverRsp.proto_property, errs, need_convert)
    return self
end

function TNetworkFailoverRsp:unpack(_)
    return self.Result
end

EthernetInterfaces.NetworkFailoverRsp = TNetworkFailoverRsp

---@class EthernetInterfaces.NetworkFailoverReq
---@field From string
---@field To string
local TNetworkFailoverReq = {}
TNetworkFailoverReq.__index = TNetworkFailoverReq
TNetworkFailoverReq.group = {}

local function TNetworkFailoverReq_from_obj(obj)
    return setmetatable(obj, TNetworkFailoverReq)
end

function TNetworkFailoverReq.new(From, To)
    return TNetworkFailoverReq_from_obj({From = From, To = To})
end
---@param obj EthernetInterfaces.NetworkFailoverReq
function TNetworkFailoverReq:init_from_obj(obj)
    self.From = obj.From
    self.To = obj.To
end

function TNetworkFailoverReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TNetworkFailoverReq.group)
end

TNetworkFailoverReq.from_obj = TNetworkFailoverReq_from_obj

TNetworkFailoverReq.proto_property = {'From', 'To'}

TNetworkFailoverReq.default = {'', ''}

TNetworkFailoverReq.struct = {
    {name = 'From', is_array = false, struct = nil}, {name = 'To', is_array = false, struct = nil}
}

function TNetworkFailoverReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'From', self.From, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'To', self.To, 'string', false, errs, need_convert)

    TNetworkFailoverReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNetworkFailoverReq.proto_property, errs, need_convert)
    return self
end

function TNetworkFailoverReq:unpack(_)
    return self.From, self.To
end

EthernetInterfaces.NetworkFailoverReq = TNetworkFailoverReq

---@class EthernetInterfaces.SetEthStateRsp
---@field Result boolean
local TSetEthStateRsp = {}
TSetEthStateRsp.__index = TSetEthStateRsp
TSetEthStateRsp.group = {}

local function TSetEthStateRsp_from_obj(obj)
    return setmetatable(obj, TSetEthStateRsp)
end

function TSetEthStateRsp.new(Result)
    return TSetEthStateRsp_from_obj({Result = Result})
end
---@param obj EthernetInterfaces.SetEthStateRsp
function TSetEthStateRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TSetEthStateRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetEthStateRsp.group)
end

TSetEthStateRsp.from_obj = TSetEthStateRsp_from_obj

TSetEthStateRsp.proto_property = {'Result'}

TSetEthStateRsp.default = {false}

TSetEthStateRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TSetEthStateRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TSetEthStateRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetEthStateRsp.proto_property, errs, need_convert)
    return self
end

function TSetEthStateRsp:unpack(_)
    return self.Result
end

EthernetInterfaces.SetEthStateRsp = TSetEthStateRsp

---@class EthernetInterfaces.SetEthStateReq
---@field EthName string
---@field EthEnabled boolean
local TSetEthStateReq = {}
TSetEthStateReq.__index = TSetEthStateReq
TSetEthStateReq.group = {}

local function TSetEthStateReq_from_obj(obj)
    return setmetatable(obj, TSetEthStateReq)
end

function TSetEthStateReq.new(EthName, EthEnabled)
    return TSetEthStateReq_from_obj({EthName = EthName, EthEnabled = EthEnabled})
end
---@param obj EthernetInterfaces.SetEthStateReq
function TSetEthStateReq:init_from_obj(obj)
    self.EthName = obj.EthName
    self.EthEnabled = obj.EthEnabled
end

function TSetEthStateReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetEthStateReq.group)
end

TSetEthStateReq.from_obj = TSetEthStateReq_from_obj

TSetEthStateReq.proto_property = {'EthName', 'EthEnabled'}

TSetEthStateReq.default = {'', false}

TSetEthStateReq.struct = {
    {name = 'EthName', is_array = false, struct = nil}, {name = 'EthEnabled', is_array = false, struct = nil}
}

function TSetEthStateReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EthName', self.EthName, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'EthEnabled', self.EthEnabled, 'bool', false, errs, need_convert)

    TSetEthStateReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetEthStateReq.proto_property, errs, need_convert)
    return self
end

function TSetEthStateReq:unpack(_)
    return self.EthName, self.EthEnabled
end

EthernetInterfaces.SetEthStateReq = TSetEthStateReq

---@class EthernetInterfaces.SetVLANConfigRsp
---@field Result boolean
local TSetVLANConfigRsp = {}
TSetVLANConfigRsp.__index = TSetVLANConfigRsp
TSetVLANConfigRsp.group = {}

local function TSetVLANConfigRsp_from_obj(obj)
    return setmetatable(obj, TSetVLANConfigRsp)
end

function TSetVLANConfigRsp.new(Result)
    return TSetVLANConfigRsp_from_obj({Result = Result})
end
---@param obj EthernetInterfaces.SetVLANConfigRsp
function TSetVLANConfigRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TSetVLANConfigRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetVLANConfigRsp.group)
end

TSetVLANConfigRsp.from_obj = TSetVLANConfigRsp_from_obj

TSetVLANConfigRsp.proto_property = {'Result'}

TSetVLANConfigRsp.default = {false}

TSetVLANConfigRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TSetVLANConfigRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TSetVLANConfigRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetVLANConfigRsp.proto_property, errs, need_convert)
    return self
end

function TSetVLANConfigRsp:unpack(_)
    return self.Result
end

EthernetInterfaces.SetVLANConfigRsp = TSetVLANConfigRsp

---@class EthernetInterfaces.SetVLANConfigReq
---@field VLANEnabled boolean
---@field VLANId integer
---@field PortType integer
local TSetVLANConfigReq = {}
TSetVLANConfigReq.__index = TSetVLANConfigReq
TSetVLANConfigReq.group = {}

local function TSetVLANConfigReq_from_obj(obj)
    return setmetatable(obj, TSetVLANConfigReq)
end

function TSetVLANConfigReq.new(VLANEnabled, VLANId, PortType)
    return TSetVLANConfigReq_from_obj({VLANEnabled = VLANEnabled, VLANId = VLANId, PortType = PortType})
end
---@param obj EthernetInterfaces.SetVLANConfigReq
function TSetVLANConfigReq:init_from_obj(obj)
    self.VLANEnabled = obj.VLANEnabled
    self.VLANId = obj.VLANId
    self.PortType = obj.PortType
end

function TSetVLANConfigReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetVLANConfigReq.group)
end

TSetVLANConfigReq.from_obj = TSetVLANConfigReq_from_obj

TSetVLANConfigReq.proto_property = {'VLANEnabled', 'VLANId', 'PortType'}

TSetVLANConfigReq.default = {false, 0, 0}

TSetVLANConfigReq.struct = {
    {name = 'VLANEnabled', is_array = false, struct = nil}, {name = 'VLANId', is_array = false, struct = nil},
    {name = 'PortType', is_array = false, struct = nil}
}

function TSetVLANConfigReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'VLANEnabled', self.VLANEnabled, 'bool', false, errs, need_convert)
    validate.Optional(prefix .. 'VLANId', self.VLANId, 'uint16', false, errs, need_convert)
    validate.Optional(prefix .. 'PortType', self.PortType, 'uint8', false, errs, need_convert)

    TSetVLANConfigReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetVLANConfigReq.proto_property, errs, need_convert)
    return self
end

function TSetVLANConfigReq:unpack(_)
    return self.VLANEnabled, self.VLANId, self.PortType
end

EthernetInterfaces.SetVLANConfigReq = TSetVLANConfigReq

---@class EthernetInterfaces.AddIp6tablesRuleRsp
---@field Result boolean
local TAddIp6tablesRuleRsp = {}
TAddIp6tablesRuleRsp.__index = TAddIp6tablesRuleRsp
TAddIp6tablesRuleRsp.group = {}

local function TAddIp6tablesRuleRsp_from_obj(obj)
    return setmetatable(obj, TAddIp6tablesRuleRsp)
end

function TAddIp6tablesRuleRsp.new(Result)
    return TAddIp6tablesRuleRsp_from_obj({Result = Result})
end
---@param obj EthernetInterfaces.AddIp6tablesRuleRsp
function TAddIp6tablesRuleRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TAddIp6tablesRuleRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddIp6tablesRuleRsp.group)
end

TAddIp6tablesRuleRsp.from_obj = TAddIp6tablesRuleRsp_from_obj

TAddIp6tablesRuleRsp.proto_property = {'Result'}

TAddIp6tablesRuleRsp.default = {false}

TAddIp6tablesRuleRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TAddIp6tablesRuleRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TAddIp6tablesRuleRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddIp6tablesRuleRsp.proto_property, errs, need_convert)
    return self
end

function TAddIp6tablesRuleRsp:unpack(_)
    return self.Result
end

EthernetInterfaces.AddIp6tablesRuleRsp = TAddIp6tablesRuleRsp

---@class EthernetInterfaces.AddIp6tablesRuleReq
---@field InterfaceName string
---@field Ipv6Addr string
local TAddIp6tablesRuleReq = {}
TAddIp6tablesRuleReq.__index = TAddIp6tablesRuleReq
TAddIp6tablesRuleReq.group = {}

local function TAddIp6tablesRuleReq_from_obj(obj)
    return setmetatable(obj, TAddIp6tablesRuleReq)
end

function TAddIp6tablesRuleReq.new(InterfaceName, Ipv6Addr)
    return TAddIp6tablesRuleReq_from_obj({InterfaceName = InterfaceName, Ipv6Addr = Ipv6Addr})
end
---@param obj EthernetInterfaces.AddIp6tablesRuleReq
function TAddIp6tablesRuleReq:init_from_obj(obj)
    self.InterfaceName = obj.InterfaceName
    self.Ipv6Addr = obj.Ipv6Addr
end

function TAddIp6tablesRuleReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddIp6tablesRuleReq.group)
end

TAddIp6tablesRuleReq.from_obj = TAddIp6tablesRuleReq_from_obj

TAddIp6tablesRuleReq.proto_property = {'InterfaceName', 'Ipv6Addr'}

TAddIp6tablesRuleReq.default = {'', ''}

TAddIp6tablesRuleReq.struct = {
    {name = 'InterfaceName', is_array = false, struct = nil}, {name = 'Ipv6Addr', is_array = false, struct = nil}
}

function TAddIp6tablesRuleReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'InterfaceName', self.InterfaceName, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Ipv6Addr', self.Ipv6Addr, 'string', false, errs, need_convert)

    TAddIp6tablesRuleReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddIp6tablesRuleReq.proto_property, errs, need_convert)
    return self
end

function TAddIp6tablesRuleReq:unpack(_)
    return self.InterfaceName, self.Ipv6Addr
end

EthernetInterfaces.AddIp6tablesRuleReq = TAddIp6tablesRuleReq

---@class EthernetInterfaces.AddIptablesRuleRsp
---@field Result boolean
local TAddIptablesRuleRsp = {}
TAddIptablesRuleRsp.__index = TAddIptablesRuleRsp
TAddIptablesRuleRsp.group = {}

local function TAddIptablesRuleRsp_from_obj(obj)
    return setmetatable(obj, TAddIptablesRuleRsp)
end

function TAddIptablesRuleRsp.new(Result)
    return TAddIptablesRuleRsp_from_obj({Result = Result})
end
---@param obj EthernetInterfaces.AddIptablesRuleRsp
function TAddIptablesRuleRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TAddIptablesRuleRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddIptablesRuleRsp.group)
end

TAddIptablesRuleRsp.from_obj = TAddIptablesRuleRsp_from_obj

TAddIptablesRuleRsp.proto_property = {'Result'}

TAddIptablesRuleRsp.default = {false}

TAddIptablesRuleRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TAddIptablesRuleRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TAddIptablesRuleRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddIptablesRuleRsp.proto_property, errs, need_convert)
    return self
end

function TAddIptablesRuleRsp:unpack(_)
    return self.Result
end

EthernetInterfaces.AddIptablesRuleRsp = TAddIptablesRuleRsp

---@class EthernetInterfaces.AddIptablesRuleReq
---@field InterfaceName string
---@field IpAddr string
local TAddIptablesRuleReq = {}
TAddIptablesRuleReq.__index = TAddIptablesRuleReq
TAddIptablesRuleReq.group = {}

local function TAddIptablesRuleReq_from_obj(obj)
    return setmetatable(obj, TAddIptablesRuleReq)
end

function TAddIptablesRuleReq.new(InterfaceName, IpAddr)
    return TAddIptablesRuleReq_from_obj({InterfaceName = InterfaceName, IpAddr = IpAddr})
end
---@param obj EthernetInterfaces.AddIptablesRuleReq
function TAddIptablesRuleReq:init_from_obj(obj)
    self.InterfaceName = obj.InterfaceName
    self.IpAddr = obj.IpAddr
end

function TAddIptablesRuleReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddIptablesRuleReq.group)
end

TAddIptablesRuleReq.from_obj = TAddIptablesRuleReq_from_obj

TAddIptablesRuleReq.proto_property = {'InterfaceName', 'IpAddr'}

TAddIptablesRuleReq.default = {'', ''}

TAddIptablesRuleReq.struct = {
    {name = 'InterfaceName', is_array = false, struct = nil}, {name = 'IpAddr', is_array = false, struct = nil}
}

function TAddIptablesRuleReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'InterfaceName', self.InterfaceName, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'IpAddr', self.IpAddr, 'string', false, errs, need_convert)

    TAddIptablesRuleReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddIptablesRuleReq.proto_property, errs, need_convert)
    return self
end

function TAddIptablesRuleReq:unpack(_)
    return self.InterfaceName, self.IpAddr
end

EthernetInterfaces.AddIptablesRuleReq = TAddIptablesRuleReq

---@class EthernetInterfaces.DeleteMgmtPortRsp
local TDeleteMgmtPortRsp = {}
TDeleteMgmtPortRsp.__index = TDeleteMgmtPortRsp
TDeleteMgmtPortRsp.group = {}

local function TDeleteMgmtPortRsp_from_obj(obj)
    return setmetatable(obj, TDeleteMgmtPortRsp)
end

function TDeleteMgmtPortRsp.new()
    return TDeleteMgmtPortRsp_from_obj({})
end
---@param obj EthernetInterfaces.DeleteMgmtPortRsp
function TDeleteMgmtPortRsp:init_from_obj(obj)

end

function TDeleteMgmtPortRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteMgmtPortRsp.group)
end

TDeleteMgmtPortRsp.from_obj = TDeleteMgmtPortRsp_from_obj

TDeleteMgmtPortRsp.proto_property = {}

TDeleteMgmtPortRsp.default = {}

TDeleteMgmtPortRsp.struct = {}

function TDeleteMgmtPortRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TDeleteMgmtPortRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteMgmtPortRsp.proto_property, errs, need_convert)
    return self
end

function TDeleteMgmtPortRsp:unpack(_)
end

EthernetInterfaces.DeleteMgmtPortRsp = TDeleteMgmtPortRsp

---@class EthernetInterfaces.DeleteMgmtPortReq
---@field PortId integer
local TDeleteMgmtPortReq = {}
TDeleteMgmtPortReq.__index = TDeleteMgmtPortReq
TDeleteMgmtPortReq.group = {}

local function TDeleteMgmtPortReq_from_obj(obj)
    return setmetatable(obj, TDeleteMgmtPortReq)
end

function TDeleteMgmtPortReq.new(PortId)
    return TDeleteMgmtPortReq_from_obj({PortId = PortId})
end
---@param obj EthernetInterfaces.DeleteMgmtPortReq
function TDeleteMgmtPortReq:init_from_obj(obj)
    self.PortId = obj.PortId
end

function TDeleteMgmtPortReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteMgmtPortReq.group)
end

TDeleteMgmtPortReq.from_obj = TDeleteMgmtPortReq_from_obj

TDeleteMgmtPortReq.proto_property = {'PortId'}

TDeleteMgmtPortReq.default = {0}

TDeleteMgmtPortReq.struct = {{name = 'PortId', is_array = false, struct = nil}}

function TDeleteMgmtPortReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PortId', self.PortId, 'uint8', false, errs, need_convert)

    TDeleteMgmtPortReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteMgmtPortReq.proto_property, errs, need_convert)
    return self
end

function TDeleteMgmtPortReq:unpack(_)
    return self.PortId
end

EthernetInterfaces.DeleteMgmtPortReq = TDeleteMgmtPortReq

---@class EthernetInterfaces.AddMgmtPortRsp
---@field PortId integer
local TAddMgmtPortRsp = {}
TAddMgmtPortRsp.__index = TAddMgmtPortRsp
TAddMgmtPortRsp.group = {}

local function TAddMgmtPortRsp_from_obj(obj)
    return setmetatable(obj, TAddMgmtPortRsp)
end

function TAddMgmtPortRsp.new(PortId)
    return TAddMgmtPortRsp_from_obj({PortId = PortId})
end
---@param obj EthernetInterfaces.AddMgmtPortRsp
function TAddMgmtPortRsp:init_from_obj(obj)
    self.PortId = obj.PortId
end

function TAddMgmtPortRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddMgmtPortRsp.group)
end

TAddMgmtPortRsp.from_obj = TAddMgmtPortRsp_from_obj

TAddMgmtPortRsp.proto_property = {'PortId'}

TAddMgmtPortRsp.default = {0}

TAddMgmtPortRsp.struct = {{name = 'PortId', is_array = false, struct = nil}}

function TAddMgmtPortRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PortId', self.PortId, 'uint8', false, errs, need_convert)

    TAddMgmtPortRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddMgmtPortRsp.proto_property, errs, need_convert)
    return self
end

function TAddMgmtPortRsp:unpack(_)
    return self.PortId
end

EthernetInterfaces.AddMgmtPortRsp = TAddMgmtPortRsp

---@class EthernetInterfaces.AddMgmtPortReq
---@field DeviceId integer
---@field DevicePortId integer
---@field Silkscreen string
---@field EthId integer
---@field Type string
---@field PortId integer
local TAddMgmtPortReq = {}
TAddMgmtPortReq.__index = TAddMgmtPortReq
TAddMgmtPortReq.group = {}

local function TAddMgmtPortReq_from_obj(obj)
    return setmetatable(obj, TAddMgmtPortReq)
end

function TAddMgmtPortReq.new(DeviceId, DevicePortId, Silkscreen, EthId, Type, PortId)
    return TAddMgmtPortReq_from_obj({
        DeviceId = DeviceId,
        DevicePortId = DevicePortId,
        Silkscreen = Silkscreen,
        EthId = EthId,
        Type = Type,
        PortId = PortId
    })
end
---@param obj EthernetInterfaces.AddMgmtPortReq
function TAddMgmtPortReq:init_from_obj(obj)
    self.DeviceId = obj.DeviceId
    self.DevicePortId = obj.DevicePortId
    self.Silkscreen = obj.Silkscreen
    self.EthId = obj.EthId
    self.Type = obj.Type
    self.PortId = obj.PortId
end

function TAddMgmtPortReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddMgmtPortReq.group)
end

TAddMgmtPortReq.from_obj = TAddMgmtPortReq_from_obj

TAddMgmtPortReq.proto_property = {'DeviceId', 'DevicePortId', 'Silkscreen', 'EthId', 'Type', 'PortId'}

TAddMgmtPortReq.default = {0, 0, '', 0, '', 0}

TAddMgmtPortReq.struct = {
    {name = 'DeviceId', is_array = false, struct = nil}, {name = 'DevicePortId', is_array = false, struct = nil},
    {name = 'Silkscreen', is_array = false, struct = nil}, {name = 'EthId', is_array = false, struct = nil},
    {name = 'Type', is_array = false, struct = nil}, {name = 'PortId', is_array = false, struct = nil}
}

function TAddMgmtPortReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DeviceId', self.DeviceId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'DevicePortId', self.DevicePortId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Silkscreen', self.Silkscreen, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'EthId', self.EthId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Type', self.Type, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'PortId', self.PortId, 'uint8', false, errs, need_convert)

    TAddMgmtPortReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddMgmtPortReq.proto_property, errs, need_convert)
    return self
end

function TAddMgmtPortReq:unpack(_)
    return self.DeviceId, self.DevicePortId, self.Silkscreen, self.EthId, self.Type, self.PortId
end

EthernetInterfaces.AddMgmtPortReq = TAddMgmtPortReq

---@class EthernetInterfaces.SetNetworkConfigRsp
local TSetNetworkConfigRsp = {}
TSetNetworkConfigRsp.__index = TSetNetworkConfigRsp
TSetNetworkConfigRsp.group = {}

local function TSetNetworkConfigRsp_from_obj(obj)
    return setmetatable(obj, TSetNetworkConfigRsp)
end

function TSetNetworkConfigRsp.new()
    return TSetNetworkConfigRsp_from_obj({})
end
---@param obj EthernetInterfaces.SetNetworkConfigRsp
function TSetNetworkConfigRsp:init_from_obj(obj)

end

function TSetNetworkConfigRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetNetworkConfigRsp.group)
end

TSetNetworkConfigRsp.from_obj = TSetNetworkConfigRsp_from_obj

TSetNetworkConfigRsp.proto_property = {}

TSetNetworkConfigRsp.default = {}

TSetNetworkConfigRsp.struct = {}

function TSetNetworkConfigRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetNetworkConfigRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetNetworkConfigRsp.proto_property, errs, need_convert)
    return self
end

function TSetNetworkConfigRsp:unpack(_)
end

EthernetInterfaces.SetNetworkConfigRsp = TSetNetworkConfigRsp

---@class EthernetInterfaces.SetNetworkConfigReq
---@field NetMode string
---@field PortId integer
---@field VLANEnable boolean
---@field VLANId integer
local TSetNetworkConfigReq = {}
TSetNetworkConfigReq.__index = TSetNetworkConfigReq
TSetNetworkConfigReq.group = {}

local function TSetNetworkConfigReq_from_obj(obj)
    return setmetatable(obj, TSetNetworkConfigReq)
end

function TSetNetworkConfigReq.new(NetMode, PortId, VLANEnable, VLANId)
    return TSetNetworkConfigReq_from_obj({NetMode = NetMode, PortId = PortId, VLANEnable = VLANEnable, VLANId = VLANId})
end
---@param obj EthernetInterfaces.SetNetworkConfigReq
function TSetNetworkConfigReq:init_from_obj(obj)
    self.NetMode = obj.NetMode
    self.PortId = obj.PortId
    self.VLANEnable = obj.VLANEnable
    self.VLANId = obj.VLANId
end

function TSetNetworkConfigReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetNetworkConfigReq.group)
end

TSetNetworkConfigReq.from_obj = TSetNetworkConfigReq_from_obj

TSetNetworkConfigReq.proto_property = {'NetMode', 'PortId', 'VLANEnable', 'VLANId'}

TSetNetworkConfigReq.default = {'', 0, false, 0}

TSetNetworkConfigReq.struct = {
    {name = 'NetMode', is_array = false, struct = nil}, {name = 'PortId', is_array = false, struct = nil},
    {name = 'VLANEnable', is_array = false, struct = nil}, {name = 'VLANId', is_array = false, struct = nil}
}

function TSetNetworkConfigReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'NetMode', self.NetMode, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'PortId', self.PortId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'VLANEnable', self.VLANEnable, 'bool', false, errs, need_convert)
    validate.Optional(prefix .. 'VLANId', self.VLANId, 'uint16', false, errs, need_convert)

    TSetNetworkConfigReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetNetworkConfigReq.proto_property, errs, need_convert)
    return self
end

function TSetNetworkConfigReq:unpack(_)
    return self.NetMode, self.PortId, self.VLANEnable, self.VLANId
end

EthernetInterfaces.SetNetworkConfigReq = TSetNetworkConfigReq

---@class EthernetInterfaces.GetAllPortRsp
---@field Port EthernetInterfaces.Port[]
local TGetAllPortRsp = {}
TGetAllPortRsp.__index = TGetAllPortRsp
TGetAllPortRsp.group = {}

local function TGetAllPortRsp_from_obj(obj)
    obj.Port = utils.from_obj(EthernetInterfaces.Port, obj.Port, true)
    return setmetatable(obj, TGetAllPortRsp)
end

function TGetAllPortRsp.new(Port)
    return TGetAllPortRsp_from_obj({Port = Port})
end
---@param obj EthernetInterfaces.GetAllPortRsp
function TGetAllPortRsp:init_from_obj(obj)
    self.Port = obj.Port
end

function TGetAllPortRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetAllPortRsp.group)
end

TGetAllPortRsp.from_obj = TGetAllPortRsp_from_obj

TGetAllPortRsp.proto_property = {'Port'}

TGetAllPortRsp.default = {{}}

TGetAllPortRsp.struct = {{name = 'Port', is_array = true, struct = EthernetInterfaces.Port.struct}}

function TGetAllPortRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.Port) do
        EthernetInterfaces.Port.new(v.Id, v.EthId, v.DeviceId, v.DevicePortId, v.Silkscreen, v.Type, v.AdaptiveFlag,
            v.LinkStatus, v.Mac):validate(prefix, errs, need_convert)
    end

    TGetAllPortRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetAllPortRsp.proto_property, errs, need_convert)
    return self
end

function TGetAllPortRsp:unpack(raw)
    return utils.unpack(raw, self.Port, true)
end

EthernetInterfaces.GetAllPortRsp = TGetAllPortRsp

---@class EthernetInterfaces.GetAllPortReq
local TGetAllPortReq = {}
TGetAllPortReq.__index = TGetAllPortReq
TGetAllPortReq.group = {}

local function TGetAllPortReq_from_obj(obj)
    return setmetatable(obj, TGetAllPortReq)
end

function TGetAllPortReq.new()
    return TGetAllPortReq_from_obj({})
end
---@param obj EthernetInterfaces.GetAllPortReq
function TGetAllPortReq:init_from_obj(obj)

end

function TGetAllPortReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetAllPortReq.group)
end

TGetAllPortReq.from_obj = TGetAllPortReq_from_obj

TGetAllPortReq.proto_property = {}

TGetAllPortReq.default = {}

TGetAllPortReq.struct = {}

function TGetAllPortReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TGetAllPortReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetAllPortReq.proto_property, errs, need_convert)
    return self
end

function TGetAllPortReq:unpack(_)
end

EthernetInterfaces.GetAllPortReq = TGetAllPortReq

EthernetInterfaces.interface = mdb.register_interface('bmc.kepler.Managers.EthernetInterfaces', {
    EthName = {'s', nil, true, nil},
    NetMode = {'s', {['emitsChangedSignal'] = 'false'}, false, nil},
    Mac = {'s', nil, true, nil},
    IpVersion = {'s', nil, false, nil},
    NcsiEnable = {'b', {['emitsChangedSignal'] = 'false'}, true, nil},
    PortId = {'y', {['emitsChangedSignal'] = 'false'}, true, nil},
    Status = {'b', {['emitsChangedSignal'] = 'true'}, true, nil},
    Channel = {'y', {['emitsChangedSignal'] = 'false'}, false, nil},
    VLANEnable = {'b', nil, true, nil},
    VLANId = {'q', nil, true, nil},
    MinVLANId = {'q', {['emitsChangedSignal'] = 'false'}, true, nil},
    MaxVLANId = {'q', {['emitsChangedSignal'] = 'false'}, true, nil},
    SLAACAddressList = {'as', nil, true, nil},
    LinkLocalAddress = {'s', nil, true, nil},
    BackupIpActivated = {'b', nil, true, nil},
    DefaultFactoryIpMode = {'s', nil, true, nil},
    DefaultFactoryIpAddr = {'s', nil, true, nil},
    DefaultFactoryIpv6Mode = {'s', nil, true, 'DHCPv6'},
    DefaultFactoryIpv6Addr = {'s', nil, true, nil},
    DefaultFactoryIpVersion = {'s', nil, true, 'IPv4AndIPv6'},
    Ipv6DynamicRouteRAPreferred = {'b', {['emitsChangedSignal'] = 'false'}, false, false},
    MTUSize = {'q', {['emitsChangedSignal'] = 'false'}, false, 1500}
}, {
    GetAllPort = {'a{ss}', 'a(yyyyssbss)', TGetAllPortReq, TGetAllPortRsp},
    SetNetworkConfig = {'a{ss}sybq', '', TSetNetworkConfigReq, TSetNetworkConfigRsp},
    AddMgmtPort = {'a{ss}yysysy', 'y', TAddMgmtPortReq, TAddMgmtPortRsp},
    DeleteMgmtPort = {'a{ss}y', '', TDeleteMgmtPortReq, TDeleteMgmtPortRsp},
    AddIptablesRule = {'a{ss}ss', 'b', TAddIptablesRuleReq, TAddIptablesRuleRsp},
    AddIp6tablesRule = {'a{ss}ss', 'b', TAddIp6tablesRuleReq, TAddIp6tablesRuleRsp},
    SetVLANConfig = {'a{ss}bqy', 'b', TSetVLANConfigReq, TSetVLANConfigRsp},
    SetEthState = {'a{ss}sb', 'b', TSetEthStateReq, TSetEthStateRsp},
    NetworkFailover = {'a{ss}ss', 'b', TNetworkFailoverReq, TNetworkFailoverRsp},
    SetChassisLanSubNet = {'a{ss}s', '', TSetChassisLanSubNetReq, TSetChassisLanSubNetRsp}
}, {ActivePortChangedSignal = 'a{ss}yy', NCSIInfoChangedSignal = 'a{ss}a(ss)', EthMacChangedSignal = 'a{ss}ss'})

return EthernetInterfaces
