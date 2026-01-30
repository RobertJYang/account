-- Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
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
local signal = require 'mc.signal'
local class = require 'mc.class'
local mc_utils = require 'mc.utils'
local utils_core = require 'utils.core'
local config = require 'user_config'
local flash_sync = require 'infrastructure.flash_synchronizer'


local authentication_config = class()

function authentication_config:ctor(db)
    self.m_db_auth = db:select(db.Authentication):first()
    self.m_config_added = signal.new()
    self.m_config_changed = signal.new()
end

function authentication_config:set_account_lockout_duration(duration)
    self.m_db_auth.AccountLockoutDuration = duration
    self.m_db_auth:save()
end

function authentication_config:get_account_lockout_duration()
    return self.m_db_auth.AccountLockoutDuration
end

function authentication_config:set_max_account_lockout_duration(duration)
    self.m_db_auth.MaxAccountLockoutDuration = duration
    self.m_db_auth:save()
end

function authentication_config:get_max_account_lockout_duration()
    return self.m_db_auth.MaxAccountLockoutDuration
end

function authentication_config:set_account_lockout_threshold(threshold)
    self.m_db_auth.AccountLockoutThreshold = threshold
    self.m_db_auth:save()
end

function authentication_config:get_account_lockout_threshold()
    return self.m_db_auth.AccountLockoutThreshold
end

function authentication_config:set_max_account_lockout_threshold(threshold)
    self.m_db_auth.MaxAccountLockoutThreshold = threshold
    self.m_db_auth:save()
end

function authentication_config:get_max_account_lockout_threshold()
    return self.m_db_auth.MaxAccountLockoutThreshold
end

function authentication_config:set_account_lockout_reset_time(reset_time)
    self.m_db_auth.AccountLockoutCounterResetAfter = reset_time
    self.m_db_auth:save()
end

function authentication_config:get_account_lockout_reset_time()
    return self.m_db_auth.AccountLockoutCounterResetAfter
end

function authentication_config:set_auth_mode(mode)
    self.m_db_auth.LocalAccountAuth = mode
    self.m_db_auth:save()
end

function authentication_config:get_auth_mode()
    return self.m_db_auth.LocalAccountAuth
end

function authentication_config:get_auth_lock_config()
    return self.m_db_auth.AccountLockoutDuration,
        self.m_db_auth.AccountLockoutThreshold,
        self.m_db_auth.AccountLockoutCounterResetAfter
end

function authentication_config:update_pam_faillock(duration, threshold, reset_time)
    duration  = duration    or self.m_db_auth.AccountLockoutDuration
    threshold  = threshold  or self.m_db_auth.AccountLockoutThreshold
    reset_time = reset_time or self.m_db_auth.AccountLockoutCounterResetAfter

    local data = string.format("#%%PAM-1.0\n" ..
    "auth        [default=die]       pam_faillock.so  authfail audit deny=%u fail_interval=%u " ..
    "unlock_time=%u even_deny_root root_unlock_time=%u\n" ..
    "auth        required         pam_faillock.so  authsucc audit deny=%u fail_interval=%u " ..
    "unlock_time=%u even_deny_root root_unlock_time=%u\n",
    threshold, reset_time, duration, duration,
    threshold, reset_time, duration, duration)
    flash_sync.write_flash_with_content(config.PAM_FAILLOCK, config.TEMP_PAM_FAILLOCK, data)
    utils_core.chmod_s(config.PAM_FAILLOCK, mc_utils.S_IRUSR | mc_utils.S_IWUSR | mc_utils.S_IRGRP | mc_utils.S_IROTH)

    data = string.format("#%%PAM-1.0\n" ..
        "auth        requisite       pam_faillock.so  preauth silent deny=%u fail_interval=%u " ..
        "unlock_time=%u even_deny_root root_unlock_time=%u",
        threshold, reset_time, duration, duration)
    flash_sync.write_flash_with_content(config.PAM_FAILLOCK_PRE, config.TEMP_PAM_FAILLOCK_PRE, data)
    utils_core.chmod_s(config.PAM_FAILLOCK_PRE,
        mc_utils.S_IRUSR | mc_utils.S_IWUSR | mc_utils.S_IRGRP | mc_utils.S_IROTH)
end

return singleton(authentication_config)