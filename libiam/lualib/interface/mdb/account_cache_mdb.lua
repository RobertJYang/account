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
local mdb_service = require 'mc.mdb.mdb_service'
local log = require 'mc.logging'
local skynet = require 'skynet'
local client = require 'iam.client'
local base_messages = require 'messages.base'

local MANAGER_ACCOUNT_INTF         = 'bmc.kepler.AccountService.ManagerAccount'
local MANAGER_ACCOUNT_PATH_PATTERN = '/bmc/kepler/AccountService/Accounts/(%d+)'
local MANAGER_ACCOUNT_PATH_BASE    = '/bmc/kepler/AccountService/Accounts/'

local properties_listener_map = {
    ['UserName'] = true,
    ['RoleId'] = true,
    ['LastLoginIP'] = true,
    ['LastLoginTime'] = true,
    ['Privileges'] = true,
    ['PasswordChangeRequired'] = true,
    ['FirstLoginPolicy'] = true
}

local security_config_map = {
    ['UserName'] = true,
    ['RoleId'] = true,
    ['Enabled'] = true,
    ['Locked'] = true,
    ['LoginInterface'] = true
}

local function get_manager_account_obj(account_id, user_name)
    if account_id == nil and user_name == nil then
        log:error('cannot found account obj when account id and user name is nil')
        error(base_messages.InternalError())
    end
    local objs = client:GetManagerAccountObjects()
    for path, obj in pairs(objs) do
        local mdb_path_id = tonumber(string.match(path or '', MANAGER_ACCOUNT_PATH_PATTERN))
        if account_id ~= nil and account_id == mdb_path_id then
            return obj
        elseif user_name ~= nil and obj.UserName == user_name then
            return obj
        end
    end
    log:error('get manager account obj failed, account_id: %s, user_name: %s',
        tostring(account_id), tostring(user_name))
end

local account_cache_mdb = class()

function account_cache_mdb:ctor(bus, account_cache, account_lock)
    self.bus = bus
    self.account_cache = account_cache
    self.account_lock = account_lock
end

-- 信号监听（用户对象新增、删除、缓存属性变更）
function account_cache_mdb:init()
    self:signal_register()
    self:foreach_check_account_cache()
    self:internal_signals_register()
end

function account_cache_mdb:signal_register()
    client:OnManagerAccountInterfacesAdded(function(_, path, _)
        local ok, account_obj = pcall(mdb.get_object, self.bus, path, MANAGER_ACCOUNT_INTF)
        local account_id = tonumber(string.match(path or '', MANAGER_ACCOUNT_PATH_PATTERN))
        log:notice("receive add account signal, account%s added", account_id)
        if ok and account_obj and account_id then
            self.account_cache:new_account_cache(account_id, account_obj)
        end
    end)

    client:OnManagerAccountInterfacesRemoved(function(_, path, _)
        local account_id = tonumber(string.match(path or '', MANAGER_ACCOUNT_PATH_PATTERN))
        log:notice("receive remove account signal, account%s removed", account_id)
        if account_id then
            self.account_cache:del_account_cache(account_id)
            self.account_lock:remove_lock_state(account_id)
        end
    end)

    client:OnManagerAccountPropertiesChanged(function(properties, path, _)
        local account_id = tonumber(string.match(path or '', MANAGER_ACCOUNT_PATH_PATTERN))
        if not account_id then
            return
        end

        local account = self.account_cache.cache_collection[account_id]
        if not account then
            return
        end
        local user_name
        for k, v in pairs(properties) do
            user_name = self.account_cache.cache_collection[account_id].UserName
            if properties[k] and properties_listener_map[k] then
                self.account_cache:edit_account_cache(account_id, k, v:value())
            end

            if properties[k] and security_config_map[k] then
                self.account_cache.m_account_security_changed:emit(account_id, user_name)
            end
        end
    end)
end

-- 注册从domain层来的内部信号
function account_cache_mdb:internal_signals_register()
    self.account_cache.m_account_refresh_by_id_username_signal:on(
        function(account_id, user_name)
            self:sync_account_info_by_id_username(account_id, user_name)
        end)
end

-- 刷新指定用户的信息，有用户id优先使用id，否则使用user_name
function account_cache_mdb:sync_account_info_by_id_username(account_id, user_name)
    local account_obj = get_manager_account_obj(account_id, user_name)
    if not account_obj then
        log:error('cannot found account when sync account info')
        return
    end
    local id = account_obj.Id
    if not self.account_cache:get_account_by_id(id) then
        self.account_cache:new_account_cache(id, account_obj)
    else
        self.account_cache:flush_account_cache(id, account_obj)
    end
end

function account_cache_mdb:foreach_check_account_cache()
    -- 每5分钟主动同步一次
    local TIME_INTERVAL = 5 * 60 * 100
    skynet.fork_loop({count = 0}, function()
        while true do
            self:sync_account_info()
            skynet.sleep(TIME_INTERVAL)
        end
    end)
end

local account_id_map = {
    {
        min_id = 18,
        max_id = 23
    },
    {
        min_id = 2,   -- 最小本地用户id：2
        max_id = 17   -- 最大本地用户id：17
    },
    {
        min_id = 101, -- 最小OEM用户id：101
        max_id = 115  -- 最大OEM用户id：105
    }
}

function account_cache_mdb:sync_obj(obj)
    if not self.account_cache:get_account_by_id(obj.Id) then
        self.account_cache:new_account_cache(obj.Id, obj)
    else
        self.account_cache:flush_account_cache(obj.Id, obj)
    end
end

function account_cache_mdb:sync_account_info()
    -- 1、清理同步状态（用于后续主动删除）
    self.account_cache:clear_cache_flush_state()

    -- 2、遍历当前所有用户对象
    local ok, obj, res
    local path_params = {}

    -- 按id分组顺序进行遍历
    for i = 1, 3 do
        for account_id = account_id_map[i].min_id, account_id_map[i].max_id do
            -- 判断路径无效时跳过获取对象的操作，提高同步效率
            res = mdb_service.is_valid_path(self.bus, MANAGER_ACCOUNT_PATH_BASE .. tostring(account_id), false)
            if not res.Result then
                goto continue
            end

            path_params.ManagerAccountId = account_id
            ok, obj = pcall(function()
                return client:GetManagerAccountManagerAccountObject(path_params)
            end)
            if ok and obj ~= nil then
                self:sync_obj(obj)
            end

            ::continue::
        end
    end

    -- 3、根据同步状态进行主动删除
    self.account_cache:clean_redundant_cache()
end

return singleton(account_cache_mdb)
