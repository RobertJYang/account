-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local login_time_rule = require 'domain.login_rule.login_time_rule'
local utils = require 'mc.utils'
local base_msg = require 'messages.base'

--- 当TIME规则不符合格式要求时，创建TIME规则实例失败
function TestAccount:test_when_ymdhm_time_rule_is_not_match_format_should_new_instance_fail()
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-01-04 16:00:00/2023-01-04 17:00:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023/01/04 16:00/2023/01/04 17:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023.01.04 16:00/2023.01.04 17:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-01-04 16:00/2023-01-04 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '1969-12-31 16:00/2023-01-04 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-01-04 16:00/2051-01-01 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-01-04 16:00/2023-02-29 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-01-04 16:00/2024-02-30 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-13-04 16:00/2024-02-29 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-11-04 16:00/2024-02-29 16:00/')
    end)
end

--- 当TIME规则不符合格式要求时，创建TIME规则实例失败
function TestAccount:test_when_ymd_time_rule_is_not_match_format_should_new_instance_fail()
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-01-04/2023-01-04')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023.01.04/2023.01.05')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '1969-12-31/2023-01-04')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-01-04/2051-01-01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-01-04/2023-02-29')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-01-04/2024-02-30')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '2023-00-04/2024-02-28')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
    login_time_rule.new(nil, '2023-01-04/2024-02-28/')
    end)
end

--- 当TIME规则不符合格式要求时，创建TIME规则实例失败
function TestAccount:test_when_hm_time_rule_is_not_match_format_should_new_instance_fail()
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '16:00:00/17:00:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '16.00/17.00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '16:00/16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '25:00/16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '16:00/16:61')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '16:00 16:01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        login_time_rule.new(nil, '16:00/16:50/')
    end)
end

--- 当TIME规则不符合格式要求时，设置规则失败
function TestAccount:test_when_set_yhdhm_rule_is_not_match_format_should_set_fail()
    local test_time_rule = login_time_rule.new(nil, nil)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-01-04 16:00:00/2023-01-04 17:00:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023/01/04 16:00/2023/01/04 17:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023.01.04 16:00/2023.01.04 17:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-01-04 16:00/2023-01-04 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('1969-12-31 16:00/2023-01-04 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-01-04 16:00/2051-01-01 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-01-04 16:00/2023-02-29 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-01-04 16:00/2024-02-30 16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-13-04 16:00/2024-02-29 16:00')
    end)
end

--- 当TIME规则不符合格式要求时，设置规则失败
function TestAccount:test_when_set_yhd_rule_is_not_match_format_should_set_fail()
    local test_time_rule = login_time_rule.new(nil, nil)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-01-04/2023-01-04')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023.01.04/2023.01.05')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('1969-12-31/2023-01-04')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-01-04/2051-01-01')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-01-04/2023-02-29')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-01-04/2024-02-30')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('2023-00-04/2024-02-30')
    end)
end

--- 当TIME规则不符合格式要求时，设置规则失败
function TestAccount:test_when_set_hm_rule_is_not_match_format_should_set_fail()
    local test_time_rule = login_time_rule.new(nil, nil)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('16:00:00/17:00:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('16.00/17.00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('16:00/16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('25:00/16:00')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('16:00/16:61')
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueFormatErrorMessage.Name, function()
        test_time_rule:set_rule('16:00 16:01')
    end)
end

-- 当设置TIME规则为YMDHM格式时，rule_type属性应设为YMDHM
function TestAccount:test_when_set_rule_is_ymdhm_format_should_get_rule_type_ymdhm()
    local test_time_rule = login_time_rule.new(nil, '2023-01-04 16:00/2023-01-04 17:00')
    lu.assertEquals(test_time_rule.m_rule_type, 'YMDHM')
end

-- 当设置TIME规则为YMD格式时，rule_type属性应设为YMD
function TestAccount:test_when_set_rule_is_ymd_format_should_get_rule_type_ymd()
    local test_time_rule = login_time_rule.new(nil, '2023-01-04/2023-01-05')
    lu.assertEquals(test_time_rule.m_rule_type, 'YMD')
end

-- 当设置TIME规则为HM格式时，rule_type属性应设为HM
function TestAccount:test_when_set_rule_is_hm_format_should_get_rule_type_hm()
    local test_time_rule = login_time_rule.new(nil, '16:00/17:00')
    lu.assertEquals(test_time_rule.m_rule_type, 'HM')
end

--- 当TIME规则为null时，应该校验成功
function TestAccount:test_when_time_rule_is_null_should_check_success()
    local test_time_rule = login_time_rule.new(nil, nil)
    local result = test_time_rule:check_rule()
    lu.assertEquals(result, true)
end

--- 当TIME规则为空串时，应该校验成功
function TestAccount:test_when_time_rule_is_empty_string_should_check_success()
    local test_time_rule = login_time_rule.new(nil, '')
    local result = test_time_rule:check_rule()
    lu.assertEquals(result, true)
end

-- 当设置TIME规则为YMDHM格式时，当前时间 < 规则开始时间，校验失败
function TestAccount:test_when_ymdhm_rule_start_time_is_after_now_should_check_fail()
    local current_time = os.date('%Y-%m-%d %H:%M', os.time())
    local current_time_info = login_time_rule.convert_time_str(current_time, 'YMDHM')
    local start_time_info = utils.table_copy(current_time_info)
    start_time_info.min = current_time_info.min + 1
    local start_time = os.date('%Y-%m-%d %H:%M', os.time(start_time_info))

    local end_time_info = utils.table_copy(current_time_info)
    end_time_info.min = current_time_info.min + 2
    local end_time = os.date('%Y-%m-%d %H:%M', os.time(end_time_info))

    local test_time_rule = login_time_rule.new(nil, start_time .. '/' .. end_time)

    local result = test_time_rule:check_rule()
    lu.assertEquals(result, false)
end

-- 当设置TIME规则为YMDHM格式时，当前时间 > 规则结束时间，校验失败
function TestAccount:test_when_ymdhm_rule_end_time_is_befor_now_should_check_fail()
    local current_time = os.date('%Y-%m-%d %H:%M', os.time())
    local current_time_info = login_time_rule.convert_time_str(current_time, 'YMDHM')
    local start_time_info = utils.table_copy(current_time_info)
    if current_time_info.min < 2 then
        start_time_info.min = 60 + current_time_info.min - 2
        start_time_info.hour = current_time_info.hour - 1
    else
        start_time_info.min = current_time_info.min - 2
    end
    local start_time = os.date('%Y-%m-%d %H:%M', os.time(start_time_info))

    local end_time_info = utils.table_copy(current_time_info)
    if current_time_info.min < 1 then
        end_time_info.min = 60 + current_time_info.min - 1
        end_time_info.hour = current_time_info.hour - 1
    else
        end_time_info.min = current_time_info.min - 1
    end
    local end_time = os.date('%Y-%m-%d %H:%M', os.time(end_time_info))

    local test_time_rule = login_time_rule.new(nil, start_time .. '/' .. end_time)

    local result = test_time_rule:check_rule()
    lu.assertEquals(result, false)
end

-- 当设置TIME规则为YMD格式时，当前时间 < 规则开始时间，校验失败
function TestAccount:test_when_ymd_rule_start_time_is_after_now_should_check_fail()
    local current_time = os.date('%Y-%m-%d', os.time())
    local current_time_info = login_time_rule.convert_time_str(current_time, 'YMD')
    local start_time_info = utils.table_copy(current_time_info)
    start_time_info.day = current_time_info.day + 1
    local start_time = os.date('%Y-%m-%d', os.time(start_time_info))

    local end_time_info = utils.table_copy(current_time_info)
    end_time_info.day = current_time_info.day + 2
    local end_time = os.date('%Y-%m-%d', os.time(end_time_info))

    local test_time_rule = login_time_rule.new(nil, start_time .. '/' .. end_time)

    local result = test_time_rule:check_rule()
    lu.assertEquals(result, false)
end

-- 当设置TIME规则为YMD格式时，当前时间 > 规则结束时间，校验失败
function TestAccount:test_when_ymd_rule_end_time_is_befor_now_should_check_fail()
    local current_time = os.date('%Y-%m-%d', os.time())
    local current_time_info = login_time_rule.convert_time_str(current_time, 'YMD')
    local start_time_info = utils.table_copy(current_time_info)
    start_time_info.day = current_time_info.day - 2
    local start_time = os.date('%Y-%m-%d', os.time(start_time_info))

    local end_time_info = utils.table_copy(current_time_info)
    end_time_info.day = current_time_info.day - 1
    local end_time = os.date('%Y-%m-%d', os.time(end_time_info))

    local test_time_rule = login_time_rule.new(nil, start_time .. '/' .. end_time)

    local result = test_time_rule:check_rule()
    lu.assertEquals(result, false)
end

-- 当设置TIME规则为HM格式时，规则开始时间 < 规则结束时间，当前时间 < 规则开始时间，校验失败
function TestAccount:test_when_hm_rule_start_time_is_after_end_time_and_now_should_check_fail()
    local start_time = os.date('%H:%M', os.time() + 60)  -- 晚60秒
    local end_time = os.date('%H:%M', os.time() + 120)   -- 晚120秒
    local test_time_rule = login_time_rule.new(nil, start_time .. '/' .. end_time)
    local result = test_time_rule:check_rule()
    lu.assertEquals(result, false)
end

-- 当设置TIME规则为HM格式时，规则开始时间 < 规则结束时间，当前时间 > 规则结束时间，校验失败
function TestAccount:test_when_hm_rule_end_time_is_after_start_time_and_befor_now_should_check_fail()
    local current_time = os.date('%H:%M', os.time())
    local current_time_info = login_time_rule.convert_time_str(current_time, 'HM')
    local start_time_info = utils.table_copy(current_time_info)
    if current_time_info.min < 2 then
        start_time_info.min = 60 + current_time_info.min - 2
        start_time_info.hour = current_time_info.hour - 1
    else
        start_time_info.min = current_time_info.min - 2
    end
    local start_time = string.format('%02d:%02d', start_time_info.hour, start_time_info.min)

    local end_time_info = utils.table_copy(current_time_info)
    if current_time_info.min < 1 then
        end_time_info.min = 60 + current_time_info.min - 1
        end_time_info.hour = current_time_info.hour - 1
    else
        end_time_info.min = current_time_info.min - 1
    end
    local end_time = string.format('%02d:%02d', end_time_info.hour, end_time_info.min)

    local test_time_rule = login_time_rule.new(nil, start_time .. '/' .. end_time)
    local result = test_time_rule:check_rule()
    lu.assertEquals(result, false)
end
