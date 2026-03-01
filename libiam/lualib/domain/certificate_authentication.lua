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
local class = require 'mc.class'
local log = require 'mc.logging'
local custom_msg = require 'messages.custom'
local iam_client = require 'iam.client'
local cert_service_enum = require 'iam.json_types.CertificateService'
local signal = require 'mc.signal'

-- 双因素认证配置
local CertificateAuthentication = class()

function CertificateAuthentication:ctor(db, inter_chassis_validator)
    self.mutual_auth_state_changed = signal.new()
    self.m_db_config = db:select(db.CertificateAuthentication):first()
    self.m_inter_chassis_validator = inter_chassis_validator
end

function CertificateAuthentication:set_certificate_authentication_state(ctx, Enabled)
    if Enabled then
        -- 开启双因素之前判断是否有客户端证书有签发者
        if not self:_check_is_exist_client_cert_has_issuer() then
            log:error("no available user, can't enable mutual authentication.")
            error(custom_msg.FailedEnableTwoFactorCertification())
        end
    end
    self.m_db_config.Enabled = Enabled
    self.m_db_config:save()
    -- 更改ca证书状态
    self:_modify_ca_privilege(Enabled)
    -- 双因素使能变动，踢出所有WEB会话
    self.mutual_auth_state_changed:emit(ctx)
end

function CertificateAuthentication:get_certificate_authentication_state()
    return self.m_db_config.Enabled
end

function CertificateAuthentication:set_ocsp_check_status(ctx, OCSPEnabled)
    self.m_db_config.OCSPEnabled = OCSPEnabled
    self.m_db_config:save()
    -- 在双因素开启后，开启OCSP需要踢出所有WEB会话
    if self.m_db_config.Enabled and OCSPEnabled then
        self.mutual_auth_state_changed:emit(ctx)
    end
end

function CertificateAuthentication:get_ocsp_check_status()
    return self.m_db_config.OCSPEnabled
end

---@function 检查是否有客户端证书有签发者且
---@return boolean
function CertificateAuthentication:_check_is_exist_client_cert_has_issuer()
    for _, obj in pairs(iam_client:GetAccountObjects()) do
        if obj.RootCertUploadedState then
            return true
        end
    end
    return false
end

---@function 更新ca的删除权限
---@param value integer true代表可以删除，false代表不可以删除
function CertificateAuthentication:_modify_ca_privilege(value)
    if not value then
        iam_client:ForeachCAObjects(function(obj)
            obj.Privilege = obj.Privilege | 1
        end
        )
    else
        iam_client:ForeachCAObjects(function(obj)
            obj.Privilege = obj.Privilege & 0xFFFFFFFE
        end
        )
    end
end

local function check_if_ca_certificate_exists()
    local cnt = 0
    for _, obj in pairs(iam_client:GetCertificateObjects()) do
        if obj.CertificateUsageType == cert_service_enum.CertificateUsageType.ManagerCACertificate:value() then
            cnt = cnt + 1
        end
    end
    return (cnt > 0)
end

function CertificateAuthentication:set_inter_chassis_auth_enabled(enabled)
    -- 开启板间通信使能前需要确保有CA证书
    if enabled and not check_if_ca_certificate_exists() then
        log:error("no available ca certificate, can't enable inter-chassis authentication.")
        error(custom_msg.RootCertificateNotImported())
    end
    self.m_db_config.InterChassisAuthEnabled = enabled
    self.m_db_config:save()
end

function CertificateAuthentication:get_inter_chassis_auth_enabled()
    return self.m_db_config.InterChassisAuthEnabled
end

local validation_map = {
    ['None']   = true,
    ['LLDP']   = true,
    ['Static'] = true
}

function CertificateAuthentication:set_inter_chassis_validation(value)
    if not validation_map[value] then
        error(custom_msg.PropertyValueNotInList(value, "InterChassisValidation"))
    end
    self.m_db_config.InterChassisValidation = value
    self.m_db_config:save()
end

function CertificateAuthentication:get_inter_chassis_validation()
    return self.m_db_config.InterChassisValidation
end

local default_ope_type = {
    ['Get'] = {
        ['succ'] = 'SkipLog',
        ['fail'] = 'SkipLog'
    },
    ['Add'] = {
        ['succ'] = 'add_success',
        ['fail'] = 'add_fail'
    },
    ['Remove'] = {
        ['succ'] = 'remove_success',
        ['fail'] = 'remove_fail'
    }
}

function CertificateAuthentication:manage_inter_chassis_whitelist(ctx, operation, type, item)
    ctx.operation_log.params = {type = type}
    if not default_ope_type[operation] then
        log:error("invalid operation(%s)", operation)
        ctx.operation_log.result = 'fail'
        error(custom_msg.PropertyValueNotInList(operation, "Operation"))
    end
    local ok, result = pcall(function()
        if operation == 'Get' then
            return self.m_inter_chassis_validator:get(type)
        elseif operation == 'Add' then
            self.m_inter_chassis_validator:add(type, item)
            return self.m_inter_chassis_validator:get(type)
        elseif operation == 'Remove' then
            self.m_inter_chassis_validator:remove(type, item)
            return self.m_inter_chassis_validator:get(type)
        end
    end)

    if ok then
        ctx.operation_log.result = default_ope_type[operation]['succ']
        return result
    else
        ctx.operation_log.result = default_ope_type[operation]['fail']
        error(result)
    end
end

function CertificateAuthentication:get_ip_access_config()
    local context = ""

    if self.m_db_config.InterChassisValidation == 'LLDP' then
        log:notice("collection inter chassis ip whitelist from LLDP Receives")
        context = context .. "# limit config from LLDP" .. '\n'

        -- 遍历LLDP发现对象收集放行策略
        iam_client:ForeachLLDPReceiveObjects(function(obj)
            if obj.ManagementAddressIPv4 ~= "" then
                context = context .. '+:inter_chassis:' .. obj.ManagementAddressIPv4 .. '\n'
            end
            if obj.ManagementAddressIPv6 ~= "" then
                context = context .. '+:inter_chassis:' .. obj.ManagementAddressIPv6 .. '\n'
            end
        end)

        -- 最后增加限制配置
        context = context .. '-:inter_chassis:ALL' .. '\n'
    elseif self.m_db_config.InterChassisValidation == 'Static' then
        log:notice("collection inter chassis ip whitelist from Static Configure")
        context = context .. "# limit config from Static Configure" .. '\n'

        -- 从静态配置白名单收集放行策略
        for _, item in pairs(self.m_inter_chassis_validator:get("IP")) do
            context = context .. '+:inter_chassis:' .. item .. '\n'
        end

        -- 最后增加限制配置
        context = context .. '-:inter_chassis:ALL' .. '\n'
    end

    return context
end

return singleton(CertificateAuthentication)