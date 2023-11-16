#!/bin/bash

# Establish variables
sapInstanceId=$1
sapPassword=$2

# Set up log file
set -v -x -E
logFile="/tmp/$(hostname)_diskConfig_$(date +%Y-%m-%d_%H-%M-%S).log"

# Set root password
echo root:$sapPassword | chpasswd

# Create physical volumes for each lun
echo "<<< create physical volumes >>>" >> $logFile
sudo pvcreate /dev/disk/azure/scsi1/lun0 | tee -i -a "$logFile"
sudo pvcreate /dev/disk/azure/scsi1/lun1 | tee -i -a "$logFile"
sudo pvcreate /dev/disk/azure/scsi1/lun2 | tee -i -a "$logFile"
sudo pvcreate /dev/disk/azure/scsi1/lun3 | tee -i -a "$logFile"
sudo pvcreate /dev/disk/azure/scsi1/lun4 | tee -i -a "$logFile"
sudo pvcreate /dev/disk/azure/scsi1/lun5 | tee -i -a "$logFile"
sudo pvcreate /dev/disk/azure/scsi1/lun6 | tee -i -a "$logFile"

# Create volume groups
echo "<<< create volume groups >>>" >> $logFile
sudo vgcreate vg_hana_data_$sapInstanceId /dev/disk/azure/scsi1/lun0 /dev/disk/azure/scsi1/lun1 /dev/disk/azure/scsi1/lun2 /dev/disk/azure/scsi1/lun3 | tee -i -a "$logFile"
sudo vgcreate vg_hana_shared_$sapInstanceId /dev/disk/azure/scsi1/lun4 | tee -i -a "$logFile"
sudo vgcreate vg_hana_shared_usrsap_$sapInstanceId /dev/disk/azure/scsi1/lun5 | tee -i -a "$logFile"
sudo vgcreate vg_hana_log_$sapInstanceId /dev/disk/azure/scsi1/lun6 | tee -i -a "$logFile"

# Creates logical volumes
echo "<<< create logical volumes >>>" >> $logFile
sudo lvcreate -i 4 -I 256 -l 100%FREE -n hana_data vg_hana_data_$sapInstanceId | tee -i -a "$logFile"
sudo lvcreate -l 100%FREE -n hana_shared vg_hana_shared_$sapInstanceId | tee -i -a "$logFile"
sudo lvcreate -l 100%FREE -n hana_usrsap vg_hana_shared_usrsap_$sapInstanceId | tee -i -a "$logFile"
sudo lvcreate -l 100%FREE -n hana_log vg_hana_log_$sapInstanceId | tee -i -a "$logFile"

# Creates a file system on each drive
echo "<<< create file systems >>>" >> $logFile
sudo mkfs.xfs /dev/vg_hana_data_$sapInstanceId/hana_data | tee -i -a "$logFile"
sudo mkfs.xfs /dev/vg_hana_shared_$sapInstanceId/hana_shared | tee -i -a "$logFile"
sudo mkfs.xfs /dev/vg_hana_shared_usrsap_$sapInstanceId/hana_usrsap | tee -i -a "$logFile"
sudo mkfs.xfs /dev/vg_hana_log_$sapInstanceId/hana_log | tee -i -a "$logFile"

# Creates the directories
echo "<<< create directories >>>" >> $logFile
sudo mkdir -p /hana/data/$sapInstanceId
sudo mkdir -p /hana/shared/$sapInstanceId
sudo mkdir -p /usr/sap/$sapInstanceId
sudo mkdir -p /hana/log/$sapInstanceId

# Extract UUIDs for each of the new drives
dataUUID=$(sudo blkid|grep /dev/mapper/vg_hana_data_$sapInstanceId-hana_data|sed "s/.* UUID=\"\([^\" ]*\).*/\1/g")
sharedUUID=$(sudo blkid|grep /dev/mapper/vg_hana_shared_$sapInstanceId-hana_shared|sed "s/.* UUID=\"\([^\" ]*\).*/\1/g")
usrsapUUID=$(sudo blkid|grep /dev/mapper/vg_hana_shared_usrsap_$sapInstanceId-hana_usrsap|sed "s/.* UUID=\"\([^\" ]*\).*/\1/g")
logUUID=$(sudo blkid|grep /dev/mapper/vg_hana_log_$sapInstanceId-hana_log|sed "s/.* UUID=\"\([^\" ]*\).*/\1/g")

echo "dataUUID = $dataUUID" >> $logFile
echo "sharedUUID = $sharedUUID" >> $logFile
echo "usrsapUUID = $usrsapUUID" >> $logFile
echo "logUUID = $logUUID" >> $logFile

# Adds each disk to fstab
echo "<<< Add drives to fstab >>>" >> $logFile
echo "/dev/disk/by-uuid/$dataUUID /hana/data/$sapInstanceId xfs defaults,nofail 0 2" >> /etc/fstab
echo "/dev/disk/by-uuid/$sharedUUID /hana/shared/$sapInstanceId xfs defaults,nofail 0 2" >> /etc/fstab
echo "/dev/disk/by-uuid/$usrsapUUID /usr/sap/$sapInstanceId xfs defaults,nofail 0 2" >> /etc/fstab
echo "/dev/disk/by-uuid/$logUUID /hana/log/$sapInstanceId xfs defaults,nofail 0 2" >> /etc/fstab

# Mounts the new disks
echo "<<< mount the disks >>>"
sudo mount -a | tee -i -a "$logFile"

# Report file system to log
echo "<<< Output of df -h >>>" >> $logFile
df -h | tee -i -a "$logFile"

echo "<<< install socat >>>" >> $logFile
sudo zypper -n install socat | tee -i -a "$logFile"

echo "<<< install resource-agents >>>" >> $logFile
sudo zypper -n install resource-agents | tee -i -a "$logFile"

echo "<<< install fence-agents >>>" >> $logFile
sudo zypper -n install fence-agents | tee -i -a "$logFile"

echo "<<< install python3-azure-mgmt-compute >>>" >> $logFile
sudo zypper -n install python3-azure-mgmt-compute | tee -i -a "$logFile"

echo "<<< install python3-azure-identity >>>" >> $logFile
sudo zypper -n install python3-azure-identity | tee -i -a "$logFile"

echo "<<< perform zypper update >>>" >> $logFile
sudo zypper -n update | tee -i -a "$logFile"

echo "<<< reboot VM >>>" >> $logFile
sudo shutdown -r
