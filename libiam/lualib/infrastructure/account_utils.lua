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
local log = require 'mc.logging'
local iam_enum = require 'class.types.types'
local custom_msg = require 'messages.custom'

local AccountUtils = {}

--- 判断busctl方式输入LoginRuleIds信息是否合法
---@param login_rule_ids table
---@return boolean
function AccountUtils.check_login_rule_ids(login_rule_ids)
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
        if not iam_enum.LoginRuleIds[rule_id] or rule_id == 'Rule_Invalid' then
            log:error('login rule id is illegal!')
            error(custom_msg.PropertyItemNotInList('LoginRuleIds:' ..
                table.concat(login_rule_ids, " "), 'LoginRuleIds'))
        end
    end
end

--- 将登录规则字符串数组转换为数字
---@param login_rule_ids table
---@return number
function AccountUtils.covert_login_rule_ids_str_to_num(login_rule_ids)
    local num = iam_enum.LoginRuleIds.Rule_Invalid:value()
    for _, value in pairs(login_rule_ids) do
        if value ~= nil and value ~= '' then
            num = (num | iam_enum.LoginRuleIds.new(value):value())
        end
    end
    return num
end

--- 将数字转换为登录规则字符串数组
---@param num number
---@return login_rule_ids table
function AccountUtils.covert_num_to_login_rule_ids_str(num)
    local login_rule_ids = {}
    if num == 0 then
        return login_rule_ids
    end

    for key, value in pairs(iam_enum.LoginRuleIds) do
        if type(value) ~= 'table' then
            goto continue
        end
        -- default 由框架增加导致，不需要处理，直接去掉
        if value == iam_enum.LoginRuleIds.default then
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
function AccountUtils.convert_num_to_interface_str(num, is_need_name)
    local interface = {}
    if num == 0 then
        return interface
    end
    for name, value in pairs(iam_enum.LoginInterface) do
        -- iam_enum.LoginInterface.default 由框架增加导致，不需要转换，直接去掉
        if type(value) ~= type(iam_enum) or value == iam_enum.LoginInterface.default then
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

--- 校验配置接口权限
---@param role_id number
---@param handle_account_id number
---@param account_id number 
function AccountUtils.configure_self_validator(role_id, handle_account_id, account_id)
    if role_id ~= iam_enum.RoleType.Administrator:value() and handle_account_id ~= account_id then
        return false
    end
    return true
end

--- 权限校验
---@param cur_privileges table 当前权限列表
---@param req_privilege enum 权限枚举
function AccountUtils.privilege_validator(cur_privileges, req_privilege)
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
function AccountUtils.get_login_interface_or_rule_ids_change(old_num, new_num, convert_fun)
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
function AccountUtils.check_login_interface_enabled(interfaces_cur, interface_check)
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

return AccountUtils
