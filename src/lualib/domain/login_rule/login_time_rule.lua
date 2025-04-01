-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local log = require 'mc.logging'
local base_msg = require 'messages.base'

local time_rule = class()

function time_rule:ctor(bus, rule)
    if not time_rule.check_format(rule) then
        log:error('The rule does not meet the format requirements')
        error(base_msg.PropertyValueFormatError(rule, 'StartTime/EndTime'))
    end

    self.m_bus = bus
    self.m_rule = rule -- 规则内容
    self.m_rule_type = time_rule.get_format_type(rule) -- 规则子类型：每种规则都支持多种格式
end

-- TIME规则格式映射表
time_rule.rule_format_type_map = {
    YMDHM = {
        regexp = '(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)',
        check_format = function(...) return time_rule.check_format_ymdhm(...) end,
        check_rule = function(...) return time_rule.check_rule_ymdhm(...) end
    },
    YMD = {
        regexp = '(%d%d%d%d)%-(%d%d)%-(%d%d)',
        check_format = function(...) return time_rule.check_format_ymd(...) end,
        check_rule = function(...) return time_rule.check_rule_ymd(...) end
    },
    HM = {
        regexp = '(%d%d):(%d%d)',
        check_format = function(...) return time_rule.check_format_hm(...) end,
        check_rule = function(...) return time_rule.check_rule_hm(...) end
    }
}

--- 设置规则
---@param rule string 规则
---@return string 规则
function time_rule:set_rule(rule)
    if not time_rule.check_format(rule) then
        log:error('The rule does not meet the format requirements')
        error(base_msg.PropertyValueFormatError(rule, 'StartTime/EndTime'))
    end

    self.m_rule = rule
    self.m_rule_type = time_rule.get_format_type(rule)
end

--- 校验规则函数
---@return boolean 校验规则是否通过
function time_rule:check_rule()
    -- 字符串长度为0不校验
    if (not self.m_rule) or string.len(self.m_rule) == 0 then
        return true
    end

    return time_rule.rule_format_type_map[self.m_rule_type].check_rule(self.m_rule)
end

--- 检查时间规则合法性，格式如下：
--- YYYY-MM-DD HH:MM/YYYY-MM-DD HH:MM  len = 33
--- YYYY-MM-DD/YYYY-MM-DD              len = 21
--- HH:MM/HH:MM                        len = 11
---@param rule string 规则
---@return boolean 时间规则是否合法
function time_rule.check_format(rule)
    -- 字符串长度为0不校验
    if (not rule) or string.len(rule) == 0 then
        return true
    end
    -- TIME规则最长33个字符
    if string.len(rule) > 33 then
        return false
    end

    local format_type = time_rule.get_format_type(rule)
    if not format_type then
        return false
    end

    return time_rule.rule_format_type_map[format_type].check_format(rule)
end

--- 获取规则格式类型
---@param rule string
---@return string 规则格式类型
function time_rule.get_format_type(rule)
    -- 字符串长度为0不校验
    if (not rule) or string.len(rule) == 0 then
        return nil
    end

    local start_time, end_time = string.match(rule, '(.+)/(.+)')
    if not start_time or not end_time then
        return nil
    end

    if string.match(start_time, '^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d$') and
        string.match(end_time, '^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d$') then
        return 'YMDHM'
    elseif string.match(start_time, '^%d%d%d%d%-%d%d%-%d%d$') and
        string.match(end_time, '^%d%d%d%d%-%d%d%-%d%d$') then
        return 'YMD'
    elseif string.match(start_time, '^%d%d:%d%d$') and string.match(end_time, '^%d%d:%d%d$') then
        return 'HM'
    end

    return nil
end

--- 通过时间规则获取时间信息
---@param rule string
---@param format_type string
---@return table 开始时间信息
---@return table 结束时间信息
function time_rule.get_time_info(rule, format_type)
    local start_time, end_time = string.match(rule, '(.+)/(.+)')

    local start_time_info = time_rule.convert_time_str(start_time, format_type)
    local end_time_info = time_rule.convert_time_str(end_time, format_type)

    return start_time_info, end_time_info
end

--- 将字符串格式时间转换为时间信息
---@param time_str string
---@param format_type string
---@return table 时间信息
function time_rule.convert_time_str(time_str, format_type)
    if format_type == 'HM' then
        local hour, min =
            string.match(time_str, time_rule.rule_format_type_map[format_type].regexp)
        return { hour = tonumber(hour), min = tonumber(min) }
    end

    local year, month, day, hour, min =
        string.match(time_str, time_rule.rule_format_type_map[format_type].regexp)
    return {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
    }
end

--- 校验YMDHM格式时间规则格式
---@param rule string
---@return boolean 校验YMDHM规则格式是否通过
function time_rule.check_format_ymdhm(rule)
    local start_time_info, end_time_info = time_rule.get_time_info(rule, 'YMDHM')

    if not (
        time_rule.is_valid_date(start_time_info.year, start_time_info.month, start_time_info.day) and
        time_rule.is_valid_date(end_time_info.year, end_time_info.month, end_time_info.day) and
        time_rule.is_valid_time(start_time_info.hour, start_time_info.min) and
        time_rule.is_valid_time(end_time_info.hour, end_time_info.min)
    ) then
        return false
    end

    -- 构成整数，通过整数判断大小
    local start_timestamp = tonumber(string.format('%04d%02d%02d%02d%02d',
        start_time_info.year, start_time_info.month, start_time_info.day, start_time_info.hour, start_time_info.min
    ))
    local end_timestamp = tonumber(string.format('%04d%02d%02d%02d%02d',
        end_time_info.year, end_time_info.month, end_time_info.day, end_time_info.hour, end_time_info.min
    ))
    if start_timestamp >= end_timestamp then
        return false
    end

    return true
end

--- 校验YMD格式时间规则格式
---@param rule string
---@return boolean 校验YMD规则格式是否通过
function time_rule.check_format_ymd(rule)
    local start_time_info, end_time_info = time_rule.get_time_info(rule, 'YMD')

    if not (
        time_rule.is_valid_date(start_time_info.year, start_time_info.month, start_time_info.day) and
        time_rule.is_valid_date(end_time_info.year, end_time_info.month, end_time_info.day)
    ) then
        return false
    end

    -- 构成整数，通过整数判断大小
    local start_timestamp = tonumber(string.format('%04d%02d%02d',
        start_time_info.year, start_time_info.month, start_time_info.day
    ))
    local end_timestamp = tonumber(string.format('%04d%02d%02d',
        end_time_info.year, end_time_info.month, end_time_info.day
    ))
    if start_timestamp >= end_timestamp then
        return false
    end

    return true
end

--- 校验HM格式时间规则格式
---@param rule string
---@return boolean 校验HM规则格式是否通过
function time_rule.check_format_hm(rule)
    local start_time_info, end_time_info = time_rule.get_time_info(rule, 'HM')

    if not (
        time_rule.is_valid_time(start_time_info.hour, start_time_info.min) and
        time_rule.is_valid_time(end_time_info.hour, end_time_info.min)
    ) then
        return false
    end

    -- 构成整数，通过整数判断大小
    local start_timestamp = tonumber(string.format('%02d%02d', start_time_info.hour, start_time_info.min))
    local end_timestamp = tonumber(string.format('%02d%02d', end_time_info.hour, end_time_info.min))
    if start_timestamp >= end_timestamp then
        return false
    end

    return true
end

--- 校验YMDHM格式时间规则
---@param rule string
---@return boolean 校验YMDHM规则是否通过
function time_rule.check_rule_ymdhm(rule)
    local start_time_info, end_time_info = time_rule.get_time_info(rule, 'YMDHM')
    local start_timestamp = tonumber(string.format('%04d%02d%02d%02d%02d',
        start_time_info.year, start_time_info.month, start_time_info.day, start_time_info.hour, start_time_info.min
    ))
    local end_timestamp = tonumber(string.format('%04d%02d%02d%02d%02d',
        end_time_info.year, end_time_info.month, end_time_info.day, end_time_info.hour, end_time_info.min
    ))
    local current_timestamp = tonumber(os.date('%Y%m%d%H%M', os.time()))

    return current_timestamp >= start_timestamp and current_timestamp <= end_timestamp
end

--- 校验YMD格式时间规则
---@param rule string
---@return boolean 校验YMD规则是否通过
function time_rule.check_rule_ymd(rule)
    local start_time_info, end_time_info = time_rule.get_time_info(rule, 'YMD')
    local start_timestamp = tonumber(string.format('%04d%02d%02d',
        start_time_info.year, start_time_info.month, start_time_info.day
    ))
    local end_timestamp = tonumber(string.format('%04d%02d%02d',
        end_time_info.year, end_time_info.month, end_time_info.day
    ))
    local current_timestamp = tonumber(os.date('%Y%m%d', os.time()))

    return current_timestamp >= start_timestamp and current_timestamp <= end_timestamp
end

--- 校验HM格式时间规则
---@param rule string
---@return boolean 校验HM规则是否通过
function time_rule.check_rule_hm(rule)
    local start_time_info, end_time_info = time_rule.get_time_info(rule, 'HM')
    local start_timestamp = tonumber(string.format('%02d%02d', start_time_info.hour, start_time_info.min))
    local end_timestamp = tonumber(string.format('%02d%02d', end_time_info.hour, end_time_info.min))
    local current_timestamp = tonumber(os.date('%H%M', os.time()))

    if start_timestamp < end_timestamp then
        return current_timestamp >= start_timestamp and current_timestamp <= end_timestamp
    end

    -- 开始时间大于结束时间,例: 12:00--8:00 有效期为 12:00~23.59 第二天00:00~8:00,即每天8:00~12:00 限制登录
    return current_timestamp >= start_timestamp or current_timestamp <= end_timestamp
end

local month_table = {
    [1] = true,
    [3] = true,
    [5] = true,
    [7] = true,
    [8] = true,
    [10] = true,
    [12] = true
}

--- 判断日期是否合法
---@param year number
---@param month number
---@param day number
---@return boolean 日期是否合法
function time_rule.is_valid_date(year, month, day)
    -- 起始年份和结束年份只能在1970到2050之间
    if year < 1970 or year > 2050 then
        return false
    end
    -- 起始月份和结束月份只能在1到12之间
    if month < 1 or month > 12 then
        return false
    end

    local maxDay = 30 -- 小月为30天
    -- 1,3,5,7,8,10,12 为大月
    if month_table[month] then
        maxDay = 31 -- 大月为31天
    elseif month == 2 then -- 2月
        maxDay = 28 -- 闰年28天
        -- 闰年: 年份被 4 整除；同時以 100 和 400 整除；整除余数为0
        if year % 4 == 0 and year % 100 ~= 0 or year % 400 == 0 then
            maxDay = 29 -- 闰年29天
        end
    end
    -- 天数必须大于0
    return day > 0 and day <= maxDay
end

--- 判断时间是否合法
---@param hour number
---@param min number
---@return boolean 时间是否合法
function time_rule.is_valid_time(hour, min)
    -- 小时只能在0到24之间
    if hour < 0 or hour > 23 then
        return false
    end
    -- 分钟只能在0到60之间
    if min < 0 or min > 59 then
        return false
    end

    return true
end

return time_rule
