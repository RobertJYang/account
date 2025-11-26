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
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local cls_mng = require 'mc.class_mgnt'
local log = require 'mc.logging'
local context = require 'mc.context'
local base_msg = require 'messages.base'
local privilege = require 'domain.privilege'
local authentication_config = require 'domain.authentication_config'
local session_service = require 'service.session_service'
local operation_logger = require 'interface.operation_logger'
local authentication_service = require 'service.authentication'
local trace = require 'telemetry.trace'
local vos_utils  = require 'utils.vos'

local INTERFACE_AUTHENTICATION = "bmc.kepler.AccountService.Authentication"
local PATH_AUTHENTICATION      = "/bmc/kepler/AccountService/Authentication"
local CLASS_AUTHENTICATION     = "Authentication"

local AuthenticationMdb = class()

function AuthenticationMdb:ctor()
    self.m_session_service = session_service.get_instance()
    self.m_auth_config = authentication_config.get_instance()
    self.m_auth_service = authentication_service.get_instance()
end

function AuthenticationMdb:init()
    local config_mdb = {}
    config_mdb.AccountLockoutDuration          = self.m_auth_config:get_account_lockout_duration()
    config_mdb.AccountLockoutThreshold         = self.m_auth_config:get_account_lockout_threshold()
    config_mdb.MaxAccountLockoutDuration       = self.m_auth_config:get_max_account_lockout_duration()
    config_mdb.MaxAccountLockoutThreshold      = self.m_auth_config:get_max_account_lockout_threshold()
    config_mdb.AccountLockoutCounterResetAfter = self.m_auth_config:get_account_lockout_reset_time()
    config_mdb.LocalAccountAuth                = self.m_auth_config:get_auth_mode()
    self:new_config_to_mdb_tree(config_mdb)
end

function AuthenticationMdb:regist_account_signals()
    self.m_new_unregist_handle = self.m_auth_config.m_config_added:on(function(...)
        self:new_config_to_mdb_tree(...)
    end)
    self.m_change_unregist_handle = self.m_auth_config.m_config_changed:on(function(...)
        self:config_mdb_update(...)
    end)
end

function AuthenticationMdb:new_config_to_mdb_tree(config)
    local mdb_config = cls_mng(CLASS_AUTHENTICATION):get(PATH_AUTHENTICATION)
    mdb_config[INTERFACE_AUTHENTICATION].AccountLockoutDuration          = config.AccountLockoutDuration
    mdb_config[INTERFACE_AUTHENTICATION].AccountLockoutThreshold         = config.AccountLockoutThreshold
    mdb_config[INTERFACE_AUTHENTICATION].MaxAccountLockoutDuration       = config.MaxAccountLockoutDuration
    mdb_config[INTERFACE_AUTHENTICATION].MaxAccountLockoutThreshold      = config.MaxAccountLockoutThreshold
    mdb_config[INTERFACE_AUTHENTICATION].AccountLockoutCounterResetAfter = config.AccountLockoutCounterResetAfter
    mdb_config[INTERFACE_AUTHENTICATION].LocalAccountAuth                = config.LocalAccountAuth
    self:watch_service_property(mdb_config)
    -- 初始化后获取锁定次数时间配置并重写pam文件
    self.m_auth_config:update_pam_faillock(nil, nil, nil)
end

-- 属性监听钩子
AuthenticationMdb.watch_property_hook = {
    AccountLockoutDuration = operation_logger.proxy(function(self, ctx, value)
        -- 入参整除60，取分钟
        ctx.operation_log.params = { duration = value // 60 }
        self.m_auth_service:set_account_lockout_duration(value)
    end, 'AccountLockoutDuration'),
    AccountLockoutThreshold = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { threshold = value }
        self.m_auth_service:set_account_lockout_threshold(value)
    end, 'AccountLockoutThreshold'),
    MaxAccountLockoutDuration = operation_logger.proxy(function(self, ctx, value)
        -- 入参整除60，取分钟
        ctx.operation_log.params = { duration = value // 60 }
        self.m_auth_service:set_max_account_lockout_duration(value)
    end, 'MaxAccountLockoutDuration'),
    MaxAccountLockoutThreshold = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { threshold = value }
        self.m_auth_service:set_max_account_lockout_threshold(value)
    end, 'MaxAccountLockoutThreshold'),
    AccountLockoutCounterResetAfter = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { reset_time = value }
        self.m_auth_service:set_account_lockout_reset_time(value)
    end, 'AccountLockoutCounterResetAfter'),
    LocalAccountAuth = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { mode = value }
        self.m_auth_service:set_auth_mode(value)
    end, 'LocalAccountAuth')
}

function AuthenticationMdb:watch_service_property(service)
    service[INTERFACE_AUTHENTICATION].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the account service property(%s) to value(%s), sender is nil', name, tostring(value))
            return true
        end

        if not self.watch_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('change the property(%s) to value(%s)', name, tostring(value))
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_property_hook[name](self, ctx, value)
        return true
    end)
end

function AuthenticationMdb:config_mdb_update(property, value)
    local config = cls_mng(CLASS_AUTHENTICATION):get(PATH_AUTHENTICATION)
    if config[INTERFACE_AUTHENTICATION][property] == nil then
        return
    end
    config[INTERFACE_AUTHENTICATION][property] = value
end

--- 【被高频调用的函数，需注意】
function AuthenticationMdb:authenticate(ctx, username, password, domain)
    local span = trace.start_span('libiam.AuthenticationMdb.authenticate', {username = username, domain = domain})
    local ts_start = vos_utils.vos_tick_get()
    ctx.operation_log.params = {
        username = username
    }

    local ext_config = {
        ["RecordLoginInfo"]  = false,
        ["UpdateActiveTime"] = false,
        ["IsAuthPassword"]   = true
    }
    local auth_account_info = self.m_session_service:authenticate(ctx, username, password, ctx.Interface,
        ctx.ClientAddr, domain, ext_config)
    local extra_data = {}
    local role_id_table = {}

    local role_id = auth_account_info.RoleId
    if type(role_id) == 'number' then
        role_id_table[1] = role_id
    else
        role_id_table = role_id
    end
    local privileges = auth_account_info.current_privileges or privilege.new_from_role_ids(role_id_table):to_array()
    if auth_account_info.ControllerId then
        extra_data = {
            UserName = auth_account_info.UserName,
            ServerId = tostring(auth_account_info.ControllerId),
            GroupId = tostring(auth_account_info.ControllerInnerId),
            RoleId = table.concat(role_id_table, ',')
        }
        role_id = role_id[1]
    end
    local ts_end = vos_utils.vos_tick_get()
    log:debug("Authenticate time, start:%s, end:%s, usage:%d", ts_start, ts_end - ts_start)
    span:finish()
    return auth_account_info.Id, privileges, role_id, extra_data
end

return singleton(AuthenticationMdb)