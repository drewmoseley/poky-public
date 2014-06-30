#!/bin/sh -e
#
# Copyright (c) 2012, Intel Corporation.
# All rights reserved.
#
# install.sh [device_name] [rootfs_name]
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# We need 20 Mb for the boot partition
boot_size=20

# 5% for swap
swap_ratio=5

# Get a list of hard drives
hdnamelist=""
live_dev_name=${1%%/*}

echo "Searching for hard drives ..."

for device in `ls /sys/block/`; do
    case $device in
	loop*)
            # skip loop device
	    ;;
	ram*)
            # skip ram device
	    ;;
	*)
	    # skip the device LiveOS is on
	    # Add valid hard drive name to the list
	    if [ $device != $live_dev_name -a -e /dev/$device ]; then
		hdnamelist="$hdnamelist $device"
	    fi
	    ;;
    esac
done

TARGET_DEVICE_NAME=""
for hdname in $hdnamelist; do
    # Display found hard drives and their basic info
    echo "-------------------------------"
    echo /dev/$hdname
    if [ -r /sys/block/$hdname/device/vendor ]; then
	echo -n "VENDOR="
	cat /sys/block/$hdname/device/vendor
    fi
    echo -n "MODEL="
    cat /sys/block/$hdname/device/model
    cat /sys/block/$hdname/device/uevent
    echo
    # Get user choice
    while true; do
	echo -n "Do you want to install this image there? [y/n] "
	read answer
	if [ "$answer" = "y" -o "$answer" = "n" ]; then
	    break
	fi
	echo "Please answer y or n"
    done
    if [ "$answer" = "y" ]; then
	TARGET_DEVICE_NAME=$hdname
	break
    fi

done

if [ -n "$TARGET_DEVICE_NAME" ]; then
    echo "Installing image on /dev/$TARGET_DEVICE_NAME ..."
else
    echo "No hard drive selected. Installation aborted."
    exit 1
fi

device=$TARGET_DEVICE_NAME

#
# The udev automounter can cause pain here, kill it
#
rm -f /etc/udev/rules.d/automount.rules
rm -f /etc/udev/scripts/mount*

#
# Unmount anything the automounter had mounted
#
umount /dev/${device}* 2> /dev/null || /bin/true

mkdir -p /tmp
cat /proc/mounts > /etc/mtab

disk_size=$(parted /dev/${device} unit mb print | grep Disk | cut -d" " -f 3 | sed -e "s/MB//")

swap_size=$((disk_size*swap_ratio/100))
rootfs_size=$((disk_size-boot_size-swap_size))

rootfs_start=$((boot_size))
rootfs_end=$((rootfs_start+rootfs_size))
swap_start=$((rootfs_end))

# MMC devices are special in a couple of ways
# 1) they use a partition prefix character 'p'
# 2) they are detected asynchronously (need rootwait)
rootwait=""
part_prefix=""
if [ ! "${device#mmcblk}" = "${device}" ]; then
    part_prefix="p"
    rootwait="rootwait"
fi
bootfs=/dev/${device}${part_prefix}1
rootfs=/dev/${device}${part_prefix}2
swap=/dev/${device}${part_prefix}3

echo "*****************"
echo "Boot partition size:   $boot_size MB ($bootfs)"
echo "Rootfs partition size: $rootfs_size MB ($rootfs)"
echo "Swap partition size:   $swap_size MB ($swap)"
echo "*****************"
echo "Deleting partition table on /dev/${device} ..."
dd if=/dev/zero of=/dev/${device} bs=512 count=2

echo "Creating new partition table on /dev/${device} ..."
parted /dev/${device} mklabel gpt

echo "Creating boot partition on $bootfs"
parted /dev/${device} mkpart primary 0% $boot_size
parted /dev/${device} set 1 boot on

echo "Creating rootfs partition on $rootfs"
parted /dev/${device} mkpart primary $rootfs_start $rootfs_end

echo "Creating swap partition on $swap"
parted /dev/${device} mkpart primary $swap_start 100%

parted /dev/${device} print

echo "Formatting $bootfs to vfat..."
mkfs.vfat $bootfs

echo "Formatting $rootfs to ext3..."
mkfs.ext3 $rootfs

echo "Formatting swap partition...($swap)"
mkswap $swap

mkdir /ssd
mkdir /rootmnt
mkdir /bootmnt

mount $rootfs /ssd
mount -o rw,loop,noatime,nodiratime /run/media/$1/$2 /rootmnt

echo "Copying rootfs files..."
cp -a /rootmnt/* /ssd

if [ -d /ssd/etc/ ] ; then
    echo "$swap                swap             swap       defaults              0  0" >> /ssd/etc/fstab

    # We dont want udev to mount our root device while we're booting...
    if [ -d /ssd/etc/udev/ ] ; then
        echo "/dev/${device}" >> /ssd/etc/udev/mount.blacklist
    fi
fi

umount /ssd
umount /rootmnt

echo "Preparing boot partition..."
mount $bootfs /ssd

EFIDIR="/ssd/EFI/BOOT"
mkdir -p $EFIDIR
cp /run/media/$1/vmlinuz /ssd
# Copy the efi loader
cp /run/media/$1/EFI/BOOT/*.efi $EFIDIR

if [ -f /run/media/$1/EFI/BOOT/grub.cfg ]; then
    GRUBCFG="$EFIDIR/grub.cfg"
    cp /run/media/$1/EFI/BOOT/grub.cfg $GRUBCFG
    # Update grub config for the installed image
    # Delete the install entry
    sed -i "/menuentry 'install'/,/^}/d" $GRUBCFG
    # Delete the initrd lines
    sed -i "/initrd /d" $GRUBCFG
    # Delete any LABEL= strings
    sed -i "s/ LABEL=[^ ]*/ /" $GRUBCFG
    # Delete any root= strings
    sed -i "s/ root=[^ ]*/ /" $GRUBCFG
    # Add the root= and other standard boot options
    sed -i "s@linux /vmlinuz *@linux /vmlinuz root=$rootfs rw $rootwait quiet @" $GRUBCFG
fi

if [ -d /run/media/$1/loader ]; then
    GUMMIBOOT_CFGS="/ssd/loader/entries/*.conf"
    # copy config files for gummiboot
    cp -dr /run/media/$1/loader /ssd
    # delete the install entry
    rm -f /ssd/loader/entries/install.conf
    # delete the initrd lines
    sed -i "/initrd /d" $GUMMIBOOT_CFGS
    # delete any LABEL= strings
    sed -i "s/ LABEL=[^ ]*/ /" $GUMMIBOOT_CFGS
    # delete any root= strings
    sed -i "s/ root=[^ ]*/ /" $GUMMIBOOT_CFGS
    # add the root= and other standard boot options
    sed -i "s@options *@options root=$rootfs rw $rootwait quiet @" $GUMMIBOOT_CFGS
fi

umount /ssd
sync

echo "Remove your installation media, and press ENTER"

read enter

echo "Rebooting..."
reboot -f
