-- Copyright (c) 2026 Huawei Technologies Co., Ltd.
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
local mdb = require 'mc.mdb'

local PasswordPolicy = {}

---@class PasswordPolicy.MaxPasswordLength
---@field MaxPasswordLength integer
local TMaxPasswordLength = {}
TMaxPasswordLength.__index = TMaxPasswordLength
TMaxPasswordLength.group = {}

local function TMaxPasswordLength_from_obj(obj)
    return setmetatable(obj, TMaxPasswordLength)
end

function TMaxPasswordLength.new(MaxPasswordLength)
    return TMaxPasswordLength_from_obj({MaxPasswordLength = MaxPasswordLength})
end
---@param obj PasswordPolicy.MaxPasswordLength
function TMaxPasswordLength:init_from_obj(obj)
    self.MaxPasswordLength = obj.MaxPasswordLength
end

function TMaxPasswordLength:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMaxPasswordLength.group)
end

TMaxPasswordLength.from_obj = TMaxPasswordLength_from_obj

TMaxPasswordLength.proto_property = {'MaxPasswordLength'}

TMaxPasswordLength.default = {0}

TMaxPasswordLength.struct = {{name = 'MaxPasswordLength', is_array = false, struct = nil}}

function TMaxPasswordLength:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'MaxPasswordLength', self.MaxPasswordLength, 'uint32', false, errs, need_convert)

    if self.MaxPasswordLength ~= nil then
        validate.ranges(prefix .. 'MaxPasswordLength', self.MaxPasswordLength, nil, 512, errs, need_convert)
    end

    TMaxPasswordLength:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMaxPasswordLength.proto_property, errs, need_convert)
    return self
end

function TMaxPasswordLength:unpack(_)
    return self.MaxPasswordLength
end

PasswordPolicy.MaxPasswordLength = TMaxPasswordLength

---@class PasswordPolicy.AccountType
---@field AccountType string
local TAccountType = {}
TAccountType.__index = TAccountType
TAccountType.group = {}

local function TAccountType_from_obj(obj)
    return setmetatable(obj, TAccountType)
end

function TAccountType.new(AccountType)
    return TAccountType_from_obj({AccountType = AccountType})
end
---@param obj PasswordPolicy.AccountType
function TAccountType:init_from_obj(obj)
    self.AccountType = obj.AccountType
end

function TAccountType:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountType.group)
end

TAccountType.from_obj = TAccountType_from_obj

TAccountType.proto_property = {'AccountType'}

TAccountType.default = {''}

TAccountType.struct = {{name = 'AccountType', is_array = false, struct = nil}}

function TAccountType:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountType', self.AccountType, 'string', true, errs, need_convert)

    TAccountType:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountType.proto_property, errs, need_convert)
    return self
end

function TAccountType:unpack(_)
    return self.AccountType
end

PasswordPolicy.AccountType = TAccountType

---@class PasswordPolicy.Pattern
---@field Pattern string
local TPattern = {}
TPattern.__index = TPattern
TPattern.group = {}

local function TPattern_from_obj(obj)
    return setmetatable(obj, TPattern)
end

function TPattern.new(Pattern)
    return TPattern_from_obj({Pattern = Pattern})
end
---@param obj PasswordPolicy.Pattern
function TPattern:init_from_obj(obj)
    self.Pattern = obj.Pattern
end

function TPattern:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPattern.group)
end

TPattern.from_obj = TPattern_from_obj

TPattern.proto_property = {'Pattern'}

TPattern.default = {''}

TPattern.struct = {{name = 'Pattern', is_array = false, struct = nil}}

function TPattern:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Pattern', self.Pattern, 'string', false, errs, need_convert)

    if self.Pattern ~= nil then
        validate.lens(prefix .. 'Pattern', self.Pattern, 0, 255, errs, need_convert)
    end

    TPattern:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPattern.proto_property, errs, need_convert)
    return self
end

function TPattern:unpack(_)
    return self.Pattern
end

PasswordPolicy.Pattern = TPattern

---@class PasswordPolicy.Policy
---@field Policy integer
local TPolicy = {}
TPolicy.__index = TPolicy
TPolicy.group = {}

local function TPolicy_from_obj(obj)
    return setmetatable(obj, TPolicy)
end

function TPolicy.new(Policy)
    return TPolicy_from_obj({Policy = Policy or 1})
end
---@param obj PasswordPolicy.Policy
function TPolicy:init_from_obj(obj)
    self.Policy = obj.Policy or 1
end

function TPolicy:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPolicy.group)
end

TPolicy.from_obj = TPolicy_from_obj

TPolicy.proto_property = {'Policy'}

TPolicy.default = {0}

TPolicy.struct = {{name = 'Policy', is_array = false, struct = nil}}

function TPolicy:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Policy', self.Policy, 'uint8', false, errs, need_convert)

    TPolicy:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPolicy.proto_property, errs, need_convert)
    return self
end

function TPolicy:unpack(_)
    return self.Policy
end

PasswordPolicy.Policy = TPolicy

PasswordPolicy.interface = mdb.register_interface('bmc.kepler.AccountService.PasswordPolicy', {
    Policy = {'y', {}, false, 1},
    Pattern = {'s', {}, false, nil},
    AccountType = {'s', {}, true, nil},
    MaxPasswordLength = {'u', {}, false, nil}
}, {}, {})

return PasswordPolicy
