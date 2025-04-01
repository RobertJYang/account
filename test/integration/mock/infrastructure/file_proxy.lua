-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local Singleton = require 'mc.singleton'
local vos = require 'utils.vos'
local utils_core = require 'utils.core'
local file_utils = require 'utils.file'

local file_proxy = class()

function file_proxy:ctor()
end

function file_proxy.proxy_create(dst_path, open_mode, file_mode, uid, gid)
    vos.system_s('touch ' .. dst_path)
    utils_core.chmod(dst_path, file_mode)
    utils_core.chown(dst_path, uid, gid)
    return true
end

function file_proxy.proxy_delete(dst_path)
    vos.system_s('rm ' .. dst_path)
    return true
end

function file_proxy.proxy_move(src_path, dst_path, uid, gid)
    file_utils.move_file_s(src_path, dst_path)
    return true
end

function file_proxy.proxy_chmod(dst_path, file_mode)
    utils_core.chmod(dst_path, file_mode)
    return true
end

function file_proxy.proxy_chown(dst_path, uid, gid)
    utils_core.chown(dst_path, uid, gid)
    return true
end

return Singleton(file_proxy)