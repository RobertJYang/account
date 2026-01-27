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
 * Create: 2026-01-26
 */

#ifndef __IP_LOCK_H__
#define __IP_LOCK_H__

#include "common.h"

#define MAX_IP_LENGTH   64
#define MAX_NAME_LENGTH 64
#define MAX_RECORD_CNT  10

#define SNMPD_USER_GROUP 95
#define SECBOX_UID       104

#if defined(ENABLE_TEST)
#define IP_UNLOCK_TIME 5
#else
#define IP_UNLOCK_TIME 30
#endif

typedef struct ip_fail_record {
    gchar   record_name[MAX_NAME_LENGTH];
    guint64 timestamp;
} IpFailRecord;

typedef struct ip_lock_status {
    gchar    ip[MAX_IP_LENGTH];
    gboolean lock_status;
    guint64  lock_start_time;
} IpLockStatus;

typedef struct ip_all_status {
    guint32      count;
    IpLockStatus *records;
} IpAllStatus;

gint32 increase_fail_record(const gchar *dir, const gchar *ip);
gint32 clean_fail_record(const gchar *dir, const gchar *ip);
gint32 get_one_lock_status(const gchar *dir, const gchar *ip, guint8 lock_threshold, guint64 fail_interval,
    IpLockStatus *status);
gint32 get_all_lock_status(const gchar *dir, guint8 lock_threshold, guint64 fail_interval, IpAllStatus *records);

#endif // __IP_LOCK_H__