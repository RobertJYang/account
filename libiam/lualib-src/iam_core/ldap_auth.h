/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2010-2022. All rights reserved.
 * Description: ldap认证接口库头文件
 * Create: 2010-01-28
 */
#ifndef __LDAP_AUTH_H__
#define __LDAP_AUTH_H__
#include "glib.h"
#include "ldap.h"

#include "../comm_utils.h"

#ifdef __cplusplus
#if __cplusplus
extern "C" {
#endif
#endif /* __cplusplus */
/* 最多支持五个用户分组 */
#define MAX_USER_GROUP 5

/* 用户树配置允许最大深度 */
#define MAX_TREE_DEPTH 50

/* ldap组遍历hash表最大条目 */
#define MAX_LDAP_GRP_HASH_SIZE 2000

#ifndef LDAP_FILT_MAXSIZ
#define LDAP_FILT_MAXSIZ 1024
#endif /* LDAP_FILT_MAXSIZ */

/* LDAP标签长度:DC=,CN=,OU=.... */
#define LDAP_TAG_SIZE 3

#define LDAP_SEARCH_FILTER "(&(objectClass=*)(cn=%s))"
#define LDAP_MEMBEROF "memberOf"
#define LDAP_MEMBER "member"
#define LDAP_SEARCH_FILTER_G "(objectClass=*)"

#define LDAP_TAG_CASE_UPPER 0
#define LDAP_TAG_CASE_LOWER 1

/* /etc/ldap.conf nss_ldap-style configuration */
typedef struct tag_PAM_LDAP_CONFIG_S {
    gint8 *uri;                     /* URI */
    gint8 *host;                    /* space delimited list of servers */
    gint32 port;                    /* port, expected to be common to all servers */
    gint8 *base;                    /* base DN, eg. dc=gnu,dc=org */
    gint8 *groupdn[MAX_USER_GROUP]; /* user group DN,eg. cn=admin,dc=gnu,dc=org */
    gint32 ldap_enable;             /* ldap_enable */
    gint32 scope;                   /* scope for searches */
    gint32 deref;                   /* deref policy */
    gint8 *filter;                  /* filter to AND with uid=%s */
    gint32 version;                 /* LDAP protocol version */
    gint32 timelimit;               /* search timelimit */
    gint32 bind_timelimit;          /* bind timelimit */
    gint32 restart;                 /* restart interrupted syscalls, OpenLDAP only */
    guint8 cert_status;
    guint8 cert_verifi_Level;
    guint8 dn_with_uid; /* Use uid=login as part of userdn */
} PAM_LDAP_CONFIG_S;

#define LDAP_AUTH_SUCCESS 0
#define LDAP_AUTH_ERROR (-1)
#define LDAP_AUTH_INVALID_PASSWD (-2)
#define LDAP_AUTH_UNAVAIL (-3)
#define USER_LDAP_LOGIN_FAIL 0xDA

#define LDAP_USERDN_TRY_UID 1
#define LDAP_USERDN_START_WITH_UID 2

#define USER_NAME_CONTAIN_DOMAIN 0
#define USER_NAME_NOT_CONTAIN_DOMAIN 1

/* LDAP用户登录uid基础为1000 */
#define LDAP_USER_ID_BASE 1000

/* 最多32个LDAP用户 */
#define LDAP_USER_MAX_COUNT 32

/* LDAP用户名最大长度 */
#define LDAP_USER_NAME_MAX_LEN 255

/* LDAP证书最大长度 */
#define LDAP_CERT_LEN512 512

/* LDAP域文件夹限制字符 */
#define LDAP_GROUPFOLDER_LIMIT_CHARACTER   ""

/* LDAP域文件夹最大长度 */
#define LDAP_GROUPFOLDER_MAX_LEN       255

/* LDAP用户域文件夹最大长度 */
#define LDAP_USERFOLDER_MAX_LEN        255

/* LDAP域控制地址限制字符 */
#define LDAP_HOSTADDR_LIMIT_CHARACTER   ""

/* LDAP域控制地址最大长度 */
#define LDAP_HOSTADDR_MAX_LEN          255

/* LDAP用户域限制字符 */
#define LDAP_USERDOMAIN_LIMIT_CHARACTER   ""

/* LDAP用户域最大长度 */
#define LDAP_USERDOMAIN_MAX_LEN          255

/* LDAP用户域最小长度 */
#define LDAP_USERDOMAIN_MIN_LEN    0

/* LDAP用户域点号中间段长度 */
#define LDAP_USERDOMAIN_SECTION_MAX_LEN    63

/* LDAP组域限制字符 */
#define LDAP_GROUPDOMAIN_LIMIT_CHARACTER   ""

/* LDAP组域最大长度 */
#define LDAP_GROUPDOMAIN_MAX_LEN          255

/* LDAP组域最小长度 */
#define LDAP_GROUPDOMAIN_MIN_LEN          0

/* LDAP组名限制字符 */
#define LDAP_GROUPNAME_LIMIT_CHARACTER   ""

/* LDAP组名最大长度 */
#define LDAP_GROUPNAME_MAX_LEN          255

/* LDAP组最大长度, 256为内存余量 */
#define LDAP_GROUPDN_MAX_LEN (LDAP_GROUPDOMAIN_MAX_LEN + LDAP_GROUPFOLDER_MAX_LEN + LDAP_GROUPNAME_MAX_LEN + 256)

/* LDAP用户组最大长度, 256为内存余量 */
#define LDAP_USERDN_MAX_LEN (LDAP_USERFOLDER_MAX_LEN + LDAP_USERDOMAIN_MAX_LEN + 256)

/* LDAP组名最小长度 */
#define LDAP_GROUPNAME_MIN_LEN          0

/* LDAP加密套件集合最大长度 */
#define LDAP_MAX_CIPHER_LEN             2048

typedef struct tag_PAM_LDAP_SESSION_S {
    LDAP *ld;
    PAM_LDAP_CONFIG_S *conf;
} PAM_LDAP_SESSION_S;

/* BEGIN: Modified by maoali, 2014/10/15   PN:AR-0000836189 NTLM */
typedef struct {
    gchar *authentication_id;
    gchar *authorization_id;
    gchar *mechanisms;
    gchar *pwd;
    gchar *realm;
    gchar **response;
    gint32 response_number;
} SASL_DEFAULT;

/* END:   Modified by maoali, 2014/10/15 */

typedef struct {
    guint8 group_inner_id;
    gchar  group_name[LDAP_GROUPNAME_MAX_LEN + 1];
    gchar  group_folder[LDAP_GROUPFOLDER_MAX_LEN + 1];
    guint8 group_priv;
} LDAP_GROUP_INFO;

typedef struct {
    // 域控制器信息
    guint8          serverid;
    gchar           hostaddr[LDAP_USERDOMAIN_MAX_LEN + 1];
    gint32          port;
    gchar           user_domain[LDAP_USERDOMAIN_MAX_LEN + 1];
    gchar           folder[LDAP_USERFOLDER_MAX_LEN + 1];
    // 代理用户信息
    gchar           bind_dn[SMALL_BUFFER_SIZE];
    gchar           bind_dn_pwd[SMALL_BUFFER_SIZE];
    // 证书校验信息
    guint8          cert_verify_enabled;
    guint8          cert_verify_level;
    gchar           cert_inner_dir[SMALL_BUFFER_SIZE];
    // 链接配置信息
    gchar           scope[LDAP_USERDOMAIN_MAX_LEN + 1];
    guint8          time_limit;
    guint8          bind_time_limit;
    guint8          version;
    gchar           tls_cipher[LDAP_MAX_CIPHER_LEN];
    // 用户组信息
    guint8          group_cnt;
    LDAP_GROUP_INFO group[MAX_USER_GROUP];
    // 认证信息
    gchar           username[LDAP_USER_NAME_MAX_LEN + 1];
    gchar           password[LDAP_USER_NAME_MAX_LEN + 1];
} LDAP_AUTH_INFO;

typedef struct {
    gchar filter[LDAP_FILT_MAXSIZ];
    gint8 escaped_user[LDAP_FILT_MAXSIZ];
} LDAP_USER_INFO;

typedef struct {
    gint8 userdn[LDAP_USERDN_MAX_LEN];
    gchar cn[LDAP_USERFOLDER_MAX_LEN + 1];
    gchar uid[LDAP_USERFOLDER_MAX_LEN + 1];
} LDAP_USERDN_INFO;

gint32 mscm_ldap_authenticate(LDAP_AUTH_INFO *ldap_auth_info, guint8 *privilege, guint8 group[MAX_USER_GROUP]);
gint32 ldap_unbind(LDAP *ld);
gint8 **ldap_get_values(LDAP *ld, LDAPMessage *entry, gint8 *attr);
gint16 ldap_count_values(gint8 **vals);
gint32 ldap_simple_bind(LDAP *ld, const gint8 *who, const gint8 *passwd);
gint32 ldap_simple_bind_s(LDAP *ld, const gint8 *who, const gint8 *passwd);
gint32 ldap_search_ext_s(LDAP *ld, LDAP_CONST gchar *base, gint32 scope, LDAP_CONST gchar *filter, gchar **attrs,
    gint32 attrsonly, LDAPControl **sctrls, LDAPControl **cctrls, struct timeval *timeout, gint32 sizelimit,
    LDAPMessage **res);
void ldap_value_free(gint8 **vals);

#ifdef __cplusplus
#if __cplusplus
}
#endif
#endif /* __cplusplus */
#endif /* __LDAP_AUTH_H__ */
