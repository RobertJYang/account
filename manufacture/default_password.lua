-- Copyright (c) 2024 Huawei Technologies Co., Ltd.
-- openUBMC is licensed under Mulan PSL v2.
-- You can use this software according to the terms and conditions of the Mulan PSL v2.
-- You may obtain a copy of Mulan PSL v2 at: http://license.coscl.org.cn/MulanPSL2
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
-- EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
-- MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
-- See the Mulan PSL v2 for more details.
local DEFAULT_PWD = {
    Admin = {
        Password = [=[$6$AhtdE42u9JhRdPw1$7e3wQX6sfjwTEJr8UZjmAM3EDJMcM0AuSrK2aN7U]=] ..
            [=[km0II0Mjm2wR8EAenfBv3SaJ/y4wCu5fqSYCqb4BJfrRd0]=],
        IpmiPassword = [=[0000000200000000000000060000000500000007c3c90f687c9010341e1ab8ff309cfaad388113c]=] ..
            [=[66f28f8f6ff48e203bfa7c31f010000010000000000000010126b5c4bb597331e5100ae9da8814a84]=],
    },
    RoCommunity = {
        IpmiPassword = [=[0000000200000000000000060000000500000007c3c90f687c901034dae1df20fc26413d5b0a09]=] ..
            [=[53c98d8f63c320bb9a9655eee7010000010000000000000010d2cd60c6dc0e254c2ffd6c138f6e5d19]=],
    },
    RwCommunity = {
        IpmiPassword = [=[0000000200000000000000060000000500000007c3c90f687c90103440282a7633d3fcdc11bc54cb5c3f]=] ..
            [=[3e33431e02241ff6f52601000001000000000000001094f0e7e79b93e98993b578df4482ed0e]=],
    },
    SnmpUserInfo = {
        AuthenticationKey = [=[7a2f5b86f20233ec7b7bef49643fbf34d86d0cbf6f1f8f5c52d4f30d4536938b]=],
        EncryptionKey = [=[7a2f5b86f20233ec7b7bef49643fbf34d86d0cbf6f1f8f5c52d4f30d4536938b]=],
        SNMPPassword = [=[$6$hqlSg3LmkBvBNpNW$eC4HKBS.8KzMPxFx/gdxhOnnrRUN8n7DDrEX92]=] ..
            [=[GsMOWfuDCJNuxzVIjkdWwEidlqPhE.dMUmD.wcgSayjC8GF/]=]
    }
}

return DEFAULT_PWD
