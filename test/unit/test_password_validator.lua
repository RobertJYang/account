-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Test passwords:[Paswd@9001, Paswd@9005, Paswd@9006, Paswd9005, Paswd_9005, 9005@Paswd]
local lu = require 'luaunit'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local enum = require 'class.types.types'

local function make_interface()
    local interface = {
        enum.LoginInterface.Redfish, enum.LoginInterface.SFTP,
        enum.LoginInterface.SNMP
    }
    return interface
end

function TestAccount:test_validator_init()
    local validator = self.test_password_validator_collection:get_validator(enum.AccountType.Local:value())
    lu.assertEquals(validator:get_policy(), enum.PasswordRulePolicy.Default:value())
    lu.assertEquals(validator:get_pattern(), "")

    validator = self.test_password_validator_collection:get_validator(enum.AccountType.SnmpCommunity:value())
    lu.assertEquals(validator:get_policy(), enum.PasswordRulePolicy.Default:value())
    lu.assertEquals(validator:get_pattern(), "")

    validator = self.test_password_validator_collection:get_validator(enum.AccountType.VNC:value())
    lu.assertEquals(validator:get_policy(), enum.PasswordRulePolicy.Default:value())
    lu.assertEquals(validator:get_pattern(), "")

    validator = self.test_password_validator_collection:get_validator(enum.AccountType.LDAP:value())
    lu.assertIsNil(validator)
end

function TestAccount:test_set_password_policy()
    -- 1、设置有效的策略
    for policy = enum.PasswordRulePolicy.Default:value(), enum.PasswordRulePolicy.Hybrid:value() do
        self.test_password_validator_collection:set_policy(self.ctx, enum.AccountType.Local:value(), policy)
        lu.assertEquals(self.test_password_validator_collection:get_policy(enum.AccountType.Local:value()), policy)
    end

    -- 2、设置无效的策略
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_password_validator_collection:set_policy(self.ctx, enum.AccountType.Local:value(), 0)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_password_validator_collection:set_policy(self.ctx, enum.AccountType.Local:value(), 4)
    end)

    -- 3、设置有效的正则：常规
    self.test_password_validator_collection:set_pattern(self.ctx, enum.AccountType.Local:value(),
        "^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])[a-zA-Z0-9]{8,20}$")
    
    -- 4、设置有效的正则：边界值255
    local pattern = "^AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAA$"
    self.test_password_validator_collection:set_pattern(self.ctx, enum.AccountType.Local:value(), pattern)

    -- 5、设置无效的正则：非精确匹配
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        self.test_password_validator_collection:set_pattern(self.ctx, enum.AccountType.Local:value(),
            "^[a-zA-Z0-9]{8,20}")
    end)
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        self.test_password_validator_collection:set_pattern(self.ctx, enum.AccountType.Local:value(),
            "[a-zA-Z0-9]{8,20}$")
    end)

    -- 6、设置无效的正则：超长(256)
    pattern = "^AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
        "AAAA$"
    lu.assertErrorMsgContains(custom_msg.StringValueTooLongMessage.Name, function()
        self.test_password_validator_collection:set_pattern(self.ctx, enum.AccountType.Local:value(), pattern)
    end)

    -- end 恢复环境
    self.test_password_validator_collection:set_policy(self.ctx, enum.AccountType.Local:value(),
        enum.PasswordRulePolicy.Default:value())
    self.test_password_validator_collection:set_pattern(self.ctx, enum.AccountType.Local:value(), "")
end

function TestAccount:test_local_account_password_validate()
    local account_id = 3
    -- 1、新建用户
    local account_info = {
        ['id'] = account_id,
        ['name'] = "test5",
        ['password'] = 'Paswd@9001',
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)

    -- 2、设置密码，通过校验（默认场景下使用basic_validate）
    self.test_account_collection:set_account_password(self.ctx, account_id, account_id, 'Paswd@9005')
    -- 3、在默认场景下设置不带特殊字符的密码失败
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection:set_account_password(self.ctx, account_id, account_id, 'Paswd9005')
    end)

    -- 4、设置密码校验模式为指定，设置正则表达式：8-20位密码，包含大小写字母和数字，无特殊字符
    self.test_password_validator_collection:set_pattern(self.ctx, enum.AccountType.Local:value(),
        "^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])[a-zA-Z0-9]{8,20}$")
    self.test_password_validator_collection:set_policy(self.ctx, enum.AccountType.Local:value(),
        enum.PasswordRulePolicy.Customized:value())
    self.test_account_collection:set_account_password(self.ctx, account_id, account_id, 'Paswd9005')

    -- 5、尝试设置默认规则允许但指定规则不允许的密码：带特殊字符
    lu.assertErrorMsgContains(custom_msg.PasswordPatternCheckFailedMessage.Name, function()
        self.test_account_collection:set_account_password(self.ctx, account_id, account_id, 'Paswd@9006')
    end)

    -- 6、设置密码校验模式为混合，设置正则表达式：6-18位，字母开头，只包含字母、数字、下划线
    -- 设置只符合单个密码复杂度的密码
    self.test_password_validator_collection:set_policy(self.ctx, enum.AccountType.Local:value(),
        enum.PasswordRulePolicy.Hybrid:value())
    self.test_password_validator_collection:set_pattern(self.ctx, enum.AccountType.Local:value(),
        "^[a-zA-Z]\\w{5,17}$")
    -- 不符合默认场景的复杂度校验
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection:set_account_password(self.ctx, account_id, account_id, 'Paswd9005')
    end)
    -- 不符合指定正则的复杂度校验
    lu.assertErrorMsgContains(custom_msg.PasswordPatternCheckFailedMessage.Name, function()
        self.test_account_collection:set_account_password(self.ctx, account_id, account_id, '9005@Paswd')
    end)
    -- 两种都符合设置成功
    self.test_account_collection:set_account_password(self.ctx, account_id, account_id, 'Paswd_9005')

    -- end 恢复环境
    self.test_password_validator_collection:set_policy(self.ctx, enum.AccountType.Local:value(),
        enum.PasswordRulePolicy.Default:value())
    self.test_password_validator_collection:set_pattern(self.ctx, enum.AccountType.Local:value(), "")
    self.test_account_collection:delete_account(self.ctx, account_id)
end