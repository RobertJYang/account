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
local log = require 'mc.logging'
local base_msg = require 'messages.base'
local json = require 'cjson'
local enum = require 'class.types.types'
local err = require 'account.errors'
local trace = require 'telemetry.trace'

local DETELE_USER_NAME = "delete_user"

local account_recover = class()
function account_recover:ctor(db, account_back_db, account_service)
    self.db = db
    self.account_db = account_back_db
    self.m_account_service = account_service
    self.m_global_account_config = account_service.m_account_config
    self.account_collection = account_service.m_account_collection
end

-- 恢复用户信息-待恢复ID无用户场景
function account_recover:recover_account_while_id_not_exist(ctx, account_id, backup_data)
    local account_data = backup_data.account_data
    local account_info = {
        ['id'] = account_data.Id,
        ['name'] = account_data.UserName,
        ['password'] = '',
        ['role_id'] = account_data.RoleId,
        ['interface'] = account_data.LoginInterface,
        ['first_login_policy'] = account_data.FirstLoginPolicy,
        ['account_type'] = enum.AccountType.Local:value()
    }

    -- 判断是否有重名用户，有的话先改名
    local account = self.account_collection:get_account_by_name(account_data.UserName)
    if account then
        -- 重名用户在最后会被删除,执行恢复前若重名用户时唯一的使能管理员,且被恢复用户不是管理员,则不支持恢复,否则无使能管理员可用
        if account_data.RoleId ~= enum.RoleType.Administrator:value() and
            self.account_collection:check_is_last_operate_admin(account:get_id()) then
            log:notice("recover non-admin account has same name with last admin account")
            error(base_msg.ActionNotSupported())
        end
        self.account_collection:change_user_name(account:get_id(), DETELE_USER_NAME)
    end

    -- 新建用户，失败的场景下可能需要恢复被改名的用户
    local ok, err = pcall(function()
        self.account_collection:new_account(ctx, account_info, true)
    end)
    if not ok then
        log:error("[Recover] create account failed")
        if account then
            self.account_collection:change_user_name(account:get_id(), account_data.UserName)
        end
        error(err)
    end

    -- 覆盖用户信息，失败的场景下需要删除新建的用户，可能需要恢复被改名的用户
    ok, err = pcall(function()
        self:cover_account_info(account_id, backup_data)
    end)
    if not ok then
        log:error("[Recover] cover account info failed")
        self.account_collection:force_delete_account(ctx, account_id)
        if account then
            self.account_collection:change_user_name(account:get_id(), account_data.UserName)
        end
        error(err)
    end

    -- 任务完成后，删除被改名的用户
    if account then
        self:delete_user(ctx, account:get_id())
    end
end

-- 恢复用户信息-待恢复ID有用户场景
function account_recover:recover_account_while_id_exist(ctx, account_id, backup_data)
    local account_data = backup_data.account_data
    -- 判断是否有重名用户，有的话先改名
    local account, id = self.account_collection:get_account_by_name(account_data.UserName)
    local is_dup_user = account and id ~= account_id
    if is_dup_user then
        -- 重名用户在最后会被删除,执行恢复前若重名用户时唯一的使能管理员,且被恢复用户不是管理员,则不支持恢复,否则无使能管理员可用
        if account_data.RoleId ~= enum.RoleType.Administrator:value() and
            self.account_collection:check_is_last_operate_admin(id) then
            log:notice("recover non-admin account has same name with last admin account")
            error(base_msg.ActionNotSupported())
        end
        self.account_collection:change_user_name(id, DETELE_USER_NAME)
    end


    -- 覆盖用户信息，失败的场景下需要删除新建的用户，可能需要恢复被改名的用户
    local ok, err = pcall(function()
        self:cover_account_info(account_id, backup_data)
    end)
    if not ok then
        log:error("[Recover] cover account info failed")
        if is_dup_user then
            self.account_collection:change_user_name(id, account_data.UserName)
        end
        error(err)
    end

    -- 任务完成后，删除被改名的用户
    if is_dup_user then
        self:delete_user(ctx, account:get_id())
    end
end

---恢复指定用户的信息
---@param ctx any
---@param account_id 用户ID，只支持恢复本地用户（2-17）
---@param policy 恢复策略(0:强制恢复 ； 1：安全恢复）当前只支持强制恢复
function account_recover:recover_account(ctx, account_id, policy)
    local span = trace.start_span('account.account_recover.recover_account', {})
    -- 参数校验
    if account_id == nil or account_id < 2 or account_id > 17 then
        log:error('[Recover] User id %d is illegal', account_id)
        span:finish()
        error(err.invalid_data_field())
    end
    if policy ~= 0 then
        log:notice('[Recover] only support force-recover')
    end
    -- 获取备份表中用户信息
    local backup_info = self.account_db:get_data(account_id)
    if backup_info == nil then
        log:error('[Recover] get account%d`s back-up data failed', account_id)
        span:finish()
        error(base_msg.PropertyMissing('id'))
    end
    local ipmi_channel_data = nil
    if backup_info.IpmiChannelData ~= nil then
        ipmi_channel_data = json.decode(backup_info.IpmiChannelData)
    end
    -- 解析备份表中的json字符串
    local backup_data = { 
        account_data = json.decode(backup_info.ManagerAccountData),
        ipmi_data = json.decode(backup_info.IpmiAccountData),
        snmp_data = json.decode(backup_info.SnmpAccountData),
        ipmi_channel_data = ipmi_channel_data,
    }
    -- 根据业务场景做策略
    local ok = pcall(function ()
        self.account_collection:get_account_by_account_id(account_id)
    end)
    if not ok then
        self:recover_account_while_id_not_exist(ctx, account_id, backup_data)
    else
        self:recover_account_while_id_exist(ctx, account_id, backup_data)
    end
    log:info('[Recover] recover user %d successfully', account_id)
    span:finish()
end

function account_recover:cover_account_info(account_id, backup_data)
    local account = self.account_collection:get_account_by_account_id(account_id)
    local account_data = backup_data.account_data
    -- 被还原账户不是管理员,被覆盖用户是最后一个使能的管理员,则不支持恢复
    if account:get_role_id() == enum.RoleType.Administrator:value() and
        account_data.RoleId ~= enum.RoleType.Administrator:value() and
        self.account_collection:check_is_last_operate_admin(account_id) then
        log:error('[Recover] account%d is last enabled admin, cannot recover', account_id)
        error(base_msg.ActionNotSupported())
    end
    if account_id == self.m_global_account_config:get_snmp_v3_trap_account_id() then
        log:notice('[Recover] account%d is trap v3 account, will be recovered', account_id)
    end
    account:recover(backup_data)
    self.account_collection.m_account_removed:emit(account_id)
    self.account_collection.m_account_added:emit(account.m_account_data, account.m_snmp_user_info_data,
        account.m_account_update_signal, account.m_snmp_update_signal)
    account:update_privileges()
    self.account_collection.m_account_file_changed:emit(account_id, account_data.UserName)
end

function account_recover:delete_user(ctx, id)
    if self.account_collection:check_is_emergency_user(id) then
        self.m_global_account_config:set_emergency_account(0)
        self.m_account_service.m_config_changed:emit('EmergencyLoginAccountId',0)
        log:notice('[Recover] account%d is emergency account, force delete',id)
    end
    if id == self.m_global_account_config:get_snmp_v3_trap_account_id() then
        self.m_global_account_config:set_snmp_v3_trap_account(0)
        self.m_account_service.m_config_changed:emit('SnmpTrapV3AccountId',0)
        log:notice('[Recover] account%d is trap v3 account, force delete',id)
    end
    self.account_collection:force_delete_account(ctx, id)
end

return singleton(account_recover)
