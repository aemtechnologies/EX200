#!/bin/bash

# ============================================================
# Exam VM Configuration Script
# servera and serverb
# ============================================================

set -u

echo "Setting up servera VM for exam..."
sleep 2

# ------------------------------------------------------------
# Q3 - Change Apache Listen port from 80 to 82
# ------------------------------------------------------------
ssh root@servera "sed -i 's/Listen 80/Listen 82/g' /etc/httpd/conf/httpd.conf"

# ------------------------------------------------------------
# Q6 - Remove chrony server entry
# ------------------------------------------------------------
ssh root@servera "sed -i '/server 172\.25\.254\.254 iburst/d' /etc/chrony.conf"
ssh root@servera "date -s \"\$(date)\""

# ------------------------------------------------------------
# Q9 - Remove autofs
# ------------------------------------------------------------
ssh root@servera "yum remove autofs -y"

# ------------------------------------------------------------
# Q10 - Remove bzip2
# ------------------------------------------------------------
ssh root@servera "yum remove bzip2 -y"

# ------------------------------------------------------------
# Q13 - Create redhat user and add to dba group
# ------------------------------------------------------------
ssh root@servera "useradd geo && passwd --stdin redhat >/dev/null 2>&1 && groupadd dba 2>/dev/null || true; usermod -aG dba redhat"

# ------------------------------------------------------------
# Q2 - Remove custom YUM repository files
# ------------------------------------------------------------
ssh root@servera "rm -f /etc/yum.repos.d/*"

# ------------------------------------------------------------
# Q1 - Set hostname and configure ens3 for DHCP
# ------------------------------------------------------------
ssh root@servera "hostnamectl set-hostname clean.example.com"
ssh root@servera "nmcli connection modify 'cloud-init ens3' connection.id ens3 && nmcli connection modify ens3 ipv4.method auto ipv4.addresses '' ipv4.gateway '' ipv4.dns '' ipv4.dns-search '' && nmcli connection down ens3 && nmcli connection up ens3"

sleep 2

echo "Setting up serverb VM for exam..."
sleep 2

# ------------------------------------------------------------
# Q1 - Set GRUB timeout to 10 seconds
# ------------------------------------------------------------
ssh root@serverb "sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub && grub2-mkconfig -o /boot/grub2/grub.cfg"

# ------------------------------------------------------------
# Q2 - Remove custom YUM repository files
# ------------------------------------------------------------
ssh root@serverb "rm -f /etc/yum.repos.d/*"

# ------------------------------------------------------------
# Q24 - Disable tuned and turn off tuned power saving
# ------------------------------------------------------------
ssh root@serverb "systemctl disable tuned"
ssh root@serverb "tuned-adm off"

# ------------------------------------------------------------
# Q21 - Delete extra disks sdc and sdd
# ------------------------------------------------------------
ssh root@serverb "echo 1 > /sys/block/sdc/device/delete; echo 1 > /sys/block/sdd/device/delete"

# ------------------------------------------------------------
# Q22 - Create partition, LVM, filesystem and mount
# ------------------------------------------------------------
ssh root@serverb "parted -s /dev/sdb mklabel gpt"
ssh root@serverb "parted -s /dev/sdb mkpart primary 1MiB 1024MiB"
ssh root@serverb "parted -s /dev/sdb set 1 lvm on"
ssh root@serverb "partprobe /dev/sdb"
ssh root@serverb "pvcreate /dev/sdb1"
ssh root@serverb "vgcreate vg1 /dev/sdb1"
ssh root@serverb "lvcreate -n lv1 -L 300M vg1"
ssh root@serverb "mkfs.xfs /dev/vg1/lv1"
ssh root@serverb "mkdir -p /images"
ssh root@serverb "echo '/dev/vg1/lv1 /images xfs defaults 0 0' >> /etc/fstab"
ssh root@serverb "systemctl daemon-reload; mount -a"

echo "Server configuration completed."
