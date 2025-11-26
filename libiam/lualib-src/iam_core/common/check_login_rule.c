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

#include <securec.h>
#include "glib.h"
#include "arpa/inet.h"
#include "net/if.h"
#include "net/if_arp.h"
#include "net/route.h"
#include "netinet/if_ether.h"
#include "netinet/in.h"
#include "sys/ioctl.h"
#include "sys/socket.h"
#include "sys/types.h"
#include "sys/stat.h"
#include "unistd.h"
#include "utils/vos.h"
#include "utils/file_securec.h"
#include "check_login_rule.h"

/* ========================================= 登录规则解析 ========================================= */
/*
 * Description: 解析登录规则文本
 * @param: [in] line：登录规则文本
 * @param: [out] login_rules：单条登录规则
 */
LOCAL gint32 parse_per_rule(gchar *line, LOGIN_RULE_INFO *login_rules)
{
    gint32 pos = 0;
    gchar *tmp_line = strdup(line);
    if (tmp_line == NULL) {
        debug_log(DLOG_ERROR, "strdup tmp_line fail.");
        return RET_ERR;
    }
    gchar *line_bak = tmp_line;
    gchar *token = strsep(&tmp_line, ",");
    while (token) {
        pos++;
        switch (pos) {
            case RULE_LINE_ID:
                (void)parse_line_token_to_uint8(token, &(login_rules->rule_id));
                break;
            case RULE_LINE_ENABLED:
                (void)parse_line_token_to_uint8(token, &(login_rules->rule_enabled));
                break;
            case RULE_LINE_TIME:
                (void)memcpy_s(login_rules->time_rule, sizeof(login_rules->time_rule), token, strlen(token));
                break;
            case RULE_LINE_IP:
                (void)memcpy_s(login_rules->ip_rule, sizeof(login_rules->ip_rule), token, strlen(token));
                break;
            case RULE_LINE_MAC:
                (void)memcpy_s(login_rules->mac_rule, sizeof(login_rules->mac_rule), token, strlen(token));
                break;
            case RULE_LINE_IPV6:
                (void)memcpy_s(login_rules->ipv6_rule, sizeof(login_rules->ipv6_rule), token, strlen(token));
                break;
            default:
                break;
        }
        token = strsep(&tmp_line, ",");
    }
    g_free(line_bak);
    return RET_OK;
}

/*
 * Description: 将登录规则文本解析到结构体
 * @param: [in] filebuf：登录规则文本
 * @param: [out] login_rules：登录规则集合
 */
LOCAL gint32 parse_rules(gchar *filebuf, LOGIN_RULE_INFO *login_rules)
{
    gint32 ret;

    gchar *tmp_line = (gchar *)g_malloc0(MAX_RULE_LINE_LEN);
    if (tmp_line == NULL) {
        debug_log(DLOG_ERROR, "g_malloc0 tmp_line fail.");
        return RET_ERR;
    }
    gchar *tmp_buf = (gchar *)g_malloc0(MAX_RULE_LINE_LEN * 3);
    if (tmp_buf == NULL) {
        debug_log(DLOG_ERROR, "g_malloc0 tmp_buf fail.");
        g_free(tmp_line);
        return RET_ERR;
    }
    gchar *line_bak = tmp_line;
    gchar *buf_bak = tmp_buf;
    gchar *token = NULL;
    gchar *endptr = NULL;

    /* 在记录权限的文件中，每行的数据格式如下:
    1,1,2023-05-11 00:00/2023-05-11 01:00,76.76.16.183,01:01:01,Fec0:75:1001::/48 */
    ret = memcpy_s(tmp_buf, MAX_RULE_LINE_LEN * 3, filebuf, strlen(filebuf));
    if (ret != EOK) {
        debug_log(DLOG_ERROR, "[BMC PAM]parse_rules: memcpy_s fail, ret = %d", ret);
        ret = RET_ERR;
        goto EXIT;
    }
    gchar *line = strsep(&tmp_buf, "\n");
    guint8 id;

    // 遍历每行数据，处理数据结构
    while (line && strlen(line) != 0) {
        ret = memset_s(tmp_line, MAX_RULE_LINE_LEN, 0, MAX_RULE_LINE_LEN);
        if (ret != EOK) {
            debug_log(DLOG_ERROR, "[BMC PAM]parse_rules: memset_s fail, ret = %d", ret);
            ret = RET_ERR;
            goto EXIT;
        }
        ret = memcpy_s(tmp_line, MAX_RULE_LINE_LEN, line, strlen(line));
        if (ret != EOK) {
            debug_log(DLOG_ERROR, "[BMC PAM]parse_rules: memcpy_s fail, ret = %d", ret);
            ret = RET_ERR;
            goto EXIT;
        }
        token    = strsep(&tmp_line, ",");
        tmp_line = line_bak;
        // 转换为10进制数字
        id = strtol(token, &endptr, DECIMAL_NUM);
        // 解析单行数据
        (void)parse_per_rule(line, &(login_rules[id - 1]));
        line = strsep(&tmp_buf, "\n");
    }

EXIT:
    g_free(line_bak);
    g_free(buf_bak);
    return ret == RET_ERR ? ret : RET_OK;
}

/*
 * Description: 从本地文件获取登录规则
 * @param: [out] login_rules：登录规则集合
 */
LOCAL gint32 get_login_rules(LOGIN_RULE_INFO *login_rules)
{
    struct stat fileinfo;
    gint32 fd = open_s(LOGINRULE_FILE, O_RDONLY, 0, NULL);
    if (fd < 0) {
        return RET_ERR;
    }

    gint32 ret = fstat(fd, &fileinfo);
    if (ret != 0) {
        close_s(fd);
        return RET_ERR;
    }

    if (fileinfo.st_size == 0) {
        close_s(fd);
        return RET_ERR;
    }

    gchar *filebuf = (gchar *)g_malloc0(fileinfo.st_size + 1);
    if (filebuf == NULL) {
        close_s(fd);
        return RET_ERR;
    }

    ret = read(fd, filebuf, fileinfo.st_size);
    if (ret < 0) {
        close_s(fd);
        g_free(filebuf);
        return RET_ERR;
    }
    close_s(fd);
    filebuf[fileinfo.st_size] = '\0';

    parse_rules(filebuf, login_rules);

    g_free(filebuf);

    return RET_OK;
}

/* ========================================= 时间规则校验 ========================================= */
/*
 * Description: 时间限制信息格式转换
 * @param: [in] time_string：时间规则字符串
 * @param: [out] time_info：时间规则结构体
 */
LOCAL gint32 timestr_to_numeric(gchar *time_string, size_t time_string_len, TIME_RULE_INFO *time_info)
{
    gint32 start_year;
    gint32 start_mon;
    gint32 start_day;
    gint32 start_hour;
    gint32 start_min;
    gint32 end_year;
    gint32 end_mon;
    gint32 end_day;
    gint32 end_hour;
    gint32 end_min;
    gint32 cnt;

    if (time_string == NULL || time_info == NULL) {
        debug_log(DLOG_ERROR, "%s param == NULL", __FUNCTION__);
        return RET_ERR;
    }

    // 设置默认值为0xff
    (void)memset_s((void *)time_info, sizeof(TIME_RULE_INFO), 0xff, sizeof(TIME_RULE_INFO));

    cnt = sscanf_s(time_string, "%d-%d-%d %d:%d/%d-%d-%d %d:%d",
        &start_year, &start_mon, &start_day, &start_hour, &start_min,
        &end_year, &end_mon, &end_day, &end_hour, &end_min);
    if (cnt != 10) { /* 一共10个数据 */
        return RET_ERR;
    }

    time_info->start_time.tm_year = ((guint32)start_year) & 0XFFFF;
    time_info->start_time.tm_mon = ((guint32)start_mon) & 0XFF;
    time_info->start_time.tm_mday = ((guint32)start_day) & 0XFF;
    time_info->start_time.tm_hour = ((guint32)start_hour) & 0XFF;
    time_info->start_time.tm_min = ((guint32)start_min) & 0XFF;
    time_info->end_time.tm_year = ((guint32)end_year) & 0XFFFF;
    time_info->end_time.tm_mon = ((guint32)end_mon) & 0XFF;
    time_info->end_time.tm_mday = ((guint32)end_day) & 0XFF;
    time_info->end_time.tm_hour = ((guint32)end_hour) & 0XFF;
    time_info->end_time.tm_min = ((guint32)end_min) & 0XFF;

    return RET_OK;
}

/*
 * Description: 将时间结构转换成数字-YMDHM
 */
LOCAL guint32 parse_time_ymdhm(guchar mmon, guchar mday, guchar hour, guchar min)
{
    guint32 time = 0;
    time += ((guint32)((guint8)mmon)) << 24; // 月份转数字左移24位
    time += ((guint32)((guint8)mday)) << 16; // 日期转数字左移16位
    time += ((guint32)((guint8)hour)) << 8;  // 小时转数字左移8位
    time += (guint8)min;                     // 分钟转数字置尾

    return time;
}

/*
 * Description: 将时间结构转换成数字-YMD
 */
LOCAL guint32 parse_time_ymd(guint16 year, guchar mmon, guchar mday)
{
    guint32 time = 0;
    time += ((guint32)((guint8)year)) << 16; // 年份转数字左移16位
    time += ((guint32)((guint8)mmon)) << 8;  // 月份转数字左移8位
    time += (guint8)mday;                    // 日期转数字置尾

    return time;
}

/*
 * Description: 将时间结构转换成数字-HM
 */
LOCAL guint32 parse_time_hm(guchar hour, guchar min)
{
    guint32 time = 0;
    time += ((guint32)((guint8)hour)) << 8; // 小时转数字左移8位
    time += ((guint32)((guint8)min));       // 分钟转数字置尾

    return time;
}

/*
 * Description: 检查时间限制状态-YMDHM
 */
LOCAL gint32 check_ymdhm(struct tm *now, TIME_RULE_INFO *time_info)
{
    // 除年份外构成整数，通过整数判断大小
    guint32 now_tmp = parse_time_ymdhm((1 + now->tm_mon), now->tm_mday, now->tm_hour, now->tm_min);

    guint32 start_tmp = parse_time_ymdhm(time_info->start_time.tm_mon, time_info->start_time.tm_mday,
        time_info->start_time.tm_hour, time_info->start_time.tm_min);

    guint32 end_tmp = parse_time_ymdhm(time_info->end_time.tm_mon, time_info->end_time.tm_mday,
        time_info->end_time.tm_hour, time_info->end_time.tm_min);

    if (((TIME_YEAR_BASE + now->tm_year) < time_info->start_time.tm_year) ||
        ((TIME_YEAR_BASE + now->tm_year) > time_info->end_time.tm_year)) {
        return RET_ERR;
    }

    if (((TIME_YEAR_BASE + now->tm_year) == time_info->start_time.tm_year) && (now_tmp < start_tmp)) {
        return RET_ERR;
    }

    if (((TIME_YEAR_BASE + now->tm_year) == time_info->end_time.tm_year) && (now_tmp > end_tmp)) {
        return RET_ERR;
    }

    return RET_OK;
}

/*
 * Description: 检查时间限制状态-YMD
 */
LOCAL gint32 check_ymd(struct tm *now, TIME_RULE_INFO *time_info)
{
    // 构成整数，通过整数判断大小
    guint32 now_tmp = parse_time_ymd((TIME_YEAR_BASE + (gulong)(now->tm_year)), (1 + (guint32)(now->tm_mon)),
        (guint32)(now->tm_mday));
    guint32 start_tmp = parse_time_ymd(time_info->start_time.tm_year, time_info->start_time.tm_mon,
        time_info->start_time.tm_mday);
    guint32 end_tmp = parse_time_ymd(time_info->end_time.tm_year, time_info->end_time.tm_mon,
        time_info->end_time.tm_mday);
    if ((now_tmp < start_tmp) || (now_tmp > end_tmp)) {
        return RET_ERR;
    } else {
        return RET_OK;
    }
}

/*
 * Description: 检查时间限制状态-HM
 */
LOCAL gint32 check_hm(struct tm *now, TIME_RULE_INFO *time_info)
{
    // 构成整数，通过整数判断大小
    guint32 now_tmp = parse_time_hm(now->tm_hour, now->tm_min);
    guint32 start_tmp = parse_time_hm(time_info->start_time.tm_hour, time_info->start_time.tm_min);
    guint32 end_tmp = parse_time_hm(time_info->end_time.tm_hour, time_info->end_time.tm_min);
    // 开始时间小于结束时间,例: 8:00--12:00 有效期为 8:00~12:00
    if (now_tmp < start_tmp || now_tmp > end_tmp) {
        return RET_ERR;
    } else {
        return RET_OK;
    }
}

/*
 * Description: 校验是否在规定时间内
 * @param: [in] now：当前时间
 * @param: [in] time_info：时间规则结构体
 * @param: [in] time_type_flag：时间校验类型
 */
LOCAL gint32 is_time_limited(struct tm *now, TIME_RULE_INFO *time_info, guint8 time_type_flag)
{
    switch (time_type_flag) {
        case TYPE_YMDHM:
            return check_ymdhm(now, time_info);
        case TYPE_YMD:
            return check_ymd(now, time_info);
        case TYPE_HM:
            return check_hm(now, time_info);
        default:
            break;
    }

    return RET_ERR;
}

/*
 * Description: 校验时间规则
 * @param: [in] time_rule：时间规则字符串
 */
LOCAL gint32 check_time_rule(gchar *time_rule)
{
    gchar real_time_info[MAX_RULE_LEN] = {0};
    TIME_RULE_INFO timeruleinfo = {0};
    struct tm local_time_tm;
    struct timeval tv;
    time_t local_time;
    gint32 iRet;
    gint32 ret;
    guint8 time_type_flag = -1;

    // 未设置时间规则，跳过
    if (strlen(time_rule) == 0) {
        return RET_OK;
    }

    // 获取当前时间
    ret = gettimeofday(&tv, NULL);
    if (ret != 0) {
        debug_log(DLOG_ERROR, "get current time failed!");
        return RET_ERR;
    }
    local_time = tv.tv_sec;
    (void)get_localtime_r(&local_time, &local_time_tm);

    // 判断时间规则类型
    /* time_rule格式:
       2014-01-01 00:00/2015-01-01 00:00  len = 33
       2014-01-01/2015-01-01              len = 21
       00:00/01:00                        len = 11
    */
    guint8 rule_len = (guint8)strlen(time_rule);
    if (rule_len == YMDHM_TIME_RULE_LEN) {
        iRet = snprintf_s(real_time_info, MAX_RULE_LEN, MAX_RULE_LEN - 1, "%s", time_rule);
        ret = timestr_to_numeric(real_time_info, sizeof(real_time_info), &timeruleinfo);
        if (ret != RET_OK || iRet <= 0) {
            return RET_ERR;
        }
        time_type_flag = TYPE_YMDHM;
    } else if (rule_len == YMD_TIME_RULE_LEN) {
        /* 拼接完期望内容为 2014-01-01 255:255/2015-01-01 255:255 */
        iRet = snprintf_s(real_time_info, MAX_RULE_LEN, MAX_RULE_LEN - 1, "%s", time_rule);
        // 前10位为 ****-**-** 第一个日期
        iRet = snprintf_s(real_time_info + 10, MAX_RULE_LEN - 10, MAX_RULE_LEN - 10 - 1, " 255:255%s 255:255",
            time_rule + 10); // 偏移10位，取"/"和第二个日期
        ret = timestr_to_numeric(real_time_info, sizeof(real_time_info), &timeruleinfo);
        if (ret != RET_OK || iRet <= 0) {
            return RET_ERR;
        }
        time_type_flag = TYPE_YMD;
    } else if (rule_len == HM_TIME_RULE_LEN) {
        /* 拼接完期望内容为 65535-255-255 00:00/65535-255-255 01:00 */
        iRet = snprintf_s(real_time_info, MAX_RULE_LEN, MAX_RULE_LEN - 1, "65535-255-255 %s", time_rule);
        // 前20位为 65535-255-255 **:**/ 第一个完整时间和"/"
        iRet = snprintf_s(real_time_info + 20, MAX_RULE_LEN - 20, MAX_RULE_LEN - 20 - 1, "65535-255-255 %s",
            time_rule + 6); // 偏移6位，取第二个完整时间
        ret = timestr_to_numeric(real_time_info, sizeof(real_time_info), &timeruleinfo);
        if (ret != RET_OK || iRet <= 0) {
            return RET_ERR;
        }
        time_type_flag = TYPE_HM;
    }

    return is_time_limited(&local_time_tm, &timeruleinfo, time_type_flag);
}

/* ========================================= ip规则校验 ========================================= */

/*
 * Description: 校验ipv4地址是否合法
 * @param: [in] str_ipv4：ip字符串
 */
LOCAL gint32 verify_ipv4_address(const gchar *str_ipv4)
{
    if (str_ipv4 == NULL) {
        return RET_ERR;
    }

    struct in_addr ipaddr;
    gint32 ret = inet_pton(AF_INET, str_ipv4, (void *)&ipaddr.s_addr);
    if (ret != 1) {
        return RET_ERR;
    }

    guint8 sect1_low_thr = 1; // IP地址第一段小于1判断为不合法
    guint8 sect1_high_thr = 223; // 223: IP地址第一段大于223判断为不合法
    guint8 sect1 = ipaddr.s_addr & 0xff;
    if ((sect1 < sect1_low_thr) || (sect1 > sect1_high_thr) || (sect1 == 127)) { // IP地址第一段不能为127
        return RET_ERR;
    }

    return RET_OK;
}

/*
 * Description: 校验ipv6地址是否合法
 * @param: [in] str_ipv6：ip字符串
 */
LOCAL gint32 verify_ipv6_address(const gchar *str_ipv6)
{
    if (str_ipv6 == NULL) {
        return RET_ERR;
    }

    struct in6_addr ipaddr;
    gint32 ret = inet_pton(AF_INET6, str_ipv6, (void *)&ipaddr);
    if (ret != 1) {
        return RET_ERR;
    }

    // 判断是否为未指定、环回、本地链路、浮动IPv6广播地址
    if (IN6_IS_ADDR_UNSPECIFIED((const struct in6_addr *)&ipaddr)) {
        return RET_ERR;
    }

    if (IN6_IS_ADDR_LOOPBACK((const struct in6_addr *)&ipaddr)) {
        return RET_ERR;
    }

    if (IN6_IS_ADDR_LINKLOCAL((const struct in6_addr *)&ipaddr)) {
        return RET_ERR;
    }

    if (IN6_IS_ADDR_MULTICAST((const struct in6_addr *)&ipaddr)) {
        return RET_ERR;
    }

    return RET_OK;
}

/*
 * Description: 根据登录规则校验登录ip
 * @param: [in] ip_rule：ip规则字符串
 * @param: [in] ip_info：登录ip
 */
LOCAL gint32 verify_ip_with_rule(gchar *ip_rule, const gchar *ip_info)
{
    gchar subnet_ip[INET6_ADDRSTRLEN] = {0};
    int mask_len = 0;

    // 取ip地址
    gint32 ret = sscanf_s(ip_rule, "%46[^/]/%d$", subnet_ip, INET6_ADDRSTRLEN, &mask_len);
    if (ret <= 0) {
        debug_log(DLOG_ERROR, "%s: sscanf_s failed.", __FUNCTION__);
        return RET_ERR;
    }
    // ip规则为ipv4
    if (verify_ipv4_address((const gchar *)subnet_ip) == RET_OK) {
        return is_ip_in_subnet(ip_info, ip_rule);
    } else if (verify_ipv6_address((const gchar *)subnet_ip) == RET_OK) {
        return is_ipv6_in_subnet(ip_info, ip_rule);
    } else {
        debug_log(DLOG_ERROR, "%s: invalid ip rule.", __FUNCTION__);
        return RET_ERR;
    }
}

/*
 * Description: 校验ip规则
 * @param: [in] ip_rule：ip规则字符串
 * @param: [in] ip_info：登录ip
 */
LOCAL gint32 check_ip_rule(gchar *ip_rule, const gchar *ip_info)
{
    gchar tmp_check_ip[MAX_RULE_LEN + 1] = {0};

    // 未设置ip规则，跳过
    if (strlen(ip_rule) == 0) {
        return RET_OK;
    }

    gint32 ret = strcpy_s(tmp_check_ip, sizeof(tmp_check_ip), ip_info);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "strcpy_s:%s error %d", ip_info, ret);
        return RET_ERR;
    }

    // 使用tmp_check_ip,若原ip带端口，已截断；若原ip不带端口，则是原文
    ret = verify_ip_with_rule(ip_rule, (const gchar *)tmp_check_ip);
    return ret == RET_OK ? RET_OK : RET_ERR;
}

/* ========================================= mac规则校验 ========================================= */
/*
 * Description: 检查ip是否在对应网口中，并获取该网口的mac地址
 * @param: [in] sockfd: sockfd描述符
 * @param: [in & out] arp: arp结构，存放各网络接口信息
 * @param: [in] active_port_name: 当前活动网口名
 * @param: [in] ip_info: 登录ip
 */
LOCAL gint32 get_mac_by_socket(gint32 sockfd, struct arpreq *arp, gchar *active_port_name, const gchar *ip_info)
{
    struct sockaddr_in sin;

    (void)memset_s(&sin, sizeof(sin), 0, sizeof(sin));
    sin.sin_family = AF_INET;
    if (inet_aton(ip_info, &sin.sin_addr) == 0) {
        debug_log(DLOG_ERROR, "IP address '%s' is invalid\n", ip_info);
        return RET_ERR;
    }

    gint32 ret = memcpy_s((void *)&(arp->arp_pa), sizeof(arp->arp_pa), &sin, sizeof(arp->arp_pa));
    if (ret != EOK) {
        debug_log(DLOG_ERROR, "memcpy_s fail, ret = %d", ret);
    }

    // 检查IP是否在eth中
    (void)strncpy_s(arp->arp_dev, sizeof(arp->arp_dev), (const gchar *)active_port_name, sizeof(arp->arp_dev) - 1);

    if (ioctl(sockfd, SIOCGARP, arp) == -1) {
        debug_log(DLOG_ERROR, "Call ioctl failed");
        ret = RET_ERR;
    }

    return ret;
}

/*
 * Description: 匹配当前活动网口的mac地址
 * @param: [in] mac_rule：mac规则字符串
 * @param：[in] ip_info: 登录ip
 */
LOCAL gint32 check_mac(gchar *mac_rule, const gchar *ip_info)
{
    struct ifconf ifc;
    struct arpreq myarp;
    gchar macaddr[MACADDRESS_LEN + 1] = {0};

    gint32 sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        debug_log(DLOG_ERROR, "cannot open socket");
        return RET_ERR;
    }

    gchar *pBuffer = (gchar *)g_malloc0(IF_BUFFER_SIZE);
    ifc.ifc_len = IF_BUFFER_SIZE;
    ifc.ifc_buf = pBuffer;

    // 通过SIOCGIFCONF获取所有活动网口（常规情况下为eth*和lo）
    gint32 ret = ioctl(sockfd, SIOCGIFCONF, &ifc);
    debug_log(DLOG_INFO, "ioctl return %d, ifc_len:%d->%d, ifr size:%d\n", ret, IF_BUFFER_SIZE, ifc.ifc_len,
        sizeof(struct ifreq));
    if (ret < 0) {
        close(sockfd);
        g_free(pBuffer);
        debug_log(DLOG_ERROR, "Call ioctl failed");
        return RET_ERR;
    }

    struct ifreq* it = ifc.ifc_req;
    size_t ifCount =  (guint32)ifc.ifc_len / sizeof(struct ifreq);

    for (guint32 i = 0; i < ifCount; i++) {
        // 跳过回环网口
        if (strcmp(it[i].ifr_name, "lo") == 0) {
            continue;
        }

        (void)memset_s(&myarp, sizeof(struct arpreq), 0, sizeof(struct arpreq));
        ret = get_mac_by_socket(sockfd, &myarp, it[i].ifr_name, ip_info);
        if (RET_OK != ret) {
            debug_log(DLOG_ERROR, "%s has no entry in arp_cache for %s", it[i].ifr_name, ip_info);
            continue;
        }

        (void)snprintf_s(macaddr, MACADDRESS_LEN + 1, MACADDRESS_LEN, "%02x:%02x:%02x:%02x:%02x:%02x\n",
            myarp.arp_ha.sa_data[0], myarp.arp_ha.sa_data[1], myarp.arp_ha.sa_data[2],  // mac地址格式化，索引下标分别为0，1，2
            myarp.arp_ha.sa_data[3], myarp.arp_ha.sa_data[4], myarp.arp_ha.sa_data[5]); // mac地址格式化，索引下标分别为3，4，5

        ret = strncasecmp(macaddr, mac_rule, strlen(mac_rule));
        if (ret == RET_OK) {
            goto safe_exit;
        }
    }

safe_exit:
    close(sockfd);
    g_free(pBuffer);
    return ret == RET_OK ? RET_OK : RET_ERR;
}

/*
 * Description: 校验mac规则
 * @param: [in] mac_rule：mac规则字符串
 * @param: [in] ip_info：登录ip
 */
LOCAL gint32 check_mac_rule(gchar *mac_rule, const gchar *ip_info)
{
    // 未设置mac规则，跳过
    if (strlen(mac_rule) == 0) {
        return RET_OK;
    }

    // 当前规则只支持IPV4,源IP为IPV6格式，不进行限制判断，返回OK
    if (strchr(ip_info, ':')) {
        debug_log(DLOG_DEBUG, "verify_ipv6_address:%s", ip_info);

        if (verify_ipv6_address((const gchar *)ip_info) != RET_OK) {
            debug_log(DLOG_ERROR, "verify_ipv6_address:%s failed", ip_info);
            return RET_ERR;
        }

        return RET_OK;
    } else {
        if (verify_ipv4_address((const gchar *)ip_info) != RET_OK) {
            debug_log(DLOG_ERROR, "verify_ipv4_address:%s failed", ip_info);
            return RET_ERR;
        }
    }

    // 遍历当前活动网口的mac地址进行匹配
    gint32 ret = check_mac(mac_rule, ip_info);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "no entry in arp_cache for %s\n", ip_info);
    }

    return ret == RET_OK ? RET_OK : RET_ERR;
}

/* ========================================= 总函数 ========================================= */
/*
 * Description: 校验登录规则
 * @param: [in] rule_ids：登录规则id集合（1+2+4）
 * @param: [in] ip_addr：登录ip
 * @param: [in] login_rules：登录规则
 */
LOCAL gint32 check_rules(guint8 rule_ids, const gchar *ip_addr, LOGIN_RULE_INFO *login_rules)
{
    gint32 ret = 0;
    guint8 flag = 0;

    for (gint32 idx = 0; idx < MAX_RULE_COUNT; idx++) {
        // 登录规则未使能 或 用户未匹配该登录规则，直接跳过
        if (login_rules[idx].rule_enabled == 0 || ((rule_ids >> idx) & 1) == 0) {
            flag += (1 << idx) & 0xff;
            continue;
        }

        // 校验时间规则
        ret = check_time_rule(login_rules[idx].time_rule);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "check_time_rule fail! rule:%d", idx);
            continue;
        }

        // 校验ip规则
        // 优先获取ipv4规则
        // ipv4为空且ipv6有值的情况下选择ipv6，其余情况均选择ipv4
        if ((strlen(login_rules[idx].ip_rule) == 0) && (strlen(login_rules[idx].ipv6_rule) != 0)) {
            ret = check_ip_rule(login_rules[idx].ipv6_rule, ip_addr);
        } else {
            ret = check_ip_rule(login_rules[idx].ip_rule, ip_addr);
        }

        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "check_ip_rule fail! rule:%d", idx);
            continue;
        }

        // 校验mac规则
        ret = check_mac_rule(login_rules[idx].mac_rule, ip_addr);
        if (ret != RET_OK) {
            debug_log(DLOG_ERROR, "check_mac_rule fail! rule:%d", idx);
            continue;
        }

        // 所有规则都OK，返回成功
        return RET_OK;
    }

    // 遍历所有规则都无法校验通过，返回失败
    // 需判断是全部规则未使能还是存在规则校验不通过
    return flag == MAX_RULE_VALUE ? RET_OK : USER_LOGIN_LIMITED;
}

/*
 * Description: 使用本地文件校验登录规则
 * @param: [in] ipmi_user：登录规则id集合（1+2+4）
 * @param: [in] ip_addr：登录ip
 * @param: [in] tty_name: 登录设备
 */
gint32 check_user_login_rule(IPMI_USER_S *ipmi_user, const gchar *ip_addr, const gchar *tty_name)
{
    LOGIN_RULE_INFO login_rules[MAX_RULE_COUNT] = {0};

    // 串口/FTP，不校验登录规则
    if ((strncmp((const gchar *)tty_name, UART2_NAME, strlen(UART2_NAME)) == 0) ||
        (strncmp((const gchar *)tty_name, FTP_NAME, strlen(FTP_NAME)) == 0)) {
        return RET_OK;
    }

    // 未设置登录规则，无需校验
    if (ipmi_user->user_login_rule == 0) {
        return RET_OK;
    }

    // 逃生用户跳过校验
    if (ipmi_user->is_exclude_user == 1) {
        return RET_OK;
    }

    gint32 ret = get_login_rules(login_rules);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "get login rules fail.");
        return RET_ERR;
    }

    return check_rules(ipmi_user->user_login_rule, ip_addr, login_rules);
}

/*
 * Description: 使用本地文件校验登录规则
 * @param: [in] ruleids：登录规则id集合（1+2+4）
 * @param: [in] ip_addr：登录ip
 */
gint32 check_snmpv1v2_login_rule(gint32 ruleids, const gchar *ip_addr)
{
    LOGIN_RULE_INFO login_rules[MAX_RULE_COUNT] = {0};

    gint32 ret = get_login_rules(login_rules);
    if (ret != RET_OK) {
        debug_log(DLOG_ERROR, "get login rules fail.");
        return RET_ERR;
    }

    return check_rules(ruleids, ip_addr, login_rules);
}