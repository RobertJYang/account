-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local custom_msg = require 'messages.custom'
local ipmi_types = require 'ipmi.types'
local ipmi_cmds = require 'account.ipmi.ipmi'
local enum = require 'class.types.types'
local utils = require 'infrastructure.utils'

local PasswordValidatorIpmi = class()

function PasswordValidatorIpmi:ctor(password_validator_collection)
    self.m_validator_collection = password_validator_collection
end

function PasswordValidatorIpmi:init()
end

local ipmi_account_type_enum = {
    [0x00] = enum.AccountType.Local,
    [0x01] = enum.AccountType.SnmpCommunity,
    [0x02] = enum.AccountType.VNC
}

local account_type_name = {
    [0x00] =  'LocalAccount',
    [0x01] =  'VNC',
    [0x02] =  'SnmpCommunity'
}

local function check_parameters(ctx, account_type, data, data_len, is_set_policy)
    if not ipmi_account_type_enum[account_type] then
        if ctx.operation_log then
            ctx.operation_log.result = 'invalid_account_type'
        end
        log:error("invalid account type")
        error(custom_msg.IPMIInvalidFieldRequest())
    end

    if ctx.operation_log then
        ctx.operation_log.params.account_type = account_type_name[account_type]
    end

    if data and data_len then
        if is_set_policy and data_len ~= 1 then
            log:error("Data input length error")
            error(custom_msg.IPMIInvalidFieldRequest())
        end
        if #data ~= data_len then
            log:error("Data input length error")
            error(custom_msg.IPMIInvalidFieldRequest())
        end
    end
end

function PasswordValidatorIpmi:set_policy(req, ctx)
    ctx.operation_log.params.account_type = ""

    local account_type = req.AccountType
    local data_len     = req.Length
    local data         = string.byte(req.Data)
    check_parameters(ctx, account_type, req.Data, data_len, true)

    self.m_validator_collection:set_policy(ctx, ipmi_account_type_enum[account_type]:value(), data)
    self.m_validator_collection.m_config_changed:emit(ipmi_account_type_enum[account_type]:value(), 'Policy', data)

    local rsp = ipmi_cmds.SetPasswordRulePolicy.rsp.new()
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.ManufactureId = utils.get_manufacture_id()
    return rsp
end

function PasswordValidatorIpmi:get_policy(req, ctx)
    local account_type = req.AccountType
    check_parameters(ctx, account_type, nil, nil, false)

    local policy = self.m_validator_collection:get_policy(ipmi_account_type_enum[account_type]:value())
    local ret_val = string.char(policy)
    local rsp = ipmi_cmds.GetPasswordRulePolicy.rsp.new()
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.Length = #ret_val
    rsp.Data = ret_val
    return rsp
end

function PasswordValidatorIpmi:set_pattern(req, ctx)
    ctx.operation_log.params.account_type = ""

    local account_type = req.AccountType
    local data_len     = req.Length
    local data         = req.Data
    check_parameters(ctx, account_type, data, data_len, false)

    self.m_validator_collection:set_pattern(ctx, ipmi_account_type_enum[account_type]:value(), data)
    self.m_validator_collection.m_config_changed:emit(ipmi_account_type_enum[account_type]:value(), 'Pattern', data)

    local rsp = ipmi_cmds.SetPasswordPattern.rsp.new()
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.ManufactureId = utils.get_manufacture_id()
    return rsp
end

function PasswordValidatorIpmi:get_pattern(req, ctx)
    local account_type = req.AccountType
    check_parameters(ctx, account_type, nil, nil, false)

    local pattern = self.m_validator_collection:get_pattern(ipmi_account_type_enum[account_type]:value())
    local rsp = ipmi_cmds.GetPasswordPattern.rsp.new()
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.ManufactureId = utils.get_manufacture_id()
    rsp.Length = #pattern
    rsp.Data = pattern
    return rsp
end

return singleton(PasswordValidatorIpmi)
