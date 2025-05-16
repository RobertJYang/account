-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local sqlite3 = require 'lsqlite3'
local profile_adapter = require 'interface.config_mgmt.profile.profile_adapter'
local mc_context = require 'mc.context'
local cjson = require 'cjson'

-- 删除测试用户
local function teardown_account_data(ctx, account_collection, num)
    for id = 3, num + 3 do
        if account_collection:get_account_data_by_id(id) then
            account_collection:delete_account(ctx, id)
        end
    end
end

function TestAccount:test_when_import_account_config_then_add_user_should_success()
    local ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    local PROJECT_DIR = os.getenv('PROJECT_DIR')

    local file = io.open(PROJECT_DIR .. "/test/unit/test_data/config_add_user.json")
    lu.assertNotEquals(file, nil)
    local config_data = file:read("a")
    local object = cjson.decode(config_data).ConfigData

    local config_service = profile_adapter.new()
    config_service:on_import(ctx, object)
    lu.assertEquals(self.test_account_collection:get_user_name(3), 'test3')

    --恢复环境
    teardown_account_data(self.ctx, self.test_account_collection, 3)
end
