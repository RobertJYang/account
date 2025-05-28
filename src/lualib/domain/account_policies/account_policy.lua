-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'

local AccountPolicy = class()

function AccountPolicy:ctor(policy, global_account_config)
    self.data             = policy
    self.m_account_config = global_account_config
end

function AccountPolicy:get_obj()
    return self.data
end

function AccountPolicy:get_name_pattern()
    return self.data.NamePattern
end

function AccountPolicy:get_allowed_login_interfaces()
    return self.data.AllowedLoginInterfaces
end

function AccountPolicy:set_visible(value)
    self.data.Visible = value
    self.data:save()
end

function AccountPolicy:get_visible()
    return self.data.Visible
end

function AccountPolicy:set_deletable(value)
    self.data.Deletable = value
    self.data:save()
end

function AccountPolicy:get_deletable()
    return self.data.Deletable
end

return singleton(AccountPolicy)