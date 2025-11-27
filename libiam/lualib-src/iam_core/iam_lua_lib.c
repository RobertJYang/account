/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 *
 * this file licensed under the Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 * http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
 * PURPOSE.
 * See the Mulan PSL v2 for more details.
 *
 * Author: liwenjie
 * Create: 2022-10-31
 * Description: password tool
 */

#define LUA_LIB
#include <lauxlib.h>
#include <lua.h>
#include <securec.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <pwd.h>
#include "../comm_utils.h"
#include "../password.h"
#include "../pam_tally_ext.h"
#include "utmp.h"
#include "signal.h"
#include "../network.h"
#include "ldap_auth_parse_info.h"
#include "uip/uip_user.h"
#include "common/common.h"

#define MAX_CLI_USER_CNT 20  // 最大支持20个cli用户获取

static int l_get_pam_tally(lua_State *L)
{
    const gchar *username    = luaL_checkstring(L, 1);            // param 1
    const gchar *tally_dir   = luaL_checkstring(L, 2);            // param 2
    guint64      unlock_time = (guint64)luaL_checkinteger(L, 3);  // param 3
    TallyLog     tally       = {0};
    gint32       ret         = get_pam_tally(username, tally_dir, unlock_time, &tally);
    if (ret != RET_OK) {
        return luaL_error(L, "get_pam_tally failed! ret code: %d!", ret);
    }
    lua_pushinteger(L, tally.fail_time);
    lua_pushinteger(L, tally.fail_cnt);
    return 2;  // 2 output param
}

static int l_get_pam_tally_with_fail_interval(lua_State *L)
{
    const gchar *username      = luaL_checkstring(L, 1);            // param 1
    const gchar *tally_dir     = luaL_checkstring(L, 2);            // param 2
    guint64      unlock_time   = (guint64)luaL_checkinteger(L, 3);  // param 3
    gint64      fail_interval  = (gint64)luaL_checkinteger(L, 4);  // param 4
    TallyLog     tally         = {0};
    gint32       ret           = get_pam_tally_with_fail_interval(username, tally_dir, unlock_time, fail_interval,
        &tally);
    if (ret != RET_OK) {
        return luaL_error(L, "get_pam_tally failed! ret code: %d!", ret);
    }
    lua_pushinteger(L, tally.fail_time);
    lua_pushinteger(L, tally.fail_cnt);
    return 2;  // 2 output param
}

static int l_reset_pam_tally(lua_State *L)
{
    const gchar *username  = luaL_checkstring(L, 1);  // param 1
    const gchar *tally_dir = luaL_checkstring(L, 2);  // param 2
    gint32       ret       = reset_pam_tally(username, tally_dir);
    if (ret != RET_OK) {
        return luaL_error(L, "reset_pam_tally failed! ret code: %d!", ret);
    }
    return 0;  // 0 output param
}

static int l_increment_pam_tally(lua_State *L)
{
    const gchar *username  = luaL_checkstring(L, 1);  // param 1
    const gchar *tally_dir = luaL_checkstring(L, 2);  // param 2
    gint32       ret       = increment_pam_tally(username, tally_dir);
    if (ret != RET_OK) {
        return luaL_error(L, "increment_pam_tally failed! ret code: %d!", ret);
    }
    return 0;  // 0 output param
}

static int l_is_pass_complexity_check_pass(lua_State *L)
{
    const gchar *name           = luaL_checkstring(L, 1);
    const gchar *pwd            = luaL_checkstring(L, 2);
    guint32      min_pwd_length = (guint32)luaL_checkinteger(L, 3);
    gboolean     ret            = is_pass_complexity_check_pass(name, pwd, min_pwd_length);
    lua_pushboolean(L, ret);
    return 1;
}

static int l_is_vnc_password_complexity_check_pass(lua_State *L)
{
    const gchar *pwd = luaL_checkstring(L, 1);
    gboolean     ret = is_vnc_password_complexity_check_pass(pwd);
    lua_pushboolean(L, ret);

    memset_s((gchar *)pwd, strlen(pwd), 0, strlen(pwd));

    return 1;
}

LOCAL gboolean is_process_alive(gint32 pid)
{
    gchar path[32] = {0};

    if (pid <= 0) {
        return FALSE;
    }

    struct stat fileinfo;

    (void)snprintf_s(path, sizeof(path), sizeof(path) - 1, "/proc/%d", pid);

    if (stat_s(path, &fileinfo) || !S_ISDIR(fileinfo.st_mode)) {
        return FALSE;
    }

    return TRUE;
}

LOCAL gchar* get_username_by_pid(gint32 pid)
{
    gchar path[SMALL_BUFFER_SIZE] = {0};
    gchar* result = NULL;
    (void)snprintf_s(path, sizeof(path), sizeof(path) - 1, "/proc/%d/status", pid);
    FILE *fp = fopen_s(path, "r", path);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open file failed");
        return NULL;
    }
    guint32 uid = 0;
    char buffer[SMALL_BUFFER_SIZE] = {0};
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        if (sscanf_s(buffer, "Uid:\t%*u\t%u", &uid) == 1) {
            break;
        }
    }
    struct passwd *pw = getpwuid(uid);
    if (pw != NULL) {
        result = g_strdup(pw->pw_name);
    }
    (void)fclose(fp);
    return result;
}

// 定义互斥锁
static pthread_mutex_t popen_mutex = PTHREAD_MUTEX_INITIALIZER;

static void get_notty_sshd(lua_State *L, gint32 *index)
{
    // 调用popen之前加锁
    pthread_mutex_lock(&popen_mutex);
    FILE* fp = popen("ps -ef|grep 'sshd:'|grep -v 'pts/'|grep -v 'priv'|grep 'notty'|awk '{print $2, $3}'", "r");

    if (fp == NULL) {
        debug_log(DLOG_ERROR, "excute vos_popen_s failed");
        pthread_mutex_unlock(&popen_mutex);  // 解锁互斥锁，以防出错
        return;
    }
    guint32 pid = 0;
    guint32 ppid = 0;
    time_t current_time_stamp = 0;
    while (fscanf_s(fp, "%u %u", &pid, &ppid) != EOF) {
        if (*index > MAX_CLI_USER_CNT) {
            break;
        }
        // 基于pid找用户名
        gchar* user_name = get_username_by_pid(pid);
        if (user_name == NULL) {
            debug_log(DLOG_ERROR, "get user name by pid failed");
            continue;
        }
        // 确认是否依然登录的用户
        if (is_process_alive(ppid)) {
            current_time_stamp = time(NULL);
            // 将用户名、IP、登录时间放入table
            lua_newtable(L);
            lua_pushinteger(L, ppid);              // pid
            lua_setfield(L, -2, "pid");            // -2: table
            lua_pushstring(L, user_name);          // 用户名
            lua_setfield(L, -2, "username");       // -2: table
            lua_pushstring(L, "127.0.0.1");        // 主机
            lua_setfield(L, -2, "host");           // -2: table
            lua_pushinteger(L, current_time_stamp);  // 登录时间
            lua_setfield(L, -2, "login_time");     // -2: table
            lua_seti(L, -2, (*index) + 1);         // 设置元素到外层array中 -2: table
            // 装填自增
            (*index)++;
        }
        g_free(user_name);
    }
    (void)pclose(fp);
    pthread_mutex_unlock(&popen_mutex);
}

static gint32 l_get_cli_online_users(lua_State *L)
{
    struct utmp *ut = NULL;
    lua_createtable(L, MAX_CLI_USER_CNT, 0);
    // mock DT CLI session
#if defined(ENABLE_TEST)
    lua_newtable(L);
    lua_pushinteger(L, 2222);        // pid
    lua_setfield(L, -2, "pid");            // -2: table
    lua_pushstring(L, "Administrator");        // 用户名
    lua_setfield(L, -2, "username");       // -2: table
    lua_pushstring(L, "192.168.100.12");        // 主机
    lua_setfield(L, -2, "host");           // -2: table
    lua_pushinteger(L, 1713275442);  // 登录时间
    lua_setfield(L, -2, "login_time");     // -2: table
    lua_seti(L, -2, 1);                // 设置元素到外层array中 -2: table
    return 1;
#endif
    setutent();
    gint32 i = 0;
    while ((ut = getutent()) != NULL) {
        if ((ut->ut_user[0] != 0) && (ut->ut_type == 7)) {  // 7: USER_PROCESS
            // 确认是否依然登录的用户
            if (is_process_alive(ut->ut_pid)) {
                lua_newtable(L);
                lua_pushinteger(L, ut->ut_pid);        // pid
                lua_setfield(L, -2, "pid");            // -2: table
                lua_pushstring(L, ut->ut_user);        // 用户名
                lua_setfield(L, -2, "username");       // -2: table
                lua_pushstring(L, ut->ut_host);        // 主机
                lua_setfield(L, -2, "host");           // -2: table
                lua_pushinteger(L, ut->ut_tv.tv_sec);  // 登录时间
                lua_setfield(L, -2, "login_time");     // -2: table
                lua_seti(L, -2, i + 1);                // 设置元素到外层array中 -2: table
                i++;
            }
        }
        if (i > MAX_CLI_USER_CNT) {
            break;
        }
    }
    endutent();
    get_notty_sshd(L, &i);
    return 1;
}

LOCAL gboolean is_notty_sshd_session(gint pid)
{
    gchar path[SMALL_BUFFER_SIZE] = {0};
    gchar cmdline[BUFFER_SIZE] = {0};
    
    // 检查 cmdline 内容
    (void)snprintf_s(path, sizeof(path), sizeof(path) - 1, "/proc/%d/cmdline", pid);
    FILE *fp = fopen_s(path, "r", path);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open cmdline file failed!");
        return FALSE;
    }
    size_t len = fread(cmdline, 1, sizeof(cmdline) - 1, fp);
    if (len <= 0) {
        debug_log(DLOG_ERROR, "fread cmdline file failed!");
        (void)fclose(fp);
        return FALSE;
    }
    (void)fclose(fp);
    // 替换 null 字符为空格以便解析
    for (guint32 i = 0; i < len; i++) {
        if (cmdline[i] == '\0') {
            cmdline[i] = ' ';
        }
    }
    cmdline[len] = '\0';
    // 关键特征匹配
    gboolean is_session = (
        strstr(cmdline, "sshd:") != NULL &&      // 会话进程格式
        strstr(cmdline, "@notty") == NULL &&     // 排除特殊标记
        strstr(cmdline, "listen") == NULL        // 排除监听进程
    );
    // 验证二进制路径
    gchar buffer[BUFFER_SIZE] = {0};
    if (is_session) {
        (void)snprintf_s(path, sizeof(path), sizeof(path) - 1, "/proc/%d/exe", pid);
        ssize_t rlen = readlink(path, buffer, sizeof(buffer) - 1);
        if (rlen > 0) {
            buffer[rlen] = '\0';
            is_session = (strstr(buffer, "sshd") != NULL &&
                strstr(cmdline, "sshd: /usr/sbin/sshd") == NULL);
        }
    }
    return is_session;
}

static int l_kill(lua_State *L)
{
    gint pid     = (gint)luaL_checkinteger(L, 1);
    gint singnal = (gint)luaL_checkinteger(L, 2);
    setutent();
    struct utmp *ut = NULL;
    while ((ut = getutent()) != NULL) {
        if ((ut->ut_user[0] != 0) && (ut->ut_type == 7) && ut->ut_pid == pid) {   // 7: USER_PROCESS
            kill(pid, singnal);
            endutent();
            return 0;
        }
    }
    endutent();
    if (is_process_alive(pid) && is_notty_sshd_session(pid)) {
        kill(pid, SIGTERM);
    }
    return 0;
}

static int l_format_realpath(lua_State *L)
{
    const gchar *path                    = luaL_checkstring(L, 1);
    gchar        real_path_str[PATH_MAX] = {0};
    const gchar *path_str                = realpath(path, real_path_str);
    if (strlen(real_path_str) == 0) {
        return luaL_error(L, "format path failed! err code: %d!", errno);
    }
    lua_pushstring(L, real_path_str);
    if (path_str == NULL) {
        lua_pushinteger(L, 0);  // not exist
    } else {
        lua_pushinteger(L, 1);  // exist
    }
    return 2;  // output param num 2
}

static int l_get_mac_by_socket(lua_State *L)
{
    const gchar *ip                          = luaL_checkstring(L, 1);
    const gchar *eth                         = luaL_checkstring(L, 2);
    gchar        mac_address[MACADDRESS_LEN] = {0};
    gchar       *ret                         = get_mac_by_socket(ip, eth, mac_address);
    lua_pushstring(L, ret);
    return 1;
}

static void lua_get_struct_string(lua_State *L, gchar *str, size_t str_len, gchar *field_name)
{
    lua_gettop(L);
    lua_pushstring(L, field_name);
    lua_gettable(L, 1);
    size_t       field_len = 0;
    gint32       ret;
    const gchar *field_str = lua_tolstring(L, -1, &field_len);
    if (field_len != 0) {
        ret = memcpy_s(str, str_len, field_str, field_len);
    } else {
        ret = memcpy_s(str, str_len, "\0", 1);
    }
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "memcpy_s field_name fail, ret:%d", ret);
    }
    lua_pop(L, 1);
}

static void lua_get_struct_uint8(lua_State *L, guint8 *res, gchar *field_name)
{
    lua_gettop(L);
    lua_pushstring(L, field_name);
    lua_gettable(L, 1);
    *res = (guint8)luaL_checkinteger(L, -1);
    lua_pop(L, 1);
}

static void lua_get_struct_group(lua_State *L, LDAP_GROUP_INFO *group, guint8 group_id)
{
    lua_pushnumber(L, group_id);
    lua_gettable(L, -2);  // -2: table

    lua_pushnumber(L, 1);  //  1: inner_id
    lua_gettable(L, -2);   // -2: table
    group->group_inner_id = (guint8)luaL_checkinteger(L, -1);
    lua_pop(L, 1);

    lua_pushnumber(L, 2);  //  2: group_name
    lua_gettable(L, -2);   // -2: table
    gint32       ret;
    size_t       field_len  = 0;
    const gchar *group_name = lua_tolstring(L, -1, &field_len);
    if (group_name != NULL) {
        ret = memcpy_s(group->group_name, sizeof(group->group_name), group_name, field_len);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "memcpy_s group_name fail, ret:%d", ret);
        }
    }
    lua_pop(L, 1);

    lua_pushnumber(L, 3);  //  3: group_folder
    lua_gettable(L, -2);   // -2: table
    field_len                 = 0;
    const gchar *group_folder = lua_tolstring(L, -1, &field_len);
    if (group_folder != NULL) {
        ret = memcpy_s(group->group_folder, sizeof(group->group_folder), group_folder, field_len);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "memcpy_s group_folder fail, ret:%d", ret);
        }
    }
    lua_pop(L, 1);

    lua_pushnumber(L, 4);  //  4: privilege
    lua_gettable(L, -2);   // -2: table
    group->group_priv = (guint8)luaL_checkinteger(L, -1);
    lua_pop(L, 2);  //  2: 推出folder和整个table
}

static int l_mscm_ldap_authenticate(lua_State *L)
{
    LDAP_AUTH_INFO ldap_auth_info = {0};

    debug_log(DLOG_ERROR, "now execute mscm_ldap_authenticate");
    // 域控制器信息
    lua_get_struct_uint8(L, &(ldap_auth_info.serverid), "serverid");

    lua_get_struct_string(L, ldap_auth_info.hostaddr, sizeof(ldap_auth_info.hostaddr), "hostaddr");

    lua_gettop(L);
    lua_pushstring(L, "port");
    lua_gettable(L, 1);
    ldap_auth_info.port = (gint32)luaL_checkinteger(L, -1);
    lua_pop(L, 1);

    lua_get_struct_string(L, ldap_auth_info.user_domain, sizeof(ldap_auth_info.user_domain), "user_domain");

    lua_get_struct_string(L, ldap_auth_info.folder, sizeof(ldap_auth_info.folder), "folder");

    lua_get_struct_string(L, ldap_auth_info.bind_dn, sizeof(ldap_auth_info.bind_dn), "bind_dn");

    lua_get_struct_string(L, ldap_auth_info.bind_dn_pwd, sizeof(ldap_auth_info.bind_dn_pwd), "bind_dn_pwd");

    lua_get_struct_uint8(L, &(ldap_auth_info.cert_verify_enabled), "cert_verify_enabled");

    lua_get_struct_uint8(L, &(ldap_auth_info.cert_verify_level), "cert_verify_level");

    lua_get_struct_string(L, ldap_auth_info.cert_inner_dir, sizeof(ldap_auth_info.cert_inner_dir), "cert_inner_dir");

    lua_get_struct_string(L, ldap_auth_info.scope, sizeof(ldap_auth_info.scope), "scope");

    lua_get_struct_uint8(L, &(ldap_auth_info.time_limit), "time_limit");

    lua_get_struct_uint8(L, &(ldap_auth_info.bind_time_limit), "bind_time_limit");

    lua_get_struct_uint8(L, &(ldap_auth_info.version), "version");

    // 用户组信息
    lua_get_struct_uint8(L, &(ldap_auth_info.group_cnt), "group_cnt");

    lua_gettop(L);
    lua_pushstring(L, "group");
    lua_gettable(L, 1);
    for (gint32 i = 0; i < ldap_auth_info.group_cnt; i++) {
        lua_get_struct_group(L, &(ldap_auth_info.group[i]), i + 1);
    }
    lua_pop(L, 1);

    // 加密套件
    lua_get_struct_string(L, ldap_auth_info.tls_cipher, sizeof(ldap_auth_info.tls_cipher), "tls_cipher");

    // 认证信息
    lua_get_struct_string(L, ldap_auth_info.username, sizeof(ldap_auth_info.username), "username");
    lua_get_struct_string(L, ldap_auth_info.password, sizeof(ldap_auth_info.password), "password");

    guint8 user_pri                 = 0;
    guint8 group_id[MAX_USER_GROUP] = {0xff, 0xff, 0xff, 0xff, 0xff};
    gint32 ret                      = mscm_ldap_authenticate(&ldap_auth_info, &user_pri, group_id);

    lua_pushinteger(L, ret);
    lua_pushinteger(L, user_pri);

    lua_newtable(L);
    for (gint32 i = 0; i < MAX_USER_GROUP; i++) {
        lua_pushinteger(L, i + 1);
        lua_pushinteger(L, group_id[i]);
        lua_settable(L, -3);  // 栈-3位置的table加入数据下标为i+1， 值为group_id[i]
    }

    return 3;  // output param num 3
}

static int l_check_username_divide_by_domain(lua_State *L)
{
    gchar user_name[LDAP_USER_NAME_MAX_LEN + 1] = {0};
    gchar domain[LDAP_USER_NAME_MAX_LEN + 1] = {0};
    guint8 has_domain = USER_NAME_NOT_CONTAIN_DOMAIN;
    errno_t safe_fun_ret;

    do {
        const gchar *user_name_remain    = luaL_checkstring(L, 1);            // param 1
        if (user_name_remain == NULL) {
            break;
        }

        /* 判断用户名是否包含格式 用户名@域名 */
        gchar *ptr = strrchr(user_name_remain, '@');
        if (ptr == NULL) { // 不包含格式，直接返回
            break;
        }

        /* 若@后无其它内容，拆分出的域名非法 */
        if (strlen(ptr) <= 1) {
            break;
        }

        safe_fun_ret = strncpy_s(domain, LDAP_USER_NAME_MAX_LEN, ptr + 1, strlen(ptr) - 1);
        if (safe_fun_ret != EOK) {
            debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", safe_fun_ret);
        }

        safe_fun_ret = strncpy_s(user_name, LDAP_USER_NAME_MAX_LEN, user_name_remain,
            strlen(user_name_remain) - strlen(ptr));
        if (safe_fun_ret != EOK) {
            debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", safe_fun_ret);
        }

        has_domain = USER_NAME_CONTAIN_DOMAIN;
    } while (0);

    lua_pushinteger(L, has_domain);
    lua_pushstring(L, user_name);
    lua_pushstring(L, domain);
    return 3; // output param num 3
}

/*
 * Description : 判断是否是合理的ipv4地址
 * Notes：返回值（1:无效；0:有效）
 */
static int l_vos_ipv4_addr_valid_check(lua_State *L)
{
    const guchar *ntp_server = (guchar *)luaL_checkstring(L, 1);
    gint32        flag       = vos_ipv4_addr_valid_check(ntp_server);

    lua_pushinteger(L, flag);

    return 1;
}

/*
 * Description : 判断是否是合理的ipv4地址
 * Notes：返回值（1:无效；0:有效）
 */
static int l_vos_ipv6_addr_valid_check(lua_State *L)
{
    const guchar *ntp_server = (guchar *)luaL_checkstring(L, 1);
    gint32        flag       = vos_ipv6_addr_valid_check(ntp_server);

    lua_pushinteger(L, flag);

    return 1;
}

static int l_get_user_shell(lua_State *L)
{
#if defined(BUILD_TYPE) && defined(BUILD_TYPE_RELEASE) && BUILD_TYPE == BUILD_TYPE_RELEASE
    lua_pushstring(L, "/usr/bin/clp_commands");
#else
    lua_pushstring(L, "/bin/bash");
#endif
    return 1;
}

/*
 * Description : VNC加密挑战函数
 */
static int l_vnc_encrypt_bytes(lua_State *L)
{
    const gchar *plaintext_luaL                = luaL_checkstring(L, 1);
    const guchar *auth_challenge               = (guchar *)luaL_checkstring(L, 2);
    gint32 authen_challenge_len                = (gint32)luaL_checkinteger(L, 3);
    gint32 outlen                              = 0;
    guchar output[VNC_CHALLENGESIZE + 1]       = {0};
    gchar plaintext[KEYLENS + 1]               = {0}; /* VNC密码明文，最大长度8 */
    errno_t ret_safe = strncpy_s(plaintext, sizeof(plaintext), plaintext_luaL, strlen(plaintext_luaL));
    if (ret_safe != EOK) {
        debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", ret_safe);
        return luaL_error(L, "vnc_encrypt_bytes failed!");
    }
    gint32 ret = vnc_encrypt_bytes((guchar *)plaintext, (guchar *)auth_challenge,
        authen_challenge_len, output, &outlen);
    (void)memset_s((gchar *)plaintext_luaL, strlen(plaintext_luaL), 0, strlen(plaintext_luaL));
    (void)memset_s(plaintext, sizeof(plaintext), 0, sizeof(plaintext));
    lua_pushinteger(L, ret);
    lua_pushlstring(L, (gchar *)output, outlen);
    return 2;       // output param num 2
}

/*
 * Description : 区分是否进入装备模式
 */
static int l_is_manufacture_mode(lua_State *L)
{
#ifdef G_BUILD_MANUFACTURE
    lua_pushboolean(L, 1);
#else
    lua_pushboolean(L, 0);
#endif
    return 1;       // output param num 1
}

/*
 * Description : 通过LDAP用户uid获取角色
 */
static int l_get_ldap_user_info(lua_State *L)
{
    gint32 uid = (gint32)luaL_checkinteger(L, -1);
    LDAP_USER user = { 0 };
    gint32 ret = uip_read_ldap_user(uid, &user);
    lua_pushinteger(L, ret);
    if (ret == RET_ERR) {
        return 1;
    }
    lua_newtable(L);
    lua_pushinteger(L, user.used);          // used
    lua_setfield(L, -2, "used");            // -2: table
    lua_pushinteger(L, user.uid);           // uid
    lua_setfield(L, -2, "uid");             // -2: table
    lua_pushstring(L, user.username);       // username
    lua_setfield(L, -2, "username");        // -2: table
    lua_pushinteger(L, user.serverid);      // LDAP控制器Id
    lua_setfield(L, -2, "serverid");        // -2: table
    lua_pushinteger(L, user.groupid);       // 远程用户组inner_id
    lua_setfield(L, -2, "groupid");         // -2: table
    lua_pushinteger(L, user.roleid[0]);     // role_id
    lua_setfield(L, -2, "roleid");          // -2: table
    return 2;
}

/*
 * Description : 获取uip_ldap_users所有已认证用户
 */
static int l_get_authed_ldap_user(lua_State *L)
{
    FILE *fp = NULL;
    gint32 user_num = 0;
    lua_createtable(L, LDAP_USER_MAX_COUNT, 0);
    // 无ldap用户登录cli时不创建文件,直接返回-1
    if (check_real_path_s(LDAP_USER_FILE, NULL) != 0) {
        lua_pushinteger(L, RET_ERR);
        return 1;
    }
    fp = fopen_s(LDAP_USER_FILE, "rb", LDAP_USER_FILE);
    if (NULL == fp) {
        debug_log(DLOG_ERROR, "fopen_s ldap user file failed.");
        lua_pushinteger(L, RET_ERR);
        return 1;
    }

    while (user_num < LDAP_USER_MAX_COUNT) {
        struct LDAP_USER ldap_user;
        size_t read_size = fread(&ldap_user, sizeof(struct LDAP_USER), 1, fp);
        if (read_size != 1) {
            if (feof(fp)) {
                break;
            } else {
                debug_log(DLOG_ERROR, "fread ldap user file failed.");
                (void)fclose(fp);
                lua_pushinteger(L, RET_ERR);
                return 1;
            }
        }
        if (ldap_user.used == 0) {
            continue;
        }
        lua_newtable(L);
        lua_pushinteger(L, ldap_user.used);          // used
        lua_setfield(L, -2, "used");            // -2: table
        lua_pushinteger(L, ldap_user.uid);           // uid
        lua_setfield(L, -2, "uid");             // -2: table
        lua_pushstring(L, ldap_user.username);       // username
        lua_setfield(L, -2, "username");        // -2: table
        lua_pushinteger(L, ldap_user.serverid);      // LDAP控制器Id
        lua_setfield(L, -2, "serverid");        // -2: table
        lua_pushinteger(L, ldap_user.groupid);       // 远程用户组inner_id
        lua_setfield(L, -2, "groupid");         // -2: table
        lua_pushinteger(L, ldap_user.roleid[0]);     // role_id
        lua_setfield(L, -2, "roleid");          // -2: table
        lua_seti(L, -2, user_num + 1);
        user_num++;
    }
    (void)fclose(fp);
    return 1;
}

/*
 * Description : 通过kill踢出的LDAP_CLI会话需要刷新uip_ldap_users文件
 */
static int l_uip_renew_ldap_user(lua_State *L)
{
    gint32 uid = (gint32)luaL_checkinteger(L, -1);
    LDAP_USER user = { 0 };
    user.uid = uid;
    gint32 ret = uip_renew_ldap_user(&user);
    lua_pushinteger(L, ret);
    return 1;
}


/*
 * Dewcription : LDAP域用户登录ssh分配uid
 */
static int l_uip_alloc_ldap_uid(lua_State *L)
{
    gint32 uid = uip_alloc_ldap_uid();
    lua_pushinteger(L, uid);
    return 1;
}

#if defined(ENABLE_TEST)
/*
 * Dewcription : LDAP域用户登录ssh分配uid
 */
static int l_set_dt_log_level(lua_State *L)
{
    set_debug_log_level(LOG_LEVEL_DEBUG);
    return 0;
}
#endif

#if defined(ENABLE_TEST)
/*
 * Dewcription : uip记录用户登录信息
 */
static int l_init_dbus_connection(lua_State *L)
{
    init_dbus_connection();
    return 0;
}
#endif

/*
 * Dewcription : 生成认证公私钥对，rest登录加解密
 */
static int l_generate_requested_key_pair(lua_State *L)
{
    gchar *public_key  = (gchar *)g_malloc0(KEY_MAX_SIZE);
    gchar *private_key = (gchar *)g_malloc0(KEY_MAX_SIZE);
    gint32 ret         = generate_key_pair(&public_key, &private_key);
    if (ret == RET_ERR) {
        g_free(public_key);
        g_free(private_key);
        return luaL_error(L, "generate_key_pair failed! ret code: %d!", ret);
    }
    lua_pushstring(L, public_key);
    lua_pushstring(L, private_key);
    (void)memset_s(private_key, KEY_MAX_SIZE, 0, KEY_MAX_SIZE);
    g_free(public_key);
    g_free(private_key);

    return 2;  // output param num 2
}

/*
 * Dewcription : 公钥加密
 */
static int l_encrypt_with_public_key(lua_State *L)
{
    const gchar  *pub_key           = luaL_checkstring(L, 1);
    gint32        pub_key_len       = (gint32)luaL_checkinteger(L, 2);
    const guchar *plaintext         = (guchar *)luaL_checkstring(L, 3);
    gint32        plaintext_len     = (gint32)luaL_checkinteger(L, 4);
    guchar       *cipher_text;
    gint32        len               = encrypt_with_public_key(pub_key, pub_key_len,
        plaintext, plaintext_len, &cipher_text);
    if (len <= 0) {
        debug_log(DLOG_ERROR, "encrypt with public failed.");
        lua_pushstring(L, "");
        return 1;
    }
    lua_pushlstring(L, (gchar *)cipher_text, len);
    OPENSSL_free(cipher_text);
    return 1;
}

/*
 * Dewcription : 私钥解密
 */
static int l_decrypt_with_private_key(lua_State *L)
{
    const gchar  *priv_key      = luaL_checkstring(L, 1);
    gint32        priv_key_len  = (gint32)luaL_checkinteger(L, 2);
    const guchar *cipher_text   = (guchar *)luaL_checkstring(L, 3);
    gint32        cipher_len    = (gint32)luaL_checkinteger(L, 4);
    guchar       *plaintext;
    gint32        len           = decrypt_with_private_key(priv_key, priv_key_len, cipher_text, cipher_len, &plaintext);
    if (len <= 0) {
        debug_log(DLOG_ERROR, "decrypt with private failed.");
        lua_pushstring(L, "");
        return 1;
    }
    lua_pushlstring(L, (gchar *)plaintext, len);
    OPENSSL_free(plaintext);
    return 1;
}

/*
 * Dewcription : ipv4子网校验
 */
static int l_is_ip_in_subnet(lua_State *L)
{
    const gchar  *ip_str           = luaL_checkstring(L, 1);
    const gchar  *subnet_str       = luaL_checkstring(L, 2);

    gint32 ret = is_ip_in_subnet(ip_str, subnet_str);
    lua_pushboolean(L, ret == RET_OK);
    return 1;
}

/*
 * Dewcription : ipv6子网校验
 */
static int l_is_ipv6_in_subnet(lua_State *L)
{
    const gchar  *ip_str           = luaL_checkstring(L, 1);
    const gchar  *subnet_str       = luaL_checkstring(L, 2);

    gint32 ret = is_ipv6_in_subnet(ip_str, subnet_str);
    lua_pushboolean(L, ret == RET_OK);
    return 1;
}

LUAMOD_API int luaopen_iam_core(lua_State *L)
{
    luaL_checkversion(L);
    luaL_Reg l[] = {
        {"is_pass_complexity_check_pass", l_is_pass_complexity_check_pass},                  // 密码复杂度检查
        {"is_vnc_password_complexity_check_pass", l_is_vnc_password_complexity_check_pass},  // vnc密码复杂度检查
        {"get_cli_online_users", l_get_cli_online_users},                                    // 获取在线cli用户
        {"kill", l_kill},                                                                    // 删除进程
        {"increment_pam_tally", l_increment_pam_tally},                                      // 增加pam锁定记录
        {"reset_pam_tally", l_reset_pam_tally},                                              // 重置pam锁定记录
        {"get_pam_tally", l_get_pam_tally},                                                  // 获取pam锁定记录
        {"get_pam_tally_with_fail_interval", l_get_pam_tally_with_fail_interval},            // 获取pam锁定记录，带失败间隔
        {"format_realpath", l_format_realpath},                                              // 格式化文件路径
        {"get_mac_by_socket", l_get_mac_by_socket},                                          // 获取MAC地址
        {"mscm_ldap_authenticate", l_mscm_ldap_authenticate},                                // LDAP远程认证
        {"check_username_divide_by_domain", l_check_username_divide_by_domain},              // 判断输入用户名是否包含domain，有则拆分
        {"vos_ipv4_addr_valid_check", l_vos_ipv4_addr_valid_check},                          // 判断ipv4地址是否有效
        {"vos_ipv6_addr_valid_check", l_vos_ipv6_addr_valid_check},                          // 判断ipv6地址是否有效
        {"get_user_shell", l_get_user_shell},                                                // 获取登录用户Shell
        {"vnc_encrypt_bytes", l_vnc_encrypt_bytes},                                          // vnc加密挑战码
        {"is_manufacture_mode", l_is_manufacture_mode},                                      // 当前是否在装备模式                                          // 解密压缩文件
        {"get_ldap_user_info", l_get_ldap_user_info},                                        // 通过uid获取LDAP已认证用户
        {"get_authed_ldap_user", l_get_authed_ldap_user},                                    // 获取所有已认证的LDAP用户
        {"uip_renew_ldap_user", l_uip_renew_ldap_user},                                      // 刷新uip_ldap_users文件
        {"uip_alloc_ldap_uid", l_uip_alloc_ldap_uid},                                        // LDAP域用户登录ssh分配uid
        {"generate_requested_key_pair", l_generate_requested_key_pair},                      // 生成证书公私钥对，rest登录加解密
        {"encrypt_with_public_key", l_encrypt_with_public_key},                              // 公钥加密
        {"decrypt_with_private_key", l_decrypt_with_private_key},                            // 私钥解密
        {"is_ip_in_subnet", l_is_ip_in_subnet},                                              // ipv4子网校验
        {"is_ipv6_in_subnet", l_is_ipv6_in_subnet},                                          // ipv6子网校验
        // 增加DT调试方法
#if defined(ENABLE_TEST)
        {"set_dt_log_level", l_set_dt_log_level},                                            // 设置日志信息
        {"init_dbus_connection", l_init_dbus_connection},                                  // uip记录登录信息
#endif
        {NULL, NULL},
    };
    luaL_newlib(L, l);

    return 1;
}