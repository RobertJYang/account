-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local log = require 'mc.logging'
local class = require 'mc.class'
local Singleton = require 'mc.singleton'
local client = require 'account.client'

local file_proxy = class()

function file_proxy:ctor()
    self.last_time_map = {}
end

local function get_file_proxy_obj()
    local objs = client:GetFileObjects()
    for _, v in pairs(objs) do
        return v
    end
    log:error("get file proxy object failed")
    return nil
end

function file_proxy.proxy_create(dst_path, open_mode, file_mode, uid, gid)
    local file_obj = get_file_proxy_obj()
    if not file_obj then
        return false
    end

    local ok, err_info = pcall(function()
        file_obj:Create({}, dst_path, open_mode, file_mode, uid, gid)
    end)

    if not ok then
        log:error("Create failed, error is %s", err_info)
        return false
    end

    return true
end

function file_proxy.proxy_delete(dst_path)
    local file_obj = get_file_proxy_obj()
    if not file_obj then
        return false
    end

    local ok, err_info = pcall(function()
        file_obj:Delete({}, dst_path)
    end)

    if not ok then
        log:error("Delete failed, error is %s", err_info)
        return false
    end

    return true
end

function file_proxy.proxy_move(src_path, dst_path, uid, gid)
    local file_obj = get_file_proxy_obj()
    if not file_obj then
        return false
    end

    local ok, err_info = pcall(function()
        file_obj:Move({}, src_path, dst_path, uid, gid)
    end)

    if not ok then
        log:error("Move failed, error is %s", err_info)
        return false
    end

    return true
end

function file_proxy.proxy_copy(src_path, dst_path, uid, gid)
    local file_obj = get_file_proxy_obj()
    if not file_obj then
        return false
    end

    local ok, err_info = pcall(function()
        file_obj:Copy({}, src_path, dst_path, uid, gid)
    end)

    if not ok then
        log:error("Copy failed, error is %s", err_info)
        return false
    end

    return true
end

function file_proxy.proxy_chmod(dst_path, file_mode)
    local file_obj = get_file_proxy_obj()
    if not file_obj then
        return false
    end

    local ok, err_info = pcall(function()
        file_obj:Chmod({}, dst_path, file_mode)
    end)

    if not ok then
        log:error("Chmod failed, error is %s", err_info)
        return false
    end

    return true
end

function file_proxy.proxy_chown(dst_path, uid, gid)
    local file_obj = get_file_proxy_obj()
    if not file_obj then
        return false
    end

    local ok, err_info = pcall(function()
        file_obj:Chown({}, dst_path, uid, gid)
    end)

    if not ok then
        log:error("Chown failed, error is %s", err_info)
        return false
    end

    return true
end

return Singleton(file_proxy)