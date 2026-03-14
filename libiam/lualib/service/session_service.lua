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
local class = require 'mc.class'
local cjson = require 'cjson'
local singleton = require 'mc.singleton'
local utils = require 'utils'
local mc_utils = require 'mc.utils'
local session_utils = require 'infrastructure.session_utils'
local gui_session = require 'domain.session_type.session_gui'
local redfish_session = require 'domain.session_type.session_redfish'
local cli_session = require 'domain.session_type.session_cli'
local sso_session = require 'domain.session_type.session_sso'
local kvm_session = require 'domain.session_type.session_kvm'
local vnc_session = require 'domain.session_type.session_vnc'
local video_session = require 'domain.session_type.session_video'
local inter_chassis_session = require 'domain.session_type.session_inter_chassis'
local authentication_service = require 'service.authentication'
local ldap_authentication_service = require 'service.ldap_authentication'
local access_service = require 'service.access_service'
local ldap_config = require 'domain.ldap_config'
local ldap_controller_collection = require 'domain.ldap.ldap_controller_collection'
local remote_group_collection = require 'domain.remote_group.remote_group_collection'
local certificate_authentication = require 'domain.certificate_authentication'
local authentication_config = require 'domain.authentication_config'
local iam_err = require 'iam.errors'
local iam_enum = require 'class.types.types'
local log = require 'mc.logging'
local config = require 'user_config'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local context = require 'mc.context'
local operation_logger = require 'interface.operation_logger'
local iam_client = require 'iam.client'
local cert_service_enum = require 'iam.json_types.CertificateService'
local privilege = require 'domain.privilege'
local account_utils = require 'infrastructure.account_utils'
local skynet_ready, skynet = pcall(require, 'skynet')
local account_cache = require 'domain.cache.account_cache'
local account_service_cache = require 'domain.cache.account_service_cache'
local trace = require 'telemetry.trace'
local session = require 'domain.session'
local ip_lock = require 'ip_lock'

-- 历史登出会话记录最大数
local MAX_LOGOUT_SESSION<const> = 32
local PATH_CERTIFICATE_SERVICE<const> = '/bmc/kepler/CertificateService'
local REGEX_PATH_CERTIFICATE_ACCOUNT<const> =
    '/bmc/kepler/AccountService/MultiFactorAuth/ClientCertificate/Certificates/(%d+)'

local ERR_MAP = {
    [iam_enum.SessionLogoutType.AccountConfigChange:value()] = custom_msg.SessionChanged,
    [iam_enum.SessionLogoutType.SessionLogout:value()] = custom_msg.SessionTimeout,
    [iam_enum.SessionLogoutType.SessionKickout:value()] = custom_msg.SessionKickout,
    [iam_enum.SessionLogoutType.SessionRelogin:value()] = custom_msg.SessionRelogin,
    [iam_enum.SessionLogoutType.SessionTimeout:value()] = custom_msg.SessionTimeout,
    [iam_enum.SessionLogoutType.BMCConfigChange:value()] = custom_msg.SessionChanged
}

local session_type_map = {
    [iam_enum.SessionType.GUI:value()] = gui_session,
    [iam_enum.SessionType.Redfish:value()] = redfish_session,
    [iam_enum.SessionType.CLI:value()] = cli_session,
    [iam_enum.SessionType.SSO:value()] = sso_session,
    [iam_enum.SessionType.KVM:value()] = kvm_session,
    [iam_enum.SessionType.VNC:value()] = vnc_session,
    [iam_enum.SessionType.VIDEO:value()] = video_session,
    [iam_enum.SessionType.INTER_CHASSIS:value()] = inter_chassis_session
}

local SessionService = class()

-- 获取区分多系统主机的对象
local function get_chip_env_obj(manager_id)
    local path_params = {}
    path_params.ManagerId = manager_id
    local ok, obj = pcall(function()
        return iam_client:GetChipEnvEnvObject(path_params)
    end)
    if not ok then
        log:error("get multi host manager_id(%d) object failed", manager_id)
        return nil
    end
   return obj
end

function SessionService:get_host_number()
    local obj = get_chip_env_obj(1) -- ManagerId默认为1
    if obj == nil then
        log:error("The retrieved object is null")
        error(base_msg.InternalError())
    end
    local systemids = obj.SystemIds
    return #systemids
end

local function set_host_operation_log(ctx)
    if SessionService:get_host_number() == 1 then -- 表示单系统
        ctx.operation_log.result = "fail"
        ctx.operation_log.params = { username = ctx.UserName, ip = ctx.ClientAddr }
    else
        ctx.operation_log.result = "fail_multihost"
        ctx.operation_log.params = { username = ctx.UserName, ip = ctx.ClientAddr, systemid = ctx.SystemId }
    end
end

-- 对传入的SystemId做效验
function SessionService:check_system_id(ctx)
    local obj = get_chip_env_obj(1) -- ManagerId默认为1
    if obj == nil then
        log:error("The retrieved object is null")
        set_host_operation_log(ctx)
        error(base_msg.InternalError())
    end
    local systemids = obj.SystemIds
    if ctx.SystemId == nil then
        ctx.SystemId = 1
    end
    local flag = false
    for i = 1, #systemids do
        if systemids[i] == tonumber(ctx.SystemId) then
            flag = true
            break
        end
    end
    if not flag then
        log:error("The system id(%s) does not exist", tonumber(ctx.SystemId))
        set_host_operation_log(ctx)
        error(base_msg.PropertyValueNotInList(ctx.SystemId, 'systemids'))
    end
end

local function get_account_obj(account_id)
    local path_params = {}
    path_params.ManagerAccountId = account_id

    local ok, obj = pcall(function()
        return iam_client:GetManagerAccountManagerAccountObject(path_params)
    end)

    if not ok then
        log:error("get account(%d) object failed", account_id)
        return nil
    end

   return obj
end

local function set_account_last_login(ctx, account_id, ip, interface)
    local obj = get_account_obj(account_id)
    if not obj then
        return false
    end
    local call_ctx = context.new(ctx.Interface, ctx.UserName, ctx.ClientAddr)
    local ok = pcall(obj.SetLastLogin, obj, call_ctx, ip, interface)
    return ok
end

local function record_login_info(user_name, ip, interface, is_record_login_info, is_update_active_time)
    local obj = iam_client:GetLocalAccountAuthNLocalAccountAuthNObject()
    if not obj then
        return false
    end

    local ctx = context.new(interface, user_name, ip)
    local ext_config = {
        ['RecordOnly'] = true,
        ['RecordLoginInfo'] = is_record_login_info,
        ['UpdateActiveTime'] = is_update_active_time
    }
    local ok = pcall(obj.LocalAuthenticate, obj, ctx, user_name, "", ext_config)
    return ok
end

function SessionService:ctor(db, inter_chassis_validator)
    local session_service_db = db:select(db.SessionService)
    local session_service_collection = session_service_db:fold(function(session_service_type_db, acc)
        local session_type = session_service_type_db.SessionType:value()
        if session_type_map[session_type] then
            acc[session_type] = session_type_map[session_type].new(session_service_type_db)
        end
        return acc
    end, {})

    self.m_session_service_collection = session_service_collection
    self.m_session_logout_collection = {}
    self.m_authentication_config = authentication_config.get_instance()
    self.m_authentication_service = authentication_service.get_instance()
    self.m_ldap_authentication_service = ldap_authentication_service.get_instance()
    self.m_ldap_config = ldap_config.get_instance()
    self.m_ldap_controller_collection = ldap_controller_collection.get_instance()
    self.m_remote_group_collection = remote_group_collection.get_instance()
    self.m_account_cache = account_cache.get_instance()
    self.m_account_service_cache = account_service_cache.get_instance()
    self.m_certificate_authtication = certificate_authentication.get_instance()
    self.m_access_service = access_service.get_instance()
    self.m_inter_chassis_validator = inter_chassis_validator

    self.m_sessions_db = db:select(db.Sessions):first()
end

local function init_auth_table(self)
    self.auth_table = {
        [iam_enum.AuthType.Local:value()] = function(...)
            return self.m_authentication_service:local_authenticate(...)
        end,
        [iam_enum.AuthType.ldap_auto_match:value()] = function(...)
            return self.m_ldap_authentication_service:ldap_authenticate_auto_match(...)
        end,
        [iam_enum.AuthType.ldap_server1:value()] = function(...)
            return self.m_ldap_authentication_service:ldap_authenticate(...)
        end,
        [iam_enum.AuthType.ldap_server2:value()] = function(...)
            return self.m_ldap_authentication_service:ldap_authenticate(...)
        end,
        [iam_enum.AuthType.ldap_server3:value()] = function(...)
            return self.m_ldap_authentication_service:ldap_authenticate(...)
        end,
        [iam_enum.AuthType.ldap_server4:value()] = function(...)
            return self.m_ldap_authentication_service:ldap_authenticate(...)
        end,
        [iam_enum.AuthType.ldap_server5:value()] = function(...)
            return self.m_ldap_authentication_service:ldap_authenticate(...)
        end,
        [iam_enum.AuthType.ldap_server6:value()] = function(...)
            return self.m_ldap_authentication_service:ldap_authenticate(...)
        end
    }
end

local function init_cert_auth_session(self)
    self.browser_type_session = {
        [iam_enum.NewSessionBrowserType.MutualAuth:value()] = function(...)
            return self:new_mutual_auth_session(...)
        end,
        [iam_enum.NewSessionBrowserType.InterChassis:value()] = function(...)
            return self:new_inter_chassis_session(iam_enum.NewSessionBrowserType.InterChassis, ...)
        end,
        [iam_enum.NewSessionBrowserType.InterChassisRest:value()] = function(...)
            return self:new_inter_chassis_session(iam_enum.NewSessionBrowserType.InterChassisRest, ...)
        end,
        [iam_enum.NewSessionBrowserType.InterChassisSsh:value()] = function(...)
            return self:new_inter_chassis_ssh_session(...)
        end
    }
end

function SessionService:init()
    init_auth_table(self)
    init_cert_auth_session(self)
    self:register_account_signals()
    self:register_mutual_auth_signals()
    self:delete_username_session_signals()
    self:register_access_signals()
end

-- 新增的独立方法：处理超时会话
function SessionService:process_timeout_sessions()
    for _, session_service in pairs(self.m_session_service_collection) do
        local ok, err = pcall(function()
            local timeout_session_list = session_service:get_timeout_session_list()
            self:delete_timeout_session_list(timeout_session_list)
        end)
        if not ok then
            log:error('delete timeout session error %s', err.name)
        end
    end
end

-- 会话监控，保证会话超时、属性变更后被重置
function SessionService:session_monitor()
    local loop_count = 0 -- 从0开始循环计数
    local CLI_COUNT = 2 -- 2:每10秒将CLI会话上树一次
    skynet.fork_loop({ count = 0 }, function()
        log:info('Start session monitor.')
        local ok, err
        local start_time, end_time, sleep_time
        while true do
            start_time = skynet.now()
            ok, err = pcall(function()
                self:process_timeout_sessions()
            end)
            if not ok then
                log:error('process timeout sessions error %s', err.name)
            end
            -- 集成测试期间禁用cli会话扫描，通过配置ENABLE_CLI_SSHD_SCAN为false跳过该检测
            if loop_count == CLI_COUNT and config.ENABLE_CLI_SSHD_SCAN == true then
                ok, err = pcall(self.update_cli_online_session, self)
                if not ok then
                    log:error('update cli online session error %s', err.name)
                end
                loop_count = 0
            end
            loop_count = loop_count + 1
            end_time = skynet.now()
            end_time = end_time > start_time and end_time or start_time
            sleep_time = math.max(500 - (end_time - start_time), 0) -- 范围 0-5秒
            skynet.sleep(sleep_time)
        end
    end)
end

local DOMAIN_AUTH_MODE_MAP = {
    ['LocaliBMC'] = {
        ['Disabled'] = {},
        ['Enabled'] = {iam_enum.AuthType.Local},
        ['Fallback'] = {iam_enum.AuthType.Local},
        ['LocalFirst'] = {iam_enum.AuthType.Local}
    },
    ['AutomaticMatching'] = {
        ['Disabled'] = {iam_enum.AuthType.ldap_auto_match},
        ['Enabled'] = {iam_enum.AuthType.Local},
        ['Fallback'] = {iam_enum.AuthType.ldap_auto_match, iam_enum.AuthType.Local},
        ['LocalFirst'] = {iam_enum.AuthType.Local, iam_enum.AuthType.ldap_auto_match}
    },
    ['RemoteAutoMatching'] = {
        ['Disabled'] = {iam_enum.AuthType.ldap_auto_match},
        ['Enabled'] = {},
        ['Fallback'] = {iam_enum.AuthType.ldap_auto_match},
        ['LocalFirst'] = {iam_enum.AuthType.ldap_auto_match}
    }
}

--- 根据domain找到可用的auth_type列表
--- @param domain string
--- @param auth_mode string
--- @return auth_type auth_type列表
function SessionService:get_auth_type_by_domain(domain, auth_mode)

    -- domain为空时走自动匹配
    if domain == '' then
        domain = 'AutomaticMatching'
    end

    if DOMAIN_AUTH_MODE_MAP[domain] then
        return DOMAIN_AUTH_MODE_MAP[domain][auth_mode]
    end

    -- 上述domain校验完成无匹配后，尝试根据域名去寻找指定LDAP域

    if auth_mode == 'Enabled' then
        -- 远程认证仅在非 Enabled 时可用
        return {}
    end
    local auth_type = {}
    local controllers = self.m_ldap_controller_collection:get_controllers_by_domain(domain)
    for i = 1, 6 do
        if controllers[i] ~= nil then
            local controller = controllers[i]:get_controller()
            auth_type[#auth_type+1] = iam_enum.AuthType.new(1+controller.Id)
        end       
    end

    return auth_type
end

--- 统一认证接口
---@param username string
---@param password string
---@param domain string
function SessionService:authenticate(ctx, username, password, session_type, ip, domain, ext_config)
    local span = trace.start_span('libiam.SessionService.authenticate', {username = username, domain = domain})
    -- 根据domain找到可用的auth_type列表
    local auth_mode = self.m_authentication_config:get_auth_mode()
    local auth_types = self:get_auth_type_by_domain(domain, auth_mode)
    if #auth_types == 0 then
        log:error("get auth_type failed, input domain is %s, cur auth mode is %s", domain, auth_mode)
        span:finish()
        error(base_msg.PropertyValueNotInList(domain, 'Domain'))
    end
    local interface = session_utils.parse_login_interface(session_type, ctx.Interface)
    local server_id, func, ok, auth_account_info
    local err_info = {}

    -- 在认证之前判断本ip是否锁定
    if self.m_access_service:check_ip_locked(ctx.ClientAddr) then
        log:error("ip %s is locked by auth failed", ctx.ClientAddr)
        error(custom_msg.AuthorizationFailed())
    end

    -- 遍历可用的auth_type
    for _, auth_type in pairs(auth_types) do
        -- 首先认证，以保证不暴露内部其他实现，暂不支持本地认证/LDAP外的其他认证
        if auth_type:value() < iam_enum.AuthType.Local:value() or
            auth_type:value() > iam_enum.AuthType.ldap_server6:value() then
            span:finish()
            error(base_msg.PropertyValueNotInList(domain, 'Domain'))
        end

        server_id = auth_type:value() >= iam_enum.AuthType.ldap_server1:value() and auth_type:value() - 1 or 0
        func = self.auth_table[auth_type:value()]

        ok, auth_account_info = pcall(func, username, password, ip, interface, server_id, ext_config)

        if ok then
            -- 若有成功，无论何种形式，解锁ip
            ip_lock.clean_ip_fail_record(config.IP_LOCK_PATH, ctx.ClientAddr)
            return auth_account_info, auth_type
        end
        table.insert(err_info, auth_account_info)
    end

    -- IP锁定无关用户，各种方式认证失败均记录，所以在此处判断增加记录（仅非DT模式下使用,SSH不记录，由openssh记录）
    if not skynet.getenv('TEST_DATA_DIR') and ctx.Interface ~= 'SSH' then
        ip_lock.increase_ip_fail_record(config.IP_LOCK_PATH, ctx.ClientAddr, 0)
    end
    collectgarbage('collect')
    span:finish()
    -- 若不成功,返回最匹配错误码
    error(utils.get_best_match_error(err_info))
end

-- @function 通过account或者session来封装会话创建的必要信息
-- @param account_info account信息，非必要（二者必须有其一）
-- @param session      session信息，非必要（二者必须有其一）
local function package_session_create_account_info(account_info, session)
    local copy_account_data = {}
    if account_info then
        return account_info
    end

    if session then
        copy_account_data = {
            UserName = session.m_username,
            Id = session.m_account_id,
            LastLoginIP = session.m_last_login_ip or '',
            LastLoginTime = session.m_last_login_time or 0,
            RoleId = session.m_role_id,
            current_privileges = session.m_privilege
        }
        return copy_account_data
    end
    error(base_msg.InternalError())
end

--- 判断是否远程会话，是的话需要增加一个属性字典
-- @param session
-- @param auth_type
-- @param group
function SessionService:handle_if_remote_session(session, auth_type, group)
    if auth_type:value() < iam_enum.AuthType.ldap_auto_match:value() or
        auth_type:value() > iam_enum.AuthType.ldap_server6:value() then
        return
    end

    session.remote_dict = {
        controller_id       = group.ControllerId,
        controller_inner_id = group.ControllerInnerId
    }
end

function SessionService:check_first_login(auth_type, account_id)
    -- 只校验本地用户
    if auth_type ~= iam_enum.AuthType.Local then
        return
    end

    -- 获取首次登陆策略和用户情况
    local account_config = self.m_account_service_cache:get_account_service_cache()
    local account_data = self.m_account_cache:get_account_by_id(account_id)

    -- 判断首次登陆策略
    if account_config.InitialPasswordNeedModify and
        account_data.PasswordChangeRequired and
        account_data.FirstLoginPolicy == iam_enum.FirstLoginPolicy.ForcePasswordReset:value() then
        log:error("Failed to create KVM session, initial password need modify")
        error(custom_msg.PasswordChangeRequired(''))
    end
end

---校验新建会话ExtraData参数
---@param extra_data table
function SessionService:check_new_session_extra_data(extra_data)
    if extra_data.SessionMode then
        local session_mode = tonumber(extra_data.SessionMode)
        if session_mode ~= iam_enum.OccupationMode.Shared:value() and
            session_mode ~= iam_enum.OccupationMode.Exclusive:value() then
            log:error("Failed to create session due to unsupported session mode : %s", extra_data.SessionMode)
            error(base_msg.PropertyValueNotInList(extra_data.SessionMode, '%SessionMode'))
        end
    end
    if extra_data.BrowserType then
        local browser_type = tonumber(extra_data.BrowserType)
        -- browser_type继承V2属性,实际无用处;范围0-255
        if browser_type == nil or browser_type < 0 or browser_type > 255 then
            log:error("Failed to create session due to unsupported browser type : %s", extra_data.BrowserType)
            error(base_msg.PropertyValueNotInList(extra_data.BrowserType, '%BrowserType'))
        end
    end
end

--- 创建本地会话
---@param username string
---@param password string
---@param session_type Enum
---@param domain string
---@param ip string
---@param extra_data table
function SessionService:new_session(ctx, username, password, session_type, domain, ip, extra_data)
    local span = trace.start_span('libiam.SessionService.new_session', {username = username, domain = domain, ip = ip})
    -- 如果不是本地会话类型，返回错误
    if session_type ~= iam_enum.SessionType.GUI and session_type ~= iam_enum.SessionType.Redfish and
        session_type ~= iam_enum.SessionType.SSO and session_type ~= iam_enum.SessionType.KVM then -- KVM有通过用户名密码认证的场景
        span:finish()
        error(base_msg.PropertyValueNotInList(tostring(session_type), 'SessionType'))
    end
    if session_type == iam_enum.SessionType.SSO and not self.m_sessions_db.SsoEnabled then
        log:error('web rest sso feature is disabled')
        span:finish()
        error(custom_msg.OperationFailed())
    end
    self:check_new_session_extra_data(extra_data)

    local ext_config = { ["RecordLoginInfo"]  = true, ["UpdateActiveTime"] = true, ["IsAuthPassword"]   = true }
    -- 完成统一认证
    local auth_account_info, auth_type = self:authenticate(ctx,
        username, password, session_type, ip, domain, ext_config)
    local current_session_type = self.m_session_service_collection[session_type:value()]
    local account_data = package_session_create_account_info(auth_account_info, nil)
    local new_session
    if session_type == iam_enum.SessionType.KVM then
        -- 对于本地用户，需要判断是否强制修改密码
        self:check_first_login(auth_type, auth_account_info.Id)
        -- 创建KVM会话需要检查用户权限及VNC会话模式是否冲突
        local privileges = auth_account_info.current_privileges or
            session.get_session_privilege(auth_account_info.RoleId):to_array()
        self:check_remote_console_session_priv(privileges, iam_enum.PrivilegeType.KVMMgmt)
        local vnc_session_service = self.m_session_service_collection[iam_enum.SessionType.VNC:value()]
        local mode = extra_data.SessionMode and tonumber(extra_data.SessionMode) or 0
        if not session_utils.check_remote_console_session_mode_conflicts(vnc_session_service,
            iam_enum.OccupationMode.new(mode)) then
            log:error('Failed to create KVM session due to a conflict with the VNC session mode.')
            span:finish()
            error(custom_msg.SessionModeIsExclusive('KVM'))
        end
        self:check_system_id(ctx)
        new_session = current_session_type:create(account_data, auth_type, ip, mode, nil, ctx.SystemId)
    else
        -- 若为独占模式，需要踢出原有用户的会话
        if current_session_type:get_session_mode() == iam_enum.OccupationMode.Exclusive then
            local del_session_list = current_session_type:delete_by_username(username,
                iam_enum.SessionLogoutType.SessionRelogin)
            self:record_logout_session(del_session_list, iam_enum.SessionLogoutType.SessionRelogin)
        end
        local browser_type = extra_data.BrowserType and tonumber(extra_data.BrowserType) or 0
        new_session = current_session_type:create(account_data, auth_type, ip, browser_type)
    end
    self:handle_if_remote_session(new_session, auth_type, auth_account_info)

    -- 若为远程认证，更新操作日志用户名
    if auth_type:value() ~= iam_enum.AuthType.Local:value() then
        ctx.operation_log.params.username = new_session.m_username
        ctx.UserName = new_session.m_username
    end

    span:finish()
    return new_session.m_token, new_session.m_csrf_token, new_session.m_session_id
end

--- 创建远程会话，基于本地会话Token
---@param token string
---@param session_type Enum
---@param create_session_mode Enum
function SessionService:new_remote_console_session(ctx, token, session_type, create_session_mode)
    local span = trace.start_span('libiam.SessionService.new_remote_console_session', {session_type = session_type})
    local new_session

    if session_type == iam_enum.SessionType.KVM then
        self:check_system_id(ctx)
        new_session = self:new_remote_console_session_kvm(ctx, token, session_type, create_session_mode)
    elseif session_type == iam_enum.SessionType.VIDEO then
        new_session = self:new_remote_console_session_video(ctx, token, session_type, create_session_mode)
    else
        span:finish()
        set_host_operation_log(ctx)
        error(base_msg.PropertyValueNotInList(tostring(session_type), 'SessionType'))
    end
    span:finish()
    return new_session.m_token, new_session.m_session_id
end

function SessionService:create_remote_session_by_session(ctx, session, session_type, create_session_mode)
    local user_name = session.m_username
    local auth_type = session.m_auth_type
    local ip = session.m_ip
    ctx.operation_log.params = { username = user_name, ip = ip,
        mode = tostring(create_session_mode), systemid = ctx.SystemId }

    local target_priv
    if session_type == iam_enum.SessionType.KVM then
        target_priv = iam_enum.PrivilegeType.KVMMgmt
    else
        target_priv = iam_enum.PrivilegeType.DiagnoseMgmt
    end
    -- 通过session创建会话，权限等对照原session
    self:check_remote_console_session_priv(session.m_privilege, target_priv)
    -- 重新组装用户信息数据
    local account_data = package_session_create_account_info(nil, session)
    local new_session
    if session_type == iam_enum.SessionType.KVM then
        new_session = self.m_session_service_collection[session_type:value()]:create(
        account_data, auth_type, ip, create_session_mode, nil, ctx.SystemId)
    else
        new_session = self.m_session_service_collection[session_type:value()]:create(
        account_data, auth_type, ip, create_session_mode)
    end
    -- 如果是本地用户，刷新最后登录记录
    if self.m_account_cache.cache_collection[session.m_account_id] then
        set_account_last_login(ctx, session.m_account_id, ip, "")
    end
    return new_session
end

function SessionService:create_remote_session_by_key(ctx, kvm_key, session_type)
    -- kvm_key直连场景:kvmkey验证,不区分大小写
    local user_name = kvm_key.m_username
    local create_session_mode = kvm_key.m_session_mode
    local auth_type = iam_enum.AuthType.skip_auth
    local ip = ctx.ClientAddr or '127.0.0.1'
    -- kvmkey直连场景context信息只有ip,interface
    ctx.UserName = kvm_key.m_username
    -- 使用后销毁kvmkey
    self.m_session_service_collection[session_type:value()]:destroy_kvm_key()

    ctx.operation_log.params = { username = user_name, ip = ip,
        mode = tostring(create_session_mode), systemid = ctx.SystemId }

    -- 应保证kvm_key的用户是本地用户
    local id, account = self.m_account_cache:get_account_by_name(user_name)
    if not id then
        error(custom_msg.UserNotExist(user_name))
    end
    local privileges = account.current_privileges or privilege.new_from_role_ids({ account:get_role_id() }):to_array()
    self:check_remote_console_session_priv(privileges, iam_enum.PrivilegeType.KVMMgmt)

    local account_data = package_session_create_account_info(account, nil)
    local new_session = self.m_session_service_collection[session_type:value()]:create(
        account_data, auth_type, ip, create_session_mode, nil, ctx.SystemId)

    set_account_last_login(ctx, id, ip, "")
    return new_session
end

function SessionService:new_remote_console_session_kvm(ctx, token, session_type, create_session_mode)
    -- 根据token获取session(KVM会话可使用kvm_key连接)
    local session_id = session_utils.generate_session_id(token)
    local session = self:get_session_by_session_id(session_id)
    local kvm_key = self.m_session_service_collection[session_type:value()]:get_kvm_key()
    local is_create_by_session, new_session

    if session and (session.m_session_type == iam_enum.SessionType.GUI or
            session.m_session_type == iam_enum.SessionType.Redfish) then
        is_create_by_session = true
    elseif kvm_key and token:lower() == kvm_key.m_kvm_key:lower() then
        is_create_by_session = false
    else
        log:error('There is no valid session to create kvm session')
        set_host_operation_log(ctx)
        error(base_msg.NoValidSession())
    end
    -- 创建KVM会话需要检查VNC会话模式是否冲突
    local vnc_session_service = self.m_session_service_collection[iam_enum.SessionType.VNC:value()]
    if not session_utils.check_remote_console_session_mode_conflicts(vnc_session_service,
            iam_enum.OccupationMode.new(create_session_mode)) then
        log:error('Failed to create KVM session due to a conflict with the VNC session mode.')
        set_host_operation_log(ctx)
        error(custom_msg.SessionModeIsExclusive('KVM'))
    end

    if is_create_by_session then
        new_session = self:create_remote_session_by_session(ctx, session, session_type, create_session_mode)
    else
        new_session = self:create_remote_session_by_key(ctx, kvm_key, session_type)
    end

    return new_session
end

function SessionService:new_remote_console_session_video(ctx, token, session_type, create_session_mode)
    -- 根据token获取session(KVM会话可使用kvm_key连接)
    local session_id = session_utils.generate_session_id(token)
    local session = self:get_session_by_session_id(session_id)
    if not session then
        log:error('There is no valid session')
        error(base_msg.NoValidSession())
    end
    if session.m_session_type ~= iam_enum.SessionType.GUI and
        session.m_session_type ~= iam_enum.SessionType.Redfish then
        log:error('The session is not supported to create video session')
        error(base_msg.NoValidSession())
    end

    return self:create_remote_session_by_session(ctx, session, session_type, create_session_mode)
end

--- 通过SsoToken创建其它会话
---@param sso_token string
---@param session_type Enum
---@param create_session_mode Enum
function SessionService:new_session_by_sso(ctx, sso_token, session_type, create_session_mode)
    ctx.operation_log.params.type = tostring(session_type)
    -- 判断token是否为SSO会话
    local session_id = session_utils.generate_session_id(sso_token)
    local session = self:get_session_by_session_id(session_id)
    if not session or session.m_session_type ~= iam_enum.SessionType.SSO then
        log:error('The token is not sso token')
        error(base_msg.NoValidSession())
    end

    -- 校验token ip是否与创建的IP一致
    if self.m_sessions_db.ValidateSsoClient then
        if not utils.check_ip_valid(session.m_ip) or not utils.check_ip_valid(ctx.ClientAddr) or
            (utils.normalize_ip(session.m_ip) ~= utils.normalize_ip(ctx.ClientAddr)) then
            log:error('sso client addr verify failed')
            error(base_msg.NoValidSession())
        end
    end

    ctx.UserName = session.m_username
    ctx.operation_log.params.username = session.m_username
    local id, _ = self.m_account_cache:get_account_by_name(session.m_username)
    if not id then
        error(custom_msg.UserNotExist(session.m_username))
    end
    local account_data = package_session_create_account_info(nil, session)
    -- 远程会话和本地会话参数不同
    local new_session
    if session_type == iam_enum.SessionType.GUI then
        -- 若为独占模式，需要踢出原有用户的会话
        if self.m_session_service_collection[session_type:value()]:get_session_mode() ==
            iam_enum.OccupationMode.Exclusive then
            local del_session_list = self.m_session_service_collection[session_type:value()]:delete_by_username(
                session.m_username, iam_enum.SessionLogoutType.SessionRelogin)
            self:record_logout_session(del_session_list, iam_enum.SessionLogoutType.SessionRelogin)
        end
        new_session = self.m_session_service_collection[session_type:value()]:create(
            account_data, session.m_auth_type, session.m_ip, session.m_browser_type, sso_token)
    elseif session_type == iam_enum.SessionType.KVM then
        -- 创建KVM会话需要检查VNC会话模式是否冲突
        local vnc_session_service = self.m_session_service_collection[iam_enum.SessionType.VNC:value()]
        local mode_str = create_session_mode == iam_enum.OccupationMode.Shared and 'Shared' or 'Private'
        ctx.operation_log.params.type = string.format('%s(%s)', session_type, mode_str)
        if not session_utils.check_remote_console_session_mode_conflicts(vnc_session_service, create_session_mode) then
            log:error('Failed to create KVM session due to a conflict with the VNC session mode.')
            error(custom_msg.SessionModeIsExclusive('KVM'))
        end
        self:check_system_id(ctx)
        new_session = self.m_session_service_collection[session_type:value()]:create(
            account_data, session.m_auth_type, session.m_ip, create_session_mode, sso_token, ctx.SystemId)
    else
        error(base_msg.PropertyValueNotInList(tostring(session_type), 'SessionType'))
    end
    self.m_session_service_collection[iam_enum.SessionType.SSO:value()]:delete(session_id,
        iam_enum.SessionLogoutType.SessionLogout)
    set_account_last_login(ctx, id, session.m_ip, "")
    return new_session.m_token, new_session.m_csrf_token, new_session.m_session_id
end

--- 新建vnc会话
---@param ctx any
---@param ciphertext string
---@param auth_challenge string
function SessionService:new_vnc_session(ctx, ciphertext, auth_challenge, session_mode)
    local span = trace.start_span('libiam.SessionService.new_vnc_session', {session_mode = session_mode})
    -- 在认证之前判断本ip是否锁定
    if self.m_access_service:check_ip_locked(ctx.ClientAddr) then
        log:error("ip %s is locked by auth failed", ctx.ClientAddr)
        error(custom_msg.AuthorizationFailed())
    end
    local vnc_account = self.m_authentication_service:vnc_authenticate(ctx, ciphertext, auth_challenge)
    -- mode为2,vnc先进行认证动作,不记录操作日志
    if session_mode == 2 then
        ctx.operation_log = nil
        span:finish()
        return ''
    end
    session_mode = iam_enum.OccupationMode.new(session_mode)
    ctx.operation_log.params = { mode = tostring(session_mode) }

    -- 创建VNC会话需要检查KVM会话模式是否冲突
    local kvm_session_service = self.m_session_service_collection[iam_enum.SessionType.KVM:value()]
    if not session_utils.check_remote_console_session_mode_conflicts(kvm_session_service, session_mode) then
        span:finish()
        error(custom_msg.SessionModeIsExclusive('VNC'))
    end
    local account_data = package_session_create_account_info(vnc_account, nil)
    local new_session = self.m_session_service_collection[iam_enum.SessionType.VNC:value()]:create(
        account_data, session_mode, ctx.ClientAddr)
    span:finish()
    return new_session.m_session_id
end

--- 删除指定会话
---@param session_id string
---@param clear_type Enum
function SessionService:delete_session(ctx, session_id, clear_type)
    local session = self:get_session_by_session_id(session_id)
    if not session then
        error(self:check_session_error(session_id))
    end
    self.m_session_service_collection[session.m_session_type:value()]:delete(session_id)
    ctx.operation_log.result = tostring(clear_type)
    ctx.operation_log.params = { username = session.m_username,
        ip = session.m_ip, session_type = tostring(session.m_session_type_name) }
    self:record_logout_session(session_id, clear_type)

    -- 针对远程会话，不存在本地账户的情况，直接返回
    if not self.m_account_cache:get_account_by_id(session.m_account_id) then
        return
    end
    record_login_info(session.m_username, session.m_ip, "", false, true)
end

--- 更新会话最后活跃时间
---@param session_id string
---@param remain_active_seconds number
function SessionService:update_session_active_time(session_id, remain_active_seconds)
    local session = self:get_session_by_session_id(session_id)
    if not session then
        error(self:check_session_error(session_id))
    end

    if remain_active_seconds == 0 then
        session.m_last_active_time = 0
        return
    end
    local session_service = self.m_session_service_collection[session.m_session_type:value()]
    session.m_last_active_time = session_service:get_session_timeout() - remain_active_seconds
end

--- 根据Token验证会话
--- 【被前端高频调用的函数，需注意】
---@param session_type Enum
---@param token string
---@param csrf_token string
function SessionService:validate_session(session_type, token, csrf_token)
    local session = self.m_session_service_collection[session_type:value()]:get_session_by_token(token, csrf_token)
    -- 板间通信恢复校验时会按照Redfish会话来，需要独立处理查找的逻辑
    if (not session) and (session_type == iam_enum.SessionType.Redfish or session_type == iam_enum.SessionType.GUI)  then
        session = self.m_session_service_collection[iam_enum.SessionType.INTER_CHASSIS:value()]:
            get_session_by_token(token, csrf_token, session_type)
        session_type = iam_enum.SessionType.INTER_CHASSIS
    end

    if not session then
        local session_id = session_utils.generate_session_id(token)
        error(self:check_session_error(session_id))
    end
    return self.m_session_service_collection[session_type:value()]:validate_session(session)
end

--- 登出会话查询，返回给前端会话失效原因
---@param session_id string 
function SessionService:get_session_logout_type(session_id)
    for _, v in pairs(self.m_session_logout_collection) do
        -- session_id, clear_type = v[1], v[2]
        if v[1] == session_id then
            return v[2]
        end
    end
    -- 如果未找见登出会话，从已有会话中查找
    local session = self:get_session_by_session_id(session_id)
    if session ~= nil then
        error(iam_err.session_still_alive())
    end

    -- 均未找见，返回未找到
    error(base_msg.NoValidSession())
end

--- 更新cli在线会话
function SessionService:update_cli_online_session()
    local cli_cur_session = {}
    local account_data ={}
    local id
    local account = {}
    local cli_online_sessions = cli_session.get_cli_online_session()
    local cli_session_collection = self:get_cli_session_list()
    self.m_session_service_collection[iam_enum.SessionType.CLI:value()]:update_ldap_authed_accounts()
    local ctx = {}
    for _, online_session in pairs(cli_online_sessions) do
        cli_cur_session[online_session.m_session_id] = online_session.m_username
    end

    for _, session in pairs(cli_session_collection) do
        if not cli_cur_session[session.m_session_id] then
            ctx = context.new('CLI', session.m_username, session.m_ip)
            operation_logger.safe_call(ctx, function()
                ctx.operation_log = { operation = 'DeleteSession', result = nil, params = {} }
                self:delete_session(ctx, session.m_session_id, iam_enum.SessionLogoutType.SessionLogout)
            end)
        else
            cli_cur_session[session.m_session_id] = nil
        end
    end
    for _, online_session in pairs(cli_online_sessions) do
        if cli_cur_session[online_session.m_session_id] then
            id, account = self.m_account_cache:get_account_by_name(online_session.m_username)
            if not id then
                -- CLI接口扫描出的域用户无Id与Role配置;创建会话需要相关配置;此处设置Id为pid;Role为CommonUser
                -- CLI接口的鉴权由框架控制,此处无影响;
                account_data = package_session_create_account_info(nil, online_session)
                account_data.Id = config.LDAP_USER_GID
                account_data.RoleId = iam_enum.RoleType.CommonUser:value()
            else
                account_data = package_session_create_account_info(account, nil)
            end
            self.m_session_service_collection[iam_enum.SessionType.CLI:value()]:create(account_data, online_session)
            set_account_last_login(ctx, id, online_session.m_ip, "")
        end
    end
end

--- 获取CLI会话集合
function SessionService:get_cli_session_list()
    local collection = self.m_session_service_collection[iam_enum.SessionType.CLI:value()].m_session_collection
    -- 使用copy后的集合来判断，避免删除动作影响原table的校验
    return mc_utils.table_copy(collection)
end

--- 根据用户名删除其所有会话
---@param username string
function SessionService:delete_session_by_username(username, logout_type)
    for session_type, session_collection in pairs(self.m_session_service_collection) do
        if session_type == iam_enum.SessionType.CLI:value() and skynet_ready then
            skynet.fork_once(function()
                -- 协程等待，防止CLI回显失败
                skynet.sleep(50)
                local del_session_list = session_collection:delete_by_username(username, logout_type)
                self:record_logout_session(del_session_list, logout_type)
            end
            )
        else
            local del_session_list = session_collection:delete_by_username(username, logout_type)
            self:record_logout_session(del_session_list, logout_type)
        end
    end
end

function SessionService:delete_session_by_ip(ip, logout_type)
    for session_type, session_collection in pairs(self.m_session_service_collection) do
        if session_type == iam_enum.SessionType.CLI:value() and skynet_ready then
            skynet.fork_once(function()
                -- 协程等待，防止CLI回显失败
                skynet.sleep(50)
                local del_session_list = session_collection:delete_by_ip(ip, logout_type)
                self:record_logout_session(del_session_list, logout_type)
            end
            )
        else
            local del_session_list = session_collection:delete_by_ip(ip, logout_type)
            self:record_logout_session(del_session_list, logout_type)
        end
    end
end

--- 根据域控制器和组信息删除对应远程会话
function SessionService:delete_remote_session(controller_id, inner_id, logout_type)
    for _, session_collection in pairs(self.m_session_service_collection) do
        local del_session_list = session_collection:delete_remote_session(controller_id, inner_id, logout_type)
        self:record_logout_session(del_session_list, logout_type)
    end
end

--- 删除所有会话
---@param logout_type Enum
---@param session_type Enum
---@param ip_type Enum
function SessionService:delete_all_session(ctx, logout_type, session_type, ip_type)
    -- 如果需要删除所有的会话，单独处理
    if session_type == iam_enum.SessionType.All then
        for _, session_collection in pairs(self.m_session_service_collection) do
            session_collection:delete_all_session(logout_type, ip_type)
        end
        return
    end
    local session_collection = self.m_session_service_collection[session_type:value()]
    if session_collection == nil then
        log:error("delete_all_session get a invalid session type: %d", tostring(session_type))
        error(base_msg.PropertyValueNotInList(tostring(session_type), "SessionType"))
    end
    if session_type == iam_enum.SessionType.KVM then
        self:check_system_id(ctx)
        session_collection:delete_all_system_id_session(logout_type, ip_type, ctx)
        return
    end
    session_collection:delete_all_session(logout_type, ip_type)
end

--- 删除超时会话list
---@param timeout_session_list table
function SessionService:delete_timeout_session_list(timeout_session_list)
    for _, session in pairs(timeout_session_list) do
        local ctx = context.new(session.m_session_type_name, session.m_username, session.m_ip)
        operation_logger.safe_call(ctx, function()
            ctx.operation_log = { operation = 'DeleteSession', result = nil, params = {} }
            self:delete_session(ctx, session.m_session_id, iam_enum.SessionLogoutType.SessionTimeout)
        end)
    end
end

--- 根据会话Id获取会话信息
---@param session_id string
---@return table
function SessionService:get_session_by_session_id(session_id)
    for _, session_service in pairs(self.m_session_service_collection) do
        local session = session_service:get_session_by_session_id(session_id)
        if session then
            return session
        end
    end
    return nil
end

--- 登出会话记录，方便前端查询会话失效原因
---@param session_id string or table
---@param clear_type Enum 
function SessionService:record_logout_session(session_id, clear_type)
    local deleted_session_list = type(session_id) == 'table' and session_id or {session_id}
    for _, id in pairs(deleted_session_list) do
        if #self.m_session_logout_collection >= MAX_LOGOUT_SESSION then
            table.remove(self.m_session_logout_collection, 1)
        end
        table.insert(self.m_session_logout_collection, {id, clear_type})
    end
end

--- 检查session登出错误
---@param session_id string
function SessionService:check_session_error(session_id)
    for _, v in pairs(self.m_session_logout_collection) do
        local logout_clear_type = v[2]:value()
        if v[1] == session_id and ERR_MAP[logout_clear_type] ~= nil then
            return ERR_MAP[logout_clear_type]()
        end
    end
    return base_msg.NoValidSession()
end

--- 设置指定会话类型的最大会话数
---@param session_type Enum
---@param max_count number
function SessionService:set_session_max_count(ctx, session_type, max_count)
    self.m_session_service_collection[session_type:value()]:set_session_max_count(max_count)
end

--- 获取指定会话类型的最大会话数
function SessionService:get_session_max_count(session_type)
    return self.m_session_service_collection[session_type:value()]:get_session_max_count()
end

--- 设置指定会话类型的会话模式
---@param session_type Enum
---@param session_mode Enum
function SessionService:set_session_mode(ctx, session_type, session_mode)
    self.m_session_service_collection[session_type:value()]:set_session_mode(session_mode)
end

--- 获取指定会话类型的会话模式
function SessionService:get_session_mode(session_type)
    return self.m_session_service_collection[session_type:value()]:get_session_mode()
end

--- 设置指定会话类型的会话超时时间
---@param session_type Enum
---@param timestamp number
function SessionService:set_session_timeout(ctx, session_type, timestamp)
    self.m_session_service_collection[session_type:value()]:set_session_timeout(timestamp)
end

--- 获取指定会话类型的会话超时时间
function SessionService:get_session_timeout(session_type)
    return self.m_session_service_collection[session_type:value()]:get_session_timeout()
end

--- 获取指定会话类型的当前会话数量
function SessionService:get_session_count(session_type)
    return self.m_session_service_collection[session_type:value()]:get_session_count()
end

--- 获取指定会话类型的最短超时时间
function SessionService:get_min_session_timeout(session_type)
    return self.m_session_service_collection[session_type:value()]:get_min_session_timeout()
end

--- 获取指定会话类型的最长超时时间
function SessionService:get_max_session_timeout(session_type)
    return self.m_session_service_collection[session_type:value()]:get_max_session_timeout()
end

function SessionService:register_access_signals()
    self.m_access_service.m_ip_locked_sig:on(function(ip)
        self:delete_session_by_ip(ip, iam_enum.SessionLogoutType.SessionKickout)
    end)
end

--- 用户信息删除及修改回调注册
function SessionService:register_account_signals()
    self.m_account_cache.m_account_removed:on(function(account_id, username)
        self:delete_session_by_username(username, iam_enum.SessionLogoutType.AccountConfigChange)
    end)
    -- 为满足IPMI带内设置密码，设置角色功能的性能需求。将此耗时操作放在协程处理
    self.m_account_cache.m_account_security_changed:on(function(account_id, username)
        if skynet_ready then
            skynet.fork_once(function()
                self:delete_session_by_username(username, iam_enum.SessionLogoutType.AccountConfigChange)
            end)
        else
            self:delete_session_by_username(username, iam_enum.SessionLogoutType.AccountConfigChange)
        end
    end)
    self:ldap_signal_register()
end

function SessionService:ldap_signal_register()
    self.m_ldap_controller_collection.m_controller_security_changed:on(function(controller_id)
        if skynet_ready then
            skynet.fork_once(function()
                self:delete_remote_session(controller_id, nil, iam_enum.SessionLogoutType.AccountConfigChange)
            end)
        else
            self:delete_remote_session(controller_id, nil, iam_enum.SessionLogoutType.AccountConfigChange)
        end
    end)
    self.m_remote_group_collection.m_remote_group_security_changed:on(function(group_id, mdb_id)
        local controller_id
        local inner_id
        -- 针对删除场景，使用group_id已经无法获取到组信息
        if mdb_id then
            _, controller_id, inner_id = string.match(mdb_id, "(%w+)(%d+)_(%d+)")
            controller_id = tonumber(controller_id)
            inner_id = tonumber(inner_id)
        else
            controller_id = self.m_remote_group_collection:get_remote_group_controller_id(group_id)
            inner_id = self.m_remote_group_collection:get_remote_group_controller_inner_id(group_id)
        end
        if skynet_ready then
            skynet.fork_once(function()
                self:delete_remote_session(controller_id, inner_id, iam_enum.SessionLogoutType.AccountConfigChange)
            end)
        else
            self:delete_remote_session(controller_id, inner_id, iam_enum.SessionLogoutType.AccountConfigChange)
        end
    end)
    self.m_ldap_config.m_config_security_changed:on(function()
        if skynet_ready then
            skynet.fork_once(function()
                self:delete_remote_session(nil, nil, iam_enum.SessionLogoutType.AccountConfigChange)
            end)
        else
            self:delete_remote_session(nil, nil, iam_enum.SessionLogoutType.AccountConfigChange)
        end
    end)
end

--- 双因素使能状态变动时，删除GUI会话
function SessionService:register_mutual_auth_signals()
    self.m_certificate_authtication.mutual_auth_state_changed:on(function(ctx)
        self:delete_all_session(ctx, iam_enum.SessionLogoutType.SessionKickout,
            iam_enum.SessionType.GUI, iam_enum.IpType.All)
    end)
end

---@param context_info table
function SessionService:get_redfish_inner_token(context_info)
    local ip_addr = context_info.ip_addr
    local user_name = context_info.user_name
    local role_id = context_info.role_id
    local inner_session_type = context_info.inner_session_type
    local redfish_session_service = self.m_session_service_collection[iam_enum.SessionType.Redfish:value()]
    local account = self.m_account_cache:get_ipmi_account(user_name)
    if not account then
        error(custom_msg.UserNotExist(user_name))
    end
    local account_data = package_session_create_account_info(account, nil)
    -- 预制账号权限最低，此处根据输入参数设置用户角色，获取符合权限的token
    local inner_session = redfish_session_service:create_inner_session(account_data, iam_enum.AuthType.skip_auth,
        ip_addr, inner_session_type, role_id)
    -- 生成session后还原账号的权限
    log:info("Create inner redfish token successfully!")
    return inner_session.m_token
end

-- 设置KvmKey
function SessionService:set_kvm_key(ctx, kvm_key, mode)
    local id, account = self.m_account_cache:get_account_by_name(ctx.UserName)
    if not id then
        log:error('Handler account not exist.')
        error(custom_msg.UserNameNotExist())
    end
    self.m_session_service_collection[iam_enum.SessionType.KVM:value()]:set_kvm_key(kvm_key, mode, account.UserName)
end

-- 设置sso token ip校验使能
function SessionService:set_validate_sso_client_addr(enable)
    self.m_sessions_db.ValidateSsoClient = enable
    self.m_sessions_db:save()
end

function SessionService:set_sso_enabled(enable)
    self.m_sessions_db.SsoEnabled = enable
    self.m_sessions_db:save()
end

function SessionService:new_mutual_auth_session(ctx, serial_number, issuer, subject, ip)
    -- 查询是否存在对应的客户端证书
    local obj
    iam_client:ForeachCertificateObjects(function(o)
        if o.CertificateUsageType == cert_service_enum.CertificateUsageType.ManagerAccountCertificate:value() and
            utils.string_equal_without_space_and_case(o.SerialNumber, serial_number) and
            self:compare_subject_and_issuer_string(ctx, o, issuer, subject) then
            obj = o
        end
    end
    )
    if not obj then
        log:error("There are no users who own this certificate.")
        error(custom_msg.AuthorizationFailed())
    end
    -- 验证吊销列表是否开启，且是否有被吊销
    local crl_enable = iam_client:GetCertificateServiceObjects()[PATH_CERTIFICATE_SERVICE].CRLEnabled
    if crl_enable then
        for _, o in pairs(iam_client:GetAccountObjects()) do
            if o.path == obj.path and o.RevokedState then
                log:error("The user has not issuer or is revoked.")
                error(custom_msg.AuthorizationFailed())
                break
            end
        end
    end
    local user_id = tonumber(string.match(obj.path, ".*/([%d]+)$"))
    local current_session_type = self.m_session_service_collection[iam_enum.SessionType.GUI:value()]
    local account_info = self.m_account_cache:get_account_by_id(user_id)
    self.m_authentication_service:mutual_auth_authentication(user_id, ip, ctx.Interface)
    local user_name = account_info.UserName
    -- rackmount仓库new出来的ctx，用户名信息只能在本组件内赋予真实值
    ctx.UserName = user_name
    ctx.operation_log.params.Ip = ip
    ctx.operation_log.params.UserName = user_name

    local account_data = package_session_create_account_info(account_info, nil)
    local new_session = current_session_type:create(account_data, iam_enum.AuthType.Local, ip,
        iam_enum.NewSessionBrowserType.MutualAuth:value())
    record_login_info(user_name, ip, "", true, true)
    return new_session.m_token, new_session.m_csrf_token, new_session.m_session_id
end

function SessionService:validate_inter_chasiss_requestor(serial_number, issuer, subject, ip)
    local validation = self.m_certificate_authtication:get_inter_chassis_validation()

    local validate_flag = false
    if validation == 'LLDP' then
        log:info("validate by LLDP")
        iam_client:ForeachLLDPReceiveObjects(function(obj)
            if obj.ManagementAddressIPv4 == ip or obj.ManagementAddressIPv6 == ip then
                validate_flag = true
                return
            end
        end)
    elseif validation == 'Static' then
        log:info("validate by Whitelist")
        local item = {['IP'] = ip}
        if self.m_inter_chassis_validator:validate(item) then
            validate_flag = true
        end
    elseif validation == 'None' then
        log:info("no need to validate")
        return
    end

    if not validate_flag then
        log:error("Requestor ip not in white list")
        error(custom_msg.AuthorizationFailed())
    end
end

local browser_type_to_session_type = {
    [iam_enum.NewSessionBrowserType.InterChassisRest] = iam_enum.SessionType.GUI,
    [iam_enum.NewSessionBrowserType.InterChassis] = iam_enum.SessionType.Redfish
}

function SessionService:new_inter_chassis_session(browser_type, ctx, serial_number, issuer, subject, ip)
    -- 板间通信会话不记录操作日志
    ctx.operation_log.operation = 'SkipLog'

    self:validate_inter_chasiss_requestor(serial_number, issuer, subject, ip)

    local account_info = self.m_account_cache:get_account_by_id(config.INTER_CHASSIS_ACCOUNT_ID)
    -- 无权限用户不允许登录
    if account_info.RoleId == iam_enum.RoleType.NoAccess:value() then
        log:error("No access to create inter-chassis session")
        error(custom_msg.NoAccess())
    end

    local current_session_type = self.m_session_service_collection[iam_enum.SessionType.INTER_CHASSIS:value()]
    local session_type = browser_type_to_session_type[browser_type]
    local validation = self.m_certificate_authtication:get_inter_chassis_validation()
    if validation ~= "None" then
        local old_session = current_session_type:get_session_by_ip(ip, session_type)
        if old_session then
            return old_session.m_token, old_session.m_csrf_token, old_session.m_session_id
        end
    end

    local account_data = package_session_create_account_info(account_info, nil)
    local new_session = current_session_type:create(account_data, iam_enum.AuthType.skip_auth, ip,
        browser_type:value(), session_type)

    return new_session.m_token, new_session.m_csrf_token, new_session.m_session_id
end

---@function 通过证书信息新建对话
function SessionService:new_session_by_cert(ctx, serial_number, issuer, subject, ip, browser_type)
    -- 在认证之前判断本ip是否锁定
    if self.m_access_service:check_ip_locked(ctx.ClientAddr) then
        log:error("ip %s is locked by auth failed", ctx.ClientAddr)
        error(custom_msg.AuthorizationFailed())
    end
    -- 参数校验
    if serial_number == nil or issuer == nil or subject == nil or ip == nil or browser_type == nil then
        error(base_msg.PropertyMissing(""))
    end

    return self.browser_type_session[browser_type](ctx, serial_number, issuer, subject, ip)
end

function SessionService:check_remote_console_session_priv(account_privilege, target_privilege)
    if not account_utils.privilege_validator(account_privilege, target_privilege) then
        log:error('There was insufficient privilege to create remote session')
        error(base_msg.InsufficientPrivilege())
    end
end

---@function 判断subject和issuer信息是否匹配
---@param mdb_obj any mdb对象
---@return boolean is_ok 是否匹配成功
function SessionService:compare_subject_and_issuer_string(ctx, mdb_obj, issuer, subject)
    -- 获取证书id
    local cert_id = string.match(mdb_obj.path, REGEX_PATH_CERTIFICATE_ACCOUNT)
    -- 获取证书信息
    local obj = iam_client:GetCertificateServiceObjects()[PATH_CERTIFICATE_SERVICE]
    local dup_ctx = context.new(ctx.Interface, ctx.UserName, ctx.ClientAddr)
    local infos = obj:GetCertChainInfo(dup_ctx,
        cert_service_enum.CertificateUsageType.ManagerAccountCertificate:value(), cert_id)
    infos = cjson.decode(infos)
    return issuer == infos["ServerCert"]["AuthIssuerInfo"] and subject == infos["ServerCert"]["AuthSubjectInfo"]
end

-- 环境变更踢出内部会话
function SessionService:delete_inner_session_due_to_env_changed(changed, extra_data)
    -- 1:os下电/重启
    -- 2:ipmi通道权限控制变更
    if changed == 1 then
        self.m_session_service_collection[iam_enum.SessionType.Redfish:value()]:delete_all_inner_session()
    elseif changed == 2 then
        self.m_session_service_collection[iam_enum.SessionType.Redfish:value()]:
            delete_high_priv_inner_session(extra_data)
    end
end

function SessionService:delete_username_session_signals()
    self.m_authentication_service.m_delete_username_session:on(function(username, logout_type)
        self:delete_session_by_username(username, logout_type)
    end)
end

return singleton(SessionService)
