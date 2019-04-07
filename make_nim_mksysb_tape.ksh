#!/usr/bin/ksh
#
# parameters <nim server>
#
# make_nim_mksysb_tape.ksh:
#
# Associated modules: none
#
# Logic:
#   1. run mksysb (with exclude list)
#
# Change Log:
# 08/12/03 cem enhance logging and create additional files required for tape recovery
#
#------------------------------------------------------------------


if [ $# -lt 2 ]; then                                       
        print ""                                            
        print "usage: mksysb image server" 
        print "usage: node name (mksysb image name)"
	print "NFS directory (/export/nim/mksys) optional"  
	print "tape drive (rmt0) optional"      
        print ""                                            
        exit 1  
else
 SERVER=$1                                          
 NODE=$2
fi
if [ $# -eq 3 ]; then
	NFSDIR = $3
else
	NFSDIR=/export/nim/mksysb
fi
if [ $# -eq 4 ]; then
	NFSDIR = $3
	TAPE = $4
else
	NFSDIR=/export/nim/mksysb
	TAPE=rmt0
fi
# vars
BOOTIMAGE=$NODE.bootimage
INSTTAPEIMAGE=$NODE.insttape
MKSYSBIMAGE=$NODE.mksysb	                                                          
TAPEDEV=/dev/$TAPE
NOREWINDTAPEDEV=/dev/${TAPE}.1
/usr/sbin/mount $SERVER:$NFSDIR /mnt
# do it
echo rewinding tape device $TAPEDEV
/usr/bin/tctl -f $TAPEDEV rewind
OLDBLK=`/usr/sbin/lsattr -E -O -a block_size -l $TAPE | tail -1`
echo "OLD BLOCK SIZE $OLDBLK"
echo "setting tape block size to 512 for tape device $TAPE"
/usr/sbin/chdev -l $TAPE -a block_size=512   
echo "setting tape block size to 512 for tape device $TAPE"
NEWBLK=`/usr/sbin/lsattr -E -O -a block_size -l $TAPE | tail -1`
echo "NEW BLOCK SIZE $NEWBLK"
echo "transferring image $BOOTIMAGE to tape device $NOREWINDTAPEDEV"
/usr/bin/dd if=/mnt/$BOOTIMAGE of=$NOREWINDTAPEDEV bs=512 conv=sync
echo "transferring image $INSTTAPEIMAGE to tape device $NOREWINDTAPEDEV"
/usr/bin/dd if=/mnt/$INSTTAPEIMAGE of=$NOREWINDTAPEDEV bs=512 conv=sync
echo "writing TOC to tape device $NOREWINDTAPEDEV"
echo "Dummy tape TOC" | /usr/bin/dd of=$NOREWINDTAPEDEV bs=512 conv=sync 
# verify tape image
echo rewinding tape device $TAPEDEV
/usr/bin/tctl -f $TAPEDEV rewind
echo "reading first image from tape device $NOREWINDTAPEDEV"
/usr/bin/dd if=$NOREWINDTAPEDEV of=/dev/null bs=512 conv=sync
RET=$?
echo "received return code of $RET when validating tape image"
echo rewinding tape device $TAPEDEV
/usr/bin/tctl -f $TAPEDEV rewind
echo "fast forward tape device $NOREWINDTAPEDEV 3 images"
/usr/bin/tctl -f $NOREWINDTAPEDEV fsf 3
echo "transferring image $MKSYSBIMAGE to tape device $NOREWINDTAPEDEV (this will take a long time)"
/usr/bin/dd if=/mnt/$MKSYSBIMAGE of=$NOREWINDTAPEDEV bs=512 conv=sync
echo "setting tape block size to $OLDBLK for tape device $TAPE"
/usr/sbin/chdev -l $TAPE -a block_size=$OLDBLK
echo rewinding tape device $TAPEDEV
/usr/bin/tctl -f  $TAPEDEV rewind
/usr/sbin/umount /mnt
exit
