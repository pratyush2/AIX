#!/bin/ksh
#################################################################
#                                                               #
#     To check BESClient job is completed successfully or not   #
#     Created by : Vaveen Selvam                                #
#     Created date : 21/03/2018                                 #
#     Version 1.0                                               #
#                                                               #
#                                                               #
#                                                               #
#################################################################

OS_type=$(uname -s)
host=$(uname -n)
Date=$(date "+%Y%m%d")
log_dir="/var/adm"
log_file="$log_dir/BESClient_status_log"
Pre_Date=$(perl -MPOSIX -e 'print strftime ("%Y%m%d\n", localtime(strftime ("%s", localtime) - 86400))')
BES_log_dir="/var/opt/BESClient/__BESData/__Global/Logs"
chk_log_file=$(ls -l $BES_log_dir/$Date.log 2>/dev/null)
if [ -z "$chk_log_file" ];then
echo "summary:$host $OS_type:Latest BESClient log file is not created under $BES_log_dir.Please check the BESClient services"
else
stat_log=$(awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=1 a=0 s="Report posted successfully" $BES_log_dir/$Date.log | tail -2 | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $2,$5,$6,$7}')
 if [ -z "$stat_log" ];then
 echo "BES_Client is not communicating with server today.Hence checking the previous day log: $Pre_Date.log"
 Pre_stat_log=$(awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=1 a=0 s="Report posted successfully" $BES_log_dir/$Pre_Date.log | tail -2 | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $2,$5,$6,$7}')
  if [ -z "$Pre_stat_log" ];then
  echo "summary:$host $OS_type: BESclient not reporting for more than a day"
  else
  echo "PASS: $Pre_Date $Pre_stat_log"
  fi
 else
 echo "PASS: $Date $stat_log"
 fi 
fi > $log_file

