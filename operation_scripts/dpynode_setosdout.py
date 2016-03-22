#!/usr/bin/python
#-*- coding: utf-8 -*-


import os
import time


def getCephStatus(str):
    cephstatus = str.split('\n')
    for part in cephstatus:
        part_status = part.split()
        if part_status[0] == 'health':
            status = part_status[1]
            break
    return status


def run(osds):
    for osd in osds:
        output = os.popen('ceph osd in %s'%osd)
        print output.read()
        status = ''
        while status != 'HEALTH_OK':
            time.sleep(5)
            output = os.popen('ceph -s')
            out = output.read()
            status = getCephStatus(out)
            print out



if __name__ == '__main__':
    osds = ['23', '29', '34', '39', '44', '49', '54', '59', '64', '69', '74', '79', '84', '89', '94', '99', '104', '109', '114', '11
9']
    run(osds)
