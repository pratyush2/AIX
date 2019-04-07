#!/bin/ksh
##############
# mksysb and alt_disk copy version 2.0
#
# Due to convergence of scripts, this script starts at 2.0
# v2 Feb 08 2011 - MWS - Initial Version 
# 2.131 31 May 2011 - MWS - Changed copy_mksysb to handle date change 
# 2.2 11 oct 2011 MWS - Added Checks, changed verification
# 2.3 11 Jan 2012 MWS - Added logging functions
# 2.4 6 Sept 2012 MWS - Added logic to not use /mksysb/.server
# 2.5  Susith Ruwanpura made following changes
# 2.5 Added extra DMZ functions to collect cfg2html 
# 2.6 Removed ipl_varyon command use. Introduce lqueryvg for checking BLV
#     Changed alt_disk logic to look for disks the same size
# 2.7 Added code to use backup interface on both source and target
#	No version change - 11/13/2014 - fixed the bug that fills /etc/eclude.rootvg with duplicate entries
#
#	Version change - V2.8 03/31/2015 - Modified to support SAN boot disks
#	mysysb_command fucntion updated
#	alt_disk_copy functions changed to accomodate SAN boot
#	removed lspv command to reduce execution time
#Bug fixes - V 2.8 - No versoin change
#	Adding version to log file
#	Declare existing variables at the begining of script
#	New disk type sisarray should be included in the search pattern June 19 2015
#Version change 2.91-08-06-2015
#	SAN boot servers picking up Oracle disks when disk for image_1 is selected 
#Version change 2.91-08-14-2015
#Bug fixes
#	When image is SYMM_RAID device, detect the right power disk name 08/14/2015
#
#	When hostname has temporary extension, the repository is not found Ex, xxxxxx99new Oct 2015
#	Backup Lebel can be different on non standard host names. updated on Oct 20, 2015 V2.92-10-20-2015
#	Version release 01-06-2016
#	ssh time out changed from 9 sec to 20 secs
#	ping replaced with traceroute to default backup gateway
#Version V2.96-01-10-2018
#	html file copied directly to UES web servers
#	Bug fixes, mainly on loggin process infor
#Version V2.97-03-30-2018
#	Bug fixes, previous version could not identify backup IP and hostname correctly on some servers
#	Bug fixes, identifying a suitable image_1 disk on powervc deployment
#Version V2.97-04-05-2018
#	Bug fixes, backup route in not recognized on AIX 7.2 traceroute output format
#Version V2.97-04-10-2018
#	For IVDC there is no backup server. Removing warning and errors for DCs without backup Repo
#	For all domains without dedicated Repo, warning about backup interface removed.
#Version V2.98-05-29-2018
#	SCP seem to fail due to unknown reason. Adding code to try 5 times before reporting failure
#	GZIP will not be attempted if the space usage is more than 65%
#
#Version V2.99-06-19-2018
#	Dedicated servers with unmirrored rootvg could not create image_1 for other two disks
#	Gatekeeper disks, size less than 5 GB omitted in selecting
#	Introduced check for server response time 07/26/2018
#	Added one hour wait for even numbered servers
#	HTML log file creation had a minor bug. Fixed on 08/02/2018
#Version V3.00-08-17-2018
#	Aug 17 2018, SW Repo is not seen by PCI/DMZ servers
#	Aug 23 2018, when file in repo is good, file copy does not happen
#Version V3.01-10-10-2018
#	Oct 10, 2018. PDC becomes default repo 
#	Oct 10, 2018. when DOMAIN is KP, will seach for data center name
#	Oct 22, 2018. WDC will be moved to PDC. When WDC servers not pingable, repos set to PDC
#Version V3.02-11-11-2018
#	Nov 2018, the servers will be moved to PSAAS, and the server names will get Xzabbsc1/2 name
#
#Version V3.03-14-12-2018
#	Dec 2018, introduction of NVMe disks nvmdisk
#	Dec 2018, -tmp -new host names to be accepted
##############

RCCS="@(#)backupos-V3.03-14-12-2018"     # version
VERSION=$(echo $RCCS | cut -c5-)

## VARIABLES ##
StartFucn=
sshsuccess=1
mksysbServer='pzabbs1.pldc.kp.org'
HomeDir="/usr/local/scripts/"
logDir=/var/log
HostName=`hostname|awk -F. '{print $1}'`
ClientName=`hostname|cut -d\. -f1`
logfilename=${HostName}.osbackup.log
itmlogfilename=backupos.itm.log
DATETIME=`date +"%D-%H:%M"`
DATE=`date +"%m%d%Y"`
MksysbFile=${HostName}.mksysb.${DATE}
GzipMksysbFile=${MksysbFile}.gz
MksysbFiletoSend=
_MksysbStatus=1
SSH_TestAttempt=0
EngCopySucc=1
SuCopySucc=1
WaitTime=15
PingWait=12
TryAgain=Yes
MyPID=$$
SSHCMD=' '		#03/31/2015
SCPCMD=' '              #03/31/2015
HNseq=			#10/19/2015  #Host name Serial Num
SCPPID=			#01/18/2017
SwRepo=${SwRepo:-pzabsu1.pldc.kp.org}
IsUP=${IsUP:-Down}
TarGetIP=
>/tmp/osbackup.temp.log

ThisHost=$HostName
## LOGGING ##
logFile="${logDir}/${logfilename}"
ITMlogFile="${logDir}/${itmlogfilename}"
HtmlFile="${HostName}.osbackup.log.html"
htmllogfile="/var/log/${HtmlFile}"
ScpStatus='InProgress'

#Get the host name sequence number
HostNameTrunc=`hostname |awk -F. '{print $1}' | sed 's/v1$//g; s/h$//g; s/v2$//g'`
Length=$(echo $HostNameTrunc | wc -c | bc)
i=0
while [[ $i -lt $Length ]]; do
  let  i=$i+1
  Lett=$(echo $HostNameTrunc | cut -c$i | tr -d '[a-z] [A-Z]')  #Filter only digits
  if [[ X != X$Lett ]]; then
   HNseq="${HNseq}${Lett}"
  else
   if [[ X == X$HNseq ]]; then
    continue
   else
     break
   fi
  fi
 done

# Declare functions 
DATETIME() {
  date +"%D-%H:%M:%S"
}

PrintINFO() {
 echo "`DATETIME`     INFO: $* " | tee -a ${logFile}
}
PrintERRO() {
 echo "`DATETIME`    ERROR: $* " | tee -a ${logFile}
}
PrintWARN() {
 echo "`DATETIME`  WARNING: $* " | tee -a ${logFile}
}
PrintSUCC() {
 echo "`DATETIME`  SUCCESS: $* " | tee -a ${logFile}
}
PrintFAIL() {
 echo "`DATETIME`     FAIL: $* " | tee -a ${logFile}
}
PrintSTAT() {
 echo "`DATETIME`   STATUS: $* " | tee -a ${logFile}
}

CFG2KEY="/.ssh/cfg2user.key"
PWOpt='PasswordAuthentication=no -o NumberofPasswordPrompts=0'
UNHF='UserKnownHostsFile=/dev/null'
TimeOUt='ConnectTimeout=30'
HstKeyCheck='StrictHostKeyChecking=no'
AllOpts="-q -i ${CFG2KEY} -o ${PWOpt} -o ${UNHF} -o ${TimeOUt} -o ${HstKeyCheck}"
LogLoc=CRDCLogs

CheckSerRename() {
  SvrSwed=No
  RepoType=$1
  TestForSvr=$2
  TarGetIP=$(host $TestForSvr | awk '{if (/,/) {print $3}else{print $NF}}')
  IsUP=$(ping -w3 -c1 $TestForSvr 2>/dev/null | grep ttl | sed '$!d')  #Ping over default route
  IsUP=${IsUP:-Down}
  if [[ "${IsUP}" == Down ]] && [[ $RepoType == mksysb ]]; then
    NewServerName=$(echo $TestForSvr | sed 's/abbs/abbsc/1')
    SvrSwed=Yes
  elif [[ "${IsUP}" == Down ]] && [[ $RepoType == SwRepo ]]; then
    NewServerName=$(echo $TestForSvr | sed 's/absu/absuc/1')
    SvrSwed=Yes
  fi
  if [[ $SvrSwed == Yes ]]; then
    IsUP=$(ping -w3 -c1 $NewServerName 2>/dev/null | grep ttl | sed '$!d')  #Ping NewmksysbServer over default route
    IsUP=${IsUP:-Down}
    if [[ "${IsUP}" != Down ]] && [[ $RepoType == mksysb ]]; then
       $SCPCMD ${logFile} mksysbu@${NewServerName}:/mksysbfs; SCP_statues=$?
       if [[ $SCP_statues == 0 ]]; then
         mksysbServer=$NewServerName
         PrintINFO "Destination server switched to $mksysbServer"
         TarGetIP=$(host $mksysbServer | awk '{if (/,/) {print $3}else{print $NF}}')
       fi
    elif [[ "${IsUP}" != Down ]] && [[ $RepoType == SwRepo ]]; then
       IsExported=$(showmount -e ${NewServerName} 2>/dev/null | grep software | awk '{print $1}' | sed 's/ //g')
       IsExported=${IsExported:-No}
       if [[ $IsExported != NO ]]; then
         SwRepo=$NewServerName
         PrintINFO "Software Repo server switched to $SwRepo"
       fi
    fi
  fi
}

clean_slate() {
# clean_slate will clear the logfile and will wipe out /mksysbfs each time the script is run
chk4oldlog=`find $logDir -name $logfilename -mtime +6 2>/dev/null`
> $ITMlogFile
# Adding OS level capture 
if [ -f /usr/ios/cli/ioscli ]
then
  find /home -xdev -type f -name core.\* -mtime +30 -exec rm {} \;
  OSNAME="VIO"
  oslevel=`/usr/ios/cli/ioscli ioslevel`
else
  OSNAME="AIX"
  oslevel=`oslevel -s`
  [ -d /opt/core ] && find /opt/core -xdev -type f -mtime +30 ! -name lost\* -exec rm {} \;
fi
PrintINFO "RUNNING $OSNAME $oslevel"

# Adding section to prevent BBS from deleting all of their files
chkhostname=`echo $HostName| egrep -i "bbs|raxbs"`
if [ -z "$chkhostname" ]
then
PrintINFO "CLEANSLATE ACTIVATED. OLD MKSYSBS WILL BE DELETED"
    for oldmksysbfile in `find /mksysbfs -xdev -size +1024k 2>/dev/null`
    do
     PrintWARN "DELETING $oldmksysbfile .. "
     rm $oldmksysbfile
    done

    for rootvgfs in `lsvgfs rootvg | egrep -v '/tmp|/mksysbs|/core'`
    do
      if [[ $rootvgfs == @(audit*) ]]; then
       MaxFSize='51200k'
      else
       MaxFSize='512000k'
      fi
      for bigfile in `find $rootvgfs -size +${MaxFSize} -xdev`
      do
       bigfilesize=`du -sm $bigfile`
       #PrintWARN "LARGE FILE FOUND: $bigfilesize Adding to exclude"
      cat /etc/exclude.rootvg | grep $bigfile >/dev/null && PrintWARN "LARGE FILE $bigfilesize already excluded" || (PrintWARN "LARGE FILE FOUND: $bigfilesize Adding to exclude" && echo "^.$bigfile" >> /etc/exclude.rootvg)
      done
   done
else
        PrintINFO "BBS SERVER. NOT DELETING FILES FROM MKSYSBFS"
fi

#adding section to test SSH connection Doing nothing for the moment
if [ -z $D_FLAG ]
then
	test_ssh_conn
fi
}

mksysb_precheck() {
# the purpose of this function is to perform the following prechecks:
# The existence of /mksysbfs, and the appropriate size 

PrintINFO "STARTING MKSYSB PRECHECK"
ITM_flush
# check for filesystem
chk4mksysbfs=`df -m|grep mksysbfs `
if [ -z "$chk4mksysbfs" ]
then
	PrintERRO "/mksysbfs does not exist! Critcal error."
else

    # Check to see if we can expand temporarily /mksysbfs by 10G if there is 15G free on rootvg 
    chk4freespace=`lsvg rootvg|grep 'FREE PPs:'|cut -d: -f3|awk '{print $2}'|sed 's/(//'`
    mksysbfssize=`df -m /mksysbfs 2>/dev/null |grep -v File|awk '{print $2}'`
    chk4jfs2=`lsfs /mksysbfs 2>/dev/null |grep jfs2`
    resizemksysbfs=0
    if [ $chk4freespace -ge 15000 -a $mksysbfssize -le 10000 -a "$chk4jfs2" ]
    then
        PrintINFO "TEMPORARILY RESIZING MKSYSBFS BY 10G"
	resizemksysbfs=1
	chfs -a size=+10G /mksysbfs
    fi
    chk4mksysbfs=`df -m|grep mksysbfs `

    freespace=`echo $chk4mksysbfs|awk '{print $3}'`
        if [ $freespace -lt 5000 ]
        then
        PrintERRO "/mksysbfs does not have enough space. It only has ${freespace}M . Exitting"
        fi
fi

for rootvgfs in `lsvgfs rootvg`
do
fsfull=`df -m $rootvgfs|grep -v File|awk '{print $4}'|sed 's/%//g'`
	if [ $fsfull -eq 100 ]
	then
		PrintERRO "$rootvgfs is full. CANNOT proceed with mksysb."
	fi
done

# Adding section to ensure script is in crontab
chk4crontab=`crontab -l|grep 'backupos.ksh'|grep -v "^#"`
if [ -z "$chk4crontab" ]
then
     PrintERRO "BACKUPOS IS NOT IN CRONTAB. PLEASE ADD BACKUPOS TO ROOT CRONTAB."
fi

# Initiating HACMP Collection....
chk4HACMP=`lssrc -s clstrmgrES|grep active`
if [ "$chk4HACMP" ]
then
	PrintINFO "STARTING HACMP SNAPSHOT"
	HACMP_info
fi
}

VIO_stagger_start () {
  houroftheday=`date +"%H"`
  if [ "$houroftheday" -le 4 ]
  then
    PrintINFO "SLEEP FOR 60 MINUTES FOR ODD NUMBERED SERVERS"
    
    lastchr=${HNseq%%-*}
    lastchr=${lastchr%%_*}
    lastchr=${lastchr#${lastchr%?}}
    [ $(( $lastchr % 2 )) -eq 1 ] && sleep 3000 || echo $lastchr is even
  fi
}

ReInstallBackup() {
    PrintINFO "Try Re-installing backupos client on this server from ${SwRepo}"
    PrintINFO "Install version before change `what /usr/local/scripts/backupos.ksh | grep V`"
    #Aug 17 2018, SW Repo is not seen by PCI/DMZ servers
    UnMount=No
    IsMOunted=$(df -g | grep -v dev | grep software | sed 1q | awk '{print $NF}')
    IsMOunted=${IsMOunted:-No}
    TrouteTo=
    if [[ ${HostName} == @(draxsu1*|*zabsu1*) ]]; then
       IsMOunted='/software'
       UnMount=No
    fi
    if [[ "X$SwRepo" != X ]] && [[ $IsMOunted == No ]]; then
              #egrep -v "${SwRepo}|traceroute|outgoing|source" | sed '$!d' | grep ms | sed 's/ //g' )
      TrouteTo=$(traceroute -m3 -q1 -w 5 ${SwRepo} 2>&1 |\
              egrep -v "traceroute|outgoing|source" | sed '$!d' | grep ms | sed 's/ //g' )
    elif [[ "X$SwRepo" == X ]]; then
       PrintINFO "Software repo detected as - ${SwRepo} , not mounted yet"
       TrouteTo='Cannot'
    fi

    if [[ $IsMOunted != No ]]; then
      PrintINFO "Software export  from ${SwRepo} is already mounted on $IsMOunted"
    elif [[ X != "X$TrouteTo" ]] && [[ "$TrouteTo" != Cannot ]]; then
      IsExported=$(showmount -e ${SwRepo} 2>/dev/null | grep software | awk '{print $1}' | sed 's/ //g')
      IsExported=${IsExported:-No}
      if [[ $IsExported != No ]] && [[ $IsMOunted == No ]]; then
         [ ! -d /swmount ] && mkdir /swmount
            /usr/sbin/mount -o ro,bg,soft,intr,proto=tcp,retry=1 ${SwRepo}:/software /swmount
            IsMOunted='/swmount'
            UnMount=Yes
      fi
    elif [[ "$TrouteTo" == Cannot ]] && [[ $IsMOunted == No ]]; then
       IsExported=No
       PrintINFO "${SwRepo}:/software cannot be mounted, or traced"
    else
      IsExported=No
       PrintINFO "${SwRepo}:/software cannot be determined"
    fi
    if [[ $IsMOunted != No ]]; then
      PrintINFO "Installing from backupos from  ${IsMOunted}/SCRIPT/OSBACKUP.tar"
      tar -xf ${IsMOunted}/SCRIPT/OSBACKUP.tar
      cp ${IsMOunted}/SCRIPT/backupos.ksh_NextRelease /usr/local/scripts/backupos.ksh >/dev/nul
    fi
     PrintINFO "Version installed `what /usr/local/scripts/backupos.ksh | grep 'V'`"
    if [[ $UnMount == Yes ]]; then
      umount ${IsMOunted}
    fi
}

ITM_flush() {
cat ${logFile} |egrep "SUCCESS|ERROR" > $ITMlogFile
}

PowerDiskName= 		#For SAN boot environment
HdiskType=
ImageDisk=
BootPowerNumber=0 	#For SAN boot environment
BackingDisks= 		#For SAN boot environment
CurrRootDisks=
StartingBootList=
CurrImage1=
altVGname=
SANimage=

BPNumber() {
 NumberOf=$1
     BootPowerNumber=$(echo $NumberOf | tr '[A-Z]' '[a-z]' | sed 's/[a-z]//g')
}

GetPowerDiskName() {
  [ $T_FLAG == TRUE ] && set -x
  TestDisk=$1
  TestDisk=${TestDisk:-NONE}
  [ $TestDisk != NONE ] && HdiskType=$(lsdev -l $TestDisk -F type) || HdiskType=
   if [[ $HdiskType == @(power|Power|SYMM_*) ]]; then
     PowerDiskName=$(odmget -q "value=$TestDisk AND attribute=pnpath" CuAt|grep -w name|sed 's/"//g'| awk '{print $NF}')
     PowerDiskName=${PowerDiskName:-$(powermt display dev=all|egrep -wp ${TestDisk}|grep Pseudo|awk -F= '{print $NF}')}
   else
     PowerDiskName=$TestDisk
   fi
   if [[ $PowerDiskName == @(hdiskpower*) ]]; then
    BackingDisks=$(powermt display dev=$PowerDiskName | grep fscsi | awk '{printf $3 " "}')
    HdiskType=$(lsdev -l $PowerDiskName -F type)
    PrintINFO "$TestDisk - type $HdiskType Disk ${BackingDisks}"
   elif [[ $TestDisk != NONE ]]; then
       BakingDisks=$(lspath -l $TestDisk | sed 's/Enabled //g; s/ /\<\-\>/g' | awk '{printf $0", "}')
       PrintINFO "$TestDisk - type $HdiskType Disk ${BackingDisks}"
   fi
 }

PrepareRootVG() {
[ $T_FLAG == TRUE ] && set -x
 CurrRootDisks=$(lsvg -p rootvg | grep active | awk '{printf $1 " "}' ) #Get active rootvg disks
 SBL=$(bootlist -m normal -o | awk '{printf $0", "}')
 PrintINFO "Starting boot list is ${SBL}"
 FirstBootDisk=`echo $CurrRootDisks | awk '{printf $1}'` #Take one and determine type and backing hdisks if necessary 
 GetPowerDiskName $FirstBootDisk #Get the PowerDiskName and set HdiskType

   if [[ $HdiskType == @(power|Power|SYMM_VRAID|SYMM_VGER) ]]; then
      PrintINFO "Server boot disk is on a SAN boot device"
      SANimage=YES
      #GetPowerDiskName $CurrRootDisks
      pprootdev on >/dev/null #&& pprootdev fix #&& bosboot -ad /dev/ipldevice  #This should fix blv issue
      StartBootListCount=$(echo $StartingBootList | wc -w | bc)
      BackingDiskCount=$(echo ${BackingDisks} | wc -w | bc)
      if [[ $StartBootListCount -ne $BackingDiskCount ]]; then
          for DisK in `echo ${BackingDisks}`
          do
            IsBLV=$(bootlist -m normal -o | grep $DisK | grep blv 2>/dev/null)
            IsBLV=${IsBLV:-Nope}
            if [[ $IsBLV == Nope ]]; then
                PrintINFO "BLV is not seen over $DisK. Trying to add.."
                bosboot -ad $DisK 2>/dev/null
            else
                PrintINFO "BLV is seen over $DisK per bootlist command." 
            fi
          done
      else
        PrintINFO "All backing disks seem to have blv=hd5 on them"
      fi
      bootlist -m normal ${BackingDisks}   #$BackingDisks better
      pprootdev fix >/dev/null
      bosboot -a >/dev/null
      BootDisks=
      lspv | grep rootvg | grep active | awk '{print $1}'  | while read Disk
      do
        bosboot -ad $Disk 2>/dev/null; RC=$?
        if [[ $RC -eq 0 ]]; then
         PrintINFO "BLV is visible through $Disk."
         BootDisks="${BootDisks}${Disk} "
        else
         PrintINFO "BLV is not visible through $Disk. Excluding it from bootlist"
        fi
      done
      bootlist -m normal ${BootDisks}
        #PrintINFO "Setting reserve lock for disk $PowerDiskName"
        #chdev -l $PowerDiskName -a reserve_policy=single_path -P
      StartingBootList=$(bootlist -m normal -o | grep blv | cut -d" " -f1-2 | sort | uniq | awk '{printf $1 " "}')
      CurrRootDisks=$BackingDisks
  fi
#Fix boot list if necessary
  if [[ `echo $CurrRootDisks | wc -w | bc` -ne `bootlist -m normal -o | grep blv | grep -v grep | wc -w | bc` ]]; then
   if [[ $HdiskType == @(scsd|vdisk|sisarray|mpioosdisk|nvmdisk) ]]; then
        bootlist -m normal -o | grep hdisk | grep -v grep | awk '{print $1 " " $2}' | sort | uniq | while read hDisk
        do
         #PrintINFO "Checking current rootvg disk $hDisk for BLV."
         if [[ $hDisk != @(*blv*) ]]; then
           hDisk=$(echo $hDisk | awk '{print $1}')
           PrintINFO "Current rootvg disk $hDisk does not have BLV on it. Fixing"
           bosboot -ad $hDisk
         fi
        done
   fi
   #altVGname=$(lsdev -Ct vgtype -Fname | egrep -w "altinst_rootvg|old_rootvg|image_1")
  else
    PrintINFO "Current Boot list is good"
  fi
}

mksysb_command() {
 [ $T_FLAG == TRUE ] && set -x
 ITM_flush
 VIO_stagger_start
 if [ -f /usr/ios/cli/ioscli ]
 then
	PrintINFO "STARTING VIO BACKUPIOS"
	/usr/ios/cli/ioscli backupios -file /mksysbfs/${MksysbFile} -mksysb 2>&1 | tee -a /tmp/osbackup.temp.log
	cd /mksysbfs
 else
  PrintINFO "mksysb to be taken for an AIX server"
	PrintINFO "STARTING MKSYSB"
	/usr/bin/mksysb '-e' '-i' '-X' '-p' /mksysbfs/${MksysbFile} 2>&1 | tee -a /tmp/osbackup.temp.log
 fi

#Backup Completed Successfully.
cat /tmp/osbackup.temp.log 2>/dev/null | grep "Backup Completed Successfully." >/dev/null; _MksysbStatus=$?

 if [[ $_MksysbStatus -ne 0 ]]; then
	PrintERRO "PROBLEM COMPLETING MKSYSB COMMAND. RC $_MksysbStatus. "
        cat /tmp/osbackup.temp.log | while read line
        do
          PrintINFO "$line"
        done
 else
	PrintSUCC "MKSYSB COMPLETED SUCCESSFULLY. "
 fi
}

mksysb_postcheck() {
  PrintINFO "MKSYSB COMPLETE. BEGINNING POSTCHECK. "
  ITM_flush

  chk4fileexist=`find /mksysbfs -xdev -name $MksysbFile`
  if [ -z "$chk4fileexist" ]
  then
	PrintERRO "MKSYSB FILE DOES NOT EXIST. EXITTING...."
        if [ $_MksysbStatus -eq 0 ]
        then
	  PrintINFO "MKSYSB COMMAND Completed but ... RC $_MksysbStatus. "
        fi
  fi

  mksysbfilesize=`du -sm /mksysbfs/${MksysbFile}|awk '{print $1}'|awk -F. '{print $1}'`
  if [ $mksysbfilesize -le 100 ]
  then
	PrintERRO "MKSYSB UNDER 100M. Bckup did not run correctly. ABORTING."
  else
	PrintINFO "MKSYSB OVER 100M. CHECKING lsmksysb"
	confirmgoodmksysb=`lsmksysb -l -f  /mksysbfs/$MksysbFile|grep hd8`
	if [ -z "$confirmgoodmksysb" ] 
	then
		PrintERRO "MKSYSB does not appear to be valid per lsmksysb"		
		PrintSTAT "MKSYSB backup is Bad"
	else
                PrintSUCC "$MksysbFile appears to be good per lsmksysb."
		PrintSTAT "MKSYSB backup is Good"
	fi
  fi
} 

compress_mksysb() {
  [ $T_FLAG == TRUE ] && set -x
  ITM_flush
  #GZIP
   if [[ $SANimage == YES ]] && [[ "$m_FLAG" = TRUE ]]; then
     PrintINFO "Alt disk is not taken. Reversing prepare rootvg steps"
     pprootdev fixback >/dev/null
     mkdev -l powerpath0 >/dev/null #cfgmgr 2>/dev/null
   fi

    FSFree=$(df -g /mksysbfs | grep -v Filesystem | awk '{print 100*$3/$2}')
    TruncTarHost=$(echo ${mksysbServer} | cut -c1-6)
    if [ $FSFree -gt 35 ] && [ "$HostName" != @($TruncTarHost*) ]; then
      cd /mksysbfs
      PrintINFO "gzipping `du -sm /mksysbfs/${MksysbFile}`" 
      /usr/bin/gzip -q -9 /mksysbfs/"${MksysbFile}"; GRC=$?
    elif [[ ! -f /mksysbfs/${MksysbFile} ]]; then
       GRC=2
       PrintWARN "Cannot gzip while file /mksysbfs/${MksysbFile} is empty"
    else
       GRC=1
       PrintWARN "Cannot gzip while ${FSFree}% Free in /mksysbfs."
       PrintINFO "********* Recording exclude.rootvg file"
       cat /etc/exclude.rootvg 2>/dev/null | while read Line
       do
        PrintINFO "Exclude directory - $Line"
       done
       PrintINFO "********* Recording root file system usage"
       lsvgfs rootvg | while read FS
       do
         PrintINFO "`df -g $FS | grep -v File`"
       done
       PrintWARN "There is not enough space in the file system only $FSFree % Free"
       PrintINFO "Check the rootvg file systems and remove anything do not belong there"
       PrintINFO "/audit should only be 256 MB"
       PrintINFO "NOT gzipping ${MksysbFile} due to space issues" 
    fi

    if [[ $GRC -eq 2 ]]; then
         PrintWARN "system mksysb was not completed successfully"
    elif [[ $GRC -eq 0 ]]; then
     MksysbFiletoSend="/mksysbfs/${GzipMksysbFile}"
     PrintSUCC "File gzipped successfully"
    else
     MksysbFiletoSend="/mksysbfs/${MksysbFile}"
      if [[ "$HostName" != @($TruncTarHost*) ]]; then
         PrintWARN "SPACE in /mksysbfs $(du -sm /mksysbfs/* | egrep -v "^0|lost")"
      else
         PrintWARN "SPACE in /mksysbfs $(du -sm /mksysbfs | egrep -v "^0|lost")"
      fi
    fi

  # Section to resize mksysbfs back to original size
  if [ $resizemksysbfs -eq 1 ]
  then
	PrintINFO "MKSYSBFS was resized for this operation. Shrinking it back"
	freespaceonfs=`df -m /mksysbfs|grep -v File|awk '{print $3}'`
	
	if [ $freespaceonfs -ge 10001 ]
	then
		PrintINFO "resizing FS to original size..."
		chfs -a size=-10G /mksysbfs
	fi
  fi

}

TrackSCP() {
    chk4mksysb=`ps -eaf | grep [s]cp | grep "${MksysbFiletoSend}" | grep -v grep`
    ShowSCP=$(echo ${chk4mksysb} | awk '{print " PID "$2" "$(NF-1) }' 2>/dev/null )
    while [ "$chk4mksysb" ]
    do
      i=0
	PrintINFO "SCP IN PROGRESS ${ShowSCP:-None}. SLEEPING $WaitTime seconds" 
        while [ $i -lt $WaitTime ] && [ ! -z "$chk4mksysb" ]; do
	  chk4mksysb=`ps -eaf |grep [s]cp | grep "${MksysbFiletoSend}" |grep -v grep | awk '{print $NF}' | sed 's/ //g'`
	  sleep 5
          let i=$i+5
        done
     chk4mksysb=`ps -eaf |grep [s]cp | grep "${MksysbFiletoSend}" |grep -v grep | awk '{print $NF}' | sed 's/ //g'`
   done
   if [[ X == "X$chk4mksysb" ]]; then
     PrintINFO "END OF SCP ${ShowSCP}" 
   fi
}

ChkRespTime() {
  RespTime=$(ping -w1 -c1 draxbs2.bcdc.kp.org | grep ttl | sed 's/^.*time//; s/ms//; s/=//' | bc)
  PrintINFO "Current response time of ${mksysbServer} is $RespTime, expected below 50 ms"
  while [[ $RespTime -gt RespVal ]]; do
    PrintINFO "Waiting 1 min for improved response time"
    sleep 60
    RespTime=$(ping -w1 -c1 draxbs2.bcdc.kp.org | grep ttl | sed 's/^.*time//; s/ms//; s/=//' | bc)
    let i=$i+1
    if [[ $i -gt 10 ]]; then
     PrintINFO "After 10 mins, response time did not improve"
     break
    fi
  done
}

copy_mksysb() {
  [ $T_FLAG == TRUE ] && set -x
  ITM_flush
  PrintINFO "${CpmleteStatus}" 

  if [[ X != "X${MksysbFiletoSend}" ]]; then
    PrintINFO "STARTING MKSYSBCOPY FUNCTION "
    CopiedFile=$(du -m ${MksysbFiletoSend} | awk '{print $1 " " $2}')
    PrintINFO "FILE @ ${ThisHost} $CopiedFile TO ${mksysbServer}"
    if [[ ${mksysbServer} != @(*e.*) ]]; then
         PrintINFO "Backup files MAY NOT be transferred over BACKUP NETWORK."
    else
         PrintINFO "BACKUP NETWORK is used to transfer files"
    fi
    PrintINFO "Starting background SCP now"
    chk4mksysb=`ps -eaf |grep [s]cp | grep "${MksysbFiletoSend}" | grep -v grep`
    if [ "$chk4mksysb" ]
    then
      PrintINFO "Another file transfer process copying the same file detected. waiting.."
      Verify_SCP
    fi
    ChkRespTime
    PrintINFO "Wait while checking for ${MksysbFiletoSend} on ${mksysbServer}"
    currentfilesize=$(sum ${MksysbFiletoSend} 2>/dev/null |awk '{print $1}')
    remotefilesize=$($SSHCMD  "sum ${MksysbFiletoSend} 2>/dev/null"|awk '{print $1}')
    remotefilesize=${remotefilesize:-0}
    if [[ $currentfilesize -eq $remotefilesize ]]; then
       PrintINFO "Server ${mksysbServer} already has ${MksysbFiletoSend}"
       PrintINFO "Files are identical. Please delete the file on the server and try again"
       TryAgain=No
    else
       PrintINFO "Initiating background copy function"
       $SCPCMD ${MksysbFiletoSend} mksysbu@${mksysbServer}:/mksysbfs/ & SCPPID=$!
       PrintINFO "PID is $SCPPID pushed file copy to background. Waiting"
    fi
    i=0
    while [[ $i -lt 25 ]]; do
     sleep 5
     let i=$i+5
     RealSCPPID=$(ps -eaf |grep [s]cp | grep "${MksysbFiletoSend}" | grep -v grep | awk '{print $2}' | sed 's/ //g')
     if [[ $i -gt 26 ]]; then break; fi
    done

    if [[ X != "X$RealSCPPID" ]]; then
       SCPPID=$RealSCPPID
    elif [[ $TryAgain == Yes ]]; then
      PrintWARN "Could not find a background SCP PID. Trying again"
      $SCPCMD ${MksysbFiletoSend} mksysbu@${mksysbServer}:/mksysbfs/ & SCPPID=$!
      sleep 5
      RealSCPPID=$(ps -eaf |grep [s]cp | grep "${MksysbFiletoSend}" | grep -v grep | awk '{print $2}' | sed 's/ //g')
      [ X != $RealSCPPID ] &&  SCPPID=$RealSCPPID
    else
      PrintWARN "NOT Trying again to send the file"
    fi

    ps -eaf | grep $SCPPID 2>/dev/null | grep -v grep | awk '{print $1 " " $2 " " $3 " " $NF}' | while read Line
    do
     PrintINFO "Process infor - $Line"
    done
    sleep 1
    chk4mksysb=`ps -eaf |grep [s]cp | grep "${MksysbFiletoSend}" | grep -v grep`
    ShowSCP=$(echo ${chk4mksysb} | awk '{print $2" "$(NF-1) }' 2>/dev/null )
    PrintINFO "Background file copy PID - ${ShowSCP:-none}"
    if [[ $B_FLAG == TRUE ]]; then
      TrackSCP &
    fi
  else
    PrintERROR "No file was available for transfer. Please run `basename $0` -m to create one"
    SCPPID=
  fi
}

Verify_SCP() {
   PrintINFO "Veryfy secure file copy PID ${SCPPID:-none} known .."
  if [[ X == "X${MksysbFiletoSend}" ]]; then
    PrintINFO "${MksysbFiletoSend:-No} file has been selected for transfer. ${SCPPID:-No} copy PID"
    ScpStatus='Complete'
  else
    PrintINFO "Checking for file transfer of selected file ${MksysbFiletoSend}"
 
    SCPPID=${SCPPID:-$(ps -eaf |grep [s]cp |grep "${MksysbFiletoSend}" | grep -v grep | awk '{print $2}' | sed 's/ //g')}
    PrintINFO "Looking for PID ${SCPPID:-None}"
    if [[ X != "X$SCPPID" ]]; then
     if [[ X == "X$(ps -p $SCPPID | grep -v PID)" ]]; then PrintINFO "Copying mksysb file seem to be over"; fi
     if [[ X != "X$(ps -p $SCPPID | grep -v PID)" ]]; then PrintINFO "Still copying mksysb file in the background"; fi
     if [ $WaitTime -gt 30 ] && [ $MainDC == Yes ]; then PrintINFO "Check backup interface and IP, should setup correctly"; fi
    chk4mksysb=`ps -eaf | grep [s]cp | grep "${MksysbFiletoSend}" | grep -v grep`
    ShowSCP=$(echo ${chk4mksysb} | awk '{print " PID "$2" "$(NF-1) }' 2>/dev/null )
    while [ "$chk4mksysb" ]
    do
      i=0
	PrintINFO "SCP IN PROGRESS ${ShowSCP}. SLEEPING $WaitTime seconds" 
        while [ $i -lt $WaitTime ] && [ ! -z "$chk4mksysb" ]; do
	  chk4mksysb=`ps -eaf |grep [s]cp | grep "${MksysbFiletoSend}" |grep -v grep | awk '{print $NF}' | sed 's/ //g'`
	  sleep 5
          let i=$i+5
        done
     chk4mksysb=`ps -eaf |grep [s]cp | grep "${MksysbFiletoSend}" |grep -v grep | awk '{print $NF}' | sed 's/ //g'`
     if [ "$chk4mksysb" ]
     then
        ScpStatus='InProgress'
     else
        ScpStatus='Complete'
        break
     fi
    done
   fi
   PrintINFO "COMPLETED SCP PROCESS - ${ShowSCP}" 
   WasTrfD=$($SSHCMD "ls ${MksysbFiletoSend} 2>/dev/null" | sed 's/ //g')
   if [[ X != "X$WasTrfD" ]]; then
     ScpStatus='Complete'
   else
     ScpStatus=Failed
   fi
   $SSHCMD "chmod 640 ${MksysbFiletoSend} 2>/dev/null"
  fi
}

verify_mksysb() {
[ $T_FLAG == TRUE ] && set -x
  ITM_flush
  # Split out verify to reduce the time for the mksysb copy
  PrintINFO "Checking for file transfer PID ${SCPPID:-none} known"
  Verify_SCP

  MksysbFiletoSend=${MksysbFiletoSend:-$(find /mksysbfs -xdev -size +1000 -name "${ClientName}.mksysb*" 2>/dev/null |head -1)}
  MksysbFiletoSend=${MksysbFiletoSend:-None}
  PrintINFO "Verifying local and remote copies of ${MksysbFiletoSend}"
  PrintINFO "Local file ${MksysbFiletoSend}"
  if [[ ${MksysbFiletoSend} == None ]]; then
    PrintINFO "No file has been selected for veryfying"
    $SSHCMD "ls -l /mksysbfs/${HostName}*.mksysb* 2>/dev/null" | awk '{print $NF}' | while read BackuFile
    do
      PrintINFO "File $BackuFile exists in repo"
    done
  elif [[ ${ScpStatus} == UnKnown ]]; then
    PrintINFO "No file has been selected for copying"
  elif [[ ${ScpStatus} == Complete ]]; then
   currentfilesize=$(sum ${MksysbFiletoSend} 2>/dev/null |awk '{print $1}')
   sleep 1
   PrintINFO "LOCAL SUM $currentfilesize ."
   RemoteFile=${RemoteFile:-$($SSHCMD "ls -l ${MksysbFiletoSend} 2>/dev/null")}
     if [[ X == "X${RemoteFile}" ]]; then
       PrintERRO "FILE COPY UNSUCCESSFUL. ${MksysbFiletoSend} does not exist in Repo"
     else
       remotefilesize=$($SSHCMD  "sum ${MksysbFiletoSend} 2>/dev/null"|awk '{print $1}')
     fi
   
     PrintINFO "REMOTE SUM $remotefilesize."
  
     if [[ $remotefilesize -ne $currentfilesize ]]; then
        PrintERRO "REMOTE MKSYSB ( ${MksysbFiletoSend} ) FILESIZE DOES NOT MATCH LOCAL SUM"
        PrintERRO "FILE COPY UNSUCCESSFUL."
       #Retry Copy
        RemoteFile=$($SSHCMD "ls -l ${MksysbFiletoSend} 2>/dev/null" | sed 's/ //g')
        SCPC=0
        while [[ $SCPC -lt 5 ]]; do
        let SCPC=$SCPC+1
           PrintWARN "Re-try copying the file. Attempt $SCPC of 5"
           ChkRespTime
           copy_mksysb
           Verify_SCP
           remotefilesize=$($SSHCMD  "sum ${MksysbFiletoSend} 2>/dev/null"|awk '{print $1}')
           if [[ $SCPC -ge 6 ]]; then
             PrintSTAT "FILE COPY UNSUCCESSFUL."
             break
           elif [[ $remotefilesize -eq $currentfilesize ]]; then
       	     PrintSUCC "REMOTE MKSYSB FILESIZE ( ${MksysbFiletoSend} ) MATCHES LOCAL SUM"
             PrintSUCC "FILE COPY HAS BEEN SUCCESSFUL."
             PrintSTAT "FILE COPY SUCCESSFUL."
             break
           else
             ChkRespTime
             sleep 60
           fi
       done
     else
       	PrintSUCC "REMOTE MKSYSB FILESIZE ( ${MksysbFiletoSend} ) MATCHES LOCAL SUM"
        PrintSUCC "FILE COPY HAS BEEN SUCCESSFUL."
        PrintSTAT "FILE COPY SUCCESSFUL."
     fi
  fi
} #End verify mksysb

HACMP_info() {
[ $T_FLAG == TRUE ] && set -x
# hacmp snapshot if a cluster is running.  
HNAME=`/usr/sbin/cluster/utilities/cltopinfo -c|grep 'Cluster Name:'|awk '{print $3}'`
tdate=`date +"%d-%m-%Y-%M"`
/usr/es/sbin/cluster/utilities/clsnapshot -c -i -n "backupos-snapshot1-${HNAME}-${tdate}" -m "$HNAME"  -d "${HNAME}-backupos-snapshot-${tdate}" | tee -a /tmp/osbackup.temp.log
sleep 5
cat /tmp/osbackup.temp.log | while read line
do
  PrintINFO "$line"
done
# snapshot trimming:
recentsnapshots=`find /usr/es/sbin/cluster/snapshots/ -name "*backupos-snapshot*" -mtime -100| sed -e 's!/usr/es/sbin/cluster/snapshots/!!g'|awk -F. '{print $1}'|uniq|wc -l|awk '{print $1}'`
if [ $recentsnapshots -ge 10 ]
then
	PrintINFO "There are currently $recentsnapshots in in the directory"
	for x in `find /usr/es/sbin/cluster/snapshots/ -name "*backupos-snapshot*" -mtime +80| sed -e 's!/usr/es/sbin/cluster/snapshots/!!g'|awk -F. '{print $1}'|uniq`
	do
		PrintINFO "Deleting $x"
		clsnapshot -r -n "$x"
	done
fi
}

html_logfile() {
# make an HTML version of the logfile for Mksysb site - Code from Susith
htmllogfile=/var/log/${HostName}.osbackup.log.html
Su3Link="http://172.21.178.147/CFG2HTML/${HostName}.html"
Eng100Link="http://172.21.178.146/mksysb/CRDCLogs/${HostName}.html"
  echo "<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
        <HTML>
        <style type=text/css>
        BODY            {FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif; FONT-SIZE: 12pt;}
        </style>
        <TITLE> $line </TITLE> " >${htmllogfile}
  echo '<BODY>' >> ${htmllogfile}
  echo "<a href=${Su3Link} > Link to cfg2html file </a> &nbsp &nbsp" >> ${htmllogfile}
  echo "<a href=${Eng100Link} > Link to cfg2html file </a> <br>" >> ${htmllogfile}

  chmod 664 ${htmllogfile}

  cat ${logFile} | while read LinE
   do
      MarRed=NO
        if [ "$L_FLAG" = TRUE ]
        then
           echo "$LinE"
        fi
        echo "$LinE" | egrep "ERROR|WARNING|FAIL|ATTENTION|does" >/dev/null && MarRed=Yes || MarRed=NO
        echo "$LinE" | egrep "SUCCESS" >/dev/null && MarBlue=Yes || MarBlue=NO
        if [[ $MarRed != NO ]]; then
         echo "<font color=red> $LinE </font><br>" >> ${htmllogfile}
        elif [[ $MarBlue != NO ]]; then
         echo "<font color=blue> $LinE </font><br>" >> ${htmllogfile}
        else
         echo "$LinE <br>" >> ${htmllogfile}
        fi
        LinE=" "
    done
   echo "<a href=http://172.21.178.147/CFG2HTML/${HostName}.html > Link to cfg2html file </a> <br>" >> ${htmllogfile}
   echo '</BODY></HTML>' >> ${htmllogfile}
}

test_ssh_conn() { 
  let SSH_TestAttempt=$SSH_TestAttempt+1
  [ $T_FLAG == TRUE ] && set -x
   sshsuccess=$($SSHCMD 'date' >/dev/null; echo $?)
   if [[ $sshsuccess != 0 ]]; then
      PrintERRO "SSH test $SSH_TestAttempt unsuccessful. SSH keys does not seem to be right. File copy may not work... "
      ClientSSH=$(lslpp -qlc openssh.base.client* 2>/dev/null | sed 1q | awk -F: '{print $3}')
      ClientSSH=${ClientSSH:-NotInstalled}
      PrintINFO "Open SSH Client Version ${ClientSSH}"
      IsQuest=$(lslpp -qlc quest-openssh.rte 2>/dev/null | sed 1q | awk -F: '{print $3}')
      IsQuest=${IsQuest:-NotInstalled}
      PrintINFO "Quest-SSH Version ${IsQuest}"
      ActiveSSH=$(lssrc -a | grep active | grep ssh | awk '{printf $1 " "}')
      PrintINFO "Active SSH $ActiveSSH"
      PrintINFO "SSH key file $(ls -l /.ssh/mksysbukey | awk '{print $5 "  " $6 ":" $7 "  " $8 " " $NF}') ."
      PrintINFO "mksysb file $(ls -lrt /mksysbfs/*.mksysb.* 2>/dev/null |sed '$!d' | awk '{print $5" "$6 ":"$7 " "$8" " $NF}' ) ."
  else
      PrintSUCC "Attempt $SSH_TestAttempt SSH KEY APPEARS TO WORK"
  fi
}

copy_logfile() {
[ $T_FLAG == TRUE ] && set -x
  ITM_flush
  $SCPCMD -p ${logFile} mksysbu@${mksysbServer}:/mksysbfs
  $SCPCMD -p ${logFile}.html  mksysbu@${mksysbServer}:/mksysbfs/HTML_Log_Files
  if [[ $Hostname == @(czaeng100*) ]]; then
    cp ${htmllogfile} /chroot/home/mksysb_reports/${LogLoc}
    chown cfg2usr /chroot/home/mksysb_reports/${LogLoc}/${htmllogfile}
    chmod 664 /chroot/home/mksysb_reports/${LogLoc}/${htmllogfile}
    SuCopySucc=0
  elif [[ $Hostname == @(czabsu3*) ]]; then
    cp ${htmllogfile} /chroot/home/mksysb_reports/${LogLoc}
    chown cfg2user /chroot/home/mksysb_reports/${LogLoc}/${htmllogfile}
    chmod 664 /chroot/home/mksysb_reports/${LogLoc}/${htmllogfile}
    SuCopySucc=0
  else
    scp ${AllOpts} ${htmllogfile} cfg2user@czabsu3:~/mksysb_reports/${LogLoc}; SuCopySucc=$?
    scp ${AllOpts} ${htmllogfile} cfg2usr@czaeng100:~/mksysb_reports/${LogLoc}; EngCopySucc=$?
  fi
}

#Creating image starts here
#
run_altrootvg_copy() {
[ $T_FLAG == TRUE ] && set -x
PrintINFO "ALT DISK COPY ACTIVATED"
ITM_flush

# Stop the process if the altdisk lpp is not installed
chklpp=`lslpp -qlc bos.alt_disk_install.rte | grep -v 'not installed' | sed 1q`
if [ -z $chklpp ]
then
        PrintERRO "ALT DISK LPP NOT INSTALLED. ABORTING"
	exit_function
fi

#=====================================================================
# collect information
# Determination for SAN boot OR VSCSI versus physical SCSI. 

SelectDiskForImage() {
  [ $T_FLAG == TRUE ] && set -x
  #set -x
  TYpe=$1
  PrintINFO "LOOKING FOR SUITABLE DISK of type $TYpe"
  case $TYpe in
   power|SYMM_VRAID|SYMM_VGER) TYpe=power ;;
   vdisk) TYpe=vdisk ;;
   mpioosdisk) TYpe=mpioosdisk ;;
   MSYMM_VRAID) TYpe=MSYMM_VRAID ;;
  esac
  #SelectFree=
  #Slect a free disk
   DisksInrootVG=$(lsvg -p rootvg | grep active | awk '{printf $1 " "}')
   #getconf BOOT_DEVICE
   NumRootvgDisks=$(echo $DisksInrootVG | wc -w | bc)
   PrintINFO "Root vg is in $NumRootvgDisks disk(s)"
   DisksFrImage=$NumRootvgDisks
   if [[ $NumRootvgDisks -gt 1 ]]; then
     PrintINFO "Rootvg is on a Multiple \($DisksInrootVG\) disks"
     for hDisks in `echo $DisksInrootVG`
     do
      lspv -l $hDisks | grep hd5 && let BLV=$BLV+1
     done
   else
       PrintINFO "Rootvg is on a Single disk"
   fi 

  #Multiple disks could be in rootvg
  RootSize=0
  for RootvgDisk in `echo $DisksInrootVG`
  do
   DiskSize=$(bootinfo -s $RootvgDisk)
   let RootSize=$RootSize+$DiskSize      #Get total  root disk space
  done
  PrintINFO "Total rootvg size is $RootSize MB"

  for RootvgDisk in `echo $DisksInrootVG`
  do
   #RootSize=$(bootinfo -s `lsvg -p rootvg | grep hdisk | sed 1q | awk '{print $1}'`)
   ThisDiskType=$(lsdev -l $RootvgDisk -F type)
   if [[ $ThisDiskType == @(SYMM_*) ]]; then
     RootPowerDisk=$(odmget -q "value=$RootvgDisk AND attribute=pnpath" CuAt 2>/dev/null | grep name | sed 's/\"//g' | awk '{print $NF}')
     TYpe=power
   else
     RootPowerDisk=$RootvgDisk #Only power disks need to get the power path identification
   fi
   RootPDsize=$(bootinfo -s $RootPowerDisk)
   VGname=rootvg
   SetPViD=0
    lsdev -Cc disk -t $TYpe -F name | egrep -v "$RootvgDisk|$RootPowerDisk" | while read sDisk 
    do
      DiskSize=$(bootinfo -s $sDisk)
      DiskOwner=$(ls -l /dev/r${sDisk} | grep -v root | sed 's/ //g')
      if [[ X != "X$DiskOwner" ]]; then
       PrintINFO "Disk $sDisk is not owned by root. Cannot be selected for image_1"
       continue #Do not select the same disk for image
      elif [[ $sDisk == $RootPowerDisk ]]; then
       #PrintINFO "$sDisk is same as rootdisk $RootPowerDisk. Looking for the next"
       continue #Do not select the same disk for image
      elif [[ $DiskSize -le 5 ]]; then
       PrintINFO "$sDisk has size $DiskSize. May be a gatekeeper. Looking for the next"
       continue #Do not select the same disk for image
      fi

      let SizeDiff=$DiskSize-$RootSize
      SizeDiff=$(echo "$SizeDiff*$SizeDiff" | bc)
      SizeDiff=$(echo "sqrt($SizeDiff)" | bc)

      PViD=$(lsattr -E -a pvid -F value -l $sDisk)
       if [[ $PViD == none ]]; then
         DiskSize=$(bootinfo -s $sDisk)
         if [[ $SetPViD -lt $DisksFrImage ]]; then
            PrintINFO "$TYpe disk $sDisk does not have PVID, and size $DiskSize. check if size matches"
            if [[ $RootSize -eq $DiskSize ]]; then    #Check for a disk with same size
              PrintINFO "$sDisk size $DiskSize is free"
              chdev -l $sDisk -a pv=yes 2>/dev/null
              let SetPViD=$SetPViD+1
            elif [[ $SizeDiff -lt 10 ]]; then    #Check for a disk with 10MB difference
              PrintINFO "$sDisk size dfference is $SizeDiff which is less than 10MB can be cosidered as free"
              chdev -l $sDisk -a pv=yes 2>/dev/null
              let SetPViD=$SetPViD+1
          #else
           #PrintWARN "Free $TYpe disk $sDisk does not match the root disk size"
            fi
         fi
        PViD=$(lsattr -E -a pvid -F value -l $sDisk)
      fi

      if [[ ! -z $PViD ]]; then
         VGname=$(odmget -q "value=$PViD AND attribute=pv" CuAt | grep -w name | sed 's/\"//g' | awk '{print $NF}')
      fi

     if [[ -z $VGname ]]; then
      DiskSize=$(getconf DISK_SIZE /dev/$sDisk 2>/dev/null) #There are disks with smaller size
      DiskSize=${DiskSize:-0}
       if [ $DiskSize == $RootPDsize -o $SizeDiff -lt 10 ]; then
         PrintINFO "$sDisk is $DiskSize MB, and it is Free. Required $RootPDsize. It can be used for image_1"
          if [[ Y == "Y$ImageDisk" ]]; then
            ImageSize=$(bootinfo -s $sDisk)
            ImageDisk="$sDisk"
            PrintINFO "$sDisk selected for image_1"
          else
            ImageSizeX=$(bootinfo -s $sDisk)
            PrintINFO "$sDisk added to $ImageDisk for image_1"
            ImageDisk="$ImageDisk $sDisk"
            let ImageSize=$ImageSize+$ImageSizeX
          fi
       fi
     else
       PrintINFO "$sDisk already used for $VGname. Looking for the next $TYpe disk"
     fi

     #Once enough disks slected break out of the loop
     NumSelectedDisks=$(echo $ImageDisk | wc -w | bc)
     if [[ $NumSelectedDisks == $NumRootvgDisks ]]; then
       PrintINFO "$NumSelectedDisks $sDisk disk(s) chosen for image_1"
      if [ $ImageSize -ge $RootSize -o $SizeDiff -lt 10 ]; then
        PrintINFO "Selected disk space $ImageSize may be sufficient for image $RootSize"
        break
      else
        PrintINFO "Selected disk space is not sufficient for image"
         if [[ $NumRootvgDisks -eq 1 ]]; then
           NumSelectedDisks=0
           ImageDisk=
         fi
      fi
     fi
 done
 [ X != "X$ImageDisk" ] && PrintINFO "Selected disk - $ImageDisk - to backup $DisksInrootVG"
done  #Limit search until number of disks matches the current rootvg

    #ImageDisk="$SelectFree"
    DisksWithoutSpace=$(echo $ImageDisk | sed 's/ //g')
    if [[ X != "X$DisksWithoutSpace" ]]; then
         PrintINFO "Selected $ImageDisk for alt_disk_image"
    else
         PrintERRO "No free disks available for alt_disk_image"
         ImageDisk="NONE"
    fi
} #SelectDiskForImage end here

#Current image name
ImageDisks=
altVGname=$(lsdev -Ct vgtype -Fname | egrep -w "altinst_rootvg|old_rootvg|image_1" | awk '{printf $0 " "}')
if [[ ! -z "$altVGname" ]]; then
 PrintINFO "Image backup exist in the system with name $altVGname"
  if [[ "X$altVGname" == Ximage_1 ]]; then
    altVGname=image_1
  fi
  for line in `odmget -q "name=$altVGname AND attribute=pv" CuAt | grep value | sed 's/\"//g' | awk '{printf $NF " "}'`
  do
    CurrDisk=$(odmget -q "attribute=pvid AND value=$line" CuAt | grep name | sed 's/\"//g' | awk '{printf $NF}')
    [ X != "X$CurrDisk" ] && ImageDisks="$ImageDisks $CurrDisk"
  done
 CurrImage1="`echo $ImageDisks | sed 's/^ //g'`"
else
 CurrImage1=
 altVGname=
fi

if [[ X == "X$CurrImage1" ]]; then  #Getting a new disk(s)
 PrintINFO "There is no alt_disk in the system. Root disk type is $HdiskType"
 PrintINFO "Rootvg $DisksInrootVG , Sequence No. $BootPowerNumber."
  #For brandnew image Select equal number of disks for image. Only relevent to scsd disks
 case $HdiskType in  #This is rootvg type
  @(power|SYMM_*|Power) )
     SelectDiskForImage $HdiskType
     DisksWithoutSpace=$(echo $ImageDisk | sed 's/ //g')
     if [[ X != X$DisksWithoutSpace ]]; then
       [ "$ImageDisk" != NONE ] && GetPowerDiskName $ImageDisk #Get the PowerDiskName
       [ "$ImageDisk" != NONE ] && PrintINFO "Querrying for $ImageDisk devices for alt_disk_image"
     fi
      ;;
  @(scsd|sisarray|nvmdisk) )  #Current rootvg is in scsd or sisarray disk
     PrintINFO "Checking for free SCSD / SISARRAY /nvmdisk disks"
       FreeSCSD=
       TotalSCSDs=
       DiskTypeS='scsd sisarray nvmdisk'
       for DiT in ${DiskTypeS}
       do
          TotDisks=$(lsdev -Cc disk -t $DiT -S a -F name | awk '{printf $1 " "}')
          TotalSCSDs="${TotalSCSDs}${TotDisks} "
       done
       DisksInrootvg=$(lsvg -p rootvg | grep active | awk '{printf $1 " "}' )
       DisksMissingInrootvg=$(lsvg -p rootvg | egrep -v 'rootvg:|PV_NAME|active' | wc -l | bc )
       if [[ $DisksMissingInrootvg -gt 0 ]]; then
        PrintERRO "One or more disks in rootvg is not active"
       fi
       DisksForImage=`echo $DisksInrootvg | wc -w |bc`
       if [[ `echo $TotalSCSDs | wc -w | bc` -ge 2 ]]; then
          for DiT in ${DiskTypeS}
          do
            lsdev -Cc disk -t $DiT -F name | while read sDisk
            do
              VGname=
              #TotalSCSDs="$TotalSCSDs $sDisk"
              PViD=$(lsattr -E -a pvid -F value -l $sDisk)
              if [[ $PViD == none ]]; then
               PrintINFO "Disk $sDisk of type $HdiskType seem to be free"
                if [[ $SetPViD -lt $DisksForImage ]]; then
                  PrintINFO "Setting PVID for free $HdiskType disk $sDisk to be used for image"
                  chdev -l $sDisk -a pv=yes >/dev/null
                  let SetPViD=$SetPViD+1
                  ImageDisk="$ImageDisk $sDisk"
                fi
                PViD=$(lsattr -E -a pvid -F value -l $sDisk)
              fi

              if [[ X != X$PViD ]]; then
                VGname=$(odmget -q "value=$PViD AND attribute=pv" CuAt |grep -w name |sed 's/\"//g' | awk '{print $NF}')
              fi
              if [[ X == X$VGname ]]; then
                FreeSCSD="$FreeSCSD $sDisk"
              fi
            done
          done
         TotalSCSDs=`print "$TotalSCSDs" |  sed -e 's/^[ \t]*//'`
         FreeSCSD=`print "$FreeSCSD" |  sed -e 's/^[ \t]*//'`

        PrintINFO "From all $HdiskType type disks $FreeSCSD seem to be free" #Now select disks
        if [[ $DisksForImage -lt 2 ]]; then
            [ `echo $TotalSCSDs |wc -w | bc` -ge 4 ] && PrintERRO "Rootvg is not mirrored. But disks are available" #What are free
        fi

        if [[ `echo $FreeSCSD |wc -w |bc` -lt $DisksForImage ]]; then
            PrintERRO "Not enough internal disks for root vg image"
            ImageDisk="NONE"
        else
            ImageDisk=$(echo $FreeSCSD | cut -d" " -f1-${DisksForImage})
        fi
        PrintINFO "Internal disks $ImageDisk has been selected for root vg image"
      else
         PrintERRO "Not enough internal disks for root vg image"
         ImageDisk="NONE"
      fi
      ;;
    @(vdisk|mpioosdisk|MSYMM_*) )
        SelectDiskForImage $HdiskType           #This should get the next free vdisk for image
        GetPowerDiskName $ImageDisk #Get the PowerDiskName
        ;;
     * )
       PrintERRO "Cannot determine the image disk type. Aborting"
       ImageDisk=NONE
        ;;
   esac
  [ "$ImageDisk" != NONE ] && PrintINFO "$ImageDisk -- altvg  disk selection summery"

else    #System already have a image_1
  CurrImage11=$(echo $CurrImage1 | awk '{printf $1}')  #Take one disk for verification
  GetPowerDiskName $CurrImage11 #Get the PowerDiskName
  ImageDisk="${CurrImage1}"
  PrintINFO "Current Image is on ${CurrImage1} $HdiskType Ex. $PowerDiskName - $BackingDisks."
fi

[ "$ImageDisk" == @(*NONE*) ] && PrintINFO "ALT Root disk type is $HdiskType , -$PowerDiskName -- $ImageDisk "
#Clean existing image
# Confirm no alt_disks are online
chk4mount=`df -m|grep 'alt_inst'`
	if [ "$chk4mount" ]
	then
	PrintERRO "ALT_ROOT FILESYSTEMS CURRENTLY MOUNTED. QUITTING ALT_DISK FUNCTION"
	exit_function
	fi

  if [[ ! -z ${altVGname} ]]; then
   IsDisk=$(lspv | grep ${altVGname} | sed 1q)
   if [[ X == "X$IsDisk" ]]; then
     PrintERRO "Name ${altVGname} exists in ODM, but no pvs assigned to it physically"
   else
      alt_rootvg_op -X "${altVGname}" 2>/dev/null #Do this after determining InageDisk
   fi
  fi

  if [[ $HdiskType != @(power|SYMM_*|Power) ]]; then
    for hDisk in $ImageDisk
      do
       [ $hDisk != NONE ] && chpv -c $hDisk; chpv -C $hDisk
      done
    fi

  if [[ "${ImageDisk}" != @(*NONE*) ]]; then
    PrintINFO "Creating NEW alt disk on ${ImageDisk}"
    #altVGname=$(lsdev -Ct vgtype -Fname | egrep -w "altinst_rootvg|old_rootvg|image_1")
    for altVGname in `lsdev -Ct vgtype -F name | egrep -w "altinst_rootvg|old_rootvg|image_1"`
    do
      PrintINFO "Releasing vg name ${altVGname}"
      [ X != "X${altVGname}" ] && alt_rootvg_op -X ${altVGname}  #Clean the image, so that case is treated as new
    done
    [ -f /save_bosinst.data_file ] && rm /save_bosinst.data_file && /usr/bin/mkszfile -m
    alt_disk_copy -B -d "${ImageDisk}"
    _CloneStatus=$?
  else
    PrintERRO "Could not select a disk for alt_disk. Check for free disks owned by root"
    PrintERRO "Look for a suitable disk and run alt_disk manually once."
    _CloneStatus=1
  fi
	if [ $_CloneStatus -eq 0 ]
	then
		PrintSUCC "ALT DISK APPEARS TO BE BOOTABLE ON ${ImageDisk}"
                PrintINFO "Renaming new root disk copy as image_1"
           alt_rootvg_op -v image_1 -d ${ImageDisk}
	else
		PrintERRO "ALT ROOTVG MAY NOT BE CREATED, OR is not bootable"
	fi

#Set the boot list back to previos
    EBL=$(bootlist -m normal -o | awk '{printf $0", "}')
    PrintINFO "Ending boot list is ${EBL}"

}

#==================================================
altroot_postcheck() {
[ $T_FLAG == TRUE ] && set -x
ITM_flush
# check for image_1 vg
chk4image1=`lsvg|grep image_1`
if [ "$chk4image1" ]
then

   odmget -q "name=image_1 AND attribute=pv" CuAt | grep value | sed 's/\"//g' | awk '{print $NF}' | while read PVId Other
    do
     Iamge_Disk=$(odmget -q "value=$PVId AND attribute=pvid" CuAt | grep name | sed 's/\"//g' | awk '{printf $NF}' )
     image1disks="$image1disks $Iamge_Disk"
    done
   image1disks=`echo $image1disks | sed -e 's/^[ \t]*//'`
	#image1disks=$(lspv|grep image_1|awk '{printf $1 " "}') #lspv may consume time in large servers
          for _Disk in `echo $image1disks`
            do
              DiskBLV=$(lqueryvg -Lp $_Disk | grep -w hd5 )
              [ X != X$DiskBLV ] && PrintINFO "$_Disk BLV info -> $DiskBLV"
              [ X != X$DiskBLV ] && ( hk4boot=YES; break) || chk4boot=
           done

        if [ "$chk4boot" ]
        then
                PrintINFO "ALT DISK APPEARS TO HAVE BLV ON $image1disks"
        fi

  # check that image_1 is recent
	image1new=`find /dev -name "image_1" -ctime -1`
	if [ "$image1new" ]
	then 
		PrintSUCC "ALT ROOTVG IS LESS THAN ONE DAY OLD"	
		PrintSTAT "image_1 backup is Good"
	else
		PrintERRO "ALT ROOTVG IS MORE THAN ONE DAY OLD"
		PrintSTAT "image_1 backup is OLD"
	fi 

else
	PrintERRO "IMAGE_1 VG DOES NOT EXIST. ALTDISK FAILED."
		PrintSTAT "image_1 backup is Bad"
fi

  if [[ $SANimage == YES ]]; then
    PrintINFO " RootVG is on SAN disk. running pprootdev command"
    pprootdev fixback >/dev/null
    mkdev -l powerpath0 >/dev/null #cfgmgr 2>/dev/null
  fi
}
#===============================================================
chk4proc() {
[ $T_FLAG == TRUE ] && set -x
#ps -T ${MyPID}
# the purpose of this is to provide a quick exit in case there's another mksysb, alt_disk 
ITM_flush
#chk4mksysbrunning=`ps -eaf | grep -v ${MyPID} | egrep -v "sshd:|SPOT|^ mksysbu|${MyPID}" |egrep -i "[m]ksysb|[a]lt_disk|bckupos"|grep -v grep`
chk4mksysbrunning=$(ps -eaf | grep -v ${MyPID} | sed 's/^ //g' |egrep -i "[m]ksysb|[a]lt_disk|bckupos"  | egrep -v "sshd:|SPOT|^mksysbu|${MyPID}| scp -t|grep")
if [ "$chk4mksysbrunning" ]
then
	PrintWARN "ANOTHER MKSYSB OR ALT DISK PROCESS IS RUNNING. sleep for 60 minutes"
	echo "$chk4mksysbrunning"	
	sleep 3600
        chk4mksysbrunning2=`ps -eaf | grep -v ${MyPID} | grep -v ${MyPID} | egrep -v "sshd:|SPOT|^ mksysbu|${MyPID}" |egrep -i "[m]ksysb|[a]lt_disk|bckupos"|grep -v grep`

	if [ "$chk4mksysbrunning2" ]
	then
		PrintERRO "MKSYSB OR ALT DISK PROCESS IS  STILL RUNNING AFTER AN HOUR. ABORTING BACKUPOS. "
		exit_function
	fi
fi
}

dmzopt() {
[ $T_FLAG == TRUE ] && set -x
ITM_flush
chk4mksysbu=`lsuser mksysbu`
if [ -z "$chk4mksysbu" ]
then
	PrintERRO "DMZ ACTIVATED. USER MKSYSBU NOT FOUND!"
	PrintINFO "CREATE USER MKSYSBU AND ADD HOSTNAME TO LIST in mksysb server"
else
################################
# Adding section to bring copy cfg2html so we can get it in the DMZ process -- Jun/10/2013 -- MWS
#####################
	cp -R /var/adm/cfg/${HostName}.* /mksysbfs
	chown mksysbu:staff /mksysbfs/${HostName}*
# 	chown mksysbu:staff /mksysbfs/${MksysbFile}* 
fi
}

exit_function() {
[ $T_FLAG == TRUE ] && set -x
    #PrintINFO "EXIT FUNCTION ACTIVTATED."
    PrintINFO "CONVERTING LOGFILE to html view"
    PrintINFO "COPY LOGFILE FUNCTION ACTIVATED"
    #PrintINFO "View logfile at http://172.21.178.147/mksysb/${LogLoc}/${HtmlFile}"
    $SCPCMD -p ${logFile} mksysbu@${mksysbServer}:/mksysbfs; SCP_Status=$?
    if [[ $SCP_Status -eq 0 ]]; then
     PrintSUCC "LOG FILE SENT to ${mksysbServer}."	
    else
     PrintFAIL "LOG FILE SCP to ${mksysbServer} FAILED."	
    fi

    PrintINFO "Copying log files to web servers"
    PrintINFO "View logfile at http://172.21.178.146/mksysb/${LogLoc}/${HtmlFile}"
    PrintINFO "View logfile at http://unix.kp.org/mksysb/${LogLoc}/${HtmlFile}"
    PrintINFO "Local LOG File /var/log/`uname -n`.osbackup.log"
    PrintINFO " ----------------------- END -------------------- \n"
    html_logfile  #Create html log file
    copy_logfile 

    if [[ $EngCopySucc -ne 0 ]]; then
     PrintFAIL "Logfile was not copied to czaeng100."
    fi
    if [[ $SuCopySucc -ne 0 ]]; then
     PrintFAIL "Logfile was not copied to czabsu3."
    fi
    ITM_flush
exit 0
}

usage() {
print "\n ------------------------------- +++ -----------------------------"
ExistMksysb=$(ls -lrt /mksysbfs | grep mksysb | awk '{ printf $6" "$7 " " $NF }')
PrintINFO "Existing mksysb ${ExistMksysb:-None}"
CurrImage=$(lsdev -Ct vgtype -Fname | egrep -w "altinst_rootvg|old_rootvg|image_1")
CurrImage=${CurrImage:-NONE}
PrintINFO "Existing image $CurrImage on $(lspv | grep "$CurrImage" | awk '{printf $1" "}')"
print "\n ------------------------------- +++ -----------------------------"
print ' backupos.ksh  is designed to do the following:
- Take a mksysb of the OS
- Upload the mksysb to a mksysb server
- take an alt_disk copy

/usr/local/scripts/backupos.ksh -B for both mksysb and alt_disk
FLAGS:
-B: BOTH - will run a mksysb and then an alt disk. Mksysb will be sent to the server
-m: Mksysb: will take a mksysb of the system, compress it and send it to the mksysb server
-a: Take alt_disk_copy and send the log file to mksysb server
-C: (Re)copy mksysb and logfile. This happens automatically. 
-L: (Re)copy log file to server
-D: DMZ. This flag is equivilant to -B without the option of files getting copied.
'
print "logfile: ${logFile}"
PrintINFO " ----------------------- NO OPTIONS SELCTED -------------------- \n"
}

run_mksysb() {
  clean_slate
  mksysb_precheck 
  #PrepareRootVG
  mksysb_command
  mksysb_postcheck
  compress_mksysb
}

#Execution starts here
RunDir=$(dirname $0)
RunFile=$(basename $0)
VERSION=$(what ${RunDir}/${RunFile} | grep backupos-V)

# This part will check if other processes are running 
# Begin Flag detection
PROG_NAME=$(basename $0)
m_FLAG=FALSE # mksysb only
a_FLAG=FALSE # Alt disk only
C_FLAG=FALSE # Copy mksysb
L_FLAG=FALSE # Copy Logfile
B_FLAG=FALSE # BOTH flag
v_FLAG=FALSE # verify
D_FLAG=FALSE # DMZ flag
T_FLAG=FALSE #Debug option, move to the setion you want to test

StartingBootList=$(bootlist -m normal -o | grep blv | cut -d" " -f1-2 | sort | uniq | awk '{printf $1 " "}')
if [[ `echo $StartingBootList | wc -w | bc` -eq 0 ]]; then
  PrintERRO "Current bootlist does not have any blv."
  PrintINFO "Very unusal situation. Chcking for rootvg and setting boot list"
  ActiveRootDisks=$(lspv | grep rootvg | grep active | awk '{printf $1" "}')
  bootlist -m normal $ActiveRootDisks
fi

while getopts BaCmLvDT OPTION
do
    case ${OPTION} in
        m) m_FLAG=TRUE; StartFucn='File backup';;
        B) B_FLAG=TRUE; StartFucn='File and Clone backup' ;;
        a) a_FLAG=TRUE; StartFucn='Clone rootvg';;
        C) C_FLAG=TRUE; StartFucn='Copy mksysb';;
        L) L_FLAG=TRUE; StartFucn='Copy log files';;
        v) v_FLAG=TRUE; StartFucn='Verify mksysb';;
        D) D_FLAG=TRUE; StartFucn='Clone and mksysb for DMZ';;
        T) T_FLAG=TRUE;;
       \?) usage
           StartFucn='None selected'
           exit 2;;
    esac
done

[ $T_FLAG == TRUE ] && set -x

if [[ ! -z $1 ]]; then
  case $1 in
    @(*B*|*D*)) echo "BEGINING BACKUPOS $VERSION on $HostName" >${logFile}
                echo "BEGINING BACKUPOS $VERSION on $HostName" ;;
  esac
 PrintINFO " ------------BEGIN `basename $0` $1 --------------------"
 PrintINFO "BEGINNING BACKUP PROCEDURE `basename $0` on $HostName with option $1"
else
 echo "BACKUPOS $VERSION requires at least one option flag to work" | tee -a ${logFile}
 PrintWARN "BACKUPOS $VERSION requires at least one option flag to work"
fi
PrintINFO "VERSION $VERSION ${logFile}"
PrintINFO "Selected operations ${StartFucn}"

if [[ -e /usr/bin/scp ]]; then
   _CMDSCP='/usr/bin/scp'
elif [[ -e /usr/local/bin/scp ]]; then
   _CMDSCP='/usr/local/bin/scp'
else
   _CMDSCP=`which scp`
fi
_CMDSSH=$(which ssh)

## Transmit ## 
CopyKey=/.ssh/mksysbukey
SSHopt="-q -i ${CopyKey} -o ${PWOpt} -o ${UNHF} -o ${HstKeyCheck} -o ConnectTimeout=60 "

DOMAINLOC=$(host `hostname` 2>/dev/null | awk -F. '{print $2}')
if [[ ! -z $DOMAINLOC ]]; then
  DM_Length=${#DOMAINLOC}
  if [[ $DM_Length -ne 4 ]]; then
    DOMAINLOC=`ifconfig -au|grep inet|head -1|awk '{print $2}'|xargs -i nslookup {}|egrep -i -w 'Name'|awk '{print $NF}'|awk -F. '{print $2}'|head -1`
  fi
else
    DOMAINLOC=`ifconfig -au|grep inet|head -1|awk '{print $2}'|xargs -i nslookup {}|egrep -i -w 'Name'|awk '{print $NF}'|awk -F. '{print $2}'|head -1`
fi

#There are servers with domain name as KP, but reside in a DR
#
if [[ $DOMAINLOC == kp ]]; then
    PrintINFO "DOMAIN is $DOMAINLOC. Looking for specific Data Center"
    FirstLet=$(echo ${HostName} | sed 's/^x//1' | cut -c1-2 | tr '[a-z]' '[A-Z]')
    case $FirstLet in
     DR) DOMAINLOC=bcdc ;;  
     CZ) DOMAINLOC=crdc ;;  
     NZ) DOMAINLOC=nndc ;;  
     SZ) DOMAINLOC=ssdc ;;  
      *) DOMAINLOC=pldc ;;  
    esac
    PrintINFO "New DOMAIN is $DOMAINLOC matching Data Center"
fi
#
SNum=1
lastdigit=`echo $HNseq | sed 's/-/./g; s/_/./g' |sed 's/x//g' |awk -F. '{print $1}' |sed -e "s/^.*\(.\)$/\1/"`
#((modlastdigit=lastdigit%2))
modlastdigit=$(($lastdigit%2))
if [ $modlastdigit -eq 0 ]
then
  SNum=1
else
  SNum=2
fi

#mksysbServer=`echo $mksysbServer|sed "s!NUM!$servernum!g"`
MainDC=Yes
RespVal=50
case $DOMAINLOC in
        crdc) mksysbServer="czabbs${SNum}e.crdc.kp.org"
              LogLoc=CRDCLogs; SwRepo=czabsu1e.crdc.kp.org
              ;;
        ivdc) mksysbServer="czabbs${SNum}.crdc.kp.org"
              RespVal=100
              LogLoc=CRDCLogs; SwRepo=czabsu1e.crdc.kp.org
              MainDC=No;;
        ssdc) mksysbServer="szabbs${SNum}e.ssdc.kp.org"
              LogLoc=SSDCLogs; SwRepo=szabsu1e.ssdc.kp.org
              ;;
        nndc) mksysbServer="nzabbs${SNum}e.nndc.kp.org"
              LogLoc=NNDCLogs; SwRepo=nzabsu1e.nndc.kp.org
              ;;
        wcdc|wpoc|tic) 
                     mksysbServer="wzabbs${SNum}e.wcdc.kp.org"
                     Pinged=$(ping -c1 -w1 $mksysbServer 2>/dev/null | grep ttl= | sed 1q)
                     Pinged=${Pinged:-NotPinged}
                     if [[ $Pinged == NotPinged ]]; then
                        mksysbServer="pzabbs${SNum}e.pldc.kp.org"
                        LogLoc=PLDCLogs; SwRepo=pzabsu1e.pldc.kp.org
                     fi
                     ;;
        bcdc) mksysbServer="draxbs${SNum}e.bcdc.kp.org"
              LogLoc=BCDCLogs; SwRepo=draxsu1e.bcdc.kp.org
              ;;
        pldc) mksysbServer="pzabbs${SNum}e.pldc.kp.org"
              LogLoc=PLDCLogs; SwRepo=pzabsu1e.pldc.kp.org
              ;;
           *) mksysbServer="pzabbs${SNum}e.pldc.kp.org"
              RespVal=100
              MainDC=No;;
              #East Bay 
esac

if [[ $MainDC == No ]]; then
  PrintINFO "DC $DOMAINLOC does not have a dedicated mksysb repo."
  PrintINFO "Transactional network will be used for file transfer"
else
  PrintINFO "DC $DOMAINLOC has a dedicated mksysb repo."
fi

CopyKey='/.ssh/mksysbukey'
if [ ! -f $CopyKey ]
then
    CheckSerRename SwRepo $SwRepo
    SwRepo=${SwRepo:-pzabsu1.pldc.kp.org}
    ReInstallBackup
fi

##Fil3 system
IsFS=$(lsfs /mksysbfs 2>/dev/null | grep jfs2)
if [[ -z ${IsFS} ]]; then
 mklv -y mksysblv -L mksysblv -t jfs2 rootvg 1 && crfs -v jfs2 -d mksysblv -m /mksysbfs -Ay -prw -a logname=INLINE
 chfs -a size=8G /mksysbfs
 mount /mksysbfs
  PrintINFO "CHECK File system - Created new /ksysbfs File system "
else
  PrintINFO "CHECK File system PASS"
fi

CronEntry='30 21 * * 0 /usr/local/scripts/backupos.ksh -B'
Crontab=$(cat /var/spool/cron/crontabs/root | grep backup)
if [[ -z ${Crontab} ]]; then
  echo "${CronEntry}" >> /var/spool/cron/crontabs/root
  CronResp=$(lsitab -a | grep cron | grep respawn)
  if [[ ! -z ${CronResp} ]]; then
   KillPID=$(ps -ef | grep -w cron | grep -v grep | awk '{print $2}')
   kill -9 $KillPID
  fi
  PrintINFO "CHECK Cron Entry - Added new cron entry"
else
  PrintINFO "CHECK Cron Entry - PASS"
fi

PrintINFO "SELECT destination server $mksysbServer for $HostName in $DOMAINLOC" 
#Check if the repo server renamed
CheckSerRename mksysb $mksysbServer

if [ "${IsUP}" != Down ] && [ $MainDC == Yes ]; then
   PrintSUCC "$mksysbServer is up. File should be transferred to this repo"
elif [[ $MainDC == No ]]; then
   PrintSUCC "$mksysbServer is up but not in the same domain as this server"
   PrintINFO "File should be transferred to this repo over transactional network"
else
   PrintWARN "$mksysbServer ping unsusscessful. Backup interface may be down while ROUTE IS SET."
   netstat -Cr | while read Line
   do
    PrintINFO "Routes : $Line"
   done
   PrintINFO "Please compare routing table with backup IP address"
fi

SSHCMD="$_CMDSSH  ${SSHopt} mksysbu@${mksysbServer}"
SCPCMD="$_CMDSCP ${SSHopt} -o BatchMode=yes"

PrintINFO "CHECK for local backup network for TARGET server $mksysbServer" 
#Get backup IP and see whether interface is configured
BackupInterface=
LinkState='Down'
IFUsed='BACKUP'
#Backup Lebel can be different on non standard host names. Following added on Oct 20, 2015
   #HostNameTrunc=`hostname |awk -F. '{print $1}' | sed 's/v1$//g; s/h$//g; s/v2$//g'`
   HostName=`hostname |awk -F. '{print $1}'`
   Length=${#HostName}
   i=0
   CleanHostName=
   DigitFound=No
      while [[ $i -lt $Length ]]; do
        let  i=$i+1
        Lett=$(echo $HostName | cut -c$i)
        Lettt=$(echo $Lett | tr -d '[a-z] [A-Z]' | sed 's/\-//g')
           if [[ X != X$Lettt ]]; then
             DigitFound=Yes
           else
            if [[ $DigitFound == Yes ]]; then
              LastPart="$(echo $HostName | cut -c${i}-${Length})"
              break
            fi
           fi
     CleanHostName="${CleanHostName}${Lett}"
  done

LastPart=$(echo $LastPart | sed 's/ //g')
if [[ X != "X${LastPart}" ]]; then
  PrintWARN "Found an extended host name. Checking further"
  case ${LastPart} in
   @(*new|*tmp)) PrintINFO "Host name determined as ${CleanHostName}${LastPart}"
                 BackupLebel="${CleanHostName}e${LastPart}" ;;
              *) PrintINFO "Trying backup lablel ${CleanHostName}e${LastPart}"
                 BackupLebel="${CleanHostName}e${LastPart}" ;;
   esac
else
   BackupLebel="${CleanHostName}e"
   PrintINFO "Host name looks correct in this system"
fi

  PrintINFO "Expected DNS Name of local Backup interface is $BackupLebel"
  host $BackupLebel >/dev/null 2>&1; InDns=$?
  if [[ $InDns -ne 0 ]]; then
   PrintERRO "There may be no DNS entry for host name $BackupLebel"
  else
   BackuIP=$(host $BackupLebel | awk '/,/ {print $3}' | sed 's/,//g')
   BackuIP=$(host $BackupLebel | awk '{print $NF}')
   PrintINFO "IP $BackuIP should have been configured as $BackupLebel on this server"
   BackupGW=${BackuIP%.*}.1
  fi

#BackupIP=$(nslookup $BackupIPName | grep -v "#" | grep Address: | sed '$!d' | awk '{print $NF}')
  for Interface in `ifconfig -ul | sed 's/lo0//g'`
  do
    IP=$(ifconfig $Interface | grep inet |sed 1q | awk '{print $2}')
    if [[ X == "X$IP" ]]; then continue; fi
    RiverseIP=$(echo $IP | awk -F"." '{print $4"."$3"."$2"."$1}')
    FromDNS=$(nslookup $IP |  awk -v Ser=$RiverseIP '$0 ~ Ser {print $NF}')
      if [[ $FromDNS != @(*kp.org*) ]]; then
       FromDNS=$(nslookup $IP |  awk -v Ser=`uname -n | tr -d '[0-9]'` '$0 ~ Ser {print $NF}')
      fi
      IFtype=$(echo $FromDNS | sed 's/ie//g; s/new//g; s/old//g' | tr -d  -c e'[0-9]'e)  #Fails when server has XXnew as part of name
#Check whether the IP is backup one
    if [[ "$FromDNS" != @(*$BackupLebel*) ]]; then
      PrintINFO "Interface $Interface $IP does not match $BackupLebel"
      continue
    else
      BackupIP=$IP
      BackupInterface=$Interface
      PrintSUCC "Backup interface $Interface has been configured. IP $IP matches $BackupLebel"
      FirstThreeBIP=$(echo ${BackupIP} | cut -d. -f1-3)
      break
    fi
 done

if [[ ! -z $BackupIP ]]; then
  BackupGW=$(echo "${BackupIP}" | sed 's/.0$/.1/g')
  if [[ -z $BackupInterface ]]; then
    BackupInterface=$(odmget -q "value=${BackupIP} AND attribute=netaddr" CuAt 2>/dev/null | grep name | sed 's/"//g' | awk '{print $NF}')
  fi
  PingWait=5
else
  PrintINFO "Backup IP has not been configured" 
  PingWait=3
fi

BackupInterface=${BackupInterface:-NotConfiged}
if [[ $BackupInterface != NotConfiged ]]; then
  BackupNM=$(odmget -q "name=$BackupInterface AND attribute=netmask" CuAt | grep value | sed 's/"//g' | awk '{print $NF}')
  BackupNM=${BackupNM:-$(lsattr -El $BackupInterface -a netmask -F value)}
  PrintINFO "CHECKING route over local backup network " 
  BackupIFace="Backup IF $BackupInterface for $BackupIP configured"

 	set -A IParray `echo $BackupIP | sed 's/\./ /g'`
	set -A NMarray `echo $BackupNM | sed 's/\./ /g'`
	set -A NetArray
	typeset -i16 NuA
	typeset -i16 NuB
		i=0	
		while [[ $i -lt 4 ]]; do
  		  #echo "${IParray[$i]} \t\c"
  		  #echo "${NMarray[$i]} \t\c"
    		  IParray[$i]=`echo "obase=16;${IParray[$i]}"|bc`
    		  NMarray[$i]=`echo "obase=16;${NMarray[$i]}"|bc`
  		  #echo "${IParray[$i]} \t\c"
  		  #echo "${NMarray[$i]} \t\c"
    		  NuA="16#${IParray[$i]}"
    		  NuB="16#${NMarray[$i]}"
    		  #echo "$NuA $NuB"
  		  NetArray[$i]=$(($NuA&$NuB))
    		  let i=$i+1
		done

	BackupNW=$(echo ${NetArray[*]} | sed 's/ /\./g')
        BackupGW=$(echo "${BackupNW}" | sed 's/.0$/.1/g')

   if [[ -z $BackupGW ]]; then
     BackupNW=$(netstat -Cnr 2>&1 | grep $BackupIP | egrep -v ".255|127.0.0|"/"" | awk '{print $1}' | grep .0$ | sed 1q)
     BackupGW=$(echo "${BackupNW}" | sed 's/.0$/.1/g')
   else
      PrintINFO "BACKUP Network is ${BackupNW} ,IP is $BackupIP , Gateway is $BackupGW" 
   fi
  [ X != "X${BackupGW}" ] && FirstThreeBGW=$(echo ${BackupGW} | cut -d. -f1-3)

  if [[ $BackupInterface != NotConfiged ]]; then
    LinkState=$(entstat -d $BackupInterface 2>&1 | awk '/Link Status/ {print $NF}')
  fi
    if [[ $LinkType != @(*Up*) ]]; then
      if [[ $BackupInterface != NotConfiged ]]; then
        LinkType=$(entstat -d $BackupInterface 2>&1 | grep -i virtual | awk '/Device Type/ {print $3}' | sed '$!d')
      fi
      if [[ "$LinkType" != @(*Virtual*) ]]; then
       LinkState=Unknown
      else
       LinkState=Up
       if [[ $BackupInterface != NotConfiged ]]; then
        PVID=$(entstat -d $BackupInterface 2>&1 | grep -i vlan | grep -v Invalid | awk -F : '{printf $NF " "}')
       fi
       PVID=$(printf "%s %s %s %s" $PVID Virtual )
      fi
      PrintINFO "IF $BackupInterface UP - PVID $PVID - bound to address $BackupIP. Testing connection" 
      #ping -w3 -c1 ${BackupGW} >/dev/null 2>&1
      PrintINFO "Backup gateway - $(traceroute -m2 -q1 -w2 ${BackupGW} 2>&1 | sed '$!d' | grep ms || echo 'DOES NOT WORK. Servers may be on same netwrok or trace BLOCKED')"
    fi
fi

#With TSM routes in place there may not be a need to add separate route.
IsGWup=
RouteSet=No
NewRoute=No
GWType=Backup
XXX=0
TarGetIP=$(host $mksysbServer | awk '{if (/,/) {print $3}else{print $NF}}')

TestRoute() {
  [ $T_FLAG == TRUE ] && set -x
  let XXX=$XXX+1
    RepoSer=$1
    SourceIP=$2
    TargetIP=$(host $RepoSer | awk '{if (/,/) {print $3}else{print $NF}}')
    TargetHost=$RepoSer
    CSourceIP=
    TRSucceess=No
    ShotRepoName=$(echo ${RepoSer} | cut -d . -f1)
    SerClient=$(traceroute -m${PingWait} -w2 ${RepoSer} 2>&1 | grep from | awk '{print $3 " " $4 " " $6}')  #$6 backup IP
    SerClient=$(echo $SerClient |sed 's/^ //g')
    SerClient=${SerClient:-None}
    if [[ "X$SerClient" != XNone ]]; then
      TargetHost=$(echo $SerClient | awk '{printf $1}')
      TargetIP=$(echo $SerClient | awk '{printf $2}' | sed 's/(//g; s/)//g')
      CSourceIP=$(echo $SerClient | awk '{printf $3}')
    else
      PrintINFO "Trying new version of traceroute"
      traceroute -m${PingWait} -w2 ${RepoSer} 2>&1 | egrep 'from|traceroute to| ms' | while read TRline
      do
        case $TRline in
         @(*traceroute*)) TargetIP=$(echo $TRline | grep 'traceroute to' |\
                            awk -F\( '{print $2}' | sed 's/)//g')
                          TargetHost=$(host $TargetIP | awk '{printf $1}') ;;
               @(*from*)) CSourceIP=$(echo $TRline | grep from | sed 's/(/ /g; s/)/ /g' | awk '{print $NF}');;
        esac

        if [[ $TRline == @(* ms *) ]]; then
          TRSucceess=Yes
        fi
      done
     if [[ $TRSucceess == No ]]; then 
       TargetIP=
     fi
     if [[ "X$CSourceIP" == "X$BackupIP" ]]; then 
       RouteSet=Yes
     fi
    fi

    if [[ X == "X$TargetIP" ]]; then
     PrintWARN "$RepoSer may not be reached through $SourceIP."
     PrintWARN "Either local network, STATIC routes, or firewall block"
     BackupNetwork="LOCAL Backup network NOT OK"
     IsUpRepo=$(ping -c1 -w1 $RepoSer 2>&1 | grep ttl | grep ms | awk '{print $4}' | sed 's/://g')
     if [[ -z $IsUpRepo ]]; then
       SerVerUP=No
     else
       SerVerUP=Yes
     fi
     IsGWup=Down
    else
     PrintSUCC "$RepoSer reached through $SourceIP."
     PrintINFO "Test $XXX - Route seem to be set for  ${mksysbServer}. Checking end to end link for SCP"
     SerVerUP=Yes
     RouteSet=Yes
     IsGWup=Up
    fi 
}

SetNewRoute() {
[ $T_FLAG == TRUE ] && set -x
 IsGWup=
   RecordStaticRoutes() {
       lsattr -El inet0 -a route -F value | while read Line
       do
         PrintWARN "Delete S.Route $Line .."
       done
   }

  DelTempRoute() {
     RouteTo=$1
     HBRoute=$(netstat -Cnr | grep $RouteTo | sed 1q)
     CurrentGateway=$(echo $HBRoute | awk '{print $2}')
      if [[ X != "X$CurrentGateway" ]]; then
         PrintINFO "Deleting $HBRoute"
         route delete ${RouteTo} $CurrentGateway  2>/dev/null
      else
         PrintINFO "No host base route qualifies for deletion"
      fi
  }

   TarGetIP=${1:-$TarGetIP} #Host based route is the one only tested
   IsNumeric=$(echo $TarGetIP | sed 's/\.//g' | tr -d '[0-9]' | sed 's/ //g')
   if [[ X != "X$IsNumeric" ]]; then
     TarGetIP=$(host $TarGetIP | awk '{if (/,/) {print $3}else{print $NF}}')
   fi
   GateWay=${2:-$BackupGW}
   PrintINFO "Checking for existing route to IP ${TarGetIP} over gateway $GateWay"  

   if [[ $BackupInterface != NotConfiged ]]; then
     IsGWup=$(ping -c1 -w5 -r -L -I ${BackupIP} -o ${BackupInterface} ${BackupGW} 2>/dev/null | grep ttl)  #TR issue WDC
     IsGWup=${IsGWup:-Down}
     [ $IsGWup != Down ] && IsGWup=Up
   fi

   if [[ $IsGWup != Down ]]; then
       PrintSUCC "Local backup gatway is UP. Testing route now"
       TestRoute ${mksysbServer} ${BackupIP} 
   else
       PrintINFO "Backup gateway is down OR $Hostname cannot reach ${mksysbServer} from ${BackupIP}"
   fi

   if [[ $RouteSet == Yes ]] && [[ $IsGWup != Down ]]; then
        PrintSUCC "Route is already set."
   elif [[ $IsGWup != Down ]]; then
      PrintINFO "Gateway seem to be up. Routing table may be updated with a host base route"
      PrintWARN "Route is NOT set for $TarGetIP over $GateWay. Checking whether gateway is active"
      HBRoute=$(netstat -Cnr | grep $TarGetIP | sed 1q)
        if [[ X == "X$HBRoute" ]]; then
          PrintINFO "No host based route has been set up yet. Adding one"
          NewRoute=Yes
          PrintINFO "NEW ROUTE to ${mksysbServer} ... -host ${TarGetIP} ${GateWay}"
          route add -host ${TarGetIP} ${GateWay} 2>/dev/null  2>/dev/null
          TestRoute ${TarGetIP} ${BackupIP} 
          if [[ $RouteSet == Yes ]]; then
            PrintSUCC "Route is set now."
            IsGWup=Yes
            GWType=Backup
          else
            PrintWARN "New route did not work. Removing it"
            DelTempRoute ${TarGetIP}
            IsGWup=No
            GWType=default
          fi
        else
          PrintWARN "A route to ${TarGetIP} may exist while gateway is down. Removing it"
          PrintWARN "Cannot remove any atatic routes, if they cause problems here"
          DelTempRoute ${TarGetIP}
          RecordStaticRoutes
        fi
    else
      PrintERRO "Backup interface gateway is not accessible. Cannot set the route"
      PrintWARN "Cannot remove any atatic routes, if they cause problems here"
      RecordStaticRoutes
      IsGWup=No
      GWType=Default
    fi
}

if [[ ! -z ${BackupGW} ]]; then
  PrintINFO "Backup gateway should be ${BackupGW}"
    if [[ $MainDC == Yes ]]; then 
        PrintINFO "This domain has its own backup repo"
        PrintINFO "Tracing route to ${mksysbServer} over backup gateway"
        if [[ $BackupInterface != NotConfiged ]]; then
          TestRoute ${mksysbServer} ${BackupIP} #Route may already been set
          if [[ $RouteSet == No ]]; then
             PrintINFO "Route is not yet set. Setting a host based route"
             SetNewRoute ${TarGetIP} ${BackupGW}
             TestRoute ${mksysbServer} ${BackupIP}
          else
             PrintINFO "Route is already set. continuing"
          fi
        else
           PrintERRO "Server in a main DC should have a backup IP"
        fi
    else
      PrintINFO "For $DOMAINLOC, there is no backup server. Main IP will be used for file transfer"
      IsGWup=Yes
      GWType=default
      RouteSet=Yes
      BackupGW=$(netstat -Cnr | grep default | awk '{print $2}')
    fi #Route may already been set

    if [[ $GWType == Backup ]] && [[ ${IsGWup} != Down ]]; then 
      #SerVerUP=Yes
      PrintSUCC "Gateway ${BackupGW} can route mksysb file to the repo. Connection is good. "
      IFUsed='BACKUP' ; WaitTime=30
      ThisHost=$BackupLebel
      BackupNetwork="Backup network usable"
      IFUsed='BACKUP' ; WaitTime=30
    elif [[ $MainDC == No ]]; then 
      SerVerUP=Yes
      PrintSUCC "Default Gateway used to copy mksysb file to the repo. Connection is good. "
      IFUsed='DEFAULT'
    elif [[ $MainDC == Yes ]]; then 
      PrintINFO "Reverting to transactional interface"
      if [[ ${IsGWup} != Up ]]; then
        PrintWARN "A server in main DC with faulty backup network found"
        PrintWARN "Probable cause a faulty backup network with static route?"
        IFUsed='DEFAULT'
      fi
    else
      PrintWARN "Undefined situation. Default Gateway used to copy mksysb file to the repo."
    fi

   #Bind="-o BindAddress=${BackupIP}"
   if [[ ! -z ${SerVerUP} ]] && [[ ${IsGWup} != Down ]]; then
    SerStatus="$mksysbServer reachable"
     KeyConn=$($SSHCMD 'date')
     sleep 1
     KeyConn=${KeyConn:-$($SSHCMD 'date')}
     if [[ -z $KeyConn ]]; then
       SerStatus="Cannot ssh to $mksysbServer"
       PrintWARN "SSH does not work well between $mksysbServer. Checking .. " 
     fi 
  else
    PrintWARN "$mksysbServer NOT reacheable over backup network."
    PrintWARN "Using default gateway to reach `echo $mksysbServer | sed 's/e././g'`" 
    mksysbServer=$(echo $mksysbServer | sed 's/e././g') #Make the mksysb server to transactional IP
    WaitTime=60 ; IFUsed='DEFAULT'
    SerStatus="$mksysbServer not reachable over backup net"
  fi
else
 PrintERRO "NO Backup Interface has been configured. Using transactional interface" 
 IFUsed=DEFAULT
fi

if [[ $IFUsed == DEFAULT ]] && [[ $MainDC == Yes ]]; then
   PrintERRO "Please trobleshoot the backup interface  when the server in a main DC"
   PrintWARN "Destination mksysb repository transactional interface selected"
   mksysbServer=$(echo $mksysbServer | sed 's/e././g') #Make the mksysb server to transactional IP
   TarGetIP=$(host $mksysbServer | awk '{if (/,/) {print $3}else{print $NF}}')
   BackupGW=$(netstat -Cnr | grep default | awk '{print $2}')
   SSHCMD="$_CMDSSH ${SSHopt} mksysbu@${mksysbServer}"
   WaitTime=60 ; IFUsed='DEFAULT'
   BackupNetwork="Backup network Not usable"
   PrintSTAT "Trans interface picked for file transfer"
elif [[ $IFUsed == DEFAULT ]] && [[ $MainDC == No ]]; then
   PrintSTAT "Backup interface picked for file transfer"
else
   PrintSTAT "Backup interface picked for file transfer"
fi

PrintINFO "Starting SCP test to ${mksysbServer}"
IsUP=$(ping -w3 -c1 $mksysbServer 2>/dev/null | grep ttl | sed '$!d')  #Ping over default route
IsUP=${IsUP:-Down}
if [[ "${IsUP}" != Down ]]; then
   PrintSUCC "$mksysbServer is up. File should be transferred to this repo"
   sshsuccess=$($SSHCMD 'date' >/dev/null; echo $?)
   if [[ $sshsuccess -ne 0 ]]; then
    PrintWARN "SSH did not work correctly. Re-installing keys and testing again"
    CheckSerRename SwRepo $SwRepo
    SwRepo=${SwRepo:-pzabsu1.pldc.kp.org}
    ReInstallBackup
   fi
   test_ssh_conn

   #Try linking the backup interface to mksysb server
   #Copy a small file to test the connection
   SCP_statues=1
     if [[ -f ${logFile} ]]; then
       LogFileDetail=$(ls -l $logFile 2>/dev/null | awk '{print $5 " " $NF}')
       PrintINFO "Test copy file ${LogFileDetail} to ${mksysbServer}:/mksysbfs"
       $SCPCMD ${logFile} mksysbu@${mksysbServer}:/mksysbfs; SCP_statues=$?
       sleep 1
     else
       PrintINFO "Log file ${logFile} does not exist. Not an error"
       PrintINFO "Retrying Test copy file ${LogFileDetail} to ${mksysbServer}:/mksysbfs"
       $SCPCMD ${logFile} mksysbu@${mksysbServer}:/mksysbfs; SCP_statues=$?
       sleep 1
     fi

     if [[ $SCP_statues != 0 ]]; then
       PrintINFO "SCP test between ${ThisHost} and ${mksysbServer} failed." 
       LinkState='Down'
       mksysbServer=$(echo $mksysbServer | sed 's/e././g') #Make the mksysb server to transactional IP
       PrintFAIL "SCP or SSH test failed."
       PrintINFO "Procceding with rest of tasks $StartFucn"
       SSHCMD="$_CMDSSH ${SSHopt} mksysbu@${mksysbServer}"
       Bind=
       IFUsed='DEFAULT'
       sshsuccess=$($SSHCMD 'date' >/dev/null; echo $?)
       lsattr -El inet0 -a route | awk '{print $2}' | while read RouteLine
       do
        let StR=$StR+1
        PrintINFO "Static route $StR $RouteLine"
       done
       StR=0
       netstat -Cnr | while read RouteLine
       do
        let StR=$StR+1
        PrintINFO "Static route $StR $RouteLine"
       done
     else
       PrintSUCC "SCP test between ${ThisHost} and ${mksysbServer} PASS." 
       LinkState='Up'
       PrintSUCC "End to end link looks good. Check which network was selected"
     fi
else
   PrintFAIL "$mksysbServer is down. File transfer may not happen"
fi

PrintINFO "Transfer files to ${mksysbServer} over $IFUsed interface" 
CpmleteStatus="`uname -n` --> ${SerStatus}. ${BackupNetwork}"

if [ "$B_FLAG" = TRUE ]
then
PrintINFO "STARTING ${StartFucn} PROCEDURE " 
	chk4proc 
	PrepareRootVG
	run_mksysb 
	copy_mksysb
	run_altrootvg_copy 
	altroot_postcheck
	verify_mksysb
	exit_function
fi

if [ "$m_FLAG" = TRUE ]
then
StartFucn='mksysb'
PrintINFO "STARTING ${StartFucn} PROCEDURE " 
	chk4proc 
	PrepareRootVG
	run_mksysb 
        if [[ $HdiskType == @(power|Power|SYMM_*) ]]; then
          pprootdev fixback >/dev/null
        fi
	copy_mksysb 
	verify_mksysb
	exit_function
fi

if [ "$a_FLAG" = TRUE ]
then 
StartFucn='Clone'
PrintINFO "STARTING ${StartFucn} PROCEDURE " 
	chk4proc 
	PrepareRootVG
	run_altrootvg_copy 
	altroot_postcheck
	exit_function
fi

if [ "$C_FLAG" = TRUE ]
then
PrintINFO "STARTING ${StartFucn} PROCEDURE " 
  MksysbFiletoSend=${MksysbFiletoSend:-$(find /mksysbfs -xdev -size +1000 -name "${ClientName}.mksysb*"|head -1)}
  if [[ X == "X$MksysbFiletoSend" ]]; then
     PrintERRO "There is no mksysb backup in /mksysbfs. Please run `basename $0` with -m option"
  else
     PrintINFO "Going to copy and save backup file ${MksysbFiletoSend}"
     copy_mksysb 
     verify_mksysb
  fi
  exit_function
fi

if [ "$L_FLAG" = TRUE ]
then
	exit_function
fi

if [ "$v_FLAG" = TRUE ]
then
PrintINFO "STARTING ${StartFucn} PROCEDURE " 
  verify_mksysb
  exit_function
fi

if [ "$D_FLAG" = TRUE ]
then
PrintINFO "STARTING ${StartFucn} PROCEDURE " 
	PrintINFO "DMZ FLAG ACTIVATED. File copy does not happen"
	chk4proc 
	PrepareRootVG
	run_mksysb 
	run_altrootvg_copy 
	altroot_postcheck
	dmzopt
	exit_function
fi

usage
