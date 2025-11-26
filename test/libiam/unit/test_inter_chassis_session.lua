-- Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local custom_msg = require 'messages.custom'
local iam_enum = require 'class.types.types'
local lu = require 'luaunit'

function TestIam:test_new_inter_chassis_session()
    -- 打桩一个23号用户
    self.test_account_cache.cache_collection[23] = {
        Id = 23,
        UserName = '<inter chassis>',
        RoleId = iam_enum.RoleType.Administrator:value(),
        AccountType = iam_enum.AccountType.InterChassis,
        LastLoginIP = '',
        LastLoginTime = 0xffffffff,
        current_privileges = {
            tostring(iam_enum.PrivilegeType.ConfigureSelf),
            tostring(iam_enum.PrivilegeType.DiagnoseMgmt),
            tostring(iam_enum.PrivilegeType.PowerMgmt),
            tostring(iam_enum.PrivilegeType.SecurityMgmt),
            tostring(iam_enum.PrivilegeType.VMMMgmt),
            tostring(iam_enum.PrivilegeType.KVMMgmt),
            tostring(iam_enum.PrivilegeType.BasicSetting),
            tostring(iam_enum.PrivilegeType.UserMgmt),
            tostring(iam_enum.PrivilegeType.ReadOnly)
        },
        PasswordChangeRequired = false,
        FirstLoginPolicy = iam_enum.FirstLoginPolicy.PromptPasswordReset,
        is_flush = true
    }

    -- 创建会话
    local token, csrf_token, session_id =
        self.test_session_service:new_session_by_cert(self.ctx, "", "", "", '127.0.0.1',
        iam_enum.NewSessionBrowserType.InterChassis:value())

    lu.assertNotIsNil(token)
    lu.assertNotIsNil(csrf_token)
    lu.assertNotIsNil(session_id)

    -- 查看会话信息
    local session = self.test_session_service:get_session_by_session_id(session_id)
    lu.assertNotIsNil(session)
    lu.assertEquals(session.m_username, '<inter chassis>')
    lu.assertEquals(session.m_role_id, iam_enum.RoleType.Administrator:value())
    lu.assertEquals(tostring(session.m_session_type), "INTER_CHASSIS")

    -- 校验会话信息(请求会以Redfish类型发过来校验)
    local validate_session_id =
        self.test_session_service:validate_session(iam_enum.SessionType.Redfish, token, csrf_token)
    lu.assertEquals(validate_session_id, session_id)

    -- 恢复
    local session_type_num = iam_enum.SessionType.INTER_CHASSIS:value()
    local collection =  self.test_session_service.m_session_service_collection[session_type_num]
    collection:delete(session_id)
    self.test_account_cache.cache_collection[23] = nil
end

function TestIam:test_no_access_to_create_inter_chassis_session()
    -- 打桩一个23号用户
    self.test_account_cache.cache_collection[23] = {
        Id = 23,
        UserName = '<inter chassis>',
        RoleId = iam_enum.RoleType.NoAccess:value(),
        AccountType = iam_enum.AccountType.InterChassis,
        LastLoginIP = '',
        LastLoginTime = 0xffffffff,
        current_privileges = {},
        PasswordChangeRequired = false,
        FirstLoginPolicy = iam_enum.FirstLoginPolicy.PromptPasswordReset,
        is_flush = true
    }

    -- 尝试创建会话
    lu.assertErrorMsgContains(custom_msg.NoAccessMessage.Name, function()
        self.test_session_service:new_session_by_cert(self.ctx, "", "", "", '127.0.0.1',
        iam_enum.NewSessionBrowserType.InterChassis:value())
    end)

    -- 恢复
    self.test_account_cache.cache_collection[23] = nil
end