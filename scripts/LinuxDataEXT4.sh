#!/bin/bash

mkdir /data
parted /dev/disk/azure/scsi1/lun0 mklabel gpt
sleep 5
parted -a opt /dev/disk/azure/scsi1/lun0 mkpart primary ext4 0% 100%
mkfs.ext4 /dev/disk/azure/scsi1/lun0-part1
partprobe /dev/disk/azure/scsi1/lun0-part1
sleep 15
UUID="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun0-part1)"
echo "UUID=$UUID /data ext4 defaults,nofail 0 0" >>/etc/fstab
mount -a
