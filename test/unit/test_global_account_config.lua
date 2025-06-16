-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local config = require 'common_config'
local file_utils = require 'utils.file'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'

local WEAK_PWDDICT_MAX_SUPPORTED_LINES<const> = 1000

-- 当在合法路径下传入合法弱口令字典时，导入弱口令字典成功
function TestAccount:test_when_weakpwddic_is_valid_should_import_successful()
    local tmp_file = self.weakpwddic_file .. '1'
    file_utils.copy_file_s(self.weakpwddic_file, tmp_file)
    local ok = pcall(function()
        self.test_global_account_config:import_weak_pwd_dictionary(tmp_file)
    end)
    lu.assertEquals(ok, true)
end

-- 当导入路径为非法路径时，检查路径结果为false
function TestAccount:test_when_weakpwddic_path_is_empty_should_check_false()
    -- 导入路径为空
    local test_empty_path = ''
    local result = pcall(function()
        self.test_global_account_config:import_weak_pwd_dictionary(test_empty_path)
    end)
    lu.assertEquals(result, false)
end

-- 当导入路径太长时，检查路径结果为false
function TestAccount:test_when_weakpwddic_path_is_too_long_should_check_false()
    config.MAX_FILEPATH_LENGTH = 10
    local result = pcall(function()
        self.test_global_account_config:import_weak_pwd_dictionary(self.weakpwddic_file)
    end)
    lu.assertEquals(result, false)
    config.MAX_FILEPATH_LENGTH = 256
end

-- 当导入路径不在/tmp目录下时，检查路径结果为false
function TestAccount:test_when_weakpwddic_path_is_not_tmp_should_check_false()
    local result = pcall(function()
        self.test_global_account_config:import_weak_pwd_dictionary(self.illegal_weakpwddic_file)
    end)
    lu.assertEquals(result, false)
end

-- 当导入弱口令字典文件为空文件时，导入弱口令字典失败
function TestAccount:test_when_weakpwddic_is_empty_should_import_fail()
    -- 导入的弱口令文件为空文件，检查文件是否导入失败
    local tmp_path = self.weakpwddic_file .. '1'
    local test_file = file_utils.open_s(tmp_path, "w+")
    test_file:write("")
    test_file:close()
    lu.assertErrorMsgContains(custom_msg.WeakPWDDictImportFailedMessage.Name, function()
        self.test_global_account_config:import_weak_pwd_dictionary(tmp_path)
    end)
end

-- 导入的弱口令文件文件大小超过最大值，检查文件是否导入失败
function TestAccount:test_when_weakpwddic_is_too_big_should_import_fail()
    local tmp_path = self.weakpwddic_file .. '1'
    local test_file = file_utils.open_s(tmp_path, "w+")
    for _ = 1, config.FILE_LIMITED_SIZE + 1 do
        test_file:write("1")
    end
    test_file:close()
    lu.assertErrorMsgContains(custom_msg.WeakPWDDictImportFailedMessage.Name, function()
        self.test_global_account_config:import_weak_pwd_dictionary(tmp_path)
    end)
end

-- 往文件中写入不可见字符，并检查文件是否导入失败
function TestAccount:test_when_weakpassword_has_invisible_character_should_import_fail()
    local tmp_path = self.weakpwddic_file .. '1'
    local test_file = file_utils.open_s(tmp_path, "w+")
    test_file:write(string.char(31,127))
    test_file:close()
    lu.assertErrorMsgContains(custom_msg.WeakPWDDictImportFailedMessage.Name, function()
        self.test_global_account_config:import_weak_pwd_dictionary(tmp_path)
    end)
end

-- 往文件中写入1001条合法弱口令，并检查文件是否导入失败
function TestAccount:test_when_weakpassword_item_is_illegal_should_import_fail()
    local tmp_path = self.weakpwddic_file .. '1'
    local test_file = file_utils.open_s(tmp_path, "w+")
    for _ = 1, WEAK_PWDDICT_MAX_SUPPORTED_LINES + 1 do
        test_file:write("1\n")
    end
    test_file:close()
    lu.assertErrorMsgContains(custom_msg.WeakPWDDictImportFailedMessage.Name, function()
        self.test_global_account_config:import_weak_pwd_dictionary(tmp_path)
    end)
end

-- 往文件中写入1000条合法弱口令和一条空行，并检查文件是否导入成功
function TestAccount:test_when_weakpassword_item_is_legal_should_import_fail()
    local tmp_path = self.weakpwddic_file .. '1'
    local test_file = file_utils.open_s(tmp_path, "w+")
    for _ = 1, WEAK_PWDDICT_MAX_SUPPORTED_LINES do
        test_file:write("1\n")
    end
    test_file:close()
    local ok = pcall(function ()
        self.test_global_account_config:import_weak_pwd_dictionary(tmp_path)
    end)
    lu.assertEquals(ok, true)
    config.TMP_PATH = tmp_path
end

-- 导出路径不为空，且不在/tmp目录下时，检查是否导出失败
function TestAccount:test_when_weakpassword_export_path_is_illegal_should_export_fail()
    local tmp_file = self.test_data_dir .. '/tmpfile'
    file_utils.copy_file_s(self.weakpwddic_file, tmp_file)
    lu.assertErrorMsgContains(custom_msg.InvalidPathMessage.Name, function()
        self.test_global_account_config:export_weak_pwd_dictionary(self.ctx, tmp_file)
    end)
end

-- 导出路径太长时，检查是否导出失败
function TestAccount:test_when_weakpassword_export_path_is_too_long_should_export_fail()
    local tmp_file = self.weakpwddic_file .. '1'
    file_utils.copy_file_s(self.weakpwddic_file, tmp_file)
    config.MAX_FILEPATH_LENGTH = 10
    lu.assertErrorMsgContains(custom_msg.InvalidPathMessage.Name, function()
        self.test_global_account_config:export_weak_pwd_dictionary(self.ctx, self.weakpwddic_file)
    end)
    config.MAX_FILEPATH_LENGTH = 256
end

-- 导出路径下已有同名文件时，检查是否导出成功
function TestAccount:test_when_weakpassword_export_file_already_exists_should_export_fail()
    local tmp_file = self.weakpwddic_file .. '1'
    file_utils.copy_file_s(self.weakpwddic_file, tmp_file)
    file_utils.copy_file_s(self.weakpwddic_file, config.WEAK_PWDDICT_FILE_EXPORT_PATH)
    local ok = pcall(function()
        self.test_global_account_config:export_weak_pwd_dictionary(self.ctx, tmp_file)
    end)
    lu.assertEquals(ok, true)
    os.remove(config.WEAK_PWDDICT_FILE_EXPORT_PATH)
end

-- 设置带内用户管理使能应该成功
function TestAccount:test_set_host_user_magagement_success()
    local ret = self.test_global_account_config:get_host_user_management_enabled()
    lu.assertEquals(ret, true)
    self.test_global_account_config:set_host_user_management_enabled(false)
    local ret2 = self.test_global_account_config:get_host_user_management_enabled()
    lu.assertEquals(ret2, false)
    self.test_global_account_config:set_host_user_management_enabled(true)
end

-- 设置用户名密码对比开关使能应该成功
function TestAccount:test_set_user_name_password_prefix_compare_enabled_should_succsess()
    local default_status = self.test_global_account_config:get_user_name_password_compared_enabled()
    lu.assertEquals(default_status, false)
    self.test_global_account_config:set_user_name_password_compared_enabled(true)
    local current_status = self.test_global_account_config:get_host_user_management_enabled()
    lu.assertEquals(current_status, true)

    -- 恢复现场
    self.test_global_account_config:set_user_name_password_compared_enabled(default_status)
end

-- 设置用户名密码合法对比长度应该成功
function TestAccount:test_set_user_name_password_prefix_compare_valid_length_should_succsess()
    local default_length = self.test_global_account_config:get_user_name_password_compared_length()
    lu.assertEquals(default_length, config.USERNAME_PWD_COMPARE_DEFAULT_LEN)
    self.test_global_account_config:set_user_name_password_compared_length(5)
    lu.assertEquals(self.test_global_account_config:get_user_name_password_compared_length(), 5)
    self.test_global_account_config:set_user_name_password_compared_length(20)
    lu.assertEquals(self.test_global_account_config:get_user_name_password_compared_length(), 20)

    --恢复现场
    self.test_global_account_config:set_user_name_password_compared_enabled(default_length)
end

-- 设置用户名密码非法对比长度应该失败
function TestAccount:test_set_user_name_password_prefix_compare_invalid_length_should_fail()
    local default_length = self.test_global_account_config:get_user_name_password_compared_length()
    lu.assertEquals(default_length, config.USERNAME_PWD_COMPARE_DEFAULT_LEN)
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        self.test_global_account_config:set_user_name_password_compared_length(3)
    end)
    lu.assertErrorMsgContains(custom_msg.InvalidValueMessage.Name, function()
        self.test_global_account_config:set_user_name_password_compared_length(21)
    end)
end

-- 带内用户使能校验检查
function TestAccount:test_host_user_mgmt_check_from_os_should_fail()
    local enums = require 'mc.ipmi.enums'
    local channel_type = enums.ChannelType
    local ipmi_ctx = {
        ChanType = channel_type.CT_EDMA_0:value(),
        Instance = 0,
        cmd = 147,
        src_addr = 32,
        netfn = 48,
        chan_num = enums.ChannelId.CT_EDMA:value(),
        src_lun = 0,
    }
    local old_user_mgmt_value = self.test_global_account_config:get_host_user_management_enabled()
    self.test_global_account_config:set_host_user_management_enabled(true)
    local res = self.test_global_account_config:check_ipmi_host_user_mgnt_enabled(ipmi_ctx)
    lu.assertEquals(res, true)

    self.test_global_account_config:set_host_user_management_enabled(false)
    res = self.test_global_account_config:check_ipmi_host_user_mgnt_enabled(ipmi_ctx)
    lu.assertEquals(res, false)

    self.test_global_account_config:set_host_user_management_enabled(old_user_mgmt_value)
end