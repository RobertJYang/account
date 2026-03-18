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
local certificate_authentication = require 'domain.certificate_authentication'
local certificate_authentication_ipmi = require 'interface.ipmi.certificate_authentication_ipmi'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local base_msg = require 'messages.base'
local class = require 'mc.class'
local context = require 'mc.context'
local operation_logger = require 'interface.operation_logger'

local cls_mng = require 'mc.class_mgnt'
local INTERFACE_CERT_AUTH<const> = 'bmc.kepler.AccountService.CertificateAuthentication'
local PATH_CERT_AUTH<const> = '/bmc/kepler/AccountService/CertificateAuthentication'

local CertificateAuthenticationMdb = class()

function CertificateAuthenticationMdb:ctor(bus)
    self.m_cert_auth = certificate_authentication.get_instance()
    self.m_cert_auth_ipmi = certificate_authentication_ipmi.get_instance()
    self.m_bus = bus
    self.m_mdb_config = {}
end


function CertificateAuthenticationMdb:init()
    self.m_cert_auth_ipmi.m_update_config:on(function(...)
        self:cert_config_mdb_update(...)
    end)
    self:new_cert_config_to_mdb_tree(self.m_cert_auth.m_db_config)
    self:update_ca_deletable_status(self.m_mdb_config)
end

function CertificateAuthenticationMdb:update_ca_deletable_status(config)
    local skynet = require 'skynet'
    skynet.fork_once(function()
        -- 等待5秒后更新CA证书是否可删除状态
        skynet.sleep(500)
        self.m_cert_auth:_modify_ca_privilege(config[INTERFACE_CERT_AUTH].Enabled)

        -- 防止certificate组件资源树未完成上树导致设置CA证书是否可删除状态失败，20秒后再次进行设置
        skynet.sleep(2000)
        self.m_cert_auth:_modify_ca_privilege(config[INTERFACE_CERT_AUTH].Enabled)
    end)
end

CertificateAuthenticationMdb.watch_config_property_hook = {
    Enabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_cert_auth:set_certificate_authentication_state(ctx, value)
    end, 'TwoFactorEnabled'),
    OCSPEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_cert_auth:set_ocsp_check_status(ctx, value)
    end, "TwoFactorOCSPEnabled"),
    InterChassisAuthEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { state = value and 'Enable' or 'Disable' }
        self.m_cert_auth:set_inter_chassis_auth_enabled(value)
    end, "InterChassisAuthEnabled"),
    InterChassisValidation = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { value = value }
        self.m_cert_auth:set_inter_chassis_validation(value)
    end, "InterChassisValidation"),
}

function CertificateAuthenticationMdb:watch_config_property(service)
    service[INTERFACE_CERT_AUTH].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the certificate authentication config property(%s) to value(%s), sender is nil',
                name, tostring(value))
            return true
        end

        if not self.watch_config_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('change the certificate authentication config property(%s) to value(%s)', name, tostring(value))
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_config_property_hook[name](self, ctx, value)
        return true
    end)
end

function CertificateAuthenticationMdb:new_cert_config_to_mdb_tree(config_mdb)
    local mdb_config = cls_mng('CertificateAuthentication'):get(PATH_CERT_AUTH)
    mdb_config[INTERFACE_CERT_AUTH].Enabled = config_mdb.Enabled
    mdb_config[INTERFACE_CERT_AUTH].OCSPEnabled = config_mdb.OCSPEnabled
    mdb_config[INTERFACE_CERT_AUTH].InterChassisAuthEnabled = config_mdb.InterChassisAuthEnabled
    mdb_config[INTERFACE_CERT_AUTH].InterChassisValidation = config_mdb.InterChassisValidation
    self:watch_config_property(mdb_config)
    self.m_mdb_config = mdb_config
end

function CertificateAuthenticationMdb:cert_config_mdb_update(property, value)
    if self.m_mdb_config[INTERFACE_CERT_AUTH][property] == nil then
        return
    end
    self.m_mdb_config[INTERFACE_CERT_AUTH][property] = value
end

return singleton(CertificateAuthenticationMdb)