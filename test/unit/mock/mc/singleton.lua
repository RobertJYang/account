-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
return function(super)
    local SingletonClass = {}
    SingletonClass.__index = SingletonClass
    setmetatable(SingletonClass, super)

    function SingletonClass.new(...)
        if SingletonClass._instance == nil then
            SingletonClass._instance = super.new(...)
        end
        return SingletonClass._instance
    end

    function SingletonClass.get_instance(...)
        return SingletonClass.new(...)
    end

    function SingletonClass.destroy()
        SingletonClass._instance = nil
    end

    return SingletonClass
end