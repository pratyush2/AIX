#!/bin/ksh
#==============================================================
#  Author: Sonnie Nguyen
#  Co-Author: Ryan Dang
#  Date:   09/13/07
#  Script: AltDiskBkup.ksh
#  ver:	3.1
#==============================================================
#  NOTE:
#	This script runs to make a 2nd backup of ROOT using
#	alt_disk method.
#
#	This script will check for 4 available SCSI disks, the
#	same amount of free disk available for backup.
#
#==============================================================
#  Modification History
#     02/14/06:sonnie:Created the script
#     04/12/06:sonnie:Added log transfer to ktazd216
#     08/02/06:sonnie:Not to list multiple hdiskx on lspv.
#     		     :to check for different SCSI disk types.
#     05/24/07:ryan:backup sys to minumum of one hdisk.
#     05/24/07:ryan:add script in rc.local to correct bootlist.
#     06/11/07:ryan:fixed alt_disk_install installation fileset path.
#     06/11/07:ryan:remove -g from command line.
#     06/11/07:ryan:added move function for log transfer to d216.
#		:add alt_disk boot device for result html
#		:correct original bootlist from possible change by alt_disk
#	09/4/07:ryan:Fix incorrect count of rootvg with altinst_rootvg
#		:tested on AIX 4.3.2, 4.3.3, 5.1, 5.2, 5.3
#		:Add alt_disk boot device physical location to log for 
#		status reporting
#		:Add function to correct bad bootlist from the original 
#		setting.
#	09/13/07:ryan:altDiskBkup will not remove old_rootvg until 2 months after
#	04/12/08:ryan:correct break when unsuccessful alt_disk
#	05/20/08:RichD:added redirect stderr to stdout log on all non-echo/print cmnds
#==============================================================
# USAGE:
#        ./altDiskBkup.ksh 
#==============================================================
# ERROR:
#	If any of the logical volume name on rootvg longer than
#	11 character, the error below will occur. Because
#	alt_disk utility add "alt_" to the beginning of the
#	logical volume which will exceed 15 character limit for
#	AIX.
#
#	0516-066 : Physical volume is not a volume group member.
#               Check the physical volume name specified.
#	0505-121 alt_disk_install: Error.
#
# RESOLUTION:
#	Either, rename the logical volume or umount the logical
#	volume.
#==============================================================
#set -x
CURRENTHOST=`hostname -s`
NUMB=`lscfg | grep "SCSI Disk" | wc -l`
OLDROOT_KILL_DATE=00
## The quotations around rootvg on the next line is important for specific grep search ##

ROOTDISK=$(lspv | grep " rootvg " | wc -l |awk '{print $1}')
ROOTNUM=`expr $ROOTDISK`

## VERIFYING IF THERE IS OLD_ROOTVG - will be removed in 2 month after ##
TIME_STAMP_FILE=/usr/local/scripts/altd_time_stamp.txt
KILL_OLD_ROOTVG=0
OLD_ROOTVG="old_rootvg"
OLD_ROOTVG_CHECK=0
TIME_STAMP_MONTH_NOW=$(date +%m)

#############

print "ROOTNUM=$ROOTNUM"
FILE="$CURRENTHOST.altDiskBkup.txt"
ALTDNUM=`lspv | grep image_1 | wc -l`
for LB in altinst_rootvg image_1 old_rootvg
do
	ALTDLABEL_TMP=$(lspv |grep $LB |awk '{print $3}' |head -1)
	if [ "$ALTDLABEL_TMP" != "" ];then
		ALTDLABEL=$ALTDLABEL_TMP	
	fi
done

COUNT=0
altdisklog="/var/adm/$FILE"
if [ -f $altdisklog ]; then
	rm -f $altdisklog
	touch $altdisklog
else
	touch $altdisklog
fi

RCLOCAL=/etc/rc.local
INITTAB=/etc/inittab
BOOTLIST_SCRIPT=/usr/local/scripts/bootlist_chk.ksh
IMAGEDATA=/image.data
IMAGEDATA_TMP=/tmp/image.tmp
ALTDISK=no
ROOTVG_MIRRORED=0
NONEAS_SPACE_DISK_TOT=0
TOTAL_AVAILABLE_DISK=0
ALT_TYPE=0
EXPORTVG=0

movelog()
{
#set -x
	print "movelog function"
REMOTEDIR='/data/WEB/docs_private/uds_internal/pp/sysback/logs'
LOCALDIR='/var/adm'
HOST='ktazd216.crdc.kp.org'
USER='incoming'
PASSWORD='kaiser'
if [ `hostname -s` = "ktazd216" ]
then
   exit 0
fi

ftp -n $HOST <<SCRIPT
quote USER $USER
quote PASS $PASSWORD
cd $REMOTEDIR
lcd $LOCALDIR
put $FILE
quit
SCRIPT
exit 0
}

success()
{
#set -x
	print "sucess function"
   echo "======= Altdisk Backup Ran Successfully `date` =======" >> $altdisklog
	if [ -f $TIME_STAMP_FILE ]; then
                rm -f $TIME_STAMP_FILE
        fi
	print "COMPLETE SUCCESSFULLY"
	movelog
}

unsuccess()
{
#set -x
	print "unsuccess function"
   echo "======= Altdisk Backup Not Run `date` =======" >> $altdisklog
	print "BACKUP PROCESS FAILED"
	movelog
}

altdiskfileset()
{
	print "altdiskfileset function"

OSLEVEL=`oslevel -r` >> $altdisklog
if [ $? -ne 0 ]; then
	OSLEVEL=$(oslevel |sed 's/\.//g')
fi
lslpp -l bos.alt_disk_install.rte
if [ $? = 0 ]
then
   echo "alt_disk_install fileset already installed" >> $altdisklog
else
   echo "alt_disk_install fileset is not installed" >> $altdisklog
   echo "Mount ktazd216:/aix to install alt_disk fileset" >> $altdisklog
   /usr/sbin/mount -o ro,bg,soft,proto=tcp,retry=100 ktazd216.crdc.kp.org:/aix /mnt
   echo "Installing bos.alt_disk_install" >> $altdisklog
   level=`oslevel -r |cut  -c1-2`
	if [ $? -ne 0 ]; then
		level=$(oslevel |sed 's/\.//g'|cut -c1-3)
	fi
   maint=`oslevel -r |cut  -c6-7`
   aix=aix
	if [ $level -eq 43 ]; then
		end=3_image
		middle=3_ML
	else
		end=0_image
   		middle=0_ML
	fi
   result=$aix$level$end
   result3=$aix$level$middle$maint
   echo "Installing bos.alt_disk_install from $result" >> $altdisklog
   /usr/sbin/installp -ac -d /mnt/$result bos.alt_disk_install -p -X >> $altdisklog 2>&1
   echo "Appling and maintenance of bos_alt_disk_install from $result3" >> $altdisklog
   /usr/sbin/installp -ac -d /mnt/$result3 bos.alt_disk_install -p -X >> $altdisklog 2>&1
   echo "Installation completed, unmounting ktazd216" >> $altdisklog
   /usr/sbin/umount /mnt
fi
}

set -A ROOTA
set -A ROOTAS
assignroot()
{
#set -x
	print "assignroot function"
  ROOTA[$rootcount]="$ALLOCATE"
  ROOTAS[$rootcount]=`lscfg -vl $ALLOCATE |grep "SCSI Disk" |grep -v "Other" | cut -f 2 -d '(' | awk '{print substr($1,1)}'`
} 

set -A NONEA
set -A NONEAS
assignnone()
{
#set -x
	print "assignnone function"
  NONEA[$nonecount]=$ALLOCATE
  NONEAS[$nonecount]=`lscfg -vl $ALLOCATE |grep "SCSI Disk" |grep -v "Other" | cut -f 2 -d '(' | awk '{print substr($1,1)}'` 
}

set -A ALTDA
set -A ALTDAS
collectdisk()
{
#set -x
	print "collectdisk function"
	ALT_TYPE=1
  ALTDA[$altdcount]=$ALLOCATE
  ALTDAS[$altdcount]=`lscfg -vl $ALLOCATE |grep "SCSI Disk" | cut -f 2 -d '(' | cut -f 1 -d ' '` 
  echo "${ALTDA[$altdcount]} is $TYPE and size is ${ALTDAS[$altdcount]}" >> $altdisklog
}

check_rootvg_actual_size()
{
#set -x	
	print "check_rootvg_actual_size function"
	ROOTVG_LP_TOTAL=0
	## Create /image.data and figure rootvg unmirrored size ##
	/usr/bin/mkszfile
	PPSIZE=$(grep "PP_SIZE=" $IMAGEDATA |uniq |head -1|awk '{print $2}')	#MB
	for rootvg_LP in $(grep "LPs=" $IMAGEDATA |cut -d"=" -f2 |awk '{print $1}')
	do
		((ROOTVG_LP_TOTAL=ROOTVG_LP_TOTAL + rootvg_LP))
	done
	ROOTVG_UNMIRROR_FS_SIZE=$((ROOTVG_LP_TOTAL * PPSIZE * 1024))
	
	## Check if any LV has more the one copies or rootvg is mirrored ##
	for COPIES in $(grep "COPIES=" $IMAGEDATA |cut -d"=" -f2 |awk '{print $1}')
	do
		if [ $COPIES -gt 1 ]; then
			ROOTVG_MIRRORED=1
		fi
	done
	if [ $ROOTVG_MIRRORED -eq 1 ]; then
		TOTAL_USED_ROOTVG_SIZE_LP=$(lsvg rootvg |grep USED |cut -d":" -f3 |awk '{print $1}')
		TOTAL_USED_ROOTVG_SIZE=$((TOTAL_USED_ROOTVG_SIZE_LP * PPSIZE * 1024))
	fi
}

check_total_available_disk_space()
{
#set -x
	print "check_total_available_disk_space function"
	t=1
	NONED_SPACE_TOTAL=0
	ALTDAS_SPACE_TOTAL=0
	if [ $ALT_TYPE -eq 0 ]; then
		until [[ $t -gt $nonecount ]]
		do
		print "${NONEAS[${t}]}"
		(( NONED_SPACE_TOTAL=NONED_SPACE_TOTAL + NONEAS[${t}] ))	
		((t=t + 1))
		done
		(( NONED_SPACE_TOTAL=NONED_SPACE_TOTAL * 1024 ))
	else
		t=1
		until [[ $t -gt $altdcount ]]
		do
		(( ALTDAS_SPACE_TOTAL=ALTDAS_SPACE_TOTAL + ALTDAS[${t}] ))
		(( t=t + 1 ))
		done
		(( ALTDAS_SPACE_TOTAL=ALTDAS_SPACE_TOTAL * 1024 ))
	fi

}
verify_bootlist_device()
{
#Set -x
	print "verify_bootlist_device function"
	B_DEVICE_TMP=$1
	if [ "$B_DEVICE_TMP" != "" ]; then
		lspv -l $B_DEVICE_TMP |grep hd5
		if [ $? -ne 0 ]; then
			return 1
		else
			return 0
		fi
	fi	
}	
dobackup()
{
#set -x
	print "dobackup function"

   (( TOTAL_AVAILABLE_DISK=nonecount + altdcount ))
   if [ $TOTAL_AVAILABLE_DISK -ge $ROOTNUM ]
   then
      echo "The available SCSI disk is $TOTAL_AVAILABLE_DISK, root disk is $rootcount" >> $altdisklog
   else
	## Second Attempt by calculating the used space and available space ##
	if [ $ROOTVG_UNMIRROR_FS_SIZE -le $NONED_SPACE_TOTAL -o $ROOTVG_UNMIRROR_FS_SIZE -le $ALTDAS_SPACE_TOTAL ]; then
		if [ $ROOTVG_MIRRORED -eq 1 ]; then
			modify_image_data_single_rootvg_copy
			ROOTNUM=1
		else
			print "rootvg is not mirrored, Attempting cloning process...." 
		fi
	else
      		echo "rootvg disk is $ROOTNUM, available SCSI disk is $nonecount" >> $altdisklog
      		echo "Not enough free SCSI disk, exiting..." >> $altdisklog
      		unsuccess
	fi
   fi

   c=1		## initate counter ##
   whichdisk=""

	## Verify disk count ##
   if [ $ALTDISK = "yes" ]; then
	## At the point ROOTNUM should be 1 or less then TOTAL AVAILABLE DISK after modify function ##
      until [[ $c -gt $ROOTNUM ]]; do

	## Verify disk available space of one single disk and VG disk exportvg ##
	set -x
         if [ ${ALTDAS[$c]} -ge ${ROOTAS[$c]} -o $ROOTVG_UNMIRROR_FS_SIZE -le $ALTDAS_SPACE_TOTAL ]; then
            whichdisk="$whichdisk ${ALTDA[$c]} "
            echo "exportvg $ALTDLABEL..." >> $altdisklog
		VARYON_CHK=$(lsvg -o |grep $ALTDLABEL)
		if [ "$VARYON_CHK" != "" ]; then
			print "1. About to varyoffvg $ALTDLABEL in 5 sec" >> $altdisklog
			sleep 5
            		varyoffvg $ALTDLABEL >> $altdisklog 2>&1
		fi
		if [ $c -eq $TOTAL_AVAILABLE_DISK ]; then
			if [ $OLD_ROOTVG_CHECK -eq 1 ] && [ $KILL_OLD_ROOTVG -eq 1 ]; then 
				print "2. About to exportvg $ALTDLABEL in 5 sec" >> $altdisklog
				sleep 5
       				exportvg $ALTDLABEL >> $altdisklog 2>&1
				EXPORTVG=1
				break
			fi

			if [ $OLD_ROOTVG_CHECK -eq 0 ]; then
				print "3. About to exportvg $ALTDLABEL in 5 sec" >> $altdisklog
                        	sleep 5
                       	 	exportvg $ALTDLABEL >> $altdisklog 2>&1
                        	EXPORTVG=1
                        	break
                        fi
		fi
         else
            echo "Available Disk size too small" >> $altdisklog
            unsuccess
         fi
	if [ $EXPORTVG -ne 1 ]; then
         	(( c=c + 1 ))
	fi
      done
	if [ $EXPORTVG -eq 0 ] && [ $OLD_ROOTVG_CHECK -eq 1 ]; then
		if [ $KILL_OLD_ROOTVG -eq 0 ]; then 
		print "OLD_ROOTVG_CHECK=yes" >> $altdisklog
		print "old_rootvg exist and will not export until after or on the month=$OLDROOT_KILL_DATE" >> $altdisklog
		if [ $OLDROOT_KILL_DATE -gt 12 ]; then
			print "Warning: Invalid month number" >> $altdisklog
		fi
		print "old_rootvg exist exiting this time" 
		exit 0
		fi
	fi
   else
      until [[ $c -gt $nonecount ]]; do
	NONEAS_SPACE_DISK=0
	if [ "${ROOTAS[$c]}" = "" ]; then
		ROOTAS[$c]=0
	fi
	
         if [ ${NONEAS[$c]} -ge ${ROOTAS[$c]} -o $ROOTVG_UNMIRROR_FS_SIZE -le $NONED_SPACE_TOTAL ]; then
        	(( NONEAS_SPACE_DISK=NONEAS[$c] * 1024 ))
		(( NONEAS_SPACE_DISK_TOT=NONEAS_SPACE_DISK_TOT + NONEAS_SPACE_DISK ))
		if [ $NONEAS_SPACE_DISK_TOT -ge $ROOTVG_UNMIRROR_FS_SIZE ]; then
			## enough disk for rootvg ## 
            		whichdisk="$whichdisk ${NONEA[$c]} "
			if [ $ROOTVG_MIRRORED -eq 0 ]; then 
				break
			else
				print "Disk for rootvg mirrorvg = $whichdisk"
			fi
		else
			## if first disk is smaller than rootvg size ##
			whichdisk="$whichdisk ${NONEA[$c]} "
		fi
	else
            echo "Available Disk size too small" >> $altdisklog
            unsuccess 
         fi
         (( c= c + 1 ))
      done
   fi
	print "Original bootlist"  >> $altdisklog 
	/usr/bin/bootlist -m normal -o >> $altdisklog 2>&1
	for OG in $(/usr/bin/bootlist -m normal -o |awk '{print $1}')
	do
		verify_bootlist_device $OG
		if [ $? -ne 0 ]; then 
			print "$OG : Bad boot Device..deleting from original list" >> $altdisklog
		else
			ORIGINAL_BOOTLIST_DEV="$ORIGINAL_BOOTLIST_DEV $OG"
			
		fi
	done
	/usr/bin/bootlist -m normal $ORIGINAL_BOOTLIST_DEV	
	print "Bootlist set to $ORIGINAL_BOOTLIST_DEV" >> $altdisklog
	
   echo "Altdisk backup..." >> $altdisklog

	## ID boot device physical location for alt_disk ##
	if [ $ROOTVG_MIRRORED -eq 0 ]; then
		ONEBOOTDISK=$(echo $whichdisk |awk '{print $1}')
		BDEVICE_LOC=$(lscfg -vpl $ONEBOOTDISK |grep "$ONEBOOTDISK" |awk '{print $2}')
		print "BDEVICE=$BDEVICE_LOC" >> $altdisklog
	else
		C=1
		for BD in $(echo $whichdisk)
		do
			ONEBOOTDISK=$(echo $BD |awk '{print $1}')
                	BDEVICE_LOC=$(lscfg -vpl $ONEBOOTDISK |grep "$ONEBOOTDISK" |awk '{print $2}')
			print "BDEVICE-$C=$BDEVICE_LOC" >> $altdisklog
			((C=C + 1))
		done
	fi
	if [ "$whichdisk" = "" ]; then
		print "no available disk to start backup" >> $altdisklog
		exit 1
	fi
	if [ -f $TIME_STAMP_FILE ]; then
		rm -f $TIME_STAMP_FILE
	fi

   echo "/usr/sbin/alt_disk_install -B -C -i $IMAGEDATA $whichdisk" >> $altdisklog
   /usr/sbin/alt_disk_install -B -C -i $IMAGEDATA $whichdisk >> $altdisklog 2>&1
	if [ $? -ne 0 ]; then 
		unsuccess
		exit 1
		
	fi
   echo "Renaming altdisk image..." >> $altdisklog
   echo "/usr/sbin/alt_disk_install -v image_1 $whichdisk" >> $altdisklog
   /usr/sbin/alt_disk_install -v image_1 $whichdisk >> $altdisklog 2>&1

	## Change back the original bootlist
	#/usr/bin/bootlist -m normal $ORIGINAL_BOOTLIST_DEV
}

add_script_entry_to_rclocal()
{
#set -x
	print "add_script_entry_to_rclocal function"

if [ -f $BOOTLIST_SCRIPT ]; then
	if [ ! -f $RCLOCAL ]; then
		touch $RCLOCAL
		echo "$BOOTLIST_SCRIPT" >> $RCLOCAL 
		chmod u+x $RCLOCAL
		grep $RCLOCAL $INITTAB
		if [ $? -eq 1 ]; then
			/usr/sbin/mkitab "rclocal:2:wait:/etc/rc.local > /dev/console 2>&1 # Start rc.local"
		fi 
	else
		echo "$BOOTLIST_SCRIPT" >> $RCLOCAL
		chmod u+x $RCLOCAL
	fi
fi

}

remove_script_entry_from_rclocal()
{
	sed -e '/bootlist_chk.ksh/d' $RCLOCAL > $RCLOCAL.tmp
        mv -f $RCLOCAL.tmp $RCLOCAL
        chmod u+x $RCLOCAL
}

modify_image_data_single_rootvg_copy()
{
#set -x
	print "modify_image_data_single_rootvg_copy function"
	INDEX=1
	LV_COPIES_FOUND=0
	if [ -f $IMAGEDATA ]; then
		rm -f $IMAGEDATA
		/usr/bin/mkszfile
	else
		/usr/bin/mkszfile
	fi
	if [ -f $IMAGEDATA_TMP ]; then
		rm -f $IMAGEDATA_TMP
		touch $IMAGEDATA_TMP
	else
		touch $IMAGEDATA_TMP
	fi
	
	while read LINE
	do
		LV_COPIES_CHK=$(echo $LINE |grep "COPIES=" |awk '{print $2}')
        	if [ "$LV_COPIES_CHK" != "" ]; then
                	LV_COPIES_NUM=$LV_COPIES_CHK
                	fileArray[${INDEX}]="\t COPIES= 1"
                	LV_COPIES_FOUND=1
        	else
                	COLON_CHK=$(echo $LINE |grep ":")
                	if [ "$COLON_CHK" = "" ]; then
                        	fileArray[${INDEX}]="\t $LINE"
                	else
                        	fileArray[${INDEX}]="$LINE"
                	fi
        	fi
		((INDEX=INDEX + 1))
	done < $IMAGEDATA
	t=1
	until [ $t -eq $INDEX ]
	do
		print "${fileArray[${t}]}" >> $IMAGEDATA_TMP
		((t=t + 1))
	done
	mv $IMAGEDATA_TMP $IMAGEDATA
}

get_disk_count()
{
#set -x
	print "get_disk_count function"
## Find and ID scsi disk on system ##

ALTDNUM_TMP=$ALTDNUM
for ALLOCATE in `lscfg |grep "SCSI Disk" |grep -v "Other" | awk '{print $2}'`
do
   if [ $ALTDNUM_TMP -gt 0 ]; then
      TYPE=`lspv $ALLOCATE | grep "VOLUME GROUP:" | awk '{print $6}'`
   else
      TYPE=`lspv |grep -w $ALLOCATE | awk '{print $3}'`
      chdev -l $ALLOCATE -a pv='yes'
   fi
   case "$TYPE" in
     rootvg )   
		rootcount=$((rootcount + 1))
                assignroot ;;
     image_1)   
		altdcount=$((altdcount + 1))
                ALTDISK="yes"
                collectdisk
                ALTDNUM_TMP=0 ;;
     altinst_rootvg)  
		altdcount=$((altdcount + 1))
                ALTDISK="yes"
                collectdisk
                ALTDNUM_TMP=0 ;;
     None)      
		nonecount=$((nonecount + 1))
                assignnone ;;
     old_rootvg)
		altdcount=$((altdcount + 1))
                ALTDISK="yes"
                collectdisk
		OLD_ROOTVG_CHECK=1
                ALTDNUM_TMP=0
		if [ ! -f $TIME_STAMP_FILE ]; then
			echo "$TIME_STAMP_MONTH_NOW" > $TIME_STAMP_FILE
		fi
		;;
   esac
done

}

##########   MAIN  ############
nonecount=0 
rootcount=0
altdcount=0

OSL=$(oslevel -r)
if [ $? -ne 0 ]; then
	OSL=$(oslevel |sed 's/\.//g' |cut -c1-3)
	if [ $OSL -le 432 ]; then
		print "AIX $OSL: Non Supported version for backup" >> $altdisklog
		unsuccess
	fi
fi
echo "========== Start AltDisk Backup `date` ==========" >> $altdisklog

## Add bootlist verification script to /etc/rc.local ##
#add_script_entry_to_rclocal

altdiskfileset

get_disk_count

if [ -f $TIME_STAMP_FILE ]; then
        OLD_ROOTVG_DATE=$(cat $TIME_STAMP_FILE |head -1)
        if [ $TIME_STAMP_MONTH_NOW -eq 12 ] || [ $TIME_STAMP_MONTH_NOW -eq 11 ]; then
                (( OLDROOT_KILL_DATE=OLD_ROOTVG_DATE + 2 - 12 ))
        else
                (( OLDROOT_KILL_DATE=OLD_ROOTVG_DATE + 2 ))
        fi
        if [ $TIME_STAMP_MONTH_NOW -ge $OLDROOT_KILL_DATE ]; then
                KILL_OLD_ROOTVG=1
        else
                KILL_OLD_ROOTVG=0
        fi
fi

## Some system has more then 1 disk for alt_disk backup: mirrored ##
## and some system can have only 1 disk for alt_disk backup: not mirrored ##

check_rootvg_actual_size

if [ $ROOTNUM -le $ALTDNUM ] || [ "$ALTDISK" = "yes" ]
then
   echo "This server have altdisk..." >> $altdisklog
   #nonecount=$altdcount
   nonecount=0
   ALTDISK="yes"
	check_total_available_disk_space
   dobackup
else
	check_total_available_disk_space
   dobackup
fi

#if [ -f $BOOTLIST_SCRIPT ]; then
#	remove_script_entry_from_rclocal
#fi

success

exit
