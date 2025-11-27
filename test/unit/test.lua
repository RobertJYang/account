loadfile(os.getenv('CONFIG_FILE'), 't', { package = package, os = os })()
local lu = require('luaunit')
local mc_utils = require 'mc.utils'
local pwd = mc_utils.realpath('.')

-- 保存初始加载的package
local origin_package = {}
for name, module in pairs(package.loaded) do
    origin_package[name] = module
end

local test_files = {
    "test_account",
    "test_libiam"
}

for _, test_file in pairs(test_files) do
    -- 清空加载的package
    for name, _ in pairs(package.loaded) do
        package.loaded[name] = nil
    end

    -- 恢复初始加载的package
    for name, module in pairs(origin_package) do
        package.loaded[name] = module
    end

    -- 执行测试文件
    package.path = pwd .. "/test/libiam/unit/?.lua;" .. package.path
    require(test_file)

    -- 清除测试套件
    for k, _ in pairs(_G) do
        if type(k) == "string" and lu.LuaUnit.isTestName(k) then
            _G[k] = nil
        end
    end
end

os.exit()