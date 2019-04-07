#!/usr/bin/ksh

#########################################################
# 							#
#	Kaiser Permanente				#
#	date: 7/16/05					#
#	osup.ksh 					#
# 	version 1.03					#
#	Ryan Dang					#
#	Group NOPS ETS OSS ENGR				#
#							#
#########################################################
PARM_COUNT=$#

if [ $# -lt 1 ] || [ $# -gt 1 ]; then
	print ""
	print "usage: $0 [-c/-v]"
	print ""
	print "c for creation of snapshots"
	print "v for verification of system snapshots after migration"
	print ""
	print "Note:\t datafiles path is optional. The default path"
	print "\t will be the same location where the script runs."
	print "\t v and e option are not in this version."
	exit 1
fi

OPTION=$1
HERE=$(pwd)
EXCLUDE_FILE=$(pwd)/osup_fs.exl
if [ ! -f $EXCLUDE_FILE ]; then
	touch $EXCLUDE_FILE
	print "/dev" >> $EXCLUDE_FILE
	print "/misc" >> $EXCLUDE_FILE
	print "/usr" >> $EXCLUDE_FILE
fi
OSLEVEL=$(oslevel -r |cut -d"-" -f1)
DESTINATION=$2

# variables
function set_variables
{
	if [ "$DESTINATION" = "" ]; then
		LOG_DIR=$(hostname -s)
		if [ ! -d $LOG_DIR ]; then
        		mkdir -p $LOG_DIR
		fi
	else
		if [ ! -d $DESTINATION ]; then
			mkdir -p $DESTINATION
			LOG_DIR=$DESTINATION
		fi
	fi

	## GET KERNEL TYPE OF SYSTEM ##
	KERNEL_TYPE=$(bootinfo -K)
	HOSTNAME=$(hostname -s)
}

# Getting ALL Files and Directories Attributes
function get_mountpoint_from_LVFS
{
	print ""
	print "Capture all Files and Directories attributes"
	## Get mountpoint with Logical Volume : FROM function list_LSFS#
	LVFS_FILE=$1
	VG_NAME=$(basename $LVFS_FILE |cut -d. -f1)
	cat $LVFS_FILE |while true
	do
		read LVFS_LINE
		JFSLOG=$(echo $LVFS_LINE |grep N/A)
		if [ "$LVFS_LINE" = "" ]; then
			break
		fi
		if [ "$JFSLOG" = "" ]; then
			MOUNT_POINT=$(echo $LVFS_LINE |awk '{print $7}')
			print "$MOUNT_POINT"
			FS_NAME=$(basename $MOUNT_POINT)
			FS_FILE="$FS_NAME.$VG_NAME"
			FS_FILE_PATH=$LOG_DIR/$FS_FILE
			if [ ! -f $FS_FILE_PATH ]; then
				touch $FS_FILE_PATH
			else
				rm -f $FS_FILE_PATH
				touch $FS_FILE_PATH	
			fi
			ls -lAR $MOUNT_POINT >> $FS_FILE_PATH
		fi
	done
}

# List all LVFS files #
function list_LVFS
{
	# List the LVFS Files #
	ls -1A $LOG_DIR/*.LVFS |while true
	do
		read LVFS_FILE
		if [ "$LVFS_FILE" = "" ]; then
			break
		else
			get_mountpoint_from_LVFS $LVFS_FILE 
		fi
	done			 
		
}

# VolumeGroup to Filesystems #
function vg_lv_fs
{
	# FIND LV and MOUNT POINT of FS #
	print ""
	print "Search Mount Points in VGs=$1"
	VG_TMP=$1
	LV_FS_LOG=$LOG_DIR/"$VG_TMP.LVFS"
	if [ ! -f $LV_FS_LOG ]; then
		touch $LV_FS_LOG
		touch $LV_FS_LOG.extra
		lsvg -l $VG_TMP |grep open >> $LV_FS_LOG.extra
		
		lsvg -l $VG_TMP |grep open |while true
		do
			read FIL
			if [ "$FIL" = "" ]; then
				break
			fi
			COMPARE_FIL_EXL=$(echo $FIL |awk '{print $7}')
			EXCLUDE_FIL=$(grep "$COMPARE_FIL_EXL" $EXCLUDE_FILE)
			if [ "$COMPARE_FIL_EXL" != "N/A" ] && [ -z "$EXCLUDE_FIL" ]; then
			 	print $FIL >> $LV_FS_LOG
			fi
		done
	else
		rm -f $LV_FS_LOG
		#lsvg -l $VG_TMP |grep open >> $LV_FS_LOG
		vg_lv_fs $1
	fi	
}

# Apps VGs and their attributes #
function vgs_pvid
{
        ## FIND PVID OF ACTIVE VGs : PASSED FROM function client_active_vg ##
	print ""
	print "Search all PVID of VG=$1"
        VG=$1
        VG_LOG=$LOG_DIR/"$(hostname -s).$VG"
        if [ ! -f $VG_LOG ]; then
		## Get PVID ##
                touch $VG_LOG
                lspv |grep active |grep $VG |awk '{print $3, $2}' >> $VG_LOG
        else
		## Get PVID ##
		rm -f $VG_LOG
		touch $VG_LOG
                lspv |grep active |grep $VG |awk '{print $3, $2}' >> $VG_LOG
        fi
}

function client_active_vg
{
	## FIND ACTIVE VGs : PASS TO function vgs_pvid ##
	print "" 
	print "Finding all Active Volume Groups"
	lsvg -o |while true
        do
                read ACTIVE_VG
                if [ "$ACTIVE_VG" = "" ]; then
                        break
                else
                        # QUERY PVID #
                        vgs_pvid $ACTIVE_VG

			# QUERY LV and FS from VG #
			vg_lv_fs $ACTIVE_VG	
                fi
        done
}


function value_snapshot
{
	LSATTR=$LOG_DIR/lsattr.log
	if [ ! -f $LSATTR ]; then
		touch $LSATTR
	else
		rm $LSATTR
		touch $LSATTR
	fi
	lsattr -El sys0 >> $LSATTR

	# kernel type
	print "$KERNEL_TYPE" > $LOG_DIR/kernel_type.log

	if [ "$OSLEVEL" != "5200" ]; then
		/usr/samples/kernel/vmtune -a > $LOG_DIR/vmtune_a.log
	else
		# vmo -a
		vmo -a > $LOG_DIR/vmo_a.log
		# ioo -a
		ioo -a > $LOG_DIR/ioo_a.log
		# vmstat -v
	        vmstat -v > $LOG_DIR/vmstat_v.log

	fi

	# lsps -a
	lsps -a > $LOG_DIR/lsps_a.log

	# lsps -s
	lsps -s > $LOG_DIR/lsps_s.log

	# aio0  async io query
	lsattr -El aio0 > $LOG_DIR/lsattr_El_aio0.log

	# mount table
	mount > $LOG_DIR/mount_table.log
	
	# ulimit all
	ulimit -a > $LOG_DIR/ulimit_a.log

	# /dev ownership
	ls -lAR > $LOG_DIR/dev_ownership.log	

	# oslevel
	oslevel -r > $LOG_DIR/oslevel_r.log
		
	
	lsdev -Cc adapter |grep fcs |awk '{print $1}' |while true
	do
		read FC
		if [ "$FC" = "" ]; then
			break
		else
			lscfg -vpl $FC > $LOG_DIR/$FC.log
		fi
	done

	# Copying configuration files to target dir
	cp -p /etc/rc.local $LOG_DIR/
	cp -p /etc/rc.net $LOG_DIR/
	cp -p /etc/rc.shutdown $LOG_DIR/
}

function tar_ball
{
	tar -cvf $HERE/$(hostname).before.tar $LOG_DIR/* 
	#if [ -d $LOG_DIR ]; then
#		rm -rf $LOG_DIR
	#fi

}
################### MAIN #########################
set_variables		# Initialize variables   

case "$OPTION" in
	-c)
		print "The Default exclude file is $EXCLUDE_FILE"
		print "30sec to modify FS exclusion file"
		sleep 30
		print "Creating snapshot of $(hostname -s)"
		client_active_vg 	# RUN active VGs to query for active PVID #
		list_LVFS		# List all generated LVFS files and then extract its mountpoints
		print "Collecting system snapshot"
		value_snapshot		# Get snapshot value from system
		print ""
		print "Taring up the logs..."
		tar_ball		# tar up the logs file
	;;
	-v)
		DATA_FILE=$(ls -l $LOG_DIR |wc -l)
		if [ $DATA_FILE -gt 0 ]; then
			print "verifying snapshot"
			print "Option is not ready yet"
			exit 1
		else
			echo "ERROR: no data file (snapshot) exist"
			print ""
			exit 1
		fi
	;;
	*)
		print "ERROR: invalid option"
		exit 1
	;;
esac
