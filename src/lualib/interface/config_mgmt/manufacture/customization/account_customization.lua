-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 定制化操作时用户配置相关项
local account_utils = require 'infrastructure.utils'
local user_config = require 'common_config'

local ENABLED_IMPORT_MAP = {
    ['on'] = true,
    ['off'] = false
}

local ENABLED_EXPORT_MAP = {
    [true] = 'on',
    [false] = 'off'
}

local DEFAULT_ADMIN_ID<const> = 2

local AccountCustomization = {}

--- 定制默认用户(Id:2)属性是否可写
---@param value string on,off
--- 支持默认用户锁定(用户名\角色\登录接口\登录权限\使能状态 不可修改)
--- 支持默认用户解锁(所有属性均可写)
function AccountCustomization.set_default_admin_writable(self, ctx, value)
    local writable = ENABLED_IMPORT_MAP[value]
    if writable then
        self.m_account_collection:unlock_all_accounts_properties_writable(ctx)
        return
    end
    local properties_writable_tab = {
        UserNameWritable = writable,
        RoleIdWritable = writable,
        LoginInterfaceWritable = writable,
        LoginRuleIdsWritable = writable,
        EnabledWritable = writable
    }
    self.m_account_collection:set_account_property_writable(ctx, DEFAULT_ADMIN_ID, properties_writable_tab)
end

function AccountCustomization.get_default_admin_writable(self)
    local properties_writable = self.m_account_collection:get_account_property_writable(DEFAULT_ADMIN_ID)
    return ENABLED_EXPORT_MAP[properties_writable.UserNameWritable]
end

function AccountCustomization.convert_vnc_login_rule_ids(custom_settings)
    return account_utils.covert_num_to_login_rule_ids_str(custom_settings['BMCSet_VNCPermitRuleIds'].Value)
end

function AccountCustomization.set_vnc_login_rule_ids(self, ctx, value)
    self.m_account_collection:set_login_rule_ids(ctx, user_config.VNC_ACCOUNT_ID, value)
    local account = self.m_account_collection:get_account_by_account_id(user_config.VNC_ACCOUNT_ID)
    account.m_account_update_signal:emit('LoginRuleIds', value)
end

function AccountCustomization.get_vnc_login_rule_ids(self)
    local account = self.m_account_collection:get_account_by_account_id(user_config.VNC_ACCOUNT_ID)
    return account:get_login_rule_ids()
end

function AccountCustomization.set_oem_account_name(self, ctx, id, value)
    if value == '' then
        self.m_account_collection:delete_account(ctx, id, true)
        return value
    end
    self.m_account_collection:set_user_name(ctx, id, value)
    return value
end

function AccountCustomization.get_oem_account_name(self, id)
    local account = self.m_account_collection.collection[id]
    if not account then
        return ''
    end
    return account:get_user_name()
end

return AccountCustomization