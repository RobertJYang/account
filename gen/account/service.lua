-- Copyright (c) 2026 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local ipmi = require 'ipmi'
local mdb = require 'mc.mdb'
local class = require 'mc.class'
local context = require 'mc.context'
local open_db = require 'account.db'
local app_base = require 'mc.service_app_base'
local object_manage = require 'mc.mdb.object_manage'
local persist_client = require 'persistence.persist_client_lib'
local orm_classes = require 'account.orm_classes'
local ok, datas = pcall(require, 'account.datas')
if not ok then
    datas = nil -- 如果没有datas配置，证明当前组件不需要datas，仅打开数据库
end

local AccountServiceTypes = require 'account.json_types.AccountService'
local PropertiesTypes = require 'mdb.bmc.kepler.Object.PropertiesInterface'
local ManagerAccountsTypes = require 'account.json_types.ManagerAccounts'
local ManagerAccountTypes = require 'account.json_types.ManagerAccount'
local SnmpUserTypes = require 'account.json_types.SnmpUser'
local RuleTypes = require 'account.json_types.Rule'
local RolesTypes = require 'account.json_types.Roles'
local RoleTypes = require 'account.json_types.Role'
local SnmpCommunityTypes = require 'account.json_types.SnmpCommunity'
local LocalAccountAuthNTypes = require 'account.json_types.LocalAccountAuthN'
local PasswordPolicyTypes = require 'account.json_types.PasswordPolicy'
local AccountPolicyTypes = require 'account.json_types.AccountPolicy'
local IpmiChannelConfigTypes = require 'account.json_types.IpmiChannelConfig'

local AccountService = mdb.register_object('/bmc/kepler/AccountService', {
    {name = 'bmc.kepler.AccountService', interface = AccountServiceTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function AccountService:ctor()
    self.path = '/bmc/kepler/AccountService'
end

local ManagerAccounts = mdb.register_object('/bmc/kepler/AccountService/Accounts', {
    {name = 'bmc.kepler.AccountService.ManagerAccounts', interface = ManagerAccountsTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function ManagerAccounts:ctor()
    self.path = '/bmc/kepler/AccountService/Accounts'
end

local ManagerAccount = mdb.register_object('/bmc/kepler/AccountService/Accounts/:Id', {
    {name = 'bmc.kepler.AccountService.ManagerAccount', interface = ManagerAccountTypes.interface},
    {name = 'bmc.kepler.AccountService.ManagerAccount.SnmpUser', interface = SnmpUserTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function ManagerAccount:ctor(Id)
    self.path = '/bmc/kepler/AccountService/Accounts/' .. Id
end

local Rule = mdb.register_object('/bmc/kepler/AccountService/Rules/:RuleId', {
    {name = 'bmc.kepler.AccountService.Rule', interface = RuleTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function Rule:ctor(RuleId)
    self.path = '/bmc/kepler/AccountService/Rules/' .. RuleId
end

local Roles = mdb.register_object('/bmc/kepler/AccountService/Roles', {
    {name = 'bmc.kepler.AccountService.Roles', interface = RolesTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function Roles:ctor()
    self.path = '/bmc/kepler/AccountService/Roles'
end

local Role = mdb.register_object('/bmc/kepler/AccountService/Roles/:Id', {
    {name = 'bmc.kepler.AccountService.Role', interface = RoleTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function Role:ctor(Id)
    self.path = '/bmc/kepler/AccountService/Roles/' .. Id
end

local SnmpCommunity = mdb.register_object('/bmc/kepler/Managers/:ManagerId/SnmpService/SnmpCommunity', {
    {name = 'bmc.kepler.Managers.SnmpService.SnmpCommunity', interface = SnmpCommunityTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function SnmpCommunity:ctor(ManagerId)
    self.path = '/bmc/kepler/Managers/' .. ManagerId .. '/SnmpService/SnmpCommunity'
end

local LocalAccountAuthN = mdb.register_object('/bmc/kepler/AccountService/LocalAccountAuthN', {
    {name = 'bmc.kepler.AccountService.LocalAccountAuthN', interface = LocalAccountAuthNTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function LocalAccountAuthN:ctor()
    self.path = '/bmc/kepler/AccountService/LocalAccountAuthN'
end

local PasswordPolicy = mdb.register_object('/bmc/kepler/AccountService/PasswordPolicys/:AccountType', {
    {name = 'bmc.kepler.AccountService.PasswordPolicy', interface = PasswordPolicyTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function PasswordPolicy:ctor(AccountType)
    self.path = '/bmc/kepler/AccountService/PasswordPolicys/' .. AccountType
end

local AccountPolicy = mdb.register_object('/bmc/kepler/AccountService/AccountPolicies/:AccountType', {
    {name = 'bmc.kepler.AccountService.AccountPolicy', interface = AccountPolicyTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function AccountPolicy:ctor(AccountType)
    self.path = '/bmc/kepler/AccountService/AccountPolicies/' .. AccountType
end

local IpmiChannelConfig = mdb.register_object('/bmc/kepler/AccountService/Accounts/:Id/Channels/:ChannelNumber', {
    {name = 'bmc.kepler.AccountService.ManagerAccount.IpmiChannelConfig', interface = IpmiChannelConfigTypes.interface},
    {name = 'bmc.kepler.Object.Properties', interface = PropertiesTypes.interface}
})

function IpmiChannelConfig:ctor(Id, ChannelNumber)
    self.path = '/bmc/kepler/AccountService/Accounts/' .. Id .. '/Channels/' .. ChannelNumber
end

local model = require 'class.model'

local account_service = class(app_base.Service)

account_service.package = 'account'

function account_service:CreateAccountService(prop_setting_cb)
    return object_manage.create_object('AccountService', 'AccountService_0', '/bmc/kepler/AccountService',
        prop_setting_cb)
end

function account_service:CreateManagerAccounts(prop_setting_cb)
    return object_manage.create_object('ManagerAccounts', 'ManagerAccounts_0', '/bmc/kepler/AccountService/Accounts',
        prop_setting_cb)
end

function account_service:CreateManagerAccount(Id, prop_setting_cb)
    local path = '/bmc/kepler/AccountService/Accounts/' .. Id
    return object_manage.create_object('ManagerAccount', path, path, prop_setting_cb)
end

function account_service:CreateRule(RuleId, prop_setting_cb)
    local path = '/bmc/kepler/AccountService/Rules/' .. RuleId
    return object_manage.create_object('Rule', path, path, prop_setting_cb)
end

function account_service:CreateRoles(prop_setting_cb)
    return object_manage.create_object('Roles', 'Roles_0', '/bmc/kepler/AccountService/Roles', prop_setting_cb)
end

function account_service:CreateRole(Id, prop_setting_cb)
    local path = '/bmc/kepler/AccountService/Roles/' .. Id
    return object_manage.create_object('Role', path, path, prop_setting_cb)
end

function account_service:CreateSnmpCommunity(ManagerId, prop_setting_cb)
    local path = '/bmc/kepler/Managers/' .. ManagerId .. '/SnmpService/SnmpCommunity'
    return object_manage.create_object('SnmpCommunity', path, path, prop_setting_cb)
end

function account_service:CreateLocalAccountAuthN(prop_setting_cb)
    return object_manage.create_object('LocalAccountAuthN', 'LocalAccountAuthN_0',
        '/bmc/kepler/AccountService/LocalAccountAuthN', prop_setting_cb)
end

function account_service:CreatePasswordPolicy(AccountType, prop_setting_cb)
    local path = '/bmc/kepler/AccountService/PasswordPolicys/' .. AccountType
    return object_manage.create_object('PasswordPolicy', path, path, prop_setting_cb)
end

function account_service:CreateAccountPolicy(AccountType, prop_setting_cb)
    local path = '/bmc/kepler/AccountService/AccountPolicies/' .. AccountType
    return object_manage.create_object('AccountPolicy', path, path, prop_setting_cb)
end

function account_service:CreateIpmiChannelConfig(Id, ChannelNumber, prop_setting_cb)
    local path = '/bmc/kepler/AccountService/Accounts/' .. Id .. '/Channels/' .. ChannelNumber
    return object_manage.create_object('IpmiChannelConfig', path, path, prop_setting_cb)
end

function account_service:ImplAccountServiceAccountServiceImportWeakPasswordDictionary(cb)
    model.ImplAccountServiceAccountServiceImportWeakPasswordDictionary(cb)
end

function account_service:ImplAccountServiceAccountServiceExportWeakPasswordDictionary(cb)
    model.ImplAccountServiceAccountServiceExportWeakPasswordDictionary(cb)
end

function account_service:ImplAccountServiceAccountServiceGetRequestedPublicKey(cb)
    model.ImplAccountServiceAccountServiceGetRequestedPublicKey(cb)
end

function account_service:ImplAccountServiceAccountServiceRecoverAccount(cb)
    model.ImplAccountServiceAccountServiceRecoverAccount(cb)
end

function account_service:ImplManagerAccountsManagerAccountsNew(cb)
    model.ImplManagerAccountsManagerAccountsNew(cb)
end

function account_service:ImplManagerAccountsManagerAccountsNewOEMAccount(cb)
    model.ImplManagerAccountsManagerAccountsNewOEMAccount(cb)
end

function account_service:ImplManagerAccountsManagerAccountsGetIdByUserName(cb)
    model.ImplManagerAccountsManagerAccountsGetIdByUserName(cb)
end

function account_service:ImplManagerAccountsManagerAccountsSetAccountWritable(cb)
    model.ImplManagerAccountsManagerAccountsSetAccountWritable(cb)
end

function account_service:ImplManagerAccountsManagerAccountsGetAccountWritable(cb)
    model.ImplManagerAccountsManagerAccountsGetAccountWritable(cb)
end

function account_service:ImplManagerAccountsManagerAccountsSetAccountLockState(cb)
    model.ImplManagerAccountsManagerAccountsSetAccountLockState(cb)
end

function account_service:ImplManagerAccountsManagerAccountsGetUidGidByUserName(cb)
    model.ImplManagerAccountsManagerAccountsGetUidGidByUserName(cb)
end

function account_service:ImplManagerAccountManagerAccountDelete(cb)
    model.ImplManagerAccountManagerAccountDelete(cb)
end

function account_service:ImplManagerAccountManagerAccountChangePwd(cb)
    model.ImplManagerAccountManagerAccountChangePwd(cb)
end

function account_service:ImplManagerAccountManagerAccountChangeSnmpPwd(cb)
    model.ImplManagerAccountManagerAccountChangeSnmpPwd(cb)
end

function account_service:ImplManagerAccountManagerAccountImportSSHPublicKey(cb)
    model.ImplManagerAccountManagerAccountImportSSHPublicKey(cb)
end

function account_service:ImplManagerAccountManagerAccountDeleteSSHPublicKey(cb)
    model.ImplManagerAccountManagerAccountDeleteSSHPublicKey(cb)
end

function account_service:ImplManagerAccountManagerAccountSetLastLogin(cb)
    model.ImplManagerAccountManagerAccountSetLastLogin(cb)
end

function account_service:ImplManagerAccountSnmpUserSetAuthenticationProtocol(cb)
    model.ImplManagerAccountSnmpUserSetAuthenticationProtocol(cb)
end

function account_service:ImplManagerAccountSnmpUserSetEncryptionProtocol(cb)
    model.ImplManagerAccountSnmpUserSetEncryptionProtocol(cb)
end

function account_service:ImplManagerAccountSnmpUserGetSnmpKeys(cb)
    model.ImplManagerAccountSnmpUserGetSnmpKeys(cb)
end

function account_service:ImplRolesRolesNew(cb)
    model.ImplRolesRolesNew(cb)
end

function account_service:ImplRoleRoleSetRolePrivilege(cb)
    model.ImplRoleRoleSetRolePrivilege(cb)
end

function account_service:ImplRoleRoleDelete(cb)
    model.ImplRoleRoleDelete(cb)
end

function account_service:ImplSnmpCommunitySnmpCommunitySetRwCommunity(cb)
    model.ImplSnmpCommunitySnmpCommunitySetRwCommunity(cb)
end

function account_service:ImplSnmpCommunitySnmpCommunitySetRoCommunity(cb)
    model.ImplSnmpCommunitySnmpCommunitySetRoCommunity(cb)
end

function account_service:ImplSnmpCommunitySnmpCommunityGetSnmpCommunity(cb)
    model.ImplSnmpCommunitySnmpCommunityGetSnmpCommunity(cb)
end

function account_service:ImplSnmpCommunitySnmpCommunitySetSnmpCommunityLoginRule(cb)
    model.ImplSnmpCommunitySnmpCommunitySetSnmpCommunityLoginRule(cb)
end

function account_service:ImplLocalAccountAuthNLocalAccountAuthNLocalAuthenticate(cb)
    model.ImplLocalAccountAuthNLocalAccountAuthNLocalAuthenticate(cb)
end

function account_service:ImplLocalAccountAuthNLocalAccountAuthNVncAuthenticate(cb)
    model.ImplLocalAccountAuthNLocalAccountAuthNVncAuthenticate(cb)
end

function account_service:ImplLocalAccountAuthNLocalAccountAuthNGenRmcp20Code(cb)
    model.ImplLocalAccountAuthNLocalAccountAuthNGenRmcp20Code(cb)
end

function account_service:ImplLocalAccountAuthNLocalAccountAuthNGenRmcp15Code(cb)
    model.ImplLocalAccountAuthNLocalAccountAuthNGenRmcp15Code(cb)
end

---@param AccountId integer
function account_service:ManagerAccountsManagerAccountsPasswordChangedSignal(AccountId)
    self.bus:signal('/bmc/kepler/AccountService/Accounts', 'bmc.kepler.AccountService.ManagerAccounts',
        'PasswordChangedSignal', 'a{ss}y', context.get_context() or {}, AccountId)
end

---@param AccountId integer
function account_service:ManagerAccountsManagerAccountsSnmpPasswordChangedSignal(AccountId)
    self.bus:signal('/bmc/kepler/AccountService/Accounts', 'bmc.kepler.AccountService.ManagerAccounts',
        'SnmpPasswordChangedSignal', 'a{ss}y', context.get_context() or {}, AccountId)
end

---@param mdb_object object
---@param RoCommunity string
---@param RwCommunity string
function account_service:SnmpCommunitySnmpCommunitySnmpCommunityChangedSignal(mdb_object, RoCommunity, RwCommunity)
    self.bus:signal(mdb_object.path, 'bmc.kepler.Managers.SnmpService.SnmpCommunity', 'SnmpCommunityChangedSignal',
        'a{ss}ss', context.get_context() or {}, RoCommunity, RwCommunity)
end

function account_service:get_bus()
    return self.bus
end

function account_service:register_ipmi_cmd(ipmi_cmd, cb)
    self.ipmi_cmds[ipmi_cmd.name] = ipmi.register_ipmi_cmd(self.bus, self.service_name, ipmi_cmd,
        cb or self[ipmi_cmd.name])
end

function account_service:unregister_ipmi_cmd(ipmi_cmd)
    local cmd_obj = self.ipmi_cmds[ipmi_cmd.name]
    if not cmd_obj then
        return
    end

    cmd_obj:unregister()
    self.ipmi_cmds[ipmi_cmd.name] = nil
end

function account_service:ctor()
    self.ipmi_cmds = {}
    self.signal_slots = {}
    self.name = self.name or account_service.package
    self.db = open_db(':memory:', datas)

    orm_classes.init(self.db)
    self.bus:request_name(app_base.Service.get_service_name(self.name))
    model.init(self.bus)
    account_service.bus = self.bus
end

function account_service:pre_init()
    account_service.super.pre_init(self)
    self.persist = persist_client.new(self.bus, self.db, self, {})
    object_manage.set_persist_client(self.persist)
end

function account_service:init()
    account_service.super.init(self)
end

return account_service
