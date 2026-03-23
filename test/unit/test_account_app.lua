local account_app = require 'account_app'
local lu = require 'luaunit'
local utils_core = require 'utils.core'

function TestAccount:test_check_uptime()
    local tmp_get_uptime = utils_core.get_bmc_uptime
    utils_core.get_bmc_uptime = nil
    local fail_value = account_app:bmcuptime()
    lu.assertEquals(fail_value, 0)

    utils_core.get_bmc_uptime = function()
        return 50
    end
    local success_value = account_app:bmcuptime()
    lu.assertEquals(success_value, 50)

    utils_core.get_bmc_uptime = tmp_get_uptime
end

function TestAccount:test_on_reboot_prepare_with_key_update_done()
    -- 测试密钥更新完成的情况
    account_app.key_mgmt_client = {}
    account_app.key_mgmt_client.m_key_update_done = true
    
    -- 模拟 account_collection.collection
    account_app.account_collection = {}
    account_app.account_collection.collection = {}
    
    local ok = account_app:on_reboot_prepare()
    lu.assertEquals(ok, 0)
end