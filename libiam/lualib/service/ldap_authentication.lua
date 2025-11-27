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
local singleton = require 'mc.singleton'
local iam_enum = require 'class.types.types'
local user_config = require 'user_config'
local err_config = require 'error_config'
local log = require 'mc.logging'
local iam_core = require 'iam_core'
local custom_msg = require 'messages.custom'
local class = require 'mc.class'
local ldap_config = require 'domain.ldap_config'
local ldap_controller_collection = require 'domain.ldap.ldap_controller_collection'
local remote_group_collection = require 'domain.remote_group.remote_group_collection'
local remote_group_config = require 'domain.remote_group.remote_group_config'
local kmc_client = require 'infrastructure.kmc_client'
local client = require 'iam.client'
local iam_utils = require 'infrastructure.iam_utils'

require 'iam.json_types.CipherSuit'

local GROUP_VALID_DEFAULT<const> = 255 -- 255是默认值，若group[i]=255则代表该用户组未匹配
local CIPHER_PATH<const> = "/bmc/kepler/Managers/1/Security/TlsConfig/CipherSuits"

local error_map = {
    [err_config.USER_LDAP_LOGIN_FAIL] = custom_msg.AuthorizationFailed,
    [err_config.USER_LOGIN_LIMITED] = custom_msg.UserLoginRestricted,
    [err_config.USER_NO_ACCESS] = custom_msg.NoAccess
}

local ldap_authentication = class()
function ldap_authentication:ctor(bus, db)
    self.m_ldap_config = ldap_config.get_instance()
    self.m_ldap_controller_collection = ldap_controller_collection.get_instance()
    self.m_remote_group_collection = remote_group_collection.get_instance()
    self.kmc_client = kmc_client.get_instance()
    self.m_bus = bus
    self.db = db
end

local function gen_auth_account_info()
    return {
        UserName       = "",
        Id             = "",
        LastLoginIP    = "",
        LastLoginTime  = 0,
        RoleId         = {},
        AccountType    = iam_enum.AccountType.LDAP,
        LoginInterface = "",
        ControllerId = "",
        ControllerInnerId = ""
    }
end

-- 获取tls加密套件
function ldap_authentication:get_tls_cipher()
    local objs = client:GetCipherSuitObjects()
    if not objs then
        log:error("[IAM] get cipher suits obj failed")
        return
    end

    local ciphers = {}
    -- 生成的代码中foreach下包含资源树上含TlsConfig.CipherSuit接口的所有对象
    client:ForeachCipherSuitObjects(function (obj)
        if obj.Enabled and obj.SuitName then
            table.insert(ciphers, obj.SuitName)
        end
    end)

    return table.concat(ciphers, ",")
end

function ldap_authentication:get_valid_group(server_id, group, groups)
    local valid_groups = {}
    for i = 1, remote_group_config.MAX_GROUP_CNT_IN_CONTROLLER do
        if group[i] ~= GROUP_VALID_DEFAULT then
            valid_groups[#valid_groups + 1] =
                self.m_remote_group_collection:get_remote_group_by_id('LDAP', server_id, i)
        end
    end

    return valid_groups
end

function ldap_authentication:get_groups_in_cur_controller(server_id)
    local groups, len = self.m_remote_group_collection:get_remote_groups_in_controller(
        iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value(), server_id)

    local t_group = {}
    local idx = 1
    for i = 1, remote_group_config.MAX_GROUP_CNT_IN_CONTROLLER do
        if groups[i] ~= nil then
            local group = groups[i]:get_group()
            local tmp_group = {group.ControllerInnerId, group.Name, group.Folder, group.Privilege}
            t_group[idx] = tmp_group
            idx = idx + 1
        end
    end

    return t_group, groups, len
end

function ldap_authentication:valid_group_authenticate(valid_groups, ip, interface, id)
    local group
    for i = 1, remote_group_config.MAX_GROUP_CNT_IN_CONTROLLER do
        group = valid_groups[i]
        if group ~= nil and ip and not group:check_login_rule(ip) then
            valid_groups[i] = nil
        end
    end

    if next(valid_groups) == nil then
        log:error("LDAP%d check login rule failed!", id)
        return err_config.USER_LOGIN_LIMITED
    end

    for i = 1, remote_group_config.MAX_GROUP_CNT_IN_CONTROLLER do
        group = valid_groups[i]
        if group ~= nil and interface and interface & group:get_remote_group_login_interface() == 0 then
            valid_groups[i] = nil
        end
    end
    if next(valid_groups) == nil then
        log:error("LDAP%d check login interface failed!", id)
        return err_config.USER_NO_ACCESS
    end
    return valid_groups
end

-- LDAP认证动作
function ldap_authentication:authenticate(user_name, password, controller, ip, interface)
    local t_group, groups, len = self:get_groups_in_cur_controller(controller.Id)

    local tls_ciphers = self:get_tls_cipher()
    local ldap_auth_info = {
        serverid            = controller.Id,
        hostaddr            = controller.HostAddr,
        port                = controller.Port,
        folder              = controller.Folder,
        user_domain         = controller.UserDomain,
        bind_dn             = controller.BindDN,
        bind_dn_pwd         = controller.BindDNPsw ~= "" and 
            self.kmc_client:decrypt_password(controller.BindDNPsw) or "",
        cert_verify_enabled = controller.CertVerifyEnabled and 1 or 0,
        cert_verify_level   = controller.CertVerifyLevel,
        cert_inner_dir      = user_config.CERT_INTER_DIR,
        scope               = controller.Scope,
        time_limit          = controller.TimeLimit,
        bind_time_limit     = controller.BindTimeLimit,
        version             = controller.LdapVer,
        group_cnt           = len,
        group               = t_group,
        tls_cipher          = tls_ciphers,
        username            = user_name,
        password            = password
    }

    local ret, pri, group = iam_core.mscm_ldap_authenticate(ldap_auth_info)
    log:info("after LDAP%d mscm_ldap_authenticate, ret = %d, pri = %d", controller.Id, ret, pri)
    if ret ~= 0 then
        log:error("%s ldap authenticate failed!", user_name)
        return err_config.USER_LDAP_LOGIN_FAIL
    end

    local valid_groups = self:get_valid_group(controller.Id, group, groups)
    if next(valid_groups) == nil then
        return err_config.USER_LDAP_LOGIN_FAIL
    end
    local final_groups = self:valid_group_authenticate(valid_groups, ip, interface, controller.Id)
    if type(final_groups) ~= "table" then
        return final_groups
    end
    local roles_table = {}
    -- 获取所属用户组Id
    local inner_ids = 0x0
    for _, final_group in pairs(final_groups) do
        table.insert(roles_table, final_group:get_role_id())
        inner_ids = inner_ids | (0x1 << final_group:get_remote_group_controller_inner_id())
    end
    return ret, pri, iam_utils:remove_duplicates(roles_table), inner_ids
end

-- LDAP指定域认证
function ldap_authentication:ldap_authenticate(user_name, password, ip, interface, server_id)

    if not self.m_ldap_config:get_ldap_enabled() then
        log:error("%s ldap authenticate failed!", user_name)
        error(custom_msg.AuthorizationFailed())
    end

    local auth_account_info = gen_auth_account_info()
    auth_account_info.Id = interface == iam_enum.LoginInterface.SSH:value() and
        iam_core.uip_alloc_ldap_uid() or user_config.LDAP_USER_GID
    auth_account_info.LoginInterface = interface
    auth_account_info.ControllerId = server_id
    local ret, role_table, inner_id
    local controller = self.m_ldap_controller_collection.m_controller_collection[server_id]:get_controller()
    
    -- 先尝试是否存在 username@domain 格式
    local has_domain, auth_user_name, auth_domain = iam_core.check_username_divide_by_domain(user_name)
    if has_domain == 0 and auth_domain == controller.UserDomain then -- 若存在，判断指定域名是否匹配
        ret, _, role_table, inner_id = self:authenticate(auth_user_name, password, controller, ip, interface)
        if ret == 0 then
            auth_account_info.UserName = user_name
            auth_account_info.RoleId = role_table
            auth_account_info.ControllerInnerId = inner_id
            return auth_account_info
        end
    end

    -- 拆分结果认证失败，使用全名进行认证
    ret, _, role_table, inner_id = self:authenticate(user_name, password, controller, ip, interface)
    if ret ~= 0 then
        self:check_ldap_ret_error(ret)
    end
    auth_account_info.UserName = string.format('%s@%s', user_name, controller.UserDomain)
    auth_account_info.RoleId = role_table
    auth_account_info.ControllerInnerId = inner_id

    return auth_account_info
end

-- 校验域控制器是否可用（最低保证HostAddr和UserDomain是有内容的）
local function check_ldap_controller_valid(controller)
    if not controller.HostAddr or controller.HostAddr == '' then
        return false
    end

    if not controller.UserDomain or controller.UserDomain == '' then
        return false
    end

    return true
end

-- LDAP认证自动匹配
function ldap_authentication:ldap_authenticate_auto_match(username, password, ip, interface, server_id)

    if not self.m_ldap_config:get_ldap_enabled() then
        log:error("%s ldap authenticate failed!", username)
        error(custom_msg.AuthorizationFailed())
    end

    local auth_account_info = gen_auth_account_info()
    auth_account_info.Id = interface == iam_enum.LoginInterface.SSH:value() and
        iam_core.uip_alloc_ldap_uid() or user_config.LDAP_USER_GID
    auth_account_info.LoginInterface = interface

    local ret, role_table, inner_id
    -- 先尝试是否存在 username@domain 格式
    local has_domain, auth_user_name, auth_domain = iam_core.check_username_divide_by_domain(username)
    if has_domain == 0 then -- 若存在，先以拆分结果尝试进行认证
        local controllers = self.m_ldap_controller_collection:get_controllers_by_domain(auth_domain)
        for j = 1, remote_group_config.MAX_LDAP_COUNT do
            if controllers[j] == nil then
                goto continue
            end
            local controller = controllers[j]:get_controller()
            ret, _, role_table, inner_id = self:authenticate(auth_user_name, password, controller, ip, interface)
            if ret == 0 then
                auth_account_info.UserName = username
                auth_account_info.RoleId = role_table
                auth_account_info.ControllerId = controller.Id
                auth_account_info.ControllerInnerId = inner_id
                return auth_account_info
            end

            ::continue::
        end
    end

    -- 若不存在 username@domain 格式，使用全名进行尝试认证
    for i = 1, remote_group_config.MAX_LDAP_COUNT do
        local controller = self.m_ldap_controller_collection.m_controller_collection[i]:get_controller()
        -- automatch全域匹配需要校验该域是否有内容，避免无用耗时
        if not check_ldap_controller_valid(controller) then
            log:info("LDAP Controller %d has no config, pass", i)
            goto next
        end
        ret, _, role_table, inner_id = self:authenticate(username, password, controller, ip, interface)
        if ret == 0 then
            auth_account_info.UserName = string.format('%s@%s', username, controller.UserDomain)
            auth_account_info.RoleId = role_table
            auth_account_info.ControllerId = controller.Id
            auth_account_info.ControllerInnerId = inner_id
            return auth_account_info
        end
        ::next::
    end

    -- 自动匹配失败，返回最后一条报错信息
    self:check_ldap_ret_error(ret)
end


-- 获取Ldap指定域认证错误类型
function ldap_authentication:check_ldap_ret_error(ret)
    if error_map[ret] ~= nil then
        error(error_map[ret]())
    else
        error(custom_msg.AuthorizationFailed())
    end
end

return singleton(ldap_authentication)