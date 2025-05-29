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
local config = require 'common_config'
local utils_core = require 'utils.core'
local account_core = require 'account_core'
local custom_msg = require 'messages.custom'
local enum = require 'class.types.types'
local base_msg = require 'messages.base'
local log = require 'mc.logging'
local utils = require 'infrastructure.utils'
local account_policy = require 'domain.account_policies.account_policy'

local LocalAccountPolicy = class(account_policy)

return singleton(LocalAccountPolicy)