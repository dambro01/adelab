#!/bin/bash

# Establish variables
sapInstanceId=HN1
sapInstanceIdLower="$(echo $sapInstanceId | tr '[:upper:]' '[:lower:]')"
sapInstanceNumber=00
sapUser=${sapInstanceIdLower}adm
sapPassword="Pa55w.rd1234!"

# Set up log file
set -v -x -E
logFile="/tmp/$(hostname)_sapInstall_$(date +%Y-%m-%d_%H-%M-%S).log"

# Make Download directory
sudo mkdir /hana/shared/$sapInstanceId/download
sudo mkdir /hana/shared/$sapInstanceId/download/sapsoftware
sudo mkdir /hana/shared/$sapInstanceId/download/hanainstall

# Download SAP Software
cd /var/tmp/ || exit
sudo mkdir -p /hana/shared/HN1/download/hanainstall
sudo wget -O azcopy_v10.tar.gz https://azcopyvnext.azureedge.net/releases/release-10.21.2-20231106/azcopy_linux_amd64_10.21.2.tar.gz && tar -xf azcopy_v10.tar.gz --strip-components=1
if [ $? -eq 0 ]; then
    /var/tmp/azcopy copy "https://diambroisap.blob.core.windows.net/sapsoftware/51057281.ZIP?sp=r&st=2023-11-16T18:35:36Z&se=2023-11-18T02:35:36Z&spr=https&sv=2022-11-02&sr=c&sig=Vbf7X%2B%2BbWVx6xBwzjWXAdQGmzMKK8V5MvXXVqm2pdws%3D" "/hana/shared/HN1/download/" --recursive=TRUE
else
    # If the first command failed, display an error message
    echo "Error occurred while downloading or extracting azcopy_v10.tar.gz" | tee -i -a "$logFile"
    exit 23
fi

# Extract installer
sudo unzip /hana/shared/HN1/download/51057281.ZIP -d /hana/shared/HN1/download/hanainstall
if [ $? -eq 0 ]; then
    echo "Successfully unzipped 51057281.ZIP" | tee -i -a "$logFile"
else
    # If the first command failed, display an error message
    echo "Error occurred while unzipping 51057281.ZIP" | tee -i -a "$logFile"
    exit 23
fi

# Permissions fix on the installation media
chmod +x /hana/shared/$sapInstanceId/download/hanainstall/DATA_UNITS/HDB_SERVER_LINUX_X86_64

# Install prereqs
echo "<<< Install libgcc_s1 >>>" >> "$logFile"
sudo zypper -n install libgcc_s1 | tee -i -a "$logFile"
echo "<<< Install libstdc++6 >>>" >> "$logFile"
sudo zypper -n install libstdc++6 | tee -i -a "$logFile"
echo "<<< install libatomic1 >>>" >> "$logFile"
sudo zypper -n install libatomic1 | tee -i -a "$logFile"
echo "<<< install insserv-compat >>>" >> "$logFile"
sudo zypper -n install insserv-compat | tee -i -a "$logFile"
echo "<<< install libtool >>>" >> "$logFile"
sudo zypper -n install libtool | tee -i -a "$logFile"

# Launch the SAP Installer and proceed through the config questions
echo "<<< Begin install of SAP >>>" >> "$logFile"
expect <<EOF | tee -i -a "$logFile"
set timeout 1500
spawn /hana/shared/$sapInstanceId/download/hanainstall/DATA_UNITS/HDB_SERVER_LINUX_X86_64/hdblcm --ignore=check_signature_file
expect -exact "Enter selected action index \[4\]: "
send "1\r"
expect -exact "Enter comma-separated list of the selected indices \[3,4\]: "
send "2,3,4\r"
expect -exact "Enter Installation Path \[/hana/shared\]: "
send "/hana/shared\r"
expect -exact "Enter Local Host Name \[$HOSTNAME\]: "
send "$HOSTNAME\r"
expect -exact "Do you want to add hosts to the system? (y/n) \[n\]: "
send "n\r"
expect -exact "Enter SAP HANA System ID: "
send "$sapInstanceId\r"
expect -exact "Enter Instance Number \[00\]: "
send "$sapInstanceNumber\r"
expect -exact "Enter Local Host Worker Group \[default\]: "
send "\r"
expect -exact "Select System Usage / Enter Index \[4\]: "
send "2\r"
expect -exact "Do you want to enable backup encryption? \[y\]: "
send "n\r"
expect -exact "Do you want to enable data and log volume encryption? \[y\]: "
send "n\r"
expect -exact "Enter Location of Data Volumes \[/hana/data/$sapInstanceId\]: "
send "/hana/data/$sapInstanceId\r"
expect -exact "Enter Location of Log Volumes \[/hana/log/$sapInstanceId\]: "
send "/hana/log/$sapInstanceId\r"
expect -exact "Restrict maximum memory allocation? \[n\]: "
send "n\r"
expect -exact "Apply System Size Dependent Resource Limits? (SAP Note 3014176) \[y\]: "
send "y\r"
expect -exact "Enter SAP Host Agent User (sapadm) Password: "
send "$sapPassword\r"
expect -exact "Confirm SAP Host Agent User (sapadm) Password: "
send "$sapPassword\r"
expect -exact "Enter System Administrator ($sapUser) Password: "
send "$sapPassword\r"
expect -exact "Confirm System Administrator ($sapUser) Password: "
send "$sapPassword\r"
expect -exact "Enter System Administrator Home Directory \[/usr/sap/$sapInstanceId/home\]: "
send "/usr/sap/$sapInstanceId/home\r"
expect -exact "Enter System Administrator Login Shell \[/bin/sh\]: "
send "\r"
expect -exact "Enter System Administrator User ID \[1001\]: "
send "\r"
expect -exact "Enter ID of User Group (sapsys) \[79\]: "
send "\r"
expect -exact "Enter System Database User (SYSTEM) Password: "
send "$sapPassword\r"
expect -exact "Confirm System Database User (SYSTEM) Password: "
send "$sapPassword\r"
expect -exact "Restart system after machine reboot? \[n]\: "
send "n\r"
expect -exact "Enter Installation Path for Local Secure Store \[/lss/shared\]: "
send "\r"
expect -exact "Enter Local Secure Store User (hn1crypt) Password: "
send "$sapPassword\r"
expect -exact "Confirm Local Secure Store User (hn1crypt) Password: "
send "$sapPassword\r"
expect -exact "Enter Local Secure Store User (hn1crypt) ID \[1002\]: "
send "\r"
expect -exact "Enter Local Secure Store User Group ID \[80\]: "
send "\r"
expect -exact "Enter Local Secure Store User Home Directory \[/usr/sap/HN1/lss/home\]: "
send "\r"
expect -exact "Enter Local Secure Store User Login Shell \[/bin/sh\]: "
send "\r"
expect -exact "Enter Local Secure Store Auto Backup Password: "
send "$sapPassword\r"
expect -exact "Confirm Local Secure Store Auto Backup Password: "
send "$sapPassword\r"
expect -exact "Do you want to continue? (y/n): "
send "y\r"
expect -exact "SAP HANA Database System installed\r"
expect eof
EOF

# SAP Installation is complete
echo "<<< SAP Installation is complete >>>" >> "$logFile"

echo "<<< Get status for log >>>" >> "$logFile"
su - "$sapUser" -c "HDB info" | tee -i -a "$logFile"