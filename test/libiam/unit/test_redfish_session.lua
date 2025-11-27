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
local redfish_session = require 'domain.session_type.session_redfish'
local iam_enum = require 'class.types.types'
local lu = require 'luaunit'
local custom_msg = require 'messages.custom'

function TestIam:test_new_redfish_session()
    local session_type = redfish_session.get_instance()

    lu.assertEquals(session_type.m_session_service_config.SessionType, iam_enum.SessionType.Redfish)
    lu.assertEquals(session_type.m_session_service_config.SessionTimeout, 300)
    lu.assertEquals(session_type.m_session_service_config.SessionModeDB, iam_enum.OccupationMode.Shared)
    lu.assertEquals(session_type.m_session_service_config.SessionMaxCount, 10)
end

function TestIam:test_set_max_count_should_failed_when_exceed_limited()
    local session_type = redfish_session.get_instance()
    lu.assertErrorMsgContains(custom_msg.PropertyValueOutOfRangeMessage.Name, function()
        session_type:set_session_max_count(21)
    end)
    lu.assertEquals(session_type.m_session_service_config.SessionMaxCount, 10)
end

function TestIam:test_set_max_count_should_success()
    local session_type = redfish_session.get_instance()
    session_type:set_session_max_count(15)

    lu.assertEquals(session_type.m_session_service_config.SessionMaxCount, 15)
    session_type:set_session_max_count(10)
end