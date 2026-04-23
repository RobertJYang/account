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

local def_types = require 'class.types.types'

local MIpmiUserInfo = {}

---@class MIpmiUserInfo.IsSynced
---@field IsSynced boolean
local TIsSynced = {}
TIsSynced.__index = TIsSynced
TIsSynced.group = {}

local function TIsSynced_from_obj(obj)
    return setmetatable(obj, TIsSynced)
end

function TIsSynced.new(IsSynced)
    return TIsSynced_from_obj({IsSynced = IsSynced or false})
end
---@param obj MIpmiUserInfo.IsSynced
function TIsSynced:init_from_obj(obj)
    self.IsSynced = obj.IsSynced or false
end

function TIsSynced:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIsSynced.group)
end

TIsSynced.from_obj = TIsSynced_from_obj

TIsSynced.proto_property = {'IsSynced'}

TIsSynced.default = {false}

TIsSynced.struct = {{name = 'IsSynced', is_array = false, struct = nil}}

function TIsSynced:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IsSynced', self.IsSynced, 'bool', false, errs, need_convert)

    TIsSynced:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIsSynced.proto_property, errs, need_convert)
    return self
end

function TIsSynced:unpack(_)
    return self.IsSynced
end

MIpmiUserInfo.IsSynced = TIsSynced

---@class MIpmiUserInfo.Privilege1
---@field Privilege1 def_types.IpmiPrivilege
local TPrivilege1 = {}
TPrivilege1.__index = TPrivilege1
TPrivilege1.group = {}

local function TPrivilege1_from_obj(obj)
    obj.Privilege1 = obj.Privilege1 and def_types.IpmiPrivilege.new(obj.Privilege1)
    return setmetatable(obj, TPrivilege1)
end

function TPrivilege1.new(Privilege1)
    return TPrivilege1_from_obj({Privilege1 = Privilege1 or [=[RESERVED]=]})
end
---@param obj MIpmiUserInfo.Privilege1
function TPrivilege1:init_from_obj(obj)
    self.Privilege1 = obj.Privilege1 or def_types.IpmiPrivilege.RESERVED
end

function TPrivilege1:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPrivilege1.group)
end

TPrivilege1.from_obj = TPrivilege1_from_obj

TPrivilege1.proto_property = {'Privilege1'}

TPrivilege1.default = {def_types.IpmiPrivilege.default}

TPrivilege1.struct = {{name = 'Privilege1', is_array = false, struct = def_types.IpmiPrivilege.struct}}

function TPrivilege1:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Privilege1', self.Privilege1, 'def_types.IpmiPrivilege', false, errs, need_convert)

    TPrivilege1:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPrivilege1.proto_property, errs, need_convert)
    return self
end

function TPrivilege1:unpack(raw)
    local Privilege1 = utils.unpack_enum(raw, self.Privilege1)
    return Privilege1
end

MIpmiUserInfo.Privilege1 = TPrivilege1

---@class MIpmiUserInfo.Privilege0
---@field Privilege0 def_types.IpmiPrivilege
local TPrivilege0 = {}
TPrivilege0.__index = TPrivilege0
TPrivilege0.group = {}

local function TPrivilege0_from_obj(obj)
    obj.Privilege0 = obj.Privilege0 and def_types.IpmiPrivilege.new(obj.Privilege0)
    return setmetatable(obj, TPrivilege0)
end

function TPrivilege0.new(Privilege0)
    return TPrivilege0_from_obj({Privilege0 = Privilege0 or [=[RESERVED]=]})
end
---@param obj MIpmiUserInfo.Privilege0
function TPrivilege0:init_from_obj(obj)
    self.Privilege0 = obj.Privilege0 or def_types.IpmiPrivilege.RESERVED
end

function TPrivilege0:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPrivilege0.group)
end

TPrivilege0.from_obj = TPrivilege0_from_obj

TPrivilege0.proto_property = {'Privilege0'}

TPrivilege0.default = {def_types.IpmiPrivilege.default}

TPrivilege0.struct = {{name = 'Privilege0', is_array = false, struct = def_types.IpmiPrivilege.struct}}

function TPrivilege0:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Privilege0', self.Privilege0, 'def_types.IpmiPrivilege', false, errs, need_convert)

    TPrivilege0:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPrivilege0.proto_property, errs, need_convert)
    return self
end

function TPrivilege0:unpack(raw)
    local Privilege0 = utils.unpack_enum(raw, self.Privilege0)
    return Privilege0
end

MIpmiUserInfo.Privilege0 = TPrivilege0

---@class MIpmiUserInfo.IsEnableByPasswd
---@field IsEnableByPasswd def_types.IpmiUserEnableByPassword
local TIsEnableByPasswd = {}
TIsEnableByPasswd.__index = TIsEnableByPasswd
TIsEnableByPasswd.group = {}

local function TIsEnableByPasswd_from_obj(obj)
    obj.IsEnableByPasswd = obj.IsEnableByPasswd and def_types.IpmiUserEnableByPassword.new(obj.IsEnableByPasswd)
    return setmetatable(obj, TIsEnableByPasswd)
end

function TIsEnableByPasswd.new(IsEnableByPasswd)
    return TIsEnableByPasswd_from_obj({IsEnableByPasswd = IsEnableByPasswd or [=[Disable]=]})
end
---@param obj MIpmiUserInfo.IsEnableByPasswd
function TIsEnableByPasswd:init_from_obj(obj)
    self.IsEnableByPasswd = obj.IsEnableByPasswd or def_types.IpmiUserEnableByPassword.Disable
end

function TIsEnableByPasswd:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIsEnableByPasswd.group)
end

TIsEnableByPasswd.from_obj = TIsEnableByPasswd_from_obj

TIsEnableByPasswd.proto_property = {'IsEnableByPasswd'}

TIsEnableByPasswd.default = {def_types.IpmiUserEnableByPassword.default}

TIsEnableByPasswd.struct = {
    {name = 'IsEnableByPasswd', is_array = false, struct = def_types.IpmiUserEnableByPassword.struct}
}

function TIsEnableByPasswd:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IsEnableByPasswd', self.IsEnableByPasswd, 'def_types.IpmiUserEnableByPassword', false,
        errs, need_convert)

    TIsEnableByPasswd:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIsEnableByPasswd.proto_property, errs, need_convert)
    return self
end

function TIsEnableByPasswd:unpack(raw)
    local IsEnableByPasswd = utils.unpack_enum(raw, self.IsEnableByPasswd)
    return IsEnableByPasswd
end

MIpmiUserInfo.IsEnableByPasswd = TIsEnableByPasswd

---@class MIpmiUserInfo.IsEnableIpmiMsg
---@field IsEnableIpmiMsg integer
local TIsEnableIpmiMsg = {}
TIsEnableIpmiMsg.__index = TIsEnableIpmiMsg
TIsEnableIpmiMsg.group = {}

local function TIsEnableIpmiMsg_from_obj(obj)
    return setmetatable(obj, TIsEnableIpmiMsg)
end

function TIsEnableIpmiMsg.new(IsEnableIpmiMsg)
    return TIsEnableIpmiMsg_from_obj({IsEnableIpmiMsg = IsEnableIpmiMsg or 1})
end
---@param obj MIpmiUserInfo.IsEnableIpmiMsg
function TIsEnableIpmiMsg:init_from_obj(obj)
    self.IsEnableIpmiMsg = obj.IsEnableIpmiMsg or 1
end

function TIsEnableIpmiMsg:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIsEnableIpmiMsg.group)
end

TIsEnableIpmiMsg.from_obj = TIsEnableIpmiMsg_from_obj

TIsEnableIpmiMsg.proto_property = {'IsEnableIpmiMsg'}

TIsEnableIpmiMsg.default = {0}

TIsEnableIpmiMsg.struct = {{name = 'IsEnableIpmiMsg', is_array = false, struct = nil}}

function TIsEnableIpmiMsg:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IsEnableIpmiMsg', self.IsEnableIpmiMsg, 'uint8', false, errs, need_convert)

    TIsEnableIpmiMsg:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIsEnableIpmiMsg.proto_property, errs, need_convert)
    return self
end

function TIsEnableIpmiMsg:unpack(_)
    return self.IsEnableIpmiMsg
end

MIpmiUserInfo.IsEnableIpmiMsg = TIsEnableIpmiMsg

---@class MIpmiUserInfo.IsEnableAuth
---@field IsEnableAuth integer
local TIsEnableAuth = {}
TIsEnableAuth.__index = TIsEnableAuth
TIsEnableAuth.group = {}

local function TIsEnableAuth_from_obj(obj)
    return setmetatable(obj, TIsEnableAuth)
end

function TIsEnableAuth.new(IsEnableAuth)
    return TIsEnableAuth_from_obj({IsEnableAuth = IsEnableAuth or 1})
end
---@param obj MIpmiUserInfo.IsEnableAuth
function TIsEnableAuth:init_from_obj(obj)
    self.IsEnableAuth = obj.IsEnableAuth or 1
end

function TIsEnableAuth:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIsEnableAuth.group)
end

TIsEnableAuth.from_obj = TIsEnableAuth_from_obj

TIsEnableAuth.proto_property = {'IsEnableAuth'}

TIsEnableAuth.default = {0}

TIsEnableAuth.struct = {{name = 'IsEnableAuth', is_array = false, struct = nil}}

function TIsEnableAuth:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IsEnableAuth', self.IsEnableAuth, 'uint8', false, errs, need_convert)

    TIsEnableAuth:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIsEnableAuth.proto_property, errs, need_convert)
    return self
end

function TIsEnableAuth:unpack(_)
    return self.IsEnableAuth
end

MIpmiUserInfo.IsEnableAuth = TIsEnableAuth

---@class MIpmiUserInfo.IsCallin
---@field IsCallin integer
local TIsCallin = {}
TIsCallin.__index = TIsCallin
TIsCallin.group = {}

local function TIsCallin_from_obj(obj)
    return setmetatable(obj, TIsCallin)
end

function TIsCallin.new(IsCallin)
    return TIsCallin_from_obj({IsCallin = IsCallin or 0})
end
---@param obj MIpmiUserInfo.IsCallin
function TIsCallin:init_from_obj(obj)
    self.IsCallin = obj.IsCallin or 0
end

function TIsCallin:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIsCallin.group)
end

TIsCallin.from_obj = TIsCallin_from_obj

TIsCallin.proto_property = {'IsCallin'}

TIsCallin.default = {0}

TIsCallin.struct = {{name = 'IsCallin', is_array = false, struct = nil}}

function TIsCallin:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IsCallin', self.IsCallin, 'uint8', false, errs, need_convert)

    TIsCallin:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIsCallin.proto_property, errs, need_convert)
    return self
end

function TIsCallin:unpack(_)
    return self.IsCallin
end

MIpmiUserInfo.IsCallin = TIsCallin

---@class MIpmiUserInfo.Use20BytesPasswd
---@field Use20BytesPasswd integer
local TUse20BytesPasswd = {}
TUse20BytesPasswd.__index = TUse20BytesPasswd
TUse20BytesPasswd.group = {}

local function TUse20BytesPasswd_from_obj(obj)
    return setmetatable(obj, TUse20BytesPasswd)
end

function TUse20BytesPasswd.new(Use20BytesPasswd)
    return TUse20BytesPasswd_from_obj({Use20BytesPasswd = Use20BytesPasswd or 1})
end
---@param obj MIpmiUserInfo.Use20BytesPasswd
function TUse20BytesPasswd:init_from_obj(obj)
    self.Use20BytesPasswd = obj.Use20BytesPasswd or 1
end

function TUse20BytesPasswd:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUse20BytesPasswd.group)
end

TUse20BytesPasswd.from_obj = TUse20BytesPasswd_from_obj

TUse20BytesPasswd.proto_property = {'Use20BytesPasswd'}

TUse20BytesPasswd.default = {0}

TUse20BytesPasswd.struct = {{name = 'Use20BytesPasswd', is_array = false, struct = nil}}

function TUse20BytesPasswd:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Use20BytesPasswd', self.Use20BytesPasswd, 'uint8', false, errs, need_convert)

    TUse20BytesPasswd:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUse20BytesPasswd.proto_property, errs, need_convert)
    return self
end

function TUse20BytesPasswd:unpack(_)
    return self.Use20BytesPasswd
end

MIpmiUserInfo.Use20BytesPasswd = TUse20BytesPasswd

---@class MIpmiUserInfo.AccountId
---@field AccountId integer
local TAccountId = {}
TAccountId.__index = TAccountId
TAccountId.group = {}

local function TAccountId_from_obj(obj)
    return setmetatable(obj, TAccountId)
end

function TAccountId.new(AccountId)
    return TAccountId_from_obj({AccountId = AccountId})
end
---@param obj MIpmiUserInfo.AccountId
function TAccountId:init_from_obj(obj)
    self.AccountId = obj.AccountId
end

function TAccountId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountId.group)
end

TAccountId.from_obj = TAccountId_from_obj

TAccountId.proto_property = {'AccountId'}

TAccountId.default = {0}

TAccountId.struct = {{name = 'AccountId', is_array = false, struct = nil}}

function TAccountId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)

    TAccountId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountId.proto_property, errs, need_convert)
    return self
end

function TAccountId:unpack(_)
    return self.AccountId
end

MIpmiUserInfo.AccountId = TAccountId

return MIpmiUserInfo
