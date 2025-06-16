-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local custom_msg = require 'messages.custom'
local password_validator = require 'domain.password_validator.password_validator'
local core = require 'account_core'

local VncPasswordValidator = class(password_validator)

function VncPasswordValidator:basic_validate(info)
    if not self.m_account_config:get_password_complexity_enable() then
        return
    end

    local result = core.is_vnc_password_complexity_check_pass(info.password)
    if not result then
        error(custom_msg.PasswordComplexityCheckFail())
    end
end

return singleton(VncPasswordValidator)