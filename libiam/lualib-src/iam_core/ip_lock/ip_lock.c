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

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <securec.h>
#include "utils/file_securec.h"
#include <dbus/dbus.h>
#include "ip_lock.h"

static GHashTable *g_ip_map = NULL;

/*
 * Description: 打开faillock文件
 */
LOCAL FILE *open_ip_fail_record(const gchar *dir, const gchar *ip)
{
    // 没有目录时先创建
    if (access_s(dir, F_OK) != 0) {
        if (mkdir(dir, S_IRWXU | S_IRGRP | S_IXGRP) < 0) {
            debug_log(DLOG_ERROR, "create ip_log dir failed.");
            return NULL;
        }
        if (chown_s(dir, SECBOX_UID, SNMPD_USER_GROUP) < 0) {
            debug_log(DLOG_ERROR, "change ip_record dir owner and group failed.");
            return NULL;
        }
    }

    // 拼接资源路径
    GString *gs_path = g_string_new("");
    g_string_append(gs_path, dir);
    if (gs_path->str[gs_path->len - 1] != '/') {
        g_string_append(gs_path, "/");
    }
    g_string_append(gs_path, ip);

    // 获取文件句柄
    FILE *fp = fopen_s(gs_path->str, "a+", gs_path->str);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open ip_record file failed.");
        g_string_free(gs_path, TRUE);
        return NULL;
    }
    g_string_free(gs_path, TRUE);

    // 改文件权限
    gint32 fd = fileno(fp);
    (void)fchmod(fd, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
    // 保证snmp接口调用时能读到faillock文件
    if (fchown(fd, SECBOX_UID, SNMPD_USER_GROUP) != 0) {
        debug_log(DLOG_DEBUG, "change ip_record file group failed.");
    }
    while (flock(fd, LOCK_EX) == -1 && errno == EINTR) {
    }
    return fp;
}

/*
 * Description: 关闭faillock文件
 */
LOCAL void close_ip_fail_record(FILE *fp)
{
    gint32 fd = fileno(fp);
    (void)flock(fd, LOCK_UN);
    (void)fclose(fp);
}

/*
 * Description: 读取锁定记录
 */
LOCAL gint32 read_ip_fail_record(FILE *fp, guint8 *record_cnt, IpFailRecord *records)
{
    (void)fseek(fp, 0, SEEK_END);
    glong size = ftell(fp);
    if (size < 0) {
        debug_log(DLOG_ERROR, "get ip record log size failed.");
        return RET_ERR;
    }

    if (size > MAX_RECORD_CNT * sizeof(IpFailRecord)) {
        size = MAX_RECORD_CNT * sizeof(IpFailRecord);
    }

    if (size % sizeof(IpFailRecord) != 0) {
        debug_log(DLOG_ERROR, "record file format error");
        gint32 fd = fileno(fp);
        if (ftruncate(fd, 0) != 0) {
            debug_log(DLOG_ERROR, "ftruncate record file failed");
        }
        rewind(fp);
        return RET_ERR;
    }

    *record_cnt = size / sizeof(IpFailRecord);
    (void)fseek(fp, 0, SEEK_SET);
    if (fread(records, sizeof(IpFailRecord), *record_cnt, fp) != *record_cnt) {
        debug_log(DLOG_ERROR, "read ip record log failed");
        return RET_ERR;
    }

    return RET_OK;
}

// 更新记录，若写满了需要覆盖最旧的记录
LOCAL gint32 update_record(guint64 now, guint8 *record_cnt, IpFailRecord* records)
{
    guint8 loc_idx = 0;
    gint32 ret = RET_ERR;
    // 若已经写满了，找到最旧的记录
    if (*record_cnt == MAX_RECORD_CNT) {
        guint64 oldest_time = records[0].timestamp;
        for (guint8 i = 1; i < *record_cnt; i++) {
            if (records[i].timestamp < oldest_time) {
                oldest_time = records[i].timestamp;
                loc_idx     = i;
            }
        }
    } else {
        // 否则直接追加到最后即可
        loc_idx = *record_cnt;
        *record_cnt += 1;
    }

    ret = strcpy_s(records[loc_idx].record_name, sizeof(records[loc_idx].record_name), "Ip");
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "strcpy_s fail, ret = %d", ret);
        return RET_ERR;
    }
    records[loc_idx].timestamp = now;
    return RET_OK;
}

LOCAL gint32 check_if_increase_record_cnt(const gchar *ip)
{
    if (g_ip_map == NULL) {
        g_ip_map = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
    }

    // 如果是表中已有的数据，可以认为OK
    gpointer value = g_hash_table_lookup(g_ip_map, ip);
    if (value != NULL) {
        return RET_OK;
    }

    if (g_hash_table_size(g_ip_map) >= MAX_IP_RECORD_CNT) {
        debug_log(DLOG_ERROR, "ip record exceeds the maximum quantity limit");
        return RET_ERR;
    }

    g_hash_table_insert(g_ip_map, (void *)g_strdup(ip), "");
    return RET_OK;
}

LOCAL gint32 remove_port_from_ip(const gchar *ip, gchar *clean_ip, size_t clean_ip_len)
{
    gint32 ret;
    if (!ip || !clean_ip) {
        debug_log(DLOG_ERROR, "invalid paramter");
        return RET_ERR;
    }

    // 有'['，为ipv6格式，找闭环的']'后面是否有':'分隔端口
    if (ip[0] == '[') {
        const gchar *end_barcket = strchr(ip, ']');
        if (!end_barcket) {
            // 找不到闭环']'，入参ip格式错误
            debug_log(DLOG_ERROR, "format ip %s err", ip);
            return RET_ERR;
        }

        // 看']'后面是否有':'用于分隔端口
        // end_barcket[1]可能存在 '\0' 或者 ':' 两类情况，否则也是非法格式的ip
        if (end_barcket[1] != ':' && end_barcket[1] != '\0') {
            debug_log(DLOG_ERROR, "format ip %s err", ip);
            return RET_ERR;
        } else { // 其他场景都不关注 ']' 后面有什么内容，只取 '[' 和 ']' 中间的部分
            ret = strncpy_s(clean_ip, clean_ip_len, ip + 1, end_barcket - ip - 1);
            if (ret != RET_OK) {
                debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", ret);
                return RET_ERR;
            }
            return RET_OK;
        }
    }

    // 其它场景：1、ipv4 带端口号；2、ipv4 不带端口号；3、ipv6 没有 '[]'（即认为不带端口号）
    const gchar *first_colon = strchr(ip, ':');
    const gchar *last_colon = strrchr(ip, ':');

    // 找到有且仅有1个':'的场景，即为 ipv4 带端口号
    if (first_colon != NULL && last_colon != NULL && first_colon == last_colon) {
        ret = strncpy_s(clean_ip, clean_ip_len, ip, last_colon - ip);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", ret);
            return RET_ERR;
        }
        return RET_OK;
    }

    // ipv4 无端口号或者 ipv6 无端口号
    ret = strncpy_s(clean_ip, clean_ip_len, ip, strlen(ip));
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", ret);
        return RET_ERR;
    }
    return RET_OK;
}

#ifndef G_ENABLE_TEST
LOCAL gboolean check_if_locked(const gchar *dir, const gchar *ip)
{
    gint32 duration      = 0;
    gint32 threshold     = 0;
    gint32 time_interval = 0;
    gint32 ret = dbus_get_auth_lockout_conf(&duration, &threshold, &time_interval);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "[ip lock] get dbus prop failed");
        // 失败时不阻塞认证行为
        return FALSE;
    }

    IpLockStatus record = {0};
    ret = get_one_lock_status(dir, ip, (guint8)threshold, (guint64)time_interval, (guint64)duration, &record);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "[ip lock] get lock record failed");
        // 失败时不阻塞认证行为
        return FALSE;
    }

    return record.lock_status;
}
#endif // G_ENABLE_TEST

// 增加特定ip的失败记录
gint32 increase_fail_record(const gchar *dir, const gchar *ip, guint8 is_check_lock)
{
    gchar clean_ip[MAX_IP_LENGTH] = {0};
    gint32 ret = remove_port_from_ip(ip, clean_ip, MAX_IP_LENGTH);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "invalid ip str");
        return RET_ERR;
    }

    // 判断如果需要新增ip，计数+1
    ret = check_if_increase_record_cnt(clean_ip);
    if (ret != RET_OK) {
        return RET_ERR;
    }

    // 若已经锁定，不再增加锁定记录，避免持续刷新时间导致无法解锁
    if (is_check_lock == DO_CHECK) {
        if (check_if_locked(dir, clean_ip)) {
            debug_log(DLOG_NOTICE, "ip %s is locked, not increase fail record", clean_ip);
            return RET_OK;
        }
    }

    // 获取失败记录文件句柄
    FILE *fp = open_ip_fail_record(dir, clean_ip);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open ip lock record file failed");
        return RET_ERR;
    }

    IpFailRecord *records = NULL;
    do {
        // 获取对应ip的失败记录
        guint8 record_cnt = 0;
        records = (IpFailRecord *)g_malloc0(MAX_RECORD_CNT * sizeof(IpFailRecord));
        if (records == NULL) {
            debug_log(DLOG_ERROR, "g_malloc0 failed");
            ret = RET_ERR;
            break;
        }
        ret = read_ip_fail_record(fp, &record_cnt, records);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "read ip lock record failed");
            break;
        }

        // 更新记录
        time_t now = 0;
        (void)time(&now);
        ret = update_record(now, &record_cnt, records);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "update ip lock record failed");
            break;
        }

        // 重置文件
        if (ftruncate(fileno(fp), 0) != 0) {
            debug_log(DLOG_ERROR, "ftruncate failed, errno: %d", errno);
            ret = errno;
            break;
        }
        rewind(fp);
        ret = fseek(fp, 0, SEEK_SET);
        if (ret != 0) {
            debug_log(DLOG_ERROR, "fseek SET failed!");
            break;
        }

        // 重写文件
        if (fwrite(records, sizeof(IpFailRecord), record_cnt, fp) != record_cnt) {
            debug_log(DLOG_ERROR, "fwrite fail.");
            ret = RET_ERR;
        }
    } while(0);

    if (records != NULL) {
        g_free(records);
        records = NULL;
    }
    close_ip_fail_record(fp);
    return ret;
}

// 清空特定ip的失败记录【由于ip不像用户时常驻的，这里清除记录直接删除文件即可】
gint32 clean_fail_record(const gchar *dir, const gchar *ip)
{
    gchar clean_ip[MAX_IP_LENGTH] = {0};
    gint32 ret = remove_port_from_ip(ip, clean_ip, MAX_IP_LENGTH);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "invalid ip str");
        return RET_ERR;
    }

    // 拼接资源路径
    GString *gs_path = g_string_new("");
    g_string_append(gs_path, dir);
    if (gs_path->str[gs_path->len - 1] != '/') {
        g_string_append(gs_path, "/");
    }
    g_string_append(gs_path, clean_ip);

    // 直接删除
    (void)remove(gs_path->str);
    g_string_free(gs_path, TRUE);
    
    // 代表要删除记录时，计数-1【无需关注是否存在，删除不存在的key无效果】
    if (g_ip_map == NULL) {
        g_ip_map = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
    }
    g_hash_table_remove(g_ip_map, (void *)clean_ip);
    return RET_OK;
}

// 获取单个ip的锁定状态
gint32 get_one_lock_status(const gchar *dir, const gchar *ip, guint8 lock_threshold, guint64 fail_interval,
    guint64 unlock_time, IpLockStatus *status)
{
    gchar clean_ip[MAX_IP_LENGTH] = {0};
    gint32 ret = remove_port_from_ip(ip, clean_ip, MAX_IP_LENGTH);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "invalid ip str");
        return RET_ERR;
    }

    // 获取当前时间
    time_t now = 0;
    (void)time(&now);

    gint32 res = RET_ERR;
    // 获取失败记录文件句柄
    FILE *fp = open_ip_fail_record(dir, clean_ip);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open ip lock record file failed");
        return RET_ERR;;
    }

    IpFailRecord *records = NULL;
    do {
        // 获取对应ip的失败记录
        guint8 record_cnt = 0;
        records = (IpFailRecord *)g_malloc0(MAX_RECORD_CNT * sizeof(IpFailRecord));
        if (records == NULL) {
            debug_log(DLOG_ERROR, "g_malloc0 failed");
            break;
        }
        res = read_ip_fail_record(fp, &record_cnt, records);
        if (res != RET_OK) {
            debug_log(DLOG_ERROR, "read ip lock record failed");
            break;
        }

        guint64 latest_time = 0;
        guint8  fail_cnt = 0;

        // 找到最后一次失败的时间
        for (guint8 i = 0; i < record_cnt; i++) {
            if (records[i].timestamp > latest_time) {
                latest_time = records[i].timestamp;
            }
        }

        // 只找一定时间内的失败记录为有效记录
        guint64 exp_oldest_time = latest_time - fail_interval;
        for (guint8 i = 0; i < record_cnt; i++) {
            if (exp_oldest_time < records[i].timestamp) {
                fail_cnt++;
            }
        }

        // 若最后一次失败到目前已经超过解锁时间，认为计数为0
        if (latest_time + unlock_time < (guint64)now) {
            fail_cnt = 0;
        }

        // 判断有效失败次数是否已经达到锁定次数
        status->lock_status = lock_threshold != 0 ? (fail_cnt >= lock_threshold) : FALSE;
        status->lock_start_time = latest_time;
        
        res = RET_OK;
    } while(0);

    if (records != NULL) {
        g_free(records);
        records = NULL;
    }
    close_ip_fail_record(fp);
    return res;
}

// 获取所有锁定状态
gint32 get_all_lock_status(const gchar *dir, guint8 lock_threshold, guint64 fail_interval, guint64 unlock_time,
    IpAllStatus *records)
{
    struct dirent *entry;

    // 打开目录
    DIR *cur_dir = opendir(dir);
    if (cur_dir == NULL) {
        debug_log(DLOG_ERROR, "cannot open dir, err: %s", strerror(errno));
        return RET_ERR;
    }

    guint32 i = 0;
    GArray *result_data = g_array_new(FALSE, TRUE, sizeof(IpLockStatus));
    while((entry = readdir(cur_dir)) != NULL) {
        // 跳过 "." 和 ".."
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        IpLockStatus data = {0};
        gint32 ret = strcpy_s(&data.ip, sizeof(data.ip), entry->d_name);
        if (ret != RET_OK) {
            (void)g_array_free(result_data, TRUE);
            closedir(cur_dir);
            debug_log(DLOG_ERROR, "strcpy_s fail, ret = %d", ret);
            return RET_ERR;
        }
        ret = get_one_lock_status(dir, entry->d_name, lock_threshold, fail_interval, unlock_time, &data);
        if (ret != RET_OK) {
            (void)g_array_free(result_data, TRUE);
            closedir(cur_dir);
            debug_log(DLOG_ERROR, "get lock status failed, ret = %d", ret);
            return RET_ERR;
        }
        g_array_append_val(result_data, data);
        i++;
    }
    closedir(cur_dir);

    records->records = (IpLockStatus *)g_array_free(result_data, FALSE);
    records->count   = i;
    return RET_OK;
}

// 清除所有IP失败记录
gint32 clean_all_fail_record(const gchar *dir)
{
    struct dirent *entry;

    // 打开目录
    DIR *cur_dir = opendir(dir);
    if (cur_dir == NULL) {
        debug_log(DLOG_ERROR, "cannot open dir, err: %s", strerror(errno));
        return RET_ERR;
    }

    while((entry = readdir(cur_dir)) != NULL) {
        // 跳过 "." 和 ".."
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        (void)clean_fail_record(dir, entry->d_name);
    }
    closedir(cur_dir);

    return RET_OK;
}
