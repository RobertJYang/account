-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--          http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local Databases = require 'database'
local Col = require 'database.column'

local db_selector = {}

local AccountDBDatabase = {}
AccountDBDatabase.__index = AccountDBDatabase

function AccountDBDatabase.new(path, datas, type)
    return db_selector[type] and db_selector[type](path, datas) or nil
end

return AccountDBDatabase.new
