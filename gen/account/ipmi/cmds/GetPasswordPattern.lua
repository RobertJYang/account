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

local GetPasswordPattern = {}

---@class AccountIpmiCmds.GetPasswordPatternReq
---@field ManufactureId integer
---@field AccountType integer
local TGetPasswordPatternReq = {}
TGetPasswordPatternReq.__index = TGetPasswordPatternReq
TGetPasswordPatternReq.group = {}

local function TGetPasswordPatternReq_from_obj(obj)
    return setmetatable(obj, TGetPasswordPatternReq)
end

function TGetPasswordPatternReq.new(ManufactureId, AccountType)
    return TGetPasswordPatternReq_from_obj({ManufactureId = ManufactureId, AccountType = AccountType})
end
---@param obj AccountIpmiCmds.GetPasswordPatternReq
function TGetPasswordPatternReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.AccountType = obj.AccountType
end

function TGetPasswordPatternReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetPasswordPatternReq.group)
end

TGetPasswordPatternReq.from_obj = TGetPasswordPatternReq_from_obj

TGetPasswordPatternReq.proto_property = {'ManufactureId', 'AccountType'}

TGetPasswordPatternReq.default = {0, 0}

TGetPasswordPatternReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'AccountType', is_array = false, struct = nil}
}

function TGetPasswordPatternReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'AccountType', self.AccountType, 'uint8', false, errs, need_convert)

    TGetPasswordPatternReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetPasswordPatternReq.proto_property, errs, need_convert)
    return self
end

function TGetPasswordPatternReq:unpack(_)
    return self.ManufactureId, self.AccountType
end

GetPasswordPattern.GetPasswordPatternReq = TGetPasswordPatternReq

---@class AccountIpmiCmds.GetPasswordPatternRsp
---@field CompletionCode integer
---@field ManufactureId integer
---@field Length integer
---@field Data string
local TGetPasswordPatternRsp = {}
TGetPasswordPatternRsp.__index = TGetPasswordPatternRsp
TGetPasswordPatternRsp.group = {}

local function TGetPasswordPatternRsp_from_obj(obj)
    return setmetatable(obj, TGetPasswordPatternRsp)
end

function TGetPasswordPatternRsp.new(CompletionCode, ManufactureId, Length, Data)
    return TGetPasswordPatternRsp_from_obj({
        CompletionCode = CompletionCode,
        ManufactureId = ManufactureId,
        Length = Length,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.GetPasswordPatternRsp
function TGetPasswordPatternRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
    self.Length = obj.Length
    self.Data = obj.Data
end

function TGetPasswordPatternRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetPasswordPatternRsp.group)
end

TGetPasswordPatternRsp.from_obj = TGetPasswordPatternRsp_from_obj

TGetPasswordPatternRsp.proto_property = {'CompletionCode', 'ManufactureId', 'Length', 'Data'}

TGetPasswordPatternRsp.default = {0, 0, 0, ''}

TGetPasswordPatternRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil},
    {name = 'Length', is_array = false, struct = nil}, {name = 'Data', is_array = false, struct = nil}
}

function TGetPasswordPatternRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Length', self.Length, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TGetPasswordPatternRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetPasswordPatternRsp.proto_property, errs, need_convert)
    return self
end

function TGetPasswordPatternRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId, self.Length, self.Data
end

GetPasswordPattern.GetPasswordPatternRsp = TGetPasswordPatternRsp

return GetPasswordPattern
