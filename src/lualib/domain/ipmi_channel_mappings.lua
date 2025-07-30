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
local log = require 'mc.logging'
local client = require 'account.client'
local singleton = require 'mc.singleton'

local channel_number_mappings = class()

function channel_number_mappings:ctor()
    self.ch_num_maps = {}
    self.path_to_ch_num = {}
    -- 标识当前多通道还是单通道，0代表单通道，1代表多通道
    self.multi_channel_status = 0
end

function channel_number_mappings:init()
    self:init_ch_num_maps()
end

function channel_number_mappings:init_ch_num_maps()
    local map_objs = client:GetChannelNumberMappingsObjects()
    if not map_objs or next(map_objs) == nil then
        log:notice('Failed to get channel number mappings objects')
        return
    end
    for path, obj in pairs(map_objs) do
        self.ch_num_maps[obj.ExternalChannelNumber] = obj.InternalChannelNumber
        self.path_to_ch_num[path] = obj.ExternalChannelNumber
    end
    self.multi_channel_status = 1
end

function channel_number_mappings:channel_number_translation(ch_num)
    if not ch_num then
        return nil
    end
    for external_channel_num, internal_channle_num in pairs(self.ch_num_maps) do
        if external_channel_num == ch_num then
            return internal_channle_num
        elseif internal_channle_num == ch_num then
            return nil
        end
    end
    return ch_num
end

-- OnChannelNumberMappingsPropertiesChanged
function channel_number_mappings:on_channel_number_mappings_properties_changed(values, path)
    if not values['ExternalChannelNumber'] then
        return
    end
    local internal_channle_num = self.ch_num_maps[self.path_to_ch_num[path]]
    local external_channel_num = values['ExternalChannelNumber']:value()

    self.ch_num_maps[self.path_to_ch_num[path]] = nil
    self.path_to_ch_num[path] = external_channel_num
    self.ch_num_maps[external_channel_num] = internal_channle_num
end

-- OnChannelNumberMappingsInterfacesAdded
function channel_number_mappings:on_channel_number_mappings_interfaces_added(sender, path, values)
    local external_channel_num = values['ExternalChannelNumber']:value()
    self.ch_num_maps[external_channel_num] = values['InternalChannelNumber']:value()
    self.path_to_ch_num[path] = external_channel_num
    self.multi_channel_status = 1
end

-- OnChannelNumberMappingsInterfacesRemoved
function channel_number_mappings:on_channel_number_mappings_interfaces_removed(sender, path)
    self.ch_num_maps[self.path_to_ch_num[path]] = nil
    self.path_to_ch_num[path] = nil
    if not self.path_to_ch_num or next(self.path_to_ch_num) == nil then
        self.multi_channel_status = 0
    end   
end

return singleton(channel_number_mappings)