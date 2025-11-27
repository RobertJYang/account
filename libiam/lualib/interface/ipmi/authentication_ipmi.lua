-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
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
local iam_enum = require 'class.types.types'
local context = require 'mc.context'
local iam_err = require 'iam.errors'
local log = require 'mc.logging'
local utils = require 'utils'
local ipmi_cmds = require 'iam.ipmi.ipmi'
local authentication = require 'service.authentication'
local ldap_authentication = require 'service.ldap_authentication'
local user_config = require 'user_config'
local err_cfg = require 'error_config'
local account_cache = require 'domain.cache.account_cache'
local account_lock = require 'domain.account_lock'
local role_privilege_map = require 'models.role_privilege_map'
local iam_core = require 'iam_core'
local custom_msg = require 'messages.custom'
local client = require 'iam.client'

local AuthenticationIpmi = class()

local function user_authentication_input_check(login_type, unlock_flag)
    if login_type ~= iam_enum.AccountType.Local:value() and
        login_type ~= iam_enum.AccountType.LDAP:value() then
        log:error('User authentication failed, login type is wrong')
        return false
    elseif unlock_flag ~= 0 and unlock_flag ~= 1 then
        log:error('User authentication failed, unlock flag is wrong')
        return false
    end
    return true
end

function AuthenticationIpmi:ctor()
    self.m_authentication_service = authentication.get_instance()
    self.m_ldap_authentication_service = ldap_authentication.get_instance()
    self.m_account_cache = account_cache.get_instance()
    self.m_account_lock = account_lock.get_instance()
end

-- 支持IPMI接口OEM认证命令
function AuthenticationIpmi:user_authentication(req, ctx)
    local login_type = req.LoginType
    local unlock_flag = req.UnlockFlag
    local user_name = utils.trim00(req.UserName)
    local password = utils.trim00(req.PasswordData)
    if not user_authentication_input_check(login_type, unlock_flag) then
        error(iam_err.invalid_parameter())
    end
    local rsp = ipmi_cmds.UserAuthentication.rsp.new()
    local ret, privilege
    if login_type == iam_enum.AccountType.Local:value() then
        ret, privilege = self:local_user_authentication(unlock_flag, user_name, password, ctx)
    else
        ret, privilege = self:ldap_user_authentication(unlock_flag, user_name, password, ctx)
    end
    if unlock_flag == 1 then
        ctx.operation_log.result = ret == err_cfg.USER_OPER_SUCCESS and 'unlock_success' or 'unlock_failed'
    end
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ret
    rsp.UserPrivilege = privilege or 0xff
    rsp.PrivilegeMaskReserved = 0xffffffff
    return rsp
end

function AuthenticationIpmi:set_account_lock_state(ctx, account_id, lock_state)
    local account = self.m_account_cache:get_account_by_id(account_id)
    if not account then
        log:error("account id %s is not exist", account_id)
        error(custom_msg.UserNotExist("Id:" .. account_id))
    end

    local is_local_user = account.AccountType == iam_enum.AccountType.Local or
        account.AccountType == iam_enum.AccountType.OEM
    if not is_local_user then
        log:error("account id %s is not local account", account_id)
        error(custom_msg.UserNotExist("Id:" .. account_id))
    end

    local user_name = account.UserName
    local obj = client:GetManagerAccountsManagerAccountsObject()
    local call_ctx = context.new(ctx.Interface, ctx.UserName, ctx.ClientAddr)
    local ok = pcall(obj.SetAccountLockState, obj, call_ctx, account_id, lock_state)
    if not ok then
        return false
    end
    if not lock_state then
        iam_core.reset_pam_tally(user_name, user_config.PAM_TALLY_LOG_DIR)
        self.m_account_lock:set_account_lock_state(account_id, iam_enum.UserLocked.USER_UNLOCK, 0)
    else
        -- 锁定踢出会话
        self.m_account_cache.m_account_security_changed:emit(account_id, user_name)
    end

    if ctx and ctx.operation_log then
        ctx.operation_log.params = { lock_state = lock_state and 'Lock' or 'Unlock',
            user_name = user_name, account_id = account_id }
    end
    return true
end

-- 支持IPMI接口OEM认证命令
function AuthenticationIpmi:local_user_authentication(unlock_flag, user_name, password, ctx)
    local account_id = self.m_account_cache:get_account_by_name(user_name)
    if not account_id then
        log:error('User(%s) do not exist', user_name)
        return err_cfg.USER_DONT_EXIST
    end
    if unlock_flag == 1 then
        local ok, _ = pcall(self.set_account_lock_state, self, ctx, account_id, false)
        return ok and err_cfg.USER_OPER_SUCCESS or err_cfg.USER_UNLOCK_FAIL
    end

    local obj = client:GetLocalAccountAuthNLocalAccountAuthNObject()
    local call_ctx = context.new(ctx.Interface, ctx.UserName, ctx.ClientAddr)
    local ext_config = {
        ['IpmiLocalAuth'] = true
    }
    local ok, result = pcall(obj.LocalAuthenticate, obj, call_ctx, user_name, password, ext_config)
    if not ok then
        log:error("LocalAuthenticate request failed!")
        return err_cfg.INVALID_PASSWORD
    end
    return tonumber(result.code), tonumber(result.privilege)
end

function AuthenticationIpmi:ldap_user_authentication(unlock_flag, user_name, password, ctx)
    if unlock_flag == 1 then
        log:error('Ldap authentication failed, operation unlock user is unsupport')
        error(iam_err.un_supported())
    end
    local ip
    -- 带内用户无需使用ip参数进行认证，带外用户通过上下文中的ip进行认证
    if ctx.session then
        ip = string.sub(ctx.session.ip, 1, string.find(ctx.session.ip, ':') - 1)
    end
    local group = self.m_ldap_authentication_service:ldap_authenticate_auto_match(user_name, password, ip)
    if not group then
        log:error('Ldap authentication failed')
        return err_cfg.INVALID_PASSWORD
    end
    local privilege = role_privilege_map.role_to_privilege_map[group:get_role_id()]
    return err_cfg.USER_OPER_SUCCESS, privilege
end

function AuthenticationIpmi:check_vnc_password(req, ctx)
    local rsp = ipmi_cmds.CheckVncPassword.rsp.new()
    if req.Length ~= #req.Password or req.Length > 8 or #req.Password > 8 then
        log:error("Data input length error")
        error(iam_err.invalid_parameter())
    end

    local vnc_account = self.m_account_cache:get_account_by_id(user_config.VNC_ACCOUNT_ID)
    local vnc_name = vnc_account.UserName
    if self.m_authentication_service:get_user_lock_state(vnc_name) then
        ctx.operation_log.result = 'lock'
        log:error('vnc account is locked.')
        rsp.CompletionCode = err_cfg.USER_IS_LOCKED
    else
        local obj = client:GetLocalAccountAuthNLocalAccountAuthNObject()
        local call_ctx = context.new(ctx.Interface, ctx.UserName, ctx.ClientAddr)
        local ext_config = {
            ['TestPassword'] = true
        }
        local ok, result = pcall(obj.LocalAuthenticate, obj, call_ctx, vnc_name, req.Password, ext_config)
        local ret = tonumber(result.code)

        if ok and ret == err_cfg.USER_OPER_SUCCESS then
            iam_core.reset_pam_tally(vnc_name, user_config.PAM_TALLY_LOG_DIR)
            rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
        else
            ctx.operation_log.result = 'fail'
            iam_core.increment_pam_tally(vnc_name, user_config.PAM_TALLY_LOG_DIR)
            log:error("check vnc password failed.")
            rsp.CompletionCode = err_cfg.USER_INVALID_DATA_FIELD
        end
    end
    rsp.ManufactureId = req.ManufactureId
    return rsp
end

return singleton(AuthenticationIpmi)