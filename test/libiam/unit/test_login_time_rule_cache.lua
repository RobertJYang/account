-- Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
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

function TestIam:test_login_time_rule_get_format_type()
    local rule1 = '2025-01-23/2025-01-26'
    local res1 = self.login_time_rule_cache.get_format_type(rule1)
    lu.assertEquals(res1, "YMD")
    local rule2 = '15:40/16:40'
    local res2 = self.login_time_rule_cache.get_format_type(rule2)
    lu.assertEquals(res2, "HM")
end