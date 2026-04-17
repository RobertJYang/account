-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Test passwords: [$6$7iS4$HmAb]
local lu = require 'luaunit'
local utils_core = require 'utils.core'
local enum = require 'class.types.types'
local LinuxAccount = require 'infrastructure.account_linux'
local config = require 'common_config'
local mc_utils = require 'mc.utils'
local file_utils = require 'utils.file'
local logging = require 'mc.logging'
local core = require 'account_core'

TestLinuxUser = {}

local function copy_file_real_path(file_from, file_to)
    local real_path_from = core.format_realpath(file_from)
    local real_path_to = core.format_realpath(file_to)
    return file_utils.copy_file_s(real_path_from, real_path_to)
end

local function read_lines(path)
    local lines = {}
    for line in io.lines(path) do
        lines[#lines + 1] = line
    end
    return lines
end

local function gen_linux_user_file(test_data_dir)
    -- config mock
    os.execute('mkdir -p ' .. test_data_dir)
    
    config.PASSWD_FILE = test_data_dir .. '/passwd_UT'
    config.SHADOW_FILE = test_data_dir .. '/shadow_UT'
    config.GROUP_FILE = test_data_dir .. '/group_UT'
    config.IPMI_FILE = test_data_dir .. '/ipmi_UT'
    config.LINUX_FILES = {
        passwd_path = config.PASSWD_FILE,
        shadow_path = config.SHADOW_FILE,
        group_path = config.GROUP_FILE,
        ipmi_path = config.IPMI_FILE
    }
    config.TMP_PASSWD_FILE = test_data_dir .. '/tmp_passwd_UT'
    config.TMP_SHADOW_FILE = test_data_dir .. '/tmp_shadow_UT'
    config.TMP_GROUP_FILE = test_data_dir .. '/tmp_group_UT'
    config.TMP_IPMI_FILE = test_data_dir .. '/tmp_ipmi_UT'
    copy_file_real_path('./test_data/passwd', config.PASSWD_FILE)
    copy_file_real_path('./test_data/shadow', config.SHADOW_FILE)
    copy_file_real_path('./test_data/group', config.GROUP_FILE)
    copy_file_real_path('./test_data/ipmi', config.IPMI_FILE)
    mc_utils.mkdir_with_parents(test_data_dir .. '/data/trust/home', mc_utils.S_IRWXU)
end

function TestLinuxUser:setupClass()
    local test_data_dir, is_exist = core.format_realpath('account.test_temp_data')
    if is_exist == 1 then
        mc_utils.remove_file(test_data_dir)
    end
    
    gen_linux_user_file(test_data_dir)
    
    os.execute('touch ' .. test_data_dir .. '/empty_group')
    os.execute('touch ' .. test_data_dir .. '/empty_password')
    self.empty_group_file = test_data_dir .. '/empty_group'
    self.empty_passwd_file = test_data_dir .. '/empty_password'
    self.group_without_root_file = test_data_dir .. '/group_no_root'
    
    copy_file_real_path('./test_data/group_no_root', self.group_without_root_file)
    self.log_buf = {}
    logging:setLevel(logging.DEBUG)
    logging:setPrint(function(limit, level, msg)
        self.log_buf[#self.log_buf + 1] = { level = level, message = msg }
    end)
end

function TestLinuxUser:teardownClass()
    local test_data_dir = core.format_realpath('account.test_temp_data')
    mc_utils.remove_file(test_data_dir)
end

function TestLinuxUser:last_log()
    return self.log_buf[#self.log_buf]
end

function TestLinuxUser:clear_log()
    self.log_buf = {}
end

-- 测试增加用户
function TestLinuxUser:test_linux_add_account()
    local role = enum.RoleType.CustomRole3:value()
    local _, groupname = LinuxAccount.role_group_map[role][1], LinuxAccount.role_group_map[role][2]

    local la = LinuxAccount.new(config.LINUX_FILES, true)
    local account = {
        user_name = 'test_linux',
        password = '$6$7iS4$HmAb',
        id = 10,
        role = role,
        is_local_user = 1,
        is_change_user = false
    }
    la:add_user(account)
    local uid = la.passwd_file:get('test_linux').user_id
    local password = la.shadow_file:get('test_linux').password
    local has_user = la.group_file:has_user('test_linux', groupname)
    local id = la.ipmi_file:get('test_linux').user_id
    lu.assertEquals(uid, config.LINUX_USER_ID_BASE + 10)
    lu.assertEquals(password, '$6$7iS4$HmAb')
    lu.assertIsTrue(has_user)
    lu.assertEquals(id, 10)

    la:remove_user('test_linux', role, false)
    lu.assertIsNil(la.passwd_file:get('test_linux'))
    lu.assertIsNil(la.shadow_file:get('test_linux'))
    lu.assertIsFalse(la.group_file:has_user('test_linux', groupname))
    lu.assertIsNil(la.ipmi_file:get('test_linux'))
end

function TestLinuxUser:test_get_all_user_info()
    local la = LinuxAccount.new(config.LINUX_FILES, true)
    local test_user = la.shadow_file:get('test')
    lu.assertNotIsNil(test_user)
    lu.assertEquals(test_user.password,
        [[$6$LECLnZDJT2SnYEVV$RMGHpZPMlJP8/2o/qq3frraPe4oCG.3IW1NdJVXUaDBMzQXzlh6vywXtWQ7FbM/boPVSxtpulptWZ7y5n8FwK.]])
end

function TestLinuxUser:test_add_user_group()
    local la = LinuxAccount.new(config.LINUX_FILES, true)

    la.group_file:add_user('test_root', 1, 'test_root')
    lu.assertEquals(self:last_log().level, logging.DEBUG)
    lu.assertStrContains(self:last_log().message, 'linux user exist')

    la.group_file:add_user('test1', 1001, 'test1')
    lu.assertEquals(self:last_log().level, logging.DEBUG)
    lu.assertStrContains(self:last_log().message, 'linux user exist')

    la.group_file:add_user('root', 1, 'test_root')
    la.group_file:add_user('test2', 1002, 'test2')

    la.group_file:create_group(config.APPS_GROUP_NAME, config.APPS_USER_GID)
    la.group_file:add_user('test3', config.APPS_USER_GID, config.APPS_GROUP_NAME)
    la.group_file:save(true)

    local la1 = LinuxAccount.new(config.LINUX_FILES, true)
    local goup1 = la1.group_file:find_by_id(1)
    lu.assertEquals(goup1.group_name, 'test_root')
    lu.assertEquals(goup1.users, { 'test_root', 'root' })

    local goup2 = la1.group_file:find_by_id(1001)
    lu.assertEquals(goup2.group_name, 'test1')
    lu.assertEquals(goup2.users, { 'test1' })

    local goup3 = la1.group_file:find_by_id(1002)
    lu.assertEquals(goup3.group_name, 'test2')
    lu.assertEquals(goup3.users, { 'test2' })

    lu.assertEquals(read_lines(config.GROUP_FILE), {
        "root:x:0:root",
        "sshd:x:74:",
        "operator:x:200:redfish_user,Administrator,kvm_user",
        "user:x:201:redfish_user,Administrator,kvm_user",
        "no_access:x:202:redfish_user,Administrator,kvm_user",
        "apache:x:98:apache",
        "snmpd_user:x:95:snmpd_user",
        "ipmi_user:x:96:ipmi_user",
        "kvm_user:x:97:kvm_user",
        "discovery_user:x:100:discovery_user",
        "comm_user:x:101:comm_user",
        "redfish_user:x:102:redfish_user",
        "secbox:x:104:secbox",
        "admin:x:204:Administrator",
        "apps:x:103:ipmi_user,snmpd_user,kvm_user,apache,discovery_user,comm_user,redfish_user,secbox,test3",
        "test_root:x:1:test_root,root",
        "test1:x:1001:test1",
        "test_linux:x:200:test_linux",
        "test2:x:1002:test2"
    })
end

function TestLinuxUser:test_add_user_group_conflict()
    local la1 = LinuxAccount.new(config.LINUX_FILES, true)
    local la2 = LinuxAccount.new(config.LINUX_FILES, true)
    la1.group_file:add_user('test4', config.APPS_USER_GID, config.APPS_GROUP_NAME)
    la2.group_file:add_user('test4', config.APPS_USER_GID, config.APPS_GROUP_NAME)

    la2.group_file:save()
    lu.assertErrorMsgContains('InternalError', function()
        la1.group_file:save()
    end)
end

-- 测试手动修改密码后，文件同步的场景
function TestLinuxUser:test_modify_shadow_passwd()
    local account = {
        user_name = 'test4',
        password = '$6$12345$67890',
        id = 10,
        role = enum.RoleType.CustomRole3:value(),
        is_local_user = 1,
        is_change_user = false
    }
    local la1 = LinuxAccount.new(config.LINUX_FILES, true)
    la1:add_user(account)

    local shadow_file = file_utils.open_s(config.SHADOW_FILE, 'r+')
    local shadow_str = shadow_file:read('a')
    local test4_str = shadow_str:match('test4:[%w$]+::0:99999::::')
    lu.assertEquals(test4_str, 'test4:$6$12345$67890::0:99999::::')
    shadow_str = shadow_str:gsub('test4:[%w$]+::0:99999::::', 'test4:$6$11111$22222::0:99999::::')
    shadow_file:seek('set', 0)
    shadow_file:write(shadow_str)
    shadow_file:close()

    local la2 = LinuxAccount.new(config.LINUX_FILES, true)
    lu.assertEquals(la2.shadow_file.datas['test4'].password, '$6$11111$22222')
    la2:update_user(account)

    shadow_file = file_utils.open_s(config.SHADOW_FILE, 'r+')
    shadow_str = shadow_file:read('a')
    shadow_str = shadow_str:match('test4:[%w$]+::0:99999::::')
    shadow_file:close()
    lu.assertEquals(shadow_str, 'test4:$6$12345$67890::0:99999::::')
end

-- 测试获取基础组名
function TestLinuxUser:test_get_base_group_name()
    local la = LinuxAccount.new(config.LINUX_FILES, true)
    lu.assertEquals(la.group_file:get_base_group_name(config.OPERATOR_GID), 'operator')
    lu.assertEquals(la.group_file:get_base_group_name(config.USER_GID), 'user')
    lu.assertEquals(la.group_file:get_base_group_name(config.NO_ACCESS_USER_GID), 'no_access')
    lu.assertEquals(la.group_file:get_base_group_name(config.ADMINISTRATOR_GID), 'admin')
    lu.assertEquals(la.group_file:get_base_group_name(config.OEM_GID), nil)
end

-- 测试检查id是否在基础组里面,operator,admin,user，no_access
function TestLinuxUser:test_check_id_in_base_group()
    local la = LinuxAccount.new(config.LINUX_FILES, true)
    lu.assertIsTrue(la.group_file:check_id_in_base_group(config.OPERATOR_GID))
    lu.assertIsTrue(la.group_file:check_id_in_base_group(config.USER_GID))
    lu.assertIsTrue(la.group_file:check_id_in_base_group(config.NO_ACCESS_USER_GID))
    lu.assertIsTrue(la.group_file:check_id_in_base_group(config.ADMINISTRATOR_GID))
    lu.assertIsFalse(la.group_file:check_id_in_base_group(config.OEM_GID))
end

-- 增加用户组测试
function TestLinuxUser:test_group_add_user()
    local linux_files = {
        passwd_path = config.PASSWD_FILE,
        shadow_path = config.SHADOW_FILE,
        group_path = self.empty_group_file,
        ipmi_path = config.IPMI_FILE
    }
    local la = LinuxAccount.new(linux_files, true)
    la:add_user_group("test1", enum.RoleType.Operator:value())
    local file = file_utils.open_s(self.empty_group_file, 'r')
    lu.assertNotIsNil(file)
    local content = mc_utils.close(file, pcall(file.read, file, "*a"))
    local value = mc_utils.split(content,":")
    lu.assertEquals("operator", value[1])
end

-- 当用户根目录已经存在，应该不再进行创建动作
function TestLinuxUser:test_when_account_root_is_exist_should_not_create_root_folder()
    local new_linux_account =
        LinuxAccount.new(config.LINUX_FILES, true)
    local account = {
        user_name = 'test_linux',
        password = '$6$7iS4$HmAb',
        id = 10,
        role = enum.RoleType.CustomRole3:value(),
        is_local_user = 1,
        is_change_user = false
    }
    new_linux_account:add_user(account)
    lu.assertEquals(file_utils.check_real_path_s(table.concat({ config.DATA_HOME_PATH, 'test_linux' }, '/')), 0)
    new_linux_account.home_dir:create('test_linux', 0, 0)
    lu.assertEquals(file_utils.check_real_path_s(table.concat({ config.DATA_HOME_PATH, 'test_linux' }, '/')), 0)
    -- 删除用户
    new_linux_account:remove_user('test_linux', enum.RoleType.CustomRole3:value(), false)
    lu.assertEquals(file_utils.check_real_path_s(table.concat({ config.DATA_HOME_PATH, 'test_linux' }, '/')), -1)
end

-- 修改用户角色，用户根目录属组同步变更
function TestLinuxUser:test_when_account_role_changed_should_change_root_folder_group()
    local la = LinuxAccount.new(config.LINUX_FILES, true)
    local account = {
        user_name = 'test_linux',
        password = '$6$7iS4$HmAb',
        id = 10,
        role = enum.RoleType.Administrator:value(),
        is_local_user = 1,
        is_change_user = false
    }
    la:add_user(account)

    lu.assertEquals(file_utils.check_real_path_s(la.home_dir:get('test_linux')), 0)
    local file_gid = utils_core.stat(la.home_dir:get('test_linux')).st_gid
    lu.assertEquals(file_gid, 204) -- 204为系统中预置Administrator组id

    account.role =  enum.RoleType.Operator:value()
    account.is_change_user = true
    account.old_username = 'test_linux'
    la:update_user(account)

    file_gid = utils_core.stat(la.home_dir:get('test_linux')).st_gid
    lu.assertEquals(file_gid, 200) -- 200为系统中预置Operator组id

    -- 删除用户
    la:remove_user('test_linux', enum.RoleType.Operator:value(), false)
end

-- 修改用户名，用户根目录更名
function TestLinuxUser:test_when_account_name_changed_should_rename_root_folder()
    local la = LinuxAccount.new(config.LINUX_FILES, true)
    local account = {
        user_name = 'test_linux',
        password = '$6$7iS4$HmAb',
        id = 10,
        role = enum.RoleType.CustomRole3:value(),
        is_local_user = 1,
        is_change_user = false
    }
    la:add_user(account)

    lu.assertEquals(file_utils.check_real_path_s(la.home_dir:get('test_linux')), 0)

    account.user_name = 'test_linux_new'
    account.is_change_user = true
    account.old_username = 'test_linux'
    la:update_user(account)

    lu.assertEquals(file_utils.check_real_path_s(la.home_dir:get('test_linux')), -1)
    lu.assertEquals(file_utils.check_real_path_s(la.home_dir:get('test_linux_new')), 0)

    -- 删除用户
    la:remove_user('test_linux_new', enum.RoleType.CustomRole3:value(), false)
end

-- 测试添加系统基础用户组，空组文件
function TestLinuxUser:test_ensure_system_base_user_exists_success1()
    os.execute("rm " .. self.empty_group_file)
    os.execute("touch " .. self.empty_group_file)
    os.execute("rm " .. config.PASSWD_FILE)
    copy_file_real_path('./test_data/passwd', config.PASSWD_FILE)
    local linux_files = {
        passwd_path = config.PASSWD_FILE,
        shadow_path = config.SHADOW_FILE,
        group_path = self.empty_group_file,
        ipmi_path = config.IPMI_FILE
    }
    local la = LinuxAccount.new(linux_files, true)
    la:ensure_system_base_user_exists()
    la:save(true)
    local file = file_utils.open_s(self.empty_group_file, 'r')
    lu.assertNotIsNil(file)
    local content_ori = mc_utils.close(file, pcall(file.read, file, "*a"))
    local content = mc_utils.split(content_ori, '\n')
    table.sort(content)

    local ret = {
        '<tsb_user>:x:105:<tsb_user>',
        'admin:x:204:',
        'apache:x:98:apache',
        'apps:x:103:apache,snmpd_user,ipmi_user,kvm_user,discovery_user,comm_user,redfish_user,secbox,<tsb_user>',
        'comm_user:x:101:comm_user',
        'discovery_user:x:100:discovery_user',
        'ipmi_user:x:96:ipmi_user',
        'kvm_user:x:97:kvm_user',
        'no_access:x:202:kvm_user,redfish_user',
        'operator:x:200:kvm_user,redfish_user',
        'redfish_user:x:102:redfish_user',
        'root:x:0:root',
        'secbox:x:104:secbox',
        'snmpd_user:x:95:snmpd_user',
        'sshd:x:74:sshd',
        'tpcm_device:x:106:ipmi_user,<tsb_user>',
        'user:x:201:kvm_user,redfish_user'
    }
    lu.assertEquals(content, ret)
    -- 环境恢复
    os.execute("rm " .. self.empty_group_file)
    os.execute("touch " .. self.empty_group_file)
    os.execute("rm " .. config.PASSWD_FILE)
    copy_file_real_path('./test_data/passwd', config.PASSWD_FILE)
end

function TestLinuxUser:test_ensure_system_base_user_exists_success2()
    os.execute("rm " .. self.empty_passwd_file)
    os.execute("rm " .. config.GROUP_FILE)
    os.execute("touch " .. self.empty_passwd_file)
    copy_file_real_path('./test_data/group', config.GROUP_FILE)
    local linux_files = { passwd_path = self.empty_passwd_file, shadow_path = config.SHADOW_FILE,
        group_path = config.GROUP_FILE, ipmi_path = config.IPMI_FILE }
    local la = LinuxAccount.new(linux_files, true)
    la:ensure_system_base_user_exists()
    la:save(true)
    local file = file_utils.open_s(self.empty_passwd_file, 'r')
    lu.assertNotIsNil(file)
    local content = mc_utils.close(file, pcall(file.read, file, "*a"))
    local ret = [[root:x:0:0:root:/:/sbin/nologin
sshd:x:74:74:Privilege-separated SSH:/var/run/sshd:/sbin/nologin
apache:x:98:98:apache:/:/sbin/nologin
snmpd_user:x:95:95:snmpd_user:/:/sbin/nologin
ipmi_user:x:96:96:ipmi_user:/:/sbin/nologin
kvm_user:x:97:97:kvm_user:/:/sbin/nologin
discovery_user:x:100:100:discovery_user:/:/sbin/nologin
comm_user:x:101:101:comm_user:/:/sbin/nologin
redfish_user:x:102:102:redfish_user:/:/sbin/nologin
secbox:x:104:104:secbox:/:/sbin/nologin
<tsb_user>:x:105:105:<tsb_user>:/:/sbin/nologin]]
    lu.assertEquals(ret, content)

    local file2 = file_utils.open_s(config.GROUP_FILE, 'r')
    lu.assertNotIsNil(file2)
    local content1 = mc_utils.close(file2, pcall(file2.read, file2, "*a"))

    local ret2 = [[root:x:0:root
sshd:x:74:sshd
operator:x:200:redfish_user,Administrator,kvm_user
user:x:201:redfish_user,Administrator,kvm_user
no_access:x:202:redfish_user,Administrator,kvm_user
apache:x:98:apache
snmpd_user:x:95:snmpd_user
ipmi_user:x:96:ipmi_user
kvm_user:x:97:kvm_user
discovery_user:x:100:discovery_user
comm_user:x:101:comm_user
redfish_user:x:102:redfish_user
secbox:x:104:secbox
admin:x:204:Administrator
apps:x:103:ipmi_user,snmpd_user,kvm_user,apache,discovery_user,comm_user,redfish_user,secbox,<tsb_user>
test_root:x:1:test_root
test1:x:1001:test1
test_linux:x:200:test_linux
tpcm_device:x:106:ipmi_user,<tsb_user>
<tsb_user>:x:105:<tsb_user>]]
    lu.assertEquals(ret2, content1)
    -- 环境恢复
    os.execute("rm " .. self.empty_passwd_file)
    os.execute("touch " .. self.empty_passwd_file)
    os.execute("rm " .. config.GROUP_FILE)
    copy_file_real_path('./test_data/group', config.GROUP_FILE)
end

function TestLinuxUser:test_ensure_system_base_user_exists_success3()
    os.execute("rm " .. config.GROUP_FILE)
    os.execute("rm " .. config.PASSWD_FILE)
    os.execute("rm " .. config.IPMI_FILE)
    copy_file_real_path('./test_data/group', config.GROUP_FILE)
    copy_file_real_path('./test_data/passwd', config.PASSWD_FILE)
    copy_file_real_path('./test_data/ipmi', config.IPMI_FILE)
    local la = LinuxAccount.new(config.LINUX_FILES, true)
    la:ensure_system_base_user_exists()
    la:save(true)
    local file = file_utils.open_s(config.PASSWD_FILE, 'r')
    lu.assertNotIsNil(file)
    local content = mc_utils.close(file, pcall(file.read, file, "*a"))

    local ret = [[root:x:0:0:root:/:/sbin/nologin
sshd:x:74:74:Privilege-separated SSH:/var/run/sshd:/sbin/nologin
Administrator:x:502:204:Administrator:/home/Administrator:/usr/bin/clp_commands
apache:x:98:98:apache:/:/sbin/nologin
snmpd_user:x:95:95:snmpd_user:/:/sbin/nologin
ipmi_user:x:96:96:ipmi_user:/:/sbin/nologin
kvm_user:x:97:97:kvm_user:/:/sbin/nologin
discovery_user:x:100:100:discovery_user:/:/sbin/nologin
comm_user:x:101:101:comm_user:/:/sbin/nologin
redfish_user:x:102:102:redfish_user:/:/sbin/nologin
secbox:x:104:104:secbox:/:/sbin/nologin
test_root:x:1:1:test_root:/test_root:/usr/bin/clp_commands
test:x:1000:1000:,,,:/home/test:/usr/bin/zsh
test_linux:x:610:200:operator:/:/sbin/nologin
<tsb_user>:x:105:105:<tsb_user>:/:/sbin/nologin]]
    lu.assertEquals(ret, content)

    local file = file_utils.open_s(config.IPMI_FILE, 'r')
    lu.assertNotIsNil(file)
    local content = mc_utils.close(file, pcall(file.read, file, "*a"))


    local ret = [[2:Administrator:0:1:5:0:1:1:1:0:0:4:0:0:0:0:0:0]]
    lu.assertEquals(ret, content)
    -- 环境恢复
    os.execute("rm " .. config.GROUP_FILE)
    os.execute("rm " .. config.PASSWD_FILE)
    copy_file_real_path('./test_data/group', config.GROUP_FILE)
    copy_file_real_path('./test_data/passwd', config.PASSWD_FILE)
end

-- 测试添加系统基础用户组,缺失组文件条目测试，是否补全
function TestLinuxUser:test_ensure_system_base_user_exists_success4()
    os.execute("rm " .. config.PASSWD_FILE)
    copy_file_real_path('./test_data/passwd', config.PASSWD_FILE)
    local linux_files = {
        passwd_path = config.PASSWD_FILE,
        shadow_path = config.SHADOW_FILE,
        group_path = self.group_without_root_file,
        ipmi_path = config.IPMI_FILE
    }
    local la =
        LinuxAccount.new(linux_files, true)
    la:ensure_system_base_user_exists()
    la:save(true)
    local file = file_utils.open_s(self.group_without_root_file, 'r')
    lu.assertNotIsNil(file)
    local content = mc_utils.close(file, pcall(file.read, file, "*a"))

    local ret = [[sshd:x:74:sshd
operator:x:200:redfish_user,Administrator,kvm_user
user:x:201:redfish_user,Administrator,kvm_user
no_access:x:202:redfish_user,Administrator,kvm_user
apache:x:98:apache
snmpd_user:x:95:snmpd_user
ipmi_user:x:96:ipmi_user
kvm_user:x:97:kvm_user
discovery_user:x:100:discovery_user
comm_user:x:101:comm_user
redfish_user:x:102:redfish_user
secbox:x:104:secbox
admin:x:204:Administrator
apps:x:103:ipmi_user,snmpd_user,kvm_user,apache,discovery_user,comm_user,redfish_user,secbox,<tsb_user>
test_root:x:1:test_root
test1:x:1001:test1
test_linux:x:200:test_linux
root:x:0:root
tpcm_device:x:106:ipmi_user,<tsb_user>
<tsb_user>:x:105:<tsb_user>]]
    lu.assertEquals(ret, content)
    -- 环境恢复
    os.execute("rm " .. config.PASSWD_FILE)
    copy_file_real_path('./test_data/passwd', config.PASSWD_FILE)
end
return TestLinuxUser
