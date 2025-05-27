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

local SetVncPassword = {}

---@class AccountIpmiCmds.SetVncPasswordReq
---@field ManufactureId integer
---@field Reserved integer
---@field Length integer
---@field Password string
local TSetVncPasswordReq = {}
TSetVncPasswordReq.__index = TSetVncPasswordReq
TSetVncPasswordReq.group = {}

local function TSetVncPasswordReq_from_obj(obj)
    return setmetatable(obj, TSetVncPasswordReq)
end

function TSetVncPasswordReq.new(ManufactureId, Reserved, Length, Password)
    return TSetVncPasswordReq_from_obj({
        ManufactureId = ManufactureId,
        Reserved = Reserved,
        Length = Length,
        Password = Password
    })
end
---@param obj AccountIpmiCmds.SetVncPasswordReq
function TSetVncPasswordReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.Reserved = obj.Reserved
    self.Length = obj.Length
    self.Password = obj.Password
end

function TSetVncPasswordReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetVncPasswordReq.group)
end

TSetVncPasswordReq.from_obj = TSetVncPasswordReq_from_obj

TSetVncPasswordReq.proto_property = {'ManufactureId', 'Reserved', 'Length', 'Password'}

TSetVncPasswordReq.default = {0, 0, 0, ''}

TSetVncPasswordReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'Reserved', is_array = false, struct = nil},
    {name = 'Length', is_array = false, struct = nil}, {name = 'Password', is_array = false, struct = nil}
}

function TSetVncPasswordReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved', self.Reserved, 'uint16', false, errs, need_convert)
    validate.Optional(prefix .. 'Length', self.Length, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Password', self.Password, 'string', false, errs, need_convert)

    TSetVncPasswordReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetVncPasswordReq.proto_property, errs, need_convert)
    return self
end

function TSetVncPasswordReq:unpack(_)
    return self.ManufactureId, self.Reserved, self.Length, self.Password
end

SetVncPassword.SetVncPasswordReq = TSetVncPasswordReq

---@class AccountIpmiCmds.SetVncPasswordRsp
---@field CompletionCode integer
---@field ManufactureId integer
local TSetVncPasswordRsp = {}
TSetVncPasswordRsp.__index = TSetVncPasswordRsp
TSetVncPasswordRsp.group = {}

local function TSetVncPasswordRsp_from_obj(obj)
    return setmetatable(obj, TSetVncPasswordRsp)
end

function TSetVncPasswordRsp.new(CompletionCode, ManufactureId)
    return TSetVncPasswordRsp_from_obj({CompletionCode = CompletionCode, ManufactureId = ManufactureId})
end
---@param obj AccountIpmiCmds.SetVncPasswordRsp
function TSetVncPasswordRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
end

function TSetVncPasswordRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetVncPasswordRsp.group)
end

TSetVncPasswordRsp.from_obj = TSetVncPasswordRsp_from_obj

TSetVncPasswordRsp.proto_property = {'CompletionCode', 'ManufactureId'}

TSetVncPasswordRsp.default = {0, 0}

TSetVncPasswordRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil}
}

function TSetVncPasswordRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)

    TSetVncPasswordRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetVncPasswordRsp.proto_property, errs, need_convert)
    return self
end

function TSetVncPasswordRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId
end

SetVncPassword.SetVncPasswordRsp = TSetVncPasswordRsp

return SetVncPassword
