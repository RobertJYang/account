#! /bin/bash
# Copyright (c) 2024 Huawei Technologies Co., Ltd.
# openUBMC is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
        #  http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.

# check pram, data files are exist, then cp to /dev/shm/
fm_get_tmp_file() {
  srcFile=$1
  tmpFile=$2
  echo srcFile="${srcFile}"
  if [ ! -f "${srcFile}" ]; then
    echo "${srcFile} is not exist!"
    echo "date: $(date), ${srcFile} is not exist!" > /dev/kmsg
    return 1
  fi
  cp -f "${srcFile}" "${tmpFile}"
  return 0
}

touch /var/run/utmp || :
chmod 640 /var/run/utmp
mkdir -p /data/trust
chmod 755 /data/trust
if [ ! -f /data/trust/passwd ]; then
  touch /data/trust/passwd
fi
if [ ! -f /data/trust/shadow ]; then
  touch /data/trust/shadow
fi
if [ ! -f /data/trust/group ]; then
  touch /data/trust/group
fi
if [ ! -f /data/trust/ipmi ]; then
  touch /data/trust/ipmi
fi
chmod 644 /data/trust/passwd
chmod 600 /data/trust/group
chmod 600 /data/trust/shadow
chmod 644 /data/trust/ipmi

# update for file end not new line()
function file_ends_with_newline() {
    [[ $(tail -c1 "$1" | wc -l) -gt 0 ]]
}
if ! file_ends_with_newline /data/trust/passwd
then
    echo "" >> /data/trust/passwd
fi
if ! file_ends_with_newline /data/trust/group
then
    echo "" >> /data/trust/group
fi
if ! file_ends_with_newline /data/trust/shadow
then
    echo "" >> /data/trust/shadow
fi
if ! file_ends_with_newline /data/trust/ipmi
then
    echo "" >> /data/trust/ipmi
fi

# set /dev/shm/ file to pram, data files, then clean /dev/shm/ file
fm_set_tmp_file() {
  dataFile=$1
  tmpFile=$2
  cat "${tmpFile}" >"${dataFile}"
  rm "${tmpFile}"
}

linuxuser_add_to_group() {
  dataFile=/etc/group
  tmpFile=/dev/shm/User_group
  fm_get_tmp_file $dataFile $tmpFile
  if [ $? -ne 0 ]; then
    return
  fi

  # admin operator user no_access apps root sshd redfish_user kvm_user apache snmpd_user ipmi_user discovery_user comm_user secbox
  for i in root,0 sshd,74 operator,200 user,201 no_access,202 admin,204 apache,98 apps,103 snmpd_user,95 ipmi_user,96 kvm_user,97 discovery_user,100 comm_user,101 redfish_user,102 secbox,104; do
    IFS=","
    set -- $i
    name=$1
    gid=$2
    gidCheck=$(awk -F: -v U="$gid" '{if (NF > 0 && $3==U) {print("yes");exit;}}' "${tmpFile}")
    nameCheck=$(awk -F: -v N="$name" '{if (NF > 0 && $1==N) {print("yes");exit;}}' "${tmpFile}")
    if [ -z $gidCheck ] && [ -z $nameCheck ]; then
      echo "date: $(date), add group ${name}!"
      echo "date: $(date), add group ${name}!" > /dev/kmsg
      if [ "${name}" = "sshd" ]; then
        echo "sshd:x:74:" >>"${tmpFile}"
      else
        echo "${name}:x:${gid}:${name}" >>"${tmpFile}"
      fi
    else
      echo "date: $(date), ${name} or ${gid} is exist!"
    fi
  done

  awkTmpFile=/dev/shm/tmp_group
  # check redfish_user,kvm_user in (operator user no_access apps)
  for gname in operator user no_access apps; do
    awk -F: -v N="$gname" '{if(($1==N) && NF>3 && !match($4, "redfish_user")){print $0",redfish_user";}else{print($0)}}' "${tmpFile}" >$awkTmpFile && mv $awkTmpFile "${tmpFile}"
    awk -F: -v N="$gname" '{if(($1==N) && NF>3 && !match($4, "kvm_user")){print $0",kvm_user";}else{print($0)}}' "${tmpFile}" >$awkTmpFile && mv $awkTmpFile "${tmpFile}"
  done
  # check apache snmpd_user ipmi_user discovery_user comm_user secbox in (apps)
  for uname in apache snmpd_user ipmi_user discovery_user comm_user secbox; do
    awk -F: -v N="$uname" '{if(($1=="apps") && NF>3 && !match($4, N)){print $0","N;}else{print($0)}}' "${tmpFile}" >$awkTmpFile && mv $awkTmpFile "${tmpFile}"
  done

  fm_set_tmp_file $dataFile $tmpFile
}

linux_add_user_for_process() {
  dataFile=/etc/passwd
  tmpFile=/dev/shm/User_passwd
  fm_get_tmp_file $dataFile $tmpFile
  if [ $? -ne 0 ]; then
    return
  fi

  # add user,uid list
  changed=0
  for i in root,0 apache,98 snmpd_user,95 ipmi_user,96 kvm_user,97 discovery_user,100 comm_user,101 sshd,74 redfish_user,102 secbox,104; do
    IFS=","
    set -- $i
    name=$1
    uid=$2
    uidCheck=$(awk -F: -v U="$uid" '{if (NF > 0 && $3==U) {print("yes");exit;}}' "${tmpFile}")
    nameCheck=$(awk -F: -v N="$name" '{if (NF > 0 && $1==N) {print("yes");exit;}}' "${tmpFile}")
    if [ -z $uidCheck ] && [ -z $nameCheck ]; then
      changed=1
      echo "date: $(date), add user ${name}!"
      echo "date: $(date), add user ${name}!" > /dev/kmsg
      if [ "${name}" = "sshd" ]; then
        echo "sshd:x:74:74:Privilege-separated SSH:/var/run/sshd:/sbin/nologin" >>"${tmpFile}"
      else
        echo "${name}:x:${uid}:${uid}:${name}:/:/sbin/nologin" >>"${tmpFile}"
      fi
    else
      echo "date: $(date), ${name} or ${uid} is exist!"
    fi
  done

  if [ $changed -eq 0 ]; then
    echo "date: $(date), all users have been added"
  fi
  fm_set_tmp_file $dataFile $tmpFile

  # if no user added, skip add group
  linuxuser_add_to_group
}

linux_check_soft_link() {
  shadow_file="/etc/shadow"
  passwd_file="/etc/passwd"
  group_file="/etc/group"

  if [ ! -f "${shadow_file}" ]; then
    echo "date: $(date), ${shadow_file} is not exist!" > /dev/kmsg
  fi
  if [ ! -f "${passwd_file}" ]; then
    echo "date: $(date), ${passwd_file} is not exist!" > /dev/kmsg
  fi
  if [ ! -f "${group_file}" ]; then
    echo "date: $(date), ${group_file} is not exist!" > /dev/kmsg
  fi
}

linux_check_soft_link
linux_add_user_for_process
chown secbox:root /data/trust/group
chown secbox:root /data/trust/passwd
chown secbox:root /data/trust/shadow
chown secbox:root /data/trust/ipmi

chmod 600 /data/trust/group
chmod 644 /data/trust/ipmi
chmod 644 /data/trust/passwd
chmod 600 /data/trust/shadow