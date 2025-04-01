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
local log = require 'mc.logging'
local vos_utils = require 'utils.vos'
local utils_crypt = require 'utils.crypt'
local base_msg = require 'messages.base'
local enum = require 'class.types.types'
local config = require 'common_config'
local utils = require 'infrastructure.utils'
local manager_account = require 'domain.manager_account.manager_account'

local OEMAccount = class(manager_account)

OEMAccount.MIN_USER_NUM = 101
OEMAccount.MAX_USER_NUM = 115


--- 对密文密码的校验，该方法仅此类需要，其他类型用户不需要
local function encrypted_password_validator(encrypted_password)
    -- 要求密文格式为$算法类型$盐值$哈希值
    local crypt_algorithm, salt, hash_value = encrypted_password:match("%$(.-)%$(.-)%$(.-)$")
    if not crypt_algorithm or not salt or not hash_value then
        log:error('Type of encrypted password is invalid')
        error(base_msg.InternalError())
    end
end

--- account_info中包含用户名字、用户id、角色id、可登录的接口、首次登录策略
function OEMAccount:init_account(account_info)
    -- 如果新增用户密码为已加密的密文，则设置密码及IPMI密码为该密文，否则进行加密
    if account_info.is_pwd_encrypted then
        encrypted_password_validator(account_info.password)
        self.m_account_data.Password = account_info.password
        self.m_account_data.IpmiPassword = ''
    else
        self.m_account_data.Password, self.m_account_data.KDFPassword =
            self:crypt_password_by_random_salt(account_info.password)
        self.m_account_data.IpmiPassword = self.kmc_client:encrypt_password(account_info.password)
    end
    self.m_account_data.UserName = account_info.name
    self.m_account_data.RoleId = account_info.role_id
    self.m_account_data.SshPublicKeyHash = ''
    self.m_account_data.Enabled = true
    self.m_account_data.Locked = false
    self.m_account_data.Deletable = true
    self.m_account_data.PasswordChangeRequired = true
    self.m_account_data.LastLoginInterface = enum.LoginInterface.Local
    self.m_account_data.FirstLoginPolicy = account_info.first_login_policy or
        enum.FirstLoginPolicy.ForcePasswordReset
    self.m_account_data.AccountType = enum.AccountType.OEM
    self.m_account_data.LoginInterface = utils.cover_interface_enum_to_num(account_info.interface)
    self.m_account_data.LoginRuleIds = 0
    self.m_account_data.PasswordValidStartTime = vos_utils.vos_get_cur_time_stamp()
    self.m_account_data.PasswordExpiration = 0xffffffff
    self.m_account_data.WithinMinPasswordDays = false
    self.m_account_data.LastLoginTime = 0xffffffff
    self.m_account_data.LastLoginIP = ""
    self.m_account_data.PasswordValidStartTime = vos_utils.vos_get_cur_time_stamp()
    self.m_account_data:save()
end

--- 设置用户名
---@param user_name string 
function OEMAccount:set_user_name(user_name)
    self:property_writable_check('UserName')
    self.m_account_data.UserName = user_name
    self.m_account_data:save()
end

function OEMAccount:set_role_id(role_id)
    self:property_writable_check('RoleId')
    self.m_account_data.RoleId = role_id
    self.m_account_data:save()
    self:update_privileges()
end

function OEMAccount:set_login_interface(interface)
    self:property_writable_check('LoginInterface')
    self.m_account_data.LoginInterface = interface
    self.m_account_data:save()
end

function OEMAccount:set_enabled(enabled)
    self:property_writable_check('Enabled')
    self.m_account_data.Enabled = enabled
    self.m_account_data:save()
end

--- 检查用户登录规则
---@param ip string
function OEMAccount:check_login_rule(ip)
    local login_rule_ids = self:get_login_rule_ids()
    return self.m_login_rule_collection:check_login_rule(login_rule_ids, ip)
end

function OEMAccount:set_properties_writable(ctx, properties)
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

function OEMAccount:get_property_writable(property)
    return self.m_account_data[property] ~= false
end

function OEMAccount:set_account_password(password, is_config_self)
    if not is_config_self then
        log:error('Only custom account itself can change password')
        error(base_msg.InsufficientPrivilege())
    end
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
end

local function password_verify(cur_password, verify_password, encrypted, pattern)
    if encrypted then
        return cur_password == verify_password
    else
        local salt = cur_password:match(pattern)
        return utils_crypt.crypt(verify_password, salt) == cur_password
    end
end

-- 预置定制用户需要做信息校验，该函数用于校验用户信息是否匹配（包括用户名、密码、权限、接口、登录策略）
-- 考虑到功能单一性，该函数未在父类声明
function OEMAccount:verify_account(AccountInfo)
    local base_data = self.m_account_data
    if base_data.UserName ~= AccountInfo.name then
        log:error('Name(%s) is not matched, verify failed', AccountInfo.name)
        error(base_msg.ActionParameterUnknown('VerifyOEMAccount', 'UserName'))
    end
    if base_data.RoleId ~= AccountInfo.role_id then
        log:error('RoleId(%d) is not matched, verify failed', AccountInfo.role_id)
        error(base_msg.ActionParameterUnknown('VerifyOEMAccount', 'RoleId'))
    end
    local interface_num = utils.cover_interface_str_to_num(AccountInfo.interface)
    if base_data.LoginInterface ~= interface_num then
        log:error('LoginInterface(num:%d) is not matched, verify failed', interface_num)
        error(base_msg.ActionParameterUnknown('VerifyOEMAccount', 'LoginInterface'))
    end
    if base_data.FirstLoginPolicy ~= AccountInfo.first_login_policy then
        log:error('FirstLoginPolicy(%d) is not matched, verify failed', AccountInfo.first_login_policy)
        error(base_msg.ActionParameterUnknown('VerifyOEMAccount', 'FirstLoginPolicy'))
    end
    local pwd_verify_result = false
    if base_data.KDFPassword then
        pwd_verify_result = password_verify(base_data.KDFPassword, AccountInfo.password,
            AccountInfo.is_pwd_encrypted, config.SHA512_SALT_PATTERN)
    end
    if not pwd_verify_result then
        pwd_verify_result = password_verify(base_data.Password, AccountInfo.password,
            AccountInfo.is_pwd_encrypted, config.SHA512_SALT_PATTERN)
    end
    if not pwd_verify_result then
        log:error('Password is not matched, verify failed')
        error(base_msg.ActionParameterUnknown('VerifyOEMAccount', 'Password'))
    end
end

return OEMAccount