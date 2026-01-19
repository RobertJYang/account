-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Test passwords:[Admin@9000]
local log = require 'mc.logging'
local class = require 'mc.class'
local skynet = require 'skynet'
local base_suit = require 'test_base_suit'
local test_case_utils = require 'testcase_utils'
local account_case = require 'test_suit.account.testcase_account'
local inter_chassis_case = require 'test_suit.account.test_inter_chassis_account'
local password_validator_ipmi_case = require 'test_suit.password_validator.testcase_password_validator_ipmi'
local account_service_ipmi_case = require 'test_suit.account.testcase_account_service_ipmi'
local role_case = require 'test_suit.role.testcase_role'

require 'account.json_types.PasswordPolicy'
require 'account.json_types.Roles'

local CommonSuit = class(base_suit)

function CommonSuit:setupClass()
    log:notice('================ test CommonSuit setupClass ================')
    -- 初始化所有依赖的外部模块对象订阅
    skynet.sleep(100)
    -- 准备初始数据
    test_case_utils.call_account_change_pwd(self.m_bus, 2, 'Admin@9000')
end

-- 基础功能测试
function CommonSuit:run()
    log:notice('================ test base_function_test start ================')
    skynet.sleep(1000)
    self:run_case_suit(account_case, self.m_bus)
    self:run_case_suit(password_validator_ipmi_case, self.m_bus)
    self:run_case_suit(account_service_ipmi_case, self.m_bus)
    self:run_case_suit(role_case, self.m_bus)
    self:run_case_suit(inter_chassis_case, self.m_bus)
    log:notice('================ test base_function_test complete ================')
end

return CommonSuit