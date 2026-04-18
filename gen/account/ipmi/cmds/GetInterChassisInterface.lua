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

local GetInterChassisInterface = {}

---@class AccountIpmiCmds.GetInterChassisInterfaceReq
---@field ManufactureId integer
---@field Reserved integer
local TGetInterChassisInterfaceReq = {}
TGetInterChassisInterfaceReq.__index = TGetInterChassisInterfaceReq
TGetInterChassisInterfaceReq.group = {}

local function TGetInterChassisInterfaceReq_from_obj(obj)
    return setmetatable(obj, TGetInterChassisInterfaceReq)
end

function TGetInterChassisInterfaceReq.new(ManufactureId, Reserved)
    return TGetInterChassisInterfaceReq_from_obj({ManufactureId = ManufactureId, Reserved = Reserved})
end
---@param obj AccountIpmiCmds.GetInterChassisInterfaceReq
function TGetInterChassisInterfaceReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.Reserved = obj.Reserved
end

function TGetInterChassisInterfaceReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetInterChassisInterfaceReq.group)
end

TGetInterChassisInterfaceReq.from_obj = TGetInterChassisInterfaceReq_from_obj

TGetInterChassisInterfaceReq.proto_property = {'ManufactureId', 'Reserved'}

TGetInterChassisInterfaceReq.default = {0, 0}

TGetInterChassisInterfaceReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'Reserved', is_array = false, struct = nil}
}

function TGetInterChassisInterfaceReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved', self.Reserved, 'uint8', false, errs, need_convert)

    TGetInterChassisInterfaceReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetInterChassisInterfaceReq.proto_property, errs, need_convert)
    return self
end

function TGetInterChassisInterfaceReq:unpack(_)
    return self.ManufactureId, self.Reserved
end

GetInterChassisInterface.GetInterChassisInterfaceReq = TGetInterChassisInterfaceReq

---@class AccountIpmiCmds.GetInterChassisInterfaceRsp
---@field CompletionCode integer
---@field ManufactureId integer
---@field DataLength integer
---@field Data string
local TGetInterChassisInterfaceRsp = {}
TGetInterChassisInterfaceRsp.__index = TGetInterChassisInterfaceRsp
TGetInterChassisInterfaceRsp.group = {}

local function TGetInterChassisInterfaceRsp_from_obj(obj)
    return setmetatable(obj, TGetInterChassisInterfaceRsp)
end

function TGetInterChassisInterfaceRsp.new(CompletionCode, ManufactureId, DataLength, Data)
    return TGetInterChassisInterfaceRsp_from_obj({
        CompletionCode = CompletionCode,
        ManufactureId = ManufactureId,
        DataLength = DataLength,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.GetInterChassisInterfaceRsp
function TGetInterChassisInterfaceRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
    self.DataLength = obj.DataLength
    self.Data = obj.Data
end

function TGetInterChassisInterfaceRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetInterChassisInterfaceRsp.group)
end

TGetInterChassisInterfaceRsp.from_obj = TGetInterChassisInterfaceRsp_from_obj

TGetInterChassisInterfaceRsp.proto_property = {'CompletionCode', 'ManufactureId', 'DataLength', 'Data'}

TGetInterChassisInterfaceRsp.default = {0, 0, 0, ''}

TGetInterChassisInterfaceRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil},
    {name = 'DataLength', is_array = false, struct = nil}, {name = 'Data', is_array = false, struct = nil}
}

function TGetInterChassisInterfaceRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'DataLength', self.DataLength, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TGetInterChassisInterfaceRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetInterChassisInterfaceRsp.proto_property, errs, need_convert)
    return self
end

function TGetInterChassisInterfaceRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId, self.DataLength, self.Data
end

GetInterChassisInterface.GetInterChassisInterfaceRsp = TGetInterChassisInterfaceRsp

return GetInterChassisInterface
