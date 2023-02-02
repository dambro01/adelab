#!/bin/bash
sleep 60
log="/var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux/extension.log"

if grep -q "exiting daemon" $log; then
  mv /boot/grub/grub.cfg /tmp/grub.cfg
  reboot
fi
