-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local test_target = require 'domain.privilege'
local lu = require 'luaunit'

function TestAccount:test_privilege_add()
    local a = test_target.new(false, true, true, false, false, false, false, false, false)
    local b = test_target.new(true, true, false, false, false, false, false, false, false)
    local c = a + b
    lu.assertEquals(c.m_UserMgmt, true)
    lu.assertEquals(c.m_BasicSetting, true)
    lu.assertEquals(c.m_KVMMgmt, true)
    lu.assertEquals(c.m_ReadOnly, false)
end
