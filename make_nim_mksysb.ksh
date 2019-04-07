#!/usr/bin/ksh


if [ $# -lt 1 ]
then
   echo "USAGE: $0 <NIM mksysb STORAGE_SERVER>"
   echo "USAGE: $1 NFS DIRECTORY (/export/nim/mksysb) optional"
   exit 1
fi

SERVER=$1

if [ $# -eq 2 ]; then                                 
   EXPORT_DIR=$2
else
   EXPORT_DIR=/export/nim/mksysb
fi                                              
mkdir -p /tmp/tmp/mnt >/dev/null 2>&1 
#/usr/sbin/mount  -o "rsize=8192,wsize=8192" $SERVER:${EXPORT_DIR} /mnt
mount -o rw,bg,soft,intr,proto=tcp,retry=100,rsize=8192,wsize=8192 $SERVER:${EXPORT_DIR} /tmp/tmp/mnt
if [ "$?" -ne 0 ]
then
   echo "$0: ERROR nfs mount failed for  $SERVER:${EXPORT_DIR} on \"$HOSTNAME\"" >&2
   exit 1
fi

# may want to calculate the best interface to mount from the server

HOST=`uname -n`
node=`uname -n`
ERR=ERROR
IMAGEDIR=/tmp/tmp/mnt
LOGDIR=/tmp/tmp/mnt
# support multiple files per day, sortable
TODAY=`date +'%Y%m%d%H%M'`
# format for xls date
TODAY_XLS=`date +'%m/%d/%Y %H:%M'`
OUTPUT=$LOGDIR/$HOST.mksysb.log.txt
ERROUT=$LOGDIR/$HOST.mksysb.err.txt
REGISTRY=$LOGDIR/registry.csv
TMPFILE=$LOGDIR/tmp.${node}.$$

   
IMAGE_FILE="${node}.mksysb"
BOOTIMAGE_FILE="${node}.bootimage"
INSTTAPE_FILE="${node}.insttape"
TAPEBLK_SIZE="/tapeblksz"
STATUS="success"

echo "============================================" > $OUTPUT
echo "============================================" > $ERROUT
echo `date +'%Y%m%d%H%M%S'` "$node: running mksysb ... to file $IMAGE_FILE to server $SERVER " >> $OUTPUT

# create the TAPEBLK_SIZE file
echo '512 NONE' > $TAPEBLK_SIZE
FSIZE=`ulimit -H`
if [ $FSIZE != "unlimited" ]; then
	echo `date +'%Y%m%d%H%M%S'` "$node: $ERR ulimit filesize is not unlimited for root userid" >> $TMPFILE 
	cat $TMPFILE >> $ERROUT
	STATUS="failure"
	exit 1
fi

/usr/bin/time -p /usr/bin/mksysb -p -e -i $IMAGEDIR/$IMAGE_FILE > $TMPFILE 2>&1
grep 0512-038 $TMPFILE 1>> $OUTPUT 2>&1
if [[ $? != 0 ]]
then
       echo `date +'%Y%m%d%H%M%S'`  "$node: $ERR mksysb did not complete to $IMAGE_FILE successfully." >> $OUTPUT
       echo `date +'%Y%m%d%H%M%S'`  "$node: $ERR mksysb did not complete to $IMAGE_FILE successfully." >> $ERROUT
       cat $TMPFILE >> $ERROUT
       STATUS="failure"
	exit 1
else
       # log the statistics
       echo `date +'%Y%m%d%H%M%S'`  "$node: mksysb completed to $IMAGE_FILE successfully." >> $OUTPUT
fi

SIZE=`du -sk $IMAGEDIR/$IMAGE_FILE | awk '{print $1}'` 
ELAPSED_TIME=`grep Real $TMPFILE | awk '{print $NF}'`


# make the BOOTIMAGE_FILE
echo `date +'%Y%m%d%H%M%S'`  "$node: running bosboot ... to file $BOOTIMAGE_FILE to server $SERVER " >> $OUTPUT
/usr/sbin/bosboot -ad /dev/rmt0 -b $IMAGEDIR/$BOOTIMAGE_FILE > $TMPFILE 2>&1
if [[ $? != 0 ]]
then
       echo `date +'%Y%m%d%H%M%S'`  "$node: $ERR bosboot did not complete to $BOOTIMAGE_FILE successfully." >> $OUTPUT
       echo `date +'%Y%m%d%H%M%S'`  "$node: $ERR bosboot did not complete to $BOOTIMAGE_FILE successfully." >> $ERROUT
       cat $TMPFILE >> $ERROUT
       STATUS="failure"
else
       # log the statistics
       echo `date +'%Y%m%d%H%M%S'` "$node: bosboot completed to $BOOTIMAGE_FILE successfully." >> $OUTPUT
fi

# make the INSTTAPE_FILE
echo `date +'%Y%m%d%H%M%S'`  "$node: running mkinsttape ... to file $INSTTAPE_FILE to server $SERVER " >> $OUTPUT
/usr/sbin/mkinsttape $IMAGEDIR/$INSTTAPE_FILE > $TMPFILE 2>&1
if [[ $? != 0 ]]
then
       echo `date +'%Y%m%d%H%M%S'`  "$node: $ERR mkinsttape did not complete to $INSTTAPE_FILE successfully." >> $OUTPUT
       echo `date +'%Y%m%d%H%M%S'` "$node: $ERR mkinsttape did not complete to $INSTTAPE_FILE successfully." >> $ERROUT
       cat $TMPFILE >> $ERROUT
       STATUS="failure"
else
       # log the statistics
       echo `date +'%Y%m%d%H%M%S'` "$node: mkinsttape completed to $INSTTAPE_FILE successfully." >> $OUTPUT
fi

# log the statistics (only time info form the mksysb file
echo "$node,$STATUS,$SERVER,$SIZE,$TODAY_XLS,$ELAPSED_TIME" >> $REGISTRY

rm -f  $TMPFILE
rm -f $TAPEBLK_SIZE

# wait a second
sleep 5

# unmount the nfs directory
cd /
/usr/sbin/umount /tmp/tmp/mnt
