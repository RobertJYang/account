-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local enum = require 'class.types.types'

local role_to_privilege_map = {
    [enum.RoleType.NoAccess:value()] = enum.IpmiPrivilege.NO_ACCESS:value(),
    [enum.RoleType.CommonUser:value()] = enum.IpmiPrivilege.USER:value(),
    [enum.RoleType.Operator:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.Administrator:value()] = enum.IpmiPrivilege.ADMIN:value(),
    [enum.RoleType.CustomRole1:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole2:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole3:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole4:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole5:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole6:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole7:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole8:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole9:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole10:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole11:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole12:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole13:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole14:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole15:value()] = enum.IpmiPrivilege.OPERATOR:value(),
    [enum.RoleType.CustomRole16:value()] = enum.IpmiPrivilege.OPERATOR:value()
}

local privilege_to_role_map = {
    [enum.IpmiPrivilege.RESERVED:value()] = enum.RoleType.NoAccess:value(),
    [enum.IpmiPrivilege.CALLBACK:value()] = enum.RoleType.NoAccess:value(),
    [enum.IpmiPrivilege.USER:value()] = enum.RoleType.CommonUser:value(),
    [enum.IpmiPrivilege.OPERATOR:value()] = enum.RoleType.Operator:value(),
    [enum.IpmiPrivilege.ADMIN:value()] = enum.RoleType.Administrator:value(),
    [enum.IpmiPrivilege.OEM:value()] = enum.RoleType.NoAccess:value(),
    [enum.IpmiPrivilege.NO_ACCESS:value()] = enum.RoleType.NoAccess:value(),
}

local privilege_to_string_map = {
    [enum.IpmiPrivilege.RESERVED:value()] = "illegal level",
    [enum.IpmiPrivilege.CALLBACK:value()] = "callback",
    [enum.IpmiPrivilege.USER:value()] = "user",
    [enum.IpmiPrivilege.OPERATOR:value()] = "operator",
    [enum.IpmiPrivilege.ADMIN:value()] = "administrator",
    [enum.IpmiPrivilege.OEM:value()] = "oem",
    [enum.IpmiPrivilege.NO_ACCESS:value()] = "no access",
}

return {
    role_to_privilege_map = role_to_privilege_map,
    privilege_to_role_map = privilege_to_role_map,
    privilege_to_string_map = privilege_to_string_map
}
