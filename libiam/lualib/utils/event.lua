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
local log = require 'mc.logging'
local context = require 'mc.context'
local mc_utils = require 'mc.utils'
local json = require 'cjson'
local client = require 'iam.client'
local base_msg = require 'messages.base'

local Event = {}

local function get_event_object()
    if not Event.event_obj then
        client:ForeachEventsObjects(
            function(obj)
                Event.event_obj = obj
            end
        )
    end
    return Event.event_obj
end

Event.event_map = {
    UserLocked = {
        ComponentName = 'BMC',
        State = '',
        EventKeyId = 'BMC.UserLocked',
        MessageArgs = '',
        SystemId = '',
        ManagerId = '1',
        ChassisId = '',
        NodeId = ''
    }
}

--- 产生软件告警
---@param type string 告警类型
---@param record_id number 
---@param state boolean
function Event.add_event(type, state, ...)
    local obj = get_event_object()
    if not obj then
        log:error('get event object fail')
        error(base_msg.InternalError())
    end
    
    local event = mc_utils.table_copy(Event.event_map[type])
    event.State = tostring(state)
    event.MessageArgs = json.encode({ ... })
    local param = {}
    for key, value in pairs(event) do
        param[#param + 1] = { key, value }
    end
    local ok, record_id = obj.pcall:AddEvent(context.new(), param)
    if not ok then
        log:error("Add soft event %s(MessageArgs:%s) failed", event.EventKeyId, ...)
        error(base_msg.PropertyValueNotInList(record_id, 'Record_Id'))
    end
    log:notice('Add Event %s record_id %s', event.Description, record_id)
    return record_id
end

function Event.set_account_lock_alarm(account_id, lock_state)
    local ok, err = pcall(Event.add_event, 'UserLocked', lock_state, account_id)
    if not ok then
        log:error('Account lock trigger failed, err : %s', err)
    end
end

return Event