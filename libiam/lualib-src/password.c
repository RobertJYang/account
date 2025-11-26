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
 * Description: password tool
 */

#include <openssl/sha.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/ec.h>
#include <openssl/provider.h>
#include <ctype.h>
#include "securec.h"
#include "comm_utils.h"
#include "password.h"
#define PWD_PASS_SPECIAL "`~!@#$%^&*()-_=+|\\[{}];:'\",<.>/? "

/*
 * Description: 新旧口令比较函数
 * Notes：调用时必须按照第一个参数为已有数据，第二个参数为新输入数据的顺序
          为防止通过输入不同长度字符串嗅探出已有字符串长度
 */
LOCAL gint32 user_strcmp_s(const gchar *old_str, const gchar *new_str)
{
    gint32  i;
    guint32 ret            = 0;
    guchar  old_sha[32]    = {0};
    guchar  new_sha[32]    = {0};
    guchar *old_sha_result = NULL;
    guchar *new_sha_result = NULL;

    if (old_str == NULL || new_str == NULL) {
        return RET_ERR;
    }

    old_sha_result = SHA256((const guint8 *)old_str, strlen(old_str), old_sha);
    new_sha_result = SHA256((const guint8 *)new_str, strlen(new_str), new_sha);
    if (old_sha_result == NULL || new_sha_result == NULL) {
        (void)memset_s(old_sha, sizeof(old_sha), 0, sizeof(old_sha));
        (void)memset_s(new_sha, sizeof(new_sha), 0, sizeof(new_sha));
        return RET_ERR;
    }
    /* 32为old_sha数组长度 */
    for (i = 0; i < 32; i++) {
        ret |= old_sha[i] ^ new_sha[i];
    }

    (void)memset_s(old_sha, sizeof(old_sha), 0, sizeof(old_sha));
    (void)memset_s(new_sha, sizeof(new_sha), 0, sizeof(new_sha));
    return (ret ? RET_ERR : RET_OK);
}

/*
 * Description: 新口令倒写不能为旧口令
 */
LOCAL gint32 isstrrev(const gchar *new_str, const gchar *old_str)
{
    guint32 i;
    guint32 ret;
    guint32 new_len;
    guint32 old_len;

    /* 参数校验 */
    if ((new_str == NULL) || (old_str == NULL)) {
        return FALSE;
    }
    new_len = strlen(new_str);
    old_len = strlen(old_str);
    if ((new_len == 0) || (old_len == 0)) {
        return FALSE;
    }
    // 检测两个字符串长度
    ret = new_len ^ old_len;

    /*
      检测其中一个字符串是
      否是另一个字符串的倒写
     */
    for (i = 0; i < new_len; i++) {
        // 如果其中一个字符不同，则
        // 认为这两个串不是倒写相同关系
        ret |= (guchar)new_str[i % new_len] ^ (guchar)old_str[(new_len - 1 - i) % old_len];
    }

    if (ret != 0) {
        return FALSE;
    }

    return TRUE;
}

/*
 * Description: 判断字符串中是否包含特殊字符
 */
LOCAL gint32 isspecial(gint32 c)
{
    gchar *str = PWD_PASS_SPECIAL;

    // 是否包含特殊字符
    if (strchr(str, c)) {
        return 1;
    }

    return 0;
}

/*
 * Description: 判断字符串中是否满足复杂度要求
 */
LOCAL gint32 dal_check_complexity_status(const gchar *pw)
{
    gint32 isconlows = 0;  // 小写字符标志 1:包含 0:没有
    gint32 isconsups = 0;  // 大写字符标志 1:包含 0:没有
    gint32 iscondigs = 0;  // 数字标志     1:包含 0:没有
    gint32 isconspcs = 0;  // 特殊字符标志 1:包含 0:没有

    if (!(pw != NULL)) {
        return RET_ERR;
    }

    /* 找出字符串中包含的各种字符类型 */
    while (*pw != '\0') {
        if (!isconlows) {
            isconlows = (islower(*pw) ? 1 : 0);
        }

        if (!isconsups) {
            isconsups = (isupper(*pw) ? 1 : 0);
        }
        if (!iscondigs) {
            iscondigs = (isdigit(*pw) ? 1 : 0);
        }

        if (!isconspcs) {
            isconspcs = isspecial(*pw);
        }

        ++pw;
    }

    /*
     口令必须在满足包含
            －至少一个特殊字符：
              `~!@#$%^&*()-_=+\|[{}];:'",<.>/?和空格；    isconspcs
              的同时包含如下至少两种字符的组合:
            －至少一个小写字母；islower
            －至少一个大写字母；issupper
            －至少一个数字；    isdigit
     */
    if ((1 != isconspcs) || (2 > (isconlows + isconsups + iscondigs))) { /* 必须有特殊字符  1 ，另外需满足两项  2 */
        return RET_ERR;
    }

    return RET_OK;
}

/*
 * Description: 用户口令复杂度检查
 * Notes：口令安全复杂度规则:
 *        1、口令长度至少为min_pwd_length个字符，不提供设置口令最大长度限制的功能；
          2、口令必须在满足包含
           －至少一个特殊字符：`~!@#$%^&*()-_=+\|[{}];:'",<.>/?  和空格
             的同时包含如下至少两种字符的组合:
           －至少一个小写字母；
           －至少一个大写字母；
           －至少一个数字；
          3、口令不能和帐号或者帐号的倒写一样(注意区分大小写)；
          若设置的口令不符合上述规则，必须进行失败提示。
 */
gboolean is_pass_complexity_check_pass(const gchar *name, const gchar *passwd, guint32 min_pwd_length)
{
    /* 参数完整性校验 */
    if ((name == NULL) || (passwd == NULL) || (strlen(name) == 0)) {
        return FALSE;
    }
    // 口令长度至少为min_pwd_length个字符
    if (strlen(passwd) < min_pwd_length) {
        return FALSE;
    }
    // 口令不能和帐号或者帐号的倒写一样；
    if ((user_strcmp_s(name, passwd) == 0)  // 口令是否与用户名相同，函数返回值为0则相同
        || isstrrev(passwd, name)) {        // 口令是否与用户名的倒写相同，函数返回值为TRUE则相同
        return FALSE;
    }
    /*
     检测用户口令是否包含复杂度
     规则中的至少两种字符的组合
     */
    if (dal_check_complexity_status(passwd) != RET_OK) {
        return FALSE;
    }
    return TRUE;
}

/*
 * Description: VNC用户密码复杂度检查
 * Notes：启用密码检查功能时，VNC服务的登录密码取值规则为：
 *        1、长度要求：必须为8个字符。
          2、复杂度要求：
           －至少包含一个空格或以下特殊字符：
             `~!@#$%^&*()-_=+\|[{}];:'",<.>/?
           －至少包含以下两种字符：
             大写字母：A～Z
             小写字母：a～z
             数字：0～9
 */
gboolean is_vnc_password_complexity_check_pass(const gchar *password)
{
    /* 参数完整性校验 */
    if (password == NULL) {
        return FALSE;
    }

    // 密码长度必须为8
    if (strlen(password) != 8) {
        return FALSE;
    }

    /*
     检测用户口令是否包含复杂度
     规则中的至少两种字符的组合
     */
    if (dal_check_complexity_status(password) != RET_OK) {
        return FALSE;
    }
    return TRUE;
}

/*
 * 翻转:高\低4位交换,从左向右依次交换高\低2位
 */
LOCAL guint8 reverse(guint8 byte)
{
    byte = ((byte & 0xF0) >> 4) | ((byte & 0x0F) << 4);  // 4位反转
    byte = ((byte & 0xCC) >> 2) | ((byte & 0x33) << 2);  // 2位反转
    byte = ((byte & 0xAA) >> 1) | ((byte & 0x55) << 1);
    return byte;
}

/*
 * VNC鉴权过程中的DES加密函数
 */
gint32 vnc_encrypt_bytes(const guchar key[KEYLENS], const guchar *input,
    const size_t inlen, guchar *output, gint32 *outlen)
{
    guint8          Revkey[KEYLENS];  // IBMC密码长度必须为8个字符，不设初始值
    gint32          temp_len;
    EVP_CIPHER_CTX *encrypt;
    gint32          i;
    for (i = 0; i < KEYLENS; i++) {
        Revkey[i] = reverse(key[i]);
    }

    OSSL_PROVIDER_set_default_search_path(NULL, "/usr/lib64/");
    const OSSL_PROVIDER *legacy_provider = OSSL_PROVIDER_load(NULL, "legacy");
    if (legacy_provider == NULL) {
        debug_log(DLOG_ERROR, "Load openssl provider failed, OpenSSL error: %s",
                  ERR_error_string(ERR_get_error(), NULL));
    }

    encrypt = EVP_CIPHER_CTX_new();
    if (encrypt == NULL) {
        debug_log(DLOG_ERROR, "Create cipher context failed.");
        (void)memset_s(Revkey, sizeof(Revkey), 0, sizeof(Revkey));
        return RET_ERR;
    }

    if (EVP_EncryptInit_ex(encrypt, EVP_des_ecb(), NULL, Revkey, NULL) == 0) {
        debug_log(DLOG_ERROR, "OpenSSL encrypt init failed, OpenSSL error: %s",
                  ERR_error_string(ERR_get_error(), NULL));
        EVP_CIPHER_CTX_free(encrypt);
        (void)memset_s(Revkey, sizeof(Revkey), 0, sizeof(Revkey));
        return RET_ERR;
    }
    if (EVP_EncryptUpdate(encrypt, output, &temp_len, input, inlen) == 0) {
        debug_log(DLOG_ERROR, "OpenSSL encrypt update failed, OpenSSL error: %s",
                  ERR_error_string(ERR_get_error(), NULL));
        EVP_CIPHER_CTX_free(encrypt);
        (void)memset_s(Revkey, sizeof(Revkey), 0, sizeof(Revkey));
        return RET_ERR;
    }
    *outlen = temp_len;

    if (EVP_EncryptFinal_ex(encrypt, output + temp_len, &temp_len) == 0) {
        debug_log(DLOG_ERROR, "OpenSSL encrypt final failed, OpenSSL error: %s",
                  ERR_error_string(ERR_get_error(), NULL));
        EVP_CIPHER_CTX_free(encrypt);
        (void)memset_s(Revkey, sizeof(Revkey), 0, sizeof(Revkey));
        return RET_ERR;
    }
    *outlen += temp_len;

    EVP_CIPHER_CTX_free(encrypt);
    (void)memset_s(Revkey, sizeof(Revkey), 0, sizeof(Revkey));
    return RET_OK;
}

/*
 * Description: 生成公私钥对，注意：出参为public_key、private_key(需要调用者释放)
 */
gint32 generate_key_pair(gchar **public_key, gchar **private_key)
{
    gint32 ret;
    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX *pkctx = NULL;
    pkctx = EVP_PKEY_CTX_new_id(EVP_PKEY_SM2, NULL);    // 创建sm2 上下文
    if (pkctx == NULL) {
        debug_log(DLOG_ERROR, "new evp pkey ctx failed");
        return RET_ERR;
    }

    ret = EVP_PKEY_keygen_init(pkctx);  // 初始化sm2 上下文
    if (ret == RET_ERR) {
        debug_log(DLOG_ERROR, "EVP_PKEY_keygen_init failed");
        EVP_PKEY_CTX_free(pkctx);
        return RET_ERR;
    }

    ret = EVP_PKEY_keygen(pkctx, &pkey);    // 生成密钥对
    if (ret == RET_ERR) {
        debug_log(DLOG_ERROR, "[security] generate pkey failed");
        EVP_PKEY_CTX_free(pkctx);
        return RET_ERR;
    }
    /* pkey对象转字符串 */
    ret = convert_private_key_to_string(pkey, private_key);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "[security] convert private key to string failed");
        EVP_PKEY_CTX_free(pkctx);
        EVP_PKEY_free(pkey);
        return ret;
    }
    ret = convert_public_key_to_string(pkey, public_key);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "[security] convert public key to string failed");
        EVP_PKEY_CTX_free(pkctx);
        EVP_PKEY_free(pkey);
        return ret;
    }
    EVP_PKEY_CTX_free(pkctx);
    EVP_PKEY_free(pkey);
    return RET_OK;
}

/*
 * Description: EVP公钥加密方法
 */
gint32 encrypt_with_public_key(const gchar *pub_key, gint32 pub_key_len, const guchar *passwd, size_t passwd_len,
    guchar **cipher_text)
{
    size_t len = 0;
    EVP_PKEY *pkey = convert_string_to_pkey(pub_key, pub_key_len, FALSE);
    if (pkey == NULL) {
        debug_log(DLOG_ERROR, "[security] convert public key string to pkey failed");
        return RET_ERR;
    }

    /* 初始化上下文 */
    EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new(pkey, NULL);
    if (ctx == NULL) {
        debug_log(DLOG_ERROR, "[security] new evp pkey_ctx failed");
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }
    if (EVP_PKEY_encrypt_init(ctx) <= 0) {
        debug_log(DLOG_ERROR, "[security] init evp pkey_ctx failed");
        EVP_PKEY_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }

    if (EVP_PKEY_encrypt(ctx, NULL, &len, passwd, passwd_len) <= 0) {
        debug_log(DLOG_ERROR, "[security] init encrypt plain text failed");
        EVP_PKEY_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }
    if (len == 0) {
        debug_log(DLOG_ERROR, "[security] init encrypt plain text failed");
        EVP_PKEY_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }

    /* 分配密文空间 */
    *cipher_text = (guchar *)OPENSSL_malloc(len);
    if (!*cipher_text) {
        debug_log(DLOG_ERROR, "[security] malloc cipher text failed");
        EVP_PKEY_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }
    gint32 ret = EVP_PKEY_encrypt(ctx, *cipher_text, &len, passwd, passwd_len);
    EVP_PKEY_CTX_free(ctx);
    if (ret <= 0 || len <=0) {
        debug_log(DLOG_ERROR, "[security] encrypt plain text failed");
        EVP_PKEY_free(pkey);
        /* 加密失败，释放内存 */
        OPENSSL_free(*cipher_text);
        *cipher_text = NULL;
        return RET_ERR;
    }
    EVP_PKEY_free(pkey);
    return len;
}

/*
 * Description: EVP私钥解密方法
 */
gint32 decrypt_with_private_key(const gchar *priv_key, gint32 priv_kev_len, const guchar *ciphertext,
    size_t ciphertext_len, guchar **plaintext)
{
    size_t len = 0;
    EVP_PKEY *pkey = convert_string_to_pkey(priv_key, priv_kev_len, TRUE);
    if (pkey == NULL) {
        debug_log(DLOG_ERROR, "[security] convert private key string to pkey failed");
        return RET_ERR;
    }
    /* 初始化ctx */
    EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new(pkey, NULL);
    if (ctx == NULL) {
        debug_log(DLOG_ERROR, "[security] new evp pkey_ctx failed");
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }
    if (EVP_PKEY_decrypt_init(ctx) <= 0) {
        debug_log(DLOG_ERROR, "[security] init evp pkey_ctx failed");
        EVP_PKEY_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }

    if (EVP_PKEY_decrypt(ctx, NULL, &len, ciphertext, ciphertext_len) <= 0) {
        debug_log(DLOG_ERROR, "[security] init decrypt cipher text failed");
        EVP_PKEY_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }
    if (len == 0) {
        debug_log(DLOG_ERROR, "[security] init decrypt cipher text failed");
        EVP_PKEY_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }

    /* 分配明文空间 */
    *plaintext = (guchar *)OPENSSL_malloc(len);
    if (!*plaintext) {
        debug_log(DLOG_ERROR, "[security] malloc plain text failed");
        EVP_PKEY_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return RET_ERR;
    }

    gint32 ret = EVP_PKEY_decrypt(ctx, *plaintext, &len, ciphertext, ciphertext_len);
    EVP_PKEY_CTX_free(ctx);
    if (ret <= 0 || len <= 0) {
        /* 解密失败，释放内存 */
        debug_log(DLOG_ERROR, "[security] decrypt cipher text failed");
        EVP_PKEY_free(pkey);
        OPENSSL_free(*plaintext);
        *plaintext = NULL;
        return RET_ERR;
    }
    EVP_PKEY_free(pkey);
    return len;
}

LOCAL gint32 pattern_validator(const gchar *pattern)
{
    // 不可使用空正则
    gsize len = strlen(pattern);
    if (len == 0) {
        debug_log(DLOG_ERROR, "invalid data length");
        return RET_ERR;
    }

    // 不可使用非精准匹配
    if (pattern[0] != '^' || pattern[len - 1] != '$') {
        debug_log(DLOG_ERROR, "invalid pattern");
        return RET_ERR;
    }

    return RET_OK;
}

gint32 check_pattern(const gchar *pattern)
{
    if (pattern_validator(pattern) != RET_OK) {
        return RET_ERR;
    }

    GRegex *regex = g_regex_new(pattern, (GRegexCompileFlags)0x0, (GRegexMatchFlags)0x0, NULL);
    if (regex == NULL) {
        debug_log(DLOG_ERROR, "invalid pattern");
        return RET_ERR;
    }
    g_regex_unref(regex);
    return RET_OK;
}

gint32 verify_passwd_with_pattern(const gchar *pattern, const gchar *passwd)
{
    if (pattern_validator(pattern) != RET_OK) {
        return RET_ERR;
    }

    gint32 ret = RET_OK;
    GRegex *regex = g_regex_new(pattern, (GRegexCompileFlags)0x0, (GRegexMatchFlags)0x0, NULL);
    if (regex == NULL) {
        debug_log(DLOG_ERROR, "invalid pattern");
        return RET_ERR;
    }
    GMatchInfo *match_info = NULL;
    gboolean is_match = g_regex_match(regex, passwd, (GRegexMatchFlags)0x0, &match_info);
    if (!is_match) {
        debug_log(DLOG_ERROR, "password regex match failed");
        ret = RET_ERR;
    }
    g_regex_unref(regex);
    return ret;
}