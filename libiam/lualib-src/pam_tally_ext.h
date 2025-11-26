/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
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
 * Author: liwenjie
 * Create: 2022-10-31
 * Description: pam tally log
 */

#ifndef PAM_TALLY_EXT_H
#define PAM_TALLY_EXT_H
#include <sys/stat.h>
#include "comm_utils.h"
#include "pwd.h"

#ifdef __cplusplus
extern "C" {
#endif

#define PAM_TALLY_LOG_DIR               "/dev/shm/tallylog"
#define TALLY_FAIL_INTERVAL_ADD_SECONDS 300 /* from faillock, the record fail_interval = unlock_time + 5min */

typedef struct tallylog_ext_t {
    guint16 fail_cnt;  /* failures since last success */
    guint64 fail_time; /* time of last failure */
} TallyLog;

gint32 get_pam_tally(const gchar *user, const gchar *tally_dir, guint64 fail_interval, TallyLog *tally);
gint32 get_pam_tally_with_fail_interval(const gchar *user, const gchar *tally_dir, guint64 unlock_time,
    gint64 fail_interval, TallyLog *tally);
gint32 reset_pam_tally(const gchar *user, const gchar *tally_dir);
gint32 increment_pam_tally(const gchar *user, const gchar *tally_dir);

#ifdef __cplusplus
}
#endif
#endif /* PAM_TALLY_EXT_H */
