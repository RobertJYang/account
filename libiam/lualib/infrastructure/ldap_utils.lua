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
local log = require 'mc.logging'
local utils_core = require 'utils.core'
local ldap_utils = {}

function ldap_utils:check_domain_name(domain_name)
    if domain_name == '' then
        return true
    end
    -- 域名结尾非连接号'-'
    if string.sub(domain_name, #domain_name, #domain_name) == '-' then
        log:error('Last domain name is [-]')
        return false
    end
    -- 分隔符.前一个字符不能为-
    local segement = domain_name:find("%.")
    if segement and domain_name:sub(segement - 1, segement - 1)  == '-' then
        log:error('There is [-] before segement of domain name')
        return false
    end
    -- 域名总长度不超过255
    -- 域名开头只能为数字与大小写字母
    -- 域名只能包含数字、大小写字母、-与.
    -- 点号之间、首个点号之前与最后一个点号之后的字符长度不超过63
    -- 分隔符.前一个字符不能为.
    local check_config = "^(?=^.{1,255}$)[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+$"
    if not utils_core.g_regex_match(check_config, domain_name) then
        log:error('Domain name is invalid')
        return false
    end
    return true
end

return ldap_utils