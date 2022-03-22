#!/bin/bash


# 1) Create default network
kcli create network -c 192.168.122.0/24 default


# 2) Download centos9stream image
kcli download image centos9stream


# 3) Create temporal VM
kcli create vm --image centos9stream \
               -P disks='[20,20]' \
               pre-staging-vm

kcli list vm
kcli info vm pre-staging-vm


# 4) Download RootFS to disk in VM
kcli ssh pre-staging-vm

# 4.1) prepare disk
lsblk -fp
sudo mkfs.ext4 /dev/vdb
sudo mount /dev/vdb /mnt/

# 4.2) copy rootfs into disk (4.9 release)
sudo curl -s -L -o /mnt/rhcos-live-rootfs.x86_64.img https://rhcos-redirector.apps.art.xq1c.p1.openshiftapps.com/art/storage/releases/rhcos-4.9/49.84.202110081407-0/x86_64/rhcos-49.84.202110081407-0-live-rootfs.x86_64.img
sudo curl -s -L -o /mnt/rhcos-live.x86_64.iso https://rhcos-redirector.apps.art.xq1c.p1.openshiftapps.com/art/storage/releases/rhcos-4.9/49.84.202110081407-0/x86_64/rhcos-49.84.202110081407-0-live.x86_64.iso
ls -lah /mnt

# 4.3) close disk and exit vm
sudo umount /mnt/
logout


# 5) Create pre_staging disk
cp /var/lib/libvirt/images/pre-staging-vm_1.img /var/lib/libvirt/images/pre-staging-ext4_1.img
ls -lah /var/lib/libvirt/images/


# 6) Remove temporal VM
kcli delete vm pre-staging-vm


# 7) Validate pre_staging disk content
cp /var/lib/libvirt/images/pre-staging-ext4_1.img /var/lib/libvirt/images/pre-staging-sno_1.img
kcli create vm --image centos9stream \
               -P disks='[20,20]' \
               pre-staging-sno
kcli ssh pre-staging-sno
sudo mount /dev/vdb /mnt/
ls -lah /mnt
logout
kcli delete vm pre-staging-sno


# 8) Clean up
kcli delete image centos9stream
kcli delete network default
