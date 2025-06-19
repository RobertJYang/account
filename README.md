# account


## 功能简介

- account组件负责openUBMC的所有用户及用户相关服务的管理，除了基本的查询增加删除外，还提供定制与备份等功能，围绕用户与用户服务该组件内主要包含：
    1. 用户：IPMI用户、本地用户、客户定制用户，SNMP团体名与VNC是提供给SNMP接口与远程窗口管理系统的，考虑到两者都有密码，组件内将之当做用户管理
    2. 用户服务：用户本身除了基础的用户名、密码、登录接口外，使用用户时还受历史密码、弱密码、密码长度、密码策略，登录规则等限制，这些功能被统称为用户服务
    3. 其他： openUBMC对外提供收集日志、备份还原、定制化、配置导入导出等功能

功能结构如下：
   1. 账户管理
      1. 本地账户
         1. SNMP鉴权与加密属性
      2. 系统账户
      3. OEM账户
      4. 特殊账户
         1. vnc密码管理
         2. 团体名管理
   2. 账户公共配置
      1. 账户属性策略
      2. 密码策略
      3. 权限配置
      4. 登录规则

### 目录结构
```
├── gen                                         -- 自动生成代码
│   ├── ...
├── manufacture
│   └── default_datas.lua                       -- 装备包中默认配置信息
├── mds
│   ├── ...                                     -- mds文件，定义了错误函数、数据库中表、枚举值等生成模板
├── proto
│   └── datas.yaml                              -- 默认配置信息
├── src
│   ├── lualib
│   │   ├── account_app.lua                     -- 组件初始化处
│   │   ├── common_config.lua                   -- 共用宏定义
│   │   ├── domain                              -- domain层，包含业务处理细节
│   │   │   ├── account_collection.lua          -- 管理用户集合   
│   │   │   ├── account_permanent_backup.lua    -- 备份用户信息
│   │   │   ├── file_synchronization.lua        -- 文件管理
│   │   │   ├── global_account_config.lua       -- 管理用户共有的配置
│   │   │   ├── login_rule                      -- 登录规则
│   │   │   │   ├── login_rule_collection.lua   -- 管理规则集合
│   │   │   │   ├── login_rule_manager.lua      -- 单条规则的类
│   │   │   │   └── ...                         -- 时间、mac地址、ip地址规则
│   │   │   ├── manager_account                 -- 用户管理
│   │   │   │   ├── manager_account.lua         -- 管理用户的父类
│   │   │   │   ├── ...                         -- 几个子类，包括：IPMI用户、本地用户、客户定制用户、SNMP团体名、VNC
│   │   │   ├── privilege.lua                   -- 处理角色权限相关操作的类
│   │   │   └── role.lua                        -- 管理角色权限的类
│   │   ├── error_config.lua                    -- IPMI与密码相关的宏定义
│   │   ├── infrastructure                      -- infrastructure层，包含供其他层调用的底层功能与业务处理
│   │   │   ├── account_backup_db.lua           -- 用户备份功能
│   │   │   ├── account_linux.lua               -- linux文件中用户配置
│   │   │   ├── db_upgrade.lua                  -- 数据库升级适配
│   │   │   ├── file_proxy.lua                  -- 本地用户沙箱内运行
│   │   │   ├── file_transfer.lua               -- 文件传输功能（涉及远程文件调用）
│   │   │   ├── flash_synchronizer.lua          -- 写flash（pam文件写入）
│   │   │   ├── history_password.lua            -- 历史密码功能
│   │   │   ├── host_privilege_limit.lua        -- 管理host(主机侧/OS侧)权限
│   │   │   ├── ipmi_running_record.lua         -- 代理执行IPMI命令，规避性能不足导致IPMI下发异常
│   │   │   ├── kmc_client.lua                  -- KMC加密
│   │   │   ├── ssh_public_key.lua              -- SSH公钥功能
│   │   │   ├── task_manager.lua                -- 任务管理
│   │   │   └── utils.lua                       -- 提供公用的小处理函数
│   │   ├── interface                           -- interface层，业务入口层
│   │   │   ├── config_mgmt                     -- 包含定制化和配置导入导出
│   │   │   │   ├── config_handle.lua           -- 功能入口，管理配置导入导出和定制化操作
│   │   │   │   ├── config_mgmt.lua             -- 定制化和配置导入导出的父类
│   │   │   │   ├── manufacture                 -- 文件夹管理了用户定制与用户配置定制
│   │   │   │   │   └── customization
│   │   │   │   │       ├── ...
│   │   │   │   ├── profile                     -- 配置导入导出，文件夹下管理了用户定制、用户配置定制、登录规则定制等内容
│   │   │   │   │   ├── ...
│   │   │   │   └── security_config
│   │   │   │       └── config_dump.lua         -- 安全配置导出，提供给一键收集使用
│   │   │   ├── dump.lua                        -- 一键收集功能的入口处             
│   │   │   ├── ipmi
│   │   │   │   └── account_service_ipmi.lua    -- IPMI命令功能下发的入口处
│   │   │   ├── mdb                             -- 业务处理入口处，连接service层和domain层
│   │   │   │   ├── account_mdb.lua             -- 用户管理功能的入口处
│   │   │   │   ├── account_service_mdb.lua     -- 用户配置管理的入口处
│   │   │   │   ├── login_rule_mdb.lua          -- 登录规则管理的入口处
│   │   │   │   ├── role_privilege_mdb.lua      -- 用户权限管理的入口处
│   │   │   │   └── snmp_community_mdb.lua      -- SNMP团体名管理的入口处
│   │   │   ├── operation_logger.lua            -- 操作日志代理，管理了组件内操作日志打印
│   │   │   └── snmp
│   │   │       └── account_service_snmp.lua    -- SNMP接口管理组件的入口处
│   │   ├── models
│   │   │   └── role_privilege_map.lua          -- 用户角色与权限的映射
│   │   ├── service                             -- service层，管理调度domain、interface、infrastructure层
│   │   │   ├── account_recover.lua             -- 用户备份还原
│   │   │   ├── account_service.lua             -- 用户相关操作
│   │   │   └── local_authentication.lua        -- 本地用户的鉴权涉及属性与功能
│   │   └── skynet_config.lua                   -- 进程内名称，该组件进程内名为account，隶属于om进程
│   └── service
│       └── main.lua                            -- 组件入口
├── test
│   ├── ...                                     -- 测试文件
```

## 关键特性
### 整体架构设计
- 本组件架构设计总体分为接口、服务、领域、基础设施四个层级
1. 接口层(interface)：作为组件级的对外统一出口，提供接口用于跨模块之间的信息交互。
2. 服务层(service)：完成内部多个领域对象和外部其他服务之间协调性、组合性的交互逻辑，作为各业务模块的出口向组件外部提供调用能力。
3. 领域层(domain)：提供了相关实体类的定义，承载了核心业务逻辑的实现，主要包括管理与备份用户、管理登录规则、管理权限角色等。
4. 基础设施层(infrastructure)：提供供其他层调用的底层功能与公用处理方法的封装，供上层调用。

### 新建与删除用户
- 通过WEB、IPMI、Redfish、SNMP、cli接口可以新建与删除用户，新建用户时可供使用的本地用户id范围为2~17，用户基本属性为用户名、密码、登录接口、权限角色、首次登陆策略。删除用户动作会受到用户服务属性限制
- 相关属性介绍：
    1. 用户名：登录BMC系统的用户名称
    2. 密码：用户登录密码，开启密码复杂度检查后有长度与密码组成等要求，开启弱口令检查后会检查新建密码是否在弱口令字典内，开启历史密码检查后会与过往使用密码作比较
    3. 登录接口：用户可通过已使能的接口登录BMC系统
        -SNMP：使能该接口后，用户可使用符合SNMP协议的终端工具（例如MIB Browser）登录BMC系统。
        -SSH：使能该接口后，用户可使用符合SSH协议的终端工具（例如PuTTY）登录BMC命令行。
        -IPMI：使能该接口后，用户可使用符合IPMI协议的终端工具（例如IPMI Tool）登录BMC命令行。
        -Local：使能该接口后，用户可通过服务器的串口登录BMC命令行。
        -SFTP：使能该接口后，用户可使用符合SFTP协议的终端工具（例如Xftp）登录BMC文件系统。
        -Web：使能该接口后，用户可使用浏览器登录BMC Web界面。
        -Redfish：使能该接口后，用户可使用符合Redfish协议的终端工具登录BMC系统。
    4. 权限角色：分为管理员、操作员、普通用户、自定义用户、无权限用户，不同角色拥有不同的细化操作权限
    5. 首次登陆策略：首次登录时的密码修改策略，分为强制修改密码和提示修改密码
    6. 密码有效期：可选功能，分为密码最大有效期和最短使用期。在最短使用期内不能修改密码，密码使用时长到达最大有效期后需要重置密码
    7. 紧急登录用户：必须为管理员用户，设置某个管理员用户为紧急登录用户后，该用户不受密码有效期、登录规则和登录接口限制的用户，用于紧急情况下登录BMC
    8. 登录失败锁定：鉴权失败到规定次数后用户将被锁定，除非使用解锁命令，否则用户短期内无法再尝试登录

### SSH公钥
- 通过文本或文件格式导入SSH公钥后，SSH登录时可以选择使用公钥认证
### SNMP相关属性
- SNMP接口的使能开启后，涉及以下几个属性：
    - 加密算法：对称加密算法，用来控制SNMP通信时的数据加密方式，和其他几个属性无联系
    - 加密密码：用户在开启接口使能后需要设置的密码
    - 鉴权算法：生成两个Key（认证Key和加密Key，前者由用户密码通过鉴权算法生成，后者由SNMP加密密码通过鉴权算法生成），用来控制SNMP认证

### 首次登录功能
- 首次登录相关全局属性(global_account_config)
  - InitialPasswordNeedModify：首次登录总体开关，关闭后会同步关闭以下其他全局属性；
  关闭后Web页面新建、编辑用户不显示首次登录策略；用户首次登录无需修改密码；
  - InitialPasswordPromptEnable：首次登录人机接口，开启后用户在建议修改密码策略下首次登录Web提示修改密码；
  当总体开关关闭时开启人机接口报错；
  - InitialAccountPrivilegeRestrictEnabled：首次登录机机接口，开启时用户强制修改密码策略下首次登录Redfish、IPMI仅有ConfigSelf权限；
  当总体开关关闭时开启机机接口报错；
- 首次登录相关用户属性
  - FirstLoginPolicy：首次登录策略1.建议修改密码：PromptPasswordReset，2.强制修改密码：ForcePasswordReset；
  - PasswordChangeRequired：是否首次登录 true：首次登录，false：非首次登录；

## 对外接口
### 资源树接口
| 所属业务：Account/Authentication/Session | OBJECT(path) | interface | method/property/signal | type | 备注 |
|---|---|---|---|---|---|
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | PasswordComplexityEnable | property | 密码复杂度检查开关 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | InitialPasswordPromptEnable | property | BMC支持生产定制化关闭首次登录修改密码提示功能 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | InitialAccountPrivilegeRestrictEnabled | property | 机机接口要求强制修改密码 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | HistoryPasswordCount | property | 历史密码数 <br>注：emit-changed为false |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | MaxPasswordLength | property | 最长密码长度 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | MinPasswordLength | property | 最短密码长度 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | MinPasswordValidDays | property | 密码最短有效期(单位：天) |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | MaxPasswordValidDays | property | 密码最长有效期(单位：天) |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | InactiveDaysThreshold | property | 不活跃阈值 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | EmergencyLoginAccountId | property | 紧急逃生用户 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | SNMPv3TrapAccountLimitPolicy | property | 不限制 0      trap版本不为v3<br> 不可删除、可重命名 1      trap版本为v3，且使能关闭<br> 不可删除、不可重命名 2      trap版本为v3，且使能打开 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | SNMPv3TrapAccountId | property | SNMPv3Trap用户 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | WeakPasswordDictionaryEnabled | property | 弱口令字典使能开关 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | OSAdministratorPrivilegeEnabled | property | true 允许业务侧管理员权限操作<br> false 禁止业务侧管理员权限操作 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | HostUserManagementEnabled | property | true 允许带内通道对用户操作访问<br> false 禁止带内通道对用户操作访问 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | UserNamePasswordPrefixCompareEnabled | property | true 开启检查<br> false 关闭检查 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | UserNamePasswordPrefixCompareLength | property | 取用户名称前n个字节与密码做对比 |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | ImportWeakPasswordDictionary | method | 导入弱口令字典<br>请求参数：导入路径 string |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | ExportWeakPasswordDictionary | method | 导出弱口令字典<br>请求参数：导出路径 string |
| Account | /bmc/kepler/AccountService | bmc.kepler.AccountService | GetRequestedPublicKey | method | web接口登录获取公钥；仅web_backend调用<br>请求参数：公钥类型 取值范围：1（web前端加密公钥）uint8 |
| Account | /bmc/kepler/AccountService/Accounts | bmc.kepler.AccountService.ManagerAccounts | New | method | 新建账户；0表示不指定用户id，默认选择一个用户<br>不能指定id为1<br>请求参数：<br> AccountId uint8 ranges(0,17)<br>UserName string lens(1,32)<br> Password bytes lens(1,32) U8[] <br>RoleId int32<br> LoginInterface int32[]<br>FirstLoginPolicy int32|
| Account | /bmc/kepler/AccountService/Accounts | bmc.kepler.AccountService.ManagerAccounts | NewOEMAccount | method | 新建用户，用户名密码id显示传入，需要该用户支持的登录接口、管理权限、首次登录策略、密码是否使用密文等信息<br>请求参数：<br>AccountId U8 ranges(2001,2015)<br>UserName string lens(1,32)<br>PassWord string lens（1，1024）<br>ExtraData(LoginInterface\Role\FirstLoginPolicy\IsPwdEncrypted)信息 a{ss} |
| Account | /bmc/kepler/AccountService/Accounts | bmc.kepler.AccountService.ManagerAccounts | GetIdByUserName | method | 通过用户名获取用户Id<br>请求参数：UserName string lens(1,32) |
| Account | /bmc/kepler/AccountService/Accounts | bmc.kepler.AccountService.ManagerAccounts | GetUidGidByUserName | method | 通过用户名查找用户ID，组ID<br>请求参数：UserName string lens(1,32) |
| Account | /bmc/kepler/AccountService/Accounts | bmc.kepler.AccountService.ManagerAccounts | PasswordChangedSignal | signal | 变更用户加密密码后发送信号 |
| Account | /bmc/kepler/AccountService/Accounts | bmc.kepler.AccountService.ManagerAccounts | SnmpPasswordChangedSignal | signal | 变更用户SNMPV3加密密码后发送信号 |
| Account | /bmc/kepler/AccountService/Accounts | bmc.kepler.AccountService.ManagerAccounts | SetAccountWritable | method | 设置用户是否可变更<br>请求参数：<br>用户id  U8<br>需要设置的属性名（UserName\PassWord\LoginInterface\Role\LoginRule等）当前定制化需求仅需支持UserName\Password  string<br>该属性是否允许修改 bool |
| Account | /bmc/kepler/AccountService/Accounts | bmc.kepler.AccountService.ManagerAccounts | GetAccountWritable | method | 获取用户是否可变更<br> 请求参数：用户id U8 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | AccountExpiration | property | 未使用 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | Enabled | property | 用户使能开关 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | Id | property | 用户id |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | Locked | property | 用户是否锁定 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | UserName | property | 用户名 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | PasswordChangeRequired | property | 判断是否首次登录，与FirstLoginPolice配合使用 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | PasswordExpiration | property | 剩余密码有效天数（单位：天）|
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | Privileges | property | 枚举值，用户拥有的九大权限 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | SSHPublicKeyHash | property | SSH公钥哈希值 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | AccountType | property | 用户类型 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | LoginRuleIds | property | 用户登录规则ID组 Rule1，Rule2 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | LastLoginTime | property | 最后一次登录时间 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | LastLoginIP | property | 最后一次登录IP |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | LastLoginInterface | property | 最后一次登录接口 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | FirstLoginPolicy | property | 首次登陆策略，强制修改密码或建议修改密码 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | LoginInterface | property | IPMI, SNMP |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | Deletable | property | 账户是否可以删除，如果是紧急用户或者trapv3用户，则无法删除 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | Delete | method | 删除账户 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | ChangePwd | method | 修改账户密码<br>请求参数：Password U8[] |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | ChangeSnmpPwd | method | 修改本地用户SNMP密码<br>请求参数：Password U8[] |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | ImportSSHPublicKey | method | 导入SSH公钥<br>请求参数：<br>Type：Content类型 string<br>Content：导入路径或文本 string |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | DeleteSSHPublicKey | method | 删除SSH公钥<br>请求参数：NA |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount | SetLoginInterface | method | 修改用户登录接口，如果IPMI接口由关闭设置为开启，需要重新设置密码<br>请求参数：<br>LoginInterface：修改的登录接口 string[]<br>PassWord：添加IPMI登录接口时需要传入密码，其他情况下传入空字符串 U8[] |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount.SnmpUser | AuthenticationProtocol | property | 鉴权算法 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount.SnmpUser | EncryptionProtocol | property | 加密算法 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount.SnmpUser | SnmpEncryptionPasswordInitialStatus | property | 加密密码初始状态 |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount.SnmpUser | SetAuthenticationProtocol | method | 设置鉴权算法<br>请求参数：<br>SNMPAuthenticationProtocol U8<br>AuthPassword string<br>EncryPassword string |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount.SnmpUser | GetSnmpKeys | method | 获取鉴权Key和加密Key<br>请求参数：NA |
| Account | /bmc/kepler/AccountService/Accounts/:AccountId | bmc.kepler.AccountService.ManagerAccount.SnmpUser | SetEncryptionProtocol | method | 设置加密算法<br>请求参数：SNMPEncryptionProtocol U8 |
| Account | /bmc/kepler/AccountService/RestrictedPrivileges | bmc.kepler.AccountService.RestrictedPrivilege | UserMgmt | property | 用户管理权限 |
| Account | /bmc/kepler/AccountService/RestrictedPrivileges | bmc.kepler.AccountService.RestrictedPrivilege | BasicSetting | property | 基本设置功能权限 |
| Account | /bmc/kepler/AccountService/RestrictedPrivileges | bmc.kepler.AccountService.RestrictedPrivilege | KVMMgmt | property | KVM使用权限 |
| Account | /bmc/kepler/AccountService/RestrictedPrivileges | bmc.kepler.AccountService.RestrictedPrivilege | VMMMgmt | property | VMM使用权限 |
| Account | /bmc/kepler/AccountService/RestrictedPrivileges | bmc.kepler.AccountService.RestrictedPrivilege | SecurityMgmt | property | 安全配置权限 |
| Account | /bmc/kepler/AccountService/RestrictedPrivileges | bmc.kepler.AccountService.RestrictedPrivilege | PowerMgmt | property | 电源控制权限，可控制电源上下电 |
| Account | /bmc/kepler/AccountService/RestrictedPrivileges | bmc.kepler.AccountService.RestrictedPrivilege | DiagnoseMgmt | property | 调试诊断权限 |
| Account | /bmc/kepler/AccountService/RestrictedPrivileges | bmc.kepler.AccountService.RestrictedPrivilege | ReadOnly | property | 只读功能权限，|
| Account | /bmc/kepler/AccountService/RestrictedPrivileges | bmc.kepler.AccountService.RestrictedPrivilege | ConfigureSelf | property | 配置自身权限，既可修改用户自身信息 |
| Account | /bmc/kepler/AccountService/Roles/:Id | bmc.kepler.AccountService.Role | RolePrivilege | property | 角色具有的权限集合，具有该权限则将属性名加入集合，如UserMgmt<br>角色的id(普通用户2、操作员3、管理员4、自定义用户1为5、自定义用户2为6，自定义3为7，自定义4为8，无权限用户为0)|
| Account | /bmc/kepler/AccountService/Roles/:Id | bmc.kepler.AccountService.Role | Name | property | 角色名称（用户角色名的英文） |
| Account | /bmc/kepler/AccountService/Roles/:Id | bmc.kepler.AccountService.Role | SetRolePrivilege | method | 角色的id(普通用户2、操作员3、管理员4、自定义用户1为5、自定义用户2为6，自定义3为7，自定义4为8，无权限用户为0)<br> 修改的权限类型（用户管理0、基本设置功能1、kvm权限2、vmm权限3、安全配置4、电源控制5、调试诊断6、只读功能7、配置自身8）<br> 启用或禁用权限（1启用、0禁用）<br>请求参数：<br>Privilege U8,(0-8,无1)<br>value bool |
| Account | /bmc/kepler/AccountService/Rules/:Id | bmc.kepler.AccountService.Rule | Enabled | property | 规则开关 |
| Account | /bmc/kepler/AccountService/Rules/:Id | bmc.kepler.AccountService.Rule | TimeRule | property | 时间规则 |
| Account | /bmc/kepler/AccountService/Rules/:Id | bmc.kepler.AccountService.Rule | MacRule | property | MAC地址规则 |
| Account | /bmc/kepler/AccountService/Rules/:Id | bmc.kepler.AccountService.Rule | IpRule | property | IP地址规则 |
| Account | /bmc/kepler/Managers/:ManagerId/SnmpService/SnmpCommunity | bmc.kepler.Managers.SnmpService.SnmpCommunity | LongCommunityEnabled | property | 长密码开关 |
| Account | /bmc/kepler/Managers/:ManagerId/SnmpService/SnmpCommunity | bmc.kepler.Managers.SnmpService.SnmpCommunity | RwCommunityEnabled | property | 读写团体名使能 |
| Account | /bmc/kepler/Managers/:ManagerId/SnmpService/SnmpCommunity | bmc.kepler.Managers.SnmpService.SnmpCommunity | SetRwCommunity | method | 设置rw snmp团体名,nil表示不设置，""表示删除<br>请求参数：RwCommunity string |
| Account | /bmc/kepler/Managers/:ManagerId/SnmpService/SnmpCommunity | bmc.kepler.Managers.SnmpService.SnmpCommunity | SetRoCommunity | method | 设置ro snmp团体名,nil表示不设置，""表示删除<br>请求参数：RoCommunity string |
| Account | /bmc/kepler/Managers/:ManagerId/SnmpService/SnmpCommunity | bmc.kepler.Managers.SnmpService.SnmpCommunity | SnmpCommunityChangedSignal | signal | 团体名变化发送信号给周边模块 |
| Account | /bmc/kepler/Managers/:ManagerId/SnmpService/SnmpCommunity | bmc.kepler.Managers.SnmpService.SnmpCommunity | GetSnmpCommunity | method | 获取snmp团体名<br>请求参数：NA |
| Account | /bmc/kepler/Managers/:ManagerId/SnmpService/SnmpCommunity | bmc.kepler.Managers.SnmpService.SnmpCommunity | SetSnmpCommunityLoginRule | method | 设置snmp团体名登录规则<br>请求参数：LoginRuleIds U8 |

### IPMI命令
- 具体参数参考本组件配置文件`ipmi.json`

| 方法  | 描述  |
| :------------: | :------------: |
| SetUserAccess | 设置用户权限 |
| GetUserAccess | 获取用户权限 |
| SetUserName | 设置特定ID的用户名字 |
| GetUserName | 获取特定ID的用户名字 |
| SetUserPassComplexity | 设置密码复杂度 |
| GetUserPassComplexity | 获取密码复杂度 |
| SetUserInterface | 设置用户登录接口 |
| UserIpmiSetUserSNMPV3PrivacyPwd | 设置用户SNMP加密密码 |
| SetSNMPConfiguration | 设置SNMP配置 |
| GetSNMPConfiguration | 获取SNMP配置 |
| SetVncPassword | 设置VNC密码 |
| SetUserPasswordCompareInfo | 设置密码对比长度信息 |
| GetUserPasswordCompareInfo | 获取密码对比长度信息 |
| GetWeakPwdDictionaryEnabled | 获取弱口令检查使能 |
| GetFirstLoginModifyPolicy | 获取首次登陆策略 |
| GetHistoryPwdCheckCount | 获取历史密码检查次数 |
| GetEmergencyLoginAccount | 获取紧急登录用户ID |
| GetInitialPasswordPromptEnable | 获取首次登录人机接口开关 |
| SetWeakPwdDictionaryEnabled | 设置弱口令字典检查使能 |
| SetFirstLoginModifyPolicy | 设置首次登陆策略 |
| SetHistoryPwdCheckCount | 设置历史密码检查次数 |
| SetEmergencyLoginAccount | 设置紧急登录用户ID |
| SetInitialPasswordPromptEnable | 设置首次登录人机接口开关 |
| DisableAccount | 关闭用户使能 |
| EnableAccount | 开启用户使能 |
| SetAccountPassword | 设置用户密码 |

## 配置介绍

### 默认用户信息
- 出厂设置中，环境默认配置2号用户，用户名为Administrator