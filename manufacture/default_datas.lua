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
-- SNMPv3TrapAccountId 在装备包不设置，避免修改用户名失败
M.t_account_service = {{Id = 1, MaxPasswordLength = 20, SNMPv3TrapAccountId = 2, SNMPv3TrapAccountLimitPolicy = 2,
    AccountLockoutCounterResetEnabled = false}}
M.t_manager_account = {
    {
        Id = 2,
        RoleId = 4,
        UserName = [=[Administrator]=],
        FirstLoginPolicy = [=[ForcePasswordReset]=],
        Password = [=[$6$AhtdE42u9JhRdPw1$7e3wQX6sfjwTEJr8UZjmAM3EDJMcM0AuSrK2aN7U]=] ..
            [=[km0II0Mjm2wR8EAenfBv3SaJ/y4wCu5fqSYCqb4BJfrRd0]=],
        IpmiPassword = [=[0000000200000000000000060000000500000007c3c90f687c9010341e1ab8ff309cfaad388113c]=] ..
            [=[66f28f8f6ff48e203bfa7c31f010000010000000000000010126b5c4bb597331e5100ae9da8814a84]=],
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
        IpmiPassword = [=[0000000200000000000000060000000500000007c3c90f687c901034dae1df20fc26413d5b0a09]=] ..
            [=[53c98d8f63c320bb9a9655eee7010000010000000000000010d2cd60c6dc0e254c2ffd6c138f6e5d19]=],
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
        IpmiPassword = [=[0000000200000000000000060000000500000007c3c90f687c90103440282a7633d3fcdc11bc54cb5c3f]=] ..
            [=[3e33431e02241ff6f52601000001000000000000001094f0e7e79b93e98993b578df4482ed0e]=],
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
    }
}
M.t_snmp_user_info = {
    {
        AccountId = 2,
        AuthenticationProtocol = [=[SNMPAuthenticationProtocols_SHA256]=],
        EncryptionProtocol = [=[SNMPEncryptionProtocols_AES128]=],
        AuthenticationKey = [=[7a2f5b86f20233ec7b7bef49643fbf34d86d0cbf6f1f8f5c52d4f30d4536938b]=],
        EncryptionKey = [=[7a2f5b86f20233ec7b7bef49643fbf34d86d0cbf6f1f8f5c52d4f30d4536938b]=],
        SNMPPassword = [=[$6$hqlSg3LmkBvBNpNW$eC4HKBS.8KzMPxFx/gdxhOnnrRUN8n7DDrEX92]=] ..
            [=[GsMOWfuDCJNuxzVIjkdWwEidlqPhE.dMUmD.wcgSayjC8GF/]=]
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
M.t_login_rule = {
    {RuleId = 1, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false},
    {RuleId = 2, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false},
    {RuleId = 3, IpRule = [=[]=], TimeRule = [=[]=], MacRule = [=[]=], Enabled = false}
}
M.t_snmp_community = {{Id = 1, LongCommunityEnabled = true, RwCommunityEnabled = true}}
M.t_password_policy = {
    {AccountType = 0, Policy = 1, Pattern = [=[]=]}, {AccountType = 3, Policy = 1, Pattern = [=[]=]},
    {AccountType = 7, Policy = 1, Pattern = [=[]=]}
}
M.t_account_policy = {
    {AccountType = 0, NamePattern = [=[]=]}
}

return M
