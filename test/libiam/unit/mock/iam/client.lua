-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local Singleton = require 'mc.singleton'
local class = require 'mc.class'

local EMPYT_HASH<const> = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
}

local config_data_account = [[{
    "ConfigData": {
        "UserRole": [{
            "DiagnoseMgmt": false,
            "Id": "NoAccess",
            "SecurityMgmt": false,
            "PowerMgmt": false,
            "KVMMgmt": false,
            "UserMgmt": false,
            "ReadOnly": false,
            "VMMMgmt": false,
            "ConfigureSelf": false,
            "BasicSetting": false
        }, {
            "DiagnoseMgmt": false,
            "Id": "CommonUser",
            "SecurityMgmt": false,
            "PowerMgmt": false,
            "KVMMgmt": false,
            "UserMgmt": false,
            "ReadOnly": true,
            "VMMMgmt": false,
            "ConfigureSelf": true,
            "BasicSetting": false
        }, {
            "DiagnoseMgmt": false,
            "Id": "Operator",
            "SecurityMgmt": false,
            "PowerMgmt": true,
            "KVMMgmt": true,
            "UserMgmt": false,
            "ReadOnly": true,
            "VMMMgmt": true,
            "ConfigureSelf": true,
            "BasicSetting": true
        }, {
            "DiagnoseMgmt": true,
            "Id": "Administrator",
            "SecurityMgmt": true,
            "PowerMgmt": true,
            "KVMMgmt": true,
            "UserMgmt": true,
            "ReadOnly": true,
            "VMMMgmt": true,
            "ConfigureSelf": true,
            "BasicSetting": true
        }, {
            "DiagnoseMgmt": false,
            "Id": "CustomRole1",
            "SecurityMgmt": false,
            "PowerMgmt": false,
            "KVMMgmt": false,
            "UserMgmt": false,
            "ReadOnly": true,
            "VMMMgmt": false,
            "ConfigureSelf": true,
            "BasicSetting": false
        }, {
            "DiagnoseMgmt": false,
            "Id": "CustomRole2",
            "SecurityMgmt": false,
            "PowerMgmt": false,
            "KVMMgmt": false,
            "UserMgmt": false,
            "ReadOnly": true,
            "VMMMgmt": false,
            "ConfigureSelf": true,
            "BasicSetting": false
        }, {
            "DiagnoseMgmt": false,
            "Id": "CustomRole3",
            "SecurityMgmt": false,
            "PowerMgmt": false,
            "KVMMgmt": false,
            "UserMgmt": false,
            "ReadOnly": true,
            "VMMMgmt": false,
            "ConfigureSelf": true,
            "BasicSetting": false
        }, {
            "DiagnoseMgmt": false,
            "Id": "CustomRole4",
            "SecurityMgmt": false,
            "PowerMgmt": false,
            "KVMMgmt": false,
            "UserMgmt": false,
            "ReadOnly": true,
            "VMMMgmt": false,
            "ConfigureSelf": true,
            "BasicSetting": false
        }],
        "PermitRule": [{
            "IpRuleInfo": "",
            "TimeRuleInfo": "",
            "MacRuleInfo": "",
            "Id": "Rule1"
        }, {
            "IpRuleInfo": "",
            "TimeRuleInfo": "",
            "MacRuleInfo": "",
            "Id": "Rule2"
        }, {
            "IpRuleInfo": "",
            "TimeRuleInfo": "",
            "MacRuleInfo": "",
            "Id": "Rule3"
        }],
        "PasswdSetting": {
            "MinPasswordLength": 8,
            "EnableStrongPassword": true
        },
        "SecurityEnhance": {
            "PwdExpiredTime": 0,
            "WeakPwdDictEnable": true,
            "MinimumPwdAge": 0,
            "UserInactTimeLimit": 0,
            "OldPwdCount": 5,
            "InitialPwdPrompt": true,
            "InitialPasswordNeedModify": true,
            "ExcludeUser": 0
        },
        "User": [{
            "Id": 2,
            "LoginInterface": ["Local", "SSH", "Web", "Redfish", "SFTP", "IPMI", "SNMP"],
            "IsUserLocked": false,
            "UserName": "Administrator",
            "Privilege": "Administrator",
            "SnmpPrivacyPwdInitialState": true,
            "PermitRuleIds": [],
            "UserRoleId": "Administrator",
            "IsUserEnable": true
        }]
    }
}]]

-- MockClient客户端，UT使用，mock掉所有rpc
local MockClient = class()

function MockClient:init()
end

function MockClient:GetSecureBootObjects()
    return {['mdb_path'] = self}
end

function MockClient:GetFileTransferObjects()
    return {['mdb_path'] = self}
end

function MockClient:GetManagerAccountsObjects()
    return {['mdb_path'] = self}
end

function MockClient:GetFirmwareVerificationObjects()
    return {['mdb_path'] = self}
end

function MockClient:GetConfigManageObjects()
    return {['/bmc/kepler/account/MicroComponent'] = self}
end

function MockClient:SetSpiMuxChannel(ctx)
end

function MockClient:ExportCustomCertificateHash(ctx, sign_mode)
    if sign_mode == 0 then
        return self.hash_pkcs and self.hash_pkcs or string.char(table.unpack(EMPYT_HASH))
    elseif sign_mode == 1 then
        return self.hash_pss and self.hash_pss or string.char(table.unpack(EMPYT_HASH))
    end
end

function MockClient:ImportCustomCertificateHash(ctx, hash)
    self.hash_pkcs = hash
    self.hash_pss = hash
end

function MockClient:ExportRepairCredentials(ctx)
    local repair = {212, 41, 3, 39, 20, 207, 229, 4, 212, 10, 210, 78, 10, 85, 124, 64, 67, 144, 14, 0, 0, 0, 0, 0}
    return string.char(table.unpack(repair))
end

function MockClient:ImportRepairCredentials(ctx, repair_credential)
    self.repair_sign = repair_credential
end

function MockClient:GetUidGidByUserName()
    return 502, 204
end

function MockClient:StartTransfer()
    return math.random(1, 1000000)
end

function MockClient:Export()
    return config_data_account
end

function MockClient:Import()
end

local clz = Singleton(MockClient)

local PMockClient = class()

function PMockClient:ctor()
    self.base = clz.new()
end

function PMockClient:SetSpiMuxChannel()
    return pcall(self.base.SetSpiMuxChannel, self.base)
end

function PMockClient:ExportCustomCertificateHash()
    return pcall(self.base.ExportCustomCertificateHash, self.base)
end

function PMockClient:ImportCustomCertificateHash()
    return pcall(self.base.ImportCustomCertificateHash, self.base)
end

function PMockClient:ExportRepairCredentials()
    return pcall(self.base.ExportRepairCredentials, self.base)
end

function PMockClient:ImportRepairCredentials()
    return pcall(self.base.ImportRepairCredentials, self.base)
end

function PMockClient:GetUidGidByUserName()
    return pcall(self.base.GetUidGidByUserName, self.base)
end

function PMockClient:StartTransfer()
    return pcall(self.base.StartTransfer, self.base)
end

function MockClient:GetAccountObjects()
    return {}
end

function MockClient:GetCertificateServiceObjects()
    return {}
end

function MockClient:OnAccountPolicyInterfacesAdded()
    return {}
end

function MockClient:OnAccountPolicyPropertiesChanged()
    return {}
end

function MockClient:GetAccountPolicyAccountPolicyObject()
    return {}
end

function MockClient:GetCipherSuitObjects()
    return {}
end

function MockClient:ForeachCipherSuitObjects(cb)
    local obj = {Enabled = true, SuitName = 'ECDHE-ECDSA-AES256-GCM-SHA384'}
    return cb(obj)
end

function MockClient:ForeachLLDPReceiveObjects(cb)
    local obj = {ManagementAddressIPv4 = '127.0.0.1', ManagementAddressIPv6 = '::'}
    return cb(obj)
end

local client = clz.new()
client.pcall = PMockClient.new()

return client
