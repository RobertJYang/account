-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.

loadfile(os.getenv('CONFIG_FILE'), 't', { package = package, os = os })()

-- 添加libliam依赖路径打桩
package.path = '../../../libiam/lualib/?.lua;' .. package.path

local utils = require 'utils.core'
local logging = require 'mc.logging'
local mc_utils = require 'mc.utils'
local current_file_dir = debug.getinfo(1).source:match('@?(.*)/')
utils.chdir(current_file_dir)
logging:setPrint(nil)
logging:setLevel(logging.INFO)

local lu = require('luaunit')

-- 增加mock的文件路径
local test_dir = mc_utils.realpath('.')
package.path = test_dir .. '/mock/?.lua;' .. package.path
package.path = test_dir .. '/?.lua;' .. package.path

local open_iam_db = require 'iam.db'
local iam_core = require 'iam_core'
local datas = require 'default_datas'
local file_utils = require 'utils.file'

local authentication = require 'service.authentication'
local certificate_authentication = require 'domain.certificate_authentication'
local SessionService = require 'service.session_service'

local ldap_config = require 'domain.ldap_config'
local remote_groups_config = require 'domain.remote_groups_config'
local ldap_controller_collection = require 'domain.ldap.ldap_controller_collection'

local remote_group_collection = require 'domain.remote_group.remote_group_collection'
local ldap_authentication = require 'service.ldap_authentication'
local kerberos_config = require 'domain.kerberos_config'
local config = require 'user_config'
local kmc = require 'mc.kmc'

local mc_context = require 'mc.context'
local KmcClient = require 'infrastructure.kmc_client'
local ipmi_running_record = require 'infrastructure.ipmi_running_record'
local session_ipmi = require 'interface.ipmi.session_ipmi'
local accoutn_service_ipmi = require 'interface.ipmi.account_service_ipmi'
local authentication_ipmi = require 'interface.ipmi.authentication_ipmi'
local test_common = require 'test_common.utils'
local vos_utils = require 'utils.vos'
local authentication_config = require 'domain.authentication_config'
local account_cache = require 'domain.cache.account_cache'
local login_time_rule_cache = require 'domain.cache.login_rule.login_time_rule_cache'
local access_service = require 'service.access_service'

TestIam = {}

local KmcEnc = kmc.encrypt_data
local KmcDec = kmc.decrypt_data

local function copy_file_real_path(file_from, file_to)
    local real_path_from = iam_core.format_realpath(file_from)
    local real_path_to = iam_core.format_realpath(file_to)
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
    config.TMP_PASSWD_FILE = test_data_dir .. '/tmp_passwd_UT'
    config.TMP_SHADOW_FILE = test_data_dir .. '/tmp_shadow_UT'
    config.TMP_GROUP_FILE = test_data_dir .. '/tmp_group_UT'
    config.TMP_IPMI_FILE = test_data_dir .. '/tmp_ipmi_UT'
    config.WEAK_PWDDICT_FILE_PATH = test_data_dir .. '/data_etc_weakpwddic_UT'
    config.WEAK_PWDDICT_FILE_PATH_INIT = test_data_dir .. '/data_etc_weakpwddic_UT_init'
    config.WEAK_PWDDICT_FILE_EXPORT_PATH = test_data_dir .. '/weakpwddic_export_file'
    config.PAM_FAILLOCK = test_data_dir .. '/pam_faillock'
    config.TEMP_PAM_FAILLOCK = test_data_dir .. '/tmp_pam_faillock'
    config.PAM_FAILLOCK_PRE = test_data_dir .. '/pam_faillock_pre'
    config.TEMP_PAM_FAILLOCK_PRE = test_data_dir .. '/tmp_pam_faillock_pre'
    config.SSH_PUBLIC_KEY_TEMP_FILE = test_data_dir .. '/ssh_rsa.pub'
    config.SSH_PUBLIC_KEY_HASH_TEMP_FILE = test_data_dir .. '/publickeyhash'
    config.SSH_PUBLIC_KEY_CONF_TEMP_FILE = test_data_dir .. '/publickeyconf'
    config.LOGINRULE_FILE = test_data_dir .. '/loginrules'
    config.SHM_PATH = test_data_dir .. '/dev/shm'
    config.SSH_PUBLIC_KEY_PARSE_PATH = test_data_dir .. config.SSH_PUBLIC_KEY_PARSE_PATH
    config.WEAK_PWDDICT_FILE_SHM_PATH = test_data_dir .. config.WEAK_PWDDICT_FILE_SHM_PATH
    config.SHM_TMP_PATH = test_data_dir .. config.SHM_TMP_PATH
    config.KRB_KEYTABLE_SHM_PATH = test_data_dir .. config.KRB_KEYTABLE_SHM_PATH
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

local function setup_init_class(db)
    kerberos_config.new(db)
end

function TestIam:setupClass()
    local test_data_dir, is_exist = iam_core.format_realpath("iam.test_temp_data")
    if is_exist == 1 then
        mc_utils.remove_file(test_data_dir)
    end
    redirect_path(test_data_dir)
    gen_linux_user_file(test_data_dir)
    gen_weakpwddic_file(test_data_dir)
    self.tally_dir = test_data_dir .. '/tally'
    os.execute('mkdir -p ' .. self.tally_dir)
    self.ip_lock_dir = test_data_dir .. '/ip_lock'
    os.execute('mkdir -p ' .. self.ip_lock_dir)
    self.IamDB = open_iam_db(test_data_dir .. '/iam.test.db', datas)
    KmcClient.new(nil, nil, true)
    self.test_account_cache = account_cache.new()
    self.authentication_config = authentication_config.new(self.IamDB)
    self.test_authentication = authentication.new(self.IamDB)
    self.certificate_authentication = certificate_authentication.new(self.IamDB)
    self.test_ldap_config = ldap_config.new(self.IamDB)
    self.test_remote_groups_config = remote_groups_config.new(self.IamDB)
    self.test_ldap_config = ldap_config.new(self.IamDB)
    self.test_ldap_controller_collection = ldap_controller_collection.new(self.IamDB)
    self.test_remote_group_collection = remote_group_collection.new(self.IamDB)
    self.test_ldap_authentication = ldap_authentication.new(nil, self.IamDB)
    self.test_access_service = access_service.new(self.test_authentication, self.certificate_authentication)
    self.test_session_service = SessionService.new(self.IamDB)
    self.ipmi_running_record = ipmi_running_record.new()
    self.test_session_ipmi = session_ipmi.new()
    self.test_account_service_ipmi = accoutn_service_ipmi.new()
    self.test_authentication_ipmi = authentication_ipmi.new()
    self.test_data_dir = test_data_dir
    self.login_time_rule_cache = login_time_rule_cache.new()
    self.ctx = mc_context.new('UT', 'Administrator', '127.0.0.1')
    self.ctx.operation_log = { operation = nil, result = nil, params = {} }
    config.ENABLE_UT = false
    self:PrepareFile(self.test_data_dir)
    self:mock()
    setup_init_class(self.IamDB)
    self.test_dir = test_dir
end

function TestIam:PrepareFile(test_data_dir)
    mc_utils.mkdir(test_data_dir .. '/tmp', mc_utils.S_IRWXU)
    mc_utils.mkdir_with_parents(config.DATA_HOME_PATH, mc_utils.S_IRWXU)
    mc_utils.mkdir_with_parents(config.DATA_HOME_PATH .. '/Administrator', mc_utils.S_IRWXU)

    self.import_false_data_path = iam_core.format_realpath("./test_data/config_mgmt/import_false_data.json")

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

function TestIam:mock()
    local group = {0, 255, 255, 255, 255}
    iam_core.mscm_ldap_authenticate = function(auth_info)
        return 0, 4, group
    end
end

function TestIam:teardownClass()
    mc_utils.remove_file(self.test_data_dir)
end

function TestIam:setUp()
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

function TestIam:tearDown()
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

require 'test_session'
require 'test_redfish_session'
require 'test_web_session'
require 'test_kvm_session'
require 'test_cli_session'
require 'test_inter_chassis_session'
require 'test_ldap_config'
require 'test_ldap_controller'
require 'test_remote_group'
require 'authentication.testcase_kerberos_keytab'
require 'authentication.testcase_ldap'
require 'test_iam_utils'
require 'test_session_ipmi'
require 'test_login_time_rule_cache'
require 'authentication.test_authentication_config'
require 'config_mgmt.test_config'
require 'test_profile_import'
require 'authentication.test_ip_lock'

lu.LuaUnit.run()
