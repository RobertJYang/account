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
local singleton = require 'mc.singleton'
local crypt = require 'utils.crypt'
local kmc = require 'mc.kmc'
local log = require 'mc.logging'
local class = require 'mc.class'
local user_config = require 'user_config'

-- KmcClient客户端，需要使用KMC加密的业务逻辑可以收口到这里
local KmcClient = class()
function KmcClient:ctor(bus, update_password_after_key_change_function, dry_run)
    if dry_run == true then
        self.key_mgmt_client = {}
        self.m_domain_id = 0
        return
    end
    self.m_key_update_done = true
    -- iam的ksf文件权限与account权限保持一致
    local permission_config = {
        uid = user_config.SECBOX_USER_UID,
        gid = user_config.SECBOX_USER_GID
    }
    local key_mgmt_client = require 'key_mgmt.key_client_lib'
    local client = key_mgmt_client.new(bus, "Login credentials", function()
        -- 在密钥更新后，刷新加密数据，需要记录更新状态
        self.m_key_update_done = false
        local result = update_password_after_key_change_function()
        self.m_key_update_done = true
        return result
    end, user_config.IAM_KSF_FILE_NAME, user_config.IAM_KSF_BACK_NAME, permission_config)
    self.key_mgmt_client = client
    self.m_domain_id = client.m_domain_id
end

-- 用户密码解密
function KmcClient:decrypt_password(encrypt_string)
    local cipher_text = crypt.convert_string_to_ciphertext(encrypt_string)
    local ok, ret = pcall(kmc.decrypt_data, self.m_domain_id, cipher_text)
    if not ok then
        log:error("decrypt failed, %s", tostring(ret))
        -- 无法解密使用key_mgmt的domain重试
        ret = kmc.decrypt_data(1, cipher_text)
    end
    return ret
end

-- 用户密码加密
function KmcClient:encrypt_password(plaintext)
    local ipmipwd_bytes = kmc.encrypt_data(self.m_domain_id, kmc.WsecAlgId.WSEC_ALGID_AES256_GCM,
        kmc.WsecAlgId.WSEC_ALGID_UNKNOWN, plaintext)
    return crypt.convert_ciphertext_to_string(ipmipwd_bytes, #ipmipwd_bytes)
end

-- 加密keytab文件数据
function KmcClient:encrypt_keytab(plaintext)
    local keytab_bytes = kmc.encrypt_data(self.m_domain_id, kmc.WsecAlgId.WSEC_ALGID_AES256_CBC,
        kmc.WsecAlgId.WSEC_ALGID_HMAC_SHA512, plaintext)
    return crypt.convert_ciphertext_to_string(keytab_bytes, #keytab_bytes)
end

-- 密钥更新后重新解密后加密存储的密文 
function KmcClient:get_update_encrypt_password(encrypt_string)
    local ret = self:decrypt_password(encrypt_string)
    ret = self:encrypt_password(ret)
    return ret
end

return singleton(KmcClient)
