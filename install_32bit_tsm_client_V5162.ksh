#!/usr/bin/ksh
#
# This script will install the 32bit TSM client. ('bootinfo -K'  32 or 64 bit)
#
# Server must be running on AIX 5.X
#
# Server running on AIX 4.3 must use ktazd216:/misc/tsm/client/V51/V5162/32bit or 64bit
# PLEASE VERIFY THAT /usr/tivoli is not used
#
# Create symbolic link
ln -s /usr/Tivoli /usr/tivoli
#
# mount ktazd216:/misc/tsm 
#
mount ktazd216:/misc/tsm /mnt
#
#
/usr/lib/instl/sm_inst installp_cmd -a -Q -d '/mnt/client/V51/V5162/32bit' -f '_all_latest'  '-c' '-N' '-g' '-X'  '-G'

#cp /usr/tivoli/tsm/client/ba/bin/dsm.opt.smp /usr/tivoli/tsm/client/ba/bin/dsm.opt
#cp /usr/tivoli/tsm/client/ba/bin/dsm.sys.smp /usr/tivoli/tsm/client/ba/bin/dsm.sys

chown storman1.storman /usr/tivoli/tsm/client/ba/bin/dsm.sys
chown storman1.storman /usr/tivoli/tsm/client/ba/bin/dsm.opt

mkdir -p /usr/tivoli/tsm/scripts
cp -p /mnt/scripts/* /usr/tivoli/tsm/scripts/

# Add inittab entries                                        
echo " Adding inittab entries"
cp /etc/inittab /etc/inittab.`date +"%m%d%y"`
echo "dsmsched:2:once:/usr/tivoli/tsm/client/ba/bin/dsmc sched #TSM Scheduler">>/etc/inittab
echo "dsmcad:2:once:/usr/tivoli/tsm/client/ba/bin/dsmcad       #TSM Client Acceptor">>/etc/inittab

#Unmount FS
umount  /mnt

echo "******************************************************************************"
echo " "
echo "Verify that the account storman1 can execute all root commands thru sudo"
echo " "
echo "******************************************************************************"
