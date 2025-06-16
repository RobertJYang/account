-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.

-- 此文件MOCK utils.core
local utils_core = {}

package.path = string.gsub(package.path,"test/integration/mock/libsoc_adapter/..lua;","")
utils_core = require 'utils.core'

function utils_core.get_uid_gid_by_name(name)
    if name == "Administrator" then
        return 502, 204
    else
        error("Not found")
    end
end

package.path = "test/integration/mock/libsoc_adapter/?.lua;" .. package.path
return utils_core
