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
local singleton = require 'mc.singleton'
local context = require 'mc.context'
local iam_enum = require 'class.types.types'
local log = require 'mc.logging'
local iam_core = require 'iam_core'
local user_config = require 'user_config'
local account_lock = require 'domain.account_lock'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local client = require 'iam.client'
local account_cache = require 'domain.cache.account_cache'
local authentication_config = require 'domain.authentication_config'
local account_service = require 'service.account_service'
local cjson = require 'cjson'
local mc_utils = require 'mc.utils'
local event = require 'utils.event'

-- Authentication
local Authentication = class()

-- 初始化
function Authentication:ctor()
    self.m_pam_tally_log_dir = user_config.PAM_TALLY_LOG_DIR
    self.m_account_lock = account_lock.get_instance()
    self.m_account_cache = account_cache.get_instance()
    self.m_auth_config = authentication_config.get_instance()
    self.m_account_service = account_service.get_instance()
end

-- 本地认证，通过linux shadow形式认证
function Authentication:local_authenticate(user_name, password, ip, interface, server_id, ext_config)
    -- 自己判断pam锁定
    if self:get_user_lock_state(user_name) then
        error(custom_msg.AuthorizationFailed()) -- 如果是登录失败之后锁定的，则用"无效密码"模糊提示错误
    end

    -- 走 user 认证
    local auth_obj = client:GetLocalAccountAuthNLocalAccountAuthNObject()
    local ok, account_info = pcall(function ()
        if type(interface) == "number" then
            interface = tostring(iam_enum.LoginInterface.new(interface))
        end
        local ctx = context.new(interface, user_name, ip)
        return auth_obj:LocalAuthenticate(ctx, user_name, password, ext_config)
    end)

    -- 认证失败
    if not ok then
        iam_core.increment_pam_tally(user_name, user_config.PAM_TALLY_LOG_DIR)
        error(account_info)
    end
    local auth_type = account_info.AccountType
    -- 认证成功,重置失败锁定计数(仅针对本地用户)
    if auth_type == tostring(iam_enum.AccountType.Local) or auth_type == tostring(iam_enum.AccountType.OEM) then
        iam_core.reset_pam_tally(user_name, self.m_pam_tally_log_dir)
    end

    -- 有些number类型和table类型需要转换过来
    account_info.Id                 = tonumber(account_info.Id)
    account_info.RoleId             = tonumber(account_info.RoleId)
    account_info.LastLoginTime      = tonumber(account_info.LastLoginTime)
    account_info.current_privileges = cjson.decode(account_info.current_privileges)

    -- 返回结果
    return account_info
end

function Authentication:vnc_authenticate(ctx, cipher_text, auth_challenge)
    local vnc_account = self.m_account_cache:get_account_by_id(user_config.VNC_ACCOUNT_ID)
    local vnc_name = vnc_account.UserName
    if self:get_user_lock_state(vnc_name) then
        log:error('vnc account is locked.')
        error(custom_msg.AuthorizationUserLocked()) -- 如果是登录失败之后锁定的，则用"无效密码"模糊提示错误
    end
    local ctx_call = mc_utils.table_copy(ctx)
    ctx_call.operation_log = nil
    local auth_obj = client:GetLocalAccountAuthNLocalAccountAuthNObject()
    local ok, account_info = pcall(function ()
        return auth_obj:VncAuthenticate(ctx_call, cipher_text, auth_challenge)
    end)
    -- 认证失败
    if not ok then
        error(account_info)
    end
    account_info.Id                 = tonumber(account_info.Id)
    account_info.RoleId             = tonumber(account_info.RoleId)
    account_info.LastLoginTime      = tonumber(account_info.LastLoginTime)
    if account_info.current_privileges == 'null' then
        account_info.current_privileges = nil
    else
        account_info.current_privileges = cjson.decode(account_info.current_privileges)
    end

    return account_info
end

function Authentication:get_user_lock_state(user_name)
    local account_id = self.m_account_cache:get_account_by_name(user_name)
    if not account_id then
        log:notice("account %s is not in cache", user_name)
        return false
    end
    -- 获取系统锁定次数
    local auth_fail_max = self.m_auth_config:get_account_lockout_threshold()
    if auth_fail_max == 0 then
        return false
    end

    -- 获取系统锁定时间
    local auth_fail_lock_time = self.m_auth_config:get_account_lockout_duration()
    local fail_interval = self.m_auth_config:get_account_lockout_reset_time()
    local fail_time, fail_cnt = iam_core.get_pam_tally_with_fail_interval(user_name, self.m_pam_tally_log_dir,
        auth_fail_lock_time, fail_interval)
    local cur_time = os.time()
    local lock_state, _ = self.m_account_lock:get_account_lock_state(account_id)
    -- 如果当前状态为解锁,更新最后一次失败时间，锁定后不再更新
    if lock_state == iam_enum.UserLocked.USER_UNLOCK then
        self.m_account_lock:set_account_lock_state(account_id, iam_enum.UserLocked.USER_UNLOCK, fail_time)
    end
    local _, lock_start_time = self.m_account_lock:get_account_lock_state(account_id)
    -- 超时判断:本地时间- 锁定开始时间 与BMC保存的锁定时间比较
    if (cur_time - lock_start_time) <= auth_fail_lock_time then
        -- 在锁定时间内，且次数达到最大次数限制，锁定
        -- 对于已锁定的，只看时间是否达到解锁时间
        if fail_cnt >= auth_fail_max then
            return true
        end
    else
        -- 清除失败次数两种场景:
        -- 1、用户登录失败几次后，长时间(超过设定值)不再登录；
        -- 2、用户锁定后，账户自动解锁
        iam_core.reset_pam_tally(user_name, self.m_pam_tally_log_dir)
    end

    return false
end

function Authentication:foreach_check_user_lock_status()
    local skynet = require 'skynet'
    skynet.fork_loop({ count = 0 }, function()
        log:info('Start foreach check user lock status')
        while true do
            skynet.sleep(300)
            self:check_user_lock_status()
            self:check_ipmi_user_test_lock_states_task()
        end
    end)
end

function Authentication:check_user_lock_status()
    local is_locked
    local lock_state
    local state, lock_start_time
    for id, account in pairs(self.m_account_cache.cache_collection) do
        if account.AccountType == iam_enum.AccountType.Local or
            account.AccountType == iam_enum.AccountType.VNC then
            lock_state = self:get_user_lock_state(account.UserName)
            state, lock_start_time = self.m_account_lock:get_account_lock_state(id)
            is_locked = (state == iam_enum.UserLocked.USER_LOCK) and true or false
            if lock_state ~= is_locked then
                self.m_account_lock:set_account_lock_state(id, lock_state and iam_enum.UserLocked.USER_LOCK or
                    iam_enum.UserLocked.USER_UNLOCK, lock_start_time)
                -- 记录安全日志并上报系统事件
                log:security("User (%s) %s", account.UserName, lock_state and "locked" or "unlocked")
                event.set_account_lock_alarm(id, lock_state)
            end
        end
    end
end

function Authentication:disable_account_lock_alarm_on_restart()
    local lock_state
    for user_id, _ in pairs(self.m_account_cache.cache_collection) do
        lock_state, _ = self.m_account_lock:get_account_lock_state(user_id)
        if lock_state == iam_enum.UserLocked.USER_LOCK then
            event.set_account_lock_alarm(user_id, false)
        end
    end
end

local MAX_USER_NUM = 17
local MIN_USER_NUM = 2

-- 以下用户不需要进行测试密码相关操作
local NOT_TEST_ACCOUNT_ID = {
    [18] = '<vnc>',
    [20] = '<ro_community>',
    [21] = '<rw_community>',
    [22] = '<host sms>'
}

function Authentication:check_ipmi_user_test_lock_states_task()
    local skynet = require 'skynet'
    local account_collection = self.m_account_cache.cache_collection
    local status
    -- 继承v2, 加入微小延时防止CPU间歇性飚高，由于lua性能问题，延时至40ms
    for id, _ in pairs(account_collection) do
        for i = MIN_USER_NUM, MAX_USER_NUM do
            if NOT_TEST_ACCOUNT_ID[id] then
                break
            end
            if not account_collection[i] then
                self.m_account_lock:set_ipmi_test_password_lock_status(id, i, iam_enum.UserLocked.USER_UNLOCK)
            end
            status = self.m_account_lock:check_ipmi_user_test_state(id, i)
            self.m_account_lock:set_ipmi_test_password_lock_status(id, i, status)
            skynet.sleep(4)
        end
        skynet.sleep(4)
    end
end

function Authentication:mutual_auth_authentication(user_id, ip, interface)
    local account = self.m_account_cache:get_account_by_id(user_id)
    if not account then
        log:error("account(%d) not available", user_id)
        error(custom_msg.AuthorizationFailed())
    end
    local user_name = account.UserName

    local ext_config = {
        ["RecordLoginInfo"]  = true,
        ["UpdateActiveTime"] = true,
        ["IsAuthPassword"]   = false
    }

    -- 走 user 认证
    local auth_obj = client:GetLocalAccountAuthNLocalAccountAuthNObject()
    local ok, _ = pcall(function ()
        -- rackmount仓库进来的ctx接口为WEB，由于安全组件内枚举字符为Web，该处需要做适配转换
        interface = interface == "WEB" and "Web" or interface
        local ctx = context.new(interface, user_name, ip)
        return auth_obj:LocalAuthenticate(ctx, user_name, "", ext_config)
    end)

    -- 认证失败
    if not ok then
        error(custom_msg.AuthorizationFailed())
    end
end

function Authentication:set_account_lockout_threshold(threshold)
    local maxthreshold = self.m_auth_config:get_max_account_lockout_threshold()
    -- 锁定预置可以配置(默认6次)
    if threshold > maxthreshold or threshold < 0 then
        log:error('set_account_lockout_threshold failed, threshold(%d) is error, maxthreshold is (%d)',
        threshold, maxthreshold)
        error(custom_msg.PropertyValueOutOfRange(threshold, 'AccountLockoutThreshold'))
    end
    local old_threshold = self.m_auth_config:get_account_lockout_threshold()
    -- 清理不锁定时的日志记录
    if old_threshold == 0 or threshold == 0 then
        self.m_account_service:clean_all_user_lock_state()
    elseif old_threshold ~= threshold then
        self.m_account_service:clean_unlock_user_lock_state()
    end
    self:update_pam_faillock(nil, threshold, nil, 'AccountLockoutThreshold')
    self.m_auth_config:set_account_lockout_threshold(threshold)
end
function Authentication:set_max_account_lockout_threshold(threshold)
    local lockout_threshold = self.m_auth_config:get_account_lockout_threshold()
    -- 设置最大锁定时常6-255且要大于当前设置的最大锁定时间
    if threshold < 6 or threshold < lockout_threshold or threshold > 255 then
        log:error('set_max_account_lockout_threshold failed,maxthreshold(%d) is error, threshold is (%d)',
        threshold,lockout_threshold)
        error(custom_msg.PropertyValueOutOfRange(threshold, 'MaxAccountLockoutThreshold'))
    end
    self.m_auth_config:set_max_account_lockout_threshold(threshold)
end

function Authentication:set_account_lockout_duration(duration)
    local maxduration = self.m_auth_config:get_max_account_lockout_duration()
    -- 如果大于最大配置范围进行返回
    if duration > maxduration or duration < 60 or duration % 60 ~= 0 then
        log:error('set_account_lockout_duration failed, duration(%d) is error, maxduration is (%d)',
        duration, maxduration)
        error(custom_msg.PropertyValueOutOfRange(duration, 'AccountLockoutDuration'))
    end
    self:update_pam_faillock(duration, nil, nil, 'AccountLockoutDuration')
    self.m_auth_config:set_account_lockout_duration(duration)
end

function Authentication:set_max_account_lockout_duration(duration)
    local lockout_duration = self.m_auth_config:get_account_lockout_duration()
    -- 锁定时间范围配置最短30分钟,最长1440分钟
    if duration < lockout_duration or duration < 1800 or duration > 86400 or duration % 60 ~= 0   then
        log:error('set_max_account_lockout_duration failed,maxduration(%d) is error, duration is (%d)',
        duration, lockout_duration)
        error(custom_msg.PropertyValueOutOfRange(duration, 'MaxAccountLockoutDuration'))
    end
    self.m_auth_config:set_max_account_lockout_duration(duration)
end

function Authentication:set_account_lockout_reset_time(reset_time)
    local duration = self.m_auth_config:get_account_lockout_duration()
    -- 锁定时间最长1800秒，最短0秒，且不大于AccountLockoutDuration
    if reset_time > 1800 or reset_time < 0 or reset_time > duration then
        log:error('set_account_lockout_reset_time failed, reset_time(%d) is error', reset_time)
        error(custom_msg.PropertyValueOutOfRange(reset_time, 'AccountLockoutCounterResetAfter'))
    end
    self:update_pam_faillock(nil, nil, reset_time, 'AccountLockoutCounterResetAfter')
    self.m_auth_config:set_account_lockout_reset_time(reset_time)
end

function Authentication:update_pam_faillock(duration, threshold, reset_time, prop_name)
    local ok, err = pcall(function()
        return self.m_auth_config:update_pam_faillock(duration, threshold, reset_time)
    end)

    if not ok then
        log:error("set %s failed, %s", prop_name, err)
        error(base_msg.InternalError())
    end
end

local AUTH_MODE_LIST = {
    ['Disabled']   = false,
    ['Enabled']    = true,
    ['Fallback']   = true,
    ['LocalFirst'] = true
}

function Authentication:set_auth_mode(mode)
    if not AUTH_MODE_LIST[mode] then
        error(base_msg.PropertyValueNotInList(mode, 'LocalAccountAuth'))
    end
    self.m_auth_config:set_auth_mode(mode)
end

return singleton(Authentication)