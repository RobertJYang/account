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
local base_msg = require 'messages.base'
local config = require 'user_config'
local error_config = require 'error_config'
local context = require 'mc.context'
local log = require 'mc.logging'
local mc_utils = require 'mc.utils'
local class = require 'mc.class'
local Singleton = require 'mc.singleton'
local client = require 'iam.client'
local cjson = require 'cjson'
local utils_core = require 'utils.core'

local function get_file_transfer_obj()
    local objs = client:GetFileTransferObjects()
    for _, v in pairs(objs) do
        return v
    end
    log:error('get file transfer obj fail.')
    error(base_msg.InternalError())
end

local function get_file_transfer_prop(task_id)
    local skynet = require 'skynet'
    local obj
    -- 当前资源上树后第一时间拿代理对象不一定能拿到，maca处理新增信号性能有待改善
    -- FIXME由框架层迭代二实现共享内存解决根源后可考虑删除这段代码
    for _ = 1, 3 do
        client:ForeachTaskObjects(function(o)
            if o.path == '/bmc/kepler/FileTransfer/TaskService/Tasks/' .. task_id then
                obj = o
            end
        end)
        if obj then
            break
        end
        skynet.sleep(100) -- 1s轮询
    end
    if not obj then
        log:error('Call transfer task failed.')
        error(base_msg.InternalError())
    end
    
    return obj
end

-- 默认传至/tmp目录下的文件权限为600
local FILE_PRIVILEGE<const> = mc_utils.S_IRUSR | mc_utils.S_IWUSR

local FileTransfer = class()
function FileTransfer:ctor(bus)
    self.bus = bus
end

--- 调用方法FileTransfer从远程下载文件至/tmp目录下,文件名与远程文件名一致
---@param url string
function FileTransfer:get_file_from_url(ctx, url, is_async)
    local transfer_obj = get_file_transfer_obj()
    local local_file_path = config.TMP_PATH .. '/' .. string.match(url, '[^/\\]+$')
    local file_transfer_ctx = context.new(ctx.Interface, ctx.UserName, ctx.ClientAddr)
    local uid, gid = utils_core.get_uid_gid_by_name(file_transfer_ctx.UserName)
    local task_id = transfer_obj:StartTransfer(file_transfer_ctx, url, 'file://' .. local_file_path,
        config.FILE_LIMITED_SIZE, uid, gid, FILE_PRIVILEGE)
    if is_async then
        return task_id, local_file_path
    end
    self:is_file_transfer_completed(task_id)
    log:info('Download remote file successfully')
    return 0, local_file_path
end

--- 调用方法FileTransfer将/tmp目录下的临时文件上传至目的路径,并将临时文件删除
---@param src_path string
---@param target_path string
function FileTransfer:upload_file_to_url(ctx, src_path, target_path)
    local transfer_obj = get_file_transfer_obj()
    local file_transfer_ctx = context.new(ctx.Interface, ctx.UserName, ctx.ClientAddr)
    local uid, gid = utils_core.get_uid_gid_by_name(file_transfer_ctx.UserName)
    local file_trans_task_id = transfer_obj:StartTransfer(file_transfer_ctx, 'file://' .. src_path, target_path,
        config.FILE_LIMITED_SIZE, uid, gid, FILE_PRIVILEGE)
    log:notice('Task begins, id:%s', file_trans_task_id)
    return file_trans_task_id
end

--- 检查远程文件是否传输完成
---@param task_id string
function FileTransfer:is_file_transfer_completed(task_id)
    local count = 0
    while true do
        local obj = get_file_transfer_prop(task_id)
        local progress = obj.Progress
        local state = obj.State
        local parameters = obj.Parameters
        local error_code = cjson.decode(parameters).ErrorCode
        if progress == 100 then
            if tostring(state) ~= 'Completed' then
                log:error('Transfer remote file failed')
                return false, error_config.FILE_TRANSFER_ERR_STR[error_code] or 'unknown error'
            end
            return true
        end
        local skynet = require 'skynet'
        skynet.sleep(100)
        count = count + 1
        log:info('Transfering remote file, progress is %s', progress)
        if count == 300 then
            log:error('Time is out, transfer remote file failed')
            return false, error_config.FILE_TRANSFER_ERR_STR[error_code] or 'unknown error'
        end
    end
end

return Singleton(FileTransfer)
