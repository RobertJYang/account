-- Copyright (c) 2025 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local log = require 'mc.logging'
local mc_utils = require 'mc.utils'
local vos_utils = require 'utils.vos'
local custom_msg = require 'messages.custom'
local enum = require 'class.types.types'
local config = require 'common_config'
local utils = require 'infrastructure.utils'
local ssh_public_key = require 'infrastructure.ssh_public_key'
local manager_account = require 'domain.manager_account.manager_account'

local inter_chassis_account = class(manager_account)

-- 框内用户第一次初始化时保留默认配置，用于恢复
function inter_chassis_account:init()
    -- 255 代表默认RoleId未被设置存储，需要进行设置
    if self.m_account_data.DefaultRoleId == 255 then
        self.m_account_data.DefaultRoleId = self.m_account_data.RoleId
    end

    if self.m_account_data.DefaultLoginInterface == enum.LoginInterface.default:value() then
        self.m_account_data.DefaultLoginInterface = self.m_account_data.LoginInterface
    end

    self.m_account_data:save()
end

-- 存在PSR配置时，使用PSR配置覆盖默认配置
function inter_chassis_account:flush_default_by_sr(inter_chassis_config)
    if inter_chassis_config.AccessRoleId then
        self.m_account_data.DefaultRoleId = inter_chassis_config.AccessRoleId
    end
    if inter_chassis_config.LoginInterface then
        self.m_account_data.DefaultLoginInterface = inter_chassis_config.LoginInterface
    end
    self.m_account_data:save()
end

function inter_chassis_account:recover_default()
    self.m_account_data.RoleId = self.m_account_data.DefaultRoleId
    self.m_account_data.LoginInterface = self.m_account_data.DefaultLoginInterface

    self.m_account_update_signal:emit('RoleId', self.m_account_data.DefaultRoleId)
    self.m_account_update_signal:emit('LoginInterface',
        utils.convert_num_to_interface_str(self.m_account_data.DefaultLoginInterface, true))
    self.m_account_data:save()
    self:update_privileges()
end

function inter_chassis_account:set_role_id(role_id)
    self.m_account_data.RoleId = role_id
    self.m_account_data:save()
    self:update_privileges()
end

function inter_chassis_account:set_login_interface(interface)
    if not self.account_policy_obj:check_login_interface_is_allowed(interface) then
        local interface_str = utils.interface_num_to_string(interface)
        log:error('LoginInterface is illegal, interface : %s', interface_str)
        error(custom_msg.PropertyItemNotInList('%LoginInterface:' .. interface_str, '%LoginInterface'))
    end
    self.m_account_data.LoginInterface = interface
    self.m_account_data:save()
end

--内部账户无设置，使用默认值
function inter_chassis_account:get_password_change_required()
    return false
end

function inter_chassis_account:import_ssh_public_key(path, home_path, uid, gid)
    local key_temp_file_path = table.concat({ config.SSH_PUBLIC_KEY_CONF_TEMP_FILE, '_', self:get_id() })
    local hash_temp_file_path = table.concat({ config.SSH_PUBLIC_KEY_HASH_TEMP_FILE, '_', self:get_id() })
    -- 文件内容长度校验
    local file_length = vos_utils.get_file_length(path)
    if file_length == 0 or file_length > config.SSH_PUBLIC_KEY_MAX_LEN then
        mc_utils.remove_file(path)
        log:error('the file content length does not meet the requirement')
        error(custom_msg.PublicKeyImportFailed())
    end

    ssh_public_key.generate_openssh_format_public_key(path, key_temp_file_path)
    local hash_value = ssh_public_key.generate_public_key_hash(key_temp_file_path, hash_temp_file_path)
    ssh_public_key.generate_authentication_public_key_file(key_temp_file_path, home_path, uid, gid)

    self.m_account_data.SshPublicKeyHash = hash_value
    self.m_account_data:save()
    self.m_account_update_signal:emit('SshPublicKeyHash', hash_value)
    return hash_value
end

function inter_chassis_account:delete_ssh_public_key(home_path)
    local ssh_path = table.concat({ home_path, config.SSH_PUBLIC_KEY_SUB_DIR_NAME }, '/')

    mc_utils.remove_file(ssh_path)
    self.m_account_data.SshPublicKeyHash = ''
    self.m_account_data:save()
    self.m_account_update_signal:emit('SshPublicKeyHash', '')
end

return inter_chassis_account