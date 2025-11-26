-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
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
local config_handle = require 'interface.config_mgmt.config_handle'
local profile_adapter = require 'interface.config_mgmt.profile.profile_adapter'
local json = require 'cjson'
local file_utils = require 'utils.file'
local mc_context = require 'mc.context'

function TestIam:test_config_mgmt_when_export_should_success()
    local ch = config_handle.new()
    local data = ch:on_export(self.ctx, "configuration")
    data = json.decode(data)
    local config_data = data.ConfigData
    lu.assertEquals(config_data ~= nil, true)
    lu.assertEquals(config_data.User == nil, true)
    lu.assertEquals(config_data.SecurityEnhance.AuthFailMax ~= nil, true)
end

function TestIam:test_config_mgmt_when_import_session_config_should_success()
    local ch = config_handle.new()
    local data = ch:on_export(self.ctx, "configuration")
    data = json.decode(data)
    local config_data = data.ConfigData
    lu.assertEquals(config_data ~= nil, true)
    lu.assertEquals(config_data.Session ~= nil, true) 
    lu.assertEquals(config_data.Session.Timeout ~= nil, true)
    lu.assertEquals(config_data.Session.RedfishSessionTimeout ~= nil, true)
    lu.assertEquals(config_data.Session.CLISessionTimeout ~= nil, true)

    local ok, _ = pcall(function ()
        profile_adapter.get_instance():import_property(self.ctx, "Session", "Timeout", 360)
        profile_adapter.get_instance():import_property(self.ctx, "Session", "RedfishSessionTimeout", 360)
        profile_adapter.get_instance():import_property(self.ctx, "Session", "CLISessionTimeout", 360)
    end)
    lu.assertEquals(ok, true)
    profile_adapter.get_instance():import_property(self.ctx, "Session", "Timeout",
        config_data.Session.Timeout)
    profile_adapter.get_instance():import_property(self.ctx, "Session", "RedfishSessionTimeout",
        config_data.Session.RedfishSessionTimeout)
    profile_adapter.get_instance():import_property(self.ctx, "Session", "CLISessionTimeout",
        config_data.Session.CLISessionTimeout)
end

function TestIam:test_config_mgmt_when_import_false_config_should_ignore()
    local config_data_file = file_utils.open_s(self.import_false_data_path, 'r')
    local config_content = config_data_file:read('*a')
    config_data_file:close()
    local config_data = json.decode(config_content).Components.iam.ConfigData
    local ctx = mc_context.copy_context(self.ctx)
    local ok, _ = pcall(function ()
        profile_adapter.get_instance():on_import(ctx, config_data)
    end)
    assert(ok)
end