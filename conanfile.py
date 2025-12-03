# Copyright (c) 2024 Huawei Technologies Co., Ltd.
# openUBMC is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#         http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.
from conanbase import ConanBase, copy, os

required_conan_version = ">=1.60.0"


class AccountConan(ConanBase):
    def package(self):
        super().package()
        copy(self, "pam_tally_ext.h", src=os.path.join(self.source_folder, "libiam/lualib-src"),
                dst=os.path.join(self.package_folder, "include"), keep_path=False)
        copy(self, "comm_utils.h", src=os.path.join(self.source_folder, "libiam/lualib-src"),
                dst=os.path.join(self.package_folder, "include"), keep_path=False)
