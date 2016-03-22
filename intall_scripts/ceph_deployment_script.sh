#!/bin/bash
# usage : scripts for install new ceph cluster
#  
# prepare: 1. all node must ssh by ssh-key
#          2. all node need installed ceph 
#          3. all node need xfs module in system 
#          4. all osd node need partion your block device
#
# operation: a. modify the config file
#            b. use this scripts 
##########################################################################

##########################################################################
#
# Global variable define from here
#
##########################################################################
CEPH_MON_HOSTS=''
CEPH_OSD_HOSTS=''
CEPH_PUBLIC_NETWORK=''

declare -A CEPH_OSD_HOSTS_PATH_SET

##########################################################################
#
# Program for print log
#
##########################################################################
function print_section()
{
    echo "=====================================\
===============================================\
====================="
    echo $*
    echo "=====================================\
===============================================\
====================="
}

function print_single()
{
    echo -----$*-----
}

function print_error()
{
    echo !!!!!!!!!!!$*!!!!!!!!!!!!
}

##########################################################################
#
# Program for check excute cmd result 
#
##########################################################################
function check_cmd_result()
{
    if [ $1 -ne 0 ]; then
        print_error "Something Error! Install Failed"
        exit 1
    fi
}

##########################################################################
#
# Install new ceph cluster programs from here
#
##########################################################################

function install_osd()
{
    osd_host=$1
    osd_device_path_set=${CEPH_OSD_HOSTS_PATH_SET[$osd_host]}
 
    print_section "install_osd on host $osd_host"
 
    for osd_path in $osd_device_path;do
        print_single "install osd_path $osd_path"

        ceph-deploy osd prepare $osd_host:$osd_path
        check_cmd_result $?

        ceph-deploy osd activate $osd_host:$osd_path
        check_cmd_result $?
    done  
}

function tuning_ceph_conf()
{
    print_single "tuning_ceph_conf"

    echo """mon_osd_full_ratio = .85
mon_osd_nearfull_ratio = .75

[osd]
osd_journal_size = 50000
osd_mkfs_type = xfs
osd_mkfs_options_xfs = -f
filestore_min_sync_interval = 10
filestore_max_sync_interval = 20
filestore_queue_max_ops = 25000
filestore_queue_max_bytes = 1048576000
filestore_queue_committing_max_ops = 5000
filestore_queue_committing_max_bytes = 1048576000
filestore_op_threads = 4
filestore_max_inline_xattr_size = 254
filestore_max_inline_xattrs = 6
journal_max_write_bytes = 1048576000
journal_max_write_entries = 10000
journal_queue_max_ops = 50000
journal_queue_max_bytes = 1048576000
ms_dispatch_throttle_bytes = 1048576000
objecter_inflight_op_bytes = 1048576000
objecter_inflight_ops = 10240
osd_max_write_size = 512
osd_client_message_size_cap = 2147483648
osd_deep_scrub_stride = 131072
osd_op_threads = 16
osd_disk_threads = 1
osd_map_cache_size = 1024
osd_map_cache_bl_size = 128
osd_mount_options_xfs = \"rw,noexec,nodev,noatime,nodiratime,nobarrier\"
osd_recovery_op_priority = 4
osd_recovery_max_active = 10
osd_max_backfills = 4
filestore_journal_writeahead = true
filestore_merge_threshold = 40
filestore_split_multiple = 8

[client]
rbd_cache = true
rbd_cache_writethrough_until_flush = false
rbd_cache_size = 67108864
rbd_cache_max_dirty = 50331648
rbd_cache_target_dirty = 33554432

[client.cinder]
admin_socket = /var/run/ceph/rbd-\$pid.asok""" >> ceph.conf

    check_cmd_result $?
}

function install_and_config_monitor_cluster()
{
    print_section "install_and_config_monitor_cluster"

    print_single "ceph-deploy new $CEPH_MON_HOSTS"
    ceph-deploy new $CEPH_MON_HOSTS
    check_cmd_result $?

    #print_single "modify osd pool size to 2 in ceph.conf "
    #echo 'osd pool default size = 2' >> ceph.conf
    #check_cmd_result $?
 
    print_single "modify public network:$CEPH_MON_HOSTS in ceph.conf"
    echo "public network = $CEPH_PUBLIC_NETWORK" >> ceph.conf 
    check_cmd_result $?
    
    tuning_ceph_conf

    print_single "ceph-deploy mon create-initial"
    ceph-deploy mon create-initial
    check_cmd_result $?
}

function install_and_config_osd_cluster()
{
    print_section "install_and_config_osd_cluster"
    for osd_host in $CEPH_OSD_HOSTS;do
        install_osd $osd_host
    done
}

function install_ceph_deploy()
{
    print_section "install_ceph_deploy"

    yum install -y ceph-deploy 
    check_cmd_result $?
    
    rm -fr ceph-cluster
    check_cmd_result $?

    mkdir ceph-cluster
    check_cmd_result $?

    cd ceph-cluster
    check_cmd_result $?
}

function fix_ceph_repo()
{
    hostname=$1
    print_single "fix_ceph_repo on host $hostname" 
    ssh $hostname  "yum -y reinstall yum-priorities;grep -q \
'check_obsoletes' /etc/yum/pluginconf.d/priorities.conf || \
sed -i '\$acheck_obsoletes=1' /etc/yum/pluginconf.d/priorities.conf"

}

function install_ceph_package()
{
    print_section "install_ceph_package"
    for mon_host in $CEPH_MON_HOSTS;do
        fix_ceph_repo $mon_host
        ssh $mon_host "yum install -y ceph"
        check_cmd_result $?
    done
    for osd_host in $CEPH_OSD_HOSTS;do
        fix_ceph_repo $osd_host
        ssh $osd_host "yum install -y ceph"
        check_cmd_result $?
    done
}

function parse_get_osd_device_by_host()
{
    print_single "parse_get_osd_device_by_host"

    conf_file=$1
    osd_host=$2

    begin_num=`awk -F:  '{v="";for (i=1;i<=NF;i++)  \
if (match($i,/osdNodeBegin.'$osd_host'/)) \
v=v?"":i;if (v) print NR}' $conf_file `
    check_cmd_result $?

    end_num=`awk -F:   '{v="";for (i=1;i<=NF;i++)  \
if (match($i,/osdNodeEnd.'$osd_host'/)) \
v=v?"":i;if (v) print NR}' $conf_file `
    check_cmd_result $?

    osd_device_path=`awk -vnum1=$begin_num -vnum2=$end_num \
'NR>num1 && NR<num2 {print $0}' $conf_file `
    check_cmd_result $?

    CEPH_OSD_HOSTS_PATH_SET[$osd_host]=$osd_device_path

    print_single "parse osd_host name is $osd_host"
    print_single "the path set is $osd_device_path"
}

function parse_get_all_osd_device()
{
    print_single "parse_get_all_osd_device"

    conf_file=$1

    for osd_host in $CEPH_OSD_HOSTS;do
        parse_get_osd_device_by_host $conf_file $osd_host
    done
}

function parse_get_osd_host()
{
    print_single "parse_get_osd_host"

    conf_file=$1

    osd_hosts_raw=`awk -F: '/cluster_osd_host/ {print $0}' \
$conf_file | awk -F\= '{print $2}'`
    check_cmd_result $?

    CEPH_OSD_HOSTS=`echo $osd_hosts_raw |awk  '{gsub(","," ");print $0}'`
    check_cmd_result $?

    print_single $CEPH_OSD_HOSTS 
}


function parse_get_network()
{
    print_single "parse_get_network"

    conf_file=$1

    CEPH_PUBLIC_NETWORK=`awk -F: '/cluster_network_mask/ {print $0}' \
$conf_file | awk -F\= '{print $2}'`
    check_cmd_result $?

    print_single $CEPH_PUBLIC_NETWORK
}


function parse_get_mon_host()
{
    print_single "parse_get_mon_host"

    conf_file=$1

    mon_hosts_raw=`awk -F: '/cluster_mon_host/ {print $0}' \
$conf_file | awk -F\= '{print $2}'`
    check_cmd_result $?

    CEPH_MON_HOSTS=`echo $mon_hosts_raw | awk  '{gsub(","," ");print $0}'`
    check_cmd_result $?

    print_single $CEPH_MON_HOSTS 
}

function parse_config()
{
    print_section "parse_config $conf_file"    

    conf_file=$1

    parse_get_mon_host $conf_file
    parse_get_network $conf_file
    parse_get_osd_host $conf_file
    parse_get_all_osd_device $conf_file
}

function install_new_cluster()
{
    print_section "install_new_cluster"

    conf_file=$1
    if [ -f "$conf_file" ]; then 
        parse_config $conf_file
    else
        print_error "Can't find config file $conf_file"
        exit 1
    fi

    install_ceph_deploy 
    install_ceph_package
    install_and_config_monitor_cluster
    install_and_config_osd_cluster
    
    print_section "install_new_cluster Success!! "
}

##########################################################################
#
# Clean fail ceph cluster programs from here
#
##########################################################################
function stop_all_process()
{
    print_single "stop_all_process"
    for mon_host in $CEPH_MON_HOSTS;do
        ssh $mon_host "/etc/init.d/ceph stop mon"
    done
    for osd_host in $CEPH_OSD_HOSTS;do
        ssh $osd_host "/etc/init.d/ceph stop osd"
    done
}

function umount_osd_device()
{
    osd_host=$1
    osd_device_path_set=${CEPH_OSD_HOSTS_PATH_SET[$osd_host]}
 
    print_section "umount_osd_device on host $osd_host"

    for osd_path in $osd_device_path;do
        print_single "umount osd_path $osd_path"
        umount_path=`echo $osd_path | awk -F : '{print $1}'` 
        ssh $osd_host "umount $umount_path"
    done  

}

function umount_all_osd_cluster()
{
    print_single "umount_all_osd_cluster"
    for osd_host in $CEPH_OSD_HOSTS;do
        umount_osd_device $osd_host
    done
}

function clean_all_ceph_files()
{
    print_single "clean_all_ceph_files"
    for mon_host in $CEPH_MON_HOSTS;do
        ssh $mon_host "rm -fr /etc/ceph"
        ssh $mon_host "rm -fr /var/log/ceph"
        ssh $mon_host "rm -fr /var/lib/ceph"
        ssh $mon_host "rm -fr /var/run/ceph"
    done
    for osd_host in $CEPH_OSD_HOSTS;do
        ssh $osd_host "rm -fr /etc/ceph"
        ssh $osd_host "rm -fr /var/log/ceph"
        ssh $osd_host "rm -fr /var/lib/ceph"
        ssh $osd_host "rm -fr /var/run/ceph"
    done
}

function remove_all_package()
{
    print_single "remove_all_package"
    for mon_host in $CEPH_MON_HOSTS;do
        ssh $mon_host "yum remove -y ceph ceph-common \
libcephfs1 librados2 librbd1 python-ceph"
    done
    for osd_host in $CEPH_OSD_HOSTS;do
        ssh $osd_host "yum remove -y ceph ceph-common \
libcephfs1 librados2 librbd1 python-ceph"
    done
}

function clean_fail_cluster()
{
    print_section "clean_fail_cluster"
    conf_file=$1
    if [ -f "$conf_file" ]; then 
        parse_config $conf_file
    else
        print_error "Can't find config file $conf_file"
        exit 1
    fi

    stop_all_process
    umount_all_osd_cluster
    clean_all_ceph_files
    remove_all_package
}
##########################################################################
#
# Usage program from here
#
##########################################################################
function usage()
{
    echo ""
    echo "+----------------------------------------------\
-----------------------------------------------+"
    echo "+./ceph_deployment_script   create-new-cluster \
 xxx.conf          Install new Ceph cluster    +"
    echo "+./ceph_deployment_script   clean-fail-cluster \
 xxx.conf          Clean fail Ceph cluster     +"
    echo "+----------------------------------------------\
-----------------------------------------------+"
    echo ""
}


##########################################################################
#
# Main program starts from here
#
##########################################################################

if [ $# -ne 2 ]; then 
    usage
    exit 1
fi
case $1 in
    "create-new-cluster")
        install_new_cluster $2
        ;;
    "clean-fail-cluster")
        clean_fail_cluster $2
        ;;
    "-h")
        usage
        ;;
    *)
        echo "Invalid Command options"
        exit 1
        ;;
esac

exit 0
