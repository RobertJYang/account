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

local SetFirstLoginModifyPolicy = {}

---@class AccountIpmiCmds.SetFirstLoginModifyPolicyReq
---@field ManufactureId integer
---@field UserId integer
---@field Reserved1 integer
---@field Reserved2 integer
---@field Length integer
---@field Data string
local TSetFirstLoginModifyPolicyReq = {}
TSetFirstLoginModifyPolicyReq.__index = TSetFirstLoginModifyPolicyReq
TSetFirstLoginModifyPolicyReq.group = {}

local function TSetFirstLoginModifyPolicyReq_from_obj(obj)
    return setmetatable(obj, TSetFirstLoginModifyPolicyReq)
end

function TSetFirstLoginModifyPolicyReq.new(ManufactureId, UserId, Reserved1, Reserved2, Length, Data)
    return TSetFirstLoginModifyPolicyReq_from_obj({
        ManufactureId = ManufactureId,
        UserId = UserId,
        Reserved1 = Reserved1,
        Reserved2 = Reserved2,
        Length = Length,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.SetFirstLoginModifyPolicyReq
function TSetFirstLoginModifyPolicyReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.UserId = obj.UserId
    self.Reserved1 = obj.Reserved1
    self.Reserved2 = obj.Reserved2
    self.Length = obj.Length
    self.Data = obj.Data
end

function TSetFirstLoginModifyPolicyReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetFirstLoginModifyPolicyReq.group)
end

TSetFirstLoginModifyPolicyReq.from_obj = TSetFirstLoginModifyPolicyReq_from_obj

TSetFirstLoginModifyPolicyReq.proto_property = {'ManufactureId', 'UserId', 'Reserved1', 'Reserved2', 'Length', 'Data'}

TSetFirstLoginModifyPolicyReq.default = {0, 0, 0, 0, 0, ''}

TSetFirstLoginModifyPolicyReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'UserId', is_array = false, struct = nil},
    {name = 'Reserved1', is_array = false, struct = nil}, {name = 'Reserved2', is_array = false, struct = nil},
    {name = 'Length', is_array = false, struct = nil}, {name = 'Data', is_array = false, struct = nil}
}

function TSetFirstLoginModifyPolicyReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved1', self.Reserved1, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved2', self.Reserved2, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Length', self.Length, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TSetFirstLoginModifyPolicyReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetFirstLoginModifyPolicyReq.proto_property, errs, need_convert)
    return self
end

function TSetFirstLoginModifyPolicyReq:unpack(_)
    return self.ManufactureId, self.UserId, self.Reserved1, self.Reserved2, self.Length, self.Data
end

SetFirstLoginModifyPolicy.SetFirstLoginModifyPolicyReq = TSetFirstLoginModifyPolicyReq

---@class AccountIpmiCmds.SetFirstLoginModifyPolicyRsp
---@field CompletionCode integer
---@field ManufactureId integer
local TSetFirstLoginModifyPolicyRsp = {}
TSetFirstLoginModifyPolicyRsp.__index = TSetFirstLoginModifyPolicyRsp
TSetFirstLoginModifyPolicyRsp.group = {}

local function TSetFirstLoginModifyPolicyRsp_from_obj(obj)
    return setmetatable(obj, TSetFirstLoginModifyPolicyRsp)
end

function TSetFirstLoginModifyPolicyRsp.new(CompletionCode, ManufactureId)
    return TSetFirstLoginModifyPolicyRsp_from_obj({CompletionCode = CompletionCode, ManufactureId = ManufactureId})
end
---@param obj AccountIpmiCmds.SetFirstLoginModifyPolicyRsp
function TSetFirstLoginModifyPolicyRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
end

function TSetFirstLoginModifyPolicyRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetFirstLoginModifyPolicyRsp.group)
end

TSetFirstLoginModifyPolicyRsp.from_obj = TSetFirstLoginModifyPolicyRsp_from_obj

TSetFirstLoginModifyPolicyRsp.proto_property = {'CompletionCode', 'ManufactureId'}

TSetFirstLoginModifyPolicyRsp.default = {0, 0}

TSetFirstLoginModifyPolicyRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil}
}

function TSetFirstLoginModifyPolicyRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)

    TSetFirstLoginModifyPolicyRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetFirstLoginModifyPolicyRsp.proto_property, errs, need_convert)
    return self
end

function TSetFirstLoginModifyPolicyRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId
end

SetFirstLoginModifyPolicy.SetFirstLoginModifyPolicyRsp = TSetFirstLoginModifyPolicyRsp

return SetFirstLoginModifyPolicy
