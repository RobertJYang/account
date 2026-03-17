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
 * Create: 2023-05-25
 */

#ifndef COMMON_H
#define COMMON_H

#include <netinet/in.h>
#include "stdio.h"
#include "fcntl.h"
#include "sys/time.h"
#include "sys/resource.h"
#include "secure/securec.h"
#include "glib.h"
#include "syslog.h"
#include "logging.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#ifndef LOCAL
#define LOCAL static
#endif

/* 通用状态码 */
#define RET_OK                  0
#define RET_ERR                 (-1)
#define USER_LOGIN_LIMITED      0x90 /* 登录受限 */

/* 登录设备 */
#define FTP_NAME    "ftp"        // ftp
#define SSH_NAME    "ssh"        // ssh
#define TELNET_NAME "/dev/pts"   // telnet
#define UART2_NAME  "/dev/ttyS0" // 串口
#define OTHER_NAME  "OTHER"      // 提供给一些第三方用，主要为了表明需要校验登录规则

/* BMC业务用户uid相关：系统用户0-99 自定义用户5xx */
#define INVAILD_UID 1000
#define IMANA_UID_BASE 500
#define IMANA_UID_MIN 1
#define IMANA_UID_MAX 17
#define INTER_CHASSIS_UID 23
#define OEM_UID_MIN 101
#define OEM_UID_MAX 115
#define IMANNA_ROOT_UID 2

/* 参数 */
#define BUFF_LEN             128
#define MAX_BUFF_SIZE        4096
#define USER_NAME_MAX_LEN    16   // 不带结束符的用户名最大长度
#define SMALL_BUFFER_SIZE    256
#define BUFFER_SIZE          1024
#define IF_BUFFER_SIZE       2048
#define USER_CHANNEL_MAX_NUM 2    // 最大支持的通道数

/* 转码 */
#define BINARY_NUM              2
#define DECIMAL_NUM             10
#define HEX_NUM                 16

#define IAM_SERVICE                    "bmc.kepler.iam"
#define ACCOUNT_SERVICE                "bmc.kepler.account"
#define AUTHENTICATION_PATH            "/bmc/kepler/AccountService/Authentication"
#define AUTHENTICATION_INTF            "bmc.kepler.AccountService.Authentication"
#define PROPERTIES_INTF                "org.freedesktop.DBus.Properties"
#define PROPERTY_LOCKOUT_DURATION      "AccountLockoutDuration"
#define PROPERTY_LOCKOUT_THRESHOLD     "AccountLockoutThreshold"
#define PROPERTY_LOCKOUT_TIME_INTERVAL "AccountLockoutCounterResetAfter"

/* 结构体 */
// ipmi用户结构
typedef struct {
    guint8 user_id;                                 /* 用户ID */
    gchar user_name[USER_NAME_MAX_LEN + 1];         /* 用户名 */
    gchar pass_word[SMALL_BUFFER_SIZE];             /* 用户密码(AES) */
    guint8 is_20bytes_passwd;                       /* 密码长度，是16还是20字节 */
    guint8 max_session_num;                         /* 用户能够支持的最大会话数 */
    guint8 callin_enabled;                          /* 是否支持CALLIN */
    guint8 user_enabled;                            /* 用户使能状态 */
    guint8 auth_enabled;                            /* 用户是否参与认证 */
    guint8 ipmi_msg_enabled;                        /* 用户是否支持IPMI Message */
    guint8 is_enable_by_passwd;                     /* 用户是否可通过密码激活 */
    guint8 privilege[USER_CHANNEL_MAX_NUM];         /* 用户在各个ipmi通道上的权限 */
    gchar snmp_privacy_password[SMALL_BUFFER_SIZE]; /* 用户SNMP加密密码(AES) */
    guint8 user_lock_status;                        /* 用户锁定状态 */
    guint8 user_login_rule;                         /* 用户开登录规则 */
    guint8 user_login_interface;                    /* 用户登录接口 */
    guint8 is_exclude_user;                         /* 是否使能用户标志 */
    guint8 is_password_expired;                     /* 密码是否过期 */
} IPMI_USER_S;

/* 对外接口 */
gint32 parse_line_token_to_uint8(gchar *data, guint8 *target);
gint32 get_localtime_r(const time_t *p_time_stamp, struct tm *p_tm);
gint32 get_uid_gid_by_name(const gchar *user_name, uid_t *uid, uid_t *gid);
gint32 check_uid_is_local_user(uid_t uid);
// 判断ipv4地址是否在子网中
gint32 is_ip_in_subnet(const gchar *ip_str, const gchar *subnet_str);
// 判断ipv6地址是否在子网中
gint32 is_ipv6_in_subnet(const gchar *ip_str, const gchar *subnet_str);
#ifndef G_ENABLE_TEST
gint32 dbus_get_auth_lockout_conf(gint32 *duration, gint32 *threshold, gint32 *time_interval);
#endif // G_ENABLE_TEST

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // COMMON_H