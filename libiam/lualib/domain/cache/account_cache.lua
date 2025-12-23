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
local signal = require 'mc.signal'
local user_config = require 'user_config'
local log = require 'mc.logging'
local iam_enum = require 'class.types.types'

local account_cache = class()

function account_cache:ctor()
    self.cache_collection = {}
    self.m_account_removed = signal.new()
    self.m_account_security_changed = signal.new()
    self.m_account_refresh_by_id_username_signal = signal.new()
end

-- 新增用户触发
function account_cache:new_account_cache(account_id, obj)
    self.cache_collection[account_id] = {}
    self:flush_account_cache(account_id, obj)
end

-- 删除用户触发
function account_cache:del_account_cache(account_id)
    if not self.cache_collection[account_id] then
        return
    end
    local user_name = self.cache_collection[account_id].UserName
    self.cache_collection[account_id] = nil
    self.m_account_removed:emit(account_id, user_name)
end

-- 缓存属性变更触发
function account_cache:edit_account_cache(account_id, property_name, property_value)
    if not self.cache_collection[account_id] then
        return
    end
    local account_data = self.cache_collection[account_id]
    if account_data ~= nil then
        account_data[property_name] = property_value
    end
    if property_name == 'Privileges' then
        account_data['current_privileges'] = property_value
    end
end

-- 刷新用户的缓存信息
function account_cache:flush_account_cache(account_id, obj)
    local account_data = self.cache_collection[account_id]
    account_data.Id                 = obj.Id
    account_data.UserName           = obj.UserName
    account_data.RoleId             = obj.RoleId
    account_data.AccountType        = iam_enum.AccountType[obj.AccountType]
    account_data.LastLoginIP        = obj.LastLoginIP
    account_data.LastLoginTime      = obj.LastLoginTime
    account_data.current_privileges = obj.Privileges
    account_data.PasswordChangeRequired = obj.PasswordChangeRequired
    account_data.FirstLoginPolicy   = obj.FirstLoginPolicy
    account_data.is_flush = true
end

-- 清理缓存的同步状态
function account_cache:clear_cache_flush_state()
    local cache
    for k, _ in pairs(self.cache_collection) do
        cache = self.cache_collection[k]
        cache.is_flush = false
    end
end

-- 清理冗余的缓存（ACCOUNT对象已删除，但IAM未收到信号导致本地残留）
function account_cache:clean_redundant_cache()
    local cache
    for k, _ in pairs(self.cache_collection) do
        cache = self.cache_collection[k]
        if not cache.is_flush then
            self.cache_collection[k] = nil
        end
    end
end

-- 缓存中不存在用户信息时，重新刷新指定缓存数据
function account_cache:account_cache_refresh_by_account_id(account_id)
    log:error('account cache missing, account_id: %d', account_id)
    self.m_account_refresh_by_id_username_signal:emit(account_id, nil)
end

-- 缓存中不存在用户信息时，重新刷新指定缓存数据
function account_cache:account_cache_refresh_by_user_name(user_name)
    log:error('account cache missing, user_name: %s', user_name)
    self.m_account_refresh_by_id_username_signal:emit(nil, user_name)
end

------- 以下为各依赖的基本使用（参考原account_collection）
function account_cache:get_account_by_name(user_name)
    for id, cache in pairs(self.cache_collection) do
        if cache.UserName == user_name then
            return id, cache
        end
    end
    return nil
end

-- 获取指定用户的缓存
function account_cache:get_account_by_id(account_id)
    return self.cache_collection[account_id]
end

function account_cache:get_ipmi_account(user_name)
    local host_sms = self.cache_collection[user_config.USER_NAME_FOR_BMA_ID]
    if user_name == host_sms.UserName then
        return host_sms
    elseif user_name == user_config.USER_NAME_FOR_HMM then
        return {
            Id                       = user_config.USER_NAME_FOR_HMM_ID,
            UserName                 = user_config.USER_NAME_FOR_HMM,
            RoleId                   = 0,
            AccountType              = "",
            LastLoginIP              = "",
            LastLoginTime            = 0,
            current_privileges       = {}
        }
    else
        return nil
    end
end

return singleton(account_cache)