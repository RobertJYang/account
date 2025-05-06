-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local M = {}

M.t_account_service = {{Id = 1, MaxPasswordLength = 20, AccountLockoutCounterResetEnabled = false}}
M.t_authentication = {{Id = 1, AccountLockoutDuration = 300, AccountLockoutThreshold = 5}}
M.t_certificate_authentication = {{Id = 1, Enabled = false, OCSPEnabled = false}}
M.t_manager_account = {
    {
        Id = 2,
        RoleId = 4,
        UserName = [=[Administrator]=],
        FirstLoginPolicy = [=[ForcePasswordReset]=],
        Password = [=[]=],
        IpmiPassword = [=[]=],
        AccountType = 0,
        Enabled = true,
        LoginInterface = 255,
        LoginRuleIds = 0,
        IpmiPasswordBak = ''
    }, {
        Id = 18,
        RoleId = 4,
        UserName = [=[<vnc>]=],
        Password = [=[]=],
        IpmiPassword = [=[]=],
        FirstLoginPolicy = [=[PromptPasswordReset]=],
        AccountType = 3,
        LoginInterface = 0,
        LoginRuleIds = 0,
        IpmiPasswordBak = ''
    }, {
        Id = 19,
        RoleId = 4,
        UserName = [=[<ipmi>]=],
        Password = [=[]=],
        IpmiPassword = [=[]=],
        FirstLoginPolicy = [=[PromptPasswordReset]=],
        AccountType = 6,
        LoginInterface = 0,
        LoginRuleIds = 0,
        IpmiPasswordBak = ''
    }, {
        Id = 20,
        RoleId = 4,
        UserName = [=[<ro_community>]=],
        Password = [=[]=],
        IpmiPassword = [=[]=],
        FirstLoginPolicy = [=[PromptPasswordReset]=],
        AccountType = 7,
        LoginInterface = 0,
        LoginRuleIds = 0,
        IpmiPasswordBak = ''
    }, {
        Id = 21,
        RoleId = 4,
        UserName = [=[<rw_community>]=],
        Password = [=[]=],
        IpmiPassword = [=[]=],
        FirstLoginPolicy = [=[PromptPasswordReset]=],
        AccountType = 7,
        LoginInterface = 0,
        LoginRuleIds = 0,
        IpmiPasswordBak = ''
    }, {
        Id = 22,
        RoleId = 2,
        UserName = [=[<host sms>]=],
        Password = [=[]=],
        IpmiPassword = [=[]=],
        FirstLoginPolicy = [=[PromptPasswordReset]=],
        AccountType = 6,
        LoginInterface = 128,
        LoginRuleIds = 0,
        IpmiPasswordBak = ''
    }
}
M.t_snmp_user_info = {
    {
        AccountId = 2,
        AuthenticationProtocol = [=[SNMPAuthenticationProtocols_SHA512]=],
        EncryptionProtocol = [=[SNMPEncryptionProtocols_AES128]=],
        AuthenticationKey = [=[]=],
        EncryptionKey = [=[]=],
        SNMPPassword = [=[]=]
    }
}
M.t_ipmi_user_info = {{AccountId = 2}, {AccountId = 18}, {AccountId = 19}}
M.t_role = {
    {
        Id = 4,
        RoleName = [=[Administrator]=],
        UserMgmt = true,
        BasicSetting = true,
        KVMMgmt = true,
        ReadOnly = true,
        VMMMgmt = true,
        SecurityMgmt = true,
        PowerMgmt = true,
        DiagnoseMgmt = true,
        ConfigureSelf = true
    }, {
        Id = 3,
        RoleName = [=[Operator]=],
        UserMgmt = false,
        BasicSetting = true,
        KVMMgmt = true,
        ReadOnly = true,
        VMMMgmt = true,
        SecurityMgmt = false,
        PowerMgmt = true,
        DiagnoseMgmt = false,
        ConfigureSelf = true
    }, {Id = 2, RoleName = [=[CommonUser]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 0, RoleName = [=[NoAccess]=]},
    {Id = 5, RoleName = [=[CustomRole1]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 6, RoleName = [=[CustomRole2]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 7, RoleName = [=[CustomRole3]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 8, RoleName = [=[CustomRole4]=], ReadOnly = true, ConfigureSelf = true}
}
M.t_session_service = {
    {
        SessionType = [=[SessionType_GUI]=],
        SessionTimeout = 300,
        SessionModeDB = [=[OccupationMode_Shared]=],
        SessionMaxCount = 4
    }, {
        SessionType = [=[SessionType_Redfish]=],
        SessionTimeout = 300,
        SessionModeDB = [=[OccupationMode_Shared]=],
        SessionMaxCount = 10
    }, {
        SessionType = [=[SessionType_CLI]=],
        SessionTimeout = 900,
        SessionModeDB = [=[OccupationMode_Shared]=],
        SessionMaxCount = 10
    }, {
        SessionType = [=[SessionType_SSO]=],
        SessionTimeout = 60,
        SessionModeDB = [=[OccupationMode_Exclusive]=],
        SessionMaxCount = 1
    }, {
        SessionType = [=[SessionType_KVM]=],
        SessionTimeout = 3600,
        SessionModeDB = [=[OccupationMode_Shared]=],
        SessionMaxCount = 2
    }, {
        SessionType = [=[SessionType_VNC]=],
        SessionTimeout = 3600,
        SessionModeDB = [=[OccupationMode_Shared]=],
        SessionMaxCount = 5
    }, {
        SessionType = [=[SessionType_VIDEO]=],
        SessionTimeout = 600,
        SessionModeDB = [=[OccupationMode_Exclusive]=],
        SessionMaxCount = 1
    }
}
M.t_login_rule = {
    {RuleId = 1, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false},
    {RuleId = 2, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false},
    {RuleId = 3, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false}
}
M.t_ldap = {{Id = 1, Enabled = false}}
M.t_ldap_controller = {
    {
        Id = 1,
        Enabled = true,
        HostAddr = [=[]=],
        Port = 636,
        UserDomain = [=[]=],
        LdapVer = 3,
        Folder = [=[]=],
        BaseDN = [=[]=],
        BindDN = [=[]=],
        BindDNPsw = [=[]=],
        Scope = [=[sub]=],
        TimeLimit = 2,
        BindTimeLimit = 2,
        CertVerifyEnabled = false,
        CertVerifyLevel = 2,
        CRLVerificationEnable = false
    }, {
        Id = 2,
        Enabled = true,
        HostAddr = [=[]=],
        Port = 636,
        UserDomain = [=[]=],
        LdapVer = 3,
        Folder = [=[]=],
        BaseDN = [=[]=],
        BindDN = [=[]=],
        BindDNPsw = [=[]=],
        Scope = [=[sub]=],
        TimeLimit = 2,
        BindTimeLimit = 2,
        CertVerifyEnabled = false,
        CertVerifyLevel = 2,
        CRLVerificationEnable = false
    }, {
        Id = 3,
        Enabled = true,
        HostAddr = [=[]=],
        Port = 636,
        UserDomain = [=[]=],
        LdapVer = 3,
        Folder = [=[]=],
        BaseDN = [=[]=],
        BindDN = [=[]=],
        BindDNPsw = [=[]=],
        Scope = [=[sub]=],
        TimeLimit = 2,
        BindTimeLimit = 2,
        CertVerifyEnabled = false,
        CertVerifyLevel = 2,
        CRLVerificationEnable = false
    }, {
        Id = 4,
        Enabled = true,
        HostAddr = [=[]=],
        Port = 636,
        UserDomain = [=[]=],
        LdapVer = 3,
        Folder = [=[]=],
        BaseDN = [=[]=],
        BindDN = [=[]=],
        BindDNPsw = [=[]=],
        Scope = [=[sub]=],
        TimeLimit = 2,
        BindTimeLimit = 2,
        CertVerifyEnabled = false,
        CertVerifyLevel = 2,
        CRLVerificationEnable = false
    }, {
        Id = 5,
        Enabled = true,
        HostAddr = [=[]=],
        Port = 636,
        UserDomain = [=[]=],
        LdapVer = 3,
        Folder = [=[]=],
        BaseDN = [=[]=],
        BindDN = [=[]=],
        BindDNPsw = [=[]=],
        Scope = [=[sub]=],
        TimeLimit = 2,
        BindTimeLimit = 2,
        CertVerifyEnabled = false,
        CertVerifyLevel = 2,
        CRLVerificationEnable = false
    }, {
        Id = 6,
        Enabled = true,
        HostAddr = [=[]=],
        Port = 636,
        UserDomain = [=[]=],
        LdapVer = 3,
        Folder = [=[]=],
        BaseDN = [=[]=],
        BindDN = [=[]=],
        BindDNPsw = [=[]=],
        Scope = [=[sub]=],
        TimeLimit = 2,
        BindTimeLimit = 2,
        CertVerifyEnabled = false,
        CertVerifyLevel = 2,
        CRLVerificationEnable = false
    }
}
M.t_kerberos = {{Id = 1, Enabled = false, Address = [=[]=], Port = 88, Realm = [=[]=]}}
M.t_snmp_community = {{Id = 1, LongCommunityEnabled = true, RwCommunityEnabled = true}}
M.t_password_policy = {
    {AccountType = 0, Policy = 1, Pattern = [=[]=]}, {AccountType = 3, Policy = 1, Pattern = [=[]=]},
    {AccountType = 7, Policy = 1, Pattern = [=[]=]}
}
M.t_account_policy = {
    {
        AccountType = 0,
        NamePattern = [=[]=],
        AllowedLoginInterfaces = 223
    }
}
return M
