--[[-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
]] --
local bs = require 'mc.bitstring'
local enums = require 'ipmi.enums'
local ipmi = require 'ipmi'
local types = require 'ipmi.types'
local privilege = require 'mc.privilege'
local msg = require 'account.ipmi.ipmi_message'

local CT = enums.ChannelType

local AccountIpmiCmds = {}

AccountIpmiCmds.SetUserAccess = {
    name = 'SetUserAccess',
    prio = types.Priority.Default,
    netfn = 0x06,
    cmd = 0x43,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[]=],
    decode = [=[<<ChannelNumber:4/unit:1, MessagingEnable:1/unit:1]=] ..
        [=[, AuthenticationEnable:1/unit:1, UserRestricted:1/]=] ..
        [=[unit:1, ChangeEnable:1/unit:1, UserId:6/unit:1, Re]=] ..
        [=[served1:2/unit:1, UserPrivilege:4/unit:1, Reserved]=] .. [=[2:4/unit:1, SessionLimit/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8>>]=],
    req = msg.SetUserAccessReq,
    rsp = msg.SetUserAccessRsp,
    manufacturer = {-1, -1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.GetUserAccess = {
    name = 'GetUserAccess',
    prio = types.Priority.Default,
    netfn = 0x06,
    cmd = 0x44,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[]=],
    decode = [=[<<ChannelNumber:4/unit:1, MessagingEnable:1/unit:1]=] ..
        [=[, AuthenticationEnable:1/unit:1, UserRestricted:1/]=] ..
        [=[unit:1, ChangeEnable:1/unit:1, UserId:6/unit:1, Re]=] .. [=[served1:2/unit:1>>]=],
    encode = [=[<<CompletionCode:1/unit:8, MaxUserNumber:6/unit:1,]=] ..
        [=[ Reserved:2/unit:1, EnabledUser:6/unit:1, EnableSt]=] ..
        [=[atus:2/unit:1, UserNumber:6/unit:1, Reserved2:2/un]=] ..
        [=[it:1, PrivilegeLimit:4/unit:1, IpmiMessaging:1/uni]=] ..
        [=[t:1, LinkAuthentication:1/unit:1, ChaAccessMode:1/]=] .. [=[unit:1, Reserved3:1/unit:1>>]=],
    req = msg.GetUserAccessReq,
    rsp = msg.GetUserAccessRsp,
    manufacturer = {-1, -1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetUserName = {
    name = 'SetUserName',
    prio = types.Priority.Default,
    netfn = 0x06,
    cmd = 0x45,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[]=],
    decode = [=[<<UserId:6/unit:1, Reserved:2/unit:1, UserName:16/]=] .. [=[string>>]=],
    encode = [=[<<CompletionCode:1/unit:8>>]=],
    req = msg.SetUserNameReq,
    rsp = msg.SetUserNameRsp,
    manufacturer = {-1, -1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.GetUserName = {
    name = 'GetUserName',
    prio = types.Priority.Default,
    netfn = 0x06,
    cmd = 0x46,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[]=],
    decode = [=[<<UserId:6/unit:1, Reserved:2/unit:1>>]=],
    encode = [=[<<CompletionCode:1/unit:8, UserName:16/string>>]=],
    req = msg.GetUserNameReq,
    rsp = msg.GetUserNameRsp,
    manufacturer = {-1, -1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetUserPassComplexity = {
    name = 'SetUserPassComplexity',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Operator,
    privilege = privilege.SecurityMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,22]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x22:1/unit:8, Control:1]=] .. [=[/unit:8>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetUserPassComplexityReq,
    rsp = msg.SetUserPassComplexityRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.GetUserPassComplexity = {
    name = 'GetUserPassComplexity',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.User,
    privilege = privilege.ReadOnly,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,21]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x21:1/unit:8>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Control:1/unit:8>>]=],
    req = msg.GetUserPassComplexityReq,
    rsp = msg.GetUserPassComplexityRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetUserInterface = {
    name = 'SetUserInterface',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = true,
    restricted_channels = {},
    filters = [=[*,*,*,68]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x68:1/unit:8, UserId:1/]=] ..
        [=[unit:8, Operation:1/unit:8, LoginInterface:1/unit:]=] ..
        [=[8, Reserved:1/unit:8, PasswordLength:1/unit:8, Pas]=] .. [=[swordData/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetUserInterfaceReq,
    rsp = msg.SetUserInterfaceRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.UserIpmiSetUserSNMPV3PrivacyPwd = {
    name = 'UserIpmiSetUserSNMPV3PrivacyPwd',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.User,
    privilege = privilege.ConfigureSelf,
    sensitive = true,
    restricted_channels = {},
    filters = [=[*,*,*,44]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x44:1/unit:8, UserId:1/]=] ..
        [=[unit:8, Operation:1/unit:8, PwdLength:1/unit:8, Pa]=] .. [=[sswordData:PwdLength/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.UserIpmiSetUserSNMPV3PrivacyPwdReq,
    rsp = msg.UserIpmiSetUserSNMPV3PrivacyPwdRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.SetSNMPConfiguration = {
    name = 'SetSNMPConfiguration',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = true,
    restricted_channels = {},
    filters = [=[*,*,*,74]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x74:1/unit:8, SNMPParam]=] ..
        [=[eter:1/unit:8, BlockSelector:1/unit:8, SubBlockSel]=] ..
        [=[ector:1/unit:8, Length:1/unit:8, Data/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetSNMPConfigurationReq,
    rsp = msg.SetSNMPConfigurationRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.GetSNMPConfiguration = {
    name = 'GetSNMPConfiguration',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = true,
    restricted_channels = {},
    filters = [=[*,*,*,75]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x75:1/unit:8, SNMPParam]=] ..
        [=[eter:1/unit:8, BlockSelector:1/unit:8, SubBlockSel]=] .. [=[ector:1/unit:8>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Length:1/unit:8, Data/string>>]=],
    req = msg.GetSNMPConfigurationReq,
    rsp = msg.GetSNMPConfigurationRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.GetAccountInterface = {
    name = 'GetAccountInterface',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,79]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x79:1/unit:8, UserId:6/]=] .. [=[unit:1, Reserved1:2/unit:1>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Interface:1/unit:8>>]=],
    req = msg.GetAccountInterfaceReq,
    rsp = msg.GetAccountInterfaceRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetVncPassword = {
    name = 'SetVncPassword',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x94,
    role = types.Role.User,
    privilege = privilege.KVMMgmt,
    sensitive = true,
    restricted_channels = {},
    filters = [=[*,*,*,67,00,01]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x67:1/unit:8, 0x00:1/un]=] ..
        [=[it:8, 0x01:1/unit:8, Reserved:2/unit:8, Length:1/u]=] .. [=[nit:8, Password/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetVncPasswordReq,
    rsp = msg.SetVncPasswordRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.SetUserPasswordCompareInfo = {
    name = 'SetUserPasswordCompareInfo',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.User,
    privilege = privilege.SecurityMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,5A,30]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x5A:1/unit:8, 0x30:1/un]=] ..
        [=[it:8, CompareEnabled:1/unit:8, CompareLength:1/uni]=] .. [=[t:8>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetUserPasswordCompareInfoReq,
    rsp = msg.SetUserPasswordCompareInfoRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.GetUserPasswordCompareInfo = {
    name = 'GetUserPasswordCompareInfo',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.User,
    privilege = privilege.ReadOnly,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,5B,30,00]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x5B:1/unit:8, 0x30:1/un]=] .. [=[it:8, 0x00:1/unit:8>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] ..
        [=[ CompareEnabled:1/unit:8, CompareLength:1/unit:8>>]=],
    req = msg.GetUserPasswordCompareInfoReq,
    rsp = msg.GetUserPasswordCompareInfoRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.GetWeakPwdDictionaryEnabled = {
    name = 'GetWeakPwdDictionaryEnabled',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,76,01]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x76:1/unit:8, 0x01:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Length:1/unit:8, Data/string>>]=],
    req = msg.GetWeakPwdDictionaryEnabledReq,
    rsp = msg.GetWeakPwdDictionaryEnabledRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.GetFirstLoginModifyPolicy = {
    name = 'GetFirstLoginModifyPolicy',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,76,02]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x76:1/unit:8, 0x02:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Length:1/unit:8, Data/string>>]=],
    req = msg.GetFirstLoginModifyPolicyReq,
    rsp = msg.GetFirstLoginModifyPolicyRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.GetHistoryPwdCheckCount = {
    name = 'GetHistoryPwdCheckCount',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,76,03]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x76:1/unit:8, 0x03:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Length:1/unit:8, Data/string>>]=],
    req = msg.GetHistoryPwdCheckCountReq,
    rsp = msg.GetHistoryPwdCheckCountRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.GetEmergencyLoginAccount = {
    name = 'GetEmergencyLoginAccount',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,76,05]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x76:1/unit:8, 0x05:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Length:1/unit:8, Data/string>>]=],
    req = msg.GetEmergencyLoginAccountReq,
    rsp = msg.GetEmergencyLoginAccountRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.GetInitialPasswordPromptEnable = {
    name = 'GetInitialPasswordPromptEnable',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,76,06]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x76:1/unit:8, 0x06:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Length:1/unit:8, Data/string>>]=],
    req = msg.GetInitialPasswordPromptEnableReq,
    rsp = msg.GetInitialPasswordPromptEnableRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetWeakPwdDictionaryEnabled = {
    name = 'SetWeakPwdDictionaryEnabled',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,77,01]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x77:1/unit:8, 0x01:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1, Reserve]=] .. [=[d2:1/unit:8, Length:1/unit:8, Data/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetWeakPwdDictionaryEnabledReq,
    rsp = msg.SetWeakPwdDictionaryEnabledRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetFirstLoginModifyPolicy = {
    name = 'SetFirstLoginModifyPolicy',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,77,02]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x77:1/unit:8, 0x02:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1, Reserve]=] .. [=[d2:1/unit:8, Length:1/unit:8, Data/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetFirstLoginModifyPolicyReq,
    rsp = msg.SetFirstLoginModifyPolicyRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetHistoryPwdCheckCount = {
    name = 'SetHistoryPwdCheckCount',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,77,03]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x77:1/unit:8, 0x03:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1, Reserve]=] .. [=[d2:1/unit:8, Length:1/unit:8, Data/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetHistoryPwdCheckCountReq,
    rsp = msg.SetHistoryPwdCheckCountRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetEmergencyLoginAccount = {
    name = 'SetEmergencyLoginAccount',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,77,05]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x77:1/unit:8, 0x05:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1, Reserve]=] .. [=[d2:1/unit:8, Length:1/unit:8, Data/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetEmergencyLoginAccountReq,
    rsp = msg.SetEmergencyLoginAccountRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetInitialPasswordPromptEnable = {
    name = 'SetInitialPasswordPromptEnable',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Administrator,
    privilege = privilege.UserMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,77,06]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x77:1/unit:8, 0x06:1/un]=] ..
        [=[it:8, UserId:6/unit:1, Reserved1:2/unit:1, Reserve]=] .. [=[d2:1/unit:8, Length:1/unit:8, Data/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetInitialPasswordPromptEnableReq,
    rsp = msg.SetInitialPasswordPromptEnableRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.DisableAccount = {
    name = 'DisableAccount',
    prio = types.Priority.Default,
    netfn = 0x06,
    cmd = 0x47,
    role = types.Role.User,
    privilege = privilege.ConfigureSelf,
    sensitive = true,
    restricted_channels = {},
    filters = [=[*,00]=],
    decode = [=[<<UserId:6/unit:1, Reserved1:1/unit:1, PasswordSiz]=] ..
        [=[e:1/unit:1, 0x00:2/unit:1, Reserved2:6/unit:1, Pas]=] .. [=[swordData/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8>>]=],
    req = msg.DisableAccountReq,
    rsp = msg.DisableAccountRsp,
    manufacturer = {-1, -1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.EnableAccount = {
    name = 'EnableAccount',
    prio = types.Priority.Default,
    netfn = 0x06,
    cmd = 0x47,
    role = types.Role.User,
    privilege = privilege.ConfigureSelf,
    sensitive = true,
    restricted_channels = {},
    filters = [=[*,01]=],
    decode = [=[<<UserId:6/unit:1, Reserved1:1/unit:1, PasswordSiz]=] ..
        [=[e:1/unit:1, 0x01:2/unit:1, Reserved2:6/unit:1, Pas]=] .. [=[swordData/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8>>]=],
    req = msg.EnableAccountReq,
    rsp = msg.EnableAccountRsp,
    manufacturer = {-1, -1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.SetAccountPassword = {
    name = 'SetAccountPassword',
    prio = types.Priority.Default,
    netfn = 0x06,
    cmd = 0x47,
    role = types.Role.User,
    privilege = privilege.ConfigureSelf,
    sensitive = true,
    restricted_channels = {},
    filters = [=[*,02]=],
    decode = [=[<<UserId:6/unit:1, Reserved1:1/unit:1, PasswordSiz]=] ..
        [=[e:1/unit:1, 0x02:2/unit:1, Reserved2:6/unit:1, Pas]=] .. [=[swordData/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8>>]=],
    req = msg.SetAccountPasswordReq,
    rsp = msg.SetAccountPasswordRsp,
    manufacturer = {-1, -1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.GetPasswordRulePolicy = {
    name = 'GetPasswordRulePolicy',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Operator,
    privilege = privilege.SecurityMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,76,07]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x76:1/unit:8, 0x07:1/un]=] .. [=[it:8, AccountType:1/unit:8>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Length:1/unit:8, Data/string>>]=],
    req = msg.GetPasswordRulePolicyReq,
    rsp = msg.GetPasswordRulePolicyRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetPasswordRulePolicy = {
    name = 'SetPasswordRulePolicy',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Operator,
    privilege = privilege.SecurityMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,77,07]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x77:1/unit:8, 0x07:1/un]=] ..
        [=[it:8, AccountType:1/unit:8, Reserved:1/unit:8, Len]=] .. [=[gth:1/unit:8, Data/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetPasswordRulePolicyReq,
    rsp = msg.SetPasswordRulePolicyRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Forbidden'
}

AccountIpmiCmds.GetPasswordPattern = {
    name = 'GetPasswordPattern',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Operator,
    privilege = privilege.SecurityMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,76,08]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x76:1/unit:8, 0x08:1/un]=] .. [=[it:8, AccountType:1/unit:8>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8,]=] .. [=[ Length:1/unit:8, Data/string>>]=],
    req = msg.GetPasswordPatternReq,
    rsp = msg.GetPasswordPatternRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Allowed'
}

AccountIpmiCmds.SetPasswordPattern = {
    name = 'SetPasswordPattern',
    prio = types.Priority.Default,
    netfn = 0x30,
    cmd = 0x93,
    role = types.Role.Operator,
    privilege = privilege.SecurityMgmt,
    sensitive = false,
    restricted_channels = {},
    filters = [=[*,*,*,77,08]=],
    decode = [=[<<ManufactureId:3/unit:8, 0x77:1/unit:8, 0x08:1/un]=] ..
        [=[it:8, AccountType:1/unit:8, Reserved:1/unit:8, Len]=] .. [=[gth:1/unit:8, Data/string>>]=],
    encode = [=[<<CompletionCode:1/unit:8, ManufactureId:3/unit:8>]=] .. [=[>]=],
    req = msg.SetPasswordPatternReq,
    rsp = msg.SetPasswordPatternRsp,
    manufacturer = {0, 1},
    sysLockedPolicy = 'Forbidden'
}

return AccountIpmiCmds
