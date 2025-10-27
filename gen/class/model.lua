-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local mdb = require 'mc.mdb'
local class = require 'mc.class_mgnt'
local privilege = require 'mc.privilege'

local types = require 'class.types.types'
local account_service_class_types = require 'class.types.AccountService'
local manager_account_db_class_types = require 'class.types.ManagerAccountDB'
local manager_account_backup_class_types = require 'class.types.ManagerAccountBackup'
local snmp_user_info_class_types = require 'class.types.SNMPUserInfo'
local ipmi_user_info_class_types = require 'class.types.IpmiUserInfo'
local history_password_class_types = require 'class.types.HistoryPassword'
local login_rule_class_types = require 'class.types.LoginRule'
local roles_class_types = require 'class.types.Roles'
local role_class_types = require 'class.types.Role'
local snmp_community_class_types = require 'class.types.SnmpCommunity'
local account_backup_class_types = require 'class.types.AccountBackup'
local password_policy_db_class_types = require 'class.types.PasswordPolicyDB'
local account_policy_db_class_types = require 'class.types.AccountPolicyDB'
local ipmi_channel_config_class_types = require 'class.types.IpmiChannelConfig'
local account_service_intf_types = require 'account.json_types.AccountService'
local properties_intf_types = require 'account.json_types.Properties'
local manager_accounts_intf_types = require 'account.json_types.ManagerAccounts'
local manager_account_intf_types = require 'account.json_types.ManagerAccount'
local snmp_user_intf_types = require 'account.json_types.SnmpUser'
local rule_intf_types = require 'account.json_types.Rule'
local roles_intf_types = require 'account.json_types.Roles'
local role_intf_types = require 'account.json_types.Role'
local snmp_community_intf_types = require 'account.json_types.SnmpCommunity'
local local_account_auth_n_intf_types = require 'account.json_types.LocalAccountAuthN'
local password_policy_intf_types = require 'account.json_types.PasswordPolicy'
local account_policy_intf_types = require 'account.json_types.AccountPolicy'
local ipmi_channel_config_intf_types = require 'account.json_types.IpmiChannelConfig'

local AccountService = {
    ['table_name'] = 't_account_service',
    ['prop_configs'] = {
        ['PasswordExpirationDays'] = {
            ['baseType'] = 'U32',
            ['default'] = 4294967295,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_service_class_types.PasswordExpirationDays
        },
        ['AccountLockoutDuration'] = {
            ['baseType'] = 'S32',
            ['default'] = 300,
            ['validator'] = account_service_class_types.AccountLockoutDuration
        },
        ['AccountLockoutThreshold'] = {
            ['baseType'] = 'S32',
            ['default'] = 5,
            ['validator'] = account_service_class_types.AccountLockoutThreshold
        },
        ['UserMgmtEnable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_service_class_types.UserMgmtEnable
        },
        ['TimeSource'] = {
            ['baseType'] = 'Enum',
            ['$ref'] = 'types.json#/defs/TimeSource',
            ['default'] = 'TS_NOT_NTP',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_service_class_types.TimeSource
        },
        ['PasswordComplexityIsLock'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_service_class_types.PasswordComplexityIsLock
        },
        ['PreviousPasswordsDisallowed'] = {
            ['baseType'] = 'U8',
            ['default'] = 5,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_service_class_types.PreviousPasswordsDisallowed
        },
        ['Id'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_service_class_types.Id
        }
    },
    ['default_props'] = {
        ['PasswordExpirationDays'] = 4294967295,
        ['AccountLockoutDuration'] = 300,
        ['AccountLockoutThreshold'] = 5,
        ['UserMgmtEnable'] = true,
        ['TimeSource'] = types.TimeSource.TS_NOT_NTP:value(),
        ['PasswordComplexityIsLock'] = false,
        ['PreviousPasswordsDisallowed'] = 5,
        ['Id'] = account_service_class_types.Id.default[1]
    },
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService'] = {
            ['AccountLockoutCounterResetAfter'] = {
                ['baseType'] = 'S32',
                ['readOnly'] = false,
                ['default'] = 0,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['validator'] = account_service_intf_types.AccountLockoutCounterResetAfter
            },
            ['AccountLockoutCounterResetEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = false,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['validator'] = account_service_intf_types.AccountLockoutCounterResetEnabled
            },
            ['AuthFailureLoggingThreshold'] = {
                ['baseType'] = 'S32',
                ['readOnly'] = false,
                ['default'] = 0,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['validator'] = account_service_intf_types.AuthFailureLoggingThreshold
            },
            ['MaxPasswordLength'] = {
                ['baseType'] = 'S32',
                ['readOnly'] = true,
                ['default'] = 20,
                ['options'] = {['emitsChangedSignal'] = 'const'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.MaxPasswordLength
            },
            ['MinPasswordLength'] = {
                ['baseType'] = 'S32',
                ['readOnly'] = false,
                ['default'] = 8,
                ['minimum'] = 8,
                ['maximum'] = 20,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.MinPasswordLength
            },
            ['ServiceEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = account_service_intf_types.ServiceEnabled
            },
            ['PasswordComplexityEnable'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.PasswordComplexityEnable
            },
            ['InitialPasswordPromptEnable'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.InitialPasswordPromptEnable
            },
            ['InitialPasswordNeedModify'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.InitialPasswordNeedModify
            },
            ['InitialAccountPrivilegeRestrictEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = false,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.InitialAccountPrivilegeRestrictEnabled
            },
            ['MinPasswordValidDays'] = {
                ['baseType'] = 'U32',
                ['readOnly'] = false,
                ['default'] = 0,
                ['minimum'] = 0,
                ['maximum'] = 365,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.MinPasswordValidDays
            },
            ['MaxPasswordValidDays'] = {
                ['baseType'] = 'U32',
                ['readOnly'] = false,
                ['default'] = 0,
                ['minimum'] = 0,
                ['maximum'] = 365,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.MaxPasswordValidDays
            },
            ['EmergencyLoginAccountId'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['default'] = 0,
                ['minimum'] = 0,
                ['maximum'] = 17,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = account_service_intf_types.EmergencyLoginAccountId
            },
            ['SNMPv3TrapAccountId'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['default'] = 2,
                ['minimum'] = 0,
                ['maximum'] = 17,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'BasicSetting'}},
                ['validator'] = account_service_intf_types.SNMPv3TrapAccountId
            },
            ['InactiveDaysThreshold'] = {
                ['baseType'] = 'U32',
                ['readOnly'] = false,
                ['default'] = 0,
                ['minimum'] = 0,
                ['maximum'] = 365,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.InactiveDaysThreshold
            },
            ['WeakPasswordDictionaryEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.WeakPasswordDictionaryEnabled
            },
            ['HistoryPasswordCount'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['default'] = 5,
                ['minimum'] = 0,
                ['maximum'] = 100,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.HistoryPasswordCount
            },
            ['MaxHistoryPasswordCount'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['default'] = 5,
                ['minimum'] = 5,
                ['maximum'] = 100,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'TemporaryPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.MaxHistoryPasswordCount
            },
            ['HostUserManagementEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = account_service_intf_types.HostUserManagementEnabled
            },
            ['OSAdministratorPrivilegeEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = account_service_intf_types.OSAdministratorPrivilegeEnabled
            },
            ['SNMPv3TrapAccountLimitPolicy'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['default'] = 2,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['validator'] = account_service_intf_types.SNMPv3TrapAccountLimitPolicy
            },
            ['UserNamePasswordPrefixCompareEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = false,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.UserNamePasswordPrefixCompareEnabled
            },
            ['UserNamePasswordPrefixCompareLength'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['default'] = 4,
                ['minimum'] = 4,
                ['maximum'] = 20,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.UserNamePasswordPrefixCompareLength
            },
            ['SNMPv3TrapAccountChangePolicy'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['default'] = 0,
                ['minimum'] = 0,
                ['maximum'] = 1,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_service_intf_types.SNMPv3TrapAccountChangePolicy
            }
        },
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_method_configs'] = {
        ['bmc.kepler.AccountService'] = {
            ['ImportWeakPasswordDictionary'] = {
                ['initiator'] = true,
                ['req'] = {{['baseType'] = 'String', ['param'] = 'Path'}},
                ['rsp'] = {{['baseType'] = 'U32', ['param'] = 'TaskId'}},
                ['privilege'] = {'SecurityMgmt'}
            },
            ['ExportWeakPasswordDictionary'] = {
                ['initiator'] = true,
                ['req'] = {{['baseType'] = 'String', ['param'] = 'Path'}},
                ['rsp'] = {{['baseType'] = 'U32', ['param'] = 'TaskId'}},
                ['privilege'] = {'SecurityMgmt'}
            },
            ['GetRequestedPublicKey'] = {
                ['initiator'] = true,
                ['req'] = {{['baseType'] = 'U8', ['param'] = 'PublicKeyUsageType'}},
                ['rsp'] = {{['baseType'] = 'String', ['param'] = 'PublicKey'}},
                ['privilege'] = {'ReadOnly'}
            },
            ['RecoverAccount'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'U8', ['maximum'] = 17, ['minimum'] = 2, ['param'] = 'AccountId'},
                    {['baseType'] = 'U8', ['maximum'] = 1, ['minimum'] = 0, ['param'] = 'Policy'}
                },
                ['rsp'] = {},
                ['privilege'] = {'UserMgmt'}
            }
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService'] = {
            ['property_defaults'] = {
                ['AccountLockoutCounterResetAfter'] = 0,
                ['AccountLockoutCounterResetEnabled'] = false,
                ['AuthFailureLoggingThreshold'] = 0,
                ['MaxPasswordLength'] = 20,
                ['MinPasswordLength'] = 8,
                ['ServiceEnabled'] = true,
                ['PasswordComplexityEnable'] = true,
                ['InitialPasswordPromptEnable'] = true,
                ['InitialPasswordNeedModify'] = true,
                ['InitialAccountPrivilegeRestrictEnabled'] = false,
                ['MinPasswordValidDays'] = 0,
                ['MaxPasswordValidDays'] = 0,
                ['EmergencyLoginAccountId'] = 0,
                ['SNMPv3TrapAccountId'] = 2,
                ['InactiveDaysThreshold'] = 0,
                ['WeakPasswordDictionaryEnabled'] = true,
                ['HistoryPasswordCount'] = 5,
                ['MaxHistoryPasswordCount'] = 5,
                ['HostUserManagementEnabled'] = true,
                ['OSAdministratorPrivilegeEnabled'] = true,
                ['SNMPv3TrapAccountLimitPolicy'] = 2,
                ['UserNamePasswordPrefixCompareEnabled'] = false,
                ['UserNamePasswordPrefixCompareLength'] = 4,
                ['SNMPv3TrapAccountChangePolicy'] = 0
            },
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['props'] = {
                    ['MaxPasswordLength'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['MinPasswordLength'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['ServiceEnabled'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt},
                    ['PasswordComplexityEnable'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['InitialPasswordPromptEnable'] = {
                        ['read'] = privilege.ReadOnly,
                        ['write'] = privilege.SecurityMgmt
                    },
                    ['InitialPasswordNeedModify'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['InitialAccountPrivilegeRestrictEnabled'] = {
                        ['read'] = privilege.ReadOnly,
                        ['write'] = privilege.SecurityMgmt
                    },
                    ['MinPasswordValidDays'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['MaxPasswordValidDays'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['EmergencyLoginAccountId'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt},
                    ['SNMPv3TrapAccountId'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.BasicSetting},
                    ['InactiveDaysThreshold'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['WeakPasswordDictionaryEnabled'] = {
                        ['read'] = privilege.ReadOnly,
                        ['write'] = privilege.SecurityMgmt
                    },
                    ['HistoryPasswordCount'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['MaxHistoryPasswordCount'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['HostUserManagementEnabled'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt},
                    ['OSAdministratorPrivilegeEnabled'] = {
                        ['read'] = privilege.ReadOnly,
                        ['write'] = privilege.UserMgmt
                    },
                    ['UserNamePasswordPrefixCompareEnabled'] = {
                        ['read'] = privilege.ReadOnly,
                        ['write'] = privilege.SecurityMgmt
                    },
                    ['UserNamePasswordPrefixCompareLength'] = {
                        ['read'] = privilege.ReadOnly,
                        ['write'] = privilege.SecurityMgmt
                    },
                    ['SNMPv3TrapAccountChangePolicy'] = {
                        ['read'] = privilege.ReadOnly,
                        ['write'] = privilege.SecurityMgmt
                    }
                },
                ['methods'] = {
                    ['ImportWeakPasswordDictionary'] = privilege.SecurityMgmt,
                    ['ExportWeakPasswordDictionary'] = privilege.SecurityMgmt,
                    ['GetRequestedPublicKey'] = privilege.ReadOnly,
                    ['RecoverAccount'] = privilege.UserMgmt
                }
            },
            ['interface_types'] = account_service_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local ManagerAccounts = {
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService.ManagerAccounts'] = {},
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_method_configs'] = {
        ['bmc.kepler.AccountService.ManagerAccounts'] = {
            ['New'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'U8', ['maximum'] = 17, ['minimum'] = 0, ['param'] = 'AccountId'},
                    {['baseType'] = 'String', ['maxLength'] = 32, ['minLength'] = 1, ['param'] = 'UserName'},
                    {['baseType'] = 'U8[]', ['maxLength'] = 512, ['param'] = 'Password'},
                    {['baseType'] = 'Enum', ['$ref'] = '#/defs/RoleType', ['param'] = 'RoleId'}, {
                        ['baseType'] = 'Array',
                        ['items'] = {['baseType'] = 'Enum', ['$ref'] = '#/defs/LoginInterfaceType'},
                        ['param'] = 'LoginInterface'
                    }, {['baseType'] = 'Enum', ['$ref'] = '#/defs/FirstLoginPolicy', ['param'] = 'FirstLoginPolicy'}
                },
                ['rsp'] = {{['baseType'] = 'U8', ['param'] = 'AccountId'}},
                ['privilege'] = {'UserMgmt'}
            },
            ['NewOEMAccount'] = {
                ['req'] = {
                    {['baseType'] = 'U8', ['maximum'] = 115, ['minimum'] = 101, ['param'] = 'AccountId'},
                    {['baseType'] = 'String', ['maxLength'] = 32, ['minLength'] = 1, ['param'] = 'UserName'},
                    {['baseType'] = 'String', ['maxLength'] = 1024, ['minLength'] = 1, ['param'] = 'Password'},
                    {['baseType'] = 'Dictionary', ['$ref'] = '#/defs/ExtraData', ['param'] = 'ExtraData'}
                },
                ['rsp'] = {{['baseType'] = 'U8', ['param'] = 'AccountId'}},
                ['privilege'] = {'UserMgmt'}
            },
            ['GetIdByUserName'] = {
                ['initiator'] = true,
                ['req'] = {{['baseType'] = 'String', ['maxLength'] = 32, ['minLength'] = 1, ['param'] = 'UserName'}},
                ['rsp'] = {{['baseType'] = 'U8', ['param'] = 'AccountId'}},
                ['privilege'] = {'ConfigureSelf'}
            },
            ['SetAccountWritable'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'U8', ['maximum'] = 115, ['minimum'] = 2, ['param'] = 'AccountId'},
                    {
                        ['baseType'] = 'Dictionary',
                        ['$ref'] = '#/defs/PropertyWritable',
                        ['param'] = 'PropertiesWritable'
                    }
                },
                ['rsp'] = {},
                ['privilege'] = {'UserMgmt'}
            },
            ['GetAccountWritable'] = {
                ['initiator'] = true,
                ['req'] = {{['baseType'] = 'U8', ['maximum'] = 115, ['minimum'] = 2, ['param'] = 'AccountId'}},
                ['rsp'] = {
                    {
                        ['baseType'] = 'Dictionary',
                        ['$ref'] = '#/defs/PropertyWritable',
                        ['param'] = 'PropertiesWritable'
                    }
                },
                ['privilege'] = {'UserMgmt'}
            },
            ['SetAccountLockState'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'U8', ['maximum'] = 115, ['minimum'] = 2, ['param'] = 'AccountId'},
                    {['baseType'] = 'Boolean', ['param'] = 'Lockstatus'}
                },
                ['rsp'] = {},
                ['privilege'] = {'UserMgmt'}
            },
            ['GetUidGidByUserName'] = {
                ['initiator'] = true,
                ['req'] = {{['baseType'] = 'String', ['maxLength'] = 32, ['minLength'] = 1, ['param'] = 'UserName'}},
                ['rsp'] = {{['baseType'] = 'U32', ['param'] = 'UID'}, {['baseType'] = 'U32', ['param'] = 'GID'}}
            }
        }
    },
    ['mdb_signal_configs'] = {
        ['bmc.kepler.AccountService.ManagerAccounts'] = {
            ['PasswordChangedSignal'] = {{['baseType'] = 'U8', ['param'] = 'AccountId'}},
            ['SnmpPasswordChangedSignal'] = {{['baseType'] = 'U8', ['param'] = 'AccountId'}}
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService/Accounts'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService.ManagerAccounts'] = {
            ['property_defaults'] = {},
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['methods'] = {
                    ['New'] = privilege.UserMgmt,
                    ['NewOEMAccount'] = privilege.UserMgmt,
                    ['GetIdByUserName'] = privilege.ConfigureSelf,
                    ['SetAccountWritable'] = privilege.UserMgmt,
                    ['GetAccountWritable'] = privilege.UserMgmt,
                    ['SetAccountLockState'] = privilege.UserMgmt
                }
            },
            ['interface_types'] = manager_accounts_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local ManagerAccount = {
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService.ManagerAccount'] = {
            ['AccountExpiration'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.AccountExpiration
            },
            ['Certificates'] = {
                ['baseType'] = 'U16',
                ['readOnly'] = true,
                ['validator'] = manager_account_intf_types.Certificates
            },
            ['Enabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.Enabled
            },
            ['Id'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = true,
                ['usage'] = {'CSR'},
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.Id
            },
            ['Locked'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.Locked
            },
            ['UserName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = false,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.UserName
            },
            ['Deletable'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.Deletable
            },
            ['PasswordChangeRequired'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'ConfigureSelf'}},
                ['validator'] = manager_account_intf_types.PasswordChangeRequired
            },
            ['PasswordExpiration'] = {
                ['baseType'] = 'U32',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.PasswordExpiration
            },
            ['RoleId'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.RoleId
            },
            ['SshPublicKeyHash'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.SshPublicKeyHash
            },
            ['AccountType'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.AccountType
            },
            ['LoginRuleIds'] = {
                ['baseType'] = 'String[]',
                ['readOnly'] = false,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.LoginRuleIds
            },
            ['LastLoginTime'] = {
                ['baseType'] = 'U32',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.LastLoginTime
            },
            ['LastLoginIP'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.LastLoginIP
            },
            ['LastLoginInterface'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.LastLoginInterface
            },
            ['FirstLoginPolicy'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['default'] = 2,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.FirstLoginPolicy
            },
            ['LoginInterface'] = {
                ['baseType'] = 'String[]',
                ['readOnly'] = false,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.LoginInterface
            },
            ['Privileges'] = {
                ['baseType'] = 'String[]',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = manager_account_intf_types.Privileges
            }
        },
        ['bmc.kepler.AccountService.ManagerAccount.SnmpUser'] = {
            ['AuthenticationProtocol'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = snmp_user_intf_types.AuthenticationProtocol
            },
            ['EncryptionProtocol'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = snmp_user_intf_types.EncryptionProtocol
            },
            ['SnmpEncryptionPasswordInitialStatus'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = true,
                ['privilege'] = {['read'] = {'ConfigureSelf'}, ['write'] = {'UserMgmt'}},
                ['validator'] = snmp_user_intf_types.SnmpEncryptionPasswordInitialStatus
            }
        },
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_method_configs'] = {
        ['bmc.kepler.AccountService.ManagerAccount'] = {
            ['Delete'] = {['initiator'] = true, ['req'] = {}, ['rsp'] = {}, ['privilege'] = {'UserMgmt'}},
            ['ChangePwd'] = {
                ['initiator'] = true,
                ['req'] = {{['baseType'] = 'U8[]', ['maxLength'] = 512, ['minLength'] = 1, ['param'] = 'Password'}},
                ['rsp'] = {},
                ['privilege'] = {'ConfigureSelf'}
            },
            ['ChangeSnmpPwd'] = {
                ['initiator'] = true,
                ['req'] = {{['baseType'] = 'U8[]', ['maxLength'] = 512, ['minLength'] = 1, ['param'] = 'Password'}},
                ['rsp'] = {},
                ['privilege'] = {'ConfigureSelf'}
            },
            ['ImportSSHPublicKey'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'String', ['param'] = 'Type'}, {['baseType'] = 'String', ['param'] = 'Content'}
                },
                ['rsp'] = {{['baseType'] = 'U32', ['param'] = 'TaskId'}},
                ['privilege'] = {'ConfigureSelf'}
            },
            ['DeleteSSHPublicKey'] = {
                ['initiator'] = true,
                ['req'] = {},
                ['rsp'] = {},
                ['privilege'] = {'ConfigureSelf'}
            },
            ['SetLastLogin'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'String', ['param'] = 'Ip'}, {['baseType'] = 'String', ['param'] = 'Interface'}
                },
                ['rsp'] = {{['baseType'] = 'U8', ['param'] = 'Result'}},
                ['privilege'] = {'ConfigureSelf'}
            }
        },
        ['bmc.kepler.AccountService.ManagerAccount.SnmpUser'] = {
            ['SetAuthenticationProtocol'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'U8', ['param'] = 'SNMPAuthenticationProtocol'},
                    {['baseType'] = 'String', ['maxLength'] = 512, ['minLength'] = 1, ['param'] = 'AuthPassword'},
                    {['baseType'] = 'String', ['maxLength'] = 512, ['minLength'] = 1, ['param'] = 'EncryPassword'}
                },
                ['rsp'] = {},
                ['privilege'] = {'ConfigureSelf'}
            },
            ['SetEncryptionProtocol'] = {
                ['initiator'] = true,
                ['req'] = {{['baseType'] = 'U8', ['param'] = 'SNMPEncryptionProtocol'}},
                ['rsp'] = {},
                ['privilege'] = {'ConfigureSelf'}
            },
            ['GetSnmpKeys'] = {
                ['req'] = {},
                ['rsp'] = {
                    {['baseType'] = 'String', ['param'] = 'AuthenticationKey'},
                    {['baseType'] = 'String', ['param'] = 'EncryptionKey'}
                },
                ['privilege'] = {'UserMgmt'}
            }
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService/Accounts/:Id'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService.ManagerAccount'] = {
            ['property_defaults'] = {
                ['AccountExpiration'] = manager_account_intf_types.AccountExpiration.default[1],
                ['Certificates'] = manager_account_intf_types.Certificates.default[1],
                ['Enabled'] = manager_account_intf_types.Enabled.default[1],
                ['Id'] = manager_account_intf_types.Id.default[1],
                ['Locked'] = manager_account_intf_types.Locked.default[1],
                ['UserName'] = manager_account_intf_types.UserName.default[1],
                ['Deletable'] = manager_account_intf_types.Deletable.default[1],
                ['PasswordChangeRequired'] = true,
                ['PasswordExpiration'] = manager_account_intf_types.PasswordExpiration.default[1],
                ['RoleId'] = manager_account_intf_types.RoleId.default[1],
                ['SshPublicKeyHash'] = manager_account_intf_types.SshPublicKeyHash.default[1],
                ['AccountType'] = manager_account_intf_types.AccountType.default[1],
                ['LoginRuleIds'] = manager_account_intf_types.LoginRuleIds.default[1],
                ['LastLoginTime'] = manager_account_intf_types.LastLoginTime.default[1],
                ['LastLoginIP'] = manager_account_intf_types.LastLoginIP.default[1],
                ['LastLoginInterface'] = manager_account_intf_types.LastLoginInterface.default[1],
                ['FirstLoginPolicy'] = 2,
                ['LoginInterface'] = manager_account_intf_types.LoginInterface.default[1],
                ['Privileges'] = manager_account_intf_types.Privileges.default[1]
            },
            ['privileges'] = {
                ['path'] = privilege.ConfigureSelf,
                ['props'] = {
                    ['AccountExpiration'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['Enabled'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['Id'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['Locked'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['UserName'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['Deletable'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['PasswordChangeRequired'] = {
                        ['read'] = privilege.ConfigureSelf,
                        ['write'] = privilege.ConfigureSelf
                    },
                    ['PasswordExpiration'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['RoleId'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['SshPublicKeyHash'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['AccountType'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['LoginRuleIds'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['LastLoginTime'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['LastLoginIP'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['LastLoginInterface'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['FirstLoginPolicy'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['LoginInterface'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['Privileges'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt}
                },
                ['methods'] = {
                    ['Delete'] = privilege.UserMgmt,
                    ['ChangePwd'] = privilege.ConfigureSelf,
                    ['ChangeSnmpPwd'] = privilege.ConfigureSelf,
                    ['ImportSSHPublicKey'] = privilege.ConfigureSelf,
                    ['DeleteSSHPublicKey'] = privilege.ConfigureSelf,
                    ['SetLastLogin'] = privilege.ConfigureSelf
                }
            },
            ['interface_types'] = manager_account_intf_types
        },
        ['bmc.kepler.AccountService.ManagerAccount.SnmpUser'] = {
            ['property_defaults'] = {
                ['AuthenticationProtocol'] = snmp_user_intf_types.AuthenticationProtocol.default[1],
                ['EncryptionProtocol'] = snmp_user_intf_types.EncryptionProtocol.default[1],
                ['SnmpEncryptionPasswordInitialStatus'] = snmp_user_intf_types.SnmpEncryptionPasswordInitialStatus
                    .default[1]
            },
            ['privileges'] = {
                ['path'] = privilege.ConfigureSelf,
                ['props'] = {
                    ['AuthenticationProtocol'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['EncryptionProtocol'] = {['read'] = privilege.ConfigureSelf, ['write'] = privilege.UserMgmt},
                    ['SnmpEncryptionPasswordInitialStatus'] = {
                        ['read'] = privilege.ConfigureSelf,
                        ['write'] = privilege.UserMgmt
                    }
                },
                ['methods'] = {
                    ['SetAuthenticationProtocol'] = privilege.ConfigureSelf,
                    ['SetEncryptionProtocol'] = privilege.ConfigureSelf,
                    ['GetSnmpKeys'] = privilege.UserMgmt
                }
            },
            ['interface_types'] = snmp_user_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ConfigureSelf},
            ['interface_types'] = properties_intf_types
        }
    })
}

local ManagerAccountDB = {
    ['table_name'] = 't_manager_account',
    ['prop_configs'] = {
        ['AccountExpiration'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = false,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.AccountExpiration
        },
        ['Certificates'] = {
            ['baseType'] = 'U16',
            ['notAllowNull'] = false,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.Certificates
        },
        ['Enabled'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.Enabled
        },
        ['Id'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.Id
        },
        ['Locked'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.Locked
        },
        ['UserName'] = {
            ['baseType'] = 'String',
            ['uniqueKey'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.UserName
        },
        ['Deletable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.Deletable
        },
        ['Password'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = manager_account_db_class_types.Password
        },
        ['KDFPassword'] = {
            ['baseType'] = 'String',
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = manager_account_db_class_types.KDFPassword
        },
        ['PasswordChangeRequired'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.PasswordChangeRequired
        },
        ['PasswordExpiration'] = {
            ['baseType'] = 'U32',
            ['default'] = 4294967295,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.PasswordExpiration
        },
        ['RoleId'] = {
            ['baseType'] = 'U8',
            ['default'] = 0,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.RoleId
        },
        ['SshPublicKeyHash'] = {
            ['baseType'] = 'String',
            ['default'] = '',
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = manager_account_db_class_types.SshPublicKeyHash
        },
        ['IpmiPassword'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = manager_account_db_class_types.IpmiPassword
        },
        ['IpmiPasswordBak'] = {
            ['baseType'] = 'String',
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = manager_account_db_class_types.IpmiPasswordBak
        },
        ['WithinMinPasswordDays'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.WithinMinPasswordDays
        },
        ['LoginRuleIds'] = {
            ['baseType'] = 'U8',
            ['default'] = 0,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.LoginRuleIds
        },
        ['InactUserRemainDays'] = {
            ['baseType'] = 'U32',
            ['default'] = 4294967295,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.InactUserRemainDays
        },
        ['LastLoginTime'] = {
            ['baseType'] = 'U32',
            ['default'] = 4294967295,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.LastLoginTime
        },
        ['LastLoginIP'] = {
            ['baseType'] = 'String',
            ['default'] = '',
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.LastLoginIP
        },
        ['LastLoginInterface'] = {
            ['baseType'] = 'Enum',
            ['default'] = 'Web',
            ['$ref'] = 'types.json#/defs/LoginInterface',
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.LastLoginInterface
        },
        ['FirstLoginPolicy'] = {
            ['baseType'] = 'Enum',
            ['default'] = 'ForcePasswordReset',
            ['$ref'] = 'types.json#/defs/FirstLoginPolicy',
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.FirstLoginPolicy
        },
        ['AccountType'] = {
            ['baseType'] = 'Enum',
            ['default'] = 'Local',
            ['$ref'] = 'types.json#/defs/AccountType',
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.AccountType
        },
        ['LoginInterface'] = {
            ['baseType'] = 'U32',
            ['default'] = 0,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.LoginInterface
        },
        ['PasswordValidStartTime'] = {
            ['baseType'] = 'U32',
            ['default'] = 0,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.PasswordValidStartTime
        },
        ['InactiveStartTime'] = {
            ['baseType'] = 'U32',
            ['default'] = 0,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.InactiveStartTime
        },
        ['PasswordWritable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.PasswordWritable
        },
        ['UserNameWritable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.UserNameWritable
        },
        ['LoginInterfaceWritable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.LoginInterfaceWritable
        },
        ['RoleIdWritable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.RoleIdWritable
        },
        ['EnabledWritable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.EnabledWritable
        },
        ['LoginRuleIdsWritable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.LoginRuleIdsWritable
        },
        ['AuthenticationProtocolWritable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.AuthenticationProtocolWritable
        },
        ['EncryptionProtocolWritable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.EncryptionProtocolWritable
        },
        ['SNMPPasswordWritable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['critical'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_db_class_types.SNMPPasswordWritable
        }
    },
    ['default_props'] = {
        ['AccountExpiration'] = manager_account_db_class_types.AccountExpiration.default[1],
        ['Certificates'] = manager_account_db_class_types.Certificates.default[1],
        ['Enabled'] = false,
        ['Id'] = manager_account_db_class_types.Id.default[1],
        ['Locked'] = false,
        ['UserName'] = manager_account_db_class_types.UserName.default[1],
        ['Deletable'] = false,
        ['Password'] = manager_account_db_class_types.Password.default[1],
        ['KDFPassword'] = manager_account_db_class_types.KDFPassword.default[1],
        ['PasswordChangeRequired'] = true,
        ['PasswordExpiration'] = 4294967295,
        ['RoleId'] = 0,
        ['SshPublicKeyHash'] = '',
        ['IpmiPassword'] = manager_account_db_class_types.IpmiPassword.default[1],
        ['IpmiPasswordBak'] = manager_account_db_class_types.IpmiPasswordBak.default[1],
        ['WithinMinPasswordDays'] = false,
        ['LoginRuleIds'] = 0,
        ['InactUserRemainDays'] = 4294967295,
        ['LastLoginTime'] = 4294967295,
        ['LastLoginIP'] = '',
        ['LastLoginInterface'] = types.LoginInterface.Web:value(),
        ['FirstLoginPolicy'] = types.FirstLoginPolicy.ForcePasswordReset:value(),
        ['AccountType'] = types.AccountType.Local:value(),
        ['LoginInterface'] = 0,
        ['PasswordValidStartTime'] = 0,
        ['InactiveStartTime'] = 0,
        ['PasswordWritable'] = true,
        ['UserNameWritable'] = true,
        ['LoginInterfaceWritable'] = true,
        ['RoleIdWritable'] = true,
        ['EnabledWritable'] = true,
        ['LoginRuleIdsWritable'] = true,
        ['AuthenticationProtocolWritable'] = true,
        ['EncryptionProtocolWritable'] = true,
        ['SNMPPasswordWritable'] = true
    }
}

local ManagerAccountBackup = {
    ['table_name'] = 't_manager_account_backup',
    ['prop_configs'] = {
        ['Id'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = manager_account_backup_class_types.Id
        },
        ['ManagerAccountData'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = false,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = manager_account_backup_class_types.ManagerAccountData
        },
        ['IpmiAccountData'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = false,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = manager_account_backup_class_types.IpmiAccountData
        },
        ['SnmpAccountData'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = false,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = manager_account_backup_class_types.SnmpAccountData
        },
        ['IpmiChannelData'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = false,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = false,
            ['validator'] = manager_account_backup_class_types.IpmiChannelData
        }
    },
    ['default_props'] = {
        ['Id'] = manager_account_backup_class_types.Id.default[1],
        ['ManagerAccountData'] = manager_account_backup_class_types.ManagerAccountData.default[1],
        ['IpmiAccountData'] = manager_account_backup_class_types.IpmiAccountData.default[1],
        ['SnmpAccountData'] = manager_account_backup_class_types.SnmpAccountData.default[1],
        ['IpmiChannelData'] = manager_account_backup_class_types.IpmiChannelData.default[1]
    }
}

local SNMPUserInfo = {
    ['table_name'] = 't_snmp_user_info',
    ['prop_configs'] = {
        ['AccountId'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = snmp_user_info_class_types.AccountId
        },
        ['AuthenticationKey'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = true,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = snmp_user_info_class_types.AuthenticationKey
        },
        ['AuthenticationKeySet'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = snmp_user_info_class_types.AuthenticationKeySet
        },
        ['AuthenticationProtocol'] = {
            ['baseType'] = 'Enum',
            ['$ref'] = 'types.json#/defs/SNMPAuthenticationProtocols',
            ['default'] = 'SHA256',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = snmp_user_info_class_types.AuthenticationProtocol
        },
        ['EncryptionKey'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = true,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = snmp_user_info_class_types.EncryptionKey
        },
        ['EncryptionKeySet'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = snmp_user_info_class_types.EncryptionKeySet
        },
        ['EncryptionProtocol'] = {
            ['baseType'] = 'Enum',
            ['$ref'] = 'types.json#/defs/SNMPEncryptionProtocols',
            ['default'] = 'AES128',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = snmp_user_info_class_types.EncryptionProtocol
        },
        ['SNMPPassword'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = true,
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = snmp_user_info_class_types.SNMPPassword
        },
        ['SNMPKDFPassword'] = {
            ['baseType'] = 'String',
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = snmp_user_info_class_types.SNMPKDFPassword
        },
        ['SnmpEncryptionPasswordInitialStatus'] = {
            ['baseType'] = 'Boolean',
            ['default'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = snmp_user_info_class_types.SnmpEncryptionPasswordInitialStatus
        }
    },
    ['default_props'] = {
        ['AccountId'] = snmp_user_info_class_types.AccountId.default[1],
        ['AuthenticationKey'] = snmp_user_info_class_types.AuthenticationKey.default[1],
        ['AuthenticationKeySet'] = false,
        ['AuthenticationProtocol'] = types.SNMPAuthenticationProtocols.SHA256:value(),
        ['EncryptionKey'] = snmp_user_info_class_types.EncryptionKey.default[1],
        ['EncryptionKeySet'] = false,
        ['EncryptionProtocol'] = types.SNMPEncryptionProtocols.AES128:value(),
        ['SNMPPassword'] = snmp_user_info_class_types.SNMPPassword.default[1],
        ['SNMPKDFPassword'] = snmp_user_info_class_types.SNMPKDFPassword.default[1],
        ['SnmpEncryptionPasswordInitialStatus'] = true
    }
}

local IpmiUserInfo = {
    ['table_name'] = 't_ipmi_user_info',
    ['prop_configs'] = {
        ['AccountId'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_user_info_class_types.AccountId
        },
        ['Use20BytesPasswd'] = {
            ['baseType'] = 'U8',
            ['default'] = 1,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_user_info_class_types.Use20BytesPasswd
        },
        ['IsCallin'] = {
            ['baseType'] = 'U8',
            ['default'] = 0,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_user_info_class_types.IsCallin
        },
        ['IsEnableAuth'] = {
            ['baseType'] = 'U8',
            ['default'] = 1,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_user_info_class_types.IsEnableAuth
        },
        ['IsEnableIpmiMsg'] = {
            ['baseType'] = 'U8',
            ['default'] = 1,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_user_info_class_types.IsEnableIpmiMsg
        },
        ['IsEnableByPasswd'] = {
            ['baseType'] = 'Enum',
            ['$ref'] = 'types.json#/defs/IpmiUserEnableByPassword',
            ['default'] = 'Disable',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_user_info_class_types.IsEnableByPasswd
        },
        ['Privilege0'] = {
            ['baseType'] = 'Enum',
            ['$ref'] = 'types.json#/defs/IpmiPrivilege',
            ['default'] = 'RESERVED',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_user_info_class_types.Privilege0
        },
        ['Privilege1'] = {
            ['baseType'] = 'Enum',
            ['$ref'] = 'types.json#/defs/IpmiPrivilege',
            ['default'] = 'RESERVED',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_user_info_class_types.Privilege1
        },
        ['IsSynced'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_user_info_class_types.IsSynced
        }
    },
    ['default_props'] = {
        ['AccountId'] = ipmi_user_info_class_types.AccountId.default[1],
        ['Use20BytesPasswd'] = 1,
        ['IsCallin'] = 0,
        ['IsEnableAuth'] = 1,
        ['IsEnableIpmiMsg'] = 1,
        ['IsEnableByPasswd'] = types.IpmiUserEnableByPassword.Disable:value(),
        ['Privilege0'] = types.IpmiPrivilege.RESERVED:value(),
        ['Privilege1'] = types.IpmiPrivilege.RESERVED:value(),
        ['IsSynced'] = false
    }
}

local HistoryPassword = {
    ['table_name'] = 't_history_password',
    ['prop_configs'] = {
        ['AccountId'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['notAllowNull'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = history_password_class_types.AccountId
        },
        ['SequenceNumber'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['notAllowNull'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = history_password_class_types.SequenceNumber
        },
        ['Password'] = {
            ['baseType'] = 'String',
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = history_password_class_types.Password
        },
        ['KDFPassword'] = {
            ['baseType'] = 'String',
            ['usage'] = {'PoweroffPer'},
            ['sensitive'] = true,
            ['validator'] = history_password_class_types.KDFPassword
        }
    },
    ['default_props'] = {
        ['AccountId'] = history_password_class_types.AccountId.default[1],
        ['SequenceNumber'] = history_password_class_types.SequenceNumber.default[1],
        ['Password'] = history_password_class_types.Password.default[1],
        ['KDFPassword'] = history_password_class_types.KDFPassword.default[1]
    }
}

local Rule = {
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService.Rule'] = {
            ['Enabled'] = {
                ['baseType'] = 'Boolean',
                ['default'] = false,
                ['readOnly'] = false,
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = rule_intf_types.Enabled
            },
            ['IpRule'] = {
                ['baseType'] = 'String',
                ['readOnly'] = false,
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = rule_intf_types.IpRule
            },
            ['MacRule'] = {
                ['baseType'] = 'String',
                ['readOnly'] = false,
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = rule_intf_types.MacRule
            },
            ['TimeRule'] = {
                ['baseType'] = 'String',
                ['readOnly'] = false,
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = rule_intf_types.TimeRule
            }
        },
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService/Rules/:RuleId'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService.Rule'] = {
            ['property_defaults'] = {
                ['Enabled'] = false,
                ['IpRule'] = rule_intf_types.IpRule.default[1],
                ['MacRule'] = rule_intf_types.MacRule.default[1],
                ['TimeRule'] = rule_intf_types.TimeRule.default[1]
            },
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['props'] = {
                    ['Enabled'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['IpRule'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['MacRule'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['TimeRule'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt}
                }
            },
            ['interface_types'] = rule_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local LoginRule = {
    ['table_name'] = 't_login_rule',
    ['prop_configs'] = {
        ['RuleId'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = login_rule_class_types.RuleId
        },
        ['IpRule'] = {
            ['baseType'] = 'String',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = login_rule_class_types.IpRule
        },
        ['Ipv6Rule'] = {
            ['baseType'] = 'String',
            ['default'] = '',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = login_rule_class_types.Ipv6Rule
        },
        ['TimeRule'] = {
            ['baseType'] = 'String',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = login_rule_class_types.TimeRule
        },
        ['MacRule'] = {
            ['baseType'] = 'String',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = login_rule_class_types.MacRule
        },
        ['Enabled'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = login_rule_class_types.Enabled
        }
    },
    ['default_props'] = {
        ['RuleId'] = login_rule_class_types.RuleId.default[1],
        ['IpRule'] = login_rule_class_types.IpRule.default[1],
        ['Ipv6Rule'] = '',
        ['TimeRule'] = login_rule_class_types.TimeRule.default[1],
        ['MacRule'] = login_rule_class_types.MacRule.default[1],
        ['Enabled'] = false
    }
}

local Roles = {
    ['table_name'] = 't_roles',
    ['prop_configs'] = {
        ['Id'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = roles_class_types.Id
        }
    },
    ['default_props'] = {['Id'] = roles_class_types.Id.default[1]},
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService.Roles'] = {
            ['ExtendedCustomRoleEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = roles_intf_types.ExtendedCustomRoleEnabled
            }
        },
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_method_configs'] = {
        ['bmc.kepler.AccountService.Roles'] = {
            ['New'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'U8', ['param'] = 'RoleId'},
                    {['baseType'] = 'String[]', ['param'] = 'AssignedPrivileges'},
                    {['baseType'] = 'String[]', ['param'] = 'OemPrivileges'}
                },
                ['rsp'] = {},
                ['privilege'] = {'UserMgmt'}
            }
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService/Roles'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService.Roles'] = {
            ['property_defaults'] = {
                ['ExtendedCustomRoleEnabled'] = roles_intf_types.ExtendedCustomRoleEnabled.default[1]
            },
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['props'] = {
                    ['ExtendedCustomRoleEnabled'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt}
                },
                ['methods'] = {['New'] = privilege.UserMgmt}
            },
            ['interface_types'] = roles_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local Role = {
    ['table_name'] = 't_role',
    ['prop_configs'] = {
        ['Id'] = {
            ['baseType'] = 'Enum',
            ['$ref'] = 'types.json#/defs/RoleType',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.Id
        },
        ['RoleName'] = {
            ['baseType'] = 'String',
            ['uniqueKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.RoleName
        },
        ['UserMgmt'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.UserMgmt
        },
        ['BasicSetting'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.BasicSetting
        },
        ['KVMMgmt'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.KVMMgmt
        },
        ['ReadOnly'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.ReadOnly
        },
        ['VMMMgmt'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.VMMMgmt
        },
        ['SecurityMgmt'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.SecurityMgmt
        },
        ['PowerMgmt'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.PowerMgmt
        },
        ['DiagnoseMgmt'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.DiagnoseMgmt
        },
        ['ConfigureSelf'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = role_class_types.ConfigureSelf
        }
    },
    ['default_props'] = {
        ['Id'] = role_class_types.Id.default[1]:value(),
        ['RoleName'] = role_class_types.RoleName.default[1],
        ['UserMgmt'] = false,
        ['BasicSetting'] = false,
        ['KVMMgmt'] = false,
        ['ReadOnly'] = false,
        ['VMMMgmt'] = false,
        ['SecurityMgmt'] = false,
        ['PowerMgmt'] = false,
        ['DiagnoseMgmt'] = false,
        ['ConfigureSelf'] = false
    },
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService.Role'] = {
            ['RolePrivilege'] = {
                ['baseType'] = 'String[]',
                ['readOnly'] = true,
                ['default'] = {},
                ['options'] = {['emitsChangedSignal'] = 'const'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = role_intf_types.RolePrivilege
            },
            ['Name'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['options'] = {['emitsChangedSignal'] = 'const'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = role_intf_types.Name
            }
        },
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_method_configs'] = {
        ['bmc.kepler.AccountService.Role'] = {
            ['SetRolePrivilege'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'U8', ['param'] = 'PrivilegeType'},
                    {['baseType'] = 'Boolean', ['param'] = 'PrivilegeValue'}
                },
                ['rsp'] = {},
                ['privilege'] = {'UserMgmt'}
            },
            ['Delete'] = {['initiator'] = true, ['req'] = {}, ['rsp'] = {}, ['privilege'] = {'UserMgmt'}}
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService/Roles/:Id'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService.Role'] = {
            ['property_defaults'] = {['RolePrivilege'] = {}, ['Name'] = role_intf_types.Name.default[1]},
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['props'] = {
                    ['RolePrivilege'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt},
                    ['Name'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt}
                },
                ['methods'] = {['SetRolePrivilege'] = privilege.UserMgmt, ['Delete'] = privilege.UserMgmt}
            },
            ['interface_types'] = role_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local SnmpCommunity = {
    ['table_name'] = 't_snmp_community',
    ['prop_configs'] = {
        ['Id'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = snmp_community_class_types.Id
        }
    },
    ['default_props'] = {['Id'] = snmp_community_class_types.Id.default[1]},
    ['mdb_prop_configs'] = {
        ['bmc.kepler.Managers.SnmpService.SnmpCommunity'] = {
            ['LongCommunityEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = snmp_community_intf_types.LongCommunityEnabled
            },
            ['RwCommunityEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = true,
                ['options'] = {['emitsChangedSignal'] = 'true'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = snmp_community_intf_types.RwCommunityEnabled
            }
        },
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_method_configs'] = {
        ['bmc.kepler.Managers.SnmpService.SnmpCommunity'] = {
            ['SetRwCommunity'] = {
                ['req'] = {{['baseType'] = 'String', ['param'] = 'RwCommunity'}},
                ['rsp'] = {},
                ['privilege'] = {'UserMgmt'}
            },
            ['SetRoCommunity'] = {
                ['req'] = {{['baseType'] = 'String', ['param'] = 'RwCommunity'}},
                ['rsp'] = {},
                ['privilege'] = {'UserMgmt'}
            },
            ['GetSnmpCommunity'] = {
                ['req'] = {},
                ['rsp'] = {
                    {['baseType'] = 'String', ['param'] = 'RwCommunity'},
                    {['baseType'] = 'String', ['param'] = 'RoCommunity'}
                },
                ['privilege'] = {'UserMgmt'}
            },
            ['SetSnmpCommunityLoginRule'] = {
                ['req'] = {{['baseType'] = 'String[]', ['param'] = 'LoginRuleIds'}},
                ['rsp'] = {},
                ['privilege'] = {'UserMgmt'}
            }
        }
    },
    ['mdb_signal_configs'] = {
        ['bmc.kepler.Managers.SnmpService.SnmpCommunity'] = {
            ['SnmpCommunityChangedSignal'] = {
                {['baseType'] = 'String', ['param'] = 'RoCommunity'},
                {['baseType'] = 'String', ['param'] = 'RwCommunity'}
            }
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/Managers/:ManagerId/SnmpService/SnmpCommunity'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.Managers.SnmpService.SnmpCommunity'] = {
            ['property_defaults'] = {['LongCommunityEnabled'] = true, ['RwCommunityEnabled'] = true},
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['props'] = {
                    ['LongCommunityEnabled'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt},
                    ['RwCommunityEnabled'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt}
                },
                ['methods'] = {
                    ['SetRwCommunity'] = privilege.UserMgmt,
                    ['SetRoCommunity'] = privilege.UserMgmt,
                    ['GetSnmpCommunity'] = privilege.UserMgmt,
                    ['SetSnmpCommunityLoginRule'] = privilege.UserMgmt
                }
            },
            ['interface_types'] = snmp_community_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local LocalAccountAuthN = {
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService.LocalAccountAuthN'] = {},
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_method_configs'] = {
        ['bmc.kepler.AccountService.LocalAccountAuthN'] = {
            ['LocalAuthenticate'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'String', ['maxLength'] = 32, ['minLength'] = 1, ['param'] = 'UserName'},
                    {['baseType'] = 'U8[]', ['param'] = 'Password'},
                    {['baseType'] = 'Dictionary', ['$ref'] = '#/defs/Config', ['param'] = 'Config'}
                },
                ['rsp'] = {{['baseType'] = 'Dictionary', ['$ref'] = '#/defs/AccountData', ['param'] = 'AccountData'}},
                ['privilege'] = {'ReadOnly'}
            },
            ['VncAuthenticate'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'String', ['param'] = 'CipherText'},
                    {['baseType'] = 'String', ['param'] = 'AuthChallenge'}
                },
                ['rsp'] = {{['baseType'] = 'Dictionary', ['$ref'] = '#/defs/AccountData', ['param'] = 'AccountData'}},
                ['privilege'] = {'ReadOnly'}
            },
            ['GenRmcp20Code'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'U8', ['param'] = 'AuthAlgo'},
                    {['baseType'] = 'String', ['maxLength'] = 32, ['minLength'] = 1, ['param'] = 'UserName'},
                    {['baseType'] = 'U32', ['param'] = 'ConsoleSid'}, {['baseType'] = 'U32', ['param'] = 'ManagedSid'},
                    {['baseType'] = 'U8[]', ['maxLength'] = 16, ['minLength'] = 16, ['param'] = 'ConsoleRandom'},
                    {['baseType'] = 'U8[]', ['maxLength'] = 16, ['minLength'] = 16, ['param'] = 'ManagedRandom'},
                    {['baseType'] = 'U8[]', ['maxLength'] = 16, ['minLength'] = 16, ['param'] = 'ManagedGuid'},
                    {['baseType'] = 'U8', ['param'] = 'Role'}, {['baseType'] = 'String', ['param'] = 'Ip'}
                },
                ['rsp'] = {
                    {['baseType'] = 'U8[]', ['param'] = 'Rap2AuthCode'}, {['baseType'] = 'U8[]', ['param'] = 'Sik'},
                    {['baseType'] = 'U8[]', ['param'] = 'Rap3AuthCode'}
                }
            },
            ['GenRmcp15Code'] = {
                ['initiator'] = true,
                ['req'] = {
                    {['baseType'] = 'U8', ['param'] = 'AuthAlgo'},
                    {['baseType'] = 'U8[]', ['maxLength'] = 255, ['minLength'] = 1, ['param'] = 'PayLoad'},
                    {['baseType'] = 'U8', ['param'] = 'AccountId'}, {['baseType'] = 'U32', ['param'] = 'SessionId'},
                    {['baseType'] = 'U32', ['param'] = 'SessionSequence'}
                },
                ['rsp'] = {{['baseType'] = 'U8[]', ['param'] = 'AuthCode'}}
            }
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService/LocalAccountAuthN'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService.LocalAccountAuthN'] = {
            ['property_defaults'] = {},
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['methods'] = {['LocalAuthenticate'] = privilege.ReadOnly, ['VncAuthenticate'] = privilege.ReadOnly}
            },
            ['interface_types'] = local_account_auth_n_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local AccountBackup = {
    ['table_name'] = 't_account_backup',
    ['prop_configs'] = {
        ['Id'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PermanentPer'},
            ['validator'] = account_backup_class_types.Id
        },
        ['UserName'] = {
            ['baseType'] = 'String',
            ['uniqueKey'] = true,
            ['usage'] = {'PermanentPer'},
            ['validator'] = account_backup_class_types.UserName
        },
        ['Password'] = {
            ['baseType'] = 'String',
            ['notAllowNull'] = true,
            ['usage'] = {'PermanentPer'},
            ['sensitive'] = true,
            ['validator'] = account_backup_class_types.Password
        },
        ['RoleId'] = {
            ['baseType'] = 'U8',
            ['default'] = 0,
            ['usage'] = {'PermanentPer'},
            ['validator'] = account_backup_class_types.RoleId
        },
        ['LoginInterface'] = {
            ['baseType'] = 'U32',
            ['default'] = 0,
            ['usage'] = {'PermanentPer'},
            ['validator'] = account_backup_class_types.LoginInterface
        },
        ['Enabled'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PermanentPer'},
            ['validator'] = account_backup_class_types.Enabled
        }
    },
    ['default_props'] = {
        ['Id'] = account_backup_class_types.Id.default[1],
        ['UserName'] = account_backup_class_types.UserName.default[1],
        ['Password'] = account_backup_class_types.Password.default[1],
        ['RoleId'] = 0,
        ['LoginInterface'] = 0,
        ['Enabled'] = false
    }
}

local PasswordPolicy = {
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService.PasswordPolicy'] = {
            ['Policy'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = false,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['default'] = 1,
                ['validator'] = password_policy_intf_types.Policy
            },
            ['Pattern'] = {
                ['baseType'] = 'String',
                ['readOnly'] = false,
                ['maxLength'] = 255,
                ['minLength'] = 0,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = password_policy_intf_types.Pattern
            },
            ['AccountType'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = password_policy_intf_types.AccountType
            },
            ['MaxPasswordLength'] = {
                ['baseType'] = 'U32',
                ['readOnly'] = false,
                ['maximum'] = 512,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = password_policy_intf_types.MaxPasswordLength
            }
        },
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService/PasswordPolicys/:AccountType'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService.PasswordPolicy'] = {
            ['property_defaults'] = {
                ['Policy'] = 1,
                ['Pattern'] = password_policy_intf_types.Pattern.default[1],
                ['AccountType'] = password_policy_intf_types.AccountType.default[1],
                ['MaxPasswordLength'] = password_policy_intf_types.MaxPasswordLength.default[1]
            },
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['props'] = {
                    ['Policy'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['Pattern'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['AccountType'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['MaxPasswordLength'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt}
                }
            },
            ['interface_types'] = password_policy_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local PasswordPolicyDB = {
    ['table_name'] = 't_password_policy',
    ['prop_configs'] = {
        ['AccountType'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = password_policy_db_class_types.AccountType
        },
        ['AccountTypeName'] = {['baseType'] = 'String', ['validator'] = password_policy_db_class_types.AccountTypeName},
        ['Policy'] = {
            ['baseType'] = 'U8',
            ['default'] = 1,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = password_policy_db_class_types.Policy
        },
        ['Pattern'] = {
            ['baseType'] = 'String',
            ['default'] = '',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = password_policy_db_class_types.Pattern
        },
        ['MaxPasswordLength'] = {
            ['baseType'] = 'U32',
            ['usage'] = {'TemporaryPer'},
            ['validator'] = password_policy_db_class_types.MaxPasswordLength
        }
    },
    ['default_props'] = {
        ['AccountType'] = password_policy_db_class_types.AccountType.default[1],
        ['AccountTypeName'] = password_policy_db_class_types.AccountTypeName.default[1],
        ['Policy'] = 1,
        ['Pattern'] = '',
        ['MaxPasswordLength'] = password_policy_db_class_types.MaxPasswordLength.default[1]
    }
}

local AccountPolicy = {
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService.AccountPolicy'] = {
            ['NamePattern'] = {
                ['baseType'] = 'String',
                ['readOnly'] = false,
                ['default'] = '',
                ['maxLength'] = 255,
                ['minLength'] = 0,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'SecurityMgmt'}},
                ['validator'] = account_policy_intf_types.NamePattern
            },
            ['AllowedLoginInterfaces'] = {
                ['baseType'] = 'String[]',
                ['readOnly'] = false,
                ['default'] = {'Web', 'SNMP', 'IPMI', 'SSH', 'SFTP', 'Local', 'Redfish'},
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = account_policy_intf_types.AllowedLoginInterfaces
            },
            ['Visible'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = false,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = account_policy_intf_types.Visible
            },
            ['Deletable'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = false,
                ['default'] = false,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['privilege'] = {['read'] = {'ReadOnly'}, ['write'] = {'UserMgmt'}},
                ['validator'] = account_policy_intf_types.Deletable
            }
        },
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService/AccountPolicies/:AccountType'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService.AccountPolicy'] = {
            ['property_defaults'] = {
                ['NamePattern'] = '',
                ['AllowedLoginInterfaces'] = {'Web', 'SNMP', 'IPMI', 'SSH', 'SFTP', 'Local', 'Redfish'},
                ['Visible'] = false,
                ['Deletable'] = false
            },
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['props'] = {
                    ['NamePattern'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.SecurityMgmt},
                    ['AllowedLoginInterfaces'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt},
                    ['Visible'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt},
                    ['Deletable'] = {['read'] = privilege.ReadOnly, ['write'] = privilege.UserMgmt}
                }
            },
            ['interface_types'] = account_policy_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local AccountPolicyDB = {
    ['table_name'] = 't_account_policy',
    ['prop_configs'] = {
        ['AccountType'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_policy_db_class_types.AccountType
        },
        ['NamePattern'] = {
            ['baseType'] = 'String',
            ['default'] = '',
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_policy_db_class_types.NamePattern
        },
        ['AllowedLoginInterfaces'] = {
            ['baseType'] = 'U32',
            ['default'] = 223,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_policy_db_class_types.AllowedLoginInterfaces
        },
        ['Visible'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_policy_db_class_types.Visible
        },
        ['Deletable'] = {
            ['baseType'] = 'Boolean',
            ['default'] = false,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = account_policy_db_class_types.Deletable
        }
    },
    ['default_props'] = {
        ['AccountType'] = account_policy_db_class_types.AccountType.default[1],
        ['NamePattern'] = '',
        ['AllowedLoginInterfaces'] = 223,
        ['Visible'] = false,
        ['Deletable'] = false
    }
}

local IpmiChannelConfig = {
    ['table_name'] = 't_ipmi_channel_config',
    ['prop_configs'] = {
        ['AccountId'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_channel_config_class_types.AccountId
        },
        ['ChannelNumber'] = {
            ['baseType'] = 'U8',
            ['primaryKey'] = true,
            ['usage'] = {'PoweroffPer'},
            ['validator'] = ipmi_channel_config_class_types.ChannelNumber
        }
    },
    ['default_props'] = {
        ['AccountId'] = ipmi_channel_config_class_types.AccountId.default[1],
        ['ChannelNumber'] = ipmi_channel_config_class_types.ChannelNumber.default[1]
    },
    ['mdb_prop_configs'] = {
        ['bmc.kepler.AccountService.ManagerAccount.IpmiChannelConfig'] = {
            ['PrivilegeLimit'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}},
                ['validator'] = ipmi_channel_config_intf_types.PrivilegeLimit
            },
            ['IpmiMessagingEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}},
                ['default'] = 'true',
                ['validator'] = ipmi_channel_config_intf_types.IpmiMessagingEnabled
            },
            ['LinkAuthenticationEnabled'] = {
                ['baseType'] = 'Boolean',
                ['readOnly'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}},
                ['default'] = 'true',
                ['validator'] = ipmi_channel_config_intf_types.LinkAuthenticationEnabled
            },
            ['CallbackRestriction'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}},
                ['validator'] = ipmi_channel_config_intf_types.CallbackRestriction
            },
            ['SessionLimit'] = {
                ['baseType'] = 'U8',
                ['readOnly'] = true,
                ['options'] = {['emitsChangedSignal'] = 'false'},
                ['usage'] = {'PoweroffPer'},
                ['privilege'] = {['read'] = {'ReadOnly'}},
                ['validator'] = ipmi_channel_config_intf_types.SessionLimit
            }
        },
        ['bmc.kepler.Object.Properties'] = {
            ['ClassName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ClassName
            },
            ['ObjectName'] = {
                ['baseType'] = 'String',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectName
            },
            ['ObjectIdentifier'] = {
                ['baseType'] = 'Struct',
                ['$ref'] = '#/defs/StructIdentifier',
                ['readOnly'] = true,
                ['validator'] = properties_intf_types.ObjectIdentifier
            }
        }
    },
    ['mdb_classes'] = mdb.get_class_obj('/bmc/kepler/AccountService/Accounts/:Id/Channels/:ChannelNumber'),
    ['new_mdb_objects'] = mdb.new_objects_builder({
        ['bmc.kepler.AccountService.ManagerAccount.IpmiChannelConfig'] = {
            ['property_defaults'] = {
                ['PrivilegeLimit'] = ipmi_channel_config_intf_types.PrivilegeLimit.default[1],
                ['IpmiMessagingEnabled'] = 'true',
                ['LinkAuthenticationEnabled'] = 'true',
                ['CallbackRestriction'] = ipmi_channel_config_intf_types.CallbackRestriction.default[1],
                ['SessionLimit'] = ipmi_channel_config_intf_types.SessionLimit.default[1]
            },
            ['privileges'] = {
                ['path'] = privilege.ReadOnly,
                ['props'] = {
                    ['PrivilegeLimit'] = {['read'] = privilege.ReadOnly},
                    ['IpmiMessagingEnabled'] = {['read'] = privilege.ReadOnly},
                    ['LinkAuthenticationEnabled'] = {['read'] = privilege.ReadOnly},
                    ['CallbackRestriction'] = {['read'] = privilege.ReadOnly},
                    ['SessionLimit'] = {['read'] = privilege.ReadOnly}
                }
            },
            ['interface_types'] = ipmi_channel_config_intf_types
        },
        ['bmc.kepler.Object.Properties'] = {
            ['property_defaults'] = {
                ['ClassName'] = properties_intf_types.ClassName.default[1],
                ['ObjectName'] = properties_intf_types.ObjectName.default[1],
                ['ObjectIdentifier'] = properties_intf_types.ObjectIdentifier.default[1]
            },
            ['privileges'] = {['path'] = privilege.ReadOnly},
            ['interface_types'] = properties_intf_types
        }
    })
}

local M = {}

function M.init(bus)
    class('AccountService', AccountService):set_bus(bus)
    class('ManagerAccounts', ManagerAccounts):set_bus(bus)
    class('ManagerAccount', ManagerAccount):set_bus(bus)
    class('ManagerAccountDB', ManagerAccountDB):set_bus(bus)
    class('ManagerAccountBackup', ManagerAccountBackup):set_bus(bus)
    class('SNMPUserInfo', SNMPUserInfo):set_bus(bus)
    class('IpmiUserInfo', IpmiUserInfo):set_bus(bus)
    class('HistoryPassword', HistoryPassword):set_bus(bus)
    class('Rule', Rule):set_bus(bus)
    class('LoginRule', LoginRule):set_bus(bus)
    class('Roles', Roles):set_bus(bus)
    class('Role', Role):set_bus(bus)
    class('SnmpCommunity', SnmpCommunity):set_bus(bus)
    class('LocalAccountAuthN', LocalAccountAuthN):set_bus(bus)
    class('AccountBackup', AccountBackup):set_bus(bus)
    class('PasswordPolicy', PasswordPolicy):set_bus(bus)
    class('PasswordPolicyDB', PasswordPolicyDB):set_bus(bus)
    class('AccountPolicy', AccountPolicy):set_bus(bus)
    class('AccountPolicyDB', AccountPolicyDB):set_bus(bus)
    class('IpmiChannelConfig', IpmiChannelConfig):set_bus(bus)
end

-- The callback needs to be registered during app initialization
function M.ImplAccountServiceAccountServiceImportWeakPasswordDictionary(cb)
    class('AccountService')['bmc.kepler.AccountService'].ImportWeakPasswordDictionary = function(obj, ctx, ...)
        local req = account_service_intf_types.ImportWeakPasswordDictionaryReq.new(...):validate(nil, nil, true)
        local rsp =
            account_service_intf_types.ImportWeakPasswordDictionaryRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplAccountServiceAccountServiceExportWeakPasswordDictionary(cb)
    class('AccountService')['bmc.kepler.AccountService'].ExportWeakPasswordDictionary = function(obj, ctx, ...)
        local req = account_service_intf_types.ExportWeakPasswordDictionaryReq.new(...):validate(nil, nil, true)
        local rsp =
            account_service_intf_types.ExportWeakPasswordDictionaryRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplAccountServiceAccountServiceGetRequestedPublicKey(cb)
    class('AccountService')['bmc.kepler.AccountService'].GetRequestedPublicKey = function(obj, ctx, ...)
        local req = account_service_intf_types.GetRequestedPublicKeyReq.new(...):validate(nil, nil, true)
        local rsp = account_service_intf_types.GetRequestedPublicKeyRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplAccountServiceAccountServiceRecoverAccount(cb)
    class('AccountService')['bmc.kepler.AccountService'].RecoverAccount = function(obj, ctx, ...)
        local req = account_service_intf_types.RecoverAccountReq.new(...):validate(nil, nil, true)
        local rsp = account_service_intf_types.RecoverAccountRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountsManagerAccountsNew(cb)
    class('ManagerAccounts')['bmc.kepler.AccountService.ManagerAccounts'].New = function(obj, ctx, ...)
        local req = manager_accounts_intf_types.NewReq.new(...):validate(nil, nil, true)
        local rsp = manager_accounts_intf_types.NewRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountsManagerAccountsNewOEMAccount(cb)
    class('ManagerAccounts')['bmc.kepler.AccountService.ManagerAccounts'].NewOEMAccount = function(obj, ctx, ...)
        local req = manager_accounts_intf_types.NewOEMAccountReq.new(...):validate(nil, nil, true)
        local rsp = manager_accounts_intf_types.NewOEMAccountRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountsManagerAccountsGetIdByUserName(cb)
    class('ManagerAccounts')['bmc.kepler.AccountService.ManagerAccounts'].GetIdByUserName = function(obj, ctx, ...)
        local req = manager_accounts_intf_types.GetIdByUserNameReq.new(...):validate(nil, nil, true)
        local rsp = manager_accounts_intf_types.GetIdByUserNameRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountsManagerAccountsSetAccountWritable(cb)
    class('ManagerAccounts')['bmc.kepler.AccountService.ManagerAccounts'].SetAccountWritable = function(obj, ctx, ...)
        local req = manager_accounts_intf_types.SetAccountWritableReq.new(...):validate(nil, nil, true)
        local rsp = manager_accounts_intf_types.SetAccountWritableRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountsManagerAccountsGetAccountWritable(cb)
    class('ManagerAccounts')['bmc.kepler.AccountService.ManagerAccounts'].GetAccountWritable = function(obj, ctx, ...)
        local req = manager_accounts_intf_types.GetAccountWritableReq.new(...):validate(nil, nil, true)
        local rsp = manager_accounts_intf_types.GetAccountWritableRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountsManagerAccountsSetAccountLockState(cb)
    class('ManagerAccounts')['bmc.kepler.AccountService.ManagerAccounts'].SetAccountLockState = function(obj, ctx, ...)
        local req = manager_accounts_intf_types.SetAccountLockStateReq.new(...):validate(nil, nil, true)
        local rsp = manager_accounts_intf_types.SetAccountLockStateRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountsManagerAccountsGetUidGidByUserName(cb)
    class('ManagerAccounts')['bmc.kepler.AccountService.ManagerAccounts'].GetUidGidByUserName = function(obj, ctx, ...)
        local req = manager_accounts_intf_types.GetUidGidByUserNameReq.new(...):validate(nil, nil, true)
        local rsp = manager_accounts_intf_types.GetUidGidByUserNameRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountManagerAccountDelete(cb)
    class('ManagerAccount')['bmc.kepler.AccountService.ManagerAccount'].Delete = function(obj, ctx, ...)
        local req = manager_account_intf_types.DeleteReq.new(...):validate(nil, nil, true)
        local rsp = manager_account_intf_types.DeleteRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountManagerAccountChangePwd(cb)
    class('ManagerAccount')['bmc.kepler.AccountService.ManagerAccount'].ChangePwd = function(obj, ctx, ...)
        local req = manager_account_intf_types.ChangePwdReq.new(...):validate(nil, nil, true)
        local rsp = manager_account_intf_types.ChangePwdRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountManagerAccountChangeSnmpPwd(cb)
    class('ManagerAccount')['bmc.kepler.AccountService.ManagerAccount'].ChangeSnmpPwd = function(obj, ctx, ...)
        local req = manager_account_intf_types.ChangeSnmpPwdReq.new(...):validate(nil, nil, true)
        local rsp = manager_account_intf_types.ChangeSnmpPwdRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountManagerAccountImportSSHPublicKey(cb)
    class('ManagerAccount')['bmc.kepler.AccountService.ManagerAccount'].ImportSSHPublicKey = function(obj, ctx, ...)
        local req = manager_account_intf_types.ImportSSHPublicKeyReq.new(...):validate(nil, nil, true)
        local rsp = manager_account_intf_types.ImportSSHPublicKeyRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountManagerAccountDeleteSSHPublicKey(cb)
    class('ManagerAccount')['bmc.kepler.AccountService.ManagerAccount'].DeleteSSHPublicKey = function(obj, ctx, ...)
        local req = manager_account_intf_types.DeleteSSHPublicKeyReq.new(...):validate(nil, nil, true)
        local rsp = manager_account_intf_types.DeleteSSHPublicKeyRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountManagerAccountSetLastLogin(cb)
    class('ManagerAccount')['bmc.kepler.AccountService.ManagerAccount'].SetLastLogin = function(obj, ctx, ...)
        local req = manager_account_intf_types.SetLastLoginReq.new(...):validate(nil, nil, true)
        local rsp = manager_account_intf_types.SetLastLoginRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountSnmpUserSetAuthenticationProtocol(cb)
    class('ManagerAccount')['bmc.kepler.AccountService.ManagerAccount.SnmpUser'].SetAuthenticationProtocol = function(
        obj, ctx, ...)
        local req = snmp_user_intf_types.SetAuthenticationProtocolReq.new(...):validate(nil, nil, true)
        local rsp = snmp_user_intf_types.SetAuthenticationProtocolRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountSnmpUserSetEncryptionProtocol(cb)
    class('ManagerAccount')['bmc.kepler.AccountService.ManagerAccount.SnmpUser'].SetEncryptionProtocol = function(obj,
        ctx, ...)
        local req = snmp_user_intf_types.SetEncryptionProtocolReq.new(...):validate(nil, nil, true)
        local rsp = snmp_user_intf_types.SetEncryptionProtocolRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplManagerAccountSnmpUserGetSnmpKeys(cb)
    class('ManagerAccount')['bmc.kepler.AccountService.ManagerAccount.SnmpUser'].GetSnmpKeys = function(obj, ctx, ...)
        local req = snmp_user_intf_types.GetSnmpKeysReq.new(...):validate(nil, nil, true)
        local rsp = snmp_user_intf_types.GetSnmpKeysRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplRolesRolesNew(cb)
    class('Roles')['bmc.kepler.AccountService.Roles'].New = function(obj, ctx, ...)
        local req = roles_intf_types.NewReq.new(...):validate(nil, nil, true)
        local rsp = roles_intf_types.NewRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplRoleRoleSetRolePrivilege(cb)
    class('Role')['bmc.kepler.AccountService.Role'].SetRolePrivilege = function(obj, ctx, ...)
        local req = role_intf_types.SetRolePrivilegeReq.new(...):validate(nil, nil, true)
        local rsp = role_intf_types.SetRolePrivilegeRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplRoleRoleDelete(cb)
    class('Role')['bmc.kepler.AccountService.Role'].Delete = function(obj, ctx, ...)
        local req = role_intf_types.DeleteReq.new(...):validate(nil, nil, true)
        local rsp = role_intf_types.DeleteRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplSnmpCommunitySnmpCommunitySetRwCommunity(cb)
    class('SnmpCommunity')['bmc.kepler.Managers.SnmpService.SnmpCommunity'].SetRwCommunity = function(obj, ctx, ...)
        local req = snmp_community_intf_types.SetRwCommunityReq.new(...):validate(nil, nil, true)
        local rsp = snmp_community_intf_types.SetRwCommunityRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplSnmpCommunitySnmpCommunitySetRoCommunity(cb)
    class('SnmpCommunity')['bmc.kepler.Managers.SnmpService.SnmpCommunity'].SetRoCommunity = function(obj, ctx, ...)
        local req = snmp_community_intf_types.SetRoCommunityReq.new(...):validate(nil, nil, true)
        local rsp = snmp_community_intf_types.SetRoCommunityRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplSnmpCommunitySnmpCommunityGetSnmpCommunity(cb)
    class('SnmpCommunity')['bmc.kepler.Managers.SnmpService.SnmpCommunity'].GetSnmpCommunity = function(obj, ctx, ...)
        local req = snmp_community_intf_types.GetSnmpCommunityReq.new(...):validate(nil, nil, true)
        local rsp = snmp_community_intf_types.GetSnmpCommunityRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplSnmpCommunitySnmpCommunitySetSnmpCommunityLoginRule(cb)
    class('SnmpCommunity')['bmc.kepler.Managers.SnmpService.SnmpCommunity'].SetSnmpCommunityLoginRule = function(obj,
        ctx, ...)
        local req = snmp_community_intf_types.SetSnmpCommunityLoginRuleReq.new(...):validate(nil, nil, true)
        local rsp = snmp_community_intf_types.SetSnmpCommunityLoginRuleRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplLocalAccountAuthNLocalAccountAuthNLocalAuthenticate(cb)
    class('LocalAccountAuthN')['bmc.kepler.AccountService.LocalAccountAuthN'].LocalAuthenticate =
        function(obj, ctx, ...)
            local req = local_account_auth_n_intf_types.LocalAuthenticateReq.new(...):validate(nil, nil, true)
            local rsp = local_account_auth_n_intf_types.LocalAuthenticateRsp.new(cb(obj, ctx, req:unpack())):validate()
            return rsp:unpack(true)
        end
end

-- The callback needs to be registered during app initialization
function M.ImplLocalAccountAuthNLocalAccountAuthNVncAuthenticate(cb)
    class('LocalAccountAuthN')['bmc.kepler.AccountService.LocalAccountAuthN'].VncAuthenticate = function(obj, ctx, ...)
        local req = local_account_auth_n_intf_types.VncAuthenticateReq.new(...):validate(nil, nil, true)
        local rsp = local_account_auth_n_intf_types.VncAuthenticateRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplLocalAccountAuthNLocalAccountAuthNGenRmcp20Code(cb)
    class('LocalAccountAuthN')['bmc.kepler.AccountService.LocalAccountAuthN'].GenRmcp20Code = function(obj, ctx, ...)
        local req = local_account_auth_n_intf_types.GenRmcp20CodeReq.new(...):validate(nil, nil, true)
        local rsp = local_account_auth_n_intf_types.GenRmcp20CodeRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

-- The callback needs to be registered during app initialization
function M.ImplLocalAccountAuthNLocalAccountAuthNGenRmcp15Code(cb)
    class('LocalAccountAuthN')['bmc.kepler.AccountService.LocalAccountAuthN'].GenRmcp15Code = function(obj, ctx, ...)
        local req = local_account_auth_n_intf_types.GenRmcp15CodeReq.new(...):validate(nil, nil, true)
        local rsp = local_account_auth_n_intf_types.GenRmcp15CodeRsp.new(cb(obj, ctx, req:unpack())):validate()
        return rsp:unpack(true)
    end
end

return M
