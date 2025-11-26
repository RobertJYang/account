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

#ifndef PAM_COMMON_H
#define PAM_COMMON_H

#include "glib.h"
#include "stdio.h"
#include "fcntl.h"
#include "sys/time.h"
#include "sys/resource.h"
#include "security/pam_modules.h"
#include "security/pam_ext.h"
#include "security/pam_modutil.h"
#include "secure/securec.h"
#include "syslog.h"
#include "logging.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#ifndef LOCAL
#define LOCAL static
#endif

/* 通用状态码 */
#define DISABLED                0
#define ENABLED                 1
#define USER_UNLOCK             0
#define USER_LOCK               1
#define PASSWD_NOT_EXPIRED      0
#define PASSWD_IS_EXPIRED       1
#define LOGIN_INTERFACE_DISABLE 0
#define LOGIN_INTERFACE_ENABLE  1
#define RET_OK                  0
#define RET_ERR                 (-1)

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // PAM_COMMON_H