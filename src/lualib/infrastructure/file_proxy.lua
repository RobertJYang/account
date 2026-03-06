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
local base_msg = require 'messages.base'
local Singleton = require 'mc.singleton'
local client = require 'account.client'
local context = require 'mc.context'
local utils_core = require 'utils.core'
local vos = require 'utils.vos'
local file_utils = require 'utils.file'
local account_utils = require 'infrastructure.utils'
local config = require 'common_config'

local FILE_OBJ_PATH<const> = '/bmc/kepler/Managers/1/Security/File'

local file_proxy = {}
file_proxy.has_cap_dac = account_utils.check_cap_dac_override_supported(config.OM_CONFIG_PATH)

local function get_file_proxy_obj()
    local objs = client:GetFileObjects()
    if objs[FILE_OBJ_PATH] then
        return objs[FILE_OBJ_PATH]
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
    -- 有特权直接执行命令
    if file_proxy.has_cap_dac then
        file_utils.move_file_s(src_path, dst_path)
        utils_core.chown_s(dst_path, uid, gid)
        return true
    end
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
    -- 有特权直接执行命令
    if file_proxy.has_cap_dac then
        file_utils.copy_file_s(src_path, dst_path)
        utils_core.chown_s(dst_path, uid, gid)
        return true
    end
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

function file_proxy.proxy_ispermitted(dst_path, permission)
    local file_obj = get_file_proxy_obj()
    if not file_obj then
        return false
    end
    local ctx = context.get_context()
    local ok, result = pcall(function()
        return file_obj:IsPermitted(ctx, dst_path, permission)
    end)
    if not ok or not result then
        log:error("Permit check failed")
        return false
    end

    return true
end

function file_proxy.proxy_access(dst_path, mode)
    -- 有特权直接执行命令
    if file_proxy.has_cap_dac then
        return vos.get_file_accessible(dst_path)
    end
    local file_obj = get_file_proxy_obj()
    if not file_obj then
        return false
    end
    local ctx = context.get_context()
    local ok, result = pcall(function()
        return file_obj:Access(ctx, dst_path, mode)
    end)
    if not ok then
        log:error("Access check failed")
        error(base_msg.InternalError())
    end

    return result
end

function file_proxy.proxy_mkdir(dst_path, dir_mod, uid, gid)
    -- 有特权直接执行命令
    if file_proxy.has_cap_dac then
        utils_core.mkdir(dst_path, dir_mod)
        utils_core.chown_s(dst_path, uid, gid)
        return true
    end

    local file_obj = get_file_proxy_obj()
    if not file_obj then
        return false
    end

    local ok, err_info = pcall(function()
        file_obj:Mkdir({}, dst_path, dir_mod, uid, gid)
    end)

    if not ok then
        log:error("Mkdir failed, error is %s", err_info)
        return false
    end

    return true
end

return file_proxy