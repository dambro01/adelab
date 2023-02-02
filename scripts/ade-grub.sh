#!/bin/bash

cat > /etc/systemd/system/ade-break.service << EOF
[Unit]
Description=ADE Lab
After=network.target

[Service]
Type=simple
ExecStart=/bin/sh -c 'for i in {1..5}; /bin/bash /root/Grub.sh; sleep 60; done'
Restart=always

[Install]
WantedBy=multi-user.target
EOF
