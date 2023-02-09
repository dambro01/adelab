#!/bin/bash

log="/var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux/extension.log"
log_file="/var/log/azure/run.log"

now=$(date '+%m%d%y')
echo "$now: Running the script" >> $log_file

if grep "exiting daemon" $log; then
  echo "$now: 'exiting daemon' found in $log, moving /boot/grub/grub.cfg to /tmp/grub.cfg" >> $log_file
  mv /boot/grub/grub.cfg /tmp/grub.cfg
  echo "$now: 'exiting daemon' found in $log" >> $log_file
  reboot
else
  echo "$now: 'exiting daemon' not found in $log" >> $log_file
fi
