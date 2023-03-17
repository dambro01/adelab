#!/bin/bash

log="/var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux/extension.log"
log_file="/var/log/azure/run.log"

now=$(date '+%m%d%y')
echo "$now: Running the script" >> $log_file

if grep "exiting daemon" $log; then
  mkdir /tempdata0
  mkdir /tempdata1

  mkfs.ext4 -F /dev/disk/azure/scsi1/lun0
  sleep 5 
  mkfs.ext4 -F /dev/disk/azure/scsi1/lun1
  sleep 5

  diskuuid0="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun0)"
  diskuuid1="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun1)"

  echo "UUID=$diskuuid0 /tempdata0 ext4 defaults,nofail 0 0" >> /etc/fstab
  echo "UUID=$diskuuid1 /tempdata1 ext4 defaults,nofail 0 0" >> /etc/fstab

  mount -a
else
  echo "$now: 'exiting daemon' not found in $log" >> $log_file
fi
