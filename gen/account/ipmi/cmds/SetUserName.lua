--[[-- Copyright (c) 2026 Huawei Technologies Co., Ltd.
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

local SetUserName = {}

---@class AccountIpmiCmds.SetUserNameReq
---@field UserId integer
---@field Reserved integer
---@field UserName string
local TSetUserNameReq = {}
TSetUserNameReq.__index = TSetUserNameReq
TSetUserNameReq.group = {}

local function TSetUserNameReq_from_obj(obj)
    return setmetatable(obj, TSetUserNameReq)
end

function TSetUserNameReq.new(UserId, Reserved, UserName)
    return TSetUserNameReq_from_obj({UserId = UserId, Reserved = Reserved, UserName = UserName})
end
---@param obj AccountIpmiCmds.SetUserNameReq
function TSetUserNameReq:init_from_obj(obj)
    self.UserId = obj.UserId
    self.Reserved = obj.Reserved
    self.UserName = obj.UserName
end

function TSetUserNameReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetUserNameReq.group)
end

TSetUserNameReq.from_obj = TSetUserNameReq_from_obj

TSetUserNameReq.proto_property = {'UserId', 'Reserved', 'UserName'}

TSetUserNameReq.default = {0, 0, ''}

TSetUserNameReq.struct = {
    {name = 'UserId', is_array = false, struct = nil}, {name = 'Reserved', is_array = false, struct = nil},
    {name = 'UserName', is_array = false, struct = nil}
}

function TSetUserNameReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved', self.Reserved, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'UserName', self.UserName, 'string', false, errs, need_convert)

    TSetUserNameReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetUserNameReq.proto_property, errs, need_convert)
    return self
end

function TSetUserNameReq:unpack(_)
    return self.UserId, self.Reserved, self.UserName
end

SetUserName.SetUserNameReq = TSetUserNameReq

---@class AccountIpmiCmds.SetUserNameRsp
---@field CompletionCode integer
local TSetUserNameRsp = {}
TSetUserNameRsp.__index = TSetUserNameRsp
TSetUserNameRsp.group = {}

local function TSetUserNameRsp_from_obj(obj)
    return setmetatable(obj, TSetUserNameRsp)
end

function TSetUserNameRsp.new(CompletionCode)
    return TSetUserNameRsp_from_obj({CompletionCode = CompletionCode})
end
---@param obj AccountIpmiCmds.SetUserNameRsp
function TSetUserNameRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
end

function TSetUserNameRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetUserNameRsp.group)
end

TSetUserNameRsp.from_obj = TSetUserNameRsp_from_obj

TSetUserNameRsp.proto_property = {'CompletionCode'}

TSetUserNameRsp.default = {0}

TSetUserNameRsp.struct = {{name = 'CompletionCode', is_array = false, struct = nil}}

function TSetUserNameRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint32', false, errs, need_convert)

    TSetUserNameRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetUserNameRsp.proto_property, errs, need_convert)
    return self
end

function TSetUserNameRsp:unpack(_)
    return self.CompletionCode
end

SetUserName.SetUserNameRsp = TSetUserNameRsp

return SetUserName
