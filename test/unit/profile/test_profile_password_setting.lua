-- Copyright (c) 2026 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local cjson = require 'cjson'
local mc_context = require 'mc.context'
local custom_msg = require 'messages.custom'
local profile_adapter = require 'interface.config_mgmt.profile.profile_adapter'
local core = require 'account_core'

local default_core_fun = core.is_manufacture_mode

local function setup_with_manufacture_mode(self)
    core.is_manufacture_mode = function()
        return true
    end
end

local function setup_without_manufacture_mode(self)
    core.is_manufacture_mode = function()
        return false
    end
end

local function teardown_with_default_config(self)
    core.is_manufacture_mode = default_core_fun
    self.test_global_account_config:set_password_complexity_lock(false)
    self.test_global_account_config:set_password_complexity_enable(true)
end

-- 场景1：当前Disabled，导入Disabled → 值未变化，无日志
function TestAccount:test_import_status_disabled_unchanged()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(false)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "Disabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsFalse(enable)

    teardown_with_default_config(self)
end

-- 场景2：当前Enabled，导入Enabled → 值未变化，无日志
function TestAccount:test_import_status_enabled_unchanged()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "Enabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景3：当前ForceEnabled，导入ForceEnabled → 值未变化，无日志
function TestAccount:test_import_status_force_enabled_unchanged()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(true)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "ForceEnabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsTrue(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景4：当前Disabled，导入Enabled → 成功
function TestAccount:test_import_status_from_disabled_to_enabled()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(false)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "Enabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景5：当前Disabled，导入ForceEnabled → 成功
function TestAccount:test_import_status_from_disabled_to_force_enabled()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(false)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "ForceEnabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsTrue(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景6：当前Enabled，导入Disabled → 成功
function TestAccount:test_import_status_from_enabled_to_disabled()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "Disabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsFalse(enable)

    teardown_with_default_config(self)
end

-- 场景7：当前Enabled，导入ForceEnabled → 成功
function TestAccount:test_import_status_from_enabled_to_force_enabled()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "ForceEnabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsTrue(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景8：非制造模式，ForceEnabled→Disabled 报错
function TestAccount:test_import_from_force_enabled_to_disabled_non_manufacture()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    setup_without_manufacture_mode(self)

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(true)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "Disabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    lu.assertErrorMsgContains(custom_msg.CollectingConfigurationErrorDescMessage.Name, function()
        config_service:on_import(ctx, object)
    end)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsTrue(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景9：非制造模式，ForceEnabled→Enabled 报错
function TestAccount:test_import_from_force_enabled_to_enabled_non_manufacture()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    setup_without_manufacture_mode(self)

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(true)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "Enabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    lu.assertErrorMsgContains(custom_msg.CollectingConfigurationErrorDescMessage.Name, function()
        config_service:on_import(ctx, object)
    end)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    lu.assertIsTrue(lock)

    teardown_with_default_config(self)
end

-- 场景10：制造模式，ForceEnabled→Disabled 成功
function TestAccount:test_import_from_force_enabled_to_disabled_manufacture_mode()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    setup_with_manufacture_mode(self)

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(true)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "Disabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsFalse(enable)

    teardown_with_default_config(self)
end

-- 场景11：制造模式，ForceEnabled→Enabled 成功
function TestAccount:test_import_from_force_enabled_to_enabled_manufacture_mode()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    setup_with_manufacture_mode(self)

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(true)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "Enabled", Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景12：同时导入Status和Enable，以Status为准
function TestAccount:test_import_both_status_and_enable_status_priority()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(false)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "Enabled", Import = true },
            EnableStrongPassword = { Value = false, Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景13：仅导入Enable=false，当前ForceEnabled，非制造模式 → 底层报错
function TestAccount:test_import_only_enable_false_with_force_enabled_non_manufacture()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    setup_without_manufacture_mode(self)

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(true)

    local object = {
        PasswdSetting = {
            EnableStrongPassword = { Value = false, Import = true }
        }
    }

    local config_service = profile_adapter.new()
    lu.assertErrorMsgContains(custom_msg.CollectingConfigurationErrorDescMessage.Name, function()
        config_service:on_import(ctx, object)
    end)

    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景14：仅导入Enable=false，当前ForceEnabled，制造模式 → 成功
function TestAccount:test_import_only_enable_false_with_force_enabled_manufacture()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    setup_with_manufacture_mode(self)

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(true)

    local object = {
        PasswdSetting = {
            EnableStrongPassword = { Value = false, Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(enable)

    teardown_with_default_config(self)
end

-- 场景15：仅导入Enable=true，当前Disabled → 成功
function TestAccount:test_import_only_enable_true_from_disabled()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(false)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            EnableStrongPassword = { Value = true, Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景16：仅导入Enable=true，当前Enabled → 跳过
function TestAccount:test_import_only_enable_true_unchanged()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            EnableStrongPassword = { Value = true, Import = true }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end

-- 场景17a：导出 Disabled 状态
function TestAccount:test_export_status_disabled()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(false)
    self.test_global_account_config:set_password_complexity_lock(false)

    local config_service = profile_adapter.new()
    local export_data = config_service:on_export(ctx)

    lu.assertEquals(export_data["PasswdSetting"]["PasswordComplexityStatus"], "Disabled")
    lu.assertIsFalse(export_data["PasswdSetting"]["EnableStrongPassword"])

    teardown_with_default_config(self)
end

-- 场景17b：导出 Enabled 状态
function TestAccount:test_export_status_enabled()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(false)

    local config_service = profile_adapter.new()
    local export_data = config_service:on_export(ctx)

    lu.assertEquals(export_data["PasswdSetting"]["PasswordComplexityStatus"], "Enabled")
    lu.assertIsTrue(export_data["PasswdSetting"]["EnableStrongPassword"])

    teardown_with_default_config(self)
end

-- 场景17c：导出 ForceEnabled 状态
function TestAccount:test_export_status_force_enabled()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(true)

    local config_service = profile_adapter.new()
    local export_data = config_service:on_export(ctx)

    lu.assertEquals(export_data["PasswdSetting"]["PasswordComplexityStatus"], "ForceEnabled")
    lu.assertIsTrue(export_data["PasswdSetting"]["EnableStrongPassword"])

    teardown_with_default_config(self)
end

-- 场景17d：导出特殊状态，当前Enable=fasle，Lock=true，到处状态为Disabled
function TestAccount:test_export_special_status()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    setup_with_manufacture_mode(self)

    self.test_global_account_config:set_password_complexity_lock(true)
    self.test_global_account_config:set_password_complexity_enable(false)

    local config_service = profile_adapter.new()
    local export_data = config_service:on_export(ctx)

    lu.assertEquals(export_data["PasswdSetting"]["PasswordComplexityStatus"], "Disabled")
    lu.assertIsFalse(export_data["PasswdSetting"]["EnableStrongPassword"])

    teardown_with_default_config(self)
end


-- 场景17e：导出同时包含Status和Enable
function TestAccount:test_export_both_status_and_enable()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(true)

    local config_service = profile_adapter.new()
    local export_data = config_service:on_export(ctx)

    lu.assertNotNil(export_data["PasswdSetting"]["PasswordComplexityStatus"])
    lu.assertNotNil(export_data["PasswdSetting"]["EnableStrongPassword"])

    teardown_with_default_config(self)
end

-- 场景18：Import=false，不应执行任何操作
function TestAccount:test_import_status_with_import_false()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(false)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {
            PasswordComplexityStatus = { Value = "ForceEnabled", Import = false }
        }
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsFalse(enable)

    teardown_with_default_config(self)
end

-- 场景19：PasswdSetting为空对象 → 跳过
function TestAccount:test_import_empty_passwd_setting()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(false)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {
        PasswdSetting = {}
    }

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsFalse(enable)

    teardown_with_default_config(self)
end

-- 场景20：无PasswdSetting → 跳过
function TestAccount:test_import_without_passwd_setting()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')

    self.test_global_account_config:set_password_complexity_enable(true)
    self.test_global_account_config:set_password_complexity_lock(false)

    local object = {}

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)

    local lock = self.test_global_account_config:get_password_complexity_lock()
    local enable = self.test_global_account_config:get_password_complexity_enable()
    lu.assertIsFalse(lock)
    lu.assertIsTrue(enable)

    teardown_with_default_config(self)
end