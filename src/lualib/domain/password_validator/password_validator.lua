-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local class = require 'mc.class'
local custom_msg = require 'messages.custom'
local account_core = require 'account_core'

local PasswordValidator = class()

function PasswordValidator:ctor(policy, global_account_config)
    self.data             = policy
    self.m_account_config = global_account_config
end

function PasswordValidator:init()
    self.bit_func_map = {
        [0] = function(...)
            return self:basic_validate(...)
        end,
        [1] = function(...)
            return self:pattern_validate(...)
        end
    }
end

function PasswordValidator:get_obj()
    return self.data
end

function PasswordValidator:set_policy(value)
    self.data.Policy = value
    self.data:save()
end

function PasswordValidator:get_policy()
    return self.data.Policy
end

function PasswordValidator:set_pattern(value)
    if string.len(value) > 255 then
        error(custom_msg.StringValueTooLong("PasswordPattern", 255))
    end
    -- 仅在正则非空字符串的场景下进行校验
    if string.len(value) ~= 0 and not account_core.check_pattern(value) then
        error(custom_msg.InvalidValue(value, "PasswordPattern"))
    end

    self.data.Pattern = value
    self.data:save()
end

function PasswordValidator:get_pattern()
    return self.data.Pattern
end

function PasswordValidator:set_password_max_length(value)
    if value < self.m_password_max_length or value > 512 then
        log:error("invalid password max length(%s) for %s, acceptable values [%s, 512]",
            value, self.data.AccountTypeName, self.m_password_max_length)
        error(custom_msg.PropertyValueOutOfRange(value, 'MaxPasswordLength'))
    end

    self.data.MaxPasswordLength = value
    self.data:save()
end

function PasswordValidator:get_password_max_length()
    return self.data.MaxPasswordLength
end

function PasswordValidator:validate(info)
    -- Policy为U8的数据类型,最多支持右移7位
    for i = 0, 7 do
        if (self.data.Policy >> i) & 1 == 1 then
            self.bit_func_map[i](info)
        end
    end
end

function PasswordValidator:pattern_validate(info)
    if not self.m_account_config:get_password_complexity_enable() then
        return
    end

    if self.data.Pattern == "" or #self.data.Pattern == 0 then
        log:error("password regex failed because the pattern is null")
        error(custom_msg.PasswordPatternCheckFailed(self.data.Pattern))
    end
    local ok = account_core.verify_passwd_with_pattern(self.data.Pattern, info.password)
    if not ok then
        error(custom_msg.PasswordPatternCheckFailed(self.data.Pattern))
    end
end

return singleton(PasswordValidator)