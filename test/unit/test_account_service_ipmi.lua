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

local function make_interface()
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
    enum.LoginInterface.SFTP, enum.LoginInterface.SNMP }
    return interface
end

-- 获取用户服务成功测试,检查密码使能
function TestAccount:test_ipmi_get_weak_pwd_dictionary_enable_success()
    local req = {}
    local ctx = {}
    req.Function = 0x01
    req.Length = 0x01
    local rsp = self.test_account_service_ipmi:get_weak_pwd_dictionary_enable(req, ctx)
    assert(string.byte(rsp.Data) == 0x01)
end

-- 获取用户服务成功测试,用户首次登录密码修改策略
function TestAccount:test_ipmi_get_first_login_policy_by_id_success()
    local req = {}
    local ctx = {}
    req.Function = 0x02
    req.UserId = 0x02
    local rsp = self.test_account_service_ipmi:get_first_login_policy_by_id(req, ctx)
    assert(string.byte(rsp.Data) == 0x01)
end

-- 获取用户服务成功测试,检查历史密码数
function TestAccount:test_ipmi_get_history_password_count_success()
    local req = {}
    local ctx = {}
    req.Function = 0x03
    local rsp = self.test_account_service_ipmi:get_history_password_count(req, ctx)
    assert(string.byte(rsp.Data) == 0x05)
end

-- 设置用户服务成功测试,历史密码检查数
function TestAccount:test_ipmi_set_history_passwd_check_count_success()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x03
    req.Length = 0x01
    req.Data = string.char(0x03)
    local ret = pcall(function() self.test_account_service_ipmi:set_history_passwd_check_count(req, ctx) end)
    assert(ret)

    -- 检测结果
    local rsp = self.test_account_service_ipmi:get_history_password_count(req, ctx)
    assert(string.byte(rsp.Data) == 0x03)

    req.Data = string.char(0x05)
    ret = pcall(function() self.test_account_service_ipmi:set_history_passwd_check_count(req, ctx) end)
    assert(ret)
end

-- 设置用户服务成功测试,首次登陆策略
function TestAccount:test_ipmi_set_first_login_passwd_modify_policy_success()
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.PromptPasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x02
    req.UserId = 0x03
    req.Length = 0x01
    req.Data = string.char(0x00)
    local ret = pcall(function() self.test_account_service_ipmi:set_first_login_passwd_modify_policy(req, ctx) end)
    assert(ret)

    -- 检测结果
    local rsp = self.test_account_service_ipmi:get_first_login_policy_by_id(req, ctx)
    assert(string.byte(rsp.Data) == 0x00)
    self.test_account_collection:delete_account(self.ctx, 3)
end

-- 设置用户服务成功测试,弱口令检测
function TestAccount:test_ipmi_set_weak_pwd_dictionary_enable_success()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x01
    req.Length = 0x01
    req.Data = string.char(0x00)
    local ret = pcall(function() self.test_account_service_ipmi:set_weak_pwd_dictionary_enable(req, ctx) end)
    assert(ret)

    -- 检测结果
    local rsp = self.test_account_service_ipmi:get_weak_pwd_dictionary_enable(req, ctx)
    assert(string.byte(rsp.Data) == 0x00)

    -- 恢复环境
    req.Data = string.char(0x01)
    ret = pcall(function() self.test_account_service_ipmi:set_weak_pwd_dictionary_enable(req, ctx) end)
    assert(ret)
end

-- 设置用户服务失败测试,弱口令检测
function TestAccount:test_ipmi_set_weak_pwd_dictionary_enable_failed()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x01
    req.Length = 0x02
    req.Data = string.char(0x00)
    local ret = pcall(function()
        self.test_account_service_ipmi:set_weak_pwd_dictionary_enable(req, ctx)
    end)
    assert(ret == false)
end

-- 设置用户服务失败测试,历史密码数
function TestAccount:test_ipmi_set_history_passwd_check_count_failed()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x03         -- 历史密码数功能
    req.Length = 0x01
    req.Data = string.char(0x07)
    local ret = pcall(function()
        self.test_account_service_ipmi:set_history_passwd_check_count(req, ctx)
    end)
    assert(ret == false)
end

-- 设置用户服务失败测试,用户首次登录密码修改
function TestAccount:test_ipmi_set_first_login_passwd_modify_policy_failed()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x02         -- web超时功能
    req.Length = 0x01
    req.UserId = 0x03
    req.Data = string.pack(">H", 3)
    local ret = pcall(function()
        self.test_account_service_ipmi:set_first_login_passwd_modify_policy(req, ctx)
    end)
    assert(ret == false)
end

-- 获取逃生用户,初始未设置逃生用户
function TestAccount:test_ipmi_get_emergency_login_account()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x05         -- 逃生用户
    local rsp = self.test_account_service_ipmi:get_emergency_login_account(req, ctx)

    assert(string.byte(rsp.Data) == 0x00)
end

-- 获取逃生用户,逃生用户为Administrator，id2
function TestAccount:test_ipmi_get_emergency_login_account_should_correct()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    self.test_account_service:set_emergency_account(ctx, 2)
    req.Function = 0x05         -- 逃生用户
    local rsp = self.test_account_service_ipmi:get_emergency_login_account(req, ctx)
    assert(string.byte(rsp.Data) == 0x02)
    -- 恢复操作
    self.test_account_service:set_emergency_account(ctx, 0)
end

-- 获取初始密码开关,默认打开
function TestAccount:test_ipmi_get_initial_password_prompt_enable()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x06         -- 初始密码开关
    local rsp = self.test_account_service_ipmi:get_initial_password_prompt_enable(req, ctx)
    assert(string.byte(rsp.Data) == 0x01)
end

-- 获取初始密码开关,关闭开关
function TestAccount:test_ipmi_get_initial_password_prompt_enable_when_disable()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    self.test_account_service:set_initial_password_prompt_enable(false)
    req.Function = 0x06         -- 初始密码开关
    local rsp = self.test_account_service_ipmi:get_initial_password_prompt_enable(req, ctx)
    assert(string.byte(rsp.Data) == 0x00)
    -- 恢复操作
    self.test_account_service:set_initial_password_prompt_enable(true)
end

-- 设置逃生用户,并移除应当成功
function TestAccount:test_ipmi_set_emergency_login_account_then_remove_should_success()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x05         -- 逃生用户
    req.Length = 0x01
    req.Data = string.char(0x02)
    local ret = pcall(function()
        self.test_account_service_ipmi:set_emergency_login_account(req, ctx)
    end)
    assert(ret == true)
    local emergency_account_id = self.test_global_account_config:get_emergency_account()
    assert(emergency_account_id == 2)
    req.Data = string.char(0x00)
    ret = pcall(function()
        self.test_account_service_ipmi:set_emergency_login_account(req, ctx)
    end)
    assert(ret == true)
    emergency_account_id = self.test_global_account_config:get_emergency_account()
    assert(emergency_account_id == 0)
end

-- 设置逃生用户为不存在的用户应当失败
function TestAccount:test_ipmi_set_emergency_login_account_then_user_not_exist_should_failed()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x05         -- 逃生用户
    req.Length = 0x01
    req.Data = string.char(0x11)
    local ret = pcall(function()
        self.test_account_service_ipmi:set_emergency_login_account(req, ctx)
    end)
    assert(ret == false)
    local emergency_account_id = self.test_global_account_config:get_emergency_account()
    assert(emergency_account_id == 0)
end

-- 设置初始密码开关关闭,应当成功
function TestAccount:test_ipmi_set_disable_initial_password_prompt_should_success()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.Function = 0x06         -- 初始密码开关
    req.Length = 0x01
    req.Data = string.char(0x00)
    local ret = pcall(function()
        self.test_account_service_ipmi:set_initial_password_prompt_enable(req, ctx)
    end)
    assert(ret == true)
    local state = self.test_global_account_config:get_initial_password_prompt_enable()
    assert(state == false)
    -- 恢复
    req.Data = string.char(0x01)
    ret = pcall(function()
        self.test_account_service_ipmi:set_initial_password_prompt_enable(req, ctx)
    end)
    assert(ret == true)
    state = self.test_global_account_config:get_initial_password_prompt_enable()
    assert(state == true)
end

-- 获取用户接口测试，
function TestAccount:test_ipmi_get_account_interface()
    local req = {}
    local ctx = {}
    ctx.ChanType = enum.IpmiChannelType.IPMI_HOST:value()
    req.UserId = 0x02
    req.ManufactureId = 0x0007db
    local rsp = self.test_account_service_ipmi:get_account_interface(req, ctx)
    assert(rsp.Interface == 0xff)
end

-- 获取用户名超过userID测试，
function TestAccount:test_ipmi_get_account_name_by_id_failed()
    local req = {}
    local ctx = {}
    ctx.ChanType = enum.IpmiChannelType.IPMI_HOST:value()
    req.UserId = 0xFF
    req.ManufactureId = 0x0007db
    local ret = pcall(function()
        self.test_account_service_ipmi:get_user_name(req, ctx)
    end)
    assert(ret == false)
end

-- 获取用户名密码对比信息
function TestAccount:test_ipmi_get_user_name_password_compare_info()
    local req = {}
    req.ManufactureId = 0x0007db
    local rsp = self.test_account_service_ipmi:get_user_name_password_compared_info(req)
    lu.assertEquals(rsp.CompareEnabled, enum.IpmiSetTwoFactorState.Disable:value())
    lu.assertEquals(rsp.CompareLength, config.USERNAME_PWD_COMPARE_DEFAULT_LEN)
end

-- 设置用户名密码对比信息合法值，应当成功
function TestAccount:test_ipmi_set_user_name_password_compare_info_should_success()
    local req = {}
    req.ManufactureId = 0x0007db
    local default = self.test_account_service_ipmi:get_user_name_password_compared_info(req)

    local ctx = {}
    ctx.operation_log = {}
    ctx.operation_log.params = {}
    req.CompareEnabled = 0x01
    req.CompareLength = 0x06
    self.test_account_service_ipmi:set_user_name_password_compared_info(req, ctx)
    local rsp = self.test_account_service_ipmi:get_user_name_password_compared_info(req)
    lu.assertEquals(rsp.CompareEnabled, enum.IpmiSetTwoFactorState.Enable:value())
    lu.assertEquals(rsp.CompareLength, 6)

    -- 恢复环境
    req.CompareEnabled = default.CompareEnabled
    req.CompareLength = default.CompareLength
    self.test_account_service_ipmi:set_user_name_password_compared_info(req, ctx)
end

-- 查询框内通信信息应该成功
function TestAccount:test_ipmi_get_inter_chassis_account_role_should_success()
    local req = {}
    local ctx = {}
    req.ManufactureId = 0x0007db
    req.ParameterSelector = 0x01

    -- 设置当前环境支持查询框内通信信息
    self.test_account_service_ipmi.is_support_inter_chassis_auth = true
    local _, rsp = pcall(function()
        return self.test_account_service_ipmi:get_inter_chassis_role(req, ctx)
    end)

    lu.assertEquals(rsp.Data, string.char(0x04))

    req.ManufactureId = 0x000700
    local res, _ = pcall(function()
        return self.test_account_service_ipmi:get_inter_chassis_role(req, ctx)
    end)
    lu.assertEquals(res, false)
end

-- 查询框内通信信息应该成功
function TestAccount:test_ipmi_get_inter_chassis_account_interface_should_success()
    local req = {}
    local ctx = {}
    req.ManufactureId = 0x0007db
    req.ParameterSelector = 0x02

    -- 设置当前环境支持查询框内通信信息
    self.test_account_service_ipmi.is_support_inter_chassis_auth = true
    local _, rsp = pcall(function()
        return self.test_account_service_ipmi:get_inter_chassis_interface(req, ctx)
    end)

    lu.assertEquals(rsp.Data, string.char(0x99))

    req.ManufactureId = 0x000700
    local res, _ = pcall(function()
        return self.test_account_service_ipmi:get_inter_chassis_interface(req, ctx)
    end)
    lu.assertEquals(res, false)
end