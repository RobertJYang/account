-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 配置导入导出时密码校验相关项
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'

local POLICY_TO_NUM_MAP = {
    ['Default']    = 1,
    ['Customized'] = 2,
    ['Hybrid']     = 3
}

local NUM_TO_POLICY_MAP = {
    [1] = 'Default',
    [2] = 'Customized',
    [3] = 'Hybrid'
}

local PasswordValidatorProfile = {}

function PasswordValidatorProfile.set_policy(self, ctx, account_type, value)
    value_num = POLICY_TO_NUM_MAP[value]
    if not value_num then
        error(base_msg.PropertyValueNotInList(value, "PasswordRulePolicy"))
    end
    self.m_password_validator_collection:set_policy(ctx, account_type, value_num)
    self.m_password_validator_collection.m_config_changed:emit(account_type, 'Policy', value_num)
end

function PasswordValidatorProfile.get_policy(self, ctx, account_type)
    local value = self.m_password_validator_collection:get_policy(account_type)
    return NUM_TO_POLICY_MAP[value]
end

function PasswordValidatorProfile.set_pattern(self, ctx, account_type, value)
    self.m_password_validator_collection:set_pattern(ctx, account_type, value)
    self.m_password_validator_collection.m_config_changed:emit(account_type, 'Pattern', value)
end

function PasswordValidatorProfile.get_pattern(self, ctx, account_type)
    return self.m_password_validator_collection:get_pattern(account_type)
end

return PasswordValidatorProfile