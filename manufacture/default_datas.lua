-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local default_pwd = require "account.default_password"
local M = {}
-- SNMPv3TrapAccountId 在装备包不设置，避免修改用户名失败
M.t_account_service = {{Id = 1, MaxPasswordLength = 20, SNMPv3TrapAccountId = 2, SNMPv3TrapAccountLimitPolicy = 2,
    AccountLockoutCounterResetEnabled = false}}
M.t_manager_account = {
    {
        Id = 2,
        RoleId = 4,
        UserName = [=[Administrator]=],
        FirstLoginPolicy = [=[ForcePasswordReset]=],
        Password = default_pwd.Admin.Password,
        IpmiPassword = default_pwd.Admin.IpmiPassword,
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
        IpmiPassword = default_pwd.RoCommunity.IpmiPassword,
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
        IpmiPassword = default_pwd.RwCommunity.IpmiPassword,
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
        UserName = [=[inter_chassis]=],
        Password = [=[]=],
        IpmiPassword = [=[]=],
        FirstLoginPolicy = [=[PromptPasswordReset]=],
        AccountType = 9,
        Enabled = true,
        LoginInterface = 153,
        LoginRuleIds = 0,
        Deletable = false,
        DefaultRoleId = 4,
        DefaultLoginInterface = 153
    }
}
M.t_snmp_user_info = {
    {
        AccountId = 2,
        AuthenticationProtocol = [=[SNMPAuthenticationProtocols_SHA256]=],
        EncryptionProtocol = [=[SNMPEncryptionProtocols_AES128]=],
        AuthenticationKey = default_pwd.SnmpUserInfo.AuthenticationKey,
        EncryptionKey = default_pwd.SnmpUserInfo.EncryptionKey,
        SNMPPassword = default_pwd.SnmpUserInfo.SNMPPassword
    }
}
M.t_ipmi_user_info = {{AccountId = 2}, {AccountId = 18}, {AccountId = 19}}
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
    {Id = 0, RoleName = [=[NoAccess]=]},
    {Id = 5, RoleName = [=[CustomRole1]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 6, RoleName = [=[CustomRole2]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 7, RoleName = [=[CustomRole3]=], ReadOnly = true, ConfigureSelf = true},
    {Id = 8, RoleName = [=[CustomRole4]=], ReadOnly = true, ConfigureSelf = true}
}
M.t_login_rule = {
    {RuleId = 1, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false},
    {RuleId = 2, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false},
    {RuleId = 3, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false}
}
M.t_snmp_community = {{Id = 1, LongCommunityEnabled = true, RwCommunityEnabled = true}}
M.t_password_policy = {
    {AccountType = 0, AccountTypeName = [=[Local]=], Policy = 1, Pattern = [=[]=], MaxPasswordLength = 20},
    {AccountType = 3, AccountTypeName = [=[VNC]=], Policy = 1, Pattern = [=[]=], MaxPasswordLength = 8},
    {AccountType = 7, AccountTypeName = [=[SnmpCommunity]=], Policy = 1, Pattern = [=[]=], MaxPasswordLength = 32},
    {AccountType = 8, AccountTypeName = [=[Oem]=], Policy = 1, Pattern = [=[]=], MaxPasswordLength = 20}
}
M.t_account_policy = {
    {AccountType = 0, NamePattern = [=[]=], AllowedLoginInterfaces = 223, Visible = true, Deletable = true, OnlineDeletable = true},
    {AccountType = 8, NamePattern = [=[]=], AllowedLoginInterfaces = 223, Visible = false, Deletable = false, OnlineDeletable = true},
    {AccountType = 9, NamePattern = [=[]=], AllowedLoginInterfaces = 153, Visible = true, Deletable = false, OnlineDeletable = true}
}

return M
