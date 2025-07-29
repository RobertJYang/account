-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

loadfile(os.getenv('CONFIG_FILE'), 't', { package = package, os = os })()
-- 增加mock的文件路径
local mc_utils = require 'mc.utils'
local test_dir = mc_utils.realpath('.')
package.path = test_dir .. '/mock/?.lua;' .. test_dir .. '/test/unit/mock/?.lua;' .. package.path

local mc_context = require 'mc.context'
local kmc = require 'mc.kmc'
local logging = require 'mc.logging'
local utile_core = require 'utils.core'
local file_utils = require 'utils.file'
local vos_utils = require 'utils.vos'
local open_db = require 'account.db'
local datas = require 'default_datas'
local config = require 'common_config'
local kmc_client = require 'infrastructure.kmc_client'
local account_backup_db = require 'infrastructure.account_backup_db'
local ipmi_running_record = require 'infrastructure.ipmi_running_record'
local role_collection = require 'domain.role'
local login_rule_collection = require 'domain.login_rule.login_rule_collection'
local global_account_config = require 'domain.global_account_config'
local password_validator_collection = require 'domain.password_validator_collection'
local account_policy_collection = require 'domain.account_policy_collection'
local manager_account = require 'domain.manager_account.manager_account'
local ipmi_channel_config = require 'domain.ipmi_channel_config'
local account_collection = require 'domain.account_collection'
local account_permanent_backup = require 'domain.account_permanent_backup'
local file_synchronization = require 'domain.file_synchronization'
local account_service = require 'service.account_service'
local account_recover = require 'service.account_recover'
local local_authentication = require 'service.local_authentication'
local accoutn_service_ipmi = require 'interface.ipmi.account_service_ipmi'
local core = require 'account_core'
local lu = require('luaunit')
local test_common = require 'test_common.utils'

loadfile(os.getenv('CONFIG_FILE'), 't', { package = package, os = os })()

local current_file_dir = debug.getinfo(1).source:match('@?(.*)/')
utile_core.chdir(current_file_dir)
logging:setPrint(nil)
logging:setLevel(logging.INFO)

TestAccount = {}

local KmcEnc = kmc.encrypt_data
local KmcDec = kmc.decrypt_data

local function copy_file_real_path(file_from, file_to)
    local real_path_from = core.format_realpath(file_from)
    local real_path_to = core.format_realpath(file_to)
    return file_utils.copy_file_s(real_path_from, real_path_to)
end

-- mock所有的路径配置
local function redirect_path(test_data_dir)
    -- 目录相关
    config.TMP_PATH = test_data_dir .. '/tmp'
    config.PAM_TALLY_LOG_DIR = test_data_dir
    config.DATA_HOME_PATH = test_data_dir .. '/data/trust/home'
    config.DATA_PATH = test_data_dir .. '/data'
    config.CERT_INTER_DIR = test_data_dir .. '/cert'

    -- 文件相关
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
    config.WEAK_PWDDICT_FILE_PATH = test_data_dir .. '/data_etc_weakpwddic_UT'
    config.WEAK_PWDDICT_FILE_PATH_INIT = test_data_dir .. '/data_etc_weakpwddic_UT_init'
    config.WEAK_PWDDICT_FILE_EXPORT_PATH = test_data_dir .. '/weakpwddic_export_file'
    config.PAM_FAILLOCK = test_data_dir .. '/pam_faillock'
    config.SSH_PUBLIC_KEY_TEMP_FILE = test_data_dir .. '/ssh_rsa.pub'
    config.SSH_PUBLIC_KEY_HASH_TEMP_FILE = test_data_dir .. '/publickeyhash'
    config.SSH_PUBLIC_KEY_CONF_TEMP_FILE = test_data_dir .. '/publickeyconf'
    config.LOGINRULE_FILE = test_data_dir .. '/loginrules'
    config.SHM_PATH = test_data_dir .. '/dev/shm'
    config.SSH_PUBLIC_KEY_PARSE_PATH = test_data_dir .. config.SSH_PUBLIC_KEY_PARSE_PATH
    config.WEAK_PWDDICT_FILE_SHM_PATH = test_data_dir .. config.WEAK_PWDDICT_FILE_SHM_PATH
    config.SHM_TMP_PATH = test_data_dir .. config.SHM_TMP_PATH
end

local function gen_linux_user_file(test_data_dir)
    os.execute('mkdir -p ' .. test_data_dir)
    copy_file_real_path('./test_data/passwd', config.PASSWD_FILE)
    copy_file_real_path('./test_data/shadow', config.SHADOW_FILE)
    copy_file_real_path('./test_data/group', config.GROUP_FILE)
    copy_file_real_path('./test_data/ipmi', config.IPMI_FILE)
end

local function gen_weakpwddic_file(test_data_dir)
    copy_file_real_path('./test_data/weakdictionary', config.WEAK_PWDDICT_FILE_PATH)
    copy_file_real_path('./test_data/weakdictionary', config.WEAK_PWDDICT_FILE_PATH_INIT)
    os.execute('touch ' .. test_data_dir .. '/test_weakpwddic_file')
end

function TestAccount:setupClass()
    local test_data_dir, is_exist = core.format_realpath("account.test_temp_data")
    if is_exist == 1 then
        mc_utils.remove_file(test_data_dir)
    end
    redirect_path(test_data_dir)
    gen_linux_user_file(test_data_dir)
    gen_weakpwddic_file(test_data_dir)
    self:PrepareFile(test_data_dir)
    self.tally_dir = test_data_dir .. '/tally'
    os.execute('mkdir -p ' .. self.tally_dir)
    self.db = open_db(test_data_dir .. '/account.test.db', datas)
    self.test_kmc_client = kmc_client.new(nil, nil, true)
    self.test_global_account_config = global_account_config.new(self.db, nil)
    self.test_password_validator_collection = password_validator_collection.new(self.db,
        self.test_global_account_config)
    self.test_account_policy_collection = account_policy_collection.new(self.db, self.test_global_account_config)
    self.test_login_rule_collection = login_rule_collection.new(nil, self.db)
    self.test_role_collection = role_collection.new(self.db)
    self.test_ipmi_channel_config = ipmi_channel_config.new(self.db)
    self.test_account_collection = account_collection.new(nil, self.db, self.test_global_account_config,
        self.test_role_collection, nil, self.test_password_validator_collection,
        self.test_account_policy_collection, self.test_ipmi_channel_config, {})
    self.test_account_permanent_backup = account_permanent_backup.new(self.db, self.test_account_collection)
    self.test_file_synchronization = file_synchronization.new(self.db, self.test_account_collection, {})
    self.test_file_synchronization:regist_file_sync_signals()
    self.test_account_service = account_service.new(self.test_global_account_config, self.test_account_collection,
        self.test_file_synchronization, self.test_role_collection, self.test_account_policy_collection)
    self.ipmi_running_record = ipmi_running_record.new()
    self.test_account_backup_db = account_backup_db.new(self.db)
    self.test_account_recover = account_recover.new(self.db, self.test_account_backup_db, self.test_account_service)
    self.test_account_service_ipmi = accoutn_service_ipmi.new()
    self.test_authentication = local_authentication.new(self.test_account_collection, self.test_global_account_config)
    self.test_data_dir = test_data_dir
    self.ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    self.ctx.operation_log = { operation = nil, result = nil, params = {} }
    config.ENABLE_UT = false
    local account_data = self.db:select(self.db.ManagerAccountDB):where(self.db.ManagerAccountDB.Id:eq(2))
        :first()
    self.test_account = manager_account.new(self.db, account_data)
    local snmp_data = self.db:select(self.db.SNMPUserInfo):where(self.db.SNMPUserInfo.AccountId:eq(2))
        :first()
    self.test_account:init_snmp_user_info(snmp_data)
    for key, _ in pairs(self.test_account_collection.collection) do
        self.test_account_collection:set_password_change_required(key, false)
    end
    self:mock()
end

function TestAccount:PrepareFile(test_data_dir)
    mc_utils.mkdir(test_data_dir .. '/tmp', mc_utils.S_IRWXU)
    mc_utils.mkdir_with_parents(config.DATA_HOME_PATH, mc_utils.S_IRWXU)
    mc_utils.mkdir_with_parents(config.DATA_HOME_PATH .. '/Administrator', mc_utils.S_IRWXU)

    self.openssh_public_key_path = test_data_dir .. '/tmp/openssh_key.pub'
    copy_file_real_path('./test_data/openssh_key.pub', self.openssh_public_key_path)
    mc_utils.chmod(self.openssh_public_key_path, mc_utils.S_IRUSR | mc_utils.S_IWUSR)

    self.ssh2_public_key_path = test_data_dir .. '/tmp/ssh2_key.pub'
    copy_file_real_path('./test_data/ssh2_key.pub', self.ssh2_public_key_path)
    mc_utils.chmod(self.ssh2_public_key_path, mc_utils.S_IRUSR | mc_utils.S_IWUSR)

    self.weakpwddic_file = test_data_dir .. '/tmp/test_weakpwddic_file'
    copy_file_real_path('./test_data/weakdictionary', self.weakpwddic_file)

    self.illegal_weakpwddic_file = test_data_dir .. '/test_weakpwddic_file'
    copy_file_real_path('./test_data/weakdictionary', self.illegal_weakpwddic_file)

    mc_utils.mkdir(test_data_dir .. '/dev/', mc_utils.S_IRWXU)
    mc_utils.mkdir(test_data_dir .. '/dev/shm', mc_utils.S_IRWXU)
    mc_utils.mkdir(test_data_dir .. '/dev/shm/tmp', mc_utils.S_IRWXU)
end

function TestAccount:mock()
    -- mock account_collection的_delete_cert函数
    self.test_account_collection._delete_cert = function(self, ctx, cert_id)
        return nil
    end
end

function TestAccount:teardownClass()
    mc_utils.remove_file(self.test_data_dir)
end

function TestAccount:setUp()
    -- mock kmc
    kmc.encrypt_data = function(domain_id, cipher_alg_id, hmac_alg_id, plaintext)
        return plaintext
    end
    kmc.decrypt_data = function(domain_id, ciphertext)
        return ciphertext
    end

    -- mock get_random_array
    vos_utils.get_random_array = test_common.get_random_array
end

function TestAccount:tearDown()
    kmc.encrypt_data = KmcEnc
    kmc.decrypt_data = KmcDec
end

-- mock app_preloader里面的excute_s函数
os.execute_s = function(cmd)
    local ret = vos_utils.check_before_system_s('/bin/sh', '-c', cmd)
    if ret ~= 0 then
        return false, 'exit', ret
    end
    return true, 'exit', ret
end

require 'test_account'
require 'test_profile'
require 'test_linux_account'
require 'test_manager_account'
require 'test_vnc_account'
require 'test_account_service'
require 'test_role'
require 'test_privilege'
require 'login_rule.test_login_ip_rule'
require 'login_rule.test_login_mac_rule'
require 'login_rule.test_login_time_rule'
require 'test_global_account_config'
require 'local_account.test_account'
require 'local_account.test_history_password'
require 'local_account.test_snmp_community'
require 'local_account.test_ssh_public_key'
require 'test_authentication'
require 'test_account_service_ipmi'
require 'test_utils'
require 'test_account_recover'
require 'test_account_permanent_backup'
require 'test_password_validator'
require 'test_account_policy'
require 'test_ipmi_channel_mappings'
-- OEM测试文件，裁剪时请注意
require 'test_oem_account'

os.exit(lu.LuaUnit.run())
