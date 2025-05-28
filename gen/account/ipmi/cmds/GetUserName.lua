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

local GetUserName = {}

---@class AccountIpmiCmds.GetUserNameReq
---@field UserId integer
---@field Reserved integer
local TGetUserNameReq = {}
TGetUserNameReq.__index = TGetUserNameReq
TGetUserNameReq.group = {}

local function TGetUserNameReq_from_obj(obj)
    return setmetatable(obj, TGetUserNameReq)
end

function TGetUserNameReq.new(UserId, Reserved)
    return TGetUserNameReq_from_obj({UserId = UserId, Reserved = Reserved})
end
---@param obj AccountIpmiCmds.GetUserNameReq
function TGetUserNameReq:init_from_obj(obj)
    self.UserId = obj.UserId
    self.Reserved = obj.Reserved
end

function TGetUserNameReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetUserNameReq.group)
end

TGetUserNameReq.from_obj = TGetUserNameReq_from_obj

TGetUserNameReq.proto_property = {'UserId', 'Reserved'}

TGetUserNameReq.default = {0, 0}

TGetUserNameReq.struct = {
    {name = 'UserId', is_array = false, struct = nil}, {name = 'Reserved', is_array = false, struct = nil}
}

function TGetUserNameReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved', self.Reserved, 'uint8', false, errs, need_convert)

    TGetUserNameReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetUserNameReq.proto_property, errs, need_convert)
    return self
end

function TGetUserNameReq:unpack(_)
    return self.UserId, self.Reserved
end

GetUserName.GetUserNameReq = TGetUserNameReq

---@class AccountIpmiCmds.GetUserNameRsp
---@field CompletionCode integer
---@field UserName string
local TGetUserNameRsp = {}
TGetUserNameRsp.__index = TGetUserNameRsp
TGetUserNameRsp.group = {}

local function TGetUserNameRsp_from_obj(obj)
    return setmetatable(obj, TGetUserNameRsp)
end

function TGetUserNameRsp.new(CompletionCode, UserName)
    return TGetUserNameRsp_from_obj({CompletionCode = CompletionCode, UserName = UserName})
end
---@param obj AccountIpmiCmds.GetUserNameRsp
function TGetUserNameRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.UserName = obj.UserName
end

function TGetUserNameRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetUserNameRsp.group)
end

TGetUserNameRsp.from_obj = TGetUserNameRsp_from_obj

TGetUserNameRsp.proto_property = {'CompletionCode', 'UserName'}

TGetUserNameRsp.default = {0, ''}

TGetUserNameRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'UserName', is_array = false, struct = nil}
}

function TGetUserNameRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'UserName', self.UserName, 'string', false, errs, need_convert)

    TGetUserNameRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetUserNameRsp.proto_property, errs, need_convert)
    return self
end

function TGetUserNameRsp:unpack(_)
    return self.CompletionCode, self.UserName
end

GetUserName.GetUserNameRsp = TGetUserNameRsp

return GetUserName
