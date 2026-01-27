-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.

local lu = require 'luaunit'
local iam_core = require 'iam_core'
local vos_utils = require 'utils.vos'

local TEST_IP_1 = "127.0.0.1"
local TEST_IP_2 = "127.0.0.2"
local TEST_IP_3 = "127.0.0.3"

-- 常规场景下的单IP锁定、解锁查询
function TestIam:test_check_one_ip_lock()
    -- 指定失败次数为3次，10秒内的记录有效
    local lock_threshold = 3
    local fail_interval  = 10

    -- 默认拿到的锁定状态是false
    lu.assertIsFalse(iam_core.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval))

    -- 增加三次记录后，拿到的锁定状态为true
    for _ = 1, lock_threshold do
        iam_core.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1)
    end
    lu.assertIsTrue(iam_core.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval))

    -- DT下将解锁时间置为5秒，预期6秒后达到查询锁定状态为false
    os.execute("sleep " .. 6)
    lu.assertIsFalse(iam_core.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval))

    -- 清理锁定记录，会直接删除对应的记录文件
    lu.assertEquals(iam_core.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_1), 0)
    lu.assertIsFalse(vos_utils.get_file_accessible(self.ip_lock_dir .. "/" .. TEST_IP_1))
    lu.assertIsFalse(iam_core.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval))
end

-- 两个不同的IP锁定状态互相隔离
function TestIam:test_two_ip_lock_is_independent_of_other()
    -- 指定失败次数为3次，10秒内的记录有效
    local lock_threshold = 3
    local fail_interval  = 10

    -- 对IP1增加三次记录后，IP1的锁定状态为true，IP2的锁定状态依然为false
    for _ = 1, lock_threshold do
        iam_core.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1)
    end
    lu.assertIsTrue(iam_core.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval))
    lu.assertIsFalse(iam_core.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_2, lock_threshold, fail_interval))

    -- 清理锁定记录
    lu.assertEquals(iam_core.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_1), 0)
end

-- 在有效时间范围外的记录不计数
function TestIam:test_fali_time_exceed_the_interval_not_lock()
    -- 指定失败次数为2次，2秒内的记录有效
    local lock_threshold = 2
    local fail_interval  = 3

    -- 两次记录间隔为4秒，第一次记录无效，锁定状态理应为false
    iam_core.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1)
    os.execute("sleep " .. 4)
    iam_core.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1)
    lu.assertIsFalse(iam_core.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval))

    -- 清理锁定记录
    lu.assertEquals(iam_core.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_1), 0)
end

-- 测试获取多个不同的IP的锁定状态
function TestIam:test_get_all_ip_lock_records()
    -- 指定失败次数为3次，10秒内的记录有效
    local lock_threshold = 3
    local fail_interval  = 10

    -- 按照期望预期执行，IP1增加3次记录，IP2增加2次记录，IP3增加3次记录
    local suit_table = {
        [TEST_IP_1] = {time = 3, expect_lock_status = true},
        [TEST_IP_2] = {time = 2, expect_lock_status = false},
        [TEST_IP_3] = {time = 3, expect_lock_status = true}
    }

    for k, v in pairs(suit_table) do
        for _ = 1, v.time do
            iam_core.increase_ip_fail_record(self.ip_lock_dir, k)
        end
    end

    -- 查看预期
    local count, records = iam_core.get_all_ip_lock_status(self.ip_lock_dir, lock_threshold, fail_interval)
    lu.assertEquals(count, 3) -- 预期有3条记录

    -- 对每条记录判断预期
    for _, v in pairs(records) do
        lu.assertEquals(v.lock_status, suit_table[v.ip].expect_lock_status)
        if suit_table[v.ip].expect_lock_status then
            -- 因为lock_start_time是个时间戳不好断言，所以仅判断是否为0
            lu.assertNotEquals(v.lock_start_time, 0)
        else
            lu.assertEquals(v.lock_start_time, 0)
        end
    end

    -- 清理锁定记录
    lu.assertEquals(iam_core.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_1), 0)
    lu.assertEquals(iam_core.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_2), 0)
    lu.assertEquals(iam_core.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_3), 0)
end