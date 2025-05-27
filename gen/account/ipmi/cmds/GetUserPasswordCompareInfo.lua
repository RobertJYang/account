--[[-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
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

local GetUserPasswordCompareInfo = {}

---@class AccountIpmiCmds.GetUserPasswordCompareInfoReq
---@field ManufactureId integer
local TGetUserPasswordCompareInfoReq = {}
TGetUserPasswordCompareInfoReq.__index = TGetUserPasswordCompareInfoReq
TGetUserPasswordCompareInfoReq.group = {}

local function TGetUserPasswordCompareInfoReq_from_obj(obj)
    return setmetatable(obj, TGetUserPasswordCompareInfoReq)
end

function TGetUserPasswordCompareInfoReq.new(ManufactureId)
    return TGetUserPasswordCompareInfoReq_from_obj({ManufactureId = ManufactureId})
end
---@param obj AccountIpmiCmds.GetUserPasswordCompareInfoReq
function TGetUserPasswordCompareInfoReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
end

function TGetUserPasswordCompareInfoReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetUserPasswordCompareInfoReq.group)
end

TGetUserPasswordCompareInfoReq.from_obj = TGetUserPasswordCompareInfoReq_from_obj

TGetUserPasswordCompareInfoReq.proto_property = {'ManufactureId'}

TGetUserPasswordCompareInfoReq.default = {0}

TGetUserPasswordCompareInfoReq.struct = {{name = 'ManufactureId', is_array = false, struct = nil}}

function TGetUserPasswordCompareInfoReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)

    TGetUserPasswordCompareInfoReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetUserPasswordCompareInfoReq.proto_property, errs, need_convert)
    return self
end

function TGetUserPasswordCompareInfoReq:unpack(_)
    return self.ManufactureId
end

GetUserPasswordCompareInfo.GetUserPasswordCompareInfoReq = TGetUserPasswordCompareInfoReq

---@class AccountIpmiCmds.GetUserPasswordCompareInfoRsp
---@field CompletionCode integer
---@field ManufactureId integer
---@field CompareEnabled integer
---@field CompareLength integer
local TGetUserPasswordCompareInfoRsp = {}
TGetUserPasswordCompareInfoRsp.__index = TGetUserPasswordCompareInfoRsp
TGetUserPasswordCompareInfoRsp.group = {}

local function TGetUserPasswordCompareInfoRsp_from_obj(obj)
    return setmetatable(obj, TGetUserPasswordCompareInfoRsp)
end

function TGetUserPasswordCompareInfoRsp.new(CompletionCode, ManufactureId, CompareEnabled, CompareLength)
    return TGetUserPasswordCompareInfoRsp_from_obj({
        CompletionCode = CompletionCode,
        ManufactureId = ManufactureId,
        CompareEnabled = CompareEnabled,
        CompareLength = CompareLength
    })
end
---@param obj AccountIpmiCmds.GetUserPasswordCompareInfoRsp
function TGetUserPasswordCompareInfoRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
    self.CompareEnabled = obj.CompareEnabled
    self.CompareLength = obj.CompareLength
end

function TGetUserPasswordCompareInfoRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetUserPasswordCompareInfoRsp.group)
end

TGetUserPasswordCompareInfoRsp.from_obj = TGetUserPasswordCompareInfoRsp_from_obj

TGetUserPasswordCompareInfoRsp.proto_property = {'CompletionCode', 'ManufactureId', 'CompareEnabled', 'CompareLength'}

TGetUserPasswordCompareInfoRsp.default = {0, 0, 0, 0}

TGetUserPasswordCompareInfoRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil},
    {name = 'CompareEnabled', is_array = false, struct = nil}, {name = 'CompareLength', is_array = false, struct = nil}
}

function TGetUserPasswordCompareInfoRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'CompareEnabled', self.CompareEnabled, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'CompareLength', self.CompareLength, 'uint8', false, errs, need_convert)

    TGetUserPasswordCompareInfoRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetUserPasswordCompareInfoRsp.proto_property, errs, need_convert)
    return self
end

function TGetUserPasswordCompareInfoRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId, self.CompareEnabled, self.CompareLength
end

GetUserPasswordCompareInfo.GetUserPasswordCompareInfoRsp = TGetUserPasswordCompareInfoRsp

return GetUserPasswordCompareInfo
