#!/bin/bash

log="/var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux/extension.log"
log_file="/var/log/azure/run.log"

now=$(date '+%m%d%y')
echo "$now: Running the script" >> $log_file

if grep "exiting daemon" $log; then
  umount -lf /tempdata0
  umount -lf /tempdata1

  uuiddata="$(grep tempdata0 /etc/fstab | awk -F/ '{print $4}')"
  uuidapp="$(grep tempdata1 /etc/fstab | awk -F/ '{print $4}')"

  sed '/tempdata/d' /etc/fstab > /etc/fstab.bk
  mv /etc/fstab.bk /etc/fstab

  echo "y" | pvcreate /dev/mapper/$uuiddata
  echo "y" | pvcreate /dev/mapper/$uuidapp

  vgcreate vgdata /dev/mapper/$uuiddata
  vgcreate vgapp /dev/mapper/$uuidapp

  lvcreate -L 3G -n lvdata vgdata
  lvcreate -L 3G -n lvapp vgapp

  echo "yes" | mkfs.ext4 /dev/vgdata/lvdata
  echo "yes" | mkfs.ext4 /dev/vgapp/lvapp

  mkdir /data
  mkdir /app

  echo "/dev/mapper/vgdata-lvdata /data ext4 defaults,nofail 0 0" >> /etc/fstab
  echo "/dev/mapper/vgapp-lvapp /app ext4 defaults,nofail 0 0" >> /etc/fstab

  mount -a
else
  echo "$now: 'exiting daemon' not found in $log" >> $log_file
fi
