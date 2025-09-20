-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local mc_utils = require 'mc.utils'
local file_utils = require 'utils.file'
local ssh_public_key = require 'infrastructure.ssh_public_key'
local config = require 'common_config'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'

local function touch_temp_file(file_path, source_file)
    os.execute('touch ' .. file_path)
    if source_file then
        file_utils.copy_file_s(source_file, file_path)
    end
    return file_path
end

--- 当导入SSH2格式公钥，应该转换为OPENSSH格式公钥
function TestAccount:test_when_import_ssh2_format_public_key_should_get_openssh_key()
    local openssh_public_temp_file = touch_temp_file(self.test_data_dir .. '/tmp/openssh_public_temp_file')
    ssh_public_key.generate_openssh_format_public_key(self.ssh2_public_key_path, openssh_public_temp_file)
    
    local key_file = file_utils.open_s(config.SSH_PUBLIC_KEY_PARSE_PATH, 'r')
    local correct_openssh_key = key_file:read('*a')
    key_file:close()
    local temp_key_file = file_utils.open_s(openssh_public_temp_file, 'r')
    local temp_openssh_key = temp_key_file:read('*a')
    temp_key_file:close()

    lu.assertEquals(correct_openssh_key, temp_openssh_key)
    -- 恢复操作
    mc_utils.remove_file(openssh_public_temp_file)
end

--- 当导入OPENSSH格式公钥，应该转换为OPENSSH格式公钥
function TestAccount:test_when_import_openssh_format_public_key_should_get_openssh_key()
    local openssh_public_temp_file = touch_temp_file(self.test_data_dir .. '/openssh_public_temp_file')
    ssh_public_key.generate_openssh_format_public_key(self.openssh_public_key_path, openssh_public_temp_file)
    
    local key_file = file_utils.open_s(config.SSH_PUBLIC_KEY_PARSE_PATH, 'r')
    local correct_openssh_key = key_file:read('*a')
    key_file:close()
    local temp_key_file = file_utils.open_s(openssh_public_temp_file, 'r')
    local temp_openssh_key = temp_key_file:read('*a')
    temp_key_file:close()

    lu.assertEquals(correct_openssh_key, temp_openssh_key)
    -- 恢复操作
    mc_utils.remove_file(openssh_public_temp_file)
end

--- 当导入OPENSHH格式公钥，应该获得正确hash值
function TestAccount:test_when_generate_openssh_public_key_hash_should_get_hash_success()
    os.execute('touch ' .. config.SSH_PUBLIC_KEY_HASH_TEMP_FILE)
    local hash_value = ssh_public_key.generate_public_key_hash(
        self.openssh_public_key_path, config.SSH_PUBLIC_KEY_HASH_TEMP_FILE)
    lu.assertEquals(hash_value, 'tUxpndtHEnwPnfHPXI+2XDaUoDpAMDJn1azS/+HfOaw')
    -- 恢复操作
    mc_utils.remove_file(config.SSH_PUBLIC_KEY_HASH_TEMP_FILE)
end

--- 传入SSH公钥文件，应该在用户根目录下
function TestAccount:test_when_generate_ssh2_public_key_hash_should_get_hash_success()
    local home_path = self.test_data_dir .. '/tmphome'
    mc_utils.mkdir(home_path, mc_utils.S_IRWXU)
    ssh_public_key.generate_authentication_public_key_file(self.openssh_public_key_path, home_path, 0, 0)

    local authorized_keys_file = file_utils.open_s(home_path .. '/.ssh/authorized_keys', 'r')
    local authorized_keys = authorized_keys_file:read('*a')
    authorized_keys_file:close()
    local key_file = file_utils.open_s(self.openssh_public_key_path, 'r')
    local correct_openssh_key = key_file:read('*a')
    key_file:close()

    lu.assertEquals(correct_openssh_key, authorized_keys)
    -- 恢复操作
    mc_utils.remove_file(home_path)
end

-- 删除不存在的公钥应失败
function TestAccount:test_delete_ssh_pub_key_when_key_not_exist_should_fail()
    -- 删除2号用户ssh公钥(未导入)
    local ok, err = pcall(self.test_account_collection.delete_ssh_public_key, self.test_account_collection, self.ctx, 2)
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, custom_msg.PublicKeyNotExistMessage.Name)
end

function TestAccount:test_change_user_name_should_dle_ssh_public_key()
    local path = touch_temp_file(config.SHM_TMP_PATH .. '/ssh_rsa.pub', self.ssh2_public_key_path)
    self.test_account_collection:import_ssh_public_key(self.ctx, 2, path)
    local account = self.test_account_collection:get_account_by_account_id(2)
    local hash = account.m_account_data.SshPublicKeyHash
    assert(hash and #hash ~= 0)
    local name_ori = account:get_user_name()
    self.test_account_collection:change_user_name(2, "Administrator2")
    hash = account.m_account_data.SshPublicKeyHash
    assert(#hash == 0)
    -- 恢复环境
    self.test_account_collection:change_user_name(2, name_ori)
end