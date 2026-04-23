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

local MIpmiChannelConfig = {}

---@class MIpmiChannelConfig.ChannelNumber
---@field ChannelNumber integer
local TChannelNumber = {}
TChannelNumber.__index = TChannelNumber
TChannelNumber.group = {}

local function TChannelNumber_from_obj(obj)
    return setmetatable(obj, TChannelNumber)
end

function TChannelNumber.new(ChannelNumber)
    return TChannelNumber_from_obj({ChannelNumber = ChannelNumber})
end
---@param obj MIpmiChannelConfig.ChannelNumber
function TChannelNumber:init_from_obj(obj)
    self.ChannelNumber = obj.ChannelNumber
end

function TChannelNumber:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TChannelNumber.group)
end

TChannelNumber.from_obj = TChannelNumber_from_obj

TChannelNumber.proto_property = {'ChannelNumber'}

TChannelNumber.default = {0}

TChannelNumber.struct = {{name = 'ChannelNumber', is_array = false, struct = nil}}

function TChannelNumber:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'ChannelNumber', self.ChannelNumber, 'uint8', false, errs, need_convert)

    TChannelNumber:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TChannelNumber.proto_property, errs, need_convert)
    return self
end

function TChannelNumber:unpack(_)
    return self.ChannelNumber
end

MIpmiChannelConfig.ChannelNumber = TChannelNumber

---@class MIpmiChannelConfig.AccountId
---@field AccountId integer
local TAccountId = {}
TAccountId.__index = TAccountId
TAccountId.group = {}

local function TAccountId_from_obj(obj)
    return setmetatable(obj, TAccountId)
end

function TAccountId.new(AccountId)
    return TAccountId_from_obj({AccountId = AccountId})
end
---@param obj MIpmiChannelConfig.AccountId
function TAccountId:init_from_obj(obj)
    self.AccountId = obj.AccountId
end

function TAccountId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountId.group)
end

TAccountId.from_obj = TAccountId_from_obj

TAccountId.proto_property = {'AccountId'}

TAccountId.default = {0}

TAccountId.struct = {{name = 'AccountId', is_array = false, struct = nil}}

function TAccountId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'AccountId', self.AccountId, 'uint8', false, errs, need_convert)

    TAccountId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountId.proto_property, errs, need_convert)
    return self
end

function TAccountId:unpack(_)
    return self.AccountId
end

MIpmiChannelConfig.AccountId = TAccountId

return MIpmiChannelConfig
