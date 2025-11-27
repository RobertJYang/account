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
local singleton = require 'mc.singleton'
local certificate_authentication = require 'domain.certificate_authentication'
local signal = require 'mc.signal'
local class = require 'mc.class'
local iam_enum = require 'class.types.types'
local iam_err = require 'iam.errors'
local log = require 'mc.logging'
local ipmi_cmds = require 'iam.ipmi.ipmi'
local ipmi_types = require 'ipmi.types'

local CertificateAuthenticationIpmi = class()

function CertificateAuthenticationIpmi:ctor()
    self.m_certificate_authentication = certificate_authentication.get_instance()
    self.m_update_config = signal.new()
end

local cert_auth_state = {
    [iam_enum.IpmiSetTwoFactorState.Enable:value()] = true,
    [iam_enum.IpmiSetTwoFactorState.Disable:value()] = false
}

local function set_two_factor_input_check(Enabled, OCSPEnabled)
    if cert_auth_state[Enabled] == nil or cert_auth_state[OCSPEnabled] == nil  then
        log:error('Set Two Factor State failed, parameter Enabled or OCSPEnabled is unsupport')
        return false
    end
    return true
end

--- ipmi设置双因素证书状态
---@param req any
---@param ctx any
function CertificateAuthenticationIpmi:set_two_factor_auth_state(req, ctx)
    local rsp = ipmi_cmds.SetTwoFactorAuthState.rsp.new()
    local Enabled = req.Enabled
    local OCSPEnabled = req.OCSPEnabled
    local ret = set_two_factor_input_check(Enabled, OCSPEnabled)
    if not ret then
        error(iam_err:unsupport_two_factor_param())
    end
    -- TODO支持双因素后需检查是否有用户配置证书
    ctx.operation_log.params.state = cert_auth_state[Enabled] and 'Enable' or 'Disable'
    ctx.operation_log.params.state_ocsp = cert_auth_state[OCSPEnabled] and 'Enable' or 'Disable'
    if self.m_certificate_authentication:get_certificate_authentication_state() ~= cert_auth_state[Enabled] then
        self.m_certificate_authentication:set_certificate_authentication_state(ctx, cert_auth_state[Enabled])
        self.m_update_config:emit('Enabled', cert_auth_state[Enabled])
    end

    if self.m_certificate_authentication:get_ocsp_check_status() ~= cert_auth_state[OCSPEnabled] then
        local ok, err = pcall(function()
            self.m_certificate_authentication:set_ocsp_check_status(ctx, cert_auth_state[OCSPEnabled])
        end)
        if not ok then
            ctx.operation_log.result = 'fail_ocsp'
            error(err)
        end
        self.m_update_config:emit('OCSPEnabled', cert_auth_state[OCSPEnabled])
    end

    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    return rsp
end

function CertificateAuthenticationIpmi:get_two_factor_auth_state(req, ctx)
    local rsp = ipmi_cmds.GetTwoFactorAuthState.rsp.new()
    local enabled = self.m_certificate_authentication.m_db_config.Enabled and
    iam_enum.IpmiSetTwoFactorState.Enable:value() or iam_enum.IpmiSetTwoFactorState.Disable:value()
    local ocsp_enabled = self.m_certificate_authentication.m_db_config.OCSPEnabled and
    iam_enum.IpmiSetTwoFactorState.Enable:value() or iam_enum.IpmiSetTwoFactorState.Disable:value()

    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.Enabled = enabled
    rsp.OCSPEnabled = ocsp_enabled
    return rsp
end

return singleton(CertificateAuthenticationIpmi)