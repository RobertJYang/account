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
-- Description: 配置导入导出时Ldap公共配置相关项

local LdapConfigProfile = {}

function LdapConfigProfile.set_ldap_enabled(self, _, value)
    self.m_ldap_config:set_ldap_enabled(value)
    self.m_ldap_config.m_ldap_config_changed:emit('Enabled', value)
end

function LdapConfigProfile.get_ldap_enabled(self)
    return self.m_ldap_config:get_ldap_enabled()
end

return LdapConfigProfile