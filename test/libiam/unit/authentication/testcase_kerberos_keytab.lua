-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
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
local file_utils = require 'utils.file'
local kerberos_config = require 'domain.kerberos_config'
local iam_err = require 'iam.errors'

local keytab_byte = {
    5, 2, 0, 0, 0, 102, 0, 2, 0, 15, 80, 82, 71, 45, 68, 67, 49, 46, 68, 72, 76, 46, 67, 79, 77,
    0, 4, 72, 84, 84, 80, 0, 30, 72, 87, 55, 49, 45, 52, 55, 45, 52, 48, 45, 49, 49, 48, 46, 112,
    114, 103, 45, 100, 99, 49, 46, 100, 104, 108, 46, 99, 111, 109, 0, 0, 0, 3, 0, 0, 0, 0, 4, 0,
    18, 0, 32, 234, 142, 227, 235, 161, 246, 145, 150, 152, 201, 179, 143, 48, 46, 18, 114, 206,
    235, 205, 91, 191, 201, 34, 127, 18, 188, 221, 160, 187, 210, 196, 209
}

--- 当导入正确keytab应该导入成功
function TestIam:test_when_import_correct_keytab_should_import_success()
    local m_kerberos_config = kerberos_config.new(self.IamDB)
    m_kerberos_config.KRB_KEYTABLE_IMPORT_REGEX = '^(/.{1,250})\\.(keytab)$'
    m_kerberos_config.KRB_ENC_KEYTABLE_PATH = self.test_data_dir .. '/tmp/kerberos.pfx'
    m_kerberos_config.KRB_ENC_KEYTABLE_TEMP_PATH = self.test_data_dir .. '/tmp/tmp_kerberos.pfx'
    local keytab_path = self.test_data_dir .. '/tmp/temp_kerberos.keytab'
    file_utils.write_file_s(keytab_path, string.char(table.unpack(keytab_byte)))
    m_kerberos_config:import_key_table(keytab_path)
    lu.assertEquals(file_utils.check_real_path_s(m_kerberos_config.KRB_ENC_KEYTABLE_PATH), 0)
    lu.assertEquals(file_utils.check_real_path_s(keytab_path), -1) -- 删除源文件
    local encrypt_keytab = file_utils.open_s(m_kerberos_config.KRB_ENC_KEYTABLE_PATH, 'r')
    local encrypt_keytab_content = encrypt_keytab:read('*a')
    encrypt_keytab:close()
    lu.assertEquals(#encrypt_keytab_content > 0, true)
end

--- 当导入路径不合法，应该导入失败
function TestIam:test_when_keytab_file_path_invalid_should_import_fail()
    local m_kerberos_config = kerberos_config.new(self.IamDB)
    m_kerberos_config.KRB_KEYTABLE_IMPORT_REGEX = '^(/tmp/.{1,246})\\.(keytab)$'
    m_kerberos_config.KRB_ENC_KEYTABLE_PATH = self.test_data_dir .. '/tmp/kerberos.pfx'
    local keytab_path = self.test_data_dir .. '/temp_kerberos.keytab'
    file_utils.write_file_s(keytab_path, string.char(table.unpack(keytab_byte)))
    lu.assertErrorMsgContains(iam_err.ImportInvalidKeytab, function()
        m_kerberos_config:import_key_table(keytab_path)
    end)
    lu.assertEquals(file_utils.check_real_path_s(keytab_path), 0) -- 文件路径检查不通过，不删除源文件
end

--- 当导入文件后缀不为keytab，应该导入失败
function TestIam:test_when_keytab_file_name_invalid_should_import_fail()
    local m_kerberos_config = kerberos_config.new(self.IamDB)
    m_kerberos_config.KRB_KEYTABLE_IMPORT_REGEX = '^(/.{1,250})\\.(keytab)$'
    m_kerberos_config.KRB_ENC_KEYTABLE_PATH = self.test_data_dir .. '/tmp/kerberos.pfx'
    local keytab_path = self.test_data_dir .. '/tmp/temp_kerberos.key'
    file_utils.write_file_s(keytab_path, string.char(table.unpack(keytab_byte)))
    lu.assertErrorMsgContains(iam_err.ImportInvalidKeytab, function()
        m_kerberos_config:import_key_table(keytab_path)
    end)
    lu.assertEquals(file_utils.check_real_path_s(keytab_path), -1) -- 删除源文件
end

--- 当导入文件内容格式不合法，应该导入失败
function TestIam:test_when_keytab_file_content_invalid_should_import_fail()
    local m_kerberos_config = kerberos_config.new(self.IamDB)
    m_kerberos_config.KRB_KEYTABLE_IMPORT_REGEX = '^(/.{1,250})\\.(keytab)$'
    m_kerberos_config.KRB_ENC_KEYTABLE_PATH = self.test_data_dir .. '/tmp/kerberos.pfx'
    local keytab_path = self.test_data_dir .. '/tmp/temp_kerberos.keytab'
    file_utils.write_file_s(keytab_path, '1' .. string.char(table.unpack(keytab_byte)))
    lu.assertErrorMsgContains(iam_err.ImportInvalidKeytab, function()
        m_kerberos_config:import_key_table(keytab_path)
    end)
    lu.assertEquals(file_utils.check_real_path_s(keytab_path), -1) -- 删除源文件
end
