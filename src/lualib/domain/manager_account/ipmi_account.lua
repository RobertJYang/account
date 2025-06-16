-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local manager_account = require 'domain.manager_account.manager_account'
local config = require 'common_config'

local ipmi_account = class(manager_account)

function ipmi_account:set_role_id(role_id)
    self.m_account_data.RoleId = role_id
    self.m_account_data:save()
    self:update_privileges()
end

--ipmi内部账户无设置，使用默认值
function ipmi_account:get_password_change_required()
    return false
end

-- 获取hmm内部账户
function ipmi_account:get_hmm_user()
    -- ipmi内部账户根据场景涉及不同内部账户
    -- OS内为<host sms>账户
    -- 框内计算板(计算节点),涉及<hmm>账户
    self.hmm_account = {
        m_account_data = {
            UserName = config.USER_NAME_FOR_HMM,
            Id = config.USER_NAME_FOR_HMM_ID,
            LastLoginIP = '',
            LastLoginTime = 0,
            RoleId = 0,
        }
    }
    function self.hmm_account:set_role_id(role_id)
        self.m_account_data.RoleId = role_id
    end
    function self.hmm_account:get_account_data()
        return self.m_account_data
    end
    return self.hmm_account
end

return ipmi_account