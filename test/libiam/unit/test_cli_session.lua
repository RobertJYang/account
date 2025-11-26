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
local cli_session = require 'domain.session_type.session_cli'
local iam_enum = require 'class.types.types'
local lu = require 'luaunit'

function TestIam:test_new_cli_session()
    local session_type = cli_session.get_instance()

    lu.assertEquals(session_type.m_session_service_config.SessionType, iam_enum.SessionType.CLI)
    lu.assertEquals(session_type.m_session_service_config.SessionTimeout, 900)
    lu.assertEquals(session_type.m_session_service_config.SessionModeDB, iam_enum.OccupationMode.Shared)
    lu.assertEquals(session_type.m_session_service_config.SessionMaxCount, 10)
end


-- 获取cli在线会话
function TestIam:test_get_cli_session_online_list()
    local stub_cli_online_list = {}
    local stub_cli_online_session = {
        pid = 20000,
        username = 'stub_cli_user',
        host = '127.0.0.1',
        login_time = 1678349284
    }
    table.insert(stub_cli_online_list, stub_cli_online_session)
    local cli_session_list = cli_session.get_cli_online_session(stub_cli_online_list)
    lu.assertEquals(cli_session_list[1].m_session_id, 'cli20000')
    lu.assertEquals(cli_session_list[1].m_username, 'stub_cli_user')
    lu.assertEquals(cli_session_list[1].m_ip, '127.0.0.1')
    lu.assertEquals(cli_session_list[1].m_created_time, 1678349284)
end

-- 根据用户名删进程需对特殊字符转义
function TestIam:test_escape_username_if_exist_special_characters()
    local raw_username = "name`$!|;*"
    local escape_username = cli_session.get_instance():escape_username(raw_username)
    lu.assertEquals(escape_username, 'name\\`\\$\\!\\|\\;\\*')
end