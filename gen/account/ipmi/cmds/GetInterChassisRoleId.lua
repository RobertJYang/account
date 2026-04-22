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

local GetInterChassisRoleId = {}

---@class AccountIpmiCmds.GetInterChassisRoleIdReq
---@field ManufactureId integer
---@field Reserved integer
local TGetInterChassisRoleIdReq = {}
TGetInterChassisRoleIdReq.__index = TGetInterChassisRoleIdReq
TGetInterChassisRoleIdReq.group = {}

local function TGetInterChassisRoleIdReq_from_obj(obj)
    return setmetatable(obj, TGetInterChassisRoleIdReq)
end

function TGetInterChassisRoleIdReq.new(ManufactureId, Reserved)
    return TGetInterChassisRoleIdReq_from_obj({ManufactureId = ManufactureId, Reserved = Reserved})
end
---@param obj AccountIpmiCmds.GetInterChassisRoleIdReq
function TGetInterChassisRoleIdReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.Reserved = obj.Reserved
end

function TGetInterChassisRoleIdReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetInterChassisRoleIdReq.group)
end

TGetInterChassisRoleIdReq.from_obj = TGetInterChassisRoleIdReq_from_obj

TGetInterChassisRoleIdReq.proto_property = {'ManufactureId', 'Reserved'}

TGetInterChassisRoleIdReq.default = {0, 0}

TGetInterChassisRoleIdReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'Reserved', is_array = false, struct = nil}
}

function TGetInterChassisRoleIdReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved', self.Reserved, 'uint8', false, errs, need_convert)

    TGetInterChassisRoleIdReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetInterChassisRoleIdReq.proto_property, errs, need_convert)
    return self
end

function TGetInterChassisRoleIdReq:unpack(_)
    return self.ManufactureId, self.Reserved
end

GetInterChassisRoleId.GetInterChassisRoleIdReq = TGetInterChassisRoleIdReq

---@class AccountIpmiCmds.GetInterChassisRoleIdRsp
---@field CompletionCode integer
---@field ManufactureId integer
---@field DataLength integer
---@field Data string
local TGetInterChassisRoleIdRsp = {}
TGetInterChassisRoleIdRsp.__index = TGetInterChassisRoleIdRsp
TGetInterChassisRoleIdRsp.group = {}

local function TGetInterChassisRoleIdRsp_from_obj(obj)
    return setmetatable(obj, TGetInterChassisRoleIdRsp)
end

function TGetInterChassisRoleIdRsp.new(CompletionCode, ManufactureId, DataLength, Data)
    return TGetInterChassisRoleIdRsp_from_obj({
        CompletionCode = CompletionCode,
        ManufactureId = ManufactureId,
        DataLength = DataLength,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.GetInterChassisRoleIdRsp
function TGetInterChassisRoleIdRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
    self.DataLength = obj.DataLength
    self.Data = obj.Data
end

function TGetInterChassisRoleIdRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetInterChassisRoleIdRsp.group)
end

TGetInterChassisRoleIdRsp.from_obj = TGetInterChassisRoleIdRsp_from_obj

TGetInterChassisRoleIdRsp.proto_property = {'CompletionCode', 'ManufactureId', 'DataLength', 'Data'}

TGetInterChassisRoleIdRsp.default = {0, 0, 0, ''}

TGetInterChassisRoleIdRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil},
    {name = 'DataLength', is_array = false, struct = nil}, {name = 'Data', is_array = false, struct = nil}
}

function TGetInterChassisRoleIdRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'DataLength', self.DataLength, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TGetInterChassisRoleIdRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetInterChassisRoleIdRsp.proto_property, errs, need_convert)
    return self
end

function TGetInterChassisRoleIdRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId, self.DataLength, self.Data
end

GetInterChassisRoleId.GetInterChassisRoleIdRsp = TGetInterChassisRoleIdRsp

return GetInterChassisRoleId
