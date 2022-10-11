#!/bin/bash

mkdir /data
/usr/bin/printf "o\nn\np\n1\n\n\nt\n83\nw\n" |fdisk /dev/disk/azure/scsi1/lun0
/usr/bin/echo "y" | /usr/sbin/mkfs.xfs -f /dev/disk/azure/scsi1/lun0-part1
/usr/sbin/partprobe /dev/disk/azure/scsi1/lun0-part1
UUID="$(/usr/sbin/blkid -s UUID -o value /dev/disk/azure/scsi1/lun0-part1)"
/usr/bin/echo "UUID=$UUID /data xfs defaults,nofail 0 0" >>/etc/fstab
mount -a
