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

local Events = {}

---@class Events.MaskedEventInfo
---@field EventCode string
---@field EventName string
local TMaskedEventInfo = {}
TMaskedEventInfo.__index = TMaskedEventInfo
TMaskedEventInfo.group = {}

local function TMaskedEventInfo_from_obj(obj)
    return setmetatable(obj, TMaskedEventInfo)
end

function TMaskedEventInfo.new(EventCode, EventName)
    return TMaskedEventInfo_from_obj({EventCode = EventCode, EventName = EventName})
end
---@param obj Events.MaskedEventInfo
function TMaskedEventInfo:init_from_obj(obj)
    self.EventCode = obj.EventCode
    self.EventName = obj.EventName
end

function TMaskedEventInfo:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMaskedEventInfo.group)
end

TMaskedEventInfo.from_obj = TMaskedEventInfo_from_obj

TMaskedEventInfo.proto_property = {'EventCode', 'EventName'}

TMaskedEventInfo.default = {'', ''}

TMaskedEventInfo.struct = {
    {name = 'EventCode', is_array = false, struct = nil}, {name = 'EventName', is_array = false, struct = nil}
}

function TMaskedEventInfo:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EventCode', self.EventCode, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'EventName', self.EventName, 'string', false, errs, need_convert)

    TMaskedEventInfo:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMaskedEventInfo.proto_property, errs, need_convert)
    return self
end

function TMaskedEventInfo:unpack(_)
    return self.EventCode, self.EventName
end

Events.MaskedEventInfo = TMaskedEventInfo

---@class Events.KeyValueTable
---@field Key string
---@field Value string
local TKeyValueTable = {}
TKeyValueTable.__index = TKeyValueTable
TKeyValueTable.group = {}

local function TKeyValueTable_from_obj(obj)
    return setmetatable(obj, TKeyValueTable)
end

function TKeyValueTable.new(Key, Value)
    return TKeyValueTable_from_obj({Key = Key, Value = Value})
end
---@param obj Events.KeyValueTable
function TKeyValueTable:init_from_obj(obj)
    self.Key = obj.Key
    self.Value = obj.Value
end

function TKeyValueTable:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TKeyValueTable.group)
end

TKeyValueTable.from_obj = TKeyValueTable_from_obj

TKeyValueTable.proto_property = {'Key', 'Value'}

TKeyValueTable.default = {'', ''}

TKeyValueTable.struct = {
    {name = 'Key', is_array = false, struct = nil}, {name = 'Value', is_array = false, struct = nil}
}

function TKeyValueTable:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Key', self.Key, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Value', self.Value, 'string', false, errs, need_convert)

    TKeyValueTable:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TKeyValueTable.proto_property, errs, need_convert)
    return self
end

function TKeyValueTable:unpack(_)
    return self.Key, self.Value
end

Events.KeyValueTable = TKeyValueTable

---@class Events.EventInfo
---@field MappingTable Events.KeyValueTable[]
local TEventInfo = {}
TEventInfo.__index = TEventInfo
TEventInfo.group = {}

local function TEventInfo_from_obj(obj)
    obj.MappingTable = utils.from_obj(Events.KeyValueTable, obj.MappingTable, true)
    return setmetatable(obj, TEventInfo)
end

function TEventInfo.new(MappingTable)
    return TEventInfo_from_obj({MappingTable = MappingTable})
end
---@param obj Events.EventInfo
function TEventInfo:init_from_obj(obj)
    self.MappingTable = obj.MappingTable
end

function TEventInfo:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TEventInfo.group)
end

TEventInfo.from_obj = TEventInfo_from_obj

TEventInfo.proto_property = {'MappingTable'}

TEventInfo.default = {{}}

TEventInfo.struct = {{name = 'MappingTable', is_array = true, struct = Events.KeyValueTable.struct}}

function TEventInfo:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.MappingTable) do
        Events.KeyValueTable.new(v.Key, v.Value):validate(prefix, errs, need_convert)
    end

    TEventInfo:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TEventInfo.proto_property, errs, need_convert)
    return self
end

function TEventInfo:unpack(raw)
    return utils.unpack(raw, self.MappingTable, true)
end

Events.EventInfo = TEventInfo

---@class Events.AddSelRsp
local TAddSelRsp = {}
TAddSelRsp.__index = TAddSelRsp
TAddSelRsp.group = {}

local function TAddSelRsp_from_obj(obj)
    return setmetatable(obj, TAddSelRsp)
end

function TAddSelRsp.new()
    return TAddSelRsp_from_obj({})
end
---@param obj Events.AddSelRsp
function TAddSelRsp:init_from_obj(obj)

end

function TAddSelRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddSelRsp.group)
end

TAddSelRsp.from_obj = TAddSelRsp_from_obj

TAddSelRsp.proto_property = {}

TAddSelRsp.default = {}

TAddSelRsp.struct = {}

function TAddSelRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TAddSelRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddSelRsp.proto_property, errs, need_convert)
    return self
end

function TAddSelRsp:unpack(_)
end

Events.AddSelRsp = TAddSelRsp

---@class Events.AddSelReq
---@field EventInfo Events.KeyValueTable[]
local TAddSelReq = {}
TAddSelReq.__index = TAddSelReq
TAddSelReq.group = {}

local function TAddSelReq_from_obj(obj)
    obj.EventInfo = utils.from_obj(Events.KeyValueTable, obj.EventInfo, true)
    return setmetatable(obj, TAddSelReq)
end

function TAddSelReq.new(EventInfo)
    return TAddSelReq_from_obj({EventInfo = EventInfo})
end
---@param obj Events.AddSelReq
function TAddSelReq:init_from_obj(obj)
    self.EventInfo = obj.EventInfo
end

function TAddSelReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddSelReq.group)
end

TAddSelReq.from_obj = TAddSelReq_from_obj

TAddSelReq.proto_property = {'EventInfo'}

TAddSelReq.default = {{}}

TAddSelReq.struct = {{name = 'EventInfo', is_array = true, struct = Events.KeyValueTable.struct}}

function TAddSelReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.EventInfo) do
        Events.KeyValueTable.new(v.Key, v.Value):validate(prefix, errs, need_convert)
    end

    TAddSelReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddSelReq.proto_property, errs, need_convert)
    return self
end

function TAddSelReq:unpack(raw)
    return utils.unpack(raw, self.EventInfo, true)
end

Events.AddSelReq = TAddSelReq

---@class Events.SetEventActionRsp
local TSetEventActionRsp = {}
TSetEventActionRsp.__index = TSetEventActionRsp
TSetEventActionRsp.group = {}

local function TSetEventActionRsp_from_obj(obj)
    return setmetatable(obj, TSetEventActionRsp)
end

function TSetEventActionRsp.new()
    return TSetEventActionRsp_from_obj({})
end
---@param obj Events.SetEventActionRsp
function TSetEventActionRsp:init_from_obj(obj)

end

function TSetEventActionRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetEventActionRsp.group)
end

TSetEventActionRsp.from_obj = TSetEventActionRsp_from_obj

TSetEventActionRsp.proto_property = {}

TSetEventActionRsp.default = {}

TSetEventActionRsp.struct = {}

function TSetEventActionRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetEventActionRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetEventActionRsp.proto_property, errs, need_convert)
    return self
end

function TSetEventActionRsp:unpack(_)
end

Events.SetEventActionRsp = TSetEventActionRsp

---@class Events.SetEventActionReq
---@field EventKeyId string
---@field Action integer
local TSetEventActionReq = {}
TSetEventActionReq.__index = TSetEventActionReq
TSetEventActionReq.group = {}

local function TSetEventActionReq_from_obj(obj)
    return setmetatable(obj, TSetEventActionReq)
end

function TSetEventActionReq.new(EventKeyId, Action)
    return TSetEventActionReq_from_obj({EventKeyId = EventKeyId, Action = Action})
end
---@param obj Events.SetEventActionReq
function TSetEventActionReq:init_from_obj(obj)
    self.EventKeyId = obj.EventKeyId
    self.Action = obj.Action
end

function TSetEventActionReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetEventActionReq.group)
end

TSetEventActionReq.from_obj = TSetEventActionReq_from_obj

TSetEventActionReq.proto_property = {'EventKeyId', 'Action'}

TSetEventActionReq.default = {'', 0}

TSetEventActionReq.struct = {
    {name = 'EventKeyId', is_array = false, struct = nil}, {name = 'Action', is_array = false, struct = nil}
}

function TSetEventActionReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EventKeyId', self.EventKeyId, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Action', self.Action, 'uint8', false, errs, need_convert)

    TSetEventActionReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetEventActionReq.proto_property, errs, need_convert)
    return self
end

function TSetEventActionReq:unpack(_)
    return self.EventKeyId, self.Action
end

Events.SetEventActionReq = TSetEventActionReq

---@class Events.SetEventSeverityRsp
local TSetEventSeverityRsp = {}
TSetEventSeverityRsp.__index = TSetEventSeverityRsp
TSetEventSeverityRsp.group = {}

local function TSetEventSeverityRsp_from_obj(obj)
    return setmetatable(obj, TSetEventSeverityRsp)
end

function TSetEventSeverityRsp.new()
    return TSetEventSeverityRsp_from_obj({})
end
---@param obj Events.SetEventSeverityRsp
function TSetEventSeverityRsp:init_from_obj(obj)

end

function TSetEventSeverityRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetEventSeverityRsp.group)
end

TSetEventSeverityRsp.from_obj = TSetEventSeverityRsp_from_obj

TSetEventSeverityRsp.proto_property = {}

TSetEventSeverityRsp.default = {}

TSetEventSeverityRsp.struct = {}

function TSetEventSeverityRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetEventSeverityRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetEventSeverityRsp.proto_property, errs, need_convert)
    return self
end

function TSetEventSeverityRsp:unpack(_)
end

Events.SetEventSeverityRsp = TSetEventSeverityRsp

---@class Events.SetEventSeverityReq
---@field EventCode string
---@field Severity integer
local TSetEventSeverityReq = {}
TSetEventSeverityReq.__index = TSetEventSeverityReq
TSetEventSeverityReq.group = {}

local function TSetEventSeverityReq_from_obj(obj)
    return setmetatable(obj, TSetEventSeverityReq)
end

function TSetEventSeverityReq.new(EventCode, Severity)
    return TSetEventSeverityReq_from_obj({EventCode = EventCode, Severity = Severity})
end
---@param obj Events.SetEventSeverityReq
function TSetEventSeverityReq:init_from_obj(obj)
    self.EventCode = obj.EventCode
    self.Severity = obj.Severity
end

function TSetEventSeverityReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetEventSeverityReq.group)
end

TSetEventSeverityReq.from_obj = TSetEventSeverityReq_from_obj

TSetEventSeverityReq.proto_property = {'EventCode', 'Severity'}

TSetEventSeverityReq.default = {'', 0}

TSetEventSeverityReq.struct = {
    {name = 'EventCode', is_array = false, struct = nil}, {name = 'Severity', is_array = false, struct = nil}
}

function TSetEventSeverityReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EventCode', self.EventCode, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Severity', self.Severity, 'uint8', false, errs, need_convert)

    TSetEventSeverityReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetEventSeverityReq.proto_property, errs, need_convert)
    return self
end

function TSetEventSeverityReq:unpack(_)
    return self.EventCode, self.Severity
end

Events.SetEventSeverityReq = TSetEventSeverityReq

---@class Events.SetAlarmNameRsp
local TSetAlarmNameRsp = {}
TSetAlarmNameRsp.__index = TSetAlarmNameRsp
TSetAlarmNameRsp.group = {}

local function TSetAlarmNameRsp_from_obj(obj)
    return setmetatable(obj, TSetAlarmNameRsp)
end

function TSetAlarmNameRsp.new()
    return TSetAlarmNameRsp_from_obj({})
end
---@param obj Events.SetAlarmNameRsp
function TSetAlarmNameRsp:init_from_obj(obj)

end

function TSetAlarmNameRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetAlarmNameRsp.group)
end

TSetAlarmNameRsp.from_obj = TSetAlarmNameRsp_from_obj

TSetAlarmNameRsp.proto_property = {}

TSetAlarmNameRsp.default = {}

TSetAlarmNameRsp.struct = {}

function TSetAlarmNameRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetAlarmNameRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetAlarmNameRsp.proto_property, errs, need_convert)
    return self
end

function TSetAlarmNameRsp:unpack(_)
end

Events.SetAlarmNameRsp = TSetAlarmNameRsp

---@class Events.SetAlarmNameReq
---@field AlarmName string
local TSetAlarmNameReq = {}
TSetAlarmNameReq.__index = TSetAlarmNameReq
TSetAlarmNameReq.group = {}

local function TSetAlarmNameReq_from_obj(obj)
    return setmetatable(obj, TSetAlarmNameReq)
end

function TSetAlarmNameReq.new(AlarmName)
    return TSetAlarmNameReq_from_obj({AlarmName = AlarmName})
end
---@param obj Events.SetAlarmNameReq
function TSetAlarmNameReq:init_from_obj(obj)
    self.AlarmName = obj.AlarmName
end

function TSetAlarmNameReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetAlarmNameReq.group)
end

TSetAlarmNameReq.from_obj = TSetAlarmNameReq_from_obj

TSetAlarmNameReq.proto_property = {'AlarmName'}

TSetAlarmNameReq.default = {''}

TSetAlarmNameReq.struct = {{name = 'AlarmName', is_array = false, struct = nil}}

function TSetAlarmNameReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'AlarmName', self.AlarmName, 'string', false, errs, need_convert)

    TSetAlarmNameReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetAlarmNameReq.proto_property, errs, need_convert)
    return self
end

function TSetAlarmNameReq:unpack(_)
    return self.AlarmName
end

Events.SetAlarmNameReq = TSetAlarmNameReq

---@class Events.CheckEventNameRsp
---@field Result boolean[]
local TCheckEventNameRsp = {}
TCheckEventNameRsp.__index = TCheckEventNameRsp
TCheckEventNameRsp.group = {}

local function TCheckEventNameRsp_from_obj(obj)
    return setmetatable(obj, TCheckEventNameRsp)
end

function TCheckEventNameRsp.new(Result)
    return TCheckEventNameRsp_from_obj({Result = Result})
end
---@param obj Events.CheckEventNameRsp
function TCheckEventNameRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TCheckEventNameRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TCheckEventNameRsp.group)
end

TCheckEventNameRsp.from_obj = TCheckEventNameRsp_from_obj

TCheckEventNameRsp.proto_property = {'Result'}

TCheckEventNameRsp.default = {{}}

TCheckEventNameRsp.struct = {{name = 'Result', is_array = true, struct = nil}}

function TCheckEventNameRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.OptionalArray(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TCheckEventNameRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TCheckEventNameRsp.proto_property, errs, need_convert)
    return self
end

function TCheckEventNameRsp:unpack(_)
    return self.Result
end

Events.CheckEventNameRsp = TCheckEventNameRsp

---@class Events.CheckEventNameReq
---@field EventName string[]
local TCheckEventNameReq = {}
TCheckEventNameReq.__index = TCheckEventNameReq
TCheckEventNameReq.group = {}

local function TCheckEventNameReq_from_obj(obj)
    return setmetatable(obj, TCheckEventNameReq)
end

function TCheckEventNameReq.new(EventName)
    return TCheckEventNameReq_from_obj({EventName = EventName})
end
---@param obj Events.CheckEventNameReq
function TCheckEventNameReq:init_from_obj(obj)
    self.EventName = obj.EventName
end

function TCheckEventNameReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TCheckEventNameReq.group)
end

TCheckEventNameReq.from_obj = TCheckEventNameReq_from_obj

TCheckEventNameReq.proto_property = {'EventName'}

TCheckEventNameReq.default = {{}}

TCheckEventNameReq.struct = {{name = 'EventName', is_array = true, struct = nil}}

function TCheckEventNameReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.OptionalArray(prefix .. 'EventName', self.EventName, 'string', false, errs, need_convert)

    TCheckEventNameReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TCheckEventNameReq.proto_property, errs, need_convert)
    return self
end

function TCheckEventNameReq:unpack(_)
    return self.EventName
end

Events.CheckEventNameReq = TCheckEventNameReq

---@class Events.ExportEventRsp
---@field TaskId integer
local TExportEventRsp = {}
TExportEventRsp.__index = TExportEventRsp
TExportEventRsp.group = {}

local function TExportEventRsp_from_obj(obj)
    return setmetatable(obj, TExportEventRsp)
end

function TExportEventRsp.new(TaskId)
    return TExportEventRsp_from_obj({TaskId = TaskId})
end
---@param obj Events.ExportEventRsp
function TExportEventRsp:init_from_obj(obj)
    self.TaskId = obj.TaskId
end

function TExportEventRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExportEventRsp.group)
end

TExportEventRsp.from_obj = TExportEventRsp_from_obj

TExportEventRsp.proto_property = {'TaskId'}

TExportEventRsp.default = {0}

TExportEventRsp.struct = {{name = 'TaskId', is_array = false, struct = nil}}

function TExportEventRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TExportEventRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TExportEventRsp.proto_property, errs, need_convert)
    return self
end

function TExportEventRsp:unpack(_)
    return self.TaskId
end

Events.ExportEventRsp = TExportEventRsp

---@class Events.ExportEventReq
---@field Path string
local TExportEventReq = {}
TExportEventReq.__index = TExportEventReq
TExportEventReq.group = {}

local function TExportEventReq_from_obj(obj)
    return setmetatable(obj, TExportEventReq)
end

function TExportEventReq.new(Path)
    return TExportEventReq_from_obj({Path = Path})
end
---@param obj Events.ExportEventReq
function TExportEventReq:init_from_obj(obj)
    self.Path = obj.Path
end

function TExportEventReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExportEventReq.group)
end

TExportEventReq.from_obj = TExportEventReq_from_obj

TExportEventReq.proto_property = {'Path'}

TExportEventReq.default = {''}

TExportEventReq.struct = {{name = 'Path', is_array = false, struct = nil}}

function TExportEventReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Path', self.Path, 'string', false, errs, need_convert)

    TExportEventReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TExportEventReq.proto_property, errs, need_convert)
    return self
end

function TExportEventReq:unpack(_)
    return self.Path
end

Events.ExportEventReq = TExportEventReq

---@class Events.AddEventRsp
---@field RecordId string
local TAddEventRsp = {}
TAddEventRsp.__index = TAddEventRsp
TAddEventRsp.group = {}

local function TAddEventRsp_from_obj(obj)
    return setmetatable(obj, TAddEventRsp)
end

function TAddEventRsp.new(RecordId)
    return TAddEventRsp_from_obj({RecordId = RecordId})
end
---@param obj Events.AddEventRsp
function TAddEventRsp:init_from_obj(obj)
    self.RecordId = obj.RecordId
end

function TAddEventRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddEventRsp.group)
end

TAddEventRsp.from_obj = TAddEventRsp_from_obj

TAddEventRsp.proto_property = {'RecordId'}

TAddEventRsp.default = {''}

TAddEventRsp.struct = {{name = 'RecordId', is_array = false, struct = nil}}

function TAddEventRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'RecordId', self.RecordId, 'string', false, errs, need_convert)

    TAddEventRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddEventRsp.proto_property, errs, need_convert)
    return self
end

function TAddEventRsp:unpack(_)
    return self.RecordId
end

Events.AddEventRsp = TAddEventRsp

---@class Events.AddEventReq
---@field EventInfo Events.KeyValueTable[]
local TAddEventReq = {}
TAddEventReq.__index = TAddEventReq
TAddEventReq.group = {}

local function TAddEventReq_from_obj(obj)
    obj.EventInfo = utils.from_obj(Events.KeyValueTable, obj.EventInfo, true)
    return setmetatable(obj, TAddEventReq)
end

function TAddEventReq.new(EventInfo)
    return TAddEventReq_from_obj({EventInfo = EventInfo})
end
---@param obj Events.AddEventReq
function TAddEventReq:init_from_obj(obj)
    self.EventInfo = obj.EventInfo
end

function TAddEventReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAddEventReq.group)
end

TAddEventReq.from_obj = TAddEventReq_from_obj

TAddEventReq.proto_property = {'EventInfo'}

TAddEventReq.default = {{}}

TAddEventReq.struct = {{name = 'EventInfo', is_array = true, struct = Events.KeyValueTable.struct}}

function TAddEventReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.EventInfo) do
        Events.KeyValueTable.new(v.Key, v.Value):validate(prefix, errs, need_convert)
    end

    TAddEventReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAddEventReq.proto_property, errs, need_convert)
    return self
end

function TAddEventReq:unpack(raw)
    return utils.unpack(raw, self.EventInfo, true)
end

Events.AddEventReq = TAddEventReq

---@class Events.GetMaskedEventListRsp
---@field MaskedEventList Events.MaskedEventInfo[]
local TGetMaskedEventListRsp = {}
TGetMaskedEventListRsp.__index = TGetMaskedEventListRsp
TGetMaskedEventListRsp.group = {}

local function TGetMaskedEventListRsp_from_obj(obj)
    obj.MaskedEventList = utils.from_obj(Events.MaskedEventInfo, obj.MaskedEventList, true)
    return setmetatable(obj, TGetMaskedEventListRsp)
end

function TGetMaskedEventListRsp.new(MaskedEventList)
    return TGetMaskedEventListRsp_from_obj({MaskedEventList = MaskedEventList})
end
---@param obj Events.GetMaskedEventListRsp
function TGetMaskedEventListRsp:init_from_obj(obj)
    self.MaskedEventList = obj.MaskedEventList
end

function TGetMaskedEventListRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetMaskedEventListRsp.group)
end

TGetMaskedEventListRsp.from_obj = TGetMaskedEventListRsp_from_obj

TGetMaskedEventListRsp.proto_property = {'MaskedEventList'}

TGetMaskedEventListRsp.default = {{}}

TGetMaskedEventListRsp.struct = {{name = 'MaskedEventList', is_array = true, struct = Events.MaskedEventInfo.struct}}

function TGetMaskedEventListRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.MaskedEventList) do
        Events.MaskedEventInfo.new(v.EventCode, v.EventName):validate(prefix, errs, need_convert)
    end

    TGetMaskedEventListRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetMaskedEventListRsp.proto_property, errs, need_convert)
    return self
end

function TGetMaskedEventListRsp:unpack(raw)
    return utils.unpack(raw, self.MaskedEventList, true)
end

Events.GetMaskedEventListRsp = TGetMaskedEventListRsp

---@class Events.GetMaskedEventListReq
local TGetMaskedEventListReq = {}
TGetMaskedEventListReq.__index = TGetMaskedEventListReq
TGetMaskedEventListReq.group = {}

local function TGetMaskedEventListReq_from_obj(obj)
    return setmetatable(obj, TGetMaskedEventListReq)
end

function TGetMaskedEventListReq.new()
    return TGetMaskedEventListReq_from_obj({})
end
---@param obj Events.GetMaskedEventListReq
function TGetMaskedEventListReq:init_from_obj(obj)

end

function TGetMaskedEventListReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetMaskedEventListReq.group)
end

TGetMaskedEventListReq.from_obj = TGetMaskedEventListReq_from_obj

TGetMaskedEventListReq.proto_property = {}

TGetMaskedEventListReq.default = {}

TGetMaskedEventListReq.struct = {}

function TGetMaskedEventListReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TGetMaskedEventListReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetMaskedEventListReq.proto_property, errs, need_convert)
    return self
end

function TGetMaskedEventListReq:unpack(_)
end

Events.GetMaskedEventListReq = TGetMaskedEventListReq

---@class Events.MaskEventRsp
local TMaskEventRsp = {}
TMaskEventRsp.__index = TMaskEventRsp
TMaskEventRsp.group = {}

local function TMaskEventRsp_from_obj(obj)
    return setmetatable(obj, TMaskEventRsp)
end

function TMaskEventRsp.new()
    return TMaskEventRsp_from_obj({})
end
---@param obj Events.MaskEventRsp
function TMaskEventRsp:init_from_obj(obj)

end

function TMaskEventRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMaskEventRsp.group)
end

TMaskEventRsp.from_obj = TMaskEventRsp_from_obj

TMaskEventRsp.proto_property = {}

TMaskEventRsp.default = {}

TMaskEventRsp.struct = {}

function TMaskEventRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TMaskEventRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMaskEventRsp.proto_property, errs, need_convert)
    return self
end

function TMaskEventRsp:unpack(_)
end

Events.MaskEventRsp = TMaskEventRsp

---@class Events.MaskEventReq
---@field EventCode string
---@field MaskState integer
---@field Mode integer
local TMaskEventReq = {}
TMaskEventReq.__index = TMaskEventReq
TMaskEventReq.group = {}

local function TMaskEventReq_from_obj(obj)
    return setmetatable(obj, TMaskEventReq)
end

function TMaskEventReq.new(EventCode, MaskState, Mode)
    return TMaskEventReq_from_obj({EventCode = EventCode, MaskState = MaskState, Mode = Mode})
end
---@param obj Events.MaskEventReq
function TMaskEventReq:init_from_obj(obj)
    self.EventCode = obj.EventCode
    self.MaskState = obj.MaskState
    self.Mode = obj.Mode
end

function TMaskEventReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMaskEventReq.group)
end

TMaskEventReq.from_obj = TMaskEventReq_from_obj

TMaskEventReq.proto_property = {'EventCode', 'MaskState', 'Mode'}

TMaskEventReq.default = {'', 0, 0}

TMaskEventReq.struct = {
    {name = 'EventCode', is_array = false, struct = nil}, {name = 'MaskState', is_array = false, struct = nil},
    {name = 'Mode', is_array = false, struct = nil}
}

function TMaskEventReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EventCode', self.EventCode, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'MaskState', self.MaskState, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'Mode', self.Mode, 'uint8', false, errs, need_convert)

    TMaskEventReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMaskEventReq.proto_property, errs, need_convert)
    return self
end

function TMaskEventReq:unpack(_)
    return self.EventCode, self.MaskState, self.Mode
end

Events.MaskEventReq = TMaskEventReq

---@class Events.GetEventInfoRsp
---@field Version string
---@field CurEventCount integer
---@field MaxEventCount integer
local TGetEventInfoRsp = {}
TGetEventInfoRsp.__index = TGetEventInfoRsp
TGetEventInfoRsp.group = {}

local function TGetEventInfoRsp_from_obj(obj)
    return setmetatable(obj, TGetEventInfoRsp)
end

function TGetEventInfoRsp.new(Version, CurEventCount, MaxEventCount)
    return TGetEventInfoRsp_from_obj({Version = Version, CurEventCount = CurEventCount, MaxEventCount = MaxEventCount})
end
---@param obj Events.GetEventInfoRsp
function TGetEventInfoRsp:init_from_obj(obj)
    self.Version = obj.Version
    self.CurEventCount = obj.CurEventCount
    self.MaxEventCount = obj.MaxEventCount
end

function TGetEventInfoRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetEventInfoRsp.group)
end

TGetEventInfoRsp.from_obj = TGetEventInfoRsp_from_obj

TGetEventInfoRsp.proto_property = {'Version', 'CurEventCount', 'MaxEventCount'}

TGetEventInfoRsp.default = {'', 0, 0}

TGetEventInfoRsp.struct = {
    {name = 'Version', is_array = false, struct = nil}, {name = 'CurEventCount', is_array = false, struct = nil},
    {name = 'MaxEventCount', is_array = false, struct = nil}
}

function TGetEventInfoRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Version', self.Version, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'CurEventCount', self.CurEventCount, 'uint16', false, errs, need_convert)
    validate.Optional(prefix .. 'MaxEventCount', self.MaxEventCount, 'uint16', false, errs, need_convert)

    TGetEventInfoRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetEventInfoRsp.proto_property, errs, need_convert)
    return self
end

function TGetEventInfoRsp:unpack(_)
    return self.Version, self.CurEventCount, self.MaxEventCount
end

Events.GetEventInfoRsp = TGetEventInfoRsp

---@class Events.GetEventInfoReq
local TGetEventInfoReq = {}
TGetEventInfoReq.__index = TGetEventInfoReq
TGetEventInfoReq.group = {}

local function TGetEventInfoReq_from_obj(obj)
    return setmetatable(obj, TGetEventInfoReq)
end

function TGetEventInfoReq.new()
    return TGetEventInfoReq_from_obj({})
end
---@param obj Events.GetEventInfoReq
function TGetEventInfoReq:init_from_obj(obj)

end

function TGetEventInfoReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetEventInfoReq.group)
end

TGetEventInfoReq.from_obj = TGetEventInfoReq_from_obj

TGetEventInfoReq.proto_property = {}

TGetEventInfoReq.default = {}

TGetEventInfoReq.struct = {}

function TGetEventInfoReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TGetEventInfoReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetEventInfoReq.proto_property, errs, need_convert)
    return self
end

function TGetEventInfoReq:unpack(_)
end

Events.GetEventInfoReq = TGetEventInfoReq

---@class Events.ClearEventListRsp
local TClearEventListRsp = {}
TClearEventListRsp.__index = TClearEventListRsp
TClearEventListRsp.group = {}

local function TClearEventListRsp_from_obj(obj)
    return setmetatable(obj, TClearEventListRsp)
end

function TClearEventListRsp.new()
    return TClearEventListRsp_from_obj({})
end
---@param obj Events.ClearEventListRsp
function TClearEventListRsp:init_from_obj(obj)

end

function TClearEventListRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TClearEventListRsp.group)
end

TClearEventListRsp.from_obj = TClearEventListRsp_from_obj

TClearEventListRsp.proto_property = {}

TClearEventListRsp.default = {}

TClearEventListRsp.struct = {}

function TClearEventListRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TClearEventListRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TClearEventListRsp.proto_property, errs, need_convert)
    return self
end

function TClearEventListRsp:unpack(_)
end

Events.ClearEventListRsp = TClearEventListRsp

---@class Events.ClearEventListReq
local TClearEventListReq = {}
TClearEventListReq.__index = TClearEventListReq
TClearEventListReq.group = {}

local function TClearEventListReq_from_obj(obj)
    return setmetatable(obj, TClearEventListReq)
end

function TClearEventListReq.new()
    return TClearEventListReq_from_obj({})
end
---@param obj Events.ClearEventListReq
function TClearEventListReq:init_from_obj(obj)

end

function TClearEventListReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TClearEventListReq.group)
end

TClearEventListReq.from_obj = TClearEventListReq_from_obj

TClearEventListReq.proto_property = {}

TClearEventListReq.default = {}

TClearEventListReq.struct = {}

function TClearEventListReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TClearEventListReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TClearEventListReq.proto_property, errs, need_convert)
    return self
end

function TClearEventListReq:unpack(_)
end

Events.ClearEventListReq = TClearEventListReq

---@class Events.GetEventListRsp
---@field Total integer
---@field EventList Events.EventInfo[]
local TGetEventListRsp = {}
TGetEventListRsp.__index = TGetEventListRsp
TGetEventListRsp.group = {}

local function TGetEventListRsp_from_obj(obj)
    obj.EventList = utils.from_obj(Events.EventInfo, obj.EventList, true)
    return setmetatable(obj, TGetEventListRsp)
end

function TGetEventListRsp.new(Total, EventList)
    return TGetEventListRsp_from_obj({Total = Total, EventList = EventList})
end
---@param obj Events.GetEventListRsp
function TGetEventListRsp:init_from_obj(obj)
    self.Total = obj.Total
    self.EventList = obj.EventList
end

function TGetEventListRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetEventListRsp.group)
end

TGetEventListRsp.from_obj = TGetEventListRsp_from_obj

TGetEventListRsp.proto_property = {'Total', 'EventList'}

TGetEventListRsp.default = {0, {}}

TGetEventListRsp.struct = {
    {name = 'Total', is_array = false, struct = nil},
    {name = 'EventList', is_array = true, struct = Events.EventInfo.struct}
}

function TGetEventListRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.EventList) do
        Events.EventInfo.new(v.MappingTable):validate(prefix, errs, need_convert)
    end

    validate.Optional(prefix .. 'Total', self.Total, 'uint16', false, errs, need_convert)

    TGetEventListRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetEventListRsp.proto_property, errs, need_convert)
    return self
end

function TGetEventListRsp:unpack(raw)
    return self.Total, utils.unpack(raw, self.EventList, true)
end

Events.GetEventListRsp = TGetEventListRsp

---@class Events.GetEventListReq
---@field StartId integer
---@field Count integer
---@field QueryParameters Events.KeyValueTable[]
local TGetEventListReq = {}
TGetEventListReq.__index = TGetEventListReq
TGetEventListReq.group = {}

local function TGetEventListReq_from_obj(obj)
    obj.QueryParameters = utils.from_obj(Events.KeyValueTable, obj.QueryParameters, true)
    return setmetatable(obj, TGetEventListReq)
end

function TGetEventListReq.new(StartId, Count, QueryParameters)
    return TGetEventListReq_from_obj({StartId = StartId, Count = Count, QueryParameters = QueryParameters})
end
---@param obj Events.GetEventListReq
function TGetEventListReq:init_from_obj(obj)
    self.StartId = obj.StartId
    self.Count = obj.Count
    self.QueryParameters = obj.QueryParameters
end

function TGetEventListReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetEventListReq.group)
end

TGetEventListReq.from_obj = TGetEventListReq_from_obj

TGetEventListReq.proto_property = {'StartId', 'Count', 'QueryParameters'}

TGetEventListReq.default = {0, 0, {}}

TGetEventListReq.struct = {
    {name = 'StartId', is_array = false, struct = nil}, {name = 'Count', is_array = false, struct = nil},
    {name = 'QueryParameters', is_array = true, struct = Events.KeyValueTable.struct}
}

function TGetEventListReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.QueryParameters) do
        Events.KeyValueTable.new(v.Key, v.Value):validate(prefix, errs, need_convert)
    end

    validate.Optional(prefix .. 'StartId', self.StartId, 'uint16', false, errs, need_convert)
    validate.Optional(prefix .. 'Count', self.Count, 'uint16', false, errs, need_convert)

    TGetEventListReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetEventListReq.proto_property, errs, need_convert)
    return self
end

function TGetEventListReq:unpack(raw)
    return self.StartId, self.Count, utils.unpack(raw, self.QueryParameters, true)
end

Events.GetEventListReq = TGetEventListReq

---@class Events.GetAlarmListRsp
---@field Total integer
---@field EventList Events.EventInfo[]
local TGetAlarmListRsp = {}
TGetAlarmListRsp.__index = TGetAlarmListRsp
TGetAlarmListRsp.group = {}

local function TGetAlarmListRsp_from_obj(obj)
    obj.EventList = utils.from_obj(Events.EventInfo, obj.EventList, true)
    return setmetatable(obj, TGetAlarmListRsp)
end

function TGetAlarmListRsp.new(Total, EventList)
    return TGetAlarmListRsp_from_obj({Total = Total, EventList = EventList})
end
---@param obj Events.GetAlarmListRsp
function TGetAlarmListRsp:init_from_obj(obj)
    self.Total = obj.Total
    self.EventList = obj.EventList
end

function TGetAlarmListRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetAlarmListRsp.group)
end

TGetAlarmListRsp.from_obj = TGetAlarmListRsp_from_obj

TGetAlarmListRsp.proto_property = {'Total', 'EventList'}

TGetAlarmListRsp.default = {0, {}}

TGetAlarmListRsp.struct = {
    {name = 'Total', is_array = false, struct = nil},
    {name = 'EventList', is_array = true, struct = Events.EventInfo.struct}
}

function TGetAlarmListRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.EventList) do
        Events.EventInfo.new(v.MappingTable):validate(prefix, errs, need_convert)
    end

    validate.Optional(prefix .. 'Total', self.Total, 'uint16', false, errs, need_convert)

    TGetAlarmListRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetAlarmListRsp.proto_property, errs, need_convert)
    return self
end

function TGetAlarmListRsp:unpack(raw)
    return self.Total, utils.unpack(raw, self.EventList, true)
end

Events.GetAlarmListRsp = TGetAlarmListRsp

---@class Events.GetAlarmListReq
---@field StartId integer
---@field Count integer
---@field QueryParameters Events.KeyValueTable[]
local TGetAlarmListReq = {}
TGetAlarmListReq.__index = TGetAlarmListReq
TGetAlarmListReq.group = {}

local function TGetAlarmListReq_from_obj(obj)
    obj.QueryParameters = utils.from_obj(Events.KeyValueTable, obj.QueryParameters, true)
    return setmetatable(obj, TGetAlarmListReq)
end

function TGetAlarmListReq.new(StartId, Count, QueryParameters)
    return TGetAlarmListReq_from_obj({StartId = StartId, Count = Count, QueryParameters = QueryParameters})
end
---@param obj Events.GetAlarmListReq
function TGetAlarmListReq:init_from_obj(obj)
    self.StartId = obj.StartId
    self.Count = obj.Count
    self.QueryParameters = obj.QueryParameters
end

function TGetAlarmListReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetAlarmListReq.group)
end

TGetAlarmListReq.from_obj = TGetAlarmListReq_from_obj

TGetAlarmListReq.proto_property = {'StartId', 'Count', 'QueryParameters'}

TGetAlarmListReq.default = {0, 0, {}}

TGetAlarmListReq.struct = {
    {name = 'StartId', is_array = false, struct = nil}, {name = 'Count', is_array = false, struct = nil},
    {name = 'QueryParameters', is_array = true, struct = Events.KeyValueTable.struct}
}

function TGetAlarmListReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for _, v in pairs(self.QueryParameters) do
        Events.KeyValueTable.new(v.Key, v.Value):validate(prefix, errs, need_convert)
    end

    validate.Optional(prefix .. 'StartId', self.StartId, 'uint16', false, errs, need_convert)
    validate.Optional(prefix .. 'Count', self.Count, 'uint16', false, errs, need_convert)

    TGetAlarmListReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetAlarmListReq.proto_property, errs, need_convert)
    return self
end

function TGetAlarmListReq:unpack(raw)
    return self.StartId, self.Count, utils.unpack(raw, self.QueryParameters, true)
end

Events.GetAlarmListReq = TGetAlarmListReq

---@class Events.MockEventRsp
local TMockEventRsp = {}
TMockEventRsp.__index = TMockEventRsp
TMockEventRsp.group = {}

local function TMockEventRsp_from_obj(obj)
    return setmetatable(obj, TMockEventRsp)
end

function TMockEventRsp.new()
    return TMockEventRsp_from_obj({})
end
---@param obj Events.MockEventRsp
function TMockEventRsp:init_from_obj(obj)

end

function TMockEventRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMockEventRsp.group)
end

TMockEventRsp.from_obj = TMockEventRsp_from_obj

TMockEventRsp.proto_property = {}

TMockEventRsp.default = {}

TMockEventRsp.struct = {}

function TMockEventRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TMockEventRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMockEventRsp.proto_property, errs, need_convert)
    return self
end

function TMockEventRsp:unpack(_)
end

Events.MockEventRsp = TMockEventRsp

---@class Events.MockEventReq
---@field EventCode string
---@field Enabled integer
---@field ObjectIndex integer
---@field MockState integer
local TMockEventReq = {}
TMockEventReq.__index = TMockEventReq
TMockEventReq.group = {}

local function TMockEventReq_from_obj(obj)
    return setmetatable(obj, TMockEventReq)
end

function TMockEventReq.new(EventCode, Enabled, ObjectIndex, MockState)
    return TMockEventReq_from_obj({
        EventCode = EventCode,
        Enabled = Enabled,
        ObjectIndex = ObjectIndex,
        MockState = MockState
    })
end
---@param obj Events.MockEventReq
function TMockEventReq:init_from_obj(obj)
    self.EventCode = obj.EventCode
    self.Enabled = obj.Enabled
    self.ObjectIndex = obj.ObjectIndex
    self.MockState = obj.MockState
end

function TMockEventReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMockEventReq.group)
end

TMockEventReq.from_obj = TMockEventReq_from_obj

TMockEventReq.proto_property = {'EventCode', 'Enabled', 'ObjectIndex', 'MockState'}

TMockEventReq.default = {'', 0, 0, 0}

TMockEventReq.struct = {
    {name = 'EventCode', is_array = false, struct = nil}, {name = 'Enabled', is_array = false, struct = nil},
    {name = 'ObjectIndex', is_array = false, struct = nil}, {name = 'MockState', is_array = false, struct = nil}
}

function TMockEventReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'EventCode', self.EventCode, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Enabled', self.Enabled, 'uint8', false, errs, need_convert)
    validate.Optional(prefix .. 'ObjectIndex', self.ObjectIndex, 'uint16', false, errs, need_convert)
    validate.Optional(prefix .. 'MockState', self.MockState, 'uint8', false, errs, need_convert)

    TMockEventReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMockEventReq.proto_property, errs, need_convert)
    return self
end

function TMockEventReq:unpack(_)
    return self.EventCode, self.Enabled, self.ObjectIndex, self.MockState
end

Events.MockEventReq = TMockEventReq

Events.interface = mdb.register_interface('bmc.kepler.Systems.Events', {
    Health = {'s', nil, true, 'Normal'},
    EventRecordSeq = {'t', nil, true, 0},
    CriticalCount = {'u', {['emitsChangedSignal'] = 'true'}, true, 0},
    MajorCount = {'u', {['emitsChangedSignal'] = 'true'}, true, 0},
    MinorCount = {'u', {['emitsChangedSignal'] = 'true'}, true, 0},
    Version = {'s', {['emitsChangedSignal'] = 'const'}, true, '`1.0.0`'},
    CurEventCount = {'u', {['emitsChangedSignal'] = 'false'}, true, 0},
    MaxEventCount = {'u', {['emitsChangedSignal'] = 'const'}, true, 10000},
    DumpRecord = {'t', {['emitsChangedSignal'] = 'false'}, true, 0},
    MajorVersion = {'s', {['emitsChangedSignal'] = 'const'}, true, '3'},
    MinorVersion = {'s', {['emitsChangedSignal'] = 'const'}, true, '0'},
    AuxVersion = {'s', {['emitsChangedSignal'] = 'const'}, true, '0'},
    EventMode = {'y', nil, false, nil}
}, {
    MockEvent = {'a{ss}syqy', '', TMockEventReq, TMockEventRsp},
    GetAlarmList = {'a{ss}qqa(ss)', 'qa(a(ss))', TGetAlarmListReq, TGetAlarmListRsp},
    GetEventList = {'a{ss}qqa(ss)', 'qa(a(ss))', TGetEventListReq, TGetEventListRsp},
    ClearEventList = {'a{ss}', '', TClearEventListReq, TClearEventListRsp},
    GetEventInfo = {'a{ss}', 'sqq', TGetEventInfoReq, TGetEventInfoRsp},
    MaskEvent = {'a{ss}syy', '', TMaskEventReq, TMaskEventRsp},
    GetMaskedEventList = {'a{ss}', 'a(ss)', TGetMaskedEventListReq, TGetMaskedEventListRsp},
    AddEvent = {'a{ss}a(ss)', 's', TAddEventReq, TAddEventRsp},
    ExportEvent = {'a{ss}s', 'u', TExportEventReq, TExportEventRsp},
    CheckEventName = {'a{ss}as', 'ab', TCheckEventNameReq, TCheckEventNameRsp},
    SetAlarmName = {'a{ss}s', '', TSetAlarmNameReq, TSetAlarmNameRsp},
    SetEventSeverity = {'a{ss}sy', '', TSetEventSeverityReq, TSetEventSeverityRsp},
    SetEventAction = {'a{ss}sy', '', TSetEventActionReq, TSetEventActionRsp},
    AddSel = {'a{ss}a(ss)', '', TAddSelReq, TAddSelRsp}
}, {})

return Events
