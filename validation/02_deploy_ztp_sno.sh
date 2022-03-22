#!/bin/bash


# 1) Download Discovery ISO for SNO
wget -O /opt/validations/discovery_image_saas.iso '<PUT-YOUR-DISCOVERY-ISO_DOWNLOAD-URl-HERE>'
ls -lah /opt/validations


# 2) Create VM with Discovery ISO
kcli create vm -P memory=32000 \
               -P numcpus=16 \
               -P iso=/opt/validations/discovery_image_saas.iso \
               -P disks=[200,20] \
               -P nets=["{\"name\":\"validations-net\",\"nic\":\"ens3\",\"mac\":\"de:ad:be:ff:00:05\"}"] \
               ztp-sno


# 3) View VM console
kcli console -s ztp-sno


# 4) Access SNO VM
ssh core@172.16.100.5


# 5) Remove SNO VM
kcli delete vm ztp-sno
