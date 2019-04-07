#########################################################################
#                                                                       #
#     To check NFS mount & Unmount if it is mounted more then 48 hours  #
#     Created by : Vaveen Selvam                                        #
#     Created date : 06/14/2017                                         #
#     Version 1.0                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#########################################################################
#!/bin/ksh

Date=`date "+%d-%b-%Y"`
Log_File="/tmp/Nfs_check_$Date"

NFS_mount ()
{
for i in $(mount | egrep '/mnt|/swmount'| awk '{print $3"_:_" $5"_"$6"_"$7}')
do
NFS_mount=$(echo $i | awk -F"_:_" '{print $1}')
Mount_date=$(echo $i | awk -F"_:_" '{print $2}'| sed 's/_/ /g')
export DATE1="$Mount_date"
export DATE2=`date '+%b %d %H:%M'`
DAYSBETWEEN=$(perl -e 'use Time::Local;
my ($day1, $month1, $hour1, $min1) = split /\W+/,$ENV{DATE1};
my ($day2, $month2, $hour2, $min2) = split /\W+/,$ENV{DATE2};
my $time1 = timelocal($min1,$hour1,$day1,$month1) ;
my $time2 = timelocal($min2,$hour2,$day2,$month2) ;
$time = ($time2 - $time1)/86400;
print $time;');
Diff=`echo "$DAYSBETWEEN"`
if [ $Diff -ge 2 ] 2>/dev/null
then
echo "\033[1;31m$NFS_mount was mounted more then 48 hours \033[m"
umount $NFS_mount 2>/dev/null
if [ $? -eq 0 ]
then
echo "\033[1;32m$NFS_mount is unmounted successfully \033[m"
else
fuser -kxuc $NFS_mount 2>/dev/null
if [ $? -eq 0 ]
then
echo "\033[1;32mUser and Process killed successfully \033[m"
else
echo "\033[1;31mUnable to kill the user or process \033[m"
fi
umount -f $NFS_mount 2>/dev/null
if [ $? -eq 0 ]
then
echo "\033[1;32m$NFS_mount is forcefully unmounted \033[m"
else
echo "\033[1;31mUnable to unmount $NFS_mount.Please unmount it manually \033[m"
exit
fi
fi
elif [ $Diff -ge 1 ] 2>/dev/null
then
echo "\033[1;33m$NFS_mount was mounted 24 hours \033[m"
else
echo "\033[1;32m$NFS_mount was mounted below 24 hours \033[m"
fi
done
}
NFS_mount > $Log_File


############################################################
#                                                          #
#Green  - Successfully  exceuted                           #
#Yellow - Warning Message                                  #
#Red    - Unable to perform the action                     #
#                                                          #
############################################################

