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

# Get IP of secondary node
otherNodeIP=$(ssh root@$otherNode "ip -4 -o a show eth0 | cut -d ' ' -f 7 | cut -d '/' -f 1")

# Register with SUSE on each node
echo "<<< Register primary system with SUSE >>>" >> $logFile
sudo SUSEConnect -p sle-module-public-cloud/15.4/x86_64 | tee -i -a "$logFile"
echo "<<< Register secondary system with SUSE >>>" >> $logFile
ssh root@$otherNode "sudo SUSEConnect -p sle-module-public-cloud/15.4/x86_64" | tee -i -a "$logFile"

# Perform systemd change on each node and restart the daemon
echo "<<< Perform changes to systemd and restart the daemon >>>" >> $logFile
sed -i '/DefaultTasksMax/c DefaultTasksMax=4096' /etc/systemd/system.conf
ssh root@$otherNode "sed -i '/DefaultTasksMax/c DefaultTasksMax=4096' /etc/systemd/system.conf"
sleep 5
sudo systemctl daemon-reload | tee -i -a "$logFile"
sleep 5
ssh root@$otherNode "sudo systemctl daemon-reload" | tee -i -a "$logFile"
sleep 5

# Perform sysctl change on each node
echo "<<< Perform sysctl change on each node >>>" >> $logFile
sudo printf '%s\n%s\n\n%s\n' 'vm.dirty_bytes = 629145600' 'vm.dirty_background_bytes = 314572800' 'vm.swappiness = 10' >> /etc/sysctl.conf
ssh root@$otherNode "sudo printf '%s\n%s\n\n%s\n' 'vm.dirty_bytes = 629145600' 'vm.dirty_background_bytes = 314572800' 'vm.swappiness = 10' >> /etc/sysctl.conf"

# Perform eth0 change on each node
echo "<<< Perform eth0 change on each node >>>" >> $logFile
sed -i 's/yes/no/' /etc/sysconfig/network/ifcfg-eth0
ssh root@$otherNode "sed -i 's/yes/no/' /etc/sysconfig/network/ifcfg-eth0"

# Add both hosts to the /etc/hosts file on each node
echo "<<< Add both hosts to the /etc/hosts file on each node >>>" >> $logFile
sudo printf '%s%s%s\n%s%s%s\n' $thisNodeIP ' ' $thisNode $otherNodeIP ' ' $otherNode >> /etc/hosts
ssh root@$otherNode "sudo printf '%s%s%s\n%s%s%s\n' $thisNodeIP ' ' $thisNode $otherNodeIP ' ' $otherNode >> /etc/hosts"

echo "<<< Sleep 15 seconds >>>" >> $logFile
sleep 15

# Initiate the Pacemaker cluster on primary node
echo "<<< Initiate the pacemaker cluster on primary node >>>" >> $logFile
expect << EOF | tee -i -a "$logFile"
set timeout 90
spawn sudo crm cluster init
expect -exact "Continue (y/n)? "
send "y\r"
expect -exact "Address for ring0 \[$thisNodeIP\]"
send "$thisNodeIP\r"
expect -exact "Port for ring0 \[5405\]"
send "\r"
expect -exact "Do you wish to use SBD (y/n)? "
send "n\r"
expect -exact "Do you wish to configure a virtual IP address (y/n)? "
send "n\r"
expect -exact "Do you want to configure QDevice (y/n)? "
send "n\r"
expect -exact "INFO: Done (log saved to /var/log/crmsh/crmsh.log)"
expect eof
EOF

# Sleep for 60 seconds
echo "<<< Sleep for 60 seconds >>>" >> $logFile
sleep 60

# Join the Pacemaker cluster on secondary node
echo "<<< Perform cluster join from secondary node >>>" >> $logFile
ssh root@$otherNode "expect << EOF
set timeout 90
spawn sudo crm cluster join
expect -exact \"IP address or hostname of existing node (e.g.: 192.168.1.1) \[\]\"
send \"$thisNodeIP\r\"
expect -exact \"Continue (y/n)? \"
send \"y\r\"
expect -exact \"Address for ring0 \[$otherNodeIP\]\"
send \"$otherNodeIP\r\"
expect -exact \"INFO: Done (log saved to /var/log/crmsh/crmsh.log)\"
expect eof
EOF" | tee -i -a "$logFile"

echo "<<< Sleep 15 seconds >>>" >> $logFile
sleep 15

# Change hacluster password from default on each node
echo "<<< Change hacluster password on each node >>>" >> $logFile
echo hacluster:"$sapPassword" | chpasswd
ssh root@$otherNode "echo hacluster:\"$sapPassword\" | chpasswd"

# Change corosync settings on each node
echo "<<< Change corosync settings on each node >>>" >> $logFile
echo "<<< Modify corosync on primary >>>" >> $logFile
sudo sed -i 's/token_retransmits_before_loss_const: 10/&\n        consensus: 36000/' /etc/corosync/corosync.conf
sudo service corosync restart | tee -i -a "$logFile"
echo "<<< Sleep 15 seconds >>>" >> $logFile
sleep 15
echo "<<< Modify corosync on secondary >>>" >> $logFile
ssh root@$otherNode "sed -i 's/token_retransmits_before_loss_const:\ 10/&\n\ \ \ \ \ \ \ \ consensus:\ 36000/' /etc/corosync/corosync.conf"
ssh root@$otherNode "sudo service corosync restart" | tee -i -a "$logFile"
echo "<<< Sleep 15 seconds >>>" >> $logFile
sleep 15

# Configure STONITH on primary node
echo "<<< Configure STONITH on primary node >>>" >> $logFile
sudo crm configure property stonith-enabled=true
sudo crm configure property concurrent-fencing=true
sudo crm configure primitive rsc_st_azure stonith:fence_azure_arm \
params msi=true subscriptionId="$subId" resourceGroup="$resourceGroup" \
pcmk_monitor_retries=4 pcmk_action_limit=3 power_timeout=240 pcmk_reboot_timeout=900 \
op monitor interval=3600 timeout=120
sudo crm configure property stonith-timeout=900

# Configure azure-events cluster resource
echo "<<< Configure azure-events cluster resource >>>" >> $logFile
echo "<<< Enter maintenance mode >>>" >> $logFile
sudo crm configure property maintenance-mode=true | tee -i -a "$logFile"
sudo crm configure primitive rsc_azure-events ocf:heartbeat:azure-events op monitor interval=10s
sudo crm configure clone cln_azure-events rsc_azure-events
echo "<<< Leave maintenance mode >>>" >> $logFile
sudo crm configure property maintenance-mode=false | tee -i -a "$logFile"

# Pause to allow Pacemaker to start resources
echo "<<< Sleep 120 seconds >>>" >> $logFile
sleep 120

# Capture current config in output
echo "<<< Show the config at this point in the install >>>" >> $logFile
sudo crm configure show | tee -i -a "$logFile"
echo "<<< Show the status at this point in the install >>>" >> $logFile
sudo crm status | tee -i -a "$logFile"

# Install HSR on each node
echo "<<< Install HSR on each node >>>" >> $logFile
echo "<<< Install HSR on primary >>>" >> $logFile
sudo zypper -n install SAPHanaSR | tee -i -a "$logFile"
echo "<<< Install HSR on secondary >>>" >> $logFile
ssh root@$otherNode "sudo zypper -n install SAPHanaSR" | tee -i -a "$logFile"

# Start the database on the primary node and take a backup of each database
echo "<<< Start HDB and take backup of each DB >>>" >> $logFile
echo "<<< HDB start >>>" >> $logFile
su - $sapUser -c "HDB start" | tee -i -a "$logFile"
echo "<<< Sleep 15 seconds >>>" >> $logFile
sleep 15
echo "<<< Take backup of SYSTEMDB >>>" >> $logFile
su - $sapUser -c "hdbsql -d SYSTEMDB -u SYSTEM -p \"$sapPassword\" -i $sapInstanceNumber \"BACKUP DATA USING FILE ('initialbackupSYS')\"" | tee -i -a "$logFile"
echo "<<< Take backup of Instance DB >>>" >> $logFile
su - $sapUser -c "hdbsql -d $sapInstanceId -u SYSTEM -p \"$sapPassword\" -i $sapInstanceNumber \"BACKUP DATA USING FILE ('initialbackup$sapInstanceId')\"" | tee -i -a "$logFile"
echo "<<< Sleep 15 seconds >>>" >> $logFile
sleep 15

# Copy key info to secondary node
echo "<<< Copy key info to secondary node >>>" >> $logFile
sudo scp -o StrictHostKeyChecking=no /usr/sap/$sapInstanceId/SYS/global/security/rsecssfs/data/SSFS_$sapInstanceId.DAT $otherNode:/usr/sap/$sapInstanceId/SYS/global/security/rsecssfs/data/ | tee -i -a "$logFile"
sudo scp -o StrictHostKeyChecking=no /usr/sap/$sapInstanceId/SYS/global/security/rsecssfs/key/SSFS_$sapInstanceId.KEY $otherNode:/usr/sap/$sapInstanceId/SYS/global/security/rsecssfs/key/ | tee -i -a "$logFile"

# Register primary node in SAP Hana SR
echo "<<< Register primary node in HSR >>>" >> $logFile
su - $sapUser -c "hdbnsutil -sr_enable --name=SITE1" | tee -i -a "$logFile"
echo "<<< Sleep 20 seconds >>>" >> $logFile
sleep 20

#Capture HSR state after enabling on primary node
echo "<<< Capture current HSR state on primary node >>>" >> $logFile
su - $sapUser -c "hdbnsutil -sr_state" | tee -i -a "$logFile"
echo "<<< HDB info from primary node >>>" >> $logFile
su - $sapUser -c "HDB info" | tee -i -a "$logFile"

# Sleep for 90 seconds to give time to process HSR enablement
echo "<<< Sleep 90 seconds >>>" >> $logFile
sleep 90

# Register secondary node in SAP Hana SR
echo "<<< Stop and register secondary node in HSR >>>" >> $logFile
echo "<<< Stop SAP >>>" >> $logFile
ssh root@$otherNode "su - $sapUser -c \"sapcontrol -nr $sapInstanceNumber -function StopWait 600 10\"" | tee -i -a "$logFile"
echo "<<< Sleep 15 seconds >>>" >> $logFile
sleep 15
echo "<<< Perform HSR registration on secondary node >>>" >> $logFile
ssh root@$otherNode "su - $sapUser -c \"hdbnsutil -sr_register --remoteHost=$thisNode --remoteInstance=$sapInstanceNumber --replicationMode=sync --name=SITE2\"" | tee -i -a "$logFile"

# Sleep for 90 seconds to give time to process join of HSR secondary
echo "<<< Sleep 90 seconds >>>" >> $logFile
sleep 90

# Capture HSR state after enabling on secondary node
echo "<<< Capture current HSR state on secondary node >>>" >> $logFile
ssh root@$otherNode "su - $sapUser -c \"hdbnsutil -sr_state\"" | tee -i -a "$logFile"
echo "<<< HDB info from secondary node >>>" >> $logFile
ssh root@$otherNode "su - $sapUser -c \"HDB info\"" | tee -i -a "$logFile"

# Capture HSR state from primary node after secondary was added
echo "<<< Capture current HSR state from primary node after secondary was added >>>" >> $logFile
su - $sapUser -c "hdbnsutil -sr_state" | tee -i -a "$logFile"

# Stop the instance on each node
su - $sapUser -c "sapcontrol -nr $sapInstanceNumber -function StopSystem" | tee -i -a "$logFile"
sleep 15
ssh root@$otherNode "su - $sapUser -c \"sapcontrol -nr $sapInstanceNumber -function StopSystem\"" | tee -i -a "$logFile"
sleep 15

# Perform changes to HSR config on each node
echo "<<< Performing changes in HSR global config >>>" >> $logFile
sudo printf '\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n' '[ha_dr_provider_SAPHanaSR]' 'provider = SAPHanaSR' 'path = /usr/share/SAPHanaSR' 'execution_order = 1' '[ha_dr_provider_suschksrv]' 'provider = susChkSrv' 'path = /usr/share/SAPHanaSR' 'execution_order = 3' 'action_on_lost = fence' '[trace]' 'ha_dr_saphanasr = info' >> /hana/shared/$sapInstanceId/global/hdb/custom/config/global.ini
ssh root@$otherNode "sudo printf '\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n' '[ha_dr_provider_SAPHanaSR]' 'provider = SAPHanaSR' 'path = /usr/share/SAPHanaSR' 'execution_order = 1' '[ha_dr_provider_suschksrv]' 'provider = susChkSrv' 'path = /usr/share/SAPHanaSR' 'execution_order = 3' 'action_on_lost = fence' '[trace]' 'ha_dr_saphanasr = info' >> /hana/shared/$sapInstanceId/global/hdb/custom/config/global.ini"

# Update sudoers file on each node
echo "<<< Performing changes to sudoers on each node >>>" >> $logFile
sudo printf '%s\n%s\n%s\n' '# Needed for SAPHanaSR and susChkSrv Python hooks' "$sapUser ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_${sapInstanceIdLower}_site_srHook_*" "$sapUser ALL=(ALL) NOPASSWD: /usr/sbin/SAPHanaSR-hookHelper --sid=$sapInstanceId --case=fenceMe" >> /etc/sudoers.d/20-saphana
ssh root@$otherNode "sudo printf '%s\n%s\n%s\n' '# Needed for SAPHanaSR and susChkSrv Python hooks' \"$sapUser ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_${sapInstanceIdLower}_site_srHook_*\" \"$sapUser ALL=(ALL) NOPASSWD: /usr/sbin/SAPHanaSR-hookHelper --sid=$sapInstanceId --case=fenceMe\" >> /etc/sudoers.d/20-saphana"

# Start the instance on each node
echo "<<< Starting instance on each node >>>" >> $logFile
echo "<<< Start on primary >>>" >> $logFile
su - $sapUser -c "sapcontrol -nr $sapInstanceNumber -function StartSystem" | tee -i -a "$logFile"
echo "<<< Sleep 15 seconds >>>" >> $logFile
sleep 15
echo "<<< Start on secondary >>>" >> $logFile
ssh root@$otherNode "su - $sapUser -c \"sapcontrol -nr $sapInstanceNumber -function StartSystem\"" | tee -i -a "$logFile"

# Sleep 3 minutes
echo "<<< Sleep for 180 seconds to allow system to stabilize >>>" >> $logFile
sleep 180

# Check for system stabilization (looking for SOK)
echo "<<< check for system stabilization (looking for SOK) >>>" >> $logFile
sudo awk '/ha_dr_SAPHanaSR.*crm_attribute/ \
{ printf "%s %s %s %s\n", $2,$3,$5,$16 }' /usr/sap/$sapInstanceId/HDB${sapInstanceNumber}/$thisNode/trace/nameserver_* | tee -i -a "$logFile"
sudo egrep '(LOST:|STOP:|START:|DOWN:|init|load|fail)' /usr/sap/$sapInstanceId/HDB${sapInstanceNumber}/$thisNode/trace/nameserver_suschksrv.trc | tee -i -a "$logFile"

# Configure Pacemaker Cluster Resources
echo "<<< Putting cluster in maintenance mode >>> " >> $logFile
sudo crm configure property maintenance-mode=true | tee -i -a "$logFile"
echo "<<< Sleep 5 seconds >>>" >> $logFile
sleep 5

echo "<<< Configuring cluster resources >>>" >> $logFile
sudo crm configure primitive rsc_SAPHanaTopology_${sapInstanceId}_HDB${sapInstanceNumber} ocf:suse:SAPHanaTopology \
operations \$id="rsc_sap2_${sapInstanceId}_HDB${sapInstanceNumber}-operations" \
op monitor interval="10" timeout="600" \
op start interval="0" timeout="600" \
op stop interval="0" timeout="300" \
params SID="$sapInstanceId" InstanceNumber="$sapInstanceNumber"

sudo crm configure clone cln_SAPHanaTopology_${sapInstanceId}_HDB${sapInstanceNumber} rsc_SAPHanaTopology_${sapInstanceId}_HDB${sapInstanceNumber} \
meta clone-node-max="1" target-role="Started" interleave="true"

sudo crm configure primitive rsc_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber} ocf:suse:SAPHana \
operations \$id="rsc_sap_${sapInstanceId}_HDB${sapInstanceNumber}-operations" \
op start interval="0" timeout="3600" \
op stop interval="0" timeout="3600" \
op promote interval="0" timeout="3600" \
op monitor interval="60" role="Master" timeout="700" \
op monitor interval="61" role="Slave" timeout="700" \
params SID="$sapInstanceId" InstanceNumber="$sapInstanceNumber" PREFER_SITE_TAKEOVER="true" \
DUPLICATE_PRIMARY_TIMEOUT="7200" AUTOMATED_REGISTER="true"

sudo crm configure ms msl_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber} rsc_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber} \
meta notify="true" clone-max="2" clone-node-max="1" \
target-role="Started" interleave="true"

sudo crm configure primitive rsc_ip_${sapInstanceId}_HDB${sapInstanceNumber} ocf:heartbeat:IPaddr2 \
meta target-role="Started" \
operations \$id="rsc_ip_${sapInstanceId}_HDB${sapInstanceNumber}-operations" \
op monitor interval="10s" timeout="20s" \
params ip="$ilbIP"

sudo crm configure primitive rsc_nc_${sapInstanceId}_HDB${sapInstanceNumber} azure-lb port=625${sapInstanceNumber} \
op monitor timeout=20s interval=10 \
meta resource-stickiness=0

sudo crm configure group g_ip_${sapInstanceId}_HDB${sapInstanceNumber} rsc_ip_${sapInstanceId}_HDB${sapInstanceNumber} rsc_nc_${sapInstanceId}_HDB${sapInstanceNumber}

sudo crm configure colocation col_saphana_ip_${sapInstanceId}_HDB${sapInstanceNumber} 4000: g_ip_${sapInstanceId}_HDB${sapInstanceNumber}:Started \
msl_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber}:Master

sudo crm configure order ord_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber} Optional: cln_SAPHanaTopology_${sapInstanceId}_HDB${sapInstanceNumber} \
msl_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber}

# Final Pacemaker cleanup
echo "<<< Performing final cleanup >>>" >> $logFile
sudo crm resource cleanup rsc_SAPHana_${sapInstanceId}_HDB${sapInstanceNumber} | tee -i -a "$logFile"
echo "<<< Sleep 10 seconds >>>" >> $logFile
sleep 10
sudo crm configure property maintenance-mode=false | tee -i -a "$logFile"
sudo crm configure rsc_defaults resource-stickiness=1000
sudo crm configure rsc_defaults migration-threshold=5000

# Pause to allow Pacemaker to promote to MASTER
echo "<<< Sleeping 180 seconds >>>" >> $logFile
sleep 180

# HA is now configured; Generate outputs for log file
echo "<<< Configuration complete. Here's the outputs >>>" >> $logFile
echo "<<< Results of crm configure show >>>" >> $logFile
sudo crm configure show | tee -i -a "$logFile"
echo "<<< Results of crm status >>>" >> $logFile
sudo crm status | tee -i -a "$logFile"