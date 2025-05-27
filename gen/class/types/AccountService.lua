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

local def_types = require 'class.types.types'

local MAccountService = {}

---@class MAccountService.Id
---@field Id integer
local TId = {}
TId.__index = TId
TId.group = {}

local function TId_from_obj(obj)
    return setmetatable(obj, TId)
end

function TId.new(Id)
    return TId_from_obj({Id = Id})
end
---@param obj MAccountService.Id
function TId:init_from_obj(obj)
    self.Id = obj.Id
end

function TId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TId.group)
end

TId.from_obj = TId_from_obj

TId.proto_property = {'Id'}

TId.default = {0}

TId.struct = {{name = 'Id', is_array = false, struct = nil}}

function TId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'Id', self.Id, 'uint8', false, errs, need_convert)

    TId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TId.proto_property, errs, need_convert)
    return self
end

function TId:unpack(_)
    return self.Id
end

MAccountService.Id = TId

---@class MAccountService.PreviousPasswordsDisallowed
---@field PreviousPasswordsDisallowed integer
local TPreviousPasswordsDisallowed = {}
TPreviousPasswordsDisallowed.__index = TPreviousPasswordsDisallowed
TPreviousPasswordsDisallowed.group = {}

local function TPreviousPasswordsDisallowed_from_obj(obj)
    return setmetatable(obj, TPreviousPasswordsDisallowed)
end

function TPreviousPasswordsDisallowed.new(PreviousPasswordsDisallowed)
    return TPreviousPasswordsDisallowed_from_obj({PreviousPasswordsDisallowed = PreviousPasswordsDisallowed or 5})
end
---@param obj MAccountService.PreviousPasswordsDisallowed
function TPreviousPasswordsDisallowed:init_from_obj(obj)
    self.PreviousPasswordsDisallowed = obj.PreviousPasswordsDisallowed or 5
end

function TPreviousPasswordsDisallowed:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPreviousPasswordsDisallowed.group)
end

TPreviousPasswordsDisallowed.from_obj = TPreviousPasswordsDisallowed_from_obj

TPreviousPasswordsDisallowed.proto_property = {'PreviousPasswordsDisallowed'}

TPreviousPasswordsDisallowed.default = {0}

TPreviousPasswordsDisallowed.struct = {{name = 'PreviousPasswordsDisallowed', is_array = false, struct = nil}}

function TPreviousPasswordsDisallowed:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PreviousPasswordsDisallowed', self.PreviousPasswordsDisallowed, 'uint8', false, errs,
        need_convert)

    TPreviousPasswordsDisallowed:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPreviousPasswordsDisallowed.proto_property, errs, need_convert)
    return self
end

function TPreviousPasswordsDisallowed:unpack(_)
    return self.PreviousPasswordsDisallowed
end

MAccountService.PreviousPasswordsDisallowed = TPreviousPasswordsDisallowed

---@class MAccountService.PasswordComplexityIsLock
---@field PasswordComplexityIsLock boolean
local TPasswordComplexityIsLock = {}
TPasswordComplexityIsLock.__index = TPasswordComplexityIsLock
TPasswordComplexityIsLock.group = {}

local function TPasswordComplexityIsLock_from_obj(obj)
    return setmetatable(obj, TPasswordComplexityIsLock)
end

function TPasswordComplexityIsLock.new(PasswordComplexityIsLock)
    return TPasswordComplexityIsLock_from_obj({PasswordComplexityIsLock = PasswordComplexityIsLock or false})
end
---@param obj MAccountService.PasswordComplexityIsLock
function TPasswordComplexityIsLock:init_from_obj(obj)
    self.PasswordComplexityIsLock = obj.PasswordComplexityIsLock or false
end

function TPasswordComplexityIsLock:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPasswordComplexityIsLock.group)
end

TPasswordComplexityIsLock.from_obj = TPasswordComplexityIsLock_from_obj

TPasswordComplexityIsLock.proto_property = {'PasswordComplexityIsLock'}

TPasswordComplexityIsLock.default = {false}

TPasswordComplexityIsLock.struct = {{name = 'PasswordComplexityIsLock', is_array = false, struct = nil}}

function TPasswordComplexityIsLock:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PasswordComplexityIsLock', self.PasswordComplexityIsLock, 'bool', false, errs,
        need_convert)

    TPasswordComplexityIsLock:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPasswordComplexityIsLock.proto_property, errs, need_convert)
    return self
end

function TPasswordComplexityIsLock:unpack(_)
    return self.PasswordComplexityIsLock
end

MAccountService.PasswordComplexityIsLock = TPasswordComplexityIsLock

---@class MAccountService.TimeSource
---@field TimeSource def_types.TimeSource
local TTimeSource = {}
TTimeSource.__index = TTimeSource
TTimeSource.group = {}

local function TTimeSource_from_obj(obj)
    obj.TimeSource = obj.TimeSource and def_types.TimeSource.new(obj.TimeSource)
    return setmetatable(obj, TTimeSource)
end

function TTimeSource.new(TimeSource)
    return TTimeSource_from_obj({TimeSource = TimeSource or [=[TS_NOT_NTP]=]})
end
---@param obj MAccountService.TimeSource
function TTimeSource:init_from_obj(obj)
    self.TimeSource = obj.TimeSource or def_types.TimeSource.TS_NOT_NTP
end

function TTimeSource:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TTimeSource.group)
end

TTimeSource.from_obj = TTimeSource_from_obj

TTimeSource.proto_property = {'TimeSource'}

TTimeSource.default = {def_types.TimeSource.default}

TTimeSource.struct = {{name = 'TimeSource', is_array = false, struct = def_types.TimeSource.struct}}

function TTimeSource:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'TimeSource', self.TimeSource, 'def_types.TimeSource', false, errs, need_convert)

    TTimeSource:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TTimeSource.proto_property, errs, need_convert)
    return self
end

function TTimeSource:unpack(raw)
    local TimeSource = utils.unpack_enum(raw, self.TimeSource)
    return TimeSource
end

MAccountService.TimeSource = TTimeSource

---@class MAccountService.UserMgmtEnable
---@field UserMgmtEnable boolean
local TUserMgmtEnable = {}
TUserMgmtEnable.__index = TUserMgmtEnable
TUserMgmtEnable.group = {}

local function TUserMgmtEnable_from_obj(obj)
    return setmetatable(obj, TUserMgmtEnable)
end

function TUserMgmtEnable.new(UserMgmtEnable)
    return TUserMgmtEnable_from_obj({UserMgmtEnable = UserMgmtEnable == nil and true or UserMgmtEnable})
end
---@param obj MAccountService.UserMgmtEnable
function TUserMgmtEnable:init_from_obj(obj)
    self.UserMgmtEnable = obj.UserMgmtEnable == nil and true or obj.UserMgmtEnable
end

function TUserMgmtEnable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUserMgmtEnable.group)
end

TUserMgmtEnable.from_obj = TUserMgmtEnable_from_obj

TUserMgmtEnable.proto_property = {'UserMgmtEnable'}

TUserMgmtEnable.default = {false}

TUserMgmtEnable.struct = {{name = 'UserMgmtEnable', is_array = false, struct = nil}}

function TUserMgmtEnable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserMgmtEnable', self.UserMgmtEnable, 'bool', false, errs, need_convert)

    TUserMgmtEnable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUserMgmtEnable.proto_property, errs, need_convert)
    return self
end

function TUserMgmtEnable:unpack(_)
    return self.UserMgmtEnable
end

MAccountService.UserMgmtEnable = TUserMgmtEnable

---@class MAccountService.AccountLockoutThreshold
---@field AccountLockoutThreshold integer
local TAccountLockoutThreshold = {}
TAccountLockoutThreshold.__index = TAccountLockoutThreshold
TAccountLockoutThreshold.group = {}

local function TAccountLockoutThreshold_from_obj(obj)
    return setmetatable(obj, TAccountLockoutThreshold)
end

function TAccountLockoutThreshold.new(AccountLockoutThreshold)
    return TAccountLockoutThreshold_from_obj({AccountLockoutThreshold = AccountLockoutThreshold or 5})
end
---@param obj MAccountService.AccountLockoutThreshold
function TAccountLockoutThreshold:init_from_obj(obj)
    self.AccountLockoutThreshold = obj.AccountLockoutThreshold or 5
end

function TAccountLockoutThreshold:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountLockoutThreshold.group)
end

TAccountLockoutThreshold.from_obj = TAccountLockoutThreshold_from_obj

TAccountLockoutThreshold.proto_property = {'AccountLockoutThreshold'}

TAccountLockoutThreshold.default = {0}

TAccountLockoutThreshold.struct = {{name = 'AccountLockoutThreshold', is_array = false, struct = nil}}

function TAccountLockoutThreshold:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountLockoutThreshold', self.AccountLockoutThreshold, 'int32', false, errs,
        need_convert)

    TAccountLockoutThreshold:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountLockoutThreshold.proto_property, errs, need_convert)
    return self
end

function TAccountLockoutThreshold:unpack(_)
    return self.AccountLockoutThreshold
end

MAccountService.AccountLockoutThreshold = TAccountLockoutThreshold

---@class MAccountService.AccountLockoutDuration
---@field AccountLockoutDuration integer
local TAccountLockoutDuration = {}
TAccountLockoutDuration.__index = TAccountLockoutDuration
TAccountLockoutDuration.group = {}

local function TAccountLockoutDuration_from_obj(obj)
    return setmetatable(obj, TAccountLockoutDuration)
end

function TAccountLockoutDuration.new(AccountLockoutDuration)
    return TAccountLockoutDuration_from_obj({AccountLockoutDuration = AccountLockoutDuration or 300})
end
---@param obj MAccountService.AccountLockoutDuration
function TAccountLockoutDuration:init_from_obj(obj)
    self.AccountLockoutDuration = obj.AccountLockoutDuration or 300
end

function TAccountLockoutDuration:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountLockoutDuration.group)
end

TAccountLockoutDuration.from_obj = TAccountLockoutDuration_from_obj

TAccountLockoutDuration.proto_property = {'AccountLockoutDuration'}

TAccountLockoutDuration.default = {0}

TAccountLockoutDuration.struct = {{name = 'AccountLockoutDuration', is_array = false, struct = nil}}

function TAccountLockoutDuration:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountLockoutDuration', self.AccountLockoutDuration, 'int32', false, errs,
        need_convert)

    TAccountLockoutDuration:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountLockoutDuration.proto_property, errs, need_convert)
    return self
end

function TAccountLockoutDuration:unpack(_)
    return self.AccountLockoutDuration
end

MAccountService.AccountLockoutDuration = TAccountLockoutDuration

---@class MAccountService.PasswordExpirationDays
---@field PasswordExpirationDays integer
local TPasswordExpirationDays = {}
TPasswordExpirationDays.__index = TPasswordExpirationDays
TPasswordExpirationDays.group = {}

local function TPasswordExpirationDays_from_obj(obj)
    return setmetatable(obj, TPasswordExpirationDays)
end

function TPasswordExpirationDays.new(PasswordExpirationDays)
    return TPasswordExpirationDays_from_obj({PasswordExpirationDays = PasswordExpirationDays or 4294967295})
end
---@param obj MAccountService.PasswordExpirationDays
function TPasswordExpirationDays:init_from_obj(obj)
    self.PasswordExpirationDays = obj.PasswordExpirationDays or 4294967295
end

function TPasswordExpirationDays:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPasswordExpirationDays.group)
end

TPasswordExpirationDays.from_obj = TPasswordExpirationDays_from_obj

TPasswordExpirationDays.proto_property = {'PasswordExpirationDays'}

TPasswordExpirationDays.default = {0}

TPasswordExpirationDays.struct = {{name = 'PasswordExpirationDays', is_array = false, struct = nil}}

function TPasswordExpirationDays:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PasswordExpirationDays', self.PasswordExpirationDays, 'uint32', false, errs,
        need_convert)

    TPasswordExpirationDays:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPasswordExpirationDays.proto_property, errs, need_convert)
    return self
end

function TPasswordExpirationDays:unpack(_)
    return self.PasswordExpirationDays
end

MAccountService.PasswordExpirationDays = TPasswordExpirationDays

return MAccountService
