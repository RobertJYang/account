-- Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
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
local enum = require 'class.types.types'

function TestIam:test_account_policy_visible()
    local visible = self.account_policy_cache:get_visible('Test')
    lu.assertEquals(visible, nil)

    visible = self.account_policy_cache:get_visible(enum.AccountType.InterChassis)
    lu.assertEquals(visible, nil)
end