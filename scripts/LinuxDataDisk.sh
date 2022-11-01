#!/bin/bash
mkdir /data
parted -s /dev/disk/azure/scsi1/lun0 mklabel gpt
parted -s /dev/disk/azure/scsi1/lun0 mkpart primary ext4 0% 100%
sleep 5
mkfs.ext4 /dev/disk/azure/scsi1/lun0-part1
sleep 10
UUID="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun0-part1)" 
echo "UUID=$UUID /data ext4 defaults,nofail 0 0" >>/etc/fstab
mount /dev/disk/azure/scsi1/lun0-part1 /data

