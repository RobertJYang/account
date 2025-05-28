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

local DisableAccount = {}

---@class AccountIpmiCmds.DisableAccountReq
---@field UserId integer
---@field Reserved1 integer
---@field PasswordSize integer
---@field Reserved2 integer
---@field PasswordData string
local TDisableAccountReq = {}
TDisableAccountReq.__index = TDisableAccountReq
TDisableAccountReq.group = {}

local function TDisableAccountReq_from_obj(obj)
    return setmetatable(obj, TDisableAccountReq)
end

function TDisableAccountReq.new(UserId, Reserved1, PasswordSize, Reserved2, PasswordData)
    return TDisableAccountReq_from_obj({
        UserId = UserId,
        Reserved1 = Reserved1,
        PasswordSize = PasswordSize,
        Reserved2 = Reserved2,
        PasswordData = PasswordData
    })
end
---@param obj AccountIpmiCmds.DisableAccountReq
function TDisableAccountReq:init_from_obj(obj)
    self.UserId = obj.UserId
    self.Reserved1 = obj.Reserved1
    self.PasswordSize = obj.PasswordSize
    self.Reserved2 = obj.Reserved2
    self.PasswordData = obj.PasswordData
end

function TDisableAccountReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDisableAccountReq.group)
end

TDisableAccountReq.from_obj = TDisableAccountReq_from_obj

TDisableAccountReq.proto_property = {'UserId', 'Reserved1', 'PasswordSize', 'Reserved2', 'PasswordData'}

TDisableAccountReq.default = {0, 0, 0, 0, ''}

TDisableAccountReq.struct = {
    {name = 'UserId', is_array = false, struct = nil}, {name = 'Reserved1', is_array = false, struct = nil},
    {name = 'PasswordSize', is_array = false, struct = nil}, {name = 'Reserved2', is_array = false, struct = nil},
    {name = 'PasswordData', is_array = false, struct = nil}
}

function TDisableAccountReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved1', self.Reserved1, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PasswordSize', self.PasswordSize, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved2', self.Reserved2, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PasswordData', self.PasswordData, 'string', false, errs, need_convert)

    TDisableAccountReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDisableAccountReq.proto_property, errs, need_convert)
    return self
end

function TDisableAccountReq:unpack(_)
    return self.UserId, self.Reserved1, self.PasswordSize, self.Reserved2, self.PasswordData
end

DisableAccount.DisableAccountReq = TDisableAccountReq

---@class AccountIpmiCmds.DisableAccountRsp
---@field CompletionCode integer
local TDisableAccountRsp = {}
TDisableAccountRsp.__index = TDisableAccountRsp
TDisableAccountRsp.group = {}

local function TDisableAccountRsp_from_obj(obj)
    return setmetatable(obj, TDisableAccountRsp)
end

function TDisableAccountRsp.new(CompletionCode)
    return TDisableAccountRsp_from_obj({CompletionCode = CompletionCode})
end
---@param obj AccountIpmiCmds.DisableAccountRsp
function TDisableAccountRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
end

function TDisableAccountRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDisableAccountRsp.group)
end

TDisableAccountRsp.from_obj = TDisableAccountRsp_from_obj

TDisableAccountRsp.proto_property = {'CompletionCode'}

TDisableAccountRsp.default = {0}

TDisableAccountRsp.struct = {{name = 'CompletionCode', is_array = false, struct = nil}}

function TDisableAccountRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint32', false, errs, need_convert)

    TDisableAccountRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDisableAccountRsp.proto_property, errs, need_convert)
    return self
end

function TDisableAccountRsp:unpack(_)
    return self.CompletionCode
end

DisableAccount.DisableAccountRsp = TDisableAccountRsp

return DisableAccount
