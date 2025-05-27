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

local CA = {}

---@class CA.RedfishSchemaVersion
---@field RedfishSchemaVersion string
local TRedfishSchemaVersion = {}
TRedfishSchemaVersion.__index = TRedfishSchemaVersion
TRedfishSchemaVersion.group = {}

local function TRedfishSchemaVersion_from_obj(obj)
    return setmetatable(obj, TRedfishSchemaVersion)
end

function TRedfishSchemaVersion.new(RedfishSchemaVersion)
    return TRedfishSchemaVersion_from_obj({RedfishSchemaVersion = RedfishSchemaVersion or [=[1.3.0]=]})
end
---@param obj CA.RedfishSchemaVersion
function TRedfishSchemaVersion:init_from_obj(obj)
    self.RedfishSchemaVersion = obj.RedfishSchemaVersion or [=[1.3.0]=]
end

function TRedfishSchemaVersion:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRedfishSchemaVersion.group)
end

TRedfishSchemaVersion.from_obj = TRedfishSchemaVersion_from_obj

TRedfishSchemaVersion.proto_property = {'RedfishSchemaVersion'}

TRedfishSchemaVersion.default = {''}

TRedfishSchemaVersion.struct = {{name = 'RedfishSchemaVersion', is_array = false, struct = nil}}

function TRedfishSchemaVersion:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RedfishSchemaVersion', self.RedfishSchemaVersion, 'string', false, errs, need_convert)

    TRedfishSchemaVersion:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRedfishSchemaVersion.proto_property, errs, need_convert)
    return self
end

function TRedfishSchemaVersion:unpack(_)
    return self.RedfishSchemaVersion
end

CA.RedfishSchemaVersion = TRedfishSchemaVersion

---@class CA.Privilege
---@field Privilege integer
local TPrivilege = {}
TPrivilege.__index = TPrivilege
TPrivilege.group = {}

local function TPrivilege_from_obj(obj)
    return setmetatable(obj, TPrivilege)
end

function TPrivilege.new(Privilege)
    return TPrivilege_from_obj({Privilege = Privilege or 1})
end
---@param obj CA.Privilege
function TPrivilege:init_from_obj(obj)
    self.Privilege = obj.Privilege or 1
end

function TPrivilege:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPrivilege.group)
end

TPrivilege.from_obj = TPrivilege_from_obj

TPrivilege.proto_property = {'Privilege'}

TPrivilege.default = {0}

TPrivilege.struct = {{name = 'Privilege', is_array = false, struct = nil}}

function TPrivilege:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Privilege', self.Privilege, 'uint32', false, errs, need_convert)

    TPrivilege:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPrivilege.proto_property, errs, need_convert)
    return self
end

function TPrivilege:unpack(_)
    return self.Privilege
end

CA.Privilege = TPrivilege

CA.interface = mdb.register_interface('bmc.kepler.CertificateService.CA', {
    Privilege = {'u', nil, false, 1, false},
    RedfishSchemaVersion = {'s', nil, false, '1.3.0', false}
}, {}, {})

return CA
