#!/bin/ksh
# Script Name:                  ha_report.ksh
# Author:                       Mohankumar Gandhi
# EMAIL:                        mohankumarg@in.ibm.com
# Creation Date:                10th Aug 2017
# Function 1: Try to identify the reason for the recent reboot.
# Function 2: Ping test between the cluster pair.
# Function 3: Analyzing the cl_event_summary log.
# Function 4: Analyzing the cluster.log.
# Function 5: Analyzing the cspoc.log.
# Function 6: Analyzing the Cluster health status.
# Function 7: Analyzing the clverify.log.
# Function 8: Analyzing the Resource Group(s).
# Function 9: Analyzing the cluster ODM verification across cluster participant nodes.
# Function 10: Checking the existence of "config_too_long" process.
# Version = 9.0
NODE=$(hostname)
HA_REP_SUMM="/tmp/ha_rep_summ.log"
echo "\033[1;36m*************************************************************\033[m"
echo "\033[1;36m          STARTING THE HA REPORT FOR $NODE SERVER         \033[m"
echo "\033[1;36m*************************************************************\033[m"
echo " "
### START THE ERRPT PORTION TO CHECK SHUTDOWN/REBOOT
echo "\033[1;33m*******   STARTING THE ERRPT PORTION TO CHECK SHUTDOWN/REBOOT/HA ERRORS   *******\033[m"
echo " $NODE server's recent Reboot/Shutdown status"
echo "----------------------------------------------------------------------------"
SHUT_REBO_LOG="/tmp/shut_rebo.log"
SW_PROB_LOG="/tmp/sw_prob.log"
HW_PROB_LOG="/tmp/hw_prob.log"
HA_PROB_LOG="/tmp/ha_prob.log"
REB_ID="2BFA76F6"
REB_ERR=$(errpt -aj 2BFA76F6)
> /tmp/ha_rep_summ.log
> /tmp/shut_rebo.log
> /tmp/sw_prob.log
> /tmp/hw_prob.log
> /tmp/ha_prob.log
Curr_date=$(date "+%m%d%H%M%y")
Ydate=$(perl -MPOSIX -e 'print strftime ("%m%d%H%M%y\n", localtime(strftime ("%s", localtime) - 86400))')
# Ydate=$(date +"%m$(date +"%d" | awk '{ printf ("%02d",($1-2)) }')%H%M%y")
errpt -J REBOOT_ID,ERRLOG_ON,ERRLOG_OFF,SYS_RESET,DUMP_STATS,MINIDUMP,KERNEL_PANIC,DOUBLE_PANIC,CONFIGRM_REBOOTOS_E -s $Ydate -e $Curr_date |grep -v IDENTIFIER >> $SHUT_REBO_LOG
errpt -J DSI_PROC,ISI_PROC,PROGRAM_INT -s $Ydate -e $Curr_date |grep -v IDENTIFIER >> $SW_PROB_LOG
errpt -J SCAN_ERROR_CHRP,SCANOUT -s $Ydate -e $Curr_date |grep -v IDENTIFIER  >> $HW_PROB_LOG
errpt -J TS_DMS_WARNING_ST,CL_LOST_AHAFS_EVENT,TS_CRITICAL_CLNT_ER,CL_DEADMAN_LIMIT,CL_REPOS_DISK_DOWN,CL_REPOS_INACCESS,CL_NETWORK_ISSUE,CL_MULTICAST_BLOCK,CL_ARU_FAILED,CL_AST_PANIC,TS_CL_CLINFO_ER,TS_CL_CLINFOFMT_ER,TS_CL_CLREG_ER,TS_CL_CLREGWR_ER,TS_CL_CMDFAIL_ER,TS_CL_DUPINFO_ER,TS_CL_FATAL_GEN_ER,TS_CL_INVCLINFO_ER,TS_CL_NO_TSTBL_ER -s $Ydate -e $Curr_date |grep -v IDENTIFIER  >> $HA_PROB_LOG

if [[ -s $SHUT_REBO_LOG ]] ; then
    echo "\033[1;31m Problem: $NODE got rebooted within 2 days\033[m"
    echo "\033[1;31m Problem: $NODE got rebooted within 2 days\033[m" >> $HA_REP_SUMM
    echo " Checking REBOOT_ID on the $NODE"
        if [[ $(errpt -J REBOOT_ID,ERRLOG_ON,ERRLOG_OFF,SYS_RESET,DUMP_STATS,MINIDUMP -s $Ydate -e $Curr_date |grep -v IDENTIFIER |awk '{print $1}' |grep "2BFA76F6") == "$REB_ID" ]] ; then
        echo "----------------------------------------------------------------------------"
        echo " ERRPT Details for the Reboot"
        echo "----------------------------------------------------------------------------"
        cat "$REB_ERR"
        echo "----------------------------------------------------------------------------"
        else
        echo " Unable to identify the REBOOT type, Please check errpt manually"
        fi
else
    echo "\033[1;32m Good: $NODE did not reboot within 2 days\033[m"
fi
echo " "

if [[ -s $SW_PROB_LOG ]] ; then
    echo "\033[1;31m Problem: $NODE might crashed within 2 days due to the Software Error, Please check errpt\033[m"
    echo "\033[1;31m Problem: $NODE might crashed within 2 days due to the Software Error, Please check errpt\033[m" >> $HA_REP_SUMM
        echo "----------------------------------------------------------------------------"
        echo " ERRPT Details for the Software Error"
        echo "----------------------------------------------------------------------------"
        cat "$SW_PROB_LOG"
        echo "----------------------------------------------------------------------------"
else
    echo "\033[1;32m Good: $NODE did not crash due to any Software Error within 2 days \033[m"
fi
echo " "

if [[ -s $HW_PROB_LOG ]] ; then
    echo "\033[1;31m Problem: $NODE might crashed within 2 days due to Hardware Malfunction \033[m" 
    echo "\033[1;31m Problem: $NODE might crashed within 2 days due to Hardware Malfunction \033[m" >> $HA_REP_SUMM
        echo "----------------------------------------------------------------------------"
        echo " ERRPT Details for the Hardware Malfunction"
        echo "----------------------------------------------------------------------------"
        cat "$HW_PROB_LOG"
        echo "----------------------------------------------------------------------------"
else
    echo "\033[1;32m Good: $NODE did not crash due to any Hardware Malfunction within 2 days \033[m"
fi
echo " "

if [[ -s $HA_PROB_LOG ]] ; then
    echo "\033[1;31m Problem: $NODE might have an issue with PowerHA/HACMP, Please check errpt\033[m" 
    echo "\033[1;31m Problem: $NODE might have an issue with PowerHA/HACMP, Please check errpt\033[m" >> $HA_REP_SUMM
        echo "----------------------------------------------------------------------------"
        echo " ERRPT Details for the PowerHA/HACMP cluster"
        echo "----------------------------------------------------------------------------"
        cat "$HA_PROB_LOG"
        echo "----------------------------------------------------------------------------"
else
    echo "\033[1;32m Good: $NODE might not have any issue with PowerHA/HACMP within 2 days \033[m"
    echo " "
fi
echo "\033[1;33m*******   END OF THE ERRPT PORTION TO CHECK SHUTDOWN/REBOOT/HA ERRORS   *******\033[m"
echo " "

### END OF ERRPT CHECK ###

### START OF To ping cluster nodes and alert if it is not "Success"
echo "\033[1;35m*******   STARTING THE CLUSTER NODE PING TEST   *******\033[m"
echo "\033[1;34m -----------------------------------------------------------------------------------------------------------------\033[m"
echo "\033[1;34m INFO: If you received a message related to -Invalid name- then there is a problem with clusternode configuration \033[m"
echo "\033[1;34m INFO: Check and Configure the clusternode names as per KP's standard configuration \033[m"
echo "\033[1;34m -----------------------------------------------------------------------------------------------------------------\033[m"
FiLE="/tmp/cl_node_list1_rg.log"
LOG="/tmp/cl_node_ping1_rg.log"
> /tmp/cl_node_list1_rg.log
> /tmp/cl_node_ping1_rg.log
NODE=$(hostname)
/usr/es/sbin/cluster/utilities/clgetactivenodes -n $NODE >> $FiLE
cat $FiLE | while read SNAME
do
   if [[ "$SNAME" != "$NODE" ]];then
       /etc/ping -c2 $SNAME > /dev/null 2>&1
      if [ $? -eq 0 ]
        then
           echo "---------------------------------------------------------------------------"
           echo " Cluster pair PING status from $NODE,"
           echo "\033[1;32m Good: $SNAME is pingable from $NODE\033[m"
           echo " "
           ## exit 0 
        else
           echo "---------------------------------------------------------------------------"
           echo " Cluster pair PING status from $NODE,"
           echo "\033[1;31m Problem: $SNAME is not pingable from $NODE\033[m" 
           echo "\033[1;31m Problem: $SNAME is not pingable from $NODE\033[m" >> $HA_REP_SUMM
           echo " " 
           ## exit 3
      fi
   else
       echo "\033[1;34m Ignore: $SNAME" is same as "$NODE so ping test is not required\033[m" 
       echo " " 
       ## exit 0
   fi
done
echo "\033[1;35m*******   END OF THE CLUSTER NODE PING TEST   *******\033[m"
echo " "
### END OF To ping cluster nodes and alert if it is not "Success"



### START OF RG FAILOVER REASON ###
#1# System or User initiated failover
#2# Variable define, Local Node, Remote Node
#3# List the recent past 3 days events
#4# Option to choose from those 3 days
#5# Analyze the cl_event_summaries.txt
#6# Display the event reasons
#7# Current state of RG
#8# Current state of Cluster

### START OF ANALYZING THE cl_event_summary file
echo "\033[1;33m*******   STARTING THE CL_EVENT_SUMMARY ANALYZING   *******\033[m"
echo "\033[1;34m -----------------------------------------------------------------------------------------------------------------\033[m"
echo "\033[1;34m INFO: If you received a message related to -Invalid name- then there is a problem with clusternode configuration \033[m"
echo "\033[1;34m INFO: Check and Configure the clusternode names as per KP's standard configuration \033[m"
echo "\033[1;34m -----------------------------------------------------------------------------------------------------------------\033[m"
cl_event_summ="/var/hacmp/log/cl_event_summaries.txt"
LOCAL_NODE=`uname -n`
FiLE="/tmp/cl_node_list1.log"
LOG="/tmp/cl_node_ping1.log"
> /tmp/cl_node_list1.log
> /tmp/cl_node_ping1.log
NODE=$(hostname)

/usr/es/sbin/cluster/utilities/clgetactivenodes -n $NODE >> $FiLE
cat $FiLE | while read SNAME
do
   if [[ "$SNAME" != "$NODE" ]];then
       REMOTE_NODE="$SNAME"
       echo "----------------------------------------------------------------------------"
       echo " Remote node of this $NODE is $REMOTE_NODE"
       echo "----------------------------------------------------------------------------"
   else
       echo " $NODE is Local-Node" > /dev/null 2>&1
   fi
done
> /tmp/cl_even_desc.info
echo "### Cluster_event_summary_variables ###
TE_SWAP_ADAPTER;" Event Meaning: Script run to swap IP Addresses between two network adapters."
TE_SWAP_ADAPTER_COMPLETE;" Event Meaning: Script run after the swap_adapter script has successfully completed."
TE_NETWORK_UP;" Event Meaning: Script run after a network has become active."
TE_NETWORK_DOWN;" Event Meaning: Script run when a network has failed."
TE_NETWORK_UP_COMPLETE;" Event Meaning: Script run after the network_up script has successfully completed."
TE_NETWORK_DOWN_COMPLETE;" Event Meaning: Script run after the network_down script has successfully completed."
TE_NODE_UP;" Event Meaning: Script run when a node is attempting to joins the cluster."
TE_NODE_DOWN;" Event Meaning: Script run when a node is attempting to leave the cluster."
TE_NODE_UP_COMPLETE;" Event Meaning: Script run after the node_up script has successfully completed."
TE_NODE_DOWN_COMPLETE;" Event Meaning: Script run after the node_down script has successfully completed."
TE_JOIN_STANDBY;" Event Meaning: Script run after a standby adapter has become active."
TE_FAIL_STANDBY;" Event Meaning: Script run after a standby adapter has failed."
TE_ACQUIRE_SERVICE_ADDR;" Event Meaning: Script run to configure a service adapter with a service address."
TE_ACQUIRE_TAKEOVER_ADDR;" Event Meaning: Script run to configure a standby adapter with a service address."
TE_GET_DISK_VG_FS;" Event Meaning: Script run to acquire disks, varyon volumegroups, and mounts filesystems."
TE_NODE_DOWN_LOCAL;" Event Meaning: Script run when it is the ${LOCAL_NODE}, it is leaving the cluster."
TE_NODE_DOWN_LOCAL_COMPLETE;" Event Meaning: Script run after the node_down_local script has successfully completed."
TE_NODE_DOWN_REMOTE;" Event Meaning: Script run when it is a ${REMOTE_NODE}, it is leaving the cluster."
TE_NODE_DOWN_REMOTE_COMPLETE;" Event Meaning: Script run after the node_down_remote script has successfully completed."
TE_NODE_UP_LOCAL;" Event Meaning: Script run when it is the ${LOCAL_NODE}, It is joining the cluster."
TE_NODE_UP_LOCAL_COMPLETE;" Event Meaning: Script run after the node_up_local script has successfully completed."
TE_NODE_UP_REMOTE;" Event Meaning: Script run when it is a ${REMOTE_NODE}, it is joining the cluster."
TE_NODE_UP_REMOTE_COMPLETE;" Event Meaning: Script run after the node_up_remote script has successfully completed."
TE_RELEASE_SERVICE_ADDR;" Event Meaning: Script run to configure the boot address on the service adapter."
TE_RELEASE_TAKEOVER_ADDR;" Event Meaning: Script run to configure a standby address on a standby adapter."
TE_RELEASE_VG_FS;" Event Meaning: Script run to unmount filesystems and varyoff volumegroups."
TE_START_SERVER;" Event Meaning: Script run to start application servers."
TE_STOP_SERVER;" Event Meaning: Script run to stop application servers."
TE_CONFIG_TOO_LONG;" Event Meaning: Script run longer time so please check hacmp.out and fix the issue."
TE_EVENT_ERROR;" Event Meaning: Script run when a previously executed script has failed to completed successfully."
TE_RECONFIG_TOPOLOGY_START;" Event Meaning: Topology reconfiguration is starting."
TE_RECONFIG_TOPOLOGY_COMPLETE;" Event Meaning: Topology reconfiguration is completed."
TE_RECONFIG_RESOURCE_RELEASE;" Event Meaning: Release old resources."
TE_RECONFIG_RESOURCE_RELEASE_PRIMARY;" Event Meaning: Release old primary resources."
TE_RECONFIG_RESOURCE_RELEASE_SECONDAR;" Event Meaning: Release old secondary resources."
TE_RECONFIG_RESOURCE_ACQUIRE_SECONDARY;" Event Meaning: Acquire secondary resources."
TE_RECONFIG_RESOURCE_COMPLETE_SECONDARY;" Event Meaning: Acquire completed on secondary resources."
TE_RECONFIG_RESOURCE_RELEASE_FENCE;" Event Meaning: Script to process disk fencing during DARE release."
TE_RECONFIG_RESOURCE_ACQUIRE_FENCE;" Event Meaning: Script to process disk fencing during DARE acquire."
TE_RECONFIG_RESOURCE_ACQUIRE;" Event Meaning: Acquire new resources."
TE_RECONFIG_RESOURCE_COMPLETE;" Event Meaning: Resource reconfiguration is completed."
TE_MIGRATE;" Event Meaning: Migrate cluster from PowerHA SystemMirror Classic to PowerHA SystemMirror/ES."
TE_MIGRATE_COMPLETE;" Event Meaning: Migration from PowerHA SystemMirror Classic is completed."
TE_ACQUIRE_ACONN_SERVICE;" Event Meaning: Script run to move AIX Connections network protocols to service adapters."
TE_SWAP_ACONN_PROTOCOLS;" Event Meaning: Script run to swap AIX Connections network protocols between two network adapters."
TE_GET_ACONN_RS;" Event Meaning: Script run to start AIX Connections services."
TE_RELEASE_ACONN_RS;" Event Meaning: Script run to stop AIX Connections services."
TE_SERVER_RESTART;" Event Meaning: Script to clean up failed application server before attempting restart."
TE_SERVER_RESTART_COMPLETE;" Event Meaning: Script to finish restarting application server."
TE_SERVER_DOWN;" Event Meaning: Script to signal the beginning of an application server shutdown."
TE_SERVER_DOWN_COMPLETE;" Event Meaning: Script to signal the completion of an application server shutdown."
TE_RG_MOVE;" Event Meaning: Script to move a resource group."
TE_RG_MOVE_RELEASE;" Event Meaning: Script to release a resource group during rg_move."
TE_RG_MOVE_ACQUIRE;" Event Meaning: Script to acquire a resource group during rg_move."
TE_RG_MOVE_FENCE;" Event Meaning: Script to process disk fencing during rg_move."
TE_RG_MOVE_COMPLETE;" Event Meaning: Script to signal the completion of a resource group move."
TE_SITE_DOWN;" Event Meaning: Script run when a site is attempting to leave the cluster."
TE_SITE_DOWN_COMPLETE;" Event Meaning: Script run after the site_down script has successfully completed."
TE_SITE_DOWN_LOCAL;" Event Meaning: Script run when it is the local-site, it is leaving the cluster."
TE_SITE_DOWN_LOCAL_COMPLETE;" Event Meaning: Script run after the site_down_local script has successfully completed."
TE_SITE_DOWN_REMOTE;" Event Meaning: Script run when it is a remote-site, it is leaving the cluster."
TE_SITE_DOWN_REMOTE_COMPLETE;" Event Meaning: Script run after the site_down_remote script has successfully completed."
TE_SITE_UP;" Event Meaning: Script run when a site is attempting to joins the cluster."
TE_SITE_UP_COMPLETE;" Event Meaning: Script run after the site_up script has successfully completed."
TE_SITE_UP_LOCAL;" Event Meaning: Script run when it is the local-site, it is joining the cluster."
TE_SITE_UP_LOCAL_COMPLETE;" Event Meaning: Script run after the site_up_local script has successfully completed."
TE_SITE_UP_REMOTE;" Event Meaning: Script run when it is a remote-site, it is joining the cluster."
TE_SITE_UP_REMOTE_COMPLETE;" Event Meaning: Script run after the site_up_remote script has successfully completed."
TE_SITE_MERGE;" Event Meaning: Script run when first geo_primary network recovers."
TE_SITE_MERGE_COMPLETE;" Event Meaning: Script run when after site_merge completes."
TE_SITE_ISOLATION;" Event Meaning: Script run when all geo_primary networks at a site go down."
TE_SITE_ISOLATION_COMPLETE;" Event Meaning: Script run when after site_isolation completes."
TE_FAIL_INTERFACE;" Event Meaning: Script run after an interface has failed."
TE_JOIN_INTERFACE;" Event Meaning: Script run after an interface has recovered."
TE_CLUSTER_NOTIFY;" Event Meaning: Script to process cluster notification event."
TE_RESOURCE_ADD;" Event Meaning: Add resources to the PowerHA SystemMirror cluster."
TE_RESOURCE_MODIFY;" Event Meaning: Changes the configuration of resources inthe PowerHA SystemMirror cluster."
TE_RESOURCE_DELETE;" Event Meaning: Removes resources from the PowerHA SystemMirror cluster."
TE_RESOURCE_ONLINE;" Event Meaning: Activates resources inthe PowerHA SystemMirror cluster."
TE_RESOURCE_OFFLINE;" Event Meaning: De-activates resources inthe PowerHA SystemMirror cluster."
TE_RESOURCE_STATE_CHANGE;" Event Meaning: Trigger event to move resourcegroups."
TE_RESOURCE_STATE_CHANGE_COMPLETE;" Event Meaning: End of resource state change event."
TE_EXTERNAL_RESOURCE_STATE_CHANGE;" Event Meaning: Event with user-requested resource group migration."
TE_EXTERNAL_RESOURCE_STATE_CHANGE_COMPLETE;" Event Meaning: Completion event with user-requested resource group migration."
TE_INTERSITE_FALLOVER_PREVENTED;" Event Meaning: Script to signal that intersite fallover was prevented."
TE_RECONFIG_CONFIGURATION_COMPLETE;" Event Meaning: Script to signal that end of reconfiguration."
TE_FORCED_DOWN_TOO_LONG;" Event Meaning: Script run when at least one of the nodes inthe Cluster has been forced down due to too long."
TE_START_UDRESOURCE;" Event Meaning: Script run to start user defined resource."
TE_STOP_UDRESOURCE;" Event Meaning: Script run to stop user defined resource."
TE_SPLIT_MERGE_PROMPT;" Event Meaning: Script to prompt the operator, manual choice on splits or merge."" > /tmp/cl_even_desc.info

### Checking the existence of "cl_event_summaries.txt" file
if [ ! -f $cl_event_summ ]; then
echo "----------------------------------------------------------------------------"
echo " There is no /var/hacmp/log/cl_event_summaries.txt file on this $NODE Server"
echo "----------------------------------------------------------------------------"
echo " " 
else
total_last_events_log="/tmp/total_last_events.log"
> /tmp/total_last_events.log

LAST_EVENT_TIME=$(cat $cl_event_summ |egrep -i "Event:|Start time|End time" |tail -1 |awk ' {print $3,$4,$5,$6,$7}')
# cat /var/hacmp/log/cl_event_summaries.txt |egrep -i "Event:|Start time|End time" |tail -1 |awk ' {print $3,$4,$5,$6,$7}'
LAST_EVENT_DAY=$(cat $cl_event_summ |egrep -i "Event:|End time" |tail -1 |cut -c 1-20)
# LAST_EVENT_DAY=$(cat /var/hacmp/log/cl_event_summaries.txt |egrep -i "Event:|End time" |tail -1 |cut -c 1-20)
TOTAL_LAST_EVENTS=$(cat $cl_event_summ |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=3 a=1 s="End" |sed '/^\s*$/d'|grep -v "SystemMirror" |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=2 s="$LAST_EVENT_DAY" |sed '/^\s*$/d')

##TOTAL_LAST_EVENTS=$(cat $cl_event_summ |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=1 a=2 s="Start" |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=1 a=2 s="$LAST_EVENT_DAY" |sed '/^\s*$/d')
echo "$TOTAL_LAST_EVENTS" >> /tmp/total_last_events.log
##TOTAL_LAST_EVENTS=$(cat /var/hacmp/log/cl_event_summaries.txt |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=1 a=2 s="Start" |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=1 a=2 s="Sat Sep 30" |sed '/^\s*$/d')

### cat /var/hacmp/log/cl_event_summaries.txt |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=3 a=1 s="End" |sed '/^\s*$/d'|grep -v "SystemMirror" |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=2 s="End time: Sun Sep  4" |sed '/^\s*$/d'

### cat /var/hacmp/log/cl_event_summaries.txt |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=3 a=1 s="End" |sed '/^\s*$/d'|grep -v "SystemMirror" |awk 'c-->0;$0~s{if(b)for(c=b+1;c>1;c--)print r[(NR-c+1)%b];print;c=a}b{r[NR%b]=$0}' b=2 s="End time: Sat Sep 30" |sed '/^\s*$/d'


echo "----------------------------------------------------------------------------"
echo " Last Cluster Event on $NODE server is on $LAST_EVENT_TIME"
echo " Recent RG related activities on this $NODE server are,"
echo "----------------------------------------------------------------------------"
echo " " 
> /tmp/total_last_events.log1
# cat /tmp/total_last_events.log
cat /tmp/total_last_events.log |grep -i "Event" |awk '{print $2}' |sort |uniq | while read line
do
a=`cat /tmp/cl_even_desc.info | grep -i "$line"`
sed "s/$line/$a/" /tmp/total_last_events.log > /tmp/total_last_events.log1
cp /tmp/total_last_events.log1 /tmp/total_last_events.log
done
#rm /tmp/total_last_events.log1
fi
cat /tmp/total_last_events.log
echo "\033[1;33m*******   END OF THE CL_EVENT_SUMMARY ANALYZING   *******\033[m"
echo " "
### END OF ANALYZING THE CL_EVENT_SUMMARY

### START OF ANALYZING THE CLUSTER.LOG
echo "\033[1;35m********* STARTING THE CLUSTER.LOG ANALYZING *********\033[m"
echo " "
CLuSTER_LOG="/var/hacmp/adm/cluster.log"
if [ ! -f $CLuSTER_LOG ]; then
echo "\033[1;31m Problem: There is no /var/hacmp/adm/cluster.log file on this Server \033[m"
echo "----------------------------------------------------------------------------"
else
total_last_cluster_log="/tmp/total_last_cluster.log"
> /tmp/total_last_cluster.log
CLUSTER_LOG_EVENT=$(cat $CLuSTER_LOG |grep -i "Event")
   if [ -z "$CLUSTER_LOG_EVENT" ];then
   echo "\033[34m INFO: There is NO EVENTS recorded in /var/hacmp/adm/cluster.log \033[m"
   else
   ## LAST_CLUSTER_LOG_EVENT_TIME=$(cat /var/hacmp/adm/cluster.log |egrep -i "Event" |tail -1 |cut -c 1-6)
   LAST_CLUSTER_LOG_EVENT_TIME=$(cat $CLuSTER_LOG |egrep -i "Event" |tail -1 |cut -c 1-6)
   # cat /var/hacmp/adm/cluster.log |egrep -i "Event" |tail -1 |cut -c 1-6
   TOTAL_CLUSTER_LOG_LAST_EVENTS=$(cat $CLuSTER_LOG |grep "$LAST_CLUSTER_LOG_EVENT_TIME" |grep -i Event)
   echo "----------------------------------------------------------------------------"
   echo " Recent cluster.log EVENTS on this $NODE server is on $LAST_CLUSTER_LOG_EVENT_TIME"
   echo "----------------------------------------------------------------------------"
   echo " Recent cluster.log EVENTS on this $NODE server are,"
   echo "----------------------------------------------------------------------------"
   echo "$TOTAL_CLUSTER_LOG_LAST_EVENTS"
   fi
fi
echo " "
#LAST_CLUSTER_LOG_EVENT_TIME=$(cat $CLuSTER_LOG |egrep -i "Event" |tail -1 |awk ' {print $1,$2}')
echo "\033[1;35m*******   END OF THE CLUSTER.LOG ANALYZING   *******\033[m"
echo " "
### END OF ANALYZING THE CLUSTER.LOG ###

### START OF ANALYZING THE CSPOC.LOG
echo "\033[1;33m*******   STARTING THE CSPOC.LOG ANALYZING   *******\033[m"
echo " " 
CsPOC_LOG="/var/hacmp/log/cspoc.log"
if [ ! -f $CsPOC_LOG ]; then
echo "----------------------------------------------------------------------------"
echo "\033[1;31m Problem: There is no /var/hacmp/log/cspoc.log file on this Server \033[m"
echo "\033[1;31m Problem: There is no /var/hacmp/log/cspoc.log file on this Server \033[m" >> $HA_REP_SUMM
echo "----------------------------------------------------------------------------"
else
RES_CspoC=$(tail -1 $CsPOC_LOG |awk '{print $1}')
RES_Cspoc_FAil_ErroR=$(cat $CsPOC_LOG |grep "$RES_CspoC" |egrep -p "FAIL|ERROR")
RES_CspoC_Details=$(cat $CsPOC_LOG |grep -p "$RES_CspoC")
echo "----------------------------------------------------------------------------"
echo " Recent CSPOC activity on this on this $NODE server is on $RES_CspoC"
echo "----------------------------------------------------------------------------"
if [ -z "$RES_Cspoc_FAil_ErroR" ];then
   echo "\033[34m INFO: There is NO ERROR/FAILED state commands in CSPOC.LOG\033[m"
   echo "----------------------------------------------------------------------------"
   else
   echo " CSPOC commands running with ERROR/FAILED state are,"
   echo "----------------------------------------------------------------------------"   
   echo "$RES_Cspoc_FAil_ErroR"
   echo "----------------------------------------------------------------------------"
   fi
   echo " Recent Total CSPOC commands executed on this on this $NODE server are,"
   echo "----------------------------------------------------------------------------"
   echo "$RES_CspoC_Details"
fi
echo " " 
echo "\033[1;33m*******   END OF THE CSPOC.LOG ANALYZING   *******\033[m"
echo " "
### END OF ANALYZING THE CSPOC.LOG ###

### START OF ANALYZING THE CLVERIFY.LOG ###
echo "\033[1;35m*******   STARTING THE CLVERIFY.LOG ANALYZING   *******\033[m"
echo " " 
echo "\033[1;34m -----------------------------------------------------------------------------------------------------------------\033[m"
echo "\033[1;34m INFO: If you received a message related to -Invalid name- then there is a problem with clusternode configuration \033[m"
echo "\033[1;34m INFO: Check and Configure the clusternode names as per KP's standard configuration \033[m"
echo "\033[1;34m -----------------------------------------------------------------------------------------------------------------\033[m"
NODE=$(hostname)
CL_VER_LOG="/var/hacmp/clverify/clverify.log"
if [ ! -f $CL_VER_LOG ]; then
echo "\033[1;31m Problem: There is no /var/hacmp/clverify/clverify.log file on this Server \033[m" >> $HA_REP_SUMM
echo "\033[1;31m Problem: There is no /var/hacmp/clverify/clverify.log file on this Server \033[m"
echo "----------------------------------------------------------------------------"
else
CL_VER_LOG=/var/hacmp/clverify/clverify.log
CL_STAT=$(lssrc -ls clstrmgrES |grep -i state |awk '{print $3}')
SDATE=$(ls -al $CL_VER_LOG |awk '{print $6$7}')
CURRENT_DATE=$(date +%b%-d)

### Check the cluster status and alert ###
 if [ "$CL_STAT" != "ST_STABLE" ];then
 ### Cluster is not stable
        echo "----------------------------------------------------------------------------"
        echo " Cluster Status on this $NODE server is,"
        echo "----------------------------------------------------------------------------"
        echo "\033[1;31m Problem: Cluster status is NOT STABLE in "$NODE" server\033[m" >&2
        echo "\033[1;31m Problem: Cluster status is NOT STABLE in "$NODE" server\033[m" >> $HA_REP_SUMM
        echo " "  
 else
        echo "----------------------------------------------------------------------------"
        echo " Cluster Status on this $NODE server is,"
        echo "----------------------------------------------------------------------------"
        echo "\033[1;32m Good: Cluster is STABLE on the $NODE \033[m"
        echo " "
        ### Check to see if this node is the first node in the list.
        if [ "$(/usr/es/sbin/cluster/utilities/clgetactivenodes -n $(hostname) | sort | head -1)" != "$NODE" ];then
        ## Node is not a first node
               echo "\033[1;34mIgnore: $Node is not a first node in the cluster\033[m"
        elif [ "$SDATE" == "$CURRENT_DATE" ];then
              STATE=$(grep "Check:" /var/hacmp/clverify/clverify.log |sort |uniq)
           if [ "$STATE" == "Check: PASSED" ];then
               echo "----------------------------------------------------------------------------"
               echo " Cluster Verification Status on this $NODE server is,"
               echo "----------------------------------------------------------------------------"               
               echo "\033[1;32m Good: Cluster Verification is PASSED on "$NODE" server \033[m" >&2
           else
               echo "----------------------------------------------------------------------------"
               echo " Cluster Verification Status on this $NODE server is,"
               echo "----------------------------------------------------------------------------"
               echo "\033[1;31m Problem: Cluster verification ran with the ERROR on "$NODE", please check /var/hacmp/clverify/clverify.log \033[m" >&2
               echo "\033[1;31m Problem: Cluster verification ran with the ERROR on "$NODE", please check /var/hacmp/clverify/clverify.log \033[m" >> $HA_REP_SUMM
           fi
        else
## clverify.log is not on current date
               echo "----------------------------------------------------------------------------"
               echo " Cluster Verification Status on this $NODE server is,"
               echo "----------------------------------------------------------------------------"
               echo "\033[1;31m Problem: Cluster verification did not run today on "$NODE" \033[m" >> $HA_REP_SUMM
               echo "\033[1;31m Problem: Cluster verification did not run today on "$NODE" \033[m" >&2
               echo "\033[0;31m Note: Check the timestamp of the /var/hacmp/clverify/clverify.log \033[m"
               echo "\033[0;31m Check any recent activity that stopped or restarted clcomd \033[m"
               echo "\033[0;31m Manually run /usr/es/sbin/cluster/utilities/clupdatetimers \033[m"
        fi
 fi
fi
echo " " 
echo "\033[1;35m*******   END OF THE CLVERIFY.LOG ANALYZING   *******\033[m"
echo " "
### END OF ANALYZING THE CLVERIFY.LOG

### START OF RG STATUS
echo "\033[1;33m*******   STARTING THE RESOURCE GROUP STATUS ANALYZING   *******\033[m"
echo " Resource Group Status on the $NODE server is,"
echo "---------------------------------------------------------------------------"
/usr/es/sbin/cluster/utilities/clRGinfo
echo " "
NODE=$(hostname)
Cl_RG_list_log="/tmp/Cl_RG_list_rg.log"
> /tmp/Cl_RG_list_rg.log
/usr/es/sbin/cluster/utilities/clshowres |grep "Resource Group Name" |awk '{print $4}' >> $Cl_RG_list_log

if [[ -s $Cl_RG_list_log ]] ; then
       echo "---------------------------------------------------------------------------"
       echo " List of Resource Groups (RGs) on this $NODE server is,"
       echo "---------------------------------------------------------------------------"
       cat $Cl_RG_list_log
       echo "---------------------------------------------------------------------------"
       echo " "
          for rg_name in `cat $Cl_RG_list_log` 
          do
          echo " Participating Nodes for the RG $rg_name are,"
          /usr/es/sbin/cluster/utilities/clshowres -g $rg_name |grep "Participating Node Name"
          echo "---------------------------------------------------------------------------" 
          echo " Primary/Home Node of the RG $rg_name is `/usr/es/sbin/cluster/utilities/clshowres -g "$rg_name" |grep "Participating" |awk '{print $4}'`"
          PNODE=$(/usr/es/sbin/cluster/utilities/clshowres -g $rg_name |grep "Participating Node Name" |awk '{print $4}')
          echo " Secondary Node of the RG $rg_name is `/usr/es/sbin/cluster/utilities/clshowres -g "$rg_name" |grep "Participating" |awk '{print $5}'`"
          echo " RG $rg_name is online on `/usr/es/sbin/cluster/utilities/clRGinfo |grep "$rg_name" |grep ONLINE | awk '{print $3}'`" 
          ONODE=$(/usr/es/sbin/cluster/utilities/clRGinfo |grep "$rg_name" |grep ONLINE | awk '{print $3}' )
              if [[ "$PNODE" == "$ONODE" ]];then
                 echo "\033[1;32m Good: RG $rg_name is ONLINE on HOME-Node \033[m"
                 echo " " 
                 else
                 echo " RG $rg_name is either \033[1;31mNOT ONLINE on HOME-Node or with ERROR state\033[m, Please check..."
                 echo "---------------------------------------------------------------------------"  
              fi
          done
else
       echo "---------------------------------------------------------------------------"
       echo " There is no Resource Groups (RGs) on this $NODE server"
       echo "---------------------------------------------------------------------------"
fi
echo "\033[1;33m*******   END OF THE RESOURCE GROUP STATUS ANALYZING   *******\033[m"
echo " "
### END OF RG STATUS

### START OF To Validate the cluster ODM values and alert if it is not "Good"
echo "\033[1;35m*******   STARTING THE CLUSTER ODM STATUS ANALYZING, PLEASE WAIT......  !!!  *******\033[m"
Cl_odm_status_log="/tmp/Cl_odm_status_rg.log"  
> /tmp/Cl_odm_status_rg.log
## /usr/es/sbin/cluster/diag/clconfig >> /tmp/Cl_odm_status_rg.log 2>/dev/null
/usr/es/sbin/cluster/diag/clconfig >> "$Cl_odm_status_log" 2>/dev/null
if [[ -s $Cl_odm_status_log ]] ; then
   ODM_STATE=$(grep "Error" $Cl_odm_status_log |sort |uniq)
     if [ "$ODM_STATE" == "Error" ];then
       echo "---------------------------------------------------------------------------"
       echo " Cluster ODM verification Status on the $NODE server is,"
       echo "---------------------------------------------------------------------------"
       echo "\033[1;31m Problem: Cluster ODM is having ISSUE/MISMATCH on $NODE and it's pair\033[m" 
       echo "\033[1;31m Problem: Cluster ODM is having ISSUE/MISMATCH on $NODE and it's pair\033[m" >> $HA_REP_SUMM
       echo " "
     else
       echo "---------------------------------------------------------------------------"
       echo " Cluster ODM verification Status on the $NODE server is,"
       echo "---------------------------------------------------------------------------"
       echo "\033[1;32m Good: Cluster ODM is good on $NODE\033[m"
       echo " "
     fi
else
       echo "---------------------------------------------------------------------------"
       echo " Cluster ODM verification Status on the $NODE server is,"
       echo "---------------------------------------------------------------------------"
   echo "\033[1;31m Problem: Unable to verify Cluster ODM on $NODE and it's PAIR\033[m"
   echo "\033[1;31m Problem: Clconfig command output is EMPTY, Please check cluster service on $NODE and it's PAIR\033[m"
   echo "\033[1;31m Problem: Unable to verify Cluster ODM on $NODE and it's PAIR\033[m" >> $HA_REP_SUMM
   echo "\033[1;31m Problem: Clconfig command output is EMPTY, Please check cluster service on $NODE and it's PAIR\033[m" >> $HA_REP_SUMM
   echo " "
fi

### END OF To Validate the cluster ODM values and alert if it is not "Good"
echo "\033[1;35m*******   END OF THE RESOURCE GROUP STATUS ANALYZING   *******\033[m"
echo " "
### START OF CHECKING CONFIG_TOO_LONG ISSUE ###
echo "\033[1;33m*******   STARTING TO CHECKING OF CONFIG_TOO_LONG PROCESS EXISTENCE   *******\033[m"
CONF_TOO_LONG=$(ps -ef |grep -i "config_too_long" |grep -v "grep")
   if [ -z "$CONF_TOO_LONG" ];then
   echo "\033[1;32m Good: There is no config_too_long issue with this $NODE server \033[m"
   else
   echo "Problem: config_too_long process is running on this $NODE Server">> $HA_REP_SUMM
   echo "\033[1;31m Problem: config_too_long process is running on this $NODE Server \033[m"
   echo "\033[0;31m Note: If a cluster event, such as a node_up or a node_down event, lasted longer than 360 seconds, \033[m"
   echo "\033[0;31m then every 30 seconds PowerHA SystemMirror issued a config_too_long warning message inside the hacmp.out file.\033[m"
   echo "\033[0;31m Activities that the script is performing take longer than the specified time to complete \033[m"
   echo "\033[0;31m For example, this could happen with events involving many disks or complex scripts \033[m"
   fi
echo " " 
echo "\033[1;33m*******   END OF THE CHECKING OF CONFIG_TOO_LONG PROCESS EXISTENCE   *******\033[m"
### END OF CHECKING CONFIG_TOO_LONG ISSUE ###
echo " " 
if [ -s "$HA_REP_SUMM" ];then
   echo "\033[1;31m*************************************************************************************************************\033[m"
   echo "\033[1;31m                              OVERALL PROBLEM SUMMARIES OF THE $NODE SERVER      \033[m" 
   echo "\033[1;31m        Note: THIS IS JUST A SUMMARY OF THE PROBLEM STATES ALONE, PLEASE READ COMPLETE SCRIPT OUTPUT      \033[m" 
   echo "\033[1;31m*************************************************************************************************************\033[m"
   echo " "
   cat "$HA_REP_SUMM"
   echo " " 
   echo "\033[1;31m*************************************************************************************************************\033[m"
   else
   echo " There is no Problem summary " >> /dev/null 2>&1 
fi

echo "\033[1;36m*************************************************************\033[m"
echo "\033[1;36m            END OF HA REPORT FOR $NODE server         \033[m"
echo "\033[1;36m*************************************************************\033[m"
echo " " 

