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
 * Create: 2023-08-30
 */

#include <sys/file.h>
#include <glib-2.0/glib.h>
#include <dbus/dbus.h>
#include "glib.h"
#include "../ldap_auth.h"
#include "../common/common.h"
#include "../common/check_login_rule.h"
#include "utils/vos.h"
#include "utils/file_securec.h"
#include "uip_user.h"

#define DBUS_CONNECTION_TIMEOUT (20000)
static DBusConnection *g_dbus_conn = NULL;

/*
 * Description: 将单行文本内容解析为username字符串
 * @param: [in]  token ：单个文本数据
 * @param: [out] target：指定存储数据
 */
LOCAL gint32 parse_line_token_to_user_name(const gchar *token, IPMI_USER_S *ipmi_user)
{
    if (strlen(token) >= sizeof(ipmi_user->user_name)) {
        return TOKEN_TOO_LONG;
    } else {
        gint32 ret = memcpy_s(ipmi_user->user_name, sizeof(ipmi_user->user_name), token, strlen(token));
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "memcpy_s user name fail, ret:%d", ret);
            return ret;
        }
        return RET_OK;
    }
}

/*
 * Description: 将单行文本内容解析到结构体中
 * @param: [in]  line     ：ipmi文件中的单个文本行，格式为 2:Administrator:x:1:5:0:1:1:1:0:0:4:x:0:0:0:0:0
 * @param: [out] ipmi_user：用于存储解析后的文本内容
 */
LOCAL gint32 parse_line_to_struct(const gchar *line, IPMI_USER_S *ipmi_user)
{
    gint32 ret = 0;
    gint32 pos = 0;

    gchar *tmp_line = strdup(line);
    if (tmp_line == NULL) {
        return STRDUP_FAILED;
    }
    gchar *line_bak = tmp_line;
    gchar *token    = strsep(&tmp_line, ":");
    while (token) {
        pos++;
        // 根据内容位置处理数据
        switch (pos) {
            case INDEX_LINE_UID:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_id));
                break;
            case INDEX_LINE_USER:
                ret = parse_line_token_to_user_name(token, ipmi_user);
                break;
            case INDEX_LINE_USER_ENABLE:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_enabled));
                break;
            case INDEX_LINE_USER_PRIVILEGE_1:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->privilege[1]));
                break;
            case INDEX_LINE_USER_LOCK_STATE:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_lock_status));
                break;
            case INDEX_LINE_USER_LOGIN_RULE:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_login_rule));
                break;
            case INDEX_LINE_USER_LOGIN_INTERFACE:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_login_interface));
                break;
            case INDEX_LINE_IS_EXCLUDE_USER:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->is_exclude_user));
                break;
            case INDEX_LINE_IS_PASSWORD_EXPIRED:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->is_password_expired));
                break;
            default:
                break;
        }

        if (ret != RET_OK) {
            g_free(line_bak);
            return ret;
        }

        token = strsep(&tmp_line, ":");
    }
    g_free(line_bak);
    return RET_OK;
}

/*
 * Description: 从文本内容中读取到用户信息
 * @param: [in]  username ：目标用户名
 * @param: [in]  data     ：ipmi文本内容
 * @param: [out] ipmi_user：用于存储解析后的文本内容
 */
LOCAL gint32 get_user(const gchar *username, gchar *data, IPMI_USER_S *ipmi_user)
{
    gchar *tmp_line = NULL;
    gchar *line_bak = NULL;
    gchar *token    = NULL;

    /* 在记录权限的文件中，每行的数据格式如下:
    2:Administrator:x:1:5:0:1:1:1:0:0:4:x:0:0:0 */
    gchar *tmp_buf = strdup(data);
    if (tmp_buf == NULL) {
        return STRDUP_FAILED;
    }
    gchar *buf_bak = tmp_buf;
    gchar *line    = strsep(&tmp_buf, "\n");

    // 遍历每行数据，根据uid找到对应的数据行
    while (line && strlen(line) != 0) {
        // 将单行数据以":"拆分，获取单个字段，第二个字段是 username
        tmp_line = strdup(line);
        if (tmp_line == NULL) {
            g_free(buf_bak);
            return STRDUP_FAILED;
        }
        line_bak = tmp_line;
        token    = strsep(&tmp_line, ":");
        token    = strsep(&tmp_line, ":");
        // username不匹配，跳过
        if (strcmp(token, username) != 0) {
            g_free(line_bak);
            line = strsep(&tmp_buf, "\n");
            continue;
        }
        // id匹配，转换该行数据（该文件中不应有重复数据，所以当有匹配uid时解析结果即为最终结果，不用再解析后续行）
        gint32 ret = parse_line_to_struct(line, ipmi_user);
        g_free(buf_bak);
        g_free(line_bak);
        return ret;
    }

    g_free(buf_bak);
    // 未找到匹配，直接失败
    return USER_NOT_FOUND_IN_IPMI;
}

/*
 * Description: 从文件中获取ipmi_user结构
 * @param: [in]  username ：登录名
 * @param: [out] ipmi_user：用户各属性，校验使用
 */
LOCAL gint32 get_ipmi_user(const gchar *username, IPMI_USER_S *ipmi_user)
{
    gchar      *path = NULL;
    struct stat fileinfo;

    const gchar *tmp_user_name = strcmp(username, ACTUAL_ROOT_USER_NAME) == 0 ? RESERVED_ROOT_USER_NAME : username;

    // 校验权限文件路径
    if ((path = realpath(DEFAULT_PRIVILEGE_FILE, NULL)) == NULL) {
        return FILE_NOT_REAL_PATH;
    }

    gint32 imana_file_fd = open(path, O_RDONLY);
    g_free(path);
    if (imana_file_fd < 0) {
        return FILE_OPEN_FAILED;
    }

    gint32 ret = fstat(imana_file_fd, &fileinfo);
    if (ret) {
        close(imana_file_fd);
        return FILE_STAT_FAILED;
    }

    if (fileinfo.st_size == 0) {
        close(imana_file_fd);
        return FILE_SIZE_ZERO;
    }

    gchar *filebuf = (gchar *)g_malloc0(fileinfo.st_size + 1);
    if (!filebuf) {
        debug_log(DLOG_ERROR, "[uip user] g_malloc0 failed");
        close(imana_file_fd);
        return RET_ERR;
    }

    ret = read(imana_file_fd, filebuf, fileinfo.st_size);
    if (ret < 0) {
        close(imana_file_fd);
        g_free(filebuf);
        return FILE_READ_FAILED;
    }
    close(imana_file_fd);
    filebuf[fileinfo.st_size] = '\0';

    // 根据uid获取对应的用户信息
    ret = get_user(tmp_user_name, filebuf, ipmi_user);
    g_free(filebuf);

    return ret;
}

/*
 * Description: 检查用户使能
 * @param: [in] username：用户名
 * @param: [in] offset  ：登录接口偏移量
 * @return：使能状态
 */
guint32 uip_is_login_interface_enable(const gchar *username, guint32 offset)
{
    IPMI_USER_S ipmi_user = {0};

    // 空用户名，禁止
    if (username == NULL) {
        debug_log(DLOG_ERROR, "[uip user] invalid user name NULL");
        return LOGIN_INTERFACE_DISABLE;
    }

    // 如果offset超出范围，则默认开启
    if (offset >= USER_LOGIN_INTERFACE_MAX) {
        debug_log(DLOG_ERROR, "[uip user] interface offset %u", offset);
        return LOGIN_INTERFACE_ENABLE;
    }

    gint32 ret = get_ipmi_user(username, &ipmi_user);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "[uip user] get ipmi user failed, ret = %d", ret);
        return LOGIN_INTERFACE_DISABLE;
    }
    // 逃生用户登录接口不做限制
    guint32 login_interface =
        ipmi_user.is_exclude_user == 1 ? LOGIN_INTERFACE_ALL_ENABLE : ipmi_user.user_login_interface;

    return (login_interface & (1 << offset)) >> offset;
}

// 调用IAM认证函数

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
        debug_log(DLOG_ERROR, "[uip user] get dbus env failed, error is %s", err->message);
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

gint32 init_dbus_connection(void)
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
        debug_log(DLOG_ERROR, "[uip user] Open dbus session failed, Error name:%s, Error message:%s.", error.name,
                  error.message);
        dbus_error_free(&error);
        return RET_ERR;
    }

    dbus_connection_set_exit_on_disconnect(g_dbus_conn, FALSE);

    return RET_OK;
}

LOCAL void append_user_context(DBusMessage *call, const gchar *user_name, const gchar *ip, const gchar *interface)
{
    typedef struct {
        const char *key;
        const char *value;
    } DBUS_STRINF_MAP;
    DBUS_STRINF_MAP map[] = {{"Interface", interface}, {"UserName", user_name}, {"ClientAddr", ip}};

    gsize i, n = sizeof(map) / sizeof(map[0]);

    DBusMessageIter iter;
    DBusMessageIter dict_iter;
    DBusMessageIter entry_iter;
    dbus_message_iter_init_append(call, &iter);
    dbus_message_iter_open_container(&iter, DBUS_TYPE_ARRAY,
                                     DBUS_DICT_ENTRY_BEGIN_CHAR_AS_STRING DBUS_TYPE_STRING_AS_STRING
                                         DBUS_TYPE_STRING_AS_STRING DBUS_DICT_ENTRY_END_CHAR_AS_STRING,
                                     &dict_iter);

    for (i = 0; i < n; ++i) {
        dbus_message_iter_open_container(&dict_iter, DBUS_TYPE_DICT_ENTRY, NULL, &entry_iter);
        dbus_message_iter_append_basic(&entry_iter, DBUS_TYPE_STRING, &map[i].key);
        dbus_message_iter_append_basic(&entry_iter, DBUS_TYPE_STRING, &map[i].value);
        dbus_message_iter_close_container(&dict_iter, &entry_iter);
    }

    dbus_message_iter_close_container(&iter, &dict_iter);
}

LOCAL void parse_role_id(const gchar *value, LDAP_USER *user)
{
    gint32 count = 0;
    gchar value_cp[LDAP_USER_ROLE_ID_NUM * 2 + 1] = {0};
    gint32 ret = strncpy_s(value_cp, sizeof(value_cp), value, sizeof(value_cp) - 1);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", ret);
        return;
    }
    gchar *end = NULL;
    gchar *token = strtok_s(value_cp, ",", &end);
    while (token != NULL && count < LDAP_USER_ROLE_ID_NUM) {
        ret = sscanf_s(token, "%u", &(user->roleid[count]));
        if (ret <= 0) {
            debug_log(DLOG_ERROR, "%s: sscanf_s failed.", __FUNCTION__);
            return;
        }
        count++;
        token = strtok_s(NULL, ",", &end);
    }
}

LOCAL void parse_extra_data(DBusMessageIter args_iter, LDAP_USER *user)
{
    char *end_ptr = NULL;
    dbus_message_iter_next(&args_iter);
    gint32 param_type = dbus_message_iter_get_arg_type(&args_iter);
    if (param_type != DBUS_TYPE_ARRAY) {
        debug_log(DLOG_ERROR, "[uip user] get return param (extra data) type failed.");
        return;
    }
    DBusMessageIter sub_iter;
    dbus_message_iter_recurse(&args_iter, &sub_iter);
    while (dbus_message_iter_get_arg_type(&sub_iter) == DBUS_TYPE_DICT_ENTRY) {
        const gchar* key;
        const gchar *value;
        DBusMessageIter value_iter;
        dbus_message_iter_recurse(&sub_iter, &value_iter);
        param_type = dbus_message_iter_get_arg_type(&value_iter);
        dbus_message_iter_get_basic(&value_iter, &key);
        if (strcmp(key, "UserName") == 0) {
            dbus_message_iter_next(&value_iter);
            dbus_message_iter_get_basic(&value_iter, &value);
            gint32 ret = strcpy_s((gchar*)&user->username, LDAP_USER_NAME_LEN, value);
            if (ret != RET_OK) {
                debug_log(DLOG_ERROR, "[uip user] strcpy_s username failed, ret = %d", ret);
                break;
            }
        }
        if (strcmp(key, "ServerId") == 0) {
            dbus_message_iter_next(&value_iter);
            dbus_message_iter_get_basic(&value_iter, &value);
            user->serverid = strtol(value, &end_ptr, DECIMAL_NUM);
        }
        if (strcmp(key, "GroupId") == 0) {
            dbus_message_iter_next(&value_iter);
            dbus_message_iter_get_basic(&value_iter, &value);
            user->groupid = strtol(value, &end_ptr, DECIMAL_NUM);
        }
        if (strcmp(key, "RoleId") == 0) {
            dbus_message_iter_next(&value_iter);
            dbus_message_iter_get_basic(&value_iter, &value);
            // 解析RoleId到user->roleid中
            parse_role_id(value, user);
        }
        dbus_message_iter_next(&sub_iter);
    }
}

LOCAL gint32 auth_user(const gchar *user_name, const gchar *pw, const gchar *ip_addr, const gchar *interface,
                       LDAP_USER *user)
{
    DBusError       error;
    DBusMessageIter args_iter;

    // 获取iam认证接口
    DBusMessage *call =
        dbus_message_new_method_call(IAM_SERVICE, AUTHENTICATION_PATH, AUTHENTICATION_INTF, "Authenticate");
    if (call == NULL) {
        debug_log(DLOG_ERROR, "[uip user] Make new method call Authenticate failed.");
        return RET_ERR;
    }

    const char *domain = "RemoteAutoMatching";

    append_user_context(call, user_name, ip_addr, interface);

    if (dbus_message_append_args(call, DBUS_TYPE_STRING, &user_name, DBUS_TYPE_ARRAY, DBUS_TYPE_BYTE, &pw, strlen(pw),
                                 DBUS_TYPE_STRING, &domain, DBUS_TYPE_INVALID) == FALSE) {
        dbus_message_unref(call);
        debug_log(DLOG_ERROR, "[uip user] Append message failed.");
        return RET_ERR;
    }
    dbus_error_init(&error);
    DBusMessage *reply = dbus_connection_send_with_reply_and_block(g_dbus_conn, call, DBUS_CONNECTION_TIMEOUT, &error);
    dbus_message_unref(call);
    if (reply == NULL || dbus_error_is_set(&error)) {
        debug_log(DLOG_ERROR, "[uip user] Call method failed, Error name:%s, Error message:%s.", error.name,
                  error.message);
        dbus_error_free(&error);
        return RET_ERR;
    }

    // 拿到结果的迭代器
    dbus_message_iter_init(reply, &args_iter);
    // 迭代器 - 1，第一个参数的数据类型
    gint32 param_type = dbus_message_iter_get_arg_type(&args_iter);
    if (param_type != DBUS_TYPE_INT32) {
        dbus_message_unref(reply);
        debug_log(DLOG_ERROR, "[uip user] get return param (uid) type failed.");
        return RET_ERR;
    }
    // 迭代器 - 1，第一个参数的值
    dbus_message_iter_get_basic(&args_iter, &user->uid);
    // 迭代器 - 2
    dbus_message_iter_next(&args_iter);
    // 迭代器 - 3
    dbus_message_iter_next(&args_iter);

    // 迭代器 - 3，第三个参数的类型
    param_type = dbus_message_iter_get_arg_type(&args_iter);
    if (param_type != DBUS_TYPE_BYTE) {
        dbus_message_unref(reply);
        debug_log(DLOG_ERROR, "[uip user] get return param (role id) type failed.");
        return RET_ERR;
    }
    // 迭代器 - 3，第三个参数
    // v3使用roleid,存在第一位;privilege储存privilege适配openssh参数检查
    dbus_message_iter_get_basic(&args_iter, &user->roleid[0]);
    dbus_message_iter_get_basic(&args_iter, &user->privilege);
    parse_extra_data(args_iter, user);

    dbus_message_unref(reply);

    return RET_OK;
}

/**
 * Description : 调用dbus记录上次登录信息
 * params[in]  : user_id          登录用户ID
 * params[in]  : ip_addr          登录IP
 * params[in]  : login_interface  登录接口
 * return      : 返回码
 */
LOCAL gint32 set_last_login_info(gint32 user_id, gchar *user_name, const gchar *ip_addr, const gchar *login_interface)
{
    gchar account_path[BUFF_LEN] = {0};
    gint32 ret = sprintf_s(account_path, sizeof(account_path), "%s%d", ACCOUNT_PATH, user_id);
    if (ret <= 0) {
        debug_log(DLOG_ERROR, "[uip user] sprintf_s failed, ret = %d", ret);
        return RET_ERR;
    }

    // 获取SetLastLogin接口
    DBusMessage *call = dbus_message_new_method_call(ACCOUNT_SERVICE, account_path, ACCOUNT_INTF, "SetLastLogin");
    if (call == NULL) {
        debug_log(DLOG_ERROR, "[uip user] Make new method call SetLastLogin failed.");
        return RET_ERR;
    }

    // 追加上下文信息
    append_user_context(call, user_name, ip_addr, login_interface);

    // 追加参数
    if (dbus_message_append_args(call, DBUS_TYPE_STRING, &ip_addr, DBUS_TYPE_STRING, &login_interface,
                                 DBUS_TYPE_INVALID) == FALSE) {
        dbus_message_unref(call);
        debug_log(DLOG_ERROR, "[uip user] Append message failed.");
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
    DBusMessageIter args_iter;
    dbus_message_iter_init(reply, &args_iter);
    // 从迭代器中获取返回结果
    gint32 param_type = dbus_message_iter_get_arg_type(&args_iter);
    if (param_type != DBUS_TYPE_BYTE) {
        dbus_message_unref(reply);
        debug_log(DLOG_ERROR, "[uip user] get return param (result) type failed.");
        return RET_ERR;
    }
    gint32 result = RET_OK;
    dbus_message_iter_get_basic(&args_iter, &result);
    // 对消息通道解引用
    dbus_message_unref(reply);
    return result;
}

/*
 * Description  : 调用AuthUser认证LDAP用户, 返回权限、服务器id、组id、域名等信息
 */

gint32 uip_auth_ldap_user(const gchar *user_name, const gchar *pw, const gchar *ip_addr, const gchar *interface,
                          LDAP_USER *user)
{
    if ((NULL == user_name) || (NULL == pw) || (NULL == ip_addr)) {
        return RET_ERR;
    }
    if (user == NULL) {
        return RET_ERR;
    }

    // 初始化DBus连接
    gint32 ret = init_dbus_connection();
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "[uip user]init DBus failed, ret: %d", ret);
        return ret;
    }

    return auth_user(user_name, pw, ip_addr, interface, user);
}

/*
 * Description  : 分配命令行LDAP用户的UID，循环使用，不重复
 */
gint32 uip_alloc_ldap_uid()
{
    gint32    handle      = 0;
    gint32    ret         = RET_OK;
    FILE     *fp          = NULL;
    guint32   n           = 0;
    LDAP_USER usr         = {0};
    guint32   file_length = 0;
    guint32   i           = 0;
    gint32    r           = 0;

    // 如果文件不存在，则创建文件，否则只打开文件
    struct stat stmp;

    if (stat_s(LDAP_USER_FILE, &stmp) < 0) {
        fp = fopen_s(LDAP_USER_FILE, "w+", LDAP_USER_FILE);
    } else {
        fp = fopen_s(LDAP_USER_FILE, "r+", LDAP_USER_FILE);
    }

    if (fp == NULL) {
        return RET_ERR;
    }

    handle = fileno(fp);
    (void)fchmod(handle, 0644);  // 修改权限为644

    // 文件加锁，防止多进程操作出错
    (void)flock(handle, LOCK_EX);

    // 读取
    (void)fseek(fp, 0, SEEK_END);
    file_length = ftell(fp);
    (void)fseek(fp, 0, SEEK_SET);

    for (i = 0; i < file_length / sizeof(LDAP_USER); i++) {
        r = fread((void *)&usr, sizeof(usr), 1, fp);
        if (r != 1) {
            break;
        }
        if (usr.used == 0) {  // 这个slot空闲
            break;
        }
        n++;
    }

    if (n >= LDAP_USER_MAX_COUNT) {  // 不允许超过32个用户
        ret = RET_ERR;
    } else {
        // 占用当前slot
        usr.used = 1;
        usr.uid  = LDAP_USER_ID_BASE + n;
        ret      = LDAP_USER_ID_BASE + n;
        (void)fseek(fp, sizeof(LDAP_USER) * (n), SEEK_SET);
        if (fwrite(&usr, sizeof(usr), 1, fp) != 1) {
            ret = RET_ERR;
        }
    }

    (void)flock(handle, LOCK_UN);
    (void)fclose(fp);
    return ret;
}

/*
 * Description  : 从文件读取对应UID LDAP用户的信息
 */
gint32 uip_read_ldap_user(gint32 uid, LDAP_USER *usr)
{
    gint32 handle = 0;
    gint32 ret    = RET_OK;
    FILE  *fp     = NULL;

    if ((NULL == usr) || (uid < LDAP_USER_ID_BASE)) {
        return RET_ERR;
    }

    fp = fopen_s(LDAP_USER_FILE, "r", LDAP_USER_FILE);
    if (NULL == fp) {
        return RET_ERR;
    }

    handle = fileno(fp);

    (void)flock(handle, LOCK_EX);

    // 根据uid来索引
    if (-1 == fseek(fp, sizeof(LDAP_USER) * (uid - LDAP_USER_ID_BASE), SEEK_SET)) {
        ret = RET_ERR;
    } else {
        if (fread(usr, sizeof(LDAP_USER), 1, fp) != 1) {
            ret = RET_ERR;
        }
    }

    (void)flock(handle, LOCK_UN);
    (void)fclose(fp);
    return ret;
}

/*
 * Description  : 刷新对应UID LDAP用户的信息
 */
gint32 uip_renew_ldap_user(LDAP_USER *usr)
{
    gint32 handle = 0;
    gint32 ret    = RET_OK;
    FILE  *fp     = NULL;

    if ((NULL == usr) || (usr->uid < LDAP_USER_ID_BASE)) {
        return RET_ERR;
    }

    fp = fopen_s(LDAP_USER_FILE, "r+", LDAP_USER_FILE);
    if (NULL == fp) {
        return RET_ERR;
    }

    handle = fileno(fp);

    (void)flock(handle, LOCK_EX);

    if (fseek(fp, sizeof(LDAP_USER) * (usr->uid - LDAP_USER_ID_BASE), SEEK_SET) == -1) {
        ret = RET_ERR;
    } else {
        if (fwrite(usr, sizeof(LDAP_USER), 1, fp) != 1) {
            ret = RET_ERR;
        }
    }

    (void)flock(handle, LOCK_UN);
    (void)fclose(fp);
    return ret;
}

static DBusMessage *get_msg_from_mdb(const gchar *destination,
    const gchar *path, const gchar *interface, const gchar *property_name)
{
    DBusError error;
    DBusMessage *call = NULL;
    DBusMessage *reply = NULL;

    call = dbus_message_new_method_call(destination, path, "org.freedesktop.DBus.Properties", "Get");
    if (call == NULL) {
        debug_log(DLOG_ERROR, "Make new method call failed\r\n");
        return NULL;
    }

    if (dbus_message_append_args(call, DBUS_TYPE_STRING, &interface, DBUS_TYPE_STRING, &property_name,
                                 DBUS_TYPE_INVALID) == FALSE) {
        dbus_message_unref(call);
        debug_log(DLOG_ERROR, "Append message failed\r\n");
        return NULL;
    }

    dbus_error_init(&error);
    reply = dbus_connection_send_with_reply_and_block(g_dbus_conn, call, DBUS_CONNECTION_TIMEOUT, &error);
    dbus_message_unref(call);
    if (reply == NULL || dbus_error_is_set(&error)) {
        debug_log(DLOG_ERROR, "Call method failed, Error name:%s, Error message:%s\r\n", error.name, error.message);
        if (dbus_error_is_set(&error)) {
            dbus_error_free(&error);
        }
    }
    return reply;
}

/*
 * Description: 从资源树获取字符串数组
 */
static gint32 get_property_value_string_array(const gchar *destination, const gchar *path, const gchar *interface,
    const gchar *property_name, gchar *out_val[], gsize out_len)
{
    DBusMessageIter args_iter = {0};
    DBusMessageIter sub_iter = {0};
    DBusMessage *reply = NULL;
    guint32 reply_count = 0;

    if (out_val == NULL) {
        debug_log(DLOG_ERROR, "Get property failed.");
        return RET_ERR;
    }
    reply = get_msg_from_mdb(destination, path, interface, property_name);
    if (reply == NULL) {
        debug_log(DLOG_ERROR, "Get property from mdb failed.");
        return RET_ERR;
    }
    dbus_message_iter_init(reply, &args_iter);
    dbus_message_iter_recurse(&args_iter, &sub_iter);
    reply_count = dbus_message_iter_get_element_count(&sub_iter);
    memset_s(&args_iter, sizeof(args_iter), 0, sizeof(args_iter));
    dbus_message_iter_recurse(&sub_iter, &args_iter);
    for (guint32 i = 0; i < reply_count && i < out_len; i++) {
        gchar *priv = NULL;
        dbus_message_iter_get_basic(&args_iter, &priv);
        dbus_message_iter_next(&args_iter);
        if (priv != NULL) {
            out_val[i] = strdup(priv);
        }
    }
    dbus_message_unref(reply);
    return RET_OK;
}

static gint32 convert_login_rule_ids_str_to_num(gchar *rules[], gint32 size)
{
    gint32 result = 0;
    // rule id 按位表示
    for (gint32 i = 0; i < size; i++) {
        if (rules[i] == NULL) {
            continue;
        } else if (strcmp(rules[i], "Rule1") == 0) {
            result += 1;
        } else if (strcmp(rules[i], "Rule2") == 0) {
            result += 2;
        } else if (strcmp(rules[i], "Rule3") == 0) {
            result += 4;
        } else {
            debug_log(DLOG_ERROR, "invalid login rule valueL:%s\r\n", rules[i]);
        }
    }
    return result;
}

/**
 * Description : 校验登录规则是否满足（基于本地文件系统）
 * params[in]  : type      用户类型
 * params[in]  : user_name 待校验的用户名（考虑到第三方调用者可能无法获取用户ID）
 * params[in]  : ip_addr   登录IP
 * return      : [boolean] 校验结果
 */
gint32 uip_check_login_rule(guint32 type, gchar *user_name, const gchar *ip_addr)
{
    switch (type) {
        case USER_TYPE_LOCAL: {
            IPMI_USER_S ipmi_user = {0};

            gint32 ret = get_ipmi_user(user_name, &ipmi_user);
            if (ret != RET_OK) {
                debug_log(DLOG_ERROR, "[uip user] get ipmi user failed, ret = %d", ret);
                return RET_ERR;
            }

            // 校验用户登录规则
            ret = check_user_login_rule(&ipmi_user, ip_addr, OTHER_NAME);
            if (ret != RET_OK) {
                debug_log(DLOG_ERROR, "[uip user] Account(%s) is restricted by login rules", user_name);
                return ret;
            }
            break;
        }
        case USER_TYPE_SNMPV1V2C: {
            // 初始化DBus连接
            gint32 ret = init_dbus_connection();
            if (ret != RET_OK || g_dbus_conn == NULL) {
                debug_log(DLOG_ERROR, "[uip user] init DBus failed, ret: %d", ret);
                return RET_ERR;
            }
            gchar *rules[MAX_RULE_COUNT]    = {NULL};
            ret = get_property_value_string_array(ACCOUNT_SERVICE, SNMP_PATH, ACCOUNT_INTF,
                "LoginRuleIds", rules, MAX_RULE_COUNT);
            if (ret != RET_OK) {
                debug_log(DLOG_ERROR, "[uip user] get property value string array failed");
                return RET_ERR;
            }
            gint32 ruleids = convert_login_rule_ids_str_to_num(rules, MAX_RULE_COUNT);
            for (int i = 0; i < MAX_RULE_COUNT; i++) {
                if (rules[i] != NULL) {
                    free(rules[i]);
                }
            }
            return check_snmpv1v2_login_rule(ruleids, ip_addr);
        }
        case USER_TYPE_LDAP:
        default:
            debug_log(DLOG_ERROR, "[uip user] invalid account type:%d", type);
            return RET_ERR;
    }

    return RET_OK;
}

/**
 * Description : 记录上次登录信息
 * params[in]  : user_name        登录用户名（考虑到第三方调用者可能无法获取用户ID）
 * params[in]  : ip_addr          登录IP
 * params[in]  : login_interface  登录接口
 */
gint32 uip_record_login_info(gchar *user_name, const gchar *ip_addr, const gchar *login_interface)
{
    if (user_name == NULL || ip_addr == NULL || login_interface == NULL) {
        debug_log(DLOG_ERROR, "[uip user] invalid parameters");
        return RET_ERR;
    }

    if (strlen(user_name) == 0 || strlen(ip_addr) == 0 || strlen(login_interface) == 0) {
        debug_log(DLOG_ERROR, "[uip user] invalid parameters");
        return RET_ERR;
    }

    // 从/etc/passwd获取uid/gid的时，root用户名转换为<root>去获取
    gchar *tmp_user_name = strcmp(user_name, ACTUAL_ROOT_USER_NAME) == 0 ? RESERVED_ROOT_USER_NAME : user_name;

    // 初始化DBus连接
    gint32 ret = init_dbus_connection();
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "[uip user] init DBus failed, ret: %d", ret);
        return RET_ERR;
    }

    uid_t uid = 0;
    uid_t gid = 0;
    // 调用记录接口
    ret = get_uid_gid_by_name(tmp_user_name, &uid, &gid);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "[uip user] get_uid_gid_by_name failed");
        return RET_ERR;
    }

    // 若不是ipmi文件中存在的本地用户，则失败
    if (!check_uid_is_local_user(uid)) {
        return RET_ERR;
    } else { // 若是ipmi文件中存在的本地用户，获取bmc业务id
        uid -= IMANA_UID_BASE;
    }

    return set_last_login_info((gint32)uid, tmp_user_name, ip_addr, login_interface);
}

/**
 * Description : 获取当前LocalAccountAuth的值
 *               注意：out_val需要由调用者进行释放
 */
gint32 uip_get_local_account_auth_mode(gchar **out_val)
{
    if (out_val == NULL) {
        debug_log(DLOG_ERROR, "[uip user] invalid parameter, out_val is NULL");
        return RET_ERR;
    }
    // 初始化DBus连接
    gint32 ret = init_dbus_connection();
    if (ret != RET_OK || g_dbus_conn == NULL) {
        debug_log(DLOG_ERROR, "[uip user] init DBus failed, ret: %d", ret);
        return RET_ERR;
    }

    // 获取Get接口
    DBusMessage *call = dbus_message_new_method_call(IAM_SERVICE, AUTHENTICATION_PATH, PROPERTIES_INTF, "Get");
    if (call == NULL) {
        debug_log(DLOG_ERROR, "[uip user] Make new method call Get failed.");
        return RET_ERR;
    }

    const gchar *interface = AUTHENTICATION_INTF;
    const gchar *property_name = "LocalAccountAuth";

    // 追加参数
    if (dbus_message_append_args(call, DBUS_TYPE_STRING, &interface, DBUS_TYPE_STRING, &property_name,
                                 DBUS_TYPE_INVALID) == FALSE) {
        dbus_message_unref(call);
        debug_log(DLOG_ERROR, "[uip user] Append message failed.");
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
    DBusMessageIter args_iter = {0};
    DBusMessageIter sub_iter  = {0};
    dbus_message_iter_init(reply, &args_iter);
    dbus_message_iter_recurse(&args_iter, &sub_iter);
    // 从迭代器中获取返回结果
    if (dbus_message_iter_get_arg_type(&sub_iter) != DBUS_TYPE_STRING) {
        dbus_message_unref(reply);
        debug_log(DLOG_ERROR, "[uip user] get return param (result) type failed.");
        return RET_ERR;
    }
    
    gchar *value = ""; /* 由dbus_message_unref释放 */
    dbus_message_iter_get_basic(&sub_iter, &value);
    *out_val = g_strdup(value);
    // 对消息通道解引用
    dbus_message_unref(reply);
    return RET_OK;
}