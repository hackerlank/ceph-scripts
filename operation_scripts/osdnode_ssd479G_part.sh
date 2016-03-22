#!/bin/bash
#use for ssd 479G part 
#
for P_disk in `/sbin/fdisk -l |grep 'Disk /dev/sd'|grep -v sda|grep 479|awk '{print substr($2,0,8)}'`;
do
/sbin/fdisk -u ${P_disk} <<EOF
n
e
1
64


n
l
128
+50G

n
l
104857792
+50G

n
l
209715456
+50G

w
EOF
done
for P_disk in `/sbin/fdisk -l |grep 'Disk /dev/sd'|grep -v sda|grep 479|awk '{print substr($2,0,8)}'`;
do
/sbin/fdisk -l ${P_disk}
done
