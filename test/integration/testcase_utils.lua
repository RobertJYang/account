-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local mc_context = require 'mc.context'
local log = require 'mc.logging'
local ctx = require 'mc.context'
local m_mdb = require 'mc.mdb'
local bs = require 'mc.bitstring'
local enums = require 'mc.ipmi.enums'
local skynet = require 'skynet'
local json = require 'cjson'
local test_common = require 'test_common.utils'
local Ipmitool = test_common.Ipmitool
local ipmi_tool = Ipmitool.new('Administrator')

local INTERFACE_TASK_SERVICE<const> = 'bmc.kepler.TaskService.Task'

local PATH_ACCOUNT_SERVICE<const> = '/bmc/kepler/AccountService'
local INTERFACE_ACCOUNT_SERVICE<const> = 'bmc.kepler.AccountService'

local PATH_FMT_MANAGER_ACCOUNTS<const> = '/bmc/kepler/AccountService/Accounts'
local INTERFACE_MANAGER_ACCOUNTS<const> = 'bmc.kepler.AccountService.ManagerAccounts'

local PATH_FMT_MANAGER_ACCOUNT<const> = '/bmc/kepler/AccountService/Accounts/%s'
local INTERFACE_MANAGER_ACCOUNT<const> = 'bmc.kepler.AccountService.ManagerAccount'
local INTERFACE_SNMP_USER<const> = 'bmc.kepler.AccountService.ManagerAccount.SnmpUser'

local PATH_AUTHENTICATION<const> = '/bmc/kepler/AccountService/LocalAccountAuthN'
local INTERFACE_AUTHENTICATION<const> = 'bmc.kepler.AccountService.LocalAccountAuthN'

local PATH_PASSWORD_POLICY<const> = '/bmc/kepler/AccountService/PasswordPolicys/%s'
local INTERFACE_PASSWORD_POLICY<const> = 'bmc.kepler.AccountService.PasswordPolicy'

local PATH_ACCOUNT_POLICY<const> = '/bmc/kepler/AccountService/AccountPolicies/%s'
local INTERFACE_ACCOUNT_POLICY<const> = 'bmc.kepler.AccountService.AccountPolicy'

local ROLES_PATH<const> = '/bmc/kepler/AccountService/Roles'
local INTERFACE_ROLES<const> = 'bmc.kepler.AccountService.Roles'

local ROLE_PATH<const> = '/bmc/kepler/AccountService/Roles/%s'
local INTERFACE_ROLE<const> = 'bmc.kepler.AccountService.Role'

local TestCaseUtils = {}

local function get_initiator_info()
    local initiator_info = mc_context.new('IT', 'Administrator', '127.0.0.1')
    initiator_info.Privilege = '511'
    return initiator_info
end

TestCaseUtils.initiator = get_initiator_info()

-- 设置日志级别
function TestCaseUtils.set_log_level(bus, apps, level)
    for _, app in ipairs(apps) do
        local service = string.format('bmc.kepler.%s', app)
        local path = string.format('/bmc/kepler/%s/MicroComponent', app)
        local intf = 'bmc.kepler.MicroComponent.Debug'
        local ok, err = pcall(bus.call, bus, service, path, intf, 'SetDlogLevel', 'a{ss}sy', ctx.new(), level, 0)
        if not ok then
            log:error('Set app [%s] log level [%s] failed, error: %s', app, level, err)
        else
            log:notice('Set app [%s] log level [%s] successfully.', app, level)
        end
    end
end

-- Task
-- 检查远程传输任务是否成功
function TestCaseUtils.check_remote_task_completed(bus, rpc_path)
    local state = bus:call('bmc.kepler.account', rpc_path, 'org.freedesktop.DBus.Properties', 'Get',
        'ss', INTERFACE_TASK_SERVICE, 'State'):value()
    if state == 'Running' then
        log:notice('task is Running...')
    end
    assert(state ~= 'Exception')
    return state == 'Completed'
end

-- AccountService
-- 获取account service属性
function TestCaseUtils.get_account_service_property(bus, prop_name)
    local mobj = m_mdb.get_object(bus, PATH_ACCOUNT_SERVICE, INTERFACE_ACCOUNT_SERVICE)
    return mobj[prop_name]
end

-- 设置account service属性
function TestCaseUtils.set_account_service_property(bus, prop_name, value)
    local mobj = m_mdb.get_object(bus, PATH_ACCOUNT_SERVICE, INTERFACE_ACCOUNT_SERVICE)
    log:notice('TestCaseUtils: set account service property(%s) (%s) to (%s)',
        prop_name, tostring(mobj[prop_name]), value)
    mobj[prop_name] = value
end

-- 调用ImportWeakPasswordDictionary方法
function TestCaseUtils.call_account_service_import_weakpwd_dict(bus, path)
    local mobj = m_mdb.get_object(bus, PATH_ACCOUNT_SERVICE, INTERFACE_ACCOUNT_SERVICE)
    return mobj:ImportWeakPasswordDictionary_PACKED(TestCaseUtils.initiator, path):unpack()
end

-- ManagerAccounts
-- 调用New方法
function TestCaseUtils.call_account_new(bus, ...)
    local mobj = m_mdb.get_object(bus, PATH_FMT_MANAGER_ACCOUNTS, INTERFACE_MANAGER_ACCOUNTS)
    local ret =  mobj:New_PACKED(TestCaseUtils.initiator, ...):unpack()
    -- 资源树更新变慢。sleep一下，经验值，随便改
    skynet.sleep(10)
    return ret
end

-- ManagerAccount
-- 获取account属性
function TestCaseUtils.get_account_property(bus, account_id, prop_name)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_MANAGER_ACCOUNT)
    return mobj[prop_name]
end

-- 设置account属性
function TestCaseUtils.set_account_property(bus, account_id, prop_name, value)
    mc_context.set_context(TestCaseUtils.initiator)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_MANAGER_ACCOUNT)
    log:notice('TestCaseUtils: set account property(%s) (%s) to (%s)',
        prop_name, tostring(mobj[prop_name]), value)
    mobj[prop_name] = value
end

-- 调用GetUidGidByUserName方法
function TestCaseUtils.call_get_uid_gid_by_username(bus, ...)
    local mobj = m_mdb.get_object(bus, PATH_FMT_MANAGER_ACCOUNTS, INTERFACE_MANAGER_ACCOUNTS)
    return mobj:GetUidGidByUserName_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- 调用ChangePwd方法
function TestCaseUtils.call_account_change_pwd(bus, account_id, ...)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_MANAGER_ACCOUNT)
    return mobj:ChangePwd_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- 调用ChangeSnmpPwd方法
function TestCaseUtils.call_account_change_snmp_pwd(bus, account_id, ...)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_MANAGER_ACCOUNT)
    return mobj:ChangeSnmpPwd_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- 调用Delete方法
function TestCaseUtils.call_account_delete(bus, account_id, ...)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_MANAGER_ACCOUNT)
    return mobj:Delete_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- 调用ImportSSHPublickey方法
function TestCaseUtils.call_account_import_ssh_public_key(bus, account_id, ...)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_MANAGER_ACCOUNT)
    return mobj:ImportSSHPublicKey_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- ManagerAccount.SnmpUser
-- 获取account snmp属性
function TestCaseUtils.get_snmp_property(bus, account_id, prop_name)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_SNMP_USER)
    return mobj[prop_name]
end

-- 调用GetSnmpKeys方法
function TestCaseUtils.get_snmp_key(bus, account_id, prop_name)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_SNMP_USER)
    local auth_key, encry_key = mobj:GetSnmpKeys_PACKED(TestCaseUtils.initiator):unpack()
    return prop_name == 'AuthenticationKey' and auth_key or encry_key
end

-- 调用SetAuthenticationProtocol方法
function TestCaseUtils.call_account_set_authentication_protocol(bus, account_id, ...)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_SNMP_USER)
    return mobj:SetAuthenticationProtocol_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- 调用SetEncryptionProtocol方法
function TestCaseUtils.call_account_set_encryption_protocol(bus, account_id, ...)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT, account_id)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_SNMP_USER)
    return mobj:SetEncryptionProtocol_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- LocalAuthenticateN
-- 调用Authenticate方法
function TestCaseUtils.call_local_authenticate(bus,  ...)
    local mobj = m_mdb.get_object(bus, PATH_AUTHENTICATION, INTERFACE_AUTHENTICATION)
    return mobj:LocalAuthenticate_PACKED(...):unpack()
end

-- PasswordPolicy
-- 获取属性
function TestCaseUtils.get_password_policy_property(bus, account_type_name, prop_name)
    local rpc_path = string.format(PATH_PASSWORD_POLICY, account_type_name)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_PASSWORD_POLICY)
    return mobj[prop_name]
end

-- 设置属性
function TestCaseUtils.set_password_policy_property(bus, account_type_name, prop_name, value)
    local rpc_path = string.format(PATH_PASSWORD_POLICY, account_type_name)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_PASSWORD_POLICY)
    log:notice('TestCaseUtils: set %s password_policy property(%s) (%s) to (%s)',
        account_type_name, prop_name, tostring(mobj[prop_name]), value)
    mobj[prop_name] = value
end

-- AccountPolicy
-- 获取属性
function TestCaseUtils.get_account_policy_property(bus, account_type_name, prop_name)
    local rpc_path = string.format(PATH_ACCOUNT_POLICY, account_type_name)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_ACCOUNT_POLICY)
    return mobj[prop_name]
end

-- 设置属性
function TestCaseUtils.set_account_policy_property(bus, account_type_name, prop_name, value)
    local rpc_path = string.format(PATH_ACCOUNT_POLICY, account_type_name)
    local mobj = m_mdb.get_object(bus, rpc_path, INTERFACE_ACCOUNT_POLICY)
    log:notice('TestCaseUtils: set %s account_policy property(%s) (%s) to (%s)',
        account_type_name, prop_name, tostring(mobj[prop_name]), value)
    mobj[prop_name] = value
end

-- Role
-- 获取Roles属性
function TestCaseUtils.get_roles_property(bus, prop_name)
    local mobj = m_mdb.get_object(bus, ROLES_PATH, INTERFACE_ROLES)
    return mobj[prop_name]
end

-- 设置Roles属性
function TestCaseUtils.set_roles_property(bus, prop_name, value)
    local mobj = m_mdb.get_object(bus, ROLES_PATH, INTERFACE_ROLES)
    log:notice('TestCaseUtils: set roles property(%s) (%s) to (%s)',
        prop_name, tostring(mobj[prop_name]), value)
    mobj[prop_name] = value
end

-- 新增角色
function TestCaseUtils.call_new_role(bus, ...)
    local mobj = m_mdb.get_object(bus, ROLES_PATH, INTERFACE_ROLES)
    return mobj:New_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- 获取Role属性
function TestCaseUtils.get_role_property(bus, role_id, prop_name)
    local path = string.format(ROLE_PATH, role_id)
    local mobj = m_mdb.get_object(bus, path, INTERFACE_ROLE)
    return mobj[prop_name]
end

-- 删除角色
function TestCaseUtils.call_delete_role(bus, role_id, ...)
    local path = string.format(ROLE_PATH, role_id)
    local mobj = m_mdb.get_object(bus, path, INTERFACE_ROLE)
    return mobj:Delete_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- 设置权限
function TestCaseUtils.call_set_privilege(bus, role_id, ...)
    local path = string.format(ROLE_PATH, role_id)
    local mobj = m_mdb.get_object(bus, path, INTERFACE_ROLE)
    return mobj:SetRolePrivilege_PACKED(TestCaseUtils.initiator, ...):unpack()
end

-- ipmitool
-- 通过dbus发命令，需要自己填充上下文，没有鉴权
function TestCaseUtils.ipmi_test_tool_by_dbus(bus, ipmi_cmd, ipmi_req, ctx)
    local perfix = bs.new('<<_,_:2,DestNetFn:6,_:3/unit:8,Cmd>>')
    local req_perfix = perfix:pack({
        DestNetFn = ipmi_cmd.netfn, -- 填写网络字节码
        Cmd = ipmi_cmd.cmd -- 填写命令字
    })
    local req = bs.new(ipmi_cmd.decode):pack(ipmi_req)
    req = req_perfix .. req .. '\x00' -- 默认最后有一位校验位，必须添加
    log:notice('ipmi dbus payload: %s', req:gsub('.', function(m)
        return ('0x%02x '):format(m:byte())
    end))
    if not ctx then
        ctx = json.encode({ChanType = enums.ChannelType.CT_ME:value(),
            Instance = 0, session = {user = {name = 'Administrator', id = 2}}})
    end
    local rsp = bus:call('bmc.kepler.ipmi_core', '/bmc/kepler/IpmiCore', 'bmc.kepler.IpmiCore',
        'Route', 'a{ss}ayay', mc_context.new(), req, ctx)
    log:notice('ipmi dbus resp: %s', rsp:gsub('.', function(m)
        return ('0x%02x '):format(m:byte())
    end))
    local data = bs.new(ipmi_cmd.encode):unpack(rsp)
    return data
end

function TestCaseUtils.ipmi_test_tool_by_dbus_pcall(bus, ipmi_cmd, ipmi_req, ctx)
    local perfix = bs.new('<<_,_:2,DestNetFn:6,_:3/unit:8,Cmd>>')
    local req_perfix = perfix:pack({
        DestNetFn = ipmi_cmd.netfn, -- 填写网络字节码
        Cmd = ipmi_cmd.cmd -- 填写命令字
    })
    local req = bs.new(ipmi_cmd.decode):pack(ipmi_req)
    req = req_perfix .. req .. '\x00' -- 默认最后有一位校验位，必须添加
    log:notice('ipmi dbus payload: %s', req:gsub('.', function(m)
        return ('0x%02x '):format(m:byte())
    end))
    if not ctx then
        ctx = json.encode({ChanType = enums.ChannelType.CT_ME:value(),
            Instance = 0, session = {user = {name = 'Administrator', id = 2}}})
    end
    local ok, rsp = pcall(bus.call, bus, 'bmc.kepler.ipmi_core', '/bmc/kepler/IpmiCore',
        'bmc.kepler.IpmiCore', 'Route', 'a{ss}ayay', require 'mc.context'.new(), req, ctx)

    if ok then
        rsp = bs.new(ipmi_cmd.encode):unpack(rsp)
    end
    return ok, rsp
end

-- 通过ipmitool发命令，有完整的鉴权和上下文
function TestCaseUtils.ipmi_test_tool_by_ipmitool(ipmi_cmd, ipmi_req)
    local perfix = bs.new('<<DestNetFn:1/unit:8,Cmd:1/unit:8>>')
    local req_perfix = perfix:pack({
        DestNetFn = ipmi_cmd.netfn, -- 填写网络字节码
        Cmd = ipmi_cmd.cmd -- 填写命令字
    })
    local req = bs.new(ipmi_cmd.decode):pack(ipmi_req)
    req = req_perfix .. req
    local raw_buf = req:gsub('.', function(m)
        return ('0x%02x '):format(m:byte())
    end)
    log:notice('ipmi payload: %s', raw_buf)
    local rsp = ipmi_tool:raw(raw_buf)
    log:notice('ipmi resp: %s', rsp:gsub('.', function(m)
        return ('0x%02x '):format(m:byte())
    end))
    local data = bs.new(ipmi_cmd.encode):unpack('\x00' .. rsp)
    return data
end

return TestCaseUtils
