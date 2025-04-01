-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local custom_msg = require 'messages.custom'
local config = require 'common_config'
local password_validator = require 'domain.password_validator.password_validator'
local core = require 'account_core'

local LocalPasswordValidator = class(password_validator)

function LocalPasswordValidator:basic_validate(info)
    if not self.m_account_config:get_password_complexity_enable() then
        return
    end

    local user_name = info.username
    local password  = info.password
    local min_password_length = self.m_account_config:get_password_min_length()
    if not core.is_pass_complexity_check_pass(user_name, password, min_password_length) then
        log:error('The password does not meet the password complexity')
        error(custom_msg.PasswordComplexityCheckFail())
    end
    local compare_enabled = self.m_account_config:get_user_name_password_compared_enabled()
    if not compare_enabled then
        return
    end
    local compare_length = self.m_account_config:get_user_name_password_compared_length()
    local name_length = #user_name
    if name_length < config.USERNAME_PWD_COMPARE_DEFAULT_LEN then
        log:notice('Length of username(%s) is too short, skip username-password compare', user_name)
        return
    end
    compare_length = (name_length < compare_length) and name_length or compare_length
    if string.sub(password, 1, compare_length) == string.sub(user_name, 1, compare_length) then
        log:error('The password and username(%s) are identical in the first %d bytes', user_name, compare_length)
        error(custom_msg.PasswordComplexityCheckFail())
    end
end

return singleton(LocalPasswordValidator)