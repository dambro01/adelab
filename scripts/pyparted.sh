#!/bin/bash

if dpkg -s python3-parted >/dev/null 2>&1; then
    echo "python3-parted package is installed. Removing it now..." >> /var/tmp/cse
    apt-get remove python3-parted -y >> /var/tmp/cse 2>&1
    if [ $? -eq 0 ]; then
        echo "python3-parted package has been successfully removed." >> /var/tmp/cse
    else
        echo "There was an error removing the package python3-parted." >> /var/tmp/cse
        exit 1
    fi
else
    echo "The package python3-parted is not installed." >> /var/tmp/cse
fi
