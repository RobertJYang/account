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
 * Description: common includes
 */

#ifndef TRUST_COMM_UTILS_H
#define TRUST_COMM_UTILS_H
#include <openssl/err.h>
#include <openssl/pem.h>
#include "glib.h"
#include "stdio.h"
#include "securec.h"
#include "syslog.h"
#include "logging.h"
#include "utils/file_securec.h"

#ifdef __cplusplus
extern "C" {
#endif

/* 函数返回值 */
#define RET_OK  0
#define RET_ERR (-1)

#ifndef DISABLE
#define DISABLE 0
#endif

#ifndef ENABLE
#define ENABLE 1
#endif

#ifndef LOCAL
#define LOCAL static
#endif

#define MAX_FILENAME_LENGTH  256
#define SMALL_BUFFER_SIZE    256
#define USER_ENPASSWD_LENGTH 32
#define MAX_RSC_URI_LEN      256

#define BUILD_TYPE_DT (0x0a)
#define BUILD_TYPE_DEBUG (0x0b)
#define BUILD_TYPE_RELEASE (0x0c)
#define KEY_MAX_SIZE (100 * 1024)    // 公私钥最大大小100k

glong get_file_length(const gchar *filename);
gint32 convert_private_key_to_string(EVP_PKEY *pkey, gchar **key_str);
gint32 convert_public_key_to_string(EVP_PKEY *pkey, gchar **key_str);
EVP_PKEY *convert_string_to_pkey(const gchar *key, gint32 key_len, gboolean is_private_key);

#ifdef __cplusplus
}
#endif
#endif  // TRUST_COMM_UTILS_H
