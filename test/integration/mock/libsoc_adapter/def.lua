-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local define = {}

define.RET_OK = 0
define.RET_ERR = -1

define.COMP_CODE_SUCCESS = 0x00
define.COMP_CODE_UNKNOWN = 0xFF

define.VERIFY_H2P_INFO = {DATA_LOAD_FAIL = 0x01, DATA_VERIFY_FAIL = 0x02}

define.EFUSE_TYPE_INFO = {EFUSE_TYPE_NO_PARTNER = 0x00, EFUSE_TYPE_PARTNER = 0x01}

define.EFUSE_STATE_INFO = {EFUSE_STATE_NO_EFUSE = 0x00, EFUSE_STATE_EFUSE_ON = 0x01}

define.BOOT_MODE = {
    SEC_FW_NON_SECURE_BOOT = 0,
    SEC_FW_FACTORY_BOOT = 1,
    SEC_FW_GUEST_BOOT = 2,
    SEC_FW_DOUBLE_ROOT_BOOT = 3
}

-- 一级命令定义
define.CMD_1_SEC_DICE = 0x01
define.CMD_1_SEC_FW = 0x02

--  SEC_FW下的二级命令
define.CMD_2_GET_BIOS_MUX_STATUS = 0x01 --  获取BIOS MUX控制状态
define.CMD_2_SET_BIOS_MUX_STATUS = 0x02 --  设置BIOS MUX控制状态
define.CMD_2_VERIFY_BIOS = 0x03 --  请求校验BIOS
define.CMD_2_GET_BIOS_VERIFY_STATUS = 0x04 --  获取BIOS校验结果、状态
define.CMD_2_SET_CUSTOMER_INFO = 0x05 --  设置客户密钥信息			//not ready
define.CMD_2_GET_CUSTOMER_INFO = 0x06 --  获取客户密钥信息
define.CMD_2_SET_BMC_UPDATE_FLAG = 0x07 --  设置升级标志
define.CMD_2_GET_BMC_SECUREBOOT_INFO = 0x08 --  获取安全启动信息
define.CMD_2_GET_BMC_LAST_UPGADE_RESULT = 0x0c --  获取BMC上次升级结果
define.CMD_2_SET_GUEST_INFO = 0x0d
define.CMD_2_FW_MSG_BMC_ROOTKEY_UPDATE = 0x18 --  KMC硬件根秘钥更新
define.CMD_2_FW_MSG_BMC_MASTER_KEY_ENCODE = 0X19 --  KMC硬件根秘钥加密主秘钥
define.CMD_2_FW_MSG_BMC_MASTER_KEY_DECODE = 0x20 --  KMC硬件根秘钥解密主秘钥
define.CMD_2_FW_MSG_PARTNER_VERIFY_H2P_CERT = 0x21 -- 校验伙伴的h2p证书

-- 安全核下的开发场景证书管理二级命令
define.CMD_2_IMPORT_PARTNER = 0x11 -- 导入伙伴证书
define.CMD_2_EXPORT_PARTNER_INFO = 0x12 -- 导出伙伴信息
define.CMD_2_EXPORT_REPAIR_INFO = 0x13 -- 导出维修信息
define.CMD_2_IMPORT_REPAIR_CERT = 0x14 -- 导入维修凭证
define.CMD_2_SET_M3_VERIFY_INVALID = 0x15 -- 使能M3校验

define.MSG_A55_SCM3_ERROR_CODE = {
    -- efuse
    MSG_ERR_EFUSE_A55_DJ_FORBID = 0x5001,
    -- parter info import
    MSG_ERR_PARTNER_CHECK_FAIL = 0x7001, -- partner info field check fail
    MSG_ERR_PARTNER_MEM_FAIL = 0x7002, -- partner info get memory fail
    MSG_ERR_PARTNER_LOAD_FAIL = 0x7003, -- partner info read fail
    MSG_ERR_PARTNER_NON_SEC = 0x7004, -- firmware & bios are both non secure boot
    MSG_ERR_PARTNER_MODE_ERR = 0x7005, -- partner mode is not enable
    MSG_ERR_PARTNER_FW_V_NALLOWED = 0x7006, -- firmware is not secure boot, not allowd to enable verify
    MSG_ERR_PARTNER_BIOS_V_NALLOWED = 0x7007, -- bios is not secure boot, not allowd to enable verify
    MSG_ERR_PARTNER_S1_IMPORTED = 0x7008, -- partner info S1 have been imported
    MSG_ERR_PARTNER_S2_IMPORTED = 0x7009, -- partner info S2 have been imported
    MSG_ERR_PARTNER_ALL_IMPORTED = 0x700A, -- partner infos have been imported
    MSG_ERR_PARTNER_H2P_LOAD_FAIL = 0x700B, -- h2p cert load fail
    MSG_ERR_PARTNER_H2P_VERIFY_FAIL = 0x700C, -- h2p cert verify fail
    MSG_ERR_PARTNER_PINFO_VERIFY_FAIL = 0x700D, -- partner info verify fail
    MSG_ERR_PARTNER_PINFO_WRITE_FAIL = 0x700E, -- partner info write fail
    -- partner mode repair
    MSG_ERR_PARTNER_NOT_IMPORTED = 0x700F, -- partner is not imported
    MSG_ERR_PARTNER_RCERT_DIEID_ERR = 0x7010, -- partner repair cert dieid is not matched
    MSG_ERR_PARTNER_RCERT_ALLREVOKED = 0x7011, -- partner all repair forbid bits has been used
    MSG_ERR_PARTNER_RCERT_REVOKED = 0x7012, -- partner repair cert has been used
    MSG_ERR_PARTNER_RCERT_VERIFY_VFAIL = 0x7013, -- partner repair cert verify fail
    MSG_ERR_PARTNER_PINFO_CLR_VFAIL = 0x7014, -- partner info write to rpmb fail
    MSG_ERR_PARTNER_FORBID_UPDATE_VFAIL = 0x7015 -- partner info write forbid bit to efuse fail
}

define.USB_STATE_NOT_USE = 0
define.USB_STATE_IN_USE = 1
define.USB_INVALID_ID = 0xffffffff

return define
