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
local enum = require 'class.types.types'

local LOGIN_RULE_INTF = "bmc.kepler.AccountService.Rule"
local LOGIN_RULE_PATH_PATTERN = "/bmc/kepler/AccountService/Rules/(%d+)"

local properties_listener_map = {
    ["Enabled"] = true,
    ["TimeRule"] = true,
    ["IpRule"] = true,
    ["MacRule"] = true
}

local login_rule_cache_mdb = class()

function login_rule_cache_mdb:ctor(bus, login_rule_cache)
    self.bus = bus
    self.login_rule_cache = login_rule_cache
end

-- 信号监听（用户对象新增、删除、缓存属性变更）
function login_rule_cache_mdb:init()
    self:signal_register()
    self:foreach_check_login_rule_cache()
end

function login_rule_cache_mdb:signal_register()
    client:OnRuleInterfacesAdded(function(_, path, _)
        local ok, obj = pcall(mdb.get_object, self.bus, path, LOGIN_RULE_INTF)
        local id = tonumber(string.match(path or '', LOGIN_RULE_PATH_PATTERN))
        if ok and obj and id then
            self.login_rule_cache:new_rule_cache(id, obj)
        end
    end)

    client:OnRuleInterfacesRemoved(function(_, path, _)
        local rule_id = tonumber(string.match(path or '', LOGIN_RULE_PATH_PATTERN))
        if rule_id then
            self.login_rule_cache:del_rule_cache(rule_id)
        end
    end)

    client:OnRulePropertiesChanged(function(properties, path, _)
        local rule_id = tonumber(string.match(path or '', LOGIN_RULE_PATH_PATTERN))
        if not rule_id then
            return
        end

        for k, v in pairs(properties) do
            if properties_listener_map[k] then
                self.login_rule_cache:edit_rule_cache(rule_id, k, v:value())
            end
        end
    end)
end

function login_rule_cache_mdb:foreach_check_login_rule_cache()
    -- 每5分钟主动同步一次
    local TIME_INTERVAL = 5 * 60 * 100
    skynet.fork_loop({ count = 0 }, function()
        while true do
            self:sync_rule_info()
            skynet.sleep(TIME_INTERVAL)
        end
    end)
end

function login_rule_cache_mdb:sync_rule_info()
    -- 1、清理同步状态（用于后续主动删除）
    self.login_rule_cache:clear_cache_flush_state()

    -- 2、遍历当前所有登录规则对象
    local ok, obj
    local path_params = {}
    local rule_id
    for mdb_rule_id = enum.LoginRuleIds.Rule1:value(), enum.LoginRuleIds.Rule3:value() do
        path_params.RuleId = mdb_rule_id
        ok, obj = pcall(function()
            return client:GetRuleRuleObject(path_params)
        end)
        if ok and obj ~= nil then
            rule_id = tonumber(string.match(obj.path or '', LOGIN_RULE_PATH_PATTERN))
            if not self.login_rule_cache:get_rule_by_id(rule_id) then
                self.login_rule_cache:new_rule_cache(rule_id, obj)
            else
                self.login_rule_cache:flush_rule_cache(rule_id, obj)
            end
        end
    end

    -- 3、根据同步状态进行主动删除
    self.login_rule_cache:clean_redundant_cache()
end

return singleton(login_rule_cache_mdb)