-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local Singleton = require 'mc.singleton'
local class = require 'mc.class'
local log = require 'mc.logging'
local task_mgmt = require 'mc.mdb.task_mgmt'
local base_messages = require 'messages.base'
local custom_messages = require 'messages.custom'

local create_code = task_mgmt.create_code
local update_code = task_mgmt.update_code
local task_state = task_mgmt.state
local task_status = task_mgmt.status

-- 任务管理类，管理所有的异步任务，包括任务消息接收，任务状态更新
local task_manager = class()

function task_manager:ctor(bus)
    self.bus = bus
    -- 默认任务不生成时，没有相关的任务id
    self.ssh_import_task_id = nil
    self.decrypt_file_task_id = nil
end

function task_manager:create_ssh_import_task(account_id)
    local name = 'Import File Task'
    local path = string.format('/bmc/kepler/AccountService/Accounts/%d', account_id)
    local timeout = 30 -- 30分钟
    local create_ret, err, task_id = task_mgmt.create_task(self.bus, name, path, timeout)
    if create_ret ~= create_code.TASK_CREATE_SUCCESSFUL then
        log:error('Failed to create a task for ssh import, err: %s', tostring(err))
        error(base_messages.InternalError())
    end
    log:info('create ssh import task success, task_id: %d', task_id)
    self.ssh_import_task_id = task_id
    return task_id
end

function task_manager:create_weakpwddic_import_task()
    local name = 'Import File Task'
    local path = string.format('/bmc/kepler/AccountService')
    local timeout = 30 -- 30分钟
    local create_ret, err, task_id = task_mgmt.create_task(self.bus, name, path, timeout)
    if create_ret ~= create_code.TASK_CREATE_SUCCESSFUL then
        log:error('Failed to create a task for weakpwddictionary import, err: %s', tostring(err))
        error(base_messages.InternalError())
    end
    log:info('create weakpwddictionary import task success, task_id: %d', task_id)
    self.weakpwddict_import_task_id = task_id
    return task_id
end

function task_manager:create_weakpwddic_export_task()
    local name = 'Export File Task'
    local path = string.format('/bmc/kepler/AccountService')
    local timeout = 30 -- 30分钟
    local create_ret, err, task_id = task_mgmt.create_task(self.bus, name, path, timeout)
    if create_ret ~= create_code.TASK_CREATE_SUCCESSFUL then
        log:error('Failed to create a task for weakpwddictionary export, err: %s', tostring(err))
        error(base_messages.InternalError())
    end
    log:info('create weakpwddictionary export task success, task_id: %d', task_id)
    self.weakpwddict_export_task_id = task_id
    return task_id
end

function task_manager:create_process_usb_control_file_task()
    local name = 'Decrypt File Task'
    local path = string.format('/bmc/kepler/Managers/1/USBPorts')
    local timeout = 30 -- 30分钟
    local create_ret, err, task_id = task_mgmt.create_task(self.bus, name, path, timeout)
    if create_ret ~= create_code.TASK_CREATE_SUCCESSFUL then
        log:error('Failed to create a task for decrypt file task, err: %s', tostring(err))
        error(base_messages.InternalError())
    end
    log:info('create decrypt file task successfully, task_id: %d', task_id)
    self.decrypt_file_task_id = task_id
    return task_id
end

function task_manager:_update_task(task_id, is_success, error_msg)
    local data, log_msg
    if is_success then
        data = {Progress = 100, State = task_state.Completed, Status = task_status.OK}
        log_msg = 'Completed'
    elseif error_msg then
        data = {
            Progress = 0,
            State = task_state.Exception,
            Status = task_status.Critical,
            MessageId = custom_messages.FileTransferErrorDescMessage.Name,
            MessageArgs = { error_msg or 'Task failed' }
        }
        log_msg = 'Error'
    else
        data = {Progress = 50, State = task_state.Running, Status = task_status.OK}
        log_msg = 'Running'
    end
    local update = task_mgmt.update_task(task_id, data)
    if update ~= update_code.TASK_UPDATE_SUCCESSFUL then
        log:error('Update task failed, task(%d) is %s', task_id, log_msg)
    end
end

function task_manager:update_ssh_import_task(is_success, error_msg)
    self:_update_task(self.ssh_import_task_id, is_success, error_msg)
end

function task_manager:update_weakpwddic_import_task(is_success, error_msg)
    self:_update_task(self.weakpwddict_import_task_id, is_success, error_msg)
end

function task_manager:update_weakpwddic_export_task(is_success, error_msg)
    self:_update_task(self.weakpwddict_export_task_id, is_success, error_msg)
end

function task_manager:update_process_usb_control_file_task(is_success, error_msg)
    self:_update_task(self.decrypt_file_task_id, is_success, error_msg)
end

return Singleton(task_manager)
