-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local vos_utils = require 'utils.vos'
local iam_enum = require 'class.types.types'

local SESSION_TOKEN_LEN<const> = 32

local SessionUtils = {}

--- 产生token，注意：字符串形式比十六进制形式长一倍，实际有效随机数按照十六进制长度
function SessionUtils.generate_token()
    local random_string = vos_utils.get_random_array(SESSION_TOKEN_LEN):gsub('.', function(s)
        return string.format('%02x', s:byte())
    end)

    return random_string
end

--- 产生sessionid
---@param token string 
function SessionUtils.generate_session_id(token)
    return vos_utils.compute_checksum(vos_utils.G_CHECKSUM_SHA256, token):sub(1, 24)
end

function SessionUtils.parse_login_interface(session_type, login_interface)
    -- 对于创建SSO会话的请求，使用接口以及接口权限校验为Web
    if session_type == iam_enum.SessionType.SSO then
        return iam_enum.LoginInterface.Web:value()
    end
    -- 针对基础认证，session_type为enum
    if type(session_type) == type(iam_enum) and
        session_type ~= iam_enum.SessionType.GUI and
        session_type ~= iam_enum.SessionType.Redfish then
        return nil
    end
    -- 针对basic_auth，session_type为字符串,直接判断接口权限
    for _, value in pairs(iam_enum.LoginInterface) do
        if type(value) ~= type(iam_enum) or value == iam_enum.LoginInterface.default then
            goto continue
        end

        if string.upper(login_interface) == string.upper(tostring(value)) then
            return value:value()
        end
        ::continue::
    end

    return nil
end

-- 转换会话类型,针对KVM与VNC会话添加SessionMode
function SessionUtils.convert_mdb_session_type(session, host_number)
    local session_type = session.m_session_type
    local session_mode = session.m_session_mode
    if (session_type == iam_enum.SessionType.KVM or session_type == iam_enum.SessionType.VNC) and host_number > 1 then
        local mode_str = session_mode == iam_enum.OccupationMode.Shared and 'Shared' or 'Private'
        local system_id = session.system_id
        return string.format('%s(%s)System(%s)', session_type, mode_str, system_id)
    elseif (session_type == iam_enum.SessionType.KVM or session_type == iam_enum.SessionType.VNC) and host_number == 1 then
        local mode_str = session_mode == iam_enum.OccupationMode.Shared and 'Shared' or 'Private'
        return string.format('%s(%s)', session_type, mode_str)
    elseif session_type == iam_enum.SessionType.GUI and session.m_sso_token then
        return string.format('%s(SSO)', session_type)
    else
        return tostring(session_type)
    end
end

--- 检查远程会话模式冲突:KVM/VNC会话的连接需要校验VNC/KVM会话的会话模式
---@param session_service table 与当前创建会话对应的会话类型Service
---@param cur_session_mode enum 当前创建会话的会话模式 
function SessionUtils.check_remote_console_session_mode_conflicts(session_service, cur_session_mode)
    -- 已有对应会话类型的会话且其模式为独占
    if session_service:get_session_mode() == iam_enum.OccupationMode.Exclusive and
        session_service:get_session_count() > 0 then
        return false
    end
    -- 已有对应会话类型的会话且当前需以独占模式创建会话
    if session_service:get_session_mode() == iam_enum.OccupationMode.Shared and
        session_service:get_session_count() > 0 and cur_session_mode == iam_enum.OccupationMode.Exclusive then
        return false
    end
    return true
end

return SessionUtils
