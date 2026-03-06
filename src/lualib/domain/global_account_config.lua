-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local singleton = require 'mc.singleton'
local class = require 'mc.class'
local mc_utils = require 'mc.utils'
local log = require 'mc.logging'
local file_utils = require 'utils.file'
local vos = require 'utils.vos'
local utils_core = require 'utils.core'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local enum = require 'class.types.types'
local config = require 'common_config'
local err_cfg = require 'error_config'
local utils = require 'infrastructure.utils'
local file_proxy = require 'infrastructure.file_proxy'
local flash_sync = require 'infrastructure.flash_synchronizer'
local core = require 'account_core'
local signal = require 'mc.signal'

local MAX_USER_NUM = 17
local MIN_USER_NUM = 2
local WEAK_PWDDICT_MAX_SUPPORTED_LINES = 1000
local MAX_MIN_DIFF = 10 -- 当min_age和max_age均不为0时，需要满足最长有效期超过最短有效期10天
local PROP_NOT_USE = 0 -- 设置为0代表该属性不生效

local global_account_config = class()

function global_account_config:ctor(db, file_transfer)
    self.m_db_account_service = db:select(db.AccountService):first()
    self.m_snmp_community = db:select(db.SnmpCommunity):first()
    self.m_file_transfer = file_transfer
    self.m_weak_password_dictionary = {}
    self.m_weak_password_dictionary_config_status = enum.WeakPwdDictEnum.WEAK_PWDDICT_COMPELETE
    self.m_account_service_config_changed = signal.new()
end

function global_account_config:init()
    if not file_proxy.proxy_access(config.WEAK_PWDDICT_FILE_PATH, 0) then
        file_proxy.proxy_copy(config.WEAK_PWDDICT_FILE_PATH_INIT, config.WEAK_PWDDICT_FILE_PATH,
            config.SECBOX_USER_UID, config.SECBOX_USER_GID)
    end
    file_proxy.proxy_chmod(config.WEAK_PWDDICT_FILE_PATH, mc_utils.S_IRUSR | mc_utils.S_IWUSR | mc_utils.S_IRGRP)
    file_proxy.proxy_chown(config.WEAK_PWDDICT_FILE_PATH, config.SECBOX_USER_UID, config.SECBOX_USER_GID)

    self.m_weak_password_dictionary = {}
    local file = file_utils.open_s(config.WEAK_PWDDICT_FILE_PATH, "r")
    if not file then
        log:error('The init weakpwddictionary is null')
        return
    end
    mc_utils.close(file, pcall(function ()
        local lines = file:lines()
        for line in lines do
            line = string.gsub(line, "\r", "")
            self.m_weak_password_dictionary[#self.m_weak_password_dictionary + 1] = line
        end
    end))
end

function global_account_config:get_password_max_length()
    return self.m_db_account_service.MaxPasswordLength
end

function global_account_config:get_password_min_length()
    return self.m_db_account_service.MinPasswordLength
end

function global_account_config:set_password_min_length(length)
    -- 最短密码长度合法范围为8-20
    if length < 8 or length > 20 then
        log:error('Set minimum password length failed, length(%d) is out of range', length)
        error(base_msg.PropertyValueNotInList('%MinPasswordLength:' .. length, '%MinPasswordLength'))
    end
    self.m_db_account_service.MinPasswordLength = length
    self.m_db_account_service:save()
end

function global_account_config:get_password_complexity_enable()
    return self.m_db_account_service.PasswordComplexityEnable
end

function global_account_config:set_password_complexity_enable(enable)
    local lock = self:get_password_complexity_lock()
    if lock and not enable then
        if core.is_manufacture_mode() then
            log:notice("Skip checking password complexity check lock in manufacture mode")
        else
            error(custom_msg.PasswordForbidSetComplexityCheck())
        end
    end
    self.m_db_account_service.PasswordComplexityEnable = enable
    self.m_db_account_service:save()
end

function global_account_config:get_initial_password_prompt_enable()
    return self.m_db_account_service.InitialPasswordPromptEnable
end

--- 首次登录人机接口:InitialPasswordPromptEnable
---@param enable boolean
function global_account_config:set_initial_password_prompt_enable(enable)
    -- 总开关关闭时无法打开人机接口
    if not self:get_initial_password_need_modify() and enable then
        log:error('Can not enable InitialPasswordPromptEnable when InitialPasswordNeedModify is disabled')
        error(custom_msg.SettingPropertyFailed('InitialPasswordPromptEnable',
            'InitialPasswordNeedModify', 'disabled'))
    end
    self.m_db_account_service.InitialPasswordPromptEnable = enable
    self.m_db_account_service:save()
end

function global_account_config:get_initial_account_privilege_restrict_enabled()
    return self.m_db_account_service.InitialAccountPrivilegeRestrictEnabled
end

--- 首次登录机机接口:InitialAccountPrivilegeRestrictEnabled
---@param enable boolean
function global_account_config:set_initial_account_privilege_restrict_enabled(enable)
    -- 总开关关闭时无法打开机机接口
    if not self:get_initial_password_need_modify() and enable then
        log:error('Can not enable InitialAccountPrivilegeRestrictEnabled when InitialPasswordNeedModify is disabled')
        error(custom_msg.SettingPropertyFailed('InitialAccountPrivilegeRestrictEnabled',
            'InitialPasswordNeedModify', 'disabled'))
    end
    self.m_db_account_service.InitialAccountPrivilegeRestrictEnabled = enable
    self.m_db_account_service:save()
end

function global_account_config:get_initial_password_need_modify()
    return self.m_db_account_service.InitialPasswordNeedModify
end

--- 首次登录总开关:InitialPasswordNeedModify
---@param enable boolean
function global_account_config:set_initial_password_need_modify(enable)
    self.m_db_account_service.InitialPasswordNeedModify = enable
    self.m_db_account_service:save()
end

function global_account_config:get_weak_pwd_dictionary_enable()
    return self.m_db_account_service.WeakPasswordDictionaryEnabled
end

function global_account_config:set_weak_pwd_dictionary_enable(enable)
    self.m_db_account_service.WeakPasswordDictionaryEnabled = enable
    self.m_db_account_service:save()
end

function global_account_config:set_password_complexity_lock(enable)
    self.m_db_account_service.PasswordComplexityIsLock = enable
    self.m_db_account_service:save()
end

function global_account_config:get_password_complexity_lock()
    return self.m_db_account_service.PasswordComplexityIsLock
end

function global_account_config:get_max_password_valid_days()
    return self.m_db_account_service.MaxPasswordValidDays
end

function global_account_config:get_min_password_valid_days()
    return self.m_db_account_service.MinPasswordValidDays
end

function global_account_config:set_min_password_valid_days(min_age)
    local max_age = self.m_db_account_service.MaxPasswordValidDays
    -- 最短有效期范围0~365天
    if min_age > 365 or min_age < 0 then
        log:error('set_minimum_password_valid_days failed, minimum_use_time(%u) is out of range', min_age)
        error(base_msg.PropertyValueNotInList('%MinPasswordValidDays:' .. min_age, '%MinPasswordValidDays'))
    end

    if min_age ~= PROP_NOT_USE and max_age ~= PROP_NOT_USE and max_age <= min_age + MAX_MIN_DIFF then
        log:error('minimum_pwd_age(%u) is no less than pwd_expired_time(%u) minus %u', max_age, min_age, MAX_MIN_DIFF)
        error(custom_msg.MinPwdAgeAndPwdValidityRestrictEachOther())
    end

    self.m_db_account_service.MinPasswordValidDays = min_age
    self.m_db_account_service:save()
end

function global_account_config:set_max_password_valid_days(max_age)
    local min_age = self.m_db_account_service.MinPasswordValidDays

    -- 最长有效期范围0~365天
    if max_age > 365 or max_age < 0 then
        log:error('Set max password valid days failed, expired_time(%u) is error', max_age)
        error(base_msg.PropertyValueNotInList('%MaxPasswordValidDays:' .. max_age, '%MaxPasswordValidDays'))
    end
    if min_age ~= PROP_NOT_USE and max_age ~= PROP_NOT_USE and max_age <= min_age + MAX_MIN_DIFF then
        log:error('expired_time(%u) is smaller than minimum_use_time(%u) + %u', max_age, min_age, MAX_MIN_DIFF)
        error(custom_msg.MinPwdAgeAndPwdValidityRestrictEachOther())
    end

    self.m_db_account_service.MaxPasswordValidDays = max_age
    self.m_db_account_service:save()
end

function global_account_config:check_password_in_weak_passwd_dictionary(ctx, password, passwd_type)
    if self.m_weak_password_dictionary_config_status == enum.WeakPwdDictEnum.WEAK_PWDDICT_IN_PROCESS then
        ctx.operation_log.params.ret = err_cfg.USER_SET_PASSWORD_TOO_WEAK
        error(custom_msg.OperationInProcess())
    end
    for _, v in pairs(self.m_weak_password_dictionary) do
        if v == password then
            ctx.operation_log.params.ret = err_cfg.USER_SET_PASSWORD_TOO_WEAK
            log:error('Password is found in weak password dictionary.')
            if ctx.Interface == "WEB" and passwd_type == "snmp_password" then
                error(custom_msg.PasswordInWeakPWDDict("The snmp privacy password"))
            else
                error(custom_msg.PasswordInWeakPWDDict("Password"))
            end
        end
    end
end

-- 导入弱口令字典，导入路径只能在/tmp目录下
function global_account_config:import_weak_pwd_dictionary(path)
    if self.m_weak_password_dictionary_config_status == enum.WeakPwdDictEnum.WEAK_PWDDICT_IN_PROCESS then
        error(custom_msg.WeakPWDDictImportFailed())
    end
    local list_count = 0
    local tmp_weak_password_dictionary = {}
    if not utils.check_import_path(path, config.SHM_PATH) and not utils.check_import_path(path, config.TMP_PATH) then
        error(custom_msg.WeakPWDDictImportFailed())
    end

    local file = file_utils.open_s(path, "r")
    if not file then
        log:error('Open weakpassword dictionary failed.')
        error(custom_msg.WeakPWDDictImportFailed())
    end
    mc_utils.close(file, pcall(function ()
        if file:seek("end") > config.FILE_LIMITED_SIZE or file:seek("end") == 0 then
            log:error('Import failed : file is empty or file size exceeded.')
            error(custom_msg.WeakPWDDictImportFailed())
        end
    end))
    for line in io.lines(path) do
        if line == '' then
            goto continue
        end
        line = string.gsub(line, "\r", "")
        if #line > self.m_db_account_service.MaxPasswordLength then
            error(custom_msg.WeakPWDDictImportFailed())
        end
        -- 弱口令中不可以包含不可见字符
        if not utils.check_string_is_valid_ascii(line) then
            error(custom_msg.WeakPWDDictImportFailed())
        end
        tmp_weak_password_dictionary[#tmp_weak_password_dictionary + 1] = line
        list_count = list_count + 1
        if list_count > WEAK_PWDDICT_MAX_SUPPORTED_LINES then
            error(custom_msg.WeakPWDDictImportFailed())
        end
        ::continue::
    end
    self.m_weak_password_dictionary_config_status = enum.WeakPwdDictEnum.WEAK_PWDDICT_IN_PROCESS
    self.m_weak_password_dictionary = tmp_weak_password_dictionary
    file_utils.copy_file_content_s(path, config.WEAK_PWDDICT_FILE_PATH)
    self.m_weak_password_dictionary_config_status = enum.WeakPwdDictEnum.WEAK_PWDDICT_COMPELETE
end

-- 本地导出弱口令字典
function global_account_config:export_weak_pwd_dictionary(ctx, path)
    if self.m_weak_password_dictionary_config_status == enum.WeakPwdDictEnum.WEAK_PWDDICT_IN_PROCESS then
        log:error('Importing or exporting the weak password dictionary is in progress.')
        error(custom_msg.OperationInProcess())
    end
    if file_utils.check_realpath_before_open_s(path, config.TMP_PATH) ~= 0 or #path > config.MAX_FILEPATH_LENGTH then
        error(custom_msg.InvalidPath('******', 'Export Path'))
    end
    -- 先copy到/dev/shm赋权后再导出给tmp
    file_utils.copy_file_s(config.WEAK_PWDDICT_FILE_PATH, config.WEAK_PWDDICT_FILE_SHM_PATH)
    local uid, gid = utils_core.get_uid_gid_by_name(ctx.UserName)
    file_proxy.proxy_chown(config.WEAK_PWDDICT_FILE_SHM_PATH, uid, gid)
    file_proxy.proxy_chmod(config.WEAK_PWDDICT_FILE_SHM_PATH, mc_utils.S_IRUSR | mc_utils.S_IWUSR)
    file_proxy.proxy_move(config.WEAK_PWDDICT_FILE_SHM_PATH, path, uid, gid)
end

function global_account_config:set_emergency_account(account_id)
    if account_id == 0 then
        log:info('When id is 0, remove emergency user')
    end
    self.m_db_account_service.EmergencyLoginAccountId = account_id
    self.m_db_account_service:save()
end

function global_account_config:get_emergency_account()
    return self.m_db_account_service.EmergencyLoginAccountId
end

function global_account_config:set_snmp_v3_trap_account(account_id)
    self.m_db_account_service.SNMPv3TrapAccountId = account_id
    self.m_db_account_service:save()
    self.m_account_service_config_changed:emit('SNMPv3TrapAccountId', account_id)
end

function global_account_config:get_snmp_v3_trap_account_id()
    return self.m_db_account_service.SNMPv3TrapAccountId
end

function global_account_config:set_snmp_v3_trap_account_limit_policy(ctx, policy_enum)
    if policy_enum == enum.SNMPv3TrapAccountLimitPolicy.Modifiable:value() then
        ctx.operation_log.result = 'Modifiable'
    elseif policy_enum == enum.SNMPv3TrapAccountLimitPolicy.NameModifiable:value() then
        ctx.operation_log.result = 'NameModifiable'
    elseif policy_enum == enum.SNMPv3TrapAccountLimitPolicy.NotModifiable:value() then
        ctx.operation_log.result = 'NotModifiable'
    else
        error(base_msg.PropertyValueNotInList('%SNMPv3TrapAccountLimitPolicy:' .. 'Unknown',
            '%SNMPv3TrapAccountLimitPolicy'))
    end
    self.m_db_account_service.SNMPv3TrapAccountLimitPolicy = policy_enum
    self.m_db_account_service:save()
end

function global_account_config:get_snmp_v3_trap_account_limit_policy()
    return self.m_db_account_service.SNMPv3TrapAccountLimitPolicy
end

function global_account_config:get_snmp_v3_trap_account_change_policy()
    return self.m_db_account_service.SNMPv3TrapAccountChangePolicy
end

function global_account_config:set_snmp_v3_trap_account_change_policy(ctx, policy_value)
    if policy_value == 0 then
        ctx.operation_log.result = 'NotChangeable'
    elseif policy_value == 1 then
        ctx.operation_log.result = 'AllowedChangeable'
    else
        log:error("Invalid SNMPv3TrapAccountChangePolicy value(%s)", policy_value)
        error(base_msg.PropertyValueNotInList('%SNMPv3TrapAccountChangePolicy:' .. 'Unknown',
            '%SNMPv3TrapAccountChangePolicy'))
    end
    self.m_db_account_service.SNMPv3TrapAccountChangePolicy = policy_value
    self.m_db_account_service:save()
    self.m_account_service_config_changed:emit('SNMPv3TrapAccountChangePolicy', policy_value)
end

function global_account_config:get_require_change_password_action()
    return self.m_db_account_service.RequireChangePasswordAction
end

function global_account_config:set_require_change_password_action(ctx, action_value)
    ctx.operation_log.params = { action = action_value and 'Enable' or 'Disable' }
    self.m_db_account_service.RequireChangePasswordAction = action_value
    self.m_db_account_service:save()
    self.m_account_service_config_changed:emit('RequireChangePasswordAction', action_value)
end

function global_account_config:get_inactive_time_threshold()
    return self.m_db_account_service.InactiveDaysThreshold
end

function global_account_config:set_inactive_time_threshold(threshold)
    local MAX_INACT_DAYS = 365  -- 不活跃阈值最长365天
    local MIN_INACT_DAYS = 30   -- 不活跃阈值最短30天

    if threshold > MAX_INACT_DAYS or (threshold < MIN_INACT_DAYS and threshold ~= PROP_NOT_USE) then
        log:error('set_inactive_time_threshold failed, inactive_user_threshold(%d) is error', threshold)
        error(base_msg.PropertyValueNotInList(threshold, "AccountInactiveTimeLimit"))
    end
    self.m_db_account_service.InactiveDaysThreshold = threshold
    self.m_db_account_service:save()
end
function global_account_config:get_max_user_num()
    return MAX_USER_NUM
end

function global_account_config:get_min_user_num()
    return MIN_USER_NUM
end

function global_account_config:set_history_password_count(count)
    local max_count = self.m_db_account_service.MaxHistoryPasswordCount
    -- 历史密码数范围由最大范围控制
    if count < 0 or count > max_count then
        log:error('Set history password count failed, count(%d) is out of range, max history password count is(%d)',
        count, max_count)
        error(custom_msg.PropertyValueOutOfRange(count, 'HistoryPasswordCount'))
    end
    self.m_db_account_service.HistoryPasswordCount = count
    self.m_db_account_service:save()
end

function global_account_config:set_max_history_password_count(count)
    local password_count = self.m_db_account_service.HistoryPasswordCount
    -- 历史密码数范围5-100
    if count < 5 or count > 100 or count < password_count then
        log:error('Set max history password count failed, count(%d) is out of range, history password count is (%d)',
        password_count ,count)
        error(custom_msg.PropertyValueOutOfRange(count, 'MaxHistoryPasswordCount'))
    end
    self.m_db_account_service.MaxHistoryPasswordCount = count
    self.m_db_account_service:save()
end

function global_account_config:get_history_password_count()
    return self.m_db_account_service.HistoryPasswordCount
end

function global_account_config:get_max_history_password_count()
    return self.m_db_account_service.MaxHistoryPasswordCount
end

function global_account_config:get_host_user_management_enabled()
    return self.m_db_account_service.HostUserManagementEnabled
end

function global_account_config:set_host_user_management_enabled(status)
    self.m_db_account_service.HostUserManagementEnabled = status
    self.m_db_account_service:save()
end

function global_account_config:set_os_administrator_privilege_enabled(status)
    self.m_db_account_service.OSAdministratorPrivilegeEnabled = status
    self.m_db_account_service:save()
end

function global_account_config:check_ipmi_host_user_mgnt_enabled(ipmi_ctx)
    if self.m_db_account_service.HostUserManagementEnabled == true then
        return true
    end
    -- HostUserManagementEnabled is false
    local from_bt = ipmi_ctx.chan_num == enum.IpmiChannel.SYS_CHAN_NUM:value() or ipmi_ctx.chan_num == 21 or
                        ipmi_ctx.chan_num == 22 -- 21与22为BMC自定义bt通道
    local from_edma = ipmi_ctx.chan_num == enum.IpmiChannel.EDMA_CHAN_NUM:value()
    local from_ipmb_os = ipmi_ctx.chan_num == enum.IpmiChannel.IPMB_SM_CHAN_NUM:value()
    if from_bt or from_edma or from_ipmb_os then
        return false
    end
    -- 兼容历史代码
    if ipmi_ctx.ChanType == enum.IpmiChannelType.IPMI_HOST:value() then
        return false
    end
    return true
end

function global_account_config:get_user_name_password_compared_enabled()
    return self.m_db_account_service.UserNamePasswordPrefixCompareEnabled
end

function global_account_config:set_user_name_password_compared_enabled(status)
    self.m_db_account_service.UserNamePasswordPrefixCompareEnabled = status
    self.m_db_account_service:save()
end

function global_account_config:get_user_name_password_compared_length()
    return self.m_db_account_service.UserNamePasswordPrefixCompareLength
end

function global_account_config:set_user_name_password_compared_length(length)
    if length < config.USERNAME_PWD_COMPARE_DEFAULT_LEN or length > config.USERNAME_PWD_COMPARE_LEN_MAX then
        log:error('Set userpwd compare length to %d failed', length)
        error(custom_msg.InvalidValue(length, 'UserNamePasswordPrefixCompareLength'))
    end
    self.m_db_account_service.UserNamePasswordPrefixCompareLength = length
    self.m_db_account_service:save()
end

function global_account_config:get_long_community_enabled()
    return self.m_snmp_community.LongCommunityEnabled
end

function global_account_config:set_long_community_enabled(enabled)
    self.m_snmp_community.LongCommunityEnabled = enabled
    self.m_snmp_community:save()
end

function global_account_config:get_rw_community_enabled()
    return self.m_snmp_community.RwCommunityEnabled
end

function global_account_config:set_rw_community_enabled(enabled)
    self.m_snmp_community.RwCommunityEnabled = enabled
    self.m_snmp_community:save()
end

--- 更新公私钥对
--- @param update_sec number 更新公私钥有效时间
function global_account_config:update_requested_key_pair(update_sec)
    if self.requested_key_tab then
        self.requested_key_tab.RemainTime = self.requested_key_tab.RemainTime - update_sec
    end
    -- 不存在公私钥对或公私钥对过期（7天），更新公私钥
    if not self.requested_key_tab or self.requested_key_tab.RemainTime <= 0 then
        local public_key, private_key = core.generate_requested_key_pair()
        self.requested_key_tab = {
            PublicKey = public_key,
            PrivateKey = private_key,
            RemainTime = config.DAY_SECOND_COUNT * 7
        }
        log:notice('generate new requested key pair')
    end
end

--- 获取web_rest请求公钥
--- @return table
function global_account_config:get_web_requested_key_pair()
    self:update_requested_key_pair(0)
    -- 如果公私钥剩余时间小于5min，更新剩余时间为5min
    if self.requested_key_tab.RemainTime < config.MIN_SECOND_COUNT * 5 then
        self.requested_key_tab.RemainTime = config.MIN_SECOND_COUNT * 5
    end
    return self.requested_key_tab
end

return singleton(global_account_config)
