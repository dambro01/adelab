#!/bin/bash

cat > /etc/systemd/system/ade-break.service << EOF
[Unit]
Description=ADE Lab
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /root/Grub.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF
