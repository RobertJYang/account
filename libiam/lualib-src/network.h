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

#ifndef IAM_NETWORK_H
#define IAM_NETWORK_H
#include "comm_utils.h"

#ifdef __cplusplus
extern "C" {
#endif

#define MACADDRESS_LEN 64

gchar *get_mac_by_socket(const gchar *ip, const gchar *eth, gchar *mac_address);

/*
 * Description: 检查ipv6地址是否有效
 */
gint32 vos_ipv6_addr_valid_check(const guchar *ipv6Str);

/*
 * Description: 检查ipv4地址是否有效
 */
gint32 vos_ipv4_addr_valid_check(const guchar *ipv4);

/*
 * Description: 判断ipv4地址是否在子网中
 */
gint32 is_ip_in_subnet(const gchar *ip_str, const gchar *subnet_str);

/*
 * Description: 判断ipv6地址是否在子网中
 */
gint32 is_ipv6_in_subnet(const gchar *ip_str, const gchar *subnet_str);


#ifdef __cplusplus
}
#endif

#endif  // IAM_NETWORK_H
