-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
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
local signal = require 'mc.signal'

-- LDAP配置
local LdapConfig = class()

function LdapConfig:ctor(db)
    self.m_config = db:select(db.LDAP):first()
    self.m_ldap_config_changed = signal.new()
    self.m_config_security_changed = signal.new()
end

-- LDAP公共配置
function LdapConfig:set_ldap_enabled(enable)
    self.m_config.Enabled = enable
    self.m_config:save()
    -- 仅在使能关闭时触发，使能从关闭到打开状态，不会有LDAP会话
    if not enable then
        self.m_config_security_changed:emit()
    end
end

function LdapConfig:get_ldap_enabled()
    return self.m_config.Enabled
end

return singleton(LdapConfig)