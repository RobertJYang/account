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

local FileTransfer = {}

---@class FileTransfer.UmountRsp
---@field Result integer
local TUmountRsp = {}
TUmountRsp.__index = TUmountRsp
TUmountRsp.group = {}

local function TUmountRsp_from_obj(obj)
    return setmetatable(obj, TUmountRsp)
end

function TUmountRsp.new(Result)
    return TUmountRsp_from_obj({Result = Result})
end
---@param obj FileTransfer.UmountRsp
function TUmountRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TUmountRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUmountRsp.group)
end

TUmountRsp.from_obj = TUmountRsp_from_obj

TUmountRsp.proto_property = {'Result'}

TUmountRsp.default = {0}

TUmountRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TUmountRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'int32', false, errs, need_convert)

    TUmountRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUmountRsp.proto_property, errs, need_convert)
    return self
end

function TUmountRsp:unpack(_)
    return self.Result
end

FileTransfer.UmountRsp = TUmountRsp

---@class FileTransfer.UmountReq
---@field MountPoint string
local TUmountReq = {}
TUmountReq.__index = TUmountReq
TUmountReq.group = {}

local function TUmountReq_from_obj(obj)
    return setmetatable(obj, TUmountReq)
end

function TUmountReq.new(MountPoint)
    return TUmountReq_from_obj({MountPoint = MountPoint})
end
---@param obj FileTransfer.UmountReq
function TUmountReq:init_from_obj(obj)
    self.MountPoint = obj.MountPoint
end

function TUmountReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TUmountReq.group)
end

TUmountReq.from_obj = TUmountReq_from_obj

TUmountReq.proto_property = {'MountPoint'}

TUmountReq.default = {''}

TUmountReq.struct = {{name = 'MountPoint', is_array = false, struct = nil}}

function TUmountReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'MountPoint', self.MountPoint, 'string', false, errs, need_convert)

    TUmountReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TUmountReq.proto_property, errs, need_convert)
    return self
end

function TUmountReq:unpack(_)
    return self.MountPoint
end

FileTransfer.UmountReq = TUmountReq

---@class FileTransfer.MountRsp
---@field Result integer
local TMountRsp = {}
TMountRsp.__index = TMountRsp
TMountRsp.group = {}

local function TMountRsp_from_obj(obj)
    return setmetatable(obj, TMountRsp)
end

function TMountRsp.new(Result)
    return TMountRsp_from_obj({Result = Result})
end
---@param obj FileTransfer.MountRsp
function TMountRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TMountRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMountRsp.group)
end

TMountRsp.from_obj = TMountRsp_from_obj

TMountRsp.proto_property = {'Result'}

TMountRsp.default = {0}

TMountRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TMountRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'int32', false, errs, need_convert)

    TMountRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMountRsp.proto_property, errs, need_convert)
    return self
end

function TMountRsp:unpack(_)
    return self.Result
end

FileTransfer.MountRsp = TMountRsp

---@class FileTransfer.MountReq
---@field Src string
---@field MountPoint string
local TMountReq = {}
TMountReq.__index = TMountReq
TMountReq.group = {}

local function TMountReq_from_obj(obj)
    return setmetatable(obj, TMountReq)
end

function TMountReq.new(Src, MountPoint)
    return TMountReq_from_obj({Src = Src, MountPoint = MountPoint})
end
---@param obj FileTransfer.MountReq
function TMountReq:init_from_obj(obj)
    self.Src = obj.Src
    self.MountPoint = obj.MountPoint
end

function TMountReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMountReq.group)
end

TMountReq.from_obj = TMountReq_from_obj

TMountReq.proto_property = {'Src', 'MountPoint'}

TMountReq.default = {'', ''}

TMountReq.struct = {
    {name = 'Src', is_array = false, struct = nil}, {name = 'MountPoint', is_array = false, struct = nil}
}

function TMountReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Src', self.Src, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'MountPoint', self.MountPoint, 'string', false, errs, need_convert)

    TMountReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMountReq.proto_property, errs, need_convert)
    return self
end

function TMountReq:unpack(_)
    return self.Src, self.MountPoint
end

FileTransfer.MountReq = TMountReq

---@class FileTransfer.StartTransferRsp
---@field TaskId integer
local TStartTransferRsp = {}
TStartTransferRsp.__index = TStartTransferRsp
TStartTransferRsp.group = {}

local function TStartTransferRsp_from_obj(obj)
    return setmetatable(obj, TStartTransferRsp)
end

function TStartTransferRsp.new(TaskId)
    return TStartTransferRsp_from_obj({TaskId = TaskId})
end
---@param obj FileTransfer.StartTransferRsp
function TStartTransferRsp:init_from_obj(obj)
    self.TaskId = obj.TaskId
end

function TStartTransferRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TStartTransferRsp.group)
end

TStartTransferRsp.from_obj = TStartTransferRsp_from_obj

TStartTransferRsp.proto_property = {'TaskId'}

TStartTransferRsp.default = {0}

TStartTransferRsp.struct = {{name = 'TaskId', is_array = false, struct = nil}}

function TStartTransferRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TStartTransferRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TStartTransferRsp.proto_property, errs, need_convert)
    return self
end

function TStartTransferRsp:unpack(_)
    return self.TaskId
end

FileTransfer.StartTransferRsp = TStartTransferRsp

---@class FileTransfer.StartTransferReq
---@field SrcUrl string
---@field TargetUrl string
---@field MaxLength integer
---@field Uid integer
---@field Gid integer
---@field Permission integer
local TStartTransferReq = {}
TStartTransferReq.__index = TStartTransferReq
TStartTransferReq.group = {}

local function TStartTransferReq_from_obj(obj)
    return setmetatable(obj, TStartTransferReq)
end

function TStartTransferReq.new(SrcUrl, TargetUrl, MaxLength, Uid, Gid, Permission)
    return TStartTransferReq_from_obj({
        SrcUrl = SrcUrl,
        TargetUrl = TargetUrl,
        MaxLength = MaxLength,
        Uid = Uid,
        Gid = Gid,
        Permission = Permission
    })
end
---@param obj FileTransfer.StartTransferReq
function TStartTransferReq:init_from_obj(obj)
    self.SrcUrl = obj.SrcUrl
    self.TargetUrl = obj.TargetUrl
    self.MaxLength = obj.MaxLength
    self.Uid = obj.Uid
    self.Gid = obj.Gid
    self.Permission = obj.Permission
end

function TStartTransferReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TStartTransferReq.group)
end

TStartTransferReq.from_obj = TStartTransferReq_from_obj

TStartTransferReq.proto_property = {'SrcUrl', 'TargetUrl', 'MaxLength', 'Uid', 'Gid', 'Permission'}

TStartTransferReq.default = {'', '', 0, 0, 0, 0}

TStartTransferReq.struct = {
    {name = 'SrcUrl', is_array = false, struct = nil}, {name = 'TargetUrl', is_array = false, struct = nil},
    {name = 'MaxLength', is_array = false, struct = nil}, {name = 'Uid', is_array = false, struct = nil},
    {name = 'Gid', is_array = false, struct = nil}, {name = 'Permission', is_array = false, struct = nil}
}

function TStartTransferReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SrcUrl', self.SrcUrl, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'TargetUrl', self.TargetUrl, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'MaxLength', self.MaxLength, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Uid', self.Uid, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Gid', self.Gid, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Permission', self.Permission, 'uint32', false, errs, need_convert)

    TStartTransferReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TStartTransferReq.proto_property, errs, need_convert)
    return self
end

function TStartTransferReq:unpack(_)
    return self.SrcUrl, self.TargetUrl, self.MaxLength, self.Uid, self.Gid, self.Permission
end

FileTransfer.StartTransferReq = TStartTransferReq

FileTransfer.interface = mdb.register_interface('bmc.kepler.Managers.FileTransfer',
    {HttpsTransferCertVerification = {'b', nil, false, nil}}, {
        StartTransfer = {'a{ss}ssuuuu', 'u', TStartTransferReq, TStartTransferRsp},
        Mount = {'a{ss}ss', 'i', TMountReq, TMountRsp},
        Umount = {'a{ss}s', 'i', TUmountReq, TUmountRsp}
    }, {})

return FileTransfer
