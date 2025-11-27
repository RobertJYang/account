/* Copyright (c) 2024 Huawei Technologies Co., Ltd.
 * openUBMC is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 */

#define LUA_LIB
#include <lauxlib.h>
#include <lua.h>
#include <securec.h>
#include "glib.h"
#include "stdio.h"
#include "syslog.h"
#include "logging.h"
#include "../network.h"
#include "../password.h"
#include "../pam_tally_ext.h"

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

static int l_get_mac_by_socket(lua_State *L)
{
    const gchar *ip                          = luaL_checkstring(L, 1);
    const gchar *eth                         = luaL_checkstring(L, 2);
    gchar        mac_address[MACADDRESS_LEN] = {0};
    gchar       *ret                         = get_mac_by_socket(ip, eth, mac_address);
    lua_pushstring(L, ret);
    return 1;
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
    gint64      fail_interval  = (gint64)luaL_checkinteger(L, 4);   // param 4
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

static int l_vnc_encrypt_bytes(lua_State *L)
{
    const guchar *plaintext                    = (guchar *)luaL_checkstring(L, 1);
    const guchar *auth_challenge               = (guchar *)luaL_checkstring(L, 2);
    gint32 authen_challenge_len                = (gint32)luaL_checkinteger(L, 3);
    gint32 outlen                              = 0;
    guchar       output[VNC_CHALLENGESIZE + 1]    = {0};
    gint32 ret = vnc_encrypt_bytes((guchar *)plaintext, (guchar *)auth_challenge,
        authen_challenge_len, output, &outlen);
    lua_pushinteger(L, ret);
    lua_pushlstring(L, (gchar *)output, outlen);
    return 2;       // output param num 2
}

static int l_check_pattern(lua_State *L)
{
    const gchar *pattern = luaL_checkstring(L, 1);
    gint32 ret = check_pattern(pattern);
    lua_pushboolean(L, ret == RET_OK);
    return 1;
}

static int l_verify_passwd_with_pattern(lua_State *L)
{
    const gchar *pattern = luaL_checkstring(L, 1);
    const gchar *passwd  = luaL_checkstring(L, 2);
    gint32 ret = verify_passwd_with_pattern(pattern, passwd);
    lua_pushboolean(L, ret == RET_OK);
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

LUAMOD_API int luaopen_account_core(lua_State *L)
{
    luaL_checkversion(L);
    luaL_Reg l[] = {
        {"format_realpath", l_format_realpath},                                              // 格式化文件路径
        {"is_manufacture_mode", l_is_manufacture_mode},                                      // 当前是否在装备模式
        {"generate_requested_key_pair", l_generate_requested_key_pair},                      // 生成证书公私钥对，rest登录加解密
        {"encrypt_with_public_key", l_encrypt_with_public_key},                              // 公钥加密
        {"decrypt_with_private_key", l_decrypt_with_private_key},                            // 私钥解密
        {"get_mac_by_socket", l_get_mac_by_socket},                                          // 获取MAC地址
        {"is_pass_complexity_check_pass", l_is_pass_complexity_check_pass},                  // 密码复杂度检查
        {"is_vnc_password_complexity_check_pass", l_is_vnc_password_complexity_check_pass},  // vnc密码复杂度检查
        {"vnc_encrypt_bytes", l_vnc_encrypt_bytes},                                          // vnc加密挑战码
        {"get_user_shell", l_get_user_shell},                                                // 获取登录用户Shell
        {"increment_pam_tally", l_increment_pam_tally},                                      // 增加pam锁定记录
        {"reset_pam_tally", l_reset_pam_tally},                                              // 重置pam锁定记录
        {"get_pam_tally", l_get_pam_tally},                                                  // 获取pam锁定记录
        {"get_pam_tally_with_fail_interval", l_get_pam_tally_with_fail_interval},            // 获取pam锁定记录，带失败间隔
        {"is_ip_in_subnet", l_is_ip_in_subnet},                                              // ipv4子网校验
        {"is_ipv6_in_subnet", l_is_ipv6_in_subnet},                                          // ipv6子网校验
        {"check_pattern", l_check_pattern},                                                  // 校验正则表达式有效性
        {"verify_passwd_with_pattern", l_verify_passwd_with_pattern},                        // 基于正则表达式验证密码
        // 增加DT调试方法
#if defined(ENABLE_TEST)
        {"set_dt_log_level", l_set_dt_log_level},                                        // 设置日志信息
#endif
        {NULL, NULL}
    };
    luaL_newlib(L, l);
    return 1;
}