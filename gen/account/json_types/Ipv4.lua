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

local Ipv4 = {}

---@class Ipv4.SetDedicatedMaintIpMaskRsp
---@field Result boolean
local TSetDedicatedMaintIpMaskRsp = {}
TSetDedicatedMaintIpMaskRsp.__index = TSetDedicatedMaintIpMaskRsp
TSetDedicatedMaintIpMaskRsp.group = {}

local function TSetDedicatedMaintIpMaskRsp_from_obj(obj)
    return setmetatable(obj, TSetDedicatedMaintIpMaskRsp)
end

function TSetDedicatedMaintIpMaskRsp.new(Result)
    return TSetDedicatedMaintIpMaskRsp_from_obj({Result = Result})
end
---@param obj Ipv4.SetDedicatedMaintIpMaskRsp
function TSetDedicatedMaintIpMaskRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TSetDedicatedMaintIpMaskRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetDedicatedMaintIpMaskRsp.group)
end

TSetDedicatedMaintIpMaskRsp.from_obj = TSetDedicatedMaintIpMaskRsp_from_obj

TSetDedicatedMaintIpMaskRsp.proto_property = {'Result'}

TSetDedicatedMaintIpMaskRsp.default = {false}

TSetDedicatedMaintIpMaskRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TSetDedicatedMaintIpMaskRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TSetDedicatedMaintIpMaskRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetDedicatedMaintIpMaskRsp.proto_property, errs, need_convert)
    return self
end

function TSetDedicatedMaintIpMaskRsp:unpack(_)
    return self.Result
end

Ipv4.SetDedicatedMaintIpMaskRsp = TSetDedicatedMaintIpMaskRsp

---@class Ipv4.SetDedicatedMaintIpMaskReq
---@field IpAddr string
---@field SubnetMask string
local TSetDedicatedMaintIpMaskReq = {}
TSetDedicatedMaintIpMaskReq.__index = TSetDedicatedMaintIpMaskReq
TSetDedicatedMaintIpMaskReq.group = {}

local function TSetDedicatedMaintIpMaskReq_from_obj(obj)
    return setmetatable(obj, TSetDedicatedMaintIpMaskReq)
end

function TSetDedicatedMaintIpMaskReq.new(IpAddr, SubnetMask)
    return TSetDedicatedMaintIpMaskReq_from_obj({IpAddr = IpAddr, SubnetMask = SubnetMask})
end
---@param obj Ipv4.SetDedicatedMaintIpMaskReq
function TSetDedicatedMaintIpMaskReq:init_from_obj(obj)
    self.IpAddr = obj.IpAddr
    self.SubnetMask = obj.SubnetMask
end

function TSetDedicatedMaintIpMaskReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetDedicatedMaintIpMaskReq.group)
end

TSetDedicatedMaintIpMaskReq.from_obj = TSetDedicatedMaintIpMaskReq_from_obj

TSetDedicatedMaintIpMaskReq.proto_property = {'IpAddr', 'SubnetMask'}

TSetDedicatedMaintIpMaskReq.default = {'', ''}

TSetDedicatedMaintIpMaskReq.struct = {
    {name = 'IpAddr', is_array = false, struct = nil}, {name = 'SubnetMask', is_array = false, struct = nil}
}

function TSetDedicatedMaintIpMaskReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpAddr', self.IpAddr, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'SubnetMask', self.SubnetMask, 'string', false, errs, need_convert)

    TSetDedicatedMaintIpMaskReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetDedicatedMaintIpMaskReq.proto_property, errs, need_convert)
    return self
end

function TSetDedicatedMaintIpMaskReq:unpack(_)
    return self.IpAddr, self.SubnetMask
end

Ipv4.SetDedicatedMaintIpMaskReq = TSetDedicatedMaintIpMaskReq

---@class Ipv4.SetDefaultGatewayRsp
---@field Result boolean
local TSetDefaultGatewayRsp = {}
TSetDefaultGatewayRsp.__index = TSetDefaultGatewayRsp
TSetDefaultGatewayRsp.group = {}

local function TSetDefaultGatewayRsp_from_obj(obj)
    return setmetatable(obj, TSetDefaultGatewayRsp)
end

function TSetDefaultGatewayRsp.new(Result)
    return TSetDefaultGatewayRsp_from_obj({Result = Result})
end
---@param obj Ipv4.SetDefaultGatewayRsp
function TSetDefaultGatewayRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TSetDefaultGatewayRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetDefaultGatewayRsp.group)
end

TSetDefaultGatewayRsp.from_obj = TSetDefaultGatewayRsp_from_obj

TSetDefaultGatewayRsp.proto_property = {'Result'}

TSetDefaultGatewayRsp.default = {false}

TSetDefaultGatewayRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TSetDefaultGatewayRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TSetDefaultGatewayRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetDefaultGatewayRsp.proto_property, errs, need_convert)
    return self
end

function TSetDefaultGatewayRsp:unpack(_)
    return self.Result
end

Ipv4.SetDefaultGatewayRsp = TSetDefaultGatewayRsp

---@class Ipv4.SetDefaultGatewayReq
---@field DefaultGateway string
local TSetDefaultGatewayReq = {}
TSetDefaultGatewayReq.__index = TSetDefaultGatewayReq
TSetDefaultGatewayReq.group = {}

local function TSetDefaultGatewayReq_from_obj(obj)
    return setmetatable(obj, TSetDefaultGatewayReq)
end

function TSetDefaultGatewayReq.new(DefaultGateway)
    return TSetDefaultGatewayReq_from_obj({DefaultGateway = DefaultGateway})
end
---@param obj Ipv4.SetDefaultGatewayReq
function TSetDefaultGatewayReq:init_from_obj(obj)
    self.DefaultGateway = obj.DefaultGateway
end

function TSetDefaultGatewayReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetDefaultGatewayReq.group)
end

TSetDefaultGatewayReq.from_obj = TSetDefaultGatewayReq_from_obj

TSetDefaultGatewayReq.proto_property = {'DefaultGateway'}

TSetDefaultGatewayReq.default = {''}

TSetDefaultGatewayReq.struct = {{name = 'DefaultGateway', is_array = false, struct = nil}}

function TSetDefaultGatewayReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DefaultGateway', self.DefaultGateway, 'string', false, errs, need_convert)

    TSetDefaultGatewayReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetDefaultGatewayReq.proto_property, errs, need_convert)
    return self
end

function TSetDefaultGatewayReq:unpack(_)
    return self.DefaultGateway
end

Ipv4.SetDefaultGatewayReq = TSetDefaultGatewayReq

---@class Ipv4.SetIpAddrRsp
---@field Result boolean
local TSetIpAddrRsp = {}
TSetIpAddrRsp.__index = TSetIpAddrRsp
TSetIpAddrRsp.group = {}

local function TSetIpAddrRsp_from_obj(obj)
    return setmetatable(obj, TSetIpAddrRsp)
end

function TSetIpAddrRsp.new(Result)
    return TSetIpAddrRsp_from_obj({Result = Result})
end
---@param obj Ipv4.SetIpAddrRsp
function TSetIpAddrRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TSetIpAddrRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetIpAddrRsp.group)
end

TSetIpAddrRsp.from_obj = TSetIpAddrRsp_from_obj

TSetIpAddrRsp.proto_property = {'Result'}

TSetIpAddrRsp.default = {false}

TSetIpAddrRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TSetIpAddrRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TSetIpAddrRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetIpAddrRsp.proto_property, errs, need_convert)
    return self
end

function TSetIpAddrRsp:unpack(_)
    return self.Result
end

Ipv4.SetIpAddrRsp = TSetIpAddrRsp

---@class Ipv4.SetIpAddrReq
---@field IpAddr string
---@field SubnetMask string
local TSetIpAddrReq = {}
TSetIpAddrReq.__index = TSetIpAddrReq
TSetIpAddrReq.group = {}

local function TSetIpAddrReq_from_obj(obj)
    return setmetatable(obj, TSetIpAddrReq)
end

function TSetIpAddrReq.new(IpAddr, SubnetMask)
    return TSetIpAddrReq_from_obj({IpAddr = IpAddr, SubnetMask = SubnetMask})
end
---@param obj Ipv4.SetIpAddrReq
function TSetIpAddrReq:init_from_obj(obj)
    self.IpAddr = obj.IpAddr
    self.SubnetMask = obj.SubnetMask
end

function TSetIpAddrReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetIpAddrReq.group)
end

TSetIpAddrReq.from_obj = TSetIpAddrReq_from_obj

TSetIpAddrReq.proto_property = {'IpAddr', 'SubnetMask'}

TSetIpAddrReq.default = {'', ''}

TSetIpAddrReq.struct = {
    {name = 'IpAddr', is_array = false, struct = nil}, {name = 'SubnetMask', is_array = false, struct = nil}
}

function TSetIpAddrReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpAddr', self.IpAddr, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'SubnetMask', self.SubnetMask, 'string', false, errs, need_convert)

    TSetIpAddrReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetIpAddrReq.proto_property, errs, need_convert)
    return self
end

function TSetIpAddrReq:unpack(_)
    return self.IpAddr, self.SubnetMask
end

Ipv4.SetIpAddrReq = TSetIpAddrReq

---@class Ipv4.SetIpMaskGatewayRsp
---@field IpAddr string
local TSetIpMaskGatewayRsp = {}
TSetIpMaskGatewayRsp.__index = TSetIpMaskGatewayRsp
TSetIpMaskGatewayRsp.group = {}

local function TSetIpMaskGatewayRsp_from_obj(obj)
    return setmetatable(obj, TSetIpMaskGatewayRsp)
end

function TSetIpMaskGatewayRsp.new(IpAddr)
    return TSetIpMaskGatewayRsp_from_obj({IpAddr = IpAddr})
end
---@param obj Ipv4.SetIpMaskGatewayRsp
function TSetIpMaskGatewayRsp:init_from_obj(obj)
    self.IpAddr = obj.IpAddr
end

function TSetIpMaskGatewayRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetIpMaskGatewayRsp.group)
end

TSetIpMaskGatewayRsp.from_obj = TSetIpMaskGatewayRsp_from_obj

TSetIpMaskGatewayRsp.proto_property = {'IpAddr'}

TSetIpMaskGatewayRsp.default = {''}

TSetIpMaskGatewayRsp.struct = {{name = 'IpAddr', is_array = false, struct = nil}}

function TSetIpMaskGatewayRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpAddr', self.IpAddr, 'string', false, errs, need_convert)

    TSetIpMaskGatewayRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetIpMaskGatewayRsp.proto_property, errs, need_convert)
    return self
end

function TSetIpMaskGatewayRsp:unpack(_)
    return self.IpAddr
end

Ipv4.SetIpMaskGatewayRsp = TSetIpMaskGatewayRsp

---@class Ipv4.SetIpMaskGatewayReq
---@field IpAddr string
---@field SubnetMask string
---@field DefaultGateway string
local TSetIpMaskGatewayReq = {}
TSetIpMaskGatewayReq.__index = TSetIpMaskGatewayReq
TSetIpMaskGatewayReq.group = {}

local function TSetIpMaskGatewayReq_from_obj(obj)
    return setmetatable(obj, TSetIpMaskGatewayReq)
end

function TSetIpMaskGatewayReq.new(IpAddr, SubnetMask, DefaultGateway)
    return TSetIpMaskGatewayReq_from_obj({IpAddr = IpAddr, SubnetMask = SubnetMask, DefaultGateway = DefaultGateway})
end
---@param obj Ipv4.SetIpMaskGatewayReq
function TSetIpMaskGatewayReq:init_from_obj(obj)
    self.IpAddr = obj.IpAddr
    self.SubnetMask = obj.SubnetMask
    self.DefaultGateway = obj.DefaultGateway
end

function TSetIpMaskGatewayReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetIpMaskGatewayReq.group)
end

TSetIpMaskGatewayReq.from_obj = TSetIpMaskGatewayReq_from_obj

TSetIpMaskGatewayReq.proto_property = {'IpAddr', 'SubnetMask', 'DefaultGateway'}

TSetIpMaskGatewayReq.default = {'', '', ''}

TSetIpMaskGatewayReq.struct = {
    {name = 'IpAddr', is_array = false, struct = nil}, {name = 'SubnetMask', is_array = false, struct = nil},
    {name = 'DefaultGateway', is_array = false, struct = nil}
}

function TSetIpMaskGatewayReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpAddr', self.IpAddr, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'SubnetMask', self.SubnetMask, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'DefaultGateway', self.DefaultGateway, 'string', false, errs, need_convert)

    TSetIpMaskGatewayReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetIpMaskGatewayReq.proto_property, errs, need_convert)
    return self
end

function TSetIpMaskGatewayReq:unpack(_)
    return self.IpAddr, self.SubnetMask, self.DefaultGateway
end

Ipv4.SetIpMaskGatewayReq = TSetIpMaskGatewayReq

Ipv4.interface = mdb.register_interface('bmc.kepler.Managers.EthernetInterfaces.Ipv4', {
    IpMode = {'s', nil, false, nil},
    IpAddr = {'s', nil, true, nil},
    BackupIpAddr = {'s', nil, false, nil},
    SubnetMask = {'s', nil, true, nil},
    BackupSubnetMask = {'s', nil, false, nil},
    DefaultGateway = {'s', nil, true, nil},
    LoopbackIpAddr = {'s', {['emitsChangedSignal'] = 'true'}, true, nil}
}, {
    SetIpMaskGateway = {'a{ss}sss', 's', TSetIpMaskGatewayReq, TSetIpMaskGatewayRsp},
    SetIpAddr = {'a{ss}ss', 'b', TSetIpAddrReq, TSetIpAddrRsp},
    SetDefaultGateway = {'a{ss}s', 'b', TSetDefaultGatewayReq, TSetDefaultGatewayRsp},
    SetDedicatedMaintIpMask = {'a{ss}ss', 'b', TSetDedicatedMaintIpMaskReq, TSetDedicatedMaintIpMaskRsp}
}, {ChangedSignal = 'a{ss}a(sss)'})

return Ipv4
