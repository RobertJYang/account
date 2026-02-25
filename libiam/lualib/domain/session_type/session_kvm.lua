-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
local session_type = require 'domain.session_type.session_type'
local session = require 'domain.session'
local class = require 'mc.class'
local singleton = require 'mc.singleton'
local log = require 'mc.logging'
local iam_enum = require 'class.types.types'
local base_msg = require 'messages.base'
local custom_msg = require 'messages.custom'
local vos = require 'utils.vos'
local user_config = require 'user_config'
local KVM_KEY_TIMEOUT<const> = 120 -- KVM_KEY2分钟失效
local KVM_NOT_AUTH_TIMEOUT<const> = 120 -- KVM未认证会话2分钟失效

local KVMSession = class(session_type)

function KVMSession:ctor()
    self.timeout_min = 0 -- KVM会话超时时间最短0:永不超时
    self.timeout_max = 28800 -- KVM会话超时时间最长480分钟
end

function KVMSession:create(account, auth_type, ip, create_session_mode, _, system_id)
    if type(create_session_mode) == 'number' then
        local ok, ret = pcall(iam_enum.OccupationMode.new, create_session_mode)
        if not ok then
            error(custom_msg.PropertyItemNotInList(create_session_mode, 'SessionMode'))
        end
        create_session_mode = ret
    end
    if not self:have_free_session_by_system_id(system_id) then
        log:error("The host(%s) has currently exceeded the maximum number of sessions", system_id)
        error(base_msg.SessionLimitExceeded())
    end
    -- 检查创建会话指定的会话模式
    self:session_mode_validator(create_session_mode, system_id)

    local new_session = session.new(account, self:get_session_type(), auth_type, ip, nil)
    new_session.m_csrf_token = ''
    new_session.m_session_mode = self:get_session_mode()
    new_session.m_valid_flag = false
    new_session.m_no_valid_check_time = 0
    new_session.system_id = system_id
    table.insert(self.m_session_collection, new_session)
    self.m_kvm_session_mode[system_id] = new_session.m_session_mode
    self.m_create_session:emit(new_session)
    return new_session
end

local function is_session_in_list(session_list, session)
    for _, s in pairs(session_list) do
        if s.m_session_id == session.m_session_id then
            return true
        end
    end

    return false
end

--- 获取超时会话
function KVMSession:get_timeout_session_list()
    local timeout_session_list = {}

    -- 未认证会话的超时校验优先于常规超时校验
    local cur_session
    for index = #self.m_session_collection, 1, -1 do
        cur_session = self.m_session_collection[index]
        local system_id = cur_session.system_id
        cur_session.m_no_valid_check_time = cur_session.m_no_valid_check_time + 5
        if not cur_session.m_valid_flag and cur_session.m_no_valid_check_time > KVM_NOT_AUTH_TIMEOUT then
            table.insert(timeout_session_list, cur_session)
            log:error("KVM systemid(%s) session(%s) without authentication timeout, now quit",
                system_id, cur_session.m_username)
        end
    end

    -- SessionTimeout为0时永不超时(KVM、VNC),直接返回
    if self.m_session_service_config.SessionTimeout == 0 then
        return timeout_session_list
    end

    local now = vos.vos_get_cur_time_stamp()
    for index = #self.m_session_collection, 1, -1 do
         cur_session = self.m_session_collection[index]
        -- 每5秒检查一次会话超时时间
        cur_session.m_last_active_time = cur_session.m_last_active_time + 5
        if cur_session.m_last_active_time >= self:get_session_timeout() then
            if not is_session_in_list(timeout_session_list, cur_session) then
                table.insert(timeout_session_list, cur_session)
            end
            goto continue
        end
        if cur_session.m_created_time < now - user_config.SESSION_EXIPRES_SEC then
            if not is_session_in_list(timeout_session_list, cur_session) then
                table.insert(timeout_session_list, cur_session)
            end
        end
        ::continue::
    end
    return timeout_session_list
end

function KVMSession:validate_session(cur_session)
    cur_session.m_valid_flag = true
    return cur_session.m_session_id
end

-- 设置KvmKey
function KVMSession:set_kvm_key(kvm_key, mode, user_name)
    -- kvm key长度固定64个16进制字符
    if not kvm_key or #kvm_key ~= 64 then
        log:error('Set kvm key failed, invalid key length')
        error(base_msg.InternalError())
    end
    self.kvm_key_info = {
        m_kvm_key = kvm_key,
        m_session_mode = mode,
        m_created_time = os.time(),
        m_username = user_name
    }
end

--- 会话模式校验
function KVMSession:session_mode_validator(mode, system_id)
    -- 当前为独占或指定创建独占会话且已有kvm会话则不可创建
    if self:get_session_mode_by_system_id(system_id) == iam_enum.OccupationMode.Exclusive or
        mode == iam_enum.OccupationMode.Exclusive then
       if self:get_session_num_by_system_id(system_id) ~= 0 then
            log:error('create %s mode failed, The session is already exclusive', mode)
            error(custom_msg.SessionModeIsExclusive('KVM'))
       end
    end
    -- 会话模式不一致需修改
    if self:get_session_mode() ~= mode then
        self:set_session_mode(mode)
        self.m_update_session_service:emit(
            self.m_session_service_config.SessionType, 'SessionMode', mode:value())
    end
end

--- 获取kvmkey
function KVMSession:get_kvm_key()
    if self.kvm_key_info and os.time() - self.kvm_key_info.m_created_time > KVM_KEY_TIMEOUT then
        self.kvm_key_info = nil
        return nil
    end
    return self.kvm_key_info
end

--- 销毁kvmkey
function KVMSession:destroy_kvm_key()
    if self.kvm_key_info then
        self.kvm_key_info = nil
    end
end

function KVMSession:get_session_num_by_system_id(system_id)
    local session_num = 0
    if self.m_session_collection == nil then
        error(custom_msg.ArraySizeTooShort('m_session_collection', 0))
    end
    for _, v in pairs(self.m_session_collection) do
        if v.system_id == system_id then
            session_num = session_num + 1
        end
    end
    return session_num
end

--- 判断是否还有剩余kvm创建会话数
function KVMSession:have_free_session_by_system_id(system_id)
    local session_num = self:get_session_num_by_system_id(system_id)
    return session_num < self.m_session_service_config.SessionMaxCount
end

function KVMSession:get_session_mode_by_system_id(system_id)
    return self.m_kvm_session_mode[system_id]
end

return singleton(KVMSession)
