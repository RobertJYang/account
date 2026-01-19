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
local create_enum_type = require 'mc.enum'

local CertificateService = {}

---@class CertificateService.CertTaskStatus: Enum
local ECertTaskStatus = create_enum_type('CertTaskStatus')
ECertTaskStatus.default = ECertTaskStatus.new(2147483647)
ECertTaskStatus.struct = nil
ECertTaskStatus.NotStart = ECertTaskStatus.new(1)
ECertTaskStatus.Running = ECertTaskStatus.new(2)
ECertTaskStatus.Failed = ECertTaskStatus.new(3)
ECertTaskStatus.Success = ECertTaskStatus.new(4)

CertificateService.CertTaskStatus = ECertTaskStatus

---@class CertificateService.CertInChainType: Enum
local ECertInChainType = create_enum_type('CertInChainType')
ECertInChainType.default = ECertInChainType.new(2147483647)
ECertInChainType.struct = nil
ECertInChainType.Root = ECertInChainType.new(0)
ECertInChainType.Intermediate = ECertInChainType.new(1)
ECertInChainType.Last = ECertInChainType.new(2)

CertificateService.CertInChainType = ECertInChainType

---@class CertificateService.CertAlgorithm: Enum
local ECertAlgorithm = create_enum_type('CertAlgorithm')
ECertAlgorithm.default = ECertAlgorithm.new(2147483647)
ECertAlgorithm.struct = nil
ECertAlgorithm.RSA = ECertAlgorithm.new(0)
ECertAlgorithm.ECC = ECertAlgorithm.new(1)
ECertAlgorithm.SM2 = ECertAlgorithm.new(2)

CertificateService.CertAlgorithm = ECertAlgorithm

---@class CertificateService.CertificateUsageType: Enum
local ECertificateUsageType = create_enum_type('CertificateUsageType')
ECertificateUsageType.default = ECertificateUsageType.new(2147483647)
ECertificateUsageType.struct = nil
ECertificateUsageType.ManagerCACertificate = ECertificateUsageType.new(0)
ECertificateUsageType.ManagerSSLCertificate = ECertificateUsageType.new(1)
ECertificateUsageType.ManagerAccountCertificate = ECertificateUsageType.new(2)
ECertificateUsageType.ManagerCMPCertificate = ECertificateUsageType.new(3)
ECertificateUsageType.ManagerFirmwareCertificate = ECertificateUsageType.new(4)

CertificateService.CertificateUsageType = ECertificateUsageType

---@class CertificateService.KeyUsage: Enum
local EKeyUsage = create_enum_type('KeyUsage')
EKeyUsage.default = EKeyUsage.new(2147483647)
EKeyUsage.struct = nil
EKeyUsage.DigitalSignature = EKeyUsage.new(0)
EKeyUsage.NonRepudiation = EKeyUsage.new(1)
EKeyUsage.KeyEncipherment = EKeyUsage.new(2)
EKeyUsage.DataEncipherment = EKeyUsage.new(3)
EKeyUsage.KeyAgreement = EKeyUsage.new(4)
EKeyUsage.KeyCertSign = EKeyUsage.new(5)
EKeyUsage.CRLSigning = EKeyUsage.new(6)
EKeyUsage.EncipherOnly = EKeyUsage.new(7)
EKeyUsage.DecipherOnly = EKeyUsage.new(8)
EKeyUsage.ServerAuthentication = EKeyUsage.new(9)
EKeyUsage.ClientAuthentication = EKeyUsage.new(10)
EKeyUsage.CodeSigning = EKeyUsage.new(11)
EKeyUsage.EmailProtection = EKeyUsage.new(12)
EKeyUsage.Timestamping = EKeyUsage.new(13)
EKeyUsage.OCSPSigning = EKeyUsage.new(14)

CertificateService.KeyUsage = EKeyUsage

---@class CertificateService.CertificateType: Enum
local ECertificateType = create_enum_type('CertificateType')
ECertificateType.default = ECertificateType.new(2147483647)
ECertificateType.struct = nil
ECertificateType.PEM = ECertificateType.new(0)
ECertificateType.PEMchain = ECertificateType.new(1)
ECertificateType.PKCS7 = ECertificateType.new(2)

CertificateService.CertificateType = ECertificateType

---@class CertificateService.Extra
---@field key string
---@field value string
local TExtra = {}
TExtra.__index = TExtra
TExtra.group = {}

local function TExtra_from_obj(obj)
    return setmetatable(obj, TExtra)
end

function TExtra.new(dict)
    return TExtra_from_obj(dict)
end

---@param obj CertificateService.Extra
function TExtra:init_from_obj(obj)
    self = obj
end

function TExtra:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExtra.group)
end

TExtra.from_obj = TExtra_from_obj

TExtra.proto_property = {}

TExtra.default = {}

TExtra.struct = {}

function TExtra:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for k, v in pairs(self) do

        validate.Optional(prefix .. 'key', k, 'string', false, errs, need_convert)

        validate.Optional(prefix .. 'value', v, 'string', false, errs, need_convert)

    end

    TExtra:remove_error_props(errs, self)
    return self
end

function TExtra:unpack(_)
    return self
end

CertificateService.Extra = TExtra

---@class CertificateService.CSRProperty
---@field key string
---@field value string
local TCSRProperty = {}
TCSRProperty.__index = TCSRProperty
TCSRProperty.group = {}

local function TCSRProperty_from_obj(obj)
    return setmetatable(obj, TCSRProperty)
end

function TCSRProperty.new(dict)
    return TCSRProperty_from_obj(dict)
end

---@param obj CertificateService.CSRProperty
function TCSRProperty:init_from_obj(obj)
    self = obj
end

function TCSRProperty:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TCSRProperty.group)
end

TCSRProperty.from_obj = TCSRProperty_from_obj

TCSRProperty.proto_property = {}

TCSRProperty.default = {}

TCSRProperty.struct = {}

function TCSRProperty:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    for k, v in pairs(self) do

        validate.Optional(prefix .. 'key', k, 'string', false, errs, need_convert)

        validate.Optional(prefix .. 'value', v, 'string', false, errs, need_convert)

    end

    TCSRProperty:remove_error_props(errs, self)
    return self
end

function TCSRProperty:unpack(_)
    return self
end

CertificateService.CSRProperty = TCSRProperty

---@class CertificateService.BackupCertificateRsp
local TBackupCertificateRsp = {}
TBackupCertificateRsp.__index = TBackupCertificateRsp
TBackupCertificateRsp.group = {}

local function TBackupCertificateRsp_from_obj(obj)
    return setmetatable(obj, TBackupCertificateRsp)
end

function TBackupCertificateRsp.new()
    return TBackupCertificateRsp_from_obj({})
end
---@param obj CertificateService.BackupCertificateRsp
function TBackupCertificateRsp:init_from_obj(obj)

end

function TBackupCertificateRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TBackupCertificateRsp.group)
end

TBackupCertificateRsp.from_obj = TBackupCertificateRsp_from_obj

TBackupCertificateRsp.proto_property = {}

TBackupCertificateRsp.default = {}

TBackupCertificateRsp.struct = {}

function TBackupCertificateRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TBackupCertificateRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TBackupCertificateRsp.proto_property, errs, need_convert)
    return self
end

function TBackupCertificateRsp:unpack(_)
end

CertificateService.BackupCertificateRsp = TBackupCertificateRsp

---@class CertificateService.BackupCertificateReq
---@field Usage string
---@field Certificates string[]
local TBackupCertificateReq = {}
TBackupCertificateReq.__index = TBackupCertificateReq
TBackupCertificateReq.group = {}

local function TBackupCertificateReq_from_obj(obj)
    return setmetatable(obj, TBackupCertificateReq)
end

function TBackupCertificateReq.new(Usage, Certificates)
    return TBackupCertificateReq_from_obj({Usage = Usage, Certificates = Certificates})
end
---@param obj CertificateService.BackupCertificateReq
function TBackupCertificateReq:init_from_obj(obj)
    self.Usage = obj.Usage
    self.Certificates = obj.Certificates
end

function TBackupCertificateReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TBackupCertificateReq.group)
end

TBackupCertificateReq.from_obj = TBackupCertificateReq_from_obj

TBackupCertificateReq.proto_property = {'Usage', 'Certificates'}

TBackupCertificateReq.default = {'', {}}

TBackupCertificateReq.struct = {
    {name = 'Usage', is_array = false, struct = nil}, {name = 'Certificates', is_array = true, struct = nil}
}

function TBackupCertificateReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Usage', self.Usage, 'string', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'Certificates', self.Certificates, 'string', false, errs, need_convert)

    TBackupCertificateReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TBackupCertificateReq.proto_property, errs, need_convert)
    return self
end

function TBackupCertificateReq:unpack(_)
    return self.Usage, self.Certificates
end

CertificateService.BackupCertificateReq = TBackupCertificateReq

---@class CertificateService.SetCSRPropertyRsp
local TSetCSRPropertyRsp = {}
TSetCSRPropertyRsp.__index = TSetCSRPropertyRsp
TSetCSRPropertyRsp.group = {}

local function TSetCSRPropertyRsp_from_obj(obj)
    return setmetatable(obj, TSetCSRPropertyRsp)
end

function TSetCSRPropertyRsp.new()
    return TSetCSRPropertyRsp_from_obj({})
end
---@param obj CertificateService.SetCSRPropertyRsp
function TSetCSRPropertyRsp:init_from_obj(obj)

end

function TSetCSRPropertyRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetCSRPropertyRsp.group)
end

TSetCSRPropertyRsp.from_obj = TSetCSRPropertyRsp_from_obj

TSetCSRPropertyRsp.proto_property = {}

TSetCSRPropertyRsp.default = {}

TSetCSRPropertyRsp.struct = {}

function TSetCSRPropertyRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetCSRPropertyRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetCSRPropertyRsp.proto_property, errs, need_convert)
    return self
end

function TSetCSRPropertyRsp:unpack(_)
end

CertificateService.SetCSRPropertyRsp = TSetCSRPropertyRsp

---@class CertificateService.SetCSRPropertyReq
---@field Property CertificateService.CSRProperty
local TSetCSRPropertyReq = {}
TSetCSRPropertyReq.__index = TSetCSRPropertyReq
TSetCSRPropertyReq.group = {}

local function TSetCSRPropertyReq_from_obj(obj)
    return setmetatable(obj, TSetCSRPropertyReq)
end

function TSetCSRPropertyReq.new(Property)
    return TSetCSRPropertyReq_from_obj({Property = Property})
end
---@param obj CertificateService.SetCSRPropertyReq
function TSetCSRPropertyReq:init_from_obj(obj)
    self.Property = obj.Property
end

function TSetCSRPropertyReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetCSRPropertyReq.group)
end

TSetCSRPropertyReq.from_obj = TSetCSRPropertyReq_from_obj

TSetCSRPropertyReq.proto_property = {'Property'}

TSetCSRPropertyReq.default = {CertificateService.CSRProperty.default}

TSetCSRPropertyReq.struct = {{name = 'Property', is_array = false, struct = CertificateService.CSRProperty.struct}}

function TSetCSRPropertyReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    CertificateService.CSRProperty.new(self.Property):validate(prefix, errs, need_convert)

    TSetCSRPropertyReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetCSRPropertyReq.proto_property, errs, need_convert)
    return self
end

function TSetCSRPropertyReq:unpack(_)
    return self.Property
end

CertificateService.SetCSRPropertyReq = TSetCSRPropertyReq

---@class CertificateService.GetCSRPropertyRsp
---@field Value string
local TGetCSRPropertyRsp = {}
TGetCSRPropertyRsp.__index = TGetCSRPropertyRsp
TGetCSRPropertyRsp.group = {}

local function TGetCSRPropertyRsp_from_obj(obj)
    return setmetatable(obj, TGetCSRPropertyRsp)
end

function TGetCSRPropertyRsp.new(Value)
    return TGetCSRPropertyRsp_from_obj({Value = Value})
end
---@param obj CertificateService.GetCSRPropertyRsp
function TGetCSRPropertyRsp:init_from_obj(obj)
    self.Value = obj.Value
end

function TGetCSRPropertyRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCSRPropertyRsp.group)
end

TGetCSRPropertyRsp.from_obj = TGetCSRPropertyRsp_from_obj

TGetCSRPropertyRsp.proto_property = {'Value'}

TGetCSRPropertyRsp.default = {''}

TGetCSRPropertyRsp.struct = {{name = 'Value', is_array = false, struct = nil}}

function TGetCSRPropertyRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Value', self.Value, 'string', false, errs, need_convert)

    TGetCSRPropertyRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCSRPropertyRsp.proto_property, errs, need_convert)
    return self
end

function TGetCSRPropertyRsp:unpack(_)
    return self.Value
end

CertificateService.GetCSRPropertyRsp = TGetCSRPropertyRsp

---@class CertificateService.GetCSRPropertyReq
---@field Property string
local TGetCSRPropertyReq = {}
TGetCSRPropertyReq.__index = TGetCSRPropertyReq
TGetCSRPropertyReq.group = {}

local function TGetCSRPropertyReq_from_obj(obj)
    return setmetatable(obj, TGetCSRPropertyReq)
end

function TGetCSRPropertyReq.new(Property)
    return TGetCSRPropertyReq_from_obj({Property = Property})
end
---@param obj CertificateService.GetCSRPropertyReq
function TGetCSRPropertyReq:init_from_obj(obj)
    self.Property = obj.Property
end

function TGetCSRPropertyReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCSRPropertyReq.group)
end

TGetCSRPropertyReq.from_obj = TGetCSRPropertyReq_from_obj

TGetCSRPropertyReq.proto_property = {'Property'}

TGetCSRPropertyReq.default = {''}

TGetCSRPropertyReq.struct = {{name = 'Property', is_array = false, struct = nil}}

function TGetCSRPropertyReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Property', self.Property, 'string', false, errs, need_convert)

    TGetCSRPropertyReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCSRPropertyReq.proto_property, errs, need_convert)
    return self
end

function TGetCSRPropertyReq:unpack(_)
    return self.Property
end

CertificateService.GetCSRPropertyReq = TGetCSRPropertyReq

---@class CertificateService.GetCSRContentRsp
---@field Status CertificateService.CertTaskStatus
---@field Content string
local TGetCSRContentRsp = {}
TGetCSRContentRsp.__index = TGetCSRContentRsp
TGetCSRContentRsp.group = {}

local function TGetCSRContentRsp_from_obj(obj)
    obj.Status = obj.Status and CertificateService.CertTaskStatus.new(obj.Status)
    return setmetatable(obj, TGetCSRContentRsp)
end

function TGetCSRContentRsp.new(Status, Content)
    return TGetCSRContentRsp_from_obj({Status = Status, Content = Content})
end
---@param obj CertificateService.GetCSRContentRsp
function TGetCSRContentRsp:init_from_obj(obj)
    self.Status = obj.Status
    self.Content = obj.Content
end

function TGetCSRContentRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCSRContentRsp.group)
end

TGetCSRContentRsp.from_obj = TGetCSRContentRsp_from_obj

TGetCSRContentRsp.proto_property = {'Status', 'Content'}

TGetCSRContentRsp.default = {CertificateService.CertTaskStatus.default, ''}

TGetCSRContentRsp.struct = {
    {name = 'Status', is_array = false, struct = CertificateService.CertTaskStatus.struct},
    {name = 'Content', is_array = false, struct = nil}
}

function TGetCSRContentRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Status', self.Status, 'CertificateService.CertTaskStatus', false, errs, need_convert)
    validate.Optional(prefix .. 'Content', self.Content, 'string', false, errs, need_convert)

    TGetCSRContentRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCSRContentRsp.proto_property, errs, need_convert)
    return self
end

function TGetCSRContentRsp:unpack(raw)
    local Status = utils.unpack_enum(raw, self.Status)
    return Status, self.Content
end

CertificateService.GetCSRContentRsp = TGetCSRContentRsp

---@class CertificateService.GetCSRContentReq
local TGetCSRContentReq = {}
TGetCSRContentReq.__index = TGetCSRContentReq
TGetCSRContentReq.group = {}

local function TGetCSRContentReq_from_obj(obj)
    return setmetatable(obj, TGetCSRContentReq)
end

function TGetCSRContentReq.new()
    return TGetCSRContentReq_from_obj({})
end
---@param obj CertificateService.GetCSRContentReq
function TGetCSRContentReq:init_from_obj(obj)

end

function TGetCSRContentReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCSRContentReq.group)
end

TGetCSRContentReq.from_obj = TGetCSRContentReq_from_obj

TGetCSRContentReq.proto_property = {}

TGetCSRContentReq.default = {}

TGetCSRContentReq.struct = {}

function TGetCSRContentReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TGetCSRContentReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCSRContentReq.proto_property, errs, need_convert)
    return self
end

function TGetCSRContentReq:unpack(_)
end

CertificateService.GetCSRContentReq = TGetCSRContentReq

---@class CertificateService.ImportCRLRsp
---@field TaskId integer
local TImportCRLRsp = {}
TImportCRLRsp.__index = TImportCRLRsp
TImportCRLRsp.group = {}

local function TImportCRLRsp_from_obj(obj)
    return setmetatable(obj, TImportCRLRsp)
end

function TImportCRLRsp.new(TaskId)
    return TImportCRLRsp_from_obj({TaskId = TaskId})
end
---@param obj CertificateService.ImportCRLRsp
function TImportCRLRsp:init_from_obj(obj)
    self.TaskId = obj.TaskId
end

function TImportCRLRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportCRLRsp.group)
end

TImportCRLRsp.from_obj = TImportCRLRsp_from_obj

TImportCRLRsp.proto_property = {'TaskId'}

TImportCRLRsp.default = {0}

TImportCRLRsp.struct = {{name = 'TaskId', is_array = false, struct = nil}}

function TImportCRLRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TImportCRLRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportCRLRsp.proto_property, errs, need_convert)
    return self
end

function TImportCRLRsp:unpack(_)
    return self.TaskId
end

CertificateService.ImportCRLRsp = TImportCRLRsp

---@class CertificateService.ImportCRLReq
---@field Type string
---@field Content string
---@field CertId integer
local TImportCRLReq = {}
TImportCRLReq.__index = TImportCRLReq
TImportCRLReq.group = {}

local function TImportCRLReq_from_obj(obj)
    return setmetatable(obj, TImportCRLReq)
end

function TImportCRLReq.new(Type, Content, CertId)
    return TImportCRLReq_from_obj({Type = Type, Content = Content, CertId = CertId or 0})
end
---@param obj CertificateService.ImportCRLReq
function TImportCRLReq:init_from_obj(obj)
    self.Type = obj.Type
    self.Content = obj.Content
    self.CertId = obj.CertId or 0
end

function TImportCRLReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportCRLReq.group)
end

TImportCRLReq.from_obj = TImportCRLReq_from_obj

TImportCRLReq.proto_property = {'Type', 'Content', 'CertId'}

TImportCRLReq.default = {'', '', 0}

TImportCRLReq.struct = {
    {name = 'Type', is_array = false, struct = nil}, {name = 'Content', is_array = false, struct = nil},
    {name = 'CertId', is_array = false, struct = nil}
}

function TImportCRLReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Type', self.Type, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Content', self.Content, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'CertId', self.CertId, 'uint32', false, errs, need_convert)

    if self.Type ~= nil then
        validate.lens(prefix .. 'Type', self.Type, 1, 5, errs, need_convert)
    end
    if self.CertId ~= nil then
        validate.ranges(prefix .. 'CertId', self.CertId, 0, 32, errs, need_convert)
    end

    TImportCRLReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportCRLReq.proto_property, errs, need_convert)
    return self
end

function TImportCRLReq:unpack(_)
    return self.Type, self.Content, self.CertId
end

CertificateService.ImportCRLReq = TImportCRLReq

---@class CertificateService.SetDefaultSSLCertSubjectRsp
local TSetDefaultSSLCertSubjectRsp = {}
TSetDefaultSSLCertSubjectRsp.__index = TSetDefaultSSLCertSubjectRsp
TSetDefaultSSLCertSubjectRsp.group = {}

local function TSetDefaultSSLCertSubjectRsp_from_obj(obj)
    return setmetatable(obj, TSetDefaultSSLCertSubjectRsp)
end

function TSetDefaultSSLCertSubjectRsp.new()
    return TSetDefaultSSLCertSubjectRsp_from_obj({})
end
---@param obj CertificateService.SetDefaultSSLCertSubjectRsp
function TSetDefaultSSLCertSubjectRsp:init_from_obj(obj)

end

function TSetDefaultSSLCertSubjectRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetDefaultSSLCertSubjectRsp.group)
end

TSetDefaultSSLCertSubjectRsp.from_obj = TSetDefaultSSLCertSubjectRsp_from_obj

TSetDefaultSSLCertSubjectRsp.proto_property = {}

TSetDefaultSSLCertSubjectRsp.default = {}

TSetDefaultSSLCertSubjectRsp.struct = {}

function TSetDefaultSSLCertSubjectRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TSetDefaultSSLCertSubjectRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetDefaultSSLCertSubjectRsp.proto_property, errs, need_convert)
    return self
end

function TSetDefaultSSLCertSubjectRsp:unpack(_)
end

CertificateService.SetDefaultSSLCertSubjectRsp = TSetDefaultSSLCertSubjectRsp

---@class CertificateService.SetDefaultSSLCertSubjectReq
---@field Country string
---@field CommonName string
---@field OrgName string
local TSetDefaultSSLCertSubjectReq = {}
TSetDefaultSSLCertSubjectReq.__index = TSetDefaultSSLCertSubjectReq
TSetDefaultSSLCertSubjectReq.group = {}

local function TSetDefaultSSLCertSubjectReq_from_obj(obj)
    return setmetatable(obj, TSetDefaultSSLCertSubjectReq)
end

function TSetDefaultSSLCertSubjectReq.new(Country, CommonName, OrgName)
    return TSetDefaultSSLCertSubjectReq_from_obj({Country = Country, CommonName = CommonName, OrgName = OrgName})
end
---@param obj CertificateService.SetDefaultSSLCertSubjectReq
function TSetDefaultSSLCertSubjectReq:init_from_obj(obj)
    self.Country = obj.Country
    self.CommonName = obj.CommonName
    self.OrgName = obj.OrgName
end

function TSetDefaultSSLCertSubjectReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TSetDefaultSSLCertSubjectReq.group)
end

TSetDefaultSSLCertSubjectReq.from_obj = TSetDefaultSSLCertSubjectReq_from_obj

TSetDefaultSSLCertSubjectReq.proto_property = {'Country', 'CommonName', 'OrgName'}

TSetDefaultSSLCertSubjectReq.default = {'', '', ''}

TSetDefaultSSLCertSubjectReq.struct = {
    {name = 'Country', is_array = false, struct = nil}, {name = 'CommonName', is_array = false, struct = nil},
    {name = 'OrgName', is_array = false, struct = nil}
}

function TSetDefaultSSLCertSubjectReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Country', self.Country, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'CommonName', self.CommonName, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'OrgName', self.OrgName, 'string', false, errs, need_convert)

    if self.Country ~= nil then
        validate.lens(prefix .. 'Country', self.Country, 1, 2, errs, need_convert)
    end
    if self.CommonName ~= nil then
        validate.lens(prefix .. 'CommonName', self.CommonName, 1, 64, errs, need_convert)
    end
    if self.OrgName ~= nil then
        validate.lens(prefix .. 'OrgName', self.OrgName, 0, 64, errs, need_convert)
    end

    TSetDefaultSSLCertSubjectReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TSetDefaultSSLCertSubjectReq.proto_property, errs, need_convert)
    return self
end

function TSetDefaultSSLCertSubjectReq:unpack(_)
    return self.Country, self.CommonName, self.OrgName
end

CertificateService.SetDefaultSSLCertSubjectReq = TSetDefaultSSLCertSubjectReq

---@class CertificateService.GetCertChainInfoRsp
---@field CertInfo string
local TGetCertChainInfoRsp = {}
TGetCertChainInfoRsp.__index = TGetCertChainInfoRsp
TGetCertChainInfoRsp.group = {}

local function TGetCertChainInfoRsp_from_obj(obj)
    return setmetatable(obj, TGetCertChainInfoRsp)
end

function TGetCertChainInfoRsp.new(CertInfo)
    return TGetCertChainInfoRsp_from_obj({CertInfo = CertInfo})
end
---@param obj CertificateService.GetCertChainInfoRsp
function TGetCertChainInfoRsp:init_from_obj(obj)
    self.CertInfo = obj.CertInfo
end

function TGetCertChainInfoRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCertChainInfoRsp.group)
end

TGetCertChainInfoRsp.from_obj = TGetCertChainInfoRsp_from_obj

TGetCertChainInfoRsp.proto_property = {'CertInfo'}

TGetCertChainInfoRsp.default = {''}

TGetCertChainInfoRsp.struct = {{name = 'CertInfo', is_array = false, struct = nil}}

function TGetCertChainInfoRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CertInfo', self.CertInfo, 'string', false, errs, need_convert)

    TGetCertChainInfoRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCertChainInfoRsp.proto_property, errs, need_convert)
    return self
end

function TGetCertChainInfoRsp:unpack(_)
    return self.CertInfo
end

CertificateService.GetCertChainInfoRsp = TGetCertChainInfoRsp

---@class CertificateService.GetCertChainInfoReq
---@field CertificateUsageType CertificateService.CertificateUsageType
---@field Id integer
local TGetCertChainInfoReq = {}
TGetCertChainInfoReq.__index = TGetCertChainInfoReq
TGetCertChainInfoReq.group = {}

local function TGetCertChainInfoReq_from_obj(obj)
    obj.CertificateUsageType = obj.CertificateUsageType and
                                   CertificateService.CertificateUsageType.new(obj.CertificateUsageType)
    return setmetatable(obj, TGetCertChainInfoReq)
end

function TGetCertChainInfoReq.new(CertificateUsageType, Id)
    return TGetCertChainInfoReq_from_obj({CertificateUsageType = CertificateUsageType, Id = Id})
end
---@param obj CertificateService.GetCertChainInfoReq
function TGetCertChainInfoReq:init_from_obj(obj)
    self.CertificateUsageType = obj.CertificateUsageType
    self.Id = obj.Id
end

function TGetCertChainInfoReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCertChainInfoReq.group)
end

TGetCertChainInfoReq.from_obj = TGetCertChainInfoReq_from_obj

TGetCertChainInfoReq.proto_property = {'CertificateUsageType', 'Id'}

TGetCertChainInfoReq.default = {CertificateService.CertificateUsageType.default, 0}

TGetCertChainInfoReq.struct = {
    {name = 'CertificateUsageType', is_array = false, struct = CertificateService.CertificateUsageType.struct},
    {name = 'Id', is_array = false, struct = nil}
}

function TGetCertChainInfoReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CertificateUsageType', self.CertificateUsageType,
        'CertificateService.CertificateUsageType', false, errs, need_convert)
    validate.Optional(prefix .. 'Id', self.Id, 'uint32', false, errs, need_convert)

    TGetCertChainInfoReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCertChainInfoReq.proto_property, errs, need_convert)
    return self
end

function TGetCertChainInfoReq:unpack(raw)
    local CertificateUsageType = utils.unpack_enum(raw, self.CertificateUsageType)
    return CertificateUsageType, self.Id
end

CertificateService.GetCertChainInfoReq = TGetCertChainInfoReq

---@class CertificateService.DeleteCertRsp
local TDeleteCertRsp = {}
TDeleteCertRsp.__index = TDeleteCertRsp
TDeleteCertRsp.group = {}

local function TDeleteCertRsp_from_obj(obj)
    return setmetatable(obj, TDeleteCertRsp)
end

function TDeleteCertRsp.new()
    return TDeleteCertRsp_from_obj({})
end
---@param obj CertificateService.DeleteCertRsp
function TDeleteCertRsp:init_from_obj(obj)

end

function TDeleteCertRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteCertRsp.group)
end

TDeleteCertRsp.from_obj = TDeleteCertRsp_from_obj

TDeleteCertRsp.proto_property = {}

TDeleteCertRsp.default = {}

TDeleteCertRsp.struct = {}

function TDeleteCertRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TDeleteCertRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteCertRsp.proto_property, errs, need_convert)
    return self
end

function TDeleteCertRsp:unpack(_)
end

CertificateService.DeleteCertRsp = TDeleteCertRsp

---@class CertificateService.DeleteCertReq
---@field CertificateUsageType CertificateService.CertificateUsageType
---@field Id integer
local TDeleteCertReq = {}
TDeleteCertReq.__index = TDeleteCertReq
TDeleteCertReq.group = {}

local function TDeleteCertReq_from_obj(obj)
    obj.CertificateUsageType = obj.CertificateUsageType and
                                   CertificateService.CertificateUsageType.new(obj.CertificateUsageType)
    return setmetatable(obj, TDeleteCertReq)
end

function TDeleteCertReq.new(CertificateUsageType, Id)
    return TDeleteCertReq_from_obj({CertificateUsageType = CertificateUsageType, Id = Id})
end
---@param obj CertificateService.DeleteCertReq
function TDeleteCertReq:init_from_obj(obj)
    self.CertificateUsageType = obj.CertificateUsageType
    self.Id = obj.Id
end

function TDeleteCertReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteCertReq.group)
end

TDeleteCertReq.from_obj = TDeleteCertReq_from_obj

TDeleteCertReq.proto_property = {'CertificateUsageType', 'Id'}

TDeleteCertReq.default = {CertificateService.CertificateUsageType.default, 0}

TDeleteCertReq.struct = {
    {name = 'CertificateUsageType', is_array = false, struct = CertificateService.CertificateUsageType.struct},
    {name = 'Id', is_array = false, struct = nil}
}

function TDeleteCertReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CertificateUsageType', self.CertificateUsageType,
        'CertificateService.CertificateUsageType', false, errs, need_convert)
    validate.Optional(prefix .. 'Id', self.Id, 'uint32', false, errs, need_convert)

    if self.Id ~= nil then
        validate.ranges(prefix .. 'Id', self.Id, 1, 32, errs, need_convert)
    end

    TDeleteCertReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteCertReq.proto_property, errs, need_convert)
    return self
end

function TDeleteCertReq:unpack(raw)
    local CertificateUsageType = utils.unpack_enum(raw, self.CertificateUsageType)
    return CertificateUsageType, self.Id
end

CertificateService.DeleteCertReq = TDeleteCertReq

---@class CertificateService.ExportCertKeyByFIFORsp
---@field FilePath string
local TExportCertKeyByFIFORsp = {}
TExportCertKeyByFIFORsp.__index = TExportCertKeyByFIFORsp
TExportCertKeyByFIFORsp.group = {}

local function TExportCertKeyByFIFORsp_from_obj(obj)
    return setmetatable(obj, TExportCertKeyByFIFORsp)
end

function TExportCertKeyByFIFORsp.new(FilePath)
    return TExportCertKeyByFIFORsp_from_obj({FilePath = FilePath})
end
---@param obj CertificateService.ExportCertKeyByFIFORsp
function TExportCertKeyByFIFORsp:init_from_obj(obj)
    self.FilePath = obj.FilePath
end

function TExportCertKeyByFIFORsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExportCertKeyByFIFORsp.group)
end

TExportCertKeyByFIFORsp.from_obj = TExportCertKeyByFIFORsp_from_obj

TExportCertKeyByFIFORsp.proto_property = {'FilePath'}

TExportCertKeyByFIFORsp.default = {''}

TExportCertKeyByFIFORsp.struct = {{name = 'FilePath', is_array = false, struct = nil}}

function TExportCertKeyByFIFORsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'FilePath', self.FilePath, 'string', false, errs, need_convert)

    if self.FilePath ~= nil then
        validate.lens(prefix .. 'FilePath', self.FilePath, 1, 2048, errs, need_convert)
    end

    TExportCertKeyByFIFORsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TExportCertKeyByFIFORsp.proto_property, errs, need_convert)
    return self
end

function TExportCertKeyByFIFORsp:unpack(_)
    return self.FilePath
end

CertificateService.ExportCertKeyByFIFORsp = TExportCertKeyByFIFORsp

---@class CertificateService.ExportCertKeyByFIFOReq
---@field CertificateUsageType CertificateService.CertificateUsageType
local TExportCertKeyByFIFOReq = {}
TExportCertKeyByFIFOReq.__index = TExportCertKeyByFIFOReq
TExportCertKeyByFIFOReq.group = {}

local function TExportCertKeyByFIFOReq_from_obj(obj)
    obj.CertificateUsageType = obj.CertificateUsageType and
                                   CertificateService.CertificateUsageType.new(obj.CertificateUsageType)
    return setmetatable(obj, TExportCertKeyByFIFOReq)
end

function TExportCertKeyByFIFOReq.new(CertificateUsageType)
    return TExportCertKeyByFIFOReq_from_obj({CertificateUsageType = CertificateUsageType})
end
---@param obj CertificateService.ExportCertKeyByFIFOReq
function TExportCertKeyByFIFOReq:init_from_obj(obj)
    self.CertificateUsageType = obj.CertificateUsageType
end

function TExportCertKeyByFIFOReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExportCertKeyByFIFOReq.group)
end

TExportCertKeyByFIFOReq.from_obj = TExportCertKeyByFIFOReq_from_obj

TExportCertKeyByFIFOReq.proto_property = {'CertificateUsageType'}

TExportCertKeyByFIFOReq.default = {CertificateService.CertificateUsageType.default}

TExportCertKeyByFIFOReq.struct = {
    {name = 'CertificateUsageType', is_array = false, struct = CertificateService.CertificateUsageType.struct}
}

function TExportCertKeyByFIFOReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CertificateUsageType', self.CertificateUsageType,
        'CertificateService.CertificateUsageType', false, errs, need_convert)

    TExportCertKeyByFIFOReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TExportCertKeyByFIFOReq.proto_property, errs, need_convert)
    return self
end

function TExportCertKeyByFIFOReq:unpack(raw)
    local CertificateUsageType = utils.unpack_enum(raw, self.CertificateUsageType)
    return CertificateUsageType
end

CertificateService.ExportCertKeyByFIFOReq = TExportCertKeyByFIFOReq

---@class CertificateService.ExportCSRRsp
---@field TaskId integer
local TExportCSRRsp = {}
TExportCSRRsp.__index = TExportCSRRsp
TExportCSRRsp.group = {}

local function TExportCSRRsp_from_obj(obj)
    return setmetatable(obj, TExportCSRRsp)
end

function TExportCSRRsp.new(TaskId)
    return TExportCSRRsp_from_obj({TaskId = TaskId})
end
---@param obj CertificateService.ExportCSRRsp
function TExportCSRRsp:init_from_obj(obj)
    self.TaskId = obj.TaskId
end

function TExportCSRRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExportCSRRsp.group)
end

TExportCSRRsp.from_obj = TExportCSRRsp_from_obj

TExportCSRRsp.proto_property = {'TaskId'}

TExportCSRRsp.default = {0}

TExportCSRRsp.struct = {{name = 'TaskId', is_array = false, struct = nil}}

function TExportCSRRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TExportCSRRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TExportCSRRsp.proto_property, errs, need_convert)
    return self
end

function TExportCSRRsp:unpack(_)
    return self.TaskId
end

CertificateService.ExportCSRRsp = TExportCSRRsp

---@class CertificateService.ExportCSRReq
---@field Path string
local TExportCSRReq = {}
TExportCSRReq.__index = TExportCSRReq
TExportCSRReq.group = {}

local function TExportCSRReq_from_obj(obj)
    return setmetatable(obj, TExportCSRReq)
end

function TExportCSRReq.new(Path)
    return TExportCSRReq_from_obj({Path = Path})
end
---@param obj CertificateService.ExportCSRReq
function TExportCSRReq:init_from_obj(obj)
    self.Path = obj.Path
end

function TExportCSRReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TExportCSRReq.group)
end

TExportCSRReq.from_obj = TExportCSRReq_from_obj

TExportCSRReq.proto_property = {'Path'}

TExportCSRReq.default = {''}

TExportCSRReq.struct = {{name = 'Path', is_array = false, struct = nil}}

function TExportCSRReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Path', self.Path, 'string', false, errs, need_convert)

    TExportCSRReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TExportCSRReq.proto_property, errs, need_convert)
    return self
end

function TExportCSRReq:unpack(_)
    return self.Path
end

CertificateService.ExportCSRReq = TExportCSRReq

---@class CertificateService.GenerateCSRRsp
---@field FilePath string
---@field TaskId integer
---@field CSRString string
local TGenerateCSRRsp = {}
TGenerateCSRRsp.__index = TGenerateCSRRsp
TGenerateCSRRsp.group = {}

local function TGenerateCSRRsp_from_obj(obj)
    return setmetatable(obj, TGenerateCSRRsp)
end

function TGenerateCSRRsp.new(FilePath, TaskId, CSRString)
    return TGenerateCSRRsp_from_obj({FilePath = FilePath, TaskId = TaskId, CSRString = CSRString})
end
---@param obj CertificateService.GenerateCSRRsp
function TGenerateCSRRsp:init_from_obj(obj)
    self.FilePath = obj.FilePath
    self.TaskId = obj.TaskId
    self.CSRString = obj.CSRString
end

function TGenerateCSRRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGenerateCSRRsp.group)
end

TGenerateCSRRsp.from_obj = TGenerateCSRRsp_from_obj

TGenerateCSRRsp.proto_property = {'FilePath', 'TaskId', 'CSRString'}

TGenerateCSRRsp.default = {'', 0, ''}

TGenerateCSRRsp.struct = {
    {name = 'FilePath', is_array = false, struct = nil}, {name = 'TaskId', is_array = false, struct = nil},
    {name = 'CSRString', is_array = false, struct = nil}
}

function TGenerateCSRRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'FilePath', self.FilePath, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'CSRString', self.CSRString, 'string', false, errs, need_convert)

    TGenerateCSRRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGenerateCSRRsp.proto_property, errs, need_convert)
    return self
end

function TGenerateCSRRsp:unpack(_)
    return self.FilePath, self.TaskId, self.CSRString
end

CertificateService.GenerateCSRRsp = TGenerateCSRRsp

---@class CertificateService.GenerateCSRReq
---@field Country string
---@field State string
---@field Location string
---@field OrgName string
---@field OrgUnit string
---@field CommonName string
---@field AlternativeNames string[]
---@field KeyUsage string[]
---@field KeyBitLength integer
---@field Options CertificateService.CSRProperty
local TGenerateCSRReq = {}
TGenerateCSRReq.__index = TGenerateCSRReq
TGenerateCSRReq.group = {}

local function TGenerateCSRReq_from_obj(obj)
    return setmetatable(obj, TGenerateCSRReq)
end

function TGenerateCSRReq.new(Country, State, Location, OrgName, OrgUnit, CommonName, AlternativeNames, KeyUsage,
    KeyBitLength, Options)
    return TGenerateCSRReq_from_obj({
        Country = Country,
        State = State,
        Location = Location,
        OrgName = OrgName,
        OrgUnit = OrgUnit,
        CommonName = CommonName,
        AlternativeNames = AlternativeNames,
        KeyUsage = KeyUsage,
        KeyBitLength = KeyBitLength,
        Options = Options
    })
end
---@param obj CertificateService.GenerateCSRReq
function TGenerateCSRReq:init_from_obj(obj)
    self.Country = obj.Country
    self.State = obj.State
    self.Location = obj.Location
    self.OrgName = obj.OrgName
    self.OrgUnit = obj.OrgUnit
    self.CommonName = obj.CommonName
    self.AlternativeNames = obj.AlternativeNames
    self.KeyUsage = obj.KeyUsage
    self.KeyBitLength = obj.KeyBitLength
    self.Options = obj.Options
end

function TGenerateCSRReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGenerateCSRReq.group)
end

TGenerateCSRReq.from_obj = TGenerateCSRReq_from_obj

TGenerateCSRReq.proto_property = {
    'Country', 'State', 'Location', 'OrgName', 'OrgUnit', 'CommonName', 'AlternativeNames', 'KeyUsage', 'KeyBitLength',
    'Options'
}

TGenerateCSRReq.default = {'', '', '', '', '', '', {}, {}, 0, CertificateService.CSRProperty.default}

TGenerateCSRReq.struct = {
    {name = 'Country', is_array = false, struct = nil}, {name = 'State', is_array = false, struct = nil},
    {name = 'Location', is_array = false, struct = nil}, {name = 'OrgName', is_array = false, struct = nil},
    {name = 'OrgUnit', is_array = false, struct = nil}, {name = 'CommonName', is_array = false, struct = nil},
    {name = 'AlternativeNames', is_array = true, struct = nil}, {name = 'KeyUsage', is_array = true, struct = nil},
    {name = 'KeyBitLength', is_array = false, struct = nil},
    {name = 'Options', is_array = false, struct = CertificateService.CSRProperty.struct}
}

function TGenerateCSRReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    CertificateService.CSRProperty.new(self.Options):validate(prefix, errs, need_convert)

    validate.Optional(prefix .. 'Country', self.Country, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'State', self.State, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Location', self.Location, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'OrgName', self.OrgName, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'OrgUnit', self.OrgUnit, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'CommonName', self.CommonName, 'string', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'AlternativeNames', self.AlternativeNames, 'string', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'KeyUsage', self.KeyUsage, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'KeyBitLength', self.KeyBitLength, 'int32', false, errs, need_convert)

    if self.Country ~= nil then
        validate.lens(prefix .. 'Country', self.Country, 1, 2, errs, need_convert)
    end
    if self.State ~= nil then
        validate.lens(prefix .. 'State', self.State, 0, 128, errs, need_convert)
    end
    if self.Location ~= nil then
        validate.lens(prefix .. 'Location', self.Location, 0, 128, errs, need_convert)
    end
    if self.OrgName ~= nil then
        validate.lens(prefix .. 'OrgName', self.OrgName, 0, 64, errs, need_convert)
    end
    if self.OrgUnit ~= nil then
        validate.lens(prefix .. 'OrgUnit', self.OrgUnit, 0, 64, errs, need_convert)
    end
    if self.CommonName ~= nil then
        validate.lens(prefix .. 'CommonName', self.CommonName, 1, 64, errs, need_convert)
    end

    TGenerateCSRReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGenerateCSRReq.proto_property, errs, need_convert)
    return self
end

function TGenerateCSRReq:unpack(_)
    return self.Country, self.State, self.Location, self.OrgName, self.OrgUnit, self.CommonName, self.AlternativeNames,
        self.KeyUsage, self.KeyBitLength, self.Options
end

CertificateService.GenerateCSRReq = TGenerateCSRReq

---@class CertificateService.StartGenerateCSRRsp
---@field FilePath string
---@field TaskId integer
local TStartGenerateCSRRsp = {}
TStartGenerateCSRRsp.__index = TStartGenerateCSRRsp
TStartGenerateCSRRsp.group = {}

local function TStartGenerateCSRRsp_from_obj(obj)
    return setmetatable(obj, TStartGenerateCSRRsp)
end

function TStartGenerateCSRRsp.new(FilePath, TaskId)
    return TStartGenerateCSRRsp_from_obj({FilePath = FilePath, TaskId = TaskId})
end
---@param obj CertificateService.StartGenerateCSRRsp
function TStartGenerateCSRRsp:init_from_obj(obj)
    self.FilePath = obj.FilePath
    self.TaskId = obj.TaskId
end

function TStartGenerateCSRRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TStartGenerateCSRRsp.group)
end

TStartGenerateCSRRsp.from_obj = TStartGenerateCSRRsp_from_obj

TStartGenerateCSRRsp.proto_property = {'FilePath', 'TaskId'}

TStartGenerateCSRRsp.default = {'', 0}

TStartGenerateCSRRsp.struct = {
    {name = 'FilePath', is_array = false, struct = nil}, {name = 'TaskId', is_array = false, struct = nil}
}

function TStartGenerateCSRRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'FilePath', self.FilePath, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TStartGenerateCSRRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TStartGenerateCSRRsp.proto_property, errs, need_convert)
    return self
end

function TStartGenerateCSRRsp:unpack(_)
    return self.FilePath, self.TaskId
end

CertificateService.StartGenerateCSRRsp = TStartGenerateCSRRsp

---@class CertificateService.StartGenerateCSRReq
---@field Country string
---@field State string
---@field Location string
---@field OrgName string
---@field OrgUnit string
---@field CommonName string
---@field AlternativeNames string[]
local TStartGenerateCSRReq = {}
TStartGenerateCSRReq.__index = TStartGenerateCSRReq
TStartGenerateCSRReq.group = {}

local function TStartGenerateCSRReq_from_obj(obj)
    return setmetatable(obj, TStartGenerateCSRReq)
end

function TStartGenerateCSRReq.new(Country, State, Location, OrgName, OrgUnit, CommonName, AlternativeNames)
    return TStartGenerateCSRReq_from_obj({
        Country = Country,
        State = State,
        Location = Location,
        OrgName = OrgName,
        OrgUnit = OrgUnit,
        CommonName = CommonName,
        AlternativeNames = AlternativeNames
    })
end
---@param obj CertificateService.StartGenerateCSRReq
function TStartGenerateCSRReq:init_from_obj(obj)
    self.Country = obj.Country
    self.State = obj.State
    self.Location = obj.Location
    self.OrgName = obj.OrgName
    self.OrgUnit = obj.OrgUnit
    self.CommonName = obj.CommonName
    self.AlternativeNames = obj.AlternativeNames
end

function TStartGenerateCSRReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TStartGenerateCSRReq.group)
end

TStartGenerateCSRReq.from_obj = TStartGenerateCSRReq_from_obj

TStartGenerateCSRReq.proto_property = {
    'Country', 'State', 'Location', 'OrgName', 'OrgUnit', 'CommonName', 'AlternativeNames'
}

TStartGenerateCSRReq.default = {'', '', '', '', '', '', {}}

TStartGenerateCSRReq.struct = {
    {name = 'Country', is_array = false, struct = nil}, {name = 'State', is_array = false, struct = nil},
    {name = 'Location', is_array = false, struct = nil}, {name = 'OrgName', is_array = false, struct = nil},
    {name = 'OrgUnit', is_array = false, struct = nil}, {name = 'CommonName', is_array = false, struct = nil},
    {name = 'AlternativeNames', is_array = true, struct = nil}
}

function TStartGenerateCSRReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Country', self.Country, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'State', self.State, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Location', self.Location, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'OrgName', self.OrgName, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'OrgUnit', self.OrgUnit, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'CommonName', self.CommonName, 'string', false, errs, need_convert)
    validate.OptionalArray(prefix .. 'AlternativeNames', self.AlternativeNames, 'string', false, errs, need_convert)

    if self.Country ~= nil then
        validate.lens(prefix .. 'Country', self.Country, 1, 2, errs, need_convert)
    end
    if self.State ~= nil then
        validate.lens(prefix .. 'State', self.State, 0, 128, errs, need_convert)
    end
    if self.Location ~= nil then
        validate.lens(prefix .. 'Location', self.Location, 0, 128, errs, need_convert)
    end
    if self.OrgName ~= nil then
        validate.lens(prefix .. 'OrgName', self.OrgName, 0, 64, errs, need_convert)
    end
    if self.OrgUnit ~= nil then
        validate.lens(prefix .. 'OrgUnit', self.OrgUnit, 0, 64, errs, need_convert)
    end
    if self.CommonName ~= nil then
        validate.lens(prefix .. 'CommonName', self.CommonName, 1, 64, errs, need_convert)
    end

    TStartGenerateCSRReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TStartGenerateCSRReq.proto_property, errs, need_convert)
    return self
end

function TStartGenerateCSRReq:unpack(_)
    return self.Country, self.State, self.Location, self.OrgName, self.OrgUnit, self.CommonName, self.AlternativeNames
end

CertificateService.StartGenerateCSRReq = TStartGenerateCSRReq

---@class CertificateService.ImportCertificateRsp
---@field Id integer
---@field TaskId integer
---@field Extra CertificateService.Extra
local TImportCertificateRsp = {}
TImportCertificateRsp.__index = TImportCertificateRsp
TImportCertificateRsp.group = {}

local function TImportCertificateRsp_from_obj(obj)
    return setmetatable(obj, TImportCertificateRsp)
end

function TImportCertificateRsp.new(Id, TaskId, Extra)
    return TImportCertificateRsp_from_obj({Id = Id, TaskId = TaskId, Extra = Extra})
end
---@param obj CertificateService.ImportCertificateRsp
function TImportCertificateRsp:init_from_obj(obj)
    self.Id = obj.Id
    self.TaskId = obj.TaskId
    self.Extra = obj.Extra
end

function TImportCertificateRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportCertificateRsp.group)
end

TImportCertificateRsp.from_obj = TImportCertificateRsp_from_obj

TImportCertificateRsp.proto_property = {'Id', 'TaskId', 'Extra'}

TImportCertificateRsp.default = {0, 0, CertificateService.Extra.default}

TImportCertificateRsp.struct = {
    {name = 'Id', is_array = false, struct = nil}, {name = 'TaskId', is_array = false, struct = nil},
    {name = 'Extra', is_array = false, struct = CertificateService.Extra.struct}
}

function TImportCertificateRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    CertificateService.Extra.new(self.Extra):validate(prefix, errs, need_convert)

    validate.Optional(prefix .. 'Id', self.Id, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TImportCertificateRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportCertificateRsp.proto_property, errs, need_convert)
    return self
end

function TImportCertificateRsp:unpack(_)
    return self.Id, self.TaskId, self.Extra
end

CertificateService.ImportCertificateRsp = TImportCertificateRsp

---@class CertificateService.ImportCertificateReq
---@field CertificateUsageType CertificateService.CertificateUsageType
---@field Type string
---@field Content string
---@field Id integer
---@field WithEncryptedKey boolean
---@field Password string
---@field Extra CertificateService.Extra
local TImportCertificateReq = {}
TImportCertificateReq.__index = TImportCertificateReq
TImportCertificateReq.group = {}

local function TImportCertificateReq_from_obj(obj)
    obj.CertificateUsageType = obj.CertificateUsageType and
                                   CertificateService.CertificateUsageType.new(obj.CertificateUsageType)
    return setmetatable(obj, TImportCertificateReq)
end

function TImportCertificateReq.new(CertificateUsageType, Type, Content, Id, WithEncryptedKey, Password, Extra)
    return TImportCertificateReq_from_obj({
        CertificateUsageType = CertificateUsageType,
        Type = Type,
        Content = Content,
        Id = Id,
        WithEncryptedKey = WithEncryptedKey,
        Password = Password,
        Extra = Extra
    })
end
---@param obj CertificateService.ImportCertificateReq
function TImportCertificateReq:init_from_obj(obj)
    self.CertificateUsageType = obj.CertificateUsageType
    self.Type = obj.Type
    self.Content = obj.Content
    self.Id = obj.Id
    self.WithEncryptedKey = obj.WithEncryptedKey
    self.Password = obj.Password
    self.Extra = obj.Extra
end

function TImportCertificateReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportCertificateReq.group)
end

TImportCertificateReq.from_obj = TImportCertificateReq_from_obj

TImportCertificateReq.proto_property = {
    'CertificateUsageType', 'Type', 'Content', 'Id', 'WithEncryptedKey', 'Password', 'Extra'
}

TImportCertificateReq.default = {
    CertificateService.CertificateUsageType.default, '', '', 0, false, '', CertificateService.Extra.default
}

TImportCertificateReq.struct = {
    {name = 'CertificateUsageType', is_array = false, struct = CertificateService.CertificateUsageType.struct},
    {name = 'Type', is_array = false, struct = nil}, {name = 'Content', is_array = false, struct = nil},
    {name = 'Id', is_array = false, struct = nil}, {name = 'WithEncryptedKey', is_array = false, struct = nil},
    {name = 'Password', is_array = false, struct = nil},
    {name = 'Extra', is_array = false, struct = CertificateService.Extra.struct}
}

function TImportCertificateReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    CertificateService.CertificateUsageType.new():validate(prefix, errs, need_convert)
    CertificateService.Extra.new(self.Extra):validate(prefix, errs, need_convert)

    validate.Optional(prefix .. 'Type', self.Type, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Content', self.Content, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Id', self.Id, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'WithEncryptedKey', self.WithEncryptedKey, 'bool', false, errs, need_convert)
    validate.Optional(prefix .. 'Password', self.Password, 'string', false, errs, need_convert)

    if self.Type ~= nil then
        validate.lens(prefix .. 'Type', self.Type, 1, 5, errs, need_convert)
    end
    if self.Id ~= nil then
        validate.ranges(prefix .. 'Id', self.Id, 0, 32, errs, need_convert)
    end
    if self.Password ~= nil then
        validate.lens(prefix .. 'Password', self.Password, 0, 127, errs, need_convert)
    end

    TImportCertificateReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportCertificateReq.proto_property, errs, need_convert)
    return self
end

function TImportCertificateReq:unpack(raw)
    local CertificateUsageType = utils.unpack_enum(raw, self.CertificateUsageType)
    return CertificateUsageType, self.Type, self.Content, self.Id, self.WithEncryptedKey, self.Password, self.Extra
end

CertificateService.ImportCertificateReq = TImportCertificateReq

---@class CertificateService.ImportCertWithKeyRsp
---@field TaskId integer
local TImportCertWithKeyRsp = {}
TImportCertWithKeyRsp.__index = TImportCertWithKeyRsp
TImportCertWithKeyRsp.group = {}

local function TImportCertWithKeyRsp_from_obj(obj)
    return setmetatable(obj, TImportCertWithKeyRsp)
end

function TImportCertWithKeyRsp.new(TaskId)
    return TImportCertWithKeyRsp_from_obj({TaskId = TaskId})
end
---@param obj CertificateService.ImportCertWithKeyRsp
function TImportCertWithKeyRsp:init_from_obj(obj)
    self.TaskId = obj.TaskId
end

function TImportCertWithKeyRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportCertWithKeyRsp.group)
end

TImportCertWithKeyRsp.from_obj = TImportCertWithKeyRsp_from_obj

TImportCertWithKeyRsp.proto_property = {'TaskId'}

TImportCertWithKeyRsp.default = {0}

TImportCertWithKeyRsp.struct = {{name = 'TaskId', is_array = false, struct = nil}}

function TImportCertWithKeyRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TImportCertWithKeyRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportCertWithKeyRsp.proto_property, errs, need_convert)
    return self
end

function TImportCertWithKeyRsp:unpack(_)
    return self.TaskId
end

CertificateService.ImportCertWithKeyRsp = TImportCertWithKeyRsp

---@class CertificateService.ImportCertWithKeyReq
---@field CertificateUsageType CertificateService.CertificateUsageType
---@field Type string
---@field Content string
---@field Key string
local TImportCertWithKeyReq = {}
TImportCertWithKeyReq.__index = TImportCertWithKeyReq
TImportCertWithKeyReq.group = {}

local function TImportCertWithKeyReq_from_obj(obj)
    obj.CertificateUsageType = obj.CertificateUsageType and
                                   CertificateService.CertificateUsageType.new(obj.CertificateUsageType)
    return setmetatable(obj, TImportCertWithKeyReq)
end

function TImportCertWithKeyReq.new(CertificateUsageType, Type, Content, Key)
    return TImportCertWithKeyReq_from_obj({
        CertificateUsageType = CertificateUsageType,
        Type = Type,
        Content = Content,
        Key = Key
    })
end
---@param obj CertificateService.ImportCertWithKeyReq
function TImportCertWithKeyReq:init_from_obj(obj)
    self.CertificateUsageType = obj.CertificateUsageType
    self.Type = obj.Type
    self.Content = obj.Content
    self.Key = obj.Key
end

function TImportCertWithKeyReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportCertWithKeyReq.group)
end

TImportCertWithKeyReq.from_obj = TImportCertWithKeyReq_from_obj

TImportCertWithKeyReq.proto_property = {'CertificateUsageType', 'Type', 'Content', 'Key'}

TImportCertWithKeyReq.default = {CertificateService.CertificateUsageType.default, '', '', ''}

TImportCertWithKeyReq.struct = {
    {name = 'CertificateUsageType', is_array = false, struct = CertificateService.CertificateUsageType.struct},
    {name = 'Type', is_array = false, struct = nil}, {name = 'Content', is_array = false, struct = nil},
    {name = 'Key', is_array = false, struct = nil}
}

function TImportCertWithKeyReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CertificateUsageType', self.CertificateUsageType,
        'CertificateService.CertificateUsageType', false, errs, need_convert)
    validate.Optional(prefix .. 'Type', self.Type, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Content', self.Content, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Key', self.Key, 'string', false, errs, need_convert)

    if self.Type ~= nil then
        validate.lens(prefix .. 'Type', self.Type, 1, 5, errs, need_convert)
    end
    if self.Key ~= nil then
        validate.lens(prefix .. 'Key', self.Key, 0, 127, errs, need_convert)
    end

    TImportCertWithKeyReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportCertWithKeyReq.proto_property, errs, need_convert)
    return self
end

function TImportCertWithKeyReq:unpack(raw)
    local CertificateUsageType = utils.unpack_enum(raw, self.CertificateUsageType)
    return CertificateUsageType, self.Type, self.Content, self.Key
end

CertificateService.ImportCertWithKeyReq = TImportCertWithKeyReq

---@class CertificateService.ImportCertRsp
---@field Id integer
---@field TaskId integer
local TImportCertRsp = {}
TImportCertRsp.__index = TImportCertRsp
TImportCertRsp.group = {}

local function TImportCertRsp_from_obj(obj)
    return setmetatable(obj, TImportCertRsp)
end

function TImportCertRsp.new(Id, TaskId)
    return TImportCertRsp_from_obj({Id = Id, TaskId = TaskId})
end
---@param obj CertificateService.ImportCertRsp
function TImportCertRsp:init_from_obj(obj)
    self.Id = obj.Id
    self.TaskId = obj.TaskId
end

function TImportCertRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportCertRsp.group)
end

TImportCertRsp.from_obj = TImportCertRsp_from_obj

TImportCertRsp.proto_property = {'Id', 'TaskId'}

TImportCertRsp.default = {0, 0}

TImportCertRsp.struct = {
    {name = 'Id', is_array = false, struct = nil}, {name = 'TaskId', is_array = false, struct = nil}
}

function TImportCertRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Id', self.Id, 'uint32', false, errs, need_convert)
    validate.Optional(prefix .. 'TaskId', self.TaskId, 'uint32', false, errs, need_convert)

    TImportCertRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportCertRsp.proto_property, errs, need_convert)
    return self
end

function TImportCertRsp:unpack(_)
    return self.Id, self.TaskId
end

CertificateService.ImportCertRsp = TImportCertRsp

---@class CertificateService.ImportCertReq
---@field CertificateUsageType CertificateService.CertificateUsageType
---@field Type string
---@field Content string
---@field Id integer
local TImportCertReq = {}
TImportCertReq.__index = TImportCertReq
TImportCertReq.group = {}

local function TImportCertReq_from_obj(obj)
    obj.CertificateUsageType = obj.CertificateUsageType and
                                   CertificateService.CertificateUsageType.new(obj.CertificateUsageType)
    return setmetatable(obj, TImportCertReq)
end

function TImportCertReq.new(CertificateUsageType, Type, Content, Id)
    return TImportCertReq_from_obj({
        CertificateUsageType = CertificateUsageType,
        Type = Type,
        Content = Content,
        Id = Id or 0
    })
end
---@param obj CertificateService.ImportCertReq
function TImportCertReq:init_from_obj(obj)
    self.CertificateUsageType = obj.CertificateUsageType
    self.Type = obj.Type
    self.Content = obj.Content
    self.Id = obj.Id or 0
end

function TImportCertReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TImportCertReq.group)
end

TImportCertReq.from_obj = TImportCertReq_from_obj

TImportCertReq.proto_property = {'CertificateUsageType', 'Type', 'Content', 'Id'}

TImportCertReq.default = {CertificateService.CertificateUsageType.default, '', '', 0}

TImportCertReq.struct = {
    {name = 'CertificateUsageType', is_array = false, struct = CertificateService.CertificateUsageType.struct},
    {name = 'Type', is_array = false, struct = nil}, {name = 'Content', is_array = false, struct = nil},
    {name = 'Id', is_array = false, struct = nil}
}

function TImportCertReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CertificateUsageType', self.CertificateUsageType,
        'CertificateService.CertificateUsageType', false, errs, need_convert)
    validate.Optional(prefix .. 'Type', self.Type, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Content', self.Content, 'string', false, errs, need_convert)
    validate.Optional(prefix .. 'Id', self.Id, 'uint32', false, errs, need_convert)

    if self.Type ~= nil then
        validate.lens(prefix .. 'Type', self.Type, 1, 5, errs, need_convert)
    end
    if self.Id ~= nil then
        validate.ranges(prefix .. 'Id', self.Id, 0, 32, errs, need_convert)
    end

    TImportCertReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TImportCertReq.proto_property, errs, need_convert)
    return self
end

function TImportCertReq:unpack(raw)
    local CertificateUsageType = utils.unpack_enum(raw, self.CertificateUsageType)
    return CertificateUsageType, self.Type, self.Content, self.Id
end

CertificateService.ImportCertReq = TImportCertReq

---@class CertificateService.GetCertPathRsp
---@field Path string
local TGetCertPathRsp = {}
TGetCertPathRsp.__index = TGetCertPathRsp
TGetCertPathRsp.group = {}

local function TGetCertPathRsp_from_obj(obj)
    return setmetatable(obj, TGetCertPathRsp)
end

function TGetCertPathRsp.new(Path)
    return TGetCertPathRsp_from_obj({Path = Path})
end
---@param obj CertificateService.GetCertPathRsp
function TGetCertPathRsp:init_from_obj(obj)
    self.Path = obj.Path
end

function TGetCertPathRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCertPathRsp.group)
end

TGetCertPathRsp.from_obj = TGetCertPathRsp_from_obj

TGetCertPathRsp.proto_property = {'Path'}

TGetCertPathRsp.default = {''}

TGetCertPathRsp.struct = {{name = 'Path', is_array = false, struct = nil}}

function TGetCertPathRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'Path', self.Path, 'string', false, errs, need_convert)

    if self.Path ~= nil then
        validate.lens(prefix .. 'Path', self.Path, 1, 2048, errs, need_convert)
    end

    TGetCertPathRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCertPathRsp.proto_property, errs, need_convert)
    return self
end

function TGetCertPathRsp:unpack(_)
    return self.Path
end

CertificateService.GetCertPathRsp = TGetCertPathRsp

---@class CertificateService.GetCertPathReq
---@field CertificateUsageType CertificateService.CertificateUsageType
local TGetCertPathReq = {}
TGetCertPathReq.__index = TGetCertPathReq
TGetCertPathReq.group = {}

local function TGetCertPathReq_from_obj(obj)
    obj.CertificateUsageType = obj.CertificateUsageType and
                                   CertificateService.CertificateUsageType.new(obj.CertificateUsageType)
    return setmetatable(obj, TGetCertPathReq)
end

function TGetCertPathReq.new(CertificateUsageType)
    return TGetCertPathReq_from_obj({CertificateUsageType = CertificateUsageType})
end
---@param obj CertificateService.GetCertPathReq
function TGetCertPathReq:init_from_obj(obj)
    self.CertificateUsageType = obj.CertificateUsageType
end

function TGetCertPathReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCertPathReq.group)
end

TGetCertPathReq.from_obj = TGetCertPathReq_from_obj

TGetCertPathReq.proto_property = {'CertificateUsageType'}

TGetCertPathReq.default = {CertificateService.CertificateUsageType.default}

TGetCertPathReq.struct = {
    {name = 'CertificateUsageType', is_array = false, struct = CertificateService.CertificateUsageType.struct}
}

function TGetCertPathReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CertificateUsageType', self.CertificateUsageType,
        'CertificateService.CertificateUsageType', false, errs, need_convert)

    TGetCertPathReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCertPathReq.proto_property, errs, need_convert)
    return self
end

function TGetCertPathReq:unpack(raw)
    local CertificateUsageType = utils.unpack_enum(raw, self.CertificateUsageType)
    return CertificateUsageType
end

CertificateService.GetCertPathReq = TGetCertPathReq

CertificateService.interface = mdb.register_interface('bmc.kepler.CertificateService', {
    CertOverdueWarnDays = {'u', nil, false, 90},
    CRLOverdueWarnMode = {'s', nil, false, 'Customized'},
    CRLOverdueWarnDays = {'u', nil, false, 90},
    CRLEnabled = {'b', nil, false, true},
    IsDefaultSSLCert = {'b', nil, true, false},
    SSLCertAlgorithm = {'y', nil, false, 0}
}, {
    GetCertPath = {'a{ss}i', 's', TGetCertPathReq, TGetCertPathRsp},
    ImportCert = {'a{ss}issu', 'uu', TImportCertReq, TImportCertRsp},
    ImportCertWithKey = {'a{ss}isss', 'u', TImportCertWithKeyReq, TImportCertWithKeyRsp},
    ImportCertificate = {'a{ss}issubsa{ss}', 'uua{ss}', TImportCertificateReq, TImportCertificateRsp},
    StartGenerateCSR = {'a{ss}ssssssas', 'su', TStartGenerateCSRReq, TStartGenerateCSRRsp},
    GenerateCSR = {'a{ss}ssssssasasia{ss}', 'sus', TGenerateCSRReq, TGenerateCSRRsp},
    ExportCSR = {'a{ss}s', 'u', TExportCSRReq, TExportCSRRsp},
    ExportCertKeyByFIFO = {'a{ss}i', 's', TExportCertKeyByFIFOReq, TExportCertKeyByFIFORsp},
    DeleteCert = {'a{ss}iu', '', TDeleteCertReq, TDeleteCertRsp},
    GetCertChainInfo = {'a{ss}iu', 's', TGetCertChainInfoReq, TGetCertChainInfoRsp},
    SetDefaultSSLCertSubject = {'a{ss}sss', '', TSetDefaultSSLCertSubjectReq, TSetDefaultSSLCertSubjectRsp},
    ImportCRL = {'a{ss}ssu', 'u', TImportCRLReq, TImportCRLRsp},
    GetCSRContent = {'a{ss}', 'is', TGetCSRContentReq, TGetCSRContentRsp},
    GetCSRProperty = {'a{ss}s', 's', TGetCSRPropertyReq, TGetCSRPropertyRsp},
    SetCSRProperty = {'a{ss}a{ss}', '', TSetCSRPropertyReq, TSetCSRPropertyRsp},
    BackupCertificate = {'a{ss}sas', '', TBackupCertificateReq, TBackupCertificateRsp}
}, {})

return CertificateService
