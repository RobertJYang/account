--[[-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
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

local GetWeakPwdDictionaryEnabled = {}

---@class AccountIpmiCmds.GetWeakPwdDictionaryEnabledReq
---@field ManufactureId integer
---@field UserId integer
---@field Reserved1 integer
local TGetWeakPwdDictionaryEnabledReq = {}
TGetWeakPwdDictionaryEnabledReq.__index = TGetWeakPwdDictionaryEnabledReq
TGetWeakPwdDictionaryEnabledReq.group = {}

local function TGetWeakPwdDictionaryEnabledReq_from_obj(obj)
    return setmetatable(obj, TGetWeakPwdDictionaryEnabledReq)
end

function TGetWeakPwdDictionaryEnabledReq.new(ManufactureId, UserId, Reserved1)
    return TGetWeakPwdDictionaryEnabledReq_from_obj({
        ManufactureId = ManufactureId,
        UserId = UserId,
        Reserved1 = Reserved1
    })
end
---@param obj AccountIpmiCmds.GetWeakPwdDictionaryEnabledReq
function TGetWeakPwdDictionaryEnabledReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.UserId = obj.UserId
    self.Reserved1 = obj.Reserved1
end

function TGetWeakPwdDictionaryEnabledReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetWeakPwdDictionaryEnabledReq.group)
end

TGetWeakPwdDictionaryEnabledReq.from_obj = TGetWeakPwdDictionaryEnabledReq_from_obj

TGetWeakPwdDictionaryEnabledReq.proto_property = {'ManufactureId', 'UserId', 'Reserved1'}

TGetWeakPwdDictionaryEnabledReq.default = {0, 0, 0}

TGetWeakPwdDictionaryEnabledReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'UserId', is_array = false, struct = nil},
    {name = 'Reserved1', is_array = false, struct = nil}
}

function TGetWeakPwdDictionaryEnabledReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved1', self.Reserved1, 'uint8', false, errs, need_convert)

    TGetWeakPwdDictionaryEnabledReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetWeakPwdDictionaryEnabledReq.proto_property, errs, need_convert)
    return self
end

function TGetWeakPwdDictionaryEnabledReq:unpack(_)
    return self.ManufactureId, self.UserId, self.Reserved1
end

GetWeakPwdDictionaryEnabled.GetWeakPwdDictionaryEnabledReq = TGetWeakPwdDictionaryEnabledReq

---@class AccountIpmiCmds.GetWeakPwdDictionaryEnabledRsp
---@field CompletionCode integer
---@field ManufactureId integer
---@field Length integer
---@field Data string
local TGetWeakPwdDictionaryEnabledRsp = {}
TGetWeakPwdDictionaryEnabledRsp.__index = TGetWeakPwdDictionaryEnabledRsp
TGetWeakPwdDictionaryEnabledRsp.group = {}

local function TGetWeakPwdDictionaryEnabledRsp_from_obj(obj)
    return setmetatable(obj, TGetWeakPwdDictionaryEnabledRsp)
end

function TGetWeakPwdDictionaryEnabledRsp.new(CompletionCode, ManufactureId, Length, Data)
    return TGetWeakPwdDictionaryEnabledRsp_from_obj({
        CompletionCode = CompletionCode,
        ManufactureId = ManufactureId,
        Length = Length,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.GetWeakPwdDictionaryEnabledRsp
function TGetWeakPwdDictionaryEnabledRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
    self.Length = obj.Length
    self.Data = obj.Data
end

function TGetWeakPwdDictionaryEnabledRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetWeakPwdDictionaryEnabledRsp.group)
end

TGetWeakPwdDictionaryEnabledRsp.from_obj = TGetWeakPwdDictionaryEnabledRsp_from_obj

TGetWeakPwdDictionaryEnabledRsp.proto_property = {'CompletionCode', 'ManufactureId', 'Length', 'Data'}

TGetWeakPwdDictionaryEnabledRsp.default = {0, 0, 0, ''}

TGetWeakPwdDictionaryEnabledRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil},
    {name = 'Length', is_array = false, struct = nil}, {name = 'Data', is_array = false, struct = nil}
}

function TGetWeakPwdDictionaryEnabledRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Length', self.Length, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TGetWeakPwdDictionaryEnabledRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetWeakPwdDictionaryEnabledRsp.proto_property, errs, need_convert)
    return self
end

function TGetWeakPwdDictionaryEnabledRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId, self.Length, self.Data
end

GetWeakPwdDictionaryEnabled.GetWeakPwdDictionaryEnabledRsp = TGetWeakPwdDictionaryEnabledRsp

return GetWeakPwdDictionaryEnabled
