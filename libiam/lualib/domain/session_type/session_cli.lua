-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local session_type = require 'domain.session_type.session_type'
local session = require 'domain.session'
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local initiator = require 'mc.initiator'
local iam_enum = require 'class.types.types'
local iam_core = require 'iam_core'
local base_msg = require 'messages.base'
local user_config = require 'user_config'
local vos = require 'utils.vos'

-- kill函数信号，非root用户需要发送SIGTERM信号
local SIGTERM<const> = 15
local SIGKILL<const> = 9

local CLISession = class(session_type)

function CLISession:ctor()
    self.timeout_min = 0 -- cli会话超时时间0，代表永不超时
    self.timeout_max = 28800 -- cli会话超时时间最长480分钟
    self.m_ldap_authed_accounts = {}
end

function CLISession:create(account, online_session)
    local auth_type
    if account.AccountType == iam_enum.AccountType.Local 
        or account.AccountType == iam_enum.AccountType.InterChassis then
        auth_type = iam_enum.AuthType.Local
    else
        auth_type = iam_enum.AuthType.ldap_auto_match
    end

    local new_session = session.new(
        account, self:get_session_type(), auth_type, online_session.m_ip)
    new_session.m_session_id = online_session.m_session_id
    new_session.m_created_time = online_session.m_created_time
    new_session.system_id = 0 --目前默认0
    table.insert(self.m_session_collection, new_session)
    self.m_create_session:emit(new_session)
    if account.AccountType == iam_enum.AccountType.InterChassis then
        return new_session
    end
    local initiator_info = initiator.new(new_session.m_session_type_name, new_session.m_username, new_session.m_ip)
    log:operation(initiator_info, 'iam', 'User %s(%s) login successfully', new_session.m_username, new_session.m_ip)
    return new_session
end

function CLISession:delete(session_id)
    local session, index = self:get_session_by_session_id(session_id)
    if not session then
        error(base_msg.NoValidSession())
    end

    local pid = tonumber(string.sub(session_id, 4))
    if session.m_ip == "COM" then
        -- 适配 kill -15 无法正确清除串口会话
        iam_core.kill(pid, SIGKILL)
    else
        iam_core.kill(pid, SIGTERM)
    end

    table.remove(self.m_session_collection, index)
    self.m_delete_session:emit(session_id)
end

function CLISession:delete_by_username(username, logout_type)
    local deleted_session_list = {}
    local cli_session_list = iam_core.get_cli_online_users()
    for _, cli_session in pairs(cli_session_list) do
        -- linux内置有root用户，当前版本客户需要创建名为root的用户，系统内该用户名会被包装为<root>，此处恢复用户名
        if cli_session.username == user_config.RESERVED_ROOT_USER_NAME then
            cli_session.username = user_config.ACTUAL_ROOT_USER_NAME
        end
        if cli_session.username == username then
            if #cli_session.host == 0 then
                -- 适配 kill -15 无法正确清除串口会话
                iam_core.kill(cli_session.pid, SIGKILL)
            else
                iam_core.kill(cli_session.pid, SIGTERM)
            end
        end
    end

    for index = #self.m_session_collection, 1, -1 do
        local session = self.m_session_collection[index]
        if username == session.m_username then
            table.remove(self.m_session_collection, index)
            self.m_delete_session:emit(session.m_session_id)
            local initiator_info = initiator.new(session.m_session_type_name, session.m_username, session.m_ip)
            if tostring(logout_type) == 'SessionKickout' then
                log:operation(initiator_info, 'iam', self.logout_type_map_log[tostring(logout_type)],
                    session.m_username, tostring(session.m_session_type), session.m_ip)
            else
                log:operation(initiator_info, 'iam', 
                    self.logout_type_map_log[tostring(logout_type)], session.m_username, session.m_ip)
            end
            table.insert(deleted_session_list, session.m_session_id)
        end
    end
    return deleted_session_list
end

function CLISession:delete_by_ip(ip, logout_type)
    local deleted_session_list = {}
    local cli_session_list = iam_core.get_cli_online_users()
    for _, cli_session in pairs(cli_session_list) do
        if cli_session.host == ip then
            if #cli_session.host == 0 then
                -- 适配 kill -15 无法正确清除串口会话
                iam_core.kill(cli_session.pid, SIGKILL)
            else
                iam_core.kill(cli_session.pid, SIGTERM)
            end
        end
    end

    for index = #self.m_session_collection, 1, -1 do
        local session = self.m_session_collection[index]
        if ip == session.m_ip then
            table.remove(self.m_session_collection, index)
            self.m_delete_session:emit(session.m_session_id)
            local initiator_info = initiator.new(session.m_session_type_name, session.m_username, session.m_ip)
            if tostring(logout_type) == 'SessionKickout' then
                log:operation(initiator_info, 'iam', self.logout_type_map_log[tostring(logout_type)],
                    session.m_username, tostring(session.m_session_type), session.m_ip)
            else
                log:operation(initiator_info, 'iam', 
                    self.logout_type_map_log[tostring(logout_type)], session.m_username, session.m_ip)
            end
            table.insert(deleted_session_list, session.m_session_id)
        end
    end
    return deleted_session_list
end

function CLISession:get_timeout_session_list(absolute_timeout)
    local timeout_session_list = {}

    local now = vos.vos_get_cur_time_stamp()
    local cur_session
    for index = #self.m_session_collection, 1, -1 do
         cur_session = self.m_session_collection[index]
        if absolute_timeout ~= 0 and cur_session.m_created_time < now - absolute_timeout then
            table.insert(timeout_session_list, cur_session)
        end
    end
    return timeout_session_list
end

function CLISession.get_cli_online_session(stub_cli_online_list)
    local cli_online_sessions = {}
    local cli_session_list = stub_cli_online_list or iam_core.get_cli_online_users()
    for i, cli_session in pairs(cli_session_list) do
        -- linux内置有root用户，当前版本客户需要创建名为root的用户，系统内该用户名会被包装为<root>，此处恢复用户名
        if cli_session.username == user_config.RESERVED_ROOT_USER_NAME then
            cli_session.username = user_config.ACTUAL_ROOT_USER_NAME
        end
        cli_online_sessions[i] = {
            m_session_id = string.format('cli%u', cli_session.pid),
            m_username = cli_session.username,
            m_ip = #cli_session.host == 0 and 'COM' or cli_session.host,
            m_created_time = cli_session.login_time
        }
    end
    return cli_online_sessions
end

function CLISession:escape_username(username)
    local to_be_replaced = {'`', '$', '!', '|', ';', '*'}
    for _, value in pairs(to_be_replaced) do
        local escape = '%' .. value
        local replace = '\\' .. value
        username, _ = string.gsub(username, escape, replace)
    end
    return username
end

--- 更新已认证Ldap域用户信息,写入m_ldap_authed_accounts中
function CLISession:update_ldap_authed_accounts()
    for k, _ in pairs(self.m_ldap_authed_accounts) do
        self.m_ldap_authed_accounts[k] = nil
    end
    local accounts = iam_core.get_authed_ldap_user()
    if type(accounts) ~= 'table' then
        log:info('no authed ldap accounts')
        return
    end
    for _, ldap_account in pairs(accounts) do
        self.m_ldap_authed_accounts[ldap_account.uid] = ldap_account
    end
end

--- 根据域控制器和组信息删除对应远程会话
--- 需覆盖三种场景:
--- 1、LDAP使能关闭(不带controller_id和inner_id),都不匹配，踢出所有
--- 2、域控制器变更(仅有controller_id),只匹配controllerid
--- 3、组信息变更(controller_id和inner_id都有),都进行匹配
function CLISession:delete_remote_session(controller_id, inner_id)
    local deleted_session_list = {}
    for uid, account in pairs(self.m_ldap_authed_accounts) do
        if controller_id and account.serverid ~= controller_id then
            goto continue
        end

        if inner_id and (account.groupid & (0x1 << inner_id) == 0) then
            goto continue
        end
        local pid = vos.popen_s(string.format('ps -u %d -o pid | sed -n \'2p\'', uid))
        -- 去除pid结果中的多余空格
        pid = pid:gsub("%s+", "")
        if not pid or pid == '' then
            log:error('delete ldap(%s) cli session failed, process not found', uid)
            iam_core.uip_renew_ldap_user(uid)
            goto continue
        end
        local ppid = string.match(vos.popen_s(string.format('ps -o ppid %s', pid)), '(%d+)')
        local session_id = string.format('cli%s', ppid)
        self:delete(session_id)
        iam_core.uip_renew_ldap_user(uid)
        table.insert(deleted_session_list, session_id)
        ::continue::
    end
    return deleted_session_list
end

return singleton(CLISession)
