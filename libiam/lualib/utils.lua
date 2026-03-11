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
local IamErr = require 'iam.errors'
local snmp = require 'lsnmp.core'
local crypt = require 'utils.crypt'
local utils_core = require 'utils.core'
local network_core = require 'network.core'
local remote_group_config = require 'domain.remote_group.remote_group_config'
local iam_enum = require 'class.types.types'
local user_config = require 'user_config'
local bs = require 'mc.bitstring'
local log = require 'mc.logging'
local custom_msg = require 'messages.custom'
local s_pack = string.pack

local MAX_USER_NUM = 17

local utils = {}

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
            table.insert(interfaceEnum, iam_enum.LoginInterface.new(value))
        end
    end
    return interfaceEnum
end

-- 实现从枚举数组转换为uint8(每1位代表一个登陆接口)，用于IAM数据库存储
function utils.cover_interface_enum_to_num(interface)
    if type(interface) == "number" then
        log:notice('convert interface failed, interface(%d) is already a number', interface)
        return interface
    end
    local interfaceNum = iam_enum.LoginInterface.Invalid:value()
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

function utils.check_ipmi_account_id(user_id)
    -- 匿名用户
    if user_id == nil or type(user_id) ~= "number" then
        error(IamErr.invalid_data_field())
    end
    if user_id == 1 then
        error(IamErr.un_supported())
    end
    if user_id == 0 then
        error(IamErr.invalid_data_field())
    end
    if user_id > MAX_USER_NUM then
        error(IamErr.value_out_of_range())
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
        if flag == iam_enum.IpmiInterfaceEnable.USER_LOGIN_INTERFACE_ENABLE:value() then
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
        if flag == iam_enum.IpmiInterfaceEnable.USER_LOGIN_INTERFACE_ENABLE:value() then
            table.insert(new_interface, iam_enum.LoginInterface.new((0x1) << (index)))
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
function utils.check_if_elements_unique(table)
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

-- 判断busctl方式输入远程用户组interface信息是否合法
function utils.check_remote_group_interface_info(group_type, interfaces)
    -- interfaces判重，如{'Web'， 'Web'，'Web'}是不合法的
    if not utils.check_if_elements_unique(interfaces) then
        return false
    end
    for _, interface in pairs(interfaces) do
        -- 目前LDAP仅支持三种接口，Kerberos仅支持两种接口
        if group_type == iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value() then
            if not remote_group_config.LDAP_SUPPORT_TYPE[interface] then
                return false
            end
        else
            if not remote_group_config.Kerberos_SUPPORT_TYPE[interface] then
                return false
            end
        end
    end
    return true
end

-- 判断busctl方式输入用户interface信息是否合法
function utils.check_interface_info(interfaces)
    -- interfaces判重，如{'Web'， 'Web'，'Web'}是不合法的
    if not utils.check_if_elements_unique(interfaces) then
        return false
    end
    for _, interface in pairs(interfaces) do
        -- 登录接口枚举中的Invalid也是不合法的
        if interface == 'Invalid' then
            return false
        end
        -- 如果interface不等于登录接口枚举中的任何一个，则说明不合法
        if not iam_enum.LoginInterface[interface] then
            return false
        end
    end
    return true
end

-- 判断busctl方式输入RoleId信息是否合法
function utils.check_role_id_info(id)
    local flag = false
    for _, value in pairs(iam_enum.RoleType) do
        if type(value) ~= type(iam_enum) then
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

-- 用户名校验
function utils.check_user_name(username)
    local check_config =
        "^(?!.*[<>&,'/\\%:\" ])(?=[A-Za-z0-9`~!@#$%^&*()_+-={};[\\]?.|])" ..
        "(?!#)(?!\\+)(?!-)([A-Za-z0-9`~!@#$%^&*()_+-={};[\\]?.|]{1,16})(?!((\r?\n|(?<!\n)\r)|\f))$"
    if username == user_config.ACTUAL_ROOT_USER_NAME then
        return true
    end
    if username == '.' or username == '..' then -- 用户名不能为.或..
        return false
    end
    for _, reserved_user_name in pairs(user_config.APP_USERS) do
        if username == reserved_user_name.name then
            return false
        end
    end

    return utils_core.g_regex_match(check_config, username)
end

-- 远程用户组名校验
function utils.contain_invisible_charactor(str)
    local c
    local byte
    for i = 1, string.len(str) do
        c = string.sub(str, i, i)
        byte = string.byte(c)
        if (byte >= 0x00 and byte <= 0x1F) or byte == 0x7F then
            return true
        end
    end

    return false
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
    -- 适配luajit:对\x00特殊处理
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

local function normalize_ipv4(ip)
    local blocks = {}
    for block in ip:gmatch("%d+") do
        table.insert(blocks, tonumber(block))
    end
    return table.concat(blocks, ".")
end

local function normalize_ipv6(ip)
    -- Expand zero-compressed blocks
    local first_part, second_part = ip:match("^(.-)::(.*)$")
    if first_part and second_part then
        local missing_blocks = 8 - select(2, ip:gsub(":", ":"))
        ip = first_part .. string.rep(":0", missing_blocks + 1) .. second_part
    elseif ip:find("::") then
        local missing_blocks = 8 - select(2, ip:gsub(":", ":")) + 1
        ip = ip:gsub("::", string.rep(":0", missing_blocks))
    end

    -- Ensure it has exactly 8 blocks
    local blocks = {}
    for block in ip:gmatch("[%x]+") do
        table.insert(blocks, block)
    end
    while #blocks < 8 do
        table.insert(blocks, "0")
    end

    -- Convert each block to four digits
    for i = 1, #blocks do
        blocks[i] = string.format("%04x", tonumber(blocks[i], 16))
    end

    return table.concat(blocks, ":")
end

-- 标准化ip地址
function utils.normalize_ip(ip)
    -- Check if input is IPv4 or IPv6
    if ip:match("^[%d%.]+$") then
        return normalize_ipv4(ip)
    else
        return normalize_ipv6(ip)
    end
end

function utils.check_ip_valid(ip)
    return network_core.verify_ipv4_address(ip) == 0 or network_core.verify_ipv6_address(ip) == 0
end

-- 错误码优先级
local ERROR_PRIORITY = {
    [custom_msg.AuthorizationFailedMessage.Name] = 1,
    [custom_msg.NoAccessMessage.Name] = 2,
    [custom_msg.AuthorizationUserPasswordExpiredMessage.Name] = 3,
    [custom_msg.UserLoginRestrictedMessage.Name] = 4,
    [custom_msg.UserLockedMessage.Name] = 5
}

function utils.get_best_match_error(err_info)
    local max_priority = 0
    local result
    for _, err in pairs(err_info) do
        if ERROR_PRIORITY[err.name] and ERROR_PRIORITY[err.name] > max_priority then
            max_priority = ERROR_PRIORITY[err.name]
            result = err
        end
    end
    -- 不在优先级列表中则返回最后一个错误
    if result then
        return result
    else
        return err_info[#err_info]
    end
end

return utils
