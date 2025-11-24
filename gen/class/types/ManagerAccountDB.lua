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

local MManagerAccountDB = {}

---@class MManagerAccountDB.IsOnline
---@field IsOnline boolean
local TIsOnline = {}
TIsOnline.__index = TIsOnline
TIsOnline.group = {}

local function TIsOnline_from_obj(obj)
    return setmetatable(obj, TIsOnline)
end

function TIsOnline.new(IsOnline)
    return TIsOnline_from_obj({IsOnline = IsOnline or false})
end
---@param obj MManagerAccountDB.IsOnline
function TIsOnline:init_from_obj(obj)
    self.IsOnline = obj.IsOnline or false
end

function TIsOnline:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIsOnline.group)
end

TIsOnline.from_obj = TIsOnline_from_obj

TIsOnline.proto_property = {'IsOnline'}

TIsOnline.default = {false}

TIsOnline.struct = {{name = 'IsOnline', is_array = false, struct = nil}}

function TIsOnline:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IsOnline', self.IsOnline, 'bool', false, errs, need_convert)

    TIsOnline:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIsOnline.proto_property, errs, need_convert)
    return self
end

function TIsOnline:unpack(_)
    return self.IsOnline
end

MManagerAccountDB.IsOnline = TIsOnline

---@class MManagerAccountDB.SNMPPasswordWritable
---@field SNMPPasswordWritable boolean
local TSNMPPasswordWritable = {}
TSNMPPasswordWritable.__index = TSNMPPasswordWritable
TSNMPPasswordWritable.group = {}

local function TSNMPPasswordWritable_from_obj(obj)
    return setmetatable(obj, TSNMPPasswordWritable)
end

function TSNMPPasswordWritable.new(SNMPPasswordWritable)
    return TSNMPPasswordWritable_from_obj({
        SNMPPasswordWritable = SNMPPasswordWritable == nil and true or SNMPPasswordWritable
    })
end
---@param obj MManagerAccountDB.SNMPPasswordWritable
function TSNMPPasswordWritable:init_from_obj(obj)
    self.SNMPPasswordWritable = obj.SNMPPasswordWritable == nil and true or obj.SNMPPasswordWritable
end

function TSNMPPasswordWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSNMPPasswordWritable.group)
end

TSNMPPasswordWritable.from_obj = TSNMPPasswordWritable_from_obj

TSNMPPasswordWritable.proto_property = {'SNMPPasswordWritable'}

TSNMPPasswordWritable.default = {false}

TSNMPPasswordWritable.struct = {{name = 'SNMPPasswordWritable', is_array = false, struct = nil}}

function TSNMPPasswordWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SNMPPasswordWritable', self.SNMPPasswordWritable, 'bool', false, errs, need_convert)

    TSNMPPasswordWritable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSNMPPasswordWritable.proto_property, errs, need_convert)
    return self
end

function TSNMPPasswordWritable:unpack(_)
    return self.SNMPPasswordWritable
end

MManagerAccountDB.SNMPPasswordWritable = TSNMPPasswordWritable

---@class MManagerAccountDB.EncryptionProtocolWritable
---@field EncryptionProtocolWritable boolean
local TEncryptionProtocolWritable = {}
TEncryptionProtocolWritable.__index = TEncryptionProtocolWritable
TEncryptionProtocolWritable.group = {}

local function TEncryptionProtocolWritable_from_obj(obj)
    return setmetatable(obj, TEncryptionProtocolWritable)
end

function TEncryptionProtocolWritable.new(EncryptionProtocolWritable)
    return TEncryptionProtocolWritable_from_obj({
        EncryptionProtocolWritable = EncryptionProtocolWritable == nil and true or EncryptionProtocolWritable
    })
end
---@param obj MManagerAccountDB.EncryptionProtocolWritable
function TEncryptionProtocolWritable:init_from_obj(obj)
    self.EncryptionProtocolWritable = obj.EncryptionProtocolWritable == nil and true or obj.EncryptionProtocolWritable
end

function TEncryptionProtocolWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TEncryptionProtocolWritable.group)
end

TEncryptionProtocolWritable.from_obj = TEncryptionProtocolWritable_from_obj

TEncryptionProtocolWritable.proto_property = {'EncryptionProtocolWritable'}

TEncryptionProtocolWritable.default = {false}

TEncryptionProtocolWritable.struct = {{name = 'EncryptionProtocolWritable', is_array = false, struct = nil}}

function TEncryptionProtocolWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EncryptionProtocolWritable', self.EncryptionProtocolWritable, 'bool', false, errs,
        need_convert)

    TEncryptionProtocolWritable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TEncryptionProtocolWritable.proto_property, errs, need_convert)
    return self
end

function TEncryptionProtocolWritable:unpack(_)
    return self.EncryptionProtocolWritable
end

MManagerAccountDB.EncryptionProtocolWritable = TEncryptionProtocolWritable

---@class MManagerAccountDB.AuthenticationProtocolWritable
---@field AuthenticationProtocolWritable boolean
local TAuthenticationProtocolWritable = {}
TAuthenticationProtocolWritable.__index = TAuthenticationProtocolWritable
TAuthenticationProtocolWritable.group = {}

local function TAuthenticationProtocolWritable_from_obj(obj)
    return setmetatable(obj, TAuthenticationProtocolWritable)
end

function TAuthenticationProtocolWritable.new(AuthenticationProtocolWritable)
    return TAuthenticationProtocolWritable_from_obj({
        AuthenticationProtocolWritable = AuthenticationProtocolWritable == nil and true or
            AuthenticationProtocolWritable
    })
end
---@param obj MManagerAccountDB.AuthenticationProtocolWritable
function TAuthenticationProtocolWritable:init_from_obj(obj)
    self.AuthenticationProtocolWritable = obj.AuthenticationProtocolWritable == nil and true or
                                              obj.AuthenticationProtocolWritable
end

function TAuthenticationProtocolWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAuthenticationProtocolWritable.group)
end

TAuthenticationProtocolWritable.from_obj = TAuthenticationProtocolWritable_from_obj

TAuthenticationProtocolWritable.proto_property = {'AuthenticationProtocolWritable'}

TAuthenticationProtocolWritable.default = {false}

TAuthenticationProtocolWritable.struct = {{name = 'AuthenticationProtocolWritable', is_array = false, struct = nil}}

function TAuthenticationProtocolWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AuthenticationProtocolWritable', self.AuthenticationProtocolWritable, 'bool', false,
        errs, need_convert)

    TAuthenticationProtocolWritable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAuthenticationProtocolWritable.proto_property, errs, need_convert)
    return self
end

function TAuthenticationProtocolWritable:unpack(_)
    return self.AuthenticationProtocolWritable
end

MManagerAccountDB.AuthenticationProtocolWritable = TAuthenticationProtocolWritable

---@class MManagerAccountDB.LoginRuleIdsWritable
---@field LoginRuleIdsWritable boolean
local TLoginRuleIdsWritable = {}
TLoginRuleIdsWritable.__index = TLoginRuleIdsWritable
TLoginRuleIdsWritable.group = {}

local function TLoginRuleIdsWritable_from_obj(obj)
    return setmetatable(obj, TLoginRuleIdsWritable)
end

function TLoginRuleIdsWritable.new(LoginRuleIdsWritable)
    return TLoginRuleIdsWritable_from_obj({
        LoginRuleIdsWritable = LoginRuleIdsWritable == nil and true or LoginRuleIdsWritable
    })
end
---@param obj MManagerAccountDB.LoginRuleIdsWritable
function TLoginRuleIdsWritable:init_from_obj(obj)
    self.LoginRuleIdsWritable = obj.LoginRuleIdsWritable == nil and true or obj.LoginRuleIdsWritable
end

function TLoginRuleIdsWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLoginRuleIdsWritable.group)
end

TLoginRuleIdsWritable.from_obj = TLoginRuleIdsWritable_from_obj

TLoginRuleIdsWritable.proto_property = {'LoginRuleIdsWritable'}

TLoginRuleIdsWritable.default = {false}

TLoginRuleIdsWritable.struct = {{name = 'LoginRuleIdsWritable', is_array = false, struct = nil}}

function TLoginRuleIdsWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'LoginRuleIdsWritable', self.LoginRuleIdsWritable, 'bool', false, errs, need_convert)

    TLoginRuleIdsWritable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLoginRuleIdsWritable.proto_property, errs, need_convert)
    return self
end

function TLoginRuleIdsWritable:unpack(_)
    return self.LoginRuleIdsWritable
end

MManagerAccountDB.LoginRuleIdsWritable = TLoginRuleIdsWritable

---@class MManagerAccountDB.EnabledWritable
---@field EnabledWritable boolean
local TEnabledWritable = {}
TEnabledWritable.__index = TEnabledWritable
TEnabledWritable.group = {}

local function TEnabledWritable_from_obj(obj)
    return setmetatable(obj, TEnabledWritable)
end

function TEnabledWritable.new(EnabledWritable)
    return TEnabledWritable_from_obj({EnabledWritable = EnabledWritable == nil and true or EnabledWritable})
end
---@param obj MManagerAccountDB.EnabledWritable
function TEnabledWritable:init_from_obj(obj)
    self.EnabledWritable = obj.EnabledWritable == nil and true or obj.EnabledWritable
end

function TEnabledWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TEnabledWritable.group)
end

TEnabledWritable.from_obj = TEnabledWritable_from_obj

TEnabledWritable.proto_property = {'EnabledWritable'}

TEnabledWritable.default = {false}

TEnabledWritable.struct = {{name = 'EnabledWritable', is_array = false, struct = nil}}

function TEnabledWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EnabledWritable', self.EnabledWritable, 'bool', false, errs, need_convert)

    TEnabledWritable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TEnabledWritable.proto_property, errs, need_convert)
    return self
end

function TEnabledWritable:unpack(_)
    return self.EnabledWritable
end

MManagerAccountDB.EnabledWritable = TEnabledWritable

---@class MManagerAccountDB.RoleIdWritable
---@field RoleIdWritable boolean
local TRoleIdWritable = {}
TRoleIdWritable.__index = TRoleIdWritable
TRoleIdWritable.group = {}

local function TRoleIdWritable_from_obj(obj)
    return setmetatable(obj, TRoleIdWritable)
end

function TRoleIdWritable.new(RoleIdWritable)
    return TRoleIdWritable_from_obj({RoleIdWritable = RoleIdWritable == nil and true or RoleIdWritable})
end
---@param obj MManagerAccountDB.RoleIdWritable
function TRoleIdWritable:init_from_obj(obj)
    self.RoleIdWritable = obj.RoleIdWritable == nil and true or obj.RoleIdWritable
end

function TRoleIdWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRoleIdWritable.group)
end

TRoleIdWritable.from_obj = TRoleIdWritable_from_obj

TRoleIdWritable.proto_property = {'RoleIdWritable'}

TRoleIdWritable.default = {false}

TRoleIdWritable.struct = {{name = 'RoleIdWritable', is_array = false, struct = nil}}

function TRoleIdWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RoleIdWritable', self.RoleIdWritable, 'bool', false, errs, need_convert)

    TRoleIdWritable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRoleIdWritable.proto_property, errs, need_convert)
    return self
end

function TRoleIdWritable:unpack(_)
    return self.RoleIdWritable
end

MManagerAccountDB.RoleIdWritable = TRoleIdWritable

---@class MManagerAccountDB.LoginInterfaceWritable
---@field LoginInterfaceWritable boolean
local TLoginInterfaceWritable = {}
TLoginInterfaceWritable.__index = TLoginInterfaceWritable
TLoginInterfaceWritable.group = {}

local function TLoginInterfaceWritable_from_obj(obj)
    return setmetatable(obj, TLoginInterfaceWritable)
end

function TLoginInterfaceWritable.new(LoginInterfaceWritable)
    return TLoginInterfaceWritable_from_obj({
        LoginInterfaceWritable = LoginInterfaceWritable == nil and true or LoginInterfaceWritable
    })
end
---@param obj MManagerAccountDB.LoginInterfaceWritable
function TLoginInterfaceWritable:init_from_obj(obj)
    self.LoginInterfaceWritable = obj.LoginInterfaceWritable == nil and true or obj.LoginInterfaceWritable
end

function TLoginInterfaceWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLoginInterfaceWritable.group)
end

TLoginInterfaceWritable.from_obj = TLoginInterfaceWritable_from_obj

TLoginInterfaceWritable.proto_property = {'LoginInterfaceWritable'}

TLoginInterfaceWritable.default = {false}

TLoginInterfaceWritable.struct = {{name = 'LoginInterfaceWritable', is_array = false, struct = nil}}

function TLoginInterfaceWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'LoginInterfaceWritable', self.LoginInterfaceWritable, 'bool', false, errs, need_convert)

    TLoginInterfaceWritable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLoginInterfaceWritable.proto_property, errs, need_convert)
    return self
end

function TLoginInterfaceWritable:unpack(_)
    return self.LoginInterfaceWritable
end

MManagerAccountDB.LoginInterfaceWritable = TLoginInterfaceWritable

---@class MManagerAccountDB.UserNameWritable
---@field UserNameWritable boolean
local TUserNameWritable = {}
TUserNameWritable.__index = TUserNameWritable
TUserNameWritable.group = {}

local function TUserNameWritable_from_obj(obj)
    return setmetatable(obj, TUserNameWritable)
end

function TUserNameWritable.new(UserNameWritable)
    return TUserNameWritable_from_obj({UserNameWritable = UserNameWritable == nil and true or UserNameWritable})
end
---@param obj MManagerAccountDB.UserNameWritable
function TUserNameWritable:init_from_obj(obj)
    self.UserNameWritable = obj.UserNameWritable == nil and true or obj.UserNameWritable
end

function TUserNameWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUserNameWritable.group)
end

TUserNameWritable.from_obj = TUserNameWritable_from_obj

TUserNameWritable.proto_property = {'UserNameWritable'}

TUserNameWritable.default = {false}

TUserNameWritable.struct = {{name = 'UserNameWritable', is_array = false, struct = nil}}

function TUserNameWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserNameWritable', self.UserNameWritable, 'bool', false, errs, need_convert)

    TUserNameWritable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUserNameWritable.proto_property, errs, need_convert)
    return self
end

function TUserNameWritable:unpack(_)
    return self.UserNameWritable
end

MManagerAccountDB.UserNameWritable = TUserNameWritable

---@class MManagerAccountDB.PasswordWritable
---@field PasswordWritable boolean
local TPasswordWritable = {}
TPasswordWritable.__index = TPasswordWritable
TPasswordWritable.group = {}

local function TPasswordWritable_from_obj(obj)
    return setmetatable(obj, TPasswordWritable)
end

function TPasswordWritable.new(PasswordWritable)
    return TPasswordWritable_from_obj({PasswordWritable = PasswordWritable == nil and true or PasswordWritable})
end
---@param obj MManagerAccountDB.PasswordWritable
function TPasswordWritable:init_from_obj(obj)
    self.PasswordWritable = obj.PasswordWritable == nil and true or obj.PasswordWritable
end

function TPasswordWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPasswordWritable.group)
end

TPasswordWritable.from_obj = TPasswordWritable_from_obj

TPasswordWritable.proto_property = {'PasswordWritable'}

TPasswordWritable.default = {false}

TPasswordWritable.struct = {{name = 'PasswordWritable', is_array = false, struct = nil}}

function TPasswordWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PasswordWritable', self.PasswordWritable, 'bool', false, errs, need_convert)

    TPasswordWritable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPasswordWritable.proto_property, errs, need_convert)
    return self
end

function TPasswordWritable:unpack(_)
    return self.PasswordWritable
end

MManagerAccountDB.PasswordWritable = TPasswordWritable

---@class MManagerAccountDB.InactiveStartTime
---@field InactiveStartTime integer
local TInactiveStartTime = {}
TInactiveStartTime.__index = TInactiveStartTime
TInactiveStartTime.group = {}

local function TInactiveStartTime_from_obj(obj)
    return setmetatable(obj, TInactiveStartTime)
end

function TInactiveStartTime.new(InactiveStartTime)
    return TInactiveStartTime_from_obj({InactiveStartTime = InactiveStartTime or 0})
end
---@param obj MManagerAccountDB.InactiveStartTime
function TInactiveStartTime:init_from_obj(obj)
    self.InactiveStartTime = obj.InactiveStartTime or 0
end

function TInactiveStartTime:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TInactiveStartTime.group)
end

TInactiveStartTime.from_obj = TInactiveStartTime_from_obj

TInactiveStartTime.proto_property = {'InactiveStartTime'}

TInactiveStartTime.default = {0}

TInactiveStartTime.struct = {{name = 'InactiveStartTime', is_array = false, struct = nil}}

function TInactiveStartTime:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'InactiveStartTime', self.InactiveStartTime, 'uint32', false, errs, need_convert)

    TInactiveStartTime:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TInactiveStartTime.proto_property, errs, need_convert)
    return self
end

function TInactiveStartTime:unpack(_)
    return self.InactiveStartTime
end

MManagerAccountDB.InactiveStartTime = TInactiveStartTime

---@class MManagerAccountDB.PasswordValidStartTime
---@field PasswordValidStartTime integer
local TPasswordValidStartTime = {}
TPasswordValidStartTime.__index = TPasswordValidStartTime
TPasswordValidStartTime.group = {}

local function TPasswordValidStartTime_from_obj(obj)
    return setmetatable(obj, TPasswordValidStartTime)
end

function TPasswordValidStartTime.new(PasswordValidStartTime)
    return TPasswordValidStartTime_from_obj({PasswordValidStartTime = PasswordValidStartTime or 0})
end
---@param obj MManagerAccountDB.PasswordValidStartTime
function TPasswordValidStartTime:init_from_obj(obj)
    self.PasswordValidStartTime = obj.PasswordValidStartTime or 0
end

function TPasswordValidStartTime:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPasswordValidStartTime.group)
end

TPasswordValidStartTime.from_obj = TPasswordValidStartTime_from_obj

TPasswordValidStartTime.proto_property = {'PasswordValidStartTime'}

TPasswordValidStartTime.default = {0}

TPasswordValidStartTime.struct = {{name = 'PasswordValidStartTime', is_array = false, struct = nil}}

function TPasswordValidStartTime:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PasswordValidStartTime', self.PasswordValidStartTime, 'uint32', false, errs,
        need_convert)

    TPasswordValidStartTime:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPasswordValidStartTime.proto_property, errs, need_convert)
    return self
end

function TPasswordValidStartTime:unpack(_)
    return self.PasswordValidStartTime
end

MManagerAccountDB.PasswordValidStartTime = TPasswordValidStartTime

---@class MManagerAccountDB.LoginInterface
---@field LoginInterface integer
local TLoginInterface = {}
TLoginInterface.__index = TLoginInterface
TLoginInterface.group = {}

local function TLoginInterface_from_obj(obj)
    return setmetatable(obj, TLoginInterface)
end

function TLoginInterface.new(LoginInterface)
    return TLoginInterface_from_obj({LoginInterface = LoginInterface or 0})
end
---@param obj MManagerAccountDB.LoginInterface
function TLoginInterface:init_from_obj(obj)
    self.LoginInterface = obj.LoginInterface or 0
end

function TLoginInterface:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLoginInterface.group)
end

TLoginInterface.from_obj = TLoginInterface_from_obj

TLoginInterface.proto_property = {'LoginInterface'}

TLoginInterface.default = {0}

TLoginInterface.struct = {{name = 'LoginInterface', is_array = false, struct = nil}}

function TLoginInterface:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'LoginInterface', self.LoginInterface, 'uint32', false, errs, need_convert)

    TLoginInterface:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLoginInterface.proto_property, errs, need_convert)
    return self
end

function TLoginInterface:unpack(_)
    return self.LoginInterface
end

MManagerAccountDB.LoginInterface = TLoginInterface

---@class MManagerAccountDB.AccountType
---@field AccountType def_types.AccountType
local TAccountType = {}
TAccountType.__index = TAccountType
TAccountType.group = {}

local function TAccountType_from_obj(obj)
    obj.AccountType = obj.AccountType and def_types.AccountType.new(obj.AccountType)
    return setmetatable(obj, TAccountType)
end

function TAccountType.new(AccountType)
    return TAccountType_from_obj({AccountType = AccountType or [=[Local]=]})
end
---@param obj MManagerAccountDB.AccountType
function TAccountType:init_from_obj(obj)
    self.AccountType = obj.AccountType or def_types.AccountType.Local
end

function TAccountType:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountType.group)
end

TAccountType.from_obj = TAccountType_from_obj

TAccountType.proto_property = {'AccountType'}

TAccountType.default = {def_types.AccountType.default}

TAccountType.struct = {{name = 'AccountType', is_array = false, struct = def_types.AccountType.struct}}

function TAccountType:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountType', self.AccountType, 'def_types.AccountType', false, errs, need_convert)

    TAccountType:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountType.proto_property, errs, need_convert)
    return self
end

function TAccountType:unpack(raw)
    local AccountType = utils.unpack_enum(raw, self.AccountType)
    return AccountType
end

MManagerAccountDB.AccountType = TAccountType

---@class MManagerAccountDB.FirstLoginPolicy
---@field FirstLoginPolicy def_types.FirstLoginPolicy
local TFirstLoginPolicy = {}
TFirstLoginPolicy.__index = TFirstLoginPolicy
TFirstLoginPolicy.group = {}

local function TFirstLoginPolicy_from_obj(obj)
    obj.FirstLoginPolicy = obj.FirstLoginPolicy and def_types.FirstLoginPolicy.new(obj.FirstLoginPolicy)
    return setmetatable(obj, TFirstLoginPolicy)
end

function TFirstLoginPolicy.new(FirstLoginPolicy)
    return TFirstLoginPolicy_from_obj({FirstLoginPolicy = FirstLoginPolicy or [=[ForcePasswordReset]=]})
end
---@param obj MManagerAccountDB.FirstLoginPolicy
function TFirstLoginPolicy:init_from_obj(obj)
    self.FirstLoginPolicy = obj.FirstLoginPolicy or def_types.FirstLoginPolicy.ForcePasswordReset
end

function TFirstLoginPolicy:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TFirstLoginPolicy.group)
end

TFirstLoginPolicy.from_obj = TFirstLoginPolicy_from_obj

TFirstLoginPolicy.proto_property = {'FirstLoginPolicy'}

TFirstLoginPolicy.default = {def_types.FirstLoginPolicy.default}

TFirstLoginPolicy.struct = {{name = 'FirstLoginPolicy', is_array = false, struct = def_types.FirstLoginPolicy.struct}}

function TFirstLoginPolicy:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'FirstLoginPolicy', self.FirstLoginPolicy, 'def_types.FirstLoginPolicy', false, errs,
        need_convert)

    TFirstLoginPolicy:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TFirstLoginPolicy.proto_property, errs, need_convert)
    return self
end

function TFirstLoginPolicy:unpack(raw)
    local FirstLoginPolicy = utils.unpack_enum(raw, self.FirstLoginPolicy)
    return FirstLoginPolicy
end

MManagerAccountDB.FirstLoginPolicy = TFirstLoginPolicy

---@class MManagerAccountDB.LastLoginInterface
---@field LastLoginInterface def_types.LoginInterface
local TLastLoginInterface = {}
TLastLoginInterface.__index = TLastLoginInterface
TLastLoginInterface.group = {}

local function TLastLoginInterface_from_obj(obj)
    obj.LastLoginInterface = obj.LastLoginInterface and def_types.LoginInterface.new(obj.LastLoginInterface)
    return setmetatable(obj, TLastLoginInterface)
end

function TLastLoginInterface.new(LastLoginInterface)
    return TLastLoginInterface_from_obj({LastLoginInterface = LastLoginInterface or [=[Web]=]})
end
---@param obj MManagerAccountDB.LastLoginInterface
function TLastLoginInterface:init_from_obj(obj)
    self.LastLoginInterface = obj.LastLoginInterface or def_types.LoginInterface.Web
end

function TLastLoginInterface:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLastLoginInterface.group)
end

TLastLoginInterface.from_obj = TLastLoginInterface_from_obj

TLastLoginInterface.proto_property = {'LastLoginInterface'}

TLastLoginInterface.default = {def_types.LoginInterface.default}

TLastLoginInterface.struct = {{name = 'LastLoginInterface', is_array = false, struct = def_types.LoginInterface.struct}}

function TLastLoginInterface:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'LastLoginInterface', self.LastLoginInterface, 'def_types.LoginInterface', false, errs,
        need_convert)

    TLastLoginInterface:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLastLoginInterface.proto_property, errs, need_convert)
    return self
end

function TLastLoginInterface:unpack(raw)
    local LastLoginInterface = utils.unpack_enum(raw, self.LastLoginInterface)
    return LastLoginInterface
end

MManagerAccountDB.LastLoginInterface = TLastLoginInterface

---@class MManagerAccountDB.LastLoginIP
---@field LastLoginIP string
local TLastLoginIP = {}
TLastLoginIP.__index = TLastLoginIP
TLastLoginIP.group = {}

local function TLastLoginIP_from_obj(obj)
    return setmetatable(obj, TLastLoginIP)
end

function TLastLoginIP.new(LastLoginIP)
    return TLastLoginIP_from_obj({LastLoginIP = LastLoginIP or [=[]=]})
end
---@param obj MManagerAccountDB.LastLoginIP
function TLastLoginIP:init_from_obj(obj)
    self.LastLoginIP = obj.LastLoginIP or [=[]=]
end

function TLastLoginIP:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLastLoginIP.group)
end

TLastLoginIP.from_obj = TLastLoginIP_from_obj

TLastLoginIP.proto_property = {'LastLoginIP'}

TLastLoginIP.default = {''}

TLastLoginIP.struct = {{name = 'LastLoginIP', is_array = false, struct = nil}}

function TLastLoginIP:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'LastLoginIP', self.LastLoginIP, 'string', false, errs, need_convert)

    TLastLoginIP:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLastLoginIP.proto_property, errs, need_convert)
    return self
end

function TLastLoginIP:unpack(_)
    return self.LastLoginIP
end

MManagerAccountDB.LastLoginIP = TLastLoginIP

---@class MManagerAccountDB.LastLoginTime
---@field LastLoginTime integer
local TLastLoginTime = {}
TLastLoginTime.__index = TLastLoginTime
TLastLoginTime.group = {}

local function TLastLoginTime_from_obj(obj)
    return setmetatable(obj, TLastLoginTime)
end

function TLastLoginTime.new(LastLoginTime)
    return TLastLoginTime_from_obj({LastLoginTime = LastLoginTime or 4294967295})
end
---@param obj MManagerAccountDB.LastLoginTime
function TLastLoginTime:init_from_obj(obj)
    self.LastLoginTime = obj.LastLoginTime or 4294967295
end

function TLastLoginTime:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLastLoginTime.group)
end

TLastLoginTime.from_obj = TLastLoginTime_from_obj

TLastLoginTime.proto_property = {'LastLoginTime'}

TLastLoginTime.default = {0}

TLastLoginTime.struct = {{name = 'LastLoginTime', is_array = false, struct = nil}}

function TLastLoginTime:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'LastLoginTime', self.LastLoginTime, 'uint32', false, errs, need_convert)

    TLastLoginTime:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLastLoginTime.proto_property, errs, need_convert)
    return self
end

function TLastLoginTime:unpack(_)
    return self.LastLoginTime
end

MManagerAccountDB.LastLoginTime = TLastLoginTime

---@class MManagerAccountDB.InactUserRemainDays
---@field InactUserRemainDays integer
local TInactUserRemainDays = {}
TInactUserRemainDays.__index = TInactUserRemainDays
TInactUserRemainDays.group = {}

local function TInactUserRemainDays_from_obj(obj)
    return setmetatable(obj, TInactUserRemainDays)
end

function TInactUserRemainDays.new(InactUserRemainDays)
    return TInactUserRemainDays_from_obj({InactUserRemainDays = InactUserRemainDays or 4294967295})
end
---@param obj MManagerAccountDB.InactUserRemainDays
function TInactUserRemainDays:init_from_obj(obj)
    self.InactUserRemainDays = obj.InactUserRemainDays or 4294967295
end

function TInactUserRemainDays:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TInactUserRemainDays.group)
end

TInactUserRemainDays.from_obj = TInactUserRemainDays_from_obj

TInactUserRemainDays.proto_property = {'InactUserRemainDays'}

TInactUserRemainDays.default = {0}

TInactUserRemainDays.struct = {{name = 'InactUserRemainDays', is_array = false, struct = nil}}

function TInactUserRemainDays:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'InactUserRemainDays', self.InactUserRemainDays, 'uint32', false, errs, need_convert)

    TInactUserRemainDays:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TInactUserRemainDays.proto_property, errs, need_convert)
    return self
end

function TInactUserRemainDays:unpack(_)
    return self.InactUserRemainDays
end

MManagerAccountDB.InactUserRemainDays = TInactUserRemainDays

---@class MManagerAccountDB.LoginRuleIds
---@field LoginRuleIds integer
local TLoginRuleIds = {}
TLoginRuleIds.__index = TLoginRuleIds
TLoginRuleIds.group = {}

local function TLoginRuleIds_from_obj(obj)
    return setmetatable(obj, TLoginRuleIds)
end

function TLoginRuleIds.new(LoginRuleIds)
    return TLoginRuleIds_from_obj({LoginRuleIds = LoginRuleIds or 0})
end
---@param obj MManagerAccountDB.LoginRuleIds
function TLoginRuleIds:init_from_obj(obj)
    self.LoginRuleIds = obj.LoginRuleIds or 0
end

function TLoginRuleIds:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLoginRuleIds.group)
end

TLoginRuleIds.from_obj = TLoginRuleIds_from_obj

TLoginRuleIds.proto_property = {'LoginRuleIds'}

TLoginRuleIds.default = {0}

TLoginRuleIds.struct = {{name = 'LoginRuleIds', is_array = false, struct = nil}}

function TLoginRuleIds:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'LoginRuleIds', self.LoginRuleIds, 'uint8', false, errs, need_convert)

    TLoginRuleIds:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLoginRuleIds.proto_property, errs, need_convert)
    return self
end

function TLoginRuleIds:unpack(_)
    return self.LoginRuleIds
end

MManagerAccountDB.LoginRuleIds = TLoginRuleIds

---@class MManagerAccountDB.WithinMinPasswordDays
---@field WithinMinPasswordDays boolean
local TWithinMinPasswordDays = {}
TWithinMinPasswordDays.__index = TWithinMinPasswordDays
TWithinMinPasswordDays.group = {}

local function TWithinMinPasswordDays_from_obj(obj)
    return setmetatable(obj, TWithinMinPasswordDays)
end

function TWithinMinPasswordDays.new(WithinMinPasswordDays)
    return TWithinMinPasswordDays_from_obj({WithinMinPasswordDays = WithinMinPasswordDays or false})
end
---@param obj MManagerAccountDB.WithinMinPasswordDays
function TWithinMinPasswordDays:init_from_obj(obj)
    self.WithinMinPasswordDays = obj.WithinMinPasswordDays or false
end

function TWithinMinPasswordDays:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TWithinMinPasswordDays.group)
end

TWithinMinPasswordDays.from_obj = TWithinMinPasswordDays_from_obj

TWithinMinPasswordDays.proto_property = {'WithinMinPasswordDays'}

TWithinMinPasswordDays.default = {false}

TWithinMinPasswordDays.struct = {{name = 'WithinMinPasswordDays', is_array = false, struct = nil}}

function TWithinMinPasswordDays:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'WithinMinPasswordDays', self.WithinMinPasswordDays, 'bool', false, errs, need_convert)

    TWithinMinPasswordDays:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TWithinMinPasswordDays.proto_property, errs, need_convert)
    return self
end

function TWithinMinPasswordDays:unpack(_)
    return self.WithinMinPasswordDays
end

MManagerAccountDB.WithinMinPasswordDays = TWithinMinPasswordDays

---@class MManagerAccountDB.IpmiPasswordBak
---@field IpmiPasswordBak string
local TIpmiPasswordBak = {}
TIpmiPasswordBak.__index = TIpmiPasswordBak
TIpmiPasswordBak.group = {}

local function TIpmiPasswordBak_from_obj(obj)
    return setmetatable(obj, TIpmiPasswordBak)
end

function TIpmiPasswordBak.new(IpmiPasswordBak)
    return TIpmiPasswordBak_from_obj({IpmiPasswordBak = IpmiPasswordBak})
end
---@param obj MManagerAccountDB.IpmiPasswordBak
function TIpmiPasswordBak:init_from_obj(obj)
    self.IpmiPasswordBak = obj.IpmiPasswordBak
end

function TIpmiPasswordBak:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIpmiPasswordBak.group)
end

TIpmiPasswordBak.from_obj = TIpmiPasswordBak_from_obj

TIpmiPasswordBak.proto_property = {'IpmiPasswordBak'}

TIpmiPasswordBak.default = {''}

TIpmiPasswordBak.struct = {{name = 'IpmiPasswordBak', is_array = false, struct = nil}}

function TIpmiPasswordBak:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpmiPasswordBak', self.IpmiPasswordBak, 'string', false, errs, need_convert)

    TIpmiPasswordBak:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIpmiPasswordBak.proto_property, errs, need_convert)
    return self
end

function TIpmiPasswordBak:unpack(_)
    return self.IpmiPasswordBak
end

MManagerAccountDB.IpmiPasswordBak = TIpmiPasswordBak

---@class MManagerAccountDB.IpmiPassword
---@field IpmiPassword string
local TIpmiPassword = {}
TIpmiPassword.__index = TIpmiPassword
TIpmiPassword.group = {}

local function TIpmiPassword_from_obj(obj)
    return setmetatable(obj, TIpmiPassword)
end

function TIpmiPassword.new(IpmiPassword)
    return TIpmiPassword_from_obj({IpmiPassword = IpmiPassword})
end
---@param obj MManagerAccountDB.IpmiPassword
function TIpmiPassword:init_from_obj(obj)
    self.IpmiPassword = obj.IpmiPassword
end

function TIpmiPassword:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIpmiPassword.group)
end

TIpmiPassword.from_obj = TIpmiPassword_from_obj

TIpmiPassword.proto_property = {'IpmiPassword'}

TIpmiPassword.default = {''}

TIpmiPassword.struct = {{name = 'IpmiPassword', is_array = false, struct = nil}}

function TIpmiPassword:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'IpmiPassword', self.IpmiPassword, 'string', false, errs, need_convert)

    TIpmiPassword:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIpmiPassword.proto_property, errs, need_convert)
    return self
end

function TIpmiPassword:unpack(_)
    return self.IpmiPassword
end

MManagerAccountDB.IpmiPassword = TIpmiPassword

---@class MManagerAccountDB.SshPublicKeyHash
---@field SshPublicKeyHash string
local TSshPublicKeyHash = {}
TSshPublicKeyHash.__index = TSshPublicKeyHash
TSshPublicKeyHash.group = {}

local function TSshPublicKeyHash_from_obj(obj)
    return setmetatable(obj, TSshPublicKeyHash)
end

function TSshPublicKeyHash.new(SshPublicKeyHash)
    return TSshPublicKeyHash_from_obj({SshPublicKeyHash = SshPublicKeyHash or [=[]=]})
end
---@param obj MManagerAccountDB.SshPublicKeyHash
function TSshPublicKeyHash:init_from_obj(obj)
    self.SshPublicKeyHash = obj.SshPublicKeyHash or [=[]=]
end

function TSshPublicKeyHash:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSshPublicKeyHash.group)
end

TSshPublicKeyHash.from_obj = TSshPublicKeyHash_from_obj

TSshPublicKeyHash.proto_property = {'SshPublicKeyHash'}

TSshPublicKeyHash.default = {''}

TSshPublicKeyHash.struct = {{name = 'SshPublicKeyHash', is_array = false, struct = nil}}

function TSshPublicKeyHash:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SshPublicKeyHash', self.SshPublicKeyHash, 'string', false, errs, need_convert)

    TSshPublicKeyHash:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSshPublicKeyHash.proto_property, errs, need_convert)
    return self
end

function TSshPublicKeyHash:unpack(_)
    return self.SshPublicKeyHash
end

MManagerAccountDB.SshPublicKeyHash = TSshPublicKeyHash

---@class MManagerAccountDB.RoleId
---@field RoleId integer
local TRoleId = {}
TRoleId.__index = TRoleId
TRoleId.group = {}

local function TRoleId_from_obj(obj)
    return setmetatable(obj, TRoleId)
end

function TRoleId.new(RoleId)
    return TRoleId_from_obj({RoleId = RoleId or 0})
end
---@param obj MManagerAccountDB.RoleId
function TRoleId:init_from_obj(obj)
    self.RoleId = obj.RoleId or 0
end

function TRoleId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRoleId.group)
end

TRoleId.from_obj = TRoleId_from_obj

TRoleId.proto_property = {'RoleId'}

TRoleId.default = {0}

TRoleId.struct = {{name = 'RoleId', is_array = false, struct = nil}}

function TRoleId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RoleId', self.RoleId, 'uint8', false, errs, need_convert)

    TRoleId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRoleId.proto_property, errs, need_convert)
    return self
end

function TRoleId:unpack(_)
    return self.RoleId
end

MManagerAccountDB.RoleId = TRoleId

---@class MManagerAccountDB.PasswordExpiration
---@field PasswordExpiration integer
local TPasswordExpiration = {}
TPasswordExpiration.__index = TPasswordExpiration
TPasswordExpiration.group = {}

local function TPasswordExpiration_from_obj(obj)
    return setmetatable(obj, TPasswordExpiration)
end

function TPasswordExpiration.new(PasswordExpiration)
    return TPasswordExpiration_from_obj({PasswordExpiration = PasswordExpiration or 4294967295})
end
---@param obj MManagerAccountDB.PasswordExpiration
function TPasswordExpiration:init_from_obj(obj)
    self.PasswordExpiration = obj.PasswordExpiration or 4294967295
end

function TPasswordExpiration:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPasswordExpiration.group)
end

TPasswordExpiration.from_obj = TPasswordExpiration_from_obj

TPasswordExpiration.proto_property = {'PasswordExpiration'}

TPasswordExpiration.default = {0}

TPasswordExpiration.struct = {{name = 'PasswordExpiration', is_array = false, struct = nil}}

function TPasswordExpiration:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PasswordExpiration', self.PasswordExpiration, 'uint32', false, errs, need_convert)

    TPasswordExpiration:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPasswordExpiration.proto_property, errs, need_convert)
    return self
end

function TPasswordExpiration:unpack(_)
    return self.PasswordExpiration
end

MManagerAccountDB.PasswordExpiration = TPasswordExpiration

---@class MManagerAccountDB.PasswordChangeRequired
---@field PasswordChangeRequired boolean
local TPasswordChangeRequired = {}
TPasswordChangeRequired.__index = TPasswordChangeRequired
TPasswordChangeRequired.group = {}

local function TPasswordChangeRequired_from_obj(obj)
    return setmetatable(obj, TPasswordChangeRequired)
end

function TPasswordChangeRequired.new(PasswordChangeRequired)
    return TPasswordChangeRequired_from_obj({
        PasswordChangeRequired = PasswordChangeRequired == nil and true or PasswordChangeRequired
    })
end
---@param obj MManagerAccountDB.PasswordChangeRequired
function TPasswordChangeRequired:init_from_obj(obj)
    self.PasswordChangeRequired = obj.PasswordChangeRequired == nil and true or obj.PasswordChangeRequired
end

function TPasswordChangeRequired:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPasswordChangeRequired.group)
end

TPasswordChangeRequired.from_obj = TPasswordChangeRequired_from_obj

TPasswordChangeRequired.proto_property = {'PasswordChangeRequired'}

TPasswordChangeRequired.default = {false}

TPasswordChangeRequired.struct = {{name = 'PasswordChangeRequired', is_array = false, struct = nil}}

function TPasswordChangeRequired:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PasswordChangeRequired', self.PasswordChangeRequired, 'bool', false, errs, need_convert)

    TPasswordChangeRequired:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPasswordChangeRequired.proto_property, errs, need_convert)
    return self
end

function TPasswordChangeRequired:unpack(_)
    return self.PasswordChangeRequired
end

MManagerAccountDB.PasswordChangeRequired = TPasswordChangeRequired

---@class MManagerAccountDB.KDFPassword
---@field KDFPassword string
local TKDFPassword = {}
TKDFPassword.__index = TKDFPassword
TKDFPassword.group = {}

local function TKDFPassword_from_obj(obj)
    return setmetatable(obj, TKDFPassword)
end

function TKDFPassword.new(KDFPassword)
    return TKDFPassword_from_obj({KDFPassword = KDFPassword})
end
---@param obj MManagerAccountDB.KDFPassword
function TKDFPassword:init_from_obj(obj)
    self.KDFPassword = obj.KDFPassword
end

function TKDFPassword:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TKDFPassword.group)
end

TKDFPassword.from_obj = TKDFPassword_from_obj

TKDFPassword.proto_property = {'KDFPassword'}

TKDFPassword.default = {''}

TKDFPassword.struct = {{name = 'KDFPassword', is_array = false, struct = nil}}

function TKDFPassword:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'KDFPassword', self.KDFPassword, 'string', false, errs, need_convert)

    TKDFPassword:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TKDFPassword.proto_property, errs, need_convert)
    return self
end

function TKDFPassword:unpack(_)
    return self.KDFPassword
end

MManagerAccountDB.KDFPassword = TKDFPassword

---@class MManagerAccountDB.Password
---@field Password string
local TPassword = {}
TPassword.__index = TPassword
TPassword.group = {}

local function TPassword_from_obj(obj)
    return setmetatable(obj, TPassword)
end

function TPassword.new(Password)
    return TPassword_from_obj({Password = Password})
end
---@param obj MManagerAccountDB.Password
function TPassword:init_from_obj(obj)
    self.Password = obj.Password
end

function TPassword:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPassword.group)
end

TPassword.from_obj = TPassword_from_obj

TPassword.proto_property = {'Password'}

TPassword.default = {''}

TPassword.struct = {{name = 'Password', is_array = false, struct = nil}}

function TPassword:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'Password', self.Password, 'string', false, errs, need_convert)

    TPassword:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPassword.proto_property, errs, need_convert)
    return self
end

function TPassword:unpack(_)
    return self.Password
end

MManagerAccountDB.Password = TPassword

---@class MManagerAccountDB.Deletable
---@field Deletable boolean
local TDeletable = {}
TDeletable.__index = TDeletable
TDeletable.group = {}

local function TDeletable_from_obj(obj)
    return setmetatable(obj, TDeletable)
end

function TDeletable.new(Deletable)
    return TDeletable_from_obj({Deletable = Deletable or false})
end
---@param obj MManagerAccountDB.Deletable
function TDeletable:init_from_obj(obj)
    self.Deletable = obj.Deletable or false
end

function TDeletable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeletable.group)
end

TDeletable.from_obj = TDeletable_from_obj

TDeletable.proto_property = {'Deletable'}

TDeletable.default = {false}

TDeletable.struct = {{name = 'Deletable', is_array = false, struct = nil}}

function TDeletable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Deletable', self.Deletable, 'bool', false, errs, need_convert)

    TDeletable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeletable.proto_property, errs, need_convert)
    return self
end

function TDeletable:unpack(_)
    return self.Deletable
end

MManagerAccountDB.Deletable = TDeletable

---@class MManagerAccountDB.UserName
---@field UserName string
local TUserName = {}
TUserName.__index = TUserName
TUserName.group = {}

local function TUserName_from_obj(obj)
    return setmetatable(obj, TUserName)
end

function TUserName.new(UserName)
    return TUserName_from_obj({UserName = UserName})
end
---@param obj MManagerAccountDB.UserName
function TUserName:init_from_obj(obj)
    self.UserName = obj.UserName
end

function TUserName:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUserName.group)
end

TUserName.from_obj = TUserName_from_obj

TUserName.proto_property = {'UserName'}

TUserName.default = {''}

TUserName.struct = {{name = 'UserName', is_array = false, struct = nil}}

function TUserName:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserName', self.UserName, 'string', false, errs, need_convert)

    TUserName:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUserName.proto_property, errs, need_convert)
    return self
end

function TUserName:unpack(_)
    return self.UserName
end

MManagerAccountDB.UserName = TUserName

---@class MManagerAccountDB.Locked
---@field Locked boolean
local TLocked = {}
TLocked.__index = TLocked
TLocked.group = {}

local function TLocked_from_obj(obj)
    return setmetatable(obj, TLocked)
end

function TLocked.new(Locked)
    return TLocked_from_obj({Locked = Locked or false})
end
---@param obj MManagerAccountDB.Locked
function TLocked:init_from_obj(obj)
    self.Locked = obj.Locked or false
end

function TLocked:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLocked.group)
end

TLocked.from_obj = TLocked_from_obj

TLocked.proto_property = {'Locked'}

TLocked.default = {false}

TLocked.struct = {{name = 'Locked', is_array = false, struct = nil}}

function TLocked:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Locked', self.Locked, 'bool', false, errs, need_convert)

    TLocked:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLocked.proto_property, errs, need_convert)
    return self
end

function TLocked:unpack(_)
    return self.Locked
end

MManagerAccountDB.Locked = TLocked

---@class MManagerAccountDB.Id
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
---@param obj MManagerAccountDB.Id
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

MManagerAccountDB.Id = TId

---@class MManagerAccountDB.Enabled
---@field Enabled boolean
local TEnabled = {}
TEnabled.__index = TEnabled
TEnabled.group = {}

local function TEnabled_from_obj(obj)
    return setmetatable(obj, TEnabled)
end

function TEnabled.new(Enabled)
    return TEnabled_from_obj({Enabled = Enabled or false})
end
---@param obj MManagerAccountDB.Enabled
function TEnabled:init_from_obj(obj)
    self.Enabled = obj.Enabled or false
end

function TEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TEnabled.group)
end

TEnabled.from_obj = TEnabled_from_obj

TEnabled.proto_property = {'Enabled'}

TEnabled.default = {false}

TEnabled.struct = {{name = 'Enabled', is_array = false, struct = nil}}

function TEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Enabled', self.Enabled, 'bool', false, errs, need_convert)

    TEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TEnabled.proto_property, errs, need_convert)
    return self
end

function TEnabled:unpack(_)
    return self.Enabled
end

MManagerAccountDB.Enabled = TEnabled

---@class MManagerAccountDB.Certificates
---@field Certificates integer
local TCertificates = {}
TCertificates.__index = TCertificates
TCertificates.group = {}

local function TCertificates_from_obj(obj)
    return setmetatable(obj, TCertificates)
end

function TCertificates.new(Certificates)
    return TCertificates_from_obj({Certificates = Certificates})
end
---@param obj MManagerAccountDB.Certificates
function TCertificates:init_from_obj(obj)
    self.Certificates = obj.Certificates
end

function TCertificates:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TCertificates.group)
end

TCertificates.from_obj = TCertificates_from_obj

TCertificates.proto_property = {'Certificates'}

TCertificates.default = {0}

TCertificates.struct = {{name = 'Certificates', is_array = false, struct = nil}}

function TCertificates:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Certificates', self.Certificates, 'uint16', false, errs, need_convert)

    TCertificates:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TCertificates.proto_property, errs, need_convert)
    return self
end

function TCertificates:unpack(_)
    return self.Certificates
end

MManagerAccountDB.Certificates = TCertificates

---@class MManagerAccountDB.AccountExpiration
---@field AccountExpiration string
local TAccountExpiration = {}
TAccountExpiration.__index = TAccountExpiration
TAccountExpiration.group = {}

local function TAccountExpiration_from_obj(obj)
    return setmetatable(obj, TAccountExpiration)
end

function TAccountExpiration.new(AccountExpiration)
    return TAccountExpiration_from_obj({AccountExpiration = AccountExpiration})
end
---@param obj MManagerAccountDB.AccountExpiration
function TAccountExpiration:init_from_obj(obj)
    self.AccountExpiration = obj.AccountExpiration
end

function TAccountExpiration:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountExpiration.group)
end

TAccountExpiration.from_obj = TAccountExpiration_from_obj

TAccountExpiration.proto_property = {'AccountExpiration'}

TAccountExpiration.default = {''}

TAccountExpiration.struct = {{name = 'AccountExpiration', is_array = false, struct = nil}}

function TAccountExpiration:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountExpiration', self.AccountExpiration, 'string', false, errs, need_convert)

    TAccountExpiration:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountExpiration.proto_property, errs, need_convert)
    return self
end

function TAccountExpiration:unpack(_)
    return self.AccountExpiration
end

MManagerAccountDB.AccountExpiration = TAccountExpiration

return MManagerAccountDB
