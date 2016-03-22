#!/bin/bash
#use for ssd 479G part 
#
for P_disk in `/sbin/fdisk -l |grep 'Disk /dev/sd'|grep -v sda|grep 479|awk '{print substr($2,0,8)}'`;
do
/sbin/fdisk -u ${P_disk} <<EOF
n
l
314573120
+5G

n
l
325058944
+5G

n
l
335544768
+5G

n
l
346030592
+90G

n
l
534774336
+90G

n
l
723518080
+90G

w
EOF
/sbin/kpartx ${P_disk}
done
for P_disk in `/sbin/fdisk -l |grep 'Disk /dev/sd'|grep -v sda|grep 479|awk '{print substr($2,0,8)}'`;
do
/sbin/fdisk -l ${P_disk}
done
