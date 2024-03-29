#!/usr/bin/env python3

import os
import sys
import tarfile
import subprocess
import time

if os.geteuid() != 0:
    print("Please run as root")
    sys.exit()

os.chdir("/var/tmp/")
os.makedirs("ADELogs", exist_ok=True)
os.chdir("ADELogs")

if os.path.exists("/var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux/"):
    with tarfile.open("varlogazure.tar.gz", "w:gz") as tar:
        tar.add("/var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux")

if os.path.exists("/var/lib/azure_disk_encryption_config/"):
    with tarfile.open("varlibazureconfig.tar.gz", "w:gz") as tar:
        tar.add("/var/lib/azure_disk_encryption_config/")

if os.path.exists("/var/lib/azure_disk_encryption_archive/"):
    with tarfile.open("varlibazurearchive.tar.gz", "w:gz") as tar:
        tar.add("/var/lib/azure_disk_encryption_archive/")

if os.path.exists("/var/lib/waagent/Microsoft.Azure.Security.AzureDiskEncryptionForLinux"):
    with tarfile.open("varlibextension.tar.gz", "w:gz") as tar:
        tar.add("/var/lib/waagent/Microsoft.Azure.Security.AzureDiskEncryptionForLinux")

with open("lsblk.out", "w") as f:
    f.write(os.popen("lsblk").read())
    f.write(os.popen("lsblk -fs").read())

with open("df.out", "w") as f:
    f.write(os.popen("df -Th").read())

with open("lvs.out", "w") as f:
    f.write(os.popen("lvs").read())

with open("pvs.out", "w") as f:
    f.write(os.popen("pvs").read())

with open("blkid.out", "w") as f:
    f.write(os.popen("blkid").read())

with open("disks.out", "w") as f:
    f.write(os.popen("ls -l /dev/disk/*").read())

with open("dmsetup_ls.out", "w") as f:
    f.write(os.popen("dmsetup ls --target crypt").read())

with open("os_version.out", "w") as f:
    f.write(os.popen("cat /proc/version").read())

with open("network_checks.out", "w") as f:
    subprocess.run(["nc", "-vz", "169.254.169.254", "80"], stdout=f, stderr=f)
    subprocess.run(["nc", "-vz", "168.63.129.16", "80"], stdout=f, stderr=f)

with open("python.out", "w") as f:
    f.write(os.popen("ls -l /usr/bin/python*").read())

os.system("cp /etc/fstab* .")
os.system("cp /etc/crypttab .")
os.system("cp /var/log/waagent.log .")

os.chdir("..")
current_time = time.strftime("%Y%m%d")
with tarfile.open("ADELogs-"+current_time + ".tar.gz", "w:gz") as tar:
    tar.add("ADELogs")
