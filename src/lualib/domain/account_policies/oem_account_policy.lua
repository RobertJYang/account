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
local config = require 'common_config'
local account_policy = require 'domain.account_policies.account_policy'
local core = require 'account_core'

local OemAccountPolicy = class(account_policy)

return singleton(OemAccountPolicy)