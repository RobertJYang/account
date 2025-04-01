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
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local cls_mng = require 'mc.class_mgnt'
local context = require 'mc.context'
local base_msg = require 'messages.base'
local operation_logger = require 'interface.operation_logger'

local INTERFACE_ACCOUNT_POLICY = 'bmc.kepler.AccountService.AccountPolicy'

local c_object = require 'mc.orm.object'
local account_policy_obj = c_object('AccountPolicy')

-- ORM会尝试调用create_mdb_object将模型类上库
-- 手动实现用户的各模型类create_mdb_object, 避免刷日志
function account_policy_obj.create_mdb_object(value)
    return value
end

local account_policy_mdb = class()

function account_policy_mdb:ctor(m_account_config)
    self.m_account_config = m_account_config
end

function account_policy_mdb:init()
    local config_mdb = {}
    local global_config = self.m_account_config
    config_mdb.NamePattern = global_config:get_name_pattern()
    self:new_config_to_mdb_tree(config_mdb)

    self.m_account_config.m_account_policy.m_config_changed:on(function(...)
        self:config_mdb_update(...)
    end)
end

-- 属性监听钩子
account_policy_mdb.watch_property_hook = {
    NamePattern = operation_logger.proxy(function(self, ctx, value)
        self.m_account_config:set_name_pattern(value)
    end, 'NamePatternChange')
}

function account_policy_mdb:watch_service_property(service)
    service[INTERFACE_ACCOUNT_POLICY].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change the manager accounts policy property(%s) to value(%s), sender is nil',
                name, tostring(value))
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

function account_policy_mdb:new_config_to_mdb_tree(user_config)
    local cls_config = cls_mng('LocalAccountPolicy'):get("/bmc/kepler/AccountService/AccountPolicies/Local")
    cls_config[INTERFACE_ACCOUNT_POLICY].NamePattern = user_config.NamePattern
    self:watch_service_property(cls_config)
end

function account_policy_mdb:config_mdb_update(property, value)
    local cls_config = cls_mng('LocalAccountPolicy'):get("/bmc/kepler/AccountService/AccountPolicies/Local")
    if cls_config[INTERFACE_ACCOUNT_POLICY][property] == nil then
        return
    end
    cls_config[INTERFACE_ACCOUNT_POLICY][property] = value
end

return singleton(account_policy_mdb)
