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

local SetPasswordPattern = {}

---@class AccountIpmiCmds.SetPasswordPatternReq
---@field ManufactureId integer
---@field AccountType integer
---@field Reserved integer
---@field Length integer
---@field Data string
local TSetPasswordPatternReq = {}
TSetPasswordPatternReq.__index = TSetPasswordPatternReq
TSetPasswordPatternReq.group = {}

local function TSetPasswordPatternReq_from_obj(obj)
    return setmetatable(obj, TSetPasswordPatternReq)
end

function TSetPasswordPatternReq.new(ManufactureId, AccountType, Reserved, Length, Data)
    return TSetPasswordPatternReq_from_obj({
        ManufactureId = ManufactureId,
        AccountType = AccountType,
        Reserved = Reserved,
        Length = Length,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.SetPasswordPatternReq
function TSetPasswordPatternReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.AccountType = obj.AccountType
    self.Reserved = obj.Reserved
    self.Length = obj.Length
    self.Data = obj.Data
end

function TSetPasswordPatternReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetPasswordPatternReq.group)
end

TSetPasswordPatternReq.from_obj = TSetPasswordPatternReq_from_obj

TSetPasswordPatternReq.proto_property = {'ManufactureId', 'AccountType', 'Reserved', 'Length', 'Data'}

TSetPasswordPatternReq.default = {0, 0, 0, 0, ''}

TSetPasswordPatternReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'AccountType', is_array = false, struct = nil},
    {name = 'Reserved', is_array = false, struct = nil}, {name = 'Length', is_array = false, struct = nil},
    {name = 'Data', is_array = false, struct = nil}
}

function TSetPasswordPatternReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'AccountType', self.AccountType, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved', self.Reserved, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Length', self.Length, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TSetPasswordPatternReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetPasswordPatternReq.proto_property, errs, need_convert)
    return self
end

function TSetPasswordPatternReq:unpack(_)
    return self.ManufactureId, self.AccountType, self.Reserved, self.Length, self.Data
end

SetPasswordPattern.SetPasswordPatternReq = TSetPasswordPatternReq

---@class AccountIpmiCmds.SetPasswordPatternRsp
---@field CompletionCode integer
---@field ManufactureId integer
local TSetPasswordPatternRsp = {}
TSetPasswordPatternRsp.__index = TSetPasswordPatternRsp
TSetPasswordPatternRsp.group = {}

local function TSetPasswordPatternRsp_from_obj(obj)
    return setmetatable(obj, TSetPasswordPatternRsp)
end

function TSetPasswordPatternRsp.new(CompletionCode, ManufactureId)
    return TSetPasswordPatternRsp_from_obj({CompletionCode = CompletionCode, ManufactureId = ManufactureId})
end
---@param obj AccountIpmiCmds.SetPasswordPatternRsp
function TSetPasswordPatternRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
end

function TSetPasswordPatternRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetPasswordPatternRsp.group)
end

TSetPasswordPatternRsp.from_obj = TSetPasswordPatternRsp_from_obj

TSetPasswordPatternRsp.proto_property = {'CompletionCode', 'ManufactureId'}

TSetPasswordPatternRsp.default = {0, 0}

TSetPasswordPatternRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil}
}

function TSetPasswordPatternRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)

    TSetPasswordPatternRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetPasswordPatternRsp.proto_property, errs, need_convert)
    return self
end

function TSetPasswordPatternRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId
end

SetPasswordPattern.SetPasswordPatternRsp = TSetPasswordPatternRsp

return SetPasswordPattern
