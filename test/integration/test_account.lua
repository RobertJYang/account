-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

require 'skynet.manager'
local skynet = require 'skynet'
local skynet_config = require 'skynet_config'
local log = require 'mc.logging'
local test_common = require 'test_common.utils'
local mc_utils = require 'mc.utils'
local sd_bus = require 'sd_bus'
local class = require 'mc.class'
local test_prepare_data = require 'test_prepare_data'
local CommonSuit = require 'test_suit.test_common_suit'
local FileTransferSuit = require 'test_suit.file_transfer.test_main'
local test_case_utils = require 'testcase_utils'
local core = require 'account_core'

require 'account.json_types.ManagerAccounts'
require 'account.json_types.ManagerAccount'
require 'account.json_types.AccountService'
require 'account.json_types.Role'
require 'account.json_types.Rule'
require 'account.json_types.LocalAccountAuthN'
require 'account.json_types.SnmpUser'
require 'account.json_types.AccountPolicy'

log:set_log_module_name('account_IT')
log:set_debug_log_type(log.OUT_TYPE_LOCAL)
log:setLevel(log.INFO)
core.set_dt_log_level()

local function prepare_test_data()
    log:notice('== prepare test data')
    local test_data_dir = skynet.getenv('TEST_DATA_DIR')
    test_prepare_data.setup(test_data_dir)
end

local TestServer = class()

function TestServer:ctor()
    assert(os.execute('mkdir -p ' .. skynet.getenv('TEST_DATA_DIR')) == true)
    self.test_data_dir = mc_utils.realpath(skynet.getenv('TEST_DATA_DIR'))
end

function TestServer:init()
    mc_utils.remove_file(self.test_data_dir)
    prepare_test_data()
    test_common.dbus_launch()
    skynet.uniqueservice('sd_bus')
    self.m_bus = sd_bus.open_user(true)
end

-- 依赖服务启动
function TestServer:start_dependency()
    skynet.uniqueservice('persistence/service/main')
    skynet.uniqueservice('key_mgmt/service/main')
    skynet.uniqueservice('maca/service/main')
    skynet.uniqueservice('hwproxy/service/main')
    skynet.uniqueservice('hwdiscovery/service/main')
    skynet.sleep(200)
    skynet.uniqueservice('ipmi_core/service/main')
    skynet.uniqueservice('rmcpd/service/main')
    skynet.uniqueservice('event/service/main')
    skynet.uniqueservice('frudata/service/main')
    skynet.uniqueservice('bmc_network/service/main')
    skynet.sleep(200)
    -- 设置日志级别
    test_case_utils.set_log_level(self.m_bus, {'persistence', 'key_mgmt', 'trust'}, 'info')
end

-- 所有服务退出
function TestServer:stop()
    skynet.timeout(0, function()
        skynet.sleep(20)
        skynet.abort()
        log:notice('- clear test data')
        mc_utils.remove_file(self.test_data_dir)
    end)
end

-- 主服务开启
function TestServer:start_main()
    self.id = skynet.newservice('main')
    -- 设置日志级别
    test_case_utils.set_log_level(self.m_bus, {'account'}, 'info')
    log:notice('==== main server start, server id: %d ====', self.id)
end

-- 主服务停止
function TestServer:stop_main()
    skynet.call(skynet_config.SERVICE_NAME, 'lua', 'exit')
    while skynet.localname(skynet_config.SERVICE_NAME) == self.id do
        skynet.sleep(30)
    end
    log:notice('==== main server stop, server id: %d ====', self.id)
    self.id = nil
end

-- 执行如下动作：
-- first_suit setup_before_server_stop
-- 服务启动
-- first_suit setupClass
-- first_suit run
-- first_suit teardownClass
-- next_suit setup_before_server_running
-- 服务停止
function TestServer:run_suit(first_suit, next_suit)
    assert(self.id == nil)
    first_suit:setup_before_server_stop()
    self:start_main()
    first_suit:setupClass()
    first_suit:run()
    first_suit:teardownClass()
    if next_suit then
        -- 必须要先设置下一个用例的数据，再停止main服务
        next_suit:setup_before_server_running()
    end
    self:stop_main()
end

local function run()
    local ts = TestServer.new()
    local cs = CommonSuit.new(ts.m_bus, ts.test_data_dir)
    local fts = FileTransferSuit.new(ts.m_bus, ts.test_data_dir)
    ts:start_dependency()
    skynet.fork_once(function()
        local ok, err = pcall(function ()
            ts:run_suit(cs, fts)
            ts:run_suit(fts, nil)
        end)
        ts:stop()
        if not ok then
            log:notice('error: %s', tostring(err))
            error('=== test failed ===')
        end
    end)
end

skynet.start(run)
