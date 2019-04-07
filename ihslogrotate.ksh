#!/bin/ksh
#==============================================================
#  Author: Sonnie Nguyen
#  Date:   05/13/04
#  Script: ihslogrotate.ksh
#==============================================================
#  NOTE:
#
#  This script written to rotate 1 or more IHS logs files.
#  This script will need the conf file ihslog.conf.
#  
#  Below is the format for ihslog.conf:
#
#  filepath:filename:day of week:1st hr:2nd hr:3 hr:old path
#
#  filepath - The path of the log file
#  filename - Name of the log file
#  day of week - 0=Everyday 1=Monday 2=Tuesday 3=Wednesday
#		 4=Thursday 5=Friday 6=Saturday 7=Sunday
#  example 1
#  /logs/NKP:access.log:3:2:::/logs/oldlogs
#
#  Configuration above is set for rotate log /logs/NKP/access.log
#     to /logs/oldlogs at 2am every Wednesday.
#
#  example 2
#  /logs/NKP:access.log:0:2:::/logs/oldlogs
#
#  Configuration above is set for rotate log /logs/NKP/access.log
#     to /logs/oldlogs at 2am everyday of the week.
#
#  Currently, this script only run 1 day of the week or everyday
#  If you want to setup for multiple days of the week, you can
#  do so by creating another line item in the ihslog.conf
# 
#  This script must have <ihslog.conf> file to work.
#==============================================================
#  Modification History
#     05/13/04:sonnie:Created the script
#==============================================================
# USAGE:
#        ./ihslogrotate.ksh 
#==============================================================
logconf=/home/snguyen/ihslogs/ihslogs.conf
logfile=/usr/local/scripts/ihsrotate.log

alias open_e=exec

if [ -f $logconf ]; then
   open_e 3<$logconf
else
   echo "\n==== WARNING !!!  there's no $logconf file" >> $logfile
   exit
fi

open_e 3<$logconf

FPATH=""
LFILE=""
DOW=""
HR1=""
HR2=""
HR3=""
LPATH=""
CURDOW=""
CURHR=""
GZIP="/usr/local/bin/gzip"

while read -u3 lineA
do
   FPATH=`echo $lineA | cut -f 1 -d :`
   LFILE=`echo $lineA | cut -f 2 -d :`
   DOW=`echo $lineA | cut -f 3 -d :`
   HR1=`echo $lineA | cut -f 4 -d :`
   HR2=`echo $lineA | cut -f 5:`
   HR3=`echo $lineA | cut -f 6 -d :`
   LPATH=`echo $lineA | cut -f 7 -d :`
   #SINGLEFILE=`echo $FPATH | cut -f 3 -d /`
   OLDFILE=$LPATH"/"$LFILE.`date +%m%d%y%H%M`
   echo "$DOW"
   if [ "$DOW" = 0 ]; then
      CURDOW="0"
   else
      CURDOW=`date +%u`
   fi
   CURHR=`date +%H`
   #echo "$CURDOW, $CURHR"

   if [ -f $FPATH ]; then
      dowhr=$CURDOW+$CURHR
      case "$dowhr" in
         $DOW+$HR1)
	    echo "Running 1st logrotate" >> $logfile
	    cp $FPATH/$LFILE $LPATH/$OLDFILE
	    sleep 60
	    cp /dev/null $FPATH
	    sleep 60
	    $GZIP $LPATH/$OLDFILE
	    ;;
	 $DOW+$HR2)
	    echo "Running 2nd logrotate" >> $logfile
	    #cp $FPATH $OLDFILE
	    cp $FPATH/$LFILE $LPATH/$OLDFILE
	    sleep 60
	    cp /dev/null $FPATH
	    sleep 60
	    $GZIP $LPATH/$OLDFILE
	    ;;
	 $DOW+$HR3)
	    echo "Running 3nd logrotate" >> $logfile
	    #cp $FPATH $OLDFILE
	    cp $FPATH/$LFILE $LPATH/$OLDFILE
	    sleep 60
	    cp /dev/null $FPATH
	    sleep 60
	    $GZIP $LPATH/$OLDFILE
	    ;;
      esac
   else
      echo "No log file found..." >> $logfile
   fi
done
exit
