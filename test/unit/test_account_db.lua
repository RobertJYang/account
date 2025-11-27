-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local sqlite3 = require 'lsqlite3'

function TestAccount:test_account_db()
    local v = self.db:select(self.db.ManagerAccountDB):where(self.db.ManagerAccountDB.Id:eq(2)):first()
    lu.assertEquals(self.db.ManagerAccountDB:get_count(), 7)
    lu.assertEquals(v.UserName, 'Administrator')
    lu.assertEquals(self.db.SNMPUserInfo:get_count(), 1)
    lu.assertEquals(self.db.Role:get_count(), 8)
end

function TestAccount:test_account_db_inner_data()
    local db = sqlite3.open(self.test_data_dir .. "/account.test.db")
    local res = {}
    db:exec([[select * from t_manager_account]], function(ud, names, columns)
        local row = {}
        for i, name in ipairs(names) do
            row[name] = columns[i]
        end
        ud[#ud + 1] = row
        return 0
    end, res)
    lu.assertEquals(res[1].UserName, 'Administrator')
end