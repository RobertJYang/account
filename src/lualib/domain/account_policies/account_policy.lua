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
local config = require 'common_config'
local utils_core = require 'utils.core'
local account_core = require 'account_core'
local custom_msg = require 'messages.custom'
local enum = require 'class.types.types'
local base_msg = require 'messages.base'
local log = require 'mc.logging'
local utils = require 'infrastructure.utils'

local AccountPolicy = class()

function AccountPolicy:ctor(policy, global_account_config)
    self.data             = policy
    self.m_account_config = global_account_config
end

function AccountPolicy:get_obj()
    return self.data
end

function AccountPolicy:get_name_pattern()
    return self.data.NamePattern
end

function AccountPolicy:set_name_pattern(pattern)
    if string.len(pattern) > 255 then
        error(custom_msg.StringValueTooLong("NamePattern", 255))
    end
    if string.len(pattern) ~= 0 and not account_core.check_pattern(pattern) then
        error(custom_msg.InvalidValue(pattern, "NamePattern"))
    end
    self.data.NamePattern = pattern
    self.data:save()
end

function AccountPolicy:check_login_interface_is_allowed(login_interfaces)
    if login_interfaces == 'table' then
        login_interfaces = utils.cover_interface_str_to_num(login_interfaces)
    end
    if login_interfaces & self.data.AllowedLoginInterfaces ~= login_interfaces then
        return false
    end
    return true
end

function AccountPolicy:check_user_name(user_name)
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

function AccountPolicy:set_allowed_login_interfaces(interface_num)
    if interface_num <= 0 or interface_num == enum.LoginInterface.SFTP:value() then
        log:error('set allowed login interfaces failed, interfaces must contain at least one valid item except SFTP')
        error(custom_msg.ArrayPropertyInvalidItem('AllowedLoginInterfaces'))
    end
    if interface_num & config.DEFAULT_INTERFACES ~= interface_num then
        log:error('set allowed login interfaces failed, interfaces : %d not supported', interface_num)
        error(base_msg.PropertyValueNotInList(interface_num, "LoginInterface"))
    end
    self.data.AllowedLoginInterfaces = interface_num
    self.data:save()
end

function AccountPolicy:get_allowed_login_interfaces()
    return self.data.AllowedLoginInterfaces
end

function AccountPolicy:set_visible(value)
    self.data.Visible = value
    self.data:save()
end

function AccountPolicy:get_visible()
    return self.data.Visible
end

function AccountPolicy:set_deletable(value)
    self.data.Deletable = value
    self.data:save()
end

function AccountPolicy:get_deletable()
    return self.data.Deletable
end

return singleton(AccountPolicy)