-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local class = require 'mc.class'
local role = require 'domain.role'
-- Privilege类用于session等对象在内存中临时持有，用于快速判断用户是否有权限操作相关接口，不用于角色管理，支持多角色
local Privilege = class()

---@param UserMgmt boolean
---@param BasicSetting boolean
---@param KVMMgmt boolean
---@param ReadOnly boolean
---@param VMMMgmt boolean
---@param SecurityMgmt boolean
---@param PowerMgmt boolean
---@param DiagnoseMgmt boolean
---@param ConfigureSelf boolean
function Privilege:ctor(UserMgmt, BasicSetting, KVMMgmt, ReadOnly, VMMMgmt, SecurityMgmt, PowerMgmt,
                       DiagnoseMgmt, ConfigureSelf)
    self.m_UserMgmt = UserMgmt
    self.m_BasicSetting = BasicSetting
    self.m_KVMMgmt = KVMMgmt
    self.m_ReadOnly = ReadOnly
    self.m_VMMMgmt = VMMMgmt
    self.m_SecurityMgmt = SecurityMgmt
    self.m_PowerMgmt = PowerMgmt
    self.m_DiagnoseMgmt = DiagnoseMgmt
    self.m_ConfigureSelf = ConfigureSelf
end

function Privilege.new_from_data(data)
    return setmetatable({
        m_UserMgmt = data.UserMgmt,
        m_BasicSetting = data.BasicSetting,
        m_KVMMgmt = data.KVMMgmt,
        m_ReadOnly = data.ReadOnly,
        m_VMMMgmt = data.VMMMgmt,
        m_SecurityMgmt = data.SecurityMgmt,
        m_PowerMgmt = data.PowerMgmt,
        m_DiagnoseMgmt = data.DiagnoseMgmt,
        m_ConfigureSelf = data.ConfigureSelf
    }, Privilege)
end

-- 重载 '+' 运算符
function Privilege.__add(a, b)
    return Privilege.new(a.m_UserMgmt or b.m_UserMgmt, a.m_BasicSetting or b.m_BasicSetting,
        a.m_KVMMgmt or b.m_KVMMgmt, a.m_ReadOnly or b.m_ReadOnly, a.m_VMMMgmt or b.m_VMMMgmt,
        a.m_SecurityMgmt or b.m_SecurityMgmt, a.m_PowerMgmt or b.m_PowerMgmt,
        a.m_DiagnoseMgmt or b.m_DiagnoseMgmt, a.m_ConfigureSelf or b.m_ConfigureSelf)
end

function Privilege.new_from_role_ids(role_ids)
    local res = Privilege.new(false, false, false, false, false, false, false, false, false)
    local role_collection = role.get_instance()
    for _, v in ipairs(role_ids) do
        local temp_role_data = role_collection:get_role_data_by_id(v)
        if temp_role_data ~= nil then
            res = res + Privilege.new_from_data(temp_role_data)
        end
    end
    return res
end

function Privilege:to_array()
    local res = {}
    for key, value in pairs(self) do
        if value == true then
            table.insert(res, key:sub(3))
        end
    end
    return res
end

local privilege_map = {
    ReadOnly = 2 ^ 0,
    DiagnoseMgmt = 2 ^ 1,
    SecurityMgmt = 2 ^ 2,
    BasicSetting = 2 ^ 3,
    UserMgmt = 2 ^ 4,
    PowerMgmt = 2 ^ 5,
    VMMMgmt = 2 ^ 6,
    KVMMgmt = 2 ^ 7,
    ConfigureSelf = 2 ^ 8
}

function Privilege:num_to_array(privilege_num)
    local privilege = {}
    for k, v in pairs(privilege_map) do
        if tonumber(privilege_num) & tonumber(v) ~= 0 then
            table.insert(privilege, tostring(k))
        end
    end
    return privilege
end

return Privilege
