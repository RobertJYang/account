-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local login_mac_rule = require 'domain.login_rule.login_mac_rule'
local base_msg = require 'messages.base'

function TestAccount:test_login_rule_manager_should_success()
    self.test_login_rule_collection:set_ip_rule(3, '1000::/128')
    self.test_login_rule_collection:set_ip_rule(3, '')

    self.test_login_rule_collection:set_mac_rule(3, '01:01:01:01:01:01')
    self.test_login_rule_collection:set_mac_rule(3, '')

    self.test_login_rule_collection:set_time_rule(3, '2023-01-04 16:00/2023-01-04 17:00')
    self.test_login_rule_collection:set_time_rule(3, '')
end

