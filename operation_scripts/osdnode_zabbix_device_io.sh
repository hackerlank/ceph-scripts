#!/bin/bash
#
# usage:        zabbix call this scripts  
#               catch block device io data
# parms:        (sdx), ("read" | "write" | "wait" | "util")
# date:         2015-07-22
# author:       Yy
##########################################################


if [ $# != "2" ];then
        echo 'err! args must be 2'
        exit 1
fi

block_device=$1
data_item=$2
if [ $data_item == "read" ];then
        iostat -xk 2 3 /dev/$block_device | grep $block_device | tail -1 | awk '{print $6}'
elif [ $data_item == "write" ];then
        iostat -xk 2 3 /dev/$block_device | grep $block_device | tail -1 | awk '{print $7}'
elif [ $data_item == "wait" ];then
        iostat -xk 2 3 /dev/$block_device | grep $block_device | tail -1 |awk '{print $10}'
elif [ $data_item == "util" ];then
        iostat -xk 2 3 /dev/$block_device | grep $block_device | tail -1 | awk '{print $12}'
fi
