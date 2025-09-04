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

local Properties = {}

---@class Properties.ObjectName
---@field ObjectName string
local TObjectName = {}
TObjectName.__index = TObjectName
TObjectName.group = {}

local function TObjectName_from_obj(obj)
    return setmetatable(obj, TObjectName)
end

function TObjectName.new(ObjectName)
    return TObjectName_from_obj({ObjectName = ObjectName})
end
---@param obj Properties.ObjectName
function TObjectName:init_from_obj(obj)
    self.ObjectName = obj.ObjectName
end

function TObjectName:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TObjectName.group)
end

TObjectName.from_obj = TObjectName_from_obj

TObjectName.proto_property = {'ObjectName'}

TObjectName.default = {''}

TObjectName.struct = {{name = 'ObjectName', is_array = false, struct = nil}}

function TObjectName:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ObjectName', self.ObjectName, 'string', true, errs, need_convert)

    TObjectName:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TObjectName.proto_property, errs, need_convert)
    return self
end

function TObjectName:unpack(_)
    return self.ObjectName
end

Properties.ObjectName = TObjectName

---@class Properties.ClassName
---@field ClassName string
local TClassName = {}
TClassName.__index = TClassName
TClassName.group = {}

local function TClassName_from_obj(obj)
    return setmetatable(obj, TClassName)
end

function TClassName.new(ClassName)
    return TClassName_from_obj({ClassName = ClassName})
end
---@param obj Properties.ClassName
function TClassName:init_from_obj(obj)
    self.ClassName = obj.ClassName
end

function TClassName:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TClassName.group)
end

TClassName.from_obj = TClassName_from_obj

TClassName.proto_property = {'ClassName'}

TClassName.default = {''}

TClassName.struct = {{name = 'ClassName', is_array = false, struct = nil}}

function TClassName:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ClassName', self.ClassName, 'string', true, errs, need_convert)

    TClassName:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TClassName.proto_property, errs, need_convert)
    return self
end

function TClassName:unpack(_)
    return self.ClassName
end

Properties.ClassName = TClassName

---@class Properties.StructIdentifier
---@field SystemId integer
---@field ManagerId string
---@field ChassisId string
---@field Position string
local TStructIdentifier = {}
TStructIdentifier.__index = TStructIdentifier
TStructIdentifier.group = {}

local function TStructIdentifier_from_obj(obj)
    return setmetatable(obj, TStructIdentifier)
end

function TStructIdentifier.new(SystemId, ManagerId, ChassisId, Position)
    return TStructIdentifier_from_obj({
        SystemId = SystemId,
        ManagerId = ManagerId,
        ChassisId = ChassisId,
        Position = Position
    })
end
---@param obj Properties.StructIdentifier
function TStructIdentifier:init_from_obj(obj)
    self.SystemId = obj.SystemId
    self.ManagerId = obj.ManagerId
    self.ChassisId = obj.ChassisId
    self.Position = obj.Position
end

function TStructIdentifier:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TStructIdentifier.group)
end

TStructIdentifier.from_obj = TStructIdentifier_from_obj

TStructIdentifier.proto_property = {'SystemId', 'ManagerId', 'ChassisId', 'Position'}

TStructIdentifier.default = {0, '', '', ''}

TStructIdentifier.struct = {
    {name = 'SystemId', is_array = false, struct = nil}, {name = 'ManagerId', is_array = false, struct = nil},
    {name = 'ChassisId', is_array = false, struct = nil}, {name = 'Position', is_array = false, struct = nil}
}

function TStructIdentifier:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SystemId', self.SystemId, 'uint8', true, errs, need_convert)
    validate.Optional(prefix .. 'ManagerId', self.ManagerId, 'string', true, errs, need_convert)
    validate.Optional(prefix .. 'ChassisId', self.ChassisId, 'string', true, errs, need_convert)
    validate.Optional(prefix .. 'Position', self.Position, 'string', true, errs, need_convert)

    TStructIdentifier:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TStructIdentifier.proto_property, errs, need_convert)
    return self
end

function TStructIdentifier:unpack(_)
    return self.SystemId, self.ManagerId, self.ChassisId, self.Position
end

Properties.StructIdentifier = TStructIdentifier

---@class Properties.ObjectIdentifier
---@field ObjectIdentifier Properties.StructIdentifier
local TObjectIdentifier = {}
TObjectIdentifier.__index = TObjectIdentifier
TObjectIdentifier.group = {}

local function TObjectIdentifier_from_obj(obj)
    obj.ObjectIdentifier = utils.from_obj(Properties.StructIdentifier, obj.ObjectIdentifier)
    return setmetatable(obj, TObjectIdentifier)
end

function TObjectIdentifier.new(ObjectIdentifier)
    return TObjectIdentifier_from_obj({ObjectIdentifier = ObjectIdentifier})
end
---@param obj Properties.ObjectIdentifier
function TObjectIdentifier:init_from_obj(obj)
    self.ObjectIdentifier = obj.ObjectIdentifier
end

function TObjectIdentifier:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TObjectIdentifier.group)
end

TObjectIdentifier.from_obj = TObjectIdentifier_from_obj

TObjectIdentifier.proto_property = {'ObjectIdentifier'}

TObjectIdentifier.default = {Properties.StructIdentifier.default}

TObjectIdentifier.struct = {{name = 'ObjectIdentifier', is_array = false, struct = Properties.StructIdentifier.struct}}

function TObjectIdentifier:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    Properties.StructIdentifier.new(self.ObjectIdentifier.SystemId, self.ObjectIdentifier.ManagerId,
        self.ObjectIdentifier.ChassisId, self.ObjectIdentifier.Position):validate(prefix, errs, need_convert)

    TObjectIdentifier:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TObjectIdentifier.proto_property, errs, need_convert)
    return self
end

function TObjectIdentifier:unpack(raw)
    return utils.unpack(raw, self.ObjectIdentifier)
end

Properties.ObjectIdentifier = TObjectIdentifier

Properties.interface = mdb.register_interface('bmc.kepler.Object.Properties', {
    ClassName = {'s', nil, true, nil, false},
    ObjectName = {'s', nil, true, nil, false},
    ObjectIdentifier = {'(ysss)', nil, true, nil, false}
}, {}, {})

return Properties
