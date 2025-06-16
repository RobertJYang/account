-- Copyright (c) 2025 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local manager_account = require 'domain.manager_account.manager_account'

local inter_chassis_account = class(manager_account)

function inter_chassis_account:set_role_id(role_id)
    self.m_account_data.RoleId = role_id
    self.m_account_data:save()
    self:update_privileges()
end

--内部账户无设置，使用默认值
function inter_chassis_account:get_password_change_required()
    return false
end

return inter_chassis_account