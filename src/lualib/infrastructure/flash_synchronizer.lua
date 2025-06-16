-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local log = require 'mc.logging'
local mc_utils = require 'mc.utils'
local file_utils = require 'utils.file'
local base_msg = require 'messages.base'

local flash_synchronizer = {}

--- 写flash操作
function flash_synchronizer.write_flash(flash_path, tmp_flash_path)
    -- 打开tmp文件，待导入文件必须存在
    local tmp_file = file_utils.open_s(tmp_flash_path, 'r')
    if not tmp_file then
        log:error('Writing file failed, open tmp file error')
        error(base_msg.InternalError())
    end
    local tmp_data = tmp_file:read('*a')
    tmp_file:close()
    -- 打开flash文件，文件可能不存在
    local file = file_utils.open_s(flash_path, 'r')
    local data = nil
    if file then
        data = file:read('*a')
        file:close()
    end
    -- 校验内容不一致则拷贝替换，否则删除tmp文件
    if not data or data ~= tmp_data then
        local ret = file_utils.move_file_s(tmp_flash_path, flash_path)
        if ret ~= 0 then
            error(base_msg.InternalError())
        end
    else
        mc_utils.remove_file(tmp_flash_path)
    end
end

--- 需要先写内存文件场景
function flash_synchronizer.write_flash_with_content(flash_path, tmp_flash_path, content)
    local file_tmp = file_utils.open_s(tmp_flash_path, 'w+')
    if not file_tmp then
        -- 避免暴露文件全路径敏感信息
        log:error('failed to write %s', file_utils.get_file_name_s(flash_path))
        error(base_msg.InternalError())
    end
    file_tmp:write(content)
    file_tmp:close()
    flash_synchronizer.write_flash(flash_path, tmp_flash_path)
end

return flash_synchronizer