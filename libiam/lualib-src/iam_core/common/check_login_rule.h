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

#ifndef CHECK_LOGIN_RULE_H
#define CHECK_LOGIN_RULE_H

#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/* 登录规则配置文件 */
#define LOGINRULE_FILE         "/dev/shm/loginrules"

/* 登录规则文本解析 */
#define RULE_LINE_ID      1 // 每行数据中第1个字段为 规则id
#define RULE_LINE_ENABLED 2 // 每行数据中第2个字段为 规则使能
#define RULE_LINE_TIME    3 // 每行数据中第3个字段为 时间规则
#define RULE_LINE_IP      4 // 每行数据中第4个字段为 ip规则
#define RULE_LINE_MAC     5 // 每行数据中第5个字段为 mac规则
#define RULE_LINE_IPV6    6 // 每行数据中第6个字段为 ipv6规则

/* 时间规则长度 */
#define YMDHM_TIME_RULE_LEN 33 // yyyy-MM-dd HH:mm:ss/yyyy-MM-dd HH:mm:ss
#define YMD_TIME_RULE_LEN   21 // yyyy-MM-dd/yyyy-MM-dd
#define HM_TIME_RULE_LEN    11 // HH:mm/HH:mm

/* 其它参数 */
#define MAX_RULE_COUNT       3    // 最多支持3条登录规则
#define MAX_RULE_VALUE       7    // 最大支持登录规则 1+2+4=7
#define MAX_RULE_LEN         64   // 每条规则最大长度
#define MAX_RULE_LINE_LEN ((MAX_RULE_LEN * 4) + 3) // 每一行规则最大长度
#define TIME_YEAR_BASE       1900 // 年份base为1900年
#define MACADDRESS_LEN       64   // mac最大长度

/* 枚举类 */
typedef enum RULE_TYPE {
    TIME_RULE = 0, // 时间限制规则
    IP_RULE,       // IP限制规则
    MAC_RULE,      // MAC地址限制规则
} RULE_TYPE;

typedef enum TIME_TYPE {
    TYPE_YMDHM = 0, // 时间格式为 YMDHM/YMDHM
    TYPE_YMD,       // 时间格式为 YMD
    TYPE_HM,        // 时间格式为 HM
} TIME_TYPE;

/* 结构体 */
// 登录规则结构
typedef struct {
    guint8 rule_id;                    // 规则ID
    guint8 rule_enabled;               // 规则状态
    gchar time_rule[MAX_RULE_LEN + 1]; // 时间规则
    gchar ip_rule[MAX_RULE_LEN + 1];   // ip规则
    gchar mac_rule[MAX_RULE_LEN + 1];  // mac规则
    gchar ipv6_rule[MAX_RULE_LEN + 1]; // ipv6规则
} LOGIN_RULE_INFO;


// 时间规则类
typedef struct {
    guint16 tm_year;
    guchar tm_mon;
    guchar tm_mday;
    guchar tm_hour;
    guchar tm_min;
} TIME_INFO;

typedef struct {
    TIME_INFO start_time;
    TIME_INFO end_time;
} TIME_RULE_INFO;

/* 提供对外接口 */
gint32 check_user_login_rule(IPMI_USER_S *ipmi_user, const gchar *ip_addr, const gchar *tty_name);
gint32 check_snmpv1v2_login_rule(gint32 ruleids, const gchar *ip_addr);

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // CHECK_LOGIN_RULE_H