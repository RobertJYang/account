-- Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
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
local mdb = require 'mc.mdb'
local skynet = require 'skynet'
local client = require 'iam.client'

local ACCOUNT_SERVICE_INTF = "bmc.kepler.AccountService"

local properties_listener_map = {
    ["HostUserManagementEnabled"] = true,
    ["InitialPasswordNeedModify"] = true
}

local account_service_cache_mdb = class()

function account_service_cache_mdb:ctor(bus, account_service_cache)
    self.bus = bus
    self.account_service_cache = account_service_cache
end

-- 信号监听（用户对象新增、删除、缓存属性变更）
function account_service_cache_mdb:init()
    self:signal_register()
    self:foreach_check_cache()
end

function account_service_cache_mdb:signal_register()
    client:OnAccountServiceInterfacesAdded(function(_, path, _)
        local ok, obj = pcall(mdb.get_object, self.bus, path, ACCOUNT_SERVICE_INTF)
        if ok and obj then
            self.account_service_cache:new_account_service_cache(obj)
        end
    end)

    client:OnAccountServicePropertiesChanged(function(properties)
        for k, v in pairs(properties) do
            if properties[k] and properties_listener_map[k] then
                self.account_service_cache:edit_account_service_cache(k, v:value())
            end
        end
    end)
end

function account_service_cache_mdb:foreach_check_cache()
    -- 每15分钟主动同步一次
    local TIME_INTERVAL = 15 * 60 * 100
    skynet.fork_loop({ count = 0 }, function()
        while true do
            self:sync_account_service_config_info()
            skynet.sleep(TIME_INTERVAL)
        end
    end)
end

function account_service_cache_mdb:sync_account_service_config_info()
    -- 1、清理同步状态（用于后续主动删除）
    self.account_service_cache:clear_cache_flush_state()

    -- 2、遍历当前对象属性
    local obj = client:GetAccountServiceAccountServiceObject()
    if not self.account_service_cache:get_account_service_cache() then
        self.account_service_cache:new_account_service_cache(obj)
    else
        self.account_service_cache:flush_account_service_cache(obj)
    end

    -- 3、根据同步状态进行主动删除
    self.account_service_cache:clean_redundant_cache()
end

return singleton(account_service_cache_mdb)