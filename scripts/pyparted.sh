#!/bin/bash

if apt remove python3-parted -y; then
    echo "The package python3-parted was successfully removed."
else
    echo "There was an error removing the package python3-parted."
    exit 1
fi
