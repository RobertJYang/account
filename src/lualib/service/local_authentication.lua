-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local utils_crypt = require 'utils.crypt'
local custom_msg = require 'messages.custom'
local cjson = require 'cjson'
local enum = require 'class.types.types'
local err_cfg = require 'error_config'
local config = require 'common_config'
local utils = require 'infrastructure.utils'
local account_core = require 'account_core'
local acount_error = require 'account.errors'

local local_authentication = class()

function local_authentication:ctor(account_collection, global_account_config)
    self.m_account_collection = account_collection
    self.m_account_config = global_account_config
    self.m_pam_tally_log_dir = config.PAM_TALLY_LOG_DIR
end

local function __auth_password(account_password, password, crypt_pattern)
    local crypt_salt, hash_value = account_password:match(crypt_pattern)
    if not crypt_salt or not hash_value then
        log:error('Password format is incorrect')
        return false
    end
    if utils_crypt.crypt(password, crypt_salt) ~= account_password then
        return false
    end
    return true
end

local function _auth_password(account, password)
    local user_name = account:get_user_name()
     local pwd_auth_result = __auth_password(account.m_account_data.Password,
            password, config.SHA512_SALT_PATTERN)
    if not pwd_auth_result then
        log:notice('%s authenticate failed!', user_name)
        error(custom_msg.AuthorizationFailed())
    end
end

function local_authentication:ext_record_operation(ctx, user_name, ext_config)
    local account, account_id = self.m_account_collection:get_account_by_name(user_name)
    if ext_config['RecordLoginInfo'] then
        self.m_account_collection:record_login_time_ip(account_id, ctx.ClientAddr, false)
        self.m_account_collection:record_last_login_interface(account_id, enum.LoginInterface[ctx.Interface], false)
    end

    if ext_config['UpdateActiveTime'] then
        account:update_inactive_user_start_time(false)
    end
end

local function package_account_info(account)
    local result = {}
    local account_data = account:get_account_data()
    result['Id']                 = tostring(account_data.Id)
    result['UserName']           = account_data.UserName
    result['RoleId']             = tostring(account_data.RoleId)
    result['AccountType']        = tostring(account_data.AccountType)
    result['LastLoginIP']        = account_data.LastLoginIP
    result['LastLoginTime']      = tostring(account_data.LastLoginTime)
    result['current_privileges'] = cjson.encode(account.current_privileges)

    return result
end

function local_authentication:check_account_login_info(ctx, account_id, is_check_password)
    local account = self.m_account_collection.collection[account_id]
    local user_name = account:get_user_name()
    -- 登陆规则等
    if account_id == self.m_account_config:get_emergency_account() then
        return
    end

    -- 校验用户登录规则
    if ctx.ClientAddr and not self.m_account_collection:check_login_rule(account_id, ctx.ClientAddr) then
        log:error("the user(%s)|id(%d) is denied to login because of login rule", user_name, account_id)
        error(custom_msg.UserLoginRestricted())
    end
    -- 校验登录接口
    if ctx.Interface then
        local interface = enum.LoginInterface[ctx.Interface]:value()
        if interface & account:get_login_interface() == 0 then
            log:error("the user(%s)|id(%d) is denied to login because of login interface", user_name, account_id)
            error(custom_msg.NoAccess())
        end
    end
end

function local_authentication:authenticate(ctx, user_name, password, ext_config)
    -- 基础校验
    if not utils.base_check_user_name(user_name) then
        error(custom_msg.AuthorizationFailed())
    end
    if ext_config["IsAuthPassword"] then
        if #password < config.MIN_PASSWORD_DEFAULT_LEN or
            #password > self.m_account_config:get_password_max_length() then
            log:error('password length is out of range')
            error(custom_msg.AuthorizationFailed())
        end
    end

    local account, account_id = self.m_account_collection:get_account_by_name(user_name)
    if not account then
        error(custom_msg.AuthorizationFailed())
    end
    -- 判断手动锁定
    if account:get_locked() then
        error(custom_msg.UserLocked())
    end

    if ext_config["IsAuthPassword"] then
        -- 密码认证
        _auth_password(account, password)
    end

    -- 用户使能
    if not account:get_enabled() then
        error(custom_msg.AuthorizationFailed())
    end

    self:check_account_login_info(ctx, account_id, ext_config["IsAuthPassword"])

    -- 无权限用户
    if account:get_role_id() == enum.RoleType.NoAccess:value() then
        error(custom_msg.NoAccess())
    end

    -- 包装返回信息，要放在扩展操作之前，否则上次登录信息可能会被覆盖
    local account_info = package_account_info(account)
    self:ext_record_operation(ctx, user_name, ext_config)
    return account_info
end

function local_authentication:test_ipmi_password(user_name, password)
    local account = self.m_account_collection:get_account_by_name(user_name)
    if not account then
        return {["code"] = tostring(err_cfg.USER_UNSUPPORT)}
    end

    local ret = account:test_password_operation(password)
    if not ret then
        return {["code"] = tostring(err_cfg.PASSWORD_TEST_FAILED1)}
    else
        return {["code"] = tostring(err_cfg.USER_OPER_SUCCESS)}
    end
end

function local_authentication:ipmi_local_authenticate(user_name, password)
    local account = self.m_account_collection:get_account_by_name(user_name)
    if not account then
        return {["code"] = tostring(err_cfg.USER_DONT_EXIST)}
    end

    if account:get_locked() then
        log:error('User(%s) is locked', user_name)
        return {["code"] = tostring(err_cfg.INVALID_PASSWORD)}
    end

    local ret = account:test_password_operation(password)
    if not ret then
        log:error('Check user(%s) password failed!', user_name)
        return {["code"] = tostring(err_cfg.INVALID_PASSWORD)}
    end

    local result, privilege = account:user_judge_priv_and_enable_valid()
    if not result then
        log:error("the user(%s) is not enabled or have no privilege to access", user_name)
        return {["code"] = tostring(err_cfg.USER_NO_ACCESS)}
    end
    if account:get_password_valid_time() == 0 then
        log:error("the user(%s) password is expired", user_name)
        return {["code"] = tostring(err_cfg.USER_PASSWORD_EXPIRED)}
    end
    log:debug('the local user(%s) authentication successfully', user_name)
    return {
        ["code"]      = tostring(err_cfg.USER_OPER_SUCCESS),
        ["privilege"] = tostring(privilege)
    }
end

function local_authentication:vnc_authenticate(ctx, cipher_text, auth_challenge)
    local vnc_account = self.m_account_collection.collection[config.VNC_ACCOUNT_ID]
    local vnc_name = vnc_account:get_user_name()
    -- 校验vnc登录规则
    local ip = ctx.ClientAddr
    if ip and not vnc_account:check_login_rule(ip) then
        log:error('vnc account login rule check failed.')
        error(custom_msg.AuthorizationUserRestricted())
    end
    -- 校验vnc密码过期
    if vnc_account:get_password_valid_time() == 0 then
        log:info("vnc password is expired, need change vnc password")
        error(custom_msg.AuthorizationUserPasswordExpired())
    end
    -- 密码校验
    local ok, plaintext = pcall(function()
        return vnc_account:get_vnc_pwd_plaintext()
    end)
    if not ok then
        log:error('authenticate failed, password not init')
        error(custom_msg.AuthorizationFailed())
    end

    -- 将密文/挑战码转换为字符串
    local cipher_str = utils.decode_hex_string(cipher_text)
    local auth_challenge_str = utils.decode_hex_string(auth_challenge)
    -- 加密挑战码
    local ret, encrypt_challenge = account_core.vnc_encrypt_bytes(plaintext, auth_challenge_str, #auth_challenge_str)
    encrypt_challenge = encrypt_challenge:sub(1, #cipher_str)
    if ret ~= 0 then
        log:error('encrypt vnc auth challenge failed, ret err : %d', ret)
        error(custom_msg.AuthorizationFailed())
    end
    if encrypt_challenge ~= cipher_str then
        account_core.increment_pam_tally(vnc_name, self.m_pam_tally_log_dir)
        log:error('authenticate failed, not eq')
        error(custom_msg.AuthorizationFailed())
    end

    -- 重置失败锁定次数
    account_core.reset_pam_tally(vnc_name, self.m_pam_tally_log_dir)
    return package_account_info(vnc_account)
end

function local_authentication:gen_rmcp20_auth_code(ctx, authalgo, user_name, console_sid, managed_sid, console_random,
                                            managed_random, managed_guid, role, ip)
    -- 枚举适配
    local auth_algo = enum.RmcpAuthAlgo.new(authalgo)
    if not utils.base_check_user_name(user_name) then
        error(custom_msg.AuthorizationFailed())
    end
    local target_account, target_account_id = self.m_account_collection:get_account_by_name(user_name)
    -- 判断手动锁定
    if target_account:get_locked() then
        error(custom_msg.UserLocked())
    end
    -- 校验用户是否使能
    if not target_account:get_enabled() then
        log:error("The account(%s) is disabled", user_name)
        error(custom_msg.AuthorizationFailed())
    end
    if target_account.m_account_data.Id ~= self.m_account_config:get_emergency_account() then
        -- 校验用户登录规则
        if ip and not self.m_account_collection:check_login_rule(target_account_id, ip) then
            log:error("the user(%s)|id(%d) is denied to login because of login rule", user_name, target_account_id)
            error(custom_msg.AuthorizationFailed())
        end
        -- 校验用户是否有IPMI接口权限
        local account_interface = self.m_account_collection:get_login_interface(target_account_id)
        if account_interface & enum.LoginInterface.IPMI:value() ~= enum.LoginInterface.IPMI:value() then
            log:error("the user(%s)|id(%d) ipmi interface is not allowed", user_name, target_account_id)
            error(custom_msg.AuthorizationFailed())
        end
        -- 校验密码是否过期
        if target_account:get_password_valid_time() == 0 then
            log:error("the user(%s)|id(%d) password is expired", user_name, target_account_id)
            error(custom_msg.AuthorizationFailed())
        end
    end


    self.m_account_collection:record_login_time_ip(target_account_id, ctx.ClientAddr, false)
    self.m_account_collection:record_last_login_interface(target_account_id, enum.LoginInterface.IPMI, false)
    local rakp2code = target_account:gen_rakp2_auth_code(auth_algo, console_sid, managed_sid, console_random,
        managed_random, managed_guid, role)
    local sik = target_account:gen_sik(auth_algo, console_random, managed_random, role)
    local rakp3code = target_account:gen_rakp3_auth_code(auth_algo, managed_random, console_sid, role)
    return rakp2code, sik, rakp3code
end

function local_authentication:gen_rmcp15_auth_code(ctx, authalgo, pay_load, account_id, session_id,
    session_sequence)
    local auth_algo = enum.RmcpAuthAlgo.new(authalgo)
    local ip = ctx.ClientAddr
    if not ip then
        log:error("ip info is error")
        error(custom_msg.invalid_parameter())
    end
    utils.check_ipmi_account_id(account_id)
    local target_account = self.m_account_collection:get_account_by_account_id(account_id)
    local account_name  = target_account.m_account_data.UserName
    -- 判断手动锁定
    if target_account:get_locked() then
        error(custom_msg.UserLocked())
    end
    -- 校验用户是否使能
    if not target_account:get_enabled() then
        log:error("The account(%s) is disabled", account_name)
        error(custom_msg.AuthorizationFailed())
    end
    -- 校验用户登录规则
    if ip and not self.m_account_collection:check_login_rule(account_id, ip) then
        log:info("The account(%s) is not allowed to login because of login rule", account_name)
        error(custom_msg.AuthorizationFailed())
    end
    -- 校验用户是否有IPMI接口权限
    local account_interface = self.m_account_collection:get_login_interface(account_id)
    if account_interface & enum.LoginInterface.IPMI:value() ~= enum.LoginInterface.IPMI:value() then
        log:info("The account(%s) ipmi interface is not allowed", account_name)
        error(custom_msg.AuthorizationFailed())
    end

    self.m_account_collection:record_login_time_ip(account_id, ctx.ClientAddr, false)
    self.m_account_collection:record_last_login_interface(account_id, enum.LoginInterface.IPMI, false)
    return target_account:gen_rmcp_md5_code(auth_algo, pay_load, session_id, session_sequence)
end

return singleton(local_authentication)