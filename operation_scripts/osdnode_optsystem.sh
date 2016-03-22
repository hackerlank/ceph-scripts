#!/bin/bash
#optimize memery parms
echo 0 > /proc/sys/vm/swappiness
echo 50 > /proc/sys/vm/vfs_cache_pressure
echo "set swappiness to 0 success"
echo "set vfs_cache_pressure to 50 success"

#optimize block scheduler algorithm and increase read throughput 
#echo "noop" > /sys/block/sdz/queue/scheduler
#echo "deadline " > /sys/block/sdz/queue/scheduler
#echo "8192" > /sys/block/sdz/queue/read_ahread_kb

sata_4T_num=`/sbin/fdisk -l | grep 'Disk /dev/sd'| grep -v sda | grep 4000.0 | wc -l`
sata_1T_type1_num=`/sbin/fdisk -l | grep 'Disk /dev/sd'| grep -v sda | grep 999.7 | wc -l`
sata_1T_type2_num=`/sbin/fdisk -l | grep 'Disk /dev/sd'| grep -v sda | grep 999.0 | wc -l`
if [ ${sata_4T_num} -eq 9 ];then
	sata_list=`/sbin/fdisk -l | grep 'Disk /dev/sd'| grep -v sda | grep 4000.0 | \
                  awk '{print substr($2,0,8)}' | awk -F\/ '{print $3}'`
	ssd_list=`/sbin/fdisk -l | grep 'Disk /dev/sd'| grep -v sda | grep 479.0 | \
                 awk '{print substr($2,0,8)}' | awk -F\/ '{print $3}'`
elif [ ${sata_1T_type1_num} -eq 20 ];then
	sata_list=`/sbin/fdisk -l | grep 'Disk /dev/sd'| grep -v sda | grep 999.7 | \
                  awk '{print substr($2,0,8)}' | awk -F\/ '{print $3}'`
	ssd_list=`/sbin/fdisk -l | grep 'Disk /dev/sd'| grep -v sda | grep 299.4 | \
                 awk '{print substr($2,0,8)}' | awk -F\/ '{print $3}'`
elif [ ${sata_1T_type2_num} -eq 20 ];then
        sata_list=`/sbin/fdisk -l | grep 'Disk /dev/sd'| grep -v sda | grep 999.0 | \
                  awk '{print substr($2,0,8)}' | awk -F\/ '{print $3}'`
        ssd_list=`/sbin/fdisk -l | grep 'Disk /dev/sd'| grep -v sda | grep 299.0 | \
                 awk '{print substr($2,0,8)}' | awk -F\/ '{print $3}'`
else
	exit 0
fi

for i in $sata_list;do
	echo 'deadline' > /sys/block/$i/queue/scheduler        
 	echo '8192' > /sys/block/$i/queue/read_ahead_kb
	echo "optimize sata block device $i success"
done
for j in $ssd_list;do
	echo 'noop' > /sys/block/$j/queue/scheduler        
 	echo '8192' > /sys/block/$j/queue/read_ahead_kb
	echo "optimize ssd block device $j success"
done

#set system daemon limit open file to 10240
echo '* soft nofile 10240' >> /etc/security/limits.conf
echo '* hard nofile 10240' >> /etc/security/limits.conf
echo '* soft nproc 10240' >> /etc/security/limits.conf  
echo '* hard nproc 10240' >> /etc/security/limits.conf
echo "optimize system limit to 10240 success"

#set osd deamon bind cpu core
#cpu_num=`cat /proc/cpuinfo | grep processor | wc -l`
#osd_num=`ls /var/lib/ceph/osd/| wc -l`
#if [ ${cpu_num} -ge ${osd_num} ];then
#	index=0
#	for i in `ls /var/lib/ceph/osd/|awk -F\- '{print $NF}'`;do 
#		echo "set osd.$i on cpu.$index"
#		echo "taskset -c $index /etc/init.d/ceph restart osd.${i}"
#		let index+=1
#		sleep 5
#	done
		
#else
#	index=0
#	for i in `ls /var/lib/ceph/osd/|awk -F\- '{print $NF}'`;do
#		if [ ${index} -eq $cpu_num ];then
#  		      index=0
#		fi
#		echo "set osd.$i on cpu.$index"
#               echo "taskset -c $index /etc/init.d/ceph restart osd.${i}"
#               let index+=1
#               sleep 5
#        done
#
#fi
