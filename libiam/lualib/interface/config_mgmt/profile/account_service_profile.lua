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
-- Description: 配置导入导出时用户公共服务相关项

local AccountServiceProfile = {}

function AccountServiceProfile.set_account_lockout_threshold(self, ctx, value)
    self.m_authentication_service:set_account_lockout_threshold(value)
    self.m_auth_config.m_config_changed:emit('AccountLockoutThreshold', value)
end

function AccountServiceProfile.get_account_lockout_threshold(self)
    return self.m_auth_config:get_account_lockout_threshold()
end

function AccountServiceProfile.set_account_lockout_duration(self, ctx, value)
    self.m_authentication_service:set_account_lockout_duration(value)
    self.m_auth_config.m_config_changed:emit('AccountLockoutDuration', value)
end

function AccountServiceProfile.get_account_lockout_duration(self)
    return self.m_auth_config:get_account_lockout_duration()
end

return AccountServiceProfile