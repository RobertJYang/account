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
local user_config = require 'user_config'
local iam_enum = require 'class.types.types'
local operation_logger = require 'interface.operation_logger'
local remote_group_collection = require 'domain.remote_group.remote_group_collection'
local remote_group_service = require 'service.remote_group_service'
local role = require 'domain.cache.role_cache'
local iam_err = require 'iam.errors'

-- 所有ipmi命令读写LDAP域控制器仅涉及控制器1
local IPMI_LDAP_CONTROLLER_ID<const> = 1

-- RemoteGroup返回Data前有5个固定字节
local GROUP_EXTRA_IPMI_DATA_LEN<const> = 5

-- base 类，所有待修改属性继承该类
local ParamBase = class()

function ParamBase:ctor()
    self.group_collection = remote_group_collection.get_instance()
    self.set_rsp_body = ipmi_cmds.SetRemoteGroupConfiguration.rsp
    self.get_rsp_body = ipmi_cmds.GetRemoteGroupConfiguration.rsp
    self.length = 0
    self.data = ''
end

-- 由对应属性自己实现
function ParamBase:validator()
end

-- 由对应属性自己实现
function ParamBase:set()
end

-- 由对应属性自己实现
function ParamBase:get()
end

-- @function 重置类属性
function ParamBase:restore()
    self.length = 0
    self.data = ''
end

-- @function     拼接类属性
-- @param offset 拼接位移
-- @param data   待拼接内容
function ParamBase:format_cache_data(offset, data)
    if offset == 0 then -- offset为0则重新填充数据
        self.data = data
    elseif offset == self.length then -- offset等于数据长度时，代表完整拼接
        self.data = self.data .. data
    else -- offset小于数据长度时，代表存在覆盖拼接
        local head = string.sub(self.data, 1, offset)
        self.data = head .. data
    end
    self.length = #self.data
end

-- GroupName 配置
local ParamGroupName = class(ParamBase)

function ParamGroupName:ctor()
    self.param = 'Name'
    self.operation = 'RemoteGroupName'
    self.service = remote_group_service.get_instance()
end

-- @function  实现ipmi设置GroupName属性校验
-- @param req ipmi请求体
function ParamGroupName:validator(req)
    local offset = req.Offset
    local length = req.Length

    -- 单次写入长度大于255、偏移在当前内容外无法索引、写入后总长度大于255
    if length > 255 or offset > self.length or (length + offset) > 255 then
        log:error("invalid data length")
        error(custom_msg.IPMIRequestLengthInvalid())
    end
end

-- @function       实现GroupName属性设置
-- @param ctx      上下文
-- @param inner_id 组id，用于索引对应的组
function ParamGroupName:set(ctx, inner_id)
    local data = self.data
    local length = self.length
    self:restore()

    local group = self.group_collection:get_remote_group_by_id('LDAP', IPMI_LDAP_CONTROLLER_ID, inner_id)

    -- 如果组不存在，设置属性也未空，直接返回，也无需日志
    if group == nil and length == 0 then
        ctx.operation_log.operation = 'SkipLog'
        return
    end

    -- 若组不存在且有设置内容，以这个id创建组
    if group == nil and length ~= 0 then
        ctx.operation_log.operation = 'NewRemoteGroup'
        self.service:new_remote_group(ctx, iam_enum.RemoteGroupType.GROUP_TYPE_LDAP:value(), IPMI_LDAP_CONTROLLER_ID,
            inner_id, data, '', '', iam_enum.RoleType.CustomRole4:value(), {}, {'Web', 'SSH', 'Redfish'})
        return
    end

    local group_id = group:get_id()
    local mdb_id = group:get_group_mdb_id()
    -- 如果组存在但设置length为0，删除这个组
    if group ~= nil and length == 0 then
        ctx.operation_log.operation = 'DeleteRemoteGroup'
        self.group_collection:delete_remote_group(ctx, mdb_id)
        return
    end

    -- 若组存在且有设置属性，修改这个组的属性
    local log_id = group:get_group_log_id()
    ctx.operation_log.params = { name = data, id = log_id }
    self.group_collection:set_remote_group_name(group_id, data)
    self.group_collection.m_remote_group_changed:emit(group_id, self.param, data)
end

-- @function             实现GroupName属性获取
-- @param inner_id       组id，用于索引对应的组
-- @param offset         待读数据位移（从第offset位开始读）
-- @param length         待读数据长度
-- @return name_str      根据offset和length截取后的目标字符串
-- @return complete_flag 标识目标字符串是否达到结尾
function ParamGroupName:get(inner_id, offset, length)
    local complete_flag = 0
    local name_str = ''
    local group = self.group_collection:get_remote_group_by_id('LDAP', IPMI_LDAP_CONTROLLER_ID, inner_id)
    -- 组不存在返回0x00
    if group == nil then
        name_str = string.char(0x00)
        return name_str, complete_flag
    end

    local group_name = group:get_remote_group_name()
    local name_len = #group_name

    -- 读取偏移超出总长度
    if offset >= name_len then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    -- 偏移(由于lua索引从1开始，offset需要加1) + 要读的长度 < 总长度，说明数据未读完整
    if (offset + 1 + length) <= name_len then
        complete_flag = 1
        name_str = string.sub(group_name, offset + 1, offset + length)
    else
        complete_flag = 0
        name_str = string.sub(group_name, offset + 1, name_len)
    end

    local real_len = #name_str
    -- 读取总长度超过ipmi命令长度上限
    if real_len >= (user_config.MAX_IPMI_DATA_LEN - GROUP_EXTRA_IPMI_DATA_LEN) then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    return name_str, complete_flag
end

-- GroupPrivilege 配置
local ParamGroupPrivilege = class(ParamBase)

function ParamGroupPrivilege:ctor()
    self.param = 'UserRoleId'
    self.operation = 'RemoteGroupRoleId'
    self.m_rc = role.get_instance()
end

-- @function  实现ipmi设置GroupPrivilege属性校验
-- @param req ipmi请求体
function ParamGroupPrivilege:validator(req)
    local offset = req.Offset
    local length = req.Length
    local flag   = req.Flag
    local data   = tonumber(req.Data, 16) -- 将ipmi的16进制输入转10进制数字

    -- 属性位仅占一个字节，不应有
    if offset ~= 0 or length ~= 1 or flag ~= 0 then
        log:error("invalid paramter to set group privilege, offset = %d, length = %d, flag = %d", offset, length, flag)
        error(custom_msg.IPMIRequestLengthInvalid())
    end

     -- Enabled使能可用值仅有0-disable、1-enable
     if data < iam_enum.RoleType.CommonUser:value() or data > iam_enum.RoleType.Administrator:value() then
        log:error("privilege level error, privilege is %d", data);
        error(custom_msg.IPMIOutOfRange())
    end
end

-- @function       实现GroupPrivilege属性设置
-- @param ctx      上下文
-- @param inner_id 组id，用于索引对应的组
function ParamGroupPrivilege:set(ctx, inner_id)
    local data = tonumber(self.data, 16) -- 将ipmi的16进制输入转10进制数字
    self:restore()

    local role_name = self.m_rc:get_role_name_by_id(data)
    ctx.operation_log.params = { role_name = role_name, id = "LDAP1 group" .. inner_id }

    local group = self.group_collection:get_remote_group_by_id('LDAP', IPMI_LDAP_CONTROLLER_ID, inner_id)
    if group == nil then
        log:error('no invalid group, please check group id.')
        error(custom_msg.IPMIInvalidFieldRequest())
    end

    local group_id = group:get_id()

    self.group_collection:set_remote_group_role_id(group_id, data)
    self.group_collection:set_remote_group_privilege(group_id, data)
    self.group_collection.m_remote_group_changed:emit(group_id, self.param, data)
end

-- @function             实现GroupName属性获取
-- @param inner_id       组id，用于索引对应的组
-- @param offset         待读数据位移（从第offset位开始读）
-- @param length         待读数据长度
-- @return privilege_str 根据offset和length截取后的目标字符串
-- @return complete_flag 标识目标字符串是否达到结尾
function ParamGroupPrivilege:get(inner_id, offset, length)
    local complete_flag = 0
    local privilege_str = ''
    local group = self.group_collection:get_remote_group_by_id('LDAP', IPMI_LDAP_CONTROLLER_ID, inner_id)
    -- 组不存在返回0x00
    if group == nil then
        privilege_str = string.char(0x00)
        return privilege_str, complete_flag
    end

    local group_id = group:get_id()
    -- 使能获取无视offset和length
    local privilege = self.group_collection:get_remote_group_privilege(group_id)
    privilege_str = tostring(privilege)
    return privilege_str, complete_flag
end

-- GroupPrivilegeMask 配置
local ParamGroupPrivilegeMask = class(ParamBase)
function ParamGroupPrivilegeMask:ctor()
    self.operation = 'RemoteGroupPrivilegeMask'
end

-- @function  实现ipmi设置GroupPrivilegeMask属性校验
-- @param req ipmi请求体
function ParamGroupPrivilegeMask:validator(req)
    local offset = req.Offset
    local length = req.Length

    -- 单次写入长度大于255、偏移在当前内容外无法索引、写入后总长度大于255
    if length > 255 or offset > self.length or (length + offset) > 255 then
        log:error("invalid data length")
        error(custom_msg.IPMIRequestLengthInvalid())
    end
end

local function generate_mask_digit(ch)
    local mask = 0
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

-- @function       实现GroupPrivilegeMask属性设置
-- @param ctx      上下文
-- @param inner_id 组id，用于索引对应的组
function ParamGroupPrivilegeMask:set(ctx, inner_id)
    local data = self.data
    local length = self.length
    self:restore()

    ctx.operation_log.params = { mask = data, id = "LDAP1 group" .. inner_id }

    local group = self.group_collection:get_remote_group_by_id('LDAP', IPMI_LDAP_CONTROLLER_ID, inner_id)
    -- 若组不存在，抛出错误
    if group == nil then
        log:error('no invalid group, please check group id.')
        error(custom_msg.IPMIInvalidFieldRequest())
    end

    local group_id = group:get_id()

    -- data转换
    local group_mask = remote_group_privilage_mask_transfer(data, length)
    -- 无用属性，未上资源树，本地存储即可
    self.group_collection:set_remote_group_privilege_mask(group_id, group_mask)
end

-- @function             实现GroupPrivilegeMask属性获取
-- @param inner_id       组id，用于索引对应的组
-- @param offset         待读数据位移（从第offset位开始读）
-- @param length         待读数据长度
-- @return mask_str    根据offset和length截取后的目标字符串
-- @return complete_flag 标识目标字符串是否达到结尾
function ParamGroupPrivilegeMask:get(inner_id, offset, length)
    local complete_flag = 0
    local mask_str = ''
    local group = self.group_collection:get_remote_group_by_id('LDAP', IPMI_LDAP_CONTROLLER_ID, inner_id)
    -- 组不存在返回0x00
    if group == nil then
        mask_str = string.char(0x00)
        return mask_str, complete_flag
    end

    local group_privilege_mask = group:get_remote_group_privilege_mask()
    -- privilege mask存储后是10进制数字，获取时需要重新转换为16进制字符串
    group_privilege_mask = string.format('%X', group_privilege_mask)
    local mask_len = #group_privilege_mask

    -- 读取偏移超出总长度
    if offset >= mask_len then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    -- 偏移(由于lua索引从1开始，offset需要加1) + 要读的长度 < 总长度，说明数据未读完整
    if (offset + 1 + length) <= mask_len then
        complete_flag = 1
        mask_str = string.sub(group_privilege_mask, offset + 1, offset + length)
    else
        complete_flag = 0
        mask_str = string.sub(group_privilege_mask, offset + 1, mask_len)
    end

    local real_len = #mask_str
    -- 读取总长度超过ipmi命令长度上限
    if real_len >= (user_config.MAX_IPMI_DATA_LEN - GROUP_EXTRA_IPMI_DATA_LEN) then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    return mask_str, complete_flag
end

-- GroupDomain 配置
local ParamGroupDomain = class(ParamBase)
function ParamGroupDomain:ctor()
    self.operation = 'RemoteGroupDomain'
end

-- @function  实现ipmi设置GroupDomain属性校验
-- @param req ipmi请求体
function ParamGroupDomain:validator(req)
    local offset = req.Offset
    local length = req.Length

    -- 单次写入长度大于255、偏移在当前内容外无法索引、写入后总长度大于255
    if length > 255 or offset > self.length or (length + offset) > 255 then
        log:error("invalid data length")
        error(custom_msg.IPMIRequestLengthInvalid())
    end
end

-- @function       实现GroupDomain属性设置
-- @param ctx      上下文
-- @param inner_id 组id，用于索引对应的组
function ParamGroupDomain:set(ctx, inner_id)
    local data = self.data
    self:restore()

    ctx.operation_log.params = { domain = data, id = "LDAP1 group" .. inner_id }

    local group = self.group_collection:get_remote_group_by_id('LDAP', IPMI_LDAP_CONTROLLER_ID, inner_id)
    -- 若组不存在，抛出错误
    if group == nil then
        log:error('no invalid group, please check group id.')
        error(custom_msg.IPMIInvalidFieldRequest())
    end

    local group_id = group:get_id()

    -- 无用属性，未上资源树，本地存储即可
    self.group_collection:set_remote_group_domain(group_id, data)
end

-- @function             实现GroupDomain属性获取
-- @param inner_id       组id，用于索引对应的组
-- @param offset         待读数据位移（从第offset位开始读）
-- @param length         待读数据长度
-- @return domain_str    根据offset和length截取后的目标字符串
-- @return complete_flag 标识目标字符串是否达到结尾
function ParamGroupDomain:get(inner_id, offset, length)
    local complete_flag = 0
    local domain_str = ''
    local group = self.group_collection:get_remote_group_by_id('LDAP', IPMI_LDAP_CONTROLLER_ID, inner_id)
    -- 组不存在返回0x00
    if group == nil then
        domain_str = string.char(0x00)
        return domain_str, complete_flag
    end

    local group_domain = group:get_remote_group_domain()
    local domain_len = #group_domain

    -- 读取偏移超出总长度
    if offset >= domain_len then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    -- 偏移(由于lua索引从1开始，offset需要加1) + 要读的长度 < 总长度，说明数据未读完整
    if (offset + 1 + length) <= domain_len then
        complete_flag = 1
        domain_str = string.sub(group_domain, offset + 1, offset + length)
    else
        complete_flag = 0
        domain_str = string.sub(group_domain, offset + 1, domain_len)
    end

    local real_len = #domain_str
    -- 读取总长度超过ipmi命令长度上限
    if real_len >= (user_config.MAX_IPMI_DATA_LEN - GROUP_EXTRA_IPMI_DATA_LEN) then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    return domain_str, complete_flag
end

-- main class
local RemoteGroupIpmi = class()

function RemoteGroupIpmi:ctor(account_service_cache)
    self.m_account_service_cache = account_service_cache
end

function RemoteGroupIpmi:init()
    self.m_parameter_map = {
        [0] = ParamGroupName.new(),
        [1] = ParamGroupPrivilege.new(),
        [2] = ParamGroupPrivilegeMask.new(),
        [3] = ParamGroupDomain.new()
    }
end

-- @function ipmi设置RemoteGroup属性总入口
-- @param req ipmi请求体
-- @param ctx 上下文
-- @return rsp ipmi返回体
function RemoteGroupIpmi:ipmi_set_remote_group_configuration(req, ctx)
    local group_id = req.GroupId + 1
    local configuration_type = req.ConfigurationType
    local length = req.Length
    local offset = req.Offset
    local flag = req.Flag
    local data = req.Data

    -- 公共数据校验
    if flag ~= 0 and flag ~= 1 then
        log:error("invalid flag")
        error(custom_msg.IPMIOutOfRange())
    end

    if length ~= #data then
        log:error("invalid data length")
        error(custom_msg.IPMIRequestLengthInvalid())
    end

    -- 权限校验-该接口需要受带内用户管理使能限制
    local is_mgmt_enable = self.m_account_service_cache:check_ipmi_host_user_mgnt_enabled(ctx)
    if is_mgmt_enable == false then
        log:debug("host user management disable, can not execute cmd")
        error(iam_err.host_user_management_diabled())
    end

    local obj = self.m_parameter_map[configuration_type]
    if obj == nil then
        log:error("invalid configuration type")
        error(custom_msg.IPMIInvalidCommand())
    end

    -- 修改各参数独立数据校验
    obj:validator(req)

    -- 拼装待修改数据
    obj:format_cache_data(offset, data)

    -- 若flag为0，开始执行set动作
    if flag == 0 then
        local set_func = operation_logger.proxy(function(proxy_obj, proxy_ctx)
            proxy_obj:set(proxy_ctx, group_id)
        end, obj.operation)
        set_func(obj, ctx)
    end

    local rsp = obj.set_rsp_body.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    return rsp
end

-- @function ipmi获取RemoteGroup属性总入口
-- @param req ipmi请求体
-- @return rsp ipmi返回体
function RemoteGroupIpmi:ipmi_get_remote_group_configuration(req)
    local group_id = req.GroupId + 1
    local configuration_type = req.ConfigurationType
    local length = req.Length
    local offset = req.Offset

    -- 长度为0，异常数据
    if length == 0 then
        log:error("invalid length for read operation")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    local obj = self.m_parameter_map[configuration_type]
    if obj == nil then
        log:error("invalid configuration type")
        error(custom_msg.IPMIInvalidCommand())
    end

    -- 读取数据
    local data, complete_flag = obj:get(group_id, offset, length)

    local rsp = obj.get_rsp_body.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.EndOfList = complete_flag
    rsp.Reserved = 0
    rsp.Data = data
    return rsp
end

return singleton(RemoteGroupIpmi)