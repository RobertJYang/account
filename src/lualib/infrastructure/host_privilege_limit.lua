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
local log = require 'mc.logging'
local Singleton = require 'mc.singleton'
local context = require 'mc.context'
local base_msg = require 'messages.base'
local enum = require 'class.types.types'
local client = require 'account.client'

local PATH_IPMI_CORE<const> = '/bmc/kepler/IpmiCore'

-- 权限类，管理host(主机侧/OS侧)能执行的命令权限
local host_privilege_limit = class()

function host_privilege_limit:ctor()
    self.ipmi_core_obj = nil
end

function host_privilege_limit:get_ipmi_core_obj()
    if not self.ipmi_core_obj then
        local objs = client:GetIpmiCoreObjects()
        -- 一般情况下，只有一个对象
        for path, obj in pairs(objs) do
            if path == PATH_IPMI_CORE then
                self.ipmi_core_obj = obj
            end
        end
    end
    return self.ipmi_core_obj
end

function host_privilege_limit:set_host_privilege_limited(ctx, status)
    local obj = self:get_ipmi_core_obj()
    local privilege = {}
    local multihost = 0
    if not status then
        privilege = {tostring(enum.PrivilegeType.UserMgmt),
            tostring(enum.PrivilegeType.SecurityMgmt),
            tostring(enum.PrivilegeType.DiagnoseMgmt)}
    end

    local host_privilege_ctx = context.get_context_or_default()
    local ok, exec_ret, reason = obj.pcall:SetHostPrivilegeLimited(host_privilege_ctx, tostring(multihost), privilege)
    if not ok then
        log:error("Pcall set host privilege limited failed, %s", exec_ret)
        ctx.operation_log.result = 'fail'
        error(base_msg.InternalError())
    end
    if not exec_ret then
        log:error("Set host privilege limited failed, multihost = %d, status = %d, reason = %s",
            multihost, status, reason)
        ctx.operation_log.result = 'fail'
        error(base_msg.InternalError())
    end
    log:notice("Set host privilege limited success, multihost = %d, status = %s", multihost, status)
    return 
end

return Singleton(host_privilege_limit)