#!/bin/bash
for host in `cat host_list`; do ssh -t $host 'top -n 1 | grep ceph-';done
#for host in `cat host_list`; do ssh -t $host 'ps aux | grep ceph- | grep -v grep';done
