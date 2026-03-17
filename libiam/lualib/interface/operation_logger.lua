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
local class = require 'mc.class'
local log = require 'mc.logging'
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
        ['kepler.iam.InvalidAccountId'] = 'Create user(user{id}) failed, account id is invalid',
        ['kepler.iam.UserFull'] = 'Create user failed, cannot add more user'
    },
    NewCustomAccount = {
        success = 'Create user({name}|user{id}) role({role}) login interface({interface}) ' ..
            'first_login_policy({first_login_policy}) successfully',
        fail = 'Create user failed, information is invalid',
        ['kepler.iam.InvalidAccountId'] = 'Create user(user{id}) failed, account id is invalid',
        ['kepler.iam.UserFull'] = 'Create user failed, cannot add more user'
    },
    DeleteAccount = {
        success = 'Delete user({name}|user{id}) successfully',
        fail = 'Delete user({name}|user{id}) failed',
        ['kepler.iam.InvalidAccountId'] = 'Delete user(user{id}) failed, account id is invalid'
    },
    TestUserPassword = {
        success = 'Test user({name}|user{id}) password successfully',
        fail = "Test user{id}'s password failed",
        fail_ret = 'Test user({name}|user{id}) password failed, ret = {ret}'
    },
    ChangeVNCPwd = {
        success = 'VNC password set successfully',
        fail = 'Failed to set the VNC password'
    },
    ChangeAccountSnmpPwd = {
        success = 'Set user({name}|user{id}) SNMP privacy password successfully',
        fail = 'Set user({name}|user{id}) SNMP privacy password failed',
        ['kepler.iam.InvalidAccountId'] = 'Set user SNMP privacy password failed'
    },
    SetAuthenticationProtocol = {
        success = 'Set user({name}|user{id}) SNMP authentication protocol to {protocol} ' ..
            'and update user password successfully',
        fail = 'Set user({name}|user{id}) SNMP authentication protocol failed',
        ['kepler.iam.InvalidAccountId'] = 'Set user SNMP authentication protocol failed'
    },
    SetEncryptionProtocol = {
        success = 'Set user({name}|user{id}) SNMP privacy protocol to {protocol} successfully',
        fail = 'Set user({name}|user{id}) SNMP privacy protocol failed',
        ['kepler.iam.InvalidAccountId'] = 'Set SNMP privacy protocol failed'
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
    ------------------------ rpc end ------------------------

    ------------------------   Ipmi  ------------------------
    IpmiNewAccount = {
        success = "Add user{id}'s username ({name}) successfully",
        fail = "Add user{id}'s username ({name}) failed"
    },
    IpmiAccountEnabled = {
        success = '{operate} user({name}|user{id}) successfully',
        fail = '{operate} user({name}|user{id}) failed, ret = {ret}'
    },
    IpmiSetUserPassComplexity = {
        success = '{state} local user password complexity check successfully',
        fail = '{state} local user password complexity check failed',
        ['kepler.iam.HostUserManagementDiabled']  = 'Set local user password complexity check status failed',
        ['kepler.iam.InvalidParameter']  = 'Set local user password complexity check status failed',
        ['kepler.iam.PasswordForbidSetComplexityCheck'] = 'Set local user password complexity check status failed',
        user_mgnt_disabled = 'Set local user password complexity check status failed'
    },
    IpmiDeleteAccount = {
        success = "Delete user{id}'s username ({name}) successfully",
        fail = "Delete user{id}'s username ({name}) failed"
    },
    IpmiSetUserAccess = {
        success = 'Modify user({name}|user{id}) privilege to ({privilege}) successfully',
        fail = 'Modify user({name}|user{id}) privilege to ({privilege}) failed',
        no_user = 'Modify user privilege to ({privilege}) failed',
        user_mgnt_disabled = "Modify user{id} privilege to ({privilege}) failed"
    },
    -- TODO需支持一个代理记录多条日志
    IpmiSetTwoFactorAuthState = {
        success = '{state} two-factor authentication and {state_ocsp} certificate revocation check successfully',
        fail = '{state} two-factor authentication and {state_ocsp} certificate revocation check failed',
        fail_ocsp = '{state} two-factor authentication successfully and ' ..
            '{state_ocsp} certificate revocation check failed'
    },
    IpmiSetUserInterface = {
        success = 'Modify {username} login interface ({change}) successfully',
        fail = 'Set User login interface failed',
        ['kepler.iam.ParameterInvalid'] = 'Set User(|user{id})login interface failed'
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
    AccountLockoutDuration = {
        success = 'Set authentication failure lock time to ({duration}) minutes successfully',
        fail = 'Set authentication failure lock time failed'
    },
    AccountLockoutThreshold = {
        success = 'Set authentication failure max count to {threshold} successfully',
        fail = 'Set authentication failure max count failed'
    },
    MaxAccountLockoutDuration = {
        success = 'Set authentication failure max lock time to ({duration}) minutes successfully',
        fail = 'Set authentication failure max lock time failed'
    },
    MaxAccountLockoutThreshold = {
        success = 'Set Max authentication failure max count to {threshold} successfully',
        fail = 'Set Max authentication failure max count failed'
    },
    AccountLockoutCounterResetAfter = {
        success = 'Set authentication failure count reset time to {reset_time} seconds successfully',
        fail = 'Set authentication failure count reset time failed'
    },
    LocalAccountAuth = {
        success = 'Set authentication mode to {mode} successfully',
        fail = 'Set authentication mode failed'
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
    InactiveDaysThreshold = {
        success = 'Set user inactive threshold to ({threshold}) days successfully',
        fail = 'Set inactive user timelimit time failed',
        ['kepler.iam.ValueOutOfRange'] = 'Set Inactive user time failed'
    },
    HistoryPasswordCount = {
        success = 'Set number of history password for comparision to ({count}) successfully',
        fail = 'Set number of history password for comparision failed',
        disable = 'Disable history password comparision successfully'
    },
    MinPasswordLength = {
        success = 'Set minimum password length to ({length}) successfully',
        fail = 'Set minimum password length to ({length}) failed',
        ['kepler.iam.ValueOutOfRange'] = 'Set minimum password length failed'
    },
    HostUserManagementEnabled = {
        success = '{state} the BMC user management function on the host side',
        fail = 'Set user management status failed'
    },
    OSAdministratorPrivilegeEnabled = {
        success = '{state} the OS administrator privilege on the host side',
        fail = 'Set OS administrator privilege failed'
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
        ['kepler.iam.InvalidAccountId'] = 'Set user role failed'
    },
    AccountEnabled = {
        success = '{state} user({name}|user{id}) successfully',
        fail = 'Set user enable state failed'
    },
    FirstLoginPolicy = {
        success = 'Set {name} first login policy to {policy} password reset successfully',
        fail = 'Set {name} first login policy to {policy} password reset failed',
        ['kepler.iam.InvalidAccountId'] = 'Set first login policy failed'
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
        success = 'Set {type} session timeout to ({time}) {timeunit} successfully',
        fail = 'Set {type} session timeout value failed',
    },
    SessionMode = {
        success = 'Set {type} session mode to ({mode}) successfully',
        fail = 'Set {type} session mode value failed'
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
        success_multihost = 'User {username}({ip}) systemid({systemid}) login successfully({mode} mode)',
        fail = 'User {username}({ip}) login failed',
        fail_multihost = 'User {username}({ip}) systemid({systemid}) login failed'
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
    ValidateSsoClient = {
        success = 'Set validate sso client verify to {state} successfully',
        fail = 'Set validate sso client verify to {state} failed'
    },
    SsoEnabled = {
        success = '{state} Web Rest Single Sign-On successfully',
        fail = '{state} Web Rest Single Sign-On failed'
    },
    AbsoluteSessionTimeoutEnabled = {
        success = '{state} Absolute Session Timeout successfully',
        fail = '{state} Absolute Session Timeout failed'
    },
    AbsoluteSessionTimeout = {
        success = 'Change Absolute Session Timeout to {timeout_value} seconds successfully',
        fail = 'Change Absolute Session Timeout to {timeout_value} seconds failed'
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
        ['kepler.iam.AuthorizationFailed'] = 'Set {id} userrole to (Unknown) failed'
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
    SetAllowedLoginInterfaces = {
        success = 'Set allowed login interfaces to ({interfaces}) successfully',
        fail = 'Set allowed login interfaces failed',
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
    InterChassisAuthEnabled = {
        success = '{state} inter chassis authentication successfully',
        fail = '{state} inter chassis authentication failed'
    },
    InterChassisValidation = {
        success = 'Set inter chassis authentication validate mode to {value} successfully',
        fail = 'Set inter chassis authentication validate mode failed'
    },
    ManageInterChassisWhitelist = {
        add_success = 'Add inter chassis authentication {type} whitelist success',
        add_fail = 'Add inter chassis authentication {type} whitelist failed',
        remove_success = 'Remove inter chassis authentication {type} whitelist success',
        remove_fail = 'Remove inter chassis authentication {type} whitelist failed',
        fail = 'Manage inter chassis authentication {type} whitelist failed'
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
    },
    SetLdapConfiguration = {
        success = 'Set LDAP {name} {property_name} to {value} successfully',
        fail = 'Set LDAP {name} {property_name} to {value} failed'
    }
}

--- 替换占位符
---@param log string
---@param params table
local function replacePlaceholder(operation_log, params)
    if type(operation_log) ~= 'string' or type(params) ~= 'table' then
        return operation_log
    end

    for key, value in pairs(params) do
        value = string.gsub(value, '%%', '%%%%') -- 对转义符做处理
        operation_log = string.gsub(operation_log, table.concat({ '{', key, '}' }), value)
    end

    return operation_log
end

--- 操作日志打印函数
---@param ctx table 上下文
---@param result string 操作结果
function OperationLogger.log(ctx, result)
    if not ctx.operation_log then
        return
    end
    -- 处理BMA通道操作日志
    if ctx.UserName == '<host sms>' then
        return
    end

    local operation_logs = operation_log_map[ctx.operation_log.operation] or {}
    local operation_log = (operation_logs[ctx.operation_log.result] or operation_logs[result]) or
        (operation_log_map[ctx.operation_log.result] or operation_log_map[result])
    local format_log = replacePlaceholder(operation_log, ctx.operation_log.params)
    if not format_log then return end
    if ctx.ChanType then
        ipmi.ipmi_operation_log(ctx, 'iam', format_log)
        return
    end
    log:operation(ctx:get_initiator(), 'iam', format_log)
    if operation_logs['security_log'] then
        log:security(format_log)
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
        log:error(string.format('%s: %s %s', ctx.operation_log.operation, err.name, err_detail))
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