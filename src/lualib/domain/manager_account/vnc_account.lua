-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local vos_utils = require 'utils.vos'
local err = require 'account.errors'
local manager_account = require 'domain.manager_account.manager_account'

local VNCAccount = class(manager_account)

function VNCAccount:update_password_valid_start_time()
    local cur_timestamp = vos_utils.vos_get_cur_time_stamp()
    self:set_password_valid_start_time(cur_timestamp)
end

function VNCAccount:password_validator(ctx, _, password, _, _)
    ctx.operation_log.operation = 'ChangeVNCPwd'
    -- vnc密码长度为1到8
    if #password > 8 or #password < 1 then
        error(err.invalid_password_length())
    end

    local info = {
        ["password"] = password
    }
    self.password_validator_obj:validate(info)
end

function VNCAccount:set_account_password(password, _)
    self.m_account_data.IpmiPassword = self.kmc_client:encrypt_password(password)
    self.m_account_data:save()
    self:update_password_valid_start_time()
end

function VNCAccount:get_vnc_pwd_plaintext()
    return self.kmc_client:decrypt_password(self.m_account_data.IpmiPassword)
end

function VNCAccount:update_privileges()
    return
end

--vnc内部账户无设置，使用默认值
function VNCAccount:get_password_change_required()
    return false
end

function VNCAccount:set_user_ku(_, _)
end

--- 检查用户登录规则
---@param ip string
function VNCAccount:check_login_rule(ip)
    local login_rule_ids = self:get_login_rule_ids()
    return self.m_login_rule_collection:check_login_rule(login_rule_ids, ip)
end

--- IPMI命令可清空VNC密码(装备场景)
function VNCAccount:clear_vnc_password()
    self.m_account_data.IpmiPassword = ''
    self.m_account_data:save()
end

--- 测试密码
---@param pwd string
function VNCAccount:test_password_operation(password)
    if self.m_account_data.IpmiPassword == '' then
        return string.byte(password) == 0x00
    end
    local pwd = self.kmc_client:decrypt_password(self.m_account_data.IpmiPassword)
    return pwd == password
end

return VNCAccount