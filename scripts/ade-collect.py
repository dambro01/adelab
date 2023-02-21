#!/usr/bin/env python3

import os
import sys
import tarfile

if os.geteuid() != 0:
    print("Please run as root")
    sys.exit()

os.chdir("/var/tmp/")
os.makedirs("ADELogs", exist_ok=True)
os.chdir("ADELogs")

with tarfile.open("varlogazure.tar.gz", "w:gz") as tar:
    tar.add("/var/log/azure/Microsoft.Azure.Security.AzureDiskEncryptionForLinux*")

with tarfile.open("varlibazureconfig.tar.gz", "w:gz") as tar:
    tar.add("/var/lib/azure_disk_encryption_config/")

with tarfile.open("varlibazurearchive.tar.gz", "w:gz") as tar:
    tar.add("/var/lib/azure_disk_encryption_archive/")

with tarfile.open("varlibextension.tar.gz", "w:gz") as tar:
    tar.add("/var/lib/waagent/Microsoft.Azure.Security.AzureDiskEncryptionForLinux*")

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
    f.write(os.popen("nc -vz 169.254.169.254 80").read())
    f.write(os.popen("nc -vz 168.63.129.16 80").read())

with open("python.out", "w") as f:
    f.write(os.popen("ls -l /usr/bin/python*").read())

os.system("cp /etc/fstab* .")
os.system("cp /etc/crypttab .")
os.system("cp /var/log/waagent.log .")

os.chdir("..")
with tarfile.open("ADELogs.tar.gz", "w:gz") as tar:
    tar.add("ADELogs")
