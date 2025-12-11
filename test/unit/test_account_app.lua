local account_app = require 'account_app'
local lu = require 'luaunit'
local utils_core = require 'utils.core'

function TestAccount:test_init_app()
    local tmp_super = account_app.super.init
    local tmp_patch = account_app.patch
    local tmp_check = account_app.check_dependencies
    local tmp_rpc_methods = account_app.register_rpc_methods
    local tmp_ipmi_methods = account_app.register_ipmi_methods
    local tmp_account_service = account_app.service_init

    local tmp_key_client = account_app.key_mgmt_client
    local tmp_file_synchronization = account_app.file_synchronization
    local tmp_account_collection = account_app.account_collection
    local tmp_account_init = account_app.account_service

    local tmp_account_garbage = account_app.collection_garbage_init
    local tmp_channel_num = account_app.monitor_ipmi_channel_num

    account_app.super.init = function(...)
    end

    account_app.patch = function(...)
    end

    account_app.check_dependencies = function(...)
    end

    account_app.register_rpc_methods = function(...)
    end

    account_app.register_ipmi_methods = function(...)
    end
    
    account_app.key_mgmt_client = {}

    account_app.service_init = function(...)
    end

    account_app.account_collection = {
        emit_init_account_signal = function(...)
        end
    }
    account_app.file_synchronization = {
        account_monitor = function(...)
        end
    }
    account_app.account_service = {
        user_time_info_monitor = function(...)
        end
    }

    account_app.collection_garbage_init = function(...)
    end

    account_app.monitor_ipmi_channel_num = function(...)
    end

    local tmp_uptime = account_app:init()
    lu.assertEquals(tmp_uptime, 0)

    account_app.super.init = tmp_super
    account_app.patch = tmp_patch
    account_app.check_dependencies = tmp_check
    account_app.register_rpc_methods = tmp_rpc_methods
    account_app.register_ipmi_methods = tmp_ipmi_methods
    account_app.service_init = tmp_account_service

    account_app.key_mgmt_c = tmp_key_client
    account_app.file_synchronization = tmp_file_synchronization
    account_app.account_collection = tmp_account_collection
    account_app.account_service = tmp_account_init

    account_app.collection_garbage_init = tmp_account_garbage
    account_app.monitor_ipmi_channel_num = tmp_channel_num
end

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