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

local UserIpmiSetUserSNMPV3PrivacyPwd = {}

---@class AccountIpmiCmds.UserIpmiSetUserSNMPV3PrivacyPwdReq
---@field ManufactureId integer
---@field UserId integer
---@field Operation integer
---@field PwdLength integer
---@field PasswordData string
local TUserIpmiSetUserSNMPV3PrivacyPwdReq = {}
TUserIpmiSetUserSNMPV3PrivacyPwdReq.__index = TUserIpmiSetUserSNMPV3PrivacyPwdReq
TUserIpmiSetUserSNMPV3PrivacyPwdReq.group = {}

local function TUserIpmiSetUserSNMPV3PrivacyPwdReq_from_obj(obj)
    return setmetatable(obj, TUserIpmiSetUserSNMPV3PrivacyPwdReq)
end

function TUserIpmiSetUserSNMPV3PrivacyPwdReq.new(ManufactureId, UserId, Operation, PwdLength, PasswordData)
    return TUserIpmiSetUserSNMPV3PrivacyPwdReq_from_obj({
        ManufactureId = ManufactureId,
        UserId = UserId,
        Operation = Operation,
        PwdLength = PwdLength,
        PasswordData = PasswordData
    })
end
---@param obj AccountIpmiCmds.UserIpmiSetUserSNMPV3PrivacyPwdReq
function TUserIpmiSetUserSNMPV3PrivacyPwdReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.UserId = obj.UserId
    self.Operation = obj.Operation
    self.PwdLength = obj.PwdLength
    self.PasswordData = obj.PasswordData
end

function TUserIpmiSetUserSNMPV3PrivacyPwdReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUserIpmiSetUserSNMPV3PrivacyPwdReq.group)
end

TUserIpmiSetUserSNMPV3PrivacyPwdReq.from_obj = TUserIpmiSetUserSNMPV3PrivacyPwdReq_from_obj

TUserIpmiSetUserSNMPV3PrivacyPwdReq.proto_property = {
    'ManufactureId', 'UserId', 'Operation', 'PwdLength', 'PasswordData'
}

TUserIpmiSetUserSNMPV3PrivacyPwdReq.default = {0, 0, 0, 0, ''}

TUserIpmiSetUserSNMPV3PrivacyPwdReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'UserId', is_array = false, struct = nil},
    {name = 'Operation', is_array = false, struct = nil}, {name = 'PwdLength', is_array = false, struct = nil},
    {name = 'PasswordData', is_array = false, struct = nil}
}

function TUserIpmiSetUserSNMPV3PrivacyPwdReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Operation', self.Operation, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PwdLength', self.PwdLength, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PasswordData', self.PasswordData, 'string', false, errs, need_convert)

    TUserIpmiSetUserSNMPV3PrivacyPwdReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUserIpmiSetUserSNMPV3PrivacyPwdReq.proto_property, errs, need_convert)
    return self
end

function TUserIpmiSetUserSNMPV3PrivacyPwdReq:unpack(_)
    return self.ManufactureId, self.UserId, self.Operation, self.PwdLength, self.PasswordData
end

UserIpmiSetUserSNMPV3PrivacyPwd.UserIpmiSetUserSNMPV3PrivacyPwdReq = TUserIpmiSetUserSNMPV3PrivacyPwdReq

---@class AccountIpmiCmds.UserIpmiSetUserSNMPV3PrivacyPwdRsp
---@field CompletionCode integer
---@field ManufactureId integer
local TUserIpmiSetUserSNMPV3PrivacyPwdRsp = {}
TUserIpmiSetUserSNMPV3PrivacyPwdRsp.__index = TUserIpmiSetUserSNMPV3PrivacyPwdRsp
TUserIpmiSetUserSNMPV3PrivacyPwdRsp.group = {}

local function TUserIpmiSetUserSNMPV3PrivacyPwdRsp_from_obj(obj)
    return setmetatable(obj, TUserIpmiSetUserSNMPV3PrivacyPwdRsp)
end

function TUserIpmiSetUserSNMPV3PrivacyPwdRsp.new(CompletionCode, ManufactureId)
    return
        TUserIpmiSetUserSNMPV3PrivacyPwdRsp_from_obj({CompletionCode = CompletionCode, ManufactureId = ManufactureId})
end
---@param obj AccountIpmiCmds.UserIpmiSetUserSNMPV3PrivacyPwdRsp
function TUserIpmiSetUserSNMPV3PrivacyPwdRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
end

function TUserIpmiSetUserSNMPV3PrivacyPwdRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUserIpmiSetUserSNMPV3PrivacyPwdRsp.group)
end

TUserIpmiSetUserSNMPV3PrivacyPwdRsp.from_obj = TUserIpmiSetUserSNMPV3PrivacyPwdRsp_from_obj

TUserIpmiSetUserSNMPV3PrivacyPwdRsp.proto_property = {'CompletionCode', 'ManufactureId'}

TUserIpmiSetUserSNMPV3PrivacyPwdRsp.default = {0, 0}

TUserIpmiSetUserSNMPV3PrivacyPwdRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil}
}

function TUserIpmiSetUserSNMPV3PrivacyPwdRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)

    TUserIpmiSetUserSNMPV3PrivacyPwdRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUserIpmiSetUserSNMPV3PrivacyPwdRsp.proto_property, errs, need_convert)
    return self
end

function TUserIpmiSetUserSNMPV3PrivacyPwdRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId
end

UserIpmiSetUserSNMPV3PrivacyPwd.UserIpmiSetUserSNMPV3PrivacyPwdRsp = TUserIpmiSetUserSNMPV3PrivacyPwdRsp

return UserIpmiSetUserSNMPV3PrivacyPwd
