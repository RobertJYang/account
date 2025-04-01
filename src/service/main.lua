-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local skynet = require 'skynet'
require 'skynet.manager'
local logging = require 'mc.logging'
local account_app = require 'account_app'
local skynet_config = require 'skynet_config'

local app = nil
local CMD = {}

function CMD.exit()
    skynet.timeout(0, function()
        logging:info('- account service exit')
        skynet.exit()
    end)
end

skynet.start(function()
    local ok
    logging:notice('account app uniqueservice')
    skynet.uniqueservice('sd_bus')
    logging:notice('account app register service')
    skynet.register(skynet_config.SERVICE_NAME)
    logging:notice('new account app start')
    ok, app = pcall(account_app.new)
    if not ok or not app then
        logging:error('new account app failed, error info : %s', app)
    end
    logging:notice('new account app success')
    skynet.dispatch('lua', function(_, _, cmd, ...)
        local f = assert(CMD[cmd])
        skynet.ret(skynet.pack(f(...)))
    end)
    logging:notice('account app dispatch')
end)
