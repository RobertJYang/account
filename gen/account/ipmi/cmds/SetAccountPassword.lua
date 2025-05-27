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

local SetAccountPassword = {}

---@class AccountIpmiCmds.SetAccountPasswordReq
---@field UserId integer
---@field Reserved1 integer
---@field PasswordSize integer
---@field Reserved2 integer
---@field PasswordData string
local TSetAccountPasswordReq = {}
TSetAccountPasswordReq.__index = TSetAccountPasswordReq
TSetAccountPasswordReq.group = {}

local function TSetAccountPasswordReq_from_obj(obj)
    return setmetatable(obj, TSetAccountPasswordReq)
end

function TSetAccountPasswordReq.new(UserId, Reserved1, PasswordSize, Reserved2, PasswordData)
    return TSetAccountPasswordReq_from_obj({
        UserId = UserId,
        Reserved1 = Reserved1,
        PasswordSize = PasswordSize,
        Reserved2 = Reserved2,
        PasswordData = PasswordData
    })
end
---@param obj AccountIpmiCmds.SetAccountPasswordReq
function TSetAccountPasswordReq:init_from_obj(obj)
    self.UserId = obj.UserId
    self.Reserved1 = obj.Reserved1
    self.PasswordSize = obj.PasswordSize
    self.Reserved2 = obj.Reserved2
    self.PasswordData = obj.PasswordData
end

function TSetAccountPasswordReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetAccountPasswordReq.group)
end

TSetAccountPasswordReq.from_obj = TSetAccountPasswordReq_from_obj

TSetAccountPasswordReq.proto_property = {'UserId', 'Reserved1', 'PasswordSize', 'Reserved2', 'PasswordData'}

TSetAccountPasswordReq.default = {0, 0, 0, 0, ''}

TSetAccountPasswordReq.struct = {
    {name = 'UserId', is_array = false, struct = nil}, {name = 'Reserved1', is_array = false, struct = nil},
    {name = 'PasswordSize', is_array = false, struct = nil}, {name = 'Reserved2', is_array = false, struct = nil},
    {name = 'PasswordData', is_array = false, struct = nil}
}

function TSetAccountPasswordReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved1', self.Reserved1, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PasswordSize', self.PasswordSize, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved2', self.Reserved2, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PasswordData', self.PasswordData, 'string', false, errs, need_convert)

    TSetAccountPasswordReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetAccountPasswordReq.proto_property, errs, need_convert)
    return self
end

function TSetAccountPasswordReq:unpack(_)
    return self.UserId, self.Reserved1, self.PasswordSize, self.Reserved2, self.PasswordData
end

SetAccountPassword.SetAccountPasswordReq = TSetAccountPasswordReq

---@class AccountIpmiCmds.SetAccountPasswordRsp
---@field CompletionCode integer
local TSetAccountPasswordRsp = {}
TSetAccountPasswordRsp.__index = TSetAccountPasswordRsp
TSetAccountPasswordRsp.group = {}

local function TSetAccountPasswordRsp_from_obj(obj)
    return setmetatable(obj, TSetAccountPasswordRsp)
end

function TSetAccountPasswordRsp.new(CompletionCode)
    return TSetAccountPasswordRsp_from_obj({CompletionCode = CompletionCode})
end
---@param obj AccountIpmiCmds.SetAccountPasswordRsp
function TSetAccountPasswordRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
end

function TSetAccountPasswordRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetAccountPasswordRsp.group)
end

TSetAccountPasswordRsp.from_obj = TSetAccountPasswordRsp_from_obj

TSetAccountPasswordRsp.proto_property = {'CompletionCode'}

TSetAccountPasswordRsp.default = {0}

TSetAccountPasswordRsp.struct = {{name = 'CompletionCode', is_array = false, struct = nil}}

function TSetAccountPasswordRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint32', false, errs, need_convert)

    TSetAccountPasswordRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetAccountPasswordRsp.proto_property, errs, need_convert)
    return self
end

function TSetAccountPasswordRsp:unpack(_)
    return self.CompletionCode
end

SetAccountPassword.SetAccountPasswordRsp = TSetAccountPasswordRsp

return SetAccountPassword
