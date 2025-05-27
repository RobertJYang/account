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

local MManagerAccountBackup = {}

---@class MManagerAccountBackup.SnmpAccountData
---@field SnmpAccountData string
local TSnmpAccountData = {}
TSnmpAccountData.__index = TSnmpAccountData
TSnmpAccountData.group = {}

local function TSnmpAccountData_from_obj(obj)
    return setmetatable(obj, TSnmpAccountData)
end

function TSnmpAccountData.new(SnmpAccountData)
    return TSnmpAccountData_from_obj({SnmpAccountData = SnmpAccountData})
end
---@param obj MManagerAccountBackup.SnmpAccountData
function TSnmpAccountData:init_from_obj(obj)
    self.SnmpAccountData = obj.SnmpAccountData
end

function TSnmpAccountData:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSnmpAccountData.group)
end

TSnmpAccountData.from_obj = TSnmpAccountData_from_obj

TSnmpAccountData.proto_property = {'SnmpAccountData'}

TSnmpAccountData.default = {''}

TSnmpAccountData.struct = {{name = 'SnmpAccountData', is_array = false, struct = nil}}

function TSnmpAccountData:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SnmpAccountData', self.SnmpAccountData, 'string', false, errs, need_convert)

    TSnmpAccountData:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSnmpAccountData.proto_property, errs, need_convert)
    return self
end

function TSnmpAccountData:unpack(_)
    return self.SnmpAccountData
end

MManagerAccountBackup.SnmpAccountData = TSnmpAccountData

---@class MManagerAccountBackup.IpmiAccountData
---@field IpmiAccountData string
local TIpmiAccountData = {}
TIpmiAccountData.__index = TIpmiAccountData
TIpmiAccountData.group = {}

local function TIpmiAccountData_from_obj(obj)
    return setmetatable(obj, TIpmiAccountData)
end

function TIpmiAccountData.new(IpmiAccountData)
    return TIpmiAccountData_from_obj({IpmiAccountData = IpmiAccountData})
end
---@param obj MManagerAccountBackup.IpmiAccountData
function TIpmiAccountData:init_from_obj(obj)
    self.IpmiAccountData = obj.IpmiAccountData
end

function TIpmiAccountData:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIpmiAccountData.group)
end

TIpmiAccountData.from_obj = TIpmiAccountData_from_obj

TIpmiAccountData.proto_property = {'IpmiAccountData'}

TIpmiAccountData.default = {''}

TIpmiAccountData.struct = {{name = 'IpmiAccountData', is_array = false, struct = nil}}

function TIpmiAccountData:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpmiAccountData', self.IpmiAccountData, 'string', false, errs, need_convert)

    TIpmiAccountData:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIpmiAccountData.proto_property, errs, need_convert)
    return self
end

function TIpmiAccountData:unpack(_)
    return self.IpmiAccountData
end

MManagerAccountBackup.IpmiAccountData = TIpmiAccountData

---@class MManagerAccountBackup.ManagerAccountData
---@field ManagerAccountData string
local TManagerAccountData = {}
TManagerAccountData.__index = TManagerAccountData
TManagerAccountData.group = {}

local function TManagerAccountData_from_obj(obj)
    return setmetatable(obj, TManagerAccountData)
end

function TManagerAccountData.new(ManagerAccountData)
    return TManagerAccountData_from_obj({ManagerAccountData = ManagerAccountData})
end
---@param obj MManagerAccountBackup.ManagerAccountData
function TManagerAccountData:init_from_obj(obj)
    self.ManagerAccountData = obj.ManagerAccountData
end

function TManagerAccountData:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TManagerAccountData.group)
end

TManagerAccountData.from_obj = TManagerAccountData_from_obj

TManagerAccountData.proto_property = {'ManagerAccountData'}

TManagerAccountData.default = {''}

TManagerAccountData.struct = {{name = 'ManagerAccountData', is_array = false, struct = nil}}

function TManagerAccountData:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManagerAccountData', self.ManagerAccountData, 'string', false, errs, need_convert)

    TManagerAccountData:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TManagerAccountData.proto_property, errs, need_convert)
    return self
end

function TManagerAccountData:unpack(_)
    return self.ManagerAccountData
end

MManagerAccountBackup.ManagerAccountData = TManagerAccountData

---@class MManagerAccountBackup.Id
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
---@param obj MManagerAccountBackup.Id
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

MManagerAccountBackup.Id = TId

return MManagerAccountBackup
