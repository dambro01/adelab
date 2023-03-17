#!/bin/bash

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
