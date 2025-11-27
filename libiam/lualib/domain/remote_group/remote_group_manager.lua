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
local class = require 'mc.class'
local log = require 'mc.logging'
local iam_utils = require 'utils'
local iam_enum = require 'class.types.types'
local remote_group_config = require 'domain.remote_group.remote_group_config'
local login_rule_collection = require 'domain.cache.login_rule_cache'
local role_collection = require 'domain.cache.role_cache'
local ldap_utils = require 'infrastructure.ldap_utils'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'

local OFFSET_WEB = 0 -- web,计算bit位移0
local OFFSET_SSH = 3 -- ssh,计算bit位移3
local OFFSET_REDFISH = 7 -- redfish,计算bit位移7

-- 远程认证组
local RemoteGroup = class()
function RemoteGroup:ctor(data)
    self.remote_group = data
    self.m_login_rule_collection = login_rule_collection.get_instance()
    self.m_role_collection = role_collection.get_instance()
end

function RemoteGroup:get_group()
    return self.remote_group
end

function RemoteGroup:package_group_auth_info(ldap_account_data)
    local result = {
        UserName       = ldap_account_data.account_name,
        Id             = ldap_account_data.account_id,
        LastLoginIP    = "",
        LastLoginTime  = 0,
        RoleId         = self.remote_group.UserRoleId,
        AccountType    = iam_enum.AccountType.LDAP,
        LoginInterface = ldap_account_data.login_interface,
        ControllerId = self:get_remote_group_controller_id(),
        ControllerInnerId = self:get_remote_group_controller_inner_id()
    }
    return result
end

function RemoteGroup:get_remote_group_type()
    return self.remote_group.GroupType
end

function RemoteGroup:get_remote_group_controller_id()
    return self.remote_group.ControllerId
end

function RemoteGroup:get_id()
    return self.remote_group.Id
end

function RemoteGroup:get_group_mdb_id()
    local mdb_id = string.format('%s%s_%s', self.remote_group.GroupType == 0 and 'LDAP' or 'Kerberos',
        self.remote_group.ControllerId, self.remote_group.ControllerInnerId)
    return mdb_id
end

function RemoteGroup:get_group_log_id()
    local log_id = string.format('%s%s group%s', self.remote_group.GroupType == 0 and 'LDAP' or 'Kerberos',
        self.remote_group.ControllerId, self.remote_group.ControllerInnerId)
    return log_id
end

function RemoteGroup:get_remote_group_controller_inner_id()
    return self.remote_group.ControllerInnerId
end

function RemoteGroup:get_remote_group_sid()
    return self.remote_group.SID
end

function RemoteGroup:set_remote_group_sid(value)
    if self.remote_group.GroupType == iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value() then
        log:info('LDAP Group do not set SID')
        return
    end

    if value == nil or value == '' then
        log:error('Set SID value failed,SID is null or length is 0.')
        error(base_msg.PropertyValueNotInList('%SID: ', '%SID'))
    end

    if string.find(value, " ", 1) ~= nil then
        log:error('Set SID value failed, input buf include Space char.')
        error(base_msg.PropertyValueFormatError('%SID:' .. value, '%SID'))
    end

    -- 必须是可见字符
    if iam_utils.contain_invisible_charactor(value) then
        error(custom_msg.InvalidValue(value, "SID"))
    end

    self.remote_group.SID = value
    self.remote_group:save()
end

function RemoteGroup:get_remote_group_name()
    return self.remote_group.Name
end

function RemoteGroup:set_remote_group_name(value)
    -- 组名不超过255
    if #value > remote_group_config.MAX_NAME_LENGTH then
        log:error("Name length too long")
        error(custom_msg.PropertyValueExceedsMaxLength(value, 'GroupName', '255'))
    end

    -- 组名首尾不可有空格
    if string.sub(value, 1, 1) == ' ' or string.sub(value, #value, #value) == ' ' then
        log:error("Set GroupName value failed, input buf include Space char in start or end.")
        error(base_msg.PropertyValueFormatError('%Name:' .. value, '%Name'))
    end

    -- 组名必须是可见字符
    if iam_utils.contain_invisible_charactor(value) then
        error(custom_msg.InvalidValue(value, "GroupName"))
    end

    self.remote_group.Name = value
    self.remote_group:save()
end

function RemoteGroup:get_remote_group_domain()
    return self.remote_group.Domain
end

function RemoteGroup:set_remote_group_domain(value)
    local ret = ldap_utils:check_domain_name(value)
    if not ret then
        log:error("check_domain_name failed")
        error(base_msg.PropertyValueFormatError('%GroupDomain:' .. value, 'GroupDomain'))
    end
    self.remote_group.Domain = value
    self.remote_group:save()
end

function RemoteGroup:get_role_id()
    return self.remote_group.UserRoleId
end

function RemoteGroup:set_remote_group_role_id(value)
    -- 非默认角色需校验角色是否存在
    if (value < iam_enum.RoleType.CommonUser:value() or value > iam_enum.RoleType.CustomRole4:value()) and
        not self.m_role_collection:get_role_data_by_id(value) then
        log:error("Invalied role[%d] to remote group[%d]", value, self.remote_group.Id)
        error(base_msg.PropertyValueNotInList('%UserRoleId:' .. 'Unknown', '%UserRoleId'))
    end
    self.remote_group.UserRoleId = value
    self.remote_group:save()
end

function RemoteGroup:get_remote_group_privilege()
    return self.remote_group.Privilege
end

function RemoteGroup:set_remote_group_privilege(value)
    -- 非默认角色需校验角色是否存在
    if (value < iam_enum.RoleType.CommonUser:value() or value > iam_enum.RoleType.CustomRole4:value()) and
        not self.m_role_collection:get_role_data_by_id(value) then
        log:error("Invalied role[%d] to remote group[%d]", value, self.remote_group.Id)
        error(base_msg.PropertyValueNotInList('%UserRoleId:' .. 'Unknown', '%UserRoleId'))
    end

    local privilege
    if value >= iam_enum.RoleType.CustomRole1:value() and value <= iam_enum.RoleType.CustomRole16:value() then
        privilege = iam_enum.IpmiPrivilege.OPERATOR:value()
    else
        privilege = value
    end

    self.remote_group.Privilege = privilege
    self.remote_group:save()
end

function RemoteGroup:get_remote_group_folder()
    return self.remote_group.Folder
end

function RemoteGroup:set_remote_group_folder(value)
    -- 组应用文件夹不超过255
    if #value > remote_group_config.MAX_NAME_LENGTH then
        log:error("Folder length too long")
        error(custom_msg.PropertyValueExceedsMaxLength(value, 'Folder', '255'))
    end

    -- 组文件夹首尾不可有空格
    if string.sub(value, 1, 1) == ' ' or string.sub(value, #value, #value) == ' ' then
        log:error("Set GroupFolder value failed, input buf include Space char in start or end.")
        error(base_msg.PropertyValueFormatError('%Folder:' .. value, '%Folder'))
    end

    -- 必须是可见字符
    if iam_utils.contain_invisible_charactor(value) then
        error(custom_msg.InvalidValue(value, "GroupFolder"))
    end

    self.remote_group.Folder = value
    self.remote_group:save()
end

function RemoteGroup:get_remote_group_privilege_mask()
    return self.remote_group.PrivilegeMask
end

function RemoteGroup:set_remote_group_privilege_mask(value)
    self.remote_group.PrivilegeMask = value
    self.remote_group:save()
end

function RemoteGroup:get_remote_group_permit_rule_ids()
    return self.remote_group.PermitRuleIdsDB
end

function RemoteGroup:set_remote_group_permit_rule_ids(value)
    -- 将规则id转为数字后，最大不超过7 = 1 + 2 + 4
    if value > remote_group_config.MAX_PERMIT_ID then
        log:error("Invalied PermitRuleIds[%d] to remote group[%d]", value, self.remote_group.Id)
        error(base_msg.InternalError())
    end

    self.remote_group.PermitRuleIdsDB = value
    self.remote_group:save()
end

function RemoteGroup:get_remote_group_login_interface()
    return self.remote_group.LoginInterfaceDB
end

local function check_ldap_group_login_interface(value)
    -- uint8，位移0~7位看bit
    for index = 0, 7 do
        local flag = iam_utils.user_login_interface_get_bit(value, index)

        if index ~= OFFSET_WEB and index ~= OFFSET_SSH and index ~= OFFSET_REDFISH and flag == 1 then
            return false
        end
    end

    return true
end

local function check_kerberos_group_login_interface(value)
    -- uint8，位移0~7位看bit
    for index = 0, 7 do
        local flag = iam_utils.user_login_interface_get_bit(value, index)

        if index ~= OFFSET_WEB and index ~= OFFSET_REDFISH and flag == 1 then
            return false
        end
    end

    return true
end

function RemoteGroup:set_remote_group_login_interface(value)
    -- 远程认证最多只涉及WEB、SSH、REDFISH这3个接口,对应值为10001001 = 137
    if value > remote_group_config.MAX_LOGIN_INTERFACE_ID then
        log:error("Invalied LoginInterface[%d] to remote group[%d]", value, self.remote_group.Id)
        error(base_msg.InternalError())
    end

    local flag
    if self.remote_group.GroupType == iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value() then
        flag = check_ldap_group_login_interface(value)
    elseif self.remote_group.GroupType == iam_enum.RemoteGroupType.GROUP_TYPE_KERBEROS:value() then
        flag = check_kerberos_group_login_interface(value)
    end

    if not flag then
        log:error("Set invalid LoginInterface %d to RemoteGroup[%d]", value, self.remote_group.Id)
        error(custom_msg.InvalidValue(value, 'LoginInterface'))
    end

    self.remote_group.LoginInterfaceDB = value
    self.remote_group:save()
end

--- 检查登录规则
---@param ip string
function RemoteGroup:check_login_rule(ip)
    local login_rule_ids = self.remote_group.PermitRuleIdsDB
    return self.m_login_rule_collection:check_login_rule(login_rule_ids, ip)
end

return RemoteGroup