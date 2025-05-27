-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local M = {}

M.t_login_rule = {
    {RuleId = 1, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false},
    {RuleId = 2, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false},
    {RuleId = 3, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false}
}
M.t_roles = {{Id = 1, ExtendedCustomRoleEnabled = false}}
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
    {Id = 0, RoleName = [=[NoAccess]=]}, {Id = 5, RoleName = [=[CustomRole1]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 6, RoleName = [=[CustomRole2]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 7, RoleName = [=[CustomRole3]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 8, RoleName = [=[CustomRole4]=], ReadOnly = true, ConfigureSelf = true}
}
M.t_account_service = {
    {
        Id = 1,
        MaxPasswordLength = 20,
        SNMPv3TrapAccountId = 2,
        SNMPv3TrapAccountLimitPolicy = 2,
        AccountLockoutCounterResetEnabled = false,
        AccountLockoutDuration = 300,
        AccountLockoutThreshold = 5
    }
}
M.t_snmp_community = {{Id = 1, LongCommunityEnabled = true, RwCommunityEnabled = true}}
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
        Deletable = false
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
        Deletable = false
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
        Deletable = false
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
        Deletable = false
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
        Deletable = false
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
        Deletable = false
    }, {
        Id = 23,
        RoleId = 4,
        UserName = [=[<inter chassis>]=],
        Password = [=[]=],
        IpmiPassword = [=[]=],
        FirstLoginPolicy = [=[PromptPasswordReset]=],
        AccountType = 9,
        LoginInterface = 128,
        LoginRuleIds = 0,
        Deletable = false
    }
}
M.t_snmp_user_info = {
    {
        AccountId = 2,
        AuthenticationProtocol = [=[SNMPAuthenticationProtocols_SHA256]=],
        EncryptionProtocol = [=[SNMPEncryptionProtocols_AES128]=],
        AuthenticationKey = [=[]=],
        EncryptionKey = [=[]=],
        SNMPPassword = [=[]=]
    }
}
M.t_ipmi_user_info = {{AccountId = 2}, {AccountId = 18}, {AccountId = 19}}
M.t_password_policy = {
    {AccountType = 0, Policy = 1, Pattern = [=[]=]}, {AccountType = 3, Policy = 1, Pattern = [=[]=]},
    {AccountType = 7, Policy = 1, Pattern = [=[]=]}
}
M.t_account_policy = {{AccountType = 0, NamePattern = [=[]=], AllowedLoginInterfaces = 223}}

return M
