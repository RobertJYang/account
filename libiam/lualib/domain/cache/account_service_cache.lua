-- Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local enum = require 'class.types.types'

local account_service_cache = class()

function account_service_cache:ctor()
    self.cache = nil
    self.is_flush = false
end

-- 新增资源触发（除了首次应该不会触发）
function account_service_cache:new_account_service_cache(obj)
    self.cache = {}
    self.cache.HostUserManagementEnabled = obj.HostUserManagementEnabled
    self.cache.InitialPasswordNeedModify = obj.InitialPasswordNeedModify
    self.is_flush = true
end

-- 删除资源触发
function account_service_cache:del_account_service_cache()
    self.cache = nil
end

-- 缓存属性变更触发
function account_service_cache:edit_account_service_cache(property_name, property_value)
    self.cache[property_name] = property_value
end

-- 刷新缓存信息
function account_service_cache:flush_account_service_cache(obj)
    self.cache.HostUserManagementEnabled = obj.HostUserManagementEnabled
    self.cache.InitialPasswordNeedModify = obj.InitialPasswordNeedModify
    self.is_flush = true
end

-- 清理缓存的同步状态
function account_service_cache:clear_cache_flush_state()
    self.is_flush = false
end

function account_service_cache:clean_redundant_cache()
    if not self.is_flush then
        self.cache = nil
    end
end

-- 获取指定用户的缓存
function account_service_cache:get_account_service_cache()
    return self.cache
end

function account_service_cache:check_ipmi_host_user_mgnt_enabled(ipmi_ctx)
    if self.cache.HostUserManagementEnabled == true then
        return true
    end
    -- HostUserManagementEnabled is false
    local from_bt = ipmi_ctx.chan_num == enum.IpmiChannel.SYS_CHAN_NUM:value() or ipmi_ctx.chan_num == 21 or
                        ipmi_ctx.chan_num == 22 -- 21与22为BMC自定义bt通道
    local from_edma = ipmi_ctx.chan_num == enum.IpmiChannel.EDMA_CHAN_NUM:value()
    local from_ipmb_os = ipmi_ctx.chan_num == enum.IpmiChannel.IPMB_SM_CHAN_NUM:value()
    if from_bt or from_edma or from_ipmb_os then
        return false
    end
    -- 兼容历史代码
    if ipmi_ctx.ChanType == enum.IpmiChannelType.IPMI_HOST:value() then
        return false
    end
    return true
end

return singleton(account_service_cache)