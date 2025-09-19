-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
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
local core = require 'account_core'
local enum = require 'class.types.types'
local error_config = require 'error_config'
local config = require 'common_config'
local utils = require 'infrastructure.utils'
local ssh_public_key = require 'infrastructure.ssh_public_key'
local manager_account = require 'domain.manager_account.manager_account'

local local_account = class(manager_account)

local_account.MIN_USER_NUM = 2
local_account.MAX_USER_NUM = 17

--- 设置用户名
---@param user_name string 
function local_account:set_user_name(user_name)
    self:property_writable_check('UserName')
    self.m_account_data.UserName = user_name
    self.m_account_data:save()
end

function local_account:set_role_id(role_id)
    self:property_writable_check('RoleId')
    self.m_account_data.RoleId = role_id
    self.m_account_data:save()
    self:update_privileges()
end

function local_account:set_login_interface(interface)
    self:property_writable_check('LoginInterface')
    self.m_account_data.LoginInterface = interface
    self.m_account_data:save()
end

--- 设置用户登录规则
---@param login_rule_ids number 
function local_account:set_login_rule_ids(login_rule_ids)
    self:property_writable_check('LoginRuleIds')
    self.m_account_data.LoginRuleIds = login_rule_ids
    self.m_account_data:save()
end

function local_account:set_user_auth_protocol(auth_protocol)
    self:property_writable_check('AuthenticationProtocol')
    self.m_snmp_user_info_data.AuthenticationProtocol = auth_protocol
    self.m_snmp_user_info_data:save()
end

function local_account:set_user_encrypt_protocol(encrypt_protocol)
    self:property_writable_check('EncryptionProtocol')
    self.m_snmp_user_info_data.EncryptionProtocol = encrypt_protocol
    self.m_snmp_user_info_data:save()
end

function local_account:set_enabled(enabled)
    self:property_writable_check('Enabled')
    -- 使能用户，判断用户是否符合密码复杂度检查
    if not self:get_enabled() and enabled and self:login_interface_exist(enum.LoginInterface.IPMI:value()) then
        if not self.m_account_data.IpmiPassword or self.m_account_data.IpmiPassword == '' then
            log:error('ipmi password is illegal.')
            error(custom_msg.InvalidPassword())
        end
        local plain_password = self.kmc_client:decrypt_password(self.m_account_data.IpmiPassword)
        -- 校验密码复杂度
        local info = {
            ["password"] = plain_password,
            ["username"] = self:get_user_name()
        }
        local ok, err = pcall(function()
            self.password_validator_obj:validate(info)
        end)
        if not ok then
            log:error('check password complexity failed, err: %s', err)
            error(custom_msg.PasswordComplexityCheckFail())
        end
    end

    local is_enable_by_passwd = enabled and
        enum.IpmiUserEnableByPassword.UserEnable or enum.IpmiUserEnableByPassword.PasswordEnable
    self:set_ipmi_enable_by_password(is_enable_by_passwd)

    self.m_account_data.Enabled = enabled
end

function local_account:set_inactive_start_time(timestamp, flash_flag)
    -- flash_flag为true立即写flash;定时刷新flash时timestamp为空
    if timestamp then
        self.m_account_data.InactiveStartTime = timestamp
    end
    if flash_flag then
        self.m_account_data:save()
    end
end

function local_account:update_inactive_status(have_only_enabled_admin, limit)
    if not self:get_enabled() then
        return
    end

    -- 逃生用户，已被禁用，最后1个使能可操作bmc的管理员不需要判断是否禁用
    if self:get_id() == self.m_account_config:get_emergency_account() or
        (have_only_enabled_admin and self:check_is_enabled_admin() and
        self:check_is_allowed_operate_interfaces()) then
        return
    end
    local inactive_start_time = self:get_inactive_start_time()
    local cur_timestamp = os.time()
    if inactive_start_time and cur_timestamp >= inactive_start_time + limit then
        log:notice('Need to disable User%d, new_timestamp = %d, inactuserstarttime = %d, limit = %d',
            self:get_id(), cur_timestamp, inactive_start_time, limit)
        self:set_enabled(false)
        self.m_account_update_signal:emit("Enabled", false)
        log:security('User (%s): disable inactive user', self:get_user_name())
    end
end

function local_account:update_deletable(have_only_enabled_admin)
    if self:get_id() == self.m_account_config:get_emergency_account() or
        (self:get_id() == self.m_account_config:get_snmp_v3_trap_account_id() and
            self.m_account_config:get_snmp_v3_trap_account_change_policy() == 0 and
            self.m_account_config:get_snmp_v3_trap_account_limit_policy() ~=
            enum.SNMPv3TrapAccountLimitPolicy.Modifiable:value()) or
            (have_only_enabled_admin and self:check_is_enabled_admin() and
            self:check_is_allowed_operate_interfaces()) then
        self.m_account_data.Deletable = false
        self.m_account_update_signal:emit("Deletable", false)
        return
    end

    self.m_account_data.Deletable = true
    self.m_account_update_signal:emit("Deletable", true)
end

function local_account:set_within_min_password_days_status(status)
    self.m_account_data.WithinMinPasswordDays = status
end

function local_account:update_password_valid_start_time()
    local cur_timestamp = vos_utils.vos_get_cur_time_stamp()
    self:set_password_valid_start_time(cur_timestamp)
end

function local_account:import_ssh_public_key(path, home_path, uid, gid)
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

function local_account:delete_ssh_public_key(home_path)
    local ssh_path = table.concat({ home_path, config.SSH_PUBLIC_KEY_SUB_DIR_NAME }, '/')

    mc_utils.remove_file(ssh_path)
    self.m_account_data.SshPublicKeyHash = ''
    self.m_account_data:save()
    self.m_account_update_signal:emit('SshPublicKeyHash', '')
end

function local_account:check_is_enabled_admin()
    local is_admin = self:get_ipmi_user_privilege() == enum.IpmiPrivilege.ADMIN:value() or
        self:get_role_id() == enum.RoleType.Administrator:value()
    return is_admin and self:get_enabled()
end

function local_account:check_is_allowed_operate_interfaces()
    local interface_num = self.m_account_data.LoginInterface
    return interface_num ~= enum.LoginInterface.Invalid:value() and interface_num ~= enum.LoginInterface.SFTP:value()
end

function local_account:password_validator(ctx, user_name, password, is_initial, is_config_self)
    self:property_writable_check('Password')
    -- 校验密码复杂度
    local info = {
        ["password"] = password,
        ["username"] = user_name
    }
    local ok, err = pcall(function()
        self.password_validator_obj:validate(info)
    end)
    if not ok then
        log:error('The password does not meet the password complexity')
        ctx.operation_log.params.ret = error_config.USER_PASS_COMPLEXITY_FAIL
        error(err)
    end
    -- 校验密码长度
    if #password < config.MIN_PASSWORD_DEFAULT_LEN or #password > config.MAX_PASSWORD_DEFAULT_LEN then
        log:error('password length is out of range')
        ctx.operation_log.params.ret = error_config.USER_USERPASS_TOO_LONG
        error(custom_msg.InvalidPasswordLength(config.MIN_PASSWORD_DEFAULT_LEN,
            self.password_validator_obj:get_password_max_length()))
    end
    -- 检查密码内是否含有汉字
    if not utils.check_if_password_character_is_valid(password) then
        log:error('password contains chinese')
        ctx.operation_log.params.ret = error_config.USER_INVALID_DATA_FIELD
        error(custom_msg.InvalidPassword())
    end
    -- 校验用户密码是否属于弱口令
    if self.m_account_config:get_weak_pwd_dictionary_enable() then
        self.m_account_config:check_password_in_weak_passwd_dictionary(ctx, password, 'user_password')
    end
    -- 和历史密码比较, 创建用户不应和历史比较
    if not is_initial and not self.m_history_password:check(password) then
        ctx.operation_log.params.ret = error_config.USER_CANNT_SET_SAME_PASSWORD
        log:error('check history password failed')
        error(custom_msg.InvalidPasswordSameWithHistory())
    end
    -- 用户修改自身密码，FirstLoginPolicy为非强制修改策略或者密码非待修改状态（初始密码状态），处于最短密码有效期限制不能修改密码
    local within_min_password_days = self:get_within_min_password_days_status()
    local password_change_require = self:get_password_change_required()
    local first_login_policy = self:get_first_login_policy()
    if within_min_password_days and is_config_self and not is_initial and
        (not password_change_require or first_login_policy ~= enum.FirstLoginPolicy.ForcePasswordReset) then
        log:error('user(%u) is in minimum password validity days limit', self:get_id())
        ctx.operation_log.params.ret = error_config.USER_TIME_LIMIT_UNREASONABLE
        error(custom_msg.DuringMinimumPasswordAge())
    end
end

function local_account:set_account_password(password, is_config_self)
    self.m_account_data.Password, self.m_account_data.KDFPassword =
        self:crypt_password_by_random_salt(password)
    self.m_account_data.IpmiPassword = self.kmc_client:encrypt_password(password)
    self.m_account_data:save()
    -- 添加至历史密码
    self.m_history_password:insert(self.m_account_data.Password, self.m_account_data.KDFPassword,
        self.m_account_config:get_history_password_count())
    -- 更新密码是否需要修改状态
    self:set_password_change_required(not is_config_self)
    self.m_account_update_signal:emit("PasswordChangeRequired", not is_config_self)
    -- FirstLogin更新用户当前权限
    self:update_privileges()
    self:set_user_ku(password, enum.SNMPKuType.Authentication)
    -- snmp密码处于初始状态下时需要同步修改snmp密码;nil视为初始状态
    if self:get_snmp_privacy_password_init_status() ~= false then
        self:set_user_snmp_pwd(password)
        self:set_user_ku(password, enum.SNMPKuType.Encryption)
    end
    self:update_password_valid_start_time()
end

function local_account:check_conditions_set_snmp_passwd(ctx, password)
    self:property_writable_check('SNMPPassword')
    local info = {
        ["password"] = password,
        ["username"] = self.m_account_data.UserName
    }
    local ok, err = pcall(function()
        self.password_validator_obj:validate(info)
    end)
    if not ok then
        log:error('The snmp password does not meet the password complexity')
        error(err)
    end

    if #password < config.MIN_PASSWORD_DEFAULT_LEN or #password > config.MAX_PASSWORD_DEFAULT_LEN then
        log:error('Length of snmp password is out of range')
        error(custom_msg.InvalidPasswordLength(config.MIN_PASSWORD_DEFAULT_LEN,
            self.password_validator_obj:get_password_max_length()))
    end
    -- 校验用户密码是否属于弱口令
    if self.m_account_config:get_weak_pwd_dictionary_enable() then
        self.m_account_config:check_password_in_weak_passwd_dictionary(ctx, password, 'snmp_password')
    end
end

--- 检查用户登录规则
---@param ip string
function local_account:check_login_rule(ip)
    local login_rule_ids = self:get_login_rule_ids()
    return self.m_login_rule_collection:check_login_rule(login_rule_ids, ip)
end

function local_account:set_properties_writable(ctx, properties)
    local writable_log_tab = {}
    for property, writable in pairs(properties) do
        if self:get_property_writable(property) ~= writable then
            self.m_account_data[property] = writable
            table.insert(writable_log_tab, property .. ':' .. tostring(writable))
        end
    end
    if ctx.operation_log then
        ctx.operation_log.params.writable_log = table.concat(writable_log_tab, ', ')
    end
    self.m_account_data:save()
end

function local_account:get_property_writable(property)
    return self.m_account_data[property] ~= false
end

return local_account
