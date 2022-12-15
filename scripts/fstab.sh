#!/bin/bash

echo "/dev/sdx2  /missingPartition   xfs   defaults   0   2" >> /etc/fstab
sudo shutdown -r