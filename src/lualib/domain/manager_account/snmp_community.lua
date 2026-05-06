-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local log = require 'mc.logging'
local custom_msg = require 'messages.custom'
local manager_account = require 'domain.manager_account.manager_account'

local SnmpCommunity = class(manager_account)

function SnmpCommunity:password_validator(ctx, _, password, _, _)
    -- 删除团体名场景,不需继续检查有效性
    if #password == 0 then
        ctx.operation_log.result = 'delete_success'
        return
    end

    if string.find(password, " ") then
        local error_param = self:get_id() == 20 and 'ReadOnlyCommunity' or 'ReadWriteCommunity'
        error(custom_msg.CommunityNameNotContainSpace(error_param))
    end

    -- 校验用户密码是否属于弱口令
    if self.m_account_config:get_weak_pwd_dictionary_enable() then
        self.m_account_config:check_password_in_weak_passwd_dictionary(ctx, password, 'snmp_community')
    end

    local info = {
        ["password"]         = password,
        ["current_password"] = self:get_account_password(),
        ["is_ro_community"]  = (self:get_id() == 20)
    }
    self.password_validator_obj:validate(info)
end

function SnmpCommunity:set_account_password(password, _)
    if #password == 0 then
        self.m_account_data.Password, self.m_account_data.KDFPassword = "", ""
        self.m_account_data.IpmiPassword = ""
        self.m_history_password:delete()
    else
        self.m_account_data.Password, self.m_account_data.KDFPassword =
            self:crypt_password_by_random_salt(password)
        self.m_account_data.IpmiPassword = self.kmc_client:encrypt_password(password)
        self.m_history_password:insert(self.m_account_data.Password, self.m_account_data.KDFPassword,
            self.m_account_config:get_history_password_count())
    end
    self.m_account_data:save()
    self:update_privileges()
end

--community内部账户无设置，使用默认值
function SnmpCommunity:get_password_change_required()
    return false
end

function SnmpCommunity:get_account_password()
    if self.m_account_data.IpmiPassword == '' then
        return ''
    end
    local ok, ret = pcall(function()
        return self.kmc_client:decrypt_password(self.m_account_data.IpmiPassword)
    end)
    if not ok then
        ret = ''
        self.m_account_data.IpmiPassword = ''
        self.m_account_data:save()
        log:error("snmp password decrypt failed")
    end
    return ret;
end

function SnmpCommunity:set_user_ku(_, _)
end

--- 检查用户登录规则
---@param ip string
function SnmpCommunity:check_login_rule(ip)
    local login_rule_ids = self:get_login_rule_ids()
    return self.m_login_rule_collection:check_login_rule(login_rule_ids, ip)
end

return SnmpCommunity
