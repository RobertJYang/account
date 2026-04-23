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

local GetInitialPasswordPromptEnable = {}

---@class AccountIpmiCmds.GetInitialPasswordPromptEnableReq
---@field ManufactureId integer
---@field UserId integer
---@field Reserved1 integer
local TGetInitialPasswordPromptEnableReq = {}
TGetInitialPasswordPromptEnableReq.__index = TGetInitialPasswordPromptEnableReq
TGetInitialPasswordPromptEnableReq.group = {}

local function TGetInitialPasswordPromptEnableReq_from_obj(obj)
    return setmetatable(obj, TGetInitialPasswordPromptEnableReq)
end

function TGetInitialPasswordPromptEnableReq.new(ManufactureId, UserId, Reserved1)
    return TGetInitialPasswordPromptEnableReq_from_obj({
        ManufactureId = ManufactureId,
        UserId = UserId,
        Reserved1 = Reserved1
    })
end
---@param obj AccountIpmiCmds.GetInitialPasswordPromptEnableReq
function TGetInitialPasswordPromptEnableReq:init_from_obj(obj)
    self.ManufactureId = obj.ManufactureId
    self.UserId = obj.UserId
    self.Reserved1 = obj.Reserved1
end

function TGetInitialPasswordPromptEnableReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetInitialPasswordPromptEnableReq.group)
end

TGetInitialPasswordPromptEnableReq.from_obj = TGetInitialPasswordPromptEnableReq_from_obj

TGetInitialPasswordPromptEnableReq.proto_property = {'ManufactureId', 'UserId', 'Reserved1'}

TGetInitialPasswordPromptEnableReq.default = {0, 0, 0}

TGetInitialPasswordPromptEnableReq.struct = {
    {name = 'ManufactureId', is_array = false, struct = nil}, {name = 'UserId', is_array = false, struct = nil},
    {name = 'Reserved1', is_array = false, struct = nil}
}

function TGetInitialPasswordPromptEnableReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'UserId', self.UserId, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Reserved1', self.Reserved1, 'uint8', false, errs, need_convert)

    TGetInitialPasswordPromptEnableReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetInitialPasswordPromptEnableReq.proto_property, errs, need_convert)
    return self
end

function TGetInitialPasswordPromptEnableReq:unpack(_)
    return self.ManufactureId, self.UserId, self.Reserved1
end

GetInitialPasswordPromptEnable.GetInitialPasswordPromptEnableReq = TGetInitialPasswordPromptEnableReq

---@class AccountIpmiCmds.GetInitialPasswordPromptEnableRsp
---@field CompletionCode integer
---@field ManufactureId integer
---@field Length integer
---@field Data string
local TGetInitialPasswordPromptEnableRsp = {}
TGetInitialPasswordPromptEnableRsp.__index = TGetInitialPasswordPromptEnableRsp
TGetInitialPasswordPromptEnableRsp.group = {}

local function TGetInitialPasswordPromptEnableRsp_from_obj(obj)
    return setmetatable(obj, TGetInitialPasswordPromptEnableRsp)
end

function TGetInitialPasswordPromptEnableRsp.new(CompletionCode, ManufactureId, Length, Data)
    return TGetInitialPasswordPromptEnableRsp_from_obj({
        CompletionCode = CompletionCode,
        ManufactureId = ManufactureId,
        Length = Length,
        Data = Data
    })
end
---@param obj AccountIpmiCmds.GetInitialPasswordPromptEnableRsp
function TGetInitialPasswordPromptEnableRsp:init_from_obj(obj)
    self.CompletionCode = obj.CompletionCode
    self.ManufactureId = obj.ManufactureId
    self.Length = obj.Length
    self.Data = obj.Data
end

function TGetInitialPasswordPromptEnableRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetInitialPasswordPromptEnableRsp.group)
end

TGetInitialPasswordPromptEnableRsp.from_obj = TGetInitialPasswordPromptEnableRsp_from_obj

TGetInitialPasswordPromptEnableRsp.proto_property = {'CompletionCode', 'ManufactureId', 'Length', 'Data'}

TGetInitialPasswordPromptEnableRsp.default = {0, 0, 0, ''}

TGetInitialPasswordPromptEnableRsp.struct = {
    {name = 'CompletionCode', is_array = false, struct = nil}, {name = 'ManufactureId', is_array = false, struct = nil},
    {name = 'Length', is_array = false, struct = nil}, {name = 'Data', is_array = false, struct = nil}
}

function TGetInitialPasswordPromptEnableRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CompletionCode', self.CompletionCode, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ManufactureId', self.ManufactureId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Length', self.Length, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Data', self.Data, 'string', false, errs, need_convert)

    TGetInitialPasswordPromptEnableRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetInitialPasswordPromptEnableRsp.proto_property, errs, need_convert)
    return self
end

function TGetInitialPasswordPromptEnableRsp:unpack(_)
    return self.CompletionCode, self.ManufactureId, self.Length, self.Data
end

GetInitialPasswordPromptEnable.GetInitialPasswordPromptEnableRsp = TGetInitialPasswordPromptEnableRsp

return GetInitialPasswordPromptEnable
