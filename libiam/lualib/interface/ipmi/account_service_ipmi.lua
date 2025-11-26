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
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local ipmi_cmds = require 'iam.ipmi.ipmi'
local account_service = require 'service.account_service'

local ipmi_running_record = require 'infrastructure.ipmi_running_record'

local AccountServiceIpmi = class()

function AccountServiceIpmi:ctor()
    self.m_account_service = account_service.get_instance()
    self.m_ipmi_running_record = ipmi_running_record.get_instance()
end

function AccountServiceIpmi:init()

end

-- ipmi命令入口
function AccountServiceIpmi:ipmi_test_account_password(req, ctx)
    local rsp = ipmi_cmds.TestUserPassword.rsp.new()
    self.m_ipmi_running_record:proxy(req, rsp, ctx, "set_password", function()
        return self.m_account_service:ipmi_test_account_password(req, ctx)
    end)
    return rsp
end
-- ipmi命令入口结束

return singleton(AccountServiceIpmi)
