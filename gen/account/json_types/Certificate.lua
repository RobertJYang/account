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

local Certificate = {}

---@class Certificate.GetCertificateStringRsp
---@field CertificateString string
local TGetCertificateStringRsp = {}
TGetCertificateStringRsp.__index = TGetCertificateStringRsp
TGetCertificateStringRsp.group = {}

local function TGetCertificateStringRsp_from_obj(obj)
    return setmetatable(obj, TGetCertificateStringRsp)
end

function TGetCertificateStringRsp.new(CertificateString)
    return TGetCertificateStringRsp_from_obj({CertificateString = CertificateString})
end
---@param obj Certificate.GetCertificateStringRsp
function TGetCertificateStringRsp:init_from_obj(obj)
    self.CertificateString = obj.CertificateString
end

function TGetCertificateStringRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCertificateStringRsp.group)
end

TGetCertificateStringRsp.from_obj = TGetCertificateStringRsp_from_obj

TGetCertificateStringRsp.proto_property = {'CertificateString'}

TGetCertificateStringRsp.default = {''}

TGetCertificateStringRsp.struct = {{name = 'CertificateString', is_array = false, struct = nil}}

function TGetCertificateStringRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    validate.Optional(prefix .. 'CertificateString', self.CertificateString, 'string', false, errs, need_convert)

    TGetCertificateStringRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCertificateStringRsp.proto_property, errs, need_convert)
    return self
end

function TGetCertificateStringRsp:unpack(_)
    return self.CertificateString
end

Certificate.GetCertificateStringRsp = TGetCertificateStringRsp

---@class Certificate.GetCertificateStringReq
local TGetCertificateStringReq = {}
TGetCertificateStringReq.__index = TGetCertificateStringReq
TGetCertificateStringReq.group = {}

local function TGetCertificateStringReq_from_obj(obj)
    return setmetatable(obj, TGetCertificateStringReq)
end

function TGetCertificateStringReq.new()
    return TGetCertificateStringReq_from_obj({})
end
---@param obj Certificate.GetCertificateStringReq
function TGetCertificateStringReq:init_from_obj(obj)

end

function TGetCertificateStringReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TGetCertificateStringReq.group)
end

TGetCertificateStringReq.from_obj = TGetCertificateStringReq_from_obj

TGetCertificateStringReq.proto_property = {}

TGetCertificateStringReq.default = {}

TGetCertificateStringReq.struct = {}

function TGetCertificateStringReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TGetCertificateStringReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TGetCertificateStringReq.proto_property, errs, need_convert)
    return self
end

function TGetCertificateStringReq:unpack(_)
end

Certificate.GetCertificateStringReq = TGetCertificateStringReq

---@class Certificate.DeleteCRLRsp
local TDeleteCRLRsp = {}
TDeleteCRLRsp.__index = TDeleteCRLRsp
TDeleteCRLRsp.group = {}

local function TDeleteCRLRsp_from_obj(obj)
    return setmetatable(obj, TDeleteCRLRsp)
end

function TDeleteCRLRsp.new()
    return TDeleteCRLRsp_from_obj({})
end
---@param obj Certificate.DeleteCRLRsp
function TDeleteCRLRsp:init_from_obj(obj)

end

function TDeleteCRLRsp:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteCRLRsp.group)
end

TDeleteCRLRsp.from_obj = TDeleteCRLRsp_from_obj

TDeleteCRLRsp.proto_property = {}

TDeleteCRLRsp.default = {}

TDeleteCRLRsp.struct = {}

function TDeleteCRLRsp:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TDeleteCRLRsp:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteCRLRsp.proto_property, errs, need_convert)
    return self
end

function TDeleteCRLRsp:unpack(_)
end

Certificate.DeleteCRLRsp = TDeleteCRLRsp

---@class Certificate.DeleteCRLReq
local TDeleteCRLReq = {}
TDeleteCRLReq.__index = TDeleteCRLReq
TDeleteCRLReq.group = {}

local function TDeleteCRLReq_from_obj(obj)
    return setmetatable(obj, TDeleteCRLReq)
end

function TDeleteCRLReq.new()
    return TDeleteCRLReq_from_obj({})
end
---@param obj Certificate.DeleteCRLReq
function TDeleteCRLReq:init_from_obj(obj)

end

function TDeleteCRLReq:remove_error_props(errs, obj)
    utils.remove_obj_error_property(obj, errs, TDeleteCRLReq.group)
end

TDeleteCRLReq.from_obj = TDeleteCRLReq_from_obj

TDeleteCRLReq.proto_property = {}

TDeleteCRLReq.default = {}

TDeleteCRLReq.struct = {}

function TDeleteCRLReq:validate(prefix, errs, need_convert)
    prefix = prefix or ''

    TDeleteCRLReq:remove_error_props(errs, self)
    validate.CheckUnknowProperty(self, TDeleteCRLReq.proto_property, errs, need_convert)
    return self
end

function TDeleteCRLReq:unpack(_)
end

Certificate.DeleteCRLReq = TDeleteCRLReq

Certificate.interface = mdb.register_interface('bmc.kepler.CertificateService.Certificate', {
    CertificateType = {'u', nil, true, nil},
    CertificateUsageType = {'u', nil, true, nil},
    Fingerprint = {'s', nil, true, nil},
    FingerprintHashAlgorithm = {'s', nil, true, nil},
    Issuer = {'s', nil, true, nil},
    KeyUsage = {'au', nil, true, nil},
    SerialNumber = {'s', nil, true, nil},
    SignatureAlgorithm = {'s', nil, true, nil},
    Subject = {'s', nil, true, nil},
    ValidNotAfter = {'s', nil, true, nil},
    ValidNotBefore = {'s', nil, true, nil},
    FilePath = {'s', nil, true, nil},
    CommonName = {'s', nil, true, nil},
    CRLStartTime = {'s', nil, true, nil},
    CRLExpireTime = {'s', nil, true, nil},
    CertCount = {'u', nil, true, nil},
    KeyLength = {'u', nil, true, nil}
}, {
    DeleteCRL = {'a{ss}', '', TDeleteCRLReq, TDeleteCRLRsp},
    GetCertificateString = {'a{ss}', 's', TGetCertificateStringReq, TGetCertificateStringRsp}
}, {})

return Certificate
