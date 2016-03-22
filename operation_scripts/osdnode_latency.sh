#!/bin/bash
for ((i=1;i>0;i++));do ceph osd perf|awk '{if($2>50||$3>50)print $0}' ; sleep 3s;done
