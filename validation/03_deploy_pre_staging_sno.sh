#!/bin/bash


# 1) Prepare pre-staging disk with RootFS files
cp /var/lib/libvirt/images/pre-staging-ext4_1.img /var/lib/libvirt/images/pre-staging-sno_1.img
cp /tmp/small_image.iso /opt/validations/custom_discovery_image.iso


# 2) Create VM with existing pre-staging disk
kcli create vm -P memory=32000 \
               -P numcpus=16 \
               -P iso=/opt/validations/custom_discovery_image.iso \
               -P disks=[200,20] \
               -P nets=["{\"name\":\"validations-net\",\"nic\":\"ens3\",\"mac\":\"de:ad:be:ff:00:06\"}"] \
               pre-staging-sno


# 3) View VM console
kcli console -s pre-staging-sno


# 4) Access SNO VM
ssh core@172.16.100.6


# 5) Remove SNO VM
kcli delete vm pre-staging-sno
