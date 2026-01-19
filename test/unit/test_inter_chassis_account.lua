-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local enum = require 'class.types.types'
local config = require 'common_config'

function TestAccount:test_recover_inter_chassis_account()
    local default_role = enum.RoleType.Administrator:value()
    local default_interface = enum.LoginInterface.Web:value() + enum.LoginInterface.Redfish:value() +
        enum.LoginInterface.SSH:value() + enum.LoginInterface.SFTP:value()
    local account_data = self.test_account_collection:get_account_data_by_id(config.INTER_CHASSIS_ACCOUNT_ID)

    -- 校验默认配置
    lu.assertEquals(account_data.RoleId, default_role)
    lu.assertEquals(account_data.LoginInterface, default_interface)
    lu.assertEquals(account_data.DefaultRoleId, default_role)
    lu.assertEquals(account_data.DefaultLoginInterface, default_interface)

    -- 进行设置
    self.test_account_collection:set_role_id(self.ctx, config.INTER_CHASSIS_ACCOUNT_ID, enum.RoleType.CommonUser:value())
    self.test_account_collection:set_login_interface(self.ctx, config.INTER_CHASSIS_ACCOUNT_ID, {'Web', 'Redfish'})

    lu.assertEquals(account_data.RoleId, enum.RoleType.CommonUser:value())
    lu.assertEquals(account_data.LoginInterface, enum.LoginInterface.Web:value() + enum.LoginInterface.Redfish:value())
    lu.assertEquals(account_data.DefaultRoleId, default_role)
    lu.assertEquals(account_data.DefaultLoginInterface, default_interface)

    -- 调用删除接口
    self.test_account_collection:delete_account(self.ctx, config.INTER_CHASSIS_ACCOUNT_ID)

    -- 校验当前配置
    lu.assertEquals(account_data.RoleId, default_role)
    lu.assertEquals(account_data.LoginInterface, default_interface)
    lu.assertEquals(account_data.DefaultRoleId, default_role)
    lu.assertEquals(account_data.DefaultLoginInterface, default_interface)
end