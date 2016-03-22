#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import paramiko
import traceback
import time
import sys 
import ConfigParser

YUM_REPO_LOCAL = 'ztrcloud-openstack-ceph.repo'
YUM_REPO_REMOTE = '/etc/yum.repos.d/'+ YUM_REPO_LOCAL

UPDATE_LOG = 'update.log'
HOST_CONFIG = 'host.conf'


global global_mon_list, global_osd_list, global_client_list
global_mon_list = []
global_osd_list = []
global_client_list = []

def loadConfig(host_conf):
    config = ConfigParser.ConfigParser()
    config.read(host_conf)
    str_mon = config.get('config', 'mon')
    str_osd = config.get('config', 'osd')
    str_client = config.get('config', 'client')
    mon_list = str_mon.split(',')
    osd_list = str_osd.split(',')
    client_list = str_client.split(',')
    print ("Ceph mon is %s" %mon_list)
    print ("Ceph osd is %s" %osd_list)
    print ("Ceph client is %s" %client_list)
    return mon_list, osd_list, client_list


def newSSHClient(hostname):
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(hostname, username='root')
    except Exception as e:
        print e 
        exit()
    return client

def destroySSHClient(client):
    client.close()
    return

def execCommand(client, command):
    try:
        stdin, stdout, stderr = client.exec_command(command)
        out = str(stdout.read())
	print out
    except Exception as e:
        print e
        exit()
    return out

def pushConfigToNode(hostname):
    try:
        client = newSSHClient(hostname)
        sftp = client.open_sftp()
        sftp.put(YUM_REPO_LOCAL, YUM_REPO_REMOTE)
        sftp.close()
        command = 'yum -y install yum-priorities'
        execCommand(client, command)
        destroySSHClient(client)
        print ('push yum repo to host %s Success ' %hostname)
    except Exception as e:
        print e
        exit()
    return

def reinstallNode(hostname):
    try:
        client = newSSHClient(hostname)
        command = 'yum -y update ceph'
        execCommand(client, command)
        destroySSHClient(client)
        print ('yum update ceph Success on host %s' %hostname)
    except Exception as e:
        print e
        exit()
    return

def getCephStatus(str):
    cephstatus = str.split('\n')
    for part in cephstatus:
        part_status = part.split()
        if part_status[0] == 'health':
            status = part_status[1]
            break
    return status

def rebootMon(hostname):
    try:
        client = newSSHClient(hostname)
        command = '/etc/init.d/ceph restart mon.' + hostname
        execCommand(client, command)
        #status = ''
        #while status != 'HEALTH_OK':
        #    time.sleep(5)
        #    command = 'ceph -s'
        #    out = execCommand(client, command)
        #    status = getCephStatus(out)
        destroySSHClient(client)
        print ('reboot mon.%s Success' %hostname)
    except Exception as e:
        print e
        exit()
    return 

def getOneNodeOSD(client): 
    command = 'ls /var/lib/ceph/osd'
    out = execCommand(client, command)
    out_temp = ''.join(out.split('\n'))
    rets = out_temp.split('ceph-')
    osds = []
    for ret in rets:
        if ret != '':
            osds.append(ret) 
    return osds

def rebootOneNodeOSD(hostname):
    client = newSSHClient(hostname)
    #command = 'ls /var/lib/ceph/osd'
    #out = execCommand(client, command)
    #out_temp = ''.join(out.split('\n'))
    #rets = out_temp.split('ceph-')
    #osds = []
    #for ret in rets:
    #    if ret != '':
    #        osds.append(ret) 
    osds = getOneNodeOSD(client)     
       
    for osd in osds:
        try:
            command = '/etc/init.d/ceph restart osd.' + osd
            execCommand(client, command)
            status = ''
            while status != 'HEALTH_OK':
                time.sleep(5)
                command = 'ceph -s'
                out = execCommand(client, command)
                status = getCephStatus(out)
            print ('reboot osd.%s Success' %osd)
        except Exception as e:
            print e
            exit()
    destroySSHClient(client)
    return
    
def rebootOSDs(hostname):
    try:
        rebootOneNodeOSD(hostname)
        print ('reboot all osds on host %s Success' %hostname)
    except Exception as e:
        print e
        exit()
    return

def updateMonitor(mon): 
    pushConfigToNode(mon)
    reinstallNode(mon)
    rebootMon(mon)
    return

def updateOSDs(osds):
    for hostname in osds:
        pushConfigToNode(hostname)
        reinstallNode(hostname)
        rebootOSDs(hostname)
    print ('reboot osds on %s Success!!!!' %hostname)
    return

def updateClients(clients):
    for hostname in clients:
        pushConfigToNode(hostname)
        reinstallNode(hostname)
    	print ('reinstall clients %s Success!!!'  %hostname)

def checkMon(hostname):
    print hostname + ":" 
    client = newSSHClient(hostname)
    command = 'ceph --admin-daemon /var/run/ceph/ceph-mon.' + hostname + '.asok version'
    out = execCommand(client, command)
    destroySSHClient(client)

def checkOSD(hostname):
    client = newSSHClient(hostname)
    osds = getOneNodeOSD(client)     
    for osd in osds:
        try:
            command = 'ceph --admin-daemon /var/run/ceph/ceph-osd.' + osd + '.asok version'
            out = execCommand(client, command)
        except Exception as e:
            print e
            exit
    destroySSHClient(client)
    return

def printUsage():
    print "Useage: update.py"
    print "    help                       :help "
    print "    exit                       :exit "
    print "    load                       :load the host config"
    print "    list                       :list the mons and osds"
    print "    mon-update                 :push repo, reinstall and reboot mon.x"
    print "    osd-update                 :update all osd in host.conf"
    print "    client-update              :update all client in host.conf"
    print "    osd-restart                :restart all osd in host.conf"
    print "    check                      :check all service's version"
    print "    command                    :command on some host"


def _exit():
    exit()

def _help():
    printUsage()

def _load():
    global global_mon_list, global_osd_list, global_client_list
    global_mon_list = []
    global_osd_list = []
    global_client_list = []
    global_mon_list, global_osd_list, global_client_list = loadConfig(HOST_CONFIG)

def _list():
    global global_mon_list, global_osd_list, global_client_list
    print ("mon: %s" %global_mon_list)
    print ("osd: %s" %global_osd_list)
    print ("client: %s" %global_client_list)
   
def _mon_update():
     print "we have mons: %s" %global_mon_list
     mon = raw_input(">>please input mon_id:")
     if mon not in global_mon_list:
         print ("mon.%s is not in host.conf!!")
         return
     print "start update mon: %s" %mon
     updateMonitor(mon)
    
def _osd_update():
    print "we have osds: %s" %global_osd_list
    print "start update all osds"
    updateOSDs(global_osd_list)

def _client_update():
    print "we have client: %s" %global_client_list
    print "start update all client"
    updateClients(global_client_list)


def _osd_restart():
    print "we have osds: %s" %global_osd_list
    print "start restart all osds"
    for hostname in global_osd_list:
        rebootOSDs(hostname)

def _check():
    print "we have mons: %s" %global_mon_list
    for mon in global_mon_list:
        checkMon(mon)
    print "we have osds: %s" %global_osd_list
    for hostname in global_osd_list:        
        checkOSD(hostname)

def _command():
    print "we have hosts: %s\n%s\n%s" %(global_mon_list,global_osd_list,global_client_list)
    hostname = raw_input("please input host:")
    command = raw_input("please input command:")
    print "exec command %s on host:%s" %(command,hostname)
    client = newSSHClient(hostname) 
    execCommand(client, command)
    destroySSHClient(client)
       

def run():
    paramiko.util.log_to_file(UPDATE_LOG)
    operator = {"help":_help, "exit":_exit, "load":_load, "list":_list, "mon-update":_mon_update, "osd-update":_osd_update, "client-update":_client_update, "osd-restart":_osd_restart, "check":_check, "command":_command}
    while True:
        cmd = raw_input(">>")
        if operator.has_key(cmd):
            operator.get(cmd)()
        else:
            print "unknow command, please input: help"


if __name__ == '__main__':
    run()
