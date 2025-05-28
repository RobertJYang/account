-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local log = require 'mc.logging'
local error = require 'mc.error'
local new_error = error.new_error
local print_log = error.print_log
local print_trace = error.print_trace
local regist_err_eng = error.register_err

local M = {}

local AuthorizationFailed = {
    name = 'kepler.account.AuthorizationFailed',
    format = [=[Authorization failed because the user name or pass]=] ..
        [=[word is incorrect, or your account is locked.]=],
    severity = 'error'
}
M.AuthorizationFailed = AuthorizationFailed.name
---@return Error
function M.authorization_failed()
    local err_data = new_error(AuthorizationFailed.name, AuthorizationFailed.format)
    regist_err_eng(AuthorizationFailed, 401, nil, 0xCC)
    print_log(log.ERROR, AuthorizationFailed.format)
    return err_data
end

local InternalError = {name = 'kepler.account.InternalError', format = [=[Internal Error Met.]=], severity = 'error'}
M.InternalError = InternalError.name
---@return Error
function M.internal_error()
    local err_data = new_error(InternalError.name, InternalError.format)
    regist_err_eng(InternalError, 500, nil, 0xFF)
    print_log(log.ERROR, InternalError.format)
    return err_data
end

local InvalidAccountId = {
    name = 'kepler.account.InvalidAccountId',
    format = [=[The Account ID is invalid.]=],
    severity = 'error'
}
M.InvalidAccountId = InvalidAccountId.name
---@return Error
function M.invalid_account_id()
    local err_data = new_error(InvalidAccountId.name, InvalidAccountId.format)
    regist_err_eng(InvalidAccountId, 401, nil, 0xC9)
    print_log(log.ERROR, InvalidAccountId.format)
    return err_data
end

local AuthTypeNotSupport = {
    name = 'kepler.account.AuthTypeNotSupport',
    format = [=[The authentication mode is not supported.]=],
    severity = 'error'
}
M.AuthTypeNotSupport = AuthTypeNotSupport.name
---@return Error
function M.auth_type_not_support()
    local err_data = new_error(AuthTypeNotSupport.name, AuthTypeNotSupport.format)
    regist_err_eng(AuthTypeNotSupport, 401, nil, 0xFF)
    print_log(log.ERROR, AuthTypeNotSupport.format)
    return err_data
end

local AuthAlgoNotSupport = {
    name = 'kepler.account.AuthAlgoNotSupport',
    format = [=[The authentication algorithm is not supported.]=],
    severity = 'error'
}
M.AuthAlgoNotSupport = AuthAlgoNotSupport.name
---@return Error
function M.auth_algo_not_support()
    local err_data = new_error(AuthAlgoNotSupport.name, AuthAlgoNotSupport.format)
    regist_err_eng(AuthAlgoNotSupport, 401, nil, 0xFF)
    print_log(log.ERROR, AuthAlgoNotSupport.format)
    return err_data
end

local SessionTypeNotSupport = {
    name = 'kepler.account.SessionTypeNotSupport',
    format = [=[The session type is not supported.]=],
    severity = 'error'
}
M.SessionTypeNotSupport = SessionTypeNotSupport.name
---@return Error
function M.session_type_not_support()
    local err_data = new_error(SessionTypeNotSupport.name, SessionTypeNotSupport.format)
    regist_err_eng(SessionTypeNotSupport, 401, nil, 0xFF)
    print_log(log.ERROR, SessionTypeNotSupport.format)
    return err_data
end

local SessionTimeout = {
    name = 'kepler.account.SessionTimeout',
    format = [=[The session has timed out, please log in again.]=],
    severity = 'error'
}
M.SessionTimeout = SessionTimeout.name
---@return Error
function M.session_timeout()
    local err_data = new_error(SessionTimeout.name, SessionTimeout.format)
    regist_err_eng(SessionTimeout, 401, nil, 0xFF)
    print_log(log.ERROR, SessionTimeout.format)
    return err_data
end

local NoValidSession = {
    name = 'kepler.account.NoValidSession',
    format = [=[There is no valid session established with the imp]=] .. [=[lementation.]=],
    severity = 'error'
}
M.NoValidSession = NoValidSession.name
---@return Error
function M.no_valid_session()
    local err_data = new_error(NoValidSession.name, NoValidSession.format)
    regist_err_eng(NoValidSession, 401, nil, 0xFF)
    print_log(log.ERROR, NoValidSession.format)
    return err_data
end

local SessionKickout = {
    name = 'kepler.account.SessionKickout',
    format = [=[You have been forced to log out by the system admi]=] .. [=[nistrator.]=],
    severity = 'error'
}
M.SessionKickout = SessionKickout.name
---@return Error
function M.session_kickout()
    local err_data = new_error(SessionKickout.name, SessionKickout.format)
    regist_err_eng(SessionKickout, 401, nil, 0xFF)
    print_log(log.ERROR, SessionKickout.format)
    return err_data
end

local SessionRelogin = {
    name = 'kepler.account.SessionRelogin',
    format = [=[Your account has been logged in elsewhere.]=],
    severity = 'error'
}
M.SessionRelogin = SessionRelogin.name
---@return Error
function M.session_relogin()
    local err_data = new_error(SessionRelogin.name, SessionRelogin.format)
    regist_err_eng(SessionRelogin, 401, nil, 0xFF)
    print_log(log.ERROR, SessionRelogin.format)
    return err_data
end

local SessionChanged = {
    name = 'kepler.account.SessionChanged',
    format = [=[Account information has been modified, please log ]=] .. [=[in again.]=],
    severity = 'error'
}
M.SessionChanged = SessionChanged.name
---@return Error
function M.session_changed()
    local err_data = new_error(SessionChanged.name, SessionChanged.format)
    regist_err_eng(SessionChanged, 401, nil, 0xFF)
    print_log(log.ERROR, SessionChanged.format)
    return err_data
end

local SessionLimitExceeded = {
    name = 'kepler.account.SessionLimitExceeded',
    format = [=[Exceeded the maximum number of sessions.]=],
    severity = 'error'
}
M.SessionLimitExceeded = SessionLimitExceeded.name
---@return Error
function M.session_limit_exceeded()
    local err_data = new_error(SessionLimitExceeded.name, SessionLimitExceeded.format)
    regist_err_eng(SessionLimitExceeded, 401, nil, 0xFF)
    print_log(log.ERROR, SessionLimitExceeded.format)
    return err_data
end

local SessionStillAlive = {
    name = 'kepler.account.SessionStillAlive',
    format = [=[The session is still alive.]=],
    severity = 'error'
}
M.SessionStillAlive = SessionStillAlive.name
---@return Error
function M.session_still_alive()
    local err_data = new_error(SessionStillAlive.name, SessionStillAlive.format)
    regist_err_eng(SessionStillAlive, 401, nil, 0xFF)
    print_log(log.ERROR, SessionStillAlive.format)
    return err_data
end

local ResourceAlreadyExists = {
    name = 'kepler.account.ResourceAlreadyExists',
    format = [=[The user already exists.]=],
    severity = 'error'
}
M.ResourceAlreadyExists = ResourceAlreadyExists.name
---@return Error
function M.resource_already_exists()
    local err_data = new_error(ResourceAlreadyExists.name, ResourceAlreadyExists.format)
    regist_err_eng(ResourceAlreadyExists, 401, nil, 0x80)
    print_log(log.ERROR, ResourceAlreadyExists.format)
    return err_data
end

local UnSupported = {name = 'kepler.account.UnSupported', format = [=[The operate not supported.]=], severity = 'error'}
M.UnSupported = UnSupported.name
---@return Error
function M.un_supported()
    local err_data = new_error(UnSupported.name, UnSupported.format)
    regist_err_eng(UnSupported, 401, nil, 0xD5)
    print_log(log.ERROR, UnSupported.format)
    return err_data
end

local InvalidParameter = {
    name = 'kepler.account.InvalidParameter',
    format = [=[The parameter is invalid.]=],
    severity = 'error'
}
M.InvalidParameter = InvalidParameter.name
---@return Error
function M.invalid_parameter()
    local err_data = new_error(InvalidParameter.name, InvalidParameter.format)
    regist_err_eng(InvalidParameter, 401, nil, 0xC1)
    print_log(log.ERROR, InvalidParameter.format)
    return err_data
end

local InvalidUserName = {
    name = 'kepler.account.InvalidUserName',
    format = [=[The user name is invalid]=],
    severity = 'error'
}
M.InvalidUserName = InvalidUserName.name
---@return Error
function M.invalid_user_name()
    local err_data = new_error(InvalidUserName.name, InvalidUserName.format)
    regist_err_eng(InvalidUserName, 401, nil, 0xC1)
    print_log(log.ERROR, InvalidUserName.format)
    return err_data
end

local ExclusiveMode = {
    name = 'kepler.account.ExclusiveMode',
    format = [=[The session is already exclusive or already exists]=] .. [=[ session cannot be created exclusive.]=],
    severity = 'error'
}
M.ExclusiveMode = ExclusiveMode.name
---@return Error
function M.exclusive_mode()
    local err_data = new_error(ExclusiveMode.name, ExclusiveMode.format)
    regist_err_eng(ExclusiveMode, 401, nil, 0xFF)
    print_log(log.ERROR, ExclusiveMode.format)
    return err_data
end

local PasswordComplexityCheckFail = {
    name = 'kepler.account.PasswordComplexityCheckFail',
    format = [=[The property does not meet the password complexity]=] .. [=[ requirements.]=],
    severity = 'error'
}
M.PasswordComplexityCheckFail = PasswordComplexityCheckFail.name
---@return Error
function M.password_complexity_check_fail()
    local err_data = new_error(PasswordComplexityCheckFail.name, PasswordComplexityCheckFail.format)
    regist_err_eng(PasswordComplexityCheckFail, 401, nil, 0x84)
    print_log(log.ERROR, PasswordComplexityCheckFail.format)
    return err_data
end

local UnlockUserFail = {
    name = 'kepler.account.UnlockUserFail',
    format = [=[Fail to unlock the user.]=],
    severity = 'error'
}
M.UnlockUserFail = UnlockUserFail.name
---@return Error
function M.unlock_user_fail()
    local err_data = new_error(UnlockUserFail.name, UnlockUserFail.format)
    regist_err_eng(UnlockUserFail, 401, nil, 0x85)
    print_log(log.ERROR, UnlockUserFail.format)
    return err_data
end

local InvalidPasswordSameWithHistory = {
    name = 'kepler.account.InvalidPasswordSameWithHistory',
    format = [=[The property can not same with history password.]=],
    severity = 'error'
}
M.InvalidPasswordSameWithHistory = InvalidPasswordSameWithHistory.name
---@return Error
function M.invalid_password_same_with_history()
    local err_data = new_error(InvalidPasswordSameWithHistory.name, InvalidPasswordSameWithHistory.format)
    regist_err_eng(InvalidPasswordSameWithHistory, 401, nil, 0x93)
    print_log(log.ERROR, InvalidPasswordSameWithHistory.format)
    return err_data
end

local IpmiPasswordEmpty = {
    name = 'kepler.account.IpmiPasswordEmpty',
    format = [=[The password for IPMI is empty, please set passwor]=] .. [=[d.]=],
    severity = 'error'
}
M.IpmiPasswordEmpty = IpmiPasswordEmpty.name
---@return Error
function M.ipmi_password_empty()
    local err_data = new_error(IpmiPasswordEmpty.name, IpmiPasswordEmpty.format)
    regist_err_eng(IpmiPasswordEmpty, 401, nil, 0x94)
    print_log(log.ERROR, IpmiPasswordEmpty.format)
    return err_data
end

local NoAccess = {
    name = 'kepler.account.NoAccess',
    format = [=[Login failed because the user has no permission or]=] ..
        [=[ is disabled, or the redfish interface is disabled]=] .. [=[.]=],
    severity = 'error'
}
M.NoAccess = NoAccess.name
---@return Error
function M.no_access()
    local err_data = new_error(NoAccess.name, NoAccess.format)
    regist_err_eng(NoAccess, 401, nil, 0xFF)
    print_log(log.ERROR, NoAccess.format)
    return err_data
end

local PasswordNeedReset = {
    name = 'kepler.account.PasswordNeedReset',
    format = [=[This password is an initial password or has been c]=] ..
        [=[hanged by another administrator. Please reset the ]=] .. [=[password for security purposes.]=],
    severity = 'error'
}
M.PasswordNeedReset = PasswordNeedReset.name
---@return Error
function M.password_need_reset()
    local err_data = new_error(PasswordNeedReset.name, PasswordNeedReset.format)
    regist_err_eng(PasswordNeedReset, 401, nil, 0x96)
    print_log(log.ERROR, PasswordNeedReset.format)
    return err_data
end

local InvalidPasswordLength = {
    name = 'kepler.account.InvalidPasswordLength',
    format = [=[Invalid password length.]=],
    severity = 'error'
}
M.InvalidPasswordLength = InvalidPasswordLength.name
---@return Error
function M.invalid_password_length()
    local err_data = new_error(InvalidPasswordLength.name, InvalidPasswordLength.format)
    regist_err_eng(InvalidPasswordLength, 401, nil, 0xC7)
    print_log(log.ERROR, InvalidPasswordLength.format)
    return err_data
end

local ValueOutOfRange = {
    name = 'kepler.account.ValueOutOfRange',
    format = [=[The value for the property is out of range.]=],
    severity = 'error'
}
M.ValueOutOfRange = ValueOutOfRange.name
---@return Error
function M.value_out_of_range()
    local err_data = new_error(ValueOutOfRange.name, ValueOutOfRange.format)
    regist_err_eng(ValueOutOfRange, 401, nil, 0xC9)
    print_log(log.ERROR, ValueOutOfRange.format)
    return err_data
end

local PasswordForbidSetComplexityCheck = {
    name = 'kepler.account.PasswordForbidSetComplexityCheck',
    format = [=[It is not allowed to enable or disable password co]=] ..
        [=[mplexity check when password complexity check enha]=] .. [=[ncement enabled.]=],
    severity = 'error'
}
M.PasswordForbidSetComplexityCheck = PasswordForbidSetComplexityCheck.name
---@return Error
function M.password_forbid_set_complexity_check()
    local err_data = new_error(PasswordForbidSetComplexityCheck.name, PasswordForbidSetComplexityCheck.format)
    regist_err_eng(PasswordForbidSetComplexityCheck, 401, nil, 0xFF)
    print_log(log.ERROR, PasswordForbidSetComplexityCheck.format)
    return err_data
end

local InvalidDataField = {
    name = 'kepler.account.InvalidDataField',
    format = [=[The user data field is invalid.]=],
    severity = 'error'
}
M.InvalidDataField = InvalidDataField.name
---@return Error
function M.invalid_data_field()
    local err_data = new_error(InvalidDataField.name, InvalidDataField.format)
    regist_err_eng(InvalidDataField, 401, nil, 0xCC)
    print_log(log.ERROR, InvalidDataField.format)
    return err_data
end

local ParameterInvalid = {
    name = 'kepler.account.ParameterInvalid',
    format = [=[The parameter %s is invalid.]=],
    severity = 'error'
}
M.ParameterInvalid = ParameterInvalid.name
---@return Error
function M.parameter_invalid(val1)
    local err_data = new_error(ParameterInvalid.name, ParameterInvalid.format, val1)
    regist_err_eng(ParameterInvalid, 401, nil, 0xFF)
    print_log(log.ERROR, ParameterInvalid.format, val1)
    return err_data
end

local RuleFormatInvalid = {
    name = 'kepler.account.RuleFormatInvalid',
    format = [=[The rule does not meet the format requirements]=],
    severity = 'error'
}
M.RuleFormatInvalid = RuleFormatInvalid.name
---@return Error
function M.rule_format_invalid()
    local err_data = new_error(RuleFormatInvalid.name, RuleFormatInvalid.format)
    regist_err_eng(RuleFormatInvalid, 401, nil, 0xFF)
    print_log(log.ERROR, RuleFormatInvalid.format)
    return err_data
end

local WeakPWDDictInProcess = {
    name = 'kepler.account.WeakPWDDictInProcess',
    format = [=[When weakpwd dictionary is in process, can't expor]=] .. [=[t or import again, or check password.]=],
    severity = 'error'
}
M.WeakPWDDictInProcess = WeakPWDDictInProcess.name
---@return Error
function M.weak_pwd_dict_in_process()
    local err_data = new_error(WeakPWDDictInProcess.name, WeakPWDDictInProcess.format)
    regist_err_eng(WeakPWDDictInProcess, 401, nil, 0xFF)
    print_log(log.ERROR, WeakPWDDictInProcess.format)
    return err_data
end

local PasswordInWeakPWDDict = {
    name = 'kepler.account.PasswordInWeakPWDDict',
    format = [=[The property cannot be in the weak password dictio]=] .. [=[nary.]=],
    severity = 'error'
}
M.PasswordInWeakPWDDict = PasswordInWeakPWDDict.name
---@return Error
function M.password_in_weak_pwd_dict()
    local err_data = new_error(PasswordInWeakPWDDict.name, PasswordInWeakPWDDict.format)
    regist_err_eng(PasswordInWeakPWDDict, 401, nil, 0x95)
    print_log(log.ERROR, PasswordInWeakPWDDict.format)
    return err_data
end

local InvalidPathOrFile = {
    name = 'kepler.account.InvalidPathOrFile',
    format = [=[The path or password dictionary is invalid.]=],
    severity = 'error'
}
M.InvalidPathOrFile = InvalidPathOrFile.name
---@return Error
function M.invalid_path_or_file()
    local err_data = new_error(InvalidPathOrFile.name, InvalidPathOrFile.format)
    regist_err_eng(InvalidPathOrFile, 401, nil, 0xFF)
    print_log(log.ERROR, InvalidPathOrFile.format)
    return err_data
end

local DuringMinimumPasswordAge = {
    name = 'kepler.account.DuringMinimumPasswordAge',
    format = [=[The password cannot be changed because it has not ]=] .. [=[passed the minimum password age.]=],
    severity = 'error'
}
M.DuringMinimumPasswordAge = DuringMinimumPasswordAge.name
---@return Error
function M.during_minimum_password_age()
    local err_data = new_error(DuringMinimumPasswordAge.name, DuringMinimumPasswordAge.format)
    regist_err_eng(DuringMinimumPasswordAge, 401, nil, 0xFF)
    print_log(log.ERROR, DuringMinimumPasswordAge.format)
    return err_data
end

local PropertyMemberQtyExceedLimit = {
    name = 'kepler.account.PropertyMemberQtyExceedLimit',
    format = [=[The number of items in the property %s exceeds the]=] .. [=[ limit.]=],
    severity = 'error'
}
M.PropertyMemberQtyExceedLimit = PropertyMemberQtyExceedLimit.name
---@return Error
function M.property_member_qty_exceed_limit(val1)
    local err_data = new_error(PropertyMemberQtyExceedLimit.name, PropertyMemberQtyExceedLimit.format, val1)
    regist_err_eng(PropertyMemberQtyExceedLimit, 401, nil, 0xFF)
    print_log(log.ERROR, PropertyMemberQtyExceedLimit.format, val1)
    return err_data
end

local UserNameNotExist = {
    name = 'kepler.account.UserNameNotExist',
    format = [=[The user name %s is not exist]=],
    severity = 'error'
}
M.UserNameNotExist = UserNameNotExist.name
---@return Error
function M.user_name_not_exist(val1)
    local err_data = new_error(UserNameNotExist.name, UserNameNotExist.format, val1)
    regist_err_eng(UserNameNotExist, 401, nil, 0x81)
    print_log(log.ERROR, UserNameNotExist.format, val1)
    return err_data
end

local IncorrectPublicKeyFormat = {
    name = 'kepler.account.IncorrectPublicKeyFormat',
    format = [=[Incorrect public key format.]=],
    severity = 'error'
}
M.IncorrectPublicKeyFormat = IncorrectPublicKeyFormat.name
---@return Error
function M.incorrect_public_key_format()
    local err_data = new_error(IncorrectPublicKeyFormat.name, IncorrectPublicKeyFormat.format)
    regist_err_eng(IncorrectPublicKeyFormat, 401, nil, 0x92)
    print_log(log.ERROR, IncorrectPublicKeyFormat.format)
    return err_data
end

local HostUserManagementDiabled = {
    name = 'kepler.account.HostUserManagementDiabled',
    format = [=[Host user management is disabled]=],
    severity = 'error'
}
M.HostUserManagementDiabled = HostUserManagementDiabled.name
---@return Error
function M.host_user_management_diabled()
    local err_data = new_error(HostUserManagementDiabled.name, HostUserManagementDiabled.format)
    regist_err_eng(HostUserManagementDiabled, 401, nil, 0x87)
    print_log(log.ERROR, HostUserManagementDiabled.format)
    return err_data
end

local UserFull = {name = 'kepler.account.UserFull', format = [=[User full, cannot add more user]=], severity = 'error'}
M.UserFull = UserFull.name
---@return Error
function M.user_full()
    local err_data = new_error(UserFull.name, UserFull.format)
    regist_err_eng(UserFull, 401, nil, 0xFF)
    print_log(log.ERROR, UserFull.format)
    return err_data
end

local CommunityStringContainSpace = {
    name = 'kepler.account.CommunityStringContainSpace',
    format = [=[The property cannot contain spaces]=],
    severity = 'error'
}
M.CommunityStringContainSpace = CommunityStringContainSpace.name
---@return Error
function M.community_string_contain_space()
    local err_data = new_error(CommunityStringContainSpace.name, CommunityStringContainSpace.format)
    regist_err_eng(CommunityStringContainSpace, 401, nil, 0x86)
    print_log(log.ERROR, CommunityStringContainSpace.format)
    return err_data
end

local InvalidCommunityStringLength = {
    name = 'kepler.account.InvalidCommunityStringLength',
    format = [=[The length of the property is invalid]=],
    severity = 'error'
}
M.InvalidCommunityStringLength = InvalidCommunityStringLength.name
---@return Error
function M.invalid_community_string_length()
    local err_data = new_error(InvalidCommunityStringLength.name, InvalidCommunityStringLength.format)
    regist_err_eng(InvalidCommunityStringLength, 401, nil, 0x85)
    print_log(log.ERROR, InvalidCommunityStringLength.format)
    return err_data
end

local UnsupportTwoFactorParam = {
    name = 'kepler.account.UnsupportTwoFactorParam',
    format = [=[Two Factor Auth parameter not supported]=],
    severity = 'error'
}
M.UnsupportTwoFactorParam = UnsupportTwoFactorParam.name
---@return Error
function M.unsupport_two_factor_param()
    local err_data = new_error(UnsupportTwoFactorParam.name, UnsupportTwoFactorParam.format)
    regist_err_eng(UnsupportTwoFactorParam, 401, nil, 0x80)
    print_log(log.ERROR, UnsupportTwoFactorParam.format)
    return err_data
end

local ImportInvalidKeytab = {
    name = 'kepler.account.ImportInvalidKeytab',
    format = [=[The Keytab path is invalid or format is invalid]=],
    severity = 'error'
}
M.ImportInvalidKeytab = ImportInvalidKeytab.name
---@return Error
function M.import_invalid_keytab()
    local err_data = new_error(ImportInvalidKeytab.name, ImportInvalidKeytab.format)
    regist_err_eng(ImportInvalidKeytab, 401, nil, 0x00)
    print_log(log.ERROR, ImportInvalidKeytab.format)
    return err_data
end

return M
