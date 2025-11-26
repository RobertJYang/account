-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local utils = require 'utils'

-- 远程用户组所有支持的登录接口位运算结果为137
local DEFAULT_INTERFACES<const> = 137

local RemoteGroupsConfig = class()

function RemoteGroupsConfig:ctor(db)
    self.m_config = db:select(db.RemoteGroupsDB):first()
end

function RemoteGroupsConfig:get_allowed_login_interfaces()
    return self.m_config.AllowedLoginInterfaces
end

function RemoteGroupsConfig:set_allowed_login_interfaces(interface_num)
    if interface_num <= 0 then
        log:error('set allowed login interfaces failed, interfaces must contain at least one valid item')
        error(custom_msg.ArrayPropertyInvalidItem('AllowedLoginInterfaces'))
    end
    if interface_num & DEFAULT_INTERFACES ~= interface_num then
        log:error('set allowed login interfaces failed, interfaces : %d not supported', interface_num)
        error(base_msg.PropertyValueNotInList(interface_num, "LoginInterface"))
    end
    self.m_config.AllowedLoginInterfaces = interface_num
    self.m_config:save()
end

function RemoteGroupsConfig:check_login_interface_is_allowed(login_interfaces)
    if login_interfaces == 'table' then
        login_interfaces = utils.cover_interface_str_to_num(login_interfaces)
    end
    if login_interfaces & self.m_config.AllowedLoginInterfaces ~= login_interfaces then
        return false
    end
    return true
end

return singleton(RemoteGroupsConfig)