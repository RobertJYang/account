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

local GetPasswordRulePolicy = {}

---@class AccountIpmiCmds.GetPasswordRulePolicyReq
---@field ManufactureId integer
---@field AccountType integer
local TGetPasswordRulePolicyReq = {}
TGetPasswordRulePolicyReq.__index = TGetPasswordRulePolicyReq
TGetPasswordRulePolicyReq.group = {}

local function TGetPasswordRulePolicyReq_from_obj(obj)
    return setmetatable(obj, TGetPasswordRulePolicyReq)
end

function TGetPasswordRulePolicyReq.new(ManufactureId, AccountType)
    return TGetPasswordRulePolicyReq_from_obj({ManufactureId = ManufactureId, AccountType = AccountType})
end
---@param obj AccountIpmiCmds.GetPasswordRulePolicyReq
function TGetPasswordRulePolicyReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.AccountType = obj.AccountType
end

function TGetPasswordRulePolicyReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetPasswordRulePolicyReq.group)
end

TGetPasswordRulePolicyReq.from_obj = TGetPasswordRulePolicyReq_from_obj

TGetPasswordRulePolicyReq.proto_property = {'ManufactureId', 'AccountType'}

TGetPasswordRulePolicyReq.default = {0, 0}

TGetPasswordRulePolicyReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'AccountType', is_array = false, struct = nil}
}

function TGetPasswordRulePolicyReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'AccountType', self.AccountType, 'uint8', false, errs, need_convert)

    TGetPasswordRulePolicyReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetPasswordRulePolicyReq.proto_property, errs, need_convert)
    return self
end

function TGetPasswordRulePolicyReq:unpack(_)
    return self.ManufactureId, self.AccountType
end

GetPasswordRulePolicy.GetPasswordRulePolicyReq = TGetPasswordRulePolicyReq

---@class AccountIpmiCmds.GetPasswordRulePolicyRsp
---@field CompletionCode integer
---@field ManufactureId integer
---@field Length integer
---@field Data string
local TGetPasswordRulePolicyRsp = {}
TGetPasswordRulePolicyRsp.__index = TGetPasswordRulePolicyRsp
TGetPasswordRulePolicyRsp.group = {}

local function TGetPasswordRulePolicyRsp_from_obj(obj)
    return setmetatable(obj, TGetPasswordRulePolicyRsp)
end

function TGetPasswordRulePolicyRsp.new(CompletionCode, ManufactureId, Length, Data)
    return TGetPasswordRulePolicyRsp_from_obj({
        CompletionCode = CompletionCode,
        ManufactureId = ManufactureId,
        Length = Length,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.GetPasswordRulePolicyRsp
function TGetPasswordRulePolicyRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
    self.Length = obj.Length
    self.Data = obj.Data
end

function TGetPasswordRulePolicyRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetPasswordRulePolicyRsp.group)
end

TGetPasswordRulePolicyRsp.from_obj = TGetPasswordRulePolicyRsp_from_obj

TGetPasswordRulePolicyRsp.proto_property = {'CompletionCode', 'ManufactureId', 'Length', 'Data'}

TGetPasswordRulePolicyRsp.default = {0, 0, 0, ''}

TGetPasswordRulePolicyRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil},
    {name = 'Length', is_array = false, struct = nil}, {name = 'Data', is_array = false, struct = nil}
}

function TGetPasswordRulePolicyRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Length', self.Length, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TGetPasswordRulePolicyRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetPasswordRulePolicyRsp.proto_property, errs, need_convert)
    return self
end

function TGetPasswordRulePolicyRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId, self.Length, self.Data
end

GetPasswordRulePolicy.GetPasswordRulePolicyRsp = TGetPasswordRulePolicyRsp

return GetPasswordRulePolicy
