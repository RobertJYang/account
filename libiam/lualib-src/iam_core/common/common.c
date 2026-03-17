/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
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
 * Create: 2023-05-22
 */

#include <arpa/inet.h>
#include "fcntl.h"
#include "errno.h"
#include "limits.h"
#include "unistd.h"
#include "dlfcn.h"
#include "sys/types.h"
#include "sys/stat.h"
#include "pwd.h"
#include "common.h"
#include <dbus/dbus.h>

#define DBUS_CONNECTION_TIMEOUT (20000)
static DBusConnection *g_dbus_conn = NULL;

/*
 * Description: 将单行文本内容解析为guint8
 * @param: [in] data：单个文本数据
 * @param: [out] target：指定存储数据
 */
gint32 parse_line_token_to_uint8(gchar *token, guint8 *target)
{
    gchar *endptr = NULL;
    guint8 tmp_val = (guint8)strtol(token, &endptr, DECIMAL_NUM);
    if ((errno == ERANGE && (tmp_val == LONG_MAX || tmp_val == LONG_MIN)) || (endptr == token)) {
        return RET_ERR;
    }

    *target = tmp_val;
    return RET_OK;
}

/*
 * Description: 获取当地系统时间
 */
gint32 get_localtime_r(const time_t *p_time_stamp, struct tm *p_tm)
{
    time_t time_stamp = 0;
    struct tm *p = NULL;

    if (p_tm == NULL) {
        return RET_ERR;
    }

    time_stamp = (p_time_stamp == NULL) ? (time_t)time(0) : *p_time_stamp;
    tzset();
    p = localtime_r(&time_stamp, p_tm); /* 取得当地时间 */
    if (p == NULL) {
        return RET_ERR;
    }

    return RET_OK;
}

/*
 * Description: 根据用户名获取uid
 *              2019-05-9 修复获取passwd失败时pw_passwd野指针导致coredump
 */
gint32 get_uid_gid_by_name(const gchar *user_name, uid_t *uid, uid_t *gid)
{
    struct passwd  pwd;
    struct passwd *result             = NULL;
    gchar          buf[MAX_BUFF_SIZE] = {0};
    gint32         ret;

    if ((user_name == NULL) || (uid == NULL)) {
        return RET_ERR;
    }

    (void)memset_s(&pwd, sizeof(pwd), 0, sizeof(pwd));

    /* 根据用户名获取用户passwd结构 */
    ret = getpwnam_r(user_name, &pwd, buf, sizeof(buf), &result);
    /* If no matching password  record  was  found,  these functions return 0 and store NULL in *result.
       In case of error, an error number is returned, and NULL is stored in *result. */
    if (result == NULL) {
        if (ret == 0) {
            ret = RET_ERR;
        }

        return ret;
    }

    if (pwd.pw_passwd != NULL) {
        (void)memset_s(pwd.pw_passwd, strlen(pwd.pw_passwd), 0, strlen(pwd.pw_passwd));
    }

    /* 获取用户uid gid */
    *uid = result->pw_uid;
    *gid = result->pw_gid;

    return RET_OK;
}

/*
 * Description: 判断uid是否为本地用户
 */
gint32 check_uid_is_local_user(uid_t uid)
{
    if (uid < IMANA_UID_BASE + IMANA_UID_MIN ||
        (uid > IMANA_UID_BASE + IMANA_UID_MAX && uid < IMANA_UID_BASE + OEM_UID_MIN) ||
        uid > IMANA_UID_BASE + OEM_UID_MAX) {
        return FALSE;
    }
    return TRUE;
}

/*
 * Description: 判断ipv4地址是否为在子网中
 */
gint32 is_ip_in_subnet(const gchar *ip_str, const gchar *subnet_str)
{
    struct in_addr ip_addr, subnet_addr, subnet_mask;
    gchar subnet_ip[INET_ADDRSTRLEN];
    int mask_len = 32;

    if (inet_pton(AF_INET, ip_str, &ip_addr) != 1) {
        debug_log(DLOG_ERROR, "Invalid IP address: %s", ip_str);
        return RET_ERR;
    }

    // 没有设置掩码时等同于掩码长为32
    gint32 ret = sscanf_s(subnet_str, "%15[^/]/%d$", subnet_ip, INET_ADDRSTRLEN, &mask_len);
    if (ret <= 0) {
        debug_log(DLOG_ERROR, "%s: sscanf_s failed.", __FUNCTION__);
        return RET_ERR;
    }

    if (mask_len > 32 || mask_len < 1) {
        debug_log(DLOG_ERROR, "Invalid mask length: %d", mask_len);
        return RET_ERR;
    }

    if (inet_pton(AF_INET, subnet_ip, &subnet_addr) != 1) {
        debug_log(DLOG_ERROR, "Invalid subnet IP: %s", subnet_ip);
        return RET_ERR;
    }

    subnet_mask.s_addr = htonl(~((1 << (32 - mask_len)) - 1));

    ret = ((ip_addr.s_addr & subnet_mask.s_addr) == (subnet_addr.s_addr & subnet_mask.s_addr)) ? RET_OK : RET_ERR;
    return ret;
}

/*
 * Description: 判断ipv6地址是否为在子网中
 */
gint32 is_ipv6_in_subnet(const gchar *ip_str, const gchar *subnet_str)
{
    struct in6_addr ip_addr, subnet_addr;
    gchar subnet_ip[INET6_ADDRSTRLEN];
    int mask_len = 128;

    if (inet_pton(AF_INET6, ip_str, &ip_addr) != 1) {
        debug_log(DLOG_ERROR, "Invalid IPV6 address: %s", ip_str);
        return RET_ERR;
    }

    // 没有设置掩码时等同于掩码长为128
    gint32 ret = sscanf_s(subnet_str, "%45[^/]/%d$", subnet_ip, INET6_ADDRSTRLEN, &mask_len);
    if (ret <= 0) {
        debug_log(DLOG_ERROR, "%s: sscanf_s failed.", __FUNCTION__);
        return RET_ERR;
    }

    if (mask_len > 128 || mask_len < 1) {
        debug_log(DLOG_ERROR, "Invalid mask length: %d", mask_len);
        return RET_ERR;
    }

    if (inet_pton(AF_INET6, subnet_ip, &subnet_addr) != 1) {
        debug_log(DLOG_ERROR, "Invalid subnet IP: %s", subnet_ip);
        return RET_ERR;
    }

    int byte_len, bit_len;
    byte_len = mask_len / 8;
    bit_len = 8 - (mask_len % 8);
    int i = 0;
    while (i < byte_len) {
        if (subnet_addr.s6_addr[i] != ip_addr.s6_addr[i]) {
            debug_log(DLOG_ERROR, "Check ip failed");
            return RET_ERR;
        }
        i++;
    }
    if (byte_len == 16) {
        return RET_OK;
    }
    if ((subnet_addr.s6_addr[i] >> bit_len) == (ip_addr.s6_addr[i] >> bit_len)) {
        return RET_OK;
    }

    return RET_ERR;
}

#ifndef G_ENABLE_TEST
LOCAL gint32 init_dbus_env(void)
{
#define DBUS_SESSION_BUS_ADDRESS "DBUS_SESSION_BUS_ADDRESS"
#define DBUS_SESSION_BUS_PID     "DBUS_SESSION_BUS_PID"
#define DBUS_ENV_FILE_PATH       "/dev/shm/dbus/.dbus"
#define ADDRESS_IDX              1
#define PID_IDX                  2
    // DBUS环境变量已加载直接返回
    if (g_getenv("DBUS_SESSION_BUS_ADDRESS") != NULL && g_getenv("DBUS_SESSION_BUS_PID") != NULL) {
        return RET_OK;
    }
    gchar  *env_content = NULL;
    gsize   file_len    = 0;
    GError *err         = NULL;
    if (g_file_get_contents(DBUS_ENV_FILE_PATH, &env_content, &file_len, &err) == FALSE) {
        debug_log(DLOG_ERROR, "[ip lock] get dbus env failed, error is %s", err->message);
        g_error_free(err);
        return RET_ERR;
    }
    GRegex     *regex      = NULL;
    GMatchInfo *match_info = NULL;
    regex                  = g_regex_new("DBUS_SESSION_BUS_ADDRESS=(.+?)\nDBUS_SESSION_BUS_PID=(\\d+)\n", 0, 0, NULL);
    g_regex_match(regex, env_content, 0, &match_info);
    if (g_match_info_matches(match_info) == FALSE) {
        g_match_info_free(match_info);
        g_regex_unref(regex);
        g_free(env_content);
        return RET_ERR;
    }
    gchar *address = g_match_info_fetch(match_info, ADDRESS_IDX);
    gchar *pid     = g_match_info_fetch(match_info, PID_IDX);
    setenv(DBUS_SESSION_BUS_ADDRESS, address, 1);
    setenv(DBUS_SESSION_BUS_PID, pid, 1);
    g_free(address);
    g_free(pid);
    g_match_info_free(match_info);
    g_regex_unref(regex);
    g_free(env_content);
    return RET_OK;
}

LOCAL gint32 init_dbus_connection(void)
{
    DBusError error = {0};

    if (g_dbus_conn != NULL) {
        return RET_OK;
    }
    gint32 ret = init_dbus_env();
    if (ret != RET_OK) {
        return ret;
    }

    dbus_error_init(&error);
    g_dbus_conn = dbus_bus_get_private(DBUS_BUS_SESSION, &error);
    if (g_dbus_conn == NULL || dbus_error_is_set(&error)) {
        debug_log(DLOG_ERROR, "[ip lock] Open dbus session failed, Error name:%s, Error message:%s.", error.name,
                  error.message);
        dbus_error_free(&error);
        return RET_ERR;
    }

    dbus_connection_set_exit_on_disconnect(g_dbus_conn, FALSE);

    return RET_OK;
}

gint32 dbus_get_auth_lockout_conf(gint32 *duration, gint32 *threshold, gint32 *time_interval)
{
    // 初始化DBus连接
    gint32 ret = init_dbus_connection();
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "[ip lock]init DBus failed, ret: %d", ret);
        return ret;
    }

    // 获取Get接口
    DBusMessage *call = dbus_message_new_method_call(IAM_SERVICE, AUTHENTICATION_PATH, PROPERTIES_INTF, "GetAll");
    if (call == NULL) {
        debug_log(DLOG_ERROR, "[ip lock] Make new method call GetAll failed.");
        return RET_ERR;
    }

    // 追加参数
    const gchar *interface = AUTHENTICATION_INTF;
    if (dbus_message_append_args(call, DBUS_TYPE_STRING, &interface, DBUS_TYPE_INVALID) == FALSE) {
        dbus_message_unref(call);
        debug_log(DLOG_ERROR, "[ip lock] Append message failed.");
        return RET_ERR;
    }

    // 初始化错误接收器
    DBusError       error;
    dbus_error_init(&error);
    // 发送请求并阻塞式等待相应
    DBusMessage *reply = dbus_connection_send_with_reply_and_block(g_dbus_conn, call, DBUS_CONNECTION_TIMEOUT, &error);
    // 对消息通道解引用
    dbus_message_unref(call);
    if (reply == NULL || dbus_error_is_set(&error)) {
        debug_log(DLOG_ERROR, "[uip user] Call method failed, Error name:%s, Error message:%s.", error.name,
                  error.message);
        dbus_error_free(&error);
        return RET_ERR;
    }

    // 拿到结果的迭代器
    DBusMessageIter iter, dict_iter, entry_iter, variant_iter;
    const gchar *prop_name;
    dbus_message_iter_init(reply, &iter);
    dbus_message_iter_recurse(&iter, &dict_iter);

    // 遍历获取需要的值
    while (dbus_message_iter_get_arg_type(&dict_iter) != DBUS_TYPE_INVALID) {
        // 获取字典条目 {key, value}
        dbus_message_iter_recurse(&dict_iter, &entry_iter);
        dbus_message_iter_get_basic(&entry_iter, &prop_name); // 属性名

        dbus_message_iter_next(&entry_iter);
        dbus_message_iter_recurse(&entry_iter, &variant_iter); // 属性变体值

        if (strcmp(prop_name, PROPERTY_LOCKOUT_DURATION) == 0) {
            dbus_message_iter_get_basic(&variant_iter, duration);
        } else if (strcmp(prop_name, PROPERTY_LOCKOUT_THRESHOLD) == 0) {
            dbus_message_iter_get_basic(&variant_iter, threshold);
        } else if (strcmp(prop_name, PROPERTY_LOCKOUT_TIME_INTERVAL) == 0) {
            dbus_message_iter_get_basic(&variant_iter, time_interval);
        }

        dbus_message_iter_next(&dict_iter);
    }

    // 释放资源
    dbus_message_unref(reply);
    return RET_OK;
}
#endif // G_ENABLE_TEST