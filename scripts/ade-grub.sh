#!/bin/bash

cat > /etc/systemd/system/ade-grub.service << EOF
[Unit]
Description=ADE grub script

[Service]
ExecStart=/bin/bash /root/Grub.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
