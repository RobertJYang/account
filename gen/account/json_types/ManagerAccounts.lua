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
local create_enum_type = require 'mc.enum'

local ManagerAccounts = {}

---@class ManagerAccounts.FirstLoginPolicy: Enum
local EFirstLoginPolicy = create_enum_type('FirstLoginPolicy')
EFirstLoginPolicy.default = EFirstLoginPolicy.new(2147483647)
EFirstLoginPolicy.struct = nil
EFirstLoginPolicy.PromptPasswordReset = EFirstLoginPolicy.new(1)
EFirstLoginPolicy.ForcePasswordReset = EFirstLoginPolicy.new(2)

ManagerAccounts.FirstLoginPolicy = EFirstLoginPolicy

---@class ManagerAccounts.LoginInterfaceType: Enum
local ELoginInterfaceType = create_enum_type('LoginInterfaceType')
ELoginInterfaceType.default = ELoginInterfaceType.new(2147483647)
ELoginInterfaceType.struct = nil
ELoginInterfaceType.Invalid = ELoginInterfaceType.new(0)
ELoginInterfaceType.Web = ELoginInterfaceType.new(1)
ELoginInterfaceType.SNMP = ELoginInterfaceType.new(2)
ELoginInterfaceType.IPMI = ELoginInterfaceType.new(4)
ELoginInterfaceType.SSH = ELoginInterfaceType.new(8)
ELoginInterfaceType.SFTP = ELoginInterfaceType.new(16)
ELoginInterfaceType.Local = ELoginInterfaceType.new(64)
ELoginInterfaceType.Redfish = ELoginInterfaceType.new(128)

ManagerAccounts.LoginInterfaceType = ELoginInterfaceType

---@class ManagerAccounts.RoleType: Enum
local ERoleType = create_enum_type('RoleType')
ERoleType.default = ERoleType.new(2147483647)
ERoleType.struct = nil
ERoleType.NoAccess = ERoleType.new(0)
ERoleType.CommonUser = ERoleType.new(2)
ERoleType.Operator = ERoleType.new(3)
ERoleType.Administrator = ERoleType.new(4)
ERoleType.CustomRole1 = ERoleType.new(5)
ERoleType.CustomRole2 = ERoleType.new(6)
ERoleType.CustomRole3 = ERoleType.new(7)
ERoleType.CustomRole4 = ERoleType.new(8)
ERoleType.CustomRole5 = ERoleType.new(9)
ERoleType.CustomRole6 = ERoleType.new(10)
ERoleType.CustomRole7 = ERoleType.new(11)
ERoleType.CustomRole8 = ERoleType.new(12)
ERoleType.CustomRole9 = ERoleType.new(13)
ERoleType.CustomRole10 = ERoleType.new(14)
ERoleType.CustomRole11 = ERoleType.new(15)
ERoleType.CustomRole12 = ERoleType.new(16)
ERoleType.CustomRole13 = ERoleType.new(17)
ERoleType.CustomRole14 = ERoleType.new(18)
ERoleType.CustomRole15 = ERoleType.new(19)
ERoleType.CustomRole16 = ERoleType.new(20)

ManagerAccounts.RoleType = ERoleType

---@class ManagerAccounts.SnmpPasswordChangedSignalSignature
---@field AccountId integer
local TSnmpPasswordChangedSignalSignature = {}
TSnmpPasswordChangedSignalSignature.__index = TSnmpPasswordChangedSignalSignature
TSnmpPasswordChangedSignalSignature.group = {}

local function TSnmpPasswordChangedSignalSignature_from_obj(obj)
    return setmetatable(obj, TSnmpPasswordChangedSignalSignature)
end

function TSnmpPasswordChangedSignalSignature.new(AccountId)
    return TSnmpPasswordChangedSignalSignature_from_obj({AccountId = AccountId})
end
---@param obj ManagerAccounts.SnmpPasswordChangedSignalSignature
function TSnmpPasswordChangedSignalSignature:init_from_obj(obj)
    self.AccountId = obj.AccountId
end

function TSnmpPasswordChangedSignalSignature:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSnmpPasswordChangedSignalSignature.group)
end

TSnmpPasswordChangedSignalSignature.from_obj = TSnmpPasswordChangedSignalSignature_from_obj

TSnmpPasswordChangedSignalSignature.proto_property = {'AccountId'}

TSnmpPasswordChangedSignalSignature.default = {0}

TSnmpPasswordChangedSignalSignature.struct = {{name = 'AccountId', is_array = false, struct = nil}}

function TSnmpPasswordChangedSignalSignature:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)

    TSnmpPasswordChangedSignalSignature:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSnmpPasswordChangedSignalSignature.proto_property, errs, need_convert)
    return self
end

function TSnmpPasswordChangedSignalSignature:unpack(_)
    return self.AccountId
end

ManagerAccounts.SnmpPasswordChangedSignalSignature = TSnmpPasswordChangedSignalSignature

---@class ManagerAccounts.PasswordChangedSignalSignature
---@field AccountId integer
local TPasswordChangedSignalSignature = {}
TPasswordChangedSignalSignature.__index = TPasswordChangedSignalSignature
TPasswordChangedSignalSignature.group = {}

local function TPasswordChangedSignalSignature_from_obj(obj)
    return setmetatable(obj, TPasswordChangedSignalSignature)
end

function TPasswordChangedSignalSignature.new(AccountId)
    return TPasswordChangedSignalSignature_from_obj({AccountId = AccountId})
end
---@param obj ManagerAccounts.PasswordChangedSignalSignature
function TPasswordChangedSignalSignature:init_from_obj(obj)
    self.AccountId = obj.AccountId
end

function TPasswordChangedSignalSignature:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPasswordChangedSignalSignature.group)
end

TPasswordChangedSignalSignature.from_obj = TPasswordChangedSignalSignature_from_obj

TPasswordChangedSignalSignature.proto_property = {'AccountId'}

TPasswordChangedSignalSignature.default = {0}

TPasswordChangedSignalSignature.struct = {{name = 'AccountId', is_array = false, struct = nil}}

function TPasswordChangedSignalSignature:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)

    TPasswordChangedSignalSignature:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPasswordChangedSignalSignature.proto_property, errs, need_convert)
    return self
end

function TPasswordChangedSignalSignature:unpack(_)
    return self.AccountId
end

ManagerAccounts.PasswordChangedSignalSignature = TPasswordChangedSignalSignature

---@class ManagerAccounts.GetUidGidByUserNameRsp
---@field UID integer
---@field GID integer
local TGetUidGidByUserNameRsp = {}
TGetUidGidByUserNameRsp.__index = TGetUidGidByUserNameRsp
TGetUidGidByUserNameRsp.group = {}

local function TGetUidGidByUserNameRsp_from_obj(obj)
    return setmetatable(obj, TGetUidGidByUserNameRsp)
end

function TGetUidGidByUserNameRsp.new(UID, GID)
    return TGetUidGidByUserNameRsp_from_obj({UID = UID, GID = GID})
end
---@param obj ManagerAccounts.GetUidGidByUserNameRsp
function TGetUidGidByUserNameRsp:init_from_obj(obj)
    self.UID = obj.UID
    self.GID = obj.GID
end

function TGetUidGidByUserNameRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetUidGidByUserNameRsp.group)
end

TGetUidGidByUserNameRsp.from_obj = TGetUidGidByUserNameRsp_from_obj

TGetUidGidByUserNameRsp.proto_property = {'UID', 'GID'}

TGetUidGidByUserNameRsp.default = {0, 0}

TGetUidGidByUserNameRsp.struct = {
    {name = 'UID', is_array = false, struct = nil}, {name = 'GID', is_array = false, struct = nil}
}

function TGetUidGidByUserNameRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UID', self.UID, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'GID', self.GID, 'uint32', false, errs, need_convert)

    TGetUidGidByUserNameRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetUidGidByUserNameRsp.proto_property, errs, need_convert)
    return self
end

function TGetUidGidByUserNameRsp:unpack(_)
    return self.UID, self.GID
end

ManagerAccounts.GetUidGidByUserNameRsp = TGetUidGidByUserNameRsp

---@class ManagerAccounts.GetUidGidByUserNameReq
---@field UserName string
local TGetUidGidByUserNameReq = {}
TGetUidGidByUserNameReq.__index = TGetUidGidByUserNameReq
TGetUidGidByUserNameReq.group = {}

local function TGetUidGidByUserNameReq_from_obj(obj)
    return setmetatable(obj, TGetUidGidByUserNameReq)
end

function TGetUidGidByUserNameReq.new(UserName)
    return TGetUidGidByUserNameReq_from_obj({UserName = UserName})
end
---@param obj ManagerAccounts.GetUidGidByUserNameReq
function TGetUidGidByUserNameReq:init_from_obj(obj)
    self.UserName = obj.UserName
end

function TGetUidGidByUserNameReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetUidGidByUserNameReq.group)
end

TGetUidGidByUserNameReq.from_obj = TGetUidGidByUserNameReq_from_obj

TGetUidGidByUserNameReq.proto_property = {'UserName'}

TGetUidGidByUserNameReq.default = {''}

TGetUidGidByUserNameReq.struct = {{name = 'UserName', is_array = false, struct = nil}}

function TGetUidGidByUserNameReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserName', self.UserName, 'string', false, errs, need_convert)

    if self.UserName ~= nil then
        validate.lens(prefix .. 'UserName', self.UserName, 1, 32, errs, need_convert)
    end

    TGetUidGidByUserNameReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetUidGidByUserNameReq.proto_property, errs, need_convert)
    return self
end

function TGetUidGidByUserNameReq:unpack(_)
    return self.UserName
end

ManagerAccounts.GetUidGidByUserNameReq = TGetUidGidByUserNameReq

---@class ManagerAccounts.SetAccountLockStateRsp
local TSetAccountLockStateRsp = {}
TSetAccountLockStateRsp.__index = TSetAccountLockStateRsp
TSetAccountLockStateRsp.group = {}

local function TSetAccountLockStateRsp_from_obj(obj)
    return setmetatable(obj, TSetAccountLockStateRsp)
end

function TSetAccountLockStateRsp.new()
    return TSetAccountLockStateRsp_from_obj({})
end
---@param obj ManagerAccounts.SetAccountLockStateRsp
function TSetAccountLockStateRsp:init_from_obj(obj)

end

function TSetAccountLockStateRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetAccountLockStateRsp.group)
end

TSetAccountLockStateRsp.from_obj = TSetAccountLockStateRsp_from_obj

TSetAccountLockStateRsp.proto_property = {}

TSetAccountLockStateRsp.default = {}

TSetAccountLockStateRsp.struct = {}

function TSetAccountLockStateRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetAccountLockStateRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetAccountLockStateRsp.proto_property, errs, need_convert)
    return self
end

function TSetAccountLockStateRsp:unpack(_)
end

ManagerAccounts.SetAccountLockStateRsp = TSetAccountLockStateRsp

---@class ManagerAccounts.SetAccountLockStateReq
---@field AccountId integer
---@field Lockstatus boolean
local TSetAccountLockStateReq = {}
TSetAccountLockStateReq.__index = TSetAccountLockStateReq
TSetAccountLockStateReq.group = {}

local function TSetAccountLockStateReq_from_obj(obj)
    return setmetatable(obj, TSetAccountLockStateReq)
end

function TSetAccountLockStateReq.new(AccountId, Lockstatus)
    return TSetAccountLockStateReq_from_obj({AccountId = AccountId, Lockstatus = Lockstatus})
end
---@param obj ManagerAccounts.SetAccountLockStateReq
function TSetAccountLockStateReq:init_from_obj(obj)
    self.AccountId = obj.AccountId
    self.Lockstatus = obj.Lockstatus
end

function TSetAccountLockStateReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetAccountLockStateReq.group)
end

TSetAccountLockStateReq.from_obj = TSetAccountLockStateReq_from_obj

TSetAccountLockStateReq.proto_property = {'AccountId', 'Lockstatus'}

TSetAccountLockStateReq.default = {0, false}

TSetAccountLockStateReq.struct = {
    {name = 'AccountId', is_array = false, struct = nil}, {name = 'Lockstatus', is_array = false, struct = nil}
}

function TSetAccountLockStateReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Lockstatus', self.Lockstatus, 'bool', false, errs, need_convert)

    if self.AccountId ~= nil then
        validate.ranges(prefix .. 'AccountId', self.AccountId, 2, 115, errs, need_convert)
    end

    TSetAccountLockStateReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetAccountLockStateReq.proto_property, errs, need_convert)
    return self
end

function TSetAccountLockStateReq:unpack(_)
    return self.AccountId, self.Lockstatus
end

ManagerAccounts.SetAccountLockStateReq = TSetAccountLockStateReq

---@class ManagerAccounts.GetAccountWritableReq
---@field AccountId integer
local TGetAccountWritableReq = {}
TGetAccountWritableReq.__index = TGetAccountWritableReq
TGetAccountWritableReq.group = {}

local function TGetAccountWritableReq_from_obj(obj)
    return setmetatable(obj, TGetAccountWritableReq)
end

function TGetAccountWritableReq.new(AccountId)
    return TGetAccountWritableReq_from_obj({AccountId = AccountId})
end
---@param obj ManagerAccounts.GetAccountWritableReq
function TGetAccountWritableReq:init_from_obj(obj)
    self.AccountId = obj.AccountId
end

function TGetAccountWritableReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetAccountWritableReq.group)
end

TGetAccountWritableReq.from_obj = TGetAccountWritableReq_from_obj

TGetAccountWritableReq.proto_property = {'AccountId'}

TGetAccountWritableReq.default = {0}

TGetAccountWritableReq.struct = {{name = 'AccountId', is_array = false, struct = nil}}

function TGetAccountWritableReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)

    if self.AccountId ~= nil then
        validate.ranges(prefix .. 'AccountId', self.AccountId, 2, 115, errs, need_convert)
    end

    TGetAccountWritableReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetAccountWritableReq.proto_property, errs, need_convert)
    return self
end

function TGetAccountWritableReq:unpack(_)
    return self.AccountId
end

ManagerAccounts.GetAccountWritableReq = TGetAccountWritableReq

---@class ManagerAccounts.SetAccountWritableRsp
local TSetAccountWritableRsp = {}
TSetAccountWritableRsp.__index = TSetAccountWritableRsp
TSetAccountWritableRsp.group = {}

local function TSetAccountWritableRsp_from_obj(obj)
    return setmetatable(obj, TSetAccountWritableRsp)
end

function TSetAccountWritableRsp.new()
    return TSetAccountWritableRsp_from_obj({})
end
---@param obj ManagerAccounts.SetAccountWritableRsp
function TSetAccountWritableRsp:init_from_obj(obj)

end

function TSetAccountWritableRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetAccountWritableRsp.group)
end

TSetAccountWritableRsp.from_obj = TSetAccountWritableRsp_from_obj

TSetAccountWritableRsp.proto_property = {}

TSetAccountWritableRsp.default = {}

TSetAccountWritableRsp.struct = {}

function TSetAccountWritableRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetAccountWritableRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetAccountWritableRsp.proto_property, errs, need_convert)
    return self
end

function TSetAccountWritableRsp:unpack(_)
end

ManagerAccounts.SetAccountWritableRsp = TSetAccountWritableRsp

---@class ManagerAccounts.GetIdByUserNameRsp
---@field AccountId integer
local TGetIdByUserNameRsp = {}
TGetIdByUserNameRsp.__index = TGetIdByUserNameRsp
TGetIdByUserNameRsp.group = {}

local function TGetIdByUserNameRsp_from_obj(obj)
    return setmetatable(obj, TGetIdByUserNameRsp)
end

function TGetIdByUserNameRsp.new(AccountId)
    return TGetIdByUserNameRsp_from_obj({AccountId = AccountId})
end
---@param obj ManagerAccounts.GetIdByUserNameRsp
function TGetIdByUserNameRsp:init_from_obj(obj)
    self.AccountId = obj.AccountId
end

function TGetIdByUserNameRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetIdByUserNameRsp.group)
end

TGetIdByUserNameRsp.from_obj = TGetIdByUserNameRsp_from_obj

TGetIdByUserNameRsp.proto_property = {'AccountId'}

TGetIdByUserNameRsp.default = {0}

TGetIdByUserNameRsp.struct = {{name = 'AccountId', is_array = false, struct = nil}}

function TGetIdByUserNameRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)

    TGetIdByUserNameRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetIdByUserNameRsp.proto_property, errs, need_convert)
    return self
end

function TGetIdByUserNameRsp:unpack(_)
    return self.AccountId
end

ManagerAccounts.GetIdByUserNameRsp = TGetIdByUserNameRsp

---@class ManagerAccounts.GetIdByUserNameReq
---@field UserName string
local TGetIdByUserNameReq = {}
TGetIdByUserNameReq.__index = TGetIdByUserNameReq
TGetIdByUserNameReq.group = {}

local function TGetIdByUserNameReq_from_obj(obj)
    return setmetatable(obj, TGetIdByUserNameReq)
end

function TGetIdByUserNameReq.new(UserName)
    return TGetIdByUserNameReq_from_obj({UserName = UserName})
end
---@param obj ManagerAccounts.GetIdByUserNameReq
function TGetIdByUserNameReq:init_from_obj(obj)
    self.UserName = obj.UserName
end

function TGetIdByUserNameReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetIdByUserNameReq.group)
end

TGetIdByUserNameReq.from_obj = TGetIdByUserNameReq_from_obj

TGetIdByUserNameReq.proto_property = {'UserName'}

TGetIdByUserNameReq.default = {''}

TGetIdByUserNameReq.struct = {{name = 'UserName', is_array = false, struct = nil}}

function TGetIdByUserNameReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserName', self.UserName, 'string', false, errs, need_convert)

    if self.UserName ~= nil then
        validate.lens(prefix .. 'UserName', self.UserName, 1, 32, errs, need_convert)
    end

    TGetIdByUserNameReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetIdByUserNameReq.proto_property, errs, need_convert)
    return self
end

function TGetIdByUserNameReq:unpack(_)
    return self.UserName
end

ManagerAccounts.GetIdByUserNameReq = TGetIdByUserNameReq

---@class ManagerAccounts.NewOEMAccountRsp
---@field AccountId integer
local TNewOEMAccountRsp = {}
TNewOEMAccountRsp.__index = TNewOEMAccountRsp
TNewOEMAccountRsp.group = {}

local function TNewOEMAccountRsp_from_obj(obj)
    return setmetatable(obj, TNewOEMAccountRsp)
end

function TNewOEMAccountRsp.new(AccountId)
    return TNewOEMAccountRsp_from_obj({AccountId = AccountId})
end
---@param obj ManagerAccounts.NewOEMAccountRsp
function TNewOEMAccountRsp:init_from_obj(obj)
    self.AccountId = obj.AccountId
end

function TNewOEMAccountRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TNewOEMAccountRsp.group)
end

TNewOEMAccountRsp.from_obj = TNewOEMAccountRsp_from_obj

TNewOEMAccountRsp.proto_property = {'AccountId'}

TNewOEMAccountRsp.default = {0}

TNewOEMAccountRsp.struct = {{name = 'AccountId', is_array = false, struct = nil}}

function TNewOEMAccountRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)

    TNewOEMAccountRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNewOEMAccountRsp.proto_property, errs, need_convert)
    return self
end

function TNewOEMAccountRsp:unpack(_)
    return self.AccountId
end

ManagerAccounts.NewOEMAccountRsp = TNewOEMAccountRsp

---@class ManagerAccounts.NewRsp
---@field AccountId integer
local TNewRsp = {}
TNewRsp.__index = TNewRsp
TNewRsp.group = {}

local function TNewRsp_from_obj(obj)
    return setmetatable(obj, TNewRsp)
end

function TNewRsp.new(AccountId)
    return TNewRsp_from_obj({AccountId = AccountId})
end
---@param obj ManagerAccounts.NewRsp
function TNewRsp:init_from_obj(obj)
    self.AccountId = obj.AccountId
end

function TNewRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TNewRsp.group)
end

TNewRsp.from_obj = TNewRsp_from_obj

TNewRsp.proto_property = {'AccountId'}

TNewRsp.default = {0}

TNewRsp.struct = {{name = 'AccountId', is_array = false, struct = nil}}

function TNewRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)

    TNewRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNewRsp.proto_property, errs, need_convert)
    return self
end

function TNewRsp:unpack(_)
    return self.AccountId
end

ManagerAccounts.NewRsp = TNewRsp

---@class ManagerAccounts.ExtraData
---@field key string
---@field value string
local TExtraData = {}
TExtraData.__index = TExtraData
TExtraData.group = {}

local function TExtraData_from_obj(obj)
    return setmetatable(obj, TExtraData)
end

function TExtraData.new(dict)
    return TExtraData_from_obj(dict)
end

---@param obj ManagerAccounts.ExtraData
function TExtraData:init_from_obj(obj)
    self = obj
end

function TExtraData:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExtraData.group)
end

TExtraData.from_obj = TExtraData_from_obj

TExtraData.proto_property = {}

TExtraData.default = {}

TExtraData.struct = {}

function TExtraData:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for k, v in pairs(self) do

        validate.Optional(prefix .. 'key', k, 'string', false, errs, need_convert)

        validate.Optional(prefix .. 'value', v, 'string', false, errs, need_convert)

    end

    TExtraData:remove_error_props(errs, self)
    return self
end

function TExtraData:unpack(_)
    return self
end

ManagerAccounts.ExtraData = TExtraData

---@class ManagerAccounts.NewOEMAccountReq
---@field AccountId integer
---@field UserName string
---@field Password string
---@field ExtraData ManagerAccounts.ExtraData
local TNewOEMAccountReq = {}
TNewOEMAccountReq.__index = TNewOEMAccountReq
TNewOEMAccountReq.group = {}

local function TNewOEMAccountReq_from_obj(obj)
    return setmetatable(obj, TNewOEMAccountReq)
end

function TNewOEMAccountReq.new(AccountId, UserName, Password, ExtraData)
    return TNewOEMAccountReq_from_obj({
        AccountId = AccountId,
        UserName = UserName,
        Password = Password,
        ExtraData = ExtraData
    })
end
---@param obj ManagerAccounts.NewOEMAccountReq
function TNewOEMAccountReq:init_from_obj(obj)
    self.AccountId = obj.AccountId
    self.UserName = obj.UserName
    self.Password = obj.Password
    self.ExtraData = obj.ExtraData
end

function TNewOEMAccountReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TNewOEMAccountReq.group)
end

TNewOEMAccountReq.from_obj = TNewOEMAccountReq_from_obj

TNewOEMAccountReq.proto_property = {'AccountId', 'UserName', 'Password', 'ExtraData'}

TNewOEMAccountReq.default = {0, '', '', ManagerAccounts.ExtraData.default}

TNewOEMAccountReq.struct = {
    {name = 'AccountId', is_array = false, struct = nil}, {name = 'UserName', is_array = false, struct = nil},
    {name = 'Password', is_array = false, struct = nil},
    {name = 'ExtraData', is_array = false, struct = ManagerAccounts.ExtraData.struct}
}

function TNewOEMAccountReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    ManagerAccounts.ExtraData.new(self.ExtraData):validate(prefix, errs, need_convert)

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'UserName', self.UserName, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Password', self.Password, 'string', false, errs, need_convert)

    if self.AccountId ~= nil then
        validate.ranges(prefix .. 'AccountId', self.AccountId, 101, 115, errs, need_convert)
    end
    if self.UserName ~= nil then
        validate.lens(prefix .. 'UserName', self.UserName, 1, 32, errs, need_convert)
    end
    if self.Password ~= nil then
        validate.lens(prefix .. 'Password', self.Password, 1, 1024, errs, need_convert)
    end

    TNewOEMAccountReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNewOEMAccountReq.proto_property, errs, need_convert)
    return self
end

function TNewOEMAccountReq:unpack(_)
    return self.AccountId, self.UserName, self.Password, self.ExtraData
end

ManagerAccounts.NewOEMAccountReq = TNewOEMAccountReq

---@class ManagerAccounts.PropertyWritable
---@field key string
---@field value boolean
local TPropertyWritable = {}
TPropertyWritable.__index = TPropertyWritable
TPropertyWritable.group = {}

local function TPropertyWritable_from_obj(obj)
    return setmetatable(obj, TPropertyWritable)
end

function TPropertyWritable.new(dict)
    return TPropertyWritable_from_obj(dict)
end

---@param obj ManagerAccounts.PropertyWritable
function TPropertyWritable:init_from_obj(obj)
    self = obj
end

function TPropertyWritable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPropertyWritable.group)
end

TPropertyWritable.from_obj = TPropertyWritable_from_obj

TPropertyWritable.proto_property = {}

TPropertyWritable.default = {}

TPropertyWritable.struct = {}

function TPropertyWritable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for k, v in pairs(self) do

        validate.Optional(prefix .. 'key', k, 'string', false, errs, need_convert)

        validate.Optional(prefix .. 'value', v, 'bool', false, errs, need_convert)

    end

    TPropertyWritable:remove_error_props(errs, self)
    return self
end

function TPropertyWritable:unpack(_)
    return self
end

ManagerAccounts.PropertyWritable = TPropertyWritable

---@class ManagerAccounts.GetAccountWritableRsp
---@field PropertiesWritable ManagerAccounts.PropertyWritable
local TGetAccountWritableRsp = {}
TGetAccountWritableRsp.__index = TGetAccountWritableRsp
TGetAccountWritableRsp.group = {}

local function TGetAccountWritableRsp_from_obj(obj)
    return setmetatable(obj, TGetAccountWritableRsp)
end

function TGetAccountWritableRsp.new(PropertiesWritable)
    return TGetAccountWritableRsp_from_obj({PropertiesWritable = PropertiesWritable})
end
---@param obj ManagerAccounts.GetAccountWritableRsp
function TGetAccountWritableRsp:init_from_obj(obj)
    self.PropertiesWritable = obj.PropertiesWritable
end

function TGetAccountWritableRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetAccountWritableRsp.group)
end

TGetAccountWritableRsp.from_obj = TGetAccountWritableRsp_from_obj

TGetAccountWritableRsp.proto_property = {'PropertiesWritable'}

TGetAccountWritableRsp.default = {ManagerAccounts.PropertyWritable.default}

TGetAccountWritableRsp.struct = {
    {name = 'PropertiesWritable', is_array = false, struct = ManagerAccounts.PropertyWritable.struct}
}

function TGetAccountWritableRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    ManagerAccounts.PropertyWritable.new(self.PropertiesWritable):validate(prefix, errs, need_convert)

    TGetAccountWritableRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetAccountWritableRsp.proto_property, errs, need_convert)
    return self
end

function TGetAccountWritableRsp:unpack(_)
    return self.PropertiesWritable
end

ManagerAccounts.GetAccountWritableRsp = TGetAccountWritableRsp

---@class ManagerAccounts.SetAccountWritableReq
---@field AccountId integer
---@field PropertiesWritable ManagerAccounts.PropertyWritable
local TSetAccountWritableReq = {}
TSetAccountWritableReq.__index = TSetAccountWritableReq
TSetAccountWritableReq.group = {}

local function TSetAccountWritableReq_from_obj(obj)
    return setmetatable(obj, TSetAccountWritableReq)
end

function TSetAccountWritableReq.new(AccountId, PropertiesWritable)
    return TSetAccountWritableReq_from_obj({AccountId = AccountId, PropertiesWritable = PropertiesWritable})
end
---@param obj ManagerAccounts.SetAccountWritableReq
function TSetAccountWritableReq:init_from_obj(obj)
    self.AccountId = obj.AccountId
    self.PropertiesWritable = obj.PropertiesWritable
end

function TSetAccountWritableReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetAccountWritableReq.group)
end

TSetAccountWritableReq.from_obj = TSetAccountWritableReq_from_obj

TSetAccountWritableReq.proto_property = {'AccountId', 'PropertiesWritable'}

TSetAccountWritableReq.default = {0, ManagerAccounts.PropertyWritable.default}

TSetAccountWritableReq.struct = {
    {name = 'AccountId', is_array = false, struct = nil},
    {name = 'PropertiesWritable', is_array = false, struct = ManagerAccounts.PropertyWritable.struct}
}

function TSetAccountWritableReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    ManagerAccounts.PropertyWritable.new(self.PropertiesWritable):validate(prefix, errs, need_convert)

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)

    if self.AccountId ~= nil then
        validate.ranges(prefix .. 'AccountId', self.AccountId, 2, 115, errs, need_convert)
    end

    TSetAccountWritableReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetAccountWritableReq.proto_property, errs, need_convert)
    return self
end

function TSetAccountWritableReq:unpack(_)
    return self.AccountId, self.PropertiesWritable
end

ManagerAccounts.SetAccountWritableReq = TSetAccountWritableReq

---@class ManagerAccounts.NewReq
---@field AccountId integer
---@field UserName string
---@field Password integer[]
---@field RoleId ManagerAccounts.RoleType
---@field LoginInterface ManagerAccounts.LoginInterfaceType[]
---@field FirstLoginPolicy ManagerAccounts.FirstLoginPolicy
local TNewReq = {}
TNewReq.__index = TNewReq
TNewReq.group = {}

local function TNewReq_from_obj(obj)
    obj.RoleId = obj.RoleId and ManagerAccounts.RoleType.new(obj.RoleId)
    obj.LoginInterface = utils.from_obj(ManagerAccounts.LoginInterfaceType, obj.LoginInterface, true)
    obj.FirstLoginPolicy = obj.FirstLoginPolicy and ManagerAccounts.FirstLoginPolicy.new(obj.FirstLoginPolicy)
    return setmetatable(obj, TNewReq)
end

function TNewReq.new(AccountId, UserName, Password, RoleId, LoginInterface, FirstLoginPolicy)
    return TNewReq_from_obj({
        AccountId = AccountId,
        UserName = UserName,
        Password = Password,
        RoleId = RoleId,
        LoginInterface = LoginInterface,
        FirstLoginPolicy = FirstLoginPolicy
    })
end
---@param obj ManagerAccounts.NewReq
function TNewReq:init_from_obj(obj)
    self.AccountId = obj.AccountId
    self.UserName = obj.UserName
    self.Password = obj.Password
    self.RoleId = obj.RoleId
    self.LoginInterface = obj.LoginInterface
    self.FirstLoginPolicy = obj.FirstLoginPolicy
end

function TNewReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TNewReq.group)
end

TNewReq.from_obj = TNewReq_from_obj

TNewReq.proto_property = {'AccountId', 'UserName', 'Password', 'RoleId', 'LoginInterface', 'FirstLoginPolicy'}

TNewReq.default = {0, '', {}, ManagerAccounts.RoleType.default, {}, ManagerAccounts.FirstLoginPolicy.default}

TNewReq.struct = {
    {name = 'AccountId', is_array = false, struct = nil}, {name = 'UserName', is_array = false, struct = nil},
    {name = 'Password', is_array = true, struct = nil},
    {name = 'RoleId', is_array = false, struct = ManagerAccounts.RoleType.struct},
    {name = 'LoginInterface', is_array = true, struct = ManagerAccounts.LoginInterfaceType.struct},
    {name = 'FirstLoginPolicy', is_array = false, struct = ManagerAccounts.FirstLoginPolicy.struct}
}

function TNewReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'UserName', self.UserName, 'string', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'Password', self.Password, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'RoleId', self.RoleId, 'ManagerAccounts.RoleType', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'LoginInterface', self.LoginInterface, 'ManagerAccounts.LoginInterfaceType', false,
        errs, need_convert)
    validate.Optional(prefix .. 'FirstLoginPolicy', self.FirstLoginPolicy, 'ManagerAccounts.FirstLoginPolicy', false,
        errs, need_convert)

    if self.AccountId ~= nil then
        validate.ranges(prefix .. 'AccountId', self.AccountId, 0, 17, errs, need_convert)
    end
    if self.UserName ~= nil then
        validate.lens(prefix .. 'UserName', self.UserName, 1, 32, errs, need_convert)
    end
    if self.Password ~= nil then
        validate.lens(prefix .. 'Password', self.Password, nil, 32, errs, need_convert)
    end

    TNewReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNewReq.proto_property, errs, need_convert)
    return self
end

function TNewReq:unpack(raw)
    local RoleId = utils.unpack_enum(raw, self.RoleId)
    local LoginInterface = utils.unpack_enum(raw, utils.from_obj(ManagerAccounts.LoginInterfaceType,
        self.LoginInterface, true), true)
    local FirstLoginPolicy = utils.unpack_enum(raw, self.FirstLoginPolicy)
    return self.AccountId, self.UserName, self.Password, RoleId, LoginInterface, FirstLoginPolicy
end

ManagerAccounts.NewReq = TNewReq

ManagerAccounts.interface = mdb.register_interface('bmc.kepler.AccountService.ManagerAccounts', {}, {
    New = {'a{ss}ysayiaii', 'y', TNewReq, TNewRsp},
    NewOEMAccount = {'a{ss}yssa{ss}', 'y', TNewOEMAccountReq, TNewOEMAccountRsp},
    GetIdByUserName = {'a{ss}s', 'y', TGetIdByUserNameReq, TGetIdByUserNameRsp},
    SetAccountWritable = {'a{ss}ya{sb}', '', TSetAccountWritableReq, TSetAccountWritableRsp},
    GetAccountWritable = {'a{ss}y', 'a{sb}', TGetAccountWritableReq, TGetAccountWritableRsp},
    SetAccountLockState = {'a{ss}yb', '', TSetAccountLockStateReq, TSetAccountLockStateRsp},
    GetUidGidByUserName = {'a{ss}s', 'uu', TGetUidGidByUserNameReq, TGetUidGidByUserNameRsp}
}, {PasswordChangedSignal = 'a{ss}y', SnmpPasswordChangedSignal = 'a{ss}y'})

return ManagerAccounts
