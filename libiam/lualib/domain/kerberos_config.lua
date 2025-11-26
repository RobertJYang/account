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
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local mc_utils = require 'mc.utils'
local vos_utils = require 'utils.vos'
local file_utils = require 'utils.file'
local network_core = require 'network.core'
local iam_err = require 'iam.errors'
local utils_core = require 'utils.core'
local iam_utils = require 'infrastructure.iam_utils'
local kmc_client = require 'infrastructure.kmc_client'
local flash_sync = require 'infrastructure.flash_synchronizer'
local base_msg = require 'messages.base'
local user_config = require 'user_config'

local KRB_KEYTABLE_IMPORT_REGEX<const> = '^(/tmp/.{1,246})\\.(keytab)$'
local KRB_ENC_KEYTABLE_PATH<const> = '/data/trust/kerberos.pfx'
local KRB_ENC_KEYTABLE_TEMP_PATH<const> = '/data/trust/tmp_kerberos.pfx'
local MAX_PLAINTEXT_BUF_SIZE<const> = 1024 * 1024
local MAX_CIPHERTEXT_BUF_SIZE<const> = MAX_PLAINTEXT_BUF_SIZE + 1024 -- 密文长度一般比明文多几十字节,增加1k余量
local KRB_KEYTABLE_FIRST_FLAG<const> = 5 -- keytab文件的第一个字节必须为5
local KRB_KEYTABLE_FIRST_FLAG_1<const> = 1 -- 文件的第二个字节必须为1或2
local KRB_KEYTABLE_FIRST_FLAG_2<const> = 2 -- 文件的第二个字节必须为1或2

-- Kerberos配置
local KerberosConfig = class()
function KerberosConfig:ctor(db)
    self.m_config = db:select(db.Kerberos):first()
    self.kmc_client = kmc_client.get_instance()
    self.KRB_KEYTABLE_IMPORT_REGEX = KRB_KEYTABLE_IMPORT_REGEX
    self.KRB_ENC_KEYTABLE_PATH = KRB_ENC_KEYTABLE_PATH
    self.KRB_ENC_KEYTABLE_TEMP_PATH = KRB_ENC_KEYTABLE_TEMP_PATH
end

--- 获取Kerberos使能状态
function KerberosConfig:get_enabled()
    return self.m_config.Enabled
end

--- 设置Kerberos使能状态
---@param enable boolean 
function KerberosConfig:set_enabled(enable)
    self.m_config.Enabled = enable
    self.m_config:save()
end

--- 检查IP地址有效性
---@param address string
local function check_address(address)
    if address == '' then
       return true
    end
    -- 特殊字符校验
    if vos_utils.vos_check_incorrect_char(address, #address, '') == -1 then -- -1代表校验失败
        log:error('check incorrect char failed')
        return false
    end
    -- 检查地址有效性
    if network_core.verify_host_addr(address) == -1 then -- -1代表校验失败
        log:error('verify host address failed')
        return false
    end

    return true
end

--- 获取IP地址
function KerberosConfig:get_address()
    return self.m_config.Address
end

--- 设置IP地址
---@param address string
function KerberosConfig:set_address(address)
    -- 去除头尾空格、tab等
    address = string.match(address, '^[%s]*(.-)[%s]*$')
    if not check_address(address) then
        log:error('verify address failed')
        error(base_msg.PropertyValueFormatError('%Address:' .. address, '%Address'))
    end
    self.m_config.Address = address
    self.m_config:save()
end

--- 获取端口
function KerberosConfig:get_port()
    return self.m_config.Port
end

--- 设置端口
---@param port number
function KerberosConfig:set_port(port)
    -- 端口有效值 1-65535
    if port < 1 or port > 65535 then
        log:error('invalid parameter port: %d', port)
        error(base_msg.PropertyValueNotInList('%Port:' .. port, '%Port'))
    end
    self.m_config.Port = port
    self.m_config:save()
end

--- 检查域名有效性
---@param realm string 
local function check_realm(realm)
    if #realm == 0 and realm == '' then
        return true
    end
    if #realm > 255 then
        log:error('input parameter range error: domain length is %d', #realm)
        return false
    end
    -- 特殊字符校验
    if vos_utils.vos_check_incorrect_char(realm, #realm, '') == -1 then -- -1代表校验失败
        log:error('check incorrect char failed')
        return false
    end
    -- 检查域名中点的个数有效性: 不能在第一个也不能在最后一个，中间也不能有连续的点
    if string.match(realm, '^(%.)') then -- 第一是'.'
        log:error('domain start charater is .')
        return false
    end
    if string.match(realm, '(%.)$') then -- 最后一个一是'.'
        log:error('domain end charater is .')
        return false
    end
    if string.match(realm, '(%.%.)') then -- 中间有2个连续的'..'
        log:error('domain has continuous charater .')
        return false
    end

    return true
end

--- 获取领域
function KerberosConfig:get_realm()
    return self.m_config.Realm
end

--- 设置领域
---@param domain string 
function KerberosConfig:set_realm(realm)
    if not check_realm(realm) then
        log:error('verify domain failed')
        error(base_msg.PropertyValueFormatError('%Realm:' .. realm, '%Realm'))
    end
    self.m_config.Realm = realm
    self.m_config:save()
end

--- 校验keytab文件内容格式
---@param file_data string
local function check_keytab_format(file_data)
    if file_data and #file_data < 2 then
        log:error('The input parameter is incorrect.')
        return false
    end
    -- 文件的第1个字节必须为5
    if string.byte(file_data, 1, 1) ~= KRB_KEYTABLE_FIRST_FLAG then
        log:error('Failed to check the first flag bit.')
        return false
    end
    -- 文件的第2个字节必须为1或2
    if string.byte(file_data, 2, 2) ~= KRB_KEYTABLE_FIRST_FLAG_1 and
        string.byte(file_data, 2, 2) ~= KRB_KEYTABLE_FIRST_FLAG_2 then
        log:error('Failed to check the second flag bit.')
        return false
    end
    
    return true
end

--- 导入秘钥表
---@param path string
function KerberosConfig:import_key_table(path)
    if not iam_utils.check_import_path(path) then
        log:error('file path is illegal!')
        error(iam_err.import_invalid_keytab())
    end

    -- 文件路径检查通过
    local ok, err = pcall(function()
        if not utils_core.g_regex_match(self.KRB_KEYTABLE_IMPORT_REGEX, path) then
            log:error('the file name format is invalid')
            error(iam_err.import_invalid_keytab())
        end

        local file_length = vos_utils.get_file_length(path)
        if file_length < 0 or file_length > MAX_CIPHERTEXT_BUF_SIZE then
            log:error('the file content length out of range')
            error(iam_err.import_invalid_keytab())
        end

        -- 转移到内部路径
        mc_utils.remove_file(user_config.KRB_KEYTABLE_SHM_PATH)
        file_utils.move_file_s(path, user_config.KRB_KEYTABLE_SHM_PATH)
        mc_utils.remove_file(path)
        path = user_config.KRB_KEYTABLE_SHM_PATH

        local keytab_file = file_utils.open_s(path, 'r')
        if not keytab_file then
            log:error('Open keytab file failed.')
            error(iam_err.import_invalid_keytab())
        end
        local keytab_file_content = keytab_file:read('*a')
        keytab_file:close()
        if not check_keytab_format(keytab_file_content) then 
            error(iam_err.import_invalid_keytab())
        end
        local encrypt_keytab_data = self.kmc_client:encrypt_keytab(keytab_file_content)
        -- 当前在iam内部加密,密文先写入tmp文件再move
        flash_sync.write_flash_with_content(self.KRB_ENC_KEYTABLE_PATH,
            self.KRB_ENC_KEYTABLE_TEMP_PATH, encrypt_keytab_data)
            utils_core.chmod_s(self.KRB_ENC_KEYTABLE_PATH, mc_utils.S_IRUSR)
    end)
    mc_utils.remove_file(path) -- 成功失败都删除源文件
    if not ok then
        error(err)
    end
end

return singleton(KerberosConfig)
