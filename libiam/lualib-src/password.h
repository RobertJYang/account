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
 * Description: certificate includes
 */

#ifndef IAM_PASSWORD_H
#define IAM_PASSWORD_H
#include "comm_utils.h"

#ifdef __cplusplus
extern "C" {
#endif

#define VNC_CHALLENGESIZE      24
#define KEYLENS                8

gboolean is_pass_complexity_check_pass(const gchar *name, const gchar *passwd, guint32 min_pwd_length);

gboolean is_vnc_password_complexity_check_pass(const gchar *password);

gint32 vnc_encrypt_bytes(const guchar key[KEYLENS], const guchar *input,
    const size_t inlen, guchar *output, gint32 *outlen);

/*
 * Description: 生成公私钥对，注意：出参为public_key、private_key(需要调用者释放)
 */
gint32 generate_key_pair(gchar **public_key, gchar **private_key);

gint32 encrypt_with_public_key(const gchar *pub_key, gint32 pub_key_len, const guchar *passwd,
    size_t passwd_len, guchar **cipher_text);

gint32 decrypt_with_private_key(const gchar *priv_key, gint32 priv_kev_len, const guchar *ciphertext,
    size_t ciphertext_len, guchar **plaintext);

gint32 check_pattern(const gchar *pattern);

gint32 verify_passwd_with_pattern(const gchar *pattern, const gchar *passwd);

#ifdef __cplusplus
}
#endif

#endif  // IAM_PASSWORD_H
