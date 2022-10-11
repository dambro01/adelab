#!/bin/bash

mkdir /data
parted /dev/disk/azure/scsi1/lun0 --script mklabel gpt mkpart xfspart xfs 0% 100%
echo "y" | mkfs.ext4 /dev/disk/azure/scsi1/lun1-part1
partprobe /dev/disk/azure/scsi1/lun0-part1
UUID="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun0-part1)"
echo "UUID=$UUID /data ext4 defaults,nofail 0 0" >>/etc/fstab
mount -a