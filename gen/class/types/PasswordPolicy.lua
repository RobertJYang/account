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

local MPasswordPolicy = {}

---@class MPasswordPolicy.AccountType
---@field AccountType integer
local TAccountType = {}
TAccountType.__index = TAccountType
TAccountType.group = {}

local function TAccountType_from_obj(obj)
    return setmetatable(obj, TAccountType)
end

function TAccountType.new(AccountType)
    return TAccountType_from_obj({AccountType = AccountType})
end
---@param obj MPasswordPolicy.AccountType
function TAccountType:init_from_obj(obj)
    self.AccountType = obj.AccountType
end

function TAccountType:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccountType.group)
end

TAccountType.from_obj = TAccountType_from_obj

TAccountType.proto_property = {'AccountType'}

TAccountType.default = {0}

TAccountType.struct = {{name = 'AccountType', is_array = false, struct = nil}}

function TAccountType:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Required(prefix .. 'AccountType', self.AccountType, 'uint8', false, errs, need_convert)

    TAccountType:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccountType.proto_property, errs, need_convert)
    return self
end

function TAccountType:unpack(_)
    return self.AccountType
end

MPasswordPolicy.AccountType = TAccountType

return MPasswordPolicy
