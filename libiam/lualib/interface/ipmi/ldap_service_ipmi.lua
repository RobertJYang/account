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
local iam_utils = require 'utils'
local ipmi_cmds = require 'iam.ipmi.ipmi'
local ipmi_types = require 'ipmi.types'
local user_config = require 'user_config'
local operation_logger = require 'interface.operation_logger'
local ldap_controller_collection = require 'domain.ldap.ldap_controller_collection'
local ldap_config = require 'domain.ldap_config'
local iam_enum = require 'class.types.types'
local iam_err = require 'iam.errors'

-- 所有ipmi命令读写LDAP域控制器仅涉及控制器1
local IPMI_LDAP_CONTROLLER_ID<const> = 1

-- LDAP返回Data前有5个固定字节
local LDAP_EXTRA_IPMI_DATA_LEN<const> = 5

-- base 类，所有待修改属性继承该类
local LdapParamBase = class()

function LdapParamBase:ctor()
    self.length = 0
    self.data = ''
end

-- 由对应属性自己实现
function LdapParamBase:validator()
end

-- 由对应属性自己实现
function LdapParamBase:set()
end

-- 由对应属性自己实现
function LdapParamBase:get()
end

-- @function 重置类属性
function LdapParamBase:restore()
    self.length = 0
    self.data = ''
end

-- @function     拼接类属性
-- @param offset 拼接位移
-- @param data   待拼接内容
function LdapParamBase:format_cache_data(offset, data)
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

-- HostAddr 配置
local ParamHostAddr = class(LdapParamBase)

function ParamHostAddr:ctor()
    self.param = 'HostAddr'
    self.set_rsp_body = ipmi_cmds.SetLdapHostAddr.rsp
    self.get_rsp_body = ipmi_cmds.GetLdapHostAddr.rsp
    self.controller_collection = ldap_controller_collection.get_instance()
end

-- @function 实现ipmi设置host_addr属性校验
function ParamHostAddr:validator(req)
    local offset = req.Offset
    local length = req.Length

    -- 单次写入长度大于255、偏移在当前内容外无法索引、写入后总长度大于255
    if length > 255 or offset > self.length or (length + offset) > 255 then
        log:error("invalid data length")
        error(custom_msg.IPMIRequestLengthInvalid())
    end
end

-- @function   实现host_addr属性设置
-- @param ctx  上下文
-- @param data 待设置属性
function ParamHostAddr:set(ctx, data) 
    ctx.operation_log.params.addr = data
    self.controller_collection:set_ldap_controller_hostaddr(IPMI_LDAP_CONTROLLER_ID, data)
    self.controller_collection.m_ldap_controller_changed:emit(IPMI_LDAP_CONTROLLER_ID, self.param, data)
end

-- @function             实现host_addr属性获取
-- @param offset         待读数据位移（从第offset位开始读）
-- @param length         待读数据长度
-- @return addr_str      根据offset和length截取后的目标字符串
-- @return complete_flag 标识目标字符串是否达到结尾
function ParamHostAddr:get(offset, length)
    local host_addr = self.controller_collection:get_ldap_controller_hostaddr(IPMI_LDAP_CONTROLLER_ID)
    local addr_len = #host_addr
    local complete_flag = 0
    local addr_str = ''

    -- 若为空，返回0x00
    if addr_len == 0 then
        addr_str = string.char(0x00)
        return addr_str, complete_flag
    end

    -- 读取偏移超出总长度
    if offset >= addr_len then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    -- 偏移(由于lua索引从1开始，offset需要加1) + 要读的长度 < 总长度，说明数据未读完整
    if (offset + 1 + length) <= addr_len then
        complete_flag = 1
        addr_str = string.sub(host_addr, offset + 1, offset + length)
    else
        complete_flag = 0
        addr_str = string.sub(host_addr, offset + 1, addr_len)
    end

    local real_len = #addr_str
    -- 读取总长度超过ipmi命令长度上限
    if real_len >= (user_config.MAX_IPMI_DATA_LEN - LDAP_EXTRA_IPMI_DATA_LEN) then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    return addr_str, complete_flag
end

-- Domain 配置
local ParamDomain = class(LdapParamBase)

function ParamDomain:ctor()
    self.param = 'UserDomain'
    self.set_rsp_body = ipmi_cmds.SetLdapDomain.rsp
    self.get_rsp_body = ipmi_cmds.GetLdapDomain.rsp
    self.controller_collection = ldap_controller_collection.get_instance()
end

-- @function 实现ipmi设置domain属性校验
function ParamDomain:validator(req)
    local offset = req.Offset
    local length = req.Length

    -- 单次写入长度大于255、偏移在当前内容外无法索引、写入后总长度大于255
    if length > 255 or offset > self.length or (length + offset) > 255 then
        log:error("invalid data length")
        error(custom_msg.IPMIRequestLengthInvalid())
    end
end

-- @function   实现domain属性设置
-- @param ctx  上下文
-- @param data 待设置属性
function ParamDomain:set(ctx, data)
    ctx.operation_log.params.domain = data
    self.controller_collection:set_ldap_controller_domain(IPMI_LDAP_CONTROLLER_ID, data)
    self.controller_collection.m_ldap_controller_changed:emit(IPMI_LDAP_CONTROLLER_ID, self.param, data)
end

-- @function             实现domain属性获取
-- @param offset         待读数据位移（从第offset位开始读）
-- @param length         待读数据长度
-- @return domain_str    根据offset和length截取后的目标字符串
-- @return complete_flag 标识目标字符串是否达到结尾
function ParamDomain:get(offset, length)
    local domain = self.controller_collection:get_ldap_controller_domain(IPMI_LDAP_CONTROLLER_ID)
    local domain_len = #domain
    local complete_flag = 0
    local domain_str = ''

    -- 若为空，返回0x00
    if domain_len == 0 then
        domain_str = string.char(0x00)
        return domain_str, complete_flag
    end

    -- 读取偏移超出总长度
    if offset >= domain_len then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    -- 偏移(由于lua索引从1开始，offset需要加1) + 要读的长度 < 总长度，说明数据未读完整
    if (offset + 1 + length) <= domain_len then
        complete_flag = 1
        domain_str = string.sub(domain, offset + 1, offset + length)
    else
        complete_flag = 0
        domain_str = string.sub(domain, offset + 1, domain_len)
    end

    local real_len = #domain_str
    -- 读取总长度超过ipmi命令长度上限
    if real_len >= (user_config.MAX_IPMI_DATA_LEN - LDAP_EXTRA_IPMI_DATA_LEN) then
        log:error("offset exceed string length")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    return domain_str, complete_flag
end

-- Enabled 配置
local ParamEnabled = class(LdapParamBase)

function ParamEnabled:ctor()
    self.param = 'Enabled'
    self.set_rsp_body = ipmi_cmds.SetLdapEnabled.rsp
    self.get_rsp_body = ipmi_cmds.GetLdapEnabled.rsp
    self.config = ldap_config.get_instance()
end

-- @function 实现ipmi设置Enabled属性校验
function ParamEnabled:validator(req)
    local offset = req.Offset
    local length = req.Length
    local flag   = req.Flag
    local data   = req.Data

    -- Enabled 有且只有一个字节
    if offset ~= 0 or length ~= 1 or flag ~= 0 then
        log:error("invalid paramter to set ldap enabled, offset = %d, length = %d, flag = %d", offset, length, flag)
        error(custom_msg.IPMIRequestLengthInvalid())
    end

    -- Enabled使能可用值仅有0-disable、1-enable
    if string.byte(data) ~= 0x00 and string.byte(data) ~= 0x01 then
        log:error("invalid ldap enabled")
        error(custom_msg.IPMIOutOfRange())
    end
end

-- @function   实现Enabled属性设置
-- @param ctx  上下文
-- @param data 待设置属性
function ParamEnabled:set(ctx, data)
    local enabled = string.byte(data) == 0x01 and true or false
    ctx.operation_log.params.state = enabled and 'Enabled' or 'Disabled'
    self.config:set_ldap_enabled(enabled)
    self.config.m_ldap_config_changed:emit(self.param, enabled)
end

-- @function             实现Enabled属性获取
-- @param offset         待读数据位移（从第offset位开始读）
-- @param length         待读数据长度
-- @return enabled_str   根据offset和length截取后的目标字符串
-- @return complete_flag 标识目标字符串是否达到结尾
function ParamEnabled:get(offset, length)
    -- 使能获取无视offset和length
    local enabled = self.config:get_ldap_enabled()

    local enabled_str = enabled and string.char(0x01) or string.char(0x00)
    local complete_flag = 0

    return enabled_str, complete_flag
end


local LdapServiceIpmi = class()

function LdapServiceIpmi:ctor(account_service_cache)
    self.m_account_service_cache = account_service_cache
end

function LdapServiceIpmi:init()
    self.m_parameter_map = {
        ["LdapControllerHostAddr"] = ParamHostAddr.new(),
        ["LdapControllerDomain"] = ParamDomain.new(),
        ["LdapEnabled"] = ParamEnabled.new()
    }
end

-- @function ipmi设置LDAP属性总入口
-- @param req ipmi请求体
-- @param ctx 上下文
-- @param operation 待设置属性，用于控制分发命令
-- @return rsp ipmi返回体
function LdapServiceIpmi:ipmi_set_ldap_configuration(req, ctx, operation)
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

    local obj = self.m_parameter_map[operation]

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
            local complete_data = proxy_obj.data
            proxy_obj:restore()
            proxy_ctx.operation_log.params = { data = complete_data, id = IPMI_LDAP_CONTROLLER_ID }
            proxy_obj:set(proxy_ctx, complete_data)
        end, operation)
        set_func(obj, ctx)
    end

    local rsp = obj.set_rsp_body.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    return rsp
end

-- @function ipmi获取LDAP属性总入口
-- @param req ipmi请求体
-- @param operation 待设置属性，用于控制分发命令
-- @return rsp ipmi返回体
function LdapServiceIpmi:ipmi_get_ldap_configuration(req, operation)
    local length = req.Length
    local offset = req.Offset

    -- 长度为0，异常数据
    if length == 0 then
        log:error("invalid length for read operation")
        error(custom_msg.IPMICommandResponseCannotProvide())
    end

    local obj = self.m_parameter_map[operation]

    if obj == nil then
        log:error("invalid configuration type")
        error(custom_msg.IPMIInvalidCommand())
    end

    -- 读取数据
    local data, complete_flag = obj:get(offset, length)

    local rsp = obj.get_rsp_body.new()
    rsp.ManufactureId = req.ManufactureId
    rsp.CompletionCode = ipmi_types.Cc.Success
    rsp.EndOfList = complete_flag
    rsp.Reserved = 0
    rsp.Data = data
    return rsp
end

return singleton(LdapServiceIpmi)