-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local iam_error = require 'iam.errors'
local custom_msg = require 'messages.custom'

local VNC_ACCOUNT_ID = 18   -- vnc用户Id

-- 关闭密码复杂度设置密码应成功
function TestIam:test_set_vnc_pwd_when_disable_password_complexity_check()
    local pwd_complexity = self.global_account_config:get_password_complexity_enable()
    self.global_account_config:set_password_complexity_enable(false)
    self.test_account_collection:set_account_password(self.ctx, 2, VNC_ACCOUNT_ID, '1')
    local vnc_account = self.test_account_collection.collection[VNC_ACCOUNT_ID]
    lu.assertEquals('1', vnc_account:get_vnc_pwd_plaintext())
    self.test_account_collection:set_account_password(self.ctx, 2, VNC_ACCOUNT_ID, '@#$%^&*(')
    vnc_account = self.test_account_collection.collection[VNC_ACCOUNT_ID]
    lu.assertEquals('@#$%^&*(', vnc_account:get_vnc_pwd_plaintext())
    self.test_account_collection:set_account_password(self.ctx, 2, VNC_ACCOUNT_ID, 'abcABC')
    vnc_account = self.test_account_collection.collection[VNC_ACCOUNT_ID]
    lu.assertEquals('abcABC', vnc_account:get_vnc_pwd_plaintext())
    -- 恢复环境
    vnc_account:clear_vnc_password()
    self.global_account_config:set_password_complexity_enable(pwd_complexity)
end

-- 关闭密码复杂度时检查超长密码,错误符合预期
function TestIam:test_check_vnc_conditions_error_should_correct_when_disable_password_complexity()
    local pwd_complexity = self.global_account_config:get_password_complexity_enable()
    self.global_account_config:set_password_complexity_enable(false)
    lu.assertErrorMsgContains(iam_error.InvalidPasswordLength, function()
        self.test_account_collection.collection[VNC_ACCOUNT_ID]:password_validator(self.ctx, '<vnc>', '123456789')
    end)
    self.global_account_config:set_password_complexity_enable(pwd_complexity)
end

-- 开启密码复杂度检查合规密码应成功
function TestIam:test_check_vnc_password_validate_when_enable_password_complexity_check()
    local pwd_complexity = self.global_account_config:get_password_complexity_enable()
    self.global_account_config:set_password_complexity_enable(true)
    self.test_account_collection:set_account_password(self.ctx, 2, VNC_ACCOUNT_ID, '123abc`~')
    local vnc_account = self.test_account_collection.collection[VNC_ACCOUNT_ID]
    lu.assertEquals('123abc`~', vnc_account:get_vnc_pwd_plaintext())
    self.test_account_collection:set_account_password(self.ctx, 2, VNC_ACCOUNT_ID, 'Admin pw')
    vnc_account = self.test_account_collection.collection[VNC_ACCOUNT_ID]
    lu.assertEquals('Admin pw', vnc_account:get_vnc_pwd_plaintext())
    -- 恢复环境
    vnc_account:clear_vnc_password()
    self.global_account_config:set_password_complexity_enable(pwd_complexity)
end

-- 开启密码复杂度时检查不合规密码,错误符合预期
function TestIam:test_check_vnc_conditions_error_should_correct_when_enable_password_complexity()
    local pwd_complexity = self.global_account_config:get_password_complexity_enable()
    self.global_account_config:set_password_complexity_enable(true)
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection.collection[VNC_ACCOUNT_ID]:password_validator(self.ctx, '<vnc>', '1234567')
    end)
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection.collection[VNC_ACCOUNT_ID]:password_validator(self.ctx, '<vnc>', '12345678')
    end)
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection.collection[VNC_ACCOUNT_ID]:password_validator(self.ctx, '<vnc>', '1234abcd')
    end)
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection.collection[VNC_ACCOUNT_ID]:password_validator(self.ctx, '<vnc>', '1234ABcd')
    end)
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection.collection[VNC_ACCOUNT_ID]:password_validator(self.ctx, '<vnc>', '!@#$%^&*')
    end)
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection.collection[VNC_ACCOUNT_ID]:password_validator(self.ctx, '<vnc>', '1234%^&*')
    end)
    self.global_account_config:set_password_complexity_enable(pwd_complexity)
end

-- 
function TestIam:test_check_vnc_password_expiration_should_correct_when_set_max_password_valid_days()
    local old_pwd_day = self.global_account_config:get_max_password_valid_days()
    self.test_account_collection:set_account_password(self.ctx, 2, VNC_ACCOUNT_ID, 'Admin@90')
    self.test_account_service:set_max_password_valid_days(20)
    local vnc_account = self.test_account_collection.collection[VNC_ACCOUNT_ID]
    lu.assertEquals(20, vnc_account:get_password_valid_time())
    self.test_account_service:set_max_password_valid_days(0)
    lu.assertEquals(0xffffffff, vnc_account:get_password_valid_time())
    -- 恢复操作
    vnc_account:clear_vnc_password()
    self.global_account_config:set_max_password_valid_days(old_pwd_day)
end
