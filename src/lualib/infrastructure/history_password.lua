-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local crypt = require 'utils.crypt'
local config = require 'common_config'

local history_password = class()

function history_password:ctor(db, account_id)
    self.db = db
    self.m_account_id = account_id
end

--- 插入指定用户历史密码
---@param password string
function history_password:insert(password, kdf_password, history_password_count)
    if history_password_count == 0 then
        return
    end

    local history_password_list = self:get()
    local idx = #history_password_list + 1
    for _, row in ipairs(history_password_list) do
        if idx > history_password_count then
            row:delete()
        elseif row.SequenceNumber ~= idx then
            row.SequenceNumber = idx
            row:save()
        end
        idx = idx - 1
    end
    local history_password_db = self.db:select(self.db.HistoryPassword)
    history_password_db.table({
        AccountId = self.m_account_id, SequenceNumber = 1, Password = password, KDFPassword = kdf_password
    })
end

--- 删除指定用户历史密码表
function history_password:delete()
    self.db:delete(self.db.HistoryPassword):where(self.db.HistoryPassword.AccountId:eq(self.m_account_id)):all()
end

--- 更新所有用户的历史密码表
---@param current_password string
function history_password:update(current_password, kdf_password, history_password_count)
    local history_password_list = self:get()
    if #history_password_list == 0 and history_password_count > 0 then
        self:insert(current_password, kdf_password)
    end

    self.db:delete(self.db.HistoryPassword)
        :where(self.db.HistoryPassword.AccountId:eq(self.m_account_id),
            self.db.HistoryPassword.SequenceNumber:gt(history_password_count)):all()
end

--- 获取指定用户历史密码表
function history_password:get()
    local history_password_list = self.db:select(self.db.HistoryPassword)
        :where(self.db.HistoryPassword.AccountId:eq(self.m_account_id))
        :order_by(self.db.HistoryPassword.SequenceNumber, true):all()
    return history_password_list or {}
end

--- 根据历史密码盐值加密密码
---@param history_password string
---@param new_password string
---@param pattern string
---@return boolean
function history_password:check_password_same(history_password, new_password, pattern)
    if not (history_password and new_password)then
        return false
    end
    local salt = string.match(history_password, pattern)
    if not salt then
        return new_password == history_password
    end
    local crypt_password = crypt.crypt(new_password, salt)
    return crypt_password == history_password
end

--- 检查指定用户是否历史密码包含当前密码
---@param password string
function history_password:check(password)
    local history_password_list = self:get()
    for _, row in pairs(history_password_list) do
        -- 存在相同历史密码则检查不通过,返回false
        if self:check_password_same(row.KDFPassword, password, config.SHA512_SALT_PATTERN) or
            self:check_password_same(row.Password, password, config.SHA512_SALT_PATTERN) then
            return false
        end
    end
    return true
end

return history_password