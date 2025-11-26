-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local base_msg = require 'messages.base'
local file_utils = require 'utils.file'
local config = require 'user_config'
local custom_msg = require 'messages.custom'

local PAM_FILE_CONTENT = "#%%PAM-1.0\n" ..
    "auth        [default=die]       pam_faillock.so  authfail audit deny=%u fail_interval=%u " ..
    "unlock_time=%u even_deny_root root_unlock_time=%u\n" ..
    "auth        required         pam_faillock.so  authsucc audit deny=%u fail_interval=%u " ..
    "unlock_time=%u even_deny_root root_unlock_time=%u\n"

local PAM_PRE_CONTENT = "#%%PAM-1.0\n" ..
    "auth        requisite       pam_faillock.so  preauth silent deny=%u fail_interval=%u " ..
    "unlock_time=%u even_deny_root root_unlock_time=%u"

local function check_pam_file_content(threshold, reset_time, unlock_time)
    local file = file_utils.open_s(config.PAM_FAILLOCK, 'r')
    local content = file:read('*a')
    file:close()
    lu.assertEquals(content, string.format(PAM_FILE_CONTENT,
        threshold, reset_time, unlock_time, unlock_time,
        threshold, reset_time, unlock_time, unlock_time))

    file = file_utils.open_s(config.PAM_FAILLOCK_PRE, 'r')
    content = file:read('*a')
    file:close()
    lu.assertEquals(content, string.format(PAM_PRE_CONTENT,
        threshold, reset_time, unlock_time, unlock_time))
end

function TestIam:test_set_lockout_duration_success()
    -- 1、获取默认值
    local duration = self.authentication_config:get_account_lockout_duration()
    local threshold = self.authentication_config:get_account_lockout_threshold()
    local reset_time = self.authentication_config:get_account_lockout_reset_time()

    -- 2、设置正常值（包括边界值）
    -- 2.1、最小值60
    self.test_authentication:set_account_lockout_duration(60)
    lu.assertEquals(self.authentication_config:get_account_lockout_duration(), 60)
    -- 检查pam文件刷新
    check_pam_file_content(threshold, reset_time, 60)

    -- 2.2、最大值1800
    self.test_authentication:set_account_lockout_duration(1800)
    lu.assertEquals(self.authentication_config:get_account_lockout_duration(), 1800)
    -- 检查pam文件刷新
    check_pam_file_content(threshold, reset_time, 1800)

    -- 3、恢复默认值
    self.test_authentication:set_account_lockout_duration(duration)
end

function TestIam:test_set_max_lockout_duration_success()
    -- 1、获取默认值
    local max_duration = self.authentication_config:get_max_account_lockout_duration()
    local duration = self.authentication_config:get_account_lockout_duration();
    -- 2、设置正常值（包括边界值）
    -- 2.1、设置两边的临界值
    self.test_authentication:set_max_account_lockout_duration(1800)
    lu.assertEquals(self.authentication_config:get_max_account_lockout_duration(), 1800)
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_duration(86400)
    end)
    self.test_authentication:set_max_account_lockout_duration(86400)
    lu.assertEquals(self.authentication_config:get_max_account_lockout_duration(), 86400)
    -- 2.2、测试能否让失败登录时间延长
    self.test_authentication:set_account_lockout_duration(86400)
    lu.assertEquals(self.authentication_config:get_account_lockout_duration(), 86400)
    -- 3、恢复默认值
    self.test_authentication:set_account_lockout_duration(duration)
    self.test_authentication:set_max_account_lockout_duration(max_duration)
end

function TestIam:test_set_max_lockout_duration_should_fail()
    -- 1、最小值1800
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_max_account_lockout_duration(1799)
    end)

    -- 2、设置大于最大值的值86401
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_max_account_lockout_duration(86401)
    end)

    -- 3、设置范围内不可被60整除的值61
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_max_account_lockout_duration(1801)
    end)
end


function TestIam:test_set_invalid_lockout_duration_should_fail()
    -- 1、设置小于最小值60的值59
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_duration(59)
    end)

    -- 2、设置大于最大值1800的值1801
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_duration(1801)
    end)

    -- 3、设置范围内不可被60整除的值61
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_duration(61)
    end)
end

function TestIam:test_set_lockout_threshold_success()
    -- 1、获取默认值
    local duration = self.authentication_config:get_account_lockout_duration()
    local threshold = self.authentication_config:get_account_lockout_threshold()
    local reset_time = self.authentication_config:get_account_lockout_reset_time()

    -- 2、设置正常值（包括边界值）
    -- 2.1、最小值0
    self.test_authentication:set_account_lockout_threshold(0)
    lu.assertEquals(self.authentication_config:get_account_lockout_threshold(), 0)
    -- 检查pam文件刷新
    check_pam_file_content(0, reset_time, duration)

    -- 2.2、最大值6
    self.test_authentication:set_account_lockout_threshold(6)
    lu.assertEquals(self.authentication_config:get_account_lockout_threshold(), 6)
    -- 检查pam文件刷新
    check_pam_file_content(6, reset_time, duration)

    -- 3、恢复默认值
    self.test_authentication:set_account_lockout_threshold(threshold)
end

function TestIam:test_set_max_lockout_threshold_success()
    -- 1、获取默认值
    local max_threshold = self.authentication_config:get_max_account_lockout_threshold()
    local threshold = self.authentication_config:get_account_lockout_threshold()
    -- 2.1、最大值255
    self.test_authentication:set_max_account_lockout_threshold(255)
    lu.assertEquals(self.authentication_config:get_max_account_lockout_threshold(), 255)
    self.test_authentication:set_account_lockout_threshold(255)
    lu.assertEquals(self.authentication_config:get_account_lockout_threshold(), 255)
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_threshold(256)
    end)
    self.test_authentication:set_account_lockout_threshold(threshold)
    self.test_authentication:set_max_account_lockout_threshold(max_threshold)
    
end

function TestIam:test_set_max_lockout_threshold_fail()
    -- 1、设置大于最大值
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_max_account_lockout_threshold(256)
    end)
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_max_account_lockout_threshold(4)
    end)
end

function TestIam:test_set_invalid_lockout_threshold_should_fail()
    -- 1、设置小于最小值0的值(-1)
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_threshold(-1)
    end)

    -- 2、设置大于最大值6的值7
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_threshold(7)
    end)
end

function TestIam:test_set_lockout_reset_time_success()
    -- 1、获取默认值
    local duration = self.authentication_config:get_account_lockout_duration()
    local threshold = self.authentication_config:get_account_lockout_threshold()
    local reset_time = self.authentication_config:get_account_lockout_reset_time()

    -- 2、设置正常值（包括边界值）
    -- 2.1、最小值0
    self.test_authentication:set_account_lockout_reset_time(0)
    lu.assertEquals(self.authentication_config:get_account_lockout_reset_time(), 0)
    -- 检查pam文件刷新
    check_pam_file_content(threshold, 0, duration)

    -- 2.2、最大值1800（由于限制，需要先将duration也设为1800）
    self.test_authentication:set_account_lockout_duration(1800)
    lu.assertEquals(self.authentication_config:get_account_lockout_duration(), 1800)
    self.test_authentication:set_account_lockout_reset_time(1800)
    lu.assertEquals(self.authentication_config:get_account_lockout_reset_time(), 1800)
    -- 检查pam文件刷新
    check_pam_file_content(threshold, 1800, 1800)

    -- 2.3、在duration为1800的情况下，reset_time可设置数据范围内的任意值,
    self.test_authentication:set_account_lockout_reset_time(1111)
    lu.assertEquals(self.authentication_config:get_account_lockout_reset_time(), 1111)
    -- 检查pam文件刷新
    check_pam_file_content(threshold, 1111, 1800)

    -- 3、恢复默认值
    self.test_authentication:set_account_lockout_duration(duration)
    self.test_authentication:set_account_lockout_reset_time(reset_time)
end

function TestIam:test_set_invalid_lockout_reset_time_should_fail()
    -- 1、设置小于最小值0的值(-1)
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_reset_time(-1)
    end)

    -- 2、设置大于最大值1800的值1801
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_threshold(1801)
    end)
    -- 3、设置大于duration的值（先设置duration为指定值600）
    local duration = self.authentication_config:get_account_lockout_duration()
    self.test_authentication:set_account_lockout_duration(600)
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        self.test_authentication:set_account_lockout_threshold(601)
    end)

    -- 4、恢复默认值
    self.test_authentication:set_account_lockout_duration(duration)
end

function TestIam:test_set_authentication_mode_success()
    -- 1、获取默认值
    local auth_mode = self.authentication_config:get_auth_mode()
    -- 2、设置有效的模式
    local auth_model_list = {'Enabled', 'Fallback', 'LocalFirst'}
    for _, mode in pairs(auth_model_list) do
        self.test_authentication:set_auth_mode(mode)
        lu.assertEquals(self.authentication_config:get_auth_mode(), mode)
    end
    -- 3、恢复默认值
    self.test_authentication:set_auth_mode(auth_mode)
end

function TestIam:test_set_invalid_authentication_mode_should_fail()
    -- 1、设置无效的模式
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_authentication:set_auth_mode('Test')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_authentication:set_auth_mode('haha')
    end)

    -- 2、独立验证，设置标准内暂不开放的模式 Disabled
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_authentication:set_auth_mode('Disabled')
    end)
end