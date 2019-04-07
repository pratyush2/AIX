#!/usr/bin/ksh

# Java DST patch script #
#	ver 1.5		#
#	Ryan Dang	#
#	EPS UNIX	#
#	02/22/07	#

DATE_TMP=$(date +"%m%d%y")
JAVA_STRING='bin sdk Dt'
TEMP_FILE=file.tmp
JAVA_131_32="Java131.rte.bin"
JAVA_131_64="Java13_64.rte.bin"
JAVA_14_32="Java14.sdk"
JAVA_14_64="Java14_64.sdk"
JAVA_5_32="Java5.sdk"
JAVA_5_64="Java5_64.sdk"

JAVA_SIZE=0
JAVA_SIZE_TOTAL=0
LOG=/usr/local/scripts/jpatch.log
FILESET_SRC_PATH=
if [ "$2" = "" ]; then
	REMOTE_FILESET_PATH_BASE=/usr/sys/inst.images
else
	REMOTE_FILESET_PATH_BASE="$2"
fi
REMOTE_FILESET_PATH_DMZ=$REMOTE_FILESET_PATH_BASE/java_dst
DMZ_TRIGGER_FILE=/tmp/jpatch.tgr
JPATCH=$(pwd)/jpatch.ksh
PKG_PATH_LOCAL=0
REMOTE_QUERY=0
EXIT_CODE=0
COMMIT=0
SCP=0
ERROR=0

p=1
h=0	#COUNTER_INDEX
s=1	#COUNTER_INDEX
j=0	#COUNTER_INDEX

if [ -f $DMZ_TRIGGER_FILE ]; then
	PKG_PATH_LOCAL=1
fi

which java 1> /dev/null
if [ $? -eq 0 ]; then
	DEFAULT_JAVA_PATH=$(which java)
else
	DEFAULT_JAVA_PATH=
fi
if [ -f $LOG ]; then
	mv $LOG $LOG.$(date +"%m%d%y%H%M%S")
fi

## CAPTURE LPP before start ##
if [ $# -ne 1 ]; then
	lslpp -l |grep Java > $LOG
	print "" >> $LOG
	print "Default system java path=$DEFAULT_JAVA_PATH" >> $LOG
fi

function backup_secure_lib
{
	SEC_LIB_DIR_TMP=$1
	if [ "$SEC_LIB_DIR_TMP" != "" ]; then
		if [ ! -f $SEC_LIB_DIR_TMP/java.policy.* ]; then
			/usr/bin/cp -p $SEC_LIB_DIR_TMP/java.policy $SEC_LIB_DIR_TMP/java.policy.$DATE_TMP
		fi
			if [ $? -ne 0 ]; then
				return 1
			fi
		if [ ! -f $SEC_LIB_DIR_TMP/java.security.* ]; then
			/usr/bin/cp -p $SEC_LIB_DIR_TMP/java.security $SEC_LIB_DIR_TMP/java.security.$DATE_TMP
		fi
			 if [ $? -ne 0 ]; then
                                return 1
                      	 fi
	fi
}

function check_java_running_process
{
	ps -ef |grep java |sed '/grep/d' |while true
	do
		read PROC_LINE
		if [ "$PROC_LINE" = "" ]; then
			break
		fi
		PROC=$(echo $PROC_LINE|awk '{print $2}')
		PROC_BIN=$(echo $PROC_LINE|awk '{print $8}')
		PROC_BIN_CK=$(echo "$PROC_BIN" |sed 's/[0-9:]//g')
		if [ "$PROC_BIN_CK" = "" ]; then
			PROC_BIN=$(echo $PROC_LINE |awk '{print $9}')
		fi
		(( h=h + 1 ))
		
		# Verify tivoli java endpoint :skipping Tivoli Endpoint #
		PROC_BIN_TIV=$(echo $PROC_LINE |grep lcf)
		
		if [ $h -ge 1 ]; then
			if [ "$PROC_BIN_TIV" = "" ]; then
				print "$(hostname):$LOG" 
				print "$(date) Please stop java process id=$PROC before restart script" |tee -a $LOG
				EXIT_CODE=1
			fi
		fi
		
	done
	if [ $EXIT_CODE -eq 1 ]; then
		print "Script Exited"
		return 1
	fi 
}

function apply_java_patch
{
	PKG_PATH=$1
	PKG_NAME=$2
	SEC_LIB_DIR=$3

	if [ "$PKG_PATH" != "" ] && [ -f $DMZ_TRIGGER_FILE ]; then
		SRC_PATH=$REMOTE_FILESET_PATH_DMZ
	elif [ "$PKG_PATH" != "" ]; then
		SRC_PATH=/mnt
		mount ktazd216.crdc.kp.org:$PKG_PATH $SRC_PATH
	fi
	if [ "$SRC_PATH" != "" ]; then
	
		backup_secure_lib "$SEC_LIB_DIR"
	
		OSLEVEL=$(oslevel -r |cut -d"-" -f1)
		if [ "$OSLEVEL" = "4330" ]; then
			/usr/lib/instl/sm_inst installp_cmd -a -d "$SRC_PATH" -f '_update_all' '-N' '-g' '-X' 2>&1 |tee -a $LOG
			if [ $? -ne 0 ]; then
				print "" >> $LOG
				print "$(date) ERROR while applying patch for $PKG_NAME" |tee -a $LOG
			fi
		
		else
			/usr/lib/instl/sm_inst installp_cmd -a -d "$SRC_PATH" -f '_update_all' '-N' '-g' '-X' '-Y' 2>&1 |tee -a $LOG
			if [ $? -ne 0 ]; then
				print "" >> $LOG
				print "$(date) ERROR while applying patch for $PKG_NAME" |tee -a $LOG
			fi
		fi
		sleep 2
		umount /mnt
	fi
}

function commit_fileset
{
	## Committing the fileset process ##

	FILESET_TMP=$1
	if [ "$FILESET_TMP" != "" ]; then
		/usr/lib/instl/sm_inst installp_cmd -c -f "$FILESET_TMP" '-g' '-X' 2>&1 |tee -a $LOG
		if [ $? -ne 0 ]; then
			print "" >> $LOG
			print "$(date) ERROR while committing fileset $FILESET_TMP" |tee -a $LOG
		fi
	fi
}

function commit_fileset_decision
{
	INDEX=$1
	## If Filesets are NOT COMMITED then commit them ##

	if [ "${java_stat_found_array[${INDEX}]}" != "COMMITTED" ]; then
		commit_fileset ${java_name_found_array[${INDEX}]}
		FILESET_BASE_NAME=$(echo ${java_name_found_array[${INDEX}]} |cut -d"." -f1 |awk '{print $1}')
		FILESET_APPLIED=$(lslpp -l |grep "$FILESET_BASE_NAME" |grep APPLIED |awk '{print $1}')
		for n in $(echo $FILESET_APPLIED)
		do
			commit_fileset $n
		done
	fi
}

function search_installed_java_type
{

for JAVA_TYPE in $(echo $JAVA_STRING)
do
        ## Getting all java fileset that match the strings ##

	if [ $REMOTE_QUERY -eq 1 ]; then
		cat $TEMP_FILE |grep Java |grep "$JAVA_TYPE" |while true
		do
			read LINE
                        if [ "$LINE" = "" ]; then
                                break
                        fi
			## Getting LINE nfo from lpp ##

                        JAVA_FOUND_TMP=$(echo "$LINE" |awk '{print $1,$2,$3}')
                        if [ "$JAVA_FOUND_TMP" != "" ]; then
                                (( j=j + 1 ))

                                ## Putting broken up infomation about fileset in ARRAY ##

                                JAVA_FILESET=$(echo $JAVA_FOUND_TMP |awk '{print $1}')
                                java_name_found_array[${j}]=$JAVA_FILESET
                                java_ver_found_array[${j}]=$(echo $JAVA_FOUND_TMP |awk '{print $2}')
                                java_stat_found_array[${j}]=$(echo $JAVA_FOUND_TMP |awk '{print $3}')

                        fi
		done

	else

        	lslpp -l |grep Java |grep "$JAVA_TYPE" |while true
        	do
                	read LINE
                	if [ "$LINE" = "" ]; then
                        	break
                	fi

                	## Getting LINE nfo from lpp ##

                	JAVA_FOUND_TMP=$(echo "$LINE" |awk '{print $1,$2,$3}')
                	if [ "$JAVA_FOUND_TMP" != "" ]; then
                        	(( j=j + 1 ))

	                        ## Putting broken up infomation about fileset in ARRAY ##
	
        	                JAVA_FILESET=$(echo $JAVA_FOUND_TMP |awk '{print $1}')
                	        java_name_found_array[${j}]=$JAVA_FILESET
                       	 	java_ver_found_array[${j}]=$(echo $JAVA_FOUND_TMP |awk '{print $2}')
                        	java_stat_found_array[${j}]=$(echo $JAVA_FOUND_TMP |awk '{print $3}')

 	                        JAVA_PATH_TMP=$(lslpp -f $JAVA_FILESET |grep "/java " |awk '{print $1}')
        	                java_path_array[${j}]="$JAVA_PATH_TMP"

        	                $JAVA_PATH_TMP -fullversion 2> $TEMP_FILE
	
        	                JAVA_BUILD_VER_TMP=$(cat $TEMP_FILE |cut -d"d" -f2 |sed 's/"//g' |awk '{print $1}')
                	        java_build_ver[${j}]="$JAVA_BUILD_VER_TMP"

 	                       $JAVA_PATH_TMP -version 2> $TEMP_FILE
	
        	                JAVA_BIT_VER_TMP=$(grep 64 $TEMP_FILE)
                	        if [ "$JAVA_BIT_VER_TMP" != "" ]; then
                        	        BIT=64
                        	else
                                	BIT=32
                        	fi
                	fi
        	done
	fi
done

}

function get_remote_host_java_nfo
{
	REMOTE_HOST_TMP=$1
	ssh $REMOTE_HOST_TMP "lslpp -l |grep Java" 2> /dev/null > $TEMP_FILE
	REMOTE_HOST_SIZE_USR=$(ssh $REMOTE_HOST_TMP "df -k $REMOTE_FILESET_PATH_BASE" |awk '{print $3}'|tail -1)
}
function gather_fileset_and_scp
{
	REMOTE_HOST_TMP=$1 
	until [ $p -gt $j ]
	do
	
		case ${java_name_found_array[${p}]} in
        	$JAVA_131_32)
               	 	JAVA_131_32VER="1.3.1.20"
			JAVA_SIZE=72177664
			if [ "${java_ver_found_array[${p}]}" != "$JAVA_131_32VER" ]; then
                                PKG_FOLDER=/misc/java/java131_32bit_SR10
				SCP=1
			fi
        	;;
        	$JAVA_131_64)
                	JAVA_131_64VER="1.3.1.12"
                	JAVA_SIZE=79394816
			
			if [ "${java_ver_found_array[${p}]}" != "$JAVA_131_64VER" ]; then
                                PKG_FOLDER=/misc/java/java131_64bit_SR10
				SCP=1
			fi
        	;;
        	$JAVA_14_32)
                	## Check for version 1.4.2.x ##
                	VER142_CK=$(echo ${java_ver_found_array[${p}]} |grep 1.4.2)
                	if [ "${java_ver_found_array[${p}]}" = "$VER142_CK" ];then
                        	JAVA_142_32VER="1.4.2.75"
                        	JAVA_SIZE=137122816
                		if [ "${java_ver_found_array[${p}]}" != "$JAVA_142_32VER" ]; then        
		               		PKG_FOLDER=/misc/java/java142_32bit_SR5
					SCP=1
				fi
			fi
		;;
		$JAVA_14_64)
               	 	VER142_CK=$(echo ${java_ver_found_array[${p}]} |grep 1.4.2)
                	if [ "${java_ver_found_array[${p}]}" = "$VER142_CK" ];then
                        	JAVA_142_64VER="1.4.2.75"
                        	JAVA_SIZE=196119552
                		if [ "${java_ver_found_array[${p}]}" != "$JAVA_142_64VER" ]; then        
		        		PKG_FOLDER=/misc/java/java142_64bit_SR5
					SCP=1
				fi
                	fi
		;;
		$JAVA_5_32)
                	JAVA_5_32VER="5.0.0.76"
                	JAVA_SIZE=74088448
                	if [ "${java_ver_found_array[${p}]}" != "$JAVA_5_32VER" ]; then
                        	PKG_FOLDER=/misc/java/java5_32bit_SR3
				SCP=1
			else
                		print "$(date) ${java_name_found_array[${p}]} already supported version" |tee -a $LOG
			fi
       		;;
        	$JAVA_5_64)
                	JAVA_5_64VER="5.0.0.75"
                	JAVA_SIZE=74456064
                	if [ "${java_ver_found_array[${p}]}" != "$JAVA_5_64VER" ]; then
                        	PKG_FOLDER=/misc/java/java5_64bit_SR3
				SCP=1
			else
				print "$(date) ${java_name_found_array[${p}]} already supported version" |tee -a $LOG
                	fi
		;;
		*)
			print "$(date) Found non-supported version ${java_ver_found_array[${p}]}" |tee -a $LOG
			SCP=0
		;;
		esac
		(( JAVA_SIZE=JAVA_SIZE / 1024 ))	
		(( JAVA_SIZE_TOTAL=JAVA_SIZE_TOTAL + JAVA_SIZE ))

		if [ $JAVA_SIZE -ne 0 ]; then
			print "JAVA_SIZE_TOTAL= $JAVA_SIZE_TOTAL REMOTE_HOST_SIZE_USE=$REMOTE_HOST_SIZE_USR"
		fi
		JAVA_SIZE=0

		## SCP fileset to remote host ##
		if [ $SCP -eq 1 ]; then
			if [ $JAVA_SIZE_TOTAL -lt $REMOTE_HOST_SIZE_USR ]; then 
				print "1st attempt...Copying fileset....$PKG_FOLDER"
				scp $PKG_FOLDER/Java* $REMOTE_HOST_TMP:$REMOTE_FILESET_PATH_DMZ 2> /dev/null
				if [ $? -eq 1 ]; then
					ssh $REMOTE_HOST_TMP "mkdir -p $REMOTE_FILESET_PATH_DMZ" 2> /dev/null
					print "Copying Fileset...$PKG_FOLDER"
					scp $PKG_FOLDER/Java* $REMOTE_HOST_TMP:$REMOTE_FILESET_PATH_DMZ 2> /dev/null
				fi
			SCP=0
			else
				print "Not enough space on $REMOTE_HOST_TMP:$REMOTE_FILESET_PATH_BASE" |tee -a $LOG
				print "Please copy fileset files relate to ${java_name_found_array[${p}]} manually to remote host" |tee -a $LOG
				EXIT_CODE=1
				break
			fi
		fi
			
		(( p=p + 1 ))
	done
}

function verify_dmz_host
{
	HOST_TEST_TMP=$1
	DMZ_HOST_TMP=$(nslookup $HOST_TEST_TMP 2>/dev/null |sed -n '/Name:/,/Address:/p'|head -1 |awk '{print $2}')
	DMZ_HOST_IP_SUBNET=$(nslookup $HOST_TEST_TMP 2>/dev/null |sed -n '/Name:/{n;p;}' |awk '{print $2}' |cut -d"." -f1-2)
	#if [ "$DMZ_HOST_TMP" != "" ] && [ "$DMZ_HOST_IP_SUBNET" = "162.119" ]; then
	if [ "$DMZ_HOST_TMP" != "" ]; then
		return 1
	else
		return 0
	fi
}
 
### MAIN ####

## If running on ktazd216 ##

if [ $# -eq 1 ]; then
	## DMZ RUN ##
	DMZ_HOST=$1
	HOST_BASE_NAME=$(echo $DMZ_HOST |cut -d"." -f1)
	USER_D_NAME=$(echo $DMZ_HOST |cut -d"." -f2-10)
	DNS_D_NAME=$(nslookup $HOST_BASE_NAME 2>/dev/null |sed -n '/Name:/p'|head -1 |awk '{print $2}' |cut -d"." -f2-10)
	
	for DOMAIN in kp.org $USER_D_NAME $DNS_D_NAME
	do
		DMZ_HOSTNAME=$HOST_BASE_NAME.$DOMAIN
		
		verify_dmz_host $DMZ_HOSTNAME
		if [ $? -eq 1 ]; then
			## answer=1 meaning good ##
			REMOTE_QUERY=1
			print "Processing $DMZ_HOSTNAME"
			get_remote_host_java_nfo $DMZ_HOSTNAME
			search_installed_java_type
			gather_fileset_and_scp $DMZ_HOSTNAME
			break
		else
			print "Trying HOST=$DMZ_HOSTNAME....." |tee -a $LOG
			print "$DMZ_HOSTNAME Not in DMZ or unknown" |tee -a $LOG
			if [ $ERROR -ge 2 ]; then
				EXIT_CODE=1
				break
			else
				(( ERROR=ERROR + 1 ))
			fi
		fi
	done
	
	if [ $EXIT_CODE -eq 1 ]; then
                print "Script Exited"
                exit 1
        else

		## Copy jpatch.ksh and Issuing trigger file to remote host and startup ##
		scp $JPATCH $DMZ_HOSTNAME:/usr/local/scripts/ 2> /dev/null
		ssh $DMZ_HOSTNAME "touch $DMZ_TRIGGER_FILE" 2> /dev/null
		print "Issuing remote start of patch scripts...."
		ssh $DMZ_HOSTNAME "/usr/local/scripts/jpatch.ksh" 2> /dev/null

		## EXIT Script HERE if run on ktazd216 ##
		exit 0
	fi
fi

### NORMAL RUN ###

check_java_running_process
if [ $? -ne 0 ]; then
	## Cleaning up TEMP file ##
	if [ -f $TEMP_FILE ]; then
		rm -f $TEMP_FILE
	fi
	if [ -f $DMZ_TRIGGER_FILE ] && [ "$DMZ_TRIGGER_FILE" != "" ]; then
        	rm -f $DMZ_TRIGGER_FILE
	fi
	if [ -d $REMOTE_FILESET_PATH_DMZ ] && [ "$REMOTE_FILESET_PATH_DMZ" != "" ]; then
        rm -rf $REMOTE_FILESET_PATH_DMZ
	fi

	exit 1
fi

## Search for java type with known strings ##
	search_installed_java_type

## Loop thru all arrays ## 

until [ $s -gt $j ]
do
	#print "${java_name_found_array[${s}]}"
	#print "${java_ver_found_array[${s}]}"
	#print "${java_stat_found_array[${s}]}"
	#print "${java_path_array[${s}]}"
	#print "${java_build_ver[${s}]}"


	## Applying patch base on version supported version ##

	case ${java_name_found_array[${s}]} in
	$JAVA_131_32)
		JAVA_131_32VER="1.3.1.20"
		JAVA_SECURITY_LIB_PATH=/usr/java131/jre/lib/security

		if [ "${java_ver_found_array[${s}]}" != "$JAVA_131_32VER" ]; then
			## PKG_PATH_LOCAL = 1 when trigger file is found on the remote host ##
			## PKG_PATH_LOCAL ne 1 means the script is running on the local host where script was initiated. ##

			if [ $PKG_PATH_LOCAL -ne 1 ]; then
				## PKG_FOLDER is NFS FS location on the remote host ##
				PKG_FOLDER=/misc/java/java131_32bit_SR10
			else
				PKG_FOLDER=$REMOTE_FILESET_PATH_DMZ
			fi
				commit_fileset_decision $s
				apply_java_patch $PKG_FOLDER ${java_name_found_array[${s}]} $JAVA_SECURITY_LIB_PATH
		else
			print "" >> $LOG
			print "$(date) ${java_name_found_array[${s}]} already supported version" |tee -a $LOG
		fi
	;;
	$JAVA_131_64)
                JAVA_131_64VER="1.3.1.12"
		JAVA_SECURITY_LIB_PATH=/usr/java13_64/jre/lib/security

                if [ "${java_ver_found_array[${s}]}" != "$JAVA_131_64VER" ]; then
        		if [ $PKG_PATH_LOCAL -ne 1 ]; then  
	              		PKG_FOLDER=/misc/java/java131_64bit_SR10
			else
				PKG_FOLDER=$REMOTE_FILESET_PATH_DMZ
			fi
               			commit_fileset_decision $s 
		        	apply_java_patch $PKG_FOLDER ${java_name_found_array[${s}]} $JAVA_SECURITY_LIB_PATH
                else
			print "" >> $LOG
                        print "$(date) ${java_name_found_array[${s}]} already supported version" |tee -a $LOG
                fi
	;;
	$JAVA_14_32)
		## Check for version 1.4.2.x ##
		VER142_CK=$(echo ${java_ver_found_array[${s}]} |grep 1.4.2)
		if [ "${java_ver_found_array[${s}]}" = "$VER142_CK" ];then
			JAVA_142_32VER="1.4.2.75"
		        JAVA_SECURITY_LIB_PATH=/usr/java14/jre/lib/security

			if [ "${java_ver_found_array[${s}]}" != "$JAVA_142_32VER" ]; then
				if [ $PKG_PATH_LOCAL -ne 1 ]; then
					PKG_FOLDER=/misc/java/java142_32bit_SR5
				else
					PKG_FOLDER=$REMOTE_FILESET_PATH_DMZ
				fi
					commit_fileset_decision $s
					apply_java_patch $PKG_FOLDER ${java_name_found_array[${s}]} $JAVA_SECURITY_LIB_PATH
			else
				print "" >> $LOG
				print "$(date) ${java_name_found_array[${s}]} already supported version" |tee -a $LOG
			fi
		else
			print "" >> $LOG
			print "$(date) Found non-supported version ${java_ver_found_array[${s}]}" |tee -a $LOG
		fi
	;;
	$JAVA_14_64)
		VER142_CK=$(echo ${java_ver_found_array[${s}]} |grep 1.4.2)
		if [ "${java_ver_found_array[${s}]}" = "$VER142_CK" ];then
			JAVA_142_64VER="1.4.2.75"
		        JAVA_SECURITY_LIB_PATH=/usr/java14_64/jre/lib/security

			if [ "${java_ver_found_array[${s}]}" != "$JAVA_142_64VER" ]; then
				if [ $PKG_PATH_LOCAL -ne 1 ]; then
					PKG_FOLDER=/misc/java/java142_64bit_SR5
				else
					PKG_FOLDER=$REMOTE_FILESET_PATH_DMZ
				fi
					commit_fileset_decision $s
			        	apply_java_patch $PKG_FOLDER ${java_name_found_array[${s}]} $JAVA_SECURITY_LIB_PATH
                        else
				print "" >> $LOG
                                print "$(date) ${java_name_found_array[${s}]} already supported version" |tee -a $LOG
                        fi
		else
			print "" >> $LOG
			print "$(date) Found non-supported version ${java_ver_found_array[${s}]}" |tee -a $LOG
		fi
	;;
	$JAVA_5_32)
		JAVA_5_32VER="5.0.0.76"
		JAVA_SECURITY_LIB_PATH=/usr/java5/jre/lib/security
		if [ "${java_ver_found_array[${s}]}" != "$JAVA_5_32VER" ]; then
			if [ $PKG_PATH_LOCAL -ne 1 ]; then
				PKG_FOLDER=/misc/java/java5_32bit_SR3
			else
				PKG_FOLDER=$REMOTE_FILESET_PATH_DMZ	
			fi
				commit_fileset_decision $s
				apply_java_patch $PKG_FOLDER ${java_name_found_array[${s}]} $JAVA_SECURITY_LIB_PATH
			
		else
			print "$(date) ${java_name_found_array[${s}]} already supported version" |tee -a $LOG
		fi
	;;
	$JAVA_5_64)
		JAVA_5_64VER="5.0.0.75"
		JAVA_SECURITY_LIB_PATH=/usr/java5_64/jre/lib/security
		if [ "${java_ver_found_array[${s}]}" != "$JAVA_5_64VER" ]; then
			if [ $PKG_PATH_LOCAL -ne 1 ]; then
				PKG_FOLDER=/misc/java/java5_64bit_SR3
			else
				PKG_FOLDER=$REMOTE_FILESET_PATH_DMZ
			fi
				commit_fileset_decision $s
				apply_java_patch $PKG_FOLDER ${java_name_found_array[${s}]} $JAVA_SECURITY_LIB_PATH 
		else
			print "$(date) ${java_name_found_array[${s}]} already supported version" |tee -a $LOG
		fi
	;;
	*)
		print "$(date) Found non-supported version ${java_ver_found_array[${s}]}" |tee -a $LOG
	;;
	esac			
	

	(( s=s + 1 ))
done
rm -f $TEMP_FILE
if [ -f $DMZ_TRIGGER_FILE ] && [ "$DMZ_TRIGGER_FILE" != "" ]; then
	rm -f $DMZ_TRIGGER_FILE
fi
if [ -d $REMOTE_FILESET_PATH_DMZ ] && [ "$REMOTE_FILESET_PATH_DMZ" != "" ]; then
	rm -rf $REMOTE_FILESET_PATH_DMZ
fi


#check
instfix -ik "IY85293 IY85294 IY84053 IY87795" |tee -a $LOG
if [[ -d /usr/java5/jre/bin ]] ; then
        cd /usr/java5/jre/bin
        ./java -fullversion |tee -a $LOG
fi
if [[ -d /usr/java5_64/jre/bin ]] ; then
        cd /usr/java5_64/jre/bin
        ./java -fullversion |tee -a $LOG
fi
 
