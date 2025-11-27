-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 配置导入导出时会话服务相关项
local iam_enum = require 'class.types.types'

local SessionServiceProfile = {}

function SessionServiceProfile.set_web_timeout(self, ctx, value)
    self.m_session_service:set_session_timeout(ctx, iam_enum.SessionType.GUI, value)
    self.m_session_service.m_session_service_collection[iam_enum.SessionType.GUI:value()].m_update_session_service:emit(
        iam_enum.SessionType.GUI, 'SessionTimeout', value
    )
end

function SessionServiceProfile.get_web_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.GUI)
end

function SessionServiceProfile.set_redfish_timeout(self, ctx, value)
    self.m_session_service:set_session_timeout(ctx, iam_enum.SessionType.Redfish, value)
    self.m_session_service.m_session_service_collection[
        iam_enum.SessionType.Redfish:value()].m_update_session_service:emit(
        iam_enum.SessionType.Redfish, 'SessionTimeout', value)
end

function SessionServiceProfile.get_redfish_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.Redfish)
end

function SessionServiceProfile.set_web_mode(self, ctx, value)
    self.m_session_service:set_session_mode(ctx, iam_enum.SessionType.GUI, iam_enum.OccupationMode.new(value))
    self.m_session_service.m_session_service_collection[iam_enum.SessionType.GUI:value()].m_update_session_service:emit(
        iam_enum.SessionType.GUI, 'SessionMode', value
    )
end

function SessionServiceProfile.get_web_mode(self)
    return self.m_session_service:get_session_mode(iam_enum.SessionType.GUI):value()
end

function SessionServiceProfile.get_redfish_session_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.Redfish)
end

function SessionServiceProfile.get_cli_session_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.CLI)
end

function SessionServiceProfile.set_cli_timeout(self, ctx, value)
    self.m_session_service:set_session_timeout(ctx, iam_enum.SessionType.CLI, value)
    self.m_session_service.m_session_service_collection[iam_enum.SessionType.CLI:value()].m_update_session_service:emit(
        iam_enum.SessionType.CLI, 'SessionTimeout', value
    )
end

function SessionServiceProfile.get_cli_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.CLI)
end

return SessionServiceProfile