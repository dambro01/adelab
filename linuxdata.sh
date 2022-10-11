#!/bin/bash

mkdir /data
parted /dev/disk/azure/scsi1/lun0 --script mklabel gpt mkpart xfspart xfs 0% 100%
/usr/bin/echo "y" | /usr/sbin/mkfs.xfs -f /dev/disk/azure/scsi1/lun0-part1
UUID="$(/usr/sbin/blkid -s UUID -o value /dev/disk/azure/scsi1/lun0-part1)"
echo "UUID=$UUID /data xfs defaults,nofail 0 0" >>/etc/fstab
mount -a
