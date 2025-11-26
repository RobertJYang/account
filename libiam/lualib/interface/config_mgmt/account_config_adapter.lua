-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 支持account与iam的兼容性配置策略

local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local cjson = require 'cjson'
local client = require 'iam.client'
local base_messages = require 'messages.base'

local ACCOUNT_MICRO_COMPONENT_PATH = '/bmc/kepler/account/MicroComponent'

local function get_account_config_mgmt_obj()
    local objs = client:GetConfigManageObjects()
    for path, obj in pairs(objs) do
        -- 寻找account组件
        if path == ACCOUNT_MICRO_COMPONENT_PATH then
            return obj
        end
    end
    log:error('get account config mgmt obj failed.')
    error(base_messages.InternalError())
end


local AccountConfigAdapter = class()

function AccountConfigAdapter:ctor()
end

function AccountConfigAdapter:_split_account_config_from_iam(config_data)
    local account_data = {}
    account_data['User'] = config_data['User']
    account_data['UserRole'] = config_data['UserRole']
    account_data['PasswdSetting'] = config_data['PasswdSetting']
    account_data['PermitRule'] = config_data['PermitRule']
    if config_data['SecurityEnhance'] then
        account_data['SecurityEnhance'] = config_data['SecurityEnhance']
        account_data['SecurityEnhance'].AuthFailMax = nil
        account_data['SecurityEnhance'].AuthFailLockTime = nil
    end
    return account_data
end


function AccountConfigAdapter:on_import(ctx, config_data, import_type)
    local object = cjson.decode(config_data)
    local object_config_data = object.ConfigData
    local object_config_data_for_account = self:_split_account_config_from_iam(object_config_data)
    object.ConfigData = object_config_data_for_account
    local config_data_for_account = cjson.encode(object)
    -- call account
    local account_mgmt_obj = get_account_config_mgmt_obj()
    account_mgmt_obj:Import(ctx, config_data_for_account, import_type)
end


return singleton(AccountConfigAdapter)