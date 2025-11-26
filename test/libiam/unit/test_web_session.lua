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
local gui_session = require 'domain.session_type.session_gui'
local iam_enum = require 'class.types.types'
local lu = require 'luaunit'

function TestIam:test_new_web_session()
    local session_type = gui_session.get_instance()

    lu.assertEquals(session_type.m_session_service_config.SessionType, iam_enum.SessionType.GUI)
    lu.assertEquals(session_type.m_session_service_config.SessionTimeout, 300)
    lu.assertEquals(session_type.m_session_service_config.SessionModeDB, iam_enum.OccupationMode.Shared)
    lu.assertEquals(session_type.m_session_service_config.SessionMaxCount, 4)
end
