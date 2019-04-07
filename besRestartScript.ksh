#!/bin/ksh
#touch /var/opt/BESClient/__BESData/__Global/Logs/BESERR.log
HOSTNAME=$(hostname)
if [ ! -f "/var/opt/BESClient/__BESData/__Global/Logs/BESMain.Log" ];then
touch /var/opt/BESClient/__BESData/__Global/Logs/BESMain.Log;
fi
DATE=$(date +"%Y-%m-%d %H:%M")
BESSERVICE="/opt/BESClient/bin/BESClient"
LOGFILE="/var/opt/BESClient/__BESData/__Global/Logs/`date +%Y%m%d`.log"
BESCLIENT=$(ps -ef |grep -i 'bes'|grep -i 'opt'|egrep -v 'grep|RPMHelpe'|awk '{print $9}')
CHECK_MAIN=$(grep -c "Maintenance Mode Enabled" /var/opt/BESClient/__BESData/__Global/Logs/BESMain.Log)
BESERR="/var/opt/BESClient/__BESData/__Global/Logs/BESErr.log"
VARSPACE=$(df -gP /var|awk '{print $5}'|tail -n 1|sed 's/%//')
#BES_SU=$(grep -c "Successful Synchronization" /var/opt/BESClient/__BESData/__Global/Logs/`date +%Y%m%d`.log)

#Check if the BESClient Service is running
if [ -f /var/opt/BESClient/__BESData/__Global/Logs/BESMain.Log -a "$CHECK_MAIN" -gt 0 ];then
  echo "$DATE BESClient is in Maintenance Mode. Exiting." >> $BESERR
  exit 0
fi

if [[ "$BESCLIENT" != "$BESSERVICE" ]]
then
  echo "Service is not running on $HOSTNAME. Starting BESClient" >> $BESERR
  /etc/rc.d/init.d/BESClientd start
  if [ $? -ne 0 ]
    then
      echo "$DATE The Script was unable to restart the BESCleint Services. Please Check Manually. Space in /var is $VARSPACE%" >> $BESERR
      exit 1
    else
      echo "$DATE Services started successfully" >>  $BESERR
  fi
else
  if [ ! -f "$LOGFILE" ]
    then
      echo "Service is running on $HOSTNAME but no logs generated for today"  >> $BESERR
      echo "Restarting the Besclient services" >> $BESERR
      /etc/rc.d/init.d/BESClientd  stop;sleep 3;/etc/rc.d/init.d/BESClientd start
      if [ $? -ne 0 ]
        then
        echo "$DATE The Script was unable to restart the BESCleint Services. Please Check Manually. Space in /var is $VARSPACE%" >> $BESERR
        exit 1
      else
        echo "$DATE Services started successfully" >>  $BESERR
      fi
    else
      echo "$DATE Service is running fine and log file is of Today's date" >> $BESERR
  fi
fi

echo "Almost Done. Checking if the server is syncronizing with the relay Server" >> $BESERR
sleep 20

BES_SU=$(grep -c "Successful Synchronization" /var/opt/BESClient/__BESData/__Global/Logs/`date +%Y%m%d`.log)

if [ "$BES_SU" -gt 0 ]
then
  echo "$DATE Syncronizing with the relay Server, Should start reporting to BigFix Server in few Minutes." >> $BESERR
  exit 0
elif [ "$VARSPACE" -lt 96 ]
then
  echo " $DATE Not Syncronizing with the relay Server, Please check manually. Space in /var is $VARSPACE%" >> $BESERR
  exit 1
fi
