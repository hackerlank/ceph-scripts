#!/bin/bash
#
# usage:        write osd latency to /root/ceph-perf.txt, 
#               take it to crontab for per-1min
#               this file service for zabbix  
# parms:        noop
# date:         2015-07-22
# author:       Yy
########################################################## 
ceph osd perf > /root/ceph-perf.txt
