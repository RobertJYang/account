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

local MRoles = {}

---@class MRoles.Id
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
---@param obj MRoles.Id
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

MRoles.Id = TId

return MRoles
