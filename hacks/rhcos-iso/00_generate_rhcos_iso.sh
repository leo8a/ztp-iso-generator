#!/bin/bash

FINAL_ISO_PATH=$1
RHCOS_LIVE_ISO=${2:-https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.9/latest/rhcos-live.x86_64.iso}


#===============================================
# 1) Create output folder if it does not exist #
#===============================================

if [ -z "$1" ]
  then
    echo "Please provide the full path for RHCOS minimal ISO"
    exit 1
fi

rm -f "$FINAL_ISO_PATH" ; mkdir -pv "$(dirname "$FINAL_ISO_PATH")"


#========================================
# 2) Download the LIVE ISO and Mount it #
#========================================

[ -f /tmp/rhcos-live.iso ] || curl "$RHCOS_LIVE_ISO" -o /tmp/rhcos-live.iso

rm -rf /tmp/coreos ; mkdir -pv /tmp/coreos
mount -o loop /tmp/rhcos-live.iso /tmp/coreos/


#====================================================
# 3) Remove the RootFS from the downloaded LIVE ISO #
#====================================================

rm -rf /tmp/custom_coreos ; mkdir -pv /tmp/custom_coreos

sudo cp -R /tmp/coreos/* /tmp/custom_coreos/
chmod -R u+w /tmp/custom_coreos
rm -f /tmp/custom_coreos/images/pxeboot/rootfs.img


#================================
# 4) Generate Minimal RHCOS ISO #
#================================

# 4.1) install dependencies
dnf install -y syslinux xorriso || true

# 4.2) modify content of cfg files
cat <<EOF > /tmp/custom_coreos/EFI/redhat/grub.cfg
set default="1"

function load_video {
  insmod efi_gop
  insmod efi_uga
  insmod video_bochs
  insmod video_cirrus
  insmod all_video
}

load_video
set gfxpayload=keep
insmod gzio
insmod part_gpt
insmod ext2

set timeout=5
### END /etc/grub.d/00_header ###

### BEGIN /etc/grub.d/10_linux ###
menuentry 'RHEL CoreOS (Live)' --class fedora --class gnu-linux --class gnu --class os {
linux /images/pxeboot/vmlinuz
initrd /images/pxeboot/initrd.img
}
EOF

cat <<EOF > /tmp/custom_coreos/isolinux/isolinux.cfg
serial 0
default vesamenu.c32
# timeout in units of 1/10s. 50 == 5 seconds
timeout 50

display boot.msg

# Clear the screen when exiting the menu, instead of leaving the menu displayed.
# For vesamenu, this means the graphical background is still displayed without
# the menu itself for as long as the screen remains in graphics mode.
menu clear
menu background splash.png
menu title RHEL CoreOS
menu vshift 8
menu rows 18
menu margin 8
#menu hidden
menu helpmsgrow 15
menu tabmsgrow 13

# Border Area
menu color border * #00000000 #00000000 none

# Selected item
menu color sel 0 #ffffffff #00000000 none

# Title bar
menu color title 0 #ff7ba3d0 #00000000 none

# Press [Tab] message
menu color tabmsg 0 #ff3a6496 #00000000 none

# Unselected menu item
menu color unsel 0 #84b8ffff #00000000 none

# Selected hotkey
menu color hotsel 0 #84b8ffff #00000000 none

# Unselected hotkey
menu color hotkey 0 #ffffffff #00000000 none

# Help text
menu color help 0 #ffffffff #00000000 none

# A scrollbar of some type? Not sure.
menu color scrollbar 0 #ffffffff #ff355594 none

# Timeout msg
menu color timeout 0 #ffffffff #00000000 none
menu color timeout_msg 0 #ffffffff #00000000 none

# Command prompt text
menu color cmdmark 0 #84b8ffff #00000000 none
menu color cmdline 0 #ffffffff #00000000 none

# Do not display the actual menu unless the user presses a key. All that is displayed is a timeout message.

menu tabmsg Press Tab for full configuration options on menu items.

menu separator # insert an empty line
menu separator # insert an empty line

label linux
  menu label ^RHEL CoreOS (Live)
  menu default
  kernel /images/pxeboot/vmlinuz
  append initrd=/images/pxeboot/initrd.img

menu separator # insert an empty line

menu end
EOF

# 4.3) generate minimal ISO
xorriso -as mkisofs \
  -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e images/efiboot.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -o "$FINAL_ISO_PATH" \
  /tmp/custom_coreos


#========================
# 5) Clean up artifacts #
#========================

umount /tmp/coreos ; rmdir /tmp/coreos
