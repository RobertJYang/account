/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2010-2022. All rights reserved.
 * Description: ldap认证接口库头文件
 * create: 2010-1-28
 */
#ifndef __LDAP_AUTH_PARSE_INFO_H__
#define __LDAP_AUTH_PARSE_INFO_H__

#include "ldap_auth.h"
#include "../comm_utils.h"

#ifdef __cplusplus
#if __cplusplus
extern "C" {
#endif
#endif /* __cplusplus */

gint32 read_ldap_config(PAM_LDAP_CONFIG_S **presult, LDAP_AUTH_INFO *ldap_auth_info);

#ifdef __cplusplus
#if __cplusplus
}
#endif
#endif /* __cplusplus */
#endif
