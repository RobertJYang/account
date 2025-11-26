-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at =  http =  //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN AS IS BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.

local class = require 'mc.class'
local singleton = require 'mc.singleton'
local cjson = require 'cjson'
local config_mgmt = require 'interface.config_mgmt.config_mgmt'

local AccountServiceProfile = require 'interface.config_mgmt.profile.account_service_profile'
local SessionServiceProfile = require 'interface.config_mgmt.profile.session_service_profile'
local LdapControllerProfile = require 'interface.config_mgmt.profile.ldap_controller_profile'
local LdapConfigProfile = require 'interface.config_mgmt.profile.ldap_config_profile'

local ConfigDump = class(config_mgmt)

local function get_ldap_controller_service_enabled(self)
    local enabled = LdapConfigProfile.get_ldap_enabled(self)
    if enabled then
        return 1
    else
        return 0
    end
end

local function get_ldap_controller_cert_verify_enabled(self, controller_id)
    local enabled = LdapControllerProfile.get_ldap_controller_cert_verify_enabled(self, controller_id)
    if enabled then
        return 1
    else
        return 0
    end
end

local function get_ldap_controller_cert_verify_level(self, controller_id)
    local level = LdapControllerProfile.get_ldap_controller_cert_verify_level(self, controller_id)
    if level == 2 then
        return 'Demand'
    elseif level == 3 then
        return 'Allow'
    else
        return ''
    end
end

local function get_cli_session_timeout(self)
    return SessionServiceProfile.get_cli_session_timeout(self) // 60
end

local function get_web_timeout(self)
    return SessionServiceProfile.get_web_timeout(self) // 60
end

local function json_sort(json_obj)
    local sort_keys = cjson.json_object_get_keys(json_obj)
    table.sort(sort_keys, function(a, b)
        return a < b
    end)
    local json_result = cjson.json_object_new_object()
    for _, value in ipairs(sort_keys) do
        json_result[value] = json_obj[value]
    end

    return json_result
end

local ConfigAdapter = {
    AccountLockoutThreshold = AccountServiceProfile.get_account_lockout_threshold,
    AccountLockoutDuration = AccountServiceProfile.get_account_lockout_duration,
    Session = {
        CliTimeoutMinutes = get_cli_session_timeout,
        SessionTimeout = SessionServiceProfile.get_redfish_session_timeout,
        WebSessionTimeoutMinutes = get_web_timeout
    },
    LdapServiceEnabled = get_ldap_controller_service_enabled,
    LdapController = {
        isObjectArray = true,
        instance_ids = { 1, 2, 3, 4, 5, 6 },
        Fields = {
            Id = LdapControllerProfile.get_ldap_controller_id,
            CertificateVerificationEnabled = get_ldap_controller_cert_verify_enabled,
            CertificateVerificationLevel = get_ldap_controller_cert_verify_level
        }
    }
}

function ConfigDump:dump_instance(class_name, instance_ids, config)
    local result = cjson.json_object_new_object()
    local v_type, value, instance_name
    for _, id in pairs(instance_ids) do
        if not config.Id(self, id) then
            goto continue
        end
        instance_name = class_name .. id
        local tmp = cjson.json_object_new_object()
        for name, config_class in pairs(config) do
            v_type = type(config_class)
            if v_type == "function" then
                value = config_class(self, id)
            elseif v_type == "table" and config_class.isObjectArray then
                value = self:dump_instance(name, config_class.instance_ids, config_class.Fields)
            elseif v_type == "table" and not config_class.isObjectArray then
                value = self:handle_config(config_class)
            else
                value = value
            end
            tmp[name] = value
        end
        result[instance_name] = json_sort(tmp)
        ::continue::
    end

    return json_sort(result)
end

function ConfigDump:handle_config(config)
    local result = cjson.json_object_new_object()
    local v_type, value
    for name, config_class in pairs(config) do
        v_type = type(config_class)
        if v_type == "function" then
            value = config_class(self)
        elseif v_type == "table" and config_class.isObjectArray then
            value = self:dump_instance(name, config_class.instance_ids, config_class.Fields)
        elseif v_type == "table" and not config_class.isObjectArray then
            value = self:handle_config(config_class)
        else
            value = value
        end
        result[name] = value
    end
    return json_sort(result)
end

function ConfigDump:dump(ctx)
    return self:handle_config(ConfigAdapter)
end

return singleton(ConfigDump)