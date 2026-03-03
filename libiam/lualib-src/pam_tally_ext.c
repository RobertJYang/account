/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2014-2020. All rights reserved.
 * Description: 提供pam锁定记录的查询和修改功能
 */

#include <pwd.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <stdio.h>
#include <securec.h>
#include "utils/file_securec.h"
#include "pam_tally_ext.h"

/* bmc里的用户：系统用户0-99 自定义用户5xx */
#undef INVAILD_UID
#define INVAILD_UID 1000

#define FAILLOCK_RECORD_VALID 0x1
#define FAILLOCK_SOURCE_RHOST 0x2
#define MAX_RECORDS           1024
#define SNMPD_USER_GROUP      95
#define APPS_USER_GROUP       103
#define SECBOX_UID            104
/* 用户名转换 */
#define ACTUAL_ROOT_USER_NAME   "root"
#define RESERVED_ROOT_USER_NAME "<root>"

/* 无效fail_interval */
#define NO_INTERVAL          (-1)

typedef struct tally_record {
    gchar   record_name[52]; /* record name */
    guint16 reserved;        /* reserved */
    guint16 status;          /* record status  */
    guint64 timestamp;       /* auth failure timestamp */
} TallyRecord;

typedef struct tally_data {
    TallyRecord *records; /* array of tallies */
    guint32      count;   /* number of records */
} TallyData;

/*
 * Description: 打开faillock文件
 */
LOCAL FILE *open_tally(const gchar *user, const gchar *dir)
{
    if (dir == NULL || strlen(dir) == 0 || strstr(user, "../") != NULL) {
        return NULL;
    }
    if (access_s(dir, F_OK) != 0) {
        if (mkdir(dir, S_IRWXU | S_IRWXG) < 0) {
            debug_log(DLOG_ERROR, "create tallylog dir failed.");
            return NULL;
        }
        if (chown_s(dir, SECBOX_UID, APPS_USER_GROUP) < 0) {
            debug_log(DLOG_ERROR, "change tallylog dir owner and group failed.");
            return NULL;
        }
    }
    GString *gs_path = g_string_new("");
    g_string_append(gs_path, dir);
    if (gs_path->str[gs_path->len - 1] != '/') {
        g_string_append(gs_path, "/");
    }

    const gchar *tmp_user_name =
        strcmp(user, ACTUAL_ROOT_USER_NAME) == 0 ? RESERVED_ROOT_USER_NAME : user;
    g_string_append(gs_path, tmp_user_name);

    FILE *fp = fopen_s(gs_path->str, "a+", gs_path->str);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open faillock file failed.");
        g_string_free(gs_path, TRUE);
        return NULL;
    }
    g_string_free(gs_path, TRUE);
    gint32 fd = fileno(fp);
    // 改文件权限
    (void)fchmod(fd, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
    // 保证snmp接口调用时能读到faillock文件
    if (fchown(fd, -1, APPS_USER_GROUP) != 0) {
        debug_log(DLOG_DEBUG, "change faillock file group failed.");
    }
    while (flock(fd, LOCK_EX) == -1 && errno == EINTR) {
    }
    return fp;
}

/*
 * Description: 关闭faillock文件
 */
LOCAL void close_tally(FILE *fp)
{
    gint32 fd = fileno(fp);
    (void)flock(fd, LOCK_UN);
    (void)fclose(fp);
}

/*
 * Description: 读取pam文件
 */
LOCAL gint32 read_tally(FILE *fp, TallyData *tallies)
{
    (void)fseek(fp, 0, SEEK_END);
    gint32 size = ftell(fp);
    if (size < 0) {
        debug_log(DLOG_ERROR, "get tally log size failed.");
        return RET_ERR;
    }
    size_t unsigned_size = (size_t)size;
    if (unsigned_size > MAX_RECORDS * sizeof(TallyRecord)) {
        unsigned_size = MAX_RECORDS * sizeof(TallyRecord);
    }
    if (unsigned_size % sizeof(TallyRecord) != 0) {
        debug_log(DLOG_ERROR, "tally log format error!");
        gint32 fd = fileno(fp);
        if (ftruncate(fd, 0) != 0) {
            debug_log(DLOG_ERROR, "tally log ftruncate error!");
        }
        rewind(fp);
        return RET_ERR;
    }
    size_t      count = unsigned_size / sizeof(TallyRecord);
    TallyRecord *data  = g_malloc0(unsigned_size);
    (void)fseek(fp, 0, SEEK_SET);
    if (fread(data, sizeof(TallyRecord), count, fp) != count) {
        g_free(data);
        debug_log(DLOG_ERROR, "tally log read error!");
        return RET_ERR;
    }
    tallies->records = data;
    tallies->count   = count;
    return RET_OK;
}

LOCAL gint32 get_user_info(const gchar *user, const gchar *dir, guint64 unlock_time, gint64 interval,
    TallyLog *tally)
{
    time_t now = 0;
    (void)time(&now);

    TallyData tallies = {0};

    FILE *fp = open_tally(user, dir);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open_tally error");
        return RET_ERR;
    }
    gint32 ret = read_tally(fp, &tallies);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "read_tally error, ret: %d", ret);
        goto exit;
    }

    guint64 latest_time   = 0;
    guint32 failures      = 0;
    guint64 fail_interval = interval == NO_INTERVAL ? unlock_time + TALLY_FAIL_INTERVAL_ADD_SECONDS : (guint64)interval;

    for (guint32 i = 0; i < tallies.count; i++) {
        if (!(tallies.records[i].status & FAILLOCK_RECORD_VALID)) {
            continue;
        }
        if (tallies.records[i].timestamp > latest_time) {
            latest_time = tallies.records[i].timestamp;
        }
    }

    for (guint32 i = 0; i < tallies.count; i++) {
        if (!(tallies.records[i].status & FAILLOCK_RECORD_VALID)) {
            continue;
        }
        if (latest_time - tallies.records[i].timestamp < fail_interval) {
            ++failures;
        }
    }
    if (latest_time + unlock_time >= (guint64)now) {
        tally->fail_cnt  = failures;
        tally->fail_time = latest_time;
    } else {
        tally->fail_cnt  = 0;
        tally->fail_time = 0;
    }

exit:
    g_free(tallies.records);
    close_tally(fp);
    return ret;
}

/*
 * Description: 获取pam锁定记录
 */
gint32 get_pam_tally(const gchar *username, const gchar *tally_dir, guint64 unlock_time, TallyLog *tally)
{
    if (tally_dir == NULL || tally == NULL) {
        return RET_ERR;
    }

    return get_user_info(username, tally_dir, unlock_time, NO_INTERVAL, tally);
}

/*
 * Description: 获取pam锁定记录
 */
gint32 get_pam_tally_with_fail_interval(const gchar *username, const gchar *tally_dir, guint64 unlock_time,
    gint64 fail_interval, TallyLog *tally)
{
    if (tally_dir == NULL || tally == NULL) {
        return RET_ERR;
    }

    return get_user_info(username, tally_dir, unlock_time, fail_interval, tally);
}

/*
 * Description: 重置pam锁定记录
 */
gint32 reset_pam_tally(const gchar *user, const gchar *tally_dir)
{
    if (user == NULL || tally_dir == NULL) {
        return RET_ERR;
    }
    FILE *fp = open_tally(user, tally_dir);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open_tally error");
        return RET_ERR;
    }
    if (ftruncate(fileno(fp), 0) != 0) {
        debug_log(DLOG_ERROR, "ftruncate failed, errno: %d", errno);
        close_tally(fp);
        return RET_ERR;
    }
    rewind(fp);
    close_tally(fp);
    return RET_OK;
}

/*
 * Description: 更新pam记录，如果写满了会替代最需旧的记录
 */
LOCAL gint32 update_tally(guint64 now, TallyData *tallies)
{
    guint32 loc_idx = 0;
    gint32 ret = RET_ERR;
    if (tallies->count == MAX_RECORDS) {
        guint64 oldest_time = tallies->records[0].timestamp;
        for (guint32 i = 1; i < tallies->count; i++) {
            if (tallies->records[i].timestamp < oldest_time) {
                oldest_time = tallies->records[i].timestamp;
                loc_idx     = i;
            }
        }
    } else {
        size_t      buf_size = tallies->count * sizeof(TallyRecord);
        TallyRecord *newdata  = g_malloc0(buf_size + sizeof(TallyRecord));
        if (tallies->records != NULL) {
            ret = memcpy_s(newdata, buf_size + sizeof(TallyRecord), tallies->records, buf_size);
            if (ret != RET_OK) {
                debug_log(DLOG_ERROR, "memcpy_s fail, ret = %d", ret);
                g_free(newdata);
                return RET_ERR;
            }
            g_free(tallies->records);
        }
        tallies->records = newdata;
        tallies->count += 1;
        loc_idx = tallies->count - 1;
    }
    tallies->records[loc_idx].timestamp = now;
    ret = strcpy_s(tallies->records[loc_idx].record_name, sizeof(tallies->records[loc_idx].record_name), "User");
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "strcpy_s fail, ret = %d", ret);
        return RET_ERR;
    }
    tallies->records[loc_idx].status = FAILLOCK_RECORD_VALID | FAILLOCK_SOURCE_RHOST;
    return RET_OK;
}

/*
 * Description: 自增pam锁定记录
 */
gint32 increment_pam_tally(const gchar *user, const gchar *tally_dir)
{
    if (user == NULL || tally_dir == NULL) {
        return RET_ERR;
    }

    FILE *fp = open_tally(user, tally_dir);
    if (fp == NULL) {
        debug_log(DLOG_ERROR, "open_tally error");
        return RET_ERR;
    }
    TallyData tallies = {0};
    gint32    ret     = read_tally(fp, &tallies);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "read_tally error, ret: %d", ret);
        goto exit;
    }
    time_t now = 0;
    (void)time(&now);
    ret = update_tally(now, &tallies);
    if (ret != 0) {
        debug_log(DLOG_ERROR, "update_tally failed!");
        goto exit;
    }

    if (ftruncate(fileno(fp), 0) != 0) {
        debug_log(DLOG_ERROR, "ftruncate failed, errno: %d", errno);
        ret = errno;
        goto exit;
    }
    rewind(fp);
    ret = fseek(fp, 0, SEEK_SET);
    if (ret != 0) {
        debug_log(DLOG_ERROR, "fseek SET failed!");
        goto exit;
    }
    if (fwrite(tallies.records, sizeof(gchar), tallies.count * sizeof(TallyRecord), fp) !=
        tallies.count * sizeof(TallyRecord)) {
        debug_log(DLOG_ERROR, "fwrite fail.");
        ret = RET_ERR;
    }

exit:
    g_free(tallies.records);
    close_tally(fp);
    return ret;
}
