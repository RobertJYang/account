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

local IpmiCore = {}

---@class IpmiCore.ChannelInfo
---@field key string
---@field value integer
local TChannelInfo = {}
TChannelInfo.__index = TChannelInfo
TChannelInfo.group = {}

local function TChannelInfo_from_obj(obj)
    return setmetatable(obj, TChannelInfo)
end

function TChannelInfo.new(dict)
    return TChannelInfo_from_obj(dict)
end

---@param obj IpmiCore.ChannelInfo
function TChannelInfo:init_from_obj(obj)
    self = obj
end

function TChannelInfo:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TChannelInfo.group)
end

TChannelInfo.from_obj = TChannelInfo_from_obj

TChannelInfo.proto_property = {}

TChannelInfo.default = {}

TChannelInfo.struct = {}

function TChannelInfo:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for k, v in pairs(self) do

        validate.Optional(prefix .. 'key', k, 'string', false, errs, need_convert)

        validate.Optional(prefix .. 'value', v, 'uint8', false, errs, need_convert)

    end

    TChannelInfo:remove_error_props(errs, self)
    return self
end

function TChannelInfo:unpack(_)
    return self
end

IpmiCore.ChannelInfo = TChannelInfo

---@class IpmiCore.GetIPMIChannelRsp
---@field Channels IpmiCore.ChannelInfo[]
local TGetIPMIChannelRsp = {}
TGetIPMIChannelRsp.__index = TGetIPMIChannelRsp
TGetIPMIChannelRsp.group = {}

local function TGetIPMIChannelRsp_from_obj(obj)
    return setmetatable(obj, TGetIPMIChannelRsp)
end

function TGetIPMIChannelRsp.new(Channels)
    return TGetIPMIChannelRsp_from_obj({Channels = Channels})
end
---@param obj IpmiCore.GetIPMIChannelRsp
function TGetIPMIChannelRsp:init_from_obj(obj)
    self.Channels = obj.Channels
end

function TGetIPMIChannelRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetIPMIChannelRsp.group)
end

TGetIPMIChannelRsp.from_obj = TGetIPMIChannelRsp_from_obj

TGetIPMIChannelRsp.proto_property = {'Channels'}

TGetIPMIChannelRsp.default = {{}}

TGetIPMIChannelRsp.struct = {{name = 'Channels', is_array = true, struct = IpmiCore.ChannelInfo.struct}}

function TGetIPMIChannelRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.Channels) do
        IpmiCore.ChannelInfo.new(v):validate(prefix, errs, need_convert)
    end

    TGetIPMIChannelRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetIPMIChannelRsp.proto_property, errs, need_convert)
    return self
end

function TGetIPMIChannelRsp:unpack(_)
    return self.Channels
end

IpmiCore.GetIPMIChannelRsp = TGetIPMIChannelRsp

---@class IpmiCore.GetIPMIChannelReq
---@field ChannelNumber integer
local TGetIPMIChannelReq = {}
TGetIPMIChannelReq.__index = TGetIPMIChannelReq
TGetIPMIChannelReq.group = {}

local function TGetIPMIChannelReq_from_obj(obj)
    return setmetatable(obj, TGetIPMIChannelReq)
end

function TGetIPMIChannelReq.new(ChannelNumber)
    return TGetIPMIChannelReq_from_obj({ChannelNumber = ChannelNumber})
end
---@param obj IpmiCore.GetIPMIChannelReq
function TGetIPMIChannelReq:init_from_obj(obj)
    self.ChannelNumber = obj.ChannelNumber
end

function TGetIPMIChannelReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetIPMIChannelReq.group)
end

TGetIPMIChannelReq.from_obj = TGetIPMIChannelReq_from_obj

TGetIPMIChannelReq.proto_property = {'ChannelNumber'}

TGetIPMIChannelReq.default = {0}

TGetIPMIChannelReq.struct = {{name = 'ChannelNumber', is_array = false, struct = nil}}

function TGetIPMIChannelReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ChannelNumber', self.ChannelNumber, 'uint8', false, errs, need_convert)

    TGetIPMIChannelReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetIPMIChannelReq.proto_property, errs, need_convert)
    return self
end

function TGetIPMIChannelReq:unpack(_)
    return self.ChannelNumber
end

IpmiCore.GetIPMIChannelReq = TGetIPMIChannelReq

---@class IpmiCore.SetChannelAccessesRsp
local TSetChannelAccessesRsp = {}
TSetChannelAccessesRsp.__index = TSetChannelAccessesRsp
TSetChannelAccessesRsp.group = {}

local function TSetChannelAccessesRsp_from_obj(obj)
    return setmetatable(obj, TSetChannelAccessesRsp)
end

function TSetChannelAccessesRsp.new()
    return TSetChannelAccessesRsp_from_obj({})
end
---@param obj IpmiCore.SetChannelAccessesRsp
function TSetChannelAccessesRsp:init_from_obj(obj)

end

function TSetChannelAccessesRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetChannelAccessesRsp.group)
end

TSetChannelAccessesRsp.from_obj = TSetChannelAccessesRsp_from_obj

TSetChannelAccessesRsp.proto_property = {}

TSetChannelAccessesRsp.default = {}

TSetChannelAccessesRsp.struct = {}

function TSetChannelAccessesRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetChannelAccessesRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetChannelAccessesRsp.proto_property, errs, need_convert)
    return self
end

function TSetChannelAccessesRsp:unpack(_)
end

IpmiCore.SetChannelAccessesRsp = TSetChannelAccessesRsp

---@class IpmiCore.SetChannelAccessesReq
---@field ChannelType string
---@field AccessRole string
local TSetChannelAccessesReq = {}
TSetChannelAccessesReq.__index = TSetChannelAccessesReq
TSetChannelAccessesReq.group = {}

local function TSetChannelAccessesReq_from_obj(obj)
    return setmetatable(obj, TSetChannelAccessesReq)
end

function TSetChannelAccessesReq.new(ChannelType, AccessRole)
    return TSetChannelAccessesReq_from_obj({ChannelType = ChannelType, AccessRole = AccessRole})
end
---@param obj IpmiCore.SetChannelAccessesReq
function TSetChannelAccessesReq:init_from_obj(obj)
    self.ChannelType = obj.ChannelType
    self.AccessRole = obj.AccessRole
end

function TSetChannelAccessesReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetChannelAccessesReq.group)
end

TSetChannelAccessesReq.from_obj = TSetChannelAccessesReq_from_obj

TSetChannelAccessesReq.proto_property = {'ChannelType', 'AccessRole'}

TSetChannelAccessesReq.default = {'', ''}

TSetChannelAccessesReq.struct = {
    {name = 'ChannelType', is_array = false, struct = nil}, {name = 'AccessRole', is_array = false, struct = nil}
}

function TSetChannelAccessesReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ChannelType', self.ChannelType, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'AccessRole', self.AccessRole, 'string', false, errs, need_convert)

    TSetChannelAccessesReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetChannelAccessesReq.proto_property, errs, need_convert)
    return self
end

function TSetChannelAccessesReq:unpack(_)
    return self.ChannelType, self.AccessRole
end

IpmiCore.SetChannelAccessesReq = TSetChannelAccessesReq

---@class IpmiCore.SetHostPrivilegeLimitedRsp
---@field Ret boolean
---@field Reason string
local TSetHostPrivilegeLimitedRsp = {}
TSetHostPrivilegeLimitedRsp.__index = TSetHostPrivilegeLimitedRsp
TSetHostPrivilegeLimitedRsp.group = {}

local function TSetHostPrivilegeLimitedRsp_from_obj(obj)
    return setmetatable(obj, TSetHostPrivilegeLimitedRsp)
end

function TSetHostPrivilegeLimitedRsp.new(Ret, Reason)
    return TSetHostPrivilegeLimitedRsp_from_obj({Ret = Ret, Reason = Reason})
end
---@param obj IpmiCore.SetHostPrivilegeLimitedRsp
function TSetHostPrivilegeLimitedRsp:init_from_obj(obj)
    self.Ret = obj.Ret
    self.Reason = obj.Reason
end

function TSetHostPrivilegeLimitedRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetHostPrivilegeLimitedRsp.group)
end

TSetHostPrivilegeLimitedRsp.from_obj = TSetHostPrivilegeLimitedRsp_from_obj

TSetHostPrivilegeLimitedRsp.proto_property = {'Ret', 'Reason'}

TSetHostPrivilegeLimitedRsp.default = {false, ''}

TSetHostPrivilegeLimitedRsp.struct = {
    {name = 'Ret', is_array = false, struct = nil}, {name = 'Reason', is_array = false, struct = nil}
}

function TSetHostPrivilegeLimitedRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Ret', self.Ret, 'bool', false, errs, need_convert)
    validate.Optional(prefix .. 'Reason', self.Reason, 'string', false, errs, need_convert)

    TSetHostPrivilegeLimitedRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetHostPrivilegeLimitedRsp.proto_property, errs, need_convert)
    return self
end

function TSetHostPrivilegeLimitedRsp:unpack(_)
    return self.Ret, self.Reason
end

IpmiCore.SetHostPrivilegeLimitedRsp = TSetHostPrivilegeLimitedRsp

---@class IpmiCore.SetHostPrivilegeLimitedReq
---@field SystemId string
---@field Privileges string[]
local TSetHostPrivilegeLimitedReq = {}
TSetHostPrivilegeLimitedReq.__index = TSetHostPrivilegeLimitedReq
TSetHostPrivilegeLimitedReq.group = {}

local function TSetHostPrivilegeLimitedReq_from_obj(obj)
    return setmetatable(obj, TSetHostPrivilegeLimitedReq)
end

function TSetHostPrivilegeLimitedReq.new(SystemId, Privileges)
    return TSetHostPrivilegeLimitedReq_from_obj({SystemId = SystemId, Privileges = Privileges})
end
---@param obj IpmiCore.SetHostPrivilegeLimitedReq
function TSetHostPrivilegeLimitedReq:init_from_obj(obj)
    self.SystemId = obj.SystemId
    self.Privileges = obj.Privileges
end

function TSetHostPrivilegeLimitedReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetHostPrivilegeLimitedReq.group)
end

TSetHostPrivilegeLimitedReq.from_obj = TSetHostPrivilegeLimitedReq_from_obj

TSetHostPrivilegeLimitedReq.proto_property = {'SystemId', 'Privileges'}

TSetHostPrivilegeLimitedReq.default = {'', {}}

TSetHostPrivilegeLimitedReq.struct = {
    {name = 'SystemId', is_array = false, struct = nil}, {name = 'Privileges', is_array = true, struct = nil}
}

function TSetHostPrivilegeLimitedReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SystemId', self.SystemId, 'string', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'Privileges', self.Privileges, 'string', false, errs, need_convert)

    TSetHostPrivilegeLimitedReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetHostPrivilegeLimitedReq.proto_property, errs, need_convert)
    return self
end

function TSetHostPrivilegeLimitedReq:unpack(_)
    return self.SystemId, self.Privileges
end

IpmiCore.SetHostPrivilegeLimitedReq = TSetHostPrivilegeLimitedReq

---@class IpmiCore.RouteRsp
---@field Rsp integer[]
local TRouteRsp = {}
TRouteRsp.__index = TRouteRsp
TRouteRsp.group = {}

local function TRouteRsp_from_obj(obj)
    return setmetatable(obj, TRouteRsp)
end

function TRouteRsp.new(Rsp)
    return TRouteRsp_from_obj({Rsp = Rsp})
end
---@param obj IpmiCore.RouteRsp
function TRouteRsp:init_from_obj(obj)
    self.Rsp = obj.Rsp
end

function TRouteRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRouteRsp.group)
end

TRouteRsp.from_obj = TRouteRsp_from_obj

TRouteRsp.proto_property = {'Rsp'}

TRouteRsp.default = {{}}

TRouteRsp.struct = {{name = 'Rsp', is_array = true, struct = nil}}

function TRouteRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.OptionalArray(prefix .. 'Rsp', self.Rsp, 'uint8', false, errs, need_convert)

    TRouteRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRouteRsp.proto_property, errs, need_convert)
    return self
end

function TRouteRsp:unpack(_)
    return self.Rsp
end

IpmiCore.RouteRsp = TRouteRsp

---@class IpmiCore.RouteReq
---@field Req integer[]
---@field Ctx integer[]
local TRouteReq = {}
TRouteReq.__index = TRouteReq
TRouteReq.group = {}

local function TRouteReq_from_obj(obj)
    return setmetatable(obj, TRouteReq)
end

function TRouteReq.new(Req, Ctx)
    return TRouteReq_from_obj({Req = Req, Ctx = Ctx})
end
---@param obj IpmiCore.RouteReq
function TRouteReq:init_from_obj(obj)
    self.Req = obj.Req
    self.Ctx = obj.Ctx
end

function TRouteReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRouteReq.group)
end

TRouteReq.from_obj = TRouteReq_from_obj

TRouteReq.proto_property = {'Req', 'Ctx'}

TRouteReq.default = {{}, {}}

TRouteReq.struct = {{name = 'Req', is_array = true, struct = nil}, {name = 'Ctx', is_array = true, struct = nil}}

function TRouteReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.OptionalArray(prefix .. 'Req', self.Req, 'uint8', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'Ctx', self.Ctx, 'uint8', false, errs, need_convert)

    TRouteReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRouteReq.proto_property, errs, need_convert)
    return self
end

function TRouteReq:unpack(_)
    return self.Req, self.Ctx
end

IpmiCore.RouteReq = TRouteReq

---@class IpmiCore.RequestRsp
---@field CompletionCode integer
---@field Payload integer[]
local TRequestRsp = {}
TRequestRsp.__index = TRequestRsp
TRequestRsp.group = {}

local function TRequestRsp_from_obj(obj)
    return setmetatable(obj, TRequestRsp)
end

function TRequestRsp.new(CompletionCode, Payload)
    return TRequestRsp_from_obj({CompletionCode = CompletionCode, Payload = Payload})
end
---@param obj IpmiCore.RequestRsp
function TRequestRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.Payload = obj.Payload
end

function TRequestRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRequestRsp.group)
end

TRequestRsp.from_obj = TRequestRsp_from_obj

TRequestRsp.proto_property = {'CompletionCode', 'Payload'}

TRequestRsp.default = {0, {}}

TRequestRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'Payload', is_array = true, struct = nil}
}

function TRequestRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'Payload', self.Payload, 'uint8', false, errs, need_convert)

    TRequestRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRequestRsp.proto_property, errs, need_convert)
    return self
end

function TRequestRsp:unpack(_)
    return self.CompletionCode, self.Payload
end

IpmiCore.RequestRsp = TRequestRsp

---@class IpmiCore.RequestReq
---@field ChanType integer
---@field Instance integer
---@field NetFn integer
---@field Lun integer
---@field Cmd integer
---@field Payload integer[]
local TRequestReq = {}
TRequestReq.__index = TRequestReq
TRequestReq.group = {}

local function TRequestReq_from_obj(obj)
    return setmetatable(obj, TRequestReq)
end

function TRequestReq.new(ChanType, Instance, NetFn, Lun, Cmd, Payload)
    return TRequestReq_from_obj({
        ChanType = ChanType,
        Instance = Instance,
        NetFn = NetFn,
        Lun = Lun,
        Cmd = Cmd,
        Payload = Payload
    })
end
---@param obj IpmiCore.RequestReq
function TRequestReq:init_from_obj(obj)
    self.ChanType = obj.ChanType
    self.Instance = obj.Instance
    self.NetFn = obj.NetFn
    self.Lun = obj.Lun
    self.Cmd = obj.Cmd
    self.Payload = obj.Payload
end

function TRequestReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRequestReq.group)
end

TRequestReq.from_obj = TRequestReq_from_obj

TRequestReq.proto_property = {'ChanType', 'Instance', 'NetFn', 'Lun', 'Cmd', 'Payload'}

TRequestReq.default = {0, 0, 0, 0, 0, {}}

TRequestReq.struct = {
    {name = 'ChanType', is_array = false, struct = nil}, {name = 'Instance', is_array = false, struct = nil},
    {name = 'NetFn', is_array = false, struct = nil}, {name = 'Lun', is_array = false, struct = nil},
    {name = 'Cmd', is_array = false, struct = nil}, {name = 'Payload', is_array = true, struct = nil}
}

function TRequestReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ChanType', self.ChanType, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Instance', self.Instance, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'NetFn', self.NetFn, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Lun', self.Lun, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Cmd', self.Cmd, 'uint8', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'Payload', self.Payload, 'uint8', false, errs, need_convert)

    TRequestReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRequestReq.proto_property, errs, need_convert)
    return self
end

function TRequestReq:unpack(_)
    return self.ChanType, self.Instance, self.NetFn, self.Lun, self.Cmd, self.Payload
end

IpmiCore.RequestReq = TRequestReq

IpmiCore.interface = mdb.register_interface('bmc.kepler.IpmiCore', {
    Version = {'s', {['emitsChangedSignal'] = 'false'}, true, '2.0'},
    HostUSBChannelEnabled = {'b', nil, false, false},
    ChannelAccesses = {'a{ss}', nil, true, nil},
    CustomManufacturerId = {'u', nil, true, nil}
}, {
    Request = {'a{ss}yyyyyay', 'yay', TRequestReq, TRequestRsp},
    Route = {'a{ss}ayay', 'ay', TRouteReq, TRouteRsp},
    SetHostPrivilegeLimited = {'a{ss}sas', 'bs', TSetHostPrivilegeLimitedReq, TSetHostPrivilegeLimitedRsp},
    SetChannelAccesses = {'a{ss}ss', '', TSetChannelAccessesReq, TSetChannelAccessesRsp},
    GetIPMIChannel = {'a{ss}y', 'aa{sy}', TGetIPMIChannelReq, TGetIPMIChannelRsp}
}, {})

return IpmiCore
