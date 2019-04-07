#!/bin/ksh
#
# Filename = nmon_cron.ksh
# Location = /usr/local/scripts
# Permissions = 754
# Ownership = root:system
# Author = Mike Wodei
# Date = 25APR18
#
#
# Set Variables
#
# Set interval for snapshots in minutes
INTERVAL=5
# Get Current Time
eval $(date +"%H:%M" | awk -F: '{print "h="$1";m="$2}')
# Calculate number of samples until midnight
SAMPLES=$(( ((24-$h)*60-$m)/$INTERVAL ))
# Set File output Directory
NMONDIR="/tmp/nmon"
#
# End Variables


# Validate file output directory
ls -ld $NMONDIR 1>/dev/null 2>&1
if [ $? != 0 ]
  them
    mkdir $NMONDIR
    ls -ld $NMONDIR 1>/dev/null 2>&1
    if [ $? = 0 ]
      then
        chmod 664 $MONDIR
      else
        exit 1
     fi
  else
    #compress files older than 1 day 
    /bin/find $NMONDIR -name '*.nmon' -mtime +1 | xargs -n1 gzip $f  1>/dev/null 2>&1
    #remove files older than 1 week
    /bin/find $NMONDIR -name '*.nmon.gz' -mtime +7 | xargs -n10 rm   1>/dev/null 2>&1
fi

#run nmon data collection
/usr/bin/nmon -f -T -d -A -M -P -m $NMONDIR -s $(( 60*$INTERVAL )) -c $SAMPLES

