-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local def = require 'def'
local crc16 = require 'mc.crc16'
local s_pack = string.pack
local s_unpack = string.unpack
local log = require 'mc.logging'
local lu = require 'luaunit'
local mock_scm3 = {}
setmetatable(mock_scm3, {__close = function()
end})

local function splice_crc16(data)
    return data .. s_pack('H', crc16(data))
end

local EMPYT_HASH<const> = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

local mock_verify_result = {}
-- crc校验错误
mock_verify_result[1] = s_pack('BBBB', 0, 0, 0, 0)

-- 正常返回值，返回结果resp_code为0
local mock_result = s_pack('BBBBH', 0, 0, 0, 0, 0)
mock_verify_result[2] = splice_crc16(mock_result)

-- 正常返回值，返回结果resp_code为0x700B
mock_result = s_pack('BBBBH', 0, 0, 0, 0, 0x700B)
mock_verify_result[3] = splice_crc16(mock_result)

-- 正常返回值，返回结果resp_code为0x700C
mock_result = s_pack('BBBBH', 0, 0, 0, 0, 0x700C)
mock_verify_result[4] = splice_crc16(mock_result)

-- 其他异常返回值
mock_result = s_pack('BBBBH', 0, 0, 0, 0, 0x700D)
mock_verify_result[5] = splice_crc16(mock_result)

-- 其他调用抛出错误
mock_verify_result.__index = function(...)
    error('call index out of range')
end
setmetatable(mock_verify_result, mock_verify_result)

local mock_efuse_type_result = {}
-- 其他数据填充
local mock_other_data = string.rep('c', 608)

-- crc校验错误
mock_efuse_type_result[1] = s_pack('BBBBHI4', 0, 0, 0, 0, 0, 0) .. mock_other_data

-- 正常返回值resp_code:0,partner_mode_en:0 - 不支持伙伴模式
mock_result = s_pack('BBBBHI4', 0, 0, 0, 0, 0, 0) .. mock_other_data
mock_efuse_type_result[2] = splice_crc16(mock_result)

-- 正常返回值resp_code:0,partner_mode_en:1 - 支持伙伴模式
mock_result = s_pack('BBBBHI4', 0, 0, 0, 0, 0, 1) .. mock_other_data
mock_efuse_type_result[3] = splice_crc16(mock_result)

-- 异常情况:resp_code其他返回值
mock_result = s_pack('BBBBHI4', 0, 0, 0, 0, 1, 1) .. mock_other_data
mock_efuse_type_result[4] = splice_crc16(mock_result)

-- 其他调用抛出错误
mock_efuse_type_result.__index = function(...)
    error('call index out of range')
end
setmetatable(mock_efuse_type_result, mock_efuse_type_result)

local mock_efuse_state_result = {}
-- crc校验错误
mock_efuse_state_result[1] = s_pack('BBBBHHHH', 0, 0, 0, 0, 0, 0, 0, 0)

-- 正常返回值resp_code:0, boot_mode:0 - 非安全启动，无efuse
mock_result = s_pack('BBBBHHHH', 0, 0, 0, 0, 0, 0, 0, 0)
mock_efuse_state_result[2] = splice_crc16(mock_result)

-- 正常返回值resp_code:0, boot_mode:非0 - 安全启动，有efuse
mock_result = s_pack('BBBBHHHH', 0, 0, 0, 0, 0, 1, 0, 0)
mock_efuse_state_result[3] = splice_crc16(mock_result)

-- 异常情况:resp_code其他返回值
mock_result = s_pack('BBBBHHHH', 0, 0, 0, 0, 1, 1, 0, 0)
mock_efuse_state_result[4] = splice_crc16(mock_result)

-- 其他调用抛出错误
mock_efuse_state_result.__index = function(...)
    error('call index out of range')
end
setmetatable(mock_efuse_state_result, mock_efuse_state_result)

local result = {
    [def.CMD_2_FW_MSG_PARTNER_VERIFY_H2P_CERT] = mock_verify_result,
    [def.CMD_2_EXPORT_PARTNER_INFO] = mock_efuse_type_result,
    [def.CMD_2_GET_BMC_SECUREBOOT_INFO] = mock_efuse_state_result
}

local count = {
    [def.CMD_2_FW_MSG_PARTNER_VERIFY_H2P_CERT] = 0,
    [def.CMD_2_EXPORT_PARTNER_INFO] = 0,
    [def.CMD_2_GET_BMC_SECUREBOOT_INFO] = 0
}


function mock_scm3:new()
    return mock_scm3
end

function mock_scm3:close()
end

function mock_scm3:sendrecv(req_data, resp_len)
    -- 取第二个命令字
    local cmd_2 = s_unpack('B', req_data, 2)
    count[cmd_2] = count[cmd_2] + 1
    return result[cmd_2][count[cmd_2]]
end

function mock_scm3:start_bios_verify(bios_type)
    lu.assertEquals(bios_type, 1)
end

function mock_scm3:get_bios_verify_result()
    return 0
end

function mock_scm3:set_spi_mux_channel(channel)
    self.bios_channel = channel
end

function mock_scm3:get_spi_mux_channel()
    return self.bios_channel or 0
end

function mock_scm3:efuse_pwr_set(...)
    return def.RET_OK
end

function mock_scm3:export_custom_cert_hash(sign_mode)
    if sign_mode == 0 then
        return self.hash_pkcs and self.hash_pkcs or string.char(table.unpack(EMPYT_HASH))
    elseif sign_mode == 1 then
        return self.hash_pss and self.hash_pss or string.char(table.unpack(EMPYT_HASH))
    end
end

function mock_scm3:import_custom_cert_hash(certificate)
    self.hash_pkcs = certificate
    self.hash_pss = certificate
    return def.RET_OK
end

function mock_scm3:export_repair_info(...)
    local repair = {212, 41, 3, 39, 20, 207, 229, 4, 212, 10, 210, 78, 10, 85, 124, 64, 67, 144, 14, 0, 0, 0, 0, 0}
    return string.char(table.unpack(repair))
end

function mock_scm3:import_repair_cert(repair_credential)
    -- 此处实际m3比较慢，延时100ms
    local skynet = require 'skynet'
    skynet.sleep(10)
    self.repair_sign = repair_credential
end

return mock_scm3