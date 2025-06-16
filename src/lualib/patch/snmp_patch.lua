-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

local sqlite3 = require 'lsqlite3'
local enum = require 'class.types.types'
local log = require 'mc.logging'

local snmp_patch = {}
function snmp_patch.exec(persist, db)
    local stmt_snmp_info = db:select(db.SNMPUserInfo)
    stmt_snmp_info:fold(function (snmp_info)
        if snmp_info.AccountId == 2 and
            snmp_info.AuthenticationProtocol == enum.SNMPAuthenticationProtocols.SHA256 and
            string.len(snmp_info.AuthenticationKey) == 128 then
            snmp_info.AuthenticationProtocol = enum.SNMPAuthenticationProtocols.SHA512
            snmp_info:save()
            log:notice("Because the authentication protocol of User 2 does not match then authentication key," ..
                "the authentication protocol has been corrected.")
        end

        -- 强制落盘
        if snmp_info.AccountId == 2 then
            persist:per_save(sqlite3.UPDATE, 't_snmp_user_info', {{'AccountId', snmp_info.AccountId}},
            {['AuthenticationProtocol'] = {value = snmp_info.AuthenticationProtocol:value(),
                                        persist_type = 'protect_power_off'}})
        end
    end)
end

return snmp_patch