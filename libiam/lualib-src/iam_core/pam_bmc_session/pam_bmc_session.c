/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026-2026. All rights reserved.
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
 * Create: 2026-03-18
 */

#include "pwd.h"
#include "fcntl.h"
#include "errno.h"
#include "limits.h"
#include "unistd.h"
#include "dlfcn.h"
#include "sys/types.h"
#include "sys/stat.h"
#include "utils/file_securec.h"
#include "../pam_common.h"
#include "pam_bmc_session.h"

#define BUFF_LEN 128

LOCAL gboolean is_process_alive(gint32 pid)
{
    gchar path[32] = {0};

    if (pid <= 0) {
        return FALSE;
    }

    struct stat fileinfo;

    (void)snprintf_s(path, sizeof(path), sizeof(path) - 1, "/proc/%d", pid);

    if (stat_s(path, &fileinfo) || !S_ISDIR(fileinfo.st_mode)) {
        return FALSE;
    }

    return TRUE;
}

// 定义互斥锁
static pthread_mutex_t pam_session_mutex = PTHREAD_MUTEX_INITIALIZER;

#define GET_SSHD_SESSION_CMD_FMT "ps -ef|grep 'sshd:'|grep -E '%s@(pts/|notty$)'|awk '{print $2, $3}'"

/*
 * Description: pam模块架构中用于处理会话的函数，声明在<security/pam_modules.h>，本模块必须实现
 */
gint32 pam_sm_open_session(pam_handle_t *pamh, gint32 flags, gint32 argc, const gchar **argv)
{
    if (!pamh) {
        return PAM_SERVICE_ERR;
    }

    gchar *user = NULL;
    gint32 rv = pam_get_item(pamh, PAM_USER, (void *)&user);
    if (rv != PAM_SUCCESS || user == NULL || *user == '\0') {
        debug_log(DLOG_ERROR, "get login user name failed");
        return PAM_SESSION_ERR;
    }

    // 当前仅限制框内通信
    if (strcmp(user, INTER_CHASSIS_USER_NAME) != 0) {
        return PAM_SUCCESS;
    }

    // 调用popen前加锁
    pthread_mutex_lock(&pam_session_mutex);
    gchar cmd_str[BUFF_LEN] = {0};
    (void)snprintf_s(cmd_str, sizeof(cmd_str), sizeof(cmd_str) - 1, GET_SSHD_SESSION_CMD_FMT, INTER_CHASSIS_USER_NAME);

    FILE *fp = popen(cmd_str, "r");
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "execute ps for found inter chassis session failed");
        pthread_mutex_unlock(&pam_session_mutex);
        return PAM_SESSION_ERR;
    }

    guint32 pid = 0;
    guint32 ppid = 0;
    gint32 session_count = 0;
    while (fscanf_s(fp, "%u %u", &pid, &ppid) != EOF) {
        if (is_process_alive(pid)) {
            session_count++;
        }
    }

    (void)pclose(fp);
    pthread_mutex_unlock(&pam_session_mutex);

    if (session_count >= MAX_INTER_CHASSIS_PROCESSES) {
        debug_log(DLOG_ERROR, "inter chassis session count exceed limits");
        pam_syslog(pamh, LOG_ALERT, "inter chassis session count exceed limits");
        return PAM_SESSION_ERR;
    }

    return PAM_SUCCESS;
}

PAM_EXTERN gint32 pam_sm_close_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    return PAM_SUCCESS;
}