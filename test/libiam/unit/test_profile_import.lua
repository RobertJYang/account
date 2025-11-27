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

local profile_adapter = require 'interface.config_mgmt.profile.profile_adapter'
local lu = require 'luaunit'
local mc_context = require 'mc.context'
local cjson = require 'cjson'
local remote_group_collection = require 'domain.remote_group.remote_group_collection'

--- 导入文件路径不合法，应该检查失败
function TestIam:test_import_ldap_config_add_ldap_group_success()
    local m_remote_group_collection = remote_group_collection.get_instance()
    
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    local PROJECT_DIR = os.getenv('PROJECT_DIR')

    local file = io.open(PROJECT_DIR .. "/test/libiam/unit/test_data/config_ldap_group.json")
    lu.assertNotEquals(file, nil)
    local config_data = file:read("a")
    local object = cjson.decode(config_data).ConfigData
    local config_service = profile_adapter.new()
    local ok = pcall(function ()
        config_service:on_import(ctx, object)
    end)
    lu.assertEquals(ok, true)
    lu.assertEquals(m_remote_group_collection:get_remote_group_by_id('LDAP', 5, '4'):get_remote_group_name(), 'test1')
    -- 恢复环境
    m_remote_group_collection:delete_remote_group(self.ctx, 'LDAP5_4')
    lu.assertEquals(m_remote_group_collection:get_remote_group_by_id('LDAP', 5, '4'), nil)
end
