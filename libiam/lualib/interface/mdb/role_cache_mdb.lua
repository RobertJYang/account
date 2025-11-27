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
local skynet = require 'skynet'
local client = require 'iam.client'
local enum = require 'class.types.types'
local remote_group_collection = require 'domain.remote_group.remote_group_collection'

local ROLE_INTF         = "bmc.kepler.AccountService.Role"
local ROLE_PATH_PATTERN = "/bmc/kepler/AccountService/Roles/(%d+)"
local ROLE_PATH_BASE    = "/bmc/kepler/AccountService/Roles/"

local properties_listener_map = {
    ["RolePrivilege"] = true
}

local role_cache_mdb = class()

function role_cache_mdb:ctor(bus, role_cache)
    self.bus = bus
    self.role_cache = role_cache
end

-- 信号监听（用户对象新增、删除、缓存属性变更）
function role_cache_mdb:init()
    self:signal_register()
    self:foreach_check_cache()
end

function role_cache_mdb:signal_register()
    client:OnRoleInterfacesAdded(function(_, path, _)
        local ok, obj = pcall(mdb.get_object, self.bus, path, ROLE_INTF)
        local role_id = tonumber(string.match(path or '', ROLE_PATH_PATTERN))
        if ok and obj and role_id then
            self.role_cache:new_role_cache(role_id, obj)
        end
    end)

    client:OnRoleInterfacesRemoved(function(_, path, _)
        local role_id = tonumber(string.match(path or '', ROLE_PATH_PATTERN))
        if role_id then
            self.role_cache:del_role_cache(role_id)
        end
        -- 扩展自定义角色被删除时需更新对应远程用户组角色
        if role_id > enum.RoleType.CustomRole4:value() then
            if not self.remote_group_collection then
                self.remote_group_collection = remote_group_collection.get_instance()
            end
            self.remote_group_collection:update_privilege(role_id)
        end
    end)

    client:OnRolePropertiesChanged(function(properties, path, _)
        local role_id = tonumber(string.match(path or '', ROLE_PATH_PATTERN))
        if not role_id then
            return
        end
        for k, v in pairs(properties) do
            if properties[k] and properties_listener_map[k] then
                self.role_cache:edit_role_cache(role_id, k, v:value())
            end
        end
    end)
end

function role_cache_mdb:foreach_check_cache()
    -- 每5分钟主动同步一次
    local TIME_INTERVAL = 5 * 60 * 100
    skynet.fork_loop({ count = 0 }, function()
        while true do
            self:sync_role_info()
            skynet.sleep(TIME_INTERVAL)
        end
    end)
end

function role_cache_mdb:sync_obj(obj)
    local role_id = tonumber(string.match(obj.path or '', ROLE_PATH_PATTERN))
    if not self.role_cache:get_role_data_by_id(role_id) then
        self.role_cache:new_role_cache(role_id, obj)
    else
        self.role_cache:flush_role_cache(role_id, obj)
    end
end

function role_cache_mdb:sync_role_info()
    -- 1、清理同步状态（用于后续主动删除）
    self.role_cache:clear_cache_flush_state()

    -- 2、遍历当前对象属性
    local ok, obj, res
    local path
    local path_params = {}
    for mdb_role_id = enum.RoleType.NoAccess:value(), enum.RoleType.CustomRole16:value() do
        -- 判断路径无效时跳过获取对象的操作，提高同步效率
        path = ROLE_PATH_BASE .. tostring(mdb_role_id)
        res = mdb_service.is_valid_path(self.bus, path, false)
        if not res.Result then
            goto continue
        end

        path_params.Id = mdb_role_id
        ok, obj = pcall(function()
            return client:GetRoleRoleObject(path_params)
        end)
        if ok and obj ~= nil then
            self:sync_obj(obj)
        end

        ::continue::
    end

    -- 3、根据同步状态进行主动删除
    self.role_cache:clean_redundant_cache()
end

return singleton(role_cache_mdb)