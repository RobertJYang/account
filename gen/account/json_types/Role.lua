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

local Role = {}

---@class Role.Name
---@field Name string
local TName = {}
TName.__index = TName
TName.group = {}

local function TName_from_obj(obj)
    return setmetatable(obj, TName)
end

function TName.new(Name)
    return TName_from_obj({Name = Name})
end
---@param obj Role.Name
function TName:init_from_obj(obj)
    self.Name = obj.Name
end

function TName:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TName.group)
end

TName.from_obj = TName_from_obj

TName.proto_property = {'Name'}

TName.default = {''}

TName.struct = {{name = 'Name', is_array = false, struct = nil}}

function TName:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Name', self.Name, 'string', true, errs, need_convert)

    TName:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TName.proto_property, errs, need_convert)
    return self
end

function TName:unpack(_)
    return self.Name
end

Role.Name = TName

---@class Role.RolePrivilege
---@field RolePrivilege string[]
local TRolePrivilege = {}
TRolePrivilege.__index = TRolePrivilege
TRolePrivilege.group = {}

local function TRolePrivilege_from_obj(obj)
    return setmetatable(obj, TRolePrivilege)
end

function TRolePrivilege.new(RolePrivilege)
    return TRolePrivilege_from_obj({RolePrivilege = RolePrivilege or {}})
end
---@param obj Role.RolePrivilege
function TRolePrivilege:init_from_obj(obj)
    self.RolePrivilege = obj.RolePrivilege or {}
end

function TRolePrivilege:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRolePrivilege.group)
end

TRolePrivilege.from_obj = TRolePrivilege_from_obj

TRolePrivilege.proto_property = {'RolePrivilege'}

TRolePrivilege.default = {{}}

TRolePrivilege.struct = {{name = 'RolePrivilege', is_array = true, struct = nil}}

function TRolePrivilege:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.OptionalArray(prefix .. 'RolePrivilege', self.RolePrivilege, 'string', true, errs, need_convert)

    TRolePrivilege:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRolePrivilege.proto_property, errs, need_convert)
    return self
end

function TRolePrivilege:unpack(_)
    return self.RolePrivilege
end

Role.RolePrivilege = TRolePrivilege

---@class Role.DeleteRsp
local TDeleteRsp = {}
TDeleteRsp.__index = TDeleteRsp
TDeleteRsp.group = {}

local function TDeleteRsp_from_obj(obj)
    return setmetatable(obj, TDeleteRsp)
end

function TDeleteRsp.new()
    return TDeleteRsp_from_obj({})
end
---@param obj Role.DeleteRsp
function TDeleteRsp:init_from_obj(obj)

end

function TDeleteRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteRsp.group)
end

TDeleteRsp.from_obj = TDeleteRsp_from_obj

TDeleteRsp.proto_property = {}

TDeleteRsp.default = {}

TDeleteRsp.struct = {}

function TDeleteRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TDeleteRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteRsp.proto_property, errs, need_convert)
    return self
end

function TDeleteRsp:unpack(_)
end

Role.DeleteRsp = TDeleteRsp

---@class Role.DeleteReq
local TDeleteReq = {}
TDeleteReq.__index = TDeleteReq
TDeleteReq.group = {}

local function TDeleteReq_from_obj(obj)
    return setmetatable(obj, TDeleteReq)
end

function TDeleteReq.new()
    return TDeleteReq_from_obj({})
end
---@param obj Role.DeleteReq
function TDeleteReq:init_from_obj(obj)

end

function TDeleteReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteReq.group)
end

TDeleteReq.from_obj = TDeleteReq_from_obj

TDeleteReq.proto_property = {}

TDeleteReq.default = {}

TDeleteReq.struct = {}

function TDeleteReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TDeleteReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteReq.proto_property, errs, need_convert)
    return self
end

function TDeleteReq:unpack(_)
end

Role.DeleteReq = TDeleteReq

---@class Role.SetRolePrivilegeRsp
local TSetRolePrivilegeRsp = {}
TSetRolePrivilegeRsp.__index = TSetRolePrivilegeRsp
TSetRolePrivilegeRsp.group = {}

local function TSetRolePrivilegeRsp_from_obj(obj)
    return setmetatable(obj, TSetRolePrivilegeRsp)
end

function TSetRolePrivilegeRsp.new()
    return TSetRolePrivilegeRsp_from_obj({})
end
---@param obj Role.SetRolePrivilegeRsp
function TSetRolePrivilegeRsp:init_from_obj(obj)

end

function TSetRolePrivilegeRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetRolePrivilegeRsp.group)
end

TSetRolePrivilegeRsp.from_obj = TSetRolePrivilegeRsp_from_obj

TSetRolePrivilegeRsp.proto_property = {}

TSetRolePrivilegeRsp.default = {}

TSetRolePrivilegeRsp.struct = {}

function TSetRolePrivilegeRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetRolePrivilegeRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetRolePrivilegeRsp.proto_property, errs, need_convert)
    return self
end

function TSetRolePrivilegeRsp:unpack(_)
end

Role.SetRolePrivilegeRsp = TSetRolePrivilegeRsp

---@class Role.SetRolePrivilegeReq
---@field PrivilegeType integer
---@field PrivilegeValue boolean
local TSetRolePrivilegeReq = {}
TSetRolePrivilegeReq.__index = TSetRolePrivilegeReq
TSetRolePrivilegeReq.group = {}

local function TSetRolePrivilegeReq_from_obj(obj)
    return setmetatable(obj, TSetRolePrivilegeReq)
end

function TSetRolePrivilegeReq.new(PrivilegeType, PrivilegeValue)
    return TSetRolePrivilegeReq_from_obj({PrivilegeType = PrivilegeType, PrivilegeValue = PrivilegeValue})
end
---@param obj Role.SetRolePrivilegeReq
function TSetRolePrivilegeReq:init_from_obj(obj)
    self.PrivilegeType = obj.PrivilegeType
    self.PrivilegeValue = obj.PrivilegeValue
end

function TSetRolePrivilegeReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetRolePrivilegeReq.group)
end

TSetRolePrivilegeReq.from_obj = TSetRolePrivilegeReq_from_obj

TSetRolePrivilegeReq.proto_property = {'PrivilegeType', 'PrivilegeValue'}

TSetRolePrivilegeReq.default = {0, false}

TSetRolePrivilegeReq.struct = {
    {name = 'PrivilegeType', is_array = false, struct = nil}, {name = 'PrivilegeValue', is_array = false, struct = nil}
}

function TSetRolePrivilegeReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PrivilegeType', self.PrivilegeType, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'PrivilegeValue', self.PrivilegeValue, 'bool', false, errs, need_convert)

    TSetRolePrivilegeReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetRolePrivilegeReq.proto_property, errs, need_convert)
    return self
end

function TSetRolePrivilegeReq:unpack(_)
    return self.PrivilegeType, self.PrivilegeValue
end

Role.SetRolePrivilegeReq = TSetRolePrivilegeReq

Role.interface = mdb.register_interface('bmc.kepler.AccountService.Role', {
    RolePrivilege = {'as', {'CONST'}, true, {}, false},
    Name = {'s', {'CONST'}, true, nil, false}
}, {
    SetRolePrivilege = {'a{ss}yb', '', TSetRolePrivilegeReq, TSetRolePrivilegeRsp},
    Delete = {'a{ss}', '', TDeleteReq, TDeleteRsp}
}, {})

return Role
