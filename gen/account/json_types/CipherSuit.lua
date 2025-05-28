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

local CipherSuit = {}

---@class CipherSuit.SuitName
---@field SuitName string
local TSuitName = {}
TSuitName.__index = TSuitName
TSuitName.group = {}

local function TSuitName_from_obj(obj)
    return setmetatable(obj, TSuitName)
end

function TSuitName.new(SuitName)
    return TSuitName_from_obj({SuitName = SuitName or [=[]=]})
end
---@param obj CipherSuit.SuitName
function TSuitName:init_from_obj(obj)
    self.SuitName = obj.SuitName or [=[]=]
end

function TSuitName:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSuitName.group)
end

TSuitName.from_obj = TSuitName_from_obj

TSuitName.proto_property = {'SuitName'}

TSuitName.default = {''}

TSuitName.struct = {{name = 'SuitName', is_array = false, struct = nil}}

function TSuitName:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SuitName', self.SuitName, 'string', true, errs, need_convert)

    TSuitName:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSuitName.proto_property, errs, need_convert)
    return self
end

function TSuitName:unpack(_)
    return self.SuitName
end

CipherSuit.SuitName = TSuitName

---@class CipherSuit.Enabled
---@field Enabled boolean
local TEnabled = {}
TEnabled.__index = TEnabled
TEnabled.group = {}

local function TEnabled_from_obj(obj)
    return setmetatable(obj, TEnabled)
end

function TEnabled.new(Enabled)
    return TEnabled_from_obj({Enabled = Enabled})
end
---@param obj CipherSuit.Enabled
function TEnabled:init_from_obj(obj)
    self.Enabled = obj.Enabled
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

    validate.Optional(prefix .. 'Enabled', self.Enabled, 'bool', true, errs, need_convert)

    TEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TEnabled.proto_property, errs, need_convert)
    return self
end

function TEnabled:unpack(_)
    return self.Enabled
end

CipherSuit.Enabled = TEnabled

CipherSuit.interface = mdb.register_interface('bmc.kepler.Managers.Security.TlsConfig.CipherSuit', {
    Enabled = {'b', {'EMIT_CHANGE'}, true, nil, false},
    SuitName = {'s', {'EMIT_CHANGE'}, true, '', false}
}, {}, {})

return CipherSuit
