-- Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.

return {
    -- 每个控制器下最多存在5个认证组
    MAX_GROUP_CNT_IN_CONTROLLER = 5,
    -- 远程认证组最多存在35个，7个控制器（6LDAP+1KRB）*5个组（每个控制器）
    MAX_GROUP_COUNT = 35,
    -- LDAP域控制器最多存在6个
    MAX_LDAP_COUNT = 6,
    -- Kerberos域控制器最多存在1个
    MAX_Kerberos_COUNT = 1,
    -- 组名和文件夹名不超过255
    MAX_NAME_LENGTH = 255,
    -- 将登录规则id转为数字后，最大不超过7 = 1 + 2 + 4
    MAX_PERMIT_ID = 7,
    -- 远程认证最多只涉及WEB、SSH、REDFISH这3个接口,对应值为10001001 = 137
    MAX_LOGIN_INTERFACE_ID = 137,
    -- LDAP目前支持三种接口
    LDAP_SUPPORT_TYPE = {Web = 'Web',Redfish = 'Redfish',SSH = 'SSH'},
    -- Kerberos目前支持两种接口
    Kerberos_SUPPORT_TYPE = {Web = 'Web',Redfish = 'Redfish'}
}