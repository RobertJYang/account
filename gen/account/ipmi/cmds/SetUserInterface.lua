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

local SetUserInterface = {}

---@class AccountIpmiCmds.SetUserInterfaceReq
---@field ManufactureId integer
---@field UserId integer
---@field Operation integer
---@field LoginInterface integer
---@field Reserved integer
---@field PasswordLength integer
---@field PasswordData string
local TSetUserInterfaceReq = {}
TSetUserInterfaceReq.__index = TSetUserInterfaceReq
TSetUserInterfaceReq.group = {}

local function TSetUserInterfaceReq_from_obj(obj)
    return setmetatable(obj, TSetUserInterfaceReq)
end

function TSetUserInterfaceReq.new(ManufactureId, UserId, Operation, LoginInterface, Reserved, PasswordLength,
    PasswordData)
    return TSetUserInterfaceReq_from_obj({
        ManufactureId = ManufactureId,
        UserId = UserId,
        Operation = Operation,
        LoginInterface = LoginInterface,
        Reserved = Reserved,
        PasswordLength = PasswordLength,
        PasswordData = PasswordData
    })
end
---@param obj AccountIpmiCmds.SetUserInterfaceReq
function TSetUserInterfaceReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.UserId = obj.UserId
    self.Operation = obj.Operation
    self.LoginInterface = obj.LoginInterface
    self.Reserved = obj.Reserved
    self.PasswordLength = obj.PasswordLength
    self.PasswordData = obj.PasswordData
end

function TSetUserInterfaceReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetUserInterfaceReq.group)
end

TSetUserInterfaceReq.from_obj = TSetUserInterfaceReq_from_obj

TSetUserInterfaceReq.proto_property = {
    'ManufactureId', 'UserId', 'Operation', 'LoginInterface', 'Reserved', 'PasswordLength', 'PasswordData'
}

TSetUserInterfaceReq.default = {0, 0, 0, 0, 0, 0, ''}

TSetUserInterfaceReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'UserId', is_array = false, struct = nil},
    {name = 'Operation', is_array = false, struct = nil}, {name = 'LoginInterface', is_array = false, struct = nil},
    {name = 'Reserved', is_array = false, struct = nil}, {name = 'PasswordLength', is_array = false, struct = nil},
    {name = 'PasswordData', is_array = false, struct = nil}
}

function TSetUserInterfaceReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Operation', self.Operation, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'LoginInterface', self.LoginInterface, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved', self.Reserved, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PasswordLength', self.PasswordLength, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PasswordData', self.PasswordData, 'string', false, errs, need_convert)

    TSetUserInterfaceReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetUserInterfaceReq.proto_property, errs, need_convert)
    return self
end

function TSetUserInterfaceReq:unpack(_)
    return self.ManufactureId, self.UserId, self.Operation, self.LoginInterface, self.Reserved, self.PasswordLength,
        self.PasswordData
end

SetUserInterface.SetUserInterfaceReq = TSetUserInterfaceReq

---@class AccountIpmiCmds.SetUserInterfaceRsp
---@field CompletionCode integer
---@field ManufactureId integer
local TSetUserInterfaceRsp = {}
TSetUserInterfaceRsp.__index = TSetUserInterfaceRsp
TSetUserInterfaceRsp.group = {}

local function TSetUserInterfaceRsp_from_obj(obj)
    return setmetatable(obj, TSetUserInterfaceRsp)
end

function TSetUserInterfaceRsp.new(CompletionCode, ManufactureId)
    return TSetUserInterfaceRsp_from_obj({CompletionCode = CompletionCode, ManufactureId = ManufactureId})
end
---@param obj AccountIpmiCmds.SetUserInterfaceRsp
function TSetUserInterfaceRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
end

function TSetUserInterfaceRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetUserInterfaceRsp.group)
end

TSetUserInterfaceRsp.from_obj = TSetUserInterfaceRsp_from_obj

TSetUserInterfaceRsp.proto_property = {'CompletionCode', 'ManufactureId'}

TSetUserInterfaceRsp.default = {0, 0}

TSetUserInterfaceRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil}
}

function TSetUserInterfaceRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)

    TSetUserInterfaceRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetUserInterfaceRsp.proto_property, errs, need_convert)
    return self
end

function TSetUserInterfaceRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId
end

SetUserInterface.SetUserInterfaceRsp = TSetUserInterfaceRsp

return SetUserInterface
