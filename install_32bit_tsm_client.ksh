#!/usr/bin/ksh
#
# This script will installs the 32bit TSM client.
#
# Create symbolic link
ln -s /usr/Tivoli /usr/tivoli
#
# mount ktazd216:/misc/tsm 
#
mount ktazd216:/misc/tsm /mnt
#
#
/usr/lib/instl/sm_inst installp_cmd -a -Q -d '/mnt/client/V52/V5220/32bit' -f 'tivoli.tivguid                                                     ALL  @@I:tivoli.tivguid _all_filesets,tivoli.tsm.client.api.32bit                                  ALL  @@I:tivoli.tsm.client.api.32bit _all_filesets,tivoli.tsm.client.ba.32bit                                   ALL  @@I:tivoli.tsm.client.ba.32bit _all_filesets'  '-c' '-N' '-g' '-X'  '-G'

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
