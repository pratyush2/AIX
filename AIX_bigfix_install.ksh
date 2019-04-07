#!/bin/ksh
# Script Name:                  AIX_bigfix_install.ksh
# Author:                       Saul Ramos 
# Creation Date:                3/4/10
# Functional Description:       Installs and Configures the AIX Bigfix agent
# Usage:                        ./AIX_bigfix_install.ksh
#
#
# Modification History:
#
# Initials      Date    Modification Description
# --------    --------  ---------------------------------------------------
#
#
############################################################################### 

## VARIABLES ##
sourceServer="czabsu1.crdc.kp.org"
sourceDir="/software/BIGFIX"
targetDir="/usr/local/scripts"
BESAgentPKG="BESAgent-7.2.5.22.ppc_aix51.pkg"
mastHeadFile="actionsite.afxm"
scriptName="AIX_bigfix_install.ksh"
nfsMountCMD="/usr/sbin/mount -o ro,bg,soft,intr,retry=20,proto=tcp" 

## LOGGING ##
logDir="/tmp/"
logFile="${logDir}/$(basename $0).out.$(date +%m%d)"
TIME_STAMP=`date +"%r %h %d %Y"`


#########
# MAIN
#########
# Copy source files
echo "${TIME_STAMP} - Start Installation of Bigfix by $LOGNAME" | tee ${logFile}
/usr/sbin/umount /mnt  >/dev/null 2>&1

#echo "${TIME_STAMP} - Mount ${sourceServer}:${sourceDir} by $LOGNAME" | tee -a ${logFile}
#${nfsMountCMD} ${sourceServer}:${sourceDir} /mnt

#check NFS mounted successfully
#/usr/bin/df |grep /mnt >/dev/null 2>&1
#rc=$?	
#if [[ $rc -ne 0 ]]
#	then 
#echo "${TIME_STAMP} - Failed to mount ${sourceServer}:/${sourcedir} over /mnt" | tee -a ${logFile}
#exit 1
#	else
echo "${TIME_STAMP} - Copy Bigfix package files by $LOGNAME" | tee -a ${logFile}
scp h173047@ktazd216.crdc.kp.org:/home/h173047/tools-aix/${BESAgentPKG} ${targetDir}
scp h173047@ktazd216.crdc.kp.org:/home/h173047/tools-aix/${mastHeadFile} ${targetDir}
#fi

echo "${TIME_STAMP} - Unmount ${sourceServer}${sourceDir} by $LOGNAME" | tee -a ${logFile}
/usr/sbin/umount /mnt >/dev/null 2>&1

echo "${TIME_STAMP} - Installaing BESAdagent package by $LOGNAME" | tee -a ${logFile}
installp -agqYXd ${targetDir}/${BESAgentPKG} BESClient

echo "${TIME_STAMP} - Copying actionsite.afxm file to /etc/opt/BESClient" | tee -a ${logFile}
/usr/bin/cp ${targetDir}/${mastHeadFile} /etc/opt/BESClient/actionsite.afxm

#Clean up temporary files
/usr/bin/rm -f ${targetDir}/${BESAgentPKG} 
/usr/bin/rm -f ${targetDir}/${mastHeadFile} 

echo "${TIME_STAMP} - Starting BESClient ....." | tee -a ${logFile}
/etc/rc.d/rc2.d/SBESClientd start

echo "${TIME_STAMP} - Installation Completed" | tee -a ${logFile}

exit 0
