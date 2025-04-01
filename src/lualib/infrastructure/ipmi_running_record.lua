-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

local Singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local skynet_ready, skynet = pcall(require, 'skynet')
local enum = require 'class.types.types'
local err_cfg = require 'error_config'

-- 为适配ipmi带内执行逻辑，同功能在超过门禁执行两次，此类用于记录第一次执行结果，
-- 并且在第二次返回
local ipmi_running_record = class()
function ipmi_running_record:ctor()
    self.record = {
        ["set_account_name"] = {
            last_result = nil,
            last_retcode_or_err = nil,
            present_process = enum.Progress.COMPLETED
        },
        ["set_password"] = {
            last_result = nil,
            last_retcode_or_err = nil,
            present_process = enum.Progress.COMPLETED
        },
        ["set_access"] = {
            last_result = nil,
            last_retcode_or_err = nil,
            present_process = enum.Progress.COMPLETED
        }
    }
end

function ipmi_running_record:set_record(function_name, result, ret_or_err, process)
    if not self.record[function_name] then
        log:error("no such function_name,%s", function_name)
        return
    end
    self.record[function_name] = {
        last_result = result,
        last_retcode_or_err = ret_or_err,
        present_process = process
    }
end

function ipmi_running_record:check_if_ipmi_run_twice(function_name, ctx)
    if not self.record[function_name] then
        log:error("no such function_name,%s", function_name)
        return false
    end
    if self.record[function_name].present_process == enum.Progress.COMPLETED then
        return false
    end
    while self.record[function_name].present_process == enum.Progress.RUNNING do
        if skynet_ready then
            skynet.sleep(10)
        end
    end
    ctx.operation_log.operation = 'SkipLog'
    if not self.record[function_name].last_result then
        error(self.record[function_name].last_retcode_or_err)
    end
    return true
end

local function is_os_cmd(ctx)
    if not ctx.session then
        return true
    else
        return false
    end
end

function ipmi_running_record:proxy(req, rsp, ctx, function_name, func)
    rsp.CompletionCode = err_cfg.USER_OPER_SUCCESS
    if is_os_cmd(ctx) then
        if self:check_if_ipmi_run_twice(function_name, ctx) then
            rsp.CompletionCode = self:get_last_retcode_or_err(function_name)
            return rsp
        end
        self:set_process(function_name, enum.Progress.RUNNING)
    end
    local ret, ret_or_err = pcall(function()
        return func(req, ctx)
    end)
    if is_os_cmd(ctx) then
        self:set_record(function_name,
            ret, ret_or_err, enum.Progress.COMPLETED)
    end
    if not ret then
        error(ret_or_err)
    end
    rsp.CompletionCode = ret_or_err
    return rsp
end

function ipmi_running_record:set_process(function_name, process)
    self.record[function_name].present_process = process
end

function ipmi_running_record:get_last_result(function_name)
    return self.record[function_name].last_result
end

function ipmi_running_record:get_last_retcode_or_err(function_name)
    return self.record[function_name].last_retcode_or_err
end

function ipmi_running_record:set_last_retcode_or_err(function_name, last_retcode_or_err)
    self.record[function_name].last_retcode_or_err = last_retcode_or_err
end

return Singleton(ipmi_running_record)
