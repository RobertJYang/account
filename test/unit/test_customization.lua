-- Copyright (c) 2025 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local sqlite3 = require 'lsqlite3'
local mc_context = require 'mc.context'
local cjson = require 'cjson'
local enum = require 'class.types.types'
local custom_settings = require 'interface.config_mgmt.manufacture.customization.custom_settings'

local function make_interface()
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
        enum.LoginInterface.SFTP, enum.LoginInterface.SNMP }
    return interface
end


function TestAccount:test_custom_settings()
    local ctx = mc_context.new('UT', 'Administrator', 'HOST')
    local PROJECT_DIR = os.getenv('PROJECT_DIR')

    local file = io.open(PROJECT_DIR .. '/test/unit/test_data/config_customization.json')
    lu.assertNotEquals(file, nil)
    local config_data = file:read('a')
    local config_object = cjson.decode(config_data).ConfigData

    local config_service = custom_settings.new()
    config_service:on_import(ctx, config_object)
    lu.assertEquals(self.test_global_account_config:get_initial_password_prompt_enable(), true)
    lu.assertEquals(self.test_global_account_config:get_initial_password_need_modify(), true)
end
