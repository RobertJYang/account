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

set -e

FILE_DIR=`dirname $0`
PROJECT_DIR=`realpath "${FILE_DIR}/../../../.."`

echo "${PROJECT_DIR}"

export LD_LIBRARY_PATH=${PROJECT_DIR}/temp/usr/lib64:${LD_LIBRARY_PATH}
export $(cat $PROJECT_DIR/test/.dbus)
LOG=debug $PROJECT_DIR/temp/opt/bmc/apps/file_transfer/file_transfer &
python3 $PROJECT_DIR/test/integration/test_suit/file_transfer/https_server.py &
exit 0
