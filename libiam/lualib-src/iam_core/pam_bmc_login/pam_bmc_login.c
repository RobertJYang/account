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
 * Create: 2023-05-22
 */
#include "pwd.h"
#include "fcntl.h"
#include "errno.h"
#include "limits.h"
#include "unistd.h"
#include "dlfcn.h"
#include "sys/types.h"
#include "sys/stat.h"
#include "../common/check_login_rule.h"
#include "pam_common.h"
#include "pam_bmc_login.h"

/*
 * Description: 解析传递给本模块的参数
 * @param: [in] pamh：pam句柄
 * @param: [out] opts：ipmi文件操作
 * @param: [in] argc：参数个数
 * @param: [in] argc：参数
 */
LOCAL gint32 parse_args(pam_handle_t *pamh, IMANA_OPTIONS *opts, gint32 argc, const gchar **argv)
{
    const gchar *from = NULL;
    opts->filename = DEFAULT_PRIVILEGE_FILE;
    opts->ctrl = OPT_FAIL_ON_ERROR;

    for (; argc > 0; argc--) {
        if (!argv || !*argv) {
            return PAM_SERVICE_ERR;
        }
        if (!strncmp(*argv, "file=", 5)) { // 比较长度为字符串"file="长度5
            from = *argv + 5; // 入参右移5位，获取文件路径
            if (*from != '/') {
                pam_syslog(pamh, LOG_ERR, "filename not /rooted; %s", *argv);
                return PAM_SERVICE_ERR;
            }
            opts->filename = from;
        } else if (!strcmp(*argv, "onerr=fail")) {
            opts->ctrl |= OPT_FAIL_ON_ERROR;
        } else if (!strcmp(*argv, "onerr=succeed")) {
            opts->ctrl &= ~OPT_FAIL_ON_ERROR;
        } else if (!strcmp(*argv, "quiet")) {
            opts->ctrl |= OPT_QUIET;
        } else {
            pam_syslog(pamh, LOG_ERR, "unknown option: %s", *argv);
        }
        ++argv;
    }
    return PAM_SUCCESS;
}

/*
 * Description: 获取当前认证用户的用户名和uid
 * @param: [in] pamh：pam句柄
 * @pamam: [out] uid：用于存储从passwd文件中获取的uid
 * @param: [out] userp：用于存储从passwd文件中获取的user name
 */
LOCAL gint32 pam_get_uid(pam_handle_t *pamh, uid_t *uid, const gchar **userp)
{
    const gchar *user = NULL;
    struct passwd *pw = NULL;

    pam_get_user(pamh, &user, NULL);

    if (!user || !*user) {
        pam_syslog(pamh, LOG_ERR, "user name is invalid");
        return PAM_AUTH_ERR;
    }

    if (strcmp(user, ACTUAL_ROOT_USER_NAME) == 0) {
        user = RESERVED_ROOT_USER_NAME;
    }

    pw = pam_modutil_getpwnam(pamh, user);
    if (!pw) {
        pam_syslog(pamh, LOG_ERR, "pam_get_uid; no such user %s",
            (0 == strcmp(user, RESERVED_ROOT_USER_NAME) ? ACTUAL_ROOT_USER_NAME : user));
        return PAM_USER_UNKNOWN;
    }

    if (uid) {
        *uid = pw->pw_uid;
    }
    if (userp) {
        *userp = user;
    }
    return PAM_SUCCESS;
}

/*
 * Description: 将单行文本内容解析到结构体中
 * @param: [in] line：ipmi文件中的单个文本行，格式为 2:Administrator:x:1:5:0:1:1:1:0:0:4:x:0:0:0
 * @param: [out] ipmi_user：用于存储解析后的文本内容
 */
LOCAL gint32 parse_line_to_struct(gchar *line, IPMI_USER_S *ipmi_user)
{
    gint32 ret = 0;
    gint32 pos = 0;

    gchar *tmp_line = strdup(line);
    gchar *line_bak = tmp_line;
    gchar *token = strsep(&tmp_line, ":");
    while (token) {
        pos++;
        // 根据内容位置处理数据
        switch (pos) {
            case INDEX_LINE_UID:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_id));
                break;
            case INDEX_LINE_USER:
                if (strlen(token) >= sizeof(ipmi_user->user_name)) {
                    ret = PAM_AUTH_ERR;
                } else {
                    (void)memcpy_s(ipmi_user->user_name, sizeof(ipmi_user->user_name), token, strlen(token));
                    ret = PAM_SUCCESS;
                }
                break;
            case INDEX_LINE_PASSWORD:
            case INDEX_LINE_IS_20BYTES_PASSWD:
            case INDEX_LINE_MAX_SESSION_NUM:
            case INDEX_LINE_IS_CALLIN:
                // 未使用，暂不处理
                break;
            case INDEX_LINE_USER_ENABLE:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_enabled));
                break;
            case INDEX_LINE_USER_AUTH_ENABLE:
            case INDEX_LINE_IPMI_MSG_ENABLE:
            case INDEX_LINE_IS_ENABLE_BY_PASSWD:
            case INDEX_LINE_USER_PRIVILEGE_0:
                // 未使用，暂不处理
                break;
            case INDEX_LINE_USER_PRIVILEGE_1:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->privilege[1]));
                break;
            case INDEX_LINE_SNMP_PASSWORD:
                break;
            case INDEX_LINE_USER_LOCK_STATE:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_lock_status));
                break;
            case INDEX_LINE_USER_LOGIN_RULE:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_login_rule));
                break;
            case INDEX_LINE_USER_LOGIN_INTERFACE:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->user_login_interface));
                break;
            case INDEX_LINE_IS_EXCLUDE_USER:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->is_exclude_user));
                break;
            case INDEX_LINE_IS_PASSWORD_EXPIRED:
                ret = parse_line_token_to_uint8(token, &(ipmi_user->is_password_expired));
                break;
            default:
                break;
        }

        if (ret != RET_OK) {
            g_free(line_bak);
            return PAM_AUTH_ERR;
        }

        token = strsep(&tmp_line, ":");
    }
    g_free(line_bak);
    return PAM_SUCCESS;
}

/*
 * Description: 从文本内容中读取到用户信息
 * @param: [in] pamh：pam句柄
 * @param: [in] uid：用户业务id
 * @param: [in] data：ipmi文本内容
 * @param: [in] opts：ipmi文件操作
 * @param: [out] ipmi_user：用于存储解析后的文本内容
 */
LOCAL gint32 get_user(pam_handle_t *pamh, gint32 uid, gchar *data, IMANA_OPTIONS *opts, IPMI_USER_S *ipmi_user)
{
    gchar *tmp_line = NULL;
    gchar *line_bak = NULL;
    gchar *token = NULL;
    gchar *endptr = NULL;
    gint32 id;

    /* 在记录权限的文件中，每行的数据格式如下:
    2:Administrator:x:1:5:0:1:1:1:0:0:4:x:0:0:0 */
    gchar *tmp_buf = strdup(data);
    gchar *buf_bak = tmp_buf;
    gchar *line = strsep(&tmp_buf, "\n");

    // 遍历每行数据，根据uid找到对应的数据行
    while (line && strlen(line) != 0) {
        // 将单行数据以":"拆分，获取单个字段，第一个字段是 uid
        tmp_line = strdup(line);
        line_bak = tmp_line;
        token = strsep(&tmp_line, ":");

        // 转换为10进制数字
        id = strtol(token, &endptr, DECIMAL_NUM);
        if ((errno == ERANGE && (id == LONG_MAX || id == LONG_MIN)) || (errno != 0 && id == 0) ||
            (endptr == token)) {
            pam_syslog(pamh, LOG_ALERT, "in %s,id(%s) is invalid", opts->filename, token);
            line = strsep(&tmp_buf, "\n");
            continue;
        }
        // id不匹配，跳过
        if (id != uid) {
            line = strsep(&tmp_buf, "\n");
            continue;
        }
        // id匹配，转换该行数据（该文件中不应有重复数据，所以当有匹配uid时解析结果即为最终结果，不用再解析后续行）
        gint32 ret = parse_line_to_struct(line, ipmi_user);
        g_free(buf_bak);
        g_free(line_bak);
        return ret;
    }

    g_free(buf_bak);
    // 未找到匹配，直接失败
    return PAM_AUTH_ERR;
}

/*
 * Description: 校验用户登录接口
 * @param: [in] ipmi_user：用户各属性，校验使用
 * @param: [in] tty_name：登录使用设备名
 */
LOCAL gint32 check_user_login_interface(pam_handle_t *pamh, IPMI_USER_S *ipmi_user, const gchar *tty_name)
{
    const gchar *login_interface_str_map[LOGIN_INTERFACE_MAX] = {
        "web",
        "snmp",
        "ipmi",
        "ssh",
        "sftp",
        "telnet",
        "serial console",
        "redfish"
    };

    // 逃生用户跳过校验
    if (ipmi_user->is_exclude_user == 1) {
        return PAM_SUCCESS;
    }

    guint8 offset = LOGIN_INTERFACE_MAX;
    if (strcmp(tty_name, UART2_NAME) == 0) {
        offset = LOGIN_INTERFACE_LOCAL_OFFSET;
    } else if (strcmp(tty_name, SSH_NAME) == 0) {
        offset = LOGIN_INTERFACE_SSH_OFFSET;
    } else if (strcmp(tty_name, FTP_NAME) == 0) {
        offset = LOGIN_INTERFACE_SFTP_OFFSET;
    } else if (strstr(tty_name, TELNET_NAME) != NULL) {
        offset = LOGIN_INTERFACE_TELNET_OFFSET;
    } else { // 其它接口不在此校验
        return PAM_SUCCESS;
    }

    gint32 enabled = (ipmi_user->user_login_interface & (1 << offset)) >> offset;
    if (enabled == LOGIN_INTERFACE_DISABLE) {
        gchar *user =
            strcmp(ipmi_user->user_name, RESERVED_ROOT_USER_NAME) == 0 ? ACTUAL_ROOT_USER_NAME : ipmi_user->user_name;
        pam_syslog(pamh, LOG_ERR, "user (%s) do not have permission to access through %s",
            user, login_interface_str_map[offset]);
        return PAM_AUTH_ERR;
    }

    return PAM_SUCCESS;
}

/*
 * Description: 校验用户名、使能、权限、锁定状态、登录规则
 *              无需校验密码过期及逃生用户，V3已在鉴权动作外做处理
 *              此处不校验登录接口，改由在account模块中校验，防止因登录接口权限不足导致用户认证失败锁定
 * @param: [in] pamh：pam句柄
 * @param: [in] user_name：用户名
 * @param: [in] tty_name：登录使用设备名
 * @param: [in] ip_addr：登录ip
 * @param: [in] ipmi_user：用户各属性，校验使用
 */
LOCAL gint32 check_user(pam_handle_t *pamh, const gchar *user_name, const gchar *tty_name, const gchar *ip_addr,
    IPMI_USER_S *ipmi_user)
{
    // 校验用户名,同id用户名不匹配，直接返回失败
    if (strcmp(ipmi_user->user_name, user_name) != 0) {
        return PAM_AUTH_ERR;
    }

    const gchar *tmp_user_name = strcmp(user_name, RESERVED_ROOT_USER_NAME) == 0 ? ACTUAL_ROOT_USER_NAME : user_name;
    // 校验用户使能
    if (ipmi_user->user_enabled == DISABLED) {
        debug_log(DLOG_ERROR, "Account(%s) disabled", tmp_user_name);
        return PAM_AUTH_ERR;
    }

    // 校验用户权限
    if (ipmi_user->privilege[1] < USER_PRIVILEGE_GENERAL || ipmi_user->privilege[1] > USER_PRIVILEGE_ADMIN) {
        debug_log(DLOG_ERROR, "Account(%s) does not have sufficient permissions", tmp_user_name);
        return PAM_AUTH_ERR;
    }
    
    // 校验用户锁定状态（ftp登录不检查）
    if (strncmp((const gchar *)tty_name, FTP_NAME, strlen(FTP_NAME)) != 0) {
        if (ipmi_user->user_lock_status == USER_LOCK) {
            debug_log(DLOG_ERROR, "Account(%s) is locked", tmp_user_name);
            return PAM_PERM_DENIED;
        }
    }

    // 校验用户登录规则
    gint32 ret = check_user_login_rule(ipmi_user, ip_addr, tty_name);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "Account(%s) is restricted by login rules", tmp_user_name);
        return PAM_AUTH_ERR;
    }

    /* 在全部校验完成后再重设pam句柄中的属性，原因未知，否则可以在pam_get_uid中就完成该动作
       可能是为了避免污染属性，保证后续的使用 */
    if (strcmp(user_name, RESERVED_ROOT_USER_NAME) == 0) {
        ret = pam_set_item(pamh, PAM_USER, RESERVED_ROOT_USER_NAME);
        if (ret != PAM_SUCCESS) {
            pam_syslog(pamh, LOG_INFO, "Set user name in pam handle failed");
            return PAM_AUTH_ERR;
        }
    }

    debug_log(DLOG_INFO, "pam_bmc_login check result ok");
    return PAM_SUCCESS;
}

/*
 * Description: 从文件中获取ipmi_user结构
 * @param: [in] pamh：pam句柄
 * @param: [in] opt：用户名
 * @param: [in] uid：登录使用设备名
 * @param: [out] ipmi_user：用户各属性，校验使用
 */
LOCAL gint32 get_ipmi_user(pam_handle_t *pamh, IMANA_OPTIONS *opts, gint32 uid, IPMI_USER_S *ipmi_user)
{
    struct stat fileinfo;
    // 校验权限文件路径
    if (strlen(opts->filename) > PATH_MAX) {
        pam_syslog(pamh, LOG_ALERT, "Path name is too long");
        return ((opts->ctrl & OPT_FAIL_ON_ERROR) ? PAM_AUTH_ERR : (PAM_SUCCESS));
    }

    gchar *path = realpath(opts->filename, NULL);
    if (path == NULL) {
        pam_syslog(pamh, LOG_ALERT, "Couldn't translate file path into realpath %s", path);
        return ((opts->ctrl & OPT_FAIL_ON_ERROR) ? PAM_AUTH_ERR : (PAM_SUCCESS));
    }

    gint32 imana_file_fd = open(path, O_RDONLY);
    g_free(path);
    if (imana_file_fd < 0) {
        pam_syslog(pamh, LOG_ALERT, "Couldn't open %s", opts->filename);
        return ((opts->ctrl & OPT_FAIL_ON_ERROR) ? imana_file_fd : (PAM_SUCCESS));
    }

    gint32 rv = fstat(imana_file_fd, &fileinfo);
    if (rv) {
        pam_syslog(pamh, LOG_ALERT, "Couldn't stat %s", opts->filename);
        close(imana_file_fd);
        return ((opts->ctrl & OPT_FAIL_ON_ERROR) ? rv : (PAM_SUCCESS));
    }

    if (fileinfo.st_size == 0) {
        close(imana_file_fd);
        return PAM_AUTH_ERR;
    }

    gchar *filebuf = (gchar *)g_malloc0(fileinfo.st_size + 1);
    if (!filebuf) {
        close(imana_file_fd);
        return PAM_AUTH_ERR;
    }

    rv = read(imana_file_fd, filebuf, fileinfo.st_size);
    if (rv < 0) {
        close(imana_file_fd);
        g_free(filebuf);
        return ((opts->ctrl & OPT_FAIL_ON_ERROR) ? rv : (PAM_SUCCESS));
    }
    close(imana_file_fd);
    filebuf[fileinfo.st_size] = '\0';

    // 根据uid获取对应的用户信息
    rv = get_user(pamh, uid, filebuf, opts, ipmi_user);
    g_free(filebuf);

    return rv;
}

/*
 * Description: pam模块架构中用于实现认证的函数，声明在<security/pam_modules.h>，本模块必须实现
 */
gint32 pam_sm_authenticate(pam_handle_t *pamh, gint32 flags, gint32 argc, const gchar **argv)
{
    IMANA_OPTIONS options = { 0 };
    IMANA_OPTIONS *opts = &options;
    uid_t uid = 0;
    const gchar *user = NULL;
    const void *void_from = NULL;
    const void *tty_name = NULL;
    IPMI_USER_S ipmi_user = {0};

    if (!pamh) {
        return PAM_SERVICE_ERR;
    }

    // 解析传入参数
    gint32 rv = parse_args(pamh, opts, argc, argv);
    if (rv != PAM_SUCCESS) {
        debug_log(DLOG_ERROR, "parse pam args failed");
        return ((opts->ctrl & OPT_FAIL_ON_ERROR) ? rv : (PAM_SUCCESS));
    }

    // 获取登录ip和设备
    rv = pam_get_item(pamh, PAM_RHOST, &void_from);
    gint32 rv2 = pam_get_item(pamh, PAM_TTY, &tty_name);
    if (PAM_SUCCESS != rv || PAM_SUCCESS != rv2) {
        pam_syslog(pamh, LOG_ALERT, "pam_get_item PAM_RHOST or PAM_TTY failed. rv:%d, rv2:%d", rv, rv2);
        return PAM_AUTH_ERR;
    }

    // 获取用户名和uid
    rv = pam_get_uid(pamh, &uid, &user);
    if (rv != PAM_SUCCESS) {
        debug_log(DLOG_ERROR, "git login user name or uid failed");
        return ((opts->ctrl & OPT_FAIL_ON_ERROR) ? rv : (PAM_SUCCESS));
    }

    // 若不是ipmi文件中存在的本地用户，跳过校验直接返回成功
    if (!check_uid_is_local_user(uid)) {
        return PAM_SUCCESS;
    } else { // 若是ipmi文件中存在的本地用户，获取bmc业务id
        uid -= IMANA_UID_BASE;
    }

    rv = get_ipmi_user(pamh, opts, (gint32)uid, &ipmi_user);
    if (rv != PAM_SUCCESS) {
        pam_syslog(pamh, LOG_ALERT, "get user failed");
        return PAM_USER_UNKNOWN;
    }

    // 校验用户属性（用户名、用户使能、用户权限、用户锁定、登录规则）
    // 校验登录接口的动作放到account动进行，排除因无接口权限导致的用户认证失败锁定
    rv = check_user(pamh, user, (const gchar *)tty_name, (const gchar *)void_from, &ipmi_user);
    if (rv != PAM_SUCCESS) {
        pam_syslog(pamh, LOG_ALERT, "check user failed");
        return PAM_PERM_DENIED;
    }

    return PAM_SUCCESS;
}

/*
 * Description: PAM架构要求用于认证的模块必须实现此函数，在这里直接返回PAM_SUCCESS
                PAM_EXTERN修饰不能去掉
 */
PAM_EXTERN gint32 pam_sm_setcred(pam_handle_t *pamh, gint32 flags, gint32 argc,
    const gchar **argv)
{
    return PAM_SUCCESS;
}

/*
 * Description: pam模块架构中用于实现账户权限管理的函数
 */
gint32 pam_sm_acct_mgmt(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
    IMANA_OPTIONS options = { 0 };
    IMANA_OPTIONS *opts = &options;
    uid_t uid = 0;
    const gchar *user = NULL;
    const void *tty_name = NULL;
    IPMI_USER_S ipmi_user = {0};

    if (!pamh) {
        return PAM_SERVICE_ERR;
    }

    // 解析传入参数
    gint32 rv = parse_args(pamh, opts, argc, argv);
    if (rv != PAM_SUCCESS) {
        debug_log(DLOG_ERROR, "parse pam args failed");
        return ((opts->ctrl & OPT_FAIL_ON_ERROR) ? rv : (PAM_SUCCESS));
    }

    // 获取登录ip和设备
    rv = pam_get_item(pamh, PAM_TTY, &tty_name);
    if (PAM_SUCCESS != rv) {
        pam_syslog(pamh, LOG_ALERT, "pam_get_item PAM_TTY failed. rv:%d", rv);
        return PAM_SERVICE_ERR;
    }

    // 获取用户名和uid
    rv = pam_get_uid(pamh, &uid, &user);
    if (rv != PAM_SUCCESS) {
        debug_log(DLOG_ERROR, "git login user name or uid failed");
        return ((opts->ctrl & OPT_FAIL_ON_ERROR) ? rv : (PAM_SUCCESS));
    }

    // 若不是ipmi文件中存在的本地用户，跳过校验直接返回成功
    if (!check_uid_is_local_user(uid)) {
        return PAM_SUCCESS;
    } else { // 若是ipmi文件中存在的本地用户，获取bmc业务id
        uid -= IMANA_UID_BASE;
    }

    rv = get_ipmi_user(pamh, opts, (gint32)uid, &ipmi_user);
    if (rv != PAM_SUCCESS) {
        pam_syslog(pamh, LOG_ALERT, "get user failed");
        return PAM_USER_UNKNOWN;
    }

    // 登录接口校验
    const gchar *tmp_user_name =
        strcmp(ipmi_user.user_name, RESERVED_ROOT_USER_NAME) == 0 ? ACTUAL_ROOT_USER_NAME : ipmi_user.user_name;
    rv = check_user_login_interface(pamh, &ipmi_user, tty_name);
    if (rv != PAM_SUCCESS) {
        debug_log(DLOG_ERROR, "Account(%s) is restricted by login interface", tmp_user_name);
        return PAM_PERM_DENIED;
    }

    return PAM_SUCCESS;
}