
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

#ifndef PAM_BMC_LOGIN_H
#define PAM_BMC_LOGIN_H

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/* 参数解析错误码 */
#define PHASE_UNKNOWN 0
#define PHASE_AUTH    1
#define PHASE_ACCOUNT 2
#define PHASE_SESSION 3

/* 执行动作码 */
#define OPT_FAIL_ON_ERROR 1
#define OPT_QUIET         2

#define ACTUAL_ROOT_USER_NAME   "root"
#define RESERVED_ROOT_USER_NAME "<root>"

/* 用户权限 */
#define USER_PRIVILEGE_CALLBACK 1
#define USER_PRIVILEGE_GENERAL  2
#define USER_PRIVILEGE_ADMIN    4

/* 用户权限管理文件 */
#define DEFAULT_PRIVILEGE_FILE "/data/trust/ipmi"

/* 用户权限管理文件解析 */
#define TOKENS_PER_LINE                 17 // 每行被:隔开的字段个数，共17个字段
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

/* 用户登陆接口编号 */
#define LOGIN_INTERFACE_WEB_OFFSET     0
#define LOGIN_INTERFACE_SNMP_OFFSET    1
#define LOGIN_INTERFACE_IPMI_OFFSET    2
#define LOGIN_INTERFACE_SSH_OFFSET     3
#define LOGIN_INTERFACE_SFTP_OFFSET    4
#define LOGIN_INTERFACE_TELNET_OFFSET  5
#define LOGIN_INTERFACE_LOCAL_OFFSET   6
#define LOGIN_INTERFACE_REDFISH_OFFSET 7
#define LOGIN_INTERFACE_MAX            8

/* 结构体 */
// ipmi操作结构
typedef struct {
    const gchar *filename; // 记录用户权限的文件的路径
    guint32 ctrl;
} IMANA_OPTIONS;

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // PAM_BMC_LOGIN_H