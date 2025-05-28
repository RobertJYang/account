-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local validate = require 'mc.validate'
local utils = require 'mc.utils'
local mdb = require 'mc.mdb'

local Task = {}

---@class Task.MessageArgs
---@field MessageArgs string[]
local TMessageArgs = {}
TMessageArgs.__index = TMessageArgs
TMessageArgs.group = {}

local function TMessageArgs_from_obj(obj)
    return setmetatable(obj, TMessageArgs)
end

function TMessageArgs.new(MessageArgs)
    return TMessageArgs_from_obj({MessageArgs = MessageArgs})
end
---@param obj Task.MessageArgs
function TMessageArgs:init_from_obj(obj)
    self.MessageArgs = obj.MessageArgs
end

function TMessageArgs:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMessageArgs.group)
end

TMessageArgs.from_obj = TMessageArgs_from_obj

TMessageArgs.proto_property = {'MessageArgs'}

TMessageArgs.default = {{}}

TMessageArgs.struct = {{name = 'MessageArgs', is_array = true, struct = nil}}

function TMessageArgs:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.OptionalArray(prefix .. 'MessageArgs', self.MessageArgs, 'string', true, errs, need_convert)

    TMessageArgs:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMessageArgs.proto_property, errs, need_convert)
    return self
end

function TMessageArgs:unpack(_)
    return self.MessageArgs
end

Task.MessageArgs = TMessageArgs

---@class Task.MessageId
---@field MessageId string
local TMessageId = {}
TMessageId.__index = TMessageId
TMessageId.group = {}

local function TMessageId_from_obj(obj)
    return setmetatable(obj, TMessageId)
end

function TMessageId.new(MessageId)
    return TMessageId_from_obj({MessageId = MessageId})
end
---@param obj Task.MessageId
function TMessageId:init_from_obj(obj)
    self.MessageId = obj.MessageId
end

function TMessageId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMessageId.group)
end

TMessageId.from_obj = TMessageId_from_obj

TMessageId.proto_property = {'MessageId'}

TMessageId.default = {''}

TMessageId.struct = {{name = 'MessageId', is_array = false, struct = nil}}

function TMessageId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'MessageId', self.MessageId, 'string', true, errs, need_convert)

    TMessageId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMessageId.proto_property, errs, need_convert)
    return self
end

function TMessageId:unpack(_)
    return self.MessageId
end

Task.MessageId = TMessageId

---@class Task.Parameters
---@field Parameters string
local TParameters = {}
TParameters.__index = TParameters
TParameters.group = {}

local function TParameters_from_obj(obj)
    return setmetatable(obj, TParameters)
end

function TParameters.new(Parameters)
    return TParameters_from_obj({Parameters = Parameters})
end
---@param obj Task.Parameters
function TParameters:init_from_obj(obj)
    self.Parameters = obj.Parameters
end

function TParameters:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TParameters.group)
end

TParameters.from_obj = TParameters_from_obj

TParameters.proto_property = {'Parameters'}

TParameters.default = {''}

TParameters.struct = {{name = 'Parameters', is_array = false, struct = nil}}

function TParameters:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Parameters', self.Parameters, 'string', true, errs, need_convert)

    TParameters:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TParameters.proto_property, errs, need_convert)
    return self
end

function TParameters:unpack(_)
    return self.Parameters
end

Task.Parameters = TParameters

---@class Task.Status
---@field Status string
local TStatus = {}
TStatus.__index = TStatus
TStatus.group = {}

local function TStatus_from_obj(obj)
    return setmetatable(obj, TStatus)
end

function TStatus.new(Status)
    return TStatus_from_obj({Status = Status})
end
---@param obj Task.Status
function TStatus:init_from_obj(obj)
    self.Status = obj.Status
end

function TStatus:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TStatus.group)
end

TStatus.from_obj = TStatus_from_obj

TStatus.proto_property = {'Status'}

TStatus.default = {''}

TStatus.struct = {{name = 'Status', is_array = false, struct = nil}}

function TStatus:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Status', self.Status, 'string', true, errs, need_convert)

    if self.Status ~= nil then
        validate.Enum(prefix .. 'Status', self.Status, '', {'OK', 'Warning', 'Major', 'Critical'}, errs, need_convert)
    end

    TStatus:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TStatus.proto_property, errs, need_convert)
    return self
end

function TStatus:unpack(_)
    return self.Status
end

Task.Status = TStatus

---@class Task.State
---@field State string
local TState = {}
TState.__index = TState
TState.group = {}

local function TState_from_obj(obj)
    return setmetatable(obj, TState)
end

function TState.new(State)
    return TState_from_obj({State = State})
end
---@param obj Task.State
function TState:init_from_obj(obj)
    self.State = obj.State
end

function TState:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TState.group)
end

TState.from_obj = TState_from_obj

TState.proto_property = {'State'}

TState.default = {''}

TState.struct = {{name = 'State', is_array = false, struct = nil}}

function TState:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'State', self.State, 'string', true, errs, need_convert)

    if self.State ~= nil then
        validate.Enum(prefix .. 'State', self.State, '', {
            'New', 'Starting', 'Running', 'Suspended', 'Interrupted', 'Pending', 'Stopping', 'Completed', 'Killed',
            'Exception', 'Service', 'Cancelled'
        }, errs, need_convert)
    end

    TState:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TState.proto_property, errs, need_convert)
    return self
end

function TState:unpack(_)
    return self.State
end

Task.State = TState

---@class Task.Progress
---@field Progress integer
local TProgress = {}
TProgress.__index = TProgress
TProgress.group = {}

local function TProgress_from_obj(obj)
    return setmetatable(obj, TProgress)
end

function TProgress.new(Progress)
    return TProgress_from_obj({Progress = Progress})
end
---@param obj Task.Progress
function TProgress:init_from_obj(obj)
    self.Progress = obj.Progress
end

function TProgress:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TProgress.group)
end

TProgress.from_obj = TProgress_from_obj

TProgress.proto_property = {'Progress'}

TProgress.default = {0}

TProgress.struct = {{name = 'Progress', is_array = false, struct = nil}}

function TProgress:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Progress', self.Progress, 'uint32', true, errs, need_convert)

    TProgress:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TProgress.proto_property, errs, need_convert)
    return self
end

function TProgress:unpack(_)
    return self.Progress
end

Task.Progress = TProgress

---@class Task.EndTime
---@field EndTime string
local TEndTime = {}
TEndTime.__index = TEndTime
TEndTime.group = {}

local function TEndTime_from_obj(obj)
    return setmetatable(obj, TEndTime)
end

function TEndTime.new(EndTime)
    return TEndTime_from_obj({EndTime = EndTime})
end
---@param obj Task.EndTime
function TEndTime:init_from_obj(obj)
    self.EndTime = obj.EndTime
end

function TEndTime:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TEndTime.group)
end

TEndTime.from_obj = TEndTime_from_obj

TEndTime.proto_property = {'EndTime'}

TEndTime.default = {''}

TEndTime.struct = {{name = 'EndTime', is_array = false, struct = nil}}

function TEndTime:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EndTime', self.EndTime, 'string', true, errs, need_convert)

    TEndTime:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TEndTime.proto_property, errs, need_convert)
    return self
end

function TEndTime:unpack(_)
    return self.EndTime
end

Task.EndTime = TEndTime

---@class Task.StartTime
---@field StartTime string
local TStartTime = {}
TStartTime.__index = TStartTime
TStartTime.group = {}

local function TStartTime_from_obj(obj)
    return setmetatable(obj, TStartTime)
end

function TStartTime.new(StartTime)
    return TStartTime_from_obj({StartTime = StartTime})
end
---@param obj Task.StartTime
function TStartTime:init_from_obj(obj)
    self.StartTime = obj.StartTime
end

function TStartTime:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TStartTime.group)
end

TStartTime.from_obj = TStartTime_from_obj

TStartTime.proto_property = {'StartTime'}

TStartTime.default = {''}

TStartTime.struct = {{name = 'StartTime', is_array = false, struct = nil}}

function TStartTime:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'StartTime', self.StartTime, 'string', true, errs, need_convert)

    TStartTime:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TStartTime.proto_property, errs, need_convert)
    return self
end

function TStartTime:unpack(_)
    return self.StartTime
end

Task.StartTime = TStartTime

---@class Task.Name
---@field Name string
local TName = {}
TName.__index = TName
TName.group = {}

local function TName_from_obj(obj)
    return setmetatable(obj, TName)
end

function TName.new(Name)
    return TName_from_obj({Name = Name})
end
---@param obj Task.Name
function TName:init_from_obj(obj)
    self.Name = obj.Name
end

function TName:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TName.group)
end

TName.from_obj = TName_from_obj

TName.proto_property = {'Name'}

TName.default = {''}

TName.struct = {{name = 'Name', is_array = false, struct = nil}}

function TName:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Name', self.Name, 'string', true, errs, need_convert)

    TName:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TName.proto_property, errs, need_convert)
    return self
end

function TName:unpack(_)
    return self.Name
end

Task.Name = TName

---@class Task.Id
---@field Id integer
local TId = {}
TId.__index = TId
TId.group = {}

local function TId_from_obj(obj)
    return setmetatable(obj, TId)
end

function TId.new(Id)
    return TId_from_obj({Id = Id})
end
---@param obj Task.Id
function TId:init_from_obj(obj)
    self.Id = obj.Id
end

function TId:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TId.group)
end

TId.from_obj = TId_from_obj

TId.proto_property = {'Id'}

TId.default = {0}

TId.struct = {{name = 'Id', is_array = false, struct = nil}}

function TId:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Id', self.Id, 'uint32', true, errs, need_convert)

    TId:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TId.proto_property, errs, need_convert)
    return self
end

function TId:unpack(_)
    return self.Id
end

Task.Id = TId

Task.interface = mdb.register_interface('bmc.kepler.TaskService.Task', {
    Id = {'u', nil, true, nil, false},
    Name = {'s', nil, true, nil, false},
    StartTime = {'s', nil, true, nil, false},
    EndTime = {'s', nil, true, nil, false},
    Progress = {'u', nil, true, nil, false},
    State = {'s', nil, true, nil, false},
    Status = {'s', nil, true, nil, false},
    Parameters = {'s', nil, true, nil, false},
    MessageId = {'s', nil, true, nil, false},
    MessageArgs = {'as', nil, true, nil, false}
}, {}, {})

return Task
