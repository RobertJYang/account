-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local mc_context = require 'mc.context'
local custom_msg = require 'messages.custom'
local enum = require 'class.types.types'
local err_cfg = require 'error_config'


function TestAccount:test_do_auth()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    -- 新建用户
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
            enum.LoginInterface.SFTP, enum.LoginInterface.Web },
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(ctx, account_info, false)

    local ctx_auth = mc_context.new('Web', 'test3', '127.0.0.1')
    local account = self.test_authentication:authenticate(ctx_auth, 'test3', 'Paswd@9001', {["IsAuthPassword"] = true})
    lu.assertEquals(account.Id, "3")
    lu.assertEquals(account.UserName, 'test3')
    lu.assertErrorMsgContains(custom_msg.AuthorizationFailedMessage.Name, function()
        self.test_authentication:authenticate(ctx_auth, 'test3', 'Paswd@90000', {["IsAuthPassword"] = true})
    end)
    lu.assertErrorMsgContains(custom_msg.AuthorizationFailedMessage.Name, function()
        self.test_authentication:authenticate(ctx_auth, 'test3', 'Paswd@9000', {["IsAuthPassword"] = true})
    end)

    -- 恢复环境
    self.test_account_collection:delete_account(ctx, 3)
    lu.assertIsNil(self.test_account_collection.collection[3])
end

function TestAccount:test_local_authentication_with_login_rule()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    -- 新建用户
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
            enum.LoginInterface.SFTP, enum.LoginInterface.Web },
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(ctx, account_info, false)

    -- 场景1：单条登录规则不满足，拦截
    -- 配置登录规则
    self.test_login_rule_collection:set_enable(1, true)
    self.test_login_rule_collection:set_ip_rule(1, "196.128.0.1")
    self.test_account_collection:set_login_rule_ids(ctx, 3, {'Rule1'})

    local ctx_auth = mc_context.new('Web', 'test3', '196.128.0.2')
    -- 尝试认证，应失败
    lu.assertErrorMsgContains(custom_msg.UserLoginRestrictedMessage.Name, function()
        self.test_authentication:authenticate(ctx_auth, 'test3', 'Paswd@9001', {["IsAuthPassword"] = true})
    end)

    -- 场景2：多条登录规则，一条满足，不拦截
    self.test_login_rule_collection:set_enable(2, true)
    self.test_login_rule_collection:set_ip_rule(2, "196.128.0.2")
    self.test_account_collection:set_login_rule_ids(ctx, 3, {'Rule1', 'Rule2'})

    -- 尝试认证，应成功
    local account = self.test_authentication:authenticate(ctx_auth, 'test3', 'Paswd@9001', {["IsAuthPassword"] = true})
    lu.assertEquals(account.Id, "3")

    -- 场景3：多条登录规则均不满足，拦截
    self.test_login_rule_collection:set_ip_rule(2, "196.128.0.3")

    -- 尝试认证，应失败
    lu.assertErrorMsgContains(custom_msg.UserLoginRestrictedMessage.Name, function()
        self.test_authentication:authenticate(ctx_auth, 'test3', 'Paswd@9001', {["IsAuthPassword"] = true})
    end)

    -- 场景4：在用户配置登陆规则后关闭某条使能，剩余一条不满足，拦截
    self.test_login_rule_collection:set_enable(2, false)

    -- 尝试认证，应失败
    lu.assertErrorMsgContains(custom_msg.UserLoginRestrictedMessage.Name, function()
        self.test_authentication:authenticate(ctx_auth, 'test3', 'Paswd@9001', {["IsAuthPassword"] = true})
    end)

    -- 场景5：在4的基础上，被禁用的一条是满足规则的，拦截
    self.test_login_rule_collection:set_ip_rule(2, "196.128.0.2")

    -- 尝试认证，应失败
    lu.assertErrorMsgContains(custom_msg.UserLoginRestrictedMessage.Name, function()
        self.test_authentication:authenticate(ctx_auth, 'test3', 'Paswd@9001', {["IsAuthPassword"] = true})
    end)

    -- 恢复环境
    self.test_account_collection:delete_account(ctx, 3)
    lu.assertIsNil(self.test_account_collection.collection[3])

    self.test_login_rule_collection:set_ip_rule(1, "")
    self.test_login_rule_collection:set_ip_rule(2, "")
    self.test_login_rule_collection:set_enable(1, false)
    self.test_login_rule_collection:set_enable(2, false)
end

function TestAccount:test_password()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    -- 新建用户
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
            enum.LoginInterface.SFTP, enum.LoginInterface.Web },
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(ctx, account_info, false)

    local result = self.test_authentication:test_ipmi_password("test3", "Paswd@9001")
    lu.assertEquals(tonumber(result.code), err_cfg.USER_OPER_SUCCESS)

    result = self.test_authentication:test_ipmi_password("test000", "Paswd@9001")
    lu.assertEquals(tonumber(result.code), err_cfg.USER_UNSUPPORT)

    result = self.test_authentication:test_ipmi_password("test3", "Paswd@9003")
    lu.assertEquals(tonumber(result.code), err_cfg.PASSWORD_TEST_FAILED1)

    -- 恢复环境
    self.test_account_collection:delete_account(ctx, 3)
    lu.assertIsNil(self.test_account_collection.collection[3])
end