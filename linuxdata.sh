#!/bin/bash

mkdir /data
parted -a opt /dev/disk/azure/scsi1/lun0 mkpart primary ext4 0% 100%
mkfs.ext4 /dev/disk/azure/scsi1/lun0-part1
echo "/dev/disk/azure/scsi1/lun0-part1 /data ext4 defaults,nofail 0 0" >>/etc/fstab
mount -a
