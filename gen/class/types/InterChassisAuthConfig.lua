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

local MInterChassisAuthConfig = {}

---@class MInterChassisAuthConfig.Visible
---@field Visible boolean
local TVisible = {}
TVisible.__index = TVisible
TVisible.group = {}

local function TVisible_from_obj(obj)
    return setmetatable(obj, TVisible)
end

function TVisible.new(Visible)
    return TVisible_from_obj({Visible = Visible})
end
---@param obj MInterChassisAuthConfig.Visible
function TVisible:init_from_obj(obj)
    self.Visible = obj.Visible
end

function TVisible:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TVisible.group)
end

TVisible.from_obj = TVisible_from_obj

TVisible.proto_property = {'Visible'}

TVisible.default = {false}

TVisible.struct = {{name = 'Visible', is_array = false, struct = nil}}

function TVisible:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Visible', self.Visible, 'bool', false, errs, need_convert)

    TVisible:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TVisible.proto_property, errs, need_convert)
    return self
end

function TVisible:unpack(_)
    return self.Visible
end

MInterChassisAuthConfig.Visible = TVisible

---@class MInterChassisAuthConfig.LoginInterface
---@field LoginInterface integer
local TLoginInterface = {}
TLoginInterface.__index = TLoginInterface
TLoginInterface.group = {}

local function TLoginInterface_from_obj(obj)
    return setmetatable(obj, TLoginInterface)
end

function TLoginInterface.new(LoginInterface)
    return TLoginInterface_from_obj({LoginInterface = LoginInterface})
end
---@param obj MInterChassisAuthConfig.LoginInterface
function TLoginInterface:init_from_obj(obj)
    self.LoginInterface = obj.LoginInterface
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

MInterChassisAuthConfig.LoginInterface = TLoginInterface

---@class MInterChassisAuthConfig.AccessRoleId
---@field AccessRoleId integer
local TAccessRoleId = {}
TAccessRoleId.__index = TAccessRoleId
TAccessRoleId.group = {}

local function TAccessRoleId_from_obj(obj)
    return setmetatable(obj, TAccessRoleId)
end

function TAccessRoleId.new(AccessRoleId)
    return TAccessRoleId_from_obj({AccessRoleId = AccessRoleId})
end
---@param obj MInterChassisAuthConfig.AccessRoleId
function TAccessRoleId:init_from_obj(obj)
    self.AccessRoleId = obj.AccessRoleId
end

function TAccessRoleId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccessRoleId.group)
end

TAccessRoleId.from_obj = TAccessRoleId_from_obj

TAccessRoleId.proto_property = {'AccessRoleId'}

TAccessRoleId.default = {0}

TAccessRoleId.struct = {{name = 'AccessRoleId', is_array = false, struct = nil}}

function TAccessRoleId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AccessRoleId', self.AccessRoleId, 'uint8', false, errs, need_convert)

    TAccessRoleId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccessRoleId.proto_property, errs, need_convert)
    return self
end

function TAccessRoleId:unpack(_)
    return self.AccessRoleId
end

MInterChassisAuthConfig.AccessRoleId = TAccessRoleId

return MInterChassisAuthConfig
