-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local log = require 'mc.logging'
local class = require 'mc.class'
local Singleton = require 'mc.singleton'
local utils_core = require 'utils.core'
local file_utils = require 'utils.file'
local crypt = require 'utils.crypt'
local skynet_queue = require 'skynet.queue'
local snmp = require 'lsnmp.core'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local enum = require 'class.types.types'
local config = require 'common_config'
local bs = require 'mc.bitstring'
local s_pack = string.pack
local vos = require 'utils.vos'

local utils = class()
utils.queue = skynet_queue()

local MIN_USER_NUM = 2
local MAX_USER_NUM = 17

function utils:ctor()
    self.last_time_map = {}
end

--- 判断busctl方式输入LoginRuleIds信息是否合法
---@param login_rule_ids table
---@return boolean
function utils.check_login_rule_ids(login_rule_ids)
    local temp_set = {}
    if #login_rule_ids > 3 then
        log:error('login rule ids exceed the limit.')
        error(custom_msg.PropertyMemberQtyExceedLimit('LoginRule'))
    end
    for _, rule_id in pairs(login_rule_ids) do
        -- 判断重复
        if temp_set[rule_id] then
            log:error('login rule id duplicate.')
            error(custom_msg.PropertyItemDuplicate(rule_id))
        end
        temp_set[rule_id] = true

        -- 如果rule_id不属于LoginRuleIds枚举，则说明不合法
        if not enum.LoginRuleIds[rule_id] or rule_id == 'Rule_Invalid' then
            log:error('login rule id is illegal!')
            error(custom_msg.PropertyItemNotInList('LoginRuleIds:' ..
                table.concat(login_rule_ids, " "), 'LoginRuleIds'))
        end
    end
end

--- 将登录规则字符串数组转换为数字
---@param login_rule_ids table
---@return number
function utils.covert_login_rule_ids_str_to_num(login_rule_ids)
    local num = enum.LoginRuleIds.Rule_Invalid:value()
    for _, value in pairs(login_rule_ids) do
        if value ~= nil and value ~= '' then
            num = (num | enum.LoginRuleIds.new(value):value())
        end
    end
    return num
end

--- 将数字转换为登录规则字符串数组
---@param num number
---@return login_rule_ids table
function utils.covert_num_to_login_rule_ids_str(num)
    local login_rule_ids = {}
    if num == 0 then
        return login_rule_ids
    end

    for key, value in pairs(enum.LoginRuleIds) do
        if type(value) ~= 'table' then
            goto continue
        end
        -- default 由框架增加导致，不需要处理，直接去掉
        if value == enum.LoginRuleIds.default then
            goto continue
        end
        if (num & value:value()) ~= 0 then
            table.insert(login_rule_ids, key)
        end
        ::continue::
    end

    return login_rule_ids
end

--- 实现从uint32（每1位代表一个登陆接口）转换为接口字符串数组
---@param num number
---@param is_need_name boolean
function utils.convert_num_to_interface_str(num, is_need_name)
    local interface = {}
    if num == 0 then
        return interface
    end
    for name, value in pairs(enum.LoginInterface) do
        -- enum.LoginInterface.default 由框架增加导致，不需要转换，直接去掉
        if type(value) ~= type(enum) or value == enum.LoginInterface.default then
            goto continue
        end
        if num & value:value() ~= 0 then
            if is_need_name then
                table.insert(interface, name)
            else
                table.insert(interface, value)
            end
        end
        ::continue::
    end
    return interface
end

--- 检查操作文件的用户是否跟文件属主一致
---@param file_path string
---@param caller_username string
---@param caller_role_id number
function utils.check_fileowner_matchs_caller(file_path, caller_username, caller_role_id)
    if file_utils.check_real_path_s(file_path) ~= 0 then
        log:error('check fileowner matchs caller: check file path failed')
        return false
    end
    -- 判断是否为管理员用户,管理员用户可以操作其他用户上传或生成的文件
    if caller_role_id == enum.RoleType.Administrator:value() then
        return true
    end
    local get_file_stat_result, file_stat = pcall(utils_core.stat_s, file_path)
    if not get_file_stat_result then
        log:error('get file stat failed,error:%s', file_stat)
        return false
    end
    local get_uid_result, uid = pcall(utils_core.get_uid_gid_by_name, caller_username)
    if not get_uid_result then
        log:error('get uid gid by name failed')
        return false
    end
    if file_stat.st_uid ~= uid then
        log:error("The user does not have the permission to operate the file with file mode.")
        return false
    end

    return true
end

--- 校验配置接口权限
---@param role_id number
---@param handle_account_id number
---@param account_id number 
function utils.configure_self_validator(role_id, handle_account_id, account_id)
    if role_id ~= enum.RoleType.Administrator:value() and handle_account_id ~= account_id then
        return false
    end
    return true
end

--- 权限校验
---@param cur_privileges table 当前权限列表
---@param req_privilege enum 权限枚举
function utils.privilege_validator(cur_privileges, req_privilege)
    for _, privilege in pairs(cur_privileges) do
        if privilege == tostring(req_privilege) then
            return true
        end
    end
    return false
end

--- 对比设置前后登录接口或登陆规则的变化
---@param old_num number
---@param new_num number
---@param convert_fun function
function utils.get_login_interface_or_rule_ids_change(old_num, new_num, convert_fun)
    local enable_array_string
    local disable_array_string
    local xor_num = new_num ~ old_num
    if xor_num == 0 then
        return nil
    end
    local enable_num = xor_num & new_num
    local disable_num = xor_num & old_num
    enable_array_string = convert_fun(enable_num, true)
    disable_array_string = convert_fun(disable_num, true)

    local enable_string = ''
    local disable_string = ''
    if enable_num ~= 0 then
        enable_string = 'enabled: ' .. table.concat(enable_array_string, ' ') .. ' '
    end
    if disable_num ~= 0 then
        disable_string = 'disabled: ' .. table.concat(disable_array_string, ' ') .. ' '
    end
    local str_connect = '; '
    if enable_num == 0 or disable_num == 0 then
        str_connect = ''
    end
    local change_str = enable_string .. str_connect .. disable_string
    return change_str
end

--- 检查指定登录接口是否开启
---@param interfaces_cur table | num
---@param interface_check enum
function utils.check_login_interface_enabled(interfaces_cur, interface_check)
    if type(interfaces_cur) == 'number' then
        return interfaces_cur & interface_check:value() ~= 0
    elseif type(interfaces_cur) == 'table' then
        for _, interface in pairs(interfaces_cur) do
            if tostring(interface) == tostring(interface_check) then
                return true
            end
        end
        return false
    end
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
function utils.convert_time_to_str(timestamp)
    local last_time_str = os.date('%Y-%m-%dT%H:%M:%S', timestamp)
    local time_zone_str = get_time_zone_str()
    return last_time_str .. time_zone_str
end

--- 检查导入路径为本地文件时文件的合法性
---@param path string
function utils.check_import_path(path, header)
    if #path == 0 or #path > config.MAX_FILEPATH_LENGTH then
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
    if file_utils.check_real_path_s(path, header .. '/') ~= 0 then
        log:error('check realpath faild.')
        return false
    end

    return true
end

-- 校验文件导入路径的合法性
function utils.is_import_permitted(type, content, file_type, property_name, result)
    if type ~= 'URI' then
        return true
    end

    
    local pattern_collection = {
        ['pub'] = "^((https|sftp|nfs|cifs|scp)://.{1,1000}|" .. config.TMP_PATH .. "/.{1,246})\\.pub$",
        ['cert'] = "^((https|sftp|nfs|cifs|scp)://.{1,1000}|" .. config.TMP_PATH .. "/.{1,246})\\.(crt|cer|cert|pem|p12|pfx|crl|der)$",
        ['tab'] = "^((https|sftp|nfs|cifs|scp)://.{1,1000}|" .. config.TMP_PATH .. "/.{1,246})\\.tab$",
        ['weakpwddic'] = "^((https|sftp|nfs|cifs|scp)://.{1,1000}|" .. config.TMP_PATH .. "/.{1,251})$"
    }

    if not utils_core.g_regex_match(pattern_collection[file_type], content) then
        error(base_msg.PropertyValueFormatError("******", property_name))
    end

    if content:sub(1,1) ~= '/' then
        return true
    end

    if result(content, 'rw') then
        return true
    end
    error(custom_msg.NoPrivilegeToOperateSpecifiedFile())
end

-- 16进制数字符串按字节转为字符串
function utils.decode_hex_string(hex_string)
    local str = hex_string:gsub('..', function(hex)
        return string.char(tonumber(hex, 16))
    end)
    return str
end

function utils.vos_get_time()
    --- 单位毫秒转秒
    return vos.vos_tick_get() // 1000
end

-- 限频日志
---@param level number params: 0,DEBUG 1,NOTICE 2,ERROR
---@param interval_s number params: interval seconds
---@param fmt string params: log messages
---@param ... string params: log messages params
function utils:frequency_limit_log(level, interval_s, fmt, ...)
    local last_time_key = debug.getinfo(2, 'S').short_src .. ':' .. debug.getinfo(2, "l").currentline
    local cur_time = self:vos_get_time()
    local log_callback = {
        [enum.LogLevel.DEBUG:value()] = log.debug,
        [enum.LogLevel.NOTICE:value()] = log.notice,
        [enum.LogLevel.ERROR:value()] = log.error
    }
    local last_time = self.last_time_map[last_time_key]
    if not last_time or cur_time - last_time >= interval_s then
        self.last_time_map[last_time_key] =  cur_time
        log_callback[level](log, fmt, ...)
    end
end

function utils.interface_num_to_string(interface_num)
    local str_table = {}
    for key, value in pairs(enum.LoginInterface) do
        if type(value) ~= 'table' then
            goto continue
        end
        if value == enum.LoginInterface.default or value == enum.LoginInterface.Invalid then
            goto continue
        end
        if value:value() & interface_num == value:value() then
            table.insert(str_table, key)
        end
        ::continue::
    end
    return table.concat(str_table, ', ')
end

-- 将接口枚举类整合为string
function utils.interface_enum_table_to_string(interface)
    local interface_str_table = {}
    for _, interface_enum in pairs(interface) do
        table.insert(interface_str_table, tostring(interface_enum))
    end
    return table.concat(interface_str_table, ' ')
end

-- 实现table中接口字符串转化为枚举
function utils.cover_interface_str_to_enum(interface)
    local interfaceEnum = {}
    for _, value in pairs(interface) do
        if value ~= nil then
            table.insert(interfaceEnum, enum.LoginInterface.new(value))
        end
    end
    return interfaceEnum
end

-- 实现从枚举数组转换为uint8(每1位代表一个登陆接口)，用于account数据库存储
function utils.cover_interface_enum_to_num(interface)
    if type(interface) == "number" then
        log:notice('convert interface failed, interface(%d) is already a number', interface)
        return interface
    end
    local interfaceNum = enum.LoginInterface.Invalid:value()
    for _, value in pairs(interface) do
        if value ~= nil then
            interfaceNum = (interfaceNum | value:value())
        end
    end
    return interfaceNum
end

-- 实现将登录接口字符串转换为num类型
function utils.cover_interface_str_to_num(interface)
    local interface_enum = utils.cover_interface_str_to_enum(interface)
    return utils.cover_interface_enum_to_num(interface_enum)
end

function utils.get_manufacture_id()
    local manufacture_id = 0x0007DB
    return manufacture_id
end

function utils.check_ipmi_account_id(user_id)
    -- 匿名用户
    if type(user_id) ~= "number" or user_id < MIN_USER_NUM or user_id > MAX_USER_NUM then
        error(custom_msg.IPMIInvalidFieldRequest())
    end
    return true
end

function utils.user_login_interface_get_bit(interface, offset)
    local data = (((interface) & ((0x1) << (offset))) >> (offset))
    return data
end

function utils.ipmi_get_user_login_interface(interface)
    local ipmi_interface = {}
    ipmi_interface[0] = 'Web'
    ipmi_interface[1] = 'SNMP'
    ipmi_interface[2] = 'IPMI'
    ipmi_interface[3] = 'SSH'
    ipmi_interface[4] = 'SFTP'
    ipmi_interface[6] = 'Local'
    ipmi_interface[7] = 'Redfish'
    local new_interface = {}
    local USER_LOGIN_INTERFACE_MAX = 8
    for index = 0, USER_LOGIN_INTERFACE_MAX, 1 do
        local flag = utils.user_login_interface_get_bit(interface, index)
        if flag == enum.IpmiInterfaceEnable.USER_LOGIN_INTERFACE_ENABLE:value() then
            table.insert(new_interface, ipmi_interface[index])
        end
    end
    return new_interface
end

function utils.oem_get_user_login_interface(interface)
    local new_interface = {}
    local USER_LOGIN_INTERFACE_MAX = 8
    for index = 0, USER_LOGIN_INTERFACE_MAX, 1 do
        local flag = utils.user_login_interface_get_bit(interface, index)
        if flag == enum.IpmiInterfaceEnable.USER_LOGIN_INTERFACE_ENABLE:value() then
            table.insert(new_interface, enum.LoginInterface.new((0x1) << (index)))
        end
    end
    return new_interface
end

-- 将九大权限中为true的权限名字加入到table中
function utils.cover_bool_to_privilege_table(data)
    local info = {}
    info['UserMgmt'] = data.UserMgmt
    info['BasicSetting'] = data.BasicSetting
    info['KVMMgmt'] = data.KVMMgmt
    info['ReadOnly'] = data.ReadOnly
    info['VMMMgmt'] = data.VMMMgmt
    info['SecurityMgmt'] = data.SecurityMgmt
    info['PowerMgm'] = data.PowerMgmt
    info['DiagnoseMgmt'] = data.DiagnoseMgmt
    info['ConfigureSelf'] = data.ConfigureSelf
    local res = {}
    for key, value in pairs(info) do
        if value then
            table.insert(res, key)
        end
    end
    return res
end

function utils.str_is_empty(data)
    if data == nil or data == '' then
        return true
    end
    return false
end

-- 判断表内是否元素重复
function utils.check_if_element_repeat(table)
    local temp_tb = {}
    for _, v in pairs(table) do
        if not temp_tb[v] then
            temp_tb[v] = true
        else
            return false
        end
    end
    return true
end

-- 判断busctl方式输入用户interface信息是否合法
function utils.check_interface_info(interfaces)
    -- interfaces判重，如{'Web'， 'Web'，'Web'}是不合法的
    if not utils.check_if_element_repeat(interfaces) then
        return false
    end
    for _, interface in pairs(interfaces) do
        -- 登录接口枚举中的Invalid也是不合法的
        if interface == 'Invalid' then
            return false
        end
        -- 如果interface不等于登录接口枚举中的任何一个，则说明不合法
        if not enum.LoginInterface[interface] then
            return false
        end
    end
    return true
end

-- 判断busctl方式输入RoleId信息是否合法
function utils.check_role_id_info(id)
    local flag = false
    for _, value in pairs(enum.RoleType) do
        if type(value) ~= type(enum) then
            goto continue
        end
        if id == value:value() then
            flag = true
            break
        end
        ::continue::
    end
    return flag
end

-- 计算Ku
function utils.generate_ku(prototol, pwd)
    local gen_ku_info = snmp.GEN_KU_STRU.new()
    gen_ku_info.pwd = pwd
    gen_ku_info.ku = ""
    gen_ku_info.protocol = prototol
    local ok = pcall(function(...)
        snmp.generate_ku(gen_ku_info)
        local s = crypt.convert_ciphertext_to_string(gen_ku_info.ku, #gen_ku_info.ku)
        gen_ku_info.ku = s
    end)
    return ok, gen_ku_info.ku
end

-- 基础用户名校验
function utils.base_check_user_name(username)
    local check_config = "^[^\\x00-\\x1F\\x7F]+$"
    if username == config.ACTUAL_ROOT_USER_NAME then
        return true
    end
    if username == '.' or username == '..' then -- 用户名不能为.或..
        return false
    end
    for _, reserved_user_name in pairs(config.APP_USERS) do
        if username == reserved_user_name.name then
            return false
        end
    end

    return utils_core.g_regex_match(check_config, username)
end

-- 去除Ipmi报文中 \0 字符
function utils.trim00(info)
    if not info or string.len(info) == 0 then
        return info
    end
    local location = string.find(info, "\0")
    if not location then
        return info
    end
    return string.sub(info, 1, location - 1)
end

-- 将字符串转换为不区分大小写的正则格式
-- 如 tEsT -> [tT][eE][sS][tT]
function utils.parse_str_no_case(s)
    s = string.gsub(s, "%a", function (c)
        return string.format("[%s%s]", string.lower(c), string.upper(c))
    end)
    return s
end

-- 检查字符串是否是可打印的ASCII码字符
function utils.check_string_is_valid_ascii(str)
    for i = 1, #str do
        local c = string.sub(str, i, i)
        local byte = string.byte(c)
        -- ascii码可打印字符边界 32-(space) 126-`
        if byte < 32 or byte > 126 then
            return false
        end
    end
    return true
end

local function b_unpack(pattn, data)
    local p = bs.new(pattn)
    return p:unpack(data)
end

-- 以字节为单位逆转
function utils.U16_BYTE_REVERSE(number)
    local data = s_pack("<H", number)
    local r = b_unpack('<<var:2/big-unit:8>>', data)
    return r.var
end

-- ipv4 binary to ipv4 string
function utils.ipv4_binary_to_string(addr_req)
    return string.format('%d.%d.%d.%d', string.unpack('BBBB', addr_req))
end

-- ipv4 string to ipv4 binary
function utils.ipv4_string_to_binary(ipv4_addr)
    local ipv4_addr_rsp = string.gsub(ipv4_addr, '(%d+)%.?', function(v)
        return string.char(tonumber(v))
        end)
    return ipv4_addr_rsp
end

-- 将ipmi传入的16个字节转化成ipv6地址的最简字符串形式,例如：0xfe 0x80 0x00 ...转化成：fe80::格式
function utils.simplify_ipmi_ipv6_req(addr_req)
    local addr_str = string.format(
        '%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x',
        string.unpack('BBBBBBBBBBBBBBBB', addr_req))
    local simplified_addr = utils.delete_zero_addr(utils.format_ipv6_addr(addr_str))
    return simplified_addr
end

function utils.delete_zero_addr(file_ipv6_str)
    local ipv6_addr = ''
    local zreo_flag = false
    local count = 0
    -- 开头全0的ip
    if string.sub(file_ipv6_str, 1, 4) == '0000' then
        ipv6_addr = ':'
    end

    for i = 1, 8 do
        local temp = string.sub(file_ipv6_str, (i - 1) * 5 + 1, i * 5 - 1)

        if temp ~= '0000' or count > 0 then
            if zreo_flag then
                count = count + 1
                zreo_flag = false
                ipv6_addr = ipv6_addr .. ':'
            end

            temp = string.format('%x', utils.to_value(temp))
            ipv6_addr = ipv6_addr .. temp
            ipv6_addr = ipv6_addr .. ':'
        else
            zreo_flag = true
        end
    end
    if zreo_flag and count == 0 then
        ipv6_addr = ipv6_addr .. ':0:'
    end
    -- 去掉字符串最后一个：
    local str = string.sub(ipv6_addr, 1, string.len(ipv6_addr) - 1)
    if #str >= 3 then
        if str:sub(-3, -1) == '::0' then
            str = str:sub(1, -2)
        end
    end
    return str
end

function utils.format_ipv6_addr(file_ipv6_str)
    local ipv6_addr = ''
    for i = 1, 8 do
        local temp = string.sub(file_ipv6_str, (i - 1) * 4 + 1, i * 4)
        ipv6_addr = ipv6_addr .. temp
        ipv6_addr = ipv6_addr .. ':'
    end
    -- 去掉字符串最后一个：
    return string.sub(ipv6_addr, 1, string.len(ipv6_addr) - 1)
end

local function from_hex(str)
    -- 滤掉分隔符
    local hex = str:gsub('[%s%p]', ''):upper()
    return hex:gsub('%x%x', function(c)
        return string.char(tonumber(c, 16))
    end)
end

-- 16进制字符串转10进制
function utils.to_value(str)
    local hexs = from_hex(str:gsub('%x', '0%1'))
    local res = 0;
    for i = 1, string.len(str) do
        res = res * 16 + hexs:byte(i)
    end
    return res
end

-- 检查密码内是否含有汉字
function utils.check_if_password_character_is_valid(password)
    if string.match(password, "[^\x00\x01-\x7f]") then
        return false
    end
    return true
end

-- 比较两个字符串去除空格后是否相等
function utils.string_equal_without_space_and_case(str1, str2)
    -- 去除字符串中的空格
    local s1 = string.gsub(str1, " ", "")
    local s2 = string.gsub(str2, " ", "")
    s1 = string.upper(s1)
    s2 = string.upper(s2)
    -- 比较字符串是否相等
    return s1 == s2
end

 -- 判断系统是否支持CAP_DAC_OVERRIDE能力
 function utils.check_cap_dac_override_supported(cfg_path)
    local ok, file = pcall(file_utils.open_s, cfg_path, 'r')
    if not ok or not file then
        return false
    end

    local content = file:read('*a')
    file:close()

    if not content or content == '' then
        return false
    end

    return string.find(content, 'CAP_DAC_OVERRIDE', 1, true) ~= nil
end

function utils.topo_sort(deps)
    local indegree = {}
    local graph = {}

    -- 初始化图和入度
    for node, pre_list in pairs(deps) do
        indegree[node] = 0
        if not graph[node] then graph[node] = {} end
        for _, pre in ipairs(pre_list) do
            if not graph[pre] then graph[pre] = {} end
            table.insert(graph[pre], node)
            indegree[node] = indegree[node] + 1
        end
    end

    -- 找到所有入度为0的节点
    local queue = {}
    for node, deg in pairs(indegree) do
        if deg == 0 then table.insert(queue, node) end
    end

    -- 拓扑排序
    local result = {}
    while #queue > 0 do
        local node = table.remove(queue, 1)
        table.insert(result, node)
        for _, child in ipairs(graph[node] or {}) do
            indegree[child] = indegree[child] - 1
            if indegree[child] == 0 then
                table.insert(queue, child)
            end
        end
    end

    -- 检查是否有环
    if #result < #indegree then
        error(base_msg.InternalError())
    end

    return result
end

return Singleton(utils)