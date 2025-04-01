-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

local class = require 'mc.class'
local singleton = require 'mc.singleton'
local cjson = require 'cjson'
local file_utils = require 'utils.file'
local crypt = require 'utils.crypt'
local config = require 'common_config'
local config_mgmt = require 'interface.config_mgmt.config_mgmt'

local AccountProfile = require 'interface.config_mgmt.profile.account_profile'
local AccountServiceProfile = require 'interface.config_mgmt.profile.account_service_profile'

local ConfigDump = class(config_mgmt)

-- SNMP鉴权算法和算法Id的映射关系
local snmp_authentication_protocols_map = {
    [1] = 'MD5',
    [2] = 'SHA',
    [3] = 'SHA1',
    [4] = 'SHA256',
    [5] = 'SHA384',
    [6] = 'SHA512'
}

local function get_first_login_policy(self, account_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    return account:get_first_login_policy():value()
end

local function get_snmp_auth_protocol(self, account_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    return snmp_authentication_protocols_map[account.m_snmp_user_info_data.AuthenticationProtocol:value()]
end

local function get_host_user_management_enabled(self)
    return self.m_account_config:get_host_user_management_enabled()
end

local function get_weak_pwd(self)
    local file = file_utils.open_s(config.WEAK_PWDDICT_FILE_PATH, 'r')
    local data = ""
    if file then
        data = file:read('*a')
        file:close()
    end
    local result = crypt.sha_256(data)
    local hex = {}
    for i = 1, #result do
        table.insert(hex, string.format("%02X", string.byte(result, i)))
    end
    return table.concat(hex)
end

local function get_emergency_account(self)
    local account_id = AccountServiceProfile.get_emergency_account(self)
    if account_id == 0 then
        return ""
    else
        local account = self.m_account_collection:get_account_by_account_id(account_id)
        return account:get_user_name()
    end
end

local ConfigAdapter = {
    User = {
        isObjectArray = true,
        instance_ids = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 },
        Fields = {
            Id = AccountProfile.get_account_id,
            FirstLoginPolicy = get_first_login_policy,
            SnmpV3AuthProtocol = get_snmp_auth_protocol,
        }
    },
    SecurityEnhance = {
        PasswordValidityDays = AccountServiceProfile.get_max_password_valid_days,
        MinimumPasswordAgeDays = AccountServiceProfile.get_min_password_valid_days,
        PreviousPasswordsDisallowedCount = AccountServiceProfile.get_history_password_count,
        PasswordComplexityCheckEnabled = AccountServiceProfile.get_password_complexity_enable,
        MinPasswordLength = AccountServiceProfile.get_password_min_length,
        AccountInactiveTimelimit = AccountServiceProfile.get_inactive_time_threshold,
        OSUserManagementEnabled = get_host_user_management_enabled,
        EmergencyLoginUser = get_emergency_account,
        WeakPwdDict = get_weak_pwd,
    }
}

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

function ConfigDump:dump_instance(class_name, instance_ids, config)
    local result = cjson.json_object_new_object()
    local v_type, value, instance_name
    for _, id in pairs(instance_ids) do
        if not config.Id(self, id) then
            goto continue
        end
        instance_name = class_name .. id
        local tmp = cjson.json_object_new_object()
        for name, class in pairs(config) do
            v_type = type(class)
            if v_type == "function" then
                value = class(self, id)
            elseif v_type == "table" and class.isObjectArray then
                value = self:dump_instance(name, class.instance_ids, class.Fields)
            elseif v_type == "table" and not class.isObjectArray then
                value = self:handle_config(class)
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
    for name, class in pairs(config) do
        v_type = type(class)
        if v_type == "function" then
            value = class(self)
        elseif v_type == "table" and class.isObjectArray then
            value = self:dump_instance(name, class.instance_ids, class.Fields)
        elseif v_type == "table" and not class.isObjectArray then
            value = self:handle_config(class)
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