#!/bin/bash

mkdir /data
parted /dev/disk/azure/scsi1/lun0 mklabel gpt
sleep 10
parted -a opt /dev/disk/azure/scsi1/lun0 mkpart primary ext4 0% 100%
sleep 10
mkfs -t ext4 /dev/disk/azure/scsi1/lun0-part1
sleep 10
mount /dev/disk/azure/scsi1/lun0-part1 /data
echo "/dev/disk/azure/scsi1/lun0-part1 /data ext4 defaults,nofail 0 2" >> /etc/fstab
