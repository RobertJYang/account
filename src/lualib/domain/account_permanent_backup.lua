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
local enum = require 'class.types.types'
local utils = require 'infrastructure.utils'
local local_account = require 'domain.manager_account.local_account'
local skynet = require 'skynet'

local DEFAULT_MIN_USER_NUM = 2
local DEFAULT_MAX_USER_NUM = 17
local AccountPermanentBackup = class()

function AccountPermanentBackup:ctor(db, account_colletion)
    self.m_account_collection = account_colletion

    local stmt_account_backup = db:select(db.AccountBackup)
    self.m_table_account_backup = stmt_account_backup.table
    self.m_account_backup_collection = stmt_account_backup:fold(function(account, acc)
        acc[account.Id] = account
        return acc
    end, {})
end

function AccountPermanentBackup:init()
    if skynet.getenv('TEST_DATA_DIR') then
        self:regist_account_signals()
    end

    -- 业务数据正常，执行备份行为
    if self:account_data_integrity_check() then
        log:info("account data integrity check successfully, do account backup")
        self:backup_permanent_account_info()
    else -- 业务数据异常，从AccountBackup中进行覆盖恢复
        log:info("account data integrity check failed, do account recover")
        self:recover_permanent_account_info()
    end
end

function AccountPermanentBackup:regist_account_signals()
    -- 新增用户
    self.m_account_collection.m_account_added:on(function(...)
        self:new_permanent_account(...)
    end)
    -- 删除用户
    self.m_account_collection.m_account_removed:on(function(...)
        self:remove_permantent_account(...)
    end)
    -- 用户信息变更
    self.m_account_collection.m_account_permanent_changed:on(function(...)
        self:flush_permantent_account(...)
    end)
end

function AccountPermanentBackup:account_data_integrity_check()
    -- 判断是否有可用的管理员
    if self.m_account_collection:get_enabled_admin_number() > 0 then
        return true
    end

    return false
end

function AccountPermanentBackup:backup_permanent_account_info()
    -- 备份前先清理表
    for id, _ in pairs(self.m_account_backup_collection) do
        self:remove_permantent_account(id)
    end

    for id, account in pairs(self.m_account_collection.collection) do
        -- 只备份 2 ~ 17 号用户
        if id < DEFAULT_MIN_USER_NUM or id > DEFAULT_MAX_USER_NUM then
            goto continue
        end
        if not self.m_account_backup_collection[id] then
            self:new_permanent_account(account:get_account_data())
        else
            self:flush_permantent_account(id, nil)
        end
        ::continue::
    end
end

function AccountPermanentBackup:recover_permanent_account_info()
    local account
    for id, account_info in pairs(self.m_account_backup_collection) do
        account = self.m_account_collection.collection[id]
        if account then
            local account_data = account:get_account_data()
            account_data.UserName       = account_info.UserName
            account_data.Password       = account_info.Password
            account_data.RoleId         = account_info.RoleId
            account_data.Enabled        = account_info.Enabled
            account_data.LoginInterface = account_info.LoginInterface
            account_data:save()
            account:update_privileges()
            -- 用户覆盖后触发信号刷新资源树
            self.m_account_collection.m_account_changed:emit(id, "UserName", account_info.UserName)
            self.m_account_collection.m_account_changed:emit(id, "RoleId", account_info.RoleId)
            self.m_account_collection.m_account_changed:emit(id, "Enabled", account_info.Enabled)
            self.m_account_collection.m_account_changed:emit(id, "LoginInterface",
                utils.convert_num_to_interface_str(account_info.LoginInterface, true))
            self.m_account_collection.m_account_file_changed:emit(id, account_info.UserName)
        else
            self:recover_new_permanent_account(id, account_info)
        end
    end
end

function AccountPermanentBackup:recover_new_permanent_account(id, account_info)
    local new_account_info = {
        id = id,
        name = account_info.UserName,
        password = account_info.Password,
        role_id = account_info.RoleId,
        interface = account_info.LoginInterface,
        first_login_policy = account_info.FirstLoginPolicy or enum.FirstLoginPolicy.ForcePasswordReset,
        is_pwd_encrypted = true
    }
    -- 不走密码校验，不需要上下文
    self.m_account_collection:new_ccount_to_db_and_mdb({}, new_account_info, local_account, false, false)
end

function AccountPermanentBackup:new_permanent_account(account_data)
    if account_data.Id < DEFAULT_MIN_USER_NUM or account_data.Id > DEFAULT_MAX_USER_NUM then
        return
    end
    local account_backup = {
        Id = account_data.Id,
        UserName = account_data.UserName,
        Password = account_data.Password,
        RoleId = account_data.RoleId,
        Enabled = account_data.Enabled,
        LoginInterface = account_data.LoginInterface
    }
    local account_db = self.m_table_account_backup(account_backup)
    account_db:save()
    self.m_account_backup_collection[account_data.Id] = account_db
end

function AccountPermanentBackup:remove_permantent_account(account_id)
    if account_id < DEFAULT_MIN_USER_NUM or account_id > DEFAULT_MAX_USER_NUM then
        return
    end
    local account_data = self.m_account_backup_collection[account_id]
    account_data:delete()
    self.m_account_backup_collection[account_id] = nil
end

function AccountPermanentBackup:flush_permantent_account(account_id, parameter)
    if account_id < DEFAULT_MIN_USER_NUM or account_id > DEFAULT_MAX_USER_NUM then
        return
    end
    local account = self.m_account_collection:get_account_data_by_id(account_id)
    local account_backup = self.m_account_backup_collection[account_id]

    if parameter then
        account_backup[parameter] = account[parameter]
    else
        account_backup.UserName = account.UserName
        account_backup.Password = account.Password
        account_backup.RoleId = account.RoleId
        account_backup.Enabled = account.Enabled
        account_backup.LoginInterface = account.LoginInterface
    end

    account_backup:save()
end

return singleton(AccountPermanentBackup)