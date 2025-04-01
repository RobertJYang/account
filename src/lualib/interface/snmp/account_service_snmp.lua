-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

local class = require 'mc.class'
local singleton = require 'mc.singleton'
local mc_utils = require 'mc.utils'

local AccountServiceSNMP = class()

function AccountServiceSNMP:ctor(account_service)
    self.m_account_service = account_service
end

function AccountServiceSNMP:init()
end

function AccountServiceSNMP:new_account(ctx, user_id, user_name)
    -- SNMP与IPMI创建新用户时仅添加用户名，共用同一个操作日志
    ctx.operation_log.operation = 'IpmiNewAccount'
    user_name = mc_utils.trim_tail_zero(user_name)
    self.m_account_service.m_account_collection:set_user_name(ctx, user_id, user_name)
    self.m_account_service:check_user_time_info()
    return user_id
end

return singleton(AccountServiceSNMP)