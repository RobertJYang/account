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
local signal = require 'mc.signal'
local config = require 'common_config'
local utils_core = require 'utils.core'
local account_core = require 'account_core'
local custom_msg = require 'messages.custom'

local local_account_policy = class()

function local_account_policy:ctor(db)
    self.m_db_local_account_policy = db:select(db.AccountPolicy):first()
    self.m_config_changed = signal.new()
end

function local_account_policy:get_name_pattern()
    return self.m_db_local_account_policy.NamePattern
end

function local_account_policy:set_name_pattern(pattern)
    if string.len(pattern) > 255 then
        error(custom_msg.StringValueTooLong("NamePattern", 255))
    end
    if string.len(pattern) ~= 0 and not account_core.check_pattern(pattern) then
        error(custom_msg.InvalidValue(pattern, "NamePattern"))
    end
    self.m_db_local_account_policy.NamePattern = pattern
    self.m_db_local_account_policy:save()
end

function local_account_policy:check_user_name(user_name)
    local check_config = self:get_name_pattern()
    if check_config == "" then
        check_config = "^(?!.*[<>&,'/\\%:\" ])(?=[A-Za-z0-9`~!@#$%^&*()_+-={};[\\]?.|])" ..
            "(?!#)(?!\\+)(?!-)([A-Za-z0-9`~!@#$%^&*()_+-={};[\\]?.|]{1,16})(?!((\r?\n|(?<!\n)\r)|\f))$"
    end

    if user_name == config.ACTUAL_ROOT_USER_NAME then
        return true
    end
    if user_name == '.' or user_name == '..' then -- 用户名不能为.或..
        return false
    end
    for _, reserved_user_name in pairs(config.APP_USERS) do
        if user_name == reserved_user_name.name then
            return false
        end
    end

    return utils_core.g_regex_match(check_config, user_name)
end

return singleton(local_account_policy)