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

local SetUserAccess = {}

---@class AccountIpmiCmds.SetUserAccessReq
---@field ChannelNumber integer
---@field MessagingEnable integer
---@field AuthenticationEnable integer
---@field UserRestricted integer
---@field ChangeEnable integer
---@field UserId integer
---@field Reserved1 integer
---@field UserPrivilege integer
---@field Reserved2 integer
---@field SessionLimit string
local TSetUserAccessReq = {}
TSetUserAccessReq.__index = TSetUserAccessReq
TSetUserAccessReq.group = {}

local function TSetUserAccessReq_from_obj(obj)
    return setmetatable(obj, TSetUserAccessReq)
end

function TSetUserAccessReq.new(ChannelNumber, MessagingEnable, AuthenticationEnable, UserRestricted, ChangeEnable,
    UserId, Reserved1, UserPrivilege, Reserved2, SessionLimit)
    return TSetUserAccessReq_from_obj({
        ChannelNumber = ChannelNumber,
        MessagingEnable = MessagingEnable,
        AuthenticationEnable = AuthenticationEnable,
        UserRestricted = UserRestricted,
        ChangeEnable = ChangeEnable,
        UserId = UserId,
        Reserved1 = Reserved1,
        UserPrivilege = UserPrivilege,
        Reserved2 = Reserved2,
        SessionLimit = SessionLimit
    })
end
---@param obj AccountIpmiCmds.SetUserAccessReq
function TSetUserAccessReq:init_from_obj(obj)
    self.ChannelNumber = obj.ChannelNumber
    self.MessagingEnable = obj.MessagingEnable
    self.AuthenticationEnable = obj.AuthenticationEnable
    self.UserRestricted = obj.UserRestricted
    self.ChangeEnable = obj.ChangeEnable
    self.UserId = obj.UserId
    self.Reserved1 = obj.Reserved1
    self.UserPrivilege = obj.UserPrivilege
    self.Reserved2 = obj.Reserved2
    self.SessionLimit = obj.SessionLimit
end

function TSetUserAccessReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetUserAccessReq.group)
end

TSetUserAccessReq.from_obj = TSetUserAccessReq_from_obj

TSetUserAccessReq.proto_property = {
    'ChannelNumber', 'MessagingEnable', 'AuthenticationEnable', 'UserRestricted', 'ChangeEnable', 'UserId', 'Reserved1',
    'UserPrivilege', 'Reserved2', 'SessionLimit'
}

TSetUserAccessReq.default = {0, 0, 0, 0, 0, 0, 0, 0, 0, ''}

TSetUserAccessReq.struct = {
    {name = 'ChannelNumber', is_array = false, struct = nil},
    {name = 'MessagingEnable', is_array = false, struct = nil},
    {name = 'AuthenticationEnable', is_array = false, struct = nil},
    {name = 'UserRestricted', is_array = false, struct = nil}, {name = 'ChangeEnable', is_array = false, struct = nil},
    {name = 'UserId', is_array = false, struct = nil}, {name = 'Reserved1', is_array = false, struct = nil},
    {name = 'UserPrivilege', is_array = false, struct = nil}, {name = 'Reserved2', is_array = false, struct = nil},
    {name = 'SessionLimit', is_array = false, struct = nil}
}

function TSetUserAccessReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ChannelNumber', self.ChannelNumber, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'MessagingEnable', self.MessagingEnable, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'AuthenticationEnable', self.AuthenticationEnable, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'UserRestricted', self.UserRestricted, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ChangeEnable', self.ChangeEnable, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved1', self.Reserved1, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'UserPrivilege', self.UserPrivilege, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved2', self.Reserved2, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'SessionLimit', self.SessionLimit, 'string', false, errs, need_convert)

    TSetUserAccessReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetUserAccessReq.proto_property, errs, need_convert)
    return self
end

function TSetUserAccessReq:unpack(_)
    return self.ChannelNumber, self.MessagingEnable, self.AuthenticationEnable, self.UserRestricted, self.ChangeEnable,
        self.UserId, self.Reserved1, self.UserPrivilege, self.Reserved2, self.SessionLimit
end

SetUserAccess.SetUserAccessReq = TSetUserAccessReq

---@class AccountIpmiCmds.SetUserAccessRsp
---@field CompletionCode integer
local TSetUserAccessRsp = {}
TSetUserAccessRsp.__index = TSetUserAccessRsp
TSetUserAccessRsp.group = {}

local function TSetUserAccessRsp_from_obj(obj)
    return setmetatable(obj, TSetUserAccessRsp)
end

function TSetUserAccessRsp.new(CompletionCode)
    return TSetUserAccessRsp_from_obj({CompletionCode = CompletionCode})
end
---@param obj AccountIpmiCmds.SetUserAccessRsp
function TSetUserAccessRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
end

function TSetUserAccessRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetUserAccessRsp.group)
end

TSetUserAccessRsp.from_obj = TSetUserAccessRsp_from_obj

TSetUserAccessRsp.proto_property = {'CompletionCode'}

TSetUserAccessRsp.default = {0}

TSetUserAccessRsp.struct = {{name = 'CompletionCode', is_array = false, struct = nil}}

function TSetUserAccessRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint32', false, errs, need_convert)

    TSetUserAccessRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetUserAccessRsp.proto_property, errs, need_convert)
    return self
end

function TSetUserAccessRsp:unpack(_)
    return self.CompletionCode
end

SetUserAccess.SetUserAccessRsp = TSetUserAccessRsp

return SetUserAccess
