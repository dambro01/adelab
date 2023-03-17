#!/bin/bash

cat > /etc/systemd/system/ade.service << EOF
[Unit]
Description=ADE Lab
After=network.target

[Service]
TimeoutStartSec=600s
Type=oneshot
ExecStart=/bin/bash /usr/local/bin/lvmoncrypt_post.sh

[Install]
WantedBy=multi-user.target
EOF
