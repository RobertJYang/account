-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

local base_msg = require 'messages.base'
local class = require 'mc.class'
local file_utils = require 'utils.file'
local file_proxy = require 'infrastructure.file_proxy'
local log = require 'mc.logging'
local mc_utils = require 'mc.utils'
local singleton = require 'mc.singleton'

local Dump = class()

function Dump:ctor()

end

function Dump:log_dump(ctx, path)
    if file_utils.check_real_path_s(path) ~= 0 then
        log:error('Dump path is invalid')
        error(base_msg.InternalError())
    end
    local log_file = path ..'/account_info.txt'
    local info_table = {}
    info_table[#info_table + 1] = string.format('account information:\n')
    local file = file_utils.open_s(log_file, 'w+')
    if not file then
        log:error('Open account_dump failed')
        return
    end
    file_proxy.proxy_chmod(log_file, mc_utils.S_IRUSR | mc_utils.S_IWUSR | mc_utils.S_IRGRP)
    file:write(table.concat(info_table))
    file:close()
end

return singleton(Dump)
