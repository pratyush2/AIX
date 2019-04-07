#!/usr/bin/ksh

############################################################################
# This is a  script to  collect system information  such  as device listing,
# PVs, VGs and other relevant info about external storage such as EMC/Shark.
# Information  is collected  in a file  and  other files are generated under
# /home/<hostname>  directory, which  are  significant  to  restore  storage
# subsystem,  VG  and  file system  structure  for a  server  due  to system
# failures  and or to import the VGs back into  the  system due to exporting
# of VGs and removal of devices because of any Storage related activity
# 
# Author : Sikandar Mohamed
# Last Modified - 04/23/04
############################################################################


echo "Collecting system info ...\n" 
HOSTNAME=`hostname`
mkdir -p /home/$HOSTNAME
logfile=/home/$HOSTNAME/$HOSTNAME.sysinfo

echo "Collecting system info....\n" > $logfile
echo "=====================================================" >> $logfile
echo "Copying the device directory listing to a file......" >> $logfile
echo "=====================================================" >> $logfile

ls -l /dev > /home/$HOSTNAME/$HOSTNAME.dev

echo "\n==========================" >> $logfile
echo "Volume Group listing......" >> $logfile
echo "==========================" >> $logfile

lsvg -o >> $logfile 
lsvg -o > /home/$HOSTNAME/$HOSTNAME.vgs

echo "\n==========================" >> $logfile
echo "Volume Group to PV........" >> $logfile
echo "==========================" >> $logfile

for VG_NAME in `cat /home/$HOSTNAME/$HOSTNAME.vgs`
do
lsvg -p $VG_NAME >> $logfile
echo "\n" >> $logfile
done

echo "\n==========================" >> $logfile
echo "Volume Group to LV........" >> $logfile
echo "==========================" >> $logfile

for VG_NAME in `cat /home/$HOSTNAME/$HOSTNAME.vgs`
do
lsvg -l $VG_NAME >> $logfile
echo "\n" >> $logfile
done

echo "\n==========================" >> $logfile
echo "Physical Volume listing..." >> $logfile
echo "==========================" >> $logfile
lspv >> $logfile
lspv > /home/$HOSTNAME/$HOSTNAME.pvs

echo "\n==========================" >> $logfile
echo "df -k Listings  .........." >> $logfile
echo "==========================" >> $logfile
df -k >> $logfile

echo "\n==========================" >> $logfile
echo "Count of filesystems......" >> $logfile
echo "==========================" >> $logfile
df -k | wc -l >> $logfile

echo "\n==========================" >> $logfile
echo "cat /etc/filesystems......" >> $logfile
echo "==========================" >> $logfile
cat /etc/filesystems >> $logfile
cp -p /etc/filesystems /home/$HOSTNAME/filesystems.$HOSTNAME

echo "\n==========================" >> $logfile
echo "Listing of fiber channel.." >> $logfile
echo "==========================" >> $logfile
lsdev -Cc adapter | grep fc >> $logfile
lsdev -Cc adapter | grep fc | awk '{print $1}' > /home/$HOSTNAME/$HOSTNAME.fa

for FA in `cat /home/$HOSTNAME/$HOSTNAME.fa`
do
	  echo "\n===  lscfg -vl $FA   ===" >> $logfile
	  lscfg -vl $FA >> $logfile
	  echo "\n===lsattr -EH -l $FA ===" >> $logfile
	  lsattr -EH -l $FA >> $logfile
done
rm /home/$HOSTNAME/$HOSTNAME.fa

echo "\n==========================" >> $logfile
echo "Level of EMC software....." >> $logfile
echo "==========================" >> $logfile
lslpp -L | grep EMC >> $logfile

echo "\n==========================" >> $logfile
echo "Level of Device Driver...." >> $logfile
echo "==========================" >> $logfile
lslpp -L | grep devices.pci.df10e51a >> $logfile

echo "\n==========================" >> $logfile
echo "inq listing of EMC disks.." >> $logfile
echo "==========================" >> $logfile
/usr/lpp/Symmetrix/bin/inq >> $logfile

echo "\n==========================" >> $logfile
echo "Display power disk ......." >> $logfile
echo "==========================" >> $logfile
if [ -f /usr/sbin/powermt ]; then
	/usr/sbin/powermt display >> $logfile
	echo "\n==========================" >> $logfile
	echo "Display power dev  ......." >> $logfile
	echo "==========================\n" >> $logfile
	/usr/sbin/powermt display dev=all >> $logfile
else
	echo "*******   NO  POWER  DEVICE  INSTALLED   *********"
fi

echo "\n===================================" >> $logfile
echo "Level of IBM software for Shark....." >> $logfile
echo "===================================" >> $logfile
lslpp -L | grep ibm2105 >> $logfile
lslpp -L | grep sdd >> $logfile

echo "\n==========================" >> $logfile
echo "Listing of Shark disks.." >> $logfile
echo "==========================" >> $logfile

/usr/sbin/lsvpcfg >> $logfile
/usr/sbin/lsvpcfg > /home/$HOSTNAME/lsvpcfg.$HOSTNAME

echo "\n========================================" >> $logfile
echo "Querying adapter for Shark disks.." >> $logfile
echo "========================================" >> $logfile

/usr/bin/datapath query adapter >> $logfile
/usr/bin/datapath query adapter > /home/$HOSTNAME/query-adapter.$HOSTNAME

echo "\n========================================" >> $logfile
echo "Querying device for Shark disks.." >> $logfile
echo "========================================" >> $logfile

/usr/bin/datapath query device >> $logfile
/usr/bin/datapath query device > /home/$HOSTNAME/query-device.$HOSTNAME

echo "\n==========================" >> $logfile
echo "AIX ML listing      ......" >> $logfile
echo "==========================" >> $logfile
instfix -i | grep AIX_ML >> $logfile

echo "\n==========================" >> $logfile
echo "End of Collecting Data ..." >> $logfile
echo "==========================" >> $logfile

exit 0
