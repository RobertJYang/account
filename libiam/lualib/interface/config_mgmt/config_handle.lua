-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 管理配置导入导出和定制化操作

local class = require 'mc.class'
local log = require 'mc.logging'
local cjson = require 'cjson'
local mdb_config_manage = require 'mc.mdb.micro_component.config_manage'

-- iam管理account相关的导入导出配置

local ConfigHandle = class()

function ConfigHandle:ctor()
    self.account_config_adapter = nil
    self.m_config_dump = nil
    self.m_config_type = nil
end

function ConfigHandle:init()
    mdb_config_manage.on_import(function(...) return self:on_import(...) end)
    mdb_config_manage.on_export(function(...) return self:on_export(...) end)
    mdb_config_manage.on_get_trusted_config(function(...) return self:on_get_trusted_config(...) end)
end

function ConfigHandle:on_import(ctx, config_data, import_type)
    if not self.m_config_type then
        local custom_settings = require 'interface.config_mgmt.manufacture.customization.custom_settings'
        local profile_adapter = require 'interface.config_mgmt.profile.profile_adapter'
        -- custom表示定制化，configuration表示配置导入导出
        self.m_config_type = {
            ['custom'] = custom_settings,
            ['configuration'] = profile_adapter
        }
    end
    if not self.m_config_type[import_type] then
        log:error('Import type(%s) is invalid', import_type)
        return
    end

    if not config_data then
        log:error('Import data is nil')
        return
    end
    local object = cjson.decode(config_data).ConfigData
    if not object then
        log:error('Import data is invalid')
        return
    end

    self.config_service = self.m_config_type[import_type].get_instance()
    self.config_service:init_remote_group_id_collection()
    self.config_service:on_import(ctx, object)
    -- 将数据发送给account组件
    if not self.account_config_adapter then
        local account_config_adapter = require 'interface.config_mgmt.account_config_adapter'
        self.account_config_adapter = account_config_adapter.get_instance()
    end

    self.account_config_adapter:on_import(ctx, config_data, import_type)
end

function ConfigHandle:on_export(ctx, export_type)
    if not self.m_config_type then
        local custom_settings = require 'interface.config_mgmt.manufacture.customization.custom_settings'
        local profile_adapter = require 'interface.config_mgmt.profile.profile_adapter'
        -- custom表示定制化，configuration表示配置导入导出
        self.m_config_type = {
            ['custom'] = custom_settings,
            ['configuration'] = profile_adapter
        }
    end

    if not self.m_config_type[export_type] then
        log:error('Export type(%s) is invalid', export_type)
        return
    end

    self.config_service = self.m_config_type[export_type].get_instance()
    self.config_service:init_remote_group_id_collection()
    local data = self.config_service:on_export(ctx)

    return cjson.encode({ ConfigData = data })
end

function ConfigHandle:on_get_trusted_config(ctx)
    if not self.m_config_dump then
        local config_dump = require 'interface.config_mgmt.security_config.config_dump'
        self.m_config_dump = config_dump.get_instance()
    end

    local data = self.m_config_dump:dump(ctx)

    return cjson.json_object_ordered_encode(data)
end

return ConfigHandle