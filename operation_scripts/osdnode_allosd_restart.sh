#!/bin/bash

for id in `ls /var/lib/ceph/osd/|awk -F\- '{print $NF}'`;do
        echo "restart osd.$id start..."
        /etc/init.d/ceph restart osd.$id
        sleep 3s
        ceph_stat=`ceph -s | grep health | awk '{print $2}'`
        while [[ $ceph_stat != 'HEALTH_OK' ]]
        do
                echo "waiting for restart osd.$id"
                sleep 3s
                ceph_stat=`ceph -s | grep health | awk '{print $2}'`
        done
        echo "restart osd.$id done!!!"

done
