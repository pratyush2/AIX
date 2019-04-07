#!/usr/bin/ksh
# @(#)/usr/local/scripts/info2db.ksh
# @(#)v1.40 07/05/07


####
#
#	info2db.ksh
#	-It scans /var/adm/cfg/hc/*.nfo
#	-It puts db information to ktazd2000.crdc.kp.org with mysql user in
#	mysql db
#
#	History:
#	version 1.40	07/05/07	D.Lieberman
#			Added support for system_info.ksh v1.28
#	version 1.39	06/15/07	D.Lieberman
#			Added support for system_info.ksh v1.27.
#			(adds fcs2 and fcs3 firmware info)
#	version 1.38	04/19/07	D.Lieberman
#			Added code to support system_info.ksh v1.25
#			(consolidation of cft2html_aix.sh and system_info.ksh)
#	version 1.37	03/27/07	D.Lieberman
#			Redirected output to ktazd2000; server DB and
#			servers_info Table (server.servers_info). No longer
#			using crdc_servers DB. ok to drop the defunct table.
#			Added $DATABASE and $TABLE to "variablize" the
#			database and table that the info2db.ksh script updates.
#			Removed redundant put_info_db function since the
#			put_info_db_update function does the updating.
#	version 1.36	03/08/07	D.Lieberman
#			Added field for KPHC environment flag
#	version 1.35	01/23/07	D.Lieberman
#			Added field for HACMP cluster name
#	version 1.34	08/07/06	D.Lieberman
#			Added support for J2RE (Java) version.
#	version 1.33	06/27/06	D.Lieberman
#			Added support for system_info.ksh version.
#	version 1.32	05/10/06	D.Lieberman
#			Added support for WSLB (or ND) version.
#	version 1.31	05/09/06	D.Lieberman
#			Added support for HACMP/ES version.
#	version 1.30	05/08/06	D.Lieberman
#			Added support for 5 new columns: model, hmc,
#			cpus, real memory, kernel.
#	Author: Ryan Dang
#	date:   10/10/05
#	date:  	02/10/06
#	version:	1.2
#
##############################################################################

####################### Variables ############################################
DATABASE="server"				# Database name to connect to.
TABLE="servers_info"				# Table to update

####################### Functions ############################################
function initialize
{
	err=0
	BASE_DIR=/var/adm/cfg/hc
	LOG=/tmp/mysql.tmp
	LOG2=/tmp/mysql.log
	if [ ! -f $LOG ]; then
		touch $LOG
	fi
	if [ ! -f $LOG2 ]; then
		touch $LOG2
	fi
}

function read_base_dir_list_queue
{
	s=1
	DIR=$1
	ls -1A $DIR |while true
	do
		read fil
		
		if [ "$fil" = "" ]; then
			(( s=s - 1 ))
			break
		else
			if [ -f "$DIR/${fil}" ] && [ "${fil}" != ".profile" ] && [ "${fil}" != ".sh_history" ]; then
				abs_path_files[${s}]="$DIR/${fil}" 
				(( s=s + 1 ))
			fi
		fi
	done	
}

function print_array
{
	print "${abs_path_files[1]}"
	print "${abs_path_files[2]}"
	print "${abs_path_files[3]}"
}

function put_info_db_update
{
# usage: put_info_db_update database table

DATABASE=$1
TABLE=$2

mysql --user=mysql --password=mysql -h ktazd2000.crdc.kp.org 2>$LOG <<!!

USE $DATABASE;
INSERT INTO $TABLE
(host_name, system_sn, system_firmware, os_level, sdd_version, ibm2105_level, fcs_firmware0, fcs_firmware1, rsct_version, fcs_com_drivers_ver_f7, fcs_rte_drivers_ver_f7, fcs_drivers_ver_f9, sysback_version, creation_date, system_model, hmc, cpus, mem, kernel, hacmp_version, wslb_version, sysinfo_version, java_version, hacmp_name, enterprise_env, proc_type, proc_speed, con_login, rem_login, auto_restart, full_core, ip_address, netmask, gateway, name_server, domain, page_space, ps_used, fcs_firmware2, fcs_firmware3, emcpower, perl_version)
VALUES ("$HOSTNAME", "$SYSTEM_SN", "$SYSTEM_FIRMWARE", "$AIX_OS_VERSION", "$SDD_VERSION", "$IBM_2105_LEVEL", "$FCS0_FIRMWARE_VERSION", "$FCS1_FIRMWARE_VERSION", "$RSCT_VERSION", "$F7_COM", "$F7_RTE", "$F9_RTE", "$SYSBACK_VERSION", "$CREATION_DATE", "$SYSTEM_MODEL", "$HMC", "$CPUS", "$MEM", "$KERNEL", "$HACMP_VERSION", "$WSLB_VERSION", "$SYSINFO_VERSION", "$JAVA_VERSION", "$HACMP_NAME", "$ENTERPRISE_ENV", "$PROC_TYPE", "$PROC_SPEED", "$CON_LOGIN", "$REM_LOGIN", "$AUTO_RESTART", "$FULL_CORE", "$IP_ADDRESS", "$NETMASK", "$GATEWAY", "$NAME_SERVER", "$DOMAIN", "$PAGE_SPACE", "$PS_USED", "$FCS2_FIRMWARE_VERSION", "$FCS3_FIRMWARE_VERSION", "$EMCPOWER", "$PERL_VERSION")
ON DUPLICATE KEY UPDATE os_level="$AIX_OS_VER", system_sn="$SYSTEM_SN", system_firmware="$SYSTEM_FIRMWARE", sdd_version="$SDD_VERSION", ibm2105_level="$IBM_2105_LEVEL", fcs_firmware0="$FCS0_FIRMWARE_VERSION", fcs_firmware1="$FCS1_FIRMWARE_VERSION", rsct_version="$RSCT_VERSION", fcs_com_drivers_ver_f7="$F7_COM", fcs_rte_drivers_ver_f7="$F7_RTE", fcs_drivers_ver_f9="$F9_RTE", sysback_version="$SYSBACK_VERSION", creation_date="$CREATION_DATE", system_model="$SYSTEM_MODEL", hmc="$HMC", cpus="$CPUS", mem="$MEM", kernel="$KERNEL", hacmp_version="$HACMP_VERSION", wslb_version="$WSLB_VERSION", sysinfo_version="$SYSINFO_VERSION", java_version="$JAVA_VERSION", hacmp_name="$HACMP_NAME", enterprise_env="$ENTERPRISE_ENV", proc_type="$PROC_TYPE", proc_speed="$PROC_SPEED", con_login="$CON_LOGIN", rem_login="$REM_LOGIN", auto_restart="$AUTO_RESTART", full_core="$FULL_CORE", ip_address="$IP_ADDRESS", netmask="$NETMASK", gateway="$GATEWAY", name_server="$NAME_SERVER", domain="$DOMAIN", page_space="$PAGE_SPACE", ps_used="$PS_USED", fcs_firmware2="$FCS2_FIRMWARE_VERSION", fcs_firmware3="$FCS3_FIRMWARE_VERSION", emcpower="$EMCPOWER", perl_version="$PERL_VERSION";


quit
!!
return $?
}

function db_layout
{
	FILE=$1

	HOSTNAME=$(cut -d"," -f1 $FILE)
	SYSTEM_SN=$(cut -d"," -f2 $FILE)
	SYSTEM_FIRMWARE=$(cut -d"," -f3 $FILE)
	AIX_OS_VER=$(cut -d"," -f4 $FILE)
	SDD_VERSION=$(cut -d"," -f5 $FILE)
	IBM_2105_LEVEL=$(cut -d"," -f6 $FILE)
	FCS0_FIRMWARE_VERSION=$(cut -d"," -f7 $FILE)
	FCS1_FIRMWARE_VERSION=$(cut -d"," -f8 $FILE)
	RSCT_VERSION=$(cut -d"," -f9 $FILE)
	F7_COM=$(cut -d"," -f10 $FILE)
	F7_RTE=$(cut -d"," -f11 $FILE)
	F9_RTE=$(cut -d"," -f12 $FILE)
	SYSBACK_VERSION=$(cut -d"," -f13 $FILE)
	CREATION_DATE=$(cut -d"," -f14 $FILE)
	SYSTEM_MODEL=$(cut -d"," -f15 $FILE)
	HMC=$(cut -d"," -f16 $FILE)
	CPUS=$(cut -d"," -f17 $FILE)
	MEM=$(cut -d"," -f18 $FILE)
	KERNEL=$(cut -d"," -f19 $FILE)
	HACMP_VERSION=$(cut -d"," -f20 $FILE)
	WSLB_VERSION=$(cut -d"," -f21 $FILE)
	SYSINFO_VERSION=$(cut -d"," -f22 $FILE)
	JAVA_VERSION=$(cut -d"," -f23 $FILE)
	HACMP_NAME=$(cut -d "," -f24 $FILE)
	ENTERPRISE_ENV=$(cut -d "," -f25 $FILE)
	PROC_TYPE=$(cut -d "," -f26 $FILE)
	PROC_SPEED=$(cut -d "," -f27 $FILE)
	CON_LOGIN=$(cut -d "," -f28 $FILE)
	REM_LOGIN=$(cut -d "," -f29 $FILE)
	AUTO_RESTART=$(cut -d "," -f30 $FILE)
	FULL_CORE=$(cut -d "," -f31 $FILE)
	IP_ADDRESS=$(cut -d "," -f32 $FILE)
	NETMASK=$(cut -d "," -f33 $FILE)
	GATEWAY=$(cut -d "," -f34 $FILE)
	NAME_SERVER=$(cut -d "," -f35 $FILE)
	DOMAIN=$(cut -d "," -f36 $FILE)
	PAGE_SPACE=$(cut -d "," -f37 $FILE)
	PS_USED=$(cut -d "," -f38 $FILE)
	FCS2_FIRMWARE_VERSION=$(cut -d"," -f39 $FILE)
	FCS3_FIRMWARE_VERSION=$(cut -d"," -f40 $FILE)
	EMCPOWER=$(cut -d"," -f41 $FILE)
	PERL_VERSION=$(cut -d"," -f42 $FILE)
}

############## MAIN ###############
#Setup environment
initialize

#Check for files
read_base_dir_list_queue $BASE_DIR

#Update database
k=1
until [ $k -gt $s ]
do
	db_layout ${abs_path_files[${k}]}
	
	put_info_db_update $DATABASE $TABLE
	
	if [ $? -eq 0 ]; then	
	#remove nfo files
	rm -f ${abs_path_files[${k}]} 
	(( k=k + 1 ))
	else
		cat $LOG >> $LOG2
		date >> $LOG2
		print "ERROR" >>$LOG2
		break
		err=1
	fi
done

if [ $err -eq 1 ]; then 
	exit 1
fi

#print_array
############ END ###########
