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
-- Description: 定制化和配置导入导出的父类

local class = require 'mc.class'

local session_service = require 'service.session_service'
local remote_group_collection = require 'domain.remote_group.remote_group_collection'
local ldap_config = require 'domain.ldap_config'
local ldap_controller_collection = require 'domain.ldap.ldap_controller_collection'
local authentication_config = require 'domain.authentication_config'
local authentication_service = require 'service.authentication'
local kerberos_config = require 'domain.kerberos_config'
local remote_group_service = require 'service.remote_group_service'

local ConfigMgmt = class()

function ConfigMgmt:ctor()
    -- 作为定制化和配置导入导出的父类，对这两个子类的共用对象实例化
    self.m_session_service = session_service.get_instance()
    self.m_ldap_controller_collection = ldap_controller_collection.get_instance()
    self.m_ldap_config = ldap_config.get_instance()
    self.m_remote_group_collection = remote_group_collection.get_instance()
    self.m_auth_config = authentication_config.get_instance()
    self.m_authentication_service = authentication_service.get_instance()
    self.m_kerberos_config = kerberos_config.get_instance()
    self.m_remote_group_service = remote_group_service.get_instance()
end

return ConfigMgmt
