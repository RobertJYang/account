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