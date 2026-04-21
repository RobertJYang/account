--[[-- Copyright (c) 2026 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
]] --
local validate = require 'mc.validate'
local utils = require 'mc.utils'

local SetUserPassComplexity = {}

---@class AccountIpmiCmds.SetUserPassComplexityReq
---@field ManufactureId integer
---@field Control integer
local TSetUserPassComplexityReq = {}
TSetUserPassComplexityReq.__index = TSetUserPassComplexityReq
TSetUserPassComplexityReq.group = {}

local function TSetUserPassComplexityReq_from_obj(obj)
    return setmetatable(obj, TSetUserPassComplexityReq)
end

function TSetUserPassComplexityReq.new(ManufactureId, Control)
    return TSetUserPassComplexityReq_from_obj({ManufactureId = ManufactureId, Control = Control})
end
---@param obj AccountIpmiCmds.SetUserPassComplexityReq
function TSetUserPassComplexityReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.Control = obj.Control
end

function TSetUserPassComplexityReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetUserPassComplexityReq.group)
end

TSetUserPassComplexityReq.from_obj = TSetUserPassComplexityReq_from_obj

TSetUserPassComplexityReq.proto_property = {'ManufactureId', 'Control'}

TSetUserPassComplexityReq.default = {0, 0}

TSetUserPassComplexityReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'Control', is_array = false, struct = nil}
}

function TSetUserPassComplexityReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Control', self.Control, 'uint8', false, errs, need_convert)

    TSetUserPassComplexityReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetUserPassComplexityReq.proto_property, errs, need_convert)
    return self
end

function TSetUserPassComplexityReq:unpack(_)
    return self.ManufactureId, self.Control
end

SetUserPassComplexity.SetUserPassComplexityReq = TSetUserPassComplexityReq

---@class AccountIpmiCmds.SetUserPassComplexityRsp
---@field CompletionCode integer
---@field ManufactureId integer
local TSetUserPassComplexityRsp = {}
TSetUserPassComplexityRsp.__index = TSetUserPassComplexityRsp
TSetUserPassComplexityRsp.group = {}

local function TSetUserPassComplexityRsp_from_obj(obj)
    return setmetatable(obj, TSetUserPassComplexityRsp)
end

function TSetUserPassComplexityRsp.new(CompletionCode, ManufactureId)
    return TSetUserPassComplexityRsp_from_obj({CompletionCode = CompletionCode, ManufactureId = ManufactureId})
end
---@param obj AccountIpmiCmds.SetUserPassComplexityRsp
function TSetUserPassComplexityRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
end

function TSetUserPassComplexityRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetUserPassComplexityRsp.group)
end

TSetUserPassComplexityRsp.from_obj = TSetUserPassComplexityRsp_from_obj

TSetUserPassComplexityRsp.proto_property = {'CompletionCode', 'ManufactureId'}

TSetUserPassComplexityRsp.default = {0, 0}

TSetUserPassComplexityRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil}
}

function TSetUserPassComplexityRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)

    TSetUserPassComplexityRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetUserPassComplexityRsp.proto_property, errs, need_convert)
    return self
end

function TSetUserPassComplexityRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId
end

SetUserPassComplexity.SetUserPassComplexityRsp = TSetUserPassComplexityRsp

return SetUserPassComplexity
