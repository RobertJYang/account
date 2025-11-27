-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN \"AS IS\" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.

local singleton = require 'mc.singleton'
local class = require 'mc.class'
local custom_msg = require 'messages.custom'
local log = require 'mc.logging'
local ipmi_cmds = require 'iam.ipmi.ipmi'
local ipmi_types = require 'ipmi.types'
local iam_err = require 'iam.errors'
local iam_enum = require 'class.types.types'

local user_config = require 'user_config'
local LdapContollerCollection = require 'domain.ldap.ldap_controller_collection'
local RemoteGroupCollection = require 'domain.remote_group.remote_group_collection'
local RemoteGroupService = require 'service.remote_group_service'
local Role = require 'domain.cache.role_cache'
local operation_logger = require 'interface.operation_logger'

-- LDAP返回Data前有5个固定字节
local LDAP_EXTRA_IPMI_DATA_LEN<const> = 5

-- @function 重置类属性
local function restore(obj)
    obj.length = 0
    obj.data = ''
end

-- @function     拼接类属性
-- @param offset 拼接位移
-- @param data   待拼接内容
local function format_cache_data(cache, offset, data)
    if offset == 0 then -- offset为0则重新填充数据
        cache.data = data
    elseif offset == cache.length then -- offset等于数据长度时，代表完整拼接
        cache.data = cache.data .. data
    else -- offset小于数据长度时，代表存在覆盖拼接
        local head = string.sub(cache.data, 1, offset)
        cache.data = head .. data
    end
    cache.length = string.len(cache.data)
end

local function validator_str(self, obj, req)
    local offset = req.Offset
    local length = req.Length

    -- 单次写入长度大于255、偏移在当前内容外无法索引、写入后总长度大于255
    if length > 255 or offset > obj.length or (length + offset) > 255 then
        log:error("invalid data length")
        error(custom_msg.IPMIRequestLengthInvalid())
    end
end

local function validator_boolean(self, obj, req)
    local offset = req.Offset
    local length = req.Length
    local flag   = req.Flag
    local data   = req.Data

    -- Enabled 有且只有一个字节
    if offset ~= 0 or length ~= 1 or flag ~= 0 then
        log:error("invalid paramter to set ldap config, offset = %d, length = %d, flag = %d", offset, length, flag)
        error(custom_msg.IPMIRequestLengthInvalid())
    end

    -- Boolean类型可用值仅有0-disable、1-enable
    if string.byte(data) ~= 0x00 and string.byte(data) ~= 0x01 then
        log:error("invalid ldap enabled")
        error(custom_msg.IPMIOutOfRange())
    end
end

local function validator_pwd(self, obj, req)
    local offset = req.Offset
    local length = req.Length

    -- 单次写入长度大于255、偏移在当前内容外无法索引、写入后总长度大于20
    if offset > obj.length or (length + offset) > 20 then
        log:error("invalid data length")
        error(custom_msg.IPMIRequestLengthInvalid())
    end
end

-- 校验参数为1个字节
local function validator_byte(self, obj, req)
    local offset = req.Offset
    local length = req.Length
    local flag   = req.Flag

    -- 参数有且只有一个字节
    if offset ~= 0 or length ~= 1 or flag ~= 0 then
        log:error("invalid paramter to set ldap config, offset = %d, length = %d, flag = %d", offset, length, flag)
        error(custom_msg.IPMIRequestLengthInvalid())
    end
end

local function get_port(self, controller_id, group_id)
    return string.pack('>H', self.controller_collection:get_ldap_controller_port(controller_id))
end

local function set_port(self, ctx, controller_id, group_id, value)
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    if string.len(value) ~= 2 then
        ctx.operation_log.params.value = "invalild value"
        log:error("invalid ldap port value")
        error(custom_msg.IPMIOutOfRange())
    end
    local port = string.unpack('>H', value)
    ctx.operation_log.params.value = port
    self.controller_collection:set_ldap_controller_port(controller_id, port)
    self.controller_collection.m_ldap_controller_changed:emit(controller_id, 'Port', port)
end

local function get_bind_dn(self, controller_id, group_id)
    return self.controller_collection:get_ldap_controller_bind_dn(controller_id, group_id)
end

local function set_bind_dn(self, ctx, controller_id, group_id, value)
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    ctx.operation_log.params.value = value
    self.controller_collection:set_ldap_controller_bind_dn(controller_id, value)
    self.controller_collection.m_ldap_controller_changed:emit(controller_id, 'BindDN', value)
end

local function get_bind_dn_pwd(self, controller_id, group_id)
    return ""
end

local function set_bind_dn_pwd(self, ctx, controller_id, group_id, value)
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    ctx.operation_log.params.value = '***'
    self.controller_collection:set_ldap_controller_bind_dn_psw(ctx, controller_id, value)
    ctx.operation_log.params.property_name = 'Password'
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    ctx.operation_log.params.value = '***'
end

local function get_folder(self, controller_id, group_id)
    return self.controller_collection:get_ldap_controller_folder(controller_id, group_id)
end

local function set_folder(self, ctx, controller_id, group_id, value)
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    ctx.operation_log.params.value = value
    self.controller_collection:set_ldap_controller_folder(controller_id, value)
    self.controller_collection.m_ldap_controller_changed:emit(controller_id, 'Folder', value)
end

local function get_host_addr(self, controller_id, group_id)
    return self.controller_collection:get_ldap_controller_hostaddr(controller_id, group_id)
end

local function set_host_addr(self, ctx, controller_id, group_id, value)
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    ctx.operation_log.params.value = value
    self.controller_collection:set_ldap_controller_hostaddr(controller_id, value)
    self.controller_collection.m_ldap_controller_changed:emit(controller_id, 'HostAddr', value)
end

local function get_domain(self, controller_id, group_id)
    return self.controller_collection:get_ldap_controller_domain(controller_id, group_id)
end

local function set_domain(self, ctx, controller_id, group_id, value)
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    ctx.operation_log.params.value = value
    self.controller_collection:set_ldap_controller_domain(controller_id, value)
    self.controller_collection.m_ldap_controller_changed:emit(controller_id, 'UserDomain', value)
end

local function get_cert_verify_enabled(self, controller_id, group_id)
    local enabled = self.controller_collection:get_ldap_controller_cert_verify_enabled(controller_id)
    return enabled and string.char(0x01) or string.char(0x00)
end

local function set_cert_verify_enabled(self, ctx, controller_id, group_id, value)
    local enabled = string.byte(value) == 0x01 and true or false
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    ctx.operation_log.params.value = tostring(enabled)
    self.controller_collection:set_ldap_controller_cert_verify_enabled(controller_id, enabled)
    self.controller_collection.m_ldap_controller_changed:emit(controller_id, 'CertVerifyEnabled', enabled)
end

local function get_cert_verify_level(self, controller_id, group_id)
    return string.char(self.controller_collection:get_ldap_controller_cert_verify_level(controller_id, group_id))
end

local function set_cert_verify_level(self, ctx, controller_id, group_id, value)
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    local level = string.byte(value)
    ctx.operation_log.params.value = tonumber(level)
    self.controller_collection:set_ldap_controller_cert_verify_level(ctx, controller_id, level)
    self.controller_collection.m_ldap_controller_changed:emit(controller_id, 'CertVerifyLevel', level)
end

local function get_enabled(self, controller_id, group_id)
    local enabled = self.controller_collection:get_ldap_controller_enabled(controller_id, group_id)
    return enabled and string.char(0x01) or string.char(0x00)
end

local function set_enabled(self, ctx, controller_id, group_id, value)
    local enabled = string.byte(value) == 0x01 and true or false
    ctx.operation_log.params.name = string.format('Controller(%s)', controller_id)
    ctx.operation_log.params.value = tostring(enabled)
    self.controller_collection:set_ldap_controller_enabled(controller_id, enabled)
    self.controller_collection.m_ldap_controller_changed:emit(controller_id, 'Enabled', enabled)
end

local function get_group_name(self, controller_id, group_id)
    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    if group == nil then
        return ''
    end

    return group:get_remote_group_name()
end

local function set_group_name(self, ctx, controller_id, group_id, value)
    local length = string.len(value)
    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)

    -- 如果组不存在，设置属性也为空，直接返回，也无需日志
    if group == nil and length == 0 then
        ctx.operation_log.operation = 'SkipLog'
        return
    end

    -- 若组不存在且有设置内容，以这个id创建组
    if group == nil and length ~= 0 then
        ctx.operation_log.operation = 'NewRemoteGroup'
        self.remote_group_service:new_remote_group(ctx, iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value(), controller_id,
            group_id, value, '', '', iam_enum.RoleType.CustomRole4:value(), {}, {'Web', 'SSH', 'Redfish'})
        return
    end

    local group_get_id = group:get_id()
    local mdb_id = group:get_group_mdb_id()
    -- 如果组存在但设置length为0，删除这个组
    if group ~= nil and length == 0 then
        ctx.operation_log.operation = 'DeleteRemoteGroup'
        self.group_collection:delete_remote_group(ctx, mdb_id)
        return
    end

    -- 若组存在且有设置属性，修改这个组的属性
    ctx.operation_log.params.name = string.format('Controller(%s) Gorup(%s)', controller_id, group_get_id)
    ctx.operation_log.params.value = value
    self.group_collection:set_remote_group_name(group_get_id, value)
    self.group_collection.m_remote_group_changed:emit(group_get_id, 'Name', value)
end

local function get_group_privilege(self, controller_id, group_id)
    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    -- 组不存在返回0x00
    if group == nil then
        return ''
    end

    local group_get_id = group:get_id()
    local privilege = self.group_collection:get_remote_group_privilege(group_get_id)
    return string.char(privilege)
end

local function set_group_privilege(self, ctx, controller_id, group_id, value)
    local data = string.byte(value) -- 将ipmi的16进制输入转10进制数字

    local role_name = self.m_rc:get_role_name_by_id(data)
    ctx.operation_log.params.name = string.format('Controller(%s) Group(%s)', controller_id, group_id)
    ctx.operation_log.params.value = role_name

    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    if group == nil then
        log:error('no invalid group, please check group id.')
        error(custom_msg.IPMIInvalidFieldRequest())
    end

    local group_get_id = group:get_id()

    self.group_collection:set_remote_group_role_id(group_get_id, data)
    self.group_collection:set_remote_group_privilege(group_get_id, data)
    self.group_collection.m_remote_group_changed:emit(group_get_id, "UserRoleId", data)
end

local function get_group_privilege_mask(self, controller_id, group_id)
    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    -- 组不存在返回0x00
    if group == nil then
        return ''
    end

    local group_privilege_mask = group:get_remote_group_privilege_mask()
    -- privilege mask存储后是10进制数字，获取时需要重新转换为16进制字符串
    return string.format('%X', group_privilege_mask)
end

local function generate_mask_digit(ch)
    local mask
    if string.byte(ch) >= string.byte('A') and string.byte(ch) <= string.byte('F') then
        mask = (string.byte(ch) - string.byte('A') + 10) & 0x0f
        return true, mask
    elseif string.byte(ch) >= string.byte('a') and string.byte(ch) <= string.byte('f') then
        mask = (string.byte(ch) - string.byte('a') + 10) & 0x0f
        return true, mask
    elseif string.byte(ch) >= string.byte('0') and string.byte(ch) <= string.byte('9') then
        mask = (string.byte(ch) - string.byte('0')) & 0x0f
        return true, mask
    end

    return false, nil
end

-- @function          实现权限掩码的转换
-- @param data        待转换掩码数据
-- @param length      待转换掩码数据长度
-- @return group_mask 转换后的掩码数据
local function remote_group_privilage_mask_transfer(data, length)
    -- 不管多长，只取最后8个字节
    local mask_len = length > 8 and 8 or length

    local group_mask = 0
    local ok, mask
    for i = 1, mask_len, 1 do
        group_mask = group_mask << 4
        ok, mask = generate_mask_digit(string.sub(data, i, i))
        if not ok then
            log:error('input parameter error, invalid privilege mask')
            error(custom_msg.IPMIInvalidFieldRequest())
        end
        group_mask = group_mask | mask
    end

    return group_mask
end

local function set_group_privilege_mask(self, ctx, controller_id, group_id, value)
    local length = string.len(value)

    ctx.operation_log.params.name = string.format('Controller(%s) Group(%s)', controller_id, group_id)
    ctx.operation_log.params.value = value

    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    -- 若组不存在，抛出错误
    if group == nil then
        log:error('no invalid group, please check group id.')
        error(custom_msg.IPMIInvalidFieldRequest())
    end

    local group_get_id = group:get_id()

    -- data转换
    local group_mask = remote_group_privilage_mask_transfer(value, length)
    -- 无用属性，未上资源树，本地存储即可
    self.group_collection:set_remote_group_privilege_mask(group_get_id, group_mask)
end

local function get_group_domain(self, controller_id, group_id)
    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    -- 组不存在返回0x00
    if group == nil then
        return ''
    end

    return group:get_remote_group_domain()
end

local function set_group_domain(self, ctx, controller_id, group_id, value)
    ctx.operation_log.params.name = string.format('Controller(%s) Group(%s)', controller_id, group_id)
    ctx.operation_log.params.value = value

    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    -- 若组不存在，抛出错误
    if group == nil then
        log:error('no invalid group, please check group id.')
        error(custom_msg.IPMIInvalidFieldRequest())
    end

    local group_get_id = group:get_id()

    -- 无用属性，未上资源树，本地存储即可
    self.group_collection:set_remote_group_domain(group_get_id, value)
end

local function get_group_access_rule(self, controller_id, group_id)
    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    -- 组不存在返回0x00
    if group == nil then
        return ''
    end

    return string.char(group:get_remote_group_permit_rule_ids())
end

local function set_group_access_rule(self, ctx, controller_id, group_id, value)
    local data = string.byte(value)

    ctx.operation_log.params.name = string.format('Controller(%s) Group(%s)', controller_id, group_id)
    ctx.operation_log.params.value = data

    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    -- 若组不存在，抛出错误
    if group == nil then
        log:error('no invalid group, please check group id.')
        error(custom_msg.IPMIInvalidFieldRequest())
    end

    local group_get_id = group:get_id()

    self.group_collection:set_remote_group_permit_rule_ids(group_get_id, data)
    local rules = {}
    if data & 0x01 ~= 0 then table.insert(rules, "Rule1") end
    if data & 0x02 ~= 0 then table.insert(rules, "Rule2") end
    if data & 0x04 ~= 0 then table.insert(rules, "Rule3") end
    self.group_collection.m_remote_group_changed:emit(group_get_id, "PermitRuleIds", rules)
end

local function get_group_folder(self, controller_id, group_id)
    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    -- 组不存在返回0x00
    if group == nil then
        return ''
    end

    return group:get_remote_group_folder()
end

local function set_group_folder(self, ctx, controller_id, group_id, value)
    ctx.operation_log.params.name = string.format('Controller(%s) Group(%s)', controller_id, group_id)
    ctx.operation_log.params.value = value

    local group = self.group_collection:get_remote_group_by_id('LDAP', controller_id, group_id)
    -- 若组不存在，抛出错误
    if group == nil then
        log:error('no invalid group, please check group id.')
        error(custom_msg.IPMIInvalidFieldRequest())
    end

    local group_get_id = group:get_id()

    self.group_collection:set_remote_group_folder(group_get_id, value)
    self.group_collection.m_remote_group_changed:emit(group_get_id, "Folder", value)
end

local config_handler = {
    [iam_enum.LdapConfig.Port:value()] = {
        property_name = "Port",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_port,
        set = set_port
    },
    [iam_enum.LdapConfig.BindDN:value()] = {
        property_name = "BindDN",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_bind_dn,
        set = set_bind_dn
    },
    [iam_enum.LdapConfig.Password:value()] = {
        property_name = "Password",
        data = "",
        length = 0,
        validator = validator_pwd,
        get = get_bind_dn_pwd,
        set = set_bind_dn_pwd
    },
    [iam_enum.LdapConfig.Folder:value()] = {
        property_name = "Folder",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_folder,
        set = set_folder
    },
    [iam_enum.LdapConfig.HostAddr:value()] = {
        property_name = "HostAddr",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_host_addr,
        set = set_host_addr
    },
    [iam_enum.LdapConfig.UserDomain:value()] = {
        property_name = "UserDomain",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_domain,
        set = set_domain
    },
    [iam_enum.LdapConfig.CertificateVerify:value()] = {
        property_name = "CertificateVerify",
        data = "",
        length = 0,
        validator = validator_boolean,
        get = get_cert_verify_enabled,
        set = set_cert_verify_enabled
    },
    [iam_enum.LdapConfig.CertificateVerifyLevel:value()] = {
        property_name = "CertificateVerifyLevel",
        data = "",
        length = 0,
        validator = validator_byte,
        get = get_cert_verify_level,
        set = set_cert_verify_level
    },
    [iam_enum.LdapConfig.Enabled:value()] = {
        property_name = "Enabled",
        data = "",
        length = 0,
        validator = validator_boolean,
        get = get_enabled,
        set = set_enabled
    },
    [iam_enum.LdapConfig.GroupName:value()] = {
        property_name = "GroupName",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_group_name,
        set = set_group_name
    },
    [iam_enum.LdapConfig.GroupPrivilege:value()] = {
        property_name = "GroupPrivilege",
        data = "",
        length = 0,
        validator = validator_byte,
        get = get_group_privilege,
        set = set_group_privilege
    },
    [iam_enum.LdapConfig.GroupPrivilegeMask:value()] = {
        property_name = "GroupPrivilegeMask",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_group_privilege_mask,
        set = set_group_privilege_mask
    },
    [iam_enum.LdapConfig.GroupDomain:value()] = {
        property_name = "GroupDomain",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_group_domain,
        set = set_group_domain
    },
    [iam_enum.LdapConfig.GroupAccessRule:value()] = {
        property_name = "GroupAccessRule",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_group_access_rule,
        set = set_group_access_rule
    },
    [iam_enum.LdapConfig.GroupFolder:value()] = {
        property_name = "GroupFolder",
        data = "",
        length = 0,
        validator = validator_str,
        get = get_group_folder,
        set = set_group_folder
    },
}

-- @function             实现属性获取
-- @param offset         待读数据位移（从第offset位开始读）
-- @param length         待读数据长度
-- @return complete_flag 标识目标字符串是否达到结尾
local function get_config_data(self, obj, offset, length, controller_id, group_id)
    local config_data = obj.get(self, controller_id, group_id)
    local data_len = string.len(config_data)
    local complete_flag = 0
    local result_str = ''

    -- 若为空，返回0x00
    if data_len == 0 then
        result_str = string.char(0x00)
        return result_str, complete_flag
    end

    -- 读取偏移超出总长度
    if offset >= data_len then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    -- 偏移(由于lua索引从1开始，offset需要加1) + 要读的长度 < 总长度，说明数据未读完整
    if (offset + 1 + length) <= data_len then
        complete_flag = 1
        result_str = string.sub(config_data, offset + 1, offset + length)
    else
        complete_flag = 0
        result_str = string.sub(config_data, offset + 1, data_len)
    end

    local real_len = string.len(result_str)
    -- 读取总长度超过ipmi命令长度上限
    if real_len >= (user_config.MAX_IPMI_DATA_LEN - LDAP_EXTRA_IPMI_DATA_LEN) then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    return result_str, complete_flag
end

-- @function   实现Ldap属性设置
-- @param ctx  上下文
-- @param data 待设置属性
local function set_config_data(self, obj, ctx, data, controller_id, group_id)
    obj.set(self, ctx, controller_id, group_id, data)
end

local LdapConfigIpmi = class()

function LdapConfigIpmi:ctor(account_service_cache)
    self.m_account_service_cache = account_service_cache
end

function LdapConfigIpmi:init()
    self.controller_collection = LdapContollerCollection.get_instance()
    self.group_collection = RemoteGroupCollection.get_instance()
    self.remote_group_service = RemoteGroupService.get_instance()
    self.m_rc = Role.get_instance()
end

-- @function ipmi设置LDAP属性总入口
-- @param req ipmi请求体
-- @param ctx 上下文
-- @param operation 待设置属性，用于控制分发命令
-- @return rsp ipmi返回体
function LdapConfigIpmi:ipmi_set_ldap_configuration(req, ctx)
    local controller_id = req.ControllerId
    local group_id = req.GroupId + 1
    local length = req.Length
    local offset = req.Offset
    local flag = req.Flag
    local data = req.Data
    local param = req.ParameterSelector

    -- 公共数据校验
    if flag ~= 0 and flag ~= 1 then
        log:error("invalid flag")
        error(custom_msg.IPMIOutOfRange())
    end

    if length ~= string.len(data) then
        log:error("invalid data length")
        error(custom_msg.IPMIRequestLengthInvalid())
    end

    -- 权限校验-该接口需要受带内用户管理使能限制
    local is_mgmt_enable = self.m_account_service_cache:check_ipmi_host_user_mgnt_enabled(ctx)
    if is_mgmt_enable == false then
        log:debug("host user management disable, can not execute cmd")
        error(iam_err.host_user_management_diabled())
    end

    local obj = config_handler[param]
    if obj == nil then
        log:error("invalid configuration type:%s", string.byte(param))
        error(custom_msg.IPMIInvalidCommand())
    end

    -- 修改各参数独立数据校验
    local ok, err = pcall(function () obj.validator(self, obj, req) end)
    -- 校验失败,重置数据
    if not ok then
        restore(obj)
        error(err)
    end

    -- 拼装待修改数据
    format_cache_data(obj, offset, data)

    -- 若flag为0，开始执行set动作
    if flag == 0 then
        local set_func = operation_logger.proxy(function(proxy_obj, proxy_ctx)
            local complete_data = proxy_obj.data
            restore(proxy_obj)
            proxy_ctx.operation_log.params.property_name = proxy_obj.property_name
            set_config_data(self, proxy_obj, proxy_ctx, complete_data, controller_id, group_id)
        end, "SetLdapConfiguration")
        set_func(obj, ctx)
    end

    local rsp = ipmi_cmds.SetLdapConfiguration.rsp.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    return rsp
end

-- @function ipmi获取LDAP属性总入口
-- @param req ipmi请求体
-- @param operation 待设置属性，用于控制分发命令
-- @return rsp ipmi返回体
function LdapConfigIpmi:ipmi_get_ldap_configuration(req)
    local length = req.Length
    local offset = req.Offset
    local controller_id = req.ControllerId
    local group_id = req.GroupId + 1
    local param = req.ParameterSelector

    -- 长度为0，异常数据
    if length == 0 then
        log:error("invalid length for read operation")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    local obj = config_handler[param]

    if obj == nil then
        log:error("invalid configuration type")
        error(custom_msg.IPMIInvalidCommand())
    end

    -- 读取数据
    local data, complete_flag = get_config_data(self, obj, offset, length, controller_id, group_id)

    local rsp = ipmi_cmds.GetLdapConfiguration.rsp.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.EndOfList = complete_flag
    rsp.Reserved = 0
    rsp.Data = data
    return rsp
end

return singleton(LdapConfigIpmi)