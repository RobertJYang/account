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

local AccountPolicy = {}

---@class AccountPolicy.Deletable
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
---@param obj AccountPolicy.Deletable
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

AccountPolicy.Deletable = TDeletable

---@class AccountPolicy.Visible
---@field Visible boolean
local TVisible = {}
TVisible.__index = TVisible
TVisible.group = {}

local function TVisible_from_obj(obj)
    return setmetatable(obj, TVisible)
end

function TVisible.new(Visible)
    return TVisible_from_obj({Visible = Visible or false})
end
---@param obj AccountPolicy.Visible
function TVisible:init_from_obj(obj)
    self.Visible = obj.Visible or false
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

AccountPolicy.Visible = TVisible

---@class AccountPolicy.AllowedLoginInterfaces
---@field AllowedLoginInterfaces string[]
local TAllowedLoginInterfaces = {}
TAllowedLoginInterfaces.__index = TAllowedLoginInterfaces
TAllowedLoginInterfaces.group = {}

local function TAllowedLoginInterfaces_from_obj(obj)
    return setmetatable(obj, TAllowedLoginInterfaces)
end

function TAllowedLoginInterfaces.new(AllowedLoginInterfaces)
    return TAllowedLoginInterfaces_from_obj({
        AllowedLoginInterfaces = AllowedLoginInterfaces or
            {[=[Web]=], [=[SNMP]=], [=[IPMI]=], [=[SSH]=], [=[SFTP]=], [=[Local]=], [=[Redfish]=]}
    })
end
---@param obj AccountPolicy.AllowedLoginInterfaces
function TAllowedLoginInterfaces:init_from_obj(obj)
    self.AllowedLoginInterfaces = obj.AllowedLoginInterfaces or
                                      {
            [=[Web]=], [=[SNMP]=], [=[IPMI]=], [=[SSH]=], [=[SFTP]=], [=[Local]=], [=[Redfish]=]
        }
end

function TAllowedLoginInterfaces:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAllowedLoginInterfaces.group)
end

TAllowedLoginInterfaces.from_obj = TAllowedLoginInterfaces_from_obj

TAllowedLoginInterfaces.proto_property = {'AllowedLoginInterfaces'}

TAllowedLoginInterfaces.default = {{}}

TAllowedLoginInterfaces.struct = {{name = 'AllowedLoginInterfaces', is_array = true, struct = nil}}

function TAllowedLoginInterfaces:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.OptionalArray(prefix .. 'AllowedLoginInterfaces', self.AllowedLoginInterfaces, 'string', false, errs,
        need_convert)

    TAllowedLoginInterfaces:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAllowedLoginInterfaces.proto_property, errs, need_convert)
    return self
end

function TAllowedLoginInterfaces:unpack(_)
    return self.AllowedLoginInterfaces
end

AccountPolicy.AllowedLoginInterfaces = TAllowedLoginInterfaces

---@class AccountPolicy.NamePattern
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
---@param obj AccountPolicy.NamePattern
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

    if self.NamePattern ~= nil then
        validate.lens(prefix .. 'NamePattern', self.NamePattern, 0, 255, errs, need_convert)
    end

    TNamePattern:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNamePattern.proto_property, errs, need_convert)
    return self
end

function TNamePattern:unpack(_)
    return self.NamePattern
end

AccountPolicy.NamePattern = TNamePattern

AccountPolicy.interface = mdb.register_interface('bmc.kepler.AccountService.AccountPolicy', {
    NamePattern = {'s', {}, false, '', false},
    AllowedLoginInterfaces = {'as', {}, false, {'Web', 'SNMP', 'IPMI', 'SSH', 'SFTP', 'Local', 'Redfish'}, false},
    Visible = {'b', {}, false, false, false},
    Deletable = {'b', {}, false, false, false}
}, {}, {})

return AccountPolicy
