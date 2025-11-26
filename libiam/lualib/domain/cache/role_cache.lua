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

local role_cache = class()

function role_cache:ctor()
    self.cache_collection = {}
    self.m_privilege_update_signal = signal.new()
end

-- 新增角色触发
function role_cache:new_role_cache(role_id, obj)
    self.cache_collection[role_id] = {}
    local role = self.cache_collection[role_id]
    role.Name = obj.Name
    role.RolePrivilege = obj.RolePrivilege
    role.is_flush = true
end

-- 删除角色触发
function role_cache:del_role_cache(role_id)
    self.cache_collection[role_id] = nil
end

-- 缓存属性变更触发
function role_cache:edit_role_cache(role_id, property_name, property_value)
    if not self.cache_collection[role_id] then
        return
    end
    local role = self.cache_collection[role_id]
    if role ~= nil then
        role[property_name] = property_value
    end
end

-- 刷新用户的缓存信息
function role_cache:flush_role_cache(role_id, obj)
    local role = self.cache_collection[role_id]
    role.Name = obj.Name
    role.RolePrivilege = obj.RolePrivilege
    role.is_flush = true
end

-- 清理缓存的同步状态
function role_cache:clear_cache_flush_state()
    local cache
    for k, _ in pairs(self.cache_collection) do
        cache = self.cache_collection[k]
        cache.is_flush = false
    end
end

-- 清理冗余的缓存（ROLE对象已删除，但IAM未收到信号导致本地残留）
function role_cache:clean_redundant_cache()
    local cache
    for k, _ in pairs(self.cache_collection) do
        cache = self.cache_collection[k]
        if not cache.is_flush then
            self.cache_collection[k] = nil
        end
    end
end

------- 以下为各依赖的基本使用（参考原role）
-- 获取role的缓存
function role_cache:get_role_name_by_id(role_id)
    if not self.cache_collection[role_id] then
        return nil
    end
    return self.cache_collection[role_id].Name
end

function role_cache:get_role_data_by_id(role_id)
    if not self.cache_collection[role_id] then
        return nil
    end
    return self.cache_collection[role_id]
end

function role_cache:role_to_string_table(ids)
    local res = {}
    if type(ids) ~= 'table' then
        res[1] = self:get_role_data_by_id(ids).Name
    else
        for _, v in ipairs(ids) do
            table.insert(res, self:get_role_data_by_id(v).Name)
        end
    end
    return res
end

return singleton(role_cache)