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

local Roles = {}

---@class Roles.ExtendedCustomRoleEnabled
---@field ExtendedCustomRoleEnabled boolean
local TExtendedCustomRoleEnabled = {}
TExtendedCustomRoleEnabled.__index = TExtendedCustomRoleEnabled
TExtendedCustomRoleEnabled.group = {}

local function TExtendedCustomRoleEnabled_from_obj(obj)
    return setmetatable(obj, TExtendedCustomRoleEnabled)
end

function TExtendedCustomRoleEnabled.new(ExtendedCustomRoleEnabled)
    return TExtendedCustomRoleEnabled_from_obj({ExtendedCustomRoleEnabled = ExtendedCustomRoleEnabled})
end
---@param obj Roles.ExtendedCustomRoleEnabled
function TExtendedCustomRoleEnabled:init_from_obj(obj)
    self.ExtendedCustomRoleEnabled = obj.ExtendedCustomRoleEnabled
end

function TExtendedCustomRoleEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExtendedCustomRoleEnabled.group)
end

TExtendedCustomRoleEnabled.from_obj = TExtendedCustomRoleEnabled_from_obj

TExtendedCustomRoleEnabled.proto_property = {'ExtendedCustomRoleEnabled'}

TExtendedCustomRoleEnabled.default = {false}

TExtendedCustomRoleEnabled.struct = {{name = 'ExtendedCustomRoleEnabled', is_array = false, struct = nil}}

function TExtendedCustomRoleEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ExtendedCustomRoleEnabled', self.ExtendedCustomRoleEnabled, 'bool', false, errs,
        need_convert)

    TExtendedCustomRoleEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TExtendedCustomRoleEnabled.proto_property, errs, need_convert)
    return self
end

function TExtendedCustomRoleEnabled:unpack(_)
    return self.ExtendedCustomRoleEnabled
end

Roles.ExtendedCustomRoleEnabled = TExtendedCustomRoleEnabled

---@class Roles.NewRsp
local TNewRsp = {}
TNewRsp.__index = TNewRsp
TNewRsp.group = {}

local function TNewRsp_from_obj(obj)
    return setmetatable(obj, TNewRsp)
end

function TNewRsp.new()
    return TNewRsp_from_obj({})
end
---@param obj Roles.NewRsp
function TNewRsp:init_from_obj(obj)

end

function TNewRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TNewRsp.group)
end

TNewRsp.from_obj = TNewRsp_from_obj

TNewRsp.proto_property = {}

TNewRsp.default = {}

TNewRsp.struct = {}

function TNewRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TNewRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNewRsp.proto_property, errs, need_convert)
    return self
end

function TNewRsp:unpack(_)
end

Roles.NewRsp = TNewRsp

---@class Roles.NewReq
---@field RoleId integer
---@field AssignedPrivileges string[]
---@field OemPrivileges string[]
local TNewReq = {}
TNewReq.__index = TNewReq
TNewReq.group = {}

local function TNewReq_from_obj(obj)
    return setmetatable(obj, TNewReq)
end

function TNewReq.new(RoleId, AssignedPrivileges, OemPrivileges)
    return TNewReq_from_obj({RoleId = RoleId, AssignedPrivileges = AssignedPrivileges, OemPrivileges = OemPrivileges})
end
---@param obj Roles.NewReq
function TNewReq:init_from_obj(obj)
    self.RoleId = obj.RoleId
    self.AssignedPrivileges = obj.AssignedPrivileges
    self.OemPrivileges = obj.OemPrivileges
end

function TNewReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TNewReq.group)
end

TNewReq.from_obj = TNewReq_from_obj

TNewReq.proto_property = {'RoleId', 'AssignedPrivileges', 'OemPrivileges'}

TNewReq.default = {0, {}, {}}

TNewReq.struct = {
    {name = 'RoleId', is_array = false, struct = nil}, {name = 'AssignedPrivileges', is_array = true, struct = nil},
    {name = 'OemPrivileges', is_array = true, struct = nil}
}

function TNewReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RoleId', self.RoleId, 'uint8', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'AssignedPrivileges', self.AssignedPrivileges, 'string', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'OemPrivileges', self.OemPrivileges, 'string', false, errs, need_convert)

    TNewReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TNewReq.proto_property, errs, need_convert)
    return self
end

function TNewReq:unpack(_)
    return self.RoleId, self.AssignedPrivileges, self.OemPrivileges
end

Roles.NewReq = TNewReq

Roles.interface = mdb.register_interface('bmc.kepler.AccountService.Roles',
    {ExtendedCustomRoleEnabled = {'b', {}, false, nil}}, {New = {'a{ss}yasas', '', TNewReq, TNewRsp}}, {})

return Roles
