/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2010-2022. All rights reserved.
 * Description: ldap接口库
 * Create:      2010-1-28
 */
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include "openssl/x509.h"
#include "openssl/ssl.h"
#include "sasl/sasl.h"
#include "ldap_auth_parse_info.h"
#include "network.h"

/*
 * Description: 将用户名中的特殊字符进行转义处理
 */
LOCAL gint32 escape_string(const gint8 *username, gint8 *escape_str, size_t str_len)
{
#define ESCAPE_LEN 3
    guint16 i;
    guint16 count = 0;
    gint32 ret;
    // 需转义的字符和转义后的字符一一对应
    const gchar to_be_replaced[] = {'(', ')', '*', '\\'};
    const gchar replace[][ESCAPE_LEN + 1] = {"\\28", "\\29", "\\2a", "\\5c"};

    while (*username && count < (str_len - ESCAPE_LEN)) {
        for (i = 0; i < sizeof(to_be_replaced); i++) {
            if (*username != to_be_replaced[i]) {
                continue;
            }

            ret = strncpy_s((gchar *)escape_str, (str_len - count), replace[i], ESCAPE_LEN);
            if (ret != 0) {
                debug_log(DLOG_ERROR, "strncpy_s fail");
                return LDAP_AUTH_ERROR;
            }
            escape_str += ESCAPE_LEN;
            count += ESCAPE_LEN;
            break;
        }
        if (i == sizeof(to_be_replaced)) {
            *escape_str = *username;
            escape_str++;
            count++;
        }
        username++;
    }

    if (*username == '\0') {
        *escape_str = '\0';
        return LDAP_AUTH_SUCCESS;
    }

    return LDAP_AUTH_ERROR;
}

/*
 * Description: 释放用户组内存
 */
LOCAL void release_groupdn(PAM_LDAP_CONFIG_S *result)
{
    gint32 i;

    for (i = 0; i < MAX_USER_GROUP; i++) {
        if (result->groupdn[i] != NULL) {
            g_free(result->groupdn[i]);
            result->groupdn[i] = NULL;
        }
    }
}

/*
 * Description: 释放配置文件生成空间
 */
LOCAL void release_config(PAM_LDAP_CONFIG_S **pconfig)
{
    PAM_LDAP_CONFIG_S *c = *pconfig;

    if (c == NULL) {
        return;
    }

    if (c->host != NULL) {
        g_free(c->host);
        c->host = NULL;
    }

    if (c->uri != NULL) {
        g_free(c->uri);
        c->uri = NULL;
    }

    if (c->base != NULL) {
        g_free(c->base);
        c->base = NULL;
    }

    if (c->filter != NULL) {
        g_free(c->filter);
        c->filter = NULL;
    }

    release_groupdn(c);

    g_free(c);
    c = NULL;
    *pconfig = NULL;
    return;
}

/*
 * Description: 清楚连接所使用的资源
 */
LOCAL void ldap_cleanup_session(PAM_LDAP_SESSION_S **session)
{
    if (*session == NULL) {
        return;
    }

    if ((*session)->ld != NULL) {
        (void)ldap_unbind((*session)->ld);
        (*session)->ld = NULL;
    }

    release_config(&((*session)->conf));
    g_free(*session);
    *session = NULL;
    return;
}

/*
 * Description: 开启一个ldap连接
 */
LOCAL gint32 ldap_get_session(PAM_LDAP_SESSION_S **psession, LDAP_AUTH_INFO *ldap_auth_info)
{
    gint32 rc;

    *psession = NULL;

    PAM_LDAP_SESSION_S *session = (PAM_LDAP_SESSION_S *)g_malloc0(sizeof(PAM_LDAP_SESSION_S));
    if (session == NULL) {
        return LDAP_AUTH_ERROR;
    }

    session->ld = NULL;
    session->conf = NULL;

    rc = read_ldap_config(&session->conf, ldap_auth_info);
    if (rc != LDAP_AUTH_SUCCESS) {
        release_config(&session->conf);
        g_free(session);
        return rc;
    }

    *psession = session;
    return LDAP_AUTH_SUCCESS;
}

/*
 * Description: 重新绑定到ldap服务器上
 */
LOCAL gint32 rebind_proc(LDAP *ld, LDAP_CONST gchar *url, ber_tag_t request, ber_int_t msgid, void *arg)
{
    return LDAP_AUTH_SUCCESS;
}

/*
 * Description: 获取字符串行ldap属性
 */
LOCAL gint32 get_string_values(LDAP *ld, LDAPMessage *e, gint8 *attr, gint8 ***ptr)
{
    gint8 **vals = NULL;

    vals = (gint8 **)ldap_get_values(ld, e, attr);
    if (vals == NULL) {
        return LDAP_AUTH_UNAVAIL;
    }

    *ptr = vals;
    return LDAP_AUTH_SUCCESS;
}

LOCAL gint32 verify_callback(gint32 ok, X509_STORE_CTX *ctx)
{
    if (ok) {
        return ok;
    }

    gint32 sslRet = X509_STORE_CTX_get_error(ctx);
    const gchar* err = NULL;
    switch (sslRet) {
        case X509_V_ERR_UNABLE_TO_GET_CRL:
        case X509_V_ERR_CRL_HAS_EXPIRED:
        case X509_V_ERR_CRL_NOT_YET_VALID:
            debug_log(DLOG_DEBUG, "CRL: Verification failed... but ignored : %d", sslRet);
            return 1;
        default:
            err = X509_verify_cert_error_string(sslRet);
            if (err)
                debug_log(DLOG_ERROR, "CRL: Failed to verify : %s", err);
            return 0;
    }
    return sslRet;
}

LOCAL void ldap_tls_cb(LDAP * ld, SSL * ssl, SSL_CTX * ctx, void * arg)
{
    SSL_set_verify(ssl, SSL_VERIFY_PEER, verify_callback);
    debug_log(DLOG_INFO, "verify call back is set...");
    return;
}

/*
 * Description: 设置LDAP证书和吊销列表的相关配置
 */
LOCAL void set_ldap_ca_and_crl_conf(LDAP *ld, const LDAP_AUTH_INFO *ldap_auth_info)
{
    gint32 rc;
    const gint32 crl_check_peer = LDAP_OPT_X_TLS_CRL_PEER;

    rc = ldap_set_option(ld, LDAP_OPT_X_TLS_CACERTFILE, ldap_auth_info->cert_inner_dir);
    if (rc != RET_OK) {
        debug_log(DLOG_ERROR, "ldap_set_option LDAP_OPT_X_TLS_CACERTDIR fail, ret :%d", rc);
    }

    rc = ldap_set_option(ld, LDAP_OPT_X_TLS_CRLCHECK, &crl_check_peer);
    if (rc != RET_OK) {
        debug_log(DLOG_ERROR, "ldap set option LDAP_OPT_X_TLS_CRLCHECK fail, ret :%d", rc);
    }

    // 直接校验，若找不到crl吊销列表或吊销列表过期则跳过
    rc = ldap_set_option(ld, LDAP_OPT_X_TLS_CONNECT_CB, (void *)ldap_tls_cb);
    if (rc != RET_OK) {
        fprintf(stderr, "ldap set option LDAP_OPT_X_TLS_CONNECT_CB fail, ret :%d", rc);
        return;
    }
}

/*
 * Description: 清除LDAP证书和吊销列表的相关配置
 */
LOCAL void clear_ldap_ca_and_crl_conf(LDAP *ld)
{
    gint32 rc;
    const gint32 crl_check_none = LDAP_OPT_X_TLS_CRL_NONE;

    rc = ldap_set_option(ld, LDAP_OPT_X_TLS_CACERTDIR, NULL);
    if (rc != RET_OK) {
        debug_log(DLOG_ERROR, "ldap_set_option LDAP_OPT_X_TLS_CACERTDIR fail, ret :%d", rc);
    }

    rc = ldap_set_option(ld, LDAP_OPT_X_TLS_CRLCHECK, &crl_check_none);
    if (rc != RET_OK) {
        debug_log(DLOG_ERROR, "ldap set option LDAP_OPT_X_TLS_CRLCHECK fail, ret :%d", rc);
    }
}

/*
 * Description: Initialize the session handle of LDAP.
 */
LOCAL gint32 ldap_initialize_handle(PAM_LDAP_SESSION_S *session)
{
    /* Make up the secure URL for LDAP. */
    gint32 ret;
    gchar secure_url[MAX_RSC_URI_LEN] = {0};
    if (vos_ipv6_addr_valid_check((const guchar *)(session->conf->host)) == RET_OK) {
        ret = snprintf_s(secure_url, sizeof(secure_url), sizeof(secure_url) - 1, "ldaps://[%s]:%d/",
            session->conf->host, session->conf->port);
    } else {
        ret = snprintf_s(secure_url, sizeof(secure_url), sizeof(secure_url) - 1, "ldaps://%s:%d/",
            session->conf->host, session->conf->port);
    }

    if (ret <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", ret);
    }

    /* Initialize the session handle of LDAP using secure URL. */
    ret = ldap_initialize(&session->ld, secure_url);
    if (ret != LDAP_SUCCESS) {
        debug_log(DLOG_ERROR, "ldap_initialize err(%s)", ldap_err2string(ret));
        return LDAP_AUTH_ERROR;
    }

    if (session->ld == NULL) {
        debug_log(DLOG_ERROR, "ldap_initialize handle is invalid");
        return LDAP_AUTH_ERROR;
    }

    return LDAP_SUCCESS;
}

/*
 * Description: Set the authentication and certificate related options of LDAP.
 */
LOCAL gint32 ldap_set_certificate_option(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info)
{
    gint32 option;
    gint32 ret;

    if (session->conf->cert_status != ENABLE) {
        /* 设置证书路径为无效，避免异常证书对以下的设置产生影响 */
        clear_ldap_ca_and_crl_conf(session->ld);
        option = LDAP_OPT_X_TLS_NEVER;
        ret = ldap_set_option(session->ld, LDAP_OPT_X_TLS_REQUIRE_CERT, &option);
        if (ret != LDAP_SUCCESS) {
            debug_log(DLOG_ERROR, "set ldap option LDAP_OPT_X_TLS_REQUIRE_CERT failed, error code:0x%x", ret);
        }
        return LDAP_SUCCESS;
    }

    // 3 代表 LDAP_OPT_X_TLS_ALLOW，在校验级别为allow时，不设置ca，否则在目录下无CA证书的情况下会报错
    if (session->conf->cert_verifi_Level == 3) {
        clear_ldap_ca_and_crl_conf(session->ld);
    } else {
        set_ldap_ca_and_crl_conf(session->ld, ldap_auth_info);
    }

    option = session->conf->cert_verifi_Level;
    ret = ldap_set_option(session->ld, LDAP_OPT_X_TLS_REQUIRE_CERT, &option);
    if (ret != LDAP_SUCCESS) {
        debug_log(DLOG_ERROR, "set ldap option LDAP_OPT_X_TLS_REQUIRE_CERT failed, error code:0x%x", ret);
    }

    return LDAP_SUCCESS;
}

/*
 * Set the context options for LDAP.
 */
LOCAL void ldap_set_context_option(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info)
{
    gint32 option = 0;
    gint32 ret;
    if (session->conf->cert_status == ENABLE && session->conf->cert_verifi_Level != LDAP_OPT_X_TLS_ALLOW) {
        /* Add default TLS secure protocol and ciphers */
        option = LDAP_OPT_X_TLS_PROTOCOL_TLS1_2;
        ret = ldap_set_option(session->ld, LDAP_OPT_X_TLS_PROTOCOL_MIN, &option);
        if (ret != LDAP_SUCCESS) {
            debug_log(DLOG_ERROR, "set ldap option LDAP_OPT_X_TLS_PROTOCOL_MIN failed, error code:0x%x", ret);
        }

        ret = ldap_set_option(session->ld, LDAP_OPT_X_TLS_CIPHER_SUITE, ldap_auth_info->tls_cipher);
        if (ret != LDAP_SUCCESS) {
            debug_log(DLOG_ERROR, "set ldap option LDAP_OPT_X_TLS_CIPHER_SUITE failed, error code: 0x%x", ret);
        }
    }

    ret = ldap_set_option(session->ld, LDAP_OPT_X_TLS_NEWCTX, &option);
    if (ret != LDAP_SUCCESS) {
        debug_log(DLOG_ERROR, "set ldap option LDAP_OPT_X_TLS_NEWCTX failed, error code: 0x%x", ret);
    }
}

/*
 * Description: 打开一个ldap连接，用户后续操作
 */
LOCAL gint32 open_session(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info)
{
    gint32 ret = ldap_initialize_handle(session);
    if (ret != LDAP_SUCCESS) {
        return ret;
    }

    ret = ldap_set_certificate_option(session, ldap_auth_info);
    if (ret != LDAP_SUCCESS) {
        return ret;
    }

    ldap_set_context_option(session, ldap_auth_info);

    (void)ldap_set_option(session->ld, LDAP_OPT_PROTOCOL_VERSION, &session->conf->version);

    (void)ldap_set_rebind_proc(session->ld, rebind_proc, (void *)session);

    (void)ldap_set_option(session->ld, LDAP_OPT_DEREF, &session->conf->deref);

    (void)ldap_set_option(session->ld, LDAP_OPT_TIMELIMIT, &session->conf->timelimit);

    struct timeval tv;
    tv.tv_sec = session->conf->bind_timelimit;
    tv.tv_usec = 0;
    (void)ldap_set_option(session->ld, LDAP_OPT_NETWORK_TIMEOUT, &tv);

    (void)ldap_set_option(session->ld, LDAP_OPT_RESTART, session->conf->restart ? LDAP_OPT_ON : LDAP_OPT_OFF);

    // 设置超时时长为30秒
    tv.tv_sec = 30;
    ldap_set_option(session->ld, LDAP_OPT_TIMEOUT, &tv);
    return LDAP_AUTH_SUCCESS;
}

/*
 * Description: 执行ldap_simple_bind并且判断结果
 */
LOCAL gint32 do_ldap_simple_bind(PAM_LDAP_SESSION_S *session, gint8 *userdn, guint32 userdn_len, gint8 *userpw)
{
    gint32 rc;
    gint32 msgid;
    struct timeval timeout;
    LDAPMessage *result = NULL;

    if (userdn_len == 0) {
        return LDAP_AUTH_ERROR;
    }
    msgid = ldap_simple_bind(session->ld, userdn, userpw);
    debug_log(DLOG_DEBUG, "userdn=%s", userdn);

    if (msgid == -1) {
        gint32 ldap_errno = 0;
        (void)ldap_get_option(session->ld, LDAP_OPT_ERROR_NUMBER, &ldap_errno);
        debug_log(DLOG_ERROR, "ldap_simple_bind fail, err: %s", ldap_err2string(ldap_errno));
        return LDAP_AUTH_INVALID_PASSWD;
    }

    timeout.tv_sec = session->conf->bind_timelimit; /* default 10 */
    timeout.tv_usec = 0;
    rc = ldap_result(session->ld, msgid, FALSE, &timeout, &result);
    if ((rc == LDAP_SERVER_DOWN) || (rc == 0)) {
        debug_log(DLOG_ERROR, "ldap_simple_bind fail");

        if (result != NULL) {
            debug_log(DLOG_ERROR, "ldap_result  result is not free!");
            (void)ldap_msgfree(result);
        }

        return LDAP_AUTH_INVALID_PASSWD;
    }

    /* 把TRUE修改为1，表示释放result的内存，更清晰 */
    (void)ldap_parse_result(session->ld, result, &rc, 0, 0, 0, 0, 1);
    if (rc != LDAP_SUCCESS) {
        debug_log(DLOG_ERROR, "do_direct_bind: userdn (%s)  error trying to bind (%s)", userdn, ldap_err2string(rc));
        return LDAP_AUTH_INVALID_PASSWD;
    }

    return LDAP_AUTH_SUCCESS;
}

LOCAL gint8 add_prefix_userdn(PAM_LDAP_SESSION_S *session, LDAP_USERDN_INFO *userdn_info, const gchar *username)
{
    gint32 iRet;
    gint8 flag = 0;
    /* 如果用户域未配置"CN=用户名" 或"UID=用户名"  则在此先 添加CN= 用户名去绑定，若绑定失败，则添加UID=用户名去绑定 */
    if ((strcasestr((gchar *)(session->conf->base), userdn_info->cn) == NULL) &&
        (strcasestr((gchar *)(session->conf->base), userdn_info->uid) == NULL)) {
        iRet = snprintf_s((gchar *)userdn_info->userdn, LDAP_USERDN_MAX_LEN, LDAP_USERDN_MAX_LEN - 1, "CN=%s,%s",
            username, session->conf->base);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
        flag = LDAP_USERDN_TRY_UID;
    } else if (strcasestr((gchar *)(session->conf->base), userdn_info->cn) != NULL) {
        iRet = snprintf_s((gchar *)userdn_info->userdn, LDAP_USERDN_MAX_LEN, LDAP_USERDN_MAX_LEN - 1, "%s",
            session->conf->base);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
    } else {
        iRet = snprintf_s((gchar *)userdn_info->userdn, LDAP_USERDN_MAX_LEN, LDAP_USERDN_MAX_LEN - 1, "%s",
            session->conf->base);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
        flag = LDAP_USERDN_START_WITH_UID;
    }
    return flag;
}

/*
 * Description: 直接向ldap服务器绑定用户，验证用户是否合法
 */
LOCAL gint32 do_direct_bind(PAM_LDAP_SESSION_S *session, const gchar *username, LDAP_AUTH_INFO *ldap_auth_info)
{
    gint32 iRet;
    gint32 rc;
    LDAP_USERDN_INFO userdn_info = {0};
    gint8 flag = 0;

    if (session->ld == NULL) {
        rc = open_session(session, ldap_auth_info);
        if (rc != LDAP_AUTH_SUCCESS) {
            return rc;
        }
    }

    debug_log(DLOG_DEBUG, "now do simple bind.....");
    /* 因为不能要求用户输入预置用户和密码, 只好使用pam传递的用户名和密码进行绑定 */
    (void)memset_s(userdn_info.userdn, sizeof(userdn_info.userdn), 0, sizeof(userdn_info.userdn));

    (void)memset_s(userdn_info.cn, sizeof(userdn_info.cn), 0, sizeof(userdn_info.cn));
    iRet = snprintf_s(userdn_info.cn, sizeof(userdn_info.cn), sizeof(userdn_info.cn) - 1, "CN=%s", username);
    if (iRet <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
    }

    (void)memset_s(userdn_info.uid, sizeof(userdn_info.uid), 0, sizeof(userdn_info.uid));
    iRet = snprintf_s(userdn_info.uid, sizeof(userdn_info.uid), sizeof(userdn_info.uid) - 1, "UID=%s", username);
    if (iRet <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
    }
    flag = add_prefix_userdn(session, &userdn_info, username);

    rc = do_ldap_simple_bind(session, (gint8 *)userdn_info.userdn, sizeof(userdn_info.userdn),
        (gint8 *)ldap_auth_info->password);
    if ((flag == LDAP_USERDN_TRY_UID) && (rc != LDAP_AUTH_SUCCESS)) {
        (void)memset_s(userdn_info.userdn, sizeof(userdn_info.userdn), 0, sizeof(userdn_info.userdn));
        iRet = snprintf_s((gchar *)userdn_info.userdn, LDAP_USERDN_MAX_LEN, LDAP_USERDN_MAX_LEN - 1, "UID=%s,%s",
            username, session->conf->base);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
        rc = do_ldap_simple_bind(session, (gint8 *)userdn_info.userdn, sizeof(userdn_info.userdn),
            (gint8 *)ldap_auth_info->password);
        if (rc == LDAP_AUTH_SUCCESS) {
            session->conf->dn_with_uid = 1;
        }
    }

    if ((flag == LDAP_USERDN_START_WITH_UID) && (rc == LDAP_AUTH_SUCCESS)) {
        session->conf->dn_with_uid = 1;
    }

    return rc;
}

#ifdef LDAP_DEBUG
/*
 * Description: 得到bmc支持的sasl 方法，目前是打印输出
 */
void get_local_sasl_support_mech(LDAP *ld)
{
    gchar **mechlist;
    guint32 lup, flag;
    gint32 rc;

    debug_log(DLOG_DEBUG, "now get local sasl mechlist...");
    rc = ldap_get_option(ld, LDAP_OPT_X_SASL_MECHLIST, &mechlist);
    if (rc != 0) {
        debug_log(DLOG_ERROR, "get LDAP_OPT_X_SASL_MECHLIST err!!");
    } else {
        debug_log(DLOG_DEBUG, "mechlist [");
        flag = 0;

        for (lup = 0; mechlist[lup]; lup++) {
            if (flag) {
                debug_log(DLOG_DEBUG, ",");
            } else {
                flag++;
            }

            debug_log(DLOG_DEBUG, "%s", mechlist[lup]);
        }

        debug_log(DLOG_DEBUG, "]");
    }

    return;
}
#endif

/*
 * Description: 设置sasl default值
 */
LOCAL SASL_DEFAULT *alloc_sasl_defaults(LDAP *ld, gchar *mechanisms, gchar *realm, gchar *authentication_id,
    gchar *passwd, gchar *authorization_id)
{
    SASL_DEFAULT *defaults = NULL;
    defaults = (SASL_DEFAULT *)g_malloc0(sizeof(SASL_DEFAULT));
    if (defaults == NULL) {
        debug_log(DLOG_ERROR, "in alloc_sasl_defaults,calloc get null!");
        return NULL;
    }

    defaults->mechanisms = strdup(mechanisms);
    defaults->realm = strdup(realm);
    defaults->authentication_id = strdup(authentication_id);
    defaults->pwd = strdup(passwd);
    defaults->authorization_id = strdup(authorization_id);

    if (defaults->mechanisms == NULL) {
        (void)ldap_get_option(ld, LDAP_OPT_X_SASL_MECH, &defaults->mechanisms);
    }

    if (defaults->realm == NULL) {
        (void)ldap_get_option(ld, LDAP_OPT_X_SASL_REALM, &defaults->realm);
    }

    if (defaults->authentication_id == NULL) {
        (void)ldap_get_option(ld, LDAP_OPT_X_SASL_AUTHCID, &defaults->authentication_id);
    }

    if (defaults->authorization_id == NULL) {
        (void)ldap_get_option(ld, LDAP_OPT_X_SASL_AUTHZID, &defaults->authorization_id);
    }

    defaults->response = NULL;
    defaults->response_number = 0;

    return defaults;
}

/*
 * Description: 释放sasl default内容
 */
LOCAL void free_sasl_defaults(SASL_DEFAULT *defaults)
{
    if (defaults == NULL) {
        return;
    }

    if (defaults->mechanisms) {
        free(defaults->mechanisms);
        defaults->mechanisms = NULL;
    }

    if (defaults->realm) {
        free(defaults->realm);
        defaults->realm = NULL;
    }

    if (defaults->authentication_id) {
        free(defaults->authentication_id);
        defaults->authentication_id = NULL;
    }

    if (defaults->pwd) {
        // 长度为0，安全函数报错
        if (strlen(defaults->pwd) != 0) {
            (void)memset_s((void *)defaults->pwd, strlen(defaults->pwd), 0, strlen(defaults->pwd));
        }

        free(defaults->pwd);
        defaults->pwd = NULL;
    }

    if (defaults->authorization_id) {
        free(defaults->authorization_id);
        defaults->authorization_id = NULL;
    }

    if (defaults->response) {
        for (gint32 i = 0; i < defaults->response_number; i++) {
            if (defaults->response[i]) {
                free(defaults->response[i]);
            }
        }
        free(defaults->response);
        defaults->response = NULL;
    }

    free(defaults);
    defaults = NULL;
    return;
}

/*
 * Description: 和SASL交互用户名、密码等信息，注意，该函数做了很多简化，目前只适应NTLM认证方式。
 */
LOCAL gint32 interaction(guint32 flags, sasl_interact_t *interact, SASL_DEFAULT *defaults)
{
    const gchar *dflt = interact->defresult;

    if (defaults == NULL) {
        debug_log(DLOG_ERROR, "in interaction, defaults is null!");
        return LDAP_UNAVAILABLE;
    }

    switch (interact->id) {
        case SASL_CB_GETREALM:
            dflt = defaults->realm;
            break;

        case SASL_CB_AUTHNAME:
            dflt = defaults->authentication_id;
            break;

        case SASL_CB_PASS:
            dflt = defaults->pwd;
            break;

        case SASL_CB_USER:
            dflt = defaults->authorization_id;
            break;

        case SASL_CB_NOECHOPROMPT:
            break;

        case SASL_CB_ECHOPROMPT:
            break;
        
        default :
            break;
    }

    if (flags == LDAP_SASL_QUIET) {
        /* don't prompt */
        return LDAP_OTHER;
    }

    /* input must be empty */
    interact->result = (dflt && *dflt) ? dflt : "";
    interact->len = (guint32)strlen((const gchar *)interact->result);

    return LDAP_SUCCESS;
}

/*
 * Description: SASL 交互的回调函数
 */
LOCAL gint32 sasl_interact_callback(LDAP *ld, guint32 flags, void *defaults, void *in)
{
    sasl_interact_t *interact = (sasl_interact_t *)in;

    if (ld == NULL) {
        return LDAP_PARAM_ERROR;
    }

    while (interact->id != SASL_CB_LIST_END) {
        gint32 rc = interaction(flags, interact, (SASL_DEFAULT *)defaults);
        if (rc) {
            return rc;
        }

        interact++;
    }

    return LDAP_AUTH_SUCCESS;
}

/*
 * Description: 输出ldap绑定失败原因
 */
LOCAL void print_ldap_error_message(PAM_LDAP_SESSION_S *session, gint32 rc)
{
    gchar *msg = NULL;

    if (session == NULL) {
        return;
    }
    (void)ldap_get_option(session->ld, LDAP_OPT_DIAGNOSTIC_MESSAGE, (void *)&msg);
    if (msg != NULL) {
        ldap_memfree(msg);
    }

    return;
}

LOCAL void do_sasl_bind_set_userdn(const PAM_LDAP_SESSION_S *session, const LDAP_AUTH_INFO *ldap_auth_info,
    gchar *userdn, size_t len, gint8 *flag)
{
    gchar cn[LDAP_USERFOLDER_MAX_LEN + 1] = {0};
    gchar uid[LDAP_USERFOLDER_MAX_LEN + 1] = {0};

    (void)memset_s(cn, sizeof(cn), 0, sizeof(cn));
    gint32 iRet = snprintf_s(cn, sizeof(cn), sizeof(cn) - 1, "CN=%s", ldap_auth_info->username);
    if (iRet <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
    }
    (void)memset_s(uid, sizeof(uid), 0, sizeof(uid));
    iRet = snprintf_s(uid, sizeof(uid), sizeof(uid) - 1, "UID=%s", ldap_auth_info->username);
    if (iRet <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
    }

    /* 如果用户域未配置"CN=用户名" 或"UID=用户名" 则在此添加"CN=用户名"去绑定,如果绑定失败则添加" UID= 用户名" 去绑定 */
    if ((strcasestr((gchar *)(session->conf->base), cn) == NULL) &&
        (strcasestr((gchar *)(session->conf->base), uid) == NULL)) {
        iRet = snprintf_s(userdn, len, len - 1, "CN=%s,%s", ldap_auth_info->username,
            session->conf->base);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
        *flag = LDAP_USERDN_TRY_UID;
    } else if (strcasestr((gchar *)(session->conf->base), cn) == NULL) {
        iRet = snprintf_s(userdn, len, len - 1, "%s", session->conf->base);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
    } else {
        iRet = snprintf_s(userdn, len, len - 1, "%s", session->conf->base);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
        *flag = LDAP_USERDN_START_WITH_UID;
    }

    debug_log(DLOG_DEBUG, "userdn: %s", userdn);
}

LOCAL void after_sasl_free_passwd(struct berval passwd)
{
    if (passwd.bv_val == NULL) {
        return;
    }
    if (passwd.bv_len != 0) {
        (void)memset_s((void *)passwd.bv_val, passwd.bv_len, 0, passwd.bv_len);
    }
    debug_log(DLOG_DEBUG, "after do sasl bind,then free val");
    free(passwd.bv_val);
}

LOCAL gint32 set_sasl_config(struct berval *passwd, LDAP_AUTH_INFO *ldap_auth_info)
{
    /* 设置sasl 认证插件所在路径 /data/plugin为暂定的 */
    gint32 rc = sasl_set_path(0, "/usr/lib");
    if (rc != 0) {
        debug_log(DLOG_ERROR, "set sasl plugin path err!");
        return LDAP_AUTH_ERROR;
    }

    passwd->bv_val = ber_strdup(ldap_auth_info->password);
    if (passwd->bv_val == NULL) {
        debug_log(DLOG_ERROR, "ber_strdup failed!");
        return LDAP_AUTH_ERROR;
    }

    passwd->bv_len = (ber_len_t)strlen(passwd->bv_val);
    return LDAP_AUTH_SUCCESS;
}

LOCAL gint32 try_ldap_sasl_interactive_bind(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info,
    struct berval passwd)
{
    gchar userdn[LDAP_USERDN_MAX_LEN] = {0};
    gint8 flag = 0;
    gchar *sasl_mech = "GSS-SPNEGO"; /* 目前我们只支持ntlm这种SASL认证方式 */
    gchar *sasl_realm = " ";
    guint32 sasl_flags = LDAP_SASL_AUTOMATIC;
    gchar *sasl_authc_id = ldap_auth_info->username;
    gchar *sasl_authz_id = ldap_auth_info->username;

    SASL_DEFAULT *defaults =
        alloc_sasl_defaults(session->ld, sasl_mech, sasl_realm, sasl_authc_id, (gchar *)passwd.bv_val, sasl_authz_id);
    if (defaults == NULL) {
        return 1;
    }

    (void)memset_s(userdn, sizeof(userdn), 0, sizeof(userdn));
    do_sasl_bind_set_userdn(session, ldap_auth_info, userdn, sizeof(userdn), &flag);

    gint32 rc = ldap_sasl_interactive_bind_s(session->ld, userdn, sasl_mech, NULL, NULL,
        sasl_flags, sasl_interact_callback, defaults);
    if ((flag == LDAP_USERDN_START_WITH_UID) && (rc == LDAP_SUCCESS)) {
        session->conf->dn_with_uid = 1;
    }

    if ((flag == LDAP_USERDN_TRY_UID) && (rc != LDAP_SUCCESS)) {
        print_ldap_error_message(session, rc);

        (void)memset_s(userdn, sizeof(userdn), 0, sizeof(userdn));
        gint32 iRet = snprintf_s(userdn, sizeof(userdn), sizeof(userdn) - 1, "UID=%s,%s", ldap_auth_info->username,
            session->conf->base);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }

        free_sasl_defaults(defaults);
        defaults = alloc_sasl_defaults(session->ld, sasl_mech, sasl_realm, sasl_authc_id, (gchar *)passwd.bv_val,
            sasl_authz_id);
        if (defaults == NULL) {
            return 1;
        }

        rc = ldap_sasl_interactive_bind_s(session->ld, userdn, sasl_mech, NULL, NULL, sasl_flags,
            sasl_interact_callback, defaults);
        if (rc == LDAP_SUCCESS) {
            session->conf->dn_with_uid = 1;
        }
    }

    free_sasl_defaults(defaults);
    return rc;
}

/*
 * Description: 使用SASL bind通过ldap服务器的验证，目前只支持微软AD的GSS-SPNEGO即NTLM
 */
static gint32 do_sasl_bind(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info)
{
    struct berval passwd = { 0, NULL };
    gint32 rc;

    if (session == NULL) {
        return LDAP_AUTH_ERROR;
    }

    if (session->ld == NULL) {
        rc = open_session(session, ldap_auth_info);
        if (rc != LDAP_AUTH_SUCCESS) {
            return rc;
        }
    }

    debug_log(DLOG_DEBUG, "now do sasl bind.....");

    rc = set_sasl_config(&passwd, ldap_auth_info);
    if (rc != LDAP_AUTH_SUCCESS) {
        return rc;
    }

    rc = try_ldap_sasl_interactive_bind(session, ldap_auth_info, passwd);
    if (rc != LDAP_SUCCESS && rc != 1) {
        print_ldap_error_message(session, rc);
        return LDAP_AUTH_INVALID_PASSWD;
    }

    after_sasl_free_passwd(passwd);
    return rc != LDAP_SUCCESS ? LDAP_AUTH_ERROR : LDAP_AUTH_SUCCESS;
}

/*
 * Description: 去掉标签，比较LDAP语句
 */
LOCAL gint32 compare_ldap_sentence_without_tag(const gchar *src_tag, const gchar *dst_tag)
{
    const gchar *p_src = src_tag;
    const gchar *p_dst = dst_tag;
    guint32 length;
    guint32 i = 0;

    if ((src_tag == NULL) || (dst_tag == NULL)) {
        debug_log(DLOG_DEBUG, "Input parameter is null.");
        return RET_ERR;
    }

    /* 不区分大小写比较:
           1、排除标签项问题；
           2、排除内容长度、字符不一致； */
    if (strcasecmp(p_src, p_dst) != 0) {
        debug_log(DLOG_DEBUG, "Result mismatch: src = %s, dst = %s.", p_src, p_dst);
        return RET_ERR;
    }

    /* 排除标签比较内容大小写 */
    length = (guint32)strlen(src_tag);

    do {
        p_src = p_src + LDAP_TAG_SIZE;
        p_dst = p_dst + LDAP_TAG_SIZE;
        i = i + LDAP_TAG_SIZE;

        while ((i <= length) && ((*p_src) != '\0')) {
            if ((*p_src) != (*p_dst)) {
                return RET_ERR;
            }

            if ((*p_src) == ',') {
                p_src++;
                p_dst++;
                i++;
                break;
            }

            p_src++;
            p_dst++;
            i++;
        }
    } while ((i <= length) && ((*p_src) != '\0'));

    debug_log(DLOG_DEBUG, "Result matched: src = %s, dst = %s.", src_tag, dst_tag);

    return RET_OK;
}

LOCAL gint32 do_search_user_group_check_hash(GHashTable *grp_hash, gint8 *group_name, guint32 tree_level)
{
    /* 如果足迹hash表的条目数超过2000，则退出，避免内存爆满导致BMC功能异常 */
    if (g_hash_table_size(grp_hash) >= MAX_LDAP_GRP_HASH_SIZE) {
        debug_log(DLOG_ERROR, "the group size reach the limit value %u", MAX_LDAP_GRP_HASH_SIZE);
        return LDAP_AUTH_UNKNOWN;
    }
    /* 如果该group已经被查找过，则退出此分支，避免环路 */
    if (g_hash_table_contains(grp_hash, (gconstpointer)(gchar *)group_name) == TRUE) {
        debug_log(DLOG_DEBUG, "the group [%s] has been route yet", (gchar *)group_name);
        return LDAP_AUTH_UNKNOWN;
    }

    /* 防止LDAP服务配置出现环，造成递归循环压栈溢出 */
    if (tree_level > MAX_TREE_DEPTH) {
        debug_log(DLOG_ERROR, "Out of range : tree_level(%u) > MaxDepth(%d).\n", tree_level, MAX_TREE_DEPTH);
        return LDAP_AUTH_UNKNOWN;
    }

    return RET_OK;
}

/*
 * Description: 递归搜索嵌套组，用于获取组名进行鉴权
 */
LOCAL gint32 do_search_user_group(PAM_LDAP_SESSION_S *session, gint8 *username, gint8 *group_name, gint8 *filter,
    guint32 tree_level, GHashTable *grp_hash)
{
    gchar *group_name_tmp = NULL;
    gint8 **member = NULL;
    LDAPMessage *res = NULL;
    LDAPMessage *msg = NULL;
    gchar userdn[LDAP_USERDN_MAX_LEN] = {0};

    gint32 ret = do_search_user_group_check_hash(grp_hash, group_name, tree_level);
    if (ret != RET_OK) {
        return LDAP_AUTH_UNKNOWN;
    }
    tree_level += 1;

    /* 未查找过的组，加入足迹hash表 */
    group_name_tmp = g_strdup((gchar *)group_name);
    if (!group_name_tmp) {
        debug_log(DLOG_ERROR, "g_strdup (%s) failed", (gchar *)group_name);
        return LDAP_AUTH_UNKNOWN;
    }

    g_hash_table_insert(grp_hash, (gpointer)group_name_tmp, (gpointer)1);

    if (session->conf->dn_with_uid == 0) {
        ret = snprintf_s(userdn, sizeof(userdn), sizeof(userdn) - 1, "CN=%s,%s", username, session->conf->base);
        if (ret <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", ret);
        }
    } else {
        ret = snprintf_s(userdn, sizeof(userdn), sizeof(userdn) - 1, "UID=%s,%s", username, session->conf->base);
        if (ret <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", ret);
        }
    }

    ret = ldap_search_ext_s(session->ld, (const gchar *)group_name, session->conf->scope, (const gchar *)filter,
        NULL, 0, NULL, NULL, NULL, 0, &res);
    if ((ret != LDAP_SUCCESS) && (ret != LDAP_TIMELIMIT_EXCEEDED) && (ret != LDAP_SIZELIMIT_EXCEEDED)) {
        debug_log(DLOG_ERROR, "ldap_search_ext_s failed:rc=%d", ret);

        if (res != NULL) {
            debug_log(DLOG_ERROR, "ldap_search_ext_s res is not free :rc=%d", ret);
            (void)ldap_msgfree(res);
        }

        return LDAP_AUTH_UNKNOWN;
    }

    msg = ldap_first_entry(session->ld, res);
    if (msg == NULL) {
        debug_log(DLOG_ERROR, "ldap_first_entry failed:rc=%d", ret);
        (void)ldap_msgfree(res);
        return LDAP_AUTH_UNKNOWN;
    }

    /*
     * it might be better to do a compare later, that way we can
     * avoid fetching any attributes at all
     */
    if (get_string_values(session->ld, msg, (gint8 *)LDAP_MEMBER, &member) == LDAP_AUTH_UNAVAIL) {
        debug_log(DLOG_ERROR, "get_string_values failed:rc=%d", ret);
        (void)ldap_msgfree(res);
        return LDAP_AUTH_UNKNOWN;
    }

    guint32 i = 0;
    while (member[i]) {
        if (compare_ldap_sentence_without_tag((gchar *)member[i], userdn) == RET_OK) {
            (void)ldap_value_free(member);
            (void)ldap_msgfree(res);
            return LDAP_AUTH_SUCCESS;
        }
        i++;
    }

    i = 0;
    while (member[i]) {
        ret = do_search_user_group(session, username, member[i], filter, tree_level, grp_hash);
        if (ret == LDAP_AUTH_SUCCESS) {
            (void)ldap_value_free(member);
            (void)ldap_msgfree(res);
            return LDAP_AUTH_SUCCESS;
        }
        i++;
    }

    (void)ldap_value_free(member);
    (void)ldap_msgfree(res);
    return LDAP_AUTH_ERROR;
}

/*
 * Description: 创建hash表，记录所有查找过的组和所有找到的组
 */
LOCAL gint32 search_hash_table_init(GHashTable **find_grp_hash, GHashTable **grp_found_hash)
{
    /* 创建hash表，记录所有查找过的组 */
    *find_grp_hash = g_hash_table_new_full(g_str_hash, g_str_equal, (GDestroyNotify)g_free, (GDestroyNotify)NULL);
    if (*find_grp_hash == NULL) {
        debug_log(DLOG_ERROR, "g_hash_table_new_full failed");
        return RET_ERR;
    }
  
    /* 创建hash表，记录所有找到的组 */
    *grp_found_hash = g_hash_table_new_full(g_str_hash, g_str_equal, (GDestroyNotify)g_free, (GDestroyNotify)NULL);
    if (*grp_found_hash == NULL) {
        debug_log(DLOG_ERROR, "g_hash_table_new_full grp_found_hash failed");
        return RET_ERR;
    }
    
    return RET_OK;
}
  
/*
 * Description: 通过输入用户名匹配用户名所属的用户组
 */
LOCAL gint32 do_search_by_username(PAM_LDAP_SESSION_S *session, gint8 *username, guint8 *group)
{
    gint8 filter[LDAP_FILT_MAXSIZ] = {0};
    gint32 flag = 0;
    guint32 tree_level = 0;
    GHashTable *find_grp_hash = NULL;
    GHashTable *grp_found_hash = NULL;
    gchar *group_name_tmp = NULL;
    gint32 ret = snprintf_s((gchar *)filter, sizeof(filter), sizeof(filter) - 1, LDAP_SEARCH_FILTER_G);
    if (ret <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", ret);
    }

    /* 搜索ldap数据库 */
    /* 创建hash表，记录所有查找过的组和所有找到的组 */
    ret = search_hash_table_init(&find_grp_hash, &grp_found_hash);
    if (ret != RET_OK) {
        return LDAP_AUTH_UNKNOWN;
    }

    for (guint8 j = 0; j < MAX_USER_GROUP; j++) {
        if (session->conf->groupdn[j] == NULL) {
            continue;
        }

        debug_log(DLOG_DEBUG, "groupdn:%s", session->conf->groupdn[j]);
        group_name_tmp = g_strdup((gchar *)session->conf->groupdn[j]);
        if (group_name_tmp == NULL) {
            debug_log(DLOG_ERROR, "g_strdup failed.");
            continue;
        }

        /* 已经查找过的组，并且与已查找到组groupdn相同，则直接加入 */
        if ((g_hash_table_contains(find_grp_hash, (gconstpointer)group_name_tmp) == TRUE) &&
            (g_hash_table_contains(grp_found_hash, (gconstpointer)group_name_tmp) == TRUE)) {
            debug_log(DLOG_DEBUG, "the group [%s] has been route and exist.", group_name_tmp);
            g_free(group_name_tmp);
            group[j] = j;
            continue;
        }

        ret = do_search_user_group(session, username, session->conf->groupdn[j], filter, tree_level, find_grp_hash);
        if (ret == LDAP_AUTH_SUCCESS) {
            group[j] = j;
            flag = 1;
            g_hash_table_insert(grp_found_hash, (gpointer)group_name_tmp, (gpointer)1);
        } else {
            // 异常场景下group_name_tmp未加入grp_found_hash，不会再g_hash_table_destory中被释放
            g_free(group_name_tmp);
        }
    }

    /* 销毁hash表，回收内存 */
    g_hash_table_destroy(find_grp_hash);
    g_hash_table_destroy(grp_found_hash);
    if (flag == 1) {
        debug_log(DLOG_DEBUG, "groupname is exist");
        return LDAP_AUTH_SUCCESS;
    }

    debug_log(DLOG_ERROR, "groupname is not exist");
    return LDAP_AUTH_UNKNOWN;
}

/*
 * Description: 通过输入用户名并指定返回memberof属性匹配用户名所属的用户组
 */
LOCAL gint32 do_search_group_owner(PAM_LDAP_SESSION_S *session, gchar *group_name, guint8 *group, guint32 tree_level,
    GHashTable *grp_hash)
{
    gchar* attrs[2] = {LDAP_MEMBEROF, NULL};
    LDAPMessage *res = NULL;
    LDAPMessage *msg = NULL;
    gchar **attrVal = NULL;
    gint16 attrCount;
    gint32 match_flag = 0;
    gint32 search_result = 0;

    gint32 ret = do_search_user_group_check_hash(grp_hash, (gint8 *)group_name, tree_level);
    if (ret != RET_OK) {
        return LDAP_AUTH_UNKNOWN;
    }
    tree_level += 1;

    /* 未查找过的组，加入足迹hash表 */
    gchar *group_name_tmp = g_strdup(group_name);
    if (!group_name_tmp) {
        debug_log(DLOG_ERROR, "g_strdup (%s) failed", (gchar *)group_name);
        return LDAP_AUTH_UNKNOWN;
    }
    g_hash_table_insert(grp_hash, (gpointer)group_name_tmp, (gpointer)1);

    /* 查找用户组 */
    for (guint8 i = 0; i < MAX_USER_GROUP; ++i) {
        if (compare_ldap_sentence_without_tag(group_name, (const gchar *)session->conf->groupdn[i]) == RET_OK) {
            match_flag = 1;
            group[i] = i;
        }
    }

    /* 继续查找组的owner */
    ret = ldap_search_ext_s(session->ld, (const gchar *)group_name, session->conf->scope,
        LDAP_SEARCH_FILTER_G, attrs, 0, NULL, NULL, NULL, 0, &res);
    if ((ret != LDAP_SUCCESS) && (ret != LDAP_TIMELIMIT_EXCEEDED) && (ret != LDAP_SIZELIMIT_EXCEEDED)) {
        debug_log(DLOG_ERROR, "ldap_search_ext_s failed:rc=%d", ret);

        if (res != NULL) {
            (void)ldap_msgfree(res);
        }

        /* 已经查找成功则返回认证OK */
        if (match_flag == 1) {
            return LDAP_AUTH_SUCCESS;
        }

        return LDAP_AUTH_UNKNOWN;
    }

    debug_log(DLOG_DEBUG, "[do_search_group_owner]:start");

    GHashTable *find_msg_own_hash =
        g_hash_table_new_full(g_direct_hash, g_direct_equal, (GDestroyNotify)NULL, (GDestroyNotify)NULL);
    if (!find_msg_own_hash) {
        debug_log(DLOG_ERROR, "g_hash_table_new_full  find_msg_own_hash failed");
        (void)ldap_msgfree(res);
        return LDAP_AUTH_UNKNOWN;
    }

    for (msg = ldap_first_entry(session->ld, res); msg != NULL; msg = ldap_next_entry(session->ld, res)) {
        /* 如果足迹hash表的条目数超过2000，则退出，避免内存爆满导致BMC功能异常 */
        if (g_hash_table_size(find_msg_own_hash) >= MAX_LDAP_GRP_HASH_SIZE) {
            debug_log(DLOG_ERROR, "the msg hash size reach the limit value %u", MAX_LDAP_GRP_HASH_SIZE);
            break;
        }

        /* 如果该节点已经被查找过，则退出此分支，避免环路 */
        if (g_hash_table_contains(find_msg_own_hash, (gconstpointer)msg) == TRUE) {
            debug_log(DLOG_ERROR, "the msg hash has been found yet");
            break;
        }

        /* 未查找过的节点，加入足迹hash表 */
        g_hash_table_insert(find_msg_own_hash, (gpointer)msg, (gpointer)1);

        attrVal = (gchar **)ldap_get_values(session->ld, msg, (gint8 *)LDAP_MEMBEROF);
        if (attrVal == NULL) {
            debug_log(DLOG_DEBUG, "[do_search_group_owner]:continue");
            continue;
        }

        attrCount = ldap_count_values((gint8 **)attrVal);

        for (gint32 i = 0; i < attrCount; ++i) {
            debug_log(DLOG_DEBUG, "[do_search_group_owner]:tree_level=(%d),attrVal[%d]=(%s)", tree_level, i,
                attrVal[i]);
            gint32 ret = do_search_group_owner(session, (gchar *)attrVal[i], group, tree_level, grp_hash);
            if (ret == LDAP_AUTH_SUCCESS) {
                search_result = 1;
            }
        }

        ldap_value_free((gint8 **)attrVal);
    }

    (void)ldap_msgfree(res);
    g_hash_table_destroy(find_msg_own_hash);
    debug_log(DLOG_DEBUG, "[do_search_group_owner]:end");

    if ((match_flag == 1) || (search_result == 1)) {
        return LDAP_AUTH_SUCCESS;
    }
    return LDAP_AUTH_ERROR;
}

LOCAL gint32 do_search_by_memberof_ext(PAM_LDAP_SESSION_S *session, guint8 *group, gint32 *flag, gint8 *filter)
{
    gchar* attrs[2] = {LDAP_MEMBEROF, NULL};
    LDAPMessage *msg = NULL;
    LDAPMessage *res = NULL;
    gchar **attrVal = NULL;
    gint16 attrCount;
    guint32 tree_level = 1;

    /* 根据用户名来查询记录，并返回memberof 属性 */
    gint32 ret = ldap_search_ext_s(session->ld, (const gchar *)session->conf->base, session->conf->scope,
        (const gchar *)filter, attrs, 0, NULL, NULL, NULL, 0, &res);
    /* 查询失败 */
    if ((ret != LDAP_SUCCESS) && (ret != LDAP_TIMELIMIT_EXCEEDED) && (ret != LDAP_SIZELIMIT_EXCEEDED)) {
        debug_log(DLOG_ERROR, "ldap_search_ext_s failed:ret=%d.", ret);

        if (res != NULL) {
            (void)ldap_msgfree(res);
        }

        return LDAP_AUTH_UNKNOWN;
    }

    /* 创建hash表，记录所有查找过的从属组 */
    GHashTable *find_grp_own_hash = g_hash_table_new_full(g_str_hash, g_str_equal, (GDestroyNotify)g_free,
        (GDestroyNotify)NULL);
    if (!find_grp_own_hash) {
        debug_log(DLOG_ERROR, "g_hash_table_new_full failed");
        (void)ldap_msgfree(res);
        return LDAP_AUTH_UNKNOWN;
    }
    /* 查询成功之后 */
    debug_log(DLOG_DEBUG, "[do_search_by_memberof]:start");

    for (msg = ldap_first_entry(session->ld, res); msg != NULL; msg = ldap_next_entry(session->ld, msg)) {
        attrVal = (gchar **)ldap_get_values(session->ld, msg, (gint8 *)LDAP_MEMBEROF);
        if (attrVal == NULL) {
            debug_log(DLOG_DEBUG, "[do_search_by_memberof]:continue");
            continue;
        }

        attrCount = ldap_count_values((gint8 **)attrVal);

        for (gint32 i = 0; i < attrCount; ++i) {
            debug_log(DLOG_DEBUG, "[do_search_by_memberof]:attrVal[%d]=(%s)", i, attrVal[i]);
            ret = do_search_group_owner(session, (gchar *)attrVal[i], group, tree_level, find_grp_own_hash);
            if (ret == LDAP_AUTH_SUCCESS) {
                *flag = 1;
            }
        }

        ldap_value_free((gint8 **)attrVal);
    }

    debug_log(DLOG_DEBUG, "g_hash_table_size(find_grp_own_hash) = %u", g_hash_table_size(find_grp_own_hash));
    /* 销毁hash表，回收内存 */
    g_hash_table_destroy(find_grp_own_hash);
    (void)ldap_msgfree(res);

    return LDAP_AUTH_SUCCESS;
}

/*
 * Description: 通过输入用户名并指定返回memberof属性匹配用户名所属的用户组
 */
LOCAL gint32 do_search_by_memberof(PAM_LDAP_SESSION_S *session, const gint8 *username, guint8 *group)
{
    gint32 iRet;
    gint8 filter[LDAP_FILT_MAXSIZ] = {0};
    gint32 flag = 0;
    gint32 ret;

    if ((session == NULL) || (username == NULL) || (group == NULL)) {
        debug_log(DLOG_ERROR, "Parameter is NULL.");
        return LDAP_AUTH_ERROR;
    }

    /* 生成按用户名来过滤的过滤器 */
    if (session->conf->dn_with_uid == 0) {
        iRet = snprintf_s((gchar *)filter, sizeof(filter), sizeof(filter) - 1, "(&(objectClass=*)(cn=%s))", username);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
    } else {
        iRet = snprintf_s((gchar *)filter, sizeof(filter), sizeof(filter) - 1, "(&(objectClass=*)(uid=%s))", username);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
    }

    ret = do_search_by_memberof_ext(session, group, &flag, filter);
    if (ret != LDAP_AUTH_SUCCESS) {
        return LDAP_AUTH_UNKNOWN;
    }

    debug_log(DLOG_DEBUG, "[do_search_by_memberof]:end");

    if (flag == 1) {
        debug_log(DLOG_DEBUG, "groupname is exist, ret = %d", ret);
        return LDAP_AUTH_SUCCESS;
    } else {
        debug_log(DLOG_ERROR, "groupname is not exist, ret = %d", ret);
        return LDAP_AUTH_UNKNOWN;
    }
}

/*
 * Description: 通过ldap搜索功能匹配用户所属的用户组
 */
LOCAL gint32 do_get_user_group(PAM_LDAP_SESSION_S *session, gint8 *username, guint8 *group)
{
    gint8 escaped_user[LDAP_FILT_MAXSIZ] = {0};
    gint32 rc;

    rc = 1;
    (void)ldap_set_option(session->ld, LDAP_OPT_SIZELIMIT, &rc);

    /* 将用户名中的特殊字符转义 */
    rc = escape_string(username, escaped_user, sizeof(escaped_user));
    if (rc != LDAP_AUTH_SUCCESS) {
        debug_log(DLOG_ERROR, "escape_string failed:rc=%d", rc);
        return rc;
    }

    rc = LDAP_AUTH_UNKNOWN;

    do {
        /* 方法一:  通过用户名的memberof  属性搜索 */
        debug_log(DLOG_DEBUG, "do search by memberof...");
        rc = do_search_by_memberof(session, escaped_user, group);
        if (rc == LDAP_AUTH_SUCCESS) {
            break;
        }

        /* 方法二:  通过用户名搜索 */
        debug_log(DLOG_DEBUG, "do search by username...");
        rc = do_search_by_username(session, escaped_user, group);
        if (rc == LDAP_AUTH_SUCCESS) {
            break;
        }
    } while (0);

    return rc;
}

/*
 * Description: 直接向ldap服务器绑定用户DN，验证用户是否合法
 */
LOCAL gint32 do_direct_bind_dn(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info)
{
    gint32 rc;
    gint32 msgid;
    struct timeval timeout;
    LDAPMessage *result = NULL;

    if (session->ld == NULL) {
        rc = open_session(session, ldap_auth_info);
        if (rc != LDAP_AUTH_SUCCESS) {
            return rc;
        }
    }

    msgid = ldap_simple_bind(session->ld, (gint8 *)ldap_auth_info->bind_dn, (gint8 *)ldap_auth_info->bind_dn_pwd);
    if (msgid == -1) {
        gint32 ldap_errno = 0;
        (void)ldap_get_option(session->ld, LDAP_OPT_ERROR_NUMBER, &ldap_errno);
        debug_log(DLOG_ERROR, "ldap_simple_bind fail, err: %s", ldap_err2string(ldap_errno));
        return LDAP_AUTH_INVALID_PASSWD;
    }
    timeout.tv_sec = session->conf->bind_timelimit; /* default 10 */
    timeout.tv_usec = 0;
    rc = ldap_result(session->ld, msgid, FALSE, &timeout, &result);
    if ((rc == -1) || (rc == 0)) {
        debug_log(DLOG_ERROR, "ldap_simple_bind fail");
        if (result != NULL) {
            debug_log(DLOG_ERROR, "ldap_result  result is not free!");
            (void)ldap_msgfree(result);
        }
        return LDAP_AUTH_INVALID_PASSWD;
    }

    /* 把TRUE修改为1，表示释放result的内存，更清晰 */
    (void)ldap_parse_result(session->ld, result, &rc, 0, 0, 0, 0, 1);

    if (rc != LDAP_SUCCESS) {
        debug_log(DLOG_ERROR, "do_direct_bind: userdn (%s)", ldap_auth_info->bind_dn);
        debug_log(DLOG_ERROR, "do_direct_bind: error trying to bind (%s)", ldap_err2string(rc));
        return LDAP_AUTH_INVALID_PASSWD;
    }

    return LDAP_AUTH_SUCCESS;
}

/*
 * Description: 通过longin name 绑定
 */
LOCAL gint32 ldap_bind_user(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info)
{
    gint32 ret;

    if (session == NULL) {
        debug_log(DLOG_ERROR, "Input parameter error.");
        return RET_ERR;
    }

    ret = do_sasl_bind(session, ldap_auth_info);
    if (ret != LDAP_AUTH_SUCCESS) {
        /* sasl bind失败后，尝试进行simple bind */
        /* 先做unbind操作 */
        if (session->ld != NULL) {
            (void)ldap_unbind(session->ld);
            session->ld = NULL;
        }

        ret = do_direct_bind(session, ldap_auth_info->username, ldap_auth_info);
        if (ret != LDAP_AUTH_SUCCESS) {
            return ret;
        }
    }

    return ret;
}

/*
 * Description: 查找用户CN
 */
LOCAL gint32 ldap_find_user_cn(PAM_LDAP_SESSION_S *session, gchar *filter, gint8 *cn, guint32 cn_size)
{
    errno_t safe_fun_ret;
    gint32 ret;
    LDAPMessage *res = NULL;
    LDAPMessage *msg = NULL;
    gint32 sizelimit;
    gint8 **cn_temp = NULL;

    if ((filter == NULL) || (session == NULL) || (cn == NULL) || (cn_size == 0)) {
        return LDAP_AUTH_ERROR;
    }

    sizelimit = 1;
    (void)ldap_set_option(session->ld, LDAP_OPT_SIZELIMIT, &sizelimit);

    ret = ldap_search_ext_s(session->ld, (const gchar *)session->conf->base, session->conf->scope,
        (const gchar *)filter, NULL, 0, NULL, NULL, NULL, 0, &res);
    if ((ret != LDAP_SUCCESS) && (ret != LDAP_TIMELIMIT_EXCEEDED) && (ret != LDAP_SIZELIMIT_EXCEEDED)) {
        debug_log(DLOG_ERROR, "LDAP search user failed, rc=%d", ret);
        if (res != NULL) {
            (void)ldap_msgfree(res);
        }

        return LDAP_AUTH_UNKNOWN;
    }

    msg = ldap_first_entry(session->ld, res);
    if (msg == NULL) {
        debug_log(DLOG_ERROR, "ldap_first_entry failed:rc=%d", ret);
        (void)ldap_msgfree(res);
        return LDAP_AUTH_UNKNOWN;
    }

    if (session->conf->dn_with_uid == 0) {
        ret = get_string_values(session->ld, msg, (gint8 *)"cn", &cn_temp);
    } else {
        ret = get_string_values(session->ld, msg, (gint8 *)"uid", &cn_temp);
    }

    if (ret != LDAP_AUTH_SUCCESS || cn_temp == NULL) {
        debug_log(DLOG_ERROR, "get_string_values displayName failed:rc=%d", ret);
        (void)ldap_msgfree(res);
        return LDAP_AUTH_UNKNOWN;
    }

    (void)memset_s(cn, cn_size, 0x00, cn_size);
    safe_fun_ret = strncpy_s((gchar *)cn, cn_size, (const gchar *)cn_temp[0], cn_size - 1);
    if (safe_fun_ret != EOK) {
        debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", safe_fun_ret);
    }

    (void)ldap_value_free(cn_temp);
    (void)ldap_msgfree(res);

    return ret;
}

LOCAL gint32 window_logon_name(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info,
    gint8 *cn, guint32 cn_size, LDAP_USER_INFO ldap_user_info)
{
    gchar full_name[LDAP_FILT_MAXSIZ] = {0};
    /* 1、使用windows logon name(pre 2000)查找 */
    debug_log(DLOG_DEBUG, "Search user by windows login name(pre 2000).");
    gint32 iRet = snprintf_s(ldap_user_info.filter, sizeof(ldap_user_info.filter), sizeof(ldap_user_info.filter) - 1,
        "(&(objectClass=*)(sAMAccountName=%s))", ldap_user_info.escaped_user);
    if (iRet <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
    }
    gint32 ret = ldap_find_user_cn(session, ldap_user_info.filter, cn, cn_size);
    if (ret == RET_OK) {
        return LDAP_AUTH_SUCCESS;
    }

    /* 2、使用windows logon name查找 */
    debug_log(DLOG_DEBUG, "Search user by windows login name.");
    iRet = snprintf_s(ldap_user_info.filter, sizeof(ldap_user_info.filter), sizeof(ldap_user_info.filter) - 1,
        "(&(objectClass=*)(userPrincipalName=%s))", ldap_user_info.escaped_user);
    if (iRet <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
    }
    ret = ldap_find_user_cn(session, ldap_user_info.filter, cn, cn_size);
    if (ret == RET_OK) {
        return LDAP_AUTH_SUCCESS;
    }

    /* 3、使用拼装的windows logon name查找 */
    // 拼装完整的logon name
    iRet = snprintf_s(full_name, sizeof(full_name), sizeof(full_name) - 1, "%s@%s", ldap_auth_info->username,
        ldap_auth_info->user_domain);
    if (iRet <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
    }
    (void)memset_s(ldap_user_info.escaped_user, sizeof(ldap_user_info.escaped_user), 0x00,
        sizeof(ldap_user_info.escaped_user));
    ret = escape_string((const gint8 *)full_name, ldap_user_info.escaped_user, sizeof(ldap_user_info.escaped_user));
    if (ret != LDAP_AUTH_SUCCESS) {
        debug_log(DLOG_ERROR, "Escape string failed.");
    }

    return ret;
}

/*
 * Description: 查找用户信息
 */
LOCAL gint32 ldap_search_user(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info, gint8 *cn, guint32 cn_size)
{
    LDAP_USER_INFO ldap_user_info = {0};

    if ((session == NULL) || (cn == NULL)) {
        return LDAP_AUTH_ERROR;
    }

    gint32 ret = escape_string((const gint8 *)ldap_auth_info->username, ldap_user_info.escaped_user,
        sizeof(ldap_user_info.escaped_user));
    if (ret != LDAP_AUTH_SUCCESS) {
        return LDAP_AUTH_ERROR;
    }

    /* 结构上支持指定特殊标识(例如UID、SN等)作为查找项(暂无需求)
          目前实现上，只支持通用标识CN和Window AD登录标识 */

    /* 1、通过通用标识CN查找 */
    if (session->conf->dn_with_uid == 0) {
        ret = snprintf_s(ldap_user_info.filter, sizeof(ldap_user_info.filter), sizeof(ldap_user_info.filter) - 1,
            "(&(objectClass=*)(cn=%s))", ldap_user_info.escaped_user);
        if (ret <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", ret);
        }
    } else {
        /* 当无法识别CN且能识别uid时用uid查找 */
        ret = snprintf_s(ldap_user_info.filter, sizeof(ldap_user_info.filter), sizeof(ldap_user_info.filter) - 1,
            "(&(objectClass=*)(uid=%s))", ldap_user_info.escaped_user);
        if (ret <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", ret);
        }
    }

    ret = ldap_find_user_cn(session, ldap_user_info.filter, cn, cn_size);
    if (ret == RET_OK) {
        return LDAP_AUTH_SUCCESS;
    }

    /* 2、通过windows特殊标签查找 */
    (void)memset_s(ldap_user_info.filter, sizeof(ldap_user_info.filter), 0x00, sizeof(ldap_user_info.filter));

    do {
        ret = window_logon_name(session, ldap_auth_info, cn, cn_size, ldap_user_info);
        if (ret == LDAP_AUTH_SUCCESS) {
            break;
        }

        debug_log(DLOG_DEBUG, "Search user by re-build windows login name.");
        ret = snprintf_s(ldap_user_info.filter, sizeof(ldap_user_info.filter), sizeof(ldap_user_info.filter) - 1,
            "(&(objectClass=*)(userPrincipalName=%s))", ldap_user_info.escaped_user);
        if (ret <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", ret);
        }
        ret = ldap_find_user_cn(session, ldap_user_info.filter, cn, cn_size);
        if (ret == RET_OK) {
            ret = LDAP_AUTH_SUCCESS;
            break;
        }

        /* 查找失败则返回错误 */
        ret = LDAP_AUTH_ERROR;
    } while (0);

    return ret;
}

/*
 * Description: 通过用户登录直接进行用户认证
 */
LOCAL gint32 ldap_auth(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info, guint8 *group)
{
    gchar full_name[LDAP_FILT_MAXSIZ] = {0};
    gint8 cn[LDAP_USERFOLDER_MAX_LEN] = {0};

    // 静态函数由调用用者保证入参合法性，此处不校验
    /* 方式一:SASL认证 */
    debug_log(DLOG_DEBUG, "Do sasl bind.");
    gint32 ret = do_sasl_bind(session, ldap_auth_info);
    if (ret == LDAP_AUTH_SUCCESS) {
        goto end_auth;
    }

    /* sasl bind失败后，先做unbind操作,尝试进行simple bind */
    if (session->ld != NULL) {
        (void)ldap_unbind(session->ld);
        session->ld = NULL;
    }

    /* 方式二:直接绑定 */
    debug_log(DLOG_DEBUG, "Do direct bind.");
    ret = do_direct_bind(session, ldap_auth_info->username, ldap_auth_info);
    if (ret == LDAP_AUTH_SUCCESS) {
        goto end_auth;
    }

    /* 方式三:直接绑定全名 */
    debug_log(DLOG_DEBUG, "LDAP simple bind.");
    // 获取LDAP服务器域名
    if (strlen(ldap_auth_info->user_domain) == 0) {
        ret = LDAP_AUTH_ERROR;
        debug_log(DLOG_DEBUG, "server(%d) domain name is NULL", ldap_auth_info->serverid);
        goto end_auth;
    }
    // 拼装完整的logon name
    gint32 iRet = snprintf_s(full_name, sizeof(full_name), sizeof(full_name) - 1, "%s@%s", ldap_auth_info->username,
        ldap_auth_info->user_domain);
    if (iRet <= 0) {
        debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
    }
    if (session->ld == NULL) {
        ret = LDAP_AUTH_ERROR;
        goto end_auth;
    }
    ret = ldap_simple_bind_s(session->ld, (gint8 *)full_name, (gint8 *)ldap_auth_info->password);

end_auth:
    if (ret != LDAP_AUTH_SUCCESS) {
        debug_log(DLOG_ERROR, "LDAP bind user failed.");
        return RET_ERR;
    }

    ret = ldap_search_user(session, ldap_auth_info, cn, sizeof(cn));
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "LDAP find user failed.");
        return RET_ERR;
    }

    ret = do_get_user_group(session, (gint8 *)cn, group);

    return ret;
}

/*
 * Description: 将ldap_auth_info中的认证用户密码和绑定用户密码进行切换
 */
LOCAL void switch_dn_and_user(LDAP_AUTH_INFO *ldap_auth_info)
{
    gchar tmp_bind_dn[SMALL_BUFFER_SIZE] = {0};
    gchar tmp_bind_dn_pwd[SMALL_BUFFER_SIZE] = {0};

    (void)strncpy_s(tmp_bind_dn, SMALL_BUFFER_SIZE, ldap_auth_info->bind_dn, strlen(ldap_auth_info->bind_dn));
    (void)strncpy_s(tmp_bind_dn_pwd, SMALL_BUFFER_SIZE, ldap_auth_info->bind_dn_pwd,
        strlen(ldap_auth_info->bind_dn_pwd));

    (void)strncpy_s(ldap_auth_info->bind_dn, SMALL_BUFFER_SIZE, ldap_auth_info->username,
        strlen(ldap_auth_info->username));
    (void)strncpy_s(ldap_auth_info->bind_dn_pwd, SMALL_BUFFER_SIZE, ldap_auth_info->password,
        strlen(ldap_auth_info->password));

    (void)strncpy_s(ldap_auth_info->username, SMALL_BUFFER_SIZE, tmp_bind_dn, strlen(tmp_bind_dn));
    (void)strncpy_s(ldap_auth_info->password, SMALL_BUFFER_SIZE, tmp_bind_dn_pwd, strlen(tmp_bind_dn_pwd));
}

/*
 * Description: 通过proxy user认证
 */
LOCAL gint32 ldap_proxyuser_auth(PAM_LDAP_SESSION_S *session, LDAP_AUTH_INFO *ldap_auth_info, guint8 *group)
{
    gint32 ret;
    gint8 cn[SMALL_BUFFER_SIZE] = {0};

    /* 当前密码明文传入，无需解密 */
    debug_log(DLOG_DEBUG, "Bind proxyuser dn.");

    /* 判断输入是用户名还是DN 如果是DN,优先判断CN开头,此后判断是UID开头 */
    if (strncasecmp(ldap_auth_info->bind_dn, "CN=", strlen("CN=")) == 0) {
        /* 绑定proxy用户DN */
        ret = do_direct_bind_dn(session, ldap_auth_info);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "Direct bind DN failed, ret = %d.", ret);
            return RET_ERR;
        }
    } else if (strncasecmp(ldap_auth_info->bind_dn, "UID=", strlen("UID=")) == 0) {
        /* 绑定proxy用户uid */
        ret = do_direct_bind_dn(session, ldap_auth_info);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "Direct bind DN failed, ret = %d.", ret);
            return RET_ERR;
        }
        session->conf->dn_with_uid = 1;
    } else {
        /* 支持仅配置用户名登录，在这个流程前后切换一下绑定用户和认证用户信息，否则本应绑定用户认证却走成了认证用户的认证 */
        switch_dn_and_user(ldap_auth_info);
        ret = ldap_bind_user(session, ldap_auth_info);
        switch_dn_and_user(ldap_auth_info);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "LDAP bind user failed, ret = %d.", ret);
            return RET_ERR;
        }
    }

    ret = ldap_search_user(session, ldap_auth_info, cn, sizeof(cn));
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "LDAP find user failed.");
        return RET_ERR;
    }

    debug_log(DLOG_DEBUG, "Re-bind user.");
    do {
        /* 方式一:SASL认证 */
        ret = do_sasl_bind(session, ldap_auth_info);
        if (ret == LDAP_AUTH_SUCCESS) {
            break;
        }

        /* sasl bind失败后，先做unbind操作,尝试进行simple bind */
        if (session->ld != NULL) {
            (void)ldap_unbind(session->ld);
            session->ld = NULL;
        }

        /* 方式二:直接绑定 */
        ret = do_direct_bind(session, (gchar *)cn, ldap_auth_info);
    } while (0);

    if (ret != LDAP_AUTH_SUCCESS) {
        debug_log(DLOG_ERROR, "LDAP bind user failed.");
        return RET_ERR;
    }

    ret = do_get_user_group(session, (gint8 *)cn, group);

    return ret;
}

/*
 * Description: 通过ldap认证用户并匹配用户组，返回所属的组号
 */
LOCAL gint32 ldap_authenticate(LDAP_AUTH_INFO *ldap_auth_info, guint8 *group)
{
    gint32 rc;
    PAM_LDAP_SESSION_S *session = NULL;

    /* 获取session */
    rc = ldap_get_session(&session, ldap_auth_info);
    if (rc != LDAP_AUTH_SUCCESS) {
        debug_log(DLOG_ERROR, "Get session failed.");
        goto _EXIT_AUTH;
    }

    if ((strlen(ldap_auth_info->bind_dn) != 0) && (strlen(ldap_auth_info->bind_dn_pwd) != 0)) {
        debug_log(DLOG_DEBUG, "Do auth ldap by proxyuser.");
        rc = ldap_proxyuser_auth(session, ldap_auth_info, group);
        if (rc != LDAP_AUTH_SUCCESS) {
            debug_log(DLOG_ERROR, "LDAP proxyuser auth failed.");
            goto _EXIT_AUTH;
        }
    } else {
        rc = ldap_auth(session, ldap_auth_info, group);
        if (rc != LDAP_AUTH_SUCCESS) {
            debug_log(DLOG_ERROR, "LDAP auth failed.");
            goto _EXIT_AUTH;
        }
    }

_EXIT_AUTH:
    ldap_cleanup_session(&session);
    return rc;
}

/*
 * Description: LDAP认证 对外接口
 */
gint32 mscm_ldap_authenticate(LDAP_AUTH_INFO *ldap_auth_info, guint8 *privilege, guint8 group[MAX_USER_GROUP])
{
    gint32 retv = 0;
    guint8 i = 0;
    guint8 j = 0;
    guint8 group_id[MAX_USER_GROUP] = {0};

    if ((privilege == NULL) || (group == NULL)) {
        return RET_ERR;
    }
    (void)memset_s(group_id, MAX_USER_GROUP, 0xff, MAX_USER_GROUP);

    /* 初始化为无权限 */
    *privilege = 0x0f;

    /* LDAP认证，认证成功，得到LDAP组ID */
    retv = ldap_authenticate(ldap_auth_info, (guint8 *)group_id);
    if (retv != LDAP_AUTH_SUCCESS) {
        debug_log(DLOG_ERROR, "Ldap authenticate failed");
        return USER_LDAP_LOGIN_FAIL;
    }

    debug_log(DLOG_ERROR, "Ldap authenticate retv = %d", retv);

    for (i = 0; i < MAX_USER_GROUP; i++) {
        if (group_id[i] == 0xff) {
            continue;
        }

        for (j = 0; j < MAX_USER_GROUP; j++) {
            if (ldap_auth_info->group[j].group_inner_id != i + 1) {
                continue;
            }

            if (*privilege == 0x0f ||
                (ldap_auth_info->group[j].group_priv != 0x0f &&
                (*privilege < ldap_auth_info->group[j].group_priv))) {
                *privilege = ldap_auth_info->group[j].group_priv;
            }
            // 此处不管权限如何，都将组赋值传出，否则若第一个组为管理员，后面的组会由于权限不足而被跳过赋值
            group[i] = group_id[i];
        }
    }
 
    (void)memset_s(ldap_auth_info->password, strlen(ldap_auth_info->password), 0, strlen(ldap_auth_info->password));

    return RET_OK;
}