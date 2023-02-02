#!/bin/bash

log="/var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux/extension.log"
line_number=$(grep -n "exiting daemon" $log | awk 'NR==2{print $1}' | cut -d: -f1)

if [ -n "$line_number" ]; then
    mv /boot/grub/grub.cfg /tmp/grub.cfg
    reboot
fi