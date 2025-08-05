-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local lu = require 'luaunit'
local client = require 'account.client'
local ipmi_channel_mappings = require 'domain.ipmi_channel_mappings'

local ch_obj_ex = {
    External = {
        value = function ()
            return 8
        end
    },
    Internal = {
        value = function ()
            return 2
        end
    }
}

local ch_obj_ex2 = {
    External = {
        value = function ()
            return 10
        end
    },
    Internal = {
        value = function ()
            return 1
        end
    }
}

local path = 'bmc.kepler.test'
local path1 = 'bmc.kepler.test1'

function TestAccount:test_ipmi_channel_mappings()
    client.GetChannelNumberMappingObjects = function ()
        return {
            path1 = ch_obj_ex2
        }
    end

    local ch_obj = ipmi_channel_mappings.new()
    ch_obj:on_channel_number_mappings_interfaces_added(nil, path, ch_obj_ex)
    lu.assertNotIsNil(next(ch_obj.ch_num_maps))
    lu.assertEquals(ch_obj.ch_num_maps[8], 2)

    local ch_num = ch_obj:channel_number_translation(8)
    lu.assertEquals(ch_num, 2)

    ch_num = ch_obj:channel_number_translation(2)
    lu.assertIsNil(ch_num)

    ch_obj_ex.External = {
        value = function ()
            return 7
        end
    }


    ch_obj:on_channel_number_mappings_properties_changed(ch_obj_ex, path)
    lu.assertEquals(ch_obj.ch_num_maps[7], 2)

    ch_obj:on_channel_number_mappings_interfaces_removed(nil, path)
    lu.assertIsNil(ch_obj.ch_num_maps[7])
end
