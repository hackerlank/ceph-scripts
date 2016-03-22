#!/usr/bin/python

import os
import json

os.popen('mkdir -p data')
os.popen('ceph report > data/ceph.report')



IN_FILE = 'data/ceph.report'
OUT_FILE = 'data/detail.all'


with open(IN_FILE) as file:
    data = json.load(file)

osdmap = data.get("osdmap")
pgmap = data.get("pgmap")
osd_list = osdmap.get("osds")
#pg_stats_sum = pgmap.get("pg_stats_sum")
pg_list = pgmap.get("pg_stats")

#get all data
osd_data = {}
for osd in osd_list:
    osd_data[osd.get('osd')]={'pg_num':0, 'object_num':0}
for pg in pg_list:
    pg_in_osds = pg.get('acting')
    object_num = pg.get('stat_sum').get('num_objects')
    for pg_in_osd in pg_in_osds:
        osd_data[pg_in_osd]['pg_num'] += 1
        osd_data[pg_in_osd]['object_num'] += object_num

#print osd_data

#write osd,pg_num,obj_num to out_file
osd_Ks = list(osd_data.keys())
osd_Ks.sort()

with open(OUT_FILE, 'w') as out_file:
    out_file.write("osd\tpg_num\tobject_num\n")
    for key in osd_Ks:
        osd_num = key
        pg_num = osd_data[key]['pg_num']
        obj_num = osd_data[key]['object_num']
        item = "%s\t%s\t%s\n" %(osd_num, pg_num, obj_num)
        out_file.write(item)

#get crush map
crushmap = data.get("crushmap")
devices = crushmap.get("devices")
osd_map = {}
for device in devices:
    osd_map[device['id']]=device['name'][4:]

rack_dic = {}
host_dic = {}
bucket_list = crushmap.get("buckets")

bucket_map = {}
for bucket in bucket_list:
    bucket_map[bucket["id"]] = bucket["name"]


for bucket in bucket_list:
    if bucket.get("type_name") == 'host':
        host_dic[bucket['name']] = []
        items = bucket.get("items")
        for item in items:
            host_dic[bucket['name']].append(item["id"])

for bucket in bucket_list:
    if bucket.get("type_name") == 'rack':
        rack_dic[bucket['name']] = []
        items = bucket.get("items")
        for item in items:
            item_id = item["id"];
            hostname = bucket_map[item_id]
            #rack_dic[bucket['name']].append(host_dic[hostname])
            rack_dic[bucket['name']].append(hostname)
#print host_dic
#print rack_dic

# write  host,pg_num,obj_num to out_file
# write  rack,pg_num,obj_num to out_file
host_data = {}
rack_data = {}
with open(OUT_FILE, 'a') as out_file:
    out_file.write("\n\n\n")
    out_file.write("host\tpg_num\tobject_num\n")
    host_Ks = list(host_dic.keys())
    host_Ks.sort()
    for host_key in host_Ks:
        host_osd_list = host_dic[host_key]
        host_pg_num = 0
        host_object_num = 0
        for host_osd in host_osd_list:
            host_pg_num += osd_data[host_osd]['pg_num']
            host_object_num += osd_data[host_osd]['object_num']
        host_data[host_key] = {'pg_num' : host_pg_num, 'object_num' : host_object_num }
        item = "%s\t%s\t%s\n" % (host_key, host_pg_num, host_object_num)
        out_file.write(item)

    out_file.write("\n\n\n")
    out_file.write("rack\tpg_num\tobject_num\n")
    rack_Ks = list(rack_dic.keys())
    rack_Ks.sort()
    for rack_key in rack_Ks:
        rack_host_list = rack_dic[rack_key]
        rack_pg_num = 0
        rack_object_num =0
        for rack_host in rack_host_list:
            rack_pg_num += host_data[rack_host]['pg_num']
            rack_object_num += host_data[rack_host]['object_num']
        rack_data[rack_key] = {'pg_num': rack_pg_num, 'object_num' : rack_object_num }
        item = "%s\t%s\t%s\n" % (rack_key, rack_pg_num, rack_object_num)
        out_file.write(item)

#print host_data
#print rack_data


#file.close()
#out_file.close()
 
cmd1 = r"""cat %s |  grep -v Cloud | grep -v pg_num | grep -v F | grep -v "^$"  > data/detail.osd""" % OUT_FILE
os.popen(cmd1)
cmd2 = r"""cat %s |  grep Cloud |  grep -v "^$"  >  data/detail.host""" % OUT_FILE
os.popen(cmd2)
cmd3 = r"""cat %s |  grep -v Cloud |  egrep ^D\|^M | grep -v "^$"  >  data/detail.rack""" % OUT_FILE 
os.popen(cmd3)

