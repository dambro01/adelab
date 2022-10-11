#!/bin/bash

mkdir /data
parted -s /dev/disk/azure/scsi1/lun0 mklabel gpt
parted -s /dev/disk/azure/scsi1/lun0 mkpart primary ext4 0% 100%
mkfs.ext4 /dev/disk/azure/scsi1/lun0-part1 > /var/log/adelab.out 2>&1
if [ echo $? -eq 0 ]; then 
  echo "successful"" >> /var/log/adelab.out
  echo "/dev/disk/azure/scsi1/lun0-part1 /data ext4 defaults,nofail 0 0" >>/etc/fstab
  exit
else 
  echo "failed"" >> /var/log/adelab.out
fi
mount /dev/disk/azure/scsi1/lun0-part1 /data
