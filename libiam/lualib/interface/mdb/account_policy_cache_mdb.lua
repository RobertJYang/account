-- Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
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
local client = require 'iam.client'
local enum = require 'class.types.types'

local ACCOUNT_POLICY_PATH_PATTERN = '/bmc/kepler/AccountService/Accounts/(%w+)'

local properties_listener_map = {
    ["Visible"] = true
}

local account_type_name_map = {
    [enum.AccountType.Local] = 'Local',
    [enum.AccountType.OEM] = 'OemAccount',
    [enum.AccountType.InterChassis] = 'InterChassis'
}

local account_policy_cache_mdb = class()

function account_policy_cache_mdb:ctor()
    self.cache = {
        Local = {},
        OemAccount = {},
        InterChassis = {}
    }
end

-- 信号监听（用户对象新增、删除、缓存属性变更）
function account_policy_cache_mdb:init()
    self:signal_register()
    -- 主动拿一次，避免account先启动
    self:sync_account_policy()
end

function account_policy_cache_mdb:signal_register()
    client:OnAccountPolicyPropertiesChanged(function(properties, path, _)
        local account_type = string.match(path or '', ACCOUNT_POLICY_PATH_PATTERN)
        if not account_type then
            return
        end

        local account_policy = self.cache[account_type]
        if not account_policy then
            return
        end
        for k, v in pairs(properties) do
            if properties[k] and properties_listener_map[k] then
                account_policy[k] = v:value()
            end
        end
    end)
end

function account_policy_cache_mdb:sync_account_policy()
    local ok, account_policy
    local path_params = {}
    for _, account_type_mdb in pairs(account_type_name_map) do
        path_params.AccountType = account_type_mdb
        ok, account_policy = pcall(function()
            return client:GetAccountPolicyAccountPolicyObject(path_params)
        end)
        if ok and account_policy ~= nil then
            self.cache[account_type_mdb]['Visible'] = account_policy.Visible
        end
    end
end


-- 缓存属性变更触发
function account_policy_cache_mdb:get_visible(account_type)
    local account_type_mdb = account_type_name_map[account_type]
    if not account_type_mdb or not self.cache[account_type_mdb] then
        return nil
    end

    return self.cache[account_type_mdb]['Visible']
end

return singleton(account_policy_cache_mdb)