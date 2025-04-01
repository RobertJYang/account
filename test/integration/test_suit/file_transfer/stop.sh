#!/bin/bash
# Copyright (c) 2024 Huawei Technologies Co., Ltd.
# openUBMC is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
        #  http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.


ps aux|grep "temp/opt/bmc/apps/file_transfer/file_transfer"|grep `whoami`|grep -v grep|awk '{print($2)}'|xargs -r kill
ps aux|grep "/test/integration/test_suit/file_transfer/https_server.py"|grep `whoami`|grep -v grep|awk '{print($2)}'|xargs -r kill

exit 0
