#!/bin/bash
mkdir /data
parted /dev/disk/azure/scsi1/lun0 --script mklabel gpt mkpart xfspart xfs 0% 100%
mkfs.xfs -f /dev/disk/azure/scsi1/lun0-part1
sleep 5
mkfs.xfs -f /dev/disk/azure/scsi1/lun0-part1
partprobe /dev/disk/azure/scsi1/lun0-part1
sleep 10
UUID="$(blkid -s UUID -o value /dev/disk/azure/scsi1/lun0-part1)" 
echo "UUID=$UUID /data xfs defaults,nofail 0 0" >>/etc/fstab
mount -a

