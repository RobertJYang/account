-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local skynet = require 'skynet'
local log = require 'mc.logging'
local class = require 'mc.class'

local TestSuit = class()

function TestSuit:ctor(bus, test_data_dir)
    self.m_bus = bus
    self.test_data_dir = test_data_dir
end

-- 测试用例条件预置，在上次服务启动时进行
function TestSuit:setup_before_server_running()

end

-- 测试用例条件预置，在上次服务停止时进行，一般为数据库、文件类操作
function TestSuit:setup_before_server_stop()

end

-- 测试用例条件预置，在本次服务启动时进行
function TestSuit:setupClass()

end

-- 测试用例环境清理，在本次服务结束时进行
function TestSuit:teardownClass()

end

-- 测试用例条件预置，在服务启动时进行
function TestSuit:run()
    error("Not implemented")
end

local case_index = 0
function TestSuit:run_case_suit(case_suit)
    table.sort(case_suit)
    for name, case in pairs(case_suit) do
        if name ~= '__index' then
            case_index = case_index + 1
            log:notice('==== Index:%d: test %s start ====', case_index, name)
            -- 保证ipmi稳定性,使用ipmitool的集成测试方式需要经历完整的rcmp认证过程
            local is_ipmi = string.find(name, "ipmi")
            if is_ipmi then
                skynet.sleep(10)
            end
            case(self.m_bus, self.test_data_dir)
            log:notice('==== Index:%d: test %s end ====', case_index, name)
        end
    end
end

return TestSuit