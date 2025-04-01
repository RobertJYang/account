-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

local file_utils = require 'utils.file'
local config = require 'chassis_security.config'
local mc_utils = require 'mc.utils'
local log = require 'mc.logging'
local M = {}

local function check_file_size(filepath)
    local file = file_utils.open_s(filepath, 'r')
    if file == nil then
        return false
    end
    local file_size = mc_utils.close(file, pcall(file.seek, file, "end"))
    return file_size
end

function M.notify_boot_ok()
    return true
end

function M.get_bmc_secure_boot_info()
end

function M.import_dice_cert0(cert_data, length)
    return true
end

function M.get_dice_csr()
    local csr_file_path = config.TEMP_DICE_CSR_PATH
    local csr_data = file_utils.read_file_s(csr_file_path, check_file_size(csr_file_path))
    return csr_data
end

local L0 = "L0 mock data"
local L1 = "L1 mock data"

function M.export_dice_cert_n(level)
    print("export dice cert L%d", level)
    if level == 0 then
        return L0
    else
        return L1
    end
end

function M.export_converged_cert_n(level, hash)
    print("export dice cert L%d, hash:%s", level, hash)
    return 'L' .. level .." mock data " .. hash
end

function M.export_nonce_chanllenge(nonce, length)
    print("mock scm3 function export_nonce_chanllenge ")
    return "export_nonce_chanllenge"
end

function M.export_nonce_chanllenge_full(nonce, length)
    print("mock scm3 function export_nonce_chanllenge_full")
    return "export_nonce_chanllenge_full"
end

return M