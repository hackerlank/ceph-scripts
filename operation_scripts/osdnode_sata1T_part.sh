#!/bin/bash
#
#
for P_disk in `/sbin/fdisk -l |grep 'Disk /dev/sd'|grep -v sda|grep 999|awk '{print substr($2,0,8)}'`;
do
#echo $P_disk
/sbin/fdisk ${P_disk} <<EOF
n
p
1


w
EOF
done

for P_disk in `/sbin/fdisk -l |grep 'Disk /dev/sd'|grep -v sda|grep 999|awk '{print substr($2,0,8)}'`;
do
/sbin/fdisk -l ${P_disk}
done

