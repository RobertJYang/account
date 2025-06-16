-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 配置导入导出时用户公共服务相关项

local AccountServiceProfile = {}

function AccountServiceProfile.set_password_complexity_enable(self, ctx, value)
    self.m_account_config:set_password_complexity_enable(value)
    self.m_account_service.m_config_changed:emit('PasswordComplexityEnable', value)
end

function AccountServiceProfile.get_password_complexity_enable(self)
    return self.m_account_config:get_password_complexity_enable()
end

function AccountServiceProfile.set_password_min_length(self, ctx, value)
    self.m_account_config:set_password_min_length(value)
    self.m_account_service.m_config_changed:emit('MinPasswordLength', value)
end

function AccountServiceProfile.get_password_min_length(self)
    return self.m_account_config:get_password_min_length()
end

function AccountServiceProfile.set_max_password_valid_days(self, ctx, value)
    self.m_account_service:set_max_password_valid_days(value)
    self.m_account_service.m_config_changed:emit('MaxPasswordValidDays', value)
end

function AccountServiceProfile.get_max_password_valid_days(self)
    return self.m_account_config:get_max_password_valid_days()
end

function AccountServiceProfile.set_min_password_valid_days(self, ctx, value)
    self.m_account_config:set_min_password_valid_days(value)
    self.m_account_service.m_config_changed:emit('MinPasswordValidDays', value)
end

function AccountServiceProfile.get_min_password_valid_days(self)
    return self.m_account_config:get_min_password_valid_days()
end

function AccountServiceProfile.set_inactive_time_threshold(self, ctx, value)
    self.m_account_service:set_inactive_time_threshold(value)
    self.m_account_service.m_config_changed:emit('InactiveDaysThreshold', value)
end

function AccountServiceProfile.get_inactive_time_threshold(self)
    return self.m_account_config:get_inactive_time_threshold()
end

function AccountServiceProfile.set_emergency_account(self, ctx, value)
    self.m_account_service:set_emergency_account(ctx, value)
    self.m_account_service.m_config_changed:emit('EmergencyLoginAccountId', value)
end

function AccountServiceProfile.get_emergency_account(self)
    return self.m_account_config:get_emergency_account()
end

function AccountServiceProfile.set_history_password_count(self, ctx, value)
    self.m_account_service:set_history_password_count(value)
    self.m_account_service.m_config_changed:emit('HistoryPasswordCount', value)
end

function AccountServiceProfile.get_history_password_count(self)
    return self.m_account_config:get_history_password_count()
end

function AccountServiceProfile.set_initial_password_prompt_enable(self, ctx, value)
    self.m_account_service:set_initial_password_prompt_enable(value)
    self.m_account_service.m_config_changed:emit('InitialPasswordPromptEnable', value)
end

function AccountServiceProfile.get_initial_password_prompt_enable(self)
    return self.m_account_config:get_initial_password_prompt_enable()
end

function AccountServiceProfile.set_first_login_enable(self, ctx, value)
    self.m_account_service:set_initial_password_need_modify(value)
    self.m_account_service.m_config_changed:emit('InitialPasswordNeedModify', value)
end

function AccountServiceProfile.get_first_login_enable(self)
    return self.m_account_config:get_initial_password_need_modify()
end

function AccountServiceProfile.set_weak_pwd_dictionary_enable(self, ctx, value)
    self.m_account_config:set_weak_pwd_dictionary_enable(value)
    self.m_account_service.m_config_changed:emit('WeakPasswordDictionaryEnabled', value)
end

function AccountServiceProfile.get_weak_pwd_dictionary_enable(self)
    return self.m_account_config:get_weak_pwd_dictionary_enable()
end

function AccountServiceProfile.set_name_pattern(self, ctx, account_type, value)
    self.m_account_policy_collection:set_name_pattern(account_type, value)
end

function AccountServiceProfile.get_name_pattern(self, ctx, account_type)
    return self.m_account_policy_collection:get_name_pattern(account_type)
end

return AccountServiceProfile