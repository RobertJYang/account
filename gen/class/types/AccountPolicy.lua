-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local validate = require 'mc.validate'
local utils = require 'mc.utils'

local MAccountPolicy = {}

---@class MAccountPolicy.AllowedLoginInterfaces
---@field AllowedLoginInterfaces integer
local TAllowedLoginInterfaces = {}
TAllowedLoginInterfaces.__index = TAllowedLoginInterfaces
TAllowedLoginInterfaces.group = {}

local function TAllowedLoginInterfaces_from_obj(obj)
    return setmetatable(obj, TAllowedLoginInterfaces)
end

function TAllowedLoginInterfaces.new(AllowedLoginInterfaces)
    return TAllowedLoginInterfaces_from_obj({AllowedLoginInterfaces = AllowedLoginInterfaces or 223})
end
---@param obj MAccountPolicy.AllowedLoginInterfaces
function TAllowedLoginInterfaces:init_from_obj(obj)
    self.AllowedLoginInterfaces = obj.AllowedLoginInterfaces or 223
end

function TAllowedLoginInterfaces:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAllowedLoginInterfaces.group)
end

TAllowedLoginInterfaces.from_obj = TAllowedLoginInterfaces_from_obj

TAllowedLoginInterfaces.proto_property = {'AllowedLoginInterfaces'}

TAllowedLoginInterfaces.default = {0}

TAllowedLoginInterfaces.struct = {{name = 'AllowedLoginInterfaces', is_array = false, struct = nil}}

function TAllowedLoginInterfaces:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AllowedLoginInterfaces', self.AllowedLoginInterfaces, 'uint32', false, errs,
        need_convert)

    TAllowedLoginInterfaces:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAllowedLoginInterfaces.proto_property, errs, need_convert)
    return self
end

function TAllowedLoginInterfaces:unpack(_)
    return self.AllowedLoginInterfaces
end

MAccountPolicy.AllowedLoginInterfaces = TAllowedLoginInterfaces

---@class MAccountPolicy.NamePattern
---@field NamePattern string
local TNamePattern = {}
TNamePattern.__index = TNamePattern
TNamePattern.group = {}

local function TNamePattern_from_obj(obj)
    return setmetatable(obj, TNamePattern)
end

function TNamePattern.new(NamePattern)
    return TNamePattern_from_obj({NamePattern = NamePattern or [=[]=]})
end
---@param obj MAccountPolicy.NamePattern
function TNamePattern:init_from_obj(obj)
    self.NamePattern = obj.NamePattern or [=[]=]
end

function TNamePattern:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TNamePattern.group)
end

TNamePattern.from_obj = TNamePattern_from_obj

TNamePattern.proto_property = {'NamePattern'}

TNamePattern.default = {''}

TNamePattern.struct = {{name = 'NamePattern', is_array = false, struct = nil}}

function TNamePattern:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'NamePattern', self.NamePattern, 'string', false, errs, need_convert)

    TNamePattern:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNamePattern.proto_property, errs, need_convert)
    return self
end

function TNamePattern:unpack(_)
    return self.NamePattern
end

MAccountPolicy.NamePattern = TNamePattern

---@class MAccountPolicy.AccountType
---@field AccountType integer
local TAccountType = {}
TAccountType.__index = TAccountType
TAccountType.group = {}

local function TAccountType_from_obj(obj)
    return setmetatable(obj, TAccountType)
end

function TAccountType.new(AccountType)
    return TAccountType_from_obj({AccountType = AccountType})
end
---@param obj MAccountPolicy.AccountType
function TAccountType:init_from_obj(obj)
    self.AccountType = obj.AccountType
end

function TAccountType:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountType.group)
end

TAccountType.from_obj = TAccountType_from_obj

TAccountType.proto_property = {'AccountType'}

TAccountType.default = {0}

TAccountType.struct = {{name = 'AccountType', is_array = false, struct = nil}}

function TAccountType:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'AccountType', self.AccountType, 'uint8', false, errs, need_convert)

    TAccountType:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountType.proto_property, errs, need_convert)
    return self
end

function TAccountType:unpack(_)
    return self.AccountType
end

MAccountPolicy.AccountType = TAccountType

return MAccountPolicy
