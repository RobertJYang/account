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
local class = require 'mc.class'
local log = require 'mc.logging'
local vos = require 'utils.vos'
local iam_enum = require 'class.types.types'
local authentication_config = require 'domain.authentication_config'
local account_cache = require 'domain.cache.account_cache'
local event = require 'utils.event'

local MAX_USER_NUM = 17

local AccountLock = class()
function AccountLock:ctor()
    self.m_auth_config = authentication_config.get_instance()
    self.m_account_cache = account_cache.get_instance()
    self.m_cache_collection = self.m_account_cache.cache_collection
    self.m_ipmi_test_passwd_lock = {}
    self.m_account_lock_state = {}
end

local function get_ipmi_test_pwd_lock_record(self, auth_account_id, account_id)
    local auth_account_record = self.m_ipmi_test_passwd_lock[auth_account_id]
    if auth_account_record == nil then
        return iam_enum.UserLocked.USER_UNLOCK, 0, 0
    end

    local test_record = auth_account_record[account_id]
    if test_record == nil then
        return iam_enum.UserLocked.USER_UNLOCK, 0, 0
    end

    return test_record.last_lock_flag or iam_enum.UserLocked.USER_UNLOCK,test_record.test_fail_cnt or 0,
        test_record.last_fail_time or 0
end

local function set_ipmi_test_pwd_lock_record(self, auth_account_id, account_id, last_lock_flag, test_fail_cnt,
        last_fail_time)
    if self.m_ipmi_test_passwd_lock[auth_account_id] == nil then
        self.m_ipmi_test_passwd_lock[auth_account_id] = {}
    end
    local auth_account_record = self.m_ipmi_test_passwd_lock[auth_account_id]

    if auth_account_record[account_id] == nil then
        auth_account_record[account_id] = {}
    end
    local test_record = auth_account_record[account_id]

    if last_lock_flag ~= nil then
        test_record.last_lock_flag = last_lock_flag
    end

    if test_fail_cnt ~= nil then
        test_record.test_fail_cnt = test_fail_cnt
    end

    if last_fail_time ~= nil then
        test_record.last_fail_time = last_fail_time
    end
end

function AccountLock:get_account_lock_state(account_id)
    if self.m_account_lock_state[account_id] == nil then
        return iam_enum.UserLocked.USER_UNLOCK, 0
    end

    return self.m_account_lock_state[account_id].state, self.m_account_lock_state[account_id].lock_start_time
end

function AccountLock:set_account_lock_state(account_id, state, lock_start_time)
    if self.m_account_lock_state[account_id] == nil then
        self.m_account_lock_state[account_id] = {}
    end

    self.m_account_lock_state[account_id].state = state
    self.m_account_lock_state[account_id].lock_start_time = lock_start_time
end

function AccountLock:remove_lock_state(account_id)
    if self.m_account_lock_state[account_id] then
        self.m_account_lock_state[account_id] = nil
        event.set_account_lock_alarm(account_id, false)
    end
end

function AccountLock:check_ipmi_user_test_state(auth_account_id, account_id)
    local current_timestamp = vos.vos_get_cur_time_stamp()
    local account_lock_duration = self.m_auth_config:get_account_lockout_duration()
    local account_lock_threshold = self.m_auth_config:get_account_lockout_threshold()
    if account_lock_threshold == 0 then
        return iam_enum.UserLocked.USER_UNLOCK
    end

    local _, test_fail_cnt, last_fail_time = get_ipmi_test_pwd_lock_record(self, auth_account_id, account_id)
    if current_timestamp - last_fail_time < account_lock_duration then
        if test_fail_cnt >= account_lock_threshold then
            return iam_enum.UserLocked.USER_LOCK
        end
    else
        set_ipmi_test_pwd_lock_record(self, auth_account_id, account_id, nil, 0, nil)
    end

    local account_lock_state = self:get_account_lock_state(account_id)
    if account_lock_state == iam_enum.UserLocked.USER_LOCK then
        return iam_enum.UserLocked.USER_LOCK
    end
    return iam_enum.UserLocked.USER_UNLOCK
end

function AccountLock:test_password_fail_cnt_increase(auth_account_id, account_id)
    local current_timestamp = vos.vos_get_cur_time_stamp()
    local _, test_fail_cnt, _ = get_ipmi_test_pwd_lock_record(self, auth_account_id, account_id)
    set_ipmi_test_pwd_lock_record(self, auth_account_id, account_id, nil, test_fail_cnt + 1, current_timestamp)
end

function AccountLock:set_ipmi_test_password_lock_status(auth_account_id, account_id, status)
    if status ~= iam_enum.UserLocked.USER_UNLOCK and status ~= iam_enum.UserLocked.USER_LOCK then
        log:error('the status to set ipmi test passwd is wrong')
        return
    end

    local auth_account_info = self.m_account_cache:get_account_by_id(auth_account_id)
    local account_info = self.m_account_cache:get_account_by_id(account_id)

    -- 不需要判断用户是否存在，用户删除后m_ipmi_test_passwd_lock中对应项也直接删除
    if not auth_account_info then
        return
    end

    local last_lock_flag, _, _ = get_ipmi_test_pwd_lock_record(self, auth_account_id, account_id)

    if last_lock_flag == status then
        return
    end

    set_ipmi_test_pwd_lock_record(self, auth_account_id, account_id, status, nil, nil)

    if account_info == nil then
        return
    end

    local account_name = account_info.UserName
    if auth_account_id >= 2 and auth_account_id <= 17 then
        local auth_account_name = auth_account_info.UserName
        log:security("The operation for user(%s) to test the password of user(%s) is %s.", auth_account_name,
            account_name, status == iam_enum.UserLocked.USER_UNLOCK and "unlocked" or "locked")
    else
        log:security("The operation to test the password of user(%s) is %s.", account_name,
            status == iam_enum.UserLocked.USER_UNLOCK and "unlocked" or "locked")
    end
end

function AccountLock:clean_account_all_ipmi_test_password_failures(auth_account_id)
    for i = 2, MAX_USER_NUM do
        set_ipmi_test_pwd_lock_record(self, auth_account_id, i, nil, 0, nil)
    end
end

function AccountLock:clean_specific_ipmi_test_password_failures(auth_account_id, account_id)
    set_ipmi_test_pwd_lock_record(self, auth_account_id, account_id, nil, 0, nil)
end

function AccountLock:clean_account_unlock_ipmi_test_password_failures(auth_account_id)
    local last_lock_flag
    for i = 2, MAX_USER_NUM do
        last_lock_flag, _, _ = get_ipmi_test_pwd_lock_record(self, auth_account_id, i)
        if last_lock_flag == iam_enum.UserLocked.USER_UNLOCK then
            set_ipmi_test_pwd_lock_record(self, auth_account_id, i, nil, 0, nil)
        end
    end
end

return singleton(AccountLock)