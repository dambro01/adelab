#!/bin/bash

log="/var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux/extension.log"

if grep "exiting daemon" $log; then
  mv /boot/grub/grub.cfg /tmp/grub.cfg
  systemctl disable /etc/systemd/system/ade-break.service
  reboot
fi
