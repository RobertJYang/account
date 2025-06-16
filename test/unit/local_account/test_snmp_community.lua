-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Test passwords:['Admin123@]
local lu = require 'luaunit'
local custom_msg = require 'messages.custom'

local RO_COMMUNITY_ID<const> = 20
local RW_COMMUNITY_ID<const> = 21
local DEFAULT_RO<const> = 'roAdministrator@9000'
local DEFAULT_RW<const> = 'rwAdministrator@9000'

function TestAccount:test_delete_snmp_community()
    local hist_pwd_count = self.test_global_account_config:get_history_password_count()
    self.test_global_account_config:set_history_password_count(0)
    self.ctx.operation_log = { operation = nil, result = nil, params = {} }
    self.test_account_service:set_account_password(self.ctx, 2, RO_COMMUNITY_ID, "")
    local ro_community = self.test_account_collection.collection[RO_COMMUNITY_ID]:get_account_password()
    lu.assertEquals(ro_community, "")
    lu.assertEquals(self.ctx.operation_log.result, "delete_success")
    lu.assertEquals(self.ctx.operation_log.params.id, RO_COMMUNITY_ID)

    self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, "")
    local rw_community = self.test_account_collection.collection[RW_COMMUNITY_ID]:get_account_password()
    lu.assertEquals(rw_community, "")
    lu.assertEquals(self.ctx.operation_log.result, "delete_success")
    lu.assertEquals(self.ctx.operation_log.params.id, RW_COMMUNITY_ID)
    -- 恢复环境
    self.test_global_account_config:set_history_password_count(hist_pwd_count)
    self.test_account_service:set_account_password(self.ctx, 2, RO_COMMUNITY_ID, DEFAULT_RO)
    self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, DEFAULT_RW)
end

function TestAccount:test_community_contains_space()
    local ok, err = pcall(function()
        self.test_account_service:set_account_password(self.ctx, 2, RO_COMMUNITY_ID, "Huawei 12345678#$%")
    end)
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, custom_msg.CommunityNameNotContainSpaceMessage.Name)
end

-- 测试超长口令使能时的团体名设置
function TestAccount:test_long_community_string_enabled()
    self.ctx.operation_log = { operation = nil, result = nil, params = {} }
    local origin = self.test_global_account_config:get_long_community_enabled()
    self.test_global_account_config:set_long_community_enabled(true)
    local ok, err = pcall(function()
        -- 长度15
        self.test_account_service:set_account_password(self.ctx, 2, RO_COMMUNITY_ID, "Paswd@123456789")
    end)
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, custom_msg.InvalidCommunityNameLengthMessage.Name)
    ok, err = pcall(function()
        -- 长度15
        self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, "Paswd@123456789")
    end)
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, custom_msg.InvalidCommunityNameLengthMessage.Name)
    -- 恢复环境
    self.test_global_account_config:set_long_community_enabled(origin)
end

-- 测试超长口令禁用时的团体名设置
function TestAccount:test_set_community_with_long_community_disable_and_pwd_complexity_disable()
    local long_ori = self.test_global_account_config:get_long_community_enabled()
    self.test_global_account_config:set_long_community_enabled(false)
    local comp_ori = self.test_global_account_config:get_password_complexity_enable()
    -- 关闭密码复杂度检查
    self.test_global_account_config:set_password_complexity_enable(false)
    local hist_pwd_count = self.test_global_account_config:get_history_password_count()
    self.test_global_account_config:set_history_password_count(0)
    self.test_account_service:set_account_password(self.ctx, 2, RO_COMMUNITY_ID, "ro")
    local ro_community = self.test_account_collection.collection[RO_COMMUNITY_ID]:get_account_password()
    lu.assertEquals(ro_community, "ro")
    self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, "rw")
    local rw_community = self.test_account_collection.collection[RW_COMMUNITY_ID]:get_account_password()
    lu.assertEquals(rw_community, "rw")
    -- 开启密码复杂度检查
    -- 长度不足8位报错
    self.test_global_account_config:set_password_complexity_enable(true)
    local ok, err = pcall(self.test_account_service.set_account_password, self.test_account_service,
        self.ctx, 2, RO_COMMUNITY_ID, "Ro1@")
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, custom_msg.InvalidCommunityNameLengthMessage.Name)
    ok, err = pcall(self.test_account_service.set_account_password, self.test_account_service,
        self.ctx, 2, RO_COMMUNITY_ID, "Rw1@")
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, custom_msg.InvalidCommunityNameLengthMessage.Name)
    -- 长度满足8位
    self.test_account_service:set_account_password(self.ctx, 2, RO_COMMUNITY_ID, "Ro12345@")
    ro_community = self.test_account_collection.collection[RO_COMMUNITY_ID]:get_account_password()
    lu.assertEquals(ro_community, "Ro12345@")
    self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, "Rw12345@")
    rw_community = self.test_account_collection.collection[RW_COMMUNITY_ID]:get_account_password()
    lu.assertEquals(rw_community, "Rw12345@")
    -- 恢复环境
    self.test_global_account_config:set_long_community_enabled(long_ori)
    self.test_global_account_config:set_password_complexity_enable(comp_ori)
    self.test_global_account_config:set_history_password_count(hist_pwd_count)
    self.test_account_service:set_account_password(self.ctx, 2, RO_COMMUNITY_ID, DEFAULT_RO)
    self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, DEFAULT_RW)
end

function TestAccount:test_max_community_string_length()
    self.ctx.operation_log = { operation = nil, result = nil, params = {} }
    local ok, err = pcall(function()
        self.test_account_service:set_account_password(self.ctx, 2,
            RO_COMMUNITY_ID, ".Huawei12345678#$%.Huawei12345678")
    end)
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, custom_msg.InvalidCommunityNameLengthMessage.Name)
end

function TestAccount:test_community_in_weak_password_dict()
    self.ctx.operation_log = { operation = nil, result = nil, params = {} }
    local origin = self.test_global_account_config.m_snmp_community.LongCommunityEnabled
    self.test_global_account_config:set_long_community_enabled(false)
    local ok, err = pcall(function()
        self.test_account_service:set_account_password(self.ctx, 2, RO_COMMUNITY_ID, 'Admin123@')
    end)
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, 'PasswordInWeakPWDDict')
    -- 恢复环境
    self.test_global_account_config:set_long_community_enabled(origin)
end

function TestAccount:test_community_complexity_check_fail()
    self.ctx.operation_log = { operation = nil, result = nil, params = {} }
    local origin = self.test_global_account_config.m_snmp_community.LongCommunityEnabled
    self.test_global_account_config:set_long_community_enabled(false)
    local ok, err = pcall(function()
        self.test_account_service:set_account_password(self.ctx, 2, RO_COMMUNITY_ID, '12345678')
    end)
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, custom_msg.PasswordComplexityCheckFailMessage.Name)
    -- 恢复环境
    self.test_global_account_config:set_long_community_enabled(origin)
end

-- 开启密码检查时，新设置的团体名需要和旧的团体名字符串相比有2位以上的差异
function TestAccount:test_community_should_different_with_last_time()
    self.ctx.operation_log = { operation = nil, result = nil, params = {} }
    local complexity_enabled = self.test_global_account_config:get_password_complexity_enable()
    lu.assertEquals(complexity_enabled, true)
    self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, "Huawei12345678#$%")
    local rw_community = self.test_account_collection.collection[RW_COMMUNITY_ID]:get_account_password()
    lu.assertEquals(rw_community, "Huawei12345678#$%")
    lu.assertEquals(self.ctx.operation_log.result, nil)
    lu.assertEquals(self.ctx.operation_log.params.id, RW_COMMUNITY_ID)

    local ok, err = pcall(function()
        self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, 'Huawei12345678#$%')
    end)
    lu.assertEquals(ok, false)
    lu.assertEquals(err.name, custom_msg.RWCommunitySimilarWithHistoryMessage.Name)
end

-- 关闭密码检查时，新设置的团体名不需要和旧的团体名字符串对比
function TestAccount:test_community_similar_with_last_time()
    self.ctx.operation_log = { operation = nil, result = nil, params = {} }
    local complexity_enabled = self.test_global_account_config:get_password_complexity_enable()
    lu.assertEquals(complexity_enabled, true)
    self.test_global_account_config:set_password_complexity_enable(false)
    self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, "Huawei12345678#$%")
    local rw_community = self.test_account_collection.collection[RW_COMMUNITY_ID]:get_account_password()
    lu.assertEquals(rw_community, "Huawei12345678#$%")
    lu.assertEquals(self.ctx.operation_log.result, nil)
    lu.assertEquals(self.ctx.operation_log.params.id, RW_COMMUNITY_ID)

    local ok = pcall(function()
        self.test_account_service:set_account_password(self.ctx, 2, RW_COMMUNITY_ID, 'Huawei12345678#$%')
    end)
    lu.assertEquals(ok, true)
    -- 恢复环境
    self.test_global_account_config:set_password_complexity_enable(complexity_enabled)
end