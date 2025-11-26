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
 */
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/if_arp.h>
#include <unistd.h>
#include <ctype.h>
#include "securec.h"
#include "comm_utils.h"
#include "network.h"

/*
 * Description: 检查ipv4地址是否有效
 */
gint32 vos_ipv4_addr_valid_check(const guchar *ipv4)
{
    gint32 ret;
    guint8 iSect1; // ip地址第一段
    struct in_addr ipaddr;
    guint8 isect1_low_thr = 1;
    guint8 isect1_high_thr = 223; /* 223:ip地址第一段大于223判断为不合法 */

    if (ipv4 == NULL) {
        return 1;
    }

    ret = inet_pton(AF_INET, (const gchar *)ipv4, (void *)&ipaddr.s_addr);
    if (ret != 1) {
        return 1;
    } else {
        // 加入对特殊IP地址限制.
        iSect1 = ipaddr.s_addr & 0xff;
        /* 127: 特殊地址限定 */
        if (((iSect1 < isect1_low_thr) || (iSect1 > isect1_high_thr) || (iSect1 == 127))) {
            return 1;
        }
    }

    return 0;
}

/*
 * Description: 检查ipv6地址是否有效
 */
gint32 vos_ipv6_addr_valid_check(const guchar *ipv6Str)
{
    guchar buf[sizeof(struct in6_addr)];
    gint ret;

    if (!ipv6Str) {
        return 1;
    }

    ret = inet_pton(AF_INET6, (const gchar *)ipv6Str, buf);
    if (!ret) {
        return 1;
    }

    // 判断是否为地址未指定 环回地址 本地链路地址  浮动IPv6广播地址
    if (IN6_IS_ADDR_UNSPECIFIED((const struct in6_addr *)buf)) {
        return 1;
    }

    if (IN6_IS_ADDR_LOOPBACK((const struct in6_addr *)buf)) {
        return 1;
    }

    if (IN6_IS_ADDR_LINKLOCAL((const struct in6_addr *)buf)) {
        return 1;
    }

    if (IN6_IS_ADDR_MULTICAST((const struct in6_addr *)buf)) {
        return 1;
    }

    return 0;
}

/*
 * Description: 获取MAC地址
 */
gchar *get_mac_by_socket(const gchar *ip, const gchar *eth, gchar *mac_address)
{
    gint32 sockfd = -1;
    guchar *ptr = NULL;

    struct sockaddr_in *sin;
    struct arpreq arp_req;
 
    sin = (struct sockaddr_in *)&(arp_req.arp_pa);
    (void)memset_s(&arp_req, sizeof(arp_req), 0, sizeof(arp_req));

    sin->sin_family = AF_INET;
    inet_pton(AF_INET, ip, &(sin->sin_addr));
    // 检查IP是否在eth中
    (void)strncpy_s(arp_req.arp_dev, sizeof(arp_req.arp_dev),
        (const gchar *)eth, sizeof(arp_req.arp_dev) - 1);

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        debug_log(DLOG_ERROR, "%s: Failed to open socket.", __FUNCTION__);
        return NULL;
    }
    if (ioctl(sockfd, SIOCGARP, &arp_req) == -1) {
        close(sockfd);
        debug_log(DLOG_ERROR, "%s: Failed to get arp data.", __FUNCTION__);
        return NULL;
    }
    close(sockfd);
    sockfd = -1;

    if (!((guint32)arp_req.arp_flags & ATF_COM)) {
        debug_log(DLOG_ERROR, "%s: Arp flags is invalid.", __FUNCTION__);
        return NULL;
    }
    ptr = (guchar *)arp_req.arp_ha.sa_data;
    (void)snprintf_s(mac_address, MACADDRESS_LEN + 1, MACADDRESS_LEN, "%02x:%02x:%02x:%02x:%02x:%02x\n",
        *ptr, *(ptr + 1), *(ptr + 2), *(ptr + 3), *(ptr + 4), *(ptr + 5)); // mac地址格式化，索引下标分别为0，1，2，3，4，5

    return mac_address;
}

/*
 * Description: 判断ipv4地址是否为在子网中
 */
gint32 is_ip_in_subnet(const gchar *ip_str, const gchar *subnet_str)
{
    struct in_addr ip_addr, subnet_addr, subnet_mask;
    gchar subnet_ip[INET_ADDRSTRLEN];
    int mask_len = 32;

    if (inet_pton(AF_INET, ip_str, &ip_addr) != 1) {
        debug_log(DLOG_ERROR, "Invalid IP address: %s", ip_str);
        return RET_ERR;
    }

    // 没有设置掩码时等同于掩码长为32
    gint32 ret = sscanf_s(subnet_str, "%16[^/]/%d$", subnet_ip, INET_ADDRSTRLEN, &mask_len);
    if (ret <= 0) {
        debug_log(DLOG_ERROR, "%s: sscanf_s failed.", __FUNCTION__);
        return RET_ERR;
    }

    if (mask_len > 32 || mask_len < 1) {
        debug_log(DLOG_ERROR, "Invalid mask length: %d", mask_len);
        return RET_ERR;
    }

    if (inet_pton(AF_INET, subnet_ip, &subnet_addr) != 1) {
        debug_log(DLOG_ERROR, "Invalid subnet IP: %s", subnet_ip);
        return RET_ERR;
    }

    subnet_mask.s_addr = htonl(~((1 << (32 - mask_len)) - 1));

    ret = ((ip_addr.s_addr & subnet_mask.s_addr) == (subnet_addr.s_addr & subnet_mask.s_addr)) ? RET_OK : RET_ERR;
    return ret;
}

/*
 * Description: 判断ipv6地址是否为在子网中
 */
gint32 is_ipv6_in_subnet(const gchar *ip_str, const gchar *subnet_str)
{
    struct in6_addr ip_addr, subnet_addr;
    gchar subnet_ip[INET6_ADDRSTRLEN];
    int mask_len = 128;

    if (inet_pton(AF_INET6, ip_str, &ip_addr) != 1) {
        debug_log(DLOG_ERROR, "Invalid IPV6 address: %s", ip_str);
        return RET_ERR;
    }

    // 没有设置掩码时等同于掩码长为128
    gint32 ret = sscanf_s(subnet_str, "%46[^/]/%d$", subnet_ip, INET6_ADDRSTRLEN, &mask_len);
    if (ret <= 0) {
        debug_log(DLOG_ERROR, "%s: sscanf_s failed.", __FUNCTION__);
        return RET_ERR;
    }

    if (mask_len > 128 || mask_len < 1) {
        debug_log(DLOG_ERROR, "Invalid mask length: %d", mask_len);
        return RET_ERR;
    }

    if (inet_pton(AF_INET6, subnet_ip, &subnet_addr) != 1) {
        debug_log(DLOG_ERROR, "Invalid subnet IP: %s", subnet_ip);
        return RET_ERR;
    }

    int byte_len, bit_len;
    byte_len = mask_len / 8;
    bit_len = 8 - (mask_len % 8);
    int i = 0;
    while (i < byte_len) {
        if (subnet_addr.s6_addr[i] != ip_addr.s6_addr[i]) {
            debug_log(DLOG_ERROR, "Check ip failed");
            return RET_ERR;
        }
        i++;
    }
    if (byte_len == 16) {
        return RET_OK;
    }
    if ((subnet_addr.s6_addr[i] >> bit_len) == (ip_addr.s6_addr[i] >> bit_len)) {
        return RET_OK;
    }

    return RET_ERR;
}