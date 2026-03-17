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
 * Create: 2026-02-09
 */

#ifndef __IP_LOCK_H__
#define __IP_LOCK_H__

#include "../common/common.h"

#define MAX_IP_LENGTH     64
#define MAX_NAME_LENGTH   64
#define MAX_IP_RECORD_CNT 1000 // 最大支持记录1000个ip的信息
#define MAX_RECORD_CNT    100  // 最大支持每个ip有100条记录

#define SNMPD_USER_GROUP 95
#define SECBOX_UID       104

#define DO_CHECK 1
#define NO_CHECK 0

#define DEFAULT_RECORD_DIR "/dev/shm/ip_lock"
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

gint32 increase_fail_record(const gchar *dir, const gchar *ip, guint8 is_check_lock);
gint32 clean_fail_record(const gchar *dir, const gchar *ip);
gint32 get_one_lock_status(const gchar *dir, const gchar *ip, guint8 lock_threshold, guint64 fail_interval,
    guint64 unlock_time, IpLockStatus *status);
gint32 get_all_lock_status(const gchar *dir, guint8 lock_threshold, guint64 fail_interval, guint64 unlock_time,
    IpAllStatus *records);
gint32 clean_all_fail_record(const gchar *dir);

#endif // __IP_LOCK_H__