-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.

local base_msg = require 'messages.base'
local class = require 'mc.class'
local file_utils = require 'utils.file'
local utils_core = require 'utils.core'
local iam_utils = require 'infrastructure.iam_utils'
local log = require 'mc.logging'
local mc_utils = require 'mc.utils'
local session_service = require 'service.session_service'
local singleton = require 'mc.singleton'

local Dump = class()

function Dump:ctor()
    self.session_service = session_service.get_instance()
end

function Dump:log_dump(ctx, path)
    if file_utils.check_real_path_s(path) ~= 0 then
        log:error('Dump path is invalid')
        error(base_msg.InternalError())
    end
    local log_file = path ..'/iam_info.txt'
    local info_table = {}
    info_table[#info_table + 1] = string.format('iam information:\n')
    info_table[#info_table + 1] = string.format('\nSession list:\n')
    for _, value in pairs(self.session_service.m_session_service_collection) do
        for _, session in pairs(value.m_session_collection) do
            info_table[#info_table + 1] = string.format('AccountId:%s\n', session.m_account_id)
            info_table[#info_table + 1] = string.format('AuthType:%s\n', session.m_auth_type)
            info_table[#info_table + 1] = string.format('SessionType:%s\n', session.m_session_type)
            info_table[#info_table + 1] = string.format('CreatedTime:%s\n',
                iam_utils.convert_time_to_str(session.m_created_time))
            info_table[#info_table + 1] = string.format('LastLoginTime:%s\n',
                iam_utils.convert_time_to_str(session.m_last_login_time))
            info_table[#info_table + 1] = string.format('Role:%s\n', session.m_role_id)
        end
    end
    local file = file_utils.open_s(log_file, 'w+')
    if not file then
        log:error('Open iam_dump failed')
        return
    end
    utils_core.chmod_s(log_file, mc_utils.S_IRUSR | mc_utils.S_IWUSR | mc_utils.S_IRGRP)
    file:write(table.concat(info_table))
    file:close()
end

return singleton(Dump)
