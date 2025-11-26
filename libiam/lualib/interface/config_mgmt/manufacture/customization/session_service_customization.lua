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
-- Description: 定制化操作时会话服务相关项
local iam_enum = require 'class.types.types'

local SessionServiceCustomization = {}

local MODE_IMPORT_MAP = {['share'] = iam_enum.OccupationMode.Shared, ['monopoly'] = iam_enum.OccupationMode.Exclusive}

local MODE_EXPORT_MAP = {
    [iam_enum.OccupationMode.Shared:value()] = 'share',
    [iam_enum.OccupationMode.Exclusive:value()] = 'monopoly'
}

function SessionServiceCustomization.convert_web_mode(custom_settings)
    return MODE_IMPORT_MAP[custom_settings['BMCSet_WebSessionMode'].Value]:value()
end

function SessionServiceCustomization.set_web_mode(self, ctx, value)
    self.m_session_service:set_session_mode(ctx, iam_enum.SessionType.GUI, iam_enum.OccupationMode.new(value))
    self.m_session_service.m_session_service_collection[iam_enum.SessionType.GUI:value()].m_update_session_service:emit(
        iam_enum.SessionType.GUI, 'SessionMode', value)
end

function SessionServiceCustomization.get_web_mode(self)
    local web_mode = self.m_session_service:get_session_mode(iam_enum.SessionType.GUI):value()
    return MODE_EXPORT_MAP[web_mode]
end

function SessionServiceCustomization.convert_web_timeout(custom_settings)
    return custom_settings['BMCSet_SessionTimeout'].Value * 60
end

function SessionServiceCustomization.set_web_timeout(self, ctx, value)
    self.m_session_service:set_session_timeout(ctx, iam_enum.SessionType.GUI, value)
    self.m_session_service.m_session_service_collection[iam_enum.SessionType.GUI:value()].m_update_session_service:emit(
        iam_enum.SessionType.GUI, 'SessionTimeout', value
    )
end

function SessionServiceCustomization.get_web_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.GUI) // 60
end

function SessionServiceCustomization.convert_kvm_timeout(custom_settings)
    return custom_settings['BMCSet_KVMTimeout'].Value * 60
end

function SessionServiceCustomization.set_kvm_timeout(self, ctx, value)
    self.m_session_service:set_session_timeout(ctx, iam_enum.SessionType.KVM, value)
    self.m_session_service.m_session_service_collection[iam_enum.SessionType.KVM:value()].m_update_session_service:emit(
        iam_enum.SessionType.KVM, 'SessionTimeout', value
    )
end

function SessionServiceCustomization.get_kvm_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.KVM) // 60
end

function SessionServiceCustomization.convert_vnc_timeout(custom_settings)
    return custom_settings['BMCSet_VNCTimeout'].Value * 60
end

function SessionServiceCustomization.set_vnc_timeout(self, ctx, value)
    self.m_session_service:set_session_timeout(ctx, iam_enum.SessionType.VNC, value)
    self.m_session_service.m_session_service_collection[iam_enum.SessionType.VNC:value()].m_update_session_service:emit(
        iam_enum.SessionType.VNC, 'SessionTimeout', value
    )
end

function SessionServiceCustomization.get_vnc_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.VNC) // 60
end

function SessionServiceCustomization.convert_redfish_timeout(custom_settings)
    return custom_settings['BMCSet_RedfishSessionTimeout'].Value * 60
end

function SessionServiceCustomization.set_redfish_timeout(self, ctx, value)
    self.m_session_service:set_session_timeout(ctx, iam_enum.SessionType.Redfish, value)
    self.m_session_service.m_session_service_collection[
        iam_enum.SessionType.Redfish:value()].m_update_session_service:emit(
        iam_enum.SessionType.Redfish, 'SessionTimeout', value
    )
end

function SessionServiceCustomization.get_redfish_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.Redfish) // 60
end

function SessionServiceCustomization.set_redfish_session_max_count(self, ctx, value)
    self.m_session_service:set_session_max_count(ctx, iam_enum.SessionType.Redfish, value)
    self.m_session_service.m_session_service_collection[
        iam_enum.SessionType.Redfish:value()].m_update_session_service:emit(
        iam_enum.SessionType.Redfish, 'SessionMaxCount', value
    )
end

function SessionServiceCustomization.get_redfish_session_max_count(self)
    return self.m_session_service:get_session_max_count(iam_enum.SessionType.Redfish)
end

function SessionServiceCustomization.convert_cli_timeout(custom_settings)
    return custom_settings['BMCSet_CLISessionTimeout'].Value * 60
end

function SessionServiceCustomization.set_cli_timeout(self, ctx, value)
    self.m_session_service:set_session_timeout(ctx, iam_enum.SessionType.CLI, value)
    self.m_session_service.m_session_service_collection[iam_enum.SessionType.CLI:value()].m_update_session_service:emit(
        iam_enum.SessionType.CLI, 'SessionTimeout', value
    )
end

function SessionServiceCustomization.get_cli_timeout(self)
    return self.m_session_service:get_session_timeout(iam_enum.SessionType.CLI) // 60
end

function SessionServiceCustomization.set_web_session_max_count(self, ctx, value)
    self.m_session_service:set_session_max_count(ctx, iam_enum.SessionType.GUI, value)
    self.m_session_service.m_session_service_collection[iam_enum.SessionType.GUI:value()].m_update_session_service:emit(
        iam_enum.SessionType.GUI, 'SessionMaxCount', value
    )
end

function SessionServiceCustomization.get_web_session_max_count(self)
    return self.m_session_service:get_session_max_count(iam_enum.SessionType.GUI)
end

return SessionServiceCustomization