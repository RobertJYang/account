-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local mc_utils = require 'mc.utils'
local log = require 'mc.logging'
local context = require 'mc.context'
local singleton = require 'mc.singleton'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local service = require 'account.service'
local operation_logger = require 'interface.operation_logger'
local account_service_ipmi = require 'interface.ipmi.account_service_ipmi'

local snmp_community_mdb = class()

local INTERFACE_SNMP_COMMUNITY<const> = 'bmc.kepler.Managers.SnmpService.SnmpCommunity'
local RO_COMMUNITY_ID<const> = 20
local RW_COMMUNITY_ID<const> = 21

function snmp_community_mdb:ctor(account_service)
    self.m_account_service = account_service
    self.m_account_collection = self.m_account_service.m_account_collection
    self.m_account_config = self.m_account_service.m_account_config
    self.m_account_service_ipmi = account_service_ipmi.get_instance()
end

function snmp_community_mdb:init()
    self.m_snmp_community = service:CreateSnmpCommunity('1', function(community_config)
        local snmp_community_data = self.m_account_config.m_snmp_community
        community_config.LongCommunityEnabled = snmp_community_data.LongCommunityEnabled
        community_config.RwCommunityEnabled = snmp_community_data.RwCommunityEnabled
        self:watch_service_property(community_config)
    end)
    self.m_account_service_ipmi.m_update_config:on(function(...)
        self:snmp_community_config_mdb_update(...)
    end)
    self.m_account_service_ipmi.m_update_community:on(function(...)
        self:snmp_community_signal_emit()
    end)
end

-- 属性监听钩子
snmp_community_mdb.watch_property_hook = {
    LongCommunityEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { operation = value and 'Enable' or 'Disable' }
        self.m_account_config:set_long_community_enabled(value)
    end, 'LongCommunityEnabled'),
    RwCommunityEnabled = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { operation = value and 'Enable' or 'Disable' }
        self.m_account_config:set_rw_community_enabled(value)
    end, 'RwCommunityEnabled')
}

function snmp_community_mdb:watch_service_property(service)
    service[INTERFACE_SNMP_COMMUNITY].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the account service property(%s) to value(%s), sender is nil', name, tostring(value))
            return true
        end

        if not self.watch_property_hook[name] then
            log:error('change the property(%s) to value(%s), invalid', name, tostring(value))
            error(base_msg.InternalError())
        end

        log:info('change the property(%s) to value(%s)', name, tostring(value))
        local ctx = context.get_context() or context.new('WEB', 'NA', 'NA')
        self.watch_property_hook[name](self, ctx, value)
        return true
    end)
end

function snmp_community_mdb:snmp_community_signal_emit()
    local rw_community, ro_community = self:get_snmp_community()
    --- 传递给下游的方法需要去掉operationLog，否则在触发信号时会报错
    local temp_ctx = mc_utils.table_copy(context.get_context())
    temp_ctx.operation_log = nil
    context.with_context(temp_ctx, function()
        service:SnmpCommunitySnmpCommunitySnmpCommunityChangedSignal(self.m_snmp_community,
            ro_community, rw_community)
    end)
end

function snmp_community_mdb:set_ro_community(ctx, community)
    -- 长度为0即删除团体名流程
    if community and #community ~= 0 then
        -- 只读团体名不可以和读写团体名一致
        local rw_community = self:get_snmp_community()
        if rw_community == community then
            log:error('ROCommunityName is not allowed to be the same as the read-write community name')
            error(custom_msg.SameROCommunityName())
        end
    end
    local account = self.m_account_service:get_account_data_by_name(ctx.UserName)
    self.m_account_service:set_account_password(ctx, account.Id, RO_COMMUNITY_ID, community)
    self:snmp_community_signal_emit()
end

function snmp_community_mdb:set_rw_community(ctx, community)
    -- 长度为0即删除团体名流程
    if community and #community ~= 0 then
        -- 读写团体名不可以和只读团体名一致
        local _, ro_community = self:get_snmp_community()
        if ro_community == community then
            log:error('RWCommunityName is not allowed to be the same as the read-only community name')
            error(custom_msg.SameRWCommunityName())
        end
    end
    local account = self.m_account_service:get_account_data_by_name(ctx.UserName)
    self.m_account_service:set_account_password(ctx, account.Id, RW_COMMUNITY_ID, community)
    self:snmp_community_signal_emit()
end

function snmp_community_mdb:get_snmp_community()
    local ro_community = self.m_account_collection.collection[RO_COMMUNITY_ID]:get_account_password()
    local rw_community = self.m_account_collection.collection[RW_COMMUNITY_ID]:get_account_password()
    return rw_community, ro_community
end

function snmp_community_mdb:snmp_community_config_mdb_update(property, value)
    if self.m_snmp_community[INTERFACE_SNMP_COMMUNITY][property] == nil then
        return
    end
    self.m_snmp_community[INTERFACE_SNMP_COMMUNITY][property] = value
end

return singleton(snmp_community_mdb)