local iam_enum = require 'class.types.types'

local role_to_privilege_map = {
    [iam_enum.RoleType.NoAccess:value()] = iam_enum.IpmiPrivilege.NO_ACCESS:value(),
    [iam_enum.RoleType.CommonUser:value()] = iam_enum.IpmiPrivilege.USER:value(),
    [iam_enum.RoleType.Operator:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.Administrator:value()] = iam_enum.IpmiPrivilege.ADMIN:value(),
    [iam_enum.RoleType.CustomRole1:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole2:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole3:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole4:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole5:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole6:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole7:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole8:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole9:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole10:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole11:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole12:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole13:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole14:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole15:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
    [iam_enum.RoleType.CustomRole16:value()] = iam_enum.IpmiPrivilege.OPERATOR:value(),
}

local privilege_to_role_map = {
    [iam_enum.IpmiPrivilege.RESERVED:value()] = iam_enum.RoleType.NoAccess:value(),
    [iam_enum.IpmiPrivilege.CALLBACK:value()] = iam_enum.RoleType.NoAccess:value(),
    [iam_enum.IpmiPrivilege.USER:value()] = iam_enum.RoleType.CommonUser:value(),
    [iam_enum.IpmiPrivilege.OPERATOR:value()] = iam_enum.RoleType.Operator:value(),
    [iam_enum.IpmiPrivilege.ADMIN:value()] = iam_enum.RoleType.Administrator:value(),
    [iam_enum.IpmiPrivilege.OEM:value()] = iam_enum.RoleType.NoAccess:value(),
    [iam_enum.IpmiPrivilege.NO_ACCESS:value()] = iam_enum.RoleType.NoAccess:value(),
}

local privilege_to_string_map = {
    [iam_enum.IpmiPrivilege.RESERVED:value()] = "illegal level",
    [iam_enum.IpmiPrivilege.CALLBACK:value()] = "callback",
    [iam_enum.IpmiPrivilege.USER:value()] = "user",
    [iam_enum.IpmiPrivilege.OPERATOR:value()] = "operator",
    [iam_enum.IpmiPrivilege.ADMIN:value()] = "administrator",
    [iam_enum.IpmiPrivilege.OEM:value()] = "oem",
    [iam_enum.IpmiPrivilege.NO_ACCESS:value()] = "no access",
}

return {
    role_to_privilege_map = role_to_privilege_map,
    privilege_to_role_map = privilege_to_role_map,
    privilege_to_string_map = privilege_to_string_map
}
