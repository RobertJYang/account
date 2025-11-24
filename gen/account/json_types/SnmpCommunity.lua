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

local SnmpCommunity = {}

---@class SnmpCommunity.RwCommunityEnabled
---@field RwCommunityEnabled boolean
local TRwCommunityEnabled = {}
TRwCommunityEnabled.__index = TRwCommunityEnabled
TRwCommunityEnabled.group = {}

local function TRwCommunityEnabled_from_obj(obj)
    return setmetatable(obj, TRwCommunityEnabled)
end

function TRwCommunityEnabled.new(RwCommunityEnabled)
    return TRwCommunityEnabled_from_obj({RwCommunityEnabled = RwCommunityEnabled == nil and true or RwCommunityEnabled})
end
---@param obj SnmpCommunity.RwCommunityEnabled
function TRwCommunityEnabled:init_from_obj(obj)
    self.RwCommunityEnabled = obj.RwCommunityEnabled == nil and true or obj.RwCommunityEnabled
end

function TRwCommunityEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TRwCommunityEnabled.group)
end

TRwCommunityEnabled.from_obj = TRwCommunityEnabled_from_obj

TRwCommunityEnabled.proto_property = {'RwCommunityEnabled'}

TRwCommunityEnabled.default = {false}

TRwCommunityEnabled.struct = {{name = 'RwCommunityEnabled', is_array = false, struct = nil}}

function TRwCommunityEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RwCommunityEnabled', self.RwCommunityEnabled, 'bool', false, errs, need_convert)

    TRwCommunityEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TRwCommunityEnabled.proto_property, errs, need_convert)
    return self
end

function TRwCommunityEnabled:unpack(_)
    return self.RwCommunityEnabled
end

SnmpCommunity.RwCommunityEnabled = TRwCommunityEnabled

---@class SnmpCommunity.LongCommunityEnabled
---@field LongCommunityEnabled boolean
local TLongCommunityEnabled = {}
TLongCommunityEnabled.__index = TLongCommunityEnabled
TLongCommunityEnabled.group = {}

local function TLongCommunityEnabled_from_obj(obj)
    return setmetatable(obj, TLongCommunityEnabled)
end

function TLongCommunityEnabled.new(LongCommunityEnabled)
    return TLongCommunityEnabled_from_obj({
        LongCommunityEnabled = LongCommunityEnabled == nil and true or LongCommunityEnabled
    })
end
---@param obj SnmpCommunity.LongCommunityEnabled
function TLongCommunityEnabled:init_from_obj(obj)
    self.LongCommunityEnabled = obj.LongCommunityEnabled == nil and true or obj.LongCommunityEnabled
end

function TLongCommunityEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLongCommunityEnabled.group)
end

TLongCommunityEnabled.from_obj = TLongCommunityEnabled_from_obj

TLongCommunityEnabled.proto_property = {'LongCommunityEnabled'}

TLongCommunityEnabled.default = {false}

TLongCommunityEnabled.struct = {{name = 'LongCommunityEnabled', is_array = false, struct = nil}}

function TLongCommunityEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'LongCommunityEnabled', self.LongCommunityEnabled, 'bool', false, errs, need_convert)

    TLongCommunityEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLongCommunityEnabled.proto_property, errs, need_convert)
    return self
end

function TLongCommunityEnabled:unpack(_)
    return self.LongCommunityEnabled
end

SnmpCommunity.LongCommunityEnabled = TLongCommunityEnabled

---@class SnmpCommunity.SnmpCommunityChangedSignalSignature
---@field RoCommunity string
---@field RwCommunity string
local TSnmpCommunityChangedSignalSignature = {}
TSnmpCommunityChangedSignalSignature.__index = TSnmpCommunityChangedSignalSignature
TSnmpCommunityChangedSignalSignature.group = {}

local function TSnmpCommunityChangedSignalSignature_from_obj(obj)
    return setmetatable(obj, TSnmpCommunityChangedSignalSignature)
end

function TSnmpCommunityChangedSignalSignature.new(RoCommunity, RwCommunity)
    return TSnmpCommunityChangedSignalSignature_from_obj({RoCommunity = RoCommunity, RwCommunity = RwCommunity})
end
---@param obj SnmpCommunity.SnmpCommunityChangedSignalSignature
function TSnmpCommunityChangedSignalSignature:init_from_obj(obj)
    self.RoCommunity = obj.RoCommunity
    self.RwCommunity = obj.RwCommunity
end

function TSnmpCommunityChangedSignalSignature:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSnmpCommunityChangedSignalSignature.group)
end

TSnmpCommunityChangedSignalSignature.from_obj = TSnmpCommunityChangedSignalSignature_from_obj

TSnmpCommunityChangedSignalSignature.proto_property = {'RoCommunity', 'RwCommunity'}

TSnmpCommunityChangedSignalSignature.default = {'', ''}

TSnmpCommunityChangedSignalSignature.struct = {
    {name = 'RoCommunity', is_array = false, struct = nil}, {name = 'RwCommunity', is_array = false, struct = nil}
}

function TSnmpCommunityChangedSignalSignature:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RoCommunity', self.RoCommunity, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'RwCommunity', self.RwCommunity, 'string', false, errs, need_convert)

    TSnmpCommunityChangedSignalSignature:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSnmpCommunityChangedSignalSignature.proto_property, errs, need_convert)
    return self
end

function TSnmpCommunityChangedSignalSignature:unpack(_)
    return self.RoCommunity, self.RwCommunity
end

SnmpCommunity.SnmpCommunityChangedSignalSignature = TSnmpCommunityChangedSignalSignature

---@class SnmpCommunity.SetSnmpCommunityLoginRuleRsp
local TSetSnmpCommunityLoginRuleRsp = {}
TSetSnmpCommunityLoginRuleRsp.__index = TSetSnmpCommunityLoginRuleRsp
TSetSnmpCommunityLoginRuleRsp.group = {}

local function TSetSnmpCommunityLoginRuleRsp_from_obj(obj)
    return setmetatable(obj, TSetSnmpCommunityLoginRuleRsp)
end

function TSetSnmpCommunityLoginRuleRsp.new()
    return TSetSnmpCommunityLoginRuleRsp_from_obj({})
end
---@param obj SnmpCommunity.SetSnmpCommunityLoginRuleRsp
function TSetSnmpCommunityLoginRuleRsp:init_from_obj(obj)

end

function TSetSnmpCommunityLoginRuleRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetSnmpCommunityLoginRuleRsp.group)
end

TSetSnmpCommunityLoginRuleRsp.from_obj = TSetSnmpCommunityLoginRuleRsp_from_obj

TSetSnmpCommunityLoginRuleRsp.proto_property = {}

TSetSnmpCommunityLoginRuleRsp.default = {}

TSetSnmpCommunityLoginRuleRsp.struct = {}

function TSetSnmpCommunityLoginRuleRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetSnmpCommunityLoginRuleRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetSnmpCommunityLoginRuleRsp.proto_property, errs, need_convert)
    return self
end

function TSetSnmpCommunityLoginRuleRsp:unpack(_)
end

SnmpCommunity.SetSnmpCommunityLoginRuleRsp = TSetSnmpCommunityLoginRuleRsp

---@class SnmpCommunity.SetSnmpCommunityLoginRuleReq
---@field LoginRuleIds string[]
local TSetSnmpCommunityLoginRuleReq = {}
TSetSnmpCommunityLoginRuleReq.__index = TSetSnmpCommunityLoginRuleReq
TSetSnmpCommunityLoginRuleReq.group = {}

local function TSetSnmpCommunityLoginRuleReq_from_obj(obj)
    return setmetatable(obj, TSetSnmpCommunityLoginRuleReq)
end

function TSetSnmpCommunityLoginRuleReq.new(LoginRuleIds)
    return TSetSnmpCommunityLoginRuleReq_from_obj({LoginRuleIds = LoginRuleIds})
end
---@param obj SnmpCommunity.SetSnmpCommunityLoginRuleReq
function TSetSnmpCommunityLoginRuleReq:init_from_obj(obj)
    self.LoginRuleIds = obj.LoginRuleIds
end

function TSetSnmpCommunityLoginRuleReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetSnmpCommunityLoginRuleReq.group)
end

TSetSnmpCommunityLoginRuleReq.from_obj = TSetSnmpCommunityLoginRuleReq_from_obj

TSetSnmpCommunityLoginRuleReq.proto_property = {'LoginRuleIds'}

TSetSnmpCommunityLoginRuleReq.default = {{}}

TSetSnmpCommunityLoginRuleReq.struct = {{name = 'LoginRuleIds', is_array = true, struct = nil}}

function TSetSnmpCommunityLoginRuleReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.OptionalArray(prefix .. 'LoginRuleIds', self.LoginRuleIds, 'string', false, errs, need_convert)

    TSetSnmpCommunityLoginRuleReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetSnmpCommunityLoginRuleReq.proto_property, errs, need_convert)
    return self
end

function TSetSnmpCommunityLoginRuleReq:unpack(_)
    return self.LoginRuleIds
end

SnmpCommunity.SetSnmpCommunityLoginRuleReq = TSetSnmpCommunityLoginRuleReq

---@class SnmpCommunity.GetSnmpCommunityRsp
---@field RwCommunity string
---@field RoCommunity string
local TGetSnmpCommunityRsp = {}
TGetSnmpCommunityRsp.__index = TGetSnmpCommunityRsp
TGetSnmpCommunityRsp.group = {}

local function TGetSnmpCommunityRsp_from_obj(obj)
    return setmetatable(obj, TGetSnmpCommunityRsp)
end

function TGetSnmpCommunityRsp.new(RwCommunity, RoCommunity)
    return TGetSnmpCommunityRsp_from_obj({RwCommunity = RwCommunity, RoCommunity = RoCommunity})
end
---@param obj SnmpCommunity.GetSnmpCommunityRsp
function TGetSnmpCommunityRsp:init_from_obj(obj)
    self.RwCommunity = obj.RwCommunity
    self.RoCommunity = obj.RoCommunity
end

function TGetSnmpCommunityRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetSnmpCommunityRsp.group)
end

TGetSnmpCommunityRsp.from_obj = TGetSnmpCommunityRsp_from_obj

TGetSnmpCommunityRsp.proto_property = {'RwCommunity', 'RoCommunity'}

TGetSnmpCommunityRsp.default = {'', ''}

TGetSnmpCommunityRsp.struct = {
    {name = 'RwCommunity', is_array = false, struct = nil}, {name = 'RoCommunity', is_array = false, struct = nil}
}

function TGetSnmpCommunityRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RwCommunity', self.RwCommunity, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'RoCommunity', self.RoCommunity, 'string', false, errs, need_convert)

    TGetSnmpCommunityRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetSnmpCommunityRsp.proto_property, errs, need_convert)
    return self
end

function TGetSnmpCommunityRsp:unpack(_)
    return self.RwCommunity, self.RoCommunity
end

SnmpCommunity.GetSnmpCommunityRsp = TGetSnmpCommunityRsp

---@class SnmpCommunity.GetSnmpCommunityReq
local TGetSnmpCommunityReq = {}
TGetSnmpCommunityReq.__index = TGetSnmpCommunityReq
TGetSnmpCommunityReq.group = {}

local function TGetSnmpCommunityReq_from_obj(obj)
    return setmetatable(obj, TGetSnmpCommunityReq)
end

function TGetSnmpCommunityReq.new()
    return TGetSnmpCommunityReq_from_obj({})
end
---@param obj SnmpCommunity.GetSnmpCommunityReq
function TGetSnmpCommunityReq:init_from_obj(obj)

end

function TGetSnmpCommunityReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetSnmpCommunityReq.group)
end

TGetSnmpCommunityReq.from_obj = TGetSnmpCommunityReq_from_obj

TGetSnmpCommunityReq.proto_property = {}

TGetSnmpCommunityReq.default = {}

TGetSnmpCommunityReq.struct = {}

function TGetSnmpCommunityReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TGetSnmpCommunityReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetSnmpCommunityReq.proto_property, errs, need_convert)
    return self
end

function TGetSnmpCommunityReq:unpack(_)
end

SnmpCommunity.GetSnmpCommunityReq = TGetSnmpCommunityReq

---@class SnmpCommunity.SetRoCommunityRsp
local TSetRoCommunityRsp = {}
TSetRoCommunityRsp.__index = TSetRoCommunityRsp
TSetRoCommunityRsp.group = {}

local function TSetRoCommunityRsp_from_obj(obj)
    return setmetatable(obj, TSetRoCommunityRsp)
end

function TSetRoCommunityRsp.new()
    return TSetRoCommunityRsp_from_obj({})
end
---@param obj SnmpCommunity.SetRoCommunityRsp
function TSetRoCommunityRsp:init_from_obj(obj)

end

function TSetRoCommunityRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetRoCommunityRsp.group)
end

TSetRoCommunityRsp.from_obj = TSetRoCommunityRsp_from_obj

TSetRoCommunityRsp.proto_property = {}

TSetRoCommunityRsp.default = {}

TSetRoCommunityRsp.struct = {}

function TSetRoCommunityRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetRoCommunityRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetRoCommunityRsp.proto_property, errs, need_convert)
    return self
end

function TSetRoCommunityRsp:unpack(_)
end

SnmpCommunity.SetRoCommunityRsp = TSetRoCommunityRsp

---@class SnmpCommunity.SetRoCommunityReq
---@field RwCommunity string
local TSetRoCommunityReq = {}
TSetRoCommunityReq.__index = TSetRoCommunityReq
TSetRoCommunityReq.group = {}

local function TSetRoCommunityReq_from_obj(obj)
    return setmetatable(obj, TSetRoCommunityReq)
end

function TSetRoCommunityReq.new(RwCommunity)
    return TSetRoCommunityReq_from_obj({RwCommunity = RwCommunity})
end
---@param obj SnmpCommunity.SetRoCommunityReq
function TSetRoCommunityReq:init_from_obj(obj)
    self.RwCommunity = obj.RwCommunity
end

function TSetRoCommunityReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetRoCommunityReq.group)
end

TSetRoCommunityReq.from_obj = TSetRoCommunityReq_from_obj

TSetRoCommunityReq.proto_property = {'RwCommunity'}

TSetRoCommunityReq.default = {''}

TSetRoCommunityReq.struct = {{name = 'RwCommunity', is_array = false, struct = nil}}

function TSetRoCommunityReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RwCommunity', self.RwCommunity, 'string', false, errs, need_convert)

    TSetRoCommunityReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetRoCommunityReq.proto_property, errs, need_convert)
    return self
end

function TSetRoCommunityReq:unpack(_)
    return self.RwCommunity
end

SnmpCommunity.SetRoCommunityReq = TSetRoCommunityReq

---@class SnmpCommunity.SetRwCommunityRsp
local TSetRwCommunityRsp = {}
TSetRwCommunityRsp.__index = TSetRwCommunityRsp
TSetRwCommunityRsp.group = {}

local function TSetRwCommunityRsp_from_obj(obj)
    return setmetatable(obj, TSetRwCommunityRsp)
end

function TSetRwCommunityRsp.new()
    return TSetRwCommunityRsp_from_obj({})
end
---@param obj SnmpCommunity.SetRwCommunityRsp
function TSetRwCommunityRsp:init_from_obj(obj)

end

function TSetRwCommunityRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetRwCommunityRsp.group)
end

TSetRwCommunityRsp.from_obj = TSetRwCommunityRsp_from_obj

TSetRwCommunityRsp.proto_property = {}

TSetRwCommunityRsp.default = {}

TSetRwCommunityRsp.struct = {}

function TSetRwCommunityRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetRwCommunityRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetRwCommunityRsp.proto_property, errs, need_convert)
    return self
end

function TSetRwCommunityRsp:unpack(_)
end

SnmpCommunity.SetRwCommunityRsp = TSetRwCommunityRsp

---@class SnmpCommunity.SetRwCommunityReq
---@field RwCommunity string
local TSetRwCommunityReq = {}
TSetRwCommunityReq.__index = TSetRwCommunityReq
TSetRwCommunityReq.group = {}

local function TSetRwCommunityReq_from_obj(obj)
    return setmetatable(obj, TSetRwCommunityReq)
end

function TSetRwCommunityReq.new(RwCommunity)
    return TSetRwCommunityReq_from_obj({RwCommunity = RwCommunity})
end
---@param obj SnmpCommunity.SetRwCommunityReq
function TSetRwCommunityReq:init_from_obj(obj)
    self.RwCommunity = obj.RwCommunity
end

function TSetRwCommunityReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetRwCommunityReq.group)
end

TSetRwCommunityReq.from_obj = TSetRwCommunityReq_from_obj

TSetRwCommunityReq.proto_property = {'RwCommunity'}

TSetRwCommunityReq.default = {''}

TSetRwCommunityReq.struct = {{name = 'RwCommunity', is_array = false, struct = nil}}

function TSetRwCommunityReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RwCommunity', self.RwCommunity, 'string', false, errs, need_convert)

    TSetRwCommunityReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetRwCommunityReq.proto_property, errs, need_convert)
    return self
end

function TSetRwCommunityReq:unpack(_)
    return self.RwCommunity
end

SnmpCommunity.SetRwCommunityReq = TSetRwCommunityReq

SnmpCommunity.interface = mdb.register_interface('bmc.kepler.Managers.SnmpService.SnmpCommunity', {
    LongCommunityEnabled = {'b', {'EMIT_CHANGE'}, false, true},
    RwCommunityEnabled = {'b', {'EMIT_CHANGE'}, false, true}
}, {
    SetRwCommunity = {'a{ss}s', '', TSetRwCommunityReq, TSetRwCommunityRsp},
    SetRoCommunity = {'a{ss}s', '', TSetRoCommunityReq, TSetRoCommunityRsp},
    GetSnmpCommunity = {'a{ss}', 'ss', TGetSnmpCommunityReq, TGetSnmpCommunityRsp},
    SetSnmpCommunityLoginRule = {'a{ss}as', '', TSetSnmpCommunityLoginRuleReq, TSetSnmpCommunityLoginRuleRsp}
}, {SnmpCommunityChangedSignal = 'a{ss}ss'})

return SnmpCommunity
