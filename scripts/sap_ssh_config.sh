#!/bin/bash

# Establish variables
sapInstanceId=$1
sapInstanceIdLower=$(echo $sapInstanceId | tr '[:upper:]' '[:lower:]')
sapInstanceNumber=$2
sapUser=${sapInstanceIdLower}adm
sapPassword=$3
thisNode=$HOSTNAME
otherNode=$4
thisNodeIP=$(ip -4 -o a show eth0 | cut -d ' ' -f 7 | cut -d '/' -f 1)
subId=$5
resourceGroup=$6
ilbIP=$7

# Set up log file
set -v -x -E
logFile="/tmp/$(hostname)_haConfig_$(date +%Y-%m-%d_%H-%M-%S).log"

# Generate SSH Key on primary node
echo "<<< Generating SSH Key on primary node >>>" >> $logFile
expect <<EOF | tee -i -a "$logFile"
set timeout 20
spawn sudo ssh-keygen
expect -exact "Enter file in which to save the key (/root/.ssh/id_rsa): "
send "\r"
expect -exact "Enter passphrase (empty for no passphrase): "
send "\r"
expect -exact "Enter same passphrase again: "
send "\r"
expect eof
EOF

# Copy SSH key to secondary node
echo "<<< Copying SSH Key to secondary node >>>" >> $logFile
expect << EOF | tee -i -a "$logFile"
set timeout 60
spawn sudo ssh-copy-id -o StrictHostKeyChecking=no -f -i /root/.ssh/id_rsa root@$otherNode
expect -exact "root@$otherNode\'s password: "
send "$sapPassword\r"
expect eof
EOF


# Connect to secondary node, generate RSA key, and post back to primary node
echo "<<< Connect to secondary node, generate RSA key, and post back to primary node >>>" >> $logFile
ssh root@$otherNode "expect <<EOF
set timout 60
spawn sudo ssh-keygen
expect -exact \"Enter file in which to save the key (/root/.ssh/id_rsa): \"
send \"\r\"
expect -exact \"Enter passphrase (empty for no passphrase): \"
send \"\r\"
expect -exact \"Enter same passphrase again: \"
send \"\r\"
expect eof
spawn sudo ssh-copy-id -o StrictHostKeyChecking=no -f -i /root/.ssh/id_rsa root@$thisNode
expect -exact \"root@$thisNode\'s password: \"
send \"$sapPassword\r\"
expect eof
EOF" | tee -i -a "$logFile"