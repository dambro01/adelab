#!/bin/bash

logfile=/var/log/logfile.log

while true; do
    output=$(dmsetup ls --target crypt)
    if [[ "$output" == *"osencrypt"* ]]; then
        echo "Found 'osencrypt' in output: $output"
        echo "$(date): $output" >> $logfile
        # do something here, like send an alert or execute another command
        exit 0
    fi
    sleep 1 # wait for 1 second before checking again
done
