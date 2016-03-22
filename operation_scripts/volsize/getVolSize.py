#!/usr/bin/python
import os
import sys

if len(sys.argv)<3:
    print('Pls input argument task_total and task_index.')
    sys.exit(1)

task_total = int(sys.argv[1])
task_index = int(sys.argv[2])


file_name = '/tmp/volsize/volResult.part%s' %task_index
rbd_pool = 'volumes'

os.popen('mkdir -p /tmp/volsize')

result = os.popen('rbd ls -p %s | grep "volume-" | wc -l' % rbd_pool)
vol_total = int(result.read())
result = os.popen('rbd ls -p %s | grep "volume-"' % rbd_pool)
vol_list = result.read().split('\n')
vol_list = vol_list[:-1]

task_num = (vol_total + task_total) / task_total
task_first  = 1 + task_num * (task_index - 1)
task_last = task_first + task_num


with open(file_name, 'w') as file:
    index = 1
    for vol in vol_list:
        if index > task_first-1 and index < task_last:
            cmd = r"""rbd diff %s/%s | awk '{ SUM += $2 } END { print SUM/1024/1024 " MB" }'""" % (rbd_pool, vol)
            vol_size = os.popen(cmd).read().split('\n')[0]
            item = str(index) + '\t' + vol + '\t'+ vol_size + '\n'
        else:
            item = str(index) + '\t' + vol + '\t'+ '\n'
        index = index + 1
        file.write(item)
        print item

