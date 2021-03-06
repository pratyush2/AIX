#!/bin/ksh
# Script Name:                  /usr/local/scripts/checklist.ksh
# Author:                       Russell Teeter 
# Creation Date:                05/21/2003
# Functional Description:       This script will generate a USS Customization summary report 
# Usage:                        checklist.ksh
#
#
# Modification History:
#
# Initials      Date    Modification Description
# --------    --------  ---------------------------------------------------
# RST		7/8/03	Added descriptions to functions
# RST		2/18/04 Change Max Processes to 500
# RST		3/2/04	Change I/O History to false.
# RST		3/4/04	Removed AOBEEP and MAX/M checks per Don.
# RST		3/9/04	Added Courion check and LPAR question
# RST		5/27/04	Modified SYS_INFO to just grep for IBM.
#
# I would like to thank Saul Ramos, Sonnie Nguyen, Sikander Mohamed, Reggie Brown and Ty Wu for their help in the creation of this script.
#
############################################################################### 

## VARIABLES ##
HOSTNAME=`hostname`
OS_LEVEL=`oslevel`
MAINT_LEVEL=`oslevel -r`
AIXLEVEL=`oslevel |awk -F . '{print $1 $2 $3}'`
HOSTIP=`netstat -in |grep en|grep -v link|awk '{print $4}'`
MBMEMORY=`lsattr -El mem0 |grep Total | awk '{print $2}'`
MEMORY=`bootinfo -r`
PAGING_SPACE=`lsps -s |grep MB|awk '{print $1}'`
ROOTVG_PPSIZE=`lsvg rootvg|grep "PP SIZE:"|awk '{print $6}'`MB
ROOTVG_QUORUM=`lsvg rootvg|grep "QUORUM"|awk '{print $5}'`
KERNEL_TYPE=`bootinfo -K`
CRON_ROOT=`grep -E "sysdumpchksz|cfg2" /var/spool/cron/crontabs/root |wc -l`
SNMP=`cat /etc/snmpd.conf|grep snmpd.log| awk '{print $3}'`
LICENSE=`lslicense |grep fixed|awk '{print $7}'|cut -c 1,2`
SYS_INFO=`lsattr -El sys0|grep -E "500|20|MBUFS|33|24|true"|grep -Ev "400000000|IBM|enable|disable|physical" |awk '{print $2}'|tr '\n' ' '`
SYSDUMP_INFO=`sysdumpdev -l |grep -E "primary|secondary"|awk '{print $2}'`
SYSDUMP=`sysdumpdev -l|grep udsdump|awk '{print $2}'|grep udsdump|wc -l`
AIO_CHECK=`lsattr -El aio0 |grep autoconfig|awk '{print $2}'`
SKULKER_SET=`crontab -l|grep skulker|awk '{print $1}'`
SKULKER_FILE=`grep 'atime +7 -mtime +7' /usr/sbin/skulker|wc -l`
NTP_PERM=`ls -l /etc |grep ntp.keys| grep '\-rw-------'`
NTP_FILE=`grep 'start /usr/sbin/xntpd "$src_running"' /etc/rc.tcpip`
NTP_PROC=`ps -aef|grep -v grep|grep xntpd`
NTP_LPP=`lslpp -l |grep ntp`
SYSB_SERV=`ls -l /usr/lpp/sysback/.servers`
SYSB_USER=`lsuser sbnet`
CHECK_DISK=`lsdev -Ccdisk|grep -w hdisk4|awk '{print $4,$5,$6,$7}'`
CHECK_APPS=`lsvg -p appsvg|grep hdiskpower`
PERF_USER=`lsuser perf|grep -E "/home/perf|/home2/perf"`
PERF_PROC=`ps -aef|grep perf|wc -l`
PERF_ACCT=`lsvg -l appsvg|grep home2`
TIV_PROC=`ps -aef|grep lcf|grep -v grep|wc -l`
LOG_ROT=`ls /etc/logrotate.conf /usr/share/man/man8/logrotate.8 /usr/local/bin/logrotate|wc -l`
LOG_FILE=`cd /usr; find . -name gzip |wc -l`
#COUR_PERM=`ls -l /usr/local/courion |grep pxy.scr| grep '\-rwx------'`
#COUR_USER=`lsuser coursvc`
COUR_PROC=`ps -aef|grep cour|grep -v grep|wc -l`
SEC_ROOT=`lsuser root |awk '{print $10}'`

## LOGGING ##
outputDir=/tmp
reportFile=${outputDir}/checklist.$(hostname -s).$(date +%m%d%y)

## FUNCTION DEFINITIONS ##
## Check which user is running the report ##
###########################################################################
#	This places the person who runs the scripts' name at the top of   #
#	the output file.                                                  #
###########################################################################
function check_name
	{
	echo "Please enter your name:"
	read i
	echo "Your name is $i" >> $reportFile
	}

## Initialize checklist report with some system config entries ##
###########################################################################
#	The gives information like servername, oslevel, all IP Addresses, #
#	Memory on the server, paging space, root PP size, and what kernel #
#	is being run.                                                     #
###########################################################################
function initialize_checklist_report
	{
	echo "AIX INSTALLATION CHECKLIST FOR `hostname` Created on `date`" >> $reportFile
	echo "" >> $reportFile
	echo "Server Name,$HOSTNAME" >> $reportFile
	echo "OS Level,$OS_LEVEL" >> $reportFile
	echo "IP Address,$HOSTIP" >> $reportFile
	echo "Size Of Memory in kbytes,$MEMORY" >> $reportFile
	echo "Size Of Memory (mem0) in MB,$MBMEMORY" >> $reportFile
	echo "Size Of Paging Space,$PAGING_SPACE" >> $reportFile
	echo "rootvg PP size,$ROOTVG_PPSIZE" >> $reportFile
	echo "AIX Kernel 32 or 64 bit?,$KERNEL_TYPE" >> $reportFile
	return 0
	}

## Check for rootvg quorum ##
###########################################################################
#	This verifies that quorum has been turned off for rootvg.         # 
###########################################################################
function check_rootvg_quorum 
	{
	if [ $ROOTVG_QUORUM = 1 ]
	then
	echo "Turn Quorum off for rootvg ?,Yes" >> $reportFile
	else
	echo "Turn Quorum off for rootvg ?,No" >> $reportFile
	fi
	return 0
	}

## Check for JFS2 Filesystems ##
###########################################################################
#	This checks to see if the filesystems are created as jfs2         #
#	filesystems.                                                      #
###########################################################################
function check_jfs2
	{
	lsvg -l rootvg|grep jfs2 >/dev/null 2>&1
	if [ $? = 0 ]
	then
	echo "rootvg JFS2 filsystem ?,Yes" >> $reportFile
	else
	echo "rootvg JFS2 filsystem ?,No" >> $reportFile
	fi 
	return 0
	}

## Check for two DNS nameservers in the configurtion ##
###########################################################################
#	This checks to make sure 2 DNS servers have been setup            #
###########################################################################
function check_dns
	{
	num_nameservers=`cat /etc/resolv.conf|grep nameserver|wc -l`
	if [ $num_nameservers -gt 1 ]
	then
	echo "Two DNS pointers configure ?,Yes " >> $reportFile
	else
	echo "Two DNS pointers configure ?,No " >> $reportFile
	fi
	return 0
	}

## Check for Network Performance Tuning ##
##########################################################################
#	This check verifies network parameters are set per standard.     #
##########################################################################
function net_perf_tuning
	{
	parameters="tcp_sendspace=65536 tcp_recvspace=65536 bcastping=1 tcp_mssdflt=1448 udp_sendspace=32768 udp_recvspace=65536 rfc1323=1 tcp_mssdflt=1448 ipqmaxlen=512 udp_pmtu_discover=0 tcp_pmtu_discover=0"
	for i in $parameters
	do
	grep $i /etc/rc.net > /dev/null 2>&1
	done
	if [ $? -eq 0 ]
	then
	echo "Network Performance Tuning Completed ?,Yes" >> $reportFile
	else
	echo "Network Performance Tuning Completed ?,No" >> $reportFile
	fi
	return 0
	}

## Check for USSWEB Monitoring ##
##########################################################################
#	Checks to see if WEB monitoring has been setup on the server.    #
##########################################################################
function check_uss_web
	{
	mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/usr/local/scripts /mnt
	grep $HOSTNAME /mnt/cfgtable >/dev/null 2>&1
	if [ $? = 0 ]
	then
	echo "USSWEB monitoring setup ?,Yes" >> $reportFile
	else
	echo "USSWEB monitoring setup ?,No" >> $reportFile
	fi
	umount /mnt
	return 0
	}

## Check for Monitoring Scripts ##
##########################################################################
#	Looks to see if certain keys words like: sysdumpchk, sysdumpchksz#
#	cfg2html_aix.sh, pscycle, psmonitor, ect are in                  #
#	/usr/local/scripts.                                              #
##########################################################################
function check_scripts
        {
        parameters="sysdumpchk sysdumpchksz mir_rootvg cfg2html_aix.sh pscycle psmonitor trackaval.ksh trackaval2.ksh sysbackc.ksh sysbackchk.ksh sysbacklocal.ksh sysbacklog.ksh"
        for i in $parameters
        do
        cd /usr/local/scripts;ls $i >/dev/null 2>&1
        done
        if [ $? = 0 ]
        then
        echo "Monitoring scripts ftp'd to /usr/local/scripts ?,Yes" >>$reportFile
        else
        echo "Monitoring scripts ftp'd to /usr/local/scripts ?,No" >>$reportFile
        fi
        return 0
        }

## Check root's cron for USS standards ##
##########################################################################
#	Checks to see if sysdumpchksz and cfg2 are in the crontab.       #
##########################################################################
function check_root_cron
	{
	if [ $CRON_ROOT = 2 ]
	then
	echo "root crontab updated for baseline config + monitoring?,Yes" >> $reportFile
	else
	echo "root crontab updated for baseline config + monitoring?,No" >> $reportFile
	fi
	return 0
	}
	

## Check Message of the Day file ##
function check_motd
	{
	grep -i "Private Computer system" /etc/motd > /dev/null 2>&1
	if [ $? = 0 ]
	then
	echo "Login 'message of the day' replaced ? (/etc/motd),Yes" >> $reportFile
	else
	echo "Login 'message of the day' replaced ? (/etc/motd),No" >> $reportFile
	fi
	return 0
	}

## Check FTPD option ##
function check_inetd
	{
	grep "ftpd -l" /etc/inetd.conf > /dev/null 2>&1
        if [ $? = 0 ]
        then
        echo "Log option set for FTPD? (/etc/inetd.conf),Yes" >> $reportFile
        else
        echo "Log option set for FTPD? (/etc/inetd.conf),No" >> $reportFile
        fi
	return 0
	}

## Check Syslog Daemon Configuration ##
function check_syslogd
	{
	grep "daemon.debug" /etc/syslog.conf | grep "/var/adm/daemon.syslog" > /dev/null 2>&1
        if [ $? = 0 ]
        then
        echo "Daemon syslog Configured?,Yes" >> $reportFile
        else
	echo "Daemon syslog Configured?,No" >> $reportFile
        fi
        return 0
        }

## Check for disabling of SNMP ##
function check_snmp
	{
	echo $SNMP |grep "disable" > /dev/null 2>&1
        if [ $? = 0 ]
        then
        echo "SNMP logging disabled?,Yes" >> $reportFile
        else
        echo "SNMP logging disabled?,No" >> $reportFile
        fi
        return 0
        }

## Verify System Parameters ##
function check_sys_parms
	{
	case $AIXLEVEL in
	433 )	sysinfo="20 0 500 true 33 24 true "
		;;
	510 )	sysinfo="20 0 500 true 33 24 true "
		;;
	520 )	sysinfo="true true 20 0 33 500 24 "
		;;
	*   )   print "OSLEVEL not correct"
		;;

esac

#	sysinfo="true true true 20 0 33 500 24 "
#	sysinfo="20 0 500 true true 33 24 true "
#	echo "sysinfo=$sysinfo"
#	set -x
	if [ "${SYS_INFO}" = "$sysinfo" ]
	then
	echo "System Parameters set?(max #s; high/low water marks....),Yes" >> $reportFile
	else
	echo "System Parameters set?(max #s; high/low water marks....),No" >> $reportFile
	fi
	return 0
	}


## Verify System Parameters - Take 2 ##
function check_sys_parms2
	{
	echo "System Parameters" >> $reportFile
	echo "-----------------" >> $reportFile
	value1=`lsattr -El sys0 | grep PROCESSES | awk '{print "Max Processes = 500 ,Current is ", $2 }'`
	value2=`lsattr -El sys0 | grep pages| awk '{print "I/O Buffer Pages = 20 ,Current is ", $2 }'`
	value3=`lsattr -El sys0 | grep MBUFS| awk '{print "Max Memory MBUFS = 0 ,Current is ", $2 }'`
	value4=`lsattr -El sys0 | grep REBOOT| awk '{print "Automatic REBOOT = true ,Current is ", $2 }'`
	value5=`lsattr -El sys0 | grep DISK| awk '{print "DISK I/O History = false ,Current is ", $2 }'`
	value6=`lsattr -El sys0 | grep HIGH| awk '{print "HIGH Watermark = 33 ,Current is ", $2 }'`
	value7=`lsattr -El sys0 | grep LOW| awk '{print "LOW Watermark = 24 ,Current is ", $2 }'`
	value8=`lsattr -El sys0 | grep fullcore| awk '{print "Enable Full CORE dump = true ,Current is ", $2 }'`
	echo $value1 >> $reportFile
	echo $value2 >> $reportFile
	echo $value3 >> $reportFile
	echo $value4 >> $reportFile
	echo $value5 >> $reportFile
	echo $value6 >> $reportFile
	echo $value7 >> $reportFile
	echo $value8 >> $reportFile
	echo "-----------------" >> $reportFile
	}

## Check Current Date and Time ##
function check_date
	{
	date >> $reportFile
	return 0
	}

## Check number of Licensed Users ##
function check_license
	{
	echo "# of Licensed AIX Users?,$LICENSE" >> $reportFile
	return 0
	}

## Check Sysdump Devices ##
function check_sysdump
	{
	num_sysdumpdevs=$SYSDUMP
	if [$num_sysdumpdevs != 2 ]
	then
	echo "You need to install 2 udsdump devices in complete successfully.,No" >> $reportFile
	else
	echo "2 System dump devices configured?,Yes" >> $reportFile
	echo $SYSDUMP_INFO >> $reportFile
	fi
	}

## Check the AIO is enabled ##
function check_aio
	{
	if [ $AIO_CHECK = available ]
	then
	echo "Asynchronous I/O enabled?,Yes" >> $reportFile
	else
	echo "Asynchronous I/O enabled?,No" >> $reportFile
	fi
	return 0
	}

## Check to see if the skulker scripts is configured ##
function check_skulker
	{
#	echo "SKULKER_SET is set to...."
#	echo $SKULKER_SET
	if [ $SKULKER_SET != 0 ]
	then 	
	echo "You need to fix skulker process in crontab.,No" >> $reportFile
	elif [ $SKULKER_FILE != 2 ]
	then
	echo "You need to change the skulker file tmp settings to be +7 atime and mtime.,No" >> $reportFile
	else
	echo "skulker configured? (edit times;cron),Yes" >> $reportFile
	fi
	return 0
	}

##  Check to see if rootvg is mirrored ##
function check_mirror
	{
	lvs="hd1 hd2 hd3 hd4 hd5 hd8 hd9var"
	sum_count=0
	for i in $lvs
	do
	j=`lslv $i |grep COPIES|awk '{print $2}'`
	sum_count=$sum_count+$j
	done
	if [ $sum_count -eq 14 ]
	then
	echo "rootvg filesystems mirrored (if prod)? (not dump;paging),Yes" >> $reportFile
	else
	echo "rootvg filesystems mirrored (if prod)? (not dump;paging),No" >> $reportFile
	fi
	return 0
	}
	
## Check to see if App-Dev fileset is installed ##
function check_appdev
	{
	case $AIXLEVEL in
	433 )	mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix433_image /mnt
		INSTALLP_CMD="/usr/lib/instl/sm_inst installp_cmd -a -Q -d /mnt -b App-Dev -f '_all_licensed' -p -g -X -G"
		;;
	510 )	mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix510_image/installp/ppc /mnt
		INSTALLP_CMD="/usr/lib/instl/sm_inst installp_cmd -a -Q -d /mnt -b App-Dev -f '_all_licensed' -p -g -X -G"
		;;
	520 )	mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix520_image/installp/ppc /mnt
		INSTALLP_CMD="/usr/lib/instl/sm_inst installp_cmd -a -Q -d /mnt -b App-Dev -f 'all' '-p' '-g' '-X' '-G'"
		;;
	*   )	print "OSLEVEL not correct"
		;;

esac

	APP_DEV=$($INSTALLP_CMD | grep "Total to be installed" | awk '{print $1}')
	if [ $APP_DEV = 0 ]
	then
	echo "App-Dev Bundle Installed?,Yes" >> $reportFile
	else
	echo "App-Dev Bundle Installed?,No" >> $reportFile
	fi
	return 0
	}

## Check to see if Server Bundle is installed ##
function check_server
	{
	case $AIXLEVEL in
	433 )   mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix433_image /mnt
		INSTALLP_CMD="/usr/lib/instl/sm_inst installp_cmd -a -Q -d /mnt -b Server -f '_all_licensed' -p -g -X -G"
		;;
	510 )   mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix510_image/installp/ppc /mnt
		INSTALLP_CMD="/usr/lib/instl/sm_inst installp_cmd -a -Q -d /mnt -b Server -f '_all_licensed' -p -g -X -G"
		;;
	520 )   mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix520_image/installp/ppc /mnt
		INSTALLP_CMD="/usr/lib/instl/sm_inst installp_cmd -a -Q -d /mnt -b Server -f 'all' -p -g -X -G"
		;;
	*   )   print "OSLEVEL not correct"
		;;

esac

	SERVER=`$INSTALLP_CMD | grep "Total to be installed" | awk '{print $1}'`
#	SERVER=`mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix${AIXLEVEL}_image/installp/ppc /mnt; /usr/lib/instl/sm_inst installp_cmd -a -Q -d '/mnt' -b 'Server' -f 'all' '-p'   '-g' '-X'  '-G' | grep "Total to be installed" | awk '{print $1}'`
	if [ $SERVER = 0 ]
	then
	echo "SERVER Bundle Installed?,Yes" >> $reportFile
	else
	echo "SERVER Bundle Installed?,No" >> $reportFile
	fi
	return 0
	}

## Check to see if all Devices are installed ##
function check_devices
	{
	case $AIXLEVEL in
	433 )   mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix433_image /mnt
		INSTALLP_CMD="/usr/lib/instl/sm_inst installp_cmd -a -c -g -Q -X -d /mnt -f 'devices' '-p'"
		;;
	510 )   mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix510_image/installp/ppc /mnt
		INSTALLP_CMD="/usr/lib/instl/sm_inst installp_cmd -a -c -g -Q -X -d /mnt -f 'devices' '-p'"
		;;
	520 )   mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix520_image/installp/ppc /mnt
		INSTALLP_CMD="/usr/lib/instl/sm_inst installp_cmd -a -c -g -Q -X -d /mnt -f 'devices' '-p'"
		;;
	*   )   print "OSLEVEL not correct"
		;;

esac

	DEVICES=`$INSTALLP_CMD | grep "Total to be installed" | awk '{print $1}'`
#	DEVICES=`mount -o rw,bg,soft,intr,proto=tcp,retry=100 ktazd216:/aix/aix${AIXLEVEL}_image/installp/ppc /mnt; /usr/lib/instl/sm_inst installp_cmd -a -c -g -Q -X -d '/mnt' -f 'devices' '-p' | grep "Total to be installed" | awk '{print $1}'`
	if [ $DEVICES = 0 ]
	then
	echo "All Devices Installed?,Yes" >> $reportFile
	else
	echo "All Devices Installed?,No" >> $reportFile
	fi
	return 0
	}


## Check to see if bos.dosutil is installed ##
function check_bosdos
	{
	lslpp -l |grep bos.dosutil > /dev/null 2>&1
	if [ $? = 0 ]
	then
	echo "DOS Utility Installed?,Yes" >> $reportFile
	else
	echo "DOS Utility Installed?,No" >> $reportFile
	fi
	return 0
	}


## Check to see if MAN pages are installed ##
function check_man
	{
	lslpp -l *en_US.cmds* >/dev/null 2>&1
	if [ $? = 0 ]
#	if [ "${CHECK_MAN}" = "" ]
	then
	echo "MAN Pages installed?,Yes" >> $reportFile
	else
	echo "MAN Pages installed?,No" >> $reportFile
	fi
	return 0
	}
	
## Check AIX Maintance Level ##
function check_maint
	{
	if [ "${MAINT_LEVEL}" = "" ]
	then
	echo "AIX Maintenance installed?,No Maintenance" >> $reportFile
	else
	echo "AIX Maintenace installed?,$MAINT_LEVEL" >> $reportFile
	fi
	return 0
	}


## Check Configuration Collection ##
function check_config
	{
	ls -ld /var/adm/cfg > /dev/null 2>&1
	if [ $? = 0 ]
	then
	echo "Configuration Collection configured?(cron;getcfg*;scripts;...),Yes" >> $reportFile
	else
	echo "Configuration Collection configured?(cron;getcfg*;scripts;...),No" >> $reportFile
	fi
	return 0
	}

## Check Page Space Monitoring ##
function check_pagespace
	{
	ls -l /var/adm/cfg/psmonitor.out >/dev/null 2>&1
	if [ $? = 0 ]
	then
	echo "Page Space Monitoring Configured?(cron;ps* scripts),Yes" >> $reportFile
	else
	echo "Page Space Monitoring Configured?(cron;ps* scripts),No" >> $reportFile
	fi
	return 0
	}

## Check if OpenSSH is installed ##
function check_ssh
	{
	lslpp -l|grep -i "OpenSSH 3.7.1" > /dev/null 2>&1
	if [ $? = 0 ]
	then
	echo "Openssh Version 3.7 Installed?,Yes" >> $reportFile
	else
	echo "Openssh Version 3.7 Installed?,No" >> $reportFile
	fi
	return 0
	}

## Check if Availibility Tracking is Configured ##
function check_avail
	{
	cat /etc/rc.shutdown |grep -E "Sikandar|Mohamed" >/dev/null 2>&1
	if [ $? = 0 ]
	then
	echo "Availablity Tracking configured?(scripts;cron;...),Yes" >> $reportFile
	else
	echo "Availablity Tracking configured?(scripts;cron;...),No" >> $reportFile
	fi
	return 0
	}

## Check if Sudo is installed ##
function check_sudo
	{
	lslpp -l |grep sudo > /dev/null 2>&1
	if [ $? = 0 ]
	then
	echo "Sudo Installed?,Yes" >> $reportFile
	else
	echo "Sudo Installed?,No" >> $reportFile
	fi
	return 0
	}


## Check if NTP is installed ##
function check_ntp
	{
#	echo "NTP_PERM is set to...."
#	echo $NTP_PERM
#	echo "NTP_LPP is set to..."
#	echo $NTP_LPP
	ntpfiles=`ls -l /etc/ntp.keys /etc/ntp.conf|wc -l`
	if [ $ntpfiles != 2 ]
	then
	echo "FTP ntp files from ktazd216.,No" >> $reportFile
	elif [ "${NTP_PERM}" = "" ]
	then
	echo "Set Parmissions on ntp.keys to 600,No" >> $reportFile
	elif [ "${NTP_FILE}" = "" ]
	then
	echo "You need to comment 'in' xntpd in /etc/tcpip.,No" >> $reportFile
	elif [ "${NTP_PROC}" = "" ]
	then
	echo "NTP process not running.,No" >> $reportFile
	elif [ "${NTP_LPP}" = "" ]
	then
	echo "NTP Installed?,No" >> $reportFile
	else
	echo "NTP Installed?,Yes" >> $reportFile
	fi
	return 0
	}

## Check to see if Sysback is Installed and Configured ##
function check_sysback
	{
	lslpp -l |grep sysback > /dev/null 2>&1
	if [ $? != 0 ]
	then
	echo "Sysback needs to be installed.,No" >> $reportFile
	elif [ "${SYSB_SERV}" = "" ]
	then
	echo "Please configure sysback.(.servers; .exclude_list),No" >> $reportFile
	elif [ "${SYSB_USER}" = "" ]
	then
	echo "Sysback Installed?,No" >> $reportFile
	else
	echo "Sysback Installed?,Yes" >> $reportFile
	fi
	return 0
	}


## Check for disaster Recovery ##
function check_disaster
	{
	echo "If production server, has Disaster Recovery been completed? (Y,N,N/A"
	read i
	if [ $i = "Y" -o $i = "y" -o $i = "Yes" -o $i = "yes" -o $i = "YES" ]
	then
	echo "Disaster Recovery? (scripts; cron; ktazp95 or ktazp131...)?,Yes" >> $reportFile
	elif [ $i = "NA" -o $i = "N/A" -o $i = "na" -o $i = "n/a" ]
	then
	echo "Disaster Recovery? (scripts; cron; ktazp95 or ktazp131...)?,Non-Production Server" >> $reportFile
	else
	echo "Disaster Recovery? (scripts; cron; ktazp95 or ktazp131...)?,No" >> $reportFile
	fi
	return 0
	}

## Check for Server Database Update ##
function check_serv_database
	{
	echo "Has the Server DataBase been Updated? Y/N"
	read i
	if [ $i = "Y" -o $i = "y" -o $i = "Yes" -o $i = "yes" -o $i = "YES" ]
	then
	echo "Server Database updated?,Yes" >> $reportFile
	else
	echo "Server Database updated?,No" >> $reportFile
	fi
	return 0
	}
	

## Check for Project/Contacts Database Update ##
function check_proj_database
	{
	echo "Has the Project/Contacts DataBase been Updated? Y/N"
	read i
	if [ $i = "Y" -o $i = "y" -o $i = "Yes" -o $i = "yes" -o $i = "YES" ]
	then
	echo "Project/Contacts Database updated?,Yes" >> $reportFile
	else
	echo "Project/Contacts Database updated?,No" >> $reportFile
	fi
	return 0
	}


## Check Root Filesystem Size ##
function check_root
	{
	echo >> $reportFile
	i=`df -k / |grep -v Used|awk '{print $4}'| sed -e "s/[%]*$//"`
	`echo "/ = $i percent Used" >> $reportFile`
	if [ $i -gt 90 ]
	then
	echo "Please check the size of /.,No" >> $reportFile
	else
	echo "/ filesystem under 90%.,Yes" >> $reportFile
	fi
	return 0
	}


## Check Var Filesystem Size ##
function check_var
	{
	i=`df -k /var |grep -v Used|awk '{print $4}'| sed -e "s/[%]*$//"`
	`echo "/var = $i percent Used" >> $reportFile`
	if [ $i -gt 60 ]
	then
	echo "Please check the size of /var.,No" >> $reportFile
	else
	echo "/var filesystem under 60%.,Yes" >> $reportFile
	fi
	return 0
	}


## Check Root Filesystem Size ##
function check_usr
	{
	i=`df -k /usr |grep -v Used|awk '{print $4}'| sed -e "s/[%]*$//"`
	`echo "/usr = $i percent Used" >> $reportFile`
	if [ $i -gt 90 ]
	then
	echo "Please check the size of /usr.,No" >> $reportFile
	else
	echo "/usr filesystem under 90%.,Yes" >> $reportFile
	fi
	return 0
	}

## Check Root Filesystem Size ##
function check_tmp
	{
	i=`df -k /tmp |grep -v Used|awk '{print $4}'| sed -e "s/[%]*$//"`
	`echo "/tmp = $i percent Used" >> $reportFile`
	if [ $i -gt 90 ]
	then
	echo "Please check the size of /tmp.,No" >> $reportFile
	else
	echo "/tmp filesystem under 90%.,Yes" >> $reportFile
	fi
	return 0
	}

## Check for DASD/External Disk Drives ##
function check_disk
	{
	d=`lsdev -Ccdisk|grep -w hdisk4`
	if [ $? != 0 ]
	then
	echo "DASD installed?,No" >> $reportFile
	else
	echo "DASD installed?,$CHECK_DISK" >> $reportFile
	fi
	return 0
	}

## Check if appsvg is created and what volume group ##
function check_appsvg
	{
	lsvg appsvg >> /dev/null 2>&1
	if [ $? != 0 ]
	then
	echo "appsvg created?(EMC or SSA),No" >> $reportFile
	elif [ "${CHECK_APPS}" = "" ]
	then
	echo "appsvg created?(EMC or SSA),SSA" >> $reportFile
	else
	echo "appsvg created?(EMC or SSA),EMC" >> $reportFile
	fi
	return 0
	}


## Check Performance Reporter ##
function check_perf_rpt
	{
	lsuser perf > /dev/null 2>&1
	if [ $? != 0 ]
	then
	echo "Performance Reporter User not created.,No" >> $reportFile
	elif [ "${PERF_USER}" = "" ]
	then
	echo "Perf User not created in /home2/perf.,No" >> $reportFile
	elif [ "${PERF_PROC}" -lt 4 ]
	then
	echo "Please run installepdm.,No" >> $reportFile
	elif [ "${PERF_ACCT}" = "" ]
	then
	echo "Create perf account in /home2 in appsvg.,No" >> $reportFile
	else
	echo "Performance Reporter installed?(not rootvg),Yes" >> $reportFile
	fi
	return 0
	}
	


## Check Tivoli Installation ##
function check_tiv
	{
	lsfs /usr/Tivoli > /dev/null 2>&1
	if [ $? != 0 ]
	then
	echo "/usr/Tivoli not created.,No" >> $reportFile
	elif [ "${PERF_ACCT}" = "" ]
	then
	echo "Tivoli not installed in /usr/Tivoli in appsvg.,No" >> $reportFile
	elif [ "${TIV_PROC}" -lt 1 ]
	then
	echo "Tivoli process not running.,No" >> $reportFile
	else
	echo "Tivoli installed in appsvg (after EMC DASD)? (not in rootvg),Yes" >> $reportFile
	echo "Please check ktazp56 for monitor status by doing the following:" >> $reportFile
	echo "/usr/easm/prod/bin/generic/check_ep.pl HOSTNAME (for status)" >> $reportFile
	echo "/usr/easm/prod/bin/generic/check_sub.pl HOSTNAME (for monitors)" >> $reportFile
	fi
	return 0
	}


## Check LOGROTATE Installation ##
function check_logrotate
	{
	if [ "${LOG_ROT}" -lt 3 ]
	then
	echo "Verify all 3 files exist for logrotate.,No" >> $reportFile
	elif [ "${LOG_FILE}" -lt 1 ]
	then
	echo "Verify that gzip is installed on the server.,No" >> $reportFile
	else
	echo "LOGROTATE Installation completed?,Yes" >> $reportFile
	fi
	return 0
	}


## Check Security Hardening ##
function check_security
	{
	parameters="/usr/sbin/rlogind /usr/sbin/tftpd /usr/bin/rlogin /usr/bin/rcp /usr/bin/rsh /usr/bin/tftp"
	SEC_CHECK=`ls -l $parameters |awk '{print $1}' | grep "\-\-\-\-\-\-\-\-\-\-" | wc -l`
#	echo $SEC_CHECK
	if [ "${SEC_CHECK}" -ne 6 ]
	then
	echo "All security files not disabled.,No" >> $reportFile
	elif [ "${SEC_ROOT}" != "rlogin=false" ]
	then
	echo $SEC_ROOT >> $reportFile
	echo "Root set for rlogin.,No" >> $reportFile
	else
	echo "Security Hardening completed?,Yes" >> $reportFile
	fi
	return 0
	}


## Check Courion Password Express ##
function check_courion
	{
	ls -l /usr/local/courion|grep pwdcour_unixpxy > /dev/null 2>&1
	if [ $? != 0 ]
	then
	echo "Files don't exist in /usr/local/courion.,No" >> $reportFile
	elif [ "${COUR_PERM}" = "" ]
	then
	echo "/usr/local/courion/pxy.scr not set to 700.,No" >> $reportFile
	elif [ "${COUR_USER}" = "" ]
	then
	echo "Courion User not created.,No" >> $reportFile
	elif [ "${COUR_PROC}" -lt 1 ]
	then
	echo "Courion process not running.,No" >> $reportFile
	else
	echo "Courion Password Express Installed?,Yes" >> $reportFile
	fi
	return 0
	}

## LPAR ONLY - Reset /etc/ct_node_id ##
function check_lpar
	{
	echo "If LPAR, has /etc/ct_node_id been reset? (Y,N,N/A)"
	read i
	if [ $i = "Y" -o $i = "y" -o $i = "Yes" -o $i = "yes" -o $i = "YES" ]
	then
	echo "LPAR /etc/ct_node_id reset?,Yes" >> $reportFile
	elif [ $i = "NA" -o $i = "N/A" -o $i = "na" -o $i = "n/a" ]
	then
	echo "LPAR /etc/ct_node_id reset?,Not an LPAR" >> $reportFile
	else
	echo "LPAR /etc/ct_node_id reset?,No" >> $reportFile
	fi
	return 0
	}
function check_vpath
	{
	echo "If server has Shark storage? (Y,N,N/A)"
	read i
	if [ $i = "Y" -o $i = "y" -o $i = "Yes" -o $i = "yes" -o $i = "YES" ]
	then
	echo "VPATH Check" >>$reportFile
	#Check to see if any 2105 hdisks  are mapped to a VG
	lspv | grep -v root |grep -v $(lsdev -Cc disk |awk '/LVD SCSI/ {printf " -e %s",$1}') | awk '/hdisk/ {if ($3 !~ "None" ) {print "Found "$1 " mapped to VG " $3}}'
	# Check to ensure that all adapters are In a NORMAL state and the Mode is ACTIVE
	datapath query adapter | awk '/fscsi/ {if ( $3 !~ "NORMAL" ||  $4 !~ "ACTIVE" ){print $2" Found to be in a non-Normal state or non-Active mode"}'}
	elif [ $i = "NA" -o $i = "N/A" -o $i = "na" -o $i = "n/a" ]
	then
	echo "Server does not have Shark Storage" >> $reportFile
	fi
	return 0
	} 
## Check which user is running the report ##
function check_disco
	{
	echo "Notification sent to DISCO & Cesar for WESP Update? Y/N"
	read i
	if [ $i = "Y" -o $i = "y" -o $i = "Yes" -o $i = "yes" -o $i = "YES" ]
	then
	echo "Notification sent to DISCO & Cesar for WESP Update?,Yes" >> $reportFile
	else
	echo "Notification sent to DISCO & Cesar for WESP Update?,No" >> $reportFile
	fi
	return 0
	}
	
	
#########
# MAIN
#########
check_name
initialize_checklist_report
check_rootvg_quorum
check_jfs2
check_dns
net_perf_tuning
check_uss_web
check_scripts
check_root_cron
check_motd
check_inetd
check_syslogd
check_snmp
check_sys_parms
check_sys_parms2
check_date
check_license
check_sysdump
check_aio
check_skulker
check_mirror
check_appdev
check_server
check_devices
check_bosdos
check_man
check_maint
check_config
check_pagespace
check_ssh
check_avail
check_sudo
check_ntp
check_sysback
check_disaster
check_serv_database
check_proj_database
check_root
check_var
check_usr
check_tmp
check_disk
check_appsvg
check_perf_rpt
check_tiv
check_logrotate
check_security
#check_courion
check_lpar
check_disco
check_vpath
unmount /mnt
