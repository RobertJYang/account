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
local iam_enum = require 'class.types.types'
local utils = require 'utils'

local function ctor_ipmi_get_auth_token_req(req, ctx)
    ctx.ChanType = iam_enum.IpmiChannelType.IPMI_BMA:value()
    req.RoleId = 4
    req.IpMode = 0
    req.IpAddress = utils.ipv4_string_to_binary("127.0.0.1")
    req.SessionType = iam_enum.SessionType.Redfish:value()
    req.ManufactureId = 0x0007db
end

-- 通过不支持的通道获取内部会话token应当失败
function TestIam:test_ipmi_get_inner_token_in_unsupported_chan_should_failed()
    local req = {}
    local ctx = {}
    ctor_ipmi_get_auth_token_req(req, ctx)
    ctx.ChanType = iam_enum.IpmiChannelType.IPMI_LAN:value()
    local ret = pcall(self.test_session_ipmi.ipmi_get_auth_token, self, req, ctx)
    assert(ret == false)
end

-- 错误参数获取内部会话token应当失败
function TestIam:test_ipmi_get_inner_token_with_unsupported_param_should_failed()
    local req = {}
    local ctx = {}
    ctor_ipmi_get_auth_token_req(req, ctx)
    -- 不支持的RoleId创建失败
    req.RoleId = 5
    local ret = pcall(self.test_session_ipmi.ipmi_get_auth_token, self, req, ctx)
    assert(ret == false)
    req.RoleId = 0
    ret = pcall(self.test_session_ipmi.ipmi_get_auth_token, self, req, ctx)
    assert(ret == false)
    req.RoleId = 4
    -- 不支持的会话类型
    req.SessionType = iam_enum.SessionType.CLI:value()
    local ret = pcall(self.test_session_ipmi.ipmi_get_auth_token, self, req, ctx)
    assert(ret == false)
    req.SessionType = iam_enum.SessionType.GUI:value()
    ret = pcall(self.test_session_ipmi.ipmi_get_auth_token, self, req, ctx)
    assert(ret == false)
    req.SessionType = iam_enum.SessionType.Redfish:value()
    -- 不支持的IpMode
    req.IpMode = 2
    ret = pcall(self.test_session_ipmi.ipmi_get_auth_token, self, req, ctx)
    assert(ret == false)
end

-- 转换ipv4进制成功测试
function TestIam:test_ip_to_binary_change_success()
    local a = utils.ipv4_string_to_binary('127.1.1.1')
    local b = utils.ipv4_binary_to_string(a)
    assert(b == '127.1.1.1')
end


-- 获取用户服务成功测试,web超时时间
function TestIam:test_ipmi_get_account_service_configuration_success4()
    local req = {}
    local ctx = {}
    req.Function = 0x04
    req.Length = 0x01
    local rsp = self.test_session_ipmi:get_web_timeout(req, ctx)
    assert(string.unpack(">H", rsp.Data) == 0x05)
end

-- 设置用户服务成功测试,web超时时间
function TestIam:test_ipmi_set_accounts_service_configuration_web_timeout_success()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x04
    req.Length = 0x02
    req.Data = string.pack(">H", 480)
    local ret = pcall(function()
        self.test_session_ipmi:set_web_timeout(req, ctx)
    end)
    assert(ret)

    req.Data = string.pack(">H", 5)
    ret = pcall(function()
        self.test_session_ipmi:set_web_timeout(req, ctx)
    end)
    assert(ret)
end

-- 设置用户服务失败测试,web超时时间
function TestIam:test_ipmi_set_accounts_service_configuration_web_timeout_failed()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x04        -- web超时功能
    req.Length = 0x01
    req.Data = string.pack(">H", 480)
    local ret = pcall(function()
        self.test_session_ipmi:set_web_timeout(req, ctx)
    end)
    assert(ret == false)
end

-- 设置用户服务失败测试,web超时时间
function TestIam:test_ipmi_set_accounts_service_configuration_web_timeout_failed2()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x04         -- web超时功能
    req.Length = 0x01
    req.Data = string.pack(">H", 3)
    local ret = pcall(function()
        self.test_session_ipmi:set_web_timeout(req, ctx)
    end)
    assert(ret == false)
end