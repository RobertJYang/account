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

local MAccountBackup = {}

---@class MAccountBackup.Enabled
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
---@param obj MAccountBackup.Enabled
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

MAccountBackup.Enabled = TEnabled

---@class MAccountBackup.LoginInterface
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
---@param obj MAccountBackup.LoginInterface
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

MAccountBackup.LoginInterface = TLoginInterface

---@class MAccountBackup.RoleId
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
---@param obj MAccountBackup.RoleId
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

MAccountBackup.RoleId = TRoleId

---@class MAccountBackup.Password
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
---@param obj MAccountBackup.Password
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

MAccountBackup.Password = TPassword

---@class MAccountBackup.UserName
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
---@param obj MAccountBackup.UserName
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

MAccountBackup.UserName = TUserName

---@class MAccountBackup.Id
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
---@param obj MAccountBackup.Id
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

MAccountBackup.Id = TId

return MAccountBackup
