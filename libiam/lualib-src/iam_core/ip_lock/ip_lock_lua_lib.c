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

#define LUA_LIB
#include <lauxlib.h>
#include <lua.h>
#include <securec.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <pwd.h>
#include "utmp.h"
#include "signal.h"
#include "ip_lock.h"

static int l_increase_ip_fail_record(lua_State *L)
{
    const gchar *dir    = luaL_checkstring(L, 1);
    const gchar *ip_str = luaL_checkstring(L, 2);
    gint32 ret = increase_fail_record(dir, ip_str);
    lua_pushinteger(L, ret);
    return 1;
}

static int l_clean_ip_fail_record(lua_State *L)
{
    const gchar *dir    = luaL_checkstring(L, 1);
    const gchar *ip_str = luaL_checkstring(L, 2);
    gint32 ret = clean_fail_record(dir, ip_str);
    lua_pushinteger(L, ret);
    return 1;
}

static int l_get_one_ip_lock_status(lua_State *L)
{
    const gchar *dir            = luaL_checkstring(L, 1);
    const gchar *ip_str         = luaL_checkstring(L, 2);
    guint8       lock_threshold = (guint8)luaL_checkinteger(L, 3);
    guint64      fail_interval  = (guint64)luaL_checkinteger(L, 4);
    guint64      unlock_time    = (guint64)luaL_checkinteger(L, 5);
    IpLockStatus status         = {0};

    gint32 res = get_one_lock_status(dir, ip_str, lock_threshold, fail_interval, unlock_time, &status);
    if (res != RET_OK) {
        return luaL_error(L, "get ip lock records failed!");
    }
    lua_pushboolean(L, status.lock_status);
    return 1;
}

static int l_get_all_ip_lock_status(lua_State *L)
{
    const gchar *dir           = luaL_checkstring(L, 1);
    guint8      lock_threshold = (guint8)luaL_checkinteger(L, 2);
    guint64     fail_interval  = (guint64)luaL_checkinteger(L, 3);
    guint64     unlock_time    = (guint64)luaL_checkinteger(L, 4);
    IpAllStatus records        = {0};

    gint32 res = get_all_lock_status(dir, lock_threshold, fail_interval, unlock_time, &records);
    if (res != RET_OK) {
        // 异常场景不需要释放
        return luaL_error(L, "get all ip lock records failed!");
    }

    // 先压栈记录的总个数
    lua_pushinteger(L, records.count);

    // 创建一个表，用于存放多行记录
    lua_createtable(L, records.count, 0);
    for (guint32 i = 0; i < records.count; i++) {
        // 创建一个副表，有3个键值对，对应一个IpLockStatus结构
        lua_createtable(L, 0, 3);

        // 压栈ip
        lua_pushstring(L, records.records[i].ip);
        lua_setfield(L, -2, "ip");

        // 压栈状态
        lua_pushboolean(L, records.records[i].lock_status);
        lua_setfield(L, -2, "lock_status");

        // 压栈锁定开始时间
        lua_pushinteger(L, records.records[i].lock_start_time);
        lua_setfield(L, -2, "lock_start_time");

        // 附表在栈顶，将其放入主表的数组中第 i+1 的位置
        lua_rawseti(L, -2, i + 1);
    }

    g_free(records.records);
    records.records = NULL;
    // 返回2个对象，记录总个数和已有的表
    return 2;
}

static int l_clean_all_fail_record(lua_State *L)
{
    const gchar *dir = luaL_checkstring(L, 1);
    gint32 res       = clean_all_fail_record(dir);
    lua_pushinteger(L, res);
    return 1;
}

LUAMOD_API int luaopen_ip_lock(lua_State *L)
{
    luaL_checkversion(L);
    luaL_Reg l[] = {
        {"increase_ip_fail_record", l_increase_ip_fail_record},  // 增加ip失败记录
        {"clean_ip_fail_record", l_clean_ip_fail_record},        // 重置ip失败记录
        {"get_one_ip_lock_status", l_get_one_ip_lock_status},    // 获取特定ip的锁定状态
        {"get_all_ip_lock_status", l_get_all_ip_lock_status},    // 获取所有ip的锁定状态
        {"clean_all_ip_fail_record", l_clean_all_fail_record},   // 清除所有ip失败记录
        {NULL, NULL},
    };
    luaL_newlib(L, l);

    return 1;
}