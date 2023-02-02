#!/bin/bash

cat > /etc/systemd/system/ade-grub.service << EOF
[Unit]
Description=ADE Lab
After=network.target

[Service]
Type=simple
ExecStart=/bin/sh -c 'for i in {1..5}; do cat /var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux/extension.log; sleep 60; done'
Restart=always

[Install]
WantedBy=multi-user.target
EOF
