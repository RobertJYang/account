-- Copyright (c) 2026 Huawei Technologies Co., Ltd.
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

local File = {}

---@class File.TarRsp
local TTarRsp = {}
TTarRsp.__index = TTarRsp
TTarRsp.group = {}

local function TTarRsp_from_obj(obj)
    return setmetatable(obj, TTarRsp)
end

function TTarRsp.new()
    return TTarRsp_from_obj({})
end
---@param obj File.TarRsp
function TTarRsp:init_from_obj(obj)

end

function TTarRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TTarRsp.group)
end

TTarRsp.from_obj = TTarRsp_from_obj

TTarRsp.proto_property = {}

TTarRsp.default = {}

TTarRsp.struct = {}

function TTarRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TTarRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TTarRsp.proto_property, errs, need_convert)
    return self
end

function TTarRsp:unpack(_)
end

File.TarRsp = TTarRsp

---@class File.TarReq
---@field Mode string
---@field Options string
---@field Archive string
---@field WorkDir string
---@field Files string[]
local TTarReq = {}
TTarReq.__index = TTarReq
TTarReq.group = {}

local function TTarReq_from_obj(obj)
    return setmetatable(obj, TTarReq)
end

function TTarReq.new(Mode, Options, Archive, WorkDir, Files)
    return TTarReq_from_obj({Mode = Mode, Options = Options, Archive = Archive, WorkDir = WorkDir, Files = Files})
end
---@param obj File.TarReq
function TTarReq:init_from_obj(obj)
    self.Mode = obj.Mode
    self.Options = obj.Options
    self.Archive = obj.Archive
    self.WorkDir = obj.WorkDir
    self.Files = obj.Files
end

function TTarReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TTarReq.group)
end

TTarReq.from_obj = TTarReq_from_obj

TTarReq.proto_property = {'Mode', 'Options', 'Archive', 'WorkDir', 'Files'}

TTarReq.default = {'', '', '', '', {}}

TTarReq.struct = {
    {name = 'Mode', is_array = false, struct = nil}, {name = 'Options', is_array = false, struct = nil},
    {name = 'Archive', is_array = false, struct = nil}, {name = 'WorkDir', is_array = false, struct = nil},
    {name = 'Files', is_array = true, struct = nil}
}

function TTarReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Mode', self.Mode, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Options', self.Options, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Archive', self.Archive, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'WorkDir', self.WorkDir, 'string', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'Files', self.Files, 'string', false, errs, need_convert)

    TTarReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TTarReq.proto_property, errs, need_convert)
    return self
end

function TTarReq:unpack(_)
    return self.Mode, self.Options, self.Archive, self.WorkDir, self.Files
end

File.TarReq = TTarReq

---@class File.MkdirRsp
local TMkdirRsp = {}
TMkdirRsp.__index = TMkdirRsp
TMkdirRsp.group = {}

local function TMkdirRsp_from_obj(obj)
    return setmetatable(obj, TMkdirRsp)
end

function TMkdirRsp.new()
    return TMkdirRsp_from_obj({})
end
---@param obj File.MkdirRsp
function TMkdirRsp:init_from_obj(obj)

end

function TMkdirRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMkdirRsp.group)
end

TMkdirRsp.from_obj = TMkdirRsp_from_obj

TMkdirRsp.proto_property = {}

TMkdirRsp.default = {}

TMkdirRsp.struct = {}

function TMkdirRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TMkdirRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMkdirRsp.proto_property, errs, need_convert)
    return self
end

function TMkdirRsp:unpack(_)
end

File.MkdirRsp = TMkdirRsp

---@class File.MkdirReq
---@field DstDir string
---@field DirMode integer
---@field Uid integer
---@field Gid integer
---@field Parents boolean
local TMkdirReq = {}
TMkdirReq.__index = TMkdirReq
TMkdirReq.group = {}

local function TMkdirReq_from_obj(obj)
    return setmetatable(obj, TMkdirReq)
end

function TMkdirReq.new(DstDir, DirMode, Uid, Gid, Parents)
    return TMkdirReq_from_obj({DstDir = DstDir, DirMode = DirMode, Uid = Uid, Gid = Gid, Parents = Parents})
end
---@param obj File.MkdirReq
function TMkdirReq:init_from_obj(obj)
    self.DstDir = obj.DstDir
    self.DirMode = obj.DirMode
    self.Uid = obj.Uid
    self.Gid = obj.Gid
    self.Parents = obj.Parents
end

function TMkdirReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMkdirReq.group)
end

TMkdirReq.from_obj = TMkdirReq_from_obj

TMkdirReq.proto_property = {'DstDir', 'DirMode', 'Uid', 'Gid', 'Parents'}

TMkdirReq.default = {'', 0, 0, 0, false}

TMkdirReq.struct = {
    {name = 'DstDir', is_array = false, struct = nil}, {name = 'DirMode', is_array = false, struct = nil},
    {name = 'Uid', is_array = false, struct = nil}, {name = 'Gid', is_array = false, struct = nil},
    {name = 'Parents', is_array = false, struct = nil}
}

function TMkdirReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DstDir', self.DstDir, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'DirMode', self.DirMode, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Uid', self.Uid, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Gid', self.Gid, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Parents', self.Parents, 'bool', false, errs, need_convert)

    TMkdirReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMkdirReq.proto_property, errs, need_convert)
    return self
end

function TMkdirReq:unpack(_)
    return self.DstDir, self.DirMode, self.Uid, self.Gid, self.Parents
end

File.MkdirReq = TMkdirReq

---@class File.AccessRsp
---@field Result boolean
local TAccessRsp = {}
TAccessRsp.__index = TAccessRsp
TAccessRsp.group = {}

local function TAccessRsp_from_obj(obj)
    return setmetatable(obj, TAccessRsp)
end

function TAccessRsp.new(Result)
    return TAccessRsp_from_obj({Result = Result})
end
---@param obj File.AccessRsp
function TAccessRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TAccessRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccessRsp.group)
end

TAccessRsp.from_obj = TAccessRsp_from_obj

TAccessRsp.proto_property = {'Result'}

TAccessRsp.default = {false}

TAccessRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TAccessRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TAccessRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccessRsp.proto_property, errs, need_convert)
    return self
end

function TAccessRsp:unpack(_)
    return self.Result
end

File.AccessRsp = TAccessRsp

---@class File.AccessReq
---@field Path string
---@field Mode integer
local TAccessReq = {}
TAccessReq.__index = TAccessReq
TAccessReq.group = {}

local function TAccessReq_from_obj(obj)
    return setmetatable(obj, TAccessReq)
end

function TAccessReq.new(Path, Mode)
    return TAccessReq_from_obj({Path = Path, Mode = Mode})
end
---@param obj File.AccessReq
function TAccessReq:init_from_obj(obj)
    self.Path = obj.Path
    self.Mode = obj.Mode
end

function TAccessReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TAccessReq.group)
end

TAccessReq.from_obj = TAccessReq_from_obj

TAccessReq.proto_property = {'Path', 'Mode'}

TAccessReq.default = {'', 0}

TAccessReq.struct = {{name = 'Path', is_array = false, struct = nil}, {name = 'Mode', is_array = false, struct = nil}}

function TAccessReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Path', self.Path, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Mode', self.Mode, 'uint8', false, errs, need_convert)

    if self.Mode ~= nil then
        validate.ranges(prefix .. 'Mode', self.Mode, 0, 7, errs, need_convert)
    end

    TAccessReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TAccessReq.proto_property, errs, need_convert)
    return self
end

function TAccessReq:unpack(_)
    return self.Path, self.Mode
end

File.AccessReq = TAccessReq

---@class File.IsPermittedRsp
---@field Result boolean
local TIsPermittedRsp = {}
TIsPermittedRsp.__index = TIsPermittedRsp
TIsPermittedRsp.group = {}

local function TIsPermittedRsp_from_obj(obj)
    return setmetatable(obj, TIsPermittedRsp)
end

function TIsPermittedRsp.new(Result)
    return TIsPermittedRsp_from_obj({Result = Result})
end
---@param obj File.IsPermittedRsp
function TIsPermittedRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TIsPermittedRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIsPermittedRsp.group)
end

TIsPermittedRsp.from_obj = TIsPermittedRsp_from_obj

TIsPermittedRsp.proto_property = {'Result'}

TIsPermittedRsp.default = {false}

TIsPermittedRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TIsPermittedRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TIsPermittedRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIsPermittedRsp.proto_property, errs, need_convert)
    return self
end

function TIsPermittedRsp:unpack(_)
    return self.Result
end

File.IsPermittedRsp = TIsPermittedRsp

---@class File.IsPermittedReq
---@field DstFile string
---@field Permission string
local TIsPermittedReq = {}
TIsPermittedReq.__index = TIsPermittedReq
TIsPermittedReq.group = {}

local function TIsPermittedReq_from_obj(obj)
    return setmetatable(obj, TIsPermittedReq)
end

function TIsPermittedReq.new(DstFile, Permission)
    return TIsPermittedReq_from_obj({DstFile = DstFile, Permission = Permission})
end
---@param obj File.IsPermittedReq
function TIsPermittedReq:init_from_obj(obj)
    self.DstFile = obj.DstFile
    self.Permission = obj.Permission
end

function TIsPermittedReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TIsPermittedReq.group)
end

TIsPermittedReq.from_obj = TIsPermittedReq_from_obj

TIsPermittedReq.proto_property = {'DstFile', 'Permission'}

TIsPermittedReq.default = {'', ''}

TIsPermittedReq.struct = {
    {name = 'DstFile', is_array = false, struct = nil}, {name = 'Permission', is_array = false, struct = nil}
}

function TIsPermittedReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DstFile', self.DstFile, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Permission', self.Permission, 'string', false, errs, need_convert)

    TIsPermittedReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TIsPermittedReq.proto_property, errs, need_convert)
    return self
end

function TIsPermittedReq:unpack(_)
    return self.DstFile, self.Permission
end

File.IsPermittedReq = TIsPermittedReq

---@class File.ChangeOwnerRsp
---@field Result boolean
local TChangeOwnerRsp = {}
TChangeOwnerRsp.__index = TChangeOwnerRsp
TChangeOwnerRsp.group = {}

local function TChangeOwnerRsp_from_obj(obj)
    return setmetatable(obj, TChangeOwnerRsp)
end

function TChangeOwnerRsp.new(Result)
    return TChangeOwnerRsp_from_obj({Result = Result})
end
---@param obj File.ChangeOwnerRsp
function TChangeOwnerRsp:init_from_obj(obj)
    self.Result = obj.Result
end

function TChangeOwnerRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TChangeOwnerRsp.group)
end

TChangeOwnerRsp.from_obj = TChangeOwnerRsp_from_obj

TChangeOwnerRsp.proto_property = {'Result'}

TChangeOwnerRsp.default = {false}

TChangeOwnerRsp.struct = {{name = 'Result', is_array = false, struct = nil}}

function TChangeOwnerRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Result', self.Result, 'bool', false, errs, need_convert)

    TChangeOwnerRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TChangeOwnerRsp.proto_property, errs, need_convert)
    return self
end

function TChangeOwnerRsp:unpack(_)
    return self.Result
end

File.ChangeOwnerRsp = TChangeOwnerRsp

---@class File.ChangeOwnerReq
---@field DstFile string
local TChangeOwnerReq = {}
TChangeOwnerReq.__index = TChangeOwnerReq
TChangeOwnerReq.group = {}

local function TChangeOwnerReq_from_obj(obj)
    return setmetatable(obj, TChangeOwnerReq)
end

function TChangeOwnerReq.new(DstFile)
    return TChangeOwnerReq_from_obj({DstFile = DstFile})
end
---@param obj File.ChangeOwnerReq
function TChangeOwnerReq:init_from_obj(obj)
    self.DstFile = obj.DstFile
end

function TChangeOwnerReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TChangeOwnerReq.group)
end

TChangeOwnerReq.from_obj = TChangeOwnerReq_from_obj

TChangeOwnerReq.proto_property = {'DstFile'}

TChangeOwnerReq.default = {''}

TChangeOwnerReq.struct = {{name = 'DstFile', is_array = false, struct = nil}}

function TChangeOwnerReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DstFile', self.DstFile, 'string', false, errs, need_convert)

    TChangeOwnerReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TChangeOwnerReq.proto_property, errs, need_convert)
    return self
end

function TChangeOwnerReq:unpack(_)
    return self.DstFile
end

File.ChangeOwnerReq = TChangeOwnerReq

---@class File.CreateRsp
local TCreateRsp = {}
TCreateRsp.__index = TCreateRsp
TCreateRsp.group = {}

local function TCreateRsp_from_obj(obj)
    return setmetatable(obj, TCreateRsp)
end

function TCreateRsp.new()
    return TCreateRsp_from_obj({})
end
---@param obj File.CreateRsp
function TCreateRsp:init_from_obj(obj)

end

function TCreateRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TCreateRsp.group)
end

TCreateRsp.from_obj = TCreateRsp_from_obj

TCreateRsp.proto_property = {}

TCreateRsp.default = {}

TCreateRsp.struct = {}

function TCreateRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TCreateRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TCreateRsp.proto_property, errs, need_convert)
    return self
end

function TCreateRsp:unpack(_)
end

File.CreateRsp = TCreateRsp

---@class File.CreateReq
---@field DstFile string
---@field OpenMode string
---@field FileMode integer
---@field Uid integer
---@field Gid integer
local TCreateReq = {}
TCreateReq.__index = TCreateReq
TCreateReq.group = {}

local function TCreateReq_from_obj(obj)
    return setmetatable(obj, TCreateReq)
end

function TCreateReq.new(DstFile, OpenMode, FileMode, Uid, Gid)
    return TCreateReq_from_obj({DstFile = DstFile, OpenMode = OpenMode, FileMode = FileMode, Uid = Uid, Gid = Gid})
end
---@param obj File.CreateReq
function TCreateReq:init_from_obj(obj)
    self.DstFile = obj.DstFile
    self.OpenMode = obj.OpenMode
    self.FileMode = obj.FileMode
    self.Uid = obj.Uid
    self.Gid = obj.Gid
end

function TCreateReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TCreateReq.group)
end

TCreateReq.from_obj = TCreateReq_from_obj

TCreateReq.proto_property = {'DstFile', 'OpenMode', 'FileMode', 'Uid', 'Gid'}

TCreateReq.default = {'', '', 0, 0, 0}

TCreateReq.struct = {
    {name = 'DstFile', is_array = false, struct = nil}, {name = 'OpenMode', is_array = false, struct = nil},
    {name = 'FileMode', is_array = false, struct = nil}, {name = 'Uid', is_array = false, struct = nil},
    {name = 'Gid', is_array = false, struct = nil}
}

function TCreateReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DstFile', self.DstFile, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'OpenMode', self.OpenMode, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'FileMode', self.FileMode, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Uid', self.Uid, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Gid', self.Gid, 'uint32', false, errs, need_convert)

    TCreateReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TCreateReq.proto_property, errs, need_convert)
    return self
end

function TCreateReq:unpack(_)
    return self.DstFile, self.OpenMode, self.FileMode, self.Uid, self.Gid
end

File.CreateReq = TCreateReq

---@class File.DeleteRsp
local TDeleteRsp = {}
TDeleteRsp.__index = TDeleteRsp
TDeleteRsp.group = {}

local function TDeleteRsp_from_obj(obj)
    return setmetatable(obj, TDeleteRsp)
end

function TDeleteRsp.new()
    return TDeleteRsp_from_obj({})
end
---@param obj File.DeleteRsp
function TDeleteRsp:init_from_obj(obj)

end

function TDeleteRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteRsp.group)
end

TDeleteRsp.from_obj = TDeleteRsp_from_obj

TDeleteRsp.proto_property = {}

TDeleteRsp.default = {}

TDeleteRsp.struct = {}

function TDeleteRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TDeleteRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteRsp.proto_property, errs, need_convert)
    return self
end

function TDeleteRsp:unpack(_)
end

File.DeleteRsp = TDeleteRsp

---@class File.DeleteReq
---@field DstFile string
local TDeleteReq = {}
TDeleteReq.__index = TDeleteReq
TDeleteReq.group = {}

local function TDeleteReq_from_obj(obj)
    return setmetatable(obj, TDeleteReq)
end

function TDeleteReq.new(DstFile)
    return TDeleteReq_from_obj({DstFile = DstFile})
end
---@param obj File.DeleteReq
function TDeleteReq:init_from_obj(obj)
    self.DstFile = obj.DstFile
end

function TDeleteReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteReq.group)
end

TDeleteReq.from_obj = TDeleteReq_from_obj

TDeleteReq.proto_property = {'DstFile'}

TDeleteReq.default = {''}

TDeleteReq.struct = {{name = 'DstFile', is_array = false, struct = nil}}

function TDeleteReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DstFile', self.DstFile, 'string', false, errs, need_convert)

    TDeleteReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteReq.proto_property, errs, need_convert)
    return self
end

function TDeleteReq:unpack(_)
    return self.DstFile
end

File.DeleteReq = TDeleteReq

---@class File.ChownRsp
local TChownRsp = {}
TChownRsp.__index = TChownRsp
TChownRsp.group = {}

local function TChownRsp_from_obj(obj)
    return setmetatable(obj, TChownRsp)
end

function TChownRsp.new()
    return TChownRsp_from_obj({})
end
---@param obj File.ChownRsp
function TChownRsp:init_from_obj(obj)

end

function TChownRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TChownRsp.group)
end

TChownRsp.from_obj = TChownRsp_from_obj

TChownRsp.proto_property = {}

TChownRsp.default = {}

TChownRsp.struct = {}

function TChownRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TChownRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TChownRsp.proto_property, errs, need_convert)
    return self
end

function TChownRsp:unpack(_)
end

File.ChownRsp = TChownRsp

---@class File.ChownReq
---@field DstFile string
---@field Uid integer
---@field Gid integer
local TChownReq = {}
TChownReq.__index = TChownReq
TChownReq.group = {}

local function TChownReq_from_obj(obj)
    return setmetatable(obj, TChownReq)
end

function TChownReq.new(DstFile, Uid, Gid)
    return TChownReq_from_obj({DstFile = DstFile, Uid = Uid, Gid = Gid})
end
---@param obj File.ChownReq
function TChownReq:init_from_obj(obj)
    self.DstFile = obj.DstFile
    self.Uid = obj.Uid
    self.Gid = obj.Gid
end

function TChownReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TChownReq.group)
end

TChownReq.from_obj = TChownReq_from_obj

TChownReq.proto_property = {'DstFile', 'Uid', 'Gid'}

TChownReq.default = {'', 0, 0}

TChownReq.struct = {
    {name = 'DstFile', is_array = false, struct = nil}, {name = 'Uid', is_array = false, struct = nil},
    {name = 'Gid', is_array = false, struct = nil}
}

function TChownReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DstFile', self.DstFile, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Uid', self.Uid, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Gid', self.Gid, 'uint32', false, errs, need_convert)

    TChownReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TChownReq.proto_property, errs, need_convert)
    return self
end

function TChownReq:unpack(_)
    return self.DstFile, self.Uid, self.Gid
end

File.ChownReq = TChownReq

---@class File.ChmodRsp
local TChmodRsp = {}
TChmodRsp.__index = TChmodRsp
TChmodRsp.group = {}

local function TChmodRsp_from_obj(obj)
    return setmetatable(obj, TChmodRsp)
end

function TChmodRsp.new()
    return TChmodRsp_from_obj({})
end
---@param obj File.ChmodRsp
function TChmodRsp:init_from_obj(obj)

end

function TChmodRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TChmodRsp.group)
end

TChmodRsp.from_obj = TChmodRsp_from_obj

TChmodRsp.proto_property = {}

TChmodRsp.default = {}

TChmodRsp.struct = {}

function TChmodRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TChmodRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TChmodRsp.proto_property, errs, need_convert)
    return self
end

function TChmodRsp:unpack(_)
end

File.ChmodRsp = TChmodRsp

---@class File.ChmodReq
---@field DstFile string
---@field FileMode integer
local TChmodReq = {}
TChmodReq.__index = TChmodReq
TChmodReq.group = {}

local function TChmodReq_from_obj(obj)
    return setmetatable(obj, TChmodReq)
end

function TChmodReq.new(DstFile, FileMode)
    return TChmodReq_from_obj({DstFile = DstFile, FileMode = FileMode})
end
---@param obj File.ChmodReq
function TChmodReq:init_from_obj(obj)
    self.DstFile = obj.DstFile
    self.FileMode = obj.FileMode
end

function TChmodReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TChmodReq.group)
end

TChmodReq.from_obj = TChmodReq_from_obj

TChmodReq.proto_property = {'DstFile', 'FileMode'}

TChmodReq.default = {'', 0}

TChmodReq.struct = {
    {name = 'DstFile', is_array = false, struct = nil}, {name = 'FileMode', is_array = false, struct = nil}
}

function TChmodReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'DstFile', self.DstFile, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'FileMode', self.FileMode, 'uint32', false, errs, need_convert)

    TChmodReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TChmodReq.proto_property, errs, need_convert)
    return self
end

function TChmodReq:unpack(_)
    return self.DstFile, self.FileMode
end

File.ChmodReq = TChmodReq

---@class File.MoveRsp
local TMoveRsp = {}
TMoveRsp.__index = TMoveRsp
TMoveRsp.group = {}

local function TMoveRsp_from_obj(obj)
    return setmetatable(obj, TMoveRsp)
end

function TMoveRsp.new()
    return TMoveRsp_from_obj({})
end
---@param obj File.MoveRsp
function TMoveRsp:init_from_obj(obj)

end

function TMoveRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMoveRsp.group)
end

TMoveRsp.from_obj = TMoveRsp_from_obj

TMoveRsp.proto_property = {}

TMoveRsp.default = {}

TMoveRsp.struct = {}

function TMoveRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TMoveRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMoveRsp.proto_property, errs, need_convert)
    return self
end

function TMoveRsp:unpack(_)
end

File.MoveRsp = TMoveRsp

---@class File.MoveReq
---@field SrcFile string
---@field DstFile string
---@field Uid integer
---@field Gid integer
local TMoveReq = {}
TMoveReq.__index = TMoveReq
TMoveReq.group = {}

local function TMoveReq_from_obj(obj)
    return setmetatable(obj, TMoveReq)
end

function TMoveReq.new(SrcFile, DstFile, Uid, Gid)
    return TMoveReq_from_obj({SrcFile = SrcFile, DstFile = DstFile, Uid = Uid, Gid = Gid})
end
---@param obj File.MoveReq
function TMoveReq:init_from_obj(obj)
    self.SrcFile = obj.SrcFile
    self.DstFile = obj.DstFile
    self.Uid = obj.Uid
    self.Gid = obj.Gid
end

function TMoveReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TMoveReq.group)
end

TMoveReq.from_obj = TMoveReq_from_obj

TMoveReq.proto_property = {'SrcFile', 'DstFile', 'Uid', 'Gid'}

TMoveReq.default = {'', '', 0, 0}

TMoveReq.struct = {
    {name = 'SrcFile', is_array = false, struct = nil}, {name = 'DstFile', is_array = false, struct = nil},
    {name = 'Uid', is_array = false, struct = nil}, {name = 'Gid', is_array = false, struct = nil}
}

function TMoveReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SrcFile', self.SrcFile, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'DstFile', self.DstFile, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Uid', self.Uid, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Gid', self.Gid, 'uint32', false, errs, need_convert)

    TMoveReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TMoveReq.proto_property, errs, need_convert)
    return self
end

function TMoveReq:unpack(_)
    return self.SrcFile, self.DstFile, self.Uid, self.Gid
end

File.MoveReq = TMoveReq

---@class File.CopyRsp
local TCopyRsp = {}
TCopyRsp.__index = TCopyRsp
TCopyRsp.group = {}

local function TCopyRsp_from_obj(obj)
    return setmetatable(obj, TCopyRsp)
end

function TCopyRsp.new()
    return TCopyRsp_from_obj({})
end
---@param obj File.CopyRsp
function TCopyRsp:init_from_obj(obj)

end

function TCopyRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TCopyRsp.group)
end

TCopyRsp.from_obj = TCopyRsp_from_obj

TCopyRsp.proto_property = {}

TCopyRsp.default = {}

TCopyRsp.struct = {}

function TCopyRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TCopyRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TCopyRsp.proto_property, errs, need_convert)
    return self
end

function TCopyRsp:unpack(_)
end

File.CopyRsp = TCopyRsp

---@class File.CopyReq
---@field SrcFile string
---@field DstFile string
---@field Uid integer
---@field Gid integer
local TCopyReq = {}
TCopyReq.__index = TCopyReq
TCopyReq.group = {}

local function TCopyReq_from_obj(obj)
    return setmetatable(obj, TCopyReq)
end

function TCopyReq.new(SrcFile, DstFile, Uid, Gid)
    return TCopyReq_from_obj({SrcFile = SrcFile, DstFile = DstFile, Uid = Uid, Gid = Gid})
end
---@param obj File.CopyReq
function TCopyReq:init_from_obj(obj)
    self.SrcFile = obj.SrcFile
    self.DstFile = obj.DstFile
    self.Uid = obj.Uid
    self.Gid = obj.Gid
end

function TCopyReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TCopyReq.group)
end

TCopyReq.from_obj = TCopyReq_from_obj

TCopyReq.proto_property = {'SrcFile', 'DstFile', 'Uid', 'Gid'}

TCopyReq.default = {'', '', 0, 0}

TCopyReq.struct = {
    {name = 'SrcFile', is_array = false, struct = nil}, {name = 'DstFile', is_array = false, struct = nil},
    {name = 'Uid', is_array = false, struct = nil}, {name = 'Gid', is_array = false, struct = nil}
}

function TCopyReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'SrcFile', self.SrcFile, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'DstFile', self.DstFile, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Uid', self.Uid, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'Gid', self.Gid, 'uint32', false, errs, need_convert)

    TCopyReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TCopyReq.proto_property, errs, need_convert)
    return self
end

function TCopyReq:unpack(_)
    return self.SrcFile, self.DstFile, self.Uid, self.Gid
end

File.CopyReq = TCopyReq

File.interface = mdb.register_interface('bmc.kepler.Managers.Security.File', {}, {
    Copy = {'a{ss}ssuu', '', TCopyReq, TCopyRsp},
    Move = {'a{ss}ssuu', '', TMoveReq, TMoveRsp},
    Chmod = {'a{ss}su', '', TChmodReq, TChmodRsp},
    Chown = {'a{ss}suu', '', TChownReq, TChownRsp},
    Delete = {'a{ss}s', '', TDeleteReq, TDeleteRsp},
    Create = {'a{ss}ssuuu', '', TCreateReq, TCreateRsp},
    ChangeOwner = {'a{ss}s', 'b', TChangeOwnerReq, TChangeOwnerRsp},
    IsPermitted = {'a{ss}ss', 'b', TIsPermittedReq, TIsPermittedRsp},
    Access = {'a{ss}sy', 'b', TAccessReq, TAccessRsp},
    Mkdir = {'a{ss}suuub', '', TMkdirReq, TMkdirRsp},
    Tar = {'a{ss}ssssas', '', TTarReq, TTarRsp}
}, {})

return File
