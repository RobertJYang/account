-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Test passwords: [.test!@#$￥, Paswd@90000, Administrator, Administrator~!@#$%^&*()_+{}:]
local lu = require 'luaunit'
local utils = require 'infrastructure.utils'
local file_proxy = require 'infrastructure.file_proxy'
local file_utils = require 'utils.file'
local config = require 'common_config'

local function touch_temp_file(file_path, source_file)
    os.execute('touch ' .. file_path)
    if source_file then
        file_utils.copy_file_s(source_file, file_path)
    end
    return file_path
end

local function proxy_ispermitted_false(dst_path, permission)
    return false
end

--- 导入文件路径不合法，应该检查失败
function TestAccount:test_when_import_path_invalid_should_check_fail()
    lu.assertIsFalse(utils.check_import_path('', config.TMP_PATH))
    lu.assertIsFalse(utils.check_import_path(string.rep('/', config.MAX_FILEPATH_LENGTH + 1), config.TMP_PATH))
    lu.assertIsFalse(utils.check_import_path('/tmp', config.TMP_PATH))
    lu.assertIsFalse(utils.check_import_path('/tmp/', config.TMP_PATH))
    lu.assertIsFalse(utils.check_import_path('/etc/passwd', config.TMP_PATH))
    lu.assertIsFalse(utils.check_import_path('/tmp//temp', config.TMP_PATH))
    lu.assertIsFalse(utils.check_import_path('/tmp/../etc/passwd', config.TMP_PATH))
    lu.assertIsFalse(utils.check_import_path('/tmp/12345', config.TMP_PATH))
    lu.assertIsFalse(utils.check_import_path('/tmp/12345/123', config.TMP_PATH))
end

--- 密码中含有中文时，应该检查失败
function TestAccount:test_when_password_contains_chinese_should_check_fail()
    local test_password = '纯中文'
    lu.assertIsFalse(utils.check_if_password_character_is_valid(test_password))
    test_password = 'mix中文'
    lu.assertIsFalse(utils.check_if_password_character_is_valid(test_password))
    test_password = '.test!@#$￥'
    lu.assertIsFalse(utils.check_if_password_character_is_valid(test_password))
end

--- 密码中不含有中文时，应该检查成功
function TestAccount:test_when_password_not_contains_chinese_should_check_success()
    local test_password = 'Paswd@90000'
    lu.assertIsTrue(utils.check_if_password_character_is_valid(test_password))
    test_password = 'Administrator'
    lu.assertIsTrue(utils.check_if_password_character_is_valid(test_password))
    test_password = 'Administrator~!@#$%^&*()_+{}:'
    lu.assertIsTrue(utils.check_if_password_character_is_valid(test_password))
end

-- 导入公钥等文件路径校验
function TestAccount:test_when_import_is_permitted_should_success()
    local path = touch_temp_file('/tmp/ssh_rsa.pub', nil)
    lu.assertIsTrue(utils.is_import_permitted('URI', path, 'pub', 'content', file_proxy.proxy_ispermitted))
    path = touch_temp_file('/tmp/ssh_rsa.cert', nil)
    lu.assertIsTrue(utils.is_import_permitted('URI', path, 'cert', 'content', file_proxy.proxy_ispermitted))
    path = touch_temp_file('/tmp/ssh_rsa.tab', nil)
    lu.assertIsTrue(utils.is_import_permitted('URI', path, 'tab', 'content', file_proxy.proxy_ispermitted))
    path = touch_temp_file('/tmp/weak', nil)
    lu.assertIsTrue(utils.is_import_permitted('URI', path, 'weakpwddic', 'content', file_proxy.proxy_ispermitted))
    path = "https://127.0.0.1/data/text\\.pub"
    lu.assertIsTrue(utils.is_import_permitted('URI', path, 'pub', 'content', file_proxy.proxy_ispermitted))
    lu.assertIsTrue(utils.is_import_permitted('text', path, 'pub', 'content', file_proxy.proxy_ispermitted))
end

function TestAccount:test_when_import_is_not_permitted_should_faild()
    -- 文件类型不对
    local path = touch_temp_file('/tmp/ssh_rsa.cc', nil)
    lu.assertIsFalse(pcall(utils.is_import_permitted, 'URI', path, 'cert', 'content', file_proxy.proxy_ispermitted))
    -- 文件不存在
    path = '/tmp/xxxxx.cert'
    lu.assertIsFalse(pcall(utils.is_import_permitted, 'URI', path, 'cert', 'content', file_proxy.proxy_ispermitted))
    local path = touch_temp_file('/tmp/../ssh_rsa.cert', nil)
    lu.assertIsFalse(pcall(utils.is_import_permitted, 'URI', path, 'cert', 'content', file_proxy.proxy_ispermitted))
    path = '/tmp/ssh_rsa.pub'
    lu.assertIsFalse(pcall(utils.is_import_permitted, 'URI', path, 'pub', 'content', proxy_ispermitted_false))
end