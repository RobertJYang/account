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

local MAccountPolicyDB = {}

---@class MAccountPolicyDB.OnlineDeletable
---@field OnlineDeletable boolean
local TOnlineDeletable = {}
TOnlineDeletable.__index = TOnlineDeletable
TOnlineDeletable.group = {}

local function TOnlineDeletable_from_obj(obj)
    return setmetatable(obj, TOnlineDeletable)
end

function TOnlineDeletable.new(OnlineDeletable)
    return TOnlineDeletable_from_obj({OnlineDeletable = OnlineDeletable == nil and true or OnlineDeletable})
end
---@param obj MAccountPolicyDB.OnlineDeletable
function TOnlineDeletable:init_from_obj(obj)
    self.OnlineDeletable = obj.OnlineDeletable == nil and true or obj.OnlineDeletable
end

function TOnlineDeletable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TOnlineDeletable.group)
end

TOnlineDeletable.from_obj = TOnlineDeletable_from_obj

TOnlineDeletable.proto_property = {'OnlineDeletable'}

TOnlineDeletable.default = {false}

TOnlineDeletable.struct = {{name = 'OnlineDeletable', is_array = false, struct = nil}}

function TOnlineDeletable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'OnlineDeletable', self.OnlineDeletable, 'bool', false, errs, need_convert)

    TOnlineDeletable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TOnlineDeletable.proto_property, errs, need_convert)
    return self
end

function TOnlineDeletable:unpack(_)
    return self.OnlineDeletable
end

MAccountPolicyDB.OnlineDeletable = TOnlineDeletable

---@class MAccountPolicyDB.Deletable
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
---@param obj MAccountPolicyDB.Deletable
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

MAccountPolicyDB.Deletable = TDeletable

---@class MAccountPolicyDB.Visible
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
---@param obj MAccountPolicyDB.Visible
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

MAccountPolicyDB.Visible = TVisible

---@class MAccountPolicyDB.AllowedLoginInterfaces
---@field AllowedLoginInterfaces integer
local TAllowedLoginInterfaces = {}
TAllowedLoginInterfaces.__index = TAllowedLoginInterfaces
TAllowedLoginInterfaces.group = {}

local function TAllowedLoginInterfaces_from_obj(obj)
    return setmetatable(obj, TAllowedLoginInterfaces)
end

function TAllowedLoginInterfaces.new(AllowedLoginInterfaces)
    return TAllowedLoginInterfaces_from_obj({AllowedLoginInterfaces = AllowedLoginInterfaces or 223})
end
---@param obj MAccountPolicyDB.AllowedLoginInterfaces
function TAllowedLoginInterfaces:init_from_obj(obj)
    self.AllowedLoginInterfaces = obj.AllowedLoginInterfaces or 223
end

function TAllowedLoginInterfaces:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAllowedLoginInterfaces.group)
end

TAllowedLoginInterfaces.from_obj = TAllowedLoginInterfaces_from_obj

TAllowedLoginInterfaces.proto_property = {'AllowedLoginInterfaces'}

TAllowedLoginInterfaces.default = {0}

TAllowedLoginInterfaces.struct = {{name = 'AllowedLoginInterfaces', is_array = false, struct = nil}}

function TAllowedLoginInterfaces:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AllowedLoginInterfaces', self.AllowedLoginInterfaces, 'uint32', false, errs,
        need_convert)

    TAllowedLoginInterfaces:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAllowedLoginInterfaces.proto_property, errs, need_convert)
    return self
end

function TAllowedLoginInterfaces:unpack(_)
    return self.AllowedLoginInterfaces
end

MAccountPolicyDB.AllowedLoginInterfaces = TAllowedLoginInterfaces

---@class MAccountPolicyDB.NamePattern
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
---@param obj MAccountPolicyDB.NamePattern
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

    TNamePattern:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNamePattern.proto_property, errs, need_convert)
    return self
end

function TNamePattern:unpack(_)
    return self.NamePattern
end

MAccountPolicyDB.NamePattern = TNamePattern

---@class MAccountPolicyDB.AccountType
---@field AccountType integer
local TAccountType = {}
TAccountType.__index = TAccountType
TAccountType.group = {}

local function TAccountType_from_obj(obj)
    return setmetatable(obj, TAccountType)
end

function TAccountType.new(AccountType)
    return TAccountType_from_obj({AccountType = AccountType})
end
---@param obj MAccountPolicyDB.AccountType
function TAccountType:init_from_obj(obj)
    self.AccountType = obj.AccountType
end

function TAccountType:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountType.group)
end

TAccountType.from_obj = TAccountType_from_obj

TAccountType.proto_property = {'AccountType'}

TAccountType.default = {0}

TAccountType.struct = {{name = 'AccountType', is_array = false, struct = nil}}

function TAccountType:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'AccountType', self.AccountType, 'uint8', false, errs, need_convert)

    TAccountType:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountType.proto_property, errs, need_convert)
    return self
end

function TAccountType:unpack(_)
    return self.AccountType
end

MAccountPolicyDB.AccountType = TAccountType

return MAccountPolicyDB
