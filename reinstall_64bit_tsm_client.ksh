#!/usr/bin/ksh
#
# This script will reinstall the 64bit TSM client.  This assumes that the proper link of /usr/tivoli to /usr/Tivoli has been properly defined.
#
# mount ktazd216:/misc/tsm 
#
mount ktazd216:/misc/tsm /mnt
#
#
/usr/lib/instl/sm_inst installp_cmd -a -l -d '/mnt/client/V52/V5220/64bit' -f 'tivoli.tivguid                                                     ALL  @@I:tivoli.tivguid _all_filesets,tivoli.tsm.client.api.64bit                                  ALL  @@I:tivoli.tsm.client.api.64bit _all_filesets,tivoli.tsm.client.ba.64bit                                   ALL  @@I:tivoli.tsm.client.ba.64bit _all_filesets'  '-c' '-N' '-X'   '-F'    

#cp /usr/tivoli/tsm/client/ba/bin/dsm.opt.smp /usr/tivoli/tsm/client/ba/bin/dsm.opt
#cp /usr/tivoli/tsm/client/ba/bin/dsm.sys.smp /usr/tivoli/tsm/client/ba/bin/dsm.sys

chown storman1.storman /usr/tivoli/tsm/client/ba/bin/dsm.sys
chown storman1.storman /usr/tivoli/tsm/client/ba/bin/dsm.opt

mkdir -p /usr/tivoli/tsm/scripts
cp -p /mnt/scripts/* /usr/tivoli/tsm/scripts/

#Unmount FS
umount  /mnt

echo "******************************************************************************"
echo " "
echo "Verify that the account storman1 can execute all root commands thru sudo"
echo " "
echo "******************************************************************************"
