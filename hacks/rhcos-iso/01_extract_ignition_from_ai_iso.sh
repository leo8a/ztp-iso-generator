#!/bin/bash

FINAL_IGNITION_PATH=$1
AI_ISO_URL=${2:-https://api.openshift.com/api/assisted-images/images/cbbd0489-0404-4603-ad58-228b1d887309?arch=x86_64&image_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NDcyOTY2NDIsInN1YiI6ImNiYmQwNDg5LTA0MDQtNDYwMy1hZDU4LTIyOGIxZDg4NzMwOSJ9.2ZOswRPOqEzNnkfAa6S8JL9vUkk1vbhmNl5dE-CjiTI&type=full-iso&version=4.9}


#===============================================
# 1) Create output folder if it does not exist #
#===============================================

if [ -z "$2" ]
  then
    echo "Please provide the full path for Assisted Installer Service (AIS) Ignition"
    exit 1
fi

rm -f "$FINAL_ISO_PATH" ; mkdir -pv "$(dirname "$FINAL_ISO_PATH")"


#=======================================
# 2) Download the AIS ISO and Mount it #
#=======================================

[ -f /tmp/discovery-iso.iso ] || curl "$AI_ISO_URL" -o /tmp/discovery-iso.iso

rm -rf /mnt/discovery_iso ; mkdir -pv /mnt/discovery_iso
mount -o loop /tmp/discovery-iso.iso /mnt/discovery_iso


#============================================================
# 3) Extract the Ignition from the downloaded Discovery ISO #
#============================================================

rm -rf /tmp/temporary_ignition ; mkdir -pv /tmp/temporary_ignition

cp /mnt/discovery_iso/images/ignition.img /tmp/temporary_ignition/

pushd /tmp/temporary_ignition || exit 1
cpio -idmv < ignition.img                   # -> extract with cpio
popd || exit 1


#===================================
# 4) Generate Ignition config file #
#===================================

cp /tmp/temporary_ignition/config.ign "$FINAL_IGNITION_PATH"        # -> copy to final file


#========================
# 5) Clean up artifacts #
#========================

rm -rf /tmp/temporary_ignition
umount /mnt/discovery_iso ; rm -rf /mnt/discovery_iso
