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

local EnableAccount = {}

---@class AccountIpmiCmds.EnableAccountReq
---@field UserId integer
---@field Reserved1 integer
---@field PasswordSize integer
---@field Reserved2 integer
---@field PasswordData string
local TEnableAccountReq = {}
TEnableAccountReq.__index = TEnableAccountReq
TEnableAccountReq.group = {}

local function TEnableAccountReq_from_obj(obj)
    return setmetatable(obj, TEnableAccountReq)
end

function TEnableAccountReq.new(UserId, Reserved1, PasswordSize, Reserved2, PasswordData)
    return TEnableAccountReq_from_obj({
        UserId = UserId,
        Reserved1 = Reserved1,
        PasswordSize = PasswordSize,
        Reserved2 = Reserved2,
        PasswordData = PasswordData
    })
end
---@param obj AccountIpmiCmds.EnableAccountReq
function TEnableAccountReq:init_from_obj(obj)
    self.UserId = obj.UserId
    self.Reserved1 = obj.Reserved1
    self.PasswordSize = obj.PasswordSize
    self.Reserved2 = obj.Reserved2
    self.PasswordData = obj.PasswordData
end

function TEnableAccountReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TEnableAccountReq.group)
end

TEnableAccountReq.from_obj = TEnableAccountReq_from_obj

TEnableAccountReq.proto_property = {'UserId', 'Reserved1', 'PasswordSize', 'Reserved2', 'PasswordData'}

TEnableAccountReq.default = {0, 0, 0, 0, ''}

TEnableAccountReq.struct = {
    {name = 'UserId', is_array = false, struct = nil}, {name = 'Reserved1', is_array = false, struct = nil},
    {name = 'PasswordSize', is_array = false, struct = nil}, {name = 'Reserved2', is_array = false, struct = nil},
    {name = 'PasswordData', is_array = false, struct = nil}
}

function TEnableAccountReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved1', self.Reserved1, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PasswordSize', self.PasswordSize, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved2', self.Reserved2, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PasswordData', self.PasswordData, 'string', false, errs, need_convert)

    TEnableAccountReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TEnableAccountReq.proto_property, errs, need_convert)
    return self
end

function TEnableAccountReq:unpack(_)
    return self.UserId, self.Reserved1, self.PasswordSize, self.Reserved2, self.PasswordData
end

EnableAccount.EnableAccountReq = TEnableAccountReq

---@class AccountIpmiCmds.EnableAccountRsp
---@field CompletionCode integer
local TEnableAccountRsp = {}
TEnableAccountRsp.__index = TEnableAccountRsp
TEnableAccountRsp.group = {}

local function TEnableAccountRsp_from_obj(obj)
    return setmetatable(obj, TEnableAccountRsp)
end

function TEnableAccountRsp.new(CompletionCode)
    return TEnableAccountRsp_from_obj({CompletionCode = CompletionCode})
end
---@param obj AccountIpmiCmds.EnableAccountRsp
function TEnableAccountRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
end

function TEnableAccountRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TEnableAccountRsp.group)
end

TEnableAccountRsp.from_obj = TEnableAccountRsp_from_obj

TEnableAccountRsp.proto_property = {'CompletionCode'}

TEnableAccountRsp.default = {0}

TEnableAccountRsp.struct = {{name = 'CompletionCode', is_array = false, struct = nil}}

function TEnableAccountRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint32', false, errs, need_convert)

    TEnableAccountRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TEnableAccountRsp.proto_property, errs, need_convert)
    return self
end

function TEnableAccountRsp:unpack(_)
    return self.CompletionCode
end

EnableAccount.EnableAccountRsp = TEnableAccountRsp

return EnableAccount
