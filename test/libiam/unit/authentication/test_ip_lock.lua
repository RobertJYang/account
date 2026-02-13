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
local ip_lock = require 'ip_lock'
local vos_utils = require 'utils.vos'

local TEST_IP_1 = "127.0.0.1"
local TEST_IP_2 = "127.0.0.2"
local TEST_IP_3 = "127.0.0.3"

-- 常规场景下的单IP锁定、解锁查询
function TestIam:test_check_one_ip_lock()
    -- 指定失败次数为3次，10秒内的记录有效，5秒解锁
    local lock_threshold = 3
    local fail_interval  = 10
    local unlock_time = 5

    -- 默认拿到的锁定状态是false
    lu.assertIsFalse(ip_lock.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval, unlock_time))

    -- 增加三次记录后，拿到的锁定状态为true
    for _ = 1, lock_threshold do
        lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1, 0), 0)
    end
    lu.assertIsTrue(ip_lock.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval, unlock_time))

    -- DT下将解锁时间置为5秒，预期6秒后达到查询锁定状态为false
    os.execute("sleep " .. 6)
    lu.assertIsFalse(ip_lock.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval, unlock_time))

    -- 清理锁定记录，会直接删除对应的记录文件
    lu.assertEquals(ip_lock.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_1), 0)
    lu.assertIsFalse(vos_utils.get_file_accessible(self.ip_lock_dir .. "/" .. TEST_IP_1))
    lu.assertIsFalse(ip_lock.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval, unlock_time))
end

-- 两个不同的IP锁定状态互相隔离
function TestIam:test_two_ip_lock_is_independent_of_other()
    -- 指定失败次数为3次，10秒内的记录有效，5秒解锁
    local lock_threshold = 3
    local fail_interval  = 10
    local unlock_time = 5

    -- 对IP1增加三次记录后，IP1的锁定状态为true，IP2的锁定状态依然为false
    for _ = 1, lock_threshold do
        lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1, 0), 0)
    end
    lu.assertIsTrue(ip_lock.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval, unlock_time))
    lu.assertIsFalse(ip_lock.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_2, lock_threshold, fail_interval, unlock_time))

    -- 清理锁定记录
    lu.assertEquals(ip_lock.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_1), 0)
end

-- 在有效时间范围外的记录不计数
function TestIam:test_fali_time_exceed_the_interval_not_lock()
    -- 指定失败次数为2次，2秒内的记录有效，5秒解锁
    local lock_threshold = 2
    local fail_interval  = 3
    local unlock_time = 5

    -- 两次记录间隔为4秒，第一次记录无效，锁定状态理应为false
    lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1, 0), 0)
    os.execute("sleep " .. 4)
    lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1, 0), 0)
    lu.assertIsFalse(ip_lock.get_one_ip_lock_status(self.ip_lock_dir, TEST_IP_1, lock_threshold, fail_interval, unlock_time))

    -- 清理锁定记录
    lu.assertEquals(ip_lock.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_1), 0)
end

-- 测试获取多个不同的IP的锁定状态
function TestIam:test_get_all_ip_lock_records()
    -- 指定失败次数为3次，10秒内的记录有效，5秒解锁
    local lock_threshold = 3
    local fail_interval  = 10
    local unlock_time = 5

    -- 按照期望预期执行，IP1增加3次记录，IP2增加2次记录，IP3增加3次记录
    local suit_table = {
        [TEST_IP_1] = {time = 3, expect_lock_status = true},
        [TEST_IP_2] = {time = 2, expect_lock_status = false},
        [TEST_IP_3] = {time = 3, expect_lock_status = true}
    }

    for k, v in pairs(suit_table) do
        for _ = 1, v.time do
            lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, k, 0), 0)
        end
    end

    -- 查看预期
    local count, records = ip_lock.get_all_ip_lock_status(self.ip_lock_dir, lock_threshold, fail_interval, unlock_time)
    lu.assertEquals(count, 3) -- 预期有3条记录

    -- 对每条记录判断预期
    for _, v in pairs(records) do
        lu.assertEquals(v.lock_status, suit_table[v.ip].expect_lock_status)
        lu.assertNotEquals(v.lock_start_time, 0)
    end

    -- 清理锁定记录
    lu.assertEquals(ip_lock.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_1), 0)
    lu.assertEquals(ip_lock.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_2), 0)
    lu.assertEquals(ip_lock.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_3), 0)
end

-- 测试文件的最大记录数量限制
function TestIam:test_single_ip_fail_record_cnt()
    -- 最大支持100条记录，每条记录72字节
    local max_file_length = 100 * 72

    -- 写入100次，文件达到最大记录
    for _ = 1, 100 do
        lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1, 0), 0)
    end
    lu.assertEquals(vos_utils.get_file_length(self.ip_lock_dir .. "/" .. TEST_IP_1), max_file_length)

    -- 再写入5次，文件大小不会再变更
    for _ = 1, 5 do
        lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, TEST_IP_1, 0), 0)
    end
    lu.assertEquals(vos_utils.get_file_length(self.ip_lock_dir .. "/" .. TEST_IP_1), max_file_length)

    -- 清理锁定记录
    lu.assertEquals(ip_lock.clean_ip_fail_record(self.ip_lock_dir, TEST_IP_1), 0)
end

-- 测试支持记录ip达到最大数量限制
function TestIam:test_all_ip_records_cnt()
    -- 首先增加记录到1000条，均成功
    for i = 1, 1000 do
        lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, tostring(i), 0), 0)
    end

    -- 再进行尝试，无法增加
    lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, "test", 0), -1)

    -- 尝试增加已有的ip的记录，可以成功
    lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, "111", 0), 0)

    -- 清理锁定记录
    lu.assertEquals(ip_lock.clean_all_ip_fail_record(self.ip_lock_dir), 0)
end

-- 测试当传入的ip带端口号时，应当只记录ip
function TestIam:test_ip_with_port_should_count_ip_only()
    local test_ipv4 = {
        "127.0.0.1",
        "127.0.0.1:80",
        "127.0.0.1:8080"
    }
    local test_ipv6 = {
        "2001:db8::1",
        "[2001:db8::1]",
        "[2001:db8::1]:8080",
        "[2001:db8::1]:80"
    }
    local expect_status = {
        ["127.0.0.1"]   = false,
        ["2001:db8::1"] = true
    }

    -- 指定失败次数为4次，10秒内的记录有效，5秒解锁
    local lock_threshold = 4
    local fail_interval  = 10
    local unlock_time = 5

    for _, ip in pairs(test_ipv4) do
        lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, ip, 0), 0)
    end
    for _, ip in pairs(test_ipv6) do
        lu.assertEquals(ip_lock.increase_ip_fail_record(self.ip_lock_dir, ip, 0), 0)
    end

    -- 预期："127.0.0.1"有3条记录，未锁定；"2001:db8::1"有四条记录，锁定
    local count, records = ip_lock.get_all_ip_lock_status(self.ip_lock_dir, lock_threshold, fail_interval, unlock_time)
    lu.assertEquals(count, 2) -- 预期有2条记录，"127.0.0.1"和"2001:db8::1"

    for _, v in pairs(records) do
        lu.assertEquals(v.lock_status, expect_status[v.ip])
    end

    -- 清理记录
    lu.assertEquals(ip_lock.clean_all_ip_fail_record(self.ip_lock_dir), 0)
end