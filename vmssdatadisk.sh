#!/bin/bash

mkdir /data
parted /dev/disk/azure/scsi1/lun0 mklabel gpt
parted -a opt /dev/disk/azure/scsi1/lun0 mkpart primary ext4 0% 100%
mkfs -t ext4 /dev/disk/azure/scsi1/lun0-part1
mount /dev/disk/azure/scsi1/lun0-part1 /data
echo "/dev/disk/azure/scsi1/lun0-part1 /data ext4 defaults,nofail 0 2" >> /etc/fstab
