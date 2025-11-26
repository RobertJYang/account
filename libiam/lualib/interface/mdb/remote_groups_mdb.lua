-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.

local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local cls_mng = require 'mc.class_mgnt'
local context = require 'mc.context'
local base_msg = require 'messages.base'
local operation_logger = require 'interface.operation_logger'
local account_utils = require 'infrastructure.account_utils'
local utils = require 'utils'
local remote_group_service = require 'service.remote_group_service'
local remote_groups_config = require 'domain.remote_groups_config'

local INTERFACE_REMOTE_GROUPS = 'bmc.kepler.AccountService.RemoteGroups'

local c_object = require 'mc.orm.object'
local remote_groups_db_obj = c_object('RemoteGroupsDB')

-- ORM会尝试调用create_mdb_object将模型类上库
-- 手动实现用户的各模型类create_mdb_object, 避免刷日志
function remote_groups_db_obj.create_mdb_object(value)
    return value
end

local RemoteGroups = class()

function RemoteGroups:ctor()
    self.remote_group_service = remote_group_service.get_instance()
    self.remote_groups_config = remote_groups_config.get_instance()
end

function RemoteGroups:init()
    local config_mdb = {}
    config_mdb.AllowedLoginInterfaces =
        account_utils.convert_num_to_interface_str(self.remote_group_service:get_allowed_login_interfaces(), true)
    self:new_config_to_mdb_tree(config_mdb)
    self.remote_group_service.m_config_changed:on(function(...)
        self:config_mdb_update(...)
    end)
end

-- 属性监听钩子
RemoteGroups.watch_property_hook = {
    AllowedLoginInterfaces = operation_logger.proxy(function(self, ctx, value)
        ctx.operation_log.params = { interfaces = table.concat(value, ', ') }
        local interface_num = utils.cover_interface_str_to_num(value)
        if not utils.check_interface_info(value) then
            log:error('set allowed login interfaces failed, interfaces not supported')
            error(base_msg.PropertyValueNotInList(value, "LoginInterface"))
        end
        self.remote_groups_config:set_allowed_login_interfaces(interface_num)
    end, 'SetAllowedLoginInterfaces')
}

function RemoteGroups:watch_service_property(service)
    service[INTERFACE_REMOTE_GROUPS].property_before_change:on(function(name, value, sender)
        if not sender then
            log:info('change remote groups property(%s) to value(%s), sender is nil',
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

function RemoteGroups:new_config_to_mdb_tree(config)
    local cls_config = cls_mng('RemoteGroups'):get("/bmc/kepler/AccountService/RemoteGroups")
    cls_config[INTERFACE_REMOTE_GROUPS].AllowedLoginInterfaces = config.AllowedLoginInterfaces
    self:watch_service_property(cls_config)
end

function RemoteGroups:config_mdb_update(property, value)
    local cls_config = cls_mng('RemoteGroups'):get("/bmc/kepler/AccountService/RemoteGroups")
    if cls_config[INTERFACE_REMOTE_GROUPS][property] == nil then
        return
    end
    cls_config[INTERFACE_REMOTE_GROUPS][property] = value
end

return singleton(RemoteGroups)
