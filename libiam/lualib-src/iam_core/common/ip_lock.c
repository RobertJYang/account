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

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <securec.h>
#include "utils/file_securec.h"
#include "ip_lock.h"

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
    if (fchown(fd, -1, SNMPD_USER_GROUP) != 0) {
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
    gsize size = ftell(fp);
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


// 增加特定ip的失败记录
gint32 increase_fail_record(const gchar *dir, const gchar *ip)
{
    // 获取失败记录文件句柄
    FILE *fp = open_ip_fail_record(dir, ip);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open ip lock record file failed");
        return RET_ERR;
    }

    gint32 ret = RET_OK;
    IpFailRecord *records = NULL;
    do {
        // 获取对应ip的失败记录
        guint8 record_cnt = 0;
        records = (IpFailRecord *)g_malloc0(MAX_RECORD_CNT * sizeof(IpFailRecord));
        if (records == NULL) {
            debug_log(DLOG_ERROR, "g_malloc0 failed");
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
    // 拼接资源路径
    GString *gs_path = g_string_new("");
    g_string_append(gs_path, dir);
    if (gs_path->str[gs_path->len - 1] != '/') {
        g_string_append(gs_path, "/");
    }
    g_string_append(gs_path, ip);

    // 直接删除
    (void)remove(gs_path->str);
    g_string_free(gs_path, TRUE);
    return RET_OK;
}

// 获取单个ip的锁定状态
gint32 get_one_lock_status(const gchar *dir, const gchar *ip, guint8 lock_threshold, guint64 fail_interval,
    IpLockStatus *status)
{
    // 获取当前时间
    time_t now = 0;
    (void)time(&now);

    gint32 res = RET_ERR;
    // 获取失败记录文件句柄
    FILE *fp = open_ip_fail_record(dir, ip);
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
        if (latest_time + IP_UNLOCK_TIME < (guint64)now) {
            fail_cnt = 0;
        }

        // 判断有效失败次数是否已经达到锁定次数
        status->lock_status = (fail_cnt >= lock_threshold);
        status->lock_start_time = status->lock_status ? latest_time : 0;
        
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
gint32 get_all_lock_status(const gchar *dir, guint8 lock_threshold, guint64 fail_interval, IpAllStatus *records)
{
    struct dirent *entry;

    // 打开目录
    DIR *cur_dir = opendir(dir);
    if (cur_dir == NULL) {
        debug_log(DLOG_ERROR, "cannot open dir, err: %s", strerror(errno));
        return RET_ERR;
    }

    // 第一次循环拿到数量
    guint32 ip_count = 0;
    while((entry = readdir(cur_dir)) != NULL) {
        // 跳过 "." 和 ".."
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        ip_count++;
    }

    // 第二次循环拿内容
    IpLockStatus *data = (IpLockStatus *)g_malloc0(ip_count * sizeof(IpLockStatus));
    rewinddir(cur_dir);
    guint32 i = 0;
    while((entry = readdir(cur_dir)) != NULL) {
        // 跳过 "." 和 ".."
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        (void)strcpy_s(data[i].ip, sizeof(data[i].ip), entry->d_name);
        (void)get_one_lock_status(dir, entry->d_name, lock_threshold, fail_interval, &data[i]);
        i++;
    }
    closedir(cur_dir);

    records->records = data;
    records->count   = ip_count;
    return RET_OK;
}