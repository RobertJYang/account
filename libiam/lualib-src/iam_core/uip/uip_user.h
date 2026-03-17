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

#ifndef UIP_USER_H
#define UIP_USER_H

#include <dbus/dbus.h>
#include "glib.h"
#include "stdio.h"
#include "secure/securec.h"
#include "syslog.h"
#include "logging.h"
#include "fcntl.h"
#include "unistd.h"
#include "errno.h"
#include "sys/types.h"
#include "sys/stat.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#ifndef LOCAL
#define LOCAL static
#endif

#define IAM_SERVICE         "bmc.kepler.iam"
#define ACCOUNT_SERVICE     "bmc.kepler.account"
#define AUTHENTICATION_PATH "/bmc/kepler/AccountService/Authentication"
#define AUTHENTICATION_INTF "bmc.kepler.AccountService.Authentication"
#define ACCOUNT_PATH        "/bmc/kepler/AccountService/Accounts/"
#define SNMP_PATH           "/bmc/kepler/AccountService/Accounts/20"
#define ACCOUNT_INTF        "bmc.kepler.AccountService.ManagerAccount"
#define PROPERTIES_INTF     "org.freedesktop.DBus.Properties"

/* *****************通用状态码****************** */
#define DISABLED                   0
#define ENABLED                    1
#define USER_UNLOCK                0
#define USER_LOCK                  1
#define PASSWD_NOT_EXPIRED         0
#define PASSWD_IS_EXPIRED          1
#define LOGIN_INTERFACE_DISABLE    0
#define LOGIN_INTERFACE_ENABLE     1
#define LOGIN_INTERFACE_ALL_ENABLE 0xFFFFFFFF // 所有接口都支持, 逃生用户专用
#define RET_OK                     0
#define RET_ERR                    (-1)

#define USER_NOT_FOUND_IN_IPMI     1
#define FILE_NOT_REAL_PATH         2
#define FILE_OPEN_FAILED           3
#define FILE_STAT_FAILED           4
#define FILE_SIZE_ZERO             5
#define FILE_READ_FAILED           6
#define TOKEN_TOO_LONG             7
#define INVALID_STRING_TO_NUMBER   8
#define STRDUP_FAILED              9

#define RESERVED_ROOT_USER_NAME "<root>"
#define ACTUAL_ROOT_USER_NAME   "root"

/* **************用户登陆接口编号*************** */
#define USER_LOGIN_INTERFACE_WEB_OFFSET     0
#define USER_LOGIN_INTERFACE_SNMP_OFFSET    1
#define USER_LOGIN_INTERFACE_IPMI_OFFSET    2
#define USER_LOGIN_INTERFACE_SSH_OFFSET     3
#define USER_LOGIN_INTERFACE_SFTP_OFFSET    4
#define USER_LOGIN_INTERFACE_TELNET_OFFSET  5
#define USER_LOGIN_INTERFACE_LOCAL_OFFSET   6
#define USER_LOGIN_INTERFACE_REDFISH_OFFSET 7
#define USER_LOGIN_INTERFACE_MAX            8

/* **************用户权限管理文件*************** */
#define DEFAULT_PRIVILEGE_FILE      "/data/trust/ipmi"
#define DEFAULT_PRIVILEGE_FILE_NAME "ipmi"

/* ************用户权限管理文件解析************* */
#define TOKENS_PER_LINE                 18 // 每行被:隔开的字段个数，共18个字段
#define INDEX_LINE_UID                  1  // 每行数据中第1 个字段为 用户id
#define INDEX_LINE_USER                 2  // 每行数据中第2 个字段为 用户名
#define INDEX_LINE_PASSWORD             3  // 每行数据中第3 个字段为 用户密码，屏蔽为'x'标识
#define INDEX_LINE_IS_20BYTES_PASSWD    4  // 每行数据中第4 个字段为 是否使用20位密码标志
#define INDEX_LINE_MAX_SESSION_NUM      5  // 每行数据中第5 个字段为 最大会话数
#define INDEX_LINE_IS_CALLIN            6  // 每行数据中第6 个字段为 是否支持CALLIN标志
#define INDEX_LINE_USER_ENABLE          7  // 每行数据中第7 个字段为 用户使能状态标志
#define INDEX_LINE_USER_AUTH_ENABLE     8  // 每行数据中第8 个字段为 用户是否支持认证标志
#define INDEX_LINE_IPMI_MSG_ENABLE      9  // 每行数据中第9 个字段为 是否支持ipmi msg标志
#define INDEX_LINE_IS_ENABLE_BY_PASSWD  10 // 每行数据中第10个字段为 用户是否可通过密码激活标志
#define INDEX_LINE_USER_PRIVILEGE_0     11 // 每行数据中第11个字段为 用户通道0权限（使用未知）
#define INDEX_LINE_USER_PRIVILEGE_1     12 // 每行数据中第12个字段为 用户通道1权限（目前看权限都用的这个）
#define INDEX_LINE_SNMP_PASSWORD        13 // 每行数据中第13个字段为 SNMP加密密码，屏蔽为'x'标识
#define INDEX_LINE_USER_LOCK_STATE      14 // 每行数据中第14个字段为 用户锁定状态标志
#define INDEX_LINE_USER_LOGIN_RULE      15 // 每行数据中第15个字段为 用户登录规则（串口/FTP不校验）
#define INDEX_LINE_USER_LOGIN_INTERFACE 16 // 每行数据中第16个字段为 用户登录接口
#define INDEX_LINE_IS_EXCLUDE_USER      17 // 每行数据中第17个字段为 是否逃生用户
#define INDEX_LINE_IS_PASSWORD_EXPIRED  18 // 每行数据中第18个字段为 密码是否过期

/* ******************其它参数******************* */
#define USER_NAME_MAX_LEN    16   // 不带结束符的用户名最大长度
#define SMALL_BUFFER_SIZE    256
#define USER_CHANNEL_MAX_NUM 2    // 最大支持的通道数

#define USER_TYPE_LOCAL 0       // 本地用户类型
#define USER_TYPE_LDAP 1        // LDAP用户类型
#define USER_TYPE_SNMPV1V2C 2   // SNMPV1/V2类型

/* ******************对外接口******************* */

// LDAP配置
#define LDAP_USER_FILE        "/dev/shm/uip_ldap_users"
#define LDAP_USER_ROLE_ID_NUM 32
#define LDAP_USER_NAME_LEN    300
#define LDAP_USER_FROM_IP     128

typedef struct LDAP_USER {
    guint8 used;  // 0 未使用; 1 已使用
    gint32 uid;
    gchar  username[LDAP_USER_NAME_LEN];
    gchar  fromip[LDAP_USER_FROM_IP];
    guint8 serverid;
    guint8 groupid;
    guint8 privilege;
    guint8 roleid[LDAP_USER_ROLE_ID_NUM];
} LDAP_USER;

guint32 uip_is_login_interface_enable(const gchar *username, guint32 offset);

// LDAP用户登录
/*
 * Description : v3支持认证，支持登录接口认证
 */
gint32 uip_auth_ldap_user(const gchar *user_name, const gchar *pw, const gchar *ip_addr, const gchar *interface,
                          LDAP_USER *user);
gint32 uip_alloc_ldap_uid(void);
gint32 uip_read_ldap_user(gint32 uid, LDAP_USER *usr);
gint32 uip_renew_ldap_user(LDAP_USER *usr);
gint32 uip_check_login_rule(guint32 type, gchar *user_name, const gchar *ip_addr);
gint32 uip_record_login_info(gchar *user_name, const gchar *ip_addr, const gchar *login_interface);
gint32 init_dbus_connection(void);
gint32 uip_get_local_account_auth_mode(gchar **out_val);
gint32 uip_get_privilege(const gchar* user_name, guchar* user_privilege);
gboolean uip_get_user_is_lock_by_username(const gchar *dir, const gchar *username);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // UIP_USER_H