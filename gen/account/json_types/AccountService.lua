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
local mdb = require 'mc.mdb'

local AccountService = {}

---@class AccountService.SNMPv3TrapAccountChangePolicy
---@field SNMPv3TrapAccountChangePolicy integer
local TSNMPv3TrapAccountChangePolicy = {}
TSNMPv3TrapAccountChangePolicy.__index = TSNMPv3TrapAccountChangePolicy
TSNMPv3TrapAccountChangePolicy.group = {}

local function TSNMPv3TrapAccountChangePolicy_from_obj(obj)
    return setmetatable(obj, TSNMPv3TrapAccountChangePolicy)
end

function TSNMPv3TrapAccountChangePolicy.new(SNMPv3TrapAccountChangePolicy)
    return TSNMPv3TrapAccountChangePolicy_from_obj({SNMPv3TrapAccountChangePolicy = SNMPv3TrapAccountChangePolicy or 0})
end
---@param obj AccountService.SNMPv3TrapAccountChangePolicy
function TSNMPv3TrapAccountChangePolicy:init_from_obj(obj)
    self.SNMPv3TrapAccountChangePolicy = obj.SNMPv3TrapAccountChangePolicy or 0
end

function TSNMPv3TrapAccountChangePolicy:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSNMPv3TrapAccountChangePolicy.group)
end

TSNMPv3TrapAccountChangePolicy.from_obj = TSNMPv3TrapAccountChangePolicy_from_obj

TSNMPv3TrapAccountChangePolicy.proto_property = {'SNMPv3TrapAccountChangePolicy'}

TSNMPv3TrapAccountChangePolicy.default = {0}

TSNMPv3TrapAccountChangePolicy.struct = {{name = 'SNMPv3TrapAccountChangePolicy', is_array = false, struct = nil}}

function TSNMPv3TrapAccountChangePolicy:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SNMPv3TrapAccountChangePolicy', self.SNMPv3TrapAccountChangePolicy, 'uint8', false,
        errs, need_convert)

    if self.SNMPv3TrapAccountChangePolicy ~= nil then
        validate.ranges(prefix .. 'SNMPv3TrapAccountChangePolicy', self.SNMPv3TrapAccountChangePolicy, 0, 1, errs,
            need_convert)
    end

    TSNMPv3TrapAccountChangePolicy:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSNMPv3TrapAccountChangePolicy.proto_property, errs, need_convert)
    return self
end

function TSNMPv3TrapAccountChangePolicy:unpack(_)
    return self.SNMPv3TrapAccountChangePolicy
end

AccountService.SNMPv3TrapAccountChangePolicy = TSNMPv3TrapAccountChangePolicy

---@class AccountService.UserNamePasswordPrefixCompareLength
---@field UserNamePasswordPrefixCompareLength integer
local TUserNamePasswordPrefixCompareLength = {}
TUserNamePasswordPrefixCompareLength.__index = TUserNamePasswordPrefixCompareLength
TUserNamePasswordPrefixCompareLength.group = {}

local function TUserNamePasswordPrefixCompareLength_from_obj(obj)
    return setmetatable(obj, TUserNamePasswordPrefixCompareLength)
end

function TUserNamePasswordPrefixCompareLength.new(UserNamePasswordPrefixCompareLength)
    return TUserNamePasswordPrefixCompareLength_from_obj({
        UserNamePasswordPrefixCompareLength = UserNamePasswordPrefixCompareLength or 4
    })
end
---@param obj AccountService.UserNamePasswordPrefixCompareLength
function TUserNamePasswordPrefixCompareLength:init_from_obj(obj)
    self.UserNamePasswordPrefixCompareLength = obj.UserNamePasswordPrefixCompareLength or 4
end

function TUserNamePasswordPrefixCompareLength:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUserNamePasswordPrefixCompareLength.group)
end

TUserNamePasswordPrefixCompareLength.from_obj = TUserNamePasswordPrefixCompareLength_from_obj

TUserNamePasswordPrefixCompareLength.proto_property = {'UserNamePasswordPrefixCompareLength'}

TUserNamePasswordPrefixCompareLength.default = {0}

TUserNamePasswordPrefixCompareLength.struct = {
    {name = 'UserNamePasswordPrefixCompareLength', is_array = false, struct = nil}
}

function TUserNamePasswordPrefixCompareLength:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserNamePasswordPrefixCompareLength', self.UserNamePasswordPrefixCompareLength,
        'uint8', false, errs, need_convert)

    if self.UserNamePasswordPrefixCompareLength ~= nil then
        validate.ranges(prefix .. 'UserNamePasswordPrefixCompareLength', self.UserNamePasswordPrefixCompareLength, 4,
            20, errs, need_convert)
    end

    TUserNamePasswordPrefixCompareLength:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUserNamePasswordPrefixCompareLength.proto_property, errs, need_convert)
    return self
end

function TUserNamePasswordPrefixCompareLength:unpack(_)
    return self.UserNamePasswordPrefixCompareLength
end

AccountService.UserNamePasswordPrefixCompareLength = TUserNamePasswordPrefixCompareLength

---@class AccountService.UserNamePasswordPrefixCompareEnabled
---@field UserNamePasswordPrefixCompareEnabled boolean
local TUserNamePasswordPrefixCompareEnabled = {}
TUserNamePasswordPrefixCompareEnabled.__index = TUserNamePasswordPrefixCompareEnabled
TUserNamePasswordPrefixCompareEnabled.group = {}

local function TUserNamePasswordPrefixCompareEnabled_from_obj(obj)
    return setmetatable(obj, TUserNamePasswordPrefixCompareEnabled)
end

function TUserNamePasswordPrefixCompareEnabled.new(UserNamePasswordPrefixCompareEnabled)
    return TUserNamePasswordPrefixCompareEnabled_from_obj({
        UserNamePasswordPrefixCompareEnabled = UserNamePasswordPrefixCompareEnabled or false
    })
end
---@param obj AccountService.UserNamePasswordPrefixCompareEnabled
function TUserNamePasswordPrefixCompareEnabled:init_from_obj(obj)
    self.UserNamePasswordPrefixCompareEnabled = obj.UserNamePasswordPrefixCompareEnabled or false
end

function TUserNamePasswordPrefixCompareEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUserNamePasswordPrefixCompareEnabled.group)
end

TUserNamePasswordPrefixCompareEnabled.from_obj = TUserNamePasswordPrefixCompareEnabled_from_obj

TUserNamePasswordPrefixCompareEnabled.proto_property = {'UserNamePasswordPrefixCompareEnabled'}

TUserNamePasswordPrefixCompareEnabled.default = {false}

TUserNamePasswordPrefixCompareEnabled.struct = {
    {name = 'UserNamePasswordPrefixCompareEnabled', is_array = false, struct = nil}
}

function TUserNamePasswordPrefixCompareEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserNamePasswordPrefixCompareEnabled', self.UserNamePasswordPrefixCompareEnabled,
        'bool', false, errs, need_convert)

    TUserNamePasswordPrefixCompareEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUserNamePasswordPrefixCompareEnabled.proto_property, errs, need_convert)
    return self
end

function TUserNamePasswordPrefixCompareEnabled:unpack(_)
    return self.UserNamePasswordPrefixCompareEnabled
end

AccountService.UserNamePasswordPrefixCompareEnabled = TUserNamePasswordPrefixCompareEnabled

---@class AccountService.SNMPv3TrapAccountLimitPolicy
---@field SNMPv3TrapAccountLimitPolicy integer
local TSNMPv3TrapAccountLimitPolicy = {}
TSNMPv3TrapAccountLimitPolicy.__index = TSNMPv3TrapAccountLimitPolicy
TSNMPv3TrapAccountLimitPolicy.group = {}

local function TSNMPv3TrapAccountLimitPolicy_from_obj(obj)
    return setmetatable(obj, TSNMPv3TrapAccountLimitPolicy)
end

function TSNMPv3TrapAccountLimitPolicy.new(SNMPv3TrapAccountLimitPolicy)
    return TSNMPv3TrapAccountLimitPolicy_from_obj({SNMPv3TrapAccountLimitPolicy = SNMPv3TrapAccountLimitPolicy or 2})
end
---@param obj AccountService.SNMPv3TrapAccountLimitPolicy
function TSNMPv3TrapAccountLimitPolicy:init_from_obj(obj)
    self.SNMPv3TrapAccountLimitPolicy = obj.SNMPv3TrapAccountLimitPolicy or 2
end

function TSNMPv3TrapAccountLimitPolicy:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSNMPv3TrapAccountLimitPolicy.group)
end

TSNMPv3TrapAccountLimitPolicy.from_obj = TSNMPv3TrapAccountLimitPolicy_from_obj

TSNMPv3TrapAccountLimitPolicy.proto_property = {'SNMPv3TrapAccountLimitPolicy'}

TSNMPv3TrapAccountLimitPolicy.default = {0}

TSNMPv3TrapAccountLimitPolicy.struct = {{name = 'SNMPv3TrapAccountLimitPolicy', is_array = false, struct = nil}}

function TSNMPv3TrapAccountLimitPolicy:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SNMPv3TrapAccountLimitPolicy', self.SNMPv3TrapAccountLimitPolicy, 'uint8', false, errs,
        need_convert)

    TSNMPv3TrapAccountLimitPolicy:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSNMPv3TrapAccountLimitPolicy.proto_property, errs, need_convert)
    return self
end

function TSNMPv3TrapAccountLimitPolicy:unpack(_)
    return self.SNMPv3TrapAccountLimitPolicy
end

AccountService.SNMPv3TrapAccountLimitPolicy = TSNMPv3TrapAccountLimitPolicy

---@class AccountService.OSAdministratorPrivilegeEnabled
---@field OSAdministratorPrivilegeEnabled boolean
local TOSAdministratorPrivilegeEnabled = {}
TOSAdministratorPrivilegeEnabled.__index = TOSAdministratorPrivilegeEnabled
TOSAdministratorPrivilegeEnabled.group = {}

local function TOSAdministratorPrivilegeEnabled_from_obj(obj)
    return setmetatable(obj, TOSAdministratorPrivilegeEnabled)
end

function TOSAdministratorPrivilegeEnabled.new(OSAdministratorPrivilegeEnabled)
    return TOSAdministratorPrivilegeEnabled_from_obj({
        OSAdministratorPrivilegeEnabled = OSAdministratorPrivilegeEnabled == nil and true or
            OSAdministratorPrivilegeEnabled
    })
end
---@param obj AccountService.OSAdministratorPrivilegeEnabled
function TOSAdministratorPrivilegeEnabled:init_from_obj(obj)
    self.OSAdministratorPrivilegeEnabled = obj.OSAdministratorPrivilegeEnabled == nil and true or
                                               obj.OSAdministratorPrivilegeEnabled
end

function TOSAdministratorPrivilegeEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TOSAdministratorPrivilegeEnabled.group)
end

TOSAdministratorPrivilegeEnabled.from_obj = TOSAdministratorPrivilegeEnabled_from_obj

TOSAdministratorPrivilegeEnabled.proto_property = {'OSAdministratorPrivilegeEnabled'}

TOSAdministratorPrivilegeEnabled.default = {false}

TOSAdministratorPrivilegeEnabled.struct = {{name = 'OSAdministratorPrivilegeEnabled', is_array = false, struct = nil}}

function TOSAdministratorPrivilegeEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'OSAdministratorPrivilegeEnabled', self.OSAdministratorPrivilegeEnabled, 'bool', false,
        errs, need_convert)

    TOSAdministratorPrivilegeEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TOSAdministratorPrivilegeEnabled.proto_property, errs, need_convert)
    return self
end

function TOSAdministratorPrivilegeEnabled:unpack(_)
    return self.OSAdministratorPrivilegeEnabled
end

AccountService.OSAdministratorPrivilegeEnabled = TOSAdministratorPrivilegeEnabled

---@class AccountService.HostUserManagementEnabled
---@field HostUserManagementEnabled boolean
local THostUserManagementEnabled = {}
THostUserManagementEnabled.__index = THostUserManagementEnabled
THostUserManagementEnabled.group = {}

local function THostUserManagementEnabled_from_obj(obj)
    return setmetatable(obj, THostUserManagementEnabled)
end

function THostUserManagementEnabled.new(HostUserManagementEnabled)
    return THostUserManagementEnabled_from_obj({
        HostUserManagementEnabled = HostUserManagementEnabled == nil and true or HostUserManagementEnabled
    })
end
---@param obj AccountService.HostUserManagementEnabled
function THostUserManagementEnabled:init_from_obj(obj)
    self.HostUserManagementEnabled = obj.HostUserManagementEnabled == nil and true or obj.HostUserManagementEnabled
end

function THostUserManagementEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, THostUserManagementEnabled.group)
end

THostUserManagementEnabled.from_obj = THostUserManagementEnabled_from_obj

THostUserManagementEnabled.proto_property = {'HostUserManagementEnabled'}

THostUserManagementEnabled.default = {false}

THostUserManagementEnabled.struct = {{name = 'HostUserManagementEnabled', is_array = false, struct = nil}}

function THostUserManagementEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'HostUserManagementEnabled', self.HostUserManagementEnabled, 'bool', false, errs,
        need_convert)

    THostUserManagementEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, THostUserManagementEnabled.proto_property, errs, need_convert)
    return self
end

function THostUserManagementEnabled:unpack(_)
    return self.HostUserManagementEnabled
end

AccountService.HostUserManagementEnabled = THostUserManagementEnabled

---@class AccountService.MaxHistoryPasswordCount
---@field MaxHistoryPasswordCount integer
local TMaxHistoryPasswordCount = {}
TMaxHistoryPasswordCount.__index = TMaxHistoryPasswordCount
TMaxHistoryPasswordCount.group = {}

local function TMaxHistoryPasswordCount_from_obj(obj)
    return setmetatable(obj, TMaxHistoryPasswordCount)
end

function TMaxHistoryPasswordCount.new(MaxHistoryPasswordCount)
    return TMaxHistoryPasswordCount_from_obj({MaxHistoryPasswordCount = MaxHistoryPasswordCount or 5})
end
---@param obj AccountService.MaxHistoryPasswordCount
function TMaxHistoryPasswordCount:init_from_obj(obj)
    self.MaxHistoryPasswordCount = obj.MaxHistoryPasswordCount or 5
end

function TMaxHistoryPasswordCount:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMaxHistoryPasswordCount.group)
end

TMaxHistoryPasswordCount.from_obj = TMaxHistoryPasswordCount_from_obj

TMaxHistoryPasswordCount.proto_property = {'MaxHistoryPasswordCount'}

TMaxHistoryPasswordCount.default = {0}

TMaxHistoryPasswordCount.struct = {{name = 'MaxHistoryPasswordCount', is_array = false, struct = nil}}

function TMaxHistoryPasswordCount:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'MaxHistoryPasswordCount', self.MaxHistoryPasswordCount, 'uint8', false, errs,
        need_convert)

    if self.MaxHistoryPasswordCount ~= nil then
        validate.ranges(prefix .. 'MaxHistoryPasswordCount', self.MaxHistoryPasswordCount, 5, 100, errs, need_convert)
    end

    TMaxHistoryPasswordCount:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMaxHistoryPasswordCount.proto_property, errs, need_convert)
    return self
end

function TMaxHistoryPasswordCount:unpack(_)
    return self.MaxHistoryPasswordCount
end

AccountService.MaxHistoryPasswordCount = TMaxHistoryPasswordCount

---@class AccountService.HistoryPasswordCount
---@field HistoryPasswordCount integer
local THistoryPasswordCount = {}
THistoryPasswordCount.__index = THistoryPasswordCount
THistoryPasswordCount.group = {}

local function THistoryPasswordCount_from_obj(obj)
    return setmetatable(obj, THistoryPasswordCount)
end

function THistoryPasswordCount.new(HistoryPasswordCount)
    return THistoryPasswordCount_from_obj({HistoryPasswordCount = HistoryPasswordCount or 5})
end
---@param obj AccountService.HistoryPasswordCount
function THistoryPasswordCount:init_from_obj(obj)
    self.HistoryPasswordCount = obj.HistoryPasswordCount or 5
end

function THistoryPasswordCount:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, THistoryPasswordCount.group)
end

THistoryPasswordCount.from_obj = THistoryPasswordCount_from_obj

THistoryPasswordCount.proto_property = {'HistoryPasswordCount'}

THistoryPasswordCount.default = {0}

THistoryPasswordCount.struct = {{name = 'HistoryPasswordCount', is_array = false, struct = nil}}

function THistoryPasswordCount:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'HistoryPasswordCount', self.HistoryPasswordCount, 'uint8', false, errs, need_convert)

    if self.HistoryPasswordCount ~= nil then
        validate.ranges(prefix .. 'HistoryPasswordCount', self.HistoryPasswordCount, 0, 100, errs, need_convert)
    end

    THistoryPasswordCount:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, THistoryPasswordCount.proto_property, errs, need_convert)
    return self
end

function THistoryPasswordCount:unpack(_)
    return self.HistoryPasswordCount
end

AccountService.HistoryPasswordCount = THistoryPasswordCount

---@class AccountService.WeakPasswordDictionaryEnabled
---@field WeakPasswordDictionaryEnabled boolean
local TWeakPasswordDictionaryEnabled = {}
TWeakPasswordDictionaryEnabled.__index = TWeakPasswordDictionaryEnabled
TWeakPasswordDictionaryEnabled.group = {}

local function TWeakPasswordDictionaryEnabled_from_obj(obj)
    return setmetatable(obj, TWeakPasswordDictionaryEnabled)
end

function TWeakPasswordDictionaryEnabled.new(WeakPasswordDictionaryEnabled)
    return TWeakPasswordDictionaryEnabled_from_obj({
        WeakPasswordDictionaryEnabled = WeakPasswordDictionaryEnabled == nil and true or WeakPasswordDictionaryEnabled
    })
end
---@param obj AccountService.WeakPasswordDictionaryEnabled
function TWeakPasswordDictionaryEnabled:init_from_obj(obj)
    self.WeakPasswordDictionaryEnabled = obj.WeakPasswordDictionaryEnabled == nil and true or
                                             obj.WeakPasswordDictionaryEnabled
end

function TWeakPasswordDictionaryEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TWeakPasswordDictionaryEnabled.group)
end

TWeakPasswordDictionaryEnabled.from_obj = TWeakPasswordDictionaryEnabled_from_obj

TWeakPasswordDictionaryEnabled.proto_property = {'WeakPasswordDictionaryEnabled'}

TWeakPasswordDictionaryEnabled.default = {false}

TWeakPasswordDictionaryEnabled.struct = {{name = 'WeakPasswordDictionaryEnabled', is_array = false, struct = nil}}

function TWeakPasswordDictionaryEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'WeakPasswordDictionaryEnabled', self.WeakPasswordDictionaryEnabled, 'bool', false,
        errs, need_convert)

    TWeakPasswordDictionaryEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TWeakPasswordDictionaryEnabled.proto_property, errs, need_convert)
    return self
end

function TWeakPasswordDictionaryEnabled:unpack(_)
    return self.WeakPasswordDictionaryEnabled
end

AccountService.WeakPasswordDictionaryEnabled = TWeakPasswordDictionaryEnabled

---@class AccountService.InactiveDaysThreshold
---@field InactiveDaysThreshold integer
local TInactiveDaysThreshold = {}
TInactiveDaysThreshold.__index = TInactiveDaysThreshold
TInactiveDaysThreshold.group = {}

local function TInactiveDaysThreshold_from_obj(obj)
    return setmetatable(obj, TInactiveDaysThreshold)
end

function TInactiveDaysThreshold.new(InactiveDaysThreshold)
    return TInactiveDaysThreshold_from_obj({InactiveDaysThreshold = InactiveDaysThreshold or 0})
end
---@param obj AccountService.InactiveDaysThreshold
function TInactiveDaysThreshold:init_from_obj(obj)
    self.InactiveDaysThreshold = obj.InactiveDaysThreshold or 0
end

function TInactiveDaysThreshold:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TInactiveDaysThreshold.group)
end

TInactiveDaysThreshold.from_obj = TInactiveDaysThreshold_from_obj

TInactiveDaysThreshold.proto_property = {'InactiveDaysThreshold'}

TInactiveDaysThreshold.default = {0}

TInactiveDaysThreshold.struct = {{name = 'InactiveDaysThreshold', is_array = false, struct = nil}}

function TInactiveDaysThreshold:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'InactiveDaysThreshold', self.InactiveDaysThreshold, 'uint32', false, errs, need_convert)

    if self.InactiveDaysThreshold ~= nil then
        validate.ranges(prefix .. 'InactiveDaysThreshold', self.InactiveDaysThreshold, 0, 365, errs, need_convert)
    end

    TInactiveDaysThreshold:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TInactiveDaysThreshold.proto_property, errs, need_convert)
    return self
end

function TInactiveDaysThreshold:unpack(_)
    return self.InactiveDaysThreshold
end

AccountService.InactiveDaysThreshold = TInactiveDaysThreshold

---@class AccountService.SNMPv3TrapAccountId
---@field SNMPv3TrapAccountId integer
local TSNMPv3TrapAccountId = {}
TSNMPv3TrapAccountId.__index = TSNMPv3TrapAccountId
TSNMPv3TrapAccountId.group = {}

local function TSNMPv3TrapAccountId_from_obj(obj)
    return setmetatable(obj, TSNMPv3TrapAccountId)
end

function TSNMPv3TrapAccountId.new(SNMPv3TrapAccountId)
    return TSNMPv3TrapAccountId_from_obj({SNMPv3TrapAccountId = SNMPv3TrapAccountId or 2})
end
---@param obj AccountService.SNMPv3TrapAccountId
function TSNMPv3TrapAccountId:init_from_obj(obj)
    self.SNMPv3TrapAccountId = obj.SNMPv3TrapAccountId or 2
end

function TSNMPv3TrapAccountId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSNMPv3TrapAccountId.group)
end

TSNMPv3TrapAccountId.from_obj = TSNMPv3TrapAccountId_from_obj

TSNMPv3TrapAccountId.proto_property = {'SNMPv3TrapAccountId'}

TSNMPv3TrapAccountId.default = {0}

TSNMPv3TrapAccountId.struct = {{name = 'SNMPv3TrapAccountId', is_array = false, struct = nil}}

function TSNMPv3TrapAccountId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SNMPv3TrapAccountId', self.SNMPv3TrapAccountId, 'uint8', false, errs, need_convert)

    if self.SNMPv3TrapAccountId ~= nil then
        validate.ranges(prefix .. 'SNMPv3TrapAccountId', self.SNMPv3TrapAccountId, 0, 17, errs, need_convert)
    end

    TSNMPv3TrapAccountId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSNMPv3TrapAccountId.proto_property, errs, need_convert)
    return self
end

function TSNMPv3TrapAccountId:unpack(_)
    return self.SNMPv3TrapAccountId
end

AccountService.SNMPv3TrapAccountId = TSNMPv3TrapAccountId

---@class AccountService.EmergencyLoginAccountId
---@field EmergencyLoginAccountId integer
local TEmergencyLoginAccountId = {}
TEmergencyLoginAccountId.__index = TEmergencyLoginAccountId
TEmergencyLoginAccountId.group = {}

local function TEmergencyLoginAccountId_from_obj(obj)
    return setmetatable(obj, TEmergencyLoginAccountId)
end

function TEmergencyLoginAccountId.new(EmergencyLoginAccountId)
    return TEmergencyLoginAccountId_from_obj({EmergencyLoginAccountId = EmergencyLoginAccountId or 0})
end
---@param obj AccountService.EmergencyLoginAccountId
function TEmergencyLoginAccountId:init_from_obj(obj)
    self.EmergencyLoginAccountId = obj.EmergencyLoginAccountId or 0
end

function TEmergencyLoginAccountId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TEmergencyLoginAccountId.group)
end

TEmergencyLoginAccountId.from_obj = TEmergencyLoginAccountId_from_obj

TEmergencyLoginAccountId.proto_property = {'EmergencyLoginAccountId'}

TEmergencyLoginAccountId.default = {0}

TEmergencyLoginAccountId.struct = {{name = 'EmergencyLoginAccountId', is_array = false, struct = nil}}

function TEmergencyLoginAccountId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EmergencyLoginAccountId', self.EmergencyLoginAccountId, 'uint8', false, errs,
        need_convert)

    if self.EmergencyLoginAccountId ~= nil then
        validate.ranges(prefix .. 'EmergencyLoginAccountId', self.EmergencyLoginAccountId, 0, 17, errs, need_convert)
    end

    TEmergencyLoginAccountId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TEmergencyLoginAccountId.proto_property, errs, need_convert)
    return self
end

function TEmergencyLoginAccountId:unpack(_)
    return self.EmergencyLoginAccountId
end

AccountService.EmergencyLoginAccountId = TEmergencyLoginAccountId

---@class AccountService.MaxPasswordValidDays
---@field MaxPasswordValidDays integer
local TMaxPasswordValidDays = {}
TMaxPasswordValidDays.__index = TMaxPasswordValidDays
TMaxPasswordValidDays.group = {}

local function TMaxPasswordValidDays_from_obj(obj)
    return setmetatable(obj, TMaxPasswordValidDays)
end

function TMaxPasswordValidDays.new(MaxPasswordValidDays)
    return TMaxPasswordValidDays_from_obj({MaxPasswordValidDays = MaxPasswordValidDays or 0})
end
---@param obj AccountService.MaxPasswordValidDays
function TMaxPasswordValidDays:init_from_obj(obj)
    self.MaxPasswordValidDays = obj.MaxPasswordValidDays or 0
end

function TMaxPasswordValidDays:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMaxPasswordValidDays.group)
end

TMaxPasswordValidDays.from_obj = TMaxPasswordValidDays_from_obj

TMaxPasswordValidDays.proto_property = {'MaxPasswordValidDays'}

TMaxPasswordValidDays.default = {0}

TMaxPasswordValidDays.struct = {{name = 'MaxPasswordValidDays', is_array = false, struct = nil}}

function TMaxPasswordValidDays:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'MaxPasswordValidDays', self.MaxPasswordValidDays, 'uint32', false, errs, need_convert)

    if self.MaxPasswordValidDays ~= nil then
        validate.ranges(prefix .. 'MaxPasswordValidDays', self.MaxPasswordValidDays, 0, 365, errs, need_convert)
    end

    TMaxPasswordValidDays:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMaxPasswordValidDays.proto_property, errs, need_convert)
    return self
end

function TMaxPasswordValidDays:unpack(_)
    return self.MaxPasswordValidDays
end

AccountService.MaxPasswordValidDays = TMaxPasswordValidDays

---@class AccountService.MinPasswordValidDays
---@field MinPasswordValidDays integer
local TMinPasswordValidDays = {}
TMinPasswordValidDays.__index = TMinPasswordValidDays
TMinPasswordValidDays.group = {}

local function TMinPasswordValidDays_from_obj(obj)
    return setmetatable(obj, TMinPasswordValidDays)
end

function TMinPasswordValidDays.new(MinPasswordValidDays)
    return TMinPasswordValidDays_from_obj({MinPasswordValidDays = MinPasswordValidDays or 0})
end
---@param obj AccountService.MinPasswordValidDays
function TMinPasswordValidDays:init_from_obj(obj)
    self.MinPasswordValidDays = obj.MinPasswordValidDays or 0
end

function TMinPasswordValidDays:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMinPasswordValidDays.group)
end

TMinPasswordValidDays.from_obj = TMinPasswordValidDays_from_obj

TMinPasswordValidDays.proto_property = {'MinPasswordValidDays'}

TMinPasswordValidDays.default = {0}

TMinPasswordValidDays.struct = {{name = 'MinPasswordValidDays', is_array = false, struct = nil}}

function TMinPasswordValidDays:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'MinPasswordValidDays', self.MinPasswordValidDays, 'uint32', false, errs, need_convert)

    if self.MinPasswordValidDays ~= nil then
        validate.ranges(prefix .. 'MinPasswordValidDays', self.MinPasswordValidDays, 0, 365, errs, need_convert)
    end

    TMinPasswordValidDays:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMinPasswordValidDays.proto_property, errs, need_convert)
    return self
end

function TMinPasswordValidDays:unpack(_)
    return self.MinPasswordValidDays
end

AccountService.MinPasswordValidDays = TMinPasswordValidDays

---@class AccountService.InitialAccountPrivilegeRestrictEnabled
---@field InitialAccountPrivilegeRestrictEnabled boolean
local TInitialAccountPrivilegeRestrictEnabled = {}
TInitialAccountPrivilegeRestrictEnabled.__index = TInitialAccountPrivilegeRestrictEnabled
TInitialAccountPrivilegeRestrictEnabled.group = {}

local function TInitialAccountPrivilegeRestrictEnabled_from_obj(obj)
    return setmetatable(obj, TInitialAccountPrivilegeRestrictEnabled)
end

function TInitialAccountPrivilegeRestrictEnabled.new(InitialAccountPrivilegeRestrictEnabled)
    return TInitialAccountPrivilegeRestrictEnabled_from_obj({
        InitialAccountPrivilegeRestrictEnabled = InitialAccountPrivilegeRestrictEnabled or false
    })
end
---@param obj AccountService.InitialAccountPrivilegeRestrictEnabled
function TInitialAccountPrivilegeRestrictEnabled:init_from_obj(obj)
    self.InitialAccountPrivilegeRestrictEnabled = obj.InitialAccountPrivilegeRestrictEnabled or false
end

function TInitialAccountPrivilegeRestrictEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TInitialAccountPrivilegeRestrictEnabled.group)
end

TInitialAccountPrivilegeRestrictEnabled.from_obj = TInitialAccountPrivilegeRestrictEnabled_from_obj

TInitialAccountPrivilegeRestrictEnabled.proto_property = {'InitialAccountPrivilegeRestrictEnabled'}

TInitialAccountPrivilegeRestrictEnabled.default = {false}

TInitialAccountPrivilegeRestrictEnabled.struct = {
    {name = 'InitialAccountPrivilegeRestrictEnabled', is_array = false, struct = nil}
}

function TInitialAccountPrivilegeRestrictEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'InitialAccountPrivilegeRestrictEnabled', self.InitialAccountPrivilegeRestrictEnabled,
        'bool', false, errs, need_convert)

    TInitialAccountPrivilegeRestrictEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TInitialAccountPrivilegeRestrictEnabled.proto_property, errs, need_convert)
    return self
end

function TInitialAccountPrivilegeRestrictEnabled:unpack(_)
    return self.InitialAccountPrivilegeRestrictEnabled
end

AccountService.InitialAccountPrivilegeRestrictEnabled = TInitialAccountPrivilegeRestrictEnabled

---@class AccountService.InitialPasswordNeedModify
---@field InitialPasswordNeedModify boolean
local TInitialPasswordNeedModify = {}
TInitialPasswordNeedModify.__index = TInitialPasswordNeedModify
TInitialPasswordNeedModify.group = {}

local function TInitialPasswordNeedModify_from_obj(obj)
    return setmetatable(obj, TInitialPasswordNeedModify)
end

function TInitialPasswordNeedModify.new(InitialPasswordNeedModify)
    return TInitialPasswordNeedModify_from_obj({
        InitialPasswordNeedModify = InitialPasswordNeedModify == nil and true or InitialPasswordNeedModify
    })
end
---@param obj AccountService.InitialPasswordNeedModify
function TInitialPasswordNeedModify:init_from_obj(obj)
    self.InitialPasswordNeedModify = obj.InitialPasswordNeedModify == nil and true or obj.InitialPasswordNeedModify
end

function TInitialPasswordNeedModify:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TInitialPasswordNeedModify.group)
end

TInitialPasswordNeedModify.from_obj = TInitialPasswordNeedModify_from_obj

TInitialPasswordNeedModify.proto_property = {'InitialPasswordNeedModify'}

TInitialPasswordNeedModify.default = {false}

TInitialPasswordNeedModify.struct = {{name = 'InitialPasswordNeedModify', is_array = false, struct = nil}}

function TInitialPasswordNeedModify:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'InitialPasswordNeedModify', self.InitialPasswordNeedModify, 'bool', false, errs,
        need_convert)

    TInitialPasswordNeedModify:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TInitialPasswordNeedModify.proto_property, errs, need_convert)
    return self
end

function TInitialPasswordNeedModify:unpack(_)
    return self.InitialPasswordNeedModify
end

AccountService.InitialPasswordNeedModify = TInitialPasswordNeedModify

---@class AccountService.InitialPasswordPromptEnable
---@field InitialPasswordPromptEnable boolean
local TInitialPasswordPromptEnable = {}
TInitialPasswordPromptEnable.__index = TInitialPasswordPromptEnable
TInitialPasswordPromptEnable.group = {}

local function TInitialPasswordPromptEnable_from_obj(obj)
    return setmetatable(obj, TInitialPasswordPromptEnable)
end

function TInitialPasswordPromptEnable.new(InitialPasswordPromptEnable)
    return TInitialPasswordPromptEnable_from_obj({
        InitialPasswordPromptEnable = InitialPasswordPromptEnable == nil and true or InitialPasswordPromptEnable
    })
end
---@param obj AccountService.InitialPasswordPromptEnable
function TInitialPasswordPromptEnable:init_from_obj(obj)
    self.InitialPasswordPromptEnable = obj.InitialPasswordPromptEnable == nil and true or
                                           obj.InitialPasswordPromptEnable
end

function TInitialPasswordPromptEnable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TInitialPasswordPromptEnable.group)
end

TInitialPasswordPromptEnable.from_obj = TInitialPasswordPromptEnable_from_obj

TInitialPasswordPromptEnable.proto_property = {'InitialPasswordPromptEnable'}

TInitialPasswordPromptEnable.default = {false}

TInitialPasswordPromptEnable.struct = {{name = 'InitialPasswordPromptEnable', is_array = false, struct = nil}}

function TInitialPasswordPromptEnable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'InitialPasswordPromptEnable', self.InitialPasswordPromptEnable, 'bool', false, errs,
        need_convert)

    TInitialPasswordPromptEnable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TInitialPasswordPromptEnable.proto_property, errs, need_convert)
    return self
end

function TInitialPasswordPromptEnable:unpack(_)
    return self.InitialPasswordPromptEnable
end

AccountService.InitialPasswordPromptEnable = TInitialPasswordPromptEnable

---@class AccountService.PasswordComplexityEnable
---@field PasswordComplexityEnable boolean
local TPasswordComplexityEnable = {}
TPasswordComplexityEnable.__index = TPasswordComplexityEnable
TPasswordComplexityEnable.group = {}

local function TPasswordComplexityEnable_from_obj(obj)
    return setmetatable(obj, TPasswordComplexityEnable)
end

function TPasswordComplexityEnable.new(PasswordComplexityEnable)
    return TPasswordComplexityEnable_from_obj({
        PasswordComplexityEnable = PasswordComplexityEnable == nil and true or PasswordComplexityEnable
    })
end
---@param obj AccountService.PasswordComplexityEnable
function TPasswordComplexityEnable:init_from_obj(obj)
    self.PasswordComplexityEnable = obj.PasswordComplexityEnable == nil and true or obj.PasswordComplexityEnable
end

function TPasswordComplexityEnable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPasswordComplexityEnable.group)
end

TPasswordComplexityEnable.from_obj = TPasswordComplexityEnable_from_obj

TPasswordComplexityEnable.proto_property = {'PasswordComplexityEnable'}

TPasswordComplexityEnable.default = {false}

TPasswordComplexityEnable.struct = {{name = 'PasswordComplexityEnable', is_array = false, struct = nil}}

function TPasswordComplexityEnable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PasswordComplexityEnable', self.PasswordComplexityEnable, 'bool', false, errs,
        need_convert)

    TPasswordComplexityEnable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPasswordComplexityEnable.proto_property, errs, need_convert)
    return self
end

function TPasswordComplexityEnable:unpack(_)
    return self.PasswordComplexityEnable
end

AccountService.PasswordComplexityEnable = TPasswordComplexityEnable

---@class AccountService.ServiceEnabled
---@field ServiceEnabled boolean
local TServiceEnabled = {}
TServiceEnabled.__index = TServiceEnabled
TServiceEnabled.group = {}

local function TServiceEnabled_from_obj(obj)
    return setmetatable(obj, TServiceEnabled)
end

function TServiceEnabled.new(ServiceEnabled)
    return TServiceEnabled_from_obj({ServiceEnabled = ServiceEnabled == nil and true or ServiceEnabled})
end
---@param obj AccountService.ServiceEnabled
function TServiceEnabled:init_from_obj(obj)
    self.ServiceEnabled = obj.ServiceEnabled == nil and true or obj.ServiceEnabled
end

function TServiceEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TServiceEnabled.group)
end

TServiceEnabled.from_obj = TServiceEnabled_from_obj

TServiceEnabled.proto_property = {'ServiceEnabled'}

TServiceEnabled.default = {false}

TServiceEnabled.struct = {{name = 'ServiceEnabled', is_array = false, struct = nil}}

function TServiceEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ServiceEnabled', self.ServiceEnabled, 'bool', false, errs, need_convert)

    TServiceEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TServiceEnabled.proto_property, errs, need_convert)
    return self
end

function TServiceEnabled:unpack(_)
    return self.ServiceEnabled
end

AccountService.ServiceEnabled = TServiceEnabled

---@class AccountService.MinPasswordLength
---@field MinPasswordLength integer
local TMinPasswordLength = {}
TMinPasswordLength.__index = TMinPasswordLength
TMinPasswordLength.group = {}

local function TMinPasswordLength_from_obj(obj)
    return setmetatable(obj, TMinPasswordLength)
end

function TMinPasswordLength.new(MinPasswordLength)
    return TMinPasswordLength_from_obj({MinPasswordLength = MinPasswordLength or 8})
end
---@param obj AccountService.MinPasswordLength
function TMinPasswordLength:init_from_obj(obj)
    self.MinPasswordLength = obj.MinPasswordLength or 8
end

function TMinPasswordLength:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMinPasswordLength.group)
end

TMinPasswordLength.from_obj = TMinPasswordLength_from_obj

TMinPasswordLength.proto_property = {'MinPasswordLength'}

TMinPasswordLength.default = {0}

TMinPasswordLength.struct = {{name = 'MinPasswordLength', is_array = false, struct = nil}}

function TMinPasswordLength:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'MinPasswordLength', self.MinPasswordLength, 'int32', false, errs, need_convert)

    if self.MinPasswordLength ~= nil then
        validate.ranges(prefix .. 'MinPasswordLength', self.MinPasswordLength, 8, 20, errs, need_convert)
    end

    TMinPasswordLength:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMinPasswordLength.proto_property, errs, need_convert)
    return self
end

function TMinPasswordLength:unpack(_)
    return self.MinPasswordLength
end

AccountService.MinPasswordLength = TMinPasswordLength

---@class AccountService.MaxPasswordLength
---@field MaxPasswordLength integer
local TMaxPasswordLength = {}
TMaxPasswordLength.__index = TMaxPasswordLength
TMaxPasswordLength.group = {}

local function TMaxPasswordLength_from_obj(obj)
    return setmetatable(obj, TMaxPasswordLength)
end

function TMaxPasswordLength.new(MaxPasswordLength)
    return TMaxPasswordLength_from_obj({MaxPasswordLength = MaxPasswordLength or 20})
end
---@param obj AccountService.MaxPasswordLength
function TMaxPasswordLength:init_from_obj(obj)
    self.MaxPasswordLength = obj.MaxPasswordLength or 20
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

    validate.Optional(prefix .. 'MaxPasswordLength', self.MaxPasswordLength, 'int32', true, errs, need_convert)

    TMaxPasswordLength:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMaxPasswordLength.proto_property, errs, need_convert)
    return self
end

function TMaxPasswordLength:unpack(_)
    return self.MaxPasswordLength
end

AccountService.MaxPasswordLength = TMaxPasswordLength

---@class AccountService.AuthFailureLoggingThreshold
---@field AuthFailureLoggingThreshold integer
local TAuthFailureLoggingThreshold = {}
TAuthFailureLoggingThreshold.__index = TAuthFailureLoggingThreshold
TAuthFailureLoggingThreshold.group = {}

local function TAuthFailureLoggingThreshold_from_obj(obj)
    return setmetatable(obj, TAuthFailureLoggingThreshold)
end

function TAuthFailureLoggingThreshold.new(AuthFailureLoggingThreshold)
    return TAuthFailureLoggingThreshold_from_obj({AuthFailureLoggingThreshold = AuthFailureLoggingThreshold or 0})
end
---@param obj AccountService.AuthFailureLoggingThreshold
function TAuthFailureLoggingThreshold:init_from_obj(obj)
    self.AuthFailureLoggingThreshold = obj.AuthFailureLoggingThreshold or 0
end

function TAuthFailureLoggingThreshold:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAuthFailureLoggingThreshold.group)
end

TAuthFailureLoggingThreshold.from_obj = TAuthFailureLoggingThreshold_from_obj

TAuthFailureLoggingThreshold.proto_property = {'AuthFailureLoggingThreshold'}

TAuthFailureLoggingThreshold.default = {0}

TAuthFailureLoggingThreshold.struct = {{name = 'AuthFailureLoggingThreshold', is_array = false, struct = nil}}

function TAuthFailureLoggingThreshold:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AuthFailureLoggingThreshold', self.AuthFailureLoggingThreshold, 'int32', false, errs,
        need_convert)

    TAuthFailureLoggingThreshold:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAuthFailureLoggingThreshold.proto_property, errs, need_convert)
    return self
end

function TAuthFailureLoggingThreshold:unpack(_)
    return self.AuthFailureLoggingThreshold
end

AccountService.AuthFailureLoggingThreshold = TAuthFailureLoggingThreshold

---@class AccountService.AccountLockoutCounterResetEnabled
---@field AccountLockoutCounterResetEnabled boolean
local TAccountLockoutCounterResetEnabled = {}
TAccountLockoutCounterResetEnabled.__index = TAccountLockoutCounterResetEnabled
TAccountLockoutCounterResetEnabled.group = {}

local function TAccountLockoutCounterResetEnabled_from_obj(obj)
    return setmetatable(obj, TAccountLockoutCounterResetEnabled)
end

function TAccountLockoutCounterResetEnabled.new(AccountLockoutCounterResetEnabled)
    return TAccountLockoutCounterResetEnabled_from_obj({
        AccountLockoutCounterResetEnabled = AccountLockoutCounterResetEnabled or false
    })
end
---@param obj AccountService.AccountLockoutCounterResetEnabled
function TAccountLockoutCounterResetEnabled:init_from_obj(obj)
    self.AccountLockoutCounterResetEnabled = obj.AccountLockoutCounterResetEnabled or false
end

function TAccountLockoutCounterResetEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountLockoutCounterResetEnabled.group)
end

TAccountLockoutCounterResetEnabled.from_obj = TAccountLockoutCounterResetEnabled_from_obj

TAccountLockoutCounterResetEnabled.proto_property = {'AccountLockoutCounterResetEnabled'}

TAccountLockoutCounterResetEnabled.default = {false}

TAccountLockoutCounterResetEnabled.struct = {
    {name = 'AccountLockoutCounterResetEnabled', is_array = false, struct = nil}
}

function TAccountLockoutCounterResetEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountLockoutCounterResetEnabled', self.AccountLockoutCounterResetEnabled, 'bool',
        false, errs, need_convert)

    TAccountLockoutCounterResetEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountLockoutCounterResetEnabled.proto_property, errs, need_convert)
    return self
end

function TAccountLockoutCounterResetEnabled:unpack(_)
    return self.AccountLockoutCounterResetEnabled
end

AccountService.AccountLockoutCounterResetEnabled = TAccountLockoutCounterResetEnabled

---@class AccountService.AccountLockoutCounterResetAfter
---@field AccountLockoutCounterResetAfter integer
local TAccountLockoutCounterResetAfter = {}
TAccountLockoutCounterResetAfter.__index = TAccountLockoutCounterResetAfter
TAccountLockoutCounterResetAfter.group = {}

local function TAccountLockoutCounterResetAfter_from_obj(obj)
    return setmetatable(obj, TAccountLockoutCounterResetAfter)
end

function TAccountLockoutCounterResetAfter.new(AccountLockoutCounterResetAfter)
    return TAccountLockoutCounterResetAfter_from_obj({
        AccountLockoutCounterResetAfter = AccountLockoutCounterResetAfter or 0
    })
end
---@param obj AccountService.AccountLockoutCounterResetAfter
function TAccountLockoutCounterResetAfter:init_from_obj(obj)
    self.AccountLockoutCounterResetAfter = obj.AccountLockoutCounterResetAfter or 0
end

function TAccountLockoutCounterResetAfter:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountLockoutCounterResetAfter.group)
end

TAccountLockoutCounterResetAfter.from_obj = TAccountLockoutCounterResetAfter_from_obj

TAccountLockoutCounterResetAfter.proto_property = {'AccountLockoutCounterResetAfter'}

TAccountLockoutCounterResetAfter.default = {0}

TAccountLockoutCounterResetAfter.struct = {{name = 'AccountLockoutCounterResetAfter', is_array = false, struct = nil}}

function TAccountLockoutCounterResetAfter:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountLockoutCounterResetAfter', self.AccountLockoutCounterResetAfter, 'int32', false,
        errs, need_convert)

    TAccountLockoutCounterResetAfter:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountLockoutCounterResetAfter.proto_property, errs, need_convert)
    return self
end

function TAccountLockoutCounterResetAfter:unpack(_)
    return self.AccountLockoutCounterResetAfter
end

AccountService.AccountLockoutCounterResetAfter = TAccountLockoutCounterResetAfter

---@class AccountService.RecoverAccountRsp
local TRecoverAccountRsp = {}
TRecoverAccountRsp.__index = TRecoverAccountRsp
TRecoverAccountRsp.group = {}

local function TRecoverAccountRsp_from_obj(obj)
    return setmetatable(obj, TRecoverAccountRsp)
end

function TRecoverAccountRsp.new()
    return TRecoverAccountRsp_from_obj({})
end
---@param obj AccountService.RecoverAccountRsp
function TRecoverAccountRsp:init_from_obj(obj)

end

function TRecoverAccountRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRecoverAccountRsp.group)
end

TRecoverAccountRsp.from_obj = TRecoverAccountRsp_from_obj

TRecoverAccountRsp.proto_property = {}

TRecoverAccountRsp.default = {}

TRecoverAccountRsp.struct = {}

function TRecoverAccountRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TRecoverAccountRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRecoverAccountRsp.proto_property, errs, need_convert)
    return self
end

function TRecoverAccountRsp:unpack(_)
end

AccountService.RecoverAccountRsp = TRecoverAccountRsp

---@class AccountService.RecoverAccountReq
---@field AccountId integer
---@field Policy integer
local TRecoverAccountReq = {}
TRecoverAccountReq.__index = TRecoverAccountReq
TRecoverAccountReq.group = {}

local function TRecoverAccountReq_from_obj(obj)
    return setmetatable(obj, TRecoverAccountReq)
end

function TRecoverAccountReq.new(AccountId, Policy)
    return TRecoverAccountReq_from_obj({AccountId = AccountId, Policy = Policy})
end
---@param obj AccountService.RecoverAccountReq
function TRecoverAccountReq:init_from_obj(obj)
    self.AccountId = obj.AccountId
    self.Policy = obj.Policy
end

function TRecoverAccountReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRecoverAccountReq.group)
end

TRecoverAccountReq.from_obj = TRecoverAccountReq_from_obj

TRecoverAccountReq.proto_property = {'AccountId', 'Policy'}

TRecoverAccountReq.default = {0, 0}

TRecoverAccountReq.struct = {
    {name = 'AccountId', is_array = false, struct = nil}, {name = 'Policy', is_array = false, struct = nil}
}

function TRecoverAccountReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Policy', self.Policy, 'uint8', false, errs, need_convert)

    if self.AccountId ~= nil then
        validate.ranges(prefix .. 'AccountId', self.AccountId, 2, 17, errs, need_convert)
    end
    if self.Policy ~= nil then
        validate.ranges(prefix .. 'Policy', self.Policy, 0, 1, errs, need_convert)
    end

    TRecoverAccountReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRecoverAccountReq.proto_property, errs, need_convert)
    return self
end

function TRecoverAccountReq:unpack(_)
    return self.AccountId, self.Policy
end

AccountService.RecoverAccountReq = TRecoverAccountReq

---@class AccountService.GetRequestedPublicKeyRsp
---@field PublicKey string
local TGetRequestedPublicKeyRsp = {}
TGetRequestedPublicKeyRsp.__index = TGetRequestedPublicKeyRsp
TGetRequestedPublicKeyRsp.group = {}

local function TGetRequestedPublicKeyRsp_from_obj(obj)
    return setmetatable(obj, TGetRequestedPublicKeyRsp)
end

function TGetRequestedPublicKeyRsp.new(PublicKey)
    return TGetRequestedPublicKeyRsp_from_obj({PublicKey = PublicKey})
end
---@param obj AccountService.GetRequestedPublicKeyRsp
function TGetRequestedPublicKeyRsp:init_from_obj(obj)
    self.PublicKey = obj.PublicKey
end

function TGetRequestedPublicKeyRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetRequestedPublicKeyRsp.group)
end

TGetRequestedPublicKeyRsp.from_obj = TGetRequestedPublicKeyRsp_from_obj

TGetRequestedPublicKeyRsp.proto_property = {'PublicKey'}

TGetRequestedPublicKeyRsp.default = {''}

TGetRequestedPublicKeyRsp.struct = {{name = 'PublicKey', is_array = false, struct = nil}}

function TGetRequestedPublicKeyRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PublicKey', self.PublicKey, 'string', false, errs, need_convert)

    TGetRequestedPublicKeyRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetRequestedPublicKeyRsp.proto_property, errs, need_convert)
    return self
end

function TGetRequestedPublicKeyRsp:unpack(_)
    return self.PublicKey
end

AccountService.GetRequestedPublicKeyRsp = TGetRequestedPublicKeyRsp

---@class AccountService.GetRequestedPublicKeyReq
---@field PublicKeyUsageType integer
local TGetRequestedPublicKeyReq = {}
TGetRequestedPublicKeyReq.__index = TGetRequestedPublicKeyReq
TGetRequestedPublicKeyReq.group = {}

local function TGetRequestedPublicKeyReq_from_obj(obj)
    return setmetatable(obj, TGetRequestedPublicKeyReq)
end

function TGetRequestedPublicKeyReq.new(PublicKeyUsageType)
    return TGetRequestedPublicKeyReq_from_obj({PublicKeyUsageType = PublicKeyUsageType})
end
---@param obj AccountService.GetRequestedPublicKeyReq
function TGetRequestedPublicKeyReq:init_from_obj(obj)
    self.PublicKeyUsageType = obj.PublicKeyUsageType
end

function TGetRequestedPublicKeyReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetRequestedPublicKeyReq.group)
end

TGetRequestedPublicKeyReq.from_obj = TGetRequestedPublicKeyReq_from_obj

TGetRequestedPublicKeyReq.proto_property = {'PublicKeyUsageType'}

TGetRequestedPublicKeyReq.default = {0}

TGetRequestedPublicKeyReq.struct = {{name = 'PublicKeyUsageType', is_array = false, struct = nil}}

function TGetRequestedPublicKeyReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PublicKeyUsageType', self.PublicKeyUsageType, 'uint8', false, errs, need_convert)

    TGetRequestedPublicKeyReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetRequestedPublicKeyReq.proto_property, errs, need_convert)
    return self
end

function TGetRequestedPublicKeyReq:unpack(_)
    return self.PublicKeyUsageType
end

AccountService.GetRequestedPublicKeyReq = TGetRequestedPublicKeyReq

---@class AccountService.ExportWeakPasswordDictionaryRsp
---@field TaskId integer
local TExportWeakPasswordDictionaryRsp = {}
TExportWeakPasswordDictionaryRsp.__index = TExportWeakPasswordDictionaryRsp
TExportWeakPasswordDictionaryRsp.group = {}

local function TExportWeakPasswordDictionaryRsp_from_obj(obj)
    return setmetatable(obj, TExportWeakPasswordDictionaryRsp)
end

function TExportWeakPasswordDictionaryRsp.new(TaskId)
    return TExportWeakPasswordDictionaryRsp_from_obj({TaskId = TaskId})
end
---@param obj AccountService.ExportWeakPasswordDictionaryRsp
function TExportWeakPasswordDictionaryRsp:init_from_obj(obj)
    self.TaskId = obj.TaskId
end

function TExportWeakPasswordDictionaryRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExportWeakPasswordDictionaryRsp.group)
end

TExportWeakPasswordDictionaryRsp.from_obj = TExportWeakPasswordDictionaryRsp_from_obj

TExportWeakPasswordDictionaryRsp.proto_property = {'TaskId'}

TExportWeakPasswordDictionaryRsp.default = {0}

TExportWeakPasswordDictionaryRsp.struct = {{name = 'TaskId', is_array = false, struct = nil}}

function TExportWeakPasswordDictionaryRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TExportWeakPasswordDictionaryRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TExportWeakPasswordDictionaryRsp.proto_property, errs, need_convert)
    return self
end

function TExportWeakPasswordDictionaryRsp:unpack(_)
    return self.TaskId
end

AccountService.ExportWeakPasswordDictionaryRsp = TExportWeakPasswordDictionaryRsp

---@class AccountService.ExportWeakPasswordDictionaryReq
---@field Path string
local TExportWeakPasswordDictionaryReq = {}
TExportWeakPasswordDictionaryReq.__index = TExportWeakPasswordDictionaryReq
TExportWeakPasswordDictionaryReq.group = {}

local function TExportWeakPasswordDictionaryReq_from_obj(obj)
    return setmetatable(obj, TExportWeakPasswordDictionaryReq)
end

function TExportWeakPasswordDictionaryReq.new(Path)
    return TExportWeakPasswordDictionaryReq_from_obj({Path = Path})
end
---@param obj AccountService.ExportWeakPasswordDictionaryReq
function TExportWeakPasswordDictionaryReq:init_from_obj(obj)
    self.Path = obj.Path
end

function TExportWeakPasswordDictionaryReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExportWeakPasswordDictionaryReq.group)
end

TExportWeakPasswordDictionaryReq.from_obj = TExportWeakPasswordDictionaryReq_from_obj

TExportWeakPasswordDictionaryReq.proto_property = {'Path'}

TExportWeakPasswordDictionaryReq.default = {''}

TExportWeakPasswordDictionaryReq.struct = {{name = 'Path', is_array = false, struct = nil}}

function TExportWeakPasswordDictionaryReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Path', self.Path, 'string', false, errs, need_convert)

    TExportWeakPasswordDictionaryReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TExportWeakPasswordDictionaryReq.proto_property, errs, need_convert)
    return self
end

function TExportWeakPasswordDictionaryReq:unpack(_)
    return self.Path
end

AccountService.ExportWeakPasswordDictionaryReq = TExportWeakPasswordDictionaryReq

---@class AccountService.ImportWeakPasswordDictionaryRsp
---@field TaskId integer
local TImportWeakPasswordDictionaryRsp = {}
TImportWeakPasswordDictionaryRsp.__index = TImportWeakPasswordDictionaryRsp
TImportWeakPasswordDictionaryRsp.group = {}

local function TImportWeakPasswordDictionaryRsp_from_obj(obj)
    return setmetatable(obj, TImportWeakPasswordDictionaryRsp)
end

function TImportWeakPasswordDictionaryRsp.new(TaskId)
    return TImportWeakPasswordDictionaryRsp_from_obj({TaskId = TaskId})
end
---@param obj AccountService.ImportWeakPasswordDictionaryRsp
function TImportWeakPasswordDictionaryRsp:init_from_obj(obj)
    self.TaskId = obj.TaskId
end

function TImportWeakPasswordDictionaryRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportWeakPasswordDictionaryRsp.group)
end

TImportWeakPasswordDictionaryRsp.from_obj = TImportWeakPasswordDictionaryRsp_from_obj

TImportWeakPasswordDictionaryRsp.proto_property = {'TaskId'}

TImportWeakPasswordDictionaryRsp.default = {0}

TImportWeakPasswordDictionaryRsp.struct = {{name = 'TaskId', is_array = false, struct = nil}}

function TImportWeakPasswordDictionaryRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TImportWeakPasswordDictionaryRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportWeakPasswordDictionaryRsp.proto_property, errs, need_convert)
    return self
end

function TImportWeakPasswordDictionaryRsp:unpack(_)
    return self.TaskId
end

AccountService.ImportWeakPasswordDictionaryRsp = TImportWeakPasswordDictionaryRsp

---@class AccountService.ImportWeakPasswordDictionaryReq
---@field Path string
local TImportWeakPasswordDictionaryReq = {}
TImportWeakPasswordDictionaryReq.__index = TImportWeakPasswordDictionaryReq
TImportWeakPasswordDictionaryReq.group = {}

local function TImportWeakPasswordDictionaryReq_from_obj(obj)
    return setmetatable(obj, TImportWeakPasswordDictionaryReq)
end

function TImportWeakPasswordDictionaryReq.new(Path)
    return TImportWeakPasswordDictionaryReq_from_obj({Path = Path})
end
---@param obj AccountService.ImportWeakPasswordDictionaryReq
function TImportWeakPasswordDictionaryReq:init_from_obj(obj)
    self.Path = obj.Path
end

function TImportWeakPasswordDictionaryReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportWeakPasswordDictionaryReq.group)
end

TImportWeakPasswordDictionaryReq.from_obj = TImportWeakPasswordDictionaryReq_from_obj

TImportWeakPasswordDictionaryReq.proto_property = {'Path'}

TImportWeakPasswordDictionaryReq.default = {''}

TImportWeakPasswordDictionaryReq.struct = {{name = 'Path', is_array = false, struct = nil}}

function TImportWeakPasswordDictionaryReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Path', self.Path, 'string', false, errs, need_convert)

    TImportWeakPasswordDictionaryReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportWeakPasswordDictionaryReq.proto_property, errs, need_convert)
    return self
end

function TImportWeakPasswordDictionaryReq:unpack(_)
    return self.Path
end

AccountService.ImportWeakPasswordDictionaryReq = TImportWeakPasswordDictionaryReq

AccountService.interface = mdb.register_interface('bmc.kepler.AccountService', {
    AccountLockoutCounterResetAfter = {'i', {}, false, 0},
    AccountLockoutCounterResetEnabled = {'b', {}, false, false},
    AuthFailureLoggingThreshold = {'i', {}, false, 0},
    MaxPasswordLength = {'i', {'CONST'}, true, 20},
    MinPasswordLength = {'i', {'EMIT_CHANGE'}, false, 8},
    ServiceEnabled = {'b', {}, false, true},
    PasswordComplexityEnable = {'b', {'EMIT_CHANGE'}, false, true},
    InitialPasswordPromptEnable = {'b', {}, false, true},
    InitialPasswordNeedModify = {'b', {}, false, true},
    InitialAccountPrivilegeRestrictEnabled = {'b', {'EMIT_CHANGE'}, false, false},
    MinPasswordValidDays = {'u', {'EMIT_CHANGE'}, false, 0},
    MaxPasswordValidDays = {'u', {'EMIT_CHANGE'}, false, 0},
    EmergencyLoginAccountId = {'y', {'EMIT_CHANGE'}, false, 0},
    SNMPv3TrapAccountId = {'y', {'EMIT_CHANGE'}, false, 2},
    InactiveDaysThreshold = {'u', {'EMIT_CHANGE'}, false, 0},
    WeakPasswordDictionaryEnabled = {'b', {}, false, true},
    HistoryPasswordCount = {'y', {'EMIT_CHANGE'}, false, 5},
    MaxHistoryPasswordCount = {'y', {}, false, 5},
    HostUserManagementEnabled = {'b', {'EMIT_CHANGE'}, false, true},
    OSAdministratorPrivilegeEnabled = {'b', {}, false, true},
    SNMPv3TrapAccountLimitPolicy = {'y', {'EMIT_CHANGE'}, false, 2},
    UserNamePasswordPrefixCompareEnabled = {'b', {'EMIT_CHANGE'}, false, false},
    UserNamePasswordPrefixCompareLength = {'y', {'EMIT_CHANGE'}, false, 4},
    SNMPv3TrapAccountChangePolicy = {'y', {'EMIT_CHANGE'}, false, 0}
}, {
    ImportWeakPasswordDictionary = {'a{ss}s', 'u', TImportWeakPasswordDictionaryReq, TImportWeakPasswordDictionaryRsp},
    ExportWeakPasswordDictionary = {'a{ss}s', 'u', TExportWeakPasswordDictionaryReq, TExportWeakPasswordDictionaryRsp},
    GetRequestedPublicKey = {'a{ss}y', 's', TGetRequestedPublicKeyReq, TGetRequestedPublicKeyRsp},
    RecoverAccount = {'a{ss}yy', '', TRecoverAccountReq, TRecoverAccountRsp}
}, {})

return AccountService
