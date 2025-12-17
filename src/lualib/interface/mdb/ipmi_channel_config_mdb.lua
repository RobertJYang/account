-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

local class = require 'mc.class'
local singleton = require 'mc.singleton'
local cls_mng = require 'mc.class_mgnt'
local c_object = require 'mc.orm.object'
local service = require 'account.service'

local INTERFACE_IPMI_CHANNEL_CONFIG = 'bmc.kepler.AccountService.ManagerAccount.IpmiChannelConfig'

local c_ipmi_channel_config_obj = c_object("IpmiChannelConfig")

function c_ipmi_channel_config_obj.create_mdb_object(value)
    return value
end

local ipmi_channel_config_mdb = class()

function ipmi_channel_config_mdb:ctor(ipmi_channel_config)
    self.m_ipmi_channel_config = ipmi_channel_config
    self.m_channel_config = {}
    self.m_mdb_cls = cls_mng("IpmiChannelConfig")
end

function ipmi_channel_config_mdb:regist_channel_config_signals()
    self.m_new_unregist_handle = self.m_ipmi_channel_config.m_channel_config_added:on(function(...)
        self:new_channel_config_to_mdb_tree(...)
    end)
    self.m_change_unregist_handle = self.m_ipmi_channel_config.m_channel_config_changed:on(function(...)
        self:update_channel_config_to_mdb(...)
    end)
    self.m_delete_unregist_handle = self.m_ipmi_channel_config.m_channel_config_removed:on(function(...)
        self:delete_channel_config_from_mdb_tree(...)
    end)
end

function ipmi_channel_config_mdb:init()
    -- 实现从IpmiChannelConfig表加载数据并上树
    local ipmi_channel_config_list = self.m_ipmi_channel_config:get_all_channel_config()
    if not ipmi_channel_config_list or not next(ipmi_channel_config_list) then
        return
    end
    for _, ipmi_channel_config in ipairs(ipmi_channel_config_list) do
        self:new_channel_config_to_mdb_tree(ipmi_channel_config)
    end
end

function ipmi_channel_config_mdb:update_channel_config_to_mdb(account_id, channel_number, property, value)
    local cls_config = cls_mng('IpmiChannelConfig'):get(
        "/bmc/kepler/AccountService/Accounts/" .. tostring(account_id) .. "/Channels/" .. tostring(channel_number))
    if cls_config[INTERFACE_IPMI_CHANNEL_CONFIG][property] == nil then
        return
    end
    cls_config[INTERFACE_IPMI_CHANNEL_CONFIG][property] = value
end

function ipmi_channel_config_mdb:new_channel_config_to_mdb_tree(ipmi_channel_config_info)
    local account_id = ipmi_channel_config_info.AccountId
    local channel_num = ipmi_channel_config_info.ChannelNumber
    local channel_config = service:CreateIpmiChannelConfig(tostring(account_id), tostring(channel_num), function(obj)
        obj.PrivilegeLimit = ipmi_channel_config_info.PrivilegeLimit
        obj.IpmiMessagingEnabled = ipmi_channel_config_info.IpmiMessagingEnabled
        obj.LinkAuthenticationEnabled = ipmi_channel_config_info.LinkAuthenticationEnabled
        obj.CallbackRestriction = ipmi_channel_config_info.CallbackRestriction
        obj.SessionLimit = ipmi_channel_config_info.SessionLimit
    end)
    if not self.m_channel_config[account_id] then
        self.m_channel_config[account_id] = {}
    end
    self.m_channel_config[account_id][channel_num] = channel_config
end

function ipmi_channel_config_mdb:delete_channel_config_from_mdb_tree(account_id)
    if not self.m_channel_config[account_id] or next(self.m_channel_config[account_id]) == nil then
        return
    end
    for _, config in pairs(self.m_channel_config[account_id]) do
        self.m_mdb_cls:remove(config)
    end
    self.m_channel_config[account_id] = nil
end

return singleton(ipmi_channel_config_mdb)
