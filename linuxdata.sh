#!/bin/bash

mkdir /data
parted /dev/disk/azure/scsi1/lun0 mklabel gpt
mkfs.ext4 /dev/disk/azure/scsi1/lun0-part1
echo "/dev/disk/azure/scsi1/lun0-part1 /data ext4 defaults,nofail 0 0" >>/etc/fstab
mount -a
