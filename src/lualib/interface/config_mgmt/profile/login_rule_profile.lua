-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 配置导入导出时登陆规则相关项
local custom_msg = require 'messages.custom'

local LoginRuleProfile = {}

local function convert_rule_name_to_id(rule_name)
    local rule_name_map = {
        Rule1 = 1,
        Rule2 = 2,
        Rule3 = 3
    }
    return rule_name_map[rule_name]
end

function LoginRuleProfile.set_rule_id(self, ctx, rule_id)
    if not convert_rule_name_to_id(rule_id) then
        error(custom_msg.InvalidValue('Id', rule_id))
    end
end

function LoginRuleProfile.get_rule_id(self, rule_name)
    local rule_id = convert_rule_name_to_id(rule_name)
    if not self.m_rule_collection.m_login_rule_collection[rule_id] then
        return nil
    end
    return rule_name
end

function LoginRuleProfile.set_enable(self, ctx, rule_name, value)
    local rule_id = convert_rule_name_to_id(rule_name)
    ctx.operation_log.params.id = rule_id
    self.m_rule_collection:set_enable(rule_id, value)
end

function LoginRuleProfile.get_enable(self, rule_name)
    local rule_id = convert_rule_name_to_id(rule_name)
    return self.m_rule_collection:get_enable(rule_id)
end

function LoginRuleProfile.set_ip_rule(self, ctx, rule_name, value)
    local rule_id = convert_rule_name_to_id(rule_name)
    ctx.operation_log.params.id = rule_id
    self.m_rule_collection:set_ip_rule(rule_id, value)
    self.m_rule_collection.m_login_rule_update:emit(rule_id, 'IpRule', value)
end

function LoginRuleProfile.get_ip_rule(self, rule_name)
    local rule_id = convert_rule_name_to_id(rule_name)
    return self.m_rule_collection:get_ip_rule(rule_id)
end

function LoginRuleProfile.set_mac_rule(self, ctx, rule_name, value)
    local rule_id = convert_rule_name_to_id(rule_name)
    ctx.operation_log.params.id = rule_id
    self.m_rule_collection:set_mac_rule(rule_id, value)
    self.m_rule_collection.m_login_rule_update:emit(rule_id, 'MacRule', value)
end

function LoginRuleProfile.get_mac_rule(self, rule_name)
    local rule_id = convert_rule_name_to_id(rule_name)
    return self.m_rule_collection:get_mac_rule(rule_id)
end

function LoginRuleProfile.set_time_rule(self, ctx, rule_name, value)
    local rule_id = convert_rule_name_to_id(rule_name)
    ctx.operation_log.params.id = rule_id
    self.m_rule_collection:set_time_rule(rule_id, value)
    self.m_rule_collection.m_login_rule_update:emit(rule_id, 'TimeRule', value)
end

function LoginRuleProfile.get_time_rule(self, rule_name)
    local rule_id = convert_rule_name_to_id(rule_name)
    return self.m_rule_collection:get_time_rule(rule_id)
end

return LoginRuleProfile