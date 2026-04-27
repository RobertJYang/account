-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 配置导入导出时用户配置相关项
local log = require 'mc.logging'
local custom_msg = require 'messages.custom'
local account_enum = require 'class.types.types'
local account_utils = require 'infrastructure.utils'
local enum = require 'class.types.types'
local operation_logger = require 'interface.operation_logger'


local AccountProfile = {}

local function enable_login_interface_check(old_interfaces, new_interfaces, check_interface)
    if not account_utils.check_login_interface_enabled(old_interfaces, check_interface) and
        account_utils.check_login_interface_enabled(new_interfaces, check_interface) then
        return true
    end
    return false
end

-- 用户导入前的预校验，支持新增和删除用户
function AccountProfile.import_precheck(profile_adapter, ctx, accounts)
    local instance_name
    local instance_id
    for _, instance in ipairs(accounts) do
        if instance.Id.Import == false or instance.UserName.Import == false then
            goto continue
        end
        instance_id = instance.Id.Value
        instance_name = instance.UserName.Value
        -- 配置导入存在用户，但是环境不存在，需要新建用户
        if profile_adapter.m_account_collection:get_account_data_by_id(instance_id) == nil then
            -- 新建用户，第三个参数为true代表当前新建用户走ipmi流程，不创建密码
            local ok, err = pcall(function()
                operation_logger.proxy(function(_, dbus_ctx)
                    AccountProfile.set_user_name(profile_adapter, dbus_ctx, instance_id, instance.UserName.Value)
                end, 'IpmiNewAccount')(nil, ctx)
            end)
            if not ok then
                log:error("import account config precheck failed, cannot add account(id:%d), %s", instance_id,
                    tostring(err))
            end
            goto continue
        end
        -- 配置导入时用户名为空，设备存在此用户，需要删除用户；删除用户后，需要移除待配置用户
        if instance_name == '' and profile_adapter.m_account_collection:get_account_data_by_id(instance_id) ~= nil then
            local ok, ret = pcall(function()
                operation_logger.proxy(function(_, dbus_ctx)
                    AccountProfile.set_user_name(profile_adapter, dbus_ctx, instance_id, '')
                end, 'IpmiDeleteAccount')(nil, ctx)
            end)
            if not ok then
                log:error("import account config precheck failed, cannot delete account(id:%d), %s", instance_id,
                    tostring(ret))
            end
        end
        ::continue::
    end
end

-- 导入前过滤已删除的用户配置
function AccountProfile.import_filter(profile_adapter, ctx, accounts)
    local filter_deleted_accounts = {}
    local instance_name
    for _, instance in ipairs(accounts) do
        instance_name = instance.UserName.Value
        -- 配置导入时用户名为空，设备存在此用户，需要删除用户；删除用户后，需要移除待配置用户
        if instance_name ~= '' then
            -- 无需删除的用户，过滤后返回继续处理
            filter_deleted_accounts[#filter_deleted_accounts+1] = instance
        end
    end
    return filter_deleted_accounts
end

function AccountProfile.set_account_id(self, ctx, account_id)
    if not self.m_account_collection.collection[account_id] then
        error(custom_msg.InvalidValue('Id', account_id))
    end
end

function AccountProfile.get_account_id(self, account_id)
    if not self.m_account_collection.collection[account_id] then
        return nil
    end
    return account_id
end

function AccountProfile.set_user_name(self, ctx, account_id, value)
    if not self.m_account_policy_collection:check_user_name(enum.AccountType.Local:value(), value) and value ~= '' then
        error(custom_msg.InvalidUserName())
    end
    local is_add = self.m_account_collection:get_account_data_by_id(account_id) == nil

    self.m_account_collection:set_user_name(ctx, account_id, value)
    if is_add then
        local account = self.m_account_collection:get_account_by_account_id(account_id)
        account.m_account_update_signal:emit('UserName', value)
    end
end

function AccountProfile.get_user_name(self, account_id)
    return self.m_account_collection:get_user_name(account_id)
end

function AccountProfile.set_role_id(self, ctx, account_id, value)
    local role_id = account_enum.RoleType[value]:value()
    self.m_account_collection:set_role_id(ctx, account_id, role_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    account.m_account_update_signal:emit('RoleId', role_id)
end

function AccountProfile.get_role_id(self, account_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    local role_id = account:get_role_id()
    return tostring(account_enum.RoleType.new(role_id))
end

function AccountProfile.set_login_interface(self, ctx, account_id, value)
    local old_interface_num = self.m_account_collection:get_login_interface(account_id)
    if enable_login_interface_check(old_interface_num, value, account_enum.LoginInterface.IPMI) or
        enable_login_interface_check(old_interface_num, value, account_enum.LoginInterface.SNMP) then
        local user_name = self.m_account_collection:get_user_name(account_id)
        log:error('set %s\'s login interface failed, IPMI/SNMP cannot be enabled without password', user_name)
        ctx.operation_log.params.username = user_name
        ctx.operation_log.result = 'fail'
        return
    end
    self.m_account_collection:set_login_interface(ctx, account_id, value)
    local new_interface_num = self.m_account_collection:get_login_interface(account_id)
    local change = account_utils.get_login_interface_or_rule_ids_change(old_interface_num,
        new_interface_num, account_utils.convert_num_to_interface_str)
    if not change then
        ctx.operation_log.operation = 'SkipLog'
    end
    ctx.operation_log.params.change = change
    self.m_account_collection.m_account_changed:emit(account_id, "LoginInterface", value)
end

function AccountProfile.get_login_interface(self, account_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    local login_interface_num = account:get_login_interface()
    return account_utils.convert_num_to_interface_str(login_interface_num, true)
end

function AccountProfile.set_login_rule_ids(self, ctx, account_id, value)
    self.m_account_collection:set_login_rule_ids(ctx, account_id, value)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    account.m_account_update_signal:emit('LoginRuleIds', value)
end

function AccountProfile.get_login_rule_ids(self, account_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    local login_rule_ids_num = account:get_login_rule_ids()
    return account_utils.covert_num_to_login_rule_ids_str(login_rule_ids_num)
end

function AccountProfile.get_account_enabled(self, account_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    return account:get_enabled()
end

function AccountProfile.get_account_locked(self, account_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    return account:get_locked()
end

function AccountProfile.get_snmp_privacy_password_init_status(self, account_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    return account:get_snmp_privacy_password_init_status()
end

local first_login_policy_str_to_num = {
    ['PromptPasswordReset'] = enum.FirstLoginPolicy.PromptPasswordReset:value(),
    ['ForcePasswordReset'] = enum.FirstLoginPolicy.ForcePasswordReset:value()
}

function AccountProfile.get_first_login_policy(self, account_id)
    local account = self.m_account_collection:get_account_by_account_id(account_id)
    return tostring(account:get_first_login_policy())
end

function AccountProfile.set_first_login_policy(self, ctx, account_id, value)
    local policy_num = first_login_policy_str_to_num[value]
    self.m_account_collection:set_first_login_policy(ctx, account_id, policy_num)
    self.m_account_collection.m_account_changed:emit(account_id, "FirstLoginPolicy", policy_num)
end

return AccountProfile
