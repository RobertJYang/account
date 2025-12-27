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
local singleton = require 'mc.singleton'
local context = require 'mc.context'
local client = require 'iam.client'
local iam_err = require 'iam.errors'
local iam_enum = require 'class.types.types'
local log = require 'mc.logging'
local mc_utils = require 'mc.utils'
local err_cfg = require 'error_config'
local custom_msg = require 'messages.custom'
local iam_utils = require 'utils'
local user_config = require 'user_config'
local account_cache = require 'domain.cache.account_cache'
local account_service_cache = require 'domain.cache.account_service_cache'
local account_lock = require 'domain.account_lock'
local core = require 'iam_core'

-- AccountService
local AccountService = class()

function AccountService:ctor(db)
    self.m_account_cache = account_cache.get_instance()
    self.m_account_service_cache = account_service_cache.get_instance()
    self.m_account_lock = account_lock.get_instance()
end

local function inner_channel_check(chann_num)
    log:debug("the chann num is %s", tostring(chann_num))
    if (chann_num == iam_enum.IpmiChannel.SYS_CHAN_NUM:value()) or
        (chann_num == iam_enum.IpmiChannel.CPLDRAM_CHAN_NUM:value()) then
        return true
    end
    return false
end

local function get_ipmi_set_account_password_handler_id(req, ctx)
    if inner_channel_check(ctx.chan_num) then
        return user_config.IPMI_ACCOUNT_ID
    end
    if ctx.session and ctx.session.user then
        return ctx.session.user.id
    end
end

function AccountService:check_ipmi_password_privilege(handle_account_id, account_id)
    if handle_account_id > user_config.MAX_LOCAL_USER_NUM or
        handle_account_id < user_config.MIN_LOCAL_USER_NUM then
        return true
    end
    local handler_account = self.m_account_cache:get_account_by_id(handle_account_id)
    -- 是首次登录，只可以修改自己密码
    if mc_utils.table_compare(handler_account.current_privileges,
        { tostring(iam_enum.PrivilegeType.ConfigureSelf) }) then
        return handle_account_id == account_id
    end

    if handler_account.RoleId ~= iam_enum.RoleType.Administrator:value() then
        return false
    end

    return true
end

--- ipmi设置密码前，对请求提参数进行预校验
---@param req any
---@param ctx any
---@return integer
function AccountService:__ipmi_set_account_password_precheck(req, ctx)
    iam_utils.check_ipmi_account_id(req.UserId)

    local user_password_size_1_5 = 16 -- IPMI1.5密码16位
    local user_password_size_2 = 20 -- IPMI2.0密码20位
    if ((req.PasswordSize == 0) and (string.len(req.PasswordData) ~= user_password_size_1_5)) or
        ((req.PasswordSize == 1) and (string.len(req.PasswordData) ~= user_password_size_2)) then
        error(custom_msg.IPMIRequestLengthInvalid())
    end

    local ret = self.m_account_service_cache:check_ipmi_host_user_mgnt_enabled(ctx)
    if not ret then
        log:error("Check host user management failed")
        error(iam_err.host_user_management_diabled())
    end
end

-- 函数中由于密码数据协议进行了补充0x00，因此去掉
function AccountService:ipmi_test_account_password(req, ctx)
    -- 预置操作日志配置，保证功能异常时返回日志记录正确性
    ctx.operation_log.params = { name = "", id = req.UserId, ret = '' }
    self:__ipmi_set_account_password_precheck(req, ctx)
    local password_data = mc_utils.trim_tail_zero(req.PasswordData)
    local account = self.m_account_cache:get_account_by_id(req.UserId)
    if account == nil then
        log:error("user(%s) is not exist", req.UserId)
        ctx.operation_log.result = 'fail'
        return err_cfg.USER_DONT_EXIST
    end
    ctx.operation_log.params.name = account.UserName
    -- os通道，ctx无认证信息
    local handler_user_id = get_ipmi_set_account_password_handler_id(req, ctx)
    if not handler_user_id then
        ctx.operation_log.result = 'fail'
        return err_cfg.USER_UNSUPPORT
    end
    if not self:check_ipmi_password_privilege(handler_user_id, req.UserId) then
        error(iam_err.un_supported())
    end

    local ret = self.m_account_lock:check_ipmi_user_test_state(handler_user_id, req.UserId)
    if ret == iam_enum.UserLocked.USER_LOCK then
        ctx.operation_log.params.ret = err_cfg.USER_IS_LOCKED
        ctx.operation_log.result = 'fail_ret'
        return err_cfg.USER_IS_LOCKED
    end

    local obj = client:GetLocalAccountAuthNLocalAccountAuthNObject()
    local call_ctx = context.new(ctx.Interface, ctx.UserName, ctx.ClientAddr)
    local ext_config = {
        ['TestPassword'] = true
    }
    local ok, result = pcall(obj.LocalAuthenticate, obj, call_ctx, account.UserName, password_data, ext_config)
    ret = tonumber(result.code)
    if not ok or ret ~= err_cfg.USER_OPER_SUCCESS then
        self.m_account_lock:test_password_fail_cnt_increase(handler_user_id, req.UserId)
        ctx.operation_log.params.ret = ret
        ctx.operation_log.result = 'fail_ret'
    else
        self.m_account_lock:clean_specific_ipmi_test_password_failures(handler_user_id, req.UserId)
    end
    return ret
end

function AccountService:clean_all_user_lock_state()
    for id, account in pairs(self.m_account_cache.cache_collection) do
        self.m_account_lock:clean_account_all_ipmi_test_password_failures(id)
        core.reset_pam_tally(account.UserName, user_config.PAM_TALLY_LOG_DIR)
    end
end

function AccountService:clean_unlock_user_lock_state()
    for id, account in pairs(self.m_account_cache.cache_collection) do
        if self.m_account_lock:get_account_lock_state(id) == iam_enum.UserLocked.USER_UNLOCK then
            self.m_account_lock:clean_account_unlock_ipmi_test_password_failures(id)
            core.reset_pam_tally(account.UserName, user_config.PAM_TALLY_LOG_DIR)
        end
    end
end

return singleton(AccountService)
