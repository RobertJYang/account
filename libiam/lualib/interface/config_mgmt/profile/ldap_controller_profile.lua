-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 配置导入导出时Ldap单个域相关项

local custom_msg = require 'messages.custom'

local LdapControllerProfile = {}

function LdapControllerProfile.set_ldap_controller_id(self, _, controller_id)
    if not self.m_ldap_controller_collection.m_controller_collection[controller_id] then
        error(custom_msg.InvalidValue('Id', controller_id))
    end
end

function LdapControllerProfile.get_ldap_controller_id(self, controller_id)
    if not self.m_ldap_controller_collection.m_controller_collection[controller_id] then
        return nil
    end
    return controller_id
end

function LdapControllerProfile.set_ldap_controller_enabled(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_enabled(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'Enabled', value)
end

function LdapControllerProfile.get_ldap_controller_enabled(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_enabled(controller_id)
end

function LdapControllerProfile.set_ldap_controller_hostaddr(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_hostaddr(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'HostAddr', value)
end

function LdapControllerProfile.get_ldap_controller_hostaddr(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_hostaddr(controller_id)
end

function LdapControllerProfile.set_ldap_controller_port(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_port(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'Port', value)
end

function LdapControllerProfile.get_ldap_controller_port(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_port(controller_id)
end

function LdapControllerProfile.set_ldap_controller_domain(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_domain(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'UserDomain', value)
end

function LdapControllerProfile.get_ldap_controller_domain(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_domain(controller_id)
end

function LdapControllerProfile.set_ldap_controller_cert_verify_enabled(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_cert_verify_enabled(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'CertVerifyEnabled', value)
end

function LdapControllerProfile.get_ldap_controller_cert_verify_enabled(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_cert_verify_enabled(controller_id)
end

function LdapControllerProfile.set_ldap_controller_cert_verify_level(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_cert_verify_level(ctx, controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'CertVerifyLevel', value)
end

function LdapControllerProfile.get_ldap_controller_cert_verify_level(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_cert_verify_level(controller_id)
end

function LdapControllerProfile.set_ldap_controller_folder(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_folder(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'Folder', value)
end

function LdapControllerProfile.get_ldap_controller_folder(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_folder(controller_id)
end

function LdapControllerProfile.set_ldap_controller_bind_dn(self, ctx, controller_id, value)
    self.m_ldap_controller_collection:set_ldap_controller_bind_dn(controller_id, value)
    self.m_ldap_controller_collection.m_ldap_controller_changed:emit(controller_id, 'BindDN', value)
end

function LdapControllerProfile.get_ldap_controller_bind_dn(self, controller_id)
    return self.m_ldap_controller_collection:get_ldap_controller_bind_dn(controller_id)
end

return LdapControllerProfile