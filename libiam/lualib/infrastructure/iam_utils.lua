
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
local utils_core = require 'utils.core'
local file_utils = require 'utils.file'
local user_config = require 'user_config'
local log = require 'mc.logging'
local class = require 'mc.class'
local iam_enum = require 'class.types.types'
local Singleton = require 'mc.singleton'
local queue = require 'skynet.queue'

local iam_utils = class()
iam_utils.queue = queue()

function iam_utils:ctor()
    self.last_time_map = {}
end

local function get_time_zone_str()
    local HOUR_SECOND = 3600
    local MINUTE_SECOND = 60
    local time_zone_second = os.difftime(os.time(), os.time(os.date('!*t', os.time())))
    local time_zone_str
    if time_zone_second < 0 then
        time_zone_str = string.format(
            '-%.2d:%.2d', -time_zone_second // HOUR_SECOND, -time_zone_second % HOUR_SECOND / MINUTE_SECOND)
    else
        time_zone_str = string.format('+%.2d:%.2d', time_zone_second // HOUR_SECOND,
            time_zone_second % HOUR_SECOND / MINUTE_SECOND)
    end
    return time_zone_str
end

--- 字符串解析时间戳
---@param timestamp number 
function iam_utils.convert_time_to_str(timestamp)
    local last_time_str = os.date('%Y-%m-%dT%H:%M:%S', timestamp)
    local time_zone_str = get_time_zone_str()
    return last_time_str .. time_zone_str
end

--- 检查导入路径为本地文件时文件的合法性
---@param path string
function iam_utils.check_import_path(path)
    if #path == 0 or #path > user_config.MAX_FILEPATH_LENGTH then
        log:error('File path length is out of range.')
        return false
    end
    if string.match(path, '/%.%./') or string.match(path, '//') then
        log:error('File path is not real path.')
        return false
    end
    if utils_core.is_dir(path) then
        log:error('File path is dir path.')
        return false
    end
    if file_utils.check_real_path_s(path, user_config.TMP_PATH .. '/') ~= 0 then
        log:error('check realpath faild.')
        return false
    end

    return true
end

-- 16进制数字符串按字节转为字符串
function iam_utils.decode_hex_string(hex_string)
    local str = hex_string:gsub('..', function(hex)
        return string.char(tonumber(hex, 16))
    end)
    return str
end

-- 限频日志
---@param level number params: 0,DEBUG 1,NOTICE 2,ERROR
---@param interval_s number params: interval seconds
---@param fmt string params: log messages
---@param ... string params: log messages params
function iam_utils:frequency_limit_log(level, interval_s, fmt, ...)
    local last_time_key = debug.getinfo(2, 'S').short_src .. ':' .. debug.getinfo(2, "l").currentline
    local cur_time = os.time()
    local log_callback = {
        [iam_enum.LogLevel.DEBUG:value()] = log.debug,
        [iam_enum.LogLevel.NOTICE:value()] = log.notice,
        [iam_enum.LogLevel.ERROR:value()] = log.error
    }
    local last_time = self.last_time_map[last_time_key]
    if not last_time or cur_time - last_time >= interval_s then
        self.last_time_map[last_time_key] =  cur_time
        log_callback[level](log, fmt, ...)
    end
end

-- 去除表中重复值
---@param ori_table table 
function iam_utils:remove_duplicates(ori_table)
    local result = {}  -- 存储去重后的结果
    local seen = {}    -- 用于快速检查值是否已存在于表中
    for _, v in ipairs(ori_table) do
        if not seen[v] then
            seen[v] = true
            table.insert(result, v)
        end
    end
    return result
end

return Singleton(iam_utils)