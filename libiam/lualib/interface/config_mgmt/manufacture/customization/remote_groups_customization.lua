-- Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
--
-- this file licensed under the Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http: //license.coscl.org.cn/MulanPSL2
--
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
-- PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 定制化操作时RemoteGroups相关项
local account_utils = require 'infrastructure.account_utils'

local RemoteGroupsCustomization = {}
function RemoteGroupsCustomization.set_allowed_login_interfaces(self, ctx, value)
    local login_interfaces_str = account_utils.convert_num_to_interface_str(value, true)
    ctx.operation_log.params = { interfaces = table.concat(login_interfaces_str, ', ') }
    self.m_remote_group_service:set_allowed_login_interfaces(value)
end

function RemoteGroupsCustomization.get_allowed_login_interfaces(self)
    return self.m_remote_group_service:get_allowed_login_interfaces()
end

return RemoteGroupsCustomization