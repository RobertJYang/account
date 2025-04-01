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
local mc_utils = require 'mc.utils'
local core = require 'account_core'
local file_utils = require 'utils.file'

local M = {}

local function copy_file_real_path(file_from, file_to)
    local real_path_from = core.format_realpath(file_from)
    local real_path_to = core.format_realpath(file_to)
    local ret = file_utils.copy_file_s(real_path_from, real_path_to)
    assert(ret == 0)
end

-- csr打桩
function M.prepare_csr_data(test_data_dir)
    local dir_list = {'apps/account/mds', 'apps/hwdiscovery/mds', 'apps/ipmi_core/mds', 'sr'}
    for _, path in pairs(dir_list) do
        os.execute('mkdir -p ' .. test_data_dir .. '/' .. path)
    end
    -- 没有硬件可以不用copy root.sr
    copy_file_real_path('mds/schema.json', test_data_dir .. '/apps/account/mds/schema.json')
    copy_file_real_path('mds/service.json', test_data_dir .. '/apps/account/mds/service.json')
    copy_file_real_path('temp/opt/bmc/apps/hwdiscovery/mds/schema.json',
        test_data_dir .. '/apps/hwdiscovery/mds/schema.json')
    copy_file_real_path('temp/opt/bmc/apps/hwdiscovery/mds/service.json',
        test_data_dir .. '/apps/hwdiscovery/mds/service.json')
    copy_file_real_path('temp/opt/bmc/apps/ipmi_core/mds/schema.json',
        test_data_dir .. '/apps/ipmi_core/mds/schema.json')
end

function M.prepare_key_mgmt_data(test_data_dir)
    local absolute_test_data_dir = os.getenv('PROJECT_DIR') .. '/' .. test_data_dir
    skynet.setenv('KSF_PATH', absolute_test_data_dir)
    skynet.setenv('KSF_BAK_PATH', absolute_test_data_dir)
    skynet.setenv('KSF_DEFAULT_PATH', absolute_test_data_dir)
end

function M.prepare_event_test_data(test_data_dir)
    os.execute('mkdir -p ' .. skynet.getenv('TEST_LOCAL_RESET_DB_DIR'))

    local dir_list = {
        'apps/event/mds', 'apps/frudata/mds', 'apps/hwdiscovery/mds',
        'apps/hwproxy/mds', 'apps/trust/mds', 'sr', 'data/sr'
    }
    for _, path in pairs(dir_list) do
        os.execute('mkdir -p ' .. test_data_dir .. '/' .. path)
    end

    -- prepare hwproxy mds files
    os.execute('tar -xzf temp/test_data/apps/hwproxy/mockdata.tar.gz -C ' .. test_data_dir .. 'data')
    mc_utils.copy_file('temp/opt/bmc/apps/hwproxy/mds/schema.json',
        test_data_dir .. '/apps/hwproxy/mds/schema.json')

    -- prepare hwdiscovery mds files
    mc_utils.copy_file('temp/opt/bmc/apps/hwdiscovery/mds/schema.json',
        test_data_dir .. '/apps/hwdiscovery/mds/schema.json')
    mc_utils.copy_file('temp/opt/bmc/apps/hwdiscovery/mds/service.json',
        test_data_dir .. '/apps/hwdiscovery/mds/service.json')
    -- prepare frudata mds files
    mc_utils.copy_file('temp/opt/bmc/apps/frudata/mds/schema.json',
        test_data_dir .. '/apps/frudata/mds/schema.json')
    mc_utils.copy_file('temp/opt/bmc/apps/frudata/mds/service.json',
        test_data_dir .. '/apps/frudata/mds/service.json')
    -- prepare trust mds files
    mc_utils.copy_file('temp/opt/bmc/apps/trust/mds/schema.json',
        test_data_dir .. '/apps/trust/mds/schema.json')
    mc_utils.copy_file('temp/opt/bmc/apps/trust/mds/service.json',
        test_data_dir .. '/apps/trust/mds/service.json')
    -- prepare root.sr
    mc_utils.copy_file('test/integration/test_data/root.sr', test_data_dir .. 'sr/root.sr')
 
    -- prepare event sr and mds files
    mc_utils.copy_file('test/integration/test_data/14100513_Event_0.sr',
        test_data_dir .. '/sr/14100513_Event_0.sr')
    mc_utils.copy_file('test/integration/test_data/14100513_Event_0.sr',
        test_data_dir .. '/data/sr/14100513_Event_0.sr')
    mc_utils.copy_file('temp/opt/bmc/apps/event/mds/schema.json', test_data_dir .. '/apps/event/mds/schema.json')
    mc_utils.copy_file('temp/opt/bmc/apps/event/mds/service.json', test_data_dir .. '/apps/event/mds/service.json')
end

function M.prepare_test_data(test_data_dir)
    mc_utils.mkdir(test_data_dir, mc_utils.S_IRWXU)
    mc_utils.mkdir(test_data_dir .. 'tmp', mc_utils.S_IRWXU)
    mc_utils.mkdir(test_data_dir .. 'home', mc_utils.S_IRWXU)
    mc_utils.mkdir(test_data_dir .. 'dev', mc_utils.S_IRWXU)
    mc_utils.mkdir(test_data_dir .. 'dev/shm', mc_utils.S_IRWXU)
    mc_utils.mkdir(test_data_dir .. 'dev/shm/tmp', mc_utils.S_IRWXU)
    copy_file_real_path('test/unit/test_data/passwd', test_data_dir .. '/passwd')
    copy_file_real_path('test/unit/test_data/shadow', test_data_dir .. '/shadow')
    copy_file_real_path('test/unit/test_data/group', test_data_dir .. '/group')
    copy_file_real_path('test/unit/test_data/ipmi', test_data_dir .. '/ipmi')
    copy_file_real_path('test/unit/test_data/datatocheck_default.dat',
        test_data_dir .. '/datatocheck_default.dat')
    copy_file_real_path('test/unit/test_data/weakdictionary', test_data_dir .. '/weakdictionary')
    copy_file_real_path('test/unit/test_data/dsa_openssh_key.pub', test_data_dir .. '/tmp/dsa_openssh_key.pub')
    copy_file_real_path('test/unit/test_data/openssh_key.pub', test_data_dir .. '/tmp/openssh_key.pub')
    copy_file_real_path('test/unit/test_data/ssh2_key.pub', test_data_dir .. '/tmp/ssh2_key.pub')
    copy_file_real_path('test/unit/test_data/pem_key.pub', test_data_dir .. '/tmp/pem_key.pub')
    local tallylog_dir = skynet.getenv('PAM_TALLY_LOG_DIR')
    mc_utils.mkdir('mkdir -p ' .. tallylog_dir, mc_utils.S_IRWXU)
    copy_file_real_path('test/unit/test_data/pem_key.pub', test_data_dir .. '/tmp/pem_key.pub')
    copy_file_real_path('test/unit/test_data/pam_faillock', test_data_dir .. '/pam_faillock')

    copy_file_real_path('test/unit/test_data/10d0c073.0', test_data_dir .. '/10d0c073.0')
    -- 复制双因素证书文件
    copy_file_real_path('test/unit/test_data/ca.crt', test_data_dir .. '/ca.crt')
    copy_file_real_path('test/unit/test_data/client.crt', test_data_dir .. '/client.crt')
    copy_file_real_path('test/unit/test_data/ca.crl', test_data_dir .. '/ca.crl')
    -- soctrl打桩
    assert(os.execute('mkdir -p ' .. test_data_dir .. '/usr/lib64') == true)
    assert(mc_utils.copy_file('temp/usr/lib64/mock/libsoc_adapter_it.so',
        test_data_dir .. '/usr/lib64/libsoc_adapter.so') == true)
    assert(mc_utils.copy_file('test/integration/test_data/test.txt', test_data_dir .. '/test.txt') == true)
    -- 由于集成测试是单进程，必须去掉kmc重复初始化流程，业务才能正常使用kmc服务
    os.execute("sed -i '/kmc.initialize/,+4d' temp/opt/bmc/lualib/key_mgmt/key_client_lib.lua")
end

-- 入口函数
function M.setup(test_data_dir)
    assert(os.execute('mkdir -p ' .. test_data_dir) == true)
    M.prepare_test_data(test_data_dir)
    M.prepare_event_test_data(test_data_dir)
    M.prepare_key_mgmt_data(test_data_dir)
    M.prepare_csr_data(test_data_dir)
    local temp_dir = os.getenv('PROJECT_DIR') .. '/temp'
    -- 防止部分接口未拉起时，访问耗时过长（不影响测试），将重试次数修改为1次
    local ret = os.execute(string.format("find %s -name client.lua|xargs sed -i -e 's/local MAX_RETRY_TIMES<const> ="..
        " 10/local MAX_RETRY_TIMES<const> = 1/g'", temp_dir))
    assert(ret == true)
    -- 部分组件未被拉起，防止maca重启所有服务，将MAX_ABNORMAL_RESET_TIMES设置为一个超大值
    ret = os.execute(string.format("sed -i -e 's/local MAX_ABNORMAL_RESET_TIMES<const> ="..
        " 10/local MAX_ABNORMAL_RESET_TIMES<const> = 0/g' %s/opt/bmc/apps/maca/lualib" ..
            "/app_mgmt/monitor/startup/init.lua", temp_dir))
    assert(ret == true)
end

return M
