-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local logging = require 'mc.logging'
local ipmi = require 'ipmi'
local mc_utils = require 'mc.utils'

local OperationLogger = class()

-- 操作动作-操作日志 映射表
local operation_log_map = {
    ------------------------ rpc ------------------------
    NewAccount = {
        success = 'Create user({name}|user{id}) role({role}) login interface({interface}) ' ..
            'first_login_policy({first_login_policy}) successfully',
        fail = 'Create user failed, information is invalid',
        ['kepler.account.InvalidAccountId'] = 'Create user(user{id}) failed, account id is invalid',
        ['kepler.account.UserFull'] = 'Create user failed, cannot add more user'
    },
    NewCustomAccount = {
        success = 'Create user({name}|user{id}) role({role}) login interface({interface}) ' ..
            'first_login_policy({first_login_policy}) successfully',
        fail = 'Create user failed, information is invalid',
        ['kepler.account.InvalidAccountId'] = 'Create user(user{id}) failed, account id is invalid',
        ['kepler.account.UserFull'] = 'Create user failed, cannot add more user'
    },
    DeleteAccount = {
        success = 'Delete user({name}|user{id}) successfully',
        fail = 'Delete user({name}|user{id}) failed',
        ['kepler.account.InvalidAccountId'] = 'Delete user(user{id}) failed, account id is invalid'
    },
    ChangeAccountPwd = {
        success = '{operate} user({name}|user{id}) password successfully',
        fail = '{operate} user({name}|user{id}) password failed',
        user_mgnt_disabled = "Modify user{id}'s password failed"
    },
    ChangeVNCPwd = {
        success = 'VNC password set successfully',
        fail = 'Failed to set the VNC password'
    },
    ChangeAccountSnmpPwd = {
        success = 'Set user({name}|user{id}) SNMP privacy password successfully',
        fail = 'Set user({name}|user{id}) SNMP privacy password failed',
        ['kepler.account.InvalidAccountId'] = 'Set user SNMP privacy password failed'
    },
    SetAuthenticationProtocol = {
        success = 'Set user({name}|user{id}) SNMP authentication protocol to {protocol} ' ..
            'and update user password successfully',
        fail = 'Set user({name}|user{id}) SNMP authentication protocol failed',
        ['kepler.account.InvalidAccountId'] = 'Set user SNMP authentication protocol failed'
    },
    SetEncryptionProtocol = {
        success = 'Set user({name}|user{id}) SNMP privacy protocol to {protocol} successfully',
        fail = 'Set user({name}|user{id}) SNMP privacy protocol failed',
        ['kepler.account.InvalidAccountId'] = 'Set SNMP privacy protocol failed'
    },
    ImportWeakPasswordDictionary = {
        success = 'Import weak password dictionary successfully',
        fail = 'Import weak password dictionary failed'
    },
    ExportWeakPasswordDictionary = {
        success = 'Export weak password dictionary successfully',
        fail = 'Export weak password dictionary failed'
    },
    SetRolePrivilege = {
        success = '{state} userrole({role_name}) {role} management state successfully',
        fail = 'Set else management state failed'
    },
    SetBindDnPassword = {
        success = 'Set LDAP{id} bind DN password successfully',
        fail = 'Set LDAP{id} bind DN password failed'
    },
    NewRemoteGroup = {
        ldap_success = 'Add RemoteGroup(name:{group_name}, login interface:{interface}, ' ..
            'userrole:{role_name})successfully',
        kerberos_success = 'Add RemoteGroup(name:{group_name}, SID:{SID}, login interface:{interface}, '..
            'userrole:{role_name})successfully',
        fail = 'Add RemoteGroup failed'
    },
    DeleteRemoteGroup = {
        success = 'Delete {group_id} successfully',
        fail = 'Delete {group_id} failed'
    },
    ChangeUserName = {
        success = "Modify user{id}'s username ({oldName} -> {name}) successfully",
        fail = "Modify user{id}'s username ({oldName} -> {name}) failed",
        user_id_invalid = "Set user{id}'s username failed",
        user_mgnt_disabled = "Modify user{id}'s username to ({name}) failed"
    },
    ImportSSHPublicKey = {
        success = 'Add user({name}|user{id}) public key successfully',
        fail = 'Add user({name}|user{id}) public key failed'
    },
    DeleteSSHPublicKey = {
        success = 'Delete user({name}|user{id}) public key successfully',
        fail = 'Delete user({name}|user{id}) public key failed'
    },
    SetRwCommunity = {
        success = 'Set SNMP Read-Write community string successfully',
        fail = 'Set SNMP Read-Write community string failed',
        delete_success = 'Delete SNMP Read-Write community string successfully',
        delete_failed = 'Delete SNMP Read-Write community string failed'
    },
    SetRoCommunity = {
        success = 'Set SNMP Read-only community string successfully',
        fail = 'Set SNMP Read-only community string failed',
        delete_success = 'Delete SNMP Read-only community string successfully',
        delete_failed = 'Delete SNMP Read-only community string failed'
    },
    LongCommunityEnabled = {
        success = '{operation} long community string successfully',
        fail = 'Set long community string enable failed',
    },
    RwCommunityEnabled = {
        success = '{operation} SNMP Read-Write community string successfully',
        fail = '{operation} SNMP Read-Write community string failed',
    },
    SetKvmKey = {
        success = 'KVM key set successfully',
        fail = 'Failed to set the KVM key'
    },
    NewRole = {
        success = 'Add custom user role({id}) successfully',
        fail = 'Add custom user role({id}) failed'
    },
    DeleteRole = {
        success = 'Delete custom user role({id}) successfully',
        fail = 'Delete custom user role({id}) failed'
    },
    ------------------------ rpc end ------------------------

    ------------------------   Ipmi  ------------------------
    IpmiNewAccount = {
        success = "Add user{id}'s username ({name}) successfully",
        user_mgnt_disabled = "Add user{id}'s username ({name}) failed",
        user_id_invalid = "Add user{id}'s username ({name}) failed",
        fail = "Add user{id}'s username ({name}) failed"
    },
    IpmiAccountEnabled = {
        success = '{operate} user({name}|user{id}) successfully',
        user_mgnt_disabled = '{operate} user({name}|user{id}) failed',
        fail = '{operate} user({name}|user{id}) failed',
        fail_ret = '{operate} user({name}|user{id}) failed, ret = {ret}'
    },
    IpmiSetUserPassComplexity = {
        success = '{state} local user password complexity check successfully',
        fail = '{state} local user password complexity check failed',
        ['kepler.account.HostUserManagementDiabled']  = 'Set local user password complexity check status failed',
        failed = 'Set local user password complexity check status failed',
        user_mgnt_disabled = 'Set local user password complexity check status failed'
    },
    IpmiDeleteAccount = {
        success = "Delete user{id}'s username ({name}) successfully",
        fail = "Delete user{id}'s username ({name}) failed",
        user_id_invalid = "Delete user{id} failed",
        user_mgnt_disabled = "Delete user{id} failed"
    },
    IpmiSetUserAccess = {
        success = 'Modify user({name}|user{id}) channel({channel_number}) privilege({privilege}), '..
            'session_limit({session_limit}) successfully',
        fail = 'Modify user({name}|user{id}) channel({channel_number}) privilege to ({privilege}) failed',
        changeable = 'Modify user({name}|user{id}) channel({channel_number}) privilege({privilege}), '..
            'session_limit({session_limit}), msg_enable({msg_enable}), link_auth({link_auth}), '..
            'callback({callback}) successfully',
        no_user = 'Modify user channel({channel_number}) privilege to ({privilege}) failed',
        user_mgnt_disabled = "Modify user{id} channel({channel_number}) privilege to ({privilege}) failed"
    },
    IpmiSetTwoFactorAuthState = {
        success = '{state} two-factor authentication and {state_ocsp} certificate revocation check successfully',
        fail = '{state} two-factor authentication and {state_ocsp} certificate revocation check failed',
        fail_ocsp = '{state} two-factor authentication successfully and ' ..
            '{state_ocsp} certificate revocation check failed'
    },
    IpmiSetUserInterface = {
        success = 'Modify {username} login interface ({change}) successfully',
        fail = 'Set User login interface failed',
        ['kepler.account.ParameterInvalid'] = 'Set User(|user{id})login interface failed'
    },
    IpmiSetSNMPConfiguration = {
        success = 'Set SNMP configuration successfully',
        fail = 'Set SNMP configuration failed',
        community_success = 'Set SNMP {com_type} community string successfully',
        delete_success = 'Delete SNMP {com_type} community string successfully',
        community_failed = 'Set SNMP community string failed',
        enabled_long_success = '{operation} long community string successfully',
        enabled_long_failed = 'Set long community string enable failed'
    },
    IpmiSetAccountServiceConfiguration = {
        success = 'Set Account Service configuration successfully',
        fail = 'Set Account Service configuration failed'
    },
    IpmiUserAuthentication = {
        unlock_success = 'Unlock user({user_name}) successfully',
        unlock_failed = 'Unlock user({user_name}) failed'
    },
    CheckVncPassword = {
        success = 'Check VNC password successfully',
        fail = 'Check VNC password failed',
        lock = 'Check VNC password failed, because account is locked'
    },
    UserNamePasswordPrefixCompareInfo = {
        success = '{state} username password check and set username password check length successfully',
        enable_failed = 'Set username password check length successfully, but set username password check failed',
        fail = 'Failed to set username password compare'
    },
    --------------------- Ipmi end  -------------------------

    ---------------- account_service_mdb --------------------
    PasswordComplexityEnable = {
        success = '{state} local user password complexity check successfully',
        fail = '{state} local user password complexity check failed'
    },
    InitialPasswordPromptEnable = {
        success = 'Set initial password prompt ({state}) successfully',
        fail = 'Set initial password prompt failed'
    },
    InitialPasswordNeedModify = {
        success = 'Set initial password {state} successfully',
        fail = 'Set initial password modify requirement failed'
    },
    InitialAccountPrivilegeRestrictEnabled = {
        success = '{state} initial account privilege restrict successfully',
        fail = '{state} initial account privilege restrict failed'
    },
    MaxPasswordValidDays = {
        success = 'Set password expired time to ({max_valid_days}) days successfully',
        fail = 'Set password expired time failed'
    },
    MinPasswordValidDays = {
        success = 'Set password minimum time to ({min_valid_days}) days successfully',
        fail = 'Set password minimum time failed'
    },
    WeakPasswordDictionaryEnabled = {
        success = '{state} weak password dictionary check successfully',
        fail = '{state} weak password dictionary check successfully'
    },
    EmergencyLoginAccountId = {
        success = 'Set exclude user to ({name}) successfully',
        fail = 'Set exclude user failed',
        remove = 'Remove emergency user successfully'
    },
    SNMPv3TrapAccountId = {
        success = 'Set SNMP trapv3 user name successfully',
        fail = 'Set SNMP trapv3 user name failed'
    },
    SNMPv3TrapAccountLimitPolicy = {
        Modifiable = 'Set SNMP v3 trap account limit policy successfully, ' ..
            'and user can rename or delete v3 trap account',
        NameModifiable = 'Set SNMP v3 trap account limit policy successfully, and user can rename v3 trap account',
        NotModifiable = 'Set SNMP v3 trap account limit policy successfully, ' ..
            'and user can not rename or delete v3 trap account',
        fail = 'Set SNMP v3 trap account limit policy failed'
    },
    SNMPv3TrapAccountChangePolicy = {
        AllowedChangeable = 'Set SNMP v3 trap account change policy successfully, ' ..
            'and user can rename or delete v3 trap account',
        NotChangeable = 'Set SNMP v3 trap account change policy successfully, ' ..
            'and v3 trap account change policy controlled by SNMPv3TrapAccountLimitPolicy',
        fail = 'Set SNMP v3 trap account change policy failed'
    },
    RequireChangePasswordAction = {
        success = '{action} require change password action successfully',
        fail = '{action} require change password action failed'
    },
    InactiveDaysThreshold = {
        success = 'Set user inactive threshold to ({threshold}) days successfully',
        fail = 'Set inactive user timelimit time failed',
        ['kepler.account.ValueOutOfRange'] = 'Set Inactive user time failed'
    },
    HistoryPasswordCount = {
        success = 'Set number of history password for comparision to ({count}) successfully',
        fail = 'Set number of history password for comparision failed',
        disable = 'Disable history password comparision successfully'
    },
    MaxHistoryPasswordCount = {
        success = 'Set number of max history password for comparision to ({count}) successfully',
        fail = 'Set number of max history password for comparision failed'
    },
    MinPasswordLength = {
        success = 'Set minimum password length to ({length}) successfully',
        fail = 'Set minimum password length to ({length}) failed',
        ['kepler.account.ValueOutOfRange'] = 'Set minimum password length failed'
    },
    HostUserManagementEnabled = {
        success = '{state} the BMC user management function on the host side',
        fail = 'Set user management status failed'
    },
    OSAdministratorPrivilegeEnabled = {
        success = '{state} the OS administrator privilege on the host side',
        fail = 'Set OS administrator privilege failed'
    },
    NamePatternChange = {
        success = 'Change name pattern successfully',
        fail = 'Change name pattern failed'
    },
    SetAllowedLoginInterfaces = {
        success = 'Set allowed login interfaces to ({interfaces}) successfully',
        fail = 'Set allowed login interfaces failed',
    },
    VisibleChange = {
        success = 'Set {account_type} visible to ({status}) successfully',
        fail = 'Set {account_type} visible failed',
        invalid_account_type = 'Set visible failed'
    },
    DeletableChange = {
        success = 'Set {account_type} deletable to ({status}) successfully',
        fail = 'Set {account_type} deletable failed',
        invalid_account_type = 'Set deletable failed'
    },
    ---------------- account_service_mdb end --------------------

    ---------------------- login_rule_mdb -----------------------
    RuleEnabled = {
        success = '{state} login rule ({id}) successfully',
        fail = 'Set enabled login rule Id failed'
    },
    IpRule = {
        success = 'Modify login rule{id} config source IP to ({ip_info}) successfully',
        fail = 'Modify login rule{id} config source IP to ({ip_info}) failed'
    },
    MacRule = {
        success = 'Modify login rule{id} config source MAC to ({mac_info}) successfully',
        fail = 'Modify login rule{id} config source MAC to ({mac_info}) failed'
    },
    TimeRule = {
        success = 'Modify login rule{id} config time range to ({time_info}) successfully',
        fail = 'Modify login rule{id} config time range to ({time_info}) failed'
    },
    -----------------  login_rule_mdb end  ----------------------

    ---------------------- account_mdb --------------------------
    AccountRoleId = {
        success = 'Set user({name}|user{id}) userrole to ({role}) successfully',
        fail = 'Set user({name}|user{id}) userrole to ({role}) failed',
        exclude_user_or_last_admin = 'Set user({name}|user{id}) userrole failed',
        ['kepler.account.InvalidAccountId'] = 'Set user role failed'
    },
    AccountEnabled = {
        success = '{state} user({name}|user{id}) successfully',
        fail = 'Set user enable state failed'
    },
    FirstLoginPolicy = {
        success = 'Set {name} first login policy to {policy} password reset successfully',
        fail = 'Set {name} first login policy to {policy} password reset failed',
        ['kepler.account.InvalidAccountId'] = 'Set first login policy failed'
    },
    --------------------       end      -------------------------

    ------------  login interface and login rule  ---------------
    LoginInterface = {
        success = 'Modify {username} login interface ({change}) successfully',
        fail = 'Modify {username} login interface ({interface}) failed'
    },
    LoginRule = {
        success = 'Modify {username} login rule ({change}) successfully',
        fail = 'Modify {username} login rule to ({rule}) failed'
    },
    -----------  login interface and login rule end -------------

    ------------------ ldap_controller_mdb ----------------------
    LdapControllerEnabled = {
        success = '{state} LDAP{id} successfully',
        fail = '{state} LDAP{id} failed'
    },
    LdapControllerHostAddr = {
        success = 'Set LDAP{id} server addr to ({addr}) successfully',
        fail = 'Set LDAP{id} server addr failed'
    },
    LdapControllerPort = {
        success = 'Set LDAP{id} port to ({port}) successfully',
        fail = 'Set LDAP{id} port failed'
    },
    LdapControllerDomain = {
        success = 'Set LDAP{id} user domain to ({domain}) successfully',
        fail = 'Set LDAP{id} user domain failed'
    },
    LdapControllerFolder = {
        success = 'Set LDAP{id} user folder to ({folder}) successfully',
        fail = 'Set LDAP{id} user folder failed'
    },
    LdapControllerBindDn = {
        success = 'Set LDAP{id} bind DN to ({bind_dn}) successfully',
        fail = 'Set LDAP{id} bind DN failed'
    },
    LdapControllerCertVerifyEnabled = {
        success = '{state} LDAP{id} certificate verification successfully',
        fail = '{state} LDAP{id} certificate verification failed'
    },
    LdapControllerCertVerifyLevel = {
        success = 'Set LDAP{id} Certificate Verification Level({level}) successfully',
        fail = 'Set LDAP{id}  Certificate Verification Level({level}) failed'
    },
    ---------------- ldap_controller_mdb end --------------------

    ------------------    ldap_config_mdb    --------------------
    LdapEnabled = {
        success = '{state} LDAP service successfully',
        fail = '{state} LDAP service failed'
    },
    ----------------   ldap_config_mdb end   --------------------

    ------------------    kerberos_config_mdb    --------------------
    KerberosEnabled = {
        success = '{state} Kerberos service successfully',
        fail = '{state} Kerberos service failed'
    },
    KerberosAddress = {
        success = 'Set Kerberos server address to ({address}) successfully',
        fail = 'Set Kerberos server address to ({address}) failed'
    },
    KerberosPort = {
        success = 'Set Kerberos server port to ({port}) successfully',
        fail = 'Set Kerberos server port to ({port}) failed'
    },
    KerberosRealm = {
        success = 'Set Kerberos server realm to ({realm}) successfully',
        fail = 'Set Kerberos server realm to ({realm}) failed'
    },
    ImportKeyTable = {
        success = 'Upload kerberos key table successfully',
        fail = 'Upload kerberos key table failed'
    },
    ----------------   kerberos_config_mdb end   --------------------

    -----------------  session_service_mdb ----------------------
    SessionTimeout = {
        success = 'Set {type} session timeout to ({time}) minutes successfully',
        fail = 'Set {type} session timeout value failed'
    },
    SessionMode = {
        success = 'Set web session mode to ({mode}) successfully',
        fail = 'Set web session mode value failed'
    },
    SessionMaxCount = {
        success = 'Set session max count to {count} successfully',
        fail = 'Set session max count to {count} failed'
    },
    NewSession = {
        security_log = true,
        success = 'User {username}({ip}) login successfully',
        fail = 'User {username}({ip}) login failed'
    },
    NewSsoSession = {
        success = 'Get sso token successfully',
        fail = 'Get sso token failed'
    },
    NewSessionBySSO = {
        success = 'User {username}({ip}) login to {type} by sso successfully',
        fail = 'User {username}({ip}) login to {type} by sso failed'
    },
    NewRemoteConsoleSession = {
        success = 'User {username}({ip}) login successfully({mode} mode)',
        fail = 'User {username}({ip}) login failed'
    },
    NewVNCSession = {
        security_log = true,
        success = 'New VNC({mode}) session successfully',
        fail = 'New VNC session failed'
    },
    DeleteSession = {
        SessionRelogin = 'User {username}({ip}) is forced to log out because the same user log in from another device',
        SessionTimeout = 'User {username}({ip}) logged out due to session timeout',
        SessionKickout = 'Kick user(username:{username}|client type:{session_type}|client IP:{ip}) out successfully',
        SessionLogout = ' User {username}({ip}) logout successfully',
        AccountConfigChange = 'User {username}({ip}) logged out due to user information change',
        BMCConfigChange = 'User {username}({ip}) logged out due to network configuration change',
        fail = 'User {username}({ip}) logout failed',
        ssoipmifail = 'Delete SSO session failed.'
    },
    UserNamePasswordPrefixCompareEnabled = {
        success = '{state} username password check successfully',
        fail = '{state} username password check failed'
    },
    UserNamePasswordPrefixCompareLength = {
        success = 'Set username password check length successfully',
        fail = 'Set username password check length failed'
    },
    ---------------  session_service_mdb end  -------------------

    -------------------  remote_group_mdb  ----------------------
    SID = {
        success = 'Set {id} SID successfully',
        fail = 'Set {id} SID failed'
    },
    RemoteGroupName = {
        success = 'Set {id} name to ({name}) successfully',
        fail = 'Set {id} name to ({name}) failed'
    },
    RemoteGroupRoleId = {
        success = 'Set {id} userrole to ({role_name}) successfully',
        fail = 'Set {id} userrole to ({role_name}) failed',
        ['kepler.account.AuthorizationFailed'] = 'Set {id} userrole to (Unknown) failed'
    },
    RemoteGroupFolder = {
        success = 'Set {id} folder to ({folder}) successfully',
        fail = 'Set {id} folder to ({folder}) failed',
        clear = 'The folder of {id} cleared successfully'
    },
    RemoteGroupPrivilegeMask = {
        success = 'Set {id} privilege mask to ({mask}) successfully',
        fail = 'Set {id} privilege mask to ({mask}) failed',
        clear = 'The privilege mask of {id} cleared successfully'
    },
    RemoteGroupDomain = {
        success = 'Set {id} domain to ({domain}) successfully',
        fail = 'Set {id} domain to ({domain}) failed',
        clear = 'The domain of {id} cleared successfully'
    },
    ---------------  remote_group_mdb end  -------------------

    -----------  certificate_authentication_mdb  -------------
    TwoFactorEnabled = {
        success = '{state} two-factor authentication successfully',
        fail = '{state} two-factor authentication failed',
    },
    TwoFactorOCSPEnabled = {
        success = '{state} certificate revocation check successfully',
        fail = '{state} certificate revocation check failed',
    },
    -----------  certificate_authentication_mdb end  ---------
    -----------------    authenticate_mdb   ------------------
    Authenticate = {
        fail = 'User {username} authentication failed'
    },
    -----------------------    end   -------------------------
    ----------------    usb_authentication   -----------------
    SetDecryptPassword = {
        success = 'Set USB uncompress password successfully',
        fail = 'Set USB uncompress password failed'
    },
    -----------------------    end   -------------------------
    -------------------  accout_recover  ---------------------
    RecoverAccount = {
        success = 'Recover Account{id} data successfully',
        fail = "Recover Account{id} data failed"
    },
    -----------------------    end   -------------------------
    ------------------  password_policy  ---------------------
    PasswordPolicy = {
        success = 'Set {account_type} password policy to {policy} successfully',
        fail = 'Set {account_type} password policy failed',
        invalid_account_type = 'Set password policy failed'
    },
    PasswordPattern = {
        success = 'Set {account_type} password pattern successfully',
        fail = 'Set {account_type} password pattern failed',
        invalid_account_type = 'Set password policy failed'
    },
    MaxPasswordLength = {
        success = 'Set {account_type} max password length to {length} successfully',
        fail = 'Set {account_type} max password length failed',
        invalid_account_type = 'Set max password length failed'
    },
    -----------------------    end   -------------------------
    ---------------  role_privilege_mdb end  -------------------
    SetExtendedCustomRoleEnabled = {
        success = 'Set extended custom role {state} successfully',
        fail = 'Set extended custom role {state} failed'
    },
    -----------------------    end   -------------------------
    ----------------------    other   ------------------------
    ConfigureSelfAuthFailed = {
        fail = 'Failed to {operation}, because the operation is allowed by administrator or account itself only'
    },
    MutualLogin = {
        success = '{UserName}({Ip}) login successfully over the WebUI',
        fail = "Login failed by certificate"
    },
    SetAccountWritable = {
        success = 'Set account(user{account_id}) properties writable({writable_log}) successfully',
        fail = 'Set account(user{account_id}) properties writable failed'
    },
    SetAccountLockState = {
        success = '{lock_state} user{account_id} ({user_name}) successfully',
        fail = 'Set user{account_id} ({user_name}) lock state failed'
    }
}

--- 替换占位符
---@param log string
---@param params table
local function replacePlaceholder(log, params)
    if type(log) ~= 'string' or type(params) ~= 'table' then
        return log
    end

    for key, value in pairs(params) do
        value = string.gsub(value, '%%', '%%%%') -- 对转义符做处理
        log = string.gsub(log, table.concat({ '{', key, '}' }), value)
    end

    return log
end

--- 操作日志打印函数
---@param ctx table 上下文
---@param result string 操作结果
function OperationLogger.log(ctx, result)
    if not ctx.operation_log then
        return
    end
    if ctx.UserName == '<host sms>' then
        return
    end

    local operation_logs = operation_log_map[ctx.operation_log.operation] or {}
    local operation_log = (operation_logs[ctx.operation_log.result] or operation_logs[result]) or
        (operation_log_map[ctx.operation_log.result] or operation_log_map[result])
    local format_log = replacePlaceholder(operation_log, ctx.operation_log.params)
    if not format_log then return end
    if ctx.ChanType then
        ipmi.ipmi_operation_log(ctx, 'account', format_log)
        return
    end
    logging:operation(ctx:get_initiator(), 'account', format_log)
    if operation_logs['security_log'] then
        logging:security(format_log)
    end
end

--- 安全调用函数并打印操作日志
---@param ctx table 上下文
---@param func function 调用函数
function OperationLogger.safe_call(ctx, func)
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    local result = table.pack(pcall(func))
    local ok = result[1]
    table.remove(result, 1)

    if not ok then
        local err = result[1]
        ctx.operation_log.result = ctx.operation_log.result or err.name
        local err_detail = string.match(tostring(err), '([%w%:%s%.%_]-)$')
        logging:error(string.format('%s: %s %s', ctx.operation_log.operation, err.name, err_detail))
        OperationLogger.log(ctx, 'fail')
        ctx.operation_log = nil
        error(err)
    end

    OperationLogger.log(ctx, 'success')
    ctx.operation_log = nil
    return table.unpack(result)
end

--- 操作日志代理
---@param func function 被代理函数
---@param operation string 操作动作
function OperationLogger.proxy(func, operation)
    return function(obj, ctx, ...)
        -- 由于ctx被框架使用，这里直接copy一份ctx出来在业务中使用
        local dup_ctx = mc_utils.table_copy(ctx)
        local args = { ... }
        return OperationLogger.safe_call(dup_ctx, function()
            dup_ctx.operation_log = { operation = operation, result = nil, params = {} }
            return func(obj, dup_ctx, table.unpack(args))
        end)
    end
end

return OperationLogger