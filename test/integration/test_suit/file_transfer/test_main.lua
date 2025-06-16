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
local test_case_utils = require 'testcase_utils'
local class = require 'mc.class'
local BaseSuit = require 'test_base_suit'
local vos = require 'utils.vos'
local mc_utils = require 'mc.utils'
local utils_core = require 'utils.core'
local gvariant = require 'mc.gvariant'

local PROJECT_DIR = os.getenv('PROJECT_DIR')
local RUN_FT = true -- 是否自动拉起file_transfer，默认自动拉

local PATH_FMT_MANAGER_ACCOUNT_TASK<const> = '/bmc/kepler/AccountService/Accounts/%s/TaskService/Tasks/%s'
local PATH_FMT_ACCOUNT_SERVICE_TASK<const> = '/bmc/kepler/AccountService/TaskService/Tasks/%s'

local function disable_file_transfer_certificate_verify(bus, test_data_dir)
    return bus:call('bmc.kepler.file_transfer', '/bmc/kepler/Managers/1/FileTransfer',
        'org.freedesktop.DBus.Properties', 'Set', 'ssv', 'bmc.kepler.Managers.FileTransfer',
        'HttpsTransferCertVerification', gvariant.new_bool(false))
end

--- 测试导入ssh公钥
local function test_when_import_remote_ssh_key_then_success(bus, test_data_dir)
    log:notice('================ test_when_import_remote_ssh_key_then_success start ================')
    local task_id = test_case_utils.call_account_import_ssh_public_key(bus, 2,
        'URI', 'https://127.0.0.1:8443/openssh_key.pub')
    assert(task_id > 0)
    local rpc_path = string.format(PATH_FMT_MANAGER_ACCOUNT_TASK, 2, task_id)
    while test_case_utils.check_remote_task_completed(bus, rpc_path) == false do
        skynet.sleep(50)
    end
    log:notice('================ test_when_import_remote_ssh_key_then_success end ================')
end

--- 测试导入弱密码字典
local function test_when_import_remote_weakdictionary_then_success(bus, test_data_dir)
    log:notice('================ test_when_import_remote_weakdictionary_then_success start ================')
    local task_id = test_case_utils.call_account_service_import_weakpwd_dict(bus,
        'https://127.0.0.1:8443/weakdictionary')
    assert(task_id > 0)
    local rpc_path = string.format(PATH_FMT_ACCOUNT_SERVICE_TASK, task_id)
    while test_case_utils.check_remote_task_completed(bus, rpc_path) == false do
        skynet.sleep(50)
    end
    log:notice('================ test_when_import_remote_weakdictionary_then_success end ================')
end

-- 初始化功能测试
local FileTransferSuit = class(BaseSuit)

function FileTransferSuit:setup_before_server_stop()
    log:notice('================ test FileTransferSuit setup_before_server_stop ================')
    if RUN_FT then
        -- 清理filetransfer进程
        local bash_path = PROJECT_DIR .. '/test/integration/test_suit/file_transfer/stop.sh'
        utils_core.chmod(bash_path, mc_utils.S_IRWXU | mc_utils.S_IRGRP | mc_utils.S_IXGRP)
        vos.system_s(bash_path, PROJECT_DIR)

        bash_path = PROJECT_DIR .. '/test/integration/test_suit/file_transfer/start.sh'
        utils_core.chmod(bash_path, mc_utils.S_IRWXU | mc_utils.S_IRGRP | mc_utils.S_IXGRP)
        vos.system_s(bash_path, PROJECT_DIR)
        -- 服务启动后，给时间让系统就绪，门禁场景下需要多等一会儿，保证数据库写入
        if string.match(self.test_data_dir, 'V3CODE') then
            skynet.sleep(300)
        end
    else
        log:info('please start file transfer...')
        skynet.sleep(500)
    end
end

function FileTransferSuit:run()
    log:notice('================ test FileTransferSuit start ================')
    --  the functions to be test
    -- 禁用证书校验
    skynet.sleep(100)
    disable_file_transfer_certificate_verify(self.m_bus)
    test_when_import_remote_ssh_key_then_success(self.m_bus, self.test_data_dir)
    test_when_import_remote_weakdictionary_then_success(self.m_bus, self.test_data_dir)
    log:notice('================ test FileTransferSuit complete ================')
end

-- 测试用例环境清理，在本次服务结束时进行
function FileTransferSuit:teardownClass()
    if RUN_FT then
        -- 清理filetransfer进程
        local bash_path = PROJECT_DIR .. '/test/integration/test_suit/file_transfer/stop.sh'
        vos.system_s(bash_path, PROJECT_DIR)
    end
end

return FileTransferSuit
