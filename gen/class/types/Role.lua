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

local MRole = {}

---@class MRole.ConfigureSelf
---@field ConfigureSelf boolean
local TConfigureSelf = {}
TConfigureSelf.__index = TConfigureSelf
TConfigureSelf.group = {}

local function TConfigureSelf_from_obj(obj)
    return setmetatable(obj, TConfigureSelf)
end

function TConfigureSelf.new(ConfigureSelf)
    return TConfigureSelf_from_obj({ConfigureSelf = ConfigureSelf or false})
end
---@param obj MRole.ConfigureSelf
function TConfigureSelf:init_from_obj(obj)
    self.ConfigureSelf = obj.ConfigureSelf or false
end

function TConfigureSelf:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TConfigureSelf.group)
end

TConfigureSelf.from_obj = TConfigureSelf_from_obj

TConfigureSelf.proto_property = {'ConfigureSelf'}

TConfigureSelf.default = {false}

TConfigureSelf.struct = {{name = 'ConfigureSelf', is_array = false, struct = nil}}

function TConfigureSelf:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ConfigureSelf', self.ConfigureSelf, 'bool', false, errs, need_convert)

    TConfigureSelf:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TConfigureSelf.proto_property, errs, need_convert)
    return self
end

function TConfigureSelf:unpack(_)
    return self.ConfigureSelf
end

MRole.ConfigureSelf = TConfigureSelf

---@class MRole.DiagnoseMgmt
---@field DiagnoseMgmt boolean
local TDiagnoseMgmt = {}
TDiagnoseMgmt.__index = TDiagnoseMgmt
TDiagnoseMgmt.group = {}

local function TDiagnoseMgmt_from_obj(obj)
    return setmetatable(obj, TDiagnoseMgmt)
end

function TDiagnoseMgmt.new(DiagnoseMgmt)
    return TDiagnoseMgmt_from_obj({DiagnoseMgmt = DiagnoseMgmt or false})
end
---@param obj MRole.DiagnoseMgmt
function TDiagnoseMgmt:init_from_obj(obj)
    self.DiagnoseMgmt = obj.DiagnoseMgmt or false
end

function TDiagnoseMgmt:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDiagnoseMgmt.group)
end

TDiagnoseMgmt.from_obj = TDiagnoseMgmt_from_obj

TDiagnoseMgmt.proto_property = {'DiagnoseMgmt'}

TDiagnoseMgmt.default = {false}

TDiagnoseMgmt.struct = {{name = 'DiagnoseMgmt', is_array = false, struct = nil}}

function TDiagnoseMgmt:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DiagnoseMgmt', self.DiagnoseMgmt, 'bool', false, errs, need_convert)

    TDiagnoseMgmt:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDiagnoseMgmt.proto_property, errs, need_convert)
    return self
end

function TDiagnoseMgmt:unpack(_)
    return self.DiagnoseMgmt
end

MRole.DiagnoseMgmt = TDiagnoseMgmt

---@class MRole.PowerMgmt
---@field PowerMgmt boolean
local TPowerMgmt = {}
TPowerMgmt.__index = TPowerMgmt
TPowerMgmt.group = {}

local function TPowerMgmt_from_obj(obj)
    return setmetatable(obj, TPowerMgmt)
end

function TPowerMgmt.new(PowerMgmt)
    return TPowerMgmt_from_obj({PowerMgmt = PowerMgmt or false})
end
---@param obj MRole.PowerMgmt
function TPowerMgmt:init_from_obj(obj)
    self.PowerMgmt = obj.PowerMgmt or false
end

function TPowerMgmt:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPowerMgmt.group)
end

TPowerMgmt.from_obj = TPowerMgmt_from_obj

TPowerMgmt.proto_property = {'PowerMgmt'}

TPowerMgmt.default = {false}

TPowerMgmt.struct = {{name = 'PowerMgmt', is_array = false, struct = nil}}

function TPowerMgmt:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PowerMgmt', self.PowerMgmt, 'bool', false, errs, need_convert)

    TPowerMgmt:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPowerMgmt.proto_property, errs, need_convert)
    return self
end

function TPowerMgmt:unpack(_)
    return self.PowerMgmt
end

MRole.PowerMgmt = TPowerMgmt

---@class MRole.SecurityMgmt
---@field SecurityMgmt boolean
local TSecurityMgmt = {}
TSecurityMgmt.__index = TSecurityMgmt
TSecurityMgmt.group = {}

local function TSecurityMgmt_from_obj(obj)
    return setmetatable(obj, TSecurityMgmt)
end

function TSecurityMgmt.new(SecurityMgmt)
    return TSecurityMgmt_from_obj({SecurityMgmt = SecurityMgmt or false})
end
---@param obj MRole.SecurityMgmt
function TSecurityMgmt:init_from_obj(obj)
    self.SecurityMgmt = obj.SecurityMgmt or false
end

function TSecurityMgmt:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSecurityMgmt.group)
end

TSecurityMgmt.from_obj = TSecurityMgmt_from_obj

TSecurityMgmt.proto_property = {'SecurityMgmt'}

TSecurityMgmt.default = {false}

TSecurityMgmt.struct = {{name = 'SecurityMgmt', is_array = false, struct = nil}}

function TSecurityMgmt:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SecurityMgmt', self.SecurityMgmt, 'bool', false, errs, need_convert)

    TSecurityMgmt:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSecurityMgmt.proto_property, errs, need_convert)
    return self
end

function TSecurityMgmt:unpack(_)
    return self.SecurityMgmt
end

MRole.SecurityMgmt = TSecurityMgmt

---@class MRole.VMMMgmt
---@field VMMMgmt boolean
local TVMMMgmt = {}
TVMMMgmt.__index = TVMMMgmt
TVMMMgmt.group = {}

local function TVMMMgmt_from_obj(obj)
    return setmetatable(obj, TVMMMgmt)
end

function TVMMMgmt.new(VMMMgmt)
    return TVMMMgmt_from_obj({VMMMgmt = VMMMgmt or false})
end
---@param obj MRole.VMMMgmt
function TVMMMgmt:init_from_obj(obj)
    self.VMMMgmt = obj.VMMMgmt or false
end

function TVMMMgmt:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TVMMMgmt.group)
end

TVMMMgmt.from_obj = TVMMMgmt_from_obj

TVMMMgmt.proto_property = {'VMMMgmt'}

TVMMMgmt.default = {false}

TVMMMgmt.struct = {{name = 'VMMMgmt', is_array = false, struct = nil}}

function TVMMMgmt:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'VMMMgmt', self.VMMMgmt, 'bool', false, errs, need_convert)

    TVMMMgmt:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TVMMMgmt.proto_property, errs, need_convert)
    return self
end

function TVMMMgmt:unpack(_)
    return self.VMMMgmt
end

MRole.VMMMgmt = TVMMMgmt

---@class MRole.ReadOnly
---@field ReadOnly boolean
local TReadOnly = {}
TReadOnly.__index = TReadOnly
TReadOnly.group = {}

local function TReadOnly_from_obj(obj)
    return setmetatable(obj, TReadOnly)
end

function TReadOnly.new(ReadOnly)
    return TReadOnly_from_obj({ReadOnly = ReadOnly or false})
end
---@param obj MRole.ReadOnly
function TReadOnly:init_from_obj(obj)
    self.ReadOnly = obj.ReadOnly or false
end

function TReadOnly:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TReadOnly.group)
end

TReadOnly.from_obj = TReadOnly_from_obj

TReadOnly.proto_property = {'ReadOnly'}

TReadOnly.default = {false}

TReadOnly.struct = {{name = 'ReadOnly', is_array = false, struct = nil}}

function TReadOnly:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ReadOnly', self.ReadOnly, 'bool', false, errs, need_convert)

    TReadOnly:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TReadOnly.proto_property, errs, need_convert)
    return self
end

function TReadOnly:unpack(_)
    return self.ReadOnly
end

MRole.ReadOnly = TReadOnly

---@class MRole.KVMMgmt
---@field KVMMgmt boolean
local TKVMMgmt = {}
TKVMMgmt.__index = TKVMMgmt
TKVMMgmt.group = {}

local function TKVMMgmt_from_obj(obj)
    return setmetatable(obj, TKVMMgmt)
end

function TKVMMgmt.new(KVMMgmt)
    return TKVMMgmt_from_obj({KVMMgmt = KVMMgmt or false})
end
---@param obj MRole.KVMMgmt
function TKVMMgmt:init_from_obj(obj)
    self.KVMMgmt = obj.KVMMgmt or false
end

function TKVMMgmt:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TKVMMgmt.group)
end

TKVMMgmt.from_obj = TKVMMgmt_from_obj

TKVMMgmt.proto_property = {'KVMMgmt'}

TKVMMgmt.default = {false}

TKVMMgmt.struct = {{name = 'KVMMgmt', is_array = false, struct = nil}}

function TKVMMgmt:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'KVMMgmt', self.KVMMgmt, 'bool', false, errs, need_convert)

    TKVMMgmt:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TKVMMgmt.proto_property, errs, need_convert)
    return self
end

function TKVMMgmt:unpack(_)
    return self.KVMMgmt
end

MRole.KVMMgmt = TKVMMgmt

---@class MRole.BasicSetting
---@field BasicSetting boolean
local TBasicSetting = {}
TBasicSetting.__index = TBasicSetting
TBasicSetting.group = {}

local function TBasicSetting_from_obj(obj)
    return setmetatable(obj, TBasicSetting)
end

function TBasicSetting.new(BasicSetting)
    return TBasicSetting_from_obj({BasicSetting = BasicSetting or false})
end
---@param obj MRole.BasicSetting
function TBasicSetting:init_from_obj(obj)
    self.BasicSetting = obj.BasicSetting or false
end

function TBasicSetting:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TBasicSetting.group)
end

TBasicSetting.from_obj = TBasicSetting_from_obj

TBasicSetting.proto_property = {'BasicSetting'}

TBasicSetting.default = {false}

TBasicSetting.struct = {{name = 'BasicSetting', is_array = false, struct = nil}}

function TBasicSetting:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'BasicSetting', self.BasicSetting, 'bool', false, errs, need_convert)

    TBasicSetting:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TBasicSetting.proto_property, errs, need_convert)
    return self
end

function TBasicSetting:unpack(_)
    return self.BasicSetting
end

MRole.BasicSetting = TBasicSetting

---@class MRole.UserMgmt
---@field UserMgmt boolean
local TUserMgmt = {}
TUserMgmt.__index = TUserMgmt
TUserMgmt.group = {}

local function TUserMgmt_from_obj(obj)
    return setmetatable(obj, TUserMgmt)
end

function TUserMgmt.new(UserMgmt)
    return TUserMgmt_from_obj({UserMgmt = UserMgmt or false})
end
---@param obj MRole.UserMgmt
function TUserMgmt:init_from_obj(obj)
    self.UserMgmt = obj.UserMgmt or false
end

function TUserMgmt:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUserMgmt.group)
end

TUserMgmt.from_obj = TUserMgmt_from_obj

TUserMgmt.proto_property = {'UserMgmt'}

TUserMgmt.default = {false}

TUserMgmt.struct = {{name = 'UserMgmt', is_array = false, struct = nil}}

function TUserMgmt:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'UserMgmt', self.UserMgmt, 'bool', false, errs, need_convert)

    TUserMgmt:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUserMgmt.proto_property, errs, need_convert)
    return self
end

function TUserMgmt:unpack(_)
    return self.UserMgmt
end

MRole.UserMgmt = TUserMgmt

---@class MRole.RoleName
---@field RoleName string
local TRoleName = {}
TRoleName.__index = TRoleName
TRoleName.group = {}

local function TRoleName_from_obj(obj)
    return setmetatable(obj, TRoleName)
end

function TRoleName.new(RoleName)
    return TRoleName_from_obj({RoleName = RoleName})
end
---@param obj MRole.RoleName
function TRoleName:init_from_obj(obj)
    self.RoleName = obj.RoleName
end

function TRoleName:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRoleName.group)
end

TRoleName.from_obj = TRoleName_from_obj

TRoleName.proto_property = {'RoleName'}

TRoleName.default = {''}

TRoleName.struct = {{name = 'RoleName', is_array = false, struct = nil}}

function TRoleName:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RoleName', self.RoleName, 'string', false, errs, need_convert)

    TRoleName:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRoleName.proto_property, errs, need_convert)
    return self
end

function TRoleName:unpack(_)
    return self.RoleName
end

MRole.RoleName = TRoleName

---@class MRole.Id
---@field Id def_types.RoleType
local TId = {}
TId.__index = TId
TId.group = {}

local function TId_from_obj(obj)
    obj.Id = obj.Id and def_types.RoleType.new(obj.Id)
    return setmetatable(obj, TId)
end

function TId.new(Id)
    return TId_from_obj({Id = Id})
end
---@param obj MRole.Id
function TId:init_from_obj(obj)
    self.Id = obj.Id
end

function TId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TId.group)
end

TId.from_obj = TId_from_obj

TId.proto_property = {'Id'}

TId.default = {def_types.RoleType.default}

TId.struct = {{name = 'Id', is_array = false, struct = def_types.RoleType.struct}}

function TId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'Id', self.Id, 'def_types.RoleType', false, errs, need_convert)

    TId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TId.proto_property, errs, need_convert)
    return self
end

function TId:unpack(raw)
    local Id = utils.unpack_enum(raw, self.Id)
    return Id
end

MRole.Id = TId

return MRole
