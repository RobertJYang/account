-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local log = require 'mc.logging'
local class = require 'mc.class'
local signal = require 'mc.signal'
local vos_utils = require 'utils.vos'
local crypt = require 'utils.crypt'
local base_msg = require 'messages.base'
local md5 = require 'md5.core'
local json = require 'cjson'
local enum = require 'class.types.types'
local err = require 'account.errors'
local ipmi_cmds = require 'account.ipmi.ipmi'
local config = require 'common_config'
local utils = require 'infrastructure.utils'
local kmc_client = require 'infrastructure.kmc_client'
local history_password = require 'infrastructure.history_password'
local global_account_cfg = require 'domain.global_account_config'
local login_rule_collection = require 'domain.login_rule.login_rule_collection'
local privilege = require 'domain.privilege'

-- 盐值生成16位长度
local LINUX_PASSWD_CRYPT_SALT_LENGTH = 16
local SaltCharset = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

local DAY_SECOND_COUNT = 24 * 60 * 60

local ManagerAccount = class()
function ManagerAccount:ctor(db, account, password_validator, ipmi_channel_config)
    local kmc_client = kmc_client.get_instance()
    local account_svc_cfg = global_account_cfg.get_instance()
    local rc = login_rule_collection.get_instance()
    local ipmi_test_passwd_lock = {}
    local max = account_svc_cfg:get_max_user_num()
    for i = 0, max, 1 do
        ipmi_test_passwd_lock[i] = {}
        ipmi_test_passwd_lock[i].last_lock_flag = enum.UserLocked.USER_UNLOCK
        ipmi_test_passwd_lock[i].last_fail_time = 0
        ipmi_test_passwd_lock[i].test_fail_cnt = 0
    end
    self.m_account_data = account
    self.kmc_client = kmc_client
    self.m_user_status = enum.UserLocked.USER_UNLOCK
    self.m_ipmi_test_passwd_lock = ipmi_test_passwd_lock
    self.m_user_lock_start_time = 0
    self.m_account_config = account_svc_cfg
    self.m_login_rule_collection = rc
    self.m_history_password = history_password.new(db, account.Id)
    self.m_account_update_signal = signal.new()
    self.m_snmp_update_signal = signal.new()
    self.current_privileges = nil
    self.login_record_flush_flag = false
    self.password_validator_obj = password_validator
    self.m_ipmi_channel_config = ipmi_channel_config
end

-- 获取用户当前锁定状态
function ManagerAccount:get_account_status()
    return self.m_user_status
end

-- 设置用户当前锁定状态(该属性无需持久化)
function ManagerAccount:set_account_status(status)
    self.m_user_status = status
end

function ManagerAccount:get_account_data()
    return self.m_account_data, self.m_snmp_user_info_data, self.m_ipmi_user_info_data
end

function ManagerAccount:init_snmp_user_info(snmp_user_info_data)
    self.m_snmp_user_info_data = snmp_user_info_data
    self.m_snmp_user_info_data:save()
end

--- 使用随机盐值加密用户密码
---@param password string
---@return string sha512加密密文
---@return string scrypt加密密文
function ManagerAccount:crypt_password_by_random_salt(password)
    local random_byte = vos_utils.get_random_array(LINUX_PASSWD_CRYPT_SALT_LENGTH)
    local salt = random_byte:gsub('.', function(s)
        local loc = string.byte(s) % #SaltCharset + 1 -- 这里的位置必须加1，保证从首位字符串开始
        return string.sub(SaltCharset, loc, loc)
    end)
    local sha512crypt_salt = config.SHA512_CRYPT_SALT_PREFIX .. salt
    local crypt_password = crypt.crypt(password, sha512crypt_salt)
    local kdf_password = crypt.crypt(password, sha512crypt_salt)
    return crypt_password, kdf_password
end

function ManagerAccount:new_account_snmp_info(snmp_user_info_data)
    local snmp_init_pwd = snmp_user_info_data.SNMPKDFPassword
    local ok, snmp_ku = utils.generate_ku(snmp_user_info_data.AuthenticationProtocol:value(), snmp_init_pwd)
    if not ok then
        error(err.auth_algo_not_support())
    end
    snmp_user_info_data.SNMPPassword, snmp_user_info_data.SNMPKDFPassword =
        self:crypt_password_by_random_salt(snmp_init_pwd)
    snmp_user_info_data.AuthenticationKey = snmp_ku
    snmp_user_info_data.EncryptionKey = snmp_ku
    self.m_snmp_user_info_data = snmp_user_info_data
end

function ManagerAccount:record_login_time_ip(timestamp, ip, flush_flag)
    if timestamp then
        self.m_account_data.LastLoginTime = timestamp
        self.login_record_flush_flag = true
    end
    if ip then
        self.m_account_data.LastLoginIP = ip
        self.login_record_flush_flag = true
    end
    if flush_flag then
        self.m_account_data:save()
        self.login_record_flush_flag = false
    end
end

function ManagerAccount:record_last_login_interface(interface, flush_flag)
    if interface then
        self.m_account_data.LastLoginInterface = interface
        self.login_record_flush_flag = true
    end
    if flush_flag then
        self.m_account_data:save()
        self.login_record_flush_flag = false
    end
end

--- 对密文密码的校验，该方法仅此类需要，其他类型用户不需要
local function encrypted_password_validator(encrypted_password)
    -- 要求密文格式为$算法类型$盐值$哈希值
    local crypt_algorithm, salt, hash_value = encrypted_password:match("%$(.-)%$(.-)%$(.-)$")
    if not crypt_algorithm or not salt or not hash_value then
        log:error('Type of encrypted password is invalid')
        error(base_msg.InternalError())
    end
end

function ManagerAccount:init_account_password(account_info)
    -- 如果新增用户密码为空(IPMI命令设置用户名时增加用户没有密码)，则设置密码及IPMI密码为空，否则进行加密
    if utils.str_is_empty(account_info.password) then
        self.m_account_data.Password, self.m_account_data.KDFPassword = '', ''
        self.m_account_data.IpmiPassword = ''
        return
    end
    if account_info.is_pwd_encrypted then
        encrypted_password_validator(account_info.password)
        self.m_account_data.Password = account_info.password
        self.m_account_data.IpmiPassword = ''
    else
        self.m_account_data.Password, self.m_account_data.KDFPassword =
            self:crypt_password_by_random_salt(account_info.password)
        self.m_account_data.IpmiPassword = self.kmc_client:encrypt_password(account_info.password)
    end
end

--- account_info中包含用户名字、用户id、角色id、可登录的接口、首次登录策略
function ManagerAccount:init_account(account_info)
    self:init_account_password(account_info)
    self.m_account_data.UserName = account_info.name
    self.m_account_data.RoleId = account_info.role_id
    self.m_account_data.SshPublicKeyHash = ''
    self.m_account_data.Enabled = true
    self.m_account_data.Locked = false
    self.m_account_data.Deletable = true
    self.m_account_data.PasswordChangeRequired = true
    self.m_account_data.LastLoginInterface = enum.LoginInterface.Invalid
    self.m_account_data.FirstLoginPolicy = account_info.first_login_policy or
        enum.FirstLoginPolicy.ForcePasswordReset
    self.m_account_data.AccountType = enum.AccountType.Local
    self.m_account_data.LoginInterface = utils.cover_interface_enum_to_num(account_info.interface)
    self.m_account_data.LoginRuleIds = 0
    self.m_account_data.PasswordValidStartTime = vos_utils.vos_get_cur_time_stamp()
    self.m_account_data.PasswordExpiration = 0xffffffff
    self.m_account_data.WithinMinPasswordDays = false
    self.m_account_data.LastLoginTime = 0xffffffff
    self.m_account_data.LastLoginIP = ""
    self.m_account_data.PasswordValidStartTime = vos_utils.vos_get_cur_time_stamp()
end

function ManagerAccount:make_rmcp_code_with_passwd(auth_algo, data)
    if self.m_account_data.IpmiPassword == '' or self.m_account_data.IpmiPassword == nil then
        error(err.ipmi_password_empty())
    end
    local key = self.kmc_client:decrypt_password(self.m_account_data.IpmiPassword)
    if auth_algo == enum.RmcpAuthAlgo.HmacSha1 then
        local out = crypt.hmac_sha1(key, data)
        return out
    elseif auth_algo == enum.RmcpAuthAlgo.HmacSha2 then
        return crypt.hmac_sha2(key, data)
    else
        error(err.auth_algo_not_support())
    end
end

function ManagerAccount:gen_rakp2_auth_code(auth_algo, console_sid, managed_sid, console_random,
    managed_random, managed_guid, role)
    -- SIDm + SIDc  + Rm + Rc + GUIDc + ROLEm + ULENGTHm + usernameLen
    local data = string.pack('I4I4c16c16c16Bs1', console_sid, managed_sid, console_random, managed_random,
        managed_guid, role, self.m_account_data.UserName)
    return self:make_rmcp_code_with_passwd(auth_algo, data)
end

function ManagerAccount:gen_rakp3_auth_code(auth_algo, managed_random, console_sid, role)
    -- Rc ＢＭＣ随机数 + SIDm 控制台端的会话ID + ROLEm 权限 + ULENGTHm 用户名长度 + usernameLen
    local data = string.pack('c16I4Bs1', managed_random, console_sid, role, self.m_account_data.UserName)
    return self:make_rmcp_code_with_passwd(auth_algo, data)
end

function ManagerAccount:gen_sik(auth_algo, console_random, managed_random, role)
    -- 客户端随机数 + BMC随机数 + ROLEm + 用户名长度字节 + usernameLen
    local data = string.pack('c16c16Bs1', console_random, managed_random, role, self.m_account_data.UserName)
    return self:make_rmcp_code_with_passwd(auth_algo, data)
end

function ManagerAccount:gen_rmcp_md5_code(auth_algo, pay_load, session_id, session_sequence)
    if auth_algo ~= enum.RmcpAuthAlgo.HmacMd5 then
        error(err.auth_algo_not_support())
    end
    if self.m_account_data.IpmiPassword == '' or self.m_account_data.IpmiPassword == nil then
        error(err.ipmi_password_empty())
    end
    local pwd = self.kmc_client:decrypt_password(self.m_account_data.IpmiPassword)
    if #pwd > 16 then
        pwd = pwd:sub(1, 16)
    elseif #pwd < 16 then
        pwd = pwd .. string.rep('\x00', 16 - #pwd)
    end
    local buf_fmt = string.format('c16I4c%dI4c16', #pay_load)
    local buf = string.pack(buf_fmt, pwd, session_id, pay_load, session_sequence, pwd)
    local md5_data = md5.sum(buf)
    return md5_data
end

function ManagerAccount:login_interface_exist(interface)
    local enable = self.m_account_data.LoginInterface & interface
    if enable ~= 0 then
        return true
    end
    return false
end

function ManagerAccount:set_user_snmp_pwd(password)
    self.m_snmp_user_info_data.SNMPPassword, self.m_snmp_user_info_data.SNMPKDFPassword =
        self:crypt_password_by_random_salt(password)
    self.m_snmp_user_info_data:save()
end

function ManagerAccount:set_user_auth_protocol(auth_protocol)
    self.m_snmp_user_info_data.AuthenticationProtocol = auth_protocol
    self.m_snmp_user_info_data:save()
end

function ManagerAccount:set_user_encrypt_protocol(encrypt_protocol)
    self.m_snmp_user_info_data.EncryptionProtocol = encrypt_protocol
    self.m_snmp_user_info_data:save()
end

function ManagerAccount:get_user_auth_ku()
    return self.m_snmp_user_info_data.AuthenticationKey
end

function ManagerAccount:set_user_auth_ku(snmp_ku)
    self.m_snmp_user_info_data.AuthenticationKey = snmp_ku
    self.m_snmp_user_info_data:save()
end

function ManagerAccount:get_user_encrypt_ku()
    return self.m_snmp_user_info_data.EncryptionKey
end

function ManagerAccount:set_user_encrypt_ku(snmp_ku)
    self.m_snmp_user_info_data.EncryptionKey = snmp_ku
    self.m_snmp_user_info_data:save()
end


function ManagerAccount:set_password_change_required(required)
    self.m_account_data.PasswordChangeRequired = required
    self.m_account_data:save()
    self:update_privileges()
end

function ManagerAccount:get_password_change_required()
    return self.m_account_data.PasswordChangeRequired
end

function ManagerAccount:set_first_login_policy(policy)
    self.m_account_data.FirstLoginPolicy = enum.FirstLoginPolicy.new(policy)
    self.m_account_data:save()
end

function ManagerAccount:get_first_login_policy()
    return self.m_account_data.FirstLoginPolicy
end

function ManagerAccount:init_ipmi_user_info(ipmi_user_info_data)
    self.m_ipmi_user_info_data = ipmi_user_info_data
end

function ManagerAccount:set_ipmi_user_use_20bytes_passwd(passwordlen)
    self.m_ipmi_user_info_data.Use20BytesPasswd = passwordlen
    self.m_ipmi_user_info_data:save()
end

function ManagerAccount:set_ipmi_user_access(req, ctx)
    local change_enable = req.ChangeEnable
    local ipmi_channel_config_info = {}
    ipmi_channel_config_info.AccountId = req.UserId
    ipmi_channel_config_info.PrivilegeLimit = req.UserPrivilege
    ipmi_channel_config_info.SessionLimit = string.unpack('>B', req.SessionLimit)

    ipmi_channel_config_info.ChannelNumber = req.ChannelNumber == enum.IpmiChannel.PRSENT_CHAN_NUM:value() and
        ctx.chan_num or req.ChannelNumber

    ipmi_channel_config_info.CallbackRestriction = req.UserRestricted
    ipmi_channel_config_info.LinkAuthenticationEnabled = (req.AuthenticationEnable == 1)
    ipmi_channel_config_info.IpmiMessagingEnabled = (req.MessagingEnable == 1)
    self.m_ipmi_channel_config:update(ipmi_channel_config_info, change_enable)
end

function ManagerAccount:get_ipmi_user_access(user_id, chan_num)
    local rsp = ipmi_cmds.GetUserAccess.rsp.new()
    rsp.MaxUserNumber = self.m_account_config:get_max_user_num()
    rsp.Reserved = 0

    -- 该通道上使能的用户数量EnabledUser
    rsp.EnabledUser = self.m_ipmi_channel_config:get_enabled_user_number_on_channel(chan_num)
    rsp.EnableStatus = 0
    if self.m_ipmi_user_info_data.IsEnableByPasswd == enum.IpmiUserEnableByPassword.PasswordEnable then
        rsp.EnableStatus = 1
    end

    rsp.UserNumber = 1
    rsp.Reserved2 = 0

    rsp.Reserved3 = 0
    -- 未配置的通道返回默认配置
    rsp.ChaAccessMode = 0
    rsp.LinkAuthentication = 1
    rsp.IpmiMessaging = 1
    rsp.PrivilegeLimit = enum.IpmiPrivilege.NO_ACCESS:value()
    -- 数据库读取配置信息
    local ipmi_channel_config_info = self.m_ipmi_channel_config:get(user_id, chan_num)
    if ipmi_channel_config_info ~= {} and #ipmi_channel_config_info ~= 0 then
        rsp.ChaAccessMode = ipmi_channel_config_info[1].CallbackRestriction
        rsp.LinkAuthentication = ipmi_channel_config_info[1].LinkAuthenticationEnabled == true and 1 or 0
        rsp.IpmiMessaging = ipmi_channel_config_info[1].IpmiMessagingEnabled == true and 1 or 0
        rsp.PrivilegeLimit = ipmi_channel_config_info[1].PrivilegeLimit
    end
    return rsp
end

function ManagerAccount:set_ipmi_user_privilege(privilege)
    if privilege == enum.IpmiPrivilege.NO_ACCESS:value() then
        privilege = enum.IpmiPrivilege.RESERVED:value()
    end
    self.m_ipmi_user_info_data.Privilege1 = enum.IpmiPrivilege.new(privilege)
    self.m_ipmi_user_info_data:save()
end

function ManagerAccount:get_ipmi_user_privilege()
    if self.m_ipmi_user_info_data.Privilege1 == enum.IpmiPrivilege.RESERVED then
        return enum.IpmiPrivilege.NO_ACCESS:value()
    end

    return self.m_ipmi_user_info_data.Privilege1:value()
end

function ManagerAccount:get_locked()
    return self.m_account_data.Locked
end

function ManagerAccount:set_locked(is_locked)
    self.m_account_data.Locked = is_locked
    self.m_account_data:save()
end

function ManagerAccount:set_password_valid_start_time(time)
    self.m_account_data.PasswordValidStartTime = time
end

function ManagerAccount:get_password_valid_start_time()
    return self.m_account_data.PasswordValidStartTime
end

function ManagerAccount:set_password_valid_time(days)
    self.m_account_data.PasswordExpiration = days
end

function ManagerAccount:get_password_valid_time()
    return self.m_account_data.PasswordExpiration
end

function ManagerAccount:calculate_password_valid_time()
    local max_password_valid_days = self.m_account_config:get_max_password_valid_days()
    local emergency_user_id = self.m_account_config:get_emergency_account()
    if max_password_valid_days == 0 or self.m_account_data.Id == emergency_user_id then
        return 0xffffffff
    end

    local timestamp = vos_utils.vos_get_cur_time_stamp()
    local days_passed = (timestamp - self:get_password_valid_start_time()) // DAY_SECOND_COUNT
    local days_remain = max_password_valid_days - days_passed
    if days_remain < 0 then
        log:notice('User %s password has been expire, cur_time : %s, pwd valid start time : %s',
            self:get_user_name(), timestamp, self:get_password_valid_start_time())
        days_remain = 0
    end
    return days_remain
end

function ManagerAccount:set_ipmi_enable_by_password(enabled)
    self.m_ipmi_user_info_data.IsEnableByPasswd = enabled
end

function ManagerAccount:get_ipmi_enable_by_password()
    return self.m_ipmi_user_info_data.IsEnableByPasswd
end

--- ipmi test password; Ipmi密码不存在或为空时使用linux密码
---@param password string
---@return boolean
function ManagerAccount:test_password_operation(password)
    if self.m_account_data.IpmiPassword and self.m_account_data.IpmiPassword ~= '' then
        return self.kmc_client:decrypt_password(self.m_account_data.IpmiPassword) == password
    end
    local crypt_salt, hash_value = self.m_account_data.Password:match(config.SHA512_SALT_PATTERN)
    if not crypt_salt or not hash_value then
        return false
    end
    return crypt.crypt(password, crypt_salt) == self.m_account_data.Password
end

function ManagerAccount:user_judge_priv_and_enable_valid()
    local user_enable = self:get_enabled()
    local privilege = self:get_ipmi_user_privilege()
    if (not user_enable) or privilege < enum.IpmiPrivilege.USER:value() or
        privilege > enum.IpmiPrivilege.ADMIN:value() then
        return false, nil
    end
    return true, privilege
end

--- 设置用户snmpv3加密密码初始状态，true为初始
---@param status boolean
function ManagerAccount:set_account_snmp_privacy_pwd_init_status(status)
    self.m_snmp_user_info_data.SnmpEncryptionPasswordInitialStatus = status
    self.m_snmp_user_info_data:save()
end

function ManagerAccount:get_snmp_privacy_password_init_status()
    return self.m_snmp_user_info_data.SnmpEncryptionPasswordInitialStatus
end

function ManagerAccount:update_ipmi_crypt_passwd()
    local pri_password = self.m_account_data.IpmiPassword
    local update_password = self.kmc_client:get_update_encrypt_password(self.m_account_data.IpmiPassword)
    self.m_account_data.IpmiPassword = update_password
    local ok = pcall(function()
        self.m_account_data:save()
    end)
    if not ok then
        log:error("account_id[%u] save ipmi password error", self.m_account_data.Id)
        self.m_account_data.IpmiPassword = pri_password
    end
end

-- 更新用户密码过期状态
function ManagerAccount:update_password_expire_status(status)
    -- 未过期时更新状态与当前状态一致则跳过
    if not status and self.m_account_data.PasswordExpiration > 0 then
        return
    end
    self:set_password_change_required(status)
    self.m_account_update_signal:emit("PasswordChangeRequired", status)
    local priv_up = status and {tostring(enum.PrivilegeType.ConfigureSelf)} or nil
    self:update_privileges(priv_up)
end

--- 更新用户当前拥有权限
function ManagerAccount:update_privileges(priv_input)
    local privilege_restrict_enabled = self.m_account_config:get_initial_account_privilege_restrict_enabled()
    local requied = self:get_password_change_required()
    local policy = self:get_first_login_policy()
    local role_id = self:get_role_id()
    local privileges = privilege.new_from_role_ids({ role_id }):to_array()
    if priv_input ~= nil and role_id ~= enum.RoleType.NoAccess:value() then
        privileges = priv_input
    end
    if privilege_restrict_enabled and requied and policy == enum.FirstLoginPolicy.ForcePasswordReset and
        role_id ~= enum.RoleType.NoAccess:value() then -- 无权限用户, Privileges始终为空
        privileges = { tostring(enum.PrivilegeType.ConfigureSelf) }
    end
    self.current_privileges = privileges
    self.m_account_update_signal:emit("Privileges", privileges)
end

-- 更新用户最后一次活跃时间
function ManagerAccount:update_inactive_user_start_time(flash_flag)
    local cur_timestamp = vos_utils.vos_get_cur_time_stamp()
    local threshold = self.m_account_config:get_inactive_time_threshold()
    -- 判断禁用不活跃用户功能是否开启, 0为未开启
    if threshold == 0 then
        log:debug('Skip update inactive time because inactive user checking is disabled.')
        return
    end
    -- 时间同步是否成功,非时间同步成功状态下的时间为非正常时间，待ntp支持

    self:set_inactive_start_time(cur_timestamp, flash_flag)
end

function ManagerAccount:set_user_ku(password, ku_type)
    -- 计算ku
    local auth_protocol = self.m_snmp_user_info_data.AuthenticationProtocol:value()
    local _, snmp_ku = utils.generate_ku(auth_protocol, password)
    -- 判断设置的Ku类型
    if ku_type == enum.SNMPKuType.Authentication then
        self:set_user_auth_ku(snmp_ku)
    elseif ku_type == enum.SNMPKuType.Encryption then
        self:set_user_encrypt_ku(snmp_ku)
    end
end

------------------------------ 重构:Interface声明 ------------------------------
--- 获取用户ID
---@return number
function ManagerAccount:get_id()
    return self.m_account_data.Id
end

--- 获取用户类型
---@return ManagerAccount.EnumAccountType
function ManagerAccount:get_account_type()
    return self.m_account_data.AccountType
end

--- 设置用户名
---@param user_name string 
function ManagerAccount:set_user_name(user_name) end

--- 获取用户名
---@return string
function ManagerAccount:get_user_name()
    return self.m_account_data.UserName
end

--- 获取用户密码
---@return string
function ManagerAccount:get_account_password()
    return self.m_account_data.Password
end

--- 设置用户角色
---@param role_id number
function ManagerAccount:set_role_id(role_id) end

--- 获取用户角色
---@return number
function ManagerAccount:get_role_id()
    return self.m_account_data.RoleId
end

--- 设置用户登录接口
---@param interface number
function ManagerAccount:set_login_interface(interface) end

--- 获取用户登录接口
---@return number
function ManagerAccount:get_login_interface()
    return self.m_account_data.LoginInterface
end

--- 设置用户登录规则
---@param login_rule_ids number 
function ManagerAccount:set_login_rule_ids(login_rule_ids)
    self.m_account_data.LoginRuleIds = login_rule_ids
    self.m_account_data:save()
end

--- 获取用户登录规则
---@return number
function ManagerAccount:get_login_rule_ids()
    return self.m_account_data.LoginRuleIds
end

--- 设置用户使能
---@param enabled boolean 
function ManagerAccount:set_enabled(enabled) end

--- 设置用户使能
---@return boolean
function ManagerAccount:get_enabled()
    return self.m_account_data.Enabled
end

--- 设置不活跃时间起点
---@param timestamp number
---@param flash_flag boolean
function ManagerAccount:set_inactive_start_time(timestamp, flash_flag) end

--- 检查用户不活跃状态
---@param have_only_enabled_admin boolean
---@param limit number
function ManagerAccount:update_inactive_status(have_only_enabled_admin, limit) end

--- 获取用户不活跃计时起点
function ManagerAccount:get_inactive_start_time()
    return self.m_account_data.InactiveStartTime
end

--- 更新用户是否可被删除标志
---@param is_last_enabled_admin boolean 
function ManagerAccount:update_deletable(have_only_enabled_admin) end

--- 获取用户是否可被删除标志
---@return boolean
function ManagerAccount:get_deletable()
    return self.m_account_data.Deletable
end

--- 设置密码是否在最短有效期内
---@param status boolean
function ManagerAccount:set_within_min_password_days_status(status) end

--- 获取密码是否在最短有效期内
---@return boolean
function ManagerAccount:get_within_min_password_days_status()
    return self.m_account_data.WithinMinPasswordDays
end

-- 更新用户密码有效期计时起点
function ManagerAccount:update_password_valid_start_time()
    local cur_timestamp = vos_utils.vos_get_cur_time_stamp()
    self:set_password_valid_start_time(cur_timestamp)
end

--- 导入SSH公钥
---@param path string
---@param home_path string
---@param uid number
---@param gid number
---@return string
function ManagerAccount:import_ssh_public_key(path, home_path, uid, gid) end

--- 删除公钥
---@param home_path string
function ManagerAccount:delete_ssh_public_key(home_path) end

--- 检查是否为使能管理员
---@return boolean
function ManagerAccount:check_is_enabled_admin()
    return false
end

--- 校验设置密码
---@param ctx table
---@param user_name string
---@param password string
---@param is_initial boolean
function ManagerAccount:password_validator(ctx, user_name, password, is_initial, is_config_self) end

--- 设置用户密码
---@param password string
function ManagerAccount:set_account_password(password, is_config_self) end

--- 检查用户登录规则
---@param ip string
function ManagerAccount:check_login_rule(ip)
    return false
end

--- 设置用户属性可写配置
---@param properties table
function ManagerAccount:set_properties_writable(ctx, properties) end

--- 获取用户属性可写配置
---@param property string
function ManagerAccount:get_property_writable(property)
    return true
end

function ManagerAccount:property_writable_check(property)
    local writable = self:get_property_writable(property .. 'Writable')
    if not writable then
        log:error('User(%d)\'s %s is not writable.', self.m_account_data.Id, property)
        error(base_msg.PropertyNotWritable(property))
    end
end


function ManagerAccount:recover_account_data(account_data)
    self.m_account_data.Id = account_data.Id
    self.m_account_data.UserName = account_data.UserName
    self.m_account_data.AccountExpiration = account_data.AccountExpiration
    self.m_account_data.Certificates = account_data.Certificates
    self.m_account_data.Enabled = account_data.Enabled
    self.m_account_data.Locked = account_data.Locked
    self.m_account_data.Deletable = account_data.Deletable
    self.m_account_data.Password = account_data.Password
    self.m_account_data.KDFPassword = account_data.KDFPassword
    self.m_account_data.PasswordChangeRequired = account_data.PasswordChangeRequired
    self.m_account_data.PasswordExpiration = account_data.PasswordExpiration
    self.m_account_data.RoleId = account_data.RoleId
    self.m_account_data.SshPublicKeyHash = account_data.SshPublicKeyHash
    self.m_account_data.IpmiPassword = account_data.IpmiPassword
    self.m_account_data.WithinMinPasswordDays = account_data.WithinMinPasswordDays
    self.m_account_data.LoginRuleIds = account_data.LoginRuleIds
    self.m_account_data.InactUserRemainDays = account_data.InactUserRemainDays
    self.m_account_data.LastLoginTime = account_data.LastLoginTime
    self.m_account_data.LastLoginIP = account_data.LastLoginIP
    self.m_account_data.LastLoginInterface = enum.LoginInterface.new(account_data.LastLoginInterface)
    self.m_account_data.FirstLoginPolicy = enum.FirstLoginPolicy.new(account_data.FirstLoginPolicy)
    self.m_account_data.AccountType = enum.AccountType.new(account_data.AccountType)
    self.m_account_data.LoginInterface = account_data.LoginInterface
    self.m_account_data.PasswordValidStartTime = account_data.PasswordValidStartTime
    self.m_account_data.InactiveStartTime = account_data.InactiveStartTime
    self.m_account_data.PasswordWritable = account_data.PasswordWritable
    self.m_account_data.UserNameWritable = account_data.UserNameWritable
    self.m_account_data.LoginInterfaceWritable = account_data.LoginInterfaceWritable
    self.m_account_data.RoleIdWritable = account_data.RoleIdWritable
    self.m_account_data.EnabledWritable = account_data.EnabledWritable
    self.m_account_data.LoginRuleIdsWritable = account_data.LoginRuleIdsWritable
    self.m_account_data.AuthenticationProtocolWritable = account_data.AuthenticationProtocolWritable
    self.m_account_data.EncryptionProtocolWritable = account_data.EncryptionProtocolWritable
    self.m_account_data.SNMPPasswordWritable = account_data.SNMPPasswordWritable
    self.m_account_data:save()
end

function ManagerAccount:recover_ipmi_data(ipmi_data)
    self.m_ipmi_user_info_data.AccountId = ipmi_data.AccountId
    self.m_ipmi_user_info_data.Use20BytesPasswd = ipmi_data.Use20BytesPasswd
    self.m_ipmi_user_info_data.IsCallin = ipmi_data.IsCallin
    self.m_ipmi_user_info_data.IsEnableAuth = ipmi_data.IsEnableAuth
    self.m_ipmi_user_info_data.IsEnableIpmiMsg = ipmi_data.IsEnableIpmiMsg
    self.m_ipmi_user_info_data.IsEnableByPasswd = enum.IpmiUserEnableByPassword.new(ipmi_data.IsEnableByPasswd)
    self.m_ipmi_user_info_data.Privilege0 =  enum.IpmiPrivilege.new(ipmi_data.Privilege0)
    self.m_ipmi_user_info_data.Privilege1 = enum.IpmiPrivilege.new(ipmi_data.Privilege1)
    self.m_ipmi_user_info_data:save()
end

function ManagerAccount:recover_snmp_data(snmp_data)
    self.m_snmp_user_info_data.AccountId = snmp_data.AccountId
    self.m_snmp_user_info_data.AuthenticationKey = snmp_data.AuthenticationKey
    self.m_snmp_user_info_data.AuthenticationKeySet = snmp_data.AuthenticationKeySet
    self.m_snmp_user_info_data.AuthenticationProtocol =
        enum.SNMPAuthenticationProtocols.new(snmp_data.AuthenticationProtocol)
    self.m_snmp_user_info_data.EncryptionKey = snmp_data.EncryptionKey
    self.m_snmp_user_info_data.EncryptionKeySet = snmp_data.EncryptionKeySet
    self.m_snmp_user_info_data.EncryptionProtocol = enum.SNMPEncryptionProtocols.new(snmp_data.EncryptionProtocol)
    self.m_snmp_user_info_data.SNMPPassword = snmp_data.SNMPPassword
    self.m_snmp_user_info_data.SNMPKDFPassword = snmp_data.SNMPKDFPassword
    self.m_snmp_user_info_data.SnmpEncryptionPasswordInitialStatus = snmp_data.SnmpEncryptionPasswordInitialStatus
    self.m_snmp_user_info_data:save()
end


function ManagerAccount:recover(account_data, ipmi_data, snmp_data)
    self:recover_account_data(account_data)
    self:recover_ipmi_data(ipmi_data)
    self:recover_snmp_data(snmp_data)
end

function ManagerAccount:get_accoutn_data_str()
    local account_data = {
        Id = self.m_account_data.Id,
        UserName = self.m_account_data.UserName,
        AccountExpiration = self.m_account_data.AccountExpiration,
        Certificates = self.m_account_data.Certificates,
        Enabled = self.m_account_data.Enabled,
        Locked = self.m_account_data.Locked,
        Deletable = self.m_account_data.Deletable,
        Password = self.m_account_data.Password,
        KDFPassword = self.m_account_data.KDFPassword,
        PasswordChangeRequired = self.m_account_data.PasswordChangeRequired,
        PasswordExpiration = self.m_account_data.PasswordExpiration,
        RoleId = self.m_account_data.RoleId,
        SshPublicKeyHash = self.m_account_data.SshPublicKeyHash,
        IpmiPassword = self.m_account_data.IpmiPassword,
        WithinMinPasswordDays = self.m_account_data.WithinMinPasswordDays,
        LoginRuleIds = self.m_account_data.LoginRuleIds,
        InactUserRemainDays = self.m_account_data.InactUserRemainDays,
        LastLoginTime = self.m_account_data.LastLoginTime,
        LastLoginIP = self.m_account_data.LastLoginIP,
        LastLoginInterface = self.m_account_data.LastLoginInterface:value(),
        FirstLoginPolicy = self.m_account_data.FirstLoginPolicy:value(),
        AccountType = self.m_account_data.AccountType:value(),
        LoginInterface = self.m_account_data.LoginInterface,
        PasswordValidStartTime = self.m_account_data.PasswordValidStartTime,
        InactiveStartTime = self.m_account_data.InactiveStartTime,
        PasswordWritable = self.m_account_data.PasswordWritable,
        UserNameWritable = self.m_account_data.UserNameWritable,
        LoginInterfaceWritable = self.m_account_data.LoginInterfaceWritable,
        RoleIdWritable = self.m_account_data.RoleIdWritable,
        EnabledWritable = self.m_account_data.EnabledWritable,
        LoginRuleIdsWritable = self.m_account_data.LoginRuleIdsWritable,
        AuthenticationProtocolWritable = self.m_account_data.AuthenticationProtocolWritable,
        EncryptionProtocolWritable = self.m_account_data.EncryptionProtocolWritable,
        SNMPPasswordWritable = self.m_account_data.SNMPPasswordWritable
    }
    return json.encode(account_data)
end

function ManagerAccount:get_ipmi_data_str()
    local ipmi_data = {
        AccountId = self.m_ipmi_user_info_data.AccountId,
        Use20BytesPasswd = self.m_ipmi_user_info_data.Use20BytesPasswd,
        IsCallin = self.m_ipmi_user_info_data.IsCallin,
        IsEnableAuth = self.m_ipmi_user_info_data.IsEnableAuth,
        IsEnableIpmiMsg = self.m_ipmi_user_info_data.IsEnableIpmiMsg,
        IsEnableByPasswd = self.m_ipmi_user_info_data.IsEnableByPasswd:value(),
        Privilege0 = self.m_ipmi_user_info_data.Privilege0:value(),
        Privilege1 = self.m_ipmi_user_info_data.Privilege1:value()
    }
    return json.encode(ipmi_data)
end

function ManagerAccount:get_snmp_data_str()
    local snmp_data = {
        AccountId = self.m_snmp_user_info_data.AccountId,
        AuthenticationKey = self.m_snmp_user_info_data.AuthenticationKey,
        AuthenticationKeySet = self.m_snmp_user_info_data.AuthenticationKeySet,
        AuthenticationProtocol = self.m_snmp_user_info_data.AuthenticationProtocol:value(),
        EncryptionKey = self.m_snmp_user_info_data.EncryptionKey,
        EncryptionKeySet = self.m_snmp_user_info_data.EncryptionKeySet,
        EncryptionProtocol = self.m_snmp_user_info_data.EncryptionProtocol:value(),
        SNMPPassword = self.m_snmp_user_info_data.SNMPPassword,
        SNMPKDFPassword = self.m_snmp_user_info_data.SNMPKDFPassword,
        SnmpEncryptionPasswordInitialStatus = self.m_snmp_user_info_data.SnmpEncryptionPasswordInitialStatus
    }
    return json.encode(snmp_data)
end

function ManagerAccount:get_backup_info()
    local account_data_str = self:get_accoutn_data_str()
    local ipmi_data_str    = self:get_ipmi_data_str()
    local snmp_data_str    = self:get_snmp_data_str()
    return account_data_str, ipmi_data_str, snmp_data_str
end

function ManagerAccount:is_delete_ipmi_interface(interface_num)
    local old_interface = self.m_account_data.LoginInterface
    -- 表示删除用户的ipmi接口权限
    if (old_interface >> 2) & 1 == 1 and (interface_num >> 2) & 1 == 0 then
        return true
    end
    return false
end

return ManagerAccount
