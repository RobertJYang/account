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
local class = require 'mc.class'
local kmc_client = require 'infrastructure.kmc_client'
local log = require 'mc.logging'
local vos = require 'utils.vos'
local iam_utils = require 'utils'
local ldap_utils = require 'infrastructure.ldap_utils'
local network_core = require 'network.core'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local iam_enum = require 'class.types.types'

-- LDAP域控制器
local LdapController = class()
function LdapController:ctor(data)
    self.ldap_controller_config = data
    self.kmc_client = kmc_client.get_instance()
end

function LdapController:get_controller()
    return self.ldap_controller_config
end

function LdapController:get_ldap_controller_enabled()
    return self.ldap_controller_config.Enabled
end

function LdapController:set_ldap_controller_enabled(value)
    self.ldap_controller_config.Enabled = value
    self.ldap_controller_config:save()
end

function LdapController:get_ldap_controller_hostaddr()
    return self.ldap_controller_config.HostAddr
end

function LdapController:set_ldap_controller_hostaddr(value)
    if value == '' then
        self.ldap_controller_config.HostAddr = value
        self.ldap_controller_config:save()
        return
    end

    -- 去除头尾空格、tab等
    local addr = string.match(value, '^[%s]*(.-)[%s]*$')
    -- 特殊字符校验
    local ret = vos.vos_check_incorrect_char(addr, #addr, "")
    if ret == -1 then -- -1代表校验失败
        log:error("vos_check_incorrect_char failed")
        error(base_msg.PropertyValueFormatError('%HostAddr:' .. addr, '%HostAddr'))
    end

    -- 检查地址有效性
    ret = network_core.verify_host_addr(addr)
    if ret == -1 then -- -1代表校验失败
        log:error("verify_host_addr failed")
        error(base_msg.PropertyValueFormatError('%HostAddr:' .. addr, '%HostAddr'))
    end

    self.ldap_controller_config.HostAddr = value
    self.ldap_controller_config:save()
end

function LdapController:get_ldap_controller_port()
    return self.ldap_controller_config.Port
end

function LdapController:set_ldap_controller_port(value)
    -- 端口有效值 1-65535
    if value < 1 or value > 65535 then
        log:error("invalid parameter port: %d", value)
        error(base_msg.PropertyValueNotInList('%Port:' .. value, '%Port'))
    end

    self.ldap_controller_config.Port = value
    self.ldap_controller_config:save()
end

function LdapController:get_ldap_controller_domain()
    return self.ldap_controller_config.UserDomain
end

function LdapController:set_ldap_controller_domain(value)
    local ret = ldap_utils:check_domain_name(value)
    if not ret then
        log:error("check_domain_name failed")
        error(base_msg.PropertyValueFormatError('%UserDomain:' .. value, 'UserDomain'))
    end

    self.ldap_controller_config.UserDomain = value
    self.ldap_controller_config:save()
end

function LdapController:get_ldap_controller_folder()
    return self.ldap_controller_config.Folder
end

function LdapController:set_ldap_controller_folder(value)
    -- LDAP用户域文件夹最大字节长度255
    if #value >  255 then
        log:error("Folder length too long")
        error(base_msg.PropertyValueNotInList('%Folder:' .. value, 'Folder'))
    end

    -- 必须是可见字符
    if iam_utils.contain_invisible_charactor(value) then
        error(custom_msg.InvalidValue(value, "Folder"))
    end

    self.ldap_controller_config.Folder = value
    self.ldap_controller_config:save()
end

function LdapController:get_ldap_controller_bind_dn()
    return self.ldap_controller_config.BindDN
end

function LdapController:set_ldap_controller_bind_dn(value)
    -- LDAP代理用户名最大长度255
    if #value >  255 then
        log:error("BindDn length too long")
        error(base_msg.PropertyValueNotInList('%BindDN:' .. value, 'BindDN'))
    end

    self.ldap_controller_config.BindDN = value
    self.ldap_controller_config:save()
end

function LdapController:get_ldap_controller_bind_dn_psw()
    return self.ldap_controller_config.BindDNPsw
end

function LdapController:set_ldap_controller_bind_dn_psw(value)
    -- 密码为空代表清除密码
    if #value == 0 then
        log:info("Set value is empty, now clean BindPassword")
        self.ldap_controller_config.BindDNPsw = value
        self.ldap_controller_config:save()
        return
    end

    -- LDAP代理用户密码长度1~20
    if #value > 20 then
        log:error("BindDNPsw length too long")
        error(custom_msg.PropertyValueExceedsMaxLength('', 'BindPassword', '20'))
    end
    local ret = iam_utils.check_string_is_valid_ascii(value)
    if not ret then
        error(base_msg.PropertyValueFormatError('', 'BindPassword'))
    end
    local encrypt_pwd = self.kmc_client:encrypt_password(value)

    self.ldap_controller_config.BindDNPsw = encrypt_pwd
    self.ldap_controller_config:save()
end

function LdapController:get_ldap_controller_cert_verify_enabled()
    return self.ldap_controller_config.CertVerifyEnabled
end

function LdapController:set_ldap_controller_cert_verify_enabled(value)
    self.ldap_controller_config.CertVerifyEnabled = value
    self.ldap_controller_config:save()
end

function LdapController:get_ldap_controller_cert_verify_level()
    return self.ldap_controller_config.CertVerifyLevel
end

function LdapController:set_ldap_controller_cert_verify_level(ctx, value)
    if value ~= iam_enum.LdapCertVerifyLevel.LDAP_OPT_X_TLS_DEMAND:value() and
        value ~= iam_enum.LdapCertVerifyLevel.LDAP_OPT_X_TLS_ALLOW:value() then
        ctx.operation_log.params.level = 'Unknown'
        log:error("invalid cert_verify_level %d", value)
        error(base_msg.PropertyValueNotInList('%CertVerifyLevel:' .. value, 'CertVerifyLevel'))
    end
    ctx.operation_log.params.level = value == iam_enum.LdapCertVerifyLevel.LDAP_OPT_X_TLS_DEMAND:value() and
        'Demand' or 'Allow'

    self.ldap_controller_config.CertVerifyLevel = value
    self.ldap_controller_config:save()
end

function LdapController:update_ldap_controller_bind_dn_psw()
    local pri_pwd = self.ldap_controller_config.BindDNPsw
    local update_password = self.kmc_client:get_update_encrypt_password(self.ldap_controller_config.BindDNPsw)
    self.ldap_controller_config.BindDNPsw = update_password
    local ok = pcall(self.ldap_controller_config.save, self.ldap_controller_config)
    if not ok then
        log:error("save ldap controller bind dn psw error")
        self.ldap_controller_config.BindDNPsw = pri_pwd
    end
end

return LdapController