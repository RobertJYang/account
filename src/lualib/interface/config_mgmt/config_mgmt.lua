-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at:
--         http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
-- Description: 定制化和配置导入导出的父类

local class = require 'mc.class'

local account_collection = require 'domain.account_collection'
local account_service = require 'service.account_service'
local global_account_config = require 'domain.global_account_config'
local password_validator_collection = require 'domain.password_validator_collection'

local ConfigMgmt = class()

function ConfigMgmt:ctor()
    -- 作为定制化和配置导入导出的父类，对这两个子类的共用对象实例化
    self.m_account_collection = account_collection.get_instance()
    self.m_account_service = account_service.get_instance()
    self.m_account_config = global_account_config.get_instance()
    self.m_password_validator_collection = password_validator_collection.get_instance()
end

return ConfigMgmt