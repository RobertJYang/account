-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
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
local iam_utils = require 'infrastructure.iam_utils'
local utils = require 'utils'
local user_config = require 'user_config'

--- 导入文件路径不合法，应该检查失败
function TestIam:test_when_import_path_invalid_should_check_fail()
    lu.assertIsFalse(iam_utils.check_import_path(''))
    lu.assertIsFalse(iam_utils.check_import_path(string.rep('/', user_config.MAX_FILEPATH_LENGTH + 1)))
    lu.assertIsFalse(iam_utils.check_import_path('/tmp'))
    lu.assertIsFalse(iam_utils.check_import_path('/tmp/'))
    lu.assertIsFalse(iam_utils.check_import_path('/etc/passwd'))
    lu.assertIsFalse(iam_utils.check_import_path('/tmp//temp'))
    lu.assertIsFalse(iam_utils.check_import_path('/tmp/../etc/passwd'))
    lu.assertIsFalse(iam_utils.check_import_path('/tmp/12345'))
    lu.assertIsFalse(iam_utils.check_import_path('/tmp/12345/123'))
end

--- 用户名合法，应该检查成功
function TestIam:test_when_unsername_valid_should_check_success()
    lu.assertIsTrue(utils.check_user_name('Administrator'))
    lu.assertIsTrue(utils.check_user_name(string.rep('A', 16)))
    lu.assertIsTrue(utils.check_user_name('A#dministrator'))
    lu.assertIsTrue(utils.check_user_name('A+dministrator'))
    lu.assertIsTrue(utils.check_user_name('A-dminis_trator'))
    lu.assertIsTrue(utils.check_user_name('.A..dministrator'))
    lu.assertIsTrue(utils.check_user_name('.A..d_123'))
    lu.assertIsTrue(utils.check_user_name('...!@#$^*()-=+_'))
    lu.assertIsTrue(utils.check_user_name('_={};[]?.'))
    lu.assertIsTrue(utils.check_user_name('[Admin]'))
    lu.assertIsTrue(utils.check_user_name('Ad{mi}n'))
    lu.assertIsTrue(utils.check_user_name(']Adm;i]n'))
    lu.assertIsTrue(utils.check_user_name('.Admin..'))
    lu.assertIsTrue(utils.check_user_name('_dm=in?'))
    lu.assertIsTrue(utils.check_user_name('[[[Ad}}}min{{'))
    lu.assertIsTrue(utils.check_user_name('|.root|'))
    lu.assertIsTrue(utils.check_user_name('adm|in+1#'))
    lu.assertIsTrue(utils.check_user_name('t1@#!~`$^*()-_+?'))
end

--- 用户名不合法，应该检查失败
function TestIam:test_when_unsername_invalid_should_check_fail()
    lu.assertIsFalse(utils.check_user_name(''))
    lu.assertIsFalse(utils.check_user_name('.'))
    lu.assertIsFalse(utils.check_user_name('..'))
    lu.assertIsFalse(utils.check_user_name(' Administrator'))
    lu.assertIsFalse(utils.check_user_name(string.rep('A', 17)))
    lu.assertIsFalse(utils.check_user_name('A:dministrator'))
    lu.assertIsFalse(utils.check_user_name('A<dministrator'))
    lu.assertIsFalse(utils.check_user_name('A>dministrator'))
    lu.assertIsFalse(utils.check_user_name('A&dministrator'))
    lu.assertIsFalse(utils.check_user_name('A,dministrator'))
    lu.assertIsFalse(utils.check_user_name('A"dministrator'))
    lu.assertIsFalse(utils.check_user_name('A/dministrator'))
    lu.assertIsFalse(utils.check_user_name('A\\dministrator'))
    lu.assertIsFalse(utils.check_user_name('A%dministrator'))
    lu.assertIsFalse(utils.check_user_name('A dministrator'))
    lu.assertIsFalse(utils.check_user_name('#Administrator'))
    lu.assertIsFalse(utils.check_user_name('+Administrator'))
    lu.assertIsFalse(utils.check_user_name('-Administrator'))
    lu.assertIsFalse(utils.check_user_name('A“dministrator'))
    lu.assertIsFalse(utils.check_user_name('Administrator\r'))
    lu.assertIsFalse(utils.check_user_name('Administrator\n'))
    lu.assertIsFalse(utils.check_user_name('Administrator\f'))
    lu.assertIsFalse(utils.check_user_name('Administrator\r\n\f'))
    lu.assertIsFalse(utils.check_user_name('Administrator\n\n'))
    lu.assertIsFalse(utils.check_user_name('Administrator\f\f'))
end

--- 密码中含有中文时，应该检查失败
function TestIam:test_when_password_contains_chinese_should_check_fail()
    local test_password = '纯中文'
    lu.assertIsFalse(utils.check_if_password_character_is_valid(test_password))
    test_password = 'mix中文'
    lu.assertIsFalse(utils.check_if_password_character_is_valid(test_password))
    test_password = '.test!@#$￥'
    lu.assertIsFalse(utils.check_if_password_character_is_valid(test_password))
end

--- 密码中不含有中文时，应该检查成功
function TestIam:test_when_password_not_contains_chinese_should_check_success()
    local test_password = 'Admin@90000'
    lu.assertIsTrue(utils.check_if_password_character_is_valid(test_password))
    test_password = 'Administrator'
    lu.assertIsTrue(utils.check_if_password_character_is_valid(test_password))
    test_password = 'Administrator~!@#$%^&*()_+{}:'
    lu.assertIsTrue(utils.check_if_password_character_is_valid(test_password))
end

--- ip地址标准化转换成功
function TestIam:test_ip_addr_normalize_success()
    lu.assertEquals(utils.normalize_ip("192.0.2.01"), "192.0.2.1")
    lu.assertEquals(utils.normalize_ip("2001:db8::8a2e:370:7334"), "2001:0db8:0000:0000:0000:8a2e:0370:7334")
    lu.assertEquals(utils.normalize_ip("2001:db8::"), "2001:0db8:0000:0000:0000:0000:0000:0000")
end