#!/bin/bash

# Increase the reboot counter
COUNTER=$(cat /var/reboot_counter)
COUNTER=$((COUNTER+1))
echo $COUNTER > /var/reboot_counter

# Run the script after the third reboot
if [ $COUNTER -eq 1 ]; then
  sleep 120
  /usr/local/bin/lvmoncrypt_post.sh
fi

exit 0
