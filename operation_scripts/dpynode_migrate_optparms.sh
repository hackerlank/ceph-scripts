#!/bin/bash
#
# usage:        when ceph data migrate,
#               optimize the ceph osd parms before
#               recover parms after
# parms:        before | after
# date:         2015-07-22
# author:       Yy
##########################################################


function fun_before()
{
	echo "----------optimize parms before ceph migrate----------"
	echo "ceph osd:"
	osd_list=`ceph osd ls`
	echo $osd_list
	echo "------------------------------------------------------"

	MAX_BACKFILL=1
	RECOVERY_THREAD=1
	RECOVERY_PRIORITY=1
	CLIENT_PRIORITY=63
	RECOVERY_ACTIVE=1 


	for id in ${osd_list};
	do
		echo "osd.$id"
		#ceph tell osd.$id injectargs "--osd-max-backfills $MAX_BACKFILL"
		#ceph tell osd.$id injectargs "--osd-recovery-threads $RECOVERY_THREAD"
		#ceph tell osd.$id injectargs "--osd-recovery-op-priority $RECOVERY_PRIORITY"
		#ceph tell osd.$id injectargs "--osd-client-op-priority $CLIENT_PRIORITY"
		#ceph tell osd.$id injectargs "--osd-recovery-max-active $RECOVERY_ACTIVE"
	done
}

function fun_after()
{
	echo "----------restore parms after ceph migrate----------"
        echo "ceph osd:"
        osd_list=`ceph osd ls`
        echo $osd_list
        echo "------------------------------------------------------"
	
	MAX_BACKFILL=4
        RECOVERY_THREAD=1
        RECOVERY_PRIORITY=10
        CLIENT_PRIORITY=63
        RECOVERY_ACTIVE=15


        for id in ${osd_list};
        do
                echo "osd.$id"
                #ceph tell osd.$id injectargs "--osd-max-backfills $MAX_BACKFILL"
                #ceph tell osd.$id injectargs "--osd-recovery-threads $RECOVERY_THREAD"
                #ceph tell osd.$id injectargs "--osd-recovery-op-priority $RECOVERY_PRIORITY"
                #ceph tell osd.$id injectargs "--osd-client-op-priority $CLIENT_PRIORITY"
                #ceph tell osd.$id injectargs "--osd-recovery-max-active $RECOVERY_ACTIVE"
        done
}

case "$1" in
    before)
        fun_before
        ;;
    after)
        fun_after
        ;;
    *)
        echo $"Usage: $0 {before|after}"
        exit 2
esac
exit $?
