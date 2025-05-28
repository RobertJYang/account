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

local SetPasswordRulePolicy = {}

---@class AccountIpmiCmds.SetPasswordRulePolicyReq
---@field ManufactureId integer
---@field AccountType integer
---@field Reserved integer
---@field Length integer
---@field Data string
local TSetPasswordRulePolicyReq = {}
TSetPasswordRulePolicyReq.__index = TSetPasswordRulePolicyReq
TSetPasswordRulePolicyReq.group = {}

local function TSetPasswordRulePolicyReq_from_obj(obj)
    return setmetatable(obj, TSetPasswordRulePolicyReq)
end

function TSetPasswordRulePolicyReq.new(ManufactureId, AccountType, Reserved, Length, Data)
    return TSetPasswordRulePolicyReq_from_obj({
        ManufactureId = ManufactureId,
        AccountType = AccountType,
        Reserved = Reserved,
        Length = Length,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.SetPasswordRulePolicyReq
function TSetPasswordRulePolicyReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.AccountType = obj.AccountType
    self.Reserved = obj.Reserved
    self.Length = obj.Length
    self.Data = obj.Data
end

function TSetPasswordRulePolicyReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetPasswordRulePolicyReq.group)
end

TSetPasswordRulePolicyReq.from_obj = TSetPasswordRulePolicyReq_from_obj

TSetPasswordRulePolicyReq.proto_property = {'ManufactureId', 'AccountType', 'Reserved', 'Length', 'Data'}

TSetPasswordRulePolicyReq.default = {0, 0, 0, 0, ''}

TSetPasswordRulePolicyReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'AccountType', is_array = false, struct = nil},
    {name = 'Reserved', is_array = false, struct = nil}, {name = 'Length', is_array = false, struct = nil},
    {name = 'Data', is_array = false, struct = nil}
}

function TSetPasswordRulePolicyReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'AccountType', self.AccountType, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved', self.Reserved, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Length', self.Length, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TSetPasswordRulePolicyReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetPasswordRulePolicyReq.proto_property, errs, need_convert)
    return self
end

function TSetPasswordRulePolicyReq:unpack(_)
    return self.ManufactureId, self.AccountType, self.Reserved, self.Length, self.Data
end

SetPasswordRulePolicy.SetPasswordRulePolicyReq = TSetPasswordRulePolicyReq

---@class AccountIpmiCmds.SetPasswordRulePolicyRsp
---@field CompletionCode integer
---@field ManufactureId integer
local TSetPasswordRulePolicyRsp = {}
TSetPasswordRulePolicyRsp.__index = TSetPasswordRulePolicyRsp
TSetPasswordRulePolicyRsp.group = {}

local function TSetPasswordRulePolicyRsp_from_obj(obj)
    return setmetatable(obj, TSetPasswordRulePolicyRsp)
end

function TSetPasswordRulePolicyRsp.new(CompletionCode, ManufactureId)
    return TSetPasswordRulePolicyRsp_from_obj({CompletionCode = CompletionCode, ManufactureId = ManufactureId})
end
---@param obj AccountIpmiCmds.SetPasswordRulePolicyRsp
function TSetPasswordRulePolicyRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
end

function TSetPasswordRulePolicyRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetPasswordRulePolicyRsp.group)
end

TSetPasswordRulePolicyRsp.from_obj = TSetPasswordRulePolicyRsp_from_obj

TSetPasswordRulePolicyRsp.proto_property = {'CompletionCode', 'ManufactureId'}

TSetPasswordRulePolicyRsp.default = {0, 0}

TSetPasswordRulePolicyRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil}
}

function TSetPasswordRulePolicyRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)

    TSetPasswordRulePolicyRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetPasswordRulePolicyRsp.proto_property, errs, need_convert)
    return self
end

function TSetPasswordRulePolicyRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId
end

SetPasswordRulePolicy.SetPasswordRulePolicyRsp = TSetPasswordRulePolicyRsp

return SetPasswordRulePolicy
