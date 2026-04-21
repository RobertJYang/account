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

local Ipv6 = {}

---@class Ipv6.SetDefaultGatewayRsp
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
---@param obj Ipv6.SetDefaultGatewayRsp
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

Ipv6.SetDefaultGatewayRsp = TSetDefaultGatewayRsp

---@class Ipv6.SetDefaultGatewayReq
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
---@param obj Ipv6.SetDefaultGatewayReq
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

Ipv6.SetDefaultGatewayReq = TSetDefaultGatewayReq

---@class Ipv6.SetIpAddrRsp
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
---@param obj Ipv6.SetIpAddrRsp
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

Ipv6.SetIpAddrRsp = TSetIpAddrRsp

---@class Ipv6.SetIpAddrReq
---@field IpAddr string
---@field PrefixLength integer
local TSetIpAddrReq = {}
TSetIpAddrReq.__index = TSetIpAddrReq
TSetIpAddrReq.group = {}

local function TSetIpAddrReq_from_obj(obj)
    return setmetatable(obj, TSetIpAddrReq)
end

function TSetIpAddrReq.new(IpAddr, PrefixLength)
    return TSetIpAddrReq_from_obj({IpAddr = IpAddr, PrefixLength = PrefixLength})
end
---@param obj Ipv6.SetIpAddrReq
function TSetIpAddrReq:init_from_obj(obj)
    self.IpAddr = obj.IpAddr
    self.PrefixLength = obj.PrefixLength
end

function TSetIpAddrReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetIpAddrReq.group)
end

TSetIpAddrReq.from_obj = TSetIpAddrReq_from_obj

TSetIpAddrReq.proto_property = {'IpAddr', 'PrefixLength'}

TSetIpAddrReq.default = {'', 0}

TSetIpAddrReq.struct = {
    {name = 'IpAddr', is_array = false, struct = nil}, {name = 'PrefixLength', is_array = false, struct = nil}
}

function TSetIpAddrReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpAddr', self.IpAddr, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'PrefixLength', self.PrefixLength, 'int32', false, errs, need_convert)

    TSetIpAddrReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetIpAddrReq.proto_property, errs, need_convert)
    return self
end

function TSetIpAddrReq:unpack(_)
    return self.IpAddr, self.PrefixLength
end

Ipv6.SetIpAddrReq = TSetIpAddrReq

---@class Ipv6.SetIpv6PrefixGatewayRsp
---@field IpAddr string
local TSetIpv6PrefixGatewayRsp = {}
TSetIpv6PrefixGatewayRsp.__index = TSetIpv6PrefixGatewayRsp
TSetIpv6PrefixGatewayRsp.group = {}

local function TSetIpv6PrefixGatewayRsp_from_obj(obj)
    return setmetatable(obj, TSetIpv6PrefixGatewayRsp)
end

function TSetIpv6PrefixGatewayRsp.new(IpAddr)
    return TSetIpv6PrefixGatewayRsp_from_obj({IpAddr = IpAddr})
end
---@param obj Ipv6.SetIpv6PrefixGatewayRsp
function TSetIpv6PrefixGatewayRsp:init_from_obj(obj)
    self.IpAddr = obj.IpAddr
end

function TSetIpv6PrefixGatewayRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetIpv6PrefixGatewayRsp.group)
end

TSetIpv6PrefixGatewayRsp.from_obj = TSetIpv6PrefixGatewayRsp_from_obj

TSetIpv6PrefixGatewayRsp.proto_property = {'IpAddr'}

TSetIpv6PrefixGatewayRsp.default = {''}

TSetIpv6PrefixGatewayRsp.struct = {{name = 'IpAddr', is_array = false, struct = nil}}

function TSetIpv6PrefixGatewayRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpAddr', self.IpAddr, 'string', false, errs, need_convert)

    TSetIpv6PrefixGatewayRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetIpv6PrefixGatewayRsp.proto_property, errs, need_convert)
    return self
end

function TSetIpv6PrefixGatewayRsp:unpack(_)
    return self.IpAddr
end

Ipv6.SetIpv6PrefixGatewayRsp = TSetIpv6PrefixGatewayRsp

---@class Ipv6.SetIpv6PrefixGatewayReq
---@field IpAddr string
---@field PrefixLength integer
---@field DefaultGateway string
local TSetIpv6PrefixGatewayReq = {}
TSetIpv6PrefixGatewayReq.__index = TSetIpv6PrefixGatewayReq
TSetIpv6PrefixGatewayReq.group = {}

local function TSetIpv6PrefixGatewayReq_from_obj(obj)
    return setmetatable(obj, TSetIpv6PrefixGatewayReq)
end

function TSetIpv6PrefixGatewayReq.new(IpAddr, PrefixLength, DefaultGateway)
    return TSetIpv6PrefixGatewayReq_from_obj({
        IpAddr = IpAddr,
        PrefixLength = PrefixLength,
        DefaultGateway = DefaultGateway
    })
end
---@param obj Ipv6.SetIpv6PrefixGatewayReq
function TSetIpv6PrefixGatewayReq:init_from_obj(obj)
    self.IpAddr = obj.IpAddr
    self.PrefixLength = obj.PrefixLength
    self.DefaultGateway = obj.DefaultGateway
end

function TSetIpv6PrefixGatewayReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetIpv6PrefixGatewayReq.group)
end

TSetIpv6PrefixGatewayReq.from_obj = TSetIpv6PrefixGatewayReq_from_obj

TSetIpv6PrefixGatewayReq.proto_property = {'IpAddr', 'PrefixLength', 'DefaultGateway'}

TSetIpv6PrefixGatewayReq.default = {'', 0, ''}

TSetIpv6PrefixGatewayReq.struct = {
    {name = 'IpAddr', is_array = false, struct = nil}, {name = 'PrefixLength', is_array = false, struct = nil},
    {name = 'DefaultGateway', is_array = false, struct = nil}
}

function TSetIpv6PrefixGatewayReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpAddr', self.IpAddr, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'PrefixLength', self.PrefixLength, 'int32', false, errs, need_convert)
    validate.Optional(prefix .. 'DefaultGateway', self.DefaultGateway, 'string', false, errs, need_convert)

    TSetIpv6PrefixGatewayReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetIpv6PrefixGatewayReq.proto_property, errs, need_convert)
    return self
end

function TSetIpv6PrefixGatewayReq:unpack(_)
    return self.IpAddr, self.PrefixLength, self.DefaultGateway
end

Ipv6.SetIpv6PrefixGatewayReq = TSetIpv6PrefixGatewayReq

Ipv6.interface = mdb.register_interface('bmc.kepler.Managers.EthernetInterfaces.Ipv6', {
    IpMode = {'s', nil, false, nil},
    IpAddr = {'s', nil, true, nil},
    PrefixLength = {'i', nil, true, nil},
    Scope = {'s', {['emitsChangedSignal'] = 'false'}, true, nil},
    DefaultGateway = {'s', nil, true, nil},
    LoopbackIpAddr = {'s', {['emitsChangedSignal'] = 'true'}, true, nil}
}, {
    SetIpv6PrefixGateway = {'a{ss}sis', 's', TSetIpv6PrefixGatewayReq, TSetIpv6PrefixGatewayRsp},
    SetIpAddr = {'a{ss}si', 'b', TSetIpAddrReq, TSetIpAddrRsp},
    SetDefaultGateway = {'a{ss}s', 'b', TSetDefaultGatewayReq, TSetDefaultGatewayRsp}
}, {ChangedSignal = 'a{ss}a(sss)'})

return Ipv6
