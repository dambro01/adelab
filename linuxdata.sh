#!/bin/bash

mkdir /data
parted -a opt /dev/disk/azure/scsi1/lun0 mkpart primary ext4 0% 100%
mkfs -t ext4 /dev/disk/azure/scsi1/lun0-part1
UUID="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun0-part1)" 
echo "UUID=$UUID /data ext4 defaults,nofail 0 0" >>/etc/fstab
mount -a
