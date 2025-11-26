-- Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
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
local iam_enum = require 'class.types.types'
local custom_msg = require 'messages.custom'

local ExtraData<const> = {
    BrowserType = 2,
    SessionMode = 0
}

-- 使用ssotoken创建会话后应删除该sso会话
function TestIam:test_create_session_by_sso_token_should_delete_cur_sso_session()
    local sso_token = self.test_session_service:new_session(self.ctx, 'Administrator', 'Admin@9000',
        iam_enum.SessionType.SSO, 'LocaliBMC', '192.168.2.1', ExtraData)
    local sso_session_id = self.test_session_service:validate_session(iam_enum.SessionType.SSO, sso_token)
    lu.assertNotIsNil(sso_token)
    lu.assertNotIsNil(sso_session_id)
    local token, _, session_id = self.test_session_service:new_session_by_sso(self.ctx, sso_token,
        iam_enum.SessionType.GUI, iam_enum.OccupationMode.Shared)
    lu.assertNotIsNil(token)
    local ok, _ = pcall(function ()
        self.test_session_service:validate_session(iam_enum.SessionType.SSO, sso_token)
    end)
    lu.assertIsFalse(ok)
    -- 恢复
    self.test_session_service:delete_session(self.ctx, session_id, iam_enum.SessionLogoutType.SessionKickout)
end

-- 创建sso1并用其创建会话,再创建sso2,使用sso2创建会话,sso1创建的会话不会被踢出
function TestIam:test_create_sessions_by_two_sso_token_and_no_created_session_should_be_deleted()
    local sso_token1 = self.test_session_service:new_session(self.ctx, 'Administrator', 'Admin@9000',
        iam_enum.SessionType.SSO, 'LocaliBMC', '192.168.2.1', ExtraData)
    local token1, _, session_id1 = self.test_session_service:new_session_by_sso(self.ctx, sso_token1,
        iam_enum.SessionType.GUI, iam_enum.OccupationMode.Shared)
    local sso_token2 = self.test_session_service:new_session(self.ctx, 'Administrator', 'Admin@9000',
        iam_enum.SessionType.SSO, 'LocaliBMC', '192.168.2.1', ExtraData)  
    local token2, _, session_id2 = self.test_session_service:new_session_by_sso(self.ctx, sso_token2,
        iam_enum.SessionType.GUI, iam_enum.OccupationMode.Shared)
    local id1 = self.test_session_service:validate_session(iam_enum.SessionType.GUI, token1)
    local id2 = self.test_session_service:validate_session(iam_enum.SessionType.GUI, token2)
    lu.assertEquals(id1, session_id1)
    lu.assertEquals(id2, session_id2)
    self.test_session_service:delete_all_session(nil, iam_enum.SessionLogoutType.SessionLogout,
        iam_enum.SessionType.All, iam_enum.IpType.All)
    -- 恢复
    self.test_session_service:delete_all_session(self.ctx, iam_enum.SessionLogoutType.SessionKickout,
        iam_enum.SessionType.All, iam_enum.IpType.All)
end

-- 使用一个ssoToken创建多个会话应当失败
function TestIam:test_create_sessions_by_one_sso_token_should_failed()
    -- 创建gui会话后尝试创建gui\kvm会话
    local sso_token = self.test_session_service:new_session(self.ctx, 'Administrator', 'Admin@9000',
        iam_enum.SessionType.SSO, 'LocaliBMC', '192.168.2.1', ExtraData)
    self.test_session_service:new_session_by_sso(self.ctx, sso_token, iam_enum.SessionType.GUI,
        iam_enum.OccupationMode.Shared)
    local ok, info = pcall(function()
        self.test_session_service:new_session_by_sso(self.ctx, sso_token, iam_enum.SessionType.GUI,
            iam_enum.OccupationMode.Shared)
    end)
    lu.assertIsFalse(ok)
    lu.assertEquals(info.name, 'NoValidSession')
    ok, info = pcall(function()
        self.test_session_service:new_session_by_sso(self.ctx, sso_token, iam_enum.SessionType.KVM,
            iam_enum.OccupationMode.Shared)
    end)
    lu.assertIsFalse(ok)
    lu.assertEquals(info.name, 'NoValidSession')
    -- 恢复
    self.test_session_service:delete_all_session(self.ctx, iam_enum.SessionLogoutType.SessionKickout,
        iam_enum.SessionType.All, iam_enum.IpType.All)
    -- 创建kvm会话后尝试创建gui\kvm会话
    sso_token = self.test_session_service:new_session(self.ctx, 'Administrator', 'Admin@9000',
        iam_enum.SessionType.SSO, 'LocaliBMC', '192.168.2.1', ExtraData)
    self.test_session_service:new_session_by_sso(self.ctx, sso_token, iam_enum.SessionType.KVM,
        iam_enum.OccupationMode.Shared)
    ok, info = pcall(function()
        self.test_session_service:new_session_by_sso(self.ctx, sso_token, iam_enum.SessionType.GUI,
            iam_enum.OccupationMode.Shared)
    end)
    lu.assertIsFalse(ok)
    lu.assertEquals(info.name, 'NoValidSession')
    ok, info = pcall(function()
        self.test_session_service:new_session_by_sso(self.ctx, sso_token, iam_enum.SessionType.KVM,
            iam_enum.OccupationMode.Shared)
    end)
    lu.assertIsFalse(ok)
    lu.assertEquals(info.name, 'NoValidSession')
    -- 恢复
    self.test_session_service:delete_all_session(self.ctx, iam_enum.SessionLogoutType.SessionKickout,
        iam_enum.SessionType.All, iam_enum.IpType.All)
end

-- 创建sso1,再创建sso2,使用sso1创建会话应当失败
function TestIam:test_when_new_two_sso_session_should_not_create_session_by_sso1()
    local sso_token = self.test_session_service:new_session(self.ctx, 'Administrator', 'Admin@9000',
        iam_enum.SessionType.SSO, 'LocaliBMC', '192.168.2.1', ExtraData)
    self.test_session_service:new_session(self.ctx, 'Administrator', 'Admin@9000',
        iam_enum.SessionType.SSO, 'LocaliBMC', '192.168.2.1', ExtraData)  
    local ok, info = pcall(function ()
        self.test_session_service:new_session_by_sso(self.ctx, sso_token,
            iam_enum.SessionType.GUI, iam_enum.OccupationMode.Shared)
    end)
    lu.assertIsFalse(ok)
    lu.assertEquals(info.name, 'NoValidSession')
    -- 恢复
    self.test_session_service:delete_all_session(self.ctx, iam_enum.SessionLogoutType.SessionKickout,
        iam_enum.SessionType.All, iam_enum.IpType.All)
end

-- 通过ipmi接口删除存在的SSO会话应该成功
function TestIam:test_delete_exist_sso_session_by_ipmi_should_success()
    local sso_token = self.test_session_service:new_session(self.ctx, 'Administrator', 'Admin@9000',
        iam_enum.SessionType.SSO, 'LocaliBMC', '192.168.2.1', ExtraData)
    local req = {}
    local ctx = {}
    req.ManufactureId = 0x0007db
    req.length = #sso_token
    ctx.ChanType = iam_enum.IpmiChannelType.IPMI_SMM:value()
    ctx.operation_log = {}
    req.token = sso_token
    local ret = pcall(function()
        return self.test_session_ipmi:delete_sso_session(req, ctx)
    end)
    lu.assertIsTrue(ret)
end

-- 通过token长度与length参数不相等应该失败
function TestIam:test_token_length_not_equal_length_should_fail()
    local sso_token = 'testipmi'
    local req = {}
    local ctx = {}
    req.ManufactureId = 0x0007db
    req.length = #sso_token - 1
    ctx.ChanType = iam_enum.IpmiChannelType.IPMI_SMM:value()
    ctx.operation_log = {}
    req.token = sso_token
    local ret, err = pcall(function()
        return self.test_session_ipmi:delete_sso_session(req, ctx)
    end)
    lu.assertIsFalse(ret)
    lu.assertEquals(err.name, custom_msg.IPMIOutOfRangeMessage.Name)
end

-- 通过ipmi接口删除不存在的SSO会话应该失败
function TestIam:test_delete_not_exist_sso_session_by_ipmi_should_success()
    local sso_token = 'test'
    local req = {}
    local ctx = {}
    req.ManufactureId = 0x0007db
    req.length = #sso_token
    ctx.ChanType = iam_enum.IpmiChannelType.IPMI_SMM:value()
    ctx.operation_log = {}
    req.token = sso_token
    local ret = pcall(function()
        return self.test_session_ipmi:delete_sso_session(req, ctx)
    end)
    lu.assertIsFalse(ret)
end