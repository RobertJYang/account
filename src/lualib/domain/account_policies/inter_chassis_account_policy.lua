-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local base_msg = require 'messages.base'
local account_policy = require 'domain.account_policies.account_policy'

local InterChassisAccountPolicy = class(account_policy)

function InterChassisAccountPolicy:set_name_pattern()
    log:error("inter chassis account cannot set name pattern")
    error(base_msg.ActionNotSupported('set InterChassis name pattern'))
end

function InterChassisAccountPolicy:set_visible()
    log:error("inter chassis account cannot set visible")
    error(base_msg.ActionNotSupported('set InterChassis name visible'))
end

function InterChassisAccountPolicy:set_deletable()
    log:error("inter chassis account cannot set deletable")
    error(base_msg.ActionNotSupported('set InterChassis name deletable'))
end

function InterChassisAccountPolicy:set_online_deletable()
    -- 此处不抛错，但也无实际动作，避免上游处理失败
    log:error("inter chassis account cannot set online deletable")
end

return singleton(InterChassisAccountPolicy)