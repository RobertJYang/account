/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2015-2020. All rights reserved.
 * Description: ldap接口库
 * History: 2021-11-20 超大源文件拆分
 */

#include "sasl/sasl.h"
#include "ldap_auth_parse_info.h"

/*
 * Description: LDAP 基础信息解析
 */
LOCAL gint32 parse_ldap_base_info(gchar *domain, guint32 domain_size, const gchar *folder, gchar *base,
    guint32 base_size)
{
    gint32 iRet;
    gint32 len = 0;
    gchar *pointer_begin = NULL;
    gchar *end = NULL;

    if (domain == NULL || folder == NULL || base == NULL || domain_size == 0 || base_size == 0) {
        return LDAP_AUTH_ERROR;
    }

    /* 如果folder为Users默认添加CN=，保证之前的配置仍可用 */
    if (strcmp(folder, "Users") == 0) {
        len += snprintf_truncated_s(base + len, base_size - len, "CN=%s%s", folder, ",");
    } else if (strlen(folder) != 0) {
        len += snprintf_truncated_s(base + len, base_size - len, "%s%s", folder, ",");
    }

    if ((pointer_begin = strtok_s(domain, ".", &end)) == NULL) {
        iRet = snprintf_s(base + len, base_size - len, base_size - len - 1, "%s%s", "DC=", domain);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
        return LDAP_AUTH_SUCCESS;
    }

    len += snprintf_truncated_s(base + len, base_size - len, "%s%s%s", "DC=", pointer_begin, ",");

    while ((pointer_begin = strtok_s(end, ".", &end)) != NULL) {
        len += snprintf_truncated_s(base + len, base_size - len, "%s%s%s", "DC=", pointer_begin, ",");
    }

    (void)snprintf_s(base + len - 1, base_size - len + 1, base_size - len, "%s", "\0");
    return LDAP_AUTH_SUCCESS;
}

/*
 * Description: 解析LDAP 组文件目录是否合法
 */
LOCAL gint32 ldap_group_forder_check(const gchar *folder)
{
    if (folder == NULL) {
        debug_log(DLOG_ERROR, "Input parameter error.");
        return RET_ERR;
    }

    // 以OU=开头，就认为是OU的格式
    if (strncasecmp(folder, "OU=", strlen("OU=")) != 0 && strncasecmp(folder, "CN=", strlen("CN=")) != 0) {
        return RET_ERR;
    }
    return RET_OK;
}

LOCAL gint32 parse_mutil_path(gchar *group_info, gint32 *len, gchar *folder_cp, gchar *end,
    guint8 tag_case)
{
    gchar *pointer_begin = NULL;
    GSList *list = NULL;
    GSList *tmp_list = NULL;
    const gchar *sub_folder = NULL;
    const gchar* tag[2][3] = {
        {"OU", "DC", "CN"},
        {"ou", "dc", "cn"}
    };

    // 解析多级文件夹路径
    pointer_begin = strtok_s(folder_cp, "/", &end);
    if (pointer_begin == NULL) {
        list = g_slist_prepend(list, g_variant_new_string((const gchar *)folder_cp));
    } else {
        list = g_slist_prepend(list, g_variant_new_string((const gchar *)pointer_begin));

        while ((pointer_begin = strtok_s(end, "/", &end)) != NULL) {
            list = g_slist_prepend(list, g_variant_new_string((const gchar *)pointer_begin));
        }
    }

    tmp_list = list;

    while (tmp_list) {
        GSList *next = tmp_list->next;
        sub_folder = g_variant_get_string((GVariant *)(tmp_list->data), NULL);
        *len += snprintf_truncated_s(group_info + *len, LDAP_GROUPDN_MAX_LEN - *len, "%s=%s,",
            tag[tag_case][0], sub_folder);
        tmp_list = next;
    }

    g_slist_free_full(list, (GDestroyNotify)g_variant_unref);
    pointer_begin = NULL;

    return RET_OK;
}

/*
 * Description: 解析LDAP组信息
 */
LOCAL gint32 parse_ldap_group_info(const gchar *domain, const gchar *folder, const gchar *name, gchar *group_info,
    guint8 tag_case)
{
    errno_t ret;
    gint32 len = 0;
    gchar *pointer_begin = NULL;
    gchar *end = NULL;
    gchar domain_cp[LDAP_GROUPFOLDER_MAX_LEN + 1] = {0};
    gchar folder_cp[LDAP_GROUPFOLDER_MAX_LEN + 1] = {0};
    const gchar* tag[2][3] = {
        {"OU", "DC", "CN"},
        {"ou", "dc", "cn"}
    };

    if (domain == NULL || folder == NULL || group_info == NULL || name == NULL ||
        ((tag_case != LDAP_TAG_CASE_UPPER) && (tag_case != LDAP_TAG_CASE_LOWER))) {
        return LDAP_AUTH_ERROR;
    }

    /* 拷贝字符串，防止strtok修改上层传入字符串 */
    ret = strncpy_s(folder_cp, sizeof(folder_cp), folder, sizeof(folder_cp) - 1);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", ret);
    }
    ret = strncpy_s(domain_cp, sizeof(domain_cp), domain, sizeof(domain_cp) - 1);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", ret);
    }

    /* 2为索引下标 */
    len += snprintf_truncated_s(group_info + len, LDAP_GROUPDN_MAX_LEN - len, "%s=%s%s", tag[tag_case][2], name, ",");

    /* 判断组信息是否符合新标准 */
    if (ldap_group_forder_check(folder_cp) == RET_OK) {
        len += snprintf_truncated_s(group_info + len, LDAP_GROUPDN_MAX_LEN - len, "%s,", folder_cp);
    } else if (strlen(folder_cp) != 0) {
        ret = parse_mutil_path(group_info, &len, folder_cp, end, tag_case);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "parse_mutil_path fail");
        }
    } else {
        // do nothing...
    }

    /* 处理域名信息 */
    if ((pointer_begin = strtok_s(domain_cp, ".", &end)) == NULL) {
        ret = snprintf_s(group_info + len, LDAP_GROUPDN_MAX_LEN - len, LDAP_GROUPDN_MAX_LEN - len - 1, "%s=%s",
            tag[tag_case][1], domain_cp);
        if (ret <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", ret);
        }
        return LDAP_AUTH_SUCCESS;
    }

    len += snprintf_truncated_s(group_info + len, LDAP_GROUPDN_MAX_LEN - len, "%s=%s%s",
        tag[tag_case][1], pointer_begin, ",");

    while ((pointer_begin = strtok_s(end, ".", &end)) != NULL) {
        len += snprintf_truncated_s(group_info + len, LDAP_GROUPDN_MAX_LEN - len, "%s=%s%s",
            tag[tag_case][1], pointer_begin, ",");
    }

    (void)snprintf_s(group_info + len - 1, LDAP_GROUPDN_MAX_LEN - len + 1, LDAP_GROUPDN_MAX_LEN - len, "%s", "\0");

    return LDAP_AUTH_SUCCESS;
}

/*
 * Description: 初始化配置属性
 */
LOCAL gint32 alloc_config(PAM_LDAP_CONFIG_S **presult)
{
    gint32 i;
    PAM_LDAP_CONFIG_S *result = NULL;

    if (*presult == NULL) {
        *presult = (PAM_LDAP_CONFIG_S *)calloc(1, sizeof(*result));

        if (*presult == NULL) {
            debug_log(DLOG_ERROR, "calloc error");
            return LDAP_AUTH_ERROR;
        }
    }

    result = *presult;

    result->scope = LDAP_SCOPE_SUBTREE;
    result->deref = LDAP_DEREF_NEVER;
    result->host = NULL;
    result->base = NULL;
    result->port = 0;
    result->ldap_enable = 0;
    result->filter = NULL;
#ifdef LDAP_VERSION3
    result->version = LDAP_VERSION3;
#else
    result->version = LDAP_VERSION2;
#endif
    /* LDAP_VERSION2 */
    result->timelimit = LDAP_NO_LIMIT;
    /* 设置LDAP绑定时间限制为10 */
    result->bind_timelimit = 10;
    result->restart = 1;

    for (i = 0; i < MAX_USER_GROUP; i++) {
        result->groupdn[i] = NULL;
    }

    return LDAP_AUTH_SUCCESS;
}

LOCAL gchar ldap_check_special_char_escape(gchar *string, guint32 i)
{
    gchar* dn_string[] = {"CN=", "OU=", "DC="};
    const guint32 dn_string_num = 3;
    gchar tmp_str[4] = {0};
    gchar tmp_uid_str[5] = {0};
    gchar is_need_escape = 1;

    (void)memset_s(tmp_str, sizeof(tmp_str), 0x00, sizeof(tmp_str));
    (void)memset_s(tmp_uid_str, sizeof(tmp_uid_str), 0x00, sizeof(tmp_uid_str));

    /* 等号加前2位，逗号后3位，需要是 CN=, OU= 或 DC= 等才不需要转义 */
    if ((string[i] == '=') && (i >= 2)) {
        /* 3为要拷贝的字符数,2为偏移量 */
        (void)strncpy_s(tmp_str, sizeof(tmp_str), &string[i - 2], 3);
        /* 逗号后3位 */
        if (i >= 3) {
            /* 4为要拷贝的字符数,3为偏移量 */
            (void)strncpy_s(tmp_uid_str, sizeof(tmp_uid_str), &string[i - 3], 4);
        }
    /* 判断字符串是否有3位余量 */
    } else if ((string[i] == ',') && (i < strlen(string) - 3)) {
        /* 3为要拷贝的字符数 */
        (void)strncpy_s(tmp_str, sizeof(tmp_str), &string[i + 1], 3);
    } else {
        is_need_escape = 1;
    }

    for (guint32 j = 0; j < dn_string_num; j++) {
        if ((strcasecmp(dn_string[j], tmp_str) == 0) || (strcasecmp("UID=", tmp_uid_str) == 0)) {
            is_need_escape = 0;
            break;
        }
    }

    return is_need_escape;
}

/*
 * Description: 特殊字符转义
 */
LOCAL void ldap_special_char_escape(gchar *string, guint32 string_max_len)
{
    gint32 iRet;
    errno_t safe_fun_ret;
    gchar folder_tmp[LDAP_USERFOLDER_MAX_LEN + 1] = {0};
    gchar *ldap_special_char1 = "\\\";<>#+=,"; /* \";<>#+=, 在ldap中需要转义，否则跟服务器查询到的不匹配 */
    gchar is_need_escape = 0;
    size_t i;

    for (i = 0; i < strlen(string); i++) {
        if (strchr(ldap_special_char1, string[i]) == NULL) {
            continue;
        }
        is_need_escape = 1;
        if ((string[i] == '=') || (string[i] == ',')) {
            is_need_escape = ldap_check_special_char_escape(string, i);
        }

        if (is_need_escape != 1) {
            continue;
        }
        
        safe_fun_ret = strncpy_s(folder_tmp, sizeof(folder_tmp), string, sizeof(folder_tmp) - 1);
        if (safe_fun_ret != RET_OK) {
            debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", safe_fun_ret);
        }
        iRet = snprintf_s(&string[i], string_max_len - i, string_max_len - i - 1, "\\%s", &folder_tmp[i]);
        if (iRet <= 0) {
            debug_log(DLOG_ERROR, "snprintf_s fail, ret = %d", iRet);
        }
        i++;
        is_need_escape = 0;
    }
}

/*
 * Description: 读取配置文件中的用户组属性
 */
LOCAL void read_groupdn(const LDAP_AUTH_INFO *ldap_auth_info, PAM_LDAP_CONFIG_S *result)
{
    guint32 i = 0;
    gint32 ret;
    gchar domain[LDAP_GROUPDOMAIN_MAX_LEN + 1] = {0};
    guint8 ldap_group_id = 0;
    gchar groupname[LDAP_GROUPNAME_MAX_LEN + 1] = {0};
    gchar folder[LDAP_GROUPFOLDER_MAX_LEN + 1] = {0};

    /* 遍历LDAP组对象 */
    for (i = 0; i < ldap_auth_info->group_cnt; i++) {
        /* 获取LDAP组的组ID */
        ldap_group_id = ldap_auth_info->group[i].group_inner_id - 1;

        /* 获取LDAP域用户组的名字 */
        ret = strncpy_s(groupname, sizeof(groupname), ldap_auth_info->group[i].group_name,
            sizeof(groupname) - 1);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "Get ldap group%d groupname failed.", i);
            break;
        }

        /* 获取LDAP组的应用文件夹 */
        (void)strncpy_s(folder, sizeof(folder), ldap_auth_info->group[i].group_folder,
            sizeof(folder) - 1);
        ldap_special_char_escape(folder, LDAP_GROUPFOLDER_MAX_LEN);

        /* 获取LDAP服务器的域名 */
        (void)strncpy_s(domain, sizeof(domain), ldap_auth_info->user_domain,
            sizeof(domain) - 1);

        result->groupdn[ldap_group_id] = (gint8 *)g_malloc(LDAP_GROUPDN_MAX_LEN);
        if (result->groupdn[ldap_group_id] == NULL) {
            debug_log(DLOG_ERROR, "malloc memory failed.");
            break;
        }
        (void)memset_s(result->groupdn[ldap_group_id], LDAP_GROUPDN_MAX_LEN, 0, LDAP_GROUPDN_MAX_LEN);

        ret = parse_ldap_group_info(domain, folder, groupname, (gchar *)result->groupdn[ldap_group_id],
            LDAP_TAG_CASE_UPPER);
        if (ret == LDAP_AUTH_ERROR) {
            return;
        }
    }

    return;
}

LOCAL gint32 get_ldap_host(PAM_LDAP_CONFIG_S *result, LDAP_AUTH_INFO *ldap_auth_info)
{
    /* 获取LDAPServer服务器地址 */
    result->host = (gint8 *)g_malloc(LDAP_USERDOMAIN_MAX_LEN + 1);
    if (result->host == NULL) {
        debug_log(DLOG_ERROR, "malloc memory failed.");
        return LDAP_AUTH_ERROR;
    }
    (void)memset_s(result->host, LDAP_USERDOMAIN_MAX_LEN + 1, 0, LDAP_USERDOMAIN_MAX_LEN + 1);
    return LDAP_AUTH_SUCCESS;
}

LOCAL void get_ldap_scope(PAM_LDAP_CONFIG_S *result, LDAP_AUTH_INFO *ldap_auth_info)
{
    /* 获取SCOPE */
    /* 比较前3个字符是否为sub */
    if (!strncasecmp(ldap_auth_info->scope, "sub", 3)) {
        result->scope = LDAP_SCOPE_SUBTREE;
    /* 比较前3个字符是否为one */
    } else if (!strncasecmp(ldap_auth_info->scope, "one", 3)) {
        result->scope = LDAP_SCOPE_ONELEVEL;
    /* 比较前4个字符是否为base */
    } else if (!strncasecmp(ldap_auth_info->scope, "base", 4)) {
        result->scope = LDAP_SCOPE_BASE;
    }
}

LOCAL void get_ldap_base_info(PAM_LDAP_CONFIG_S *result, LDAP_AUTH_INFO *ldap_auth_info)
{
    result->deref = LDAP_DEREF_NEVER;
    
    /* 获取域服务器端口 */
    result->port = ldap_auth_info->port;

    /* 获取LDAP连接时间限制 */
    result->timelimit = ldap_auth_info->time_limit;

    /* 获取LDAP绑定时间限制 */
    result->bind_timelimit = ldap_auth_info->bind_time_limit;

    /* 获取LDAP版本信息 */
    result->version = ldap_auth_info->version;

    result->restart = 0;
}

/*
 * Description: 读取ldap配置文件并解析
 */
gint32 read_ldap_config(PAM_LDAP_CONFIG_S **presult, LDAP_AUTH_INFO *ldap_auth_info)
{
    /* this is the same configuration file as nss_ldap */
    PAM_LDAP_CONFIG_S *result = NULL;
    gchar folder[LDAP_USERFOLDER_MAX_LEN + 1] = {0};
    gchar userdomain[LDAP_USERDOMAIN_MAX_LEN + 1] = {0};

    /* 初始化LDAP配置属性 */
    if (alloc_config(presult) != LDAP_AUTH_SUCCESS) {
        return LDAP_AUTH_SUCCESS;
    }

    result = *presult;
    result->scope = LDAP_SCOPE_SUBTREE;
    result->dn_with_uid = 0;

    if (get_ldap_host(result, ldap_auth_info) != LDAP_AUTH_SUCCESS) {
        return LDAP_AUTH_ERROR;
    }
    
    errno_t safe_fun_ret = strncpy_s((gchar *)(result->host), LDAP_USERDOMAIN_MAX_LEN + 1, ldap_auth_info->hostaddr,
        strlen(ldap_auth_info->hostaddr));
    if (safe_fun_ret != RET_OK) {
        debug_log(DLOG_ERROR, "strncpy_s fail, ret = %d", safe_fun_ret);
    }

    /* 获取证书启用状态 */
    result->cert_status = ldap_auth_info->cert_verify_enabled;
    /* 获取证书校验级别 */
    result->cert_verifi_Level = ldap_auth_info->cert_verify_level;
    debug_log(DLOG_DEBUG, "get ldap level: %d", result->cert_verifi_Level);

    /* 获取域名 */
    (void)strncpy_s(userdomain, sizeof(userdomain), ldap_auth_info->user_domain,
        sizeof(userdomain) - 1);

    /* 获取用户文件夹 */
    (void)strncpy_s(folder, sizeof(folder), ldap_auth_info->folder,
        sizeof(folder) - 1);

    /* 将域名转换成ldap的格式 */
    result->base = (gint8 *)g_malloc0(LDAP_USERDN_MAX_LEN);

    if (result->base == NULL) {
        debug_log(DLOG_ERROR, "malloc memory failed.");
        return LDAP_AUTH_ERROR;
    }

    gint32 ret = parse_ldap_base_info(userdomain, sizeof(userdomain), folder, (gchar *)result->base,
        LDAP_USERDN_MAX_LEN);
    if (ret == LDAP_AUTH_ERROR) {
        return LDAP_AUTH_ERROR;
    }

    get_ldap_scope(result, ldap_auth_info);
    get_ldap_base_info(result, ldap_auth_info);

    /* 读取该LDAP控制器的组配置 */
    read_groupdn(ldap_auth_info, result);

    if ((result->host == NULL) && (result->uri == NULL)) {
        return LDAP_AUTH_ERROR;
    }

    if (result->port == 0) {
        result->port = LDAP_PORT;
    }

    return LDAP_AUTH_SUCCESS;
}
