#!/usr/bin/python

import os

os.popen('mkdir -p data')

OUT_FILE = 'data/osd_df.result'
OUT_SORT_FILE = 'data/osd_df.sort'

cmd_get_host = r"""ceph osd tree | grep host | grep -v SSD | awk '{print $4}' | sort -k1 -n | uniq -c | awk '{print $2}'"""
host_list = os.popen(cmd_get_host).read().split('\n')[:-1]

with open(OUT_FILE, 'w') as file:
    for host in host_list:
        head = "---------------------------- hostname:  %s ----------------------------\n" % host
        file.write(head)
        cmd_df = r"""ssh %s df -h | grep osd""" % host
        osds_per_host = os.popen(cmd_df).read().split('\n')[:-1]
        for osd_df in osds_per_host:
            item = osd_df + "\t" + host + "\n"
            #print item
            file.write(item)

cmd_sort_osd_df = r"""cat %s | grep -v hostname | sort -k5 -n  > %s""" % (OUT_FILE, OUT_SORT_FILE)
os.popen(cmd_sort_osd_df)
