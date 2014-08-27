#!/bin/bash

echo comment out pve-enterprise package repo, that requires a license
sed -i 's/^\([^#]\)/#\1/g' /etc/apt/sources.list.d/pve-enterprise.list

echo get some packages
apt-get update; DEBIAN_FRONTEND=noninteractive apt-get install -y mdadm vim

echo duplicate partition table from sda to sdb, change uuid of sdb
sgdisk -R /dev/sdb /dev/sda
sgdisk -G /dev/sdb

echo tell the OS that we are going to use linux software raid
sgdisk -t 2:fd00 /dev/sdb
sgdisk -t 3:fd00 /dev/sdb

echo create the raid devices
mdadm --create --metadata=1.2 -l 1 -n 2 /dev/md0 missing /dev/sdb2
mdadm --create --metadata=1.2 -l 1 -n 2 /dev/md1 missing /dev/sdb3

echo save raid config
mdadm --detail --scan >> /etc/mdadm/mdadm.conf

echo duplicate BIOS boot partition
dd if=/dev/sda1 of=/dev/sdb1

echo format md0
mkfs.ext3 /dev/md0

echo copy /boot to /dev/md0
mkdir /mnt/md0
mount /dev/md0 /mnt/md0
cp -ax /boot/* /mnt/md0

echo replace /boot with /dev/md0
umount /mnt/md0
umount /boot
mount /dev/md0 /boot

echo change /etc/fstab to use the new md0 as boot
OldUUID=`grep ^UUID /etc/fstab`; echo "#$OldUUID" >> /etc/fstab
NewUUID=`blkid | grep md0 | sed -e 's/.*UUID="//g' -e 's/".*//g'`
sed -i 's/^\(UUID=\)[^ ]*\( .*\)/\1'$NewUUID'\2/g' /etc/fstab

echo setup grub to use the new boot device
grub-install /dev/sda
grub-install /dev/sdb
echo '# customizations' >> /etc/default/grub  
echo 'GRUB_PRELOAD_MODULES="raid dmraid"' >> /etc/default/grub  
update-grub
update-initramfs -u

echo add sda2 to md0
sgdisk -t 2:fd00 /dev/sda
sleep 1
mdadm --add /dev/md0 /dev/sda2

echo monitor the raid rebuild process
ISBUILDING=`grep '=' /proc/mdstat|wc -l`
while [ $ISBUILDING -ne 0 ]; do
  clear
  echo "waiting for raid rebuild to finish before continuing, please stand by..."
  cat /proc/mdstat
  sleep 1
  ISBUILDING=`grep '=' /proc/mdstat|wc -l`
done

echo move pve lvm to /dev/md1
pvcreate /dev/md1
vgextend pve /dev/md1
pvmove /dev/sda3 /dev/md1
vgreduce pve /dev/sda3
pvremove /dev/sda3
sgdisk -t 3:fd00 /dev/sda
mdadm --add /dev/md1 /dev/sda3

echo make the raid rebuild go faster
echo 800000 > /proc/sys/dev/raid/speed_limit_min;
echo 1600000 > /proc/sys/dev/raid/speed_limit_max;

echo monitor the raid rebuild process
ISBUILDING=`grep '=' /proc/mdstat|wc -l`
while [ $ISBUILDING -ne 0 ]; do
  clear
  echo "waiting for raid rebuild to finish before rebooting, please stand by..."
  cat /proc/mdstat
  sleep 1
  ISBUILDING=`grep '=' /proc/mdstat|wc -l`
done

echo reboot
reboot