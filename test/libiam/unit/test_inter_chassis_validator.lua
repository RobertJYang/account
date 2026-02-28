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
local mc_utils = require 'mc.utils'
local base_msg = require 'messages.base'
local lu = require 'luaunit'

local TEST_IP = "127.0.0.1"


function TestIam:test_inter_chassis_ip_whitelist_validate()
    -- 增加白名单
    self.test_inter_chassis_validator:add("IP", TEST_IP)

    -- 查询白名单
    lu.assertEquals(self.test_inter_chassis_validator:get("IP"), {TEST_IP})

    -- 白名单验证
    lu.assertIsTrue(self.test_inter_chassis_validator:validate({['IP'] = TEST_IP}))
    lu.assertIsFalse(self.test_inter_chassis_validator:validate("123"))

    -- 删除白名单
    self.test_inter_chassis_validator:remove("IP", TEST_IP)
    lu.assertEquals(self.test_inter_chassis_validator:get("IP"), {})
end

function TestIam:test_add_whitelist_exceed_limits()
    -- 增加白名单到上限
    for i = 1, 10 do
        self.test_inter_chassis_validator:add("IP", tostring(i))
    end

    local expect_table = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}
    lu.assertIsTrue(mc_utils.table_compare(self.test_inter_chassis_validator:get("IP"), expect_table))

    -- 再尝试增加报错
    lu.assertErrorMsgContains(base_msg.CreateLimitReachedForResourceMessage.Name, function()
        self.test_inter_chassis_validator:add("IP", TEST_IP)
    end)

    -- 恢复
    self.test_inter_chassis_validator:remove("IP", '*')
end

function TestIam:test_invalid_whitelist_type()
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_inter_chassis_validator:add("111", TEST_IP)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_inter_chassis_validator:remove("111", TEST_IP)
    end)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_inter_chassis_validator:get("111")
    end)
end

function TestIam:test_manage_unused_item()
    -- 增加白名单
    self.test_inter_chassis_validator:add("IP", TEST_IP)

    local list = self.test_inter_chassis_validator:get("IP")

    -- 重复增加不会抛错
    self.test_inter_chassis_validator:add("IP", TEST_IP)

    -- 列表不会变化
    lu.assertEquals(self.test_inter_chassis_validator:get("IP"), list)

    -- 删除不存在的白名单不会抛错
    self.test_inter_chassis_validator:remove("IP", "123")

    -- 列表不会变化
    lu.assertEquals(self.test_inter_chassis_validator:get("IP"), list)

    -- 删除白名单
    self.test_inter_chassis_validator:remove("IP", TEST_IP)
    lu.assertEquals(self.test_inter_chassis_validator:get("IP"), {})
end

function TestIam:test_manage_inter_chassis_whitelist()
    -- 查看初始白名单
    local list = self.certificate_authentication:manage_inter_chassis_whitelist(self.ctx, 'Get', 'IP', '')
    lu.assertEquals(list, {})

    -- 增加白名单
    list = self.certificate_authentication:manage_inter_chassis_whitelist(self.ctx, 'Add', 'IP', TEST_IP)
    lu.assertEquals(list, {TEST_IP})

    -- 删除白名单
    list = self.certificate_authentication:manage_inter_chassis_whitelist(self.ctx, 'Remove', 'IP', TEST_IP)
    lu.assertEquals(list, {})

    -- 异常场景1：无效的operation
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.certificate_authentication:manage_inter_chassis_whitelist(self.ctx, '123', 'IP', '')
    end)

    -- 异常场景2：无效的type
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.certificate_authentication:manage_inter_chassis_whitelist(self.ctx, 'Get', '123', '')
    end)
end