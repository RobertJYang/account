-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local log = require 'mc.logging'
local mc_utils = require 'mc.utils'
local class = require 'mc.class'
local utils_core = require 'utils.core'
local file_utils = require 'utils.file'
local vos = require 'utils.vos'
local base_msg = require 'messages.base'
local enum = require 'class.types.types'
local config = require 'common_config'
local file_proxy = require 'infrastructure.file_proxy'
local core = require 'account_core'

-- role = gid groupname
local role_group_map = {
    [enum.RoleType.Administrator:value()] = { config.ADMINISTRATOR_GID, 'admin' },
    [enum.RoleType.Operator:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole1:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole2:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole3:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole4:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole5:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole6:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole7:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole8:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole9:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole10:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole11:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole12:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole13:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole14:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole15:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CustomRole16:value()] = { config.OPERATOR_GID, 'operator' },
    [enum.RoleType.CommonUser:value()] = { config.USER_GID, 'user' },
    [enum.RoleType.NoAccess:value()] = { config.NO_ACCESS_USER_GID, 'no_access' },
}

local function get_last_update_time(file_name)
    return utils_core.stat_s(file_name).st_mtim
end

local function is_time_changed(t1, t2)
    if not t1 or not t2 then
        return true
    end

    return t1.tv_sec ~= t2.tv_sec or t1.tv_nsec ~= t2.tv_nsec
end

local function str(v)
    local s = v and tostring(v)
    return s or ''
end

local FileBase = class()

function FileBase:ctor(path, tmp_path)
    self.path = core.format_realpath(path)
    self.tmp_path = core.format_realpath(tmp_path)
    self.last_updated_time = nil
    self.is_dirty = false
end

function FileBase:file_name()
    return self.path:match('([^/\\]+)$') or 'unknow'
end

function FileBase:open()
    local file, err = file_utils.open_s(self.path, 'r')
    if not file then
        err = err:gsub(self.path, '') -- 过滤文件路径不要打印到日志中
        log:error(string.format('Open file %s error: %s', self:file_name(), err))
        error(base_msg.InternalError())
    end

    return file
end

function FileBase:prepare()
    local last_updated_time = get_last_update_time(self.path)
    if not is_time_changed(last_updated_time, self.last_updated_time) then
        return
    end

    -- 当前有修改，并且文件被其他地方修改
    if self.is_dirty then
        log:error(string.format('Open file %s conflict.', self:file_name()))
        error(base_msg.InternalError())
    end

    self:__do_load()
    self.last_updated_time = last_updated_time
end

function FileBase:__do_load()
    log:error('Unimplementd mothod.')
    error(base_msg.InternalError())
end

function FileBase:dirty()
    self.is_dirty = true
end

-- skip_modify_time_check: 为了测试增加的参数，某些测试用例并不关心文件修改时间
function FileBase:save(skip_modify_time_check)
    if not self.is_dirty then
        return false
    end

    local last_updated_time = get_last_update_time(self.path)
    if is_time_changed(last_updated_time, self.last_updated_time) then
        log:error(string.format('File %s modifying conflict.', self:file_name()))
        error(base_msg.InternalError())
    end

    if not skip_modify_time_check then
        -- 需要间隔一会保证修改后文件时间改变
        while last_updated_time.tv_sec == os.time() do
            mc_utils.msleep(100)
        end
    end

    -- 先比较文件内容是否变更
    local new_content = table.concat(self:lines(), '\n')
    local target_file, err = file_utils.open_s(self.path, 'r')
    if not target_file then
        err = err:gsub(self.path, '') -- 过滤文件路径不要打印到日志中
        log:error(string.format('Open file %s error: %s', self:file_name(), err))
        error(base_msg.InternalError())
    end

    local old_content = target_file:read('*a')
    target_file:close()
    -- 若无变更，无需刷新文件
    if new_content == old_content then
        self.last_updated_time = get_last_update_time(self.path)
        self.is_dirty = false
        return false
    end

    -- 若有变更，再执行写入和替换动作
    local tmp_file, tmp_err = file_utils.open_s(self.tmp_path, 'w+')
    if not tmp_file then
        tmp_err = tmp_err:gsub(self.tmp_path, '') -- 过滤文件路径不要打印到日志中
        log:error(string.format('Open file %s error: %s', self:file_name(), tmp_err))
        error(base_msg.InternalError())
    end
    tmp_file:write(new_content)
    tmp_file:close()

    -- 执行替换动作，保留源文件权限
    file_utils.copy_file_content_s(self.tmp_path, self.path)
    mc_utils.remove_file(self.tmp_path)

    self.last_updated_time = get_last_update_time(self.path)
    self.is_dirty = false
    return true
end

-- linux 文件
local LinuxFile = class(FileBase)

function LinuxFile:ctor(path, tmp_path, dfx_enable)
    LinuxFile.super.ctor(self, path, tmp_path)
    -- path: 文件路径, data_key: 数据主键，对passwd和shadow来说是user_name，对group来说是group_id
    self.data_key = nil
    self.datas = {}
    self.dfx_enable = dfx_enable
    self.dfx_data = {}
end

function LinuxFile:init()
    self:prepare()
end

function LinuxFile:line_to_data(values)
    log:error('Unimplementd mothod.')
    error(base_msg.InternalError())
end

function LinuxFile:data_to_line(data)
    log:error('Unimplementd mothod.')
    error(base_msg.InternalError())
end

function LinuxFile:__do_load()
    local file = self:open()

    local datas = {}
    for line in file:lines() do
        if line == '' then
            goto continue
        end
        local values = mc_utils.split(line, ':')
        local info = self:line_to_data(values)
        if info == nil or datas[info[self.data_key]] ~= nil then
            goto continue
        end
        datas[#datas + 1] = info
        datas[info[self.data_key]] = info
        ::continue::
    end

    self.datas = datas
    file:close()
end

function LinuxFile:delete_data_by_key(data_key)
    local loc_idx = -1
    for idx, data in ipairs(self.datas) do
        if data[self.data_key] == data_key then
            loc_idx = idx
        end
    end
    if loc_idx == -1 then
        return
    end
    if loc_idx >= 0 then
        table.remove(self.datas, loc_idx)
    end
    self.datas[data_key] = nil
    log:debug("%s delete data by key(%s)", self:file_name(), data_key)
    self:dirty()
end

function LinuxFile:get(data_key)
    return self.datas[data_key]
end

function LinuxFile:lines()
    local lines = {}
    for _, data in ipairs(self.datas) do
        lines[#lines + 1] = self:data_to_line(data)
    end
    return lines
end

function LinuxFile:equals(data)
    local own_data = self.datas[data[self.data_key]]
    for key, value in pairs(own_data) do
        if data[key] ~= value then
            return false
        end
    end
    return true
end

function LinuxFile:add_item(data, overwrite)
    if self.datas[data[self.data_key]] ~= nil then
        if overwrite == false then
            log:debug('file key %s duplicated!', data[self.data_key])
            return
        end
        if self:equals(data) then
            log:debug('file key data %s is no change!', data[self.data_key])
            return
        end
        for idx, v in ipairs(self.datas) do
            if data[self.data_key] == v[self.data_key] then
                table.remove(self.datas, idx)
                break
            end
        end
    end
    self.datas[#self.datas + 1] = data
    self.datas[data[self.data_key]] = data
    self:dirty()
    self.dfx_data[#self.dfx_data + 1] = data[self.data_key]
end

function LinuxFile:save(skip_modify_time_check)
    local file_changed = LinuxFile.super.save(self, skip_modify_time_check)
    if not file_changed or not self:file_name() or not self.dfx_enable then
        return
    end

    if self.dfx_data and #self.dfx_data ~= 0 then
        local info = table.concat(self.dfx_data, ",")
        log:notice("[%s] write %s", self:file_name(), info)
        log:notice_printf("[%s] write %s", self:file_name(), info)
        self.dfx_data = {}
    end

    if self.dfx_data_group_user then
        for group_name , users in pairs(self.dfx_data_group_user) do
            local all_user = table.concat(users, ",")
            log:notice("[%s] add %s to group %s", self:file_name(), all_user, group_name)
            log:notice_printf("[%s] add %s to group %s", self:file_name(), all_user, group_name)
        end
        self.dfx_data_group_user = {}
    end
end

-- shadow 文件
local ShadowFile = class(LinuxFile)

function ShadowFile:ctor()
    -- path: 文件路径, data_key: 数据主键，对passwd和shadow来说是user_name，对group来说是group_id
    self.data_key = 'user_name'
end

function ShadowFile:line_to_data(values)
    if #values ~= 9 then
        log:error('invalid shadow file, the segment count: %d', #values)
        return nil
    end
    return {
        user_name = values[1],
        password = values[2],
        last_pwd_change = tonumber(values[3]),
        minimum = tonumber(values[4]),
        maximum = tonumber(values[5]),
        warn = tonumber(values[6]),
        inactive = tonumber(values[7]),
        expire = tonumber(values[8]),
        reserved = values[9]
    }
end

function ShadowFile:data_to_line(shadow)
    return table.concat({
        str(shadow.user_name),
        shadow.password or '*',
        str(shadow.last_pwd_change),
        str(shadow.minimumor),
        str(shadow.maximumor),
        str(shadow.warnor),
        str(shadow.inactiveor),
        str(shadow.expire),
        str(shadow.reserved)
    }, ':')
end

-- passwd 文件
local PasswdFile = class(LinuxFile)

function PasswdFile:ctor()
    -- path: 文件路径, data_key: 数据主键，对passwd和shadow来说是user_name，对group来说是group_id
    self.data_key = 'user_name'
end

function PasswdFile:line_to_data(values)
    if #values ~= 7 then
        log:error('invalid passwd file, the segment count: %d', #values)
        return nil
    end
    return {
        user_name = values[1],
        user_id = tonumber(values[3]),
        group_id = tonumber(values[4]),
        gecos = values[5],
        home_dir = values[6],
        shell = values[7],
    }
end

function PasswdFile:data_to_line(user)
    return table.concat({
        user.user_name, 'x', str(user.user_id), str(user.group_id), user.gecos or '', user.home_dir or '',
        user.shell or ''
    }, ':')
end

-- 用户组文件
local GroupFile = class(LinuxFile)

function GroupFile:ctor()
    -- path: 文件路径, data_key: 数据主键，对passwd和shadow来说是user_name，对group来说是group_name
    self.data_key = 'group_name'
    self.dfx_data_group_user = {}
end

function GroupFile:line_to_data(values)
    if #values ~= 4 then
        log:error('invalid group file, the segment count: %d', #values)
        return nil
    end
    return {
        group_name = values[1],
        group_id = tonumber(values[3]),
        users = mc_utils.split(values[4], ',') or {}
    }
end

function GroupFile:data_to_line(group)
    return table.concat({ str(group.group_name), 'x', str(group.group_id), table.concat(group.users or {}, ',') }, ':')
end

function GroupFile:has_user(user_name, group_name)
    local group = self.datas[group_name]
    if group == nil then
        return false
    end
    for _, user in ipairs(group.users) do
        if user == user_name then
            return true
        end
    end
    return false
end

function GroupFile:find_by_id(group_id)
    for _, group in ipairs(self.datas) do
        if group.group_id == group_id then
            return group
        end
    end
end

function GroupFile:create_group(group_name, group_id)
    local group = self.datas[group_name]
    if group then
        return group
    end
    group = {
        group_name = group_name,
        group_id = group_id,
        users = {}
    }
    self.datas[#self.datas + 1] = group
    self.datas[group_name] = group
    self:dirty()
    self.dfx_data[#self.dfx_data + 1] = group_name
    return group
end

function GroupFile:add_user(user_name, group_id, group_name)
    local group = self.datas[group_name]
    local ret = self:check_id_in_base_group(group_id)
    if not group and ret then
        local base_group_name = self:get_base_group_name(group_id)
        group = self:create_group(base_group_name, group_id)
    end
    if not group and not ret then
        group = self:create_group(user_name, group_id)
    end
    for _, user in ipairs(group.users) do
        if user == user_name then
            log:debug('add %s to user group %s: linux user exist', user_name, group_name)
            return
        end
    end
    table.insert(group.users, user_name)
    self:dirty()

    if not self.dfx_data_group_user[group_name] then
        self.dfx_data_group_user[group_name] = {}
    end
    table.insert(self.dfx_data_group_user[group_name], user_name)
end

function GroupFile:check_id_in_base_group(group_id)
    local ret = false
    for _, target_group in pairs(role_group_map) do
        if target_group[1] == group_id then
            ret = true
        end
    end
    return ret
end

-- 根据role_group_map里的组Id获取组名
function GroupFile:get_base_group_name(base_group_id)
    for _, target_group in pairs(role_group_map) do
        if target_group[1] == base_group_id then
            return target_group[2]
        end
    end
    return nil
end

function GroupFile:remove_user(user_name, group_name)
    local group = self.datas[group_name]
    if not group then
        return
    end
    for idx, user in ipairs(group.users) do
        if user == user_name then
            table.remove(group.users, idx)
            log:debug('remove %s from user group %s', user_name, group.group_name)
            self:dirty()
            return
        end
    end
end

function GroupFile:lines()
    local lines = {}
    for _, group in ipairs(self.datas) do
        lines[#lines + 1] = self:data_to_line(group)
    end
    return lines
end

-- Ipmi 文件
local IpmiFile = class(LinuxFile)

function IpmiFile:ctor()
    -- path: 文件路径, data_key: 数据主键，对passwd、ipmi和shadow来说是user_name，对group来说是group_name
    self.data_key = 'user_name'
end

function IpmiFile:line_to_data(values)
    if #values ~= 18 then
        log:error('invalid ipmi file, the segment count: %d', #values)
        return nil
    end
    return {
        user_id = values[1],
        user_name = values[2],
        user_password_max_length = tonumber(values[4]),
        max_session_cnt = tonumber(values[5]),
        is_callin = tonumber(values[6]),
        user_enabled = tonumber(values[7]),
        auth_enabled = tonumber(values[8]),
        ipmi_msg_enabled = tonumber(values[9]),
        is_enabled_by_passwd = tonumber(values[10]),
        privilege_0 = tonumber(values[11]),
        privilege_1 = tonumber(values[12]),
        is_locked = tonumber(values[14]),
        login_rule_ids_num = tonumber(values[15]),
        login_interface_num = tonumber(values[16]),
        is_exclude_user = tonumber(values[17]),
        is_password_expired = tonumber(values[18])
    }
end

function IpmiFile:data_to_line(ipmi_user)
    return table.concat({
        str(ipmi_user.user_id),
        str(ipmi_user.user_name),
        'x',
        str(ipmi_user.user_password_max_length),
        str(ipmi_user.max_session_cnt),
        str(ipmi_user.is_callin),
        str(ipmi_user.user_enabled),
        str(ipmi_user.auth_enabled),
        str(ipmi_user.ipmi_msg_enabled),
        str(ipmi_user.is_enabled_by_passwd),
        str(ipmi_user.privilege_0),
        str(ipmi_user.privilege_1),
        'x',
        str(ipmi_user.is_locked),
        str(ipmi_user.login_rule_ids_num),
        str(ipmi_user.login_interface_num),
        str(ipmi_user.is_exclude_user),
        str(ipmi_user.is_password_expired)
    }, ':')
end

-- 用户根目录
local HomeDir = class()
function HomeDir:ctor()
    if not vos.get_file_accessible(config.DATA_HOME_PATH) then
        log:info('Home directory does not exist, create one now')
        local home_path_mod = mc_utils.S_IRWXU | mc_utils.S_IRGRP | mc_utils.S_IXGRP | mc_utils.S_IROTH | mc_utils.S_IXOTH
        if not file_proxy.proxy_mkdir(config.DATA_HOME_PATH, home_path_mod, config.ROOT_USER_GID, config.ROOT_USER_GID) then
            log:error("mkdir home path failed")
        end
    end
end

--- 创建用户根目录
---@param user_name string
---@param uid number
---@param gid number
function HomeDir:create(user_name, uid, gid)
    local home_dir_path = self:get(user_name)
    if file_utils.check_real_path_s(home_dir_path) ~= 0 then
        if not file_proxy.proxy_mkdir(home_dir_path, mc_utils.S_IRWXU, uid, gid) then
            log:error("mkdir home path failed")
        end

        if not file_proxy.proxy_chown(home_dir_path, uid, gid) then
            log:error("chown home path failed")
        end
        if not file_proxy.proxy_chmod(home_dir_path, mc_utils.S_IRWXU) then
            log:error("chmod home path failed")
        end
    end
end

--- 修改用户名，只更新根目录，不能删除后再创建。同时涉及用户名修改为root情况。
---@param old_user_name any
---@param new_user_name any
function HomeDir:update(old_user_name, new_user_name, uid, gid)
    local new_home_dir_path = self:get(new_user_name)
    -- 若存在改名，才需要进行根目录名变更，否则可能被识别为将目录mv到自己的子目录
    if old_user_name ~= new_user_name then
        local old_home_dir_path = self:get(old_user_name)
        file_proxy.proxy_move(old_home_dir_path, new_home_dir_path, uid, gid)
    end
    file_proxy.proxy_chown(new_home_dir_path, uid, gid)
end

--- 删除用户根目录
---@param user_name string
function HomeDir:delete(user_name)
    local home_dir_path = self:get(user_name)
    file_proxy.proxy_delete(home_dir_path)
end

--- 获取用户根目录
---@param username string
function HomeDir:get(username)
    -- 区分系统root与<root>
    username = username == config.ACTUAL_ROOT_USER_NAME and config.RESERVED_ROOT_USER_NAME or username
    return table.concat({ config.DATA_HOME_PATH, username }, '/')
end

local file_mod = {
    ['.ssh'] = mc_utils.S_IRWXU,
    ['.ash_history'] = mc_utils.S_IRUSR | mc_utils.S_IWUSR,
    ['.ssh/authorized_keys'] = mc_utils.S_IRUSR | mc_utils.S_IWUSR
}

function HomeDir:set_home_file_owner(base_path, file_name, uid, gid)
    if not file_mod[file_name] then
        return
    end
    local file_path = base_path .. '/' .. file_name
    if file_proxy.proxy_access(file_path, 0) then
        file_proxy.proxy_chown(file_path, uid, gid)
        file_proxy.proxy_chmod(file_path, file_mod[file_name])
    end
end

function HomeDir:backup(backup_path, user_name, uid, gid)
    local home_dir_path = self:get(user_name)
    local backup_home_dir_path = backup_path .. '/' .. user_name
    file_proxy.proxy_mkdir(backup_home_dir_path, mc_utils.S_IRWXU, uid, gid)

    -- 复制.ash_history文件
    local ash_path = home_dir_path .. '/.ash_history'
    local backup_ash_path = backup_home_dir_path .. '/.ash_history'
    if file_proxy.proxy_access(ash_path, 0) then
        file_proxy.proxy_copy(ash_path, backup_ash_path, uid, gid)
        file_proxy.proxy_chmod(ash_path, mc_utils.S_IRUSR | mc_utils. S_IWUSR)
    end

    -- 复制.ssh/authorrized_keys目录
    local ssh_keys_path = table.concat({home_dir_path, config.SSH_PUBLIC_KEY_SUB_DIR_NAME, 'authorized_keys'}, '/')
    local backup_ssh_dir_path = table.concat({backup_home_dir_path, config.SSH_PUBLIC_KEY_SUB_DIR_NAME}, '/')
    local backup_ssh_key_path = table.concat({backup_home_dir_path, config.SSH_PUBLIC_KEY_SUB_DIR_NAME, 'authorized_keys'}, '/')

    if file_proxy.proxy_access(ssh_keys_path, 0) then
        file_proxy.proxy_mkdir(backup_ssh_dir_path, mc_utils.S_IRWXU, uid, gid)
        file_proxy.proxy_copy(ssh_keys_path, backup_ssh_key_path, uid, gid)
        file_proxy.proxy_chmod(backup_ssh_key_path, mc_utils.S_IRUSR | mc_utils. S_IWUSR)
    end
end

-- 用户管理
-- @class LinuxUserMgr
local LinuxUserMgr = class()

-- @param  dfx_enable 使能恢复场景dfx日志
-- @return LinuxUserMgr
function LinuxUserMgr:ctor(linux_files, is_save, dfx_enable)
    if is_save == nil then -- 不可为空，必须指明是否立即刷新
        error(base_msg.InternalError())
    end
    self.passwd_file = PasswdFile.new(linux_files.passwd_path, config.TMP_PASSWD_FILE, dfx_enable)
    self.shadow_file = ShadowFile.new(linux_files.shadow_path, config.TMP_SHADOW_FILE, dfx_enable)
    self.group_file = GroupFile.new(linux_files.group_path, config.TMP_GROUP_FILE, dfx_enable)
    self.ipmi_file = IpmiFile.new(linux_files.ipmi_path, config.TMP_IPMI_FILE, dfx_enable)
    self.home_dir = HomeDir.new()
    self.is_save = is_save
end

function LinuxUserMgr:save(skip_modify_time_check)
    self.passwd_file:save(skip_modify_time_check)
    self.shadow_file:save(skip_modify_time_check)
    self.group_file:save(skip_modify_time_check)
    self.ipmi_file:save(skip_modify_time_check)
end

function LinuxUserMgr:recover_file_owner(path, file_name, uid, gid)
    local file_path = path .. '/' .. file_name
    file_proxy.proxy_chown(file_path, uid, gid)
    file_proxy.proxy_chmod(file_path, mc_utils.S_IRWXU)
    self.home_dir:set_home_file_owner(file_path, '.ash_history', uid, gid)
    self.home_dir:set_home_file_owner(file_path, '.ssh', uid, gid)
    self.home_dir:set_home_file_owner(file_path, '.ssh/authorized_keys', uid, gid)
end

function LinuxUserMgr:backup_user_file(backup_path, user_name, uid, gid)
    self.home_dir:backup(backup_path, user_name, uid, gid)
end

function LinuxUserMgr:prepare_user(account, uid, gid, groupname)
    local user = {
        user_name = account.user_name,
        user_id = uid,
        group_id = gid,
        gecos = groupname,
        home_dir = self.home_dir:get(account.user_name),
        shell = core.get_user_shell()
    }

    local shadow = {
        user_name = account.user_name,
        password = account.password,
        last_pwd_change = '',
        minimumor = 0,
        maximumor = 99999,
        warnor = '',
        inactiveor = '',
        expire = '',
        reserved = ''
    }

    local ipmi_user = {
        user_id = account.id,
        user_name = account.user_name,
        password = 'x',
        user_password_max_length = 1, -- 是否最大20字节密码，未使用
        max_session_cnt = 5,          -- 支持最大会话数5个，未使用
        is_callin = 0,                -- 是否支持Callin，未使用
        user_enabled = account.user_enabled,
        auth_enabled = 1,             -- 是否参与认证，未使用
        ipmi_msg_enabled = 1,         -- 是否支持IPMI Message，未使用
        is_enabled_by_passwd = 0,     -- 是否可以通过密码激活，未使用
        privilege_0 = enum.IpmiPrivilege.RESERVED:value(),
        privilege_1 = account.privilege_num,
        snmp_privacy_password = 'x',
        is_locked = account.is_locked,
        login_rule_ids_num = account.login_rule_ids_num,
        login_interface_num = account.login_interface_num,
        is_exclude_user = account.is_exclude_user,
        is_password_expired = account.is_password_expired
    }

    return user, shadow, ipmi_user
end

local function escape_username(username)
    local to_be_replaced = {'`', '$', '!', '|', ';', '*', '<', '>'}
    for _, value in pairs(to_be_replaced) do
        local escape = '%' .. value
        local replace = '\\' .. value
        username, _ = string.gsub(username, escape, replace)
    end
    return username
end

local TALLY_LOG_PATH = '/dev/shm/tallylog/'

local function process_tallylog(account, uid)
    -- 支持snmp用户登录失败锁定功能
    local file_path = TALLY_LOG_PATH .. account.user_name
    local mode = mc_utils.S_IRUSR| mc_utils.S_IWUSR | mc_utils.S_IRGRP| mc_utils.S_IWGRP
    local res = file_proxy.proxy_access(file_path, 0)
    if not res then
        -- 文件不存在，创建文件
        core.reset_pam_tally(account.user_name, TALLY_LOG_PATH)
    end
    file_proxy.proxy_chmod(file_path, mode)
    file_proxy.proxy_chown(file_path, uid, config.APPS_USER_GID)
end

local function remove_tallylog(username)
    local user_name = escape_username(username)
    local tmp_file_path = TALLY_LOG_PATH .. user_name
    file_proxy.proxy_delete(tmp_file_path)
end

function LinuxUserMgr:add_user(account)
    if role_group_map[account.role] == nil then
        log:error('Invalid group file.')
        error(base_msg.InternalError())
    end
    local uid = config.LINUX_USER_ID_BASE + account.id
    local gid, groupname = role_group_map[account.role][1], role_group_map[account.role][2]

    local user, shadow, ipmi_user = self:prepare_user(account, uid, gid, groupname)

    if account.is_local_user then
        if account.is_change_user then
            self.home_dir:update(account.old_username, account.user_name, uid, gid)
        else
            self.home_dir:create(account.user_name, uid, gid)
        end
    end
    self.passwd_file:add_item(user)
    self.shadow_file:add_item(shadow)
    self.ipmi_file:add_item(ipmi_user)
    self.group_file:add_user(account.user_name, gid, groupname)
    if self.is_save then
        self.passwd_file:save(true)
        self.shadow_file:save(true)
        self.group_file:save(true)
        self.ipmi_file:save(true)
    end

    process_tallylog(account, uid)
end

function LinuxUserMgr:update_user(account)
    for _, value in pairs(role_group_map) do
        self.group_file:remove_user(account.user_name, value[2])
    end
    self:add_user(account)
    if self.is_save then
        self.passwd_file:save(true)
        self.shadow_file:save(true)
        self.group_file:save(true)
        self.ipmi_file:save(true)
    end
end

function LinuxUserMgr:add_user_group(username, role)
    if role_group_map[role] == nil then
        log:error('Invalid group file.')
        error(base_msg.InternalError())
    end
    local gid, groupname = role_group_map[role][1], role_group_map[role][2]
    self.group_file:add_user(username, gid, groupname)
    if self.is_save then
        self.group_file:save(true)
    end
end

function LinuxUserMgr:remove_user(username, role, is_change_user)
    -- 不指定role，默认删除所以组中用户
    if role ~= nil and role_group_map[role] == nil then
        log:error('Invalid group file.')
        error(base_msg.InternalError())
    end
    self.passwd_file:delete_data_by_key(username)
    self.shadow_file:delete_data_by_key(username)
    self.ipmi_file:delete_data_by_key(username)
    if role == nil then
        for _, value in pairs(role_group_map) do
            self.group_file:remove_user(username, value[2])
        end
    else
        local group_name = role_group_map[role][2]
        self.group_file:remove_user(username, group_name)
    end
    if not is_change_user then
        self.home_dir:delete(username)
    end
    if self.is_save then
        self.passwd_file:save(true)
        self.shadow_file:save(true)
        self.group_file:save(true)
        self.ipmi_file:save(true)
    end

    if not is_change_user then
        remove_tallylog(username)
    end
end

-- 单独ipmi配置文件
function LinuxUserMgr:flush_ipmi_user_cfg(username, id, user_enabled, privilege_num, is_locked, login_rule_ids_num,
    login_interface_num, is_exclude_user, is_password_expired)

    local ipmi_user = {
        user_id = id,
        user_name = username,
        password = 'x',
        user_password_max_length = 1,
        max_session_cnt = 5,
        is_callin = 0,
        user_enabled = user_enabled,
        auth_enabled = 1,
        ipmi_msg_enabled = 1,
        is_enabled_by_passwd = 0,
        privilege_0 = enum.IpmiPrivilege.RESERVED:value(),
        privilege_1 = privilege_num,
        snmp_privacy_password = 'x',
        is_locked = is_locked,
        login_rule_ids_num = login_rule_ids_num,
        login_interface_num = login_interface_num,
        is_exclude_user = is_exclude_user,
        is_password_expired = is_password_expired
    }

    self.ipmi_file:add_item(ipmi_user)
    if self.is_save then
        self.ipmi_file:save(true)
    end
end

--- 获取uid, gid
---@param id number
---@param role number
function LinuxUserMgr:get_uid_gid(id, role)
    local uid = config.LINUX_USER_ID_BASE + id
    local gid = role_group_map[role][1]
    return uid, gid
end

function LinuxUserMgr:ensure_system_base_user_exists()
    -- 系统基础用户不存在，就添加进去
    for _, target_group in pairs(role_group_map) do
        local gid = target_group[1]
        local gname = target_group[2]
        self.group_file:create_group(gname, gid)
    end
    self.group_file:create_group(config.APPS_GROUP_NAME, config.APPS_USER_GID)
    for _, app_user in pairs(config.APP_USERS) do
        local gid = app_user.gids[1]
        local groupname = config.APP_GID_NAME_MAP[gid]
        local user = {
            user_name = app_user.name,
            user_id = app_user.uid,
            group_id = gid,
            gecos = groupname,
            home_dir = '/',
            shell = '/sbin/nologin'
        }
        if user.user_name == config.SSHD_USER_NAME then
            user.home_dir = '/var/run/sshd'
            user.gecos = "Privilege-separated SSH"
        end

        self.passwd_file:add_item(user, false)
        for _, ggid in pairs(app_user.gids) do
            local gname = config.APP_GID_NAME_MAP[ggid]
            self.group_file:add_user(app_user.name, ggid, gname)
        end
    end
end

LinuxUserMgr.role_group_map = role_group_map
return LinuxUserMgr
