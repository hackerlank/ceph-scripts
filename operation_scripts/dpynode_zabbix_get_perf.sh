#!/bin/bash
#
# usage:        zabbix call this scripts  
#               catch osd's latency
# parms:        (osd-id), ("commit" or "apply")
# date:         2015-07-22
# author:       Yy
##########################################################
if [ $# != "2" ];then
        echo 'err! args must be 2'
        exit 1
fi

perfFile="/root/ceph-perf.txt"


if [ ! -f "$perfFile" ];then
        ceph osd perf > $perfFile
        echo "the file is not exist,touch /root/ceph-perf.txt"
fi


if [ $2 == "commit" ];then
        cat $perfFile |awk -v name=$1 '{if($1==name)print $2}'
else [ $2 == "apply" ]
        cat $perfFile |awk -v name=$1 '{if($1==name)print $3}'
fi
