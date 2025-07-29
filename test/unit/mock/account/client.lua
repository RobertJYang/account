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

local EMPYT_HASH<const> = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}


-- MockClient客户端，UT使用，mock掉所有rpc
local MockClient = class()

function MockClient:init()
end

function MockClient:GetSecureBootObjects()
    return {['mdb_path'] = self}
end

function MockClient:GetFileTransferObjects()
    return {['mdb_path'] = self}
end

function MockClient:GetManagerAccountsObjects()
    return {['mdb_path'] = self}
end

function MockClient:GetFirmwareVerificationObjects()
    return {['mdb_path'] = self}
end

function MockClient:SetSpiMuxChannel(ctx)
end

function MockClient:ExportCustomCertificateHash(ctx, sign_mode)
    if sign_mode == 0 then
        return self.hash_pkcs and self.hash_pkcs or string.char(table.unpack(EMPYT_HASH))
    elseif sign_mode == 1 then
        return self.hash_pss and self.hash_pss or string.char(table.unpack(EMPYT_HASH))
    end
end

function MockClient:ImportCustomCertificateHash(ctx, hash)
    self.hash_pkcs = hash
    self.hash_pss = hash
end

function MockClient:ExportRepairCredentials(ctx)
    local repair = {
        212, 41, 3, 39, 20, 207, 229, 4, 212, 10, 210, 78, 10, 85, 124, 64, 67, 144, 14, 0, 0, 0, 0,
        0
    }
    return string.char(table.unpack(repair))
end

function MockClient:ImportRepairCredentials(ctx, repair_credential)
    self.repair_sign = repair_credential
end

function MockClient:GetUidGidByUserName()
    return 502, 204
end

function MockClient:StartTransfer()
    return math.random(1,1000000)
end

local clz = Singleton(MockClient)

local PMockClient = class()

function PMockClient:ctor()
    self.base = clz.new()
end

function PMockClient:SetSpiMuxChannel()
    return pcall(self.base.SetSpiMuxChannel, self.base)
end

function PMockClient:ExportCustomCertificateHash()
    return pcall(self.base.ExportCustomCertificateHash, self.base)
end

function PMockClient:ImportCustomCertificateHash()
    return pcall(self.base.ImportCustomCertificateHash, self.base)
end

function PMockClient:ExportRepairCredentials()
    return pcall(self.base.ExportRepairCredentials, self.base)
end

function PMockClient:ImportRepairCredentials()
    return pcall(self.base.ImportRepairCredentials, self.base)
end

function PMockClient:GetUidGidByUserName()
    return pcall(self.base.GetUidGidByUserName, self.base)
end

function PMockClient:StartTransfer()
    return pcall(self.base.StartTransfer, self.base)
end

function MockClient:GetAccountObjects()
    return {}
end

function MockClient:GetCertificateServiceObjects()
    return {}
end

function MockClient:GetCipherSuitObjects()
    return {}
end

function MockClient:ForeachCipherSuitObjects(cb)
    local obj = {Enabled=true, SuitName="ECDHE-ECDSA-AES256-GCM-SHA384"}
    return cb(obj)
end

function MockClient:GetChannelNumberMappingsObjects()
    return {}
end

local client = clz.new()
client.pcall = PMockClient.new()

return client
