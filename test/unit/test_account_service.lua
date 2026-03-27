-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Test passwords:[Admin123!, Paswd@90000, Paswd@123456789123456]
local lu = require 'luaunit'
local account_linux = require 'infrastructure.account_linux'
local config = require 'common_config'
local enum = require 'class.types.types'
local core = require 'account_core'
local utils = require 'infrastructure.utils'
local err_cfg = require 'error_config'
local vos = require 'utils.vos'
local custom_msg = require 'messages.custom'
local base_msg = require 'messages.base'
local err = require 'account.errors'
local file_utils = require 'utils.file'
local mc_utils = require 'mc.utils'

local function table_length(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

local function make_interface()
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish,
        enum.LoginInterface.SFTP, enum.LoginInterface.SNMP }
    return interface
end

local function make_channel_config(ctx, account_collection)
    account_collection:set_account_password(ctx, 2, 4, "Paswd@9000")
    local req = {}
    local ctx = {}
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    req.ChannelNumber = 1
    req.MessagingEnable = 1
    req.AuthenticationEnable = 1
    req.UserRestricted = 1
    req.ChangeEnable = 1
    req.UserId = 4
    req.UserPrivilege = 4
    req.SessionLimit = string.pack(">B", 0)
    return req, ctx
end

function TestAccount:add_test_account(user_id, login_interface)
    local interface = login_interface or make_interface()
    local account_info = {
        ['id'] = user_id,
        ['name'] = "test" .. tostring(user_id),
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
end

-- 重复获取的公私钥对应当相同(7天有效期内)
function TestAccount:test_repeatedly_require_requested_key_should_be_the_same()
    local key_tab_1 = self.test_global_account_config:get_web_requested_key_pair()
    local pub_key_1, priv_key_1 = key_tab_1.PublicKey, key_tab_1.PrivateKey
    local key_tab_2 = self.test_global_account_config:get_web_requested_key_pair()
    local pub_key_2, priv_key_2 = key_tab_2.PublicKey, key_tab_2.PrivateKey
    lu.assertEquals(pub_key_2, pub_key_1)
    lu.assertEquals(priv_key_2, priv_key_1)
end

-- 测试公私钥每5s更新有效时间正常
function TestAccount:test_requested_key_update_remain_time_per_5sec_success()
    local key_tab = self.test_global_account_config:get_web_requested_key_pair()
    local bef_update_remain = key_tab.RemainTime
    self.test_global_account_config:update_requested_key_pair(5)
    local aft_update_remain = key_tab.RemainTime
    lu.assertEquals(aft_update_remain, bef_update_remain - 5)
end

-- 测试公私钥有效时间不足5秒时，每次获取更新有效时间为5min
function TestAccount:test_get_requested_key_should_update_remain_time_to_5min_when_key_remain_time_less_than_5min()
    local key_tab = self.test_global_account_config:get_web_requested_key_pair()
    key_tab.RemainTime = 299        -- 4min59s
    key_tab = self.test_global_account_config:get_web_requested_key_pair()
    lu.assertEquals(key_tab.RemainTime, 300)
    key_tab.RemainTime = 5        -- 5s
    key_tab = self.test_global_account_config:get_web_requested_key_pair()
    lu.assertEquals(key_tab.RemainTime, 300)
end

-- 测试获取已过期公私钥会时会生成新公私钥
function TestAccount:test_get_expired_requested_key_should_generate_new_requested_key()
    local key_tab = self.test_global_account_config:get_web_requested_key_pair()
    local old_pub_key, old_priv_key = key_tab.PublicKey, key_tab.PrivateKey
    key_tab.RemainTime = 0  -- 有效时间0s
    key_tab = self.test_global_account_config:get_web_requested_key_pair()
    local old_pub_key2, old_priv_key2 = key_tab.PublicKey, key_tab.PrivateKey
    lu.assertNotEquals(old_pub_key2, old_pub_key)
    lu.assertNotEquals(old_priv_key2, old_priv_key)
    key_tab.RemainTime = -1 -- 有效时间-1s
    key_tab = self.test_global_account_config:get_web_requested_key_pair()
    local old_pub_key3, old_priv_key3 = key_tab.PublicKey, key_tab.PrivateKey
    lu.assertNotEquals(old_pub_key3, old_pub_key2)
    lu.assertNotEquals(old_priv_key3, old_priv_key2)
end

-- 测试使用公私钥对加解密密码成功
function TestAccount:test_encrypt_and_decrypt_password_success()
    local test_password = "Paswd@90000"
    local pub_key, priv_key = core.generate_requested_key_pair()
    local cipher_text = core.encrypt_with_public_key(pub_key, #pub_key, test_password, #test_password)
    local plain_text = core.decrypt_with_private_key(priv_key, #priv_key, cipher_text, #cipher_text)
    lu.assertEquals(plain_text, test_password)
end

-- 测试使用过期公钥加密后解密失败
function TestAccount:test_encrypt_with_expired_pub_key_should_decrypt_failed()
    local test_password = "Paswd@90000"
    local key_tab = self.test_global_account_config:get_web_requested_key_pair()
    local pub_key = key_tab.PublicKey
    local cipher_text = core.encrypt_with_public_key(pub_key, #pub_key, test_password, #test_password)
    key_tab.RemainTime = 0
    key_tab = self.test_global_account_config:get_web_requested_key_pair()
    local priv_key = key_tab.PrivateKey
    local plain_text = core.decrypt_with_private_key(priv_key, #priv_key, cipher_text, #cipher_text)
    lu.assertNotEquals(plain_text, test_password)
    lu.assertEquals(plain_text, "")
end

-- 测试初始化结果正确，初始化在setupClass()中开展了，因为全局都需要在初始化完成状态下开展
function TestAccount:test_account_service_init()
    lu.assertNotIsNil(self.test_account_collection)
    -- test_account_collection.collection[1] is nil and cnt
    lu.assertEquals(table_length(self.test_account_collection.collection), 7)
end

-- 测试可以通过id获取用户集合中的指定用户
function TestAccount:test_get_account_by_id()
    local test_account = self.test_account_collection.collection[2]
    lu.assertNotIsNil(test_account)
    lu.assertEquals(test_account.m_account_data.Id, 2)
    lu.assertEquals(test_account.m_account_data.UserName, 'Administrator')
    test_account = self.test_account_collection.collection[25]
    lu.assertIsNil(test_account)
    test_account = self.test_account_collection.collection[0]
    lu.assertIsNil(test_account)
end

-- 测试增加用户
function TestAccount:test_add_account()
    local interface = make_interface()
    self:add_test_account(3, interface)

    local test_account = self.test_account_collection.collection[3]
    lu.assertEquals(test_account.m_account_data.UserName, "test3")
    lu.assertEquals(test_account.m_account_data.LoginInterface, utils.cover_interface_enum_to_num(interface))
    self.test_account_collection:delete_account(self.ctx, 3)
    test_account = self.test_account_collection.collection[3]
    lu.assertIsNil(test_account)
end

-- 测试增加用户从2-17
function TestAccount:test_add_account_full()
    -- 包含默认的一个Administrator和一个VNC用户, IPMI用户与2个snmp community, 一个redfish专用用户，一个设备间内部通信用户
    local table_cnt = 7
    for id = 3, 17 do
        self:add_test_account(id)
        table_cnt = table_cnt + 1
    end
    local test_account = self.test_account_collection.collection[10]
    lu.assertEquals(test_account.m_account_data.UserName, "test10")
    for id = 3, 17 do
        test_account = self.test_account_collection.collection[id]
        lu.assertNotIsNil(test_account)
        lu.assertEquals(table_length(self.test_account_collection.collection), table_cnt)
        self.test_account_collection:delete_account(self.ctx, id)
        table_cnt = table_cnt - 1
        test_account = self.test_account_collection.collection[id]
        lu.assertIsNil(test_account)
    end
end

function TestAccount:test_user_file_sync()
    self:add_test_account(4)
    local account = self.test_account_collection.collection[4]

    local la1 = account_linux.new(config.LINUX_FILES, true)
    lu.assertNotIsNil(la1.passwd_file.datas["test4"])
    lu.assertNotIsNil(la1.ipmi_file.datas["test4"])

    -- 将用户从db与mbd移除
    account.m_account_data:delete()
    account.m_snmp_user_info_data:delete()
    account.m_ipmi_user_info_data:delete()
    account.m_history_password:delete()
    self.test_account_collection.collection[4] = nil

    self.test_file_synchronization:flush_account()
    local la2 = account_linux.new(config.LINUX_FILES, true)
    lu.assertIsNil(la2.passwd_file.datas["test4"])
    lu.assertIsNil(la2.ipmi_file.datas["test4"])
end

function TestAccount:test_user_file_sync_dfx()
    self:add_test_account(4)
    local account = self.test_account_collection.collection[4]

    local la1 = account_linux.new(config.LINUX_FILES, true)
    lu.assertNotIsNil(la1.passwd_file.datas["test4"])
    lu.assertNotIsNil(la1.ipmi_file.datas["test4"])

    -- 清空LINUX_FILES文件内容
    for _, v in pairs(config.LINUX_FILES) do
        os.execute('echo "" > ' .. v)

        local file = file_utils.open_s(v, 'w+')
        lu.assertNotIsNil(file)
        mc_utils.close(file, pcall(file.write, file, ""))

        file = file_utils.open_s(v, 'r')
        lu.assertNotIsNil(file)
        local content = mc_utils.close(file, pcall(file.read, file, "*a"))
        lu.assertEquals(content, "")
    end

    self.test_file_synchronization:flush_account()
    local la2 = account_linux.new(config.LINUX_FILES, true)
    lu.assertNotIsNil(la2.passwd_file.datas["test4"])
    lu.assertNotIsNil(la2.ipmi_file.datas["test4"])

    -- 恢复环境
    account.m_account_data:delete()
    account.m_snmp_user_info_data:delete()
    account.m_ipmi_user_info_data:delete()
    account.m_history_password:delete()
    self.test_account_collection.collection[4] = nil
end

function TestAccount:test_change_interface()
    self:add_test_account(3)
    local interface = { "IPMI", "Web" }
    self.test_account_collection:set_login_interface(self.ctx, 3, interface)
    local account = self.test_account_collection.collection[3]
    lu.assertEquals(account.m_account_data.LoginInterface, 5)

    local la1 = account_linux.new(config.LINUX_FILES, true)
    lu.assertEquals(la1.ipmi_file.datas["test3"].login_interface_num, 5)

    self.test_account_collection:delete_account(self.ctx, 3)
    account = self.test_account_collection.collection[3]
    lu.assertIsNil(account)
end

function TestAccount:test_change_role_id()
    self:add_test_account(3)
    self.test_account_collection:set_role_id(self.ctx, 3, 4)
    local account = self.test_account_collection.collection[3]
    lu.assertEquals(account.m_account_data.RoleId, 4)
    self.test_account_collection:delete_account(self.ctx, 3)
    account = self.test_account_collection.collection[3]
    lu.assertIsNil(account)
end

function TestAccount:test_change_user_name()
    self:add_test_account(3)
    self.test_account_collection:set_user_name(self.ctx, 3, "test3_new")
    local account = self.test_account_collection.collection[3]
    lu.assertEquals(account.m_account_data.UserName, "test3_new")
    self.test_account_collection:delete_account(self.ctx, 3)
    account = self.test_account_collection.collection[3]
    lu.assertIsNil(account)
end

function TestAccount:test_change_user_pwd()
    local account_data, last_sha512_pwd, new_sha512_pwd, last_kdf_pwd, new_kdf_pwd
    self:add_test_account(3)
    account_data = self.test_account_collection:get_account_data_by_id(3)
    last_sha512_pwd, last_kdf_pwd = account_data.Password, account_data.KDFPassword
    self.test_account_collection:set_account_password(self.ctx, 2, 3, "Paswd@9002")
    account_data = self.test_account_collection:get_account_data_by_id(3)
    new_sha512_pwd, new_kdf_pwd = account_data.Password, account_data.KDFPassword
    lu.assertNotEquals(last_sha512_pwd, new_sha512_pwd)
    lu.assertNotEquals(last_kdf_pwd, new_kdf_pwd)
    -- 恢复操作
    self.test_account_collection:delete_account(self.ctx, 3)
end

function TestAccount:test_change_user_pwd_in_weak_password_dictionary()
    self:add_test_account(3)
    lu.assertErrorMsgContains(custom_msg.PasswordInWeakPWDDictMessage.Name, function()
        self.test_account_service:set_account_password(self.ctx, 2, 3, "Admin123!")
    end)
    self.test_account_collection:delete_account(self.ctx, 3)
    local account = self.test_account_collection.collection[3]
    lu.assertIsNil(account)
end

function TestAccount:test_get_password_complexity_enable()
    local value = self.test_global_account_config:get_password_complexity_enable()
    lu.assertEquals(value, true)
end

function TestAccount:test_set_password_complexity_disable()
    local enable = false
    self.test_global_account_config:set_password_complexity_enable(enable)
    local value = self.test_global_account_config:get_password_complexity_enable()
    lu.assertEquals(value, enable)
end

function TestAccount:test_set_password_complexity_enable()
    local enable = true
    self.test_global_account_config:set_password_complexity_enable(enable)
    local value = self.test_global_account_config:get_password_complexity_enable()
    lu.assertEquals(value, enable)
end

-- pam锁定次数lib库测试
function TestAccount:test_pam_lock_cnt()
    local old_fail_time = 0
    for i = 1, 10, 1 do
        core.increment_pam_tally("Administrator", self.tally_dir)
        local fail_time, fail_cnt = core.get_pam_tally("Administrator", self.tally_dir, 300) -- 锁定时长300秒
        lu.assertEquals(fail_cnt, i)
        lu.assertIsTrue(fail_time >= old_fail_time)
        old_fail_time = fail_time
    end

    core.reset_pam_tally("Administrator", self.tally_dir)
    local fail_time, fail_cnt = core.get_pam_tally("Administrator", self.tally_dir, 300) -- 锁定时长300秒
    lu.assertEquals(fail_time, 0)
    lu.assertEquals(fail_cnt, 0)
end

function TestAccount:test_set_ipmi_password_complexity()
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    req.Control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_ENABLE:value()
    req.ManufactureId = 0x0007DB
    self.test_account_service:set_ipmi_password_complexity(req, ctx)
    local data = self.test_account_service:get_ipmi_password_complexity(req, ctx)
    lu.assertEquals(data, req.Control)

    req.Control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_DISABLE:value()
    self.test_account_service:set_ipmi_password_complexity(req, ctx)
    data = self.test_account_service:get_ipmi_password_complexity(req, ctx)
    lu.assertEquals(data, req.Control)

    req.Control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_STRONG_ENABLE:value()
    self.test_account_service:set_ipmi_password_complexity(req, ctx)
    data = self.test_global_account_config:get_password_complexity_lock()
    lu.assertEquals(data, true)
    data = self.test_account_service:get_ipmi_password_complexity(req, ctx)
    lu.assertEquals(data, req.Control)

    -- 开启强检查后，再次关闭密码复杂度检查
    req.Control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_DISABLE:value()
    lu.assertErrorMsgContains(custom_msg.PasswordForbidSetComplexityCheckMessage.Name, function ()
        self.test_account_service:set_ipmi_password_complexity(req, ctx)
    end)
    data = self.test_account_service:get_ipmi_password_complexity(req, ctx)
    lu.assertNotEquals(data, req.Control)

    -- 关闭密码复杂度强检查, 还原配置
    self.test_global_account_config:set_password_complexity_lock(false)

    -- 不合法的Control
    req.Control = 3
    lu.assertErrorMsgContains(custom_msg.IPMIOutOfRangeMessage.Name, function ()
        self.test_account_service:set_ipmi_password_complexity(req, ctx)
    end)

    req.Control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_DISABLE:value()
    -- 不合法的ManufactureId
    req.ManufactureId = 0x0007DA
    lu.assertErrorMsgContains(err.InvalidParameter, function ()
        self.test_account_service:set_ipmi_password_complexity(req, ctx)
    end)
end

function TestAccount:test_set_ipmi_password_complexity_in_manufacture_mode()
    local base_func = core.is_manufacture_mode
    core.is_manufacture_mode = (function () return true end)
    local req = {}
    local ctx = {}
    ctx.operation_log = {}
    req.Control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_STRONG_ENABLE:value()
    req.ManufactureId = 0x0007DB
    self.test_account_service:set_ipmi_password_complexity(req, ctx)

    req.Control = enum.IpmiPwdComplexityEnum.PWD_COMPLEXITY_DISABLE:value()
    self.test_account_service:set_ipmi_password_complexity(req, ctx)

    -- 装备模式下，开启强检查后，可以再次关闭密码复杂度检查
    data = self.test_account_service:get_ipmi_password_complexity(req, ctx)
    lu.assertEquals(data, req.Control)

    -- 还原配置
    self.test_global_account_config:set_password_complexity_lock(false)
    core.is_manufacture_mode = base_func
end

function TestAccount:test_set_ipmi_user_name()
    local req = {}
    local ctx = {}

    -- 增加用户
    req.UserName = 'Administrator3'
    req.UserId = 3
    self.test_account_collection:set_user_name(self.ctx, req.UserId, req.UserName)
    local user_name = self.test_account_collection:get_user_name(req.UserId)
    lu.assertEquals(user_name, req.UserName)
    -- 修改用户名
    req.UserName = 'Administrator4'
    self.test_account_collection:set_user_name(self.ctx, req.UserId, req.UserName)
    user_name = self.test_account_collection:get_user_name(req.UserId)
    lu.assertEquals(user_name, req.UserName)

    -- 删除用户
    req.UserName = ''
    req.UserId = 3
    self.test_account_collection:set_user_name(self.ctx, req.UserId, req.UserName)
    lu.assertEquals(false, self.test_account_collection:check_user_id_exist(req.UserId))

    -- 非法用户ID
    req.UserName = 'dafdfa'
    req.UserId = 18
    lu.assertErrorMsgContains(custom_msg.IPMIInvalidFieldRequestMessage.Name, function ()
        self.test_account_collection:set_user_name(self.ctx, req.UserId, req.UserName)
    end)
end

function TestAccount:test_set_ipmi_login_interface()
    local interface = { enum.LoginInterface.Redfish, enum.LoginInterface.SFTP }
    self:add_test_account(3, interface)
    local req = {}
    local ctx = {}
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    req.ManufactureId = 0x0007DB
    req.UserId = 3
    req.LoginInterface = 7
    req.Operation = 1
    req.PasswordData = 'Paswd@9000'
    req.PasswordLength = 10
    req.UserName = 'Test'
    self.test_account_service:set_ipmi_login_interface(req, ctx)
    self.test_account_collection:delete_account(self.ctx, 3)
end

function TestAccount:test_set_user_password()
    self:add_test_account(3)
    local account = self.test_account_collection:get_account_by_account_id(3)
    local req = {}
    local ctx = {}
    req.UserId = 3
    req.PasswordSize = 0 -- 16字节长
    req.PasswordData = 'Paswd@90001\0\0\0\0\0' -- 通过\0补齐到16字节
    ctx.ChanType = 3
    ctx.session = {}
    ctx.session.user = {}
    ctx.session.user.name = 'Administrator'
    ctx.session.user.id = 2
    req.Operation = 0 -- disable user
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    self.test_account_service:ipmi_set_account_password(req, ctx)
    lu.assertEquals(false, account:get_enabled())
    req.Operation = 1 -- enable user
    self.test_account_service:ipmi_set_account_password(req, ctx)
    lu.assertEquals(true, account:get_enabled())
    req.Operation = 2 -- set password
    self.test_account_service:ipmi_set_account_password(req, ctx)

    self.test_account_collection:delete_account(self.ctx, 3)
end

function TestAccount:test_set_user_password_fail()
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish, enum.LoginInterface.SFTP }
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = interface,
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    local account = self.test_account_collection:get_account_by_account_id(3)
    local req = {}
    local ctx = {}
    req.UserId = 3
    ctx.ChanType = 3
    ctx.session = {}
    ctx.session.user = {}
    ctx.session.user.name = 'Administrator'
    ctx.session.user.id = 2
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    req.Operation = 2 -- set password

    req.PasswordSize = 0 -- 16字节长
    req.PasswordData = 'Paswd@90001\0\0\0' -- 不够16字节
    lu.assertErrorMsgContains(custom_msg.IPMIRequestLengthInvalidMessage.Name, function()
        self.test_account_service:ipmi_set_account_password(req, ctx)
    end)

    req.PasswordSize = 0 -- 16字节长
    req.PasswordData = 'Paswd@90001\0\0\0\0\0\0\0\0\0\0' -- 超过16字节
    lu.assertErrorMsgContains(custom_msg.IPMIRequestLengthInvalidMessage.Name, function()
        self.test_account_service:ipmi_set_account_password(req, ctx)
    end)

    req.PasswordSize = 1 -- 20字节长
    req.PasswordData = 'Paswd@900010\0\0\0\0\0\0\0' -- 不够20字节
    lu.assertErrorMsgContains(custom_msg.IPMIRequestLengthInvalidMessage.Name, function()
        self.test_account_service:ipmi_set_account_password(req, ctx)
    end)

    req.PasswordSize = 1 -- 20字节长
    req.PasswordData = 'Paswd@90001\0\0\0\0\0\0\0\0\0\0' -- 不够20字节
    lu.assertErrorMsgContains(custom_msg.IPMIRequestLengthInvalidMessage.Name, function()
        self.test_account_service:ipmi_set_account_password(req, ctx)
    end)

    -- 禁用紧急用户
    req.Operation = 0 -- disable user
    self.test_account_service:set_emergency_account(self.ctx, req.UserId)
    self.test_account_service:ipmi_set_account_password(req, ctx)

    lu.assertEquals(true, account:get_enabled())

    self.test_account_service:set_emergency_account(self.ctx, 0)
    self.test_account_collection:delete_account(self.ctx, 3)
end

function TestAccount:test_set_password_age()
    local min_age = 5 -- 设置最短有效期为5天
    self.test_account_service:set_min_password_valid_days(min_age)
    local value = self.test_global_account_config:get_min_password_valid_days()
    lu.assertEquals(value, min_age)

    local max_age = 20 -- 设置最长有效期为20天
    self.test_account_service:set_max_password_valid_days(max_age)
    local value = self.test_global_account_config:get_max_password_valid_days()
    lu.assertEquals(value, max_age)

    local overrange_max_age = 366 -- 设置最长有效期为366天
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_account_service:set_max_password_valid_days(overrange_max_age)
    end)

    local invalid_max_age = 10 -- 设置最长有效期为10天
    lu.assertErrorMsgContains(custom_msg.MinPwdAgeAndPwdValidityRestrictEachOtherMessage.Name, function()
        self.test_account_service:set_max_password_valid_days(invalid_max_age)
    end)
end

-- 设置密码最短有效期后修改用户自己密码
function TestAccount:test_change_self_pwd_while_in_password_min_valid_limit()
    -- 添加用户Id:3,username:test3
    local interface = { enum.LoginInterface.IPMI, enum.LoginInterface.Redfish, enum.LoginInterface.SFTP }
    self:add_test_account(3, interface)
    -- 设置最短有效期10天
    self.test_global_account_config:set_min_password_valid_days(10)
    --  直接从collection设置最短密码有效期(未更新状态)
    lu.assertEquals(false, self.test_account_collection.collection[3]:get_within_min_password_days_status())
    self.test_account_collection:update_within_min_password_days_status()
    --  新增用户默认强制修改密码，此时可以修改成功
    lu.assertEquals(true, self.test_account_collection.collection[3]:get_within_min_password_days_status())
    lu.assertEquals(true, self.test_account_collection.collection[3]:get_password_change_required())
    lu.assertEquals(enum.FirstLoginPolicy.ForcePasswordReset,
        self.test_account_collection.collection[3]:get_first_login_policy())
    self.test_account_collection:set_account_password(self.ctx, 3, 3, "Paswd@9000")
    -- 修改后密码修改请求为false，此时在最短有效期内不可再次修改自己密码
    lu.assertErrorMsgContains(custom_msg.DuringMinimumPasswordAgeMessage.Name, function()
        self.test_account_collection:set_account_password(self.ctx, 3, 3, "Paswd@90000")
    end)
    --  通过service层设置最短有效期后会更新状态:0天
    self.test_account_service:set_min_password_valid_days(0)
    lu.assertEquals(false, self.test_account_collection.collection[3]:get_within_min_password_days_status())
    self.test_account_collection:delete_account(self.ctx, 3)
    local test_account = self.test_account_collection.collection[3]
    lu.assertIsNil(test_account)
end

function TestAccount:test_set_emergency_user()
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    account_info = {
        ['id'] = 4,
        ['name'] = "test4",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)

    local emergency_user = 3
    lu.assertErrorMsgContains(custom_msg.EmergencyLoginUserSettingFailMessage.Name, function()
        self.test_account_service:set_emergency_account(self.ctx, emergency_user)
    end)
    local value = self.test_global_account_config:get_emergency_account()
    lu.assertEquals(value, 0)
    self.test_account_collection:delete_account(self.ctx, emergency_user)
    emergency_user = 4
    self.test_account_service:set_emergency_account(self.ctx, emergency_user)
    value = self.test_global_account_config:get_emergency_account()
    lu.assertEquals(value, emergency_user)

    lu.assertErrorMsgContains(custom_msg.EmergencyLoginUserSettingFailMessage.Name, function()
        self.test_account_service:set_emergency_account(self.ctx, 23)
    end)
    value = self.test_global_account_config:get_emergency_account()
    lu.assertEquals(value, emergency_user)

    local la1 = account_linux.new(config.LINUX_FILES, true)
    lu.assertEquals(la1.ipmi_file.datas["test4"].is_exclude_user, 1)

    lu.assertErrorMsgContains(custom_msg.AccountForbidRemovedMessage.Name, function()
        self.test_account_collection:delete_account(self.ctx, emergency_user)
    end)
    lu.assertErrorMsgContains(custom_msg.EmergencyLoginUserMessage.Name, function()
        self.test_account_collection:set_enabled(emergency_user, false)
    end)

    local max_age = 10
    self.test_account_service:set_max_password_valid_days(max_age)
    local remain_time = self.test_account_collection.collection[emergency_user]:calculate_password_valid_time()
    lu.assertEquals(remain_time, 0xffffffff)

    self.test_account_service:set_emergency_account(self.ctx, 0)
    self.test_account_collection:delete_account(self.ctx, emergency_user)
    self.test_account_service:set_max_password_valid_days(0)
end

function TestAccount:test_set_emergency_user_by_username()
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    account_info = {
        ['id'] = 4,
        ['name'] = "test4",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    lu.assertErrorMsgContains(custom_msg.EmergencyLoginUserSettingFailMessage.Name, function()
        self.test_account_service:set_emergency_account(self.ctx, 3)
    end)
    self.test_account_service:set_emergency_account(self.ctx, 4)
    local emergency_user_id = self.test_global_account_config:get_emergency_account()
    lu.assertEquals(emergency_user_id, 4)

    local la1 = account_linux.new(config.LINUX_FILES, true)
    lu.assertEquals(la1.ipmi_file.datas["test4"].is_exclude_user, 1)

    lu.assertErrorMsgContains(custom_msg.AccountForbidRemovedMessage.Name, function()
        self.test_account_collection:delete_account(self.ctx, emergency_user_id)
    end)
    self.test_account_service:set_emergency_account(self.ctx, 0)
    self.test_account_collection:delete_account(self.ctx, 3)
    self.test_account_collection:delete_account(self.ctx, 4)
end

function TestAccount:test_check_user_time_info_while_pwd_max_valid_days_not_use()
    local max_age = 0 -- 密码最大有效期
    self.test_account_service:set_max_password_valid_days(max_age)
    local remain_time = self.test_account_collection.collection[2]:calculate_password_valid_time()
    lu.assertEquals(remain_time, 0xffffffff)
end

function TestAccount:test_check_user_time_info_while_user_password_not_expired()
    local max_age = 10
    self.test_account_collection.collection[2]:update_password_valid_start_time()
    self.test_account_service:set_max_password_valid_days(max_age)
    local remain_time = self.test_account_collection.collection[2]:calculate_password_valid_time()
    lu.assertEquals(remain_time, 10)
    -- 设置为0代表该密码有效期无限制
    self.test_account_service:set_max_password_valid_days(0)
end

function TestAccount:test_check_user_time_info_while_user_password_expired()
    local max_age = 10
    self.test_account_service:set_max_password_valid_days(max_age)
    self.test_account_collection.collection[2]:set_password_valid_start_time(1)
    self.test_account_collection:check_password_valid_days()
    local remain_time = self.test_account_collection.collection[2]:calculate_password_valid_time()
    lu.assertEquals(remain_time, 0)
    -- 设置为0代表该密码有效期无限制
    self.test_account_service:set_max_password_valid_days(0)
end

function TestAccount:test_check_user_time_info_while_detected_time_diff()
    local DAY_SECOND_COUNT = 24 * 60 * 60
    local max_age = 10
    self.test_account_collection.collection[2]:update_password_valid_start_time()
    self.test_account_service:set_max_password_valid_days(max_age)
    local time_set = -11 * DAY_SECOND_COUNT
    self.test_account_collection:update_all_password_valid_start_time(time_set)
    local remain_time = self.test_account_collection.collection[2]:calculate_password_valid_time()
    lu.assertEquals(remain_time, 0)
    -- 设置为0代表该密码有效期无限制
    self.test_account_service:set_max_password_valid_days(0)
end

-- 测试设置鉴权算法
function TestAccount:test_set_auth_protocol()
    self:add_test_account(3)
    self.test_account_service:set_user_auth_protocol(self.ctx, 2, 3,
        enum.SNMPAuthenticationProtocols.SHA512, "Paswd@9000", "Asplin@9000")
    local account = self.test_account_collection.collection[3]
    lu.assertEquals(account.m_snmp_user_info_data.AuthenticationProtocol,
        enum.SNMPAuthenticationProtocols.SHA512)
    self.test_account_collection:delete_account(self.ctx, 3)
    local test_account = self.test_account_collection.collection[3]
    lu.assertIsNil(test_account)

end

function TestAccount:test_set_encrypt_protocol()
    self:add_test_account(3)
    self.test_account_service:set_user_encrypt_protocol(self.ctx, 3, enum.SNMPEncryptionProtocols.AES256)
    local account = self.test_account_collection.collection[3]
    lu.assertEquals(account.m_snmp_user_info_data.EncryptionProtocol, enum.SNMPEncryptionProtocols.AES256)
    self.test_account_collection:delete_account(self.ctx, 3)
    local test_account = self.test_account_collection.collection[3]
    lu.assertIsNil(test_account)
end

function TestAccount:test_set_snmp_password()
    self:add_test_account(3)
    self.test_account_service:set_user_snmp_pwd(self.ctx, 3, "Paswd@90011")
    self.test_account_collection:delete_account(self.ctx, 3)
    local test_account = self.test_account_collection.collection[3]
    lu.assertIsNil(test_account)
end

-- 测试设置非法长度的snmp加密密码时，应该失败
function TestAccount:test_set_snmp_invalid_length_password_should_fail()
    self:add_test_account(3)
    -- 本用例仅检测关闭密码复杂度检查时的长度校验
    self.test_global_account_config:set_password_complexity_enable(false)
    local invalid_length_password = ''
    lu.assertErrorMsgContains(custom_msg.InvalidPasswordLengthMessage.Name, function()
        self.test_account_service:set_user_snmp_pwd(self.ctx, 3, invalid_length_password)
    end)
    invalid_length_password = 'Paswd@123456789123456'
    lu.assertErrorMsgContains(custom_msg.StringValueTooLongMessage.Name, function()
        self.test_account_service:set_user_snmp_pwd(self.ctx, 3, invalid_length_password)
    end)

    -- 清理现场
    self.test_account_collection:delete_account(self.ctx, 3)
    local test_account = self.test_account_collection.collection[3]
    self.test_global_account_config:set_password_complexity_enable(true)
    lu.assertIsNil(test_account)
end

-- 测试增加用户中account_service业务逻辑
function TestAccount:test_account_service_add_account()
    local interface = make_interface()
    self:add_test_account(3, interface)

    local test_account = self.test_account_collection.collection[3]
    lu.assertEquals(test_account.m_account_data.UserName, "test3")
    lu.assertEquals(test_account.m_account_data.LoginInterface, utils.cover_interface_enum_to_num(interface))
    self.test_account_collection:delete_account(self.ctx, 3)
    test_account = self.test_account_collection.collection[3]
    lu.assertIsNil(test_account)
end

-- 更新用户不活跃起点
function TestAccount:test_update_user_inactive_start_time()
    -- 启用禁用不活跃用户功能
    self.test_account_service:set_inactive_time_threshold(30)
    self:add_test_account(3)
    self:add_test_account(17)
    local cur_timestamp = vos.vos_get_cur_time_stamp()
    -- 设置用户不活跃起始时间为当前
    self.test_account_collection.collection[3]:update_inactive_user_start_time()
    local start_time = self.test_account_collection.collection[3]:get_inactive_start_time()
    lu.assertIsTrue(start_time >= cur_timestamp)
    self.test_account_collection:delete_account(self.ctx, 3)
    self.test_account_collection.collection[17]:update_inactive_user_start_time()
    start_time = self.test_account_collection.collection[17]:get_inactive_start_time()
    lu.assertIsTrue(start_time >= cur_timestamp)
    self.test_account_collection:delete_account(self.ctx, 17)
    self.test_account_collection.collection[2]:update_inactive_user_start_time()
    start_time = self.test_account_collection.collection[2]:get_inactive_start_time()
    lu.assertIsTrue(start_time >= cur_timestamp)
    -- 设置不存在用户不活跃起始时间，设置失败
    local ok = pcall(function()
        self.test_account_collection.collection[9]:update_inactive_user_start_time()
    end)
    lu.assertEquals(ok, false)
    -- 更新所有用户的不活跃起始时间
    ok = pcall(function()
        self.test_account_collection:update_inactive_start_time(nil)
    end)
    lu.assertEquals(ok, true)
end

function TestAccount:test_set_account_snmp_privacy_pwd_init_status()
    local account_info = {
        ['id'] = 6,
        ['name'] = "test6",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    local req = {}
    local ctx = {}
    req.UserId = 6
    req.PwdLength = 11
    req.Operation = 0
    req.ManufactureId = 0x0007db
    req.PasswordData = 'TestAdmin1@'

    ctx.session = {}
    ctx.session.user = {}
    ctx.session.user.name = 'test6'
    ctx.session.user.id = 6
    ctx.ChanType = enum.IpmiChannelType.IPMI_LAN
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    -- 设置加密密码成功
    local ret = self.test_account_service:ipmi_set_user_snmp_v3_privacy_pwd(req, ctx)
    lu.assertEquals(err_cfg.USER_OPER_SUCCESS, ret)
    local account = self.test_account_collection.collection[6]
    lu.assertEquals(account.m_snmp_user_info_data.SnmpEncryptionPasswordInitialStatus,
        false)
    self.test_account_collection:delete_account(self.ctx, 6)
end

function TestAccount:test_check_host_user_magagement_success()
    local ctx = {}
    ctx.ChanType = enum.IpmiChannelType.IPMI_HOST:value()

    local ret = self.test_global_account_config:get_host_user_management_enabled()
    lu.assertEquals(ret, true)
    local ret_val = self.test_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    lu.assertEquals(ret_val, nil)

    self.test_global_account_config:set_host_user_management_enabled(false)
    lu.assertErrorMsgContains(err.HostUserManagementDiabled, function()
        self.test_account_collection:check_ipmi_host_user_mgnt_enabled(ctx)
    end)

    self.test_global_account_config:set_host_user_management_enabled(true)
end

-- set user access 成功设置用户通道权限
function TestAccount:test_ipmi_set_user_access_when_config_not_exist_should_success()
    self:add_test_account(4)
    local req, ctx = make_channel_config(self.ctx, self.test_account_collection)
    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsTrue(ret)
    self.test_account_collection:delete_account(ctx, 4)
end

-- set user access 成功更改用户通道配置(ChangeEnable为1)
function TestAccount:test_ipmi_set_user_access_when_config_exist_should_success()
    self:add_test_account(4)
    local req, ctx = make_channel_config(self.ctx, self.test_account_collection)
    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsTrue(ret)
    -- 更改用户配置
    req.ChangeEnable = 1

    req.MessagingEnable = 0
    req.AuthenticationEnable = 0
    req.UserRestricted = 0
    req.UserPrivilege = 2
    req.SessionLimit = string.pack(">B", 1)
    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsTrue(ret)
    self.test_account_collection:delete_account(ctx, 4)
end

-- set user access 成功更改用户通道配置(ChangeEnable为0)
function TestAccount:test_ipmi_set_user_access_when_config_exist_should_success2()
    self:add_test_account(4)
    local req, ctx = make_channel_config(self.ctx, self.test_account_collection)
    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsTrue(ret)
    -- 更改用户配置
    req.ChangeEnable = 0

    req.MessagingEnable = 0
    req.AuthenticationEnable = 0
    req.UserRestricted = 0
    req.UserPrivilege = 2
    req.SessionLimit = string.pack(">B", 1)
    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsTrue(ret)
    self.test_account_collection:delete_account(ctx, 4)
end

-- 获取正常用户通道配置测试
function TestAccount:test_ipmi_get_user_access_success()
    self:add_test_account(4)
    local set_req, ctx = make_channel_config(self.ctx, self.test_account_collection)
    self.test_account_collection:set_ipmi_user_access(set_req, ctx)
    local req = {}
    local ctx = {}
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    req.UserId = 4
    req.ChannelNumber = 1

    local ok, ret = self.test_account_service:get_ipmi_user_access(req, ctx)
    lu.assertEquals(ok, err_cfg.USER_OPER_SUCCESS)
    lu.assertEquals(ret.MaxUserNumber, 17)
    lu.assertEquals(ret.EnableStatus, 1)
    lu.assertEquals(ret.UserNumber, 1)
    lu.assertEquals(ret.IpmiMessaging, 1)
    lu.assertEquals(ret.ChaAccessMode, 1)
    lu.assertEquals(ret.LinkAuthentication, 1)
    lu.assertEquals(ret.PrivilegeLimit, 4)
    self.test_account_collection:delete_account(ctx, 4)
end

function TestAccount:test_ipmi_get_user_access_enable()
    local user_id = 8
    self:add_test_account(user_id)

    local req = { UserId = user_id, PasswordSize = 0 }
    local ctx = { ChanType = 3 }
    ctx.session = {}
    ctx.session.user = {}
    ctx.session.user.name = 'Administrator'
    ctx.session.user.id = 2
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    req.PasswordData = 'Paswd@90001\0\0\0\0\0' -- 通过\0补齐到16字节

    req.Operation = 0 -- disable user
    self.test_account_service:ipmi_set_account_password(req, ctx)

    local user_access_req = {}
    user_access_req.UserId = user_id
    user_access_req.ChannelNumber = 1
    local _, ret = self.test_account_service:get_ipmi_user_access(user_access_req, ctx)
    lu.assertEquals(ret.EnableStatus, 2)

    req.Operation = 1 -- enable user
    self.test_account_service:ipmi_set_account_password(req, ctx)
    local _, access_ret = self.test_account_service:get_ipmi_user_access(user_access_req, ctx)
    lu.assertEquals(access_ret.EnableStatus, 1)

    self.test_account_collection:delete_account(ctx, user_id)
end

-- 获取空用户通道配置测试
function TestAccount:test_ipmi_get_empty_user_access_success()
    local req = {}
    local ctx = {}
    req.UserId = 4
    req.ChannelNumber = 1
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    pcall(function()
        self.test_account_collection:delete_account(ctx, 4)
    end)
    local ok, ret = self.test_account_service:get_ipmi_user_access(req, ctx)
    lu.assertEquals(ok, err_cfg.USER_OPER_SUCCESS)
    lu.assertEquals(ret.MaxUserNumber, 17)
    lu.assertEquals(ret.EnableStatus, 0)
    lu.assertEquals(ret.EnabledUser, 1)
    lu.assertEquals(ret.UserNumber, 1)
    lu.assertEquals(ret.IpmiMessaging, 1)
    lu.assertEquals(ret.LinkAuthentication, 1)
    lu.assertEquals(ret.ChaAccessMode, 0)
    lu.assertEquals(ret.PrivilegeLimit, enum.IpmiPrivilege.NO_ACCESS:value())
end

-- 用户存在未配置通道权限，获取通道配置成功测试
function TestAccount:test_ipmi_get_channel_not_config_should_success()
    local req = {}
    local ctx = {}
    req.UserId = 4
    req.ChannelNumber = 1
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    local ok, ret = self.test_account_service:get_ipmi_user_access(req, ctx)
    lu.assertEquals(ok, err_cfg.USER_OPER_SUCCESS)
    lu.assertEquals(ret.MaxUserNumber, 17)
    lu.assertEquals(ret.EnableStatus, 0)
    lu.assertEquals(ret.UserNumber, 1)
    lu.assertEquals(ret.IpmiMessaging, 1)
    lu.assertEquals(ret.LinkAuthentication, 1)
    lu.assertEquals(ret.ChaAccessMode, 0)
    lu.assertEquals(ret.PrivilegeLimit, enum.IpmiPrivilege.NO_ACCESS:value())
end

-- 用户ID非法，获取通道配置失败测试
function TestAccount:test_ipmi_get_invalid_user_id_config_should_fail()
    local req = {}
    local ctx = {}
    req.UserId = 18
    req.ChannelNumber = 1
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    local ret = pcall(function()
        self.test_account_service:get_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
end

-- 通道号非法，获取通道配置失败测试
function TestAccount:test_ipmi_get_invalid_channel_config_should_fail()
    local req = {}
    local ctx = {}
    req.UserId = 4
    req.ChannelNumber = 12
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    local ret = pcall(function()
        self.test_account_service:get_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
end

-- 设置单通道下，通道号非法
function TestAccount:test_ipmi_get_invalid_channel_config_when_singel_channel_status()
    local req = {}
    local ctx = {}
    local tmp = self.test_account_collection.ipmi_channel_mappings.multi_channel_status
    local tmp_translation = self.test_account_collection.ipmi_channel_mappings.channel_number_translation
    req.UserId = 4
    req.ChannelNumber = 3
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    self.test_account_collection.ipmi_channel_mappings.multi_channel_status = 0
    local ret = pcall(function()
        self.test_account_service:get_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
    self.test_account_collection.ipmi_channel_mappings.multi_channel_status = 1
    self.test_account_collection.ipmi_channel_mappings.channel_number_translation = function()
        return nil
    end
    ret = pcall(function()
        self.test_account_service:get_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
    self.test_account_collection.ipmi_channel_mappings.multi_channel_status = tmp
    self.test_account_collection.ipmi_channel_mappings.channel_number_translation = tmp_translation
end

-- 设置权限异常值失败测试
function TestAccount:test_ipmi_set_user_access_when_privilege_invalid_should_fail()
    self:add_test_account(4)
    local req, ctx = make_channel_config(self.ctx, self.test_account_collection)
    req.UserPrivilege = 0
    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
    self.test_account_collection:delete_account(ctx, 4)
end

-- 设置通道异常值失败测试
function TestAccount:test_ipmi_set_user_access_when_channel_invalid_should_fail()
    self:add_test_account(4)
    local req, ctx = make_channel_config(self.ctx, self.test_account_collection)
    req.ChannelNumber = 12  -- 通道异常
    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
    self.test_account_collection:delete_account(ctx, 4)
end

-- 设置用户不存在失败测试
function TestAccount:test_ipmi_set_user_access_when_account_not_exist_should_fail()
    local req = {}
    local ctx = {}
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    req.ChannelNumber = 12  -- 通道异常
    req.MessagingEnable = 1
    req.AuthenticationEnable = 1
    req.UserRestricted = 1
    req.ChangeEnable = 1
    req.UserId = 12
    req.UserPrivilege = 4
    req.SessionLimit = string.pack(">B", 0)

    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
end

-- 设置无效用户ID失败测试
function TestAccount:test_ipmi_set_user_access_when_accountid_invalid_should_fail()
    local req = {}
    local ctx = {}
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    req.ChannelNumber = 12  -- 通道异常
    req.MessagingEnable = 1
    req.AuthenticationEnable = 1
    req.UserRestricted = 1
    req.ChangeEnable = 1
    req.UserId = 18
    req.UserPrivilege = 4
    req.SessionLimit = string.pack(">B", 0)

    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
end

-- 设置无效会话限制失败测试
function TestAccount:test_ipmi_set_user_access_when_sessionlimit_invalid_should_fail()
    local req = {}
    local ctx = {}
    ctx.operation_log = { operation = nil, result = nil, params = {} }
    req.ChannelNumber = 12  -- 通道异常
    req.MessagingEnable = 1
    req.AuthenticationEnable = 1
    req.UserRestricted = 1
    req.ChangeEnable = 1
    req.UserId = 4
    req.UserPrivilege = 4
    req.SessionLimit = string.pack(">B", 17)

    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
end

-- 设置set user access命令长度超长测试
function TestAccount:test_ipmi_set_user_access_when_sessionlimit_too_long_should_fail()
    self:add_test_account(4)
    local req, ctx = make_channel_config(self.ctx, self.test_account_collection)
    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsTrue(ret)
    -- 更改用户配置
    req.ChangeEnable = 1

    req.MessagingEnable = 0
    req.AuthenticationEnable = 0
    req.UserRestricted = 0
    req.UserPrivilege = 2
    req.SessionLimit = string.pack(">BB", 1, 1)
    lu.assertErrorMsgContains(custom_msg.IPMIRequestLengthInvalidMessage.Name, function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    self.test_account_collection:delete_account(ctx, 4)
end

-- 设置通道为当前通道且不满足通道校验限制失败测试
-- 设置通道异常值失败测试
function TestAccount:test_ipmi_set_user_access_when_present_channel_invalid_should_fail()
    self:add_test_account(4)
    local req, ctx = make_channel_config(self.ctx, self.test_account_collection)
    req.ChannelNumber = 14  -- 通道异常
    ctx.chan_num = 16
    local ret = pcall(function()
        self.test_account_collection:set_ipmi_user_access(req, ctx)
    end)
    lu.assertIsFalse(ret)
    self.test_account_collection:delete_account(ctx, 4)
end

-- 测试get_id_by_user_name with InterChassis account when not visible
function TestAccount:test_get_id_by_user_name_with_interchassis_account_not_visible()
    -- 测试获取不可见的InterChassis账户ID应当失败
    lu.assertErrorMsgContains(custom_msg.UserNotExistMessage.Name, function()
        self.test_account_service:get_id_by_user_name(self.ctx, "inter_chassis")
    end)
end

--- 用户未满时，获取当前可添加的用户id应为最小的空闲id 
function TestAccount:test_get_valid_account_id_should_same_to_min_valid_id_when_user_is_not_full()
    --  只有用户2时应当获取到id为3
    local account_id = self.test_account_collection:get_valid_account_id(0, nil)
    lu.assertEquals(account_id, 3)
    --  添加id为3的用户,再次获取最小的可用id应为4
    self:add_test_account(3)
    account_id = self.test_account_collection:get_valid_account_id(0, nil)
    lu.assertEquals(account_id, 4)
    --  恢复操作
    self.test_account_collection:delete_account(self.ctx, 3)
end

--- 用户已满时，获取当前可添加用户id应为nil
function TestAccount:test_get_valid_account_id_should_be_nil_when_user_is_full()
    local account_info
    --  添加id:3-17用户
    for id = 3, 17 do
        self:add_test_account(id)
    end
    lu.assertErrorMsgContains(base_msg.CreateLimitReachedForResourceMessage.Name, function()
        self.test_account_collection:get_valid_account_id(0, nil)
    end)
    --  恢复操作
    for i = 3, 17 do
        self.test_account_collection:delete_account(self.ctx, i)
    end
end

--- 设置snmpv3trap用户的限制策略非法值，应该设置失败
function TestAccount:test_set_invalid_snmp_v3_trap_account_limit_policy_should_fail()
    local origin = self.test_global_account_config:get_snmp_v3_trap_account_limit_policy()
    lu.assertEquals(origin, 2)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_account_service:set_snmp_v3_trap_account_limit_policy(self.ctx, 3)
    end)
end

--- 设置snmpv3trap用户的变更策略非法值，应该设置失败
function TestAccount:test_set_invalid_snmp_v3_trap_account_change_policy_should_fail()
    local origin = self.test_global_account_config:get_snmp_v3_trap_account_change_policy()
    lu.assertEquals(origin, 0)
    lu.assertErrorMsgContains(base_msg.PropertyValueNotInListMessage.Name, function()
        self.test_global_account_config:set_snmp_v3_trap_account_change_policy(self.ctx, 2)
    end)
end

--- 设置snmpv3trap用户的变更策略合法值，应该设置成功
function TestAccount:test_set_invalid_snmp_v3_trap_account_change_policy_should_success() 
    self.test_global_account_config:set_snmp_v3_trap_account_change_policy(self.ctx, 1)
    local origin = self.test_global_account_config:get_snmp_v3_trap_account_change_policy()
    lu.assertEquals(origin, 1)
    -- 恢复环境
    self.test_global_account_config:set_snmp_v3_trap_account_change_policy(self.ctx, 0)
end

--- 设置RequireChangePasswordAction合法值，应该设置成功
function TestAccount:test_set_require_change_password_action_should_success()
    self.test_global_account_config:set_require_change_password_action(self.ctx, true)
    local origin = self.test_global_account_config:get_require_change_password_action()
    lu.assertEquals(origin, true)
    -- 恢复环境
    self.test_global_account_config:set_require_change_password_action(self.ctx, false)
end

--- 默认情况下密码用户名策略关闭，新建与设置密码与用户名前n字节相同，应该成功
function TestAccount:test_set_same_with_name_password_when_default_should_success()
    local default_user_name_password_compard_status =
        self.test_global_account_config:get_user_name_password_compared_enabled()
    lu.assertEquals(default_user_name_password_compard_status, false)
    local default_length = self.test_global_account_config:get_user_name_password_compared_length()
    lu.assertEquals(default_length, 4)
    local default_status = self.test_global_account_config:get_password_complexity_enable()
    lu.assertEquals(default_status, true)
    self:add_test_account(3)
    self.test_account_collection:set_user_name(self.ctx, 3, "test3_new")
    self.test_account_collection:set_account_password(self.ctx, 2, 3, "test333@132")

    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, 3)
end

--- 密码与用户名前n个字节比较策略正常时，新建与设置密码为非法密码应该失败
function TestAccount:test_set_invalid_password_when_username_pwd_compare_on_should_fail()
    local default_user_name_password_compard_status =
        self.test_global_account_config:get_user_name_password_compared_enabled()
    lu.assertEquals(default_user_name_password_compard_status, false)
    local default_length = self.test_global_account_config:get_user_name_password_compared_length()
    lu.assertEquals(default_length, 4)
    local default_status = self.test_global_account_config:get_password_complexity_enable()
    lu.assertEquals(default_status, true)
    self:add_test_account(3)
    self.test_global_account_config:set_user_name_password_compared_enabled(true)
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection:set_account_password(self.ctx, 2, 3, "test111@132")
    end)
    local account_info = {
        ['id'] = 4,
        ['name'] = "test4",
        ['password'] = "test111@132",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_collection:new_account(self.ctx, account_info, false)
    end)
    self.test_global_account_config:set_user_name_password_compared_enabled(default_user_name_password_compard_status)
    self.test_account_collection:set_account_password(self.ctx, 2, 3, "test111@132")

    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, 3)
end

--- 密码与用户名前n个字节比较策略正常时，用户名太短设置密码应该成功
function TestAccount:test_set_password_when_username_pwd_compare_on_and_username_too_short_should_succsee()
    local default_user_name_password_compard_status =
        self.test_global_account_config:get_user_name_password_compared_enabled()
    lu.assertEquals(default_user_name_password_compard_status, false)
    local default_length = self.test_global_account_config:get_user_name_password_compared_length()
    lu.assertEquals(default_length, 4)
    local default_status = self.test_global_account_config:get_password_complexity_enable()
    lu.assertEquals(default_status, true)
    self.test_global_account_config:set_user_name_password_compared_enabled(true)
    local account_info = {
        ['id'] = 3,
        ['name'] = "tes",
        ['password'] = "test111@132",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)

    -- 恢复环境
    self.test_global_account_config:set_user_name_password_compared_enabled(default_user_name_password_compard_status)
    self.test_account_collection:delete_account(self.ctx, 3)
end

--- 密码与用户名前n个字节比较策略正常时，设置SNMP加密密码为非法密码应该失败
function TestAccount:test_set_invalid_snmp_password_when_username_pwd_compare_on_should_fail()
    local default_user_name_password_compard_status =
        self.test_global_account_config:get_user_name_password_compared_enabled()
    lu.assertEquals(default_user_name_password_compard_status, false)
    local default_length = self.test_global_account_config:get_user_name_password_compared_length()
    lu.assertEquals(default_length, 4)
    local default_status = self.test_global_account_config:get_password_complexity_enable()
    lu.assertEquals(default_status, true)
    self.test_global_account_config:set_user_name_password_compared_enabled(true)
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9000",
        ['role_id'] = enum.RoleType.Operator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    lu.assertErrorMsgContains(custom_msg.PasswordComplexityCheckFailMessage.Name, function()
        self.test_account_service:set_user_snmp_pwd(self.ctx, 3, "test111@132")
    end)

    -- 恢复环境
    self.test_global_account_config:set_user_name_password_compared_enabled(default_user_name_password_compard_status)
    self.test_account_collection:delete_account(self.ctx, 3)
end

-- 设置初始密码提示开关，应成功
function TestAccount:test_when_set_initial_password_need_modify_should_set_success()
    local default_need = self.test_global_account_config:get_initial_password_prompt_enable()
    self.test_account_service:set_initial_password_prompt_enable(not default_need)
    lu.assertEquals(self.test_global_account_config:get_initial_password_prompt_enable(), not default_need)
    self.test_account_service:set_initial_password_prompt_enable(default_need)
    lu.assertEquals(self.test_global_account_config:get_initial_password_prompt_enable(), default_need)
end

--- 当创建新用户, PasswordChangeRequired应该为true
--- 管理员重置密码后应为true, 修改自己密码后变为false
function TestAccount:test_when_new_account_password_change_required_should_be_true()
    local account_id = 9
    self:add_test_account(account_id)

    local account = self.test_account_collection.collection[account_id]
    lu.assertEquals(account.m_account_data.PasswordChangeRequired, true)

    self.test_account_collection:set_account_password(self.ctx, 2, account_id, "Paswd@9002")
    lu.assertEquals(account.m_account_data.PasswordChangeRequired, true)

    self.test_account_collection:set_account_password(self.ctx, account_id, account_id, "Paswd@9004")
    lu.assertEquals(account.m_account_data.PasswordChangeRequired, false)
    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, account_id)
end

-- 不同初始密码策略下，新建用户权限不同
-- 强制 - 仅ConfigSelf
-- 提示 - 角色对应权限
function TestAccount:test_when_new_account_privilege_with_different_initial_policy()
    self.test_account_service:set_initial_account_privilege_restrict_enabled(true)
    local account_id = 11
    self:add_test_account(account_id)

    local account = self.test_account_collection.collection[account_id]
    lu.assertEquals(#account.current_privileges, 1)
    lu.assertEquals(account.current_privileges, {tostring(enum.PrivilegeType.ConfigureSelf)})

    self.test_account_service:set_initial_account_privilege_restrict_enabled(false)
    lu.assertEquals(#account.current_privileges, 6)

    self.test_account_service:set_initial_account_privilege_restrict_enabled(true)
    lu.assertEquals(#account.current_privileges, 1)
    lu.assertEquals(account.current_privileges, {tostring(enum.PrivilegeType.ConfigureSelf)})

    self.test_account_collection:set_first_login_policy(self.ctx, account_id,
        enum.FirstLoginPolicy.PromptPasswordReset:value())
    lu.assertEquals(#account.current_privileges, 6)

    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, account_id)
    self.test_account_service:set_initial_account_privilege_restrict_enabled(false)
end

-- 用户自己修改初始密码后，用户权限和角色权限一致
function TestAccount:test_when_change_password_should_update_privilege()
    self.test_account_service:set_initial_account_privilege_restrict_enabled(true)
    local account_id = 12
    self:add_test_account(account_id)

    local account = self.test_account_collection.collection[account_id]
    lu.assertEquals(#account.current_privileges, 1)
    lu.assertEquals(account.current_privileges, {tostring(enum.PrivilegeType.ConfigureSelf)})

    self.test_account_collection:set_account_password(self.ctx, 2,  account_id, "Paswd@9002")
    lu.assertEquals(#account.current_privileges, 1)
    lu.assertEquals(account.current_privileges, {tostring(enum.PrivilegeType.ConfigureSelf)})

    self.test_account_collection:set_account_password(self.ctx, account_id, account_id, "Paswd@9003")
    lu.assertEquals(#account.current_privileges, 6)

    -- 恢复环境
    self.test_account_collection:delete_account(self.ctx, account_id)
    self.test_account_service:set_initial_account_privilege_restrict_enabled(false)
end

--- 禁用首次登录总开关后应当同步禁用InitialPasswordPromptEnable和InitialAccountPrivilegeRestrictEnabled
function TestAccount:test_change_pwd_need_modify_shoule_change_pwd_prompt_and_priv_restrict()
    local modify_status = self.test_global_account_config:get_initial_password_need_modify()
    local prompt_status = self.test_global_account_config:get_initial_password_prompt_enable()
    local priv_restrict_status self.test_global_account_config:get_initial_account_privilege_restrict_enabled()
    -- 关闭总开关
    self.test_account_service:set_initial_password_need_modify(false)
    -- 其他开关应当关闭
    lu.assertIsFalse(self.test_global_account_config:get_initial_password_prompt_enable())
    lu.assertIsFalse(self.test_global_account_config:get_initial_account_privilege_restrict_enabled())
    -- 尝试开启其他开关应当失败
    lu.assertErrorMsgContains(custom_msg.SettingPropertyFailedMessage.Name, function()
        self.test_account_service:set_initial_password_prompt_enable(true)
    end)
    lu.assertErrorMsgContains(custom_msg.SettingPropertyFailedMessage.Name, function()
        self.test_account_service:set_initial_account_privilege_restrict_enabled(true)
    end)
    -- 恢复环境
    self.test_global_account_config:set_initial_password_need_modify(modify_status)
    self.test_global_account_config:set_initial_password_prompt_enable(prompt_status)
    self.test_global_account_config:set_initial_account_privilege_restrict_enabled(priv_restrict_status)
end

-- 测试删除trapv3用户后会自动更改trapv3用户
function TestAccount:test_change_snmp_v3_account_when_is_emergency_account_should_success()
    -- 前置条件准备，存在两个管理员用户2、3，其中2号为设置为逃生用户，3号为trapv3用户
    local account_info = {
        ['id'] = 3,
        ['name'] = "test3",
        ['password'] = "Paswd@9001",
        ['role_id'] = enum.RoleType.Administrator:value(),
        ['interface'] = make_interface(),
        ['first_login_policy'] = enum.FirstLoginPolicy.ForcePasswordReset,
        ['account_type'] = enum.AccountType.Local:value()
    }
    self.test_account_collection:new_account(self.ctx, account_info, false)
    local emergency_id = self.test_global_account_config:get_emergency_account()
    local trap_id = self.test_global_account_config:get_snmp_v3_trap_account_id()
    self.test_global_account_config:set_emergency_account(2)
    self.test_global_account_config:set_snmp_v3_trap_account(3)
    self.test_global_account_config:set_snmp_v3_trap_account_change_policy(self.ctx, 1)
    -- 删除trapv3用户
    self.test_account_collection:delete_account(self.ctx, 3)
    local account_id = self.test_global_account_config:get_snmp_v3_trap_account_id()
    lu.assertEquals(account_id, 2)
    -- 恢复环境
    self.test_global_account_config:set_snmp_v3_trap_account_change_policy(self.ctx, 0)
    self.test_global_account_config:set_snmp_v3_trap_account(trap_id)
    self.test_global_account_config:set_emergency_account(emergency_id)
end

-- 测试获取ipmi_channel_config时不存在用户通道配置
function TestAccount:test_get_ipmi_channel_config_when_user_config_not_exist()
    local ipmi_channel_config_info = self.test_account_collection.ipmi_channel_config:get(101, 1)
    lu.assertEquals(next(ipmi_channel_config_info), nil)
end
