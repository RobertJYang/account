-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 管理配置导入导出和定制化操作

local class = require 'mc.class'
local log = require 'mc.logging'
local utils_core = require 'utils.core'
local vos = require 'utils.vos'
local cjson = require 'cjson'
local base_messages = require 'messages.base'
local custom_messages = require 'messages.custom'
local mdb_config_manage = require 'mc.mdb.micro_component.config_manage'
local custom_settings = require 'interface.config_mgmt.manufacture.customization.custom_settings'
local profile_adapter = require 'interface.config_mgmt.profile.profile_adapter'
local account_colletion = require 'domain.account_collection'
local config_dump = require 'interface.config_mgmt.security_config.config_dump'
local kmc_client = require 'infrastructure.kmc_client'
local utils = require 'mc.utils'
local config = require 'common_config'
local file_proxy = require 'infrastructure.file_proxy'
local file_synchronization = require 'domain.file_synchronization'

local ConfigHandle = class()

function ConfigHandle:ctor()
    self.account_collection = account_colletion.get_instance()
    self.m_kmc_client = kmc_client.get_instance()
end

-- custom表示定制化，configuration表示配置导入导出
local config_type = {
    ['custom'] = custom_settings,
    ['configuration'] = profile_adapter
}

function ConfigHandle:init()
    mdb_config_manage.on_import(function(...) return self:on_import(...) end)
    mdb_config_manage.on_export(function(...) return self:on_export(...) end)
    mdb_config_manage.on_backup(function(...) return self:on_backup(...) end)
    mdb_config_manage.on_recover(function(...) return self:on_recover(...) end)
    mdb_config_manage.on_get_trusted_config(function(...) return self:on_get_trusted_config(...) end)
    mdb_config_manage.on_get_preserved_config(function(...) return self:on_get_preserved_config(...)end)
end

function ConfigHandle:on_import(ctx, config_data, import_type)
    if not config_type[import_type] then
        log:error('Import type(%s) is invalid', import_type)
        return
    end

    if not config_data then
        log:error('Import data is nil')
        return
    end
    local object = cjson.decode(config_data).ConfigData
    if not object then
        log:notice('No ConfigData in config.json, nothing to import')
        return
    end

    self.config_service = config_type[import_type].get_instance()
    self.config_service:on_import(ctx, object)
end

function ConfigHandle:on_export(ctx, export_type)
    if not config_type[export_type] then
        log:error('Export type(%s) is invalid', export_type)
        return
    end

    self.config_service = config_type[export_type].get_instance()
    local data = self.config_service:on_export(ctx)

    return cjson.encode({ ConfigData = data })
end

function ConfigHandle:on_backup(ctx, filepath)
    if not utils_core.is_dir(filepath) then
        error(custom_messages.InvalidValue('******', 'filepath'))
    end
    local res = {
        {'weakdictionary', '/data/trust/weakdictionary'},
        {'pam_faillock', '/data/trust/pam_faillock'}
    }

    -- 备份用户目录
    local m_file_synchronization = file_synchronization.get_instance()
    local backup_home_path = filepath .. '/home'
    local dir_mode = utils.S_IRWXU | utils.S_IRGRP | utils.S_IXGRP | utils.S_IROTH | utils.S_IXOTH
    if file_proxy.proxy_mkdir(backup_home_path, dir_mode, config.ROOT_USER_UID, config.ROOT_USER_GID) then
        m_file_synchronization:backup_user_file(backup_home_path)
    end

    for _, f in ipairs(res) do
        local name = f[1]
        local src_path = f[2]
        local dest_path = filepath .. '/' .. name
        local ok = file_proxy.proxy_copy(src_path, dest_path, config.SECBOX_USER_UID, config.SECBOX_USER_GID)
        if not ok then
            file_proxy.proxy_delete(dest_path)
            log:mcf_error('[config_manage] Backup %s to destination path failed', name)
            log:operation(ctx:get_initiator(), 'account',
                'Set persistence manufacturer default configuration failed')
            error(base_messages.InternalError())
        end
    end
    self.account_collection:backup_account_info()
    log:operation(ctx:get_initiator(), 'account', 'Set account manufacturer default configuration successfully')
    return res
end

local TRUST_HOME_DIR_PATH<const> = '/data/trust/home/'

function ConfigHandle:on_recover(ctx, preserve_list)
    local ok, err = pcall(vos.check_before_system_s, '/bin/rm', '-rf', '/data/trust/kerberos.pfx')
    if not ok then
        log:error('check_before_system_s failed, err: %s', err)
    end

    if preserve_list.PreserveUsers == "true" then
        file_proxy.proxy_tar('Compress', 'z', config.PRESERVE_CONFIG_FILE, config.PRESERVE_CONFIG_PATH, {'home'})
    end

    file_proxy.proxy_delete(TRUST_HOME_DIR_PATH)
    log:operation(ctx:get_initiator(), 'account', 'Recover manufacturer default configuration successfully')
end

function ConfigHandle:on_get_trusted_config(ctx)
    local data = config_dump.get_instance():dump(ctx)

    return cjson.json_object_ordered_encode(data)
end

function ConfigHandle:on_get_preserved_config(ctx, preserve_list)
    local data = {}
    if preserve_list.PreserveUsers == "true" then
        data = {
            DataBase = {
                't_manager_account',
                't_snmp_user_info',
                't_ipmi_user_info',
                't_account_service',
                't_account_backup',
                't_ipmi_channel_config'
            },
            DomainId = {
                self.m_kmc_client.m_domain_id
            }
        }
    end

    return cjson.encode(data)
end

return ConfigHandle