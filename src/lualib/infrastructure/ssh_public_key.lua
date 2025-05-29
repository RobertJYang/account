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
local mc_utils = require 'mc.utils'
local log = require 'mc.logging'
local file_utils = require 'utils.file'
local utils_core = require 'utils.core'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local config = require 'common_config'
local file_proxy = require 'infrastructure.file_proxy'

local ssh_publickey = class()

local function get_ssh_keygen_command_path()
    local ssh_keygen = '/usr/sbin/ssh-keygen'
    if file_utils.check_real_path_s(ssh_keygen) ~= 0 then
        ssh_keygen = '/usr/bin/ssh-keygen'
    end
    return ssh_keygen
end

--- 生成openssh格式公钥
---@param src_path string
---@param dest_path string
function ssh_publickey.generate_openssh_format_public_key(src_path, dest_path)
    if src_path ~= config.SSH_PUBLIC_KEY_PARSE_PATH then
        if file_utils.check_real_path_s(src_path, config.TMP_PATH) ~= 0 then
            log:error('File should be in the tmp path')
            error(base_msg.PropertyValueFormatError('******', 'Path'))
        end
        -- 转移到内部路径
        mc_utils.remove_file(config.SSH_PUBLIC_KEY_PARSE_PATH)
        file_utils.move_file_s(src_path, config.SSH_PUBLIC_KEY_PARSE_PATH)
        mc_utils.remove_file(src_path)
        src_path = config.SSH_PUBLIC_KEY_PARSE_PATH
    end

    if file_utils.check_shell_special_character_s(src_path) ~= 0 then
        log:error('ssh publickey path check shell special character failed')
        mc_utils.remove_file(src_path)
        error(base_msg.PropertyValueFormatError('******', 'Path'))
    end

    local key_file = file_utils.open_s(src_path, 'r')
    if not key_file then
        log:error('open public key file failed')
        error(custom_msg.PublicKeyImportFailed())
    end
    local key_content = key_file:read('*a')
    key_file:close()

    if string.find(key_content, config.SSH_PUBLIC_KEY_RFC4716_HEADER) then
        local cmd = { get_ssh_keygen_command_path(), '-i', '-f', src_path, '>', dest_path }
        local ok = pcall(os.execute, table.concat(cmd, ' '))
        if not ok then
            log:error('generate openssh format publickey failed')
            error(custom_msg.PublicKeyImportFailed())
        end
        return
    end
    file_utils.copy_file_s(src_path, dest_path)
end

--- 根据SSH公钥获取hash值
---@param key_path string
---@param hash_path string
function ssh_publickey.generate_public_key_hash(key_path, hash_path)
    if file_utils.check_real_path_s(key_path) ~= 0 then
        error(custom_msg.PublicKeyImportFailed())
    end
    local cmd = { get_ssh_keygen_command_path(), '-l', '-E', 'SHA256', '-f', key_path, '>', hash_path }
    local ok = pcall(os.execute, table.concat(cmd, ' '))
    if not ok then
        log:error('generate publickey hash failed')
        error(custom_msg.PublicKeyImportFailed())
    end
    local hash_file = file_utils.open_s(hash_path, 'r')
    if not hash_file then
        log:error('open hash file failed')
        error(custom_msg.PublicKeyImportFailed())
    end
    local hash_content = hash_file:read('*a')
    hash_file:close()
    local key_length, _, hash_value = string.match(hash_content, '^(%d+)%s(%w+):([^%s]+)%s')
    local get_key_type_ok, key_type = pcall(file_utils.read_file_s, key_path, 7)
    if not get_key_type_ok then
        log:error('get key type failed, content too short.')
        error(custom_msg.PublicKeyImportFailed())
    end
    -- 支持DSA密钥长度2048位；RSA密钥长度2048、4096位
    if key_type == config.SSH_PUBLIC_KEY_DSA_HEADER then
        if tonumber(key_length) ~= 2048 then
            log:error('generate publickey hash failed, key length is wrong')
            error(custom_msg.PublicKeyImportFailed())
        end
    elseif key_type == config.SSH_PUBLIC_KEY_RSA_HEADER then
        if tonumber(key_length) ~= 2048 and tonumber(key_length) ~= 4096 then
            log:error('generate publickey hash failed, key length is wrong')
            error(custom_msg.PublicKeyImportFailed())
        end
    else
        log:error('generate publickey hash failed, key type is wrong')
        error(custom_msg.PublicKeyImportFailed())
    end

    return hash_value
end

--- 在用户根目录下生成公钥文件
---@param key_path string
---@param home_path string
---@param uid number
---@param gid number
function ssh_publickey.generate_authentication_public_key_file(key_path, home_path, uid, gid)
    if file_utils.check_real_path_s(key_path) ~= 0 then
        log:error('path must be file path')
        error(custom_msg.PublicKeyImportFailed())
    end

    -- .ssh与/data/trust/home拼接
    local ssh_dir_path = table.concat({ home_path, config.SSH_PUBLIC_KEY_SUB_DIR_NAME }, '/')
    utils_core.mkdir(ssh_dir_path, mc_utils.S_IRWXU)
    file_proxy.proxy_chown(ssh_dir_path, uid, gid)
    file_proxy.proxy_chmod(ssh_dir_path, mc_utils.S_IRWXU)

    local auth_file_path = ssh_dir_path .. '/authorized_keys'
    file_utils.copy_file_s(key_path, auth_file_path)
    file_proxy.proxy_chown(auth_file_path, uid, gid)
    file_proxy.proxy_chmod(auth_file_path, mc_utils.S_IRUSR | mc_utils.S_IWUSR)
end

function ssh_publickey.parse_content_with_type(user_name, type, content)
    -- 若是URI类型则校验文件格式
    if type == "URI" then
        -- 本地文件路径场景，若非/tmp目录下，直接抛出失败，不能删除文件
        if string.sub(content, 1, 1) == '/' and
            file_utils.check_realpath_before_open_s(content, config.TMP_PATH) ~= 0 then
            log:error("invalid local file path")
            error(base_msg.PropertyValueFormatError('******', 'Content'))
        end

        -- 走到这里的只会是本地/tmp路径或者远程路径
        if string.sub(content, -4) ~= '.pub' or (string.sub(content, 1, 1) ~= '/' and #content > 1000) then
            -- 仅判断为文件时才删除
            if utils_core.is_file(content) then
                mc_utils.remove_file(content)
            end
            error(base_msg.PropertyValueFormatError('******', 'Content'))
        end
        return content
    end

    local ok, uid, gid = pcall(utils_core.get_uid_gid_by_name, user_name)
    if not ok then
        log:error("get %s uid gid failed", user_name)
        uid = config.APACHE_UID
        gid = config.APACHE_GID
    end

    -- text类型先在本地生成文件
    mc_utils.remove_file(config.SSH_PUBLIC_KEY_PARSE_PATH)
    local ret = file_utils.check_realpath_before_open_s(config.SSH_PUBLIC_KEY_PARSE_PATH, config.SHM_PATH)
    if ret ~= 0 then
        log:error('the file path is invalid.')
        error(base_msg.PropertyValueFormatError('******', 'Content'))
    end

    local file = file_utils.open_s(config.SSH_PUBLIC_KEY_PARSE_PATH, 'w+b')
    if not file then
        log:error('open the file failed.')
        error(custom_msg.PublicKeyImportFailed())
    end

    file:write(content)
    file:close()
    mc_utils.remove_file(config.SSH_PUBLIC_KEY_TEMP_FILE)
    file_proxy.proxy_chown(config.SSH_PUBLIC_KEY_PARSE_PATH, uid, gid)
    ok = pcall(file_utils.move_file_s, config.SSH_PUBLIC_KEY_PARSE_PATH, config.SSH_PUBLIC_KEY_TEMP_FILE)
    if not ok then
        log:notice("move ssh key file failed")
        error(custom_msg.PublicKeyImportFailed())
    end
    return config.SSH_PUBLIC_KEY_TEMP_FILE
end

return ssh_publickey