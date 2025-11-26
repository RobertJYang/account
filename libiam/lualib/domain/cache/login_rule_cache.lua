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
local user_config = require 'user_config'
local login_rule_manager_cache = require 'domain.cache.login_rule.login_rule_manager_cache'

local login_rule_cache = class()

function login_rule_cache:ctor()
    self.cache_collection = {}
end

function login_rule_cache:init()
    self.property_change_cb = {
        Enabled = function(...)
            return self:set_enabled(...)
        end,
        IpRule = function(...)
            return self:set_ip_rule(...)
        end,
        TimeRule = function(...)
            return self:set_time_rule(...)
        end,
        MacRule = function(...)
            return self:set_mac_rule(...)
        end
    }
end

function login_rule_cache:set_enabled(rule_id, value)
    self.cache_collection[rule_id]:set_enabled(value)
end

function login_rule_cache:set_ip_rule(rule_id, value)
    self.cache_collection[rule_id]:set_ip_rule(value)
end

function login_rule_cache:set_time_rule(rule_id, value)
    self.cache_collection[rule_id]:set_time_rule(value)
end

function login_rule_cache:set_mac_rule(rule_id, value)
    self.cache_collection[rule_id]:set_mac_rule(value)
end

function login_rule_cache:get_rule_by_id(rule_id)
    if not rule_id or not self.cache_collection[rule_id] then
        return nil
    end
    return self.cache_collection[rule_id]
end

-- 新增规则触发
function login_rule_cache:new_rule_cache(rule_id, obj)
    local rule = {
        Enabled = obj.Enabled,
        -- 资源树对外只会有一个IpRule
        IpRule = obj.IpRule,
        TimeRule = obj.TimeRule,
        MacRule = obj.MacRule,
        is_flush = true
    }
    self.cache_collection[rule_id] = login_rule_manager_cache.new(rule)
end

-- 删除规则触发
function login_rule_cache:del_rule_cache(rule_id)
    local rule = self.cache_collection[rule_id]
    rule.destroy()
    self.cache_collection[rule_id] = nil
end

-- 缓存属性变更触发
function login_rule_cache:edit_rule_cache(rule_id, property_name, property_value)
    if not self.cache_collection[rule_id] then
        return
    end
    local func = self.property_change_cb[property_name]
    pcall(func, rule_id, property_value)
end

-- 刷新规则的缓存信息
function login_rule_cache:flush_rule_cache(rule_id, obj)
    local rule = self.cache_collection[rule_id]
    self:set_enabled(rule_id, obj.Enabled)
    self:set_ip_rule(rule_id, obj.IpRule)
    self:set_time_rule(rule_id, obj.TimeRule)
    self:set_mac_rule(rule_id, obj.MacRule)
    rule.is_flush = true
end

-- 清理缓存的同步状态
function login_rule_cache:clear_cache_flush_state()
    local cache
    for k, _ in pairs(self.cache_collection) do
        cache = self.cache_collection[k]
        cache.is_flush = false
    end
end

-- 清理冗余的缓存（RULE对象已删除，但IAM未收到信号导致本地残留）
function login_rule_cache:clean_redundant_cache()
    local cache
    for k, _ in pairs(self.cache_collection) do
        cache = self.cache_collection[k]
        if not cache.is_flush then
            self.cache_collection[k] = nil
        end
    end
end

------- 以下为各依赖的基本使用（参考原login_rule_collection）
--- 根据login_rule_ids依次校验规则X
---@param login_rule_ids number
---@param ip string
function login_rule_cache:check_login_rule(login_rule_ids, ip)
    local ids = login_rule_ids and login_rule_ids or 0

    local rule
    local skip_num = 0
    for i = 1, user_config.LOGIN_RULE_COUNT do -- 最多使能3个登录规则
        -- 选择遍历该账户已配置的登陆规则
        if (ids >> (i - 1)) & 1 == 1 then
            rule = self.cache_collection[i]
            -- 若未使能，则跳过
            if not rule:get_enabled() then
                skip_num = skip_num + 1
                goto continue
            end
            -- 若单个规则已使能校验通过，直接通过
            if rule:check_login_rule(ip) then
                return true
            end
        else
            -- 对于未配置到用户的规则，直接跳过
            skip_num = skip_num + 1
        end
        ::continue::
    end

    -- 走到此处的场景：
    -- 1、全部登录规则未使能or未配置，被跳过了，对应 skip_num == user_config.LOGIN_RULE_COUNT
    -- 2、存在已使能且配置的规则，没有校验成功的，对应其他场景下的false
    return skip_num == user_config.LOGIN_RULE_COUNT
end

return singleton(login_rule_cache)