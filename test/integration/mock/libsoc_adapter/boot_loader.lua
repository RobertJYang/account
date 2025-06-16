-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'

local boot_loader = {}
setmetatable(boot_loader, {__close = function()
end})

function boot_loader.new()
    return boot_loader
end

function boot_loader:get_pcie_controller_state(id)
    lu.assertEquals(id, 1)
    return self.state
end

function boot_loader:set_pcie_controller_state(id, state)
    lu.assertEquals(id, 1)
    self.state = state
end

return boot_loader