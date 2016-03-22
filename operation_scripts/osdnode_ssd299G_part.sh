#!/bin/bash
#
#
for P_disk in `/sbin/fdisk -l |grep 'Disk /dev/sd'|grep -v sda|grep 299|awk '{print substr($2,0,8)}'`;
do
/sbin/fdisk -u ${P_disk} <<EOF
n
e
1
64

n
l
128
+55G

n
l
115343552
+55G

n
l
230686976
+55G

n
l
346030400
+55G

n
l
461373824

w
EOF
done
for P_disk in `/sbin/fdisk -l |grep 'Disk /dev/sd'|grep -v sda|grep 299|awk '{print substr($2,0,8)}'`;
do
/sbin/fdisk -l ${P_disk}
done
