# Copyright (c) 2024 Huawei Technologies Co., Ltd.
# openUBMC is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#          http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.
import subprocess


# 定制化脚本，由manifest构建时调用
class Customization(object):
    def __init__(self, board_name, rootfs_path):
        self.board_name = board_name
        self.rootfs_path = rootfs_path

    def post_image(self):
        pass

    def post_rootfs(self):
        subprocess.run(['/usr/bin/sudo', '/usr/bin/rm', '-rf', f'{self.rootfs_path}/opt/bmc/lualib/libiam'], check=True)
        subprocess.run(['/usr/bin/sudo', '/usr/bin/mv', f'{self.rootfs_path}/opt/bmc/lualib/account',
            f'{self.rootfs_path}/opt/bmc/lualib/libiam'], check=True)

        subprocess.run(['/usr/bin/sudo', '/usr/bin/rm', '-rf', f'{self.rootfs_path}/opt/bmc/luaclib/account_core.so'], check=True)
        subprocess.run(['/usr/bin/sudo', '/usr/bin/rm', '-rf', f'{self.rootfs_path}/opt/bmc/luaclib/iam_core.so'], check=True)
        subprocess.run(['/usr/bin/sudo', '/usr/bin/rm', '-rf', f'{self.rootfs_path}/usr/lib64/libaccount_core_c.so'], check=True)
        subprocess.run(['/usr/bin/sudo', '/usr/bin/rm', '-rf', f'{self.rootfs_path}/lib64/security/pam_bmc_login.so'], check=True)
        subprocess.run(['/usr/bin/sudo', '/usr/bin/rm', '-rf', f'{self.rootfs_path}/usr/lib64/libuip.so'], check=True)

        subprocess.run(['/usr/bin/sudo', '/usr/bin/mv', f'{self.rootfs_path}/opt/bmc/luaclib/account/account_core.so',
            f'{self.rootfs_path}/opt/bmc/luaclib/account_core.so'], check=True)
        subprocess.run(['/usr/bin/sudo', '/usr/bin/mv', f'{self.rootfs_path}/opt/bmc/luaclib/account/iam_core.so',
            f'{self.rootfs_path}/opt/bmc/luaclib/iam_core.so'], check=True)
        subprocess.run(['/usr/bin/sudo', '/usr/bin/mv', f'{self.rootfs_path}/opt/bmc/luaclib/account/libaccount_core_c.so',
            f'{self.rootfs_path}/usr/lib64/libaccount_core_c.so'], check=True)
        subprocess.run(['/usr/bin/sudo', '/usr/bin/mv', f'{self.rootfs_path}/opt/bmc/luaclib/account/pam_bmc_login.so',
            f'{self.rootfs_path}/lib64/security/pam_bmc_login.so'], check=True)
        subprocess.run(['/usr/bin/sudo', '/usr/bin/mv', f'{self.rootfs_path}/opt/bmc/luaclib/account/libuip.so',
            f'{self.rootfs_path}/usr/lib64/libuip.so'], check=True)