--[[-- Copyright (c) 2026 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
]] --
local validate = require 'mc.validate'
local utils = require 'mc.utils'

local GetAccountInterface = {}

---@class AccountIpmiCmds.GetAccountInterfaceReq
---@field ManufactureId integer
---@field UserId integer
---@field Reserved1 integer
local TGetAccountInterfaceReq = {}
TGetAccountInterfaceReq.__index = TGetAccountInterfaceReq
TGetAccountInterfaceReq.group = {}

local function TGetAccountInterfaceReq_from_obj(obj)
    return setmetatable(obj, TGetAccountInterfaceReq)
end

function TGetAccountInterfaceReq.new(ManufactureId, UserId, Reserved1)
    return TGetAccountInterfaceReq_from_obj({ManufactureId = ManufactureId, UserId = UserId, Reserved1 = Reserved1})
end
---@param obj AccountIpmiCmds.GetAccountInterfaceReq
function TGetAccountInterfaceReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.UserId = obj.UserId
    self.Reserved1 = obj.Reserved1
end

function TGetAccountInterfaceReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetAccountInterfaceReq.group)
end

TGetAccountInterfaceReq.from_obj = TGetAccountInterfaceReq_from_obj

TGetAccountInterfaceReq.proto_property = {'ManufactureId', 'UserId', 'Reserved1'}

TGetAccountInterfaceReq.default = {0, 0, 0}

TGetAccountInterfaceReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'UserId', is_array = false, struct = nil},
    {name = 'Reserved1', is_array = false, struct = nil}
}

function TGetAccountInterfaceReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved1', self.Reserved1, 'uint8', false, errs, need_convert)

    TGetAccountInterfaceReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetAccountInterfaceReq.proto_property, errs, need_convert)
    return self
end

function TGetAccountInterfaceReq:unpack(_)
    return self.ManufactureId, self.UserId, self.Reserved1
end

GetAccountInterface.GetAccountInterfaceReq = TGetAccountInterfaceReq

---@class AccountIpmiCmds.GetAccountInterfaceRsp
---@field CompletionCode integer
---@field ManufactureId integer
---@field Interface integer
local TGetAccountInterfaceRsp = {}
TGetAccountInterfaceRsp.__index = TGetAccountInterfaceRsp
TGetAccountInterfaceRsp.group = {}

local function TGetAccountInterfaceRsp_from_obj(obj)
    return setmetatable(obj, TGetAccountInterfaceRsp)
end

function TGetAccountInterfaceRsp.new(CompletionCode, ManufactureId, Interface)
    return TGetAccountInterfaceRsp_from_obj({
        CompletionCode = CompletionCode,
        ManufactureId = ManufactureId,
        Interface = Interface
    })
end
---@param obj AccountIpmiCmds.GetAccountInterfaceRsp
function TGetAccountInterfaceRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
    self.Interface = obj.Interface
end

function TGetAccountInterfaceRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetAccountInterfaceRsp.group)
end

TGetAccountInterfaceRsp.from_obj = TGetAccountInterfaceRsp_from_obj

TGetAccountInterfaceRsp.proto_property = {'CompletionCode', 'ManufactureId', 'Interface'}

TGetAccountInterfaceRsp.default = {0, 0, 0}

TGetAccountInterfaceRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil},
    {name = 'Interface', is_array = false, struct = nil}
}

function TGetAccountInterfaceRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Interface', self.Interface, 'uint8', false, errs, need_convert)

    TGetAccountInterfaceRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetAccountInterfaceRsp.proto_property, errs, need_convert)
    return self
end

function TGetAccountInterfaceRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId, self.Interface
end

GetAccountInterface.GetAccountInterfaceRsp = TGetAccountInterfaceRsp

return GetAccountInterface
