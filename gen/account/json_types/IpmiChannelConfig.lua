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

local IpmiChannelConfig = {}

---@class IpmiChannelConfig.SessionLimit
---@field SessionLimit integer
local TSessionLimit = {}
TSessionLimit.__index = TSessionLimit
TSessionLimit.group = {}

local function TSessionLimit_from_obj(obj)
    return setmetatable(obj, TSessionLimit)
end

function TSessionLimit.new(SessionLimit)
    return TSessionLimit_from_obj({SessionLimit = SessionLimit})
end
---@param obj IpmiChannelConfig.SessionLimit
function TSessionLimit:init_from_obj(obj)
    self.SessionLimit = obj.SessionLimit
end

function TSessionLimit:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSessionLimit.group)
end

TSessionLimit.from_obj = TSessionLimit_from_obj

TSessionLimit.proto_property = {'SessionLimit'}

TSessionLimit.default = {0}

TSessionLimit.struct = {{name = 'SessionLimit', is_array = false, struct = nil}}

function TSessionLimit:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SessionLimit', self.SessionLimit, 'uint8', true, errs, need_convert)

    TSessionLimit:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSessionLimit.proto_property, errs, need_convert)
    return self
end

function TSessionLimit:unpack(_)
    return self.SessionLimit
end

IpmiChannelConfig.SessionLimit = TSessionLimit

---@class IpmiChannelConfig.CallbackRestriction
---@field CallbackRestriction integer
local TCallbackRestriction = {}
TCallbackRestriction.__index = TCallbackRestriction
TCallbackRestriction.group = {}

local function TCallbackRestriction_from_obj(obj)
    return setmetatable(obj, TCallbackRestriction)
end

function TCallbackRestriction.new(CallbackRestriction)
    return TCallbackRestriction_from_obj({CallbackRestriction = CallbackRestriction})
end
---@param obj IpmiChannelConfig.CallbackRestriction
function TCallbackRestriction:init_from_obj(obj)
    self.CallbackRestriction = obj.CallbackRestriction
end

function TCallbackRestriction:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TCallbackRestriction.group)
end

TCallbackRestriction.from_obj = TCallbackRestriction_from_obj

TCallbackRestriction.proto_property = {'CallbackRestriction'}

TCallbackRestriction.default = {0}

TCallbackRestriction.struct = {{name = 'CallbackRestriction', is_array = false, struct = nil}}

function TCallbackRestriction:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CallbackRestriction', self.CallbackRestriction, 'uint8', true, errs, need_convert)

    TCallbackRestriction:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TCallbackRestriction.proto_property, errs, need_convert)
    return self
end

function TCallbackRestriction:unpack(_)
    return self.CallbackRestriction
end

IpmiChannelConfig.CallbackRestriction = TCallbackRestriction

---@class IpmiChannelConfig.LinkAuthenticationEnabled
---@field LinkAuthenticationEnabled boolean
local TLinkAuthenticationEnabled = {}
TLinkAuthenticationEnabled.__index = TLinkAuthenticationEnabled
TLinkAuthenticationEnabled.group = {}

local function TLinkAuthenticationEnabled_from_obj(obj)
    return setmetatable(obj, TLinkAuthenticationEnabled)
end

function TLinkAuthenticationEnabled.new(LinkAuthenticationEnabled)
    return TLinkAuthenticationEnabled_from_obj({
        LinkAuthenticationEnabled = LinkAuthenticationEnabled == nil and true or LinkAuthenticationEnabled
    })
end
---@param obj IpmiChannelConfig.LinkAuthenticationEnabled
function TLinkAuthenticationEnabled:init_from_obj(obj)
    self.LinkAuthenticationEnabled = obj.LinkAuthenticationEnabled == nil and true or obj.LinkAuthenticationEnabled
end

function TLinkAuthenticationEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TLinkAuthenticationEnabled.group)
end

TLinkAuthenticationEnabled.from_obj = TLinkAuthenticationEnabled_from_obj

TLinkAuthenticationEnabled.proto_property = {'LinkAuthenticationEnabled'}

TLinkAuthenticationEnabled.default = {false}

TLinkAuthenticationEnabled.struct = {{name = 'LinkAuthenticationEnabled', is_array = false, struct = nil}}

function TLinkAuthenticationEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'LinkAuthenticationEnabled', self.LinkAuthenticationEnabled, 'bool', true, errs,
        need_convert)

    TLinkAuthenticationEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TLinkAuthenticationEnabled.proto_property, errs, need_convert)
    return self
end

function TLinkAuthenticationEnabled:unpack(_)
    return self.LinkAuthenticationEnabled
end

IpmiChannelConfig.LinkAuthenticationEnabled = TLinkAuthenticationEnabled

---@class IpmiChannelConfig.IpmiMessagingEnabled
---@field IpmiMessagingEnabled boolean
local TIpmiMessagingEnabled = {}
TIpmiMessagingEnabled.__index = TIpmiMessagingEnabled
TIpmiMessagingEnabled.group = {}

local function TIpmiMessagingEnabled_from_obj(obj)
    return setmetatable(obj, TIpmiMessagingEnabled)
end

function TIpmiMessagingEnabled.new(IpmiMessagingEnabled)
    return TIpmiMessagingEnabled_from_obj({
        IpmiMessagingEnabled = IpmiMessagingEnabled == nil and true or IpmiMessagingEnabled
    })
end
---@param obj IpmiChannelConfig.IpmiMessagingEnabled
function TIpmiMessagingEnabled:init_from_obj(obj)
    self.IpmiMessagingEnabled = obj.IpmiMessagingEnabled == nil and true or obj.IpmiMessagingEnabled
end

function TIpmiMessagingEnabled:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIpmiMessagingEnabled.group)
end

TIpmiMessagingEnabled.from_obj = TIpmiMessagingEnabled_from_obj

TIpmiMessagingEnabled.proto_property = {'IpmiMessagingEnabled'}

TIpmiMessagingEnabled.default = {false}

TIpmiMessagingEnabled.struct = {{name = 'IpmiMessagingEnabled', is_array = false, struct = nil}}

function TIpmiMessagingEnabled:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'IpmiMessagingEnabled', self.IpmiMessagingEnabled, 'bool', true, errs, need_convert)

    TIpmiMessagingEnabled:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIpmiMessagingEnabled.proto_property, errs, need_convert)
    return self
end

function TIpmiMessagingEnabled:unpack(_)
    return self.IpmiMessagingEnabled
end

IpmiChannelConfig.IpmiMessagingEnabled = TIpmiMessagingEnabled

---@class IpmiChannelConfig.PrivilegeLimit
---@field PrivilegeLimit integer
local TPrivilegeLimit = {}
TPrivilegeLimit.__index = TPrivilegeLimit
TPrivilegeLimit.group = {}

local function TPrivilegeLimit_from_obj(obj)
    return setmetatable(obj, TPrivilegeLimit)
end

function TPrivilegeLimit.new(PrivilegeLimit)
    return TPrivilegeLimit_from_obj({PrivilegeLimit = PrivilegeLimit})
end
---@param obj IpmiChannelConfig.PrivilegeLimit
function TPrivilegeLimit:init_from_obj(obj)
    self.PrivilegeLimit = obj.PrivilegeLimit
end

function TPrivilegeLimit:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TPrivilegeLimit.group)
end

TPrivilegeLimit.from_obj = TPrivilegeLimit_from_obj

TPrivilegeLimit.proto_property = {'PrivilegeLimit'}

TPrivilegeLimit.default = {0}

TPrivilegeLimit.struct = {{name = 'PrivilegeLimit', is_array = false, struct = nil}}

function TPrivilegeLimit:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'PrivilegeLimit', self.PrivilegeLimit, 'uint8', true, errs, need_convert)

    TPrivilegeLimit:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TPrivilegeLimit.proto_property, errs, need_convert)
    return self
end

function TPrivilegeLimit:unpack(_)
    return self.PrivilegeLimit
end

IpmiChannelConfig.PrivilegeLimit = TPrivilegeLimit

IpmiChannelConfig.interface = mdb.register_interface('bmc.kepler.AccountService.ManagerAccount.IpmiChannelConfig', {
    PrivilegeLimit = {'y', {}, true, nil},
    IpmiMessagingEnabled = {'b', {}, true, 'true'},
    LinkAuthenticationEnabled = {'b', {}, true, 'true'},
    CallbackRestriction = {'y', {}, true, nil},
    SessionLimit = {'y', {}, true, nil}
}, {}, {})

return IpmiChannelConfig
