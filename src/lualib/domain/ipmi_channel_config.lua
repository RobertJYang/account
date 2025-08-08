-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local signal = require 'mc.signal'

local ipmi_channel_config = class()

function ipmi_channel_config:ctor(db)
    self.db = db
    self.collection = {}
end

function ipmi_channel_config:signals_init()
    self.m_channel_config_added = signal.new()
    self.m_channel_config_changed = signal.new()
    self.m_channel_config_removed = signal.new()
end

function ipmi_channel_config:init()
    self:signals_init()
    local ipmi_channel_config_list = self.db:select(self.db.IpmiChannelConfig)
    ipmi_channel_config_list:fold(function(row)
        if self.collection[row.AccountId] == nil then
            self.collection[row.AccountId] = {}
        end

        self.collection[row.AccountId][row.ChannelNumber] = row
    end)
end

--- 获取指定用户指定通道的ipmi通道配置表
function ipmi_channel_config:get(account_id, channel_number)
    return self.collection[account_id][channel_number] or {}
end

--- 插入指定用户指定通道配置信息
function ipmi_channel_config:insert(ipmi_channel_config_info, change_enable)
    local ipmi_channel_config_db = self.db:select(self.db.IpmiChannelConfig)
    -- 默认配置
    if change_enable ~= 1 then
        ipmi_channel_config_info.CallbackRestriction = 0
        ipmi_channel_config_info.LinkAuthenticationEnabled = true
        ipmi_channel_config_info.IpmiMessagingEnabled = true
    end
    local row_data = ipmi_channel_config_db.table({
        AccountId = ipmi_channel_config_info.AccountId,
        ChannelNumber = ipmi_channel_config_info.ChannelNumber,
        PrivilegeLimit = ipmi_channel_config_info.PrivilegeLimit,
        SessionLimit = ipmi_channel_config_info.SessionLimit,
        -- change_enable为0时,以下配置应保持默认
        CallbackRestriction = ipmi_channel_config_info.CallbackRestriction,
        LinkAuthenticationEnabled = ipmi_channel_config_info.LinkAuthenticationEnabled,
        IpmiMessagingEnabled = ipmi_channel_config_info.IpmiMessagingEnabled
    })
    row_data:save()
    if not self.collection[row_data.AccountId] then
        self.collection[row_data.AccountId] = {}
    end
    self.collection[row_data.AccountId][row_data.ChannelNumber] = row_data
    self.m_channel_config_added:emit(ipmi_channel_config_info)
end

--- 更新指定用户指定通道配置
function ipmi_channel_config:update(ipmi_channel_config_info, change_enable)
    local account_id = ipmi_channel_config_info.AccountId
    local channel_number = ipmi_channel_config_info.ChannelNumber
    local ipmi_channel_config_list = self:get(account_id, channel_number)
    if ipmi_channel_config_list then
        ipmi_channel_config_list.PrivilegeLimit = ipmi_channel_config_info.PrivilegeLimit
        ipmi_channel_config_list.SessionLimit = ipmi_channel_config_info.SessionLimit
        -- changeable = 0 时以下字段保持原有配置
        if change_enable == 1 then
            ipmi_channel_config_list.CallbackRestriction = ipmi_channel_config_info.CallbackRestriction
            ipmi_channel_config_list.LinkAuthenticationEnabled = ipmi_channel_config_info.LinkAuthenticationEnabled
            ipmi_channel_config_list.IpmiMessagingEnabled = ipmi_channel_config_info.IpmiMessagingEnabled
        end
        ipmi_channel_config_list:save()
        self.m_channel_config_changed:emit(account_id, channel_number,
                "PrivilegeLimit", ipmi_channel_config_list.PrivilegeLimit)
        self.m_channel_config_changed:emit(account_id, channel_number,
            "SessionLimit", ipmi_channel_config_list.SessionLimit)
        self.m_channel_config_changed:emit(account_id, channel_number,
            "CallbackRestriction", ipmi_channel_config_list.CallbackRestriction)
        self.m_channel_config_changed:emit(account_id, channel_number,
            "LinkAuthenticationEnabled", ipmi_channel_config_list.LinkAuthenticationEnabled)
        self.m_channel_config_changed:emit(account_id, channel_number,
            "IpmiMessagingEnabled", ipmi_channel_config_list.IpmiMessagingEnabled)
        return
    end
    -- 通道配置不存在则新增
    self:insert(ipmi_channel_config_info, change_enable)
end

--- 删除指定用户通道配置
function ipmi_channel_config:delete(account_id)
    self.db:delete(self.db.IpmiChannelConfig):where(self.db.IpmiChannelConfig.AccountId:eq(account_id)):all()
    self.collection[account_id] = nil
    self.m_channel_config_removed:emit(account_id)
end

--- 获取指定通道使能用户数量
function ipmi_channel_config:get_enabled_user_number_on_channel(channel_number)
    local ipmi_channel_config_list = self.db:select(self.db.IpmiChannelConfig)
        :where(self.db.IpmiChannelConfig.ChannelNumber:eq(channel_number)):all()
    local enable_num = 0
    if ipmi_channel_config_list and #ipmi_channel_config_list ~= 0 then
        for _, row in ipairs(ipmi_channel_config_list) do
            if row.IpmiMessagingEnabled == true then
                enable_num = enable_num + 1
            end
        end
    else
        enable_num = 1
    end
    return enable_num
end

--- 获取所有通道配置
function ipmi_channel_config:get_all_channel_config()
    local ipmi_channel_config_list = self.db:select(self.db.IpmiChannelConfig):all()
    return ipmi_channel_config_list or {}
end

return ipmi_channel_config