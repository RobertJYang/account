-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Test passwords:[Paswd@9001, Paswd@9005]
local lu = require 'luaunit'
local enum = require 'class.types.types'
local core = require 'account_core'
local mc_utils = require 'mc.utils'
local utils = require 'infrastructure.utils'

local user_parse_table = {
    ['root'] = '<su>',
    ['<root>'] = 'root'
}

local function make_interface()
    local interface = {
        enum.LoginInterface.Redfish, enum.LoginInterface.SFTP,
        enum.LoginInterface.SNMP
    }
    return interface
end

function TestAccount:test_get_account_data()
    -- 测试接口可以查询到默认用户信息
    local account_data, snmp_info_data = self.test_account:get_account_data()
    lu.assertEquals(account_data.Id, 2)
    lu.assertEquals(account_data.UserName, 'Administrator')
    lu.assertEquals(account_data.RoleId, enum.RoleType.Administrator:value())
    lu.assertEquals(account_data.FirstLoginPolicy, enum.FirstLoginPolicy.ForcePasswordReset)
    lu.assertEquals(snmp_info_data.AccountId, 2)
    lu.assertEquals(snmp_info_data.AuthenticationProtocol,
        enum.SNMPAuthenticationProtocols.SHA512)
end

function TestAccount:test_passwordcomplexity_check()
    local res = core.is_pass_complexity_check_pass('Administrator', 'dsaflkjdakfs', 8)
    lu.assertEquals(res, false)
    local res = core.is_pass_complexity_check_pass('Administrator', 'ABCDEFGHI ', 8)
    lu.assertEquals(res, false)
    local res = core.is_pass_complexity_check_pass('Administrator', 'rotartsinimdA', 8)
    lu.assertEquals(res, false)
    local res = core.is_pass_complexity_check_pass('ADMINISTRATOR+', '+ROTARTSINIMDA', 8)
    lu.assertEquals(res, false)
    local res = core.is_pass_complexity_check_pass('Administrator', 'Abc', 8)
    lu.assertEquals(res, false)
    local res = core.is_pass_complexity_check_pass('Administrator', '123456789', 8)
    lu.assertEquals(res, false)
    local res = core.is_pass_complexity_check_pass('Administrator', '::::::::::::', 8)
    lu.assertEquals(res, false)
    local res = core.is_pass_complexity_check_pass('Administrator', 'Abcdefghijkl+++', 8)
    lu.assertEquals(res, true)
    local res = core.is_pass_complexity_check_pass('Administrator', 'Abcdefghijkl++', 8)
    lu.assertEquals(res, true)
    local res = core.is_pass_complexity_check_pass('Administrator', 'Abcdefg-', 8)
    lu.assertEquals(res, true)
    local res = core.is_pass_complexity_check_pass('Administrator', 'Abcdefgh8+', 8)
    lu.assertEquals(res, true)
end

--- 当文件操作者角色为Administrator，检验成功
function TestAccount:test_when_fileowner_matchs_caller_role_is_admin_should_check_success()
    local temp_file = self.test_data_dir .. '/temp_file'
    os.execute('touch ' .. temp_file)
    local handler = 'usernotexist'
    handler = user_parse_table[handler] or handler
    local result = utils.check_fileowner_matchs_caller(
        temp_file, handler, enum.RoleType.Administrator:value())
    lu.assertEquals(result, true)
    -- 恢复操作
    mc_utils.remove_file(temp_file)
end

--- 当文件操作者和用户属主一致，检验成功
function TestAccount:test_when_fileowner_matchs_caller_should_check_success()
    local temp_file = self.test_data_dir .. '/temp_file'
    os.execute('touch ' .. temp_file)
    local cmd_output = io.popen("whoami")
    lu.assertNotIsNil(cmd_output)
    local handler = mc_utils.close(cmd_output, pcall(cmd_output.read, cmd_output, "l"))
    handler = user_parse_table[handler] or handler
    local result = utils.check_fileowner_matchs_caller(
        temp_file, handler, enum.RoleType.Operator:value())
    lu.assertEquals(result, true)
    -- 恢复操作
    mc_utils.remove_file(temp_file)
end

--- 当文件操作者和用户属主不一致，检验失败
function TestAccount:test_when_fileowner_not_matchs_caller_should_check_fail()
    local temp_file = self.test_data_dir .. '/temp_file'
    os.execute('touch ' .. temp_file)
    mc_utils.chown(temp_file, 2, 2)
    local handler = 'root'
    handler = user_parse_table[handler] or handler
    local result = utils.check_fileowner_matchs_caller(
        temp_file, handler, enum.RoleType.Operator:value())
    lu.assertEquals(result, false)
    -- 恢复操作
    mc_utils.remove_file(temp_file)
end
