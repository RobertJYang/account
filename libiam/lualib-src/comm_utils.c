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
 * Description: common utils
 */

#include <sys/stat.h>
#include <unistd.h>
#include <glib/gstdio.h>
#include <glib.h>
#include <execinfo.h>
#include <sys/wait.h>
#include <sys/syslog.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include "securec.h"
#include "comm_utils.h"

#define BUFF_SIZE  (4 * 1024)
#define LOG_MAX_SZ (1024)

typedef size_t (*FILE_READ_OR_WRITE_HANDLE)(gchar *, size_t, size_t, FILE *);
typedef struct {
    gchar                    *open_file_para;
    FILE_READ_OR_WRITE_HANDLE file_op_handle;
} FILE_IO_PARA;
typedef enum {
    READ_FLAG  = 0,
    WRITE_FLAG = 1,
} read_or_write_flag;

/*
 * Description : 获取文件长度
 */
gint64 get_file_length(const gchar *filename)
{
    struct stat stmp;
    if (filename == NULL) {
        return 0;
    }
    if (stat_s(filename, &stmp) < 0) {
        return 0;
    }
    return stmp.st_size;
}

/*
 * Description: 把私钥EVP_PKEY对象转成PKCS#8格式的字符串
 * Note: 返回的key_str字符串内存空间由调用者负责释放，释放函数为g_free
 */
gint32 convert_private_key_to_string(EVP_PKEY *pkey, gchar **key_str)
{
    BIO *bio = NULL;

    if (pkey == NULL || key_str == NULL) {
        debug_log(DLOG_ERROR, "[security] the parameter is invalid.");
        return RET_ERR;
    }

    bio = BIO_new(BIO_s_mem());
    if (bio == NULL) {
        debug_log(DLOG_ERROR, "[security] bio init failed.");
        return RET_ERR;
    }

    if (PEM_write_bio_PrivateKey(bio, pkey, NULL, NULL, 0, NULL, NULL) != 1) {
        debug_log(DLOG_ERROR, "[security] write private failed: %s", ERR_error_string(ERR_get_error(), NULL));
        BIO_free(bio);
        return RET_ERR;
    }

    if (BIO_number_written(bio) >= KEY_MAX_SIZE) {
        BIO_free(bio);
        debug_log(DLOG_ERROR, "[security] the space of key is not enough.");
        return RET_ERR;
    }

    gint32 ret = BIO_read(bio, *key_str, BIO_number_written(bio));
    if (ret <= 0) {
        BIO_free(bio);
        debug_log(DLOG_ERROR, "[security] BIO_read the private key string failed, ret = %d.", ret);
        return RET_ERR;
    }
    BIO_free(bio);
    return RET_OK;
}

/*
 * Description: 把EVP_PKEY对象的公钥转成PKCS#8格式的字符串
 * Note: 返回的key_str字符串内存空间由调用者负责释放，释放函数为g_free
 */
gint32 convert_public_key_to_string(EVP_PKEY *pkey, gchar **key_str)
{
    BIO *bio = NULL;

    if (pkey == NULL || key_str == NULL) {
        debug_log(DLOG_ERROR, "[security] the parameter is invalid.");
        return RET_ERR;
    }

    bio = BIO_new(BIO_s_mem());
    if (bio == NULL) {
        debug_log(DLOG_ERROR, "[security] bio init failed.");
        return RET_ERR;
    }

    if (PEM_write_bio_PUBKEY(bio, pkey) != 1) {
        debug_log(DLOG_ERROR, "[security] write public failed: %s", ERR_error_string(ERR_get_error(), NULL));
        BIO_free(bio);
        return RET_ERR;
    }

    if (BIO_number_written(bio) >= KEY_MAX_SIZE) {
        BIO_free(bio);
        debug_log(DLOG_ERROR, "[security] the space of key is not enough.");
        return RET_ERR;
    }

    gint32 ret = BIO_read(bio, *key_str, BIO_number_written(bio));
    if (ret <= 0) {
        BIO_free(bio);
        debug_log(DLOG_ERROR, "[security] BIO_read the public key string failed, ret = %d.", ret);
        return RET_ERR;
    }
    BIO_free(bio);
    return RET_OK;
}

/*
 * Description: 将字符串*pkey_str转成密钥对象EVP_PKEY
 */
EVP_PKEY *convert_string_to_pkey(const gchar *key, gint32 key_len, gboolean is_private_key)
{
    BIO      *bio  = NULL;
    EVP_PKEY *pkey = NULL;
    if (key == NULL) {
        return NULL;
    }

    bio = BIO_new(BIO_s_mem());
    if (bio == NULL) {
        debug_log(DLOG_ERROR, "[security] convert string to pkey bio init fail");
        return NULL;
    }
    if (BIO_write(bio, key, key_len) <= 0) {
        debug_log(DLOG_ERROR, "[security] convert string to pkey bio write fail");
        goto exit;
    }

    if (is_private_key) {
        // private key
        if (PEM_read_bio_PrivateKey(bio, &pkey, NULL, NULL) == NULL) {
            debug_log(DLOG_ERROR, "[security] read private key error: %s", ERR_error_string(ERR_get_error(), NULL));
            goto exit;
        }
    } else {
        // public key
        if (PEM_read_bio_PUBKEY(bio, &pkey, NULL, NULL) == NULL) {
            debug_log(DLOG_ERROR, "[security] read public key error: %s", ERR_error_string(ERR_get_error(), NULL));
            goto exit;
        }
    }

exit:
    BIO_free(bio);
    return pkey;
}