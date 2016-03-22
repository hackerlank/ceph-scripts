#!/bin/bash
# usage :       perpare ceph cluster for openstack 
#               before use this ensure host can visit ceph cluster
#  
# description:  1. create pool for openstack
#               2. create pool's auth  
#               3. create new crush map 
#               4. create new crush rule and set pool to this rule 
#               5. move osd to new crush map
#
# warning:      Please use this scripts in new cluster 
#               which created by ceph_deployment_script.sh 
#               and not do anything 
##########################################################################

##########################################################################
#
# Global variable define from here
#
##########################################################################
DATA_CENTER=`hostname | awk -F \- '{print $1}'`
CRUSH_ROOT=$DATA_CENTER-sata
CRUSH_RULESET_NAME=$CRUSH_ROOT

##############################################################################
#
# Program for print log
#
##############################################################################
function print_single()
{
    echo ----------$*----------
}

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

function print_error()
{
    echo !!!!!!!!!!!$*!!!!!!!!!!!!
}

##############################################################################
#
# Program for check excute cmd result 
#
##############################################################################
function check_cmd_result()
{
    if [ $1 -ne 0 ]; then
        print_error "Something Error! Install Failed"
        exit 1
    fi
}

##############################################################################
#
# Ceph dead work for openstack program from here
#
##############################################################################
function check_auth()
{
    print_section "Begin check auth can visit cluster"
    ceph -s
    if [ $? -ne 0 ]; then
        print_error "We cannot visit ceph cluster, please check \
/etc/ceph/ceph.conf"
        exit 1
    fi
}

function backups()
{
    print_section "Begin backups ceph crush map"
    ceph osd getcrushmap -o /tmp/crushmap
    check_cmd_result $?
}

function Step1()
{
    print_section "Begin Step1: create pool for openstack"

    ceph osd pool create volumes 1024
    check_cmd_result $?
    print_single "create pool volumes success!"

    ceph osd pool create images 1024
    check_cmd_result $?
    print_single "create pool images success!"
}


function Step2()
{
    print_section "Begin Step2: create pool's auth"

    ceph auth get-or-create client.cinder mon 'allow r' osd 'allow \
class-read object_prefix rbd_children, allow rwx pool=volumes, \
allow rwx pool=images'
    check_cmd_result $?
    print_single "create cinder client auth success!"

    ceph auth get-or-create client.glance mon 'allow r' osd 'allow \
class-read object_prefix rbd_children, allow rwx pool=images'
    check_cmd_result $?
    print_single "create glance client auth success!"
}


function Step3()
{
    print_section "Begin Step3: create new crush map"

    #DATA_CENTER=`hostname | awk -F \- '{print $1}'`
    #CRUSH_ROOT=$DATA_CENTER-sata

    ceph osd crush add-bucket  $CRUSH_ROOT root
    check_cmd_result $?
    print_single "add root-bucket $CRUSH_ROOT success!"

    for host_name in `ceph osd tree | grep host | awk '{print $4}'` ; do 
        rack_name=`echo $host_name | awk -F \- '{print $2}'`;
        ceph osd crush add-bucket  ${rack_name}-sata rack;
        check_cmd_result $?
        print_single "add rack-bucket ${rack_name}-sata success!"
    
        ceph osd crush move ${rack_name}-sata root=$CRUSH_ROOT; 
        check_cmd_result $?
        print_single "move rack-bucket ${rack_name}-sata to root success!"

        ceph osd crush add-bucket ${host_name}-sata host;
        check_cmd_result $?
        print_single "add host-bucket ${host_name}-sata success!"
    
        ceph osd crush move ${host_name}-sata rack=${rack_name}-sata;
        check_cmd_result $?
        print_single "move host-bucket ${host_name}-sata to \
${rack_name}-sata success!"
    done
}


function Step4()
{
    print_section "Begin Step4: create new crush rule and set pool \
to this rule"

    #CRUSH_RULESET_NAME=$CRUSH_ROOT

    ceph osd crush rule create-simple $CRUSH_RULESET_NAME $CRUSH_ROOT rack 
    check_cmd_result $?
    print_single "create crush_rule $CRUSH_RULESET_NAME success!"

    crush_rule_id=`ceph osd crush rule dump $CRUSH_RULESET_NAME | \
awk 'NR==1{print $0}' | awk '{print $3}'|awk -F\, '{print $1}'`

    ceph osd pool set images crush_ruleset  $crush_rule_id
    check_cmd_result $?
    print_single "set pool images use rule $CRUSH_RULESET_NAME success!"

    ceph osd pool set volumes crush_ruleset  $crush_rule_id
    check_cmd_result $?
    print_single "set pool volumes use rule $CRUSH_RULESET_NAME success!"

    ceph osd pool set rbd crush_ruleset  $crush_rule_id
    check_cmd_result $?
    print_single "set pool rbd use rule $CRUSH_RULESET_NAME success!"
}

function Step5()
{
    print_section "Begin Step5: move osd to new crush map"

    default_line=`ceph osd tree| awk '{print  $3,$4}' | \
awk '{for (i=1;i<=NF;i++) if (match($i,/default/)) print NR}' `
    check_cmd_result $?
    print_single "line=$default_line"

    temp1=`ceph osd tree| awk '{print  $3,$4}' | \
awk -v begin_num=$default_line 'NR>begin_num {print $0}'`
    check_cmd_result $?
    print_single "temp1=$temp1"

    temp2=`echo $temp1 |sed 's/up//g' | sed 's/down//g' `
    check_cmd_result $?
    print_single "temp2=$temp2"

    Num=`echo $temp2 | awk -F 'host' '{print NF}'`
    check_cmd_result $?
    print_single "Num=$Num"

    for ((i=$Num-2;i>=0;i--));do 
        unit=`echo $temp2 | awk -v num=$i -F 'host' '{print $(NF-num)}'`; 
        check_cmd_result $?
        print_single "unit=$unit"

        host_temp=`echo $unit | awk '{print $1}'`;
        check_cmd_result $?
        print_single "host_temp=$host_temp"; 

        osd_set=`echo $unit | awk '{for (i=2;i<=NF;i++) print $i}'`
        check_cmd_result $?
        print_single "osd_set=$osd_set";

        for item in $osd_set;do
            ceph osd crush create-or-move $item 1 host=${host_temp}-sata;
            check_cmd_result $?
        done
    done
}


function excute()
{
    print_section "Begin Ceph dead work for openstack"
    check_auth 
    backups
    Step1
    Step2
    Step3
    Step4
    Step5
    print_section "Ceph dead work for openstack is Success!"
}


##########################################################################
#
# Recover if prepare fail programs from here
#
##########################################################################
function recover()
{
    print_section "Begin recover ceph cluster"
    ceph osd setcrushmap -i /tmp/crushmap
    check_cmd_result $?

    ceph osd pool delete volumes volumes --yes-i-really-really-mean-it
    check_cmd_result $?
    print_single "delete pool volumes success!"

    ceph osd pool delete images images --yes-i-really-really-mean-it
    check_cmd_result $?
    print_single "delete pool images success!"
    
    ceph osd pool set rbd crush_ruleset 0
    check_cmd_result $?
    print_single "reset rbd pool to default ruleset success!"

    ceph auth del client.cinder
    check_cmd_result $?
    print_single "delete client.cinder auth success!"
    
    ceph auth del client.glance
    check_cmd_result $?
    print_single "delete client.glance auth success!"

    print_section "recover ceph cluster Success!"
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
    echo "+./prepare_for_openstack.sh   excute           \
Prepare for openstack                          +"
    echo "+./prepare_for_openstack.sh   recover          \
Recover if you prepare fail                    +"
    echo "+----------------------------------------------\
-----------------------------------------------+"
    echo ""
}


##########################################################################
#
# Main program starts from here
#
##########################################################################

if [ $# -ne 1 ]; then 
    usage
    exit 1
fi
case $1 in
    "excute")
        excute 
        ;;
    "recover")
        recover 
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
