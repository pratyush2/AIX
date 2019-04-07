#!/usr/bin/ksh
LOGFILE=/usr/local/scripts/mksysb_vios.log
HOSTNAME=`hostname`
cp /dev/null /usr/local/scripts/mksysb_vios.log
mount -o rw,bg,soft,proto=tcp,retry=100 ktazp1560:/export/mksysb /mnt
sleep 2
/usr/ios/cli/ioscli backupios -file /mnt/$HOSTNAME.mksysb -mksysb -nosvg >> $LOGFILE
sleep 2
umount /mnt
