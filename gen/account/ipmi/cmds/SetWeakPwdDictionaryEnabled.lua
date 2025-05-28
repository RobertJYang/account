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

local SetWeakPwdDictionaryEnabled = {}

---@class AccountIpmiCmds.SetWeakPwdDictionaryEnabledReq
---@field ManufactureId integer
---@field UserId integer
---@field Reserved1 integer
---@field Reserved2 integer
---@field Length integer
---@field Data string
local TSetWeakPwdDictionaryEnabledReq = {}
TSetWeakPwdDictionaryEnabledReq.__index = TSetWeakPwdDictionaryEnabledReq
TSetWeakPwdDictionaryEnabledReq.group = {}

local function TSetWeakPwdDictionaryEnabledReq_from_obj(obj)
    return setmetatable(obj, TSetWeakPwdDictionaryEnabledReq)
end

function TSetWeakPwdDictionaryEnabledReq.new(ManufactureId, UserId, Reserved1, Reserved2, Length, Data)
    return TSetWeakPwdDictionaryEnabledReq_from_obj({
        ManufactureId = ManufactureId,
        UserId = UserId,
        Reserved1 = Reserved1,
        Reserved2 = Reserved2,
        Length = Length,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.SetWeakPwdDictionaryEnabledReq
function TSetWeakPwdDictionaryEnabledReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.UserId = obj.UserId
    self.Reserved1 = obj.Reserved1
    self.Reserved2 = obj.Reserved2
    self.Length = obj.Length
    self.Data = obj.Data
end

function TSetWeakPwdDictionaryEnabledReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetWeakPwdDictionaryEnabledReq.group)
end

TSetWeakPwdDictionaryEnabledReq.from_obj = TSetWeakPwdDictionaryEnabledReq_from_obj

TSetWeakPwdDictionaryEnabledReq.proto_property = {'ManufactureId', 'UserId', 'Reserved1', 'Reserved2', 'Length', 'Data'}

TSetWeakPwdDictionaryEnabledReq.default = {0, 0, 0, 0, 0, ''}

TSetWeakPwdDictionaryEnabledReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'UserId', is_array = false, struct = nil},
    {name = 'Reserved1', is_array = false, struct = nil}, {name = 'Reserved2', is_array = false, struct = nil},
    {name = 'Length', is_array = false, struct = nil}, {name = 'Data', is_array = false, struct = nil}
}

function TSetWeakPwdDictionaryEnabledReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved1', self.Reserved1, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved2', self.Reserved2, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Length', self.Length, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TSetWeakPwdDictionaryEnabledReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetWeakPwdDictionaryEnabledReq.proto_property, errs, need_convert)
    return self
end

function TSetWeakPwdDictionaryEnabledReq:unpack(_)
    return self.ManufactureId, self.UserId, self.Reserved1, self.Reserved2, self.Length, self.Data
end

SetWeakPwdDictionaryEnabled.SetWeakPwdDictionaryEnabledReq = TSetWeakPwdDictionaryEnabledReq

---@class AccountIpmiCmds.SetWeakPwdDictionaryEnabledRsp
---@field CompletionCode integer
---@field ManufactureId integer
local TSetWeakPwdDictionaryEnabledRsp = {}
TSetWeakPwdDictionaryEnabledRsp.__index = TSetWeakPwdDictionaryEnabledRsp
TSetWeakPwdDictionaryEnabledRsp.group = {}

local function TSetWeakPwdDictionaryEnabledRsp_from_obj(obj)
    return setmetatable(obj, TSetWeakPwdDictionaryEnabledRsp)
end

function TSetWeakPwdDictionaryEnabledRsp.new(CompletionCode, ManufactureId)
    return TSetWeakPwdDictionaryEnabledRsp_from_obj({CompletionCode = CompletionCode, ManufactureId = ManufactureId})
end
---@param obj AccountIpmiCmds.SetWeakPwdDictionaryEnabledRsp
function TSetWeakPwdDictionaryEnabledRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
end

function TSetWeakPwdDictionaryEnabledRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetWeakPwdDictionaryEnabledRsp.group)
end

TSetWeakPwdDictionaryEnabledRsp.from_obj = TSetWeakPwdDictionaryEnabledRsp_from_obj

TSetWeakPwdDictionaryEnabledRsp.proto_property = {'CompletionCode', 'ManufactureId'}

TSetWeakPwdDictionaryEnabledRsp.default = {0, 0}

TSetWeakPwdDictionaryEnabledRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil}
}

function TSetWeakPwdDictionaryEnabledRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)

    TSetWeakPwdDictionaryEnabledRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetWeakPwdDictionaryEnabledRsp.proto_property, errs, need_convert)
    return self
end

function TSetWeakPwdDictionaryEnabledRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId
end

SetWeakPwdDictionaryEnabled.SetWeakPwdDictionaryEnabledRsp = TSetWeakPwdDictionaryEnabledRsp

return SetWeakPwdDictionaryEnabled
