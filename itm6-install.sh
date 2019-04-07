#!/bin/ksh
########################################################################
#	$Id: itm6-install.sh,v 1.31 2008/03/31 16:19:50 m408925 Exp $
########################################################################
#	$Log: itm6-install.sh,v $
#	Revision 1.31  2008/03/31 16:19:50  m408925
#	fp4if9 installation media was removed, as fp5if4 supersedes it.
#
#	Revision 1.30  2008/01/24 02:24:10  m408925
#	changed the mount cmd from hard to soft
#
#	Revision 1.29  2007/12/26 19:23:54  m408925
#	Added 64 bit provisional patch - IY99106
#
#	Revision 1.28  2007/11/14 05:48:48  m408925
#	integrated fp5 provisional patch
#
#	Revision 1.27  2007/10/17 21:18:44  m408925
#	Added FP5IF4 installation
#
#	Revision 1.26  2007/10/08 22:35:49  m408925
#	Added DMZ support...
#
#	Revision 1.25  2007/02/23 23:57:31  m408925
#	Updates for itm-config support
#
#	Revision 1.24  2007/02/23 22:34:08  m408925
#	Added itm-config file support to manually assign primary and secondary remote tems
#
#	Revision 1.23  2007/02/23 17:06:24  m408925
#	Attempt to resolve fqdn (via ping).  If not, then use ip address.  Also check the length of fqdn
#
#	Revision 1.22  2007/02/21 17:26:38  m408925
#	Changed logic for custom ini variables to be used for all systems (not just linux)
#
#	Revision 1.21  2007/02/21 17:09:45  m408925
#	Corrected elif statement again (missing then)...
#
#	Revision 1.20  2007/02/21 17:03:38  m408925
#	Corrected elif statement (was elsif)...
#
#	Revision 1.19  2007/02/21 16:32:24  m408925
#	Added logic for domain / ip for special ini entries for linux
#
#	Revision 1.18  2007/02/20 16:26:21  m408925
#	Added KDCB0_HOSTNAME for linux, new host variable, Readded KDEB_INTERFACELIST config for linux, misc. clean-up
#
########################################################################
#
# Date : 01/08/2007
#
# Author : Darin Gowan
#
# Description: ITM6 installation for unix (aix, solaris, linux)
#
# Supporting Documentation:
# 
######################################################################## 
# itm6-install

#####
function ErrMsg {
#####
  echo
  echo "$script requires ONE option: [ -d <dmz_gw_ip> | -n | -p | -t | -z <env>]"
  echo "-d = specify the IP address of the ITM6 DMZ gateway"
  echo "-n = Non production server"
  echo "-p = Production server"
  echo "-t = Tivoli infrastructure server"
  echo "-z = Manually select ITM environment (special cases only)"
  echo
  exit 1
}
#####
  
umask 113
script=`basename $0`
name=`echo $script | cut -f1 -d"."`
CANDLEHOME="/usr/Tivoli/ITM"
mnt="/mntZitm6"
silentpath="$mnt/itm/v61/silent"
log="/tmp/$name.log"
dfcmd="df -k"
configpath="$CANDLEHOME/config"
host=`uname -n`
cleanmnt="no"
dom=""
ip=""
ctr=0

if (( $# < 1 ))
then
  # no options/arguments specified
  ErrMsg
elif (( $# > 1 )) 
then
  # only one option can be specified at a time
  # check for -d and -z options (each requires an argument)
  if (( `echo $*|grep -c "z"` == 0 && `echo $*|grep -c "d"` == 0 ))
  then
    echo "Too many options specified..."
    echo "$*"
    ErrMsg
  fi
fi

while getopts :d:nptz: ans
do
  case $ans in

    d) # DMZ server
	itmenv="dmz"
        dmztems=$OPTARG
        
	echo "ITM env=$itmenv\tdmztems=$dmztems" | tee -a $log
	;;

    n) # Non prod server
	itmenv=2
	echo "ITM env=$itmenv" | tee -a $log
	;;

    p) # Prod server
	itmenv=3
	echo "ITM env=$itmenv" | tee -a $log
	;;

    t) # Tivoli server
	itmenv=5
	echo "ITM env=$itmenv" | tee -a $log
	;;

    z) # Manual ITM env selection
	if [[ $OPTARG != [1-6] ]]
	then
	  echo "Invalid value for -z option, $OPTARG"
	  exit 1
	else 
	  itmenv=$OPTARG
	fi
	echo "ITM env=$itmenv" | tee -a $log
	;;

    :) # no option specified
	echo "-$OPTARG requires an argument..."
	ErrMsg
	;;

    \?) # invalid option specified
	echo "Invalid option \"$OPTARG\" specified..."
	ErrMsg
	;;
  esac
done

echo
echo "log=$log"
echo

echo "`date`  $script beginning on $host...\n" | tee $log

OS=`uname`
case $OS in
AIX) osname="aix"
  patchosname="AIX"
  osgen="unix"
  agentlist="ux ul um"
  pingcmd="ping -c1"
  ID=`whoami|awk '{print $1}'`

  instpath="$mnt/itm/v61/product/base_FP1/agent_install/$osname"
  fp4path="$mnt/itm/v61/patches/FP4IF9/${patchosname}"
  fp5path="$mnt/itm/v61/patches/FP5IF4/${patchosname}"
  IY99106="$mnt/itm/v61/patches/IY99106"
  ;;

SunOS) osname="solaris"
  patchosname="solaris"
  osgen="unix"
  agentlist="ux ul um"
  pingcmd="/usr/sbin/ping"
  ID=`who am i|awk '{print $1}'`
  if [[ $ID = '' ]]
  then
    ID=`/usr/ucb/whoami`
  fi

  instpath="$mnt/itm/v61/product/base_FP1/agent_install/$osname"
  fp4path="$mnt/itm/v61/patches/FP4IF9/${patchosname}"
  fp5path="$mnt/itm/v61/patches/FP5IF4/${patchosname}"
  ;;

Linux) osmach=`uname -m`
  if [[ ${dmztems}x != "x" ]]
  then
    echo "" | tee -a $log
    echo "DMZ for linux not supported at this time.  Please contact your Systems Management support team." | tee -a $log
    echo "" | tee -a $log
    echo "Exiting..." | tee -a $log
    exit 99
  fi
  osgen="linux"
  dfcmd="df -kP"
  agentlist="lz ul um"
  pingcmd="ping -c1"
  ID=`whoami|awk '{print $1}'`
  if (( `echo $osmach|grep -ci i.86` == 1 ))
  then
    osname="iLinux"
    patchosname="iLinux32"
    fp4path="$mnt/itm/v61/patches/FP4IF9/${patchosname}/cd1"
    fp5path="$mnt/itm/v61/patches/FP5IF4/${patchosname}/disk1"
  elif (( `echo $osmach|grep -ci x86_64` == 1 ))
  then
    osname="iLinux"
    patchosname="iLinux64"
    fp4path="$mnt/itm/v61/patches/FP4IF9/${patchosname}"
    fp5path="$mnt/itm/v61/patches/FP5IF4/${patchosname}"
  elif (( `echo $osmach|grep -ci s390` == 1 ))
  then
    osname="zLinux"
    patchosname="zLinux"
    fp4path="$mnt/itm/v61/patches/FP4IF9/${patchosname}"
    fp5path="$mnt/itm/v61/patches/FP5IF4/${patchosname}"
  else
    echo 
    echo "Unknown Linux machine type ($osmach), exiting..." | tee -a $log
    echo 
    exit 1
  fi

  # common linux installation path
  instpath="$mnt/itm/v61/product/base_FP1/$osname"
  ;;

*) echo "\nUnknown Operating System: $OS\n"
   exit 1
  ;;
esac

# debugging
echo "Debug info:" >> $log
env >> $log
echo  >> $log

if [[ $ID != 'root' && $ID != '' ]]
then 
  echo "\n$script requires to be run as root (not as $ID).\n" | tee -a $log
  exit 1
fi

# check if dmz and validate 
if [[ ${dmztems}x != "x" ]]
then
  $pingcmd $dmztems >/dev/null 2>&1
  dmzrc=$?
  if (( $dmzrc == 0 )) 
  then
    echo "DMZ gateway $dmztems validated, continuing..." | tee -a $log
  else
    echo "DMZ gateway $dmztems unreachable, exiting..." | tee -a $log
    exit 99
  fi
fi

# determine install fs - target = /usr/Tivoli
fsutil=`$dfcmd |grep /usr/Tivoli$`
if [[ $fsutil = '' ]]
then
  # no /usr/Tivoli fs, check /usr
  echo "/usr/Tivoli filesystem not found, checking /usr..." | tee -a $log
  fsutil=`$dfcmd |grep /usr$`
  if [[ $fsutil = '' ]]
  then
    # no /usr fs, check /
    echo "/usr filesystem not found, checking /..." | tee -a $log
    fsutil=`$dfcmd |grep /$`
  fi
fi

if [[ $OS = "AIX" ]]
then
  fsavail=`echo $fsutil|awk '{print $3}'`
else
  fsavail=`echo $fsutil|awk '{print $4}'`
fi

if (( $fsavail < 300000 ))
then
  # less than 300MB
  echo
  echo "$fsutil" | tee -a $log
  echo
  echo "Available free space less than 300MB, exiting..." | tee -a $log
  echo
  exit 1
fi

echo "OS=$OS" | tee -a $log
echo "osname=$osname" | tee -a $log
echo "host=$host" | tee -a $log
echo "instpath=$instpath" | tee -a $log
echo "fp4path=$fp4path" | tee -a $log
echo "fp5path=$fp5path" | tee -a $log
echo "fsutil=$fsutil" | tee -a $log
echo "fsavail=$fsavail" | tee -a $log

# attempt to get domain
if (( `grep -c domain /etc/resolv.conf` == 1 ))
then
  dom=`grep domain /etc/resolv.conf|awk '{print $2}'`

# check for more than one domain entry
elif (( `grep -c domain /etc/resolv.conf` > 1 ))
then
  # more than one domain statement, take the last one...
  grep domain /etc/resolv.conf|awk '{print $2}'|while read domz
  do
    dom=$domz
  done
fi

# is fqdn resolvable?
if [ $dom ]
then
  $pingcmd $host.$dom > /dev/null 2>&1
  pingrc=$?

  if (( $pingrc != 0 ))
  then
    # fqdn not resolvable, use ip addr instead...
    dom=""
  fi
fi

if [ $dom ]
then
  # domain found and resolvable, use it
  echo "fqdn=$host.$dom" | tee -a $log
else
  # no domain entries, attempt to get ip from /etc/hosts
  if (( `grep $host /etc/hosts | grep -v 127|wc -l` == 1 ))
  then
    ip=`grep $host /etc/hosts | grep -v 127 | awk '{print $1}'`
  
  # check for more than one non loopback ip
  elif (( `grep $host /etc/hosts | grep -v 127|wc -l` > 1 ))
  then
    # more than one host entry, look for fqdn
    if (( `grep $host /etc/hosts | grep -c kp.org` == 1 ))
    then
      # found fqdn, grab the ip
      ip=`grep $host /etc/hosts | grep kp.org | awk '{print $1}'`
  
    # check for multiple fqdn entries
    elif (( `grep $host /etc/hosts | grep -c kp.org` > 1 ))
    then
      # more than one fqdn host entry, take the last one
      grep $host /etc/hosts | grep kp.org | awk '{print $1}' | while read ipz
      do
        ip=$ipz
      done
    fi
  fi
fi

if [ $dom ]
then
  echo "dom=$dom" | tee -a $log
fi

if [ $ip ]
then
  echo "ip=$ip" | tee -a $log
fi

# prepare mount point
if [ ! -d $mnt ]
then
  echo "Creating mount point $mnt" | tee -a $log
  cleanmnt="yes"
  mkdir $mnt 2>&1 | tee -a $log
  mntrc=$?
  if (( $mntrc == 0 ))
  then
    echo "Mount point created successfully" | tee -a $log
  else
    echo "Mount point creation failed: $mntrc" | tee -a $log
    exit $mntrc
  fi
fi

echo "Mounting ITM6 install fs..." | tee -a $log
if [[ ${dmztems}x != "x" ]]
then
  mount -o ro,bg,soft,intr,proto=tcp,retry=100 $dmztems:/usr/Tivoli/media $mnt 2>&1 | tee -a $log
  mntrc=$?
else
  mount -o ro,bg,soft,intr,proto=tcp,retry=100 ktazp2989.crdc.kp.org:/usr/Tivoli/media $mnt 2>&1 | tee -a $log
  mntrc=$?
fi

if (( $mntrc == 0 ))
then
  echo "Mount for ITM6 install fs successful..." | tee -a $log
else
  echo "Mount for ITM6 install fs failed, exiting..." | tee -a $log
  exit 1
fi

# Unix itm6 base FP1 agent installation (silent)
echo | tee -a $log
echo "Installing ITM6 agents..." | tee -a $log
$instpath/install.sh -q -h $CANDLEHOME -p $silentpath/silent_install_${osgen} 2>&1 | tee -a $log

# fp4if9 installation media was removed, as fp5if4 supersedes it.
# Install FP4IF9 patch
#echo | tee -a $log
#echo "Patching ITM6 agents with FP4IF9..." | tee -a $log
#$fp4path/install.sh -q -h $CANDLEHOME -p $silentpath/silent_install_${osgen} 2>&1 | tee -a $log

# Install FP5IF4 patch
echo | tee -a $log
echo "Patching ITM6 agents with FP5IF4..." | tee -a $log
$fp5path/install.sh -q -h $CANDLEHOME -p $silentpath/silent_install_${osgen} 2>&1 | tee -a $log

if [[ $OS = 'AIX' ]]
then
  sleep 5
  # need to apply the fp5 provisional patch
  echo "Patching ITM6 agents with IY99106 32 bit (fp5 provisional patch)..." | tee -a $log
  cd $CANDLEHOME
  cp $IY99106/patch-IY99106.aix51-aix513.tar $CANDLEHOME >> $log 2>&1
  tar -xvf patch-IY99106.aix51-aix513.tar >> $log 2>&1
  ksh IY99106.aix51-aix513.sh install >> $log 2>&1

  echo "Patching ITM6 agents with IY99106 64 bit (fp5 provisional patch)..." | tee -a $log
  cp $IY99106/patch-IY99106.aix51x6-aix516.tar $CANDLEHOME >> $log 2>&1
  tar -xvf patch-IY99106.aix51x6-aix516.tar >> $log 2>&1
  ksh IY99106.aix51x6-aix516.sh install >> $log 2>&1
  sleep 5
fi

# Napa specific config
if (( `echo $host|grep -c "^nz"` > 0 ))
then
  # Napa server, use special config file
  config_file="itm_env_${itmenv}_template_napa.cfg"
else
  config_file="itm_env_${itmenv}_template.cfg"
fi

# prep the config files from itm-config
echo | tee -a $log
echo "Config prep starting..." | tee -a $log
cp $silentpath/$config_file $configpath/silent.cfg

if [[ ${dmztems}x != "x" ]]
then
  # dmz config
  echo "HOSTNAME=$dmztems" >> $configpath/silent.cfg
else
  if (( `grep -c -w $host ${silentpath}/itm-config` > 0 ))
  then
    # host found, get the config
    grep -w $host ${silentpath}/itm-config | while read host2 pri sec junk
    do
      echo "$host2\t$pri\t$sec" | tee -a $log
      export primary=$pri
      export secondary=$sec
    done
  else
    # host not found, use default config
    grep -w default-${itmenv} ${silentpath}/itm-config | while read host2 pri sec junk
    do
      echo "host2=$host2\tpri=$pri\tsec=$sec" | tee -a $log
      export primary=$pri
      export secondary=$sec
    done
  fi

  echo "HOSTNAME=$primary" >> $configpath/silent.cfg
  echo "MIRROR=$secondary" >> $configpath/silent.cfg
fi

# Unix itm6 agent configuration (silent)
echo | tee -a $log
echo "Configuring ITM6 agents..." | tee -a $log
for agent in $agentlist
do
  echo $agent | tee -a $log
  # update ini files
  if [[ $osgen = 'linux' ]]
  then
    # special entry for linux
    echo "KDCB0_HOSTNAME=$host" >> ${configpath}/${agent}.ini
  fi
  
  # customized ini variables for all systems
  if [ $dom ]
  then
    echo "KDEB_INTERFACELIST=!${host}.${dom}" >> ${configpath}/${agent}.ini

    # check the length of fqdn (can't be > 28 bytes)
    if (( `echo $host.$dom|wc -c` > 28 ))
    then
      echo "CITRA_HOSTNAME=$host" >> ${configpath}/${agent}.ini
    fi
  elif [ $ip ]
  then
    echo "KDEB_INTERFACELIST=$ip" >> ${configpath}/${agent}.ini
  else
    echo 'KDEB_INTERFACELIST=!*' >> ${configpath}/${agent}.ini
  fi


  # config agents
  $CANDLEHOME/bin/itmcmd config -A -p $configpath/silent.cfg $agent 2>&1 | tee -a $log
done


# Start unix itm6 agents
echo | tee -a $log
$CANDLEHOME/bin/itmcmd agent start $agentlist 2>&1 | tee -a $log

# unmount
umount $mnt 2>&1 | tee -a $log

if [[ $cleanmnt = 'yes' ]]
then
  # delete mount point
  echo | tee -a $log 
  echo "Cleaning up mount point $mnt..." | tee -a $log
  rmdir $mnt 2>&1 | tee -a $log
  if (( $? == 0 ))
  then
    echo "directory $mnt removed..." | tee -a $log
  else
    echo "directory $mnt removal failed..." | tee -a $log
  fi
fi
 
# list the running ITM6 agents
echo | tee -a $log
$CANDLEHOME/bin/cinfo -r 2>&1 | tee -a $log

echo | tee -a $log
echo "`date`  $script complete on $host" | tee -a $log
