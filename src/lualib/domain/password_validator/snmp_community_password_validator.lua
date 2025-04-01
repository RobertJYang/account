-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local custom_msg = require 'messages.custom'
local password_validator = require 'domain.password_validator.password_validator'
local core = require 'account_core'

local SnmpCommunityPasswordValidator = class(password_validator)

-- 设置新团体名时要求和旧团体名相比至少有两位字符是不同的
local function compare_snmp(new_password, current_password)
    local count  = 0
    local diff = math.abs(#new_password - #current_password)
    if diff >= 2 then
        return true
    end

    local minLength = math.min(#new_password, #current_password)
    for i = 1, minLength do
        if new_password:sub(i, i) ~= current_password:sub(i, i) then
            count  = count  + 1
        end
        if (count + diff) >= 2 then
            return true
        end
    end
    return false
end

function SnmpCommunityPasswordValidator:basic_validate(info)
    local password = info.password

    local long_community_enable = self.m_account_config:get_long_community_enabled()
    local max_community_length = 32
    local min_community_length = 16

    local password_complexity_check_enable = self.m_account_config:get_password_complexity_enable()

    -- 启用超长口令时团体名最短可设置为16个字符，禁用时，若开启密码检查，最短为8个字符，反之最短为1个字符
    if not long_community_enable then
        min_community_length = password_complexity_check_enable and 8 or 1
    end
    if #password < min_community_length or #password > max_community_length then
        -- 根据用户id选择错误机制填入参数,id为20时为只读团体名，为21时为读写团体名
        local error_param = info.is_ro_community and 'ReadOnlyCommunity' or 'ReadWriteCommunity'
        error(custom_msg.InvalidCommunityNameLength(error_param))
    end

    if password_complexity_check_enable then
        -- 如果使用单一"."无法通过密码复杂度检查(因为至少要求有2种字符，通过该字符串跳过用户名检查)
        local result = core.is_pass_complexity_check_pass(".", password, min_community_length)
        if not result then
            log:error('The community string does not meet the password complexity')
            error(custom_msg.PasswordComplexityCheckFail())
        end
    else
        log:notice('When password complexity is off, no need to check password with history')
        return
    end

    if not compare_snmp(password, info.current_password) then
        log:error('The new and old passwords of the community name must have at least two different characters')
        if info.is_ro_community then
            error(custom_msg.ROCommunitySimilarWithHistory())
        end
        error(custom_msg.RWCommunitySimilarWithHistory())
    end
end

return singleton(SnmpCommunityPasswordValidator)