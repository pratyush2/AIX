#!/bin/ksh
#
#set -x
# ----------------------------------------------------------------------
# 2002-10-15 GL 1.0  Initial release
# 2003-02-24 GL 2.2e xxx
# 2003-05-09 GL 2.5a xxx
# 2005-05-13 AW 2.6  some improvements/bugfixes
# 2005-09-30 GL 2.6c xxx
# 2005-10-01 CP 2.5b <private release>
# 2005-10-07 AW 2.7  new release number, HP OpenView support
# ----------------------------------------------------------------------
# ---

RCCS="@(#)Cfg2Html -IBM- Version 2.7beta01_005"          # useful for what (1)
VERSION=$(echo $RCCS | cut -c5-)

echo "Starting up $VERSION\r"

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# RR Ralph Roth Ralph_Roth@hp.com
# GL Gert Leerdam Gert.Leerdam@getronics.com
# AW Andreas Wizemann Andreas.Wizemann@FVVaG.de
# CP Chris Paulheim (HP OpenView support)
#
# 2.6 2005-05-13 A.Wizemann
#  - some bugs fixed
#  - internal improvements
#  - new: AIX 5.3 support
#  - new: ported some options from LINUX or HP version
#
# New
# --------
# §CP001§ HP OpenView support (copied from 2.5b)
#
# BUGFIXES
# --------
# §GL001§ AIX 5.3 correction in psawk
# §GL002§ additions from 2.5c
#
# changes and general improvements
# --------------------------------
# §AW001§ Translate German comments to english
# §AW002§ Translate Dutch comments to english
# §AW003§ add some more comments
# §AW004§ always use option -f and 2>/dev/null on rm command
# §AW005§ changed var RECHNER to NODE / ANTPROS to NO_OF_CPUS
# §AW006§ code to identify CPU Type moved to function and improved
# §AW007§ add more debuging capabilities
# §AW008§ code restructured for better readability
# §AW009§ changed tabs to spaces for better readability in some editors
# §AW010§ changed internel name device_info to disk_info to fit with option name (CFG_DISKS)
# §AW011§ changed internel name patch/software_info to software_info to fit with option name (CFG_SOFTWARE)
# §AW012§ add CFG_APPL (APPLICATIONS e.g SAMBA) (as in linux version)
# §AW013§ display warning if using AIX 4.x as this has reached end of service
# §AW014§ AIX 5.3 use sysdump -Lv older releases -L
# §AW015§ small corrections in HTML header to show correct oslevel
# §AW016§ moved <META http-equiv=expires... to open_html, so it is only found once in the html file
# §AW017§ TRAP handling
# §AW018§ xexit - single exit point
# §AW019§ add support for "sysinfo" file. Idea "stolen" from linux port
# §AW020§ -o OUTDIR support (as in HP Version 2.92)
# §AW021§ C2H_CMDLINE (same as CFG_CMDLINE in HP Version 2.92)
# §AW022§ C2H_DATE    (same as CFG_DATE in HP Version 2.92)
# §AW023§ get info about package to install if cmd not found
# §AW024§ check for command availability using "which <cmd>" before using them
# §AW025§ add /etc/security/limits to files
# §AW026§ add (internal) css style (as in LINUX 1.20)
# §AW027§ add ALT= option to IMG tag
# §AW028§ repquota (10) moved to "Filesystem" collector
# §AW029§ passwd (13) moved to "User & Group" collector
# §AW030§ defrag (11) moved to "Filesystem" collector
# §AW031§ screen tips inline (same as CFG_STILINE in HP Version 2.92)
# §AW032§ AIX 4.2 and lower desupported
# §AW033§ small optical changes in output files
# §AW000§ ...34
#
# Under Construction
# ------------------
# §AW104§ add "PLUGIN" support
# §AW105§ check that we are running only once
#
# §AW201§ check for "vmtune" 5.2 knows vmtune IF UPGRADED from earlier release 5.3 uses vmo,ioo,schedo
# §AW202§ skip "ps -Af..." on all aix (5.3)
# §AW203§ skip "ipcs" on AIX 5.3 (aixn,...)
#
# NEW (EXPERIMENTAL)
# ---
# §AW050§ suma (AIX 5.1+5.2 with PTF or AIX 5.3 and higer;)
# §AW051§ *emgr,epkg (AIX 4.3.3 + IY41248; AIX 5.1 + IY40088; AIX 5.2 + IY40236 or AIX 5.3 and higher)
# §AW052§ *java -version
# §AW053§ *WLM* Work Load Manager (AIX 5.x)
# §AW054§ smtctl (AIX 5.3 on Power5)
# §AW055§ cpupstat (AIX 5.3)
# §AW056§ mpstat -s (AIX 5.3)
# §AW057§ lparstat (AIX 5.3)
# §AW058§ lsslot
# §AW059§ aio, ASYNC I/O
# §AW060§ *SDD/SDDPCM* Subsystem Device Driver (ESS, DS8000), CIM-Agent
# §AW061§ *IBM HTTP Server (Apache)
# §AW062§ *SAMBA
#
# BUGFIXES
# --------
# §AW301§ BUG: var DB_F in PrtLayout not set
# §AW302§ BUG: do not use fix "proc0" ! as we may run on a different proc
# §AW303§ BUG: sed will convert also for *.TXT output file, which is not necessary
# §AW303§ BUG: found in: cron,lsrset,ps,ifconfig,netstat
# §AW304§ BUG: change uname -n to $(uname -n)
# §AW305§ BUG: do not display "<file> file not found" in *.err file !
# §AW306§ BUG: ignore newly created devices which do not have a PVID (PVID is none)
# §AW307§ BUG: check for "/var/ifor/i4cfg" Don't use if not available !
# §AW308§ BUG: lower "f" missing in getopts list
# §AW309§ BUG: if execution fails or scrpt is interrupted output is missing !
# §AW310§ BUG: out of memory error (first seen on AIX 5.3)
#
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#*********************************************************************
# TODO: alstat  emstat  gennames  locktrace  truss  wimmon alog?
# TODO: errpt -a bij -x
# ToDo: needs improvement!
# trap "echo Signal: Aborting!; rm $HTML_OUTFILE_TEMP"  2 13 15
#*********************************************************************

#----------------------------------------------------------------------------
# Thanks to Olaf Morgenstern (olaf.morgenstern@web.de) for several improvements
# Thanks to Jim Lane (JLane@torontohydro.com) for lsuser & lsgroup command
# "Stolen" Command-line option structure with getopts from HP-UX version from Ralph Roth
# Thanks to colleague Marco Stork for supplying the PrtLayout function
#----------------------------------------------------------------------------

######################################################################
# usage: show the options for this script
# Collectors use CAPITAL letters to enable/disable.
######################################################################
usage ()
{
   echo "\n usage: cfg2html_aix.sh [options]"
   echo "\ncreates HTML and plain ASCII host documentation"
   echo
   echo "  -o  set directory to write (or use the environment variable)"
   echo "                OUTDIR=\"/path/to/dir\" (directory must exist)"
  #echo "  -l  DIS-able: Screen tips inline"  # §AW031§
  #         ToDo. -g like LINUX port
  #         x in use with eXtended. use g (gif)
  #echo "  -g  don't create background images (gif)"
   echo "  -0 (null)     append the current date+time to the output files (D-M-Y-hhmm)"  # §AW022§
   echo "  -1 (one)      append the current date to the output files (Day-Month-Year)"   # §AW022§
  #echo "  -2 modifier   like option -1, you can use date +modifer, e.g. -2%d%m"         # §AW022§
  #echo "                DO NOT use spaces for the filename, e.g. -2%c"                  # §AW022§
   echo "  -h  display this help and exit"
   echo "  -v  output version information and exit"
   echo "  -x  eXtended output"
   echo "  -y  Verbose (Debug) output"
   echo
   echo "use the following (case-sensitive) options to (enable/)disable collectors"
   echo
   echo "  -^  Reverse Yes/No; MUST be first option"
   echo "  -a  DIS-able: Applications (e.g. SAMBA)" #*col-18*
   echo "  -C  DIS-able: Cron"           # *col-12*
   echo "  -d  DIS-able: Defragfs"       # *col-11* §AW030§ => to be DELETED
   echo "  -D  DIS-able: Disks"          # *col-05*
   echo "  -e  DIS-able: Enhancements"   # *col-19*
   echo "  -E  DIS-able: Experimental"   # *col-20*
   echo "  -f  DIS-able: Files"          # *col-15*
   echo "  -F  DIS-able: Filesystem"     # *col-04*
   echo "  -H  DIS-able: Hardware"       # *col-03*
   echo "  -K  DIS-able: Kernel"         # *col-02*
   echo "  -l  DIS-able: LUM"            # *col-17*
   echo "  -L  DIS-able: LVM"            # *col-06*
   echo "  -n  DIS-able: NIM"            # *col-16*
   echo "  -N  DIS-able: Network"        # *col-08*
   echo "  -p  DIS-able: Password"       # *col-13* §AW029§ => to be DELETED
   echo "  -P  DIS-able: Printer"        # *col-09*
   echo "  -O  DIS-able: HP OpenView"    # *col-21* §CP001§
   echo "  -Q  DIS-able: Quota"          # *col-10* §AW028§ => to be DELETED
   echo "  -s  DIS-able: Software"       # *col-14*
   echo "  -S  DIS-able: System"         # *col-01*
   echo "  -U  DIS-able: Users"          # *col-07*

   echo
 # echo  "\n(#) these collectors create a lot of information!"
   echo  "Example:  $0 -C   to skip CRON"
   echo  "          $0 -^C  to do -ONLY- CRON"
   echo
}

######################################################################
# InitVars: initialize some basic variables
######################################################################
InitVars ()
{
#----------------------------------------------------------------------------
# use "yes/no" to enable/disable a collection; CASE sensitive !!
 CFG_SYSTEM=yes          # S  *col-01*
 CFG_KERNEL=yes          # K  *col-02* ! Trouble on 5.3 ! (psawk)
 CFG_HARDWARE=yes        # H  *col-03*
 CFG_HACMP=yes	         # o  *col-22* Kaiser
 CFG_FILESYS=yes         # F  *col-04*
 CFG_DISKS=yes           # D  *col-05* (Device)
 CFG_LVM=yes             # L  *col-06*
 CFG_USERS=yes           # U  *col-07*
 CFG_NETWORK=yes         # N  *col-08*
 CFG_PRINTER=no          # P  *col-09*
 CFG_QUOTA=yes           # Q  *col-10* §AW028§ => to be DELETED
 CFG_DEFRAG=yes          # d  *col-11* §AW030§ => to be DELETED
 CFG_CRON=yes            # C  *col-12*
 CFG_PASSWD=yes          # p  *col-13* §AW029§ => to be DELETED
 CFG_SOFTWARE=yes        # s  *col-14* (Patch)
 CFG_FILES=yes           # f  *col-15* ! Trouble on 5.3 !
 CFG_NIM=yes             # n  *col-16*
 CFG_LUM=yes             # l  *col-17*
 CFG_APPL=yes            # a  *col-18* comming soon
 CFG_ENH=yes             # e  *col-19* comming soon
 CFG_EXP=yes             # E  *col-20*
 CFG_HPO=yes             # O  *col-21* §CP001§
 maxcoll=21

 CFG2HTML=true
 MYNAME=`whence $0`
 C2H_HOME=`dirname $MYNAME`
 PLUGINS=$C2H_HOME

 C2H_DATE="";  # §AW022§
 C2H_STINLINE="YES"  # §AW031§

# Convert illegal characters for HTML into escaped ones.
# Convert '&' first! (Peter Bisset [pbisset@emergency.qld.gov.au])
CONVSTR='
s/&/\&amp;/g
s/</\&lt;/g
s/>/\&gt;/g
s/\\/\&#92;/g
'

# ...
 SEP="================================" # 32
 SEP10="==========" #10
 SEP20="====================" #20
 SEP30=${SEP20}""${SEP10}
 SEP40=${SEP20}""${SEP20}
 SEP60=${SEP40}""${SEP20}
 SEP70=${SEP40}""${SEP20}""${SEP10}
 SEP80=${SEP40}""${SEP40}
 SEP90=${SEP40}""${SEP40}""${SEP10}
 SEP100=${SEP40}""${SEP40}""${SEP20}
 SEP120=${SEP40}""${SEP40}""${SEP40}
#
 DATE=$(date "+%Y-%m-%d")                 # ISO8601 compliant date string
 DATEFULL=$(date "+%Y-%m-%d - %H:%M:%S")  # ISO8601 compliant date and time string
 CURRDATE=$(date +"%b %e %Y")
 NODE=$(uname -n) # §AW005§
 SYSTEM=$(uname -s)
 USER=`id | cut -f2 -d"(" | cut -f1 -d")"`

# Let the (HTML) cache expire since this script runs every night
 EXPIRE_CACHE=$(date "+%a, %d %b %Y ")"23:00 GMT"

# §AW017§ Define signals
 SIGNEXIT=0   ; export SIGNEXIT  # normal exit
 SIGHUP=1     ; export SIGHUP    # when session disconnected
 SIGINT=2     ; export SIGINT    # ctrl-c
 SIGTERM=15   ; export SIGTERM   # kill command
 SIGSTP=18    ; export SIGSTP    # ctrl-z
#SIG...=13    ; export SIG...    # ...

# get no of installed CPU's
 NO_OF_CPUS=$(lscfg | grep 'proc[0-9]' | awk 'END {print NR}')

}

######################################################################
# Init_Part2: called AFTER options are processed
######################################################################
Init_Part2 ()
{
 AWTRACE "AW SET"
  set | grep -e CFG_ -e OUTDIR_ENV
 AWTRACE "AW SET"
 if [ "$OUTDIR" = "" ] ; then
   OUTDIR="/var/adm/cfg"  # §AW020§
 fi
 AWTRACE "AW000I OUTDIR=${OUTDIR}"
 AWTRACE "AW000I OUTDIR_ENV=${OUTDIR_ENV}"

 BASEFILE=`hostname`$C2H_DATE  # §AW022§
 HTML_OUTFILE=${OUTDIR}/${BASEFILE}.html
 HTML_OUTFILE_TEMP=/tmp/${BASEFILE}.html.$$
 TEXT_OUTFILE=${OUTDIR}/${BASEFILE}.txt
 TEXT_OUTFILE_TEMP=/tmp/${BASEFILE}.txt.$$
 ERROR_LOG=${OUTDIR}/${BASEFILE}.err

 if [ ! -d $OUTDIR ] ; then
  echo "can't create $HTML_OUTFILE, $OUTDIR does not exist"
  xexit 1
 fi

 cmdout=$(touch $HTML_OUTFILE 2>/dev/null)
 touch_rc=$?
 if [[ $touch_rc = 0 ]]
 then
   :  # OK
 else
   banner "Error"
   ERRMSG "C2H000S Cannot create $HTML_OUTFILE RC=${touch_rc}"
   xexit 1
 fi

# clear error_log
 [ -s "$ERROR_LOG" ] && rm -f $ERROR_LOG 2> /dev/null

 AWTRACE "** ${DATEFULL} **"
 AWTRACE "\n${VERSION}"

 Get_CPU_Type  # §AW006§

#----------------------------------------------------------
# IPADRES=$(cut -d"#" -f1 /etc/hosts | awk '{for (i=2; i<=NF; i++) if ("'$HOSTNAME'" == $i) {print $1; exit}}') # n.u.
#----------------------------------------------------------
# SPEED=$(psrinfo -v | awk '/MHz/{print $(NF-1); exit }')    # TODO: lots of work ! (silly IBM ?) ....
#SPEED=XXX     # TODO: ...
#----------------------------------------------------------
# CPU=$(lscfg | grep Architecture | cut -d: -f2)     # n.u.
#----------------------------------------------------------

 OSLEVEL=$(oslevel)      # ver.rel.mod
 OSLEVEL_R=$(oslevel -r) # ver.rel.mod-ml

 AWTRACE "\n: Node: ${NODE} OSLEVEL: ${OSLEVEL_R} **"

 os_vr="$(uname -v)$(uname -r)"

#AWTRACE "\nAW000I OSLEVEL=${OSLEVEL}"
#AWTRACE "\nAW000I os_vr=${os_vr}"
#AWTRACE "\nAW000I os_v=${os_v}"

# oslevel -r => 5300-02
# OSVER6CHAR => 530002
# OSVER3CHAR => 530

 if test oslevel
 then
   OSVER6CHAR=`oslevel -r | sed 's/-//'`
   OSVER3CHAR=`oslevel -r | awk '{print substr($1,1,3)}'`
 else
   OSVER6CHAR="000000"
   OSVER3CHAR="000"
 fi

#AWTRACE "\nAW OSVER3CHAR=${OSVER3CHAR}"
#AWTRACE "\nAW OSVER6CHAR=${OSVER6CHAR}"

# ToDo: bindprocessor -q  (bos.mp)

# set PROC_Type e.g. PowerPC_POWER4
# some commands may be available only on specific hardware
# e.g. smt (Simultaneous Multi-Threading) with AIX 5.3 on POWER5
 procs=$(lscfg | grep proc | awk '{print $2}')
 for proc in $(echo $procs)
 do
   proctype=$(lsattr -El $proc | grep type | awk '{print $2}')
 done
 AWTRACE ": PROC_Type="$proctype
 POWER5="NO"
 if [[ $proctype = "PowerPC_POWER5" ]] ; then
   POWER5="YES"
 fi
 AWTRACE ": POWER5="$POWER5

# set SysModel e.g. IBM,7038-6M2 (p650)
 SysModel=$(prtconf 2>/dev/null | grep "System Model" | awk '{print $3}')
 AWTRACE ": SysModel="$SysModel

# set PROC_Type e.g. PowerPC_POWER4
 proctype2=$(prtconf 2>/dev/null | grep "Processor Type" | awk '{print $3}')
 AWTRACE ": PROC_Type2="$proctype2

# set CPU_Type e.g. 64-bit
 CPU_TYPE=$(prtconf -c | grep "CPU Type" | awk '{print $3}')
 AWTRACE ": CPU_Type="$CPU_TYPE

# set KERNEL_Type e.g. 64-bit
 KERNEL_TYPE=$(prtconf -k | grep "Kernel Type" | awk '{print $3}')
 AWTRACE ": KERNEL_Type="$KERNEL_TYPE
 BIT64="NO"
 if [[ $KERNEL_TYPE = "64-bit" ]] ; then
   BIT64="YES"
 fi
 AWTRACE ": 64BIT="$BIT64

 if [[ "$KERNEL_TYPE" = "$CPU_TYPE" ]]
 then
   :
   #ERRMSG "\nC2H800I OK ! You are running a ${KERNEL_TYPE}-Kernel on a ${CPU_TYPE}-CPU !"
 else
   ERRMSG "\nC2H801W Warning ! You are running a ${KERNEL_TYPE}-Kernel on a ${CPU_TYPE}-CPU !"
 fi

# ToDo: check if dir exist before adding to path
# set Path to be used in this script
 PATH00=$PATH:/local/bin:/local/sbin:/usr/bin:/usr/sbin:/local/gnu/bin:/usr/ccs/bin:
 PATH01=/local/X11/bin:/usr/openwin/bin:/usr/dt/bin:/usr/proc/bin:/usr/ucb:
 PATH02=/local/misc/openv/netbackup/bin
 PATH=${PATH00}""${PATH01}""${PATH03}

}

######################################################################
# xexit: extended exit (e.g. run cleanup)
######################################################################
xexit ()  # §AW018§
{
 if [ -z "$1" ] ; then      # if string 1 is zero/empty (no rc given)
   #ERRMSG "C2H000I no rc at call to xexit. Set to ZERO."
   xrc=0
 else
   xrc=$1
 fi

# write HTML_OUTFILE_TEMP to HTML_OUTFILE !!
 close_html

 cleanup

 DATEFULL=$(date "+%Y-%m-%d - %H:%M:%S")     # ISO8601 compliant date and time string
 echo "Finished at ${DATEFULL}. RC=${xrc}";

 exit $xrc
}

######################################################################
# cleanup: remove some files
######################################################################
cleanup ()
{
 ERRMSG "now performing cleanup..."

# list process
 PROCID=$$
 ps -ef | grep $PROCID
 echo "======"
 ERRMSG ps -ef | grep $PROCID

# list temp files for this process
 ls -la /tmp/*$$
 echo "======"
 ERRMSG ls -la /tmp/*$$

# remove dump
 rm -f core 2>/dev/null  # §AW004§

 # remove the error.log if it has size zero
 [ ! -s "$ERROR_LOG" ] && rm -f $ERROR_LOG 2> /dev/null

}

######################################################################
# line: ...
######################################################################
line ()
{
	echo "\n"
}
######################################################################
# check_basic_req: check for some basic requirements...
######################################################################
check_basic_req ()
{
# echo "\n"
AWCONS "AWTRACE: CBR 000"
  if [ $(id -u) != 0 ] ; then
     banner "Sorry"
     line
     echo "You must run this script as Root\n"
     xexit 1 # §AW018§
  fi

  #os_v=$(uname -v)

AWCONS "AWTRACE: CBR 001"
  if [ "$os_vr" -lt 43 ] ; then  # §AW032§
     banner "Sorry"
     echo "$0: Requires AIX 4.3 or better!\n"
     xexit 1 # §AW018§
  fi

AWCONS "AWTRACE: CBR 002"
  if [ "$os_v" -lt 5 ] ; then
     banner "WARNING"
     echo "$0: Note AIX 4.x is outdated ! Please upgrade to AIX 5.x as soon as possible !\n"
    #xexit 1 # §AW018§
  fi

AWCONS "AWTRACE: CBR 003 "$HTML_OUTFILE
  if [ ! -f $HTML_OUTFILE ]
  then
     banner "Error"
     echo "C2H000S You have not the rights to create ${HTML_OUTFILE}! (NFS?)\n"
     xexit 1 # §AW018§
  fi
AWCONS "AWTRACE: CBR 004"

#++ §AW105§ start *run-once*-------------------------------------------
 PROCID=$$
AWCONS "AWTRACE: CBR 005 "$BASEFILE $PROCID
 ps -ef | grep -v $PROCID | grep -v grep | grep $BASEFILE

AWCONS "AWTRACE: CBR 005a "$BASEFILE $PROCID


#++ §AW105§ end *run-once* --------------------------------------------

#++ §AW104§ start *PLUGIN*---------------------------------------------
#...Check if /plugin dir is there
  PLUGINS=plugins
  if [ ! -d $PLUGINS ]
  then
    echo "C2H010W Warning, the plugin directory is missing or execute bit is not set"
    echo "C2H011I Plugin-Dir = $PLUGINS"
#   xexit 1 # §AW018§
  fi
#++ §AW104§ end *plugin* ----------------------------------------------

#++ §AW310§ start *out of memory*--------------------------------------
# 128K - 131.072
# 256K - 262.144
# 384K - 393.216
# 512K - 524.288
#...Check if ulimit -d is at least 524288
 curr_ulimit_d=$(ulimit -d) # -d => data area
 if [[ $curr_ulimit_d = "unlimited" ]]
 then
   verbose_out "C2H020I ulimit -d is set to 'unlimited'. No action required."
   AWTRACE     "C2H020I ulimit -d is set to 'unlimited'. No action required."
 elif [[ $curr_ulimit_d -lt 524288 ]]
 then
   verbose_out "C2H020I ulimit -d was "$curr_ulimit_d" now set to 524288"
   AWTRACE     "C2H020I ulimit -d was "$curr_ulimit_d" now set to 524288"
   ulimit -d 524288  # set the new ulimit
 else
   verbose_out "C2H020I ulimit -d is set to "$curr_ulimit_d". No action required."
   AWTRACE     "C2H020I ulimit -d is set to "$curr_ulimit_d". No action required."
 fi

 curr_ulimit_c=$(ulimit -c) # -c => core dumps
 AWTRACE "C2H021I ulimit -c is "$curr_ulimit_c
 curr_ulimit_f=$(ulimit -f) # -f => file size
 AWTRACE "C2H021I ulimit -f is "$curr_ulimit_f
 curr_ulimit_m=$(ulimit -m) # -m => memory
 AWTRACE "C2H021I ulimit -m is "$curr_ulimit_m
 curr_ulimit_n=$(ulimit -n) # -n => number of file descriptors
 AWTRACE "C2H021I ulimit -n is "$curr_ulimit_n
 curr_ulimit_s=$(ulimit -s) # -s => stack
 AWTRACE "C2H021I ulimit -s is "$curr_ulimit_s
 curr_ulimit_t=$(ulimit -t) # -t => number of seconds to be used by each proc
 AWTRACE "C2H021I ulimit -t is "$curr_ulimit_t
#++ §AW310§ end *out of memory*----------------------------------------

#++ §AW019§ start *SYSINF*---------------------------------------------
#...Check if file *SYSINF* is there
# SYSINF=c2h_sysinfo.txt
# if [ ! -f $SYSINF ]
# then
#   echo "C2H030W Warning, the sysinfo file '${SYSINF}' is missing. Using internal defaults"
# else
#   cat $SYSINF
# fi
#++ §AW019§ end *SYSINF* ---------------------------------------------

AWCONS "AWTRACE: CBR 999"
}

######################################################################
# DBG: write DEBUG information
######################################################################
DBG ()
{
 if (( $DEBUG == 1 )); then
   DATEFULL=$(date "+%Y-%m-%d - %H:%M:%S")     # ISO8601 compliant date and time string
   # tee -a will "add" the output to a file
   dbgline="${DATEFULL} $*"
  #echo $dbgline | tee -a $ERROR_LOG
   echo $dbgline >> $ERROR_LOG
 fi
}

######################################################################
# AWCONS: write line to console
######################################################################
AWCONS ()
{
  echo "$*"
}

######################################################################
# AWTRACE: write line to error log
######################################################################
AWTRACE ()
{
  DATEFULL=$(date "+%Y-%m-%d - %H:%M:%S")     # ISO8601 compliant date and time string
  echo "${DATEFULL} $*" >> $ERROR_LOG
}

######################################################################
# ERRMSG: write line to error log AND console
######################################################################
ERRMSG ()
{
  echo "$*"
  echo "$*" >> $ERROR_LOG
}

######################################################################
# verbose_out: display text if verbose is on
######################################################################
verbose_out ()
{
  if (( VERBOSE == 1 )) ; then
    echo "$*"
  fi
}

# ... execution starts here ...MOVED
#*********************************************************************
# start of HTML file with heading and titel
#
# Note: there is only ONE HTML and TXT file after the script has
#       finished. This file contains an index and all command output,
#       so this file might be quite large.
#       While this script is running we are writing the index
#       (directory)" entries directly to the main output file.
#       Command output is written to a temp file, which will then
#       be copied to the end of the main output file when the script
#       finishes.
#*********************************************************************

######################################################################
# open_html: ...
######################################################################
open_html ()
{
# §AW015§ show correct oslevel in "GENERATOR"
# §AW015§ show correct version in "DESCRIPTION"
# §AW026§ add (internal) css style (as in LINUX 1.20)
   echo " \
<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2//EN\">
<HTML> <HEAD>
 <META NAME="GENERATOR" CONTENT="Selfmade-$RCCS-vi AIX ${OSLEVEL_R}">
 <META NAME="AUTHOR" CONTENT="Gert.Leerdam@getronics.com,Andreas.Wizemann@FVVaG.de">
 <META NAME="CREATED" CONTENT="\"Gert Leerdam,Andreas Wizemann\"">
 <META NAME="CHANGED" CONTENT="${USER} %A%">
 <META NAME="DESCRIPTION" CONTENT="$Header: ${VERSION} $DATE root Exp $">
 <META NAME="ROBOTS" CONTENT="noindex">
 <META NAME="subject" CONTENT="$VERSION on $NODE by Gert.Leerdam@getronics.com, Andreas.Wizemann@FVVaG.de">

<style type="text/css">
/* (c) 2001-2005 by ROSE SWE, Ralph Roth - http://come.to/rose_swe
 * CSS for cfg2html.sh, 12.04.2001, initial creation
 */

Pre             {Font-Family: Courier-New, Courier;Font-Size: 10pt}
BODY            {FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif; FONT-SIZE: 12pt;}
A               {FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif}
A:link          {text-decoration: none}
A:visited       {text-decoration: none}
A:hover         {text-decoration: underline}
A:active        {color: red; text-decoration: none}

H1              {FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif;FONT-SIZE: 20pt}
H2              {FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif;FONT-SIZE: 14pt}
H3              {FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif;FONT-SIZE: 12pt}
DIV, P, OL, UL, SPAN, TD
                {FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif;FONT-SIZE: 11pt}

</style>

<TITLE>${NODE} - Documentation - $VERSION</TITLE>
</HEAD><BODY>
<BODY LINK="#0000ff" VLINK="#800080" BACKGROUND="cfg2html_back.jpg">
<H1><CENTER><FONT COLOR=blue>
<P><hr><B>$NODE - AIX "${OSLEVEL_R}" - System Documentation</P></H1>
<hr><FONT COLOR=blue><small>Created: - "$DATEFULL" - with: " $VERSION "</font></center></B></small>
<HR><H1>Contents\n</font></H1>\n\
" >$HTML_OUTFILE

# §AW016§ moved <META http-equiv=expires... here, so it is only found once in the html file
 echo "<META http-equiv=\"expires\" content=\"${EXPIRE_CACHE}\">">> $HTML_OUTFILE    # expires...

# AddText "Used command line was=$C2H_CMDLINE"  # §AW021§

 #(line;banner $NODE;line) > $TEXT_OUTFILE
 echo "\n" >> $TEXT_OUTFILE
 echo "\n" > $TEXT_OUTFILE_TEMP
}

######################################################################
# inc_heading_level: increases the heading level
######################################################################
inc_heading_level ()
{
   HEADL=HEADL+1
#  echo "<UL>\n" >> $HTML_OUTFILE
   echo "<UL> <!-- ${HEADL} -->\n" >> $HTML_OUTFILE
}

######################################################################
# dec_heading_level: decreases the heading level
######################################################################
dec_heading_level ()
{
   HEADL=HEADL-1
#  echo "</UL>\n" >> $HTML_OUTFILE
   echo "</UL> <!-- ${HEADL} -->\n" >> $HTML_OUTFILE
}

######################################################################
# paragraph: Creates an own paragraph, $1 = heading
######################################################################
paragraph ()
{
  DBG ":---------------------------------------"
  DBG ": $1 xx"

# ToDo: HTML2   writeTF # §AW309§ BUG: write temp output to final file

   echo "<!--${SEP80}-->" >> $HTML_OUTFILE

   if [ "$HEADL" -eq 1 ] ; then
      echo "\n<HR>\n" >> $HTML_OUTFILE_TEMP
   fi

  #echo "\n<table WIDTH="90%"><tr BGCOLOR="#CCCCCC"><td>\n" >> $HTML_OUTFILE_TEMP
   echo "<A NAME=\"$1\">" >> $HTML_OUTFILE_TEMP
   echo "<A HREF=\"#Content-$1\"><H${HEADL}> $1 </H${HEADL}></A><P>" >> $HTML_OUTFILE_TEMP
  #echo "<A HREF=\"#Content-$1\"><H${HEADL}> $1 </H${HEADL}></A></table><P>" >> $HTML_OUTFILE_TEMP

   if [ "$HEADL" -eq 1 ] ; then
      echo "<!--${SEP80}-->" >> $HTML_OUTFILE
      # §AW027§ add ALT= option to IMG tag
      echo '<IMG ALT="profbull.gif" SRC="profbull.gif" WIDTH=14 HEIGHT=14>' >> $HTML_OUTFILE
   else
      echo "<LI>\c" >> $HTML_OUTFILE
   fi

   echo "<A NAME=\"Content-$1\"></A><A HREF=\"#$1\">$1</A>" >> $HTML_OUTFILE

   if [ "$HEADL" -eq 1 ] ; then
      echo "\nCollecting: $1 .\c"
      if (( VERBOSE == 1 )) ; then
        echo " +++"
      fi
   fi

   #echo "    $1" >> $TEXT_OUTFILE
}

######################################################################
# writeTF: write temp output to final file
######################################################################
writeTF ()
{
# §AW309§ BUG: write temp output to final file
# write temp output to final file, so we don't loose the whole
# information in case script fails.
  cat $HTML_OUTFILE_TEMP >> $HTML_OUTFILE
  cat $TEXT_OUTFILE_TEMP >> $TEXT_OUTFILE
  rm -f $HTML_OUTFILE_TEMP $TEXT_OUTFILE_TEMP 2>/dev/null  # §AW004§
}

######################################################################
# AddText: adds a text to the output files, rar, 25.04.99
######################################################################
AddText ()
{
  echo "<p>$*</p>" >> $HTML_OUTFILE_TEMP
  echo "$*\n"      >> $TEXT_OUTFILE_TEMP
}

######################################################################
# close_html: end of html document
######################################################################
close_html ()
{
  echo "<hr>" >> $HTML_OUTFILE
  echo "</P><P>\n<hr><FONT COLOR=blue>Created "$DATEFULL" with " $VERSION " by
  <A HREF="mailto:Gert.Leerdam@getronics.com?subject=${VERSION}_">Gert Leerdam, SysAdm</A>&nbsp;
  <A HREF="mailto:Andreas.Wizemann@FVVaG.de?subject=${VERSION}_">Andreas Wizemann, SysAdm</A>&nbsp;
  </P></font>" >> $HTML_OUTFILE_TEMP
  echo "</P><P>\n<FONT COLOR=blue>Based on the original script by <A HREF="mailto:Ralph_Roth@hp.com?subject=${VERSION}_">Ralph Roth</A></P></font>" >> $HTML_OUTFILE_TEMP
  echo "<hr><center>\
  <A HREF="http://come.to/cfg2html">  [ Download cfg2html from external home page ] </b></A></center></P><hr></BODY></HTML>\n" >> $HTML_OUTFILE_TEMP
  writeTF # §AW309§ BUG: write temp output to final file
  copyright="(c) 2000-2002 by Gert Leerdam, SysSupp; 2005 by Andreas Wizemann"
  echo "\n\nCreated "$DATEFULL" with " $VERSION" "$copyright" \n" >> $TEXT_OUTFILE
}

######################################################################
# exec_command: Documents the single commands and their output
#  $1 = unix command,  $2 = parm/opt for cmd $3 = text for the heading
######################################################################
exec_command ()
{
   if [ -z "$3" ] ; then      # if string 3 is zero
      TiTel="$1"
   else
      TiTel="$3"
   fi

   if (( VERBOSE == 1 )) ; then
      echo "$(date '+ %b-%d %T') - $TiTel +++"
   else
      echo ".\c"
   fi

   #echo "\n---=[ $2 ]=----------------------------------------------------------------" |
      #cut -c1-74 >> $TEXT_OUTFILE_TEMP
   #echo "       - $2" >> $TEXT_OUTFILE

   # §AW023§ get info about package to install if cmd not found
   # §AW024§ check for command availability using "which <cmd>" before using them
   #         to prevent unnecessary error messages
   cmd=$1
   package $cmd  # set package info

   cmdrc=77 # init rc with a dummy value
   case $package in
     *INTERNAL* ) : # OK
                    cmdrc=9
                    ;;
     *EXTERNAL* ) : # OK (Reserved for future use)
                    cmdrc=8
                    ;;
     *DUMMY*    ) : # OK - DUMMY
                    cmdrc=7
                    ;;
     *          ) which ${cmd} > /dev/null;  # §AW024§
                    cmdrc=$?
                    ;;
   esac

   runcmd="YES"
   case $cmdrc in
     0) : # OK cmd found
        # now call the "real working horse" IF cmd is available...
        ;;
     9) : # OK this is an INTERNAL cmd (function)
        ;;
     8) : # OK this is an EXTERNAL cmd (function)
        ;;
     7) : # OK this is an DUMMY    cmd (function)
        ;;
     1) runcmd="NO";
        txt="\nC2H040I CMD '${cmd}' not found in path.";
        verbose_out $txt;
        AWTRACE     $txt;
# ToDo: test package: if found we need to update the path, if not we need to install package
        txt="C2H041I You need to install package '${package}' to use cmd '${cmd}'";
        verbose_out $txt;
        AWTRACE     $txt;
        ;;
     *) runcmd="NO";
        verbose_out "\nC2H042E UNEXPECTED RC ${cmdrc} from 'which ${cmd}'\n";
        AWTRACE     "\nC2H042E UNEXPECTED RC ${cmdrc} from 'which ${cmd}'\n";
        ;;
   esac

#}
#
#ec2 ()
#{
if [[ "$runcmd" = "NO" ]]
then
  verbose_out "C2H043I CMD '${cmd}' NOT EXECUTED!"
  AWTRACE     "C2H043I CMD '${cmd}' NOT EXECUTED!"
else
 #AWCONS "AW E_C2 $1="$1" $2="$2
   ######========================##########
   ###### the real working horse ##########
   ######========================##########
   TMP_EXEC_COMMAND_ERR=/tmp/exec_cmd.tmp.$$

   # §AW303§ BUG: sed will convert also for *.TXT output file, which is not necessary
   AW303="YES"
   if [[ $AW303 = "YES" ]]
   then
     EXECRES=$(eval $1 2> $TMP_EXEC_COMMAND_ERR | expand | cut -c 1-150 | sed "$CONVSTR")
   else
     EXECRES=$(eval $1 2> $TMP_EXEC_COMMAND_ERR | expand | cut -c 1-150)
   fi
   if [ -z "$EXECRES" ] ; then
     EXECRES="n/a or not configured!"
   fi

   if [ -s $TMP_EXEC_COMMAND_ERR ] ; then
      echo ${SEP120} >> $ERROR_LOG
      echo "stderr output from \"$1\":" >> $ERROR_LOG
      cat $TMP_EXEC_COMMAND_ERR | sed 's/^/    /' >> $ERROR_LOG
      echo " " >> $ERROR_LOG
   fi
   rm -f $TMP_EXEC_COMMAND_ERR  2>/dev/null  # §AW004§

   # write header above output
   echo "\n" >> $HTML_OUTFILE_TEMP

   # write title with or without screentips
   if [ "$STINLINE" = "YES" ]   # §AW031§
   then
     echo "<A NAME=\"$2\"></A> <H${HEADL}><A HREF=\"#Content-$2\" title=\"$TiTel\"> $2 </A></H${HEADL}>\n" >> $HTML_OUTFILE_TEMP     # orig screentips by Ralph
   else
     # or more netscape friendly inline?
     echo "<A NAME=\"$2\"></A>            <A HREF=\"#Content-$2\"             ><H${HEADL}> $2 </H${HEADL}></A>\n" >>$HTML_OUTFILE_TEMP
   fi

   # show cmd used to produce the output
   if [ "X$1" = "X$2" ]
   then    : #no need to duplicate, do nothing
   else
     echo "<h6>$1</h6>" >>$HTML_OUTFILE_TEMP
     #echo "Cmd: $1"     >>$TEXT_OUTFILE_TEMP
     #echo "====   "     >>$TEXT_OUTFILE_TEMP
     #echo "       "     >>$TEXT_OUTFILE_TEMP
   fi

   # write output to text file
   echo "$EXECRES\n" >> $TEXT_OUTFILE_TEMP

   if [[ $AW303 = "YES" ]]
   then
     :
   else
     # now convert special char for HTML output
     EXECRES=$(echo $EXECRES | sed "$CONVSTR")
   fi

   # display content of ($EXECRES)
   echo "<PRE><B>$EXECRES</B></PRE>\n"  >> $HTML_OUTFILE_TEMP     # write contents

   # §AW016§ moved <META http-equiv=expires... to open_html, so it is only found once in the html file

   echo "<LI><A NAME=\"Content-$2\"></A><A HREF=\"#$2\" title=\"$TiTel\">$2</A>\n" >> $HTML_OUTFILE     # writes header of index
fi
}

#*********************************************************************
#  end of HTML file with heading and titel
#*********************************************************************

######################################################################
# KillOnHang: Schedule a job for killing commands
######################################################################
#*********************************************************************
# Schedule a job for killing commands
# may hang under special conditions. <mortene@sim.no>
# Argument 1: regular expression to search processlist for. Be careful
# when specifiying this so you don't kill any more processes than
# those you are looking for!
# Argument 2: number of minutes to wait for process to complete.
#*********************************************************************
KillOnHang ()
{
   TMP_KILL_OUTPUT=/tmp/kill_hang.tmp.$$
   at now + $2 minutes 1>$TMP_KILL_OUTPUT 2>&1 <<EOF
   ps -ef | grep root | grep -v grep | egrep $1 | awk '{print \$2}' | sort -n -r | xargs kill
EOF
   AT_JOB_NR=$(egrep '^job' $TMP_KILL_OUTPUT | awk '{print \$2}')
   rm -f $TMP_KILL_OUTPUT 2>/dev/null  # §AW004§
}

######################################################################
# CancelOnHang: ...
######################################################################
#*********************************************************************
# You should always match a KillOnHang() call with a matching call
# to this function immediately after the command which could hang
# has properly finished.
#*********************************************************************
CancelKillOnHang ()
{
  at -r $AT_JOB_NR
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# General-Functions
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

######################################################################
# package: get package name for command
######################################################################
package ()
{
# §AW023§ get info about package to install if cmd not found

# exec_command "cmd parm text"
 package="*UNKNOWN*"
 desc="*?*"
 cmd=$1
#cmd=xyz
#cmd=$(echo $1 | cut -c 1-1)

 case $cmd in
  "(("         ) package="*DUMMY*"               ; desc="*DUMMY*"      ;; # DUMMY - DO NOT DELETE
  "[["         ) package="*DUMMY*"               ; desc="*DUMMY*"      ;; # DUMMY - DO NOT DELETE
  "at"         ) package="bos.rte.cron"          ; desc="*at*"         ;; # Base OS
  "bootinfo"   ) package="bos.rte.boot"          ; desc="?"            ;; # ...
  "bootlist"   ) package="bos.rte.boot"          ; desc="?"            ;; # ...
  "cat"        ) package="bos.rte.commands"      ; desc="?"            ;; # ...
  "chcod"      ) package="bos.rte.methods"       ; desc="?"            ;; # ...
  "cpupstat"   ) package="bos.rte.commands"      ; desc="?"            ;; # AIX 5.3
  "datapath"   ) package="*sdd"                  ; desc="IBM SDD"      ;; # ... SDD
  "df"         ) package="bos.rte.filesystems"   ; desc="?"            ;; # ...
  "domainname" ) package="bos.net.nis.client"    ; desc="?"            ;; # ... NIS
  "dumpcheck"  ) package="bos.?"                 ; desc="?"            ;; # ...
  "echo"       ) package="bos.rte.shell"         ; desc="?"            ;; # ...
  "egrep"      ) package="bos.rte.commands"      ; desc="?"            ;; # ...
  "exportfs"   ) package="bos.net.nfs.client"    ; desc="?"            ;; # ...
  "find"       ) package="bos.rte.commands"      ; desc="?"            ;; # ...
  "genkex"     ) package="bos.perf.tools"        ; desc="?"            ;; # ...
  "grep"       ) package="bos.rte.commands"      ; desc="?"            ;; # ...
  "grpck"      ) package="bos.rte.seurity"       ; desc="?"            ;; # ...
  "hostname"   ) package="bos.rte.net"           ; desc="?"            ;; # ...
  "i4blt"      ) package="bos.?"                 ; desc="?"            ;; # ...
  "ifconfig"   ) package="bos.net.tcp.client"    ; desc="?"            ;; # ...
  "inulag"     ) package="bos.rte.instal"        ; desc="?"            ;; # ...
  "ioo"        ) package="bos.perf.tune"         ; desc="?"            ;; # ...
  "iostat"     ) package="bos.acct"              ; desc="?"            ;; # ...
  "ipcs"       ) package="bos.rte.control"       ; desc="?"            ;; # ...
  "java"       ) package="*java"                 ; desc="JAVA"         ;; # ... JAVA
  "locktrace"  ) package="bos.perf.tools"        ; desc="?"            ;; # ...
  "lparstat"   ) package="bos.acct"              ; desc="?"            ;; # AIX 5.3
  "lppchk"     ) package="bos.rte.install"       ; desc="?"            ;; # ...
  "lpstat"     ) package="bos.?"                 ; desc="AIX Print subsystem" ;; # ...
  "lsattr"     ) package="bos.rte.methods"       ; desc="?"            ;; # ...
  "lscfg"      ) package="bos.rte.diag"          ; desc="?"            ;; # ...
  "lsclient"   ) package="bos.net.nis.client"    ; desc="?"            ;; # ... NIS
  "lsdev"      ) package="bos.rte.methods"       ; desc="?"            ;; # ...
  "lsess"      ) package="*ESSUTIL"              ; desc="ESSUTIL"      ;; # ... ESSUTIL
  "ls2105"     ) package="*ESSUTIL"              ; desc="ESSUTIL"      ;; # ... ESSUTIL
  "lsvp"       ) package="*ESSUTIL"              ; desc="ESSUTIL"      ;; # ... ESSUTIL
  "lssdd"      ) package="*ESSUTIL"              ; desc="ESSUTIL"      ;; # ... ESSUTIL
  "lsfs"       ) package="bos.rte.filesystems"   ; desc="File Systems" ;; # Base OS
  "lslpp"      ) package="bos.rte.install"       ; desc="?"            ;; # ...
  "lsnamsv"    ) package="bos.net.tcp.smit"      ; desc="?"            ;; # ...
  "lsnfsexp"   ) package="bos.net.nfs.client"    ; desc="?"            ;; # ...
  "lsnfsmnt"   ) package="bos.net.nfs.cient"     ; desc="?"            ;; # ...
  "lsnim"      ) package="bos.sysmgt.nim.master" ; desc="NIM"          ;; # NIM Master (NIM Server)
  "lspath"     ) package="bos.rte.methods"       ; desc="?"            ;; # ...
  "lsps"       ) package="bos.rte.lvm"           ; desc="?"            ;; # ...
  "lspv"       ) package="bos.rte.lvm"           ; desc="?"            ;; # Physical Volumes
  "lsrole"     ) package="bos.rte.security"      ; desc="?"            ;; # ...
  "lsrset"     ) package="bos.rte.control"       ; desc="?"            ;; # ...
  "lsrsrc"     ) package="rsct.core.rmc"         ; desc="?"            ;; # ...
  "lssrc"      ) package="bos.rte.SRC"           ; desc="?"            ;; # ...
  "lsvg"       ) package="bos.rte.lvm"           ; desc="?"            ;; # Volume Groups
  "lsvpd"      ) package="bos.rte.methods"       ; desc="?"            ;; # ...
  "mount"      ) package="bos.rte.filesystems"   ; desc="?"            ;; # ...
  "mpstat"     ) package="bos.acct"              ; desc="?"            ;; # AIX 5.3
  "namerslv"   ) package="bos.net.tcp.client"    ; desc="?"            ;; # ...
  "netstat"    ) package="bos.net.tcp.client"    ; desc="?"            ;; # ...
  "nfso"       ) package="bos.net.nfs.client"    ; desc="?"            ;; # ...
  "nfsstat"    ) package="bos.net.nfs.client"    ; desc="?"            ;; # ...
  "no"         ) package="bos.net.tcp.client"    ; desc="?"            ;; # ...
  "nslookup"   ) package="bos.net.tcp.client"    ; desc="?"            ;; # ...
  "oslevel"    ) package="bos.rte.install"       ; desc="?"            ;; # ...
  "pcmpath"    ) package="*sddpcm"               ; desc="IBM SDDPCM"   ;; # ... SDDPCM
  "pmctrl"     ) package="bos.powermgt.rte"      ; desc="?"            ;; # ... Power Management
  "printf"     ) package="bos.rte.commands"      ; desc="?"            ;; # ...
  "prtconf"    ) package="bos.rte.diag"          ; desc="?"            ;; # ...
  "ps"         ) package="bos.rte.control"       ; desc="?"            ;; # ...
  "pwdck"      ) package="bos.?"                 ; desc="?"            ;; # ...
  "qchk"       ) package="printers.rte"          ; desc="?"            ;; # ...
  "repquota"   ) package="bos.sysmgt.quota"      ; desc="?"            ;; # ...
  "rpcinfo"    ) package="bos.net.tcp.client"    ; desc="?"            ;; # ...
  "sar"        ) package="bos.acct"              ; desc="?"            ;; # ...
  "smtctl"     ) package="bos.rte.methods"       ; desc="?"            ;; # AIX 5.3 + Power5
  "suma"       ) package="bos.suma"              ; desc="SUMA"         ;; # SUMA
  "sysdumpdev" ) package="bos.rte.serv_aid"      ; desc="?"            ;; # ...
  "tcbck"      ) package="bos.rte.security"      ; desc="?"            ;; # ...
  "uname"      ) package="bos.rte.misc_cmds"     ; desc="?"            ;; # ...
  "usrck"      ) package="bos.rte.security"      ; desc="?"            ;; # ...
  "vmstat"     ) package="bos.acct"              ; desc="?"            ;; # ...
  "vmtune"     ) package="bos.?"                 ; desc="?"            ;; # ...
  "vmo"        ) package="bos.perf.tune"         ; desc="?"            ;; # ...
  "w"          ) package="bos.rte.misc_cmds"     ; desc="?"            ;; # ...
  "wlmstat"    ) package="bos.rte.control"       ; desc="WLM - Workload Manager" ;; # WLM Workload Manager
  "ypwhich"    ) package="bos.net.nis.client"    ; desc="?"            ;; # ... NIS
  "lslicense"  ) package="bos.sysmgt.loginlic"   ; desc="?"            ;; # ...
  "PrtLayout"   ) package="*INTERNAL*"         ; desc="?"            ;; # ...
  "PrintLVM"    ) package="*INTERNAL*"         ; desc="?"            ;; # ...
  "psawk"       ) package="*INTERNAL*"         ; desc="?"            ;; # ...
  "bdf_collect" ) package="*INTERNAL*"         ; desc="?"            ;; # ...
  "cron_tabs"   ) package="*INTERNAL*"         ; desc="?"            ;; # ...
  "xyz"         ) package="*EXTERNAL*"         ; desc="?"            ;; # ...
  "*"           ) ERRMSG "C2H006W cmd '${cmd}' not defined.";
                  package="*UNKNOWN*" ; desc="*unknown*"
                  ;; # NOT DEFINED
 esac
}

#*********************************************************************
#
#*********************************************************************
######################################################################
# ShowLVM: get Logical Volume Manager information
######################################################################
ShowLVM ()
{
   DEBUG=0  # debugging 0=OFF 1=ON

   export PATH=$PATH:/usr/sbin

   pvs=/tmp/lvm.pvs_$$  # ToDo: Delete tmp-file after usage
#  mnttab=/tmp/lvm.mnttab_$$  # var NOT used

   echo "Primary:Altern:Tot.PPs:FreePPs:PPsz:Group / Volume:Filesys:LVSzPP:Cpy:Mount-Point:HW-Path / Product"

   pvs=$(lsvg -p $(lsvg -o) | egrep -v ':$|^PV' | awk '{printf "%s:%s:%s:%s\n",$1,"",$3,$4}')

   #  process for each physical volume (Prim. Link)
   for line in $(echo $pvs)
   do
      dev=$(echo $line | cut -d':' -f1 )
  DBG "ShowLVM 001 lspv "
      vg=$(lspv | grep "^$dev " | awk '{print $3}')
      hwpath=$(echo $(lscfg -l $dev | tail -1) | cut -d' ' -f2- | sed 's- - / -')
  DBG "ShowLVM 002 lspv -l ${dev}"
      lspvs=$(lspv -l $dev | egrep -v ':$|^LV')
      lvs=$(echo "$lspvs" | awk '{print $1}')

      #  search for mount points of logical volumes
      n=1
      for lv in $(echo $lvs)
      do
        mnt=$(echo "$lspvs" | grep "^$lv " | awk '{print $5}')
        lvsiz=$(echo "$lspvs" | grep "^$lv " | awk '{print $2}')
        lslv=$(lslv $lv)
        mir=$(echo "$lslv" | grep "^COPIES:" | awk '{print $2}')
        fstyp=$(echo "$lslv" | grep "^TYPE:" | awk '{print $2}')
        ppsiz=$(echo "$lslv" | grep "PP SIZE" | awk '{print $6}')

        if [[ $n = 1 ]] ; then
           echo "$line:${ppsiz}MB:$vg/$lv:$fstyp:$lvsiz:$mir:$mnt:$hwpath"
        else
           echo ":::::$vg/$lv:$fstyp:$lvsiz:$mir:$mnt:"
        fi

        let n=$n+1
      done
   done
}

######################################################################
# PrintLVM: print Logical Volume Manager information
######################################################################
PrintLVM ()
{
 DEBUG=0  # debugging 0=OFF 1=ON

 ShowLVM | awk '
   BEGIN { FS=":" }
     {
      printf("%-7s %-7s ", $1, $2);          # prim, alt
      printf("%-18s ", $6);                  # vg/lvol
      printf("%7s %-7s %4s ", $3, $4, $5);   # tot, free, size
      printf("%7s %7s %3s ", $8, $7, $9);    # size, fs, mir
      printf("%-20s %s", $10, $11);          # mnt, hwpath/prod
      printf("\n");
      }'
}

######################################################################
# PrtLayout: ...
######################################################################
PrtLayout ()
{
   DEBUG=0  # debugging 0=OFF 1=ON

   VGS="$1"
   if (( $# == 0 )); then
      VGS=$(lsvg -o | awk '{print $1}')
   fi

   if [[ "$2" != "" ]]; then
      MAN_LV="$2"
   fi

   DB ()
   {
   if (( $DEBUG == 1 )); then
      # tee -a will "add" the output to a file
      # BUG §AW301§ DB_F currently NOT DEFINED
      echo $* | tee -a $DB_F
   fi
   }  ## DEBUG MODE ##

   COL ()   ########## ( put var on positions )
   {
      case $1 in
      1)
       shift
       echo $* | awk '{printf("%10s%10s%9s%9s%16s%23s\n",$1,$2,$3,$4,$5,$6 )}'
       ;;
      2)
       shift
       echo $* | awk '{printf("%10s%5s%7s%9s%5s%2s%-17s\n",$1,$2,$3,$4,$5," ",$6 )}'
       ;;
      3)
       shift
       echo $* | awk '{printf("%47s%8s%22s\n",$1,$2,$3 )}'
       ;;
      esac
   }

   DB [-]  running on debug mode

   L0="=========================================================================="
   L1="--------------------------------------------------------------------------"
   PID=$(echo $$)
   PDD=$(date "+%y%m%d")

   DB [1] $PID $PDD

   ## create PHD list ###
   if lsdev -Cc pdisk | grep pdisk >/dev/null
   then
      >/tmp/PHD.tmp
      lsdev -Cc pdisk | awk '{print $1}' | while read PHD
      do
       echo " $PHD $(lsattr -l $PHD -E -a=connwhere_shad 2>/dev/null | awk '{print $2}') " >> /tmp/PHD.tmp
      done
   fi  ##############

   for VG in $VGS    ### check per Volume group #########
   do
      D=$(date "+%D")
      NAME=$(uname -n)
      PP=$(lsvg $VG 2>/dev/null | awk '/SIZE/ {print $6}')

      ######### PRINT VG #####
      echo "-*-"$L0
      echo " | $VG    PPsize:$PP	          date: $D 	from: $NAME "
      echo " + $L1"
      #######################
      HDS=$(lspv 2>/dev/null | grep $VG | awk '{print $1}')

      DB [2] HDS= $HDS

      COL 1 Logical Physical  Tot_Mb Used_Mb location [Free_distribution]

      for HD in $HDS
      do
       CAP=$(lspv $HD 2>/dev/null | awk '/PPs/{print $4}' | cut -c2-)
       echo $CAP | read TOT_MB USED_MB USE_C  ## CAP p/ disk
       lsvg -p $VG 2>/dev/null | awk "/$HD/{print \$5}" | sed s'/\.\./:/g' | \
       awk -F: '{printf("%.3d:%.3d:%.3d:%.3d:%.3d\n",$1,$2,$3,$4,$5)}' | read FREE_DISTR
       ### convert HDS PDS
       if lsattr -l $HD -E -a=connwhere_shad 2>/dev/null >/dev/null
       then
          CWiD=$(lsattr -l $HD -E -a=connwhere_shad | awk '{print $2}')
          awk "/$CWiD/{print \$1}" </tmp/PHD.tmp | read ITEM
          PD=$(lsdev -Cc pdisk | grep "$ITEM " | awk '{print $1}')
       else
          PD="$HD"
       fi
       #### end convert ###

       lsdev -Cc disk | awk "/$HD/{print \$3}" | read LOC

       #####  HD  info #########################################
       COL 1 $HD $PD $TOT_MB $USE_C $LOC $FREE_DISTR
       #############################################################

       DB [3]  "${PID}_${PDD} ${VG}_${HD} $PD  $TOT_MB $USED_MB $LOC $FREE_DISTR "
      done

      if [[ "$MAN_LV" = "" ]]; then
       LVS=$(lsvg -l $VG 2>/dev/null | egrep -v "$VG|NAM"| awk '{print $1"_"$2"_"$3}') # gen LVS
      else
       if lsvg -l $VG | grep "$MAN_LV" >/dev/null ; then
          LVS=$(lsvg -l $VG | egrep -v "$VG|NAM"| grep "$MAN_LV" | awk '{print $1"_"$2"_"$3}') # gen LVS
       else
          echo " \n ERROR :  $MAN_LV   not on $VG ! \n"
          xexit  # §AW018§
       fi
      fi

      echo "   $L1 \n"

      ########################################## show ############
      COL 2 LVname LPs FStype Size used FS
      ############################################################

      for RLV in $LVS
      do
       echo  $RLV | awk -F_ '{print $1,$2,$3}' | read LV TLV LP
       B_SZ=$(expr $LP \* $PP)
       case $TLV in
          jfs|jfs2)
             lsfs | awk "/$LV/{print \$5,\$3}" | read SZK MP
             if [[ "$SZK" = "" ]]; then
              SZ="${B_SZ}MB"
              TLV="-"
             else
              SZ=$(expr $SZK / 2048 2>/dev/null)
              if [[ "$B_SZ" != "$SZ" ]]; then
               SZ="->${SZ}MB"  ## warning: fs-size < lv-size
              else
               SZ="${SZ}MB"
              fi
             fi
             df | awk "/$LV/{print \$4}" | read PRC

             if [[ "$PRC" = "" ]]; then
              PRC="n/a"
             fi
             ;;
          paging)
             lsps -a | grep "$LV" | grep "$VG" | awk '{print $4,$5"%"}' | read SZ PRC
             ;;
          *)
             SZ=" "
             PRC=" "
             MP=" "
             ;;
       esac

       ############### show LV  info ####################
       COL 2 $LV  $LP  $TLV  $SZ  $PRC $MP
       ##################################################

       lslv -m $LV 2>/dev/null | egrep -v "LP" | awk '{print $3,$5,$7}' | sort | uniq | while read A B C
       do
          echo $A >>/tmp/PV_1
          echo $B >>/tmp/PV_2
          echo $C >>/tmp/PV_3
       done

       for C in 1 2 3
       do
          cat /tmp/PV_${C} | sort | uniq | while read PV
          do
             if [[ "$PV" != "" ]]; then
             lslv -l $LV 2>/dev/null | awk "/$PV/{print \$4}" | sed 's/000/---/g' | read PPP

             DB [4]  " PPP = $PPP "

             if [[ "$C" = "1" ]]; then
              Y="+"
              PRE_PV="$PV"
             else
              Y="copy_$C"
              if [[ "$PRE_PV" = "$PV" ]]; then
                 PPP=$(echo $PPP | tr "0-9" "|||||||||")
              fi
             fi

             if lspv | grep $PV >/dev/null ; then  ## if hdisk not avail
              :
             else
              PV="N/A"
             fi

             ########## show PV position  #####
             COL 3  $Y   $PV   $PPP
             ######################################

             DB [5]  "${PID}_${PDD} ${VG}_${PV} $LV $LP $TLV $SZ $PRC $MP $Y $PV $PPP "
             fi
          done
       done

       rm -f /tmp/PV_? 2>/dev/null  # §AW004§
      done

      echo
   done

   rm -f /tmp/PHD.tmp 2>/dev/null  # §AW004§
}

######################################################################
# Get_CPU_Type: Get Model name/CPU Speed of RS/6000 machines
######################################################################
Get_CPU_Type ()
{
#----------------------------------------------------------------------
# This routine is ONLY needed for AIX 4.x Systems !
# Bruce Spencer, IBM # 2/4/99
# This program identifies the CPU type on a RS/6000
# Note:  newer RS/6000 models such as the S70 do not have a unique name
#        they will always return 4C !
#----------------------------------------------------------------------
DEBUG=0  # debugging 0=OFF 1=ON

DBG "CPU-TYPE 000"
uname_u=$(uname -u)
uname_M=$(uname -M)
uname_L=$(uname -L)
uname_m=$(uname -m)
uname_F=$(uname -F)
DBG "CPU-TYPE 001 uname -u "$uname_u
DBG "CPU-TYPE 001 uname -M "$uname_M
DBG "CPU-TYPE 001 uname -L "$uname_L
DBG "CPU-TYPE 001 uname -m "$uname_m
DBG "CPU-TYPE 001 uname -F "$uname_F

# PSPEED is Processor speed in MHz
PSPEED="?"
# ARCH is architecture
ARCH="?"

# uname -m ==> xxyyyyyymmss
# xx = 00
# yyyyyy = unique CPU ID
# mm = Model ID
# ss = 00 (Submodel)
CODE=$(uname -m | cut -c9,10 )

#30) MODEL="7018-740/741" # ??? unknown
case $CODE in
   02) MODEL="7015-930"; PSPEED=25; ARCH="Power";;
   10) MODEL="7016-730, 7013-530"; PSPEED=25; ARCH="Power";;
   11) MODEL="7013-540"; PSPEED=30; ARCH="Power" ;;
   14) MODEL="7013-540"; PSPEED=30; ARCH="Power" ;;
   18) MODEL="7013-53H"; PSPEED=33; ARCH="Power" ;;
   1C) MODEL="7013-550"; PSPEED=41.6; ARCH="Power" ;;
   20) MODEL="7015-930"; PSPEED=25; ARCH="Power" ;;
   2E) MODEL="7015-950"; PSPEED=41; ARCH="Power" ;;
   30) MODEL="7013-520"; PSPEED=20; ARCH="Power" ;;
   31) MODEL="7012-320"; PSPEED=20; ARCH="Power" ;;
   34) MODEL="7013-52H"; PSPEED=25; ARCH="Power" ;;
   35) MODEL="7012-32H"; PSPEED=25; ARCH="Power" ;;
   37) MODEL="7012-340"; PSPEED=33; ARCH="Power" ;;
   38) MODEL="7012-350"; PSPEED=41; ARCH="Power" ;;
   41) MODEL="7011-220"; PSPEED=33; ARCH="RSC" ;;
   42) MODEL="7006-41T/41W"; PSPEED=30; ARCH="Power" ;;
   43) MODEL="7008-M20, 7008-M2A"; PSPEED=33; ARCH="Power" ;;
   46) MODEL="7011-250"; PSPEED=66; ARCH="PowerPC" ;;
   47) MODEL="7011-230"; PSPEED=45; ARCH="RSC" ;;
   48) MODEL="7009-C10"; PSPEED=80; ARCH="PowerPC" ;;
   4C) MODEL="*NOTE-1*"; PSPEED=?; ARCH="?" ;; # Note 1
   57) MODEL="7012-390, 7030-3BT"; PSPEED=67; ARCH="Power2" ;;
   58) MODEL="7012-380, 7030-3AT"; PSPEED=59; ARCH="Power2" ;;
   59) MODEL="7012-39H, 7030-3CT"; PSPEED=67; ARCH="Power2" ;;
   5C) MODEL="7013-560"; PSPEED=50; ARCH="Power" ;;
   63) MODEL="7015-970/97B"; PSPEED=50; ARCH="Power" ;;
   64) MODEL="7015-980/98B"; PSPEED=62.5; ARCH="Power" ;;
   66) MODEL="7013-580/58F"; PSPEED=62.5; ARCH="Power" ;;
   67) MODEL="7013-570/770/771, 7015-R10"; PSPEED=50; ARCH="Power" ;;
   70) MODEL="7013-590, 9076-SP2"; PSPEED=66; ARCH="Power2" ;;
   71) MODEL="7013-58H"; PSPEED=55; ARCH="Power2" ;;
   72) MODEL="7013-59H/R12"; PSPEED=66; ARCH="Power2" ;;
   75) MODEL="7012-370/375/37T, 9076-SP1 Thin"; PSPEED=62; ARCH="Power" ;;
   76) MODEL="7012-360/365/36T"; PSPEED=50; ARCH="Power" ;;
   77) MODEL="7012-355/55H/55L"; PSPEED=41; ARCH="Power" ;;
   79) MODEL="7013-590/591, 9076-SP2 Wide"; PSPEED=77; ARCH="Power2" ;;
   80) MODEL="7015-990"; PSPEED=71.5; ARCH="Power2" ;;
   82) MODEL="7015-R24"; PSPEED=71.5; ARCH="Power2" ;;
   89) MODEL="7013-595, 9076-SP2 Wide"; PSPEED=135; ARCH="P2SC" ;;
   90) MODEL="7009-C20";  PSPEED=0; ARCH="Power" ;;
   91) MODEL="7006-42x"; PSPEED=0; ARCH="Power" ;;
   94) MODEL="7012-397, 9076-SP2 Thin"; PSPEED=0; ARCH="P2SC" ;;
   A0) MODEL="7013-J30"; PSPEED=75; ARCH="PowerPC" ;;
   A1) MODEL="7013-J40"; PSPEED=112; ARCH="PowerPC" ;;
   A3) MODEL="7015-R30"; PSPEED=?; ARCH="PowerPC" ;; # Note 2
   A4) MODEL="7015-R40/R50, 9076-SP2 High"; PSPEED=?; ARCH="PowerPC" ;; # Note 2;
   A6) MODEL="7012-G30"; PSPEED=?; ARCH="PowerPC" ;; # Note 2;
   A7) MODEL="7012-G40"; PSPEED=?; ARCH="PowerPC" ;; # Note 2;
   C0) MODEL="7024-E20/E30"; PSPEED=?; ARCH="PowerPC" ;; # Note 3
   C4) MODEL="7025-F30"; PSPEED=?; ARCH="PowerPC" ;; # Note 3;
   F0) MODEL="7007-N40"; PSPEED=50; ARCH="ThinkPad" ;;
    *) MODEL="Unknown";;
esac

# Note 1
# ======
# If uname -m is "4C" you can get the processor speed by booting
# to SMS Menu and use "System Config" option.
# Maybe a uname -M may help. (So we try this here)
#
if [[ $MODEL = "4C" ]];
then
  DBG "CPU-TYPE 200 MODEL=4C"
  uname_M=$(uname -M)
  case $uname_M in
    "IBM,Model 7043-150") MODEL="7043-150"; PSPEED=375; ARCH="PowerPC";;
                       *) MODEL="Unknown";;
  esac
fi

# Note 2
#=======
# J-/R-/G-Series
# Use "lscfg -vl cpucard0 | grep FRU"
#
# FRU Processor type Processor speed
# --- -------------- ---------------
# E1D PowerPC 601     75
#

# Note 3
#=======
# E-/F30-Series
# Use "lscfg -vp | more" and look for "CPU Card"
# In the line "Device Specific.(ZA)" PS=xxx shows the Processor Speed
#

# Note 4
#=======
# F50-/H50-Series
# Use "lscfg -vp | more" and look for "OrcaM5 CPU"
# In the line "Product Specific.(ZC)" PS=xxx shows the Processor Speed in HEX
# 0009E4F580=166MHz 0013C9EB00=332MHz
# PF=xxx shows processor config
# 251=1-way 166 / 261=2-way 166
# 451=1-way 332 / 461=2-way 332
#

TYPE=$MODEL
DBG "CPU-TYPE 100 TYPE "$TYPE
DBG "CPU-TYPE 101 PSPEED "$PSPEED
DBG "CPU-TYPE 102 ARCH "$ARCH
DBG "CPU-TYPE 999"
}

######################################################################
# CpuSpeed: ...
######################################################################
CpuSpeed ()
{
  DEBUG=0  # debugging 0=OFF 1=ON

  # cpu-speed (moeilijk-moeilijk, zie CpuSpeed[12].txt)
  # BUG §AW302§ proc0
  #    in AIX V5:  lsattr -El proc0     # frequency 333000000      Processor Speed False
  #    of: In AIX V5 you can use the pmcycles  command (perfagent.tools fileset).
  #    pmcycles  command (bos.pmapi.pmsvc)
  #    see also: http://www.rootvg.net/RSmodels.htm

  # AIX 5.x: Determine CPU speed:
   typeset -i10 mhz                      # integer base 10
   lscfg -vp | grep PS= | tail -1 | awk -F= '{print $2 }' | awk -F, '{print $1}' | read f
   typeset -i10 f=16#$f                  # integer base 10 from base 16
   if [ $f -eq 0 ] ; then
      print "Cannot determine CPU speed"
   else
      mhz=f/1000000                      # From Hz to MHz
      print "CPU Clock Speed is: $mhz MHz"
   fi
  :     # Dummy: DO *NOT* delete !!!
}

######################################################################
# bdf_collect: ...
######################################################################
bdf_collect ()
{
   DEBUG=0  # debugging 0=OFF 1=ON

   # Stolen from: cfg2html for HP-UX
   # Revision 1.2  2001/04/18  14:51:34  14:51:34  root (Guru Ralph)

   # echo "Total Used Local Diskspace\n"
   df -Pk | grep ^/ | grep -v '^/proc' | awk '
      {
       alloc += $2;
       used  += $3;
       avail += $4;
      }

      END {
       print  "Allocated\tUsed \t \tAvailable\tUsed (%)";
       printf "%ld \t%ld \t%ld\t \t%3.1f\n", alloc, used, avail, (used*100.0/alloc);
   }'
}

######################################################################
# cron_tabs: ...
######################################################################
cron_tabs ()
{
   DEBUG=0  # debugging 0=OFF 1=ON

   # §AW303§ BUG: sed will convert also for *.TXT output file, which is not necessary
   # §AW303§ BUG: 0 * * * * /usr/lpp/diagnostics/bin/run_ssa_healthcheck 1&gt;/dev/null 2&gt;/dev/null
   CRON_PATH=/var/spool/cron/crontabs
   for i in `ls $CRON_PATH`; do
      #echo "\n-=[ Crontab entry for user $i ]=-\n"
     #cat $CRON_PATH/$i | grep -v "^#"
      cat $CRON_PATH/$i | egrep -v "^#|^[ 	]*$"     # remove comment and empty lines
   done
}

######################################################################
# LsConfig: ...
######################################################################
LsConfig ()
{
   DEBUG=0  # debugging 0=OFF 1=ON

   for i in $(lsvg -o)
   do
      lsvg $i
   done | awk '
      BEGIN      { printf("%10s\t%10s\t%10s\t%10s\t%10s\n","VG","Total(MB)","Free","USED","Disks") }
      /VOLUME GROUP:/ { printf("%10s\t", $3)  }
      /TOTAL PP/ {    B=index($0,"(") + 1
                  E=index($0," megaby")
                  D=E-B
                  printf("%10s\t", substr($0,B,D) )
                 }
      /FREE PP/  {    B=index($0,"(") + 1
                  E=index($0," megaby")
                  D=E-B
                  printf("%10s\t", substr($0,B,D) )
                 }
      /USED PP/  {    B=index($0,"(")  + 1
                  E=index($0," megaby")
                  D=E-B
                  printf("%10s\t", substr($0,B,D) )
                 }
      /ACTIVE PV/ { printf("%10s\t\n", $3)  } '
}

######################################################################
# psawk: ...
######################################################################
psawk ()
{
   DEBUG=0  # debugging 0=OFF 1=ON

   awkscript='
#-------------------------------------------
function putstack(ppid,   i)
{
   if (ppids[ppid] > 1)  # is er meer dan 1 ppid met dit nr.?
   {
      for (i = 1; i <= endstack; i++)  # of deze? verschil? snelheid?
       if (stack[i] == ppid)  # bestaat al in stack?
          return  # ja; scheelt tijd

      stack[++endstack] = ppid  # sla op
   }
}
#-------------------------------------------
function getstack ()
{
   if (endstack > 0)  # zit er wat in de stack?
   {
      while (ppids[stack[endstack]] < 1)  # verlaag aantal ppids
      {
       endstack--  # stack leeg, neem voorgaande
       if (endstack < 1)  # allemaal op
          return 0
      }

      return stack[endstack]  # return stackwaarde
   }
   else
      return 0  # stack was leeg
}

#-------------------------------------------
function getlevel(curpid,   n)
{
   n = 1
   while (tree[curpid] != 0)
   {
      curpid = tree[curpid]
      n++
   }

   return n
}

#-------------------------------------------
function printnow(line,   spc, subs, ind, sub2, sub3)
{
   spc = substr(spcs,1,level - 1)
   subs = substr(line,cmd)
   ind = index(subs," ") - 1  # start vanaf 1, nu dus 0
   sub2 = substr(line,1,cmd + ind)
   sub3 = substr(line,cmd + ind + 1)

   printf("%s%s%s\n",sub2,spc,sub3)
}

#-------------------------------------------
BEGIN {
   n = 0  # teller op nul
   spcs = "                                                      " # veel!!
}

/^.*UID / {
   head=$0  # sla header op
   cmd=index($0,"CMD") - 1
   next
}

/..*/ {
   n++            # teller (start op 1)
   line[n] = $0   # gehele regel
   pid[n] = $2    # 2e veld = PID
   ppid[n] = $3   # 3e veld = PPID
   tree[$2] = $3  # onthoud parent
   ppids[$3]++    # ppids met zelfde nummer: ++
}

#-------------------------------------------
END {
   printf("%s\n",head)  # print header

   for (i = 1; i <= n; i++)  # zoek vanaf 1e
   {
      s = getstack()

      if (ppid[i] == -1 && s == 0)
       continue  # al gehad...

      if (s > 0)
      {
         current = i  # zet alvast regelnummer
         for (j = 1; j <= n; j++)  # zoek regelnr. met deze ppid
            if (ppid[j] == s)
            {
            current = j  # zet regelnummer
            break  # na 1e gevonden eruit
            }
      }
      else
         current = i  # zet alvast regelnummer

      curpid = pid[current]  # startpunt

      putstack(curpid)  # zet op stack als (nog) niet aanwezig
      level = getlevel(curpid)  # reken terug

      printnow(line[current])  # "1e" regel van groep

      ppids[ppid[current]]--  # geprint, dus geen sub meer
      ppid[current] = -1  # is geprint

       do  # loop
       {
          found = 0
          if (ppids[curpid] == 0)
             break

          for (j = 1; j <= n; j++)  # start weer op 1e pos
             if (curpid == ppid[j])  # gevonden ?
             {
              curpid = pid[j]  # prep. volgende
              level = getlevel(curpid)  # reken terug
              putstack(curpid)  # zet op stack als (nog) niet aanwezig

              printnow(line[j])  # volg. regel(s) printen

              ppids[ppid[j]]--  # geprint, dus geen sub meer
              ppid[j] = -1  # zet op "gehad"
              found = 1  # blijf zoeken
             }

          if (! found)  # na groep lege regel
             printf("%%%\n")

       } while (found)  # nodig ivm soms omgek. volgorde
   }
}'

# ToDo: ps -ef | grep -v aioserver !! Don't show aio here !!

   #++ §GL000§ start *5.3* --------------------------------------------
   #-- ps -Af | grep -v "awk ?" | sort +2 -3 -n +1 -2 | awk "$awkscript"
   # from Yahoo-Groups
   #Date: Tue Apr 12, 2005  5:15 pm
   #Subject: RE: [cfg2html] Is anyone working on IBM HACMP or SDD info?
   #   Gert Leerdam
   #
   #P.S. There are small changes regarding AIX 5.3, so if you work with
   #that, do the following:
   #
   #Line 922 (of version 2.5a):
   #
   #The original line is:
   #
   #ps -Af | grep -v "awk ?" | sort +2 -3 -n +1 -2 | awk "$awkscript"
   #
   #Change into:
   #
   #ps -Af | grep -v "awk ?" | grep -v "^s/[&<>\\]" | grep -v "^[ ]$" |
   #sort +2 -3 -n +1 -2 | awk "$awkscript"
   #
   #ATTENTION: Between the [ ] 's in grep -v "^[ ]$" put ONE space and ONE tab !!!
   #
   #It's not finished, but I don't have an AIX 5.3 (yet... :-(
   #++ §GL000§ end *5.3* ----------------------------------------------

   #++ §GL002§ start *5.3* --------------------------------------------
   ## NOTE ! Between [ ] is a space !!!
   #ps -Af | egrep -v '^[ ]*$|&amp' | grep -v "awk ?" | sort +2 -3 -n +1 -2 | awk "$awkscript"
   #++ §GL002§ end *5.3* ----------------------------------------------

   # remove the aioserver entries
  AWTRACE     "AW_PS-Af START"
  #  ps -Af | grep -v aioserver | grep -v "awk ?" | grep -v "^s/[&<>\\]" | grep -v "^[ ]$" |
  #  sort +2 -3 -n +1 -2 | awk "$awkscript"
     ps -Af | grep -v aioserver | egrep -v '^[ ]*$|&amp' | grep -v "awk ?" | sort +2 -3 -n +1 -2 | awk "$awkscript"
  AWTRACE     "AW_PS-Af END"

}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# COLLECTIONS
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

######################################################################
# sys_info: *col-01*S* System-Information
######################################################################
sys_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "SYSTEM 001"

  #verbose_out "\n-=[ 01/${maxcoll} Sys_Info ]=-\n"
  paragraph "AIX/System"
  inc_heading_level
    exec_command "hostname" "Hostname"  

#   exec_command "lscfg -vpl sysplanar0 | grep Machine/Cabinet | awk '{print \$2,\$3}'" "Serial Number"
   exec_command "lsattr -El sys0 |grep systemid |cut -c23-29" "Machine Serial Number" ""
   exec_command "uname -M" "Machine Type"  # §CP001§ add

   if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
      exec_command "uname -n" "Display the name of the current operating system (EXTENDED)"
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
   fi

   # AIX 5.x knows prtconf
   # ToDo: check if AIX 5.x
   exec_command "prtconf" "System Configuration"

   # -- OSLEVEL --
   # -- ******* --
   # ToDo: check for Version / Release / ML
   # AIX 4.3.3 ML11
   # AIX 5.1.0 ML09 Oct 2005
   # AIX 5.2.0 ML07 Oct 2005
   # AIX 5.3.0 ML03 Oct 2005
   # see http://xxxxxxxxxxxx
   #
   exec_command "oslevel" "OS Version)"
  #exec_command "piet=$(oslevel -r); (( $? = 0 )) && echo \"$piet\" || echo N/a" "HHHHHHHHHHHHHH"

   exec_command "oslevel -r" "OS Maintenance Level"
   exec_command "instfix -i |grep ML" "OS Maintenance Level instfix"  # §CP001§ add

  #exec_command "oslevel -g" "OS ML higher" # To determine the filesets at levels later than the current ML

   # -- BOOTINFO --
   # -- ******** --
   exec_command "bootinfo -T" "Hardware Platform Type"
   exec_command "bootinfo -p" "Model Architecture"
   exec_command "echo \"$(bootinfo -r) KB / $(echo $(bootinfo -r)/1024 | bc) MB\"" \
      "Memory Size" "bootinfo -r"

   exec_command "bootinfo -y" "CPU Type"

   exec_command "bootinfo -K" "Kernel Type"
   exec_command "(( $(bootinfo -z) == 0 )) && echo No || echo Yes" "Multi-Processor Capability" "bootinfo -z"

   # COMMAND: bootinfo -K
   #     Reports whether the system is running a 32-bit or 64-bit KERNEL.
   #     - AIX 4.3 has only a 32-bit kernel
   #     - AIX 5.1 has both 32-bit and 64-bit kernels. Only one [1]
   #         can be active on a system [or within a LPAR] at a time.
   #
   # COMMAND: bootinfo -y:
   #     Reports whether the CPU is 32-bit or 64-bit.

   # cputype=`getsystype -y`  # only 5.x (will be used by prtconf)
   # kerntype=`getsystype -K` # only 5.x

   exec_command "lscfg | grep Implementation | cut -d: -f2 | tr -d ' '" \
      "Model Implementation" "lscfg | grep Implementation"

   exec_command "bootlist -m normal -o" "Boot Device List"
   exec_command "bootinfo -m" "Machine Model Code"
   exec_command "bootinfo -b" "Boot device "

   # BUG §AW302§ proc0
   procs=$(lscfg | grep proc | awk '{print $2}')
   #for proc in $(echo $procs)
   #do
    exec_command "echo 'CPU's:' $NO_OF_CPUS of type: $(lsattr -El $proc | \
       grep type | awk '{print $2}')" "CPU's" "lsattr -El $proc | grep type"

    piet=$(lsattr -El $proc -a frequency -F value)
    exec_command "echo $(expr ${piet:-1} / 1000000) MHz" "CPU's Speed" "lsattr -El $proc | grep freq"
   #done

   # §AW303§ BUG: sed will convert also for *.TXT output file, which is not necessary
   # §AW303§ BUG: CPU: &lt;empty&gt;
   #exec_command "lsrset -av" "Display System Rset Contents"

   # -- PMCTRL --
   # -- ****** --
#   exec_command "pmctrl -v" "Display Power Management Information"

   # -- SAR --
   # -- *** --
  #DBG "start sar"
  #exec_command "w ; sar" "Uptime, Who, Load & Sar Cpu"
  #exec_command "sar -b 1 9" "Buffer Activity"  # sar -b ???? # TODO: ??
  #exec_command "sar -b" "Sar: Buffer Activity"
  #DBG "end   sar"

   # -- VMSTAT --
   # -- ****** --
   #DBG "start vmstat"
   #exec_command "vmstat" "Display Summary of Statistics since boot"
   #exec_command "vmstat -f" "Display Fork statistics"
   #exec_command "vmstat -i" "Displays the number of Interrupts"
   #exec_command "vmstat -s" "List Sum of paging events"
   #DBG "end   vmstat"

   # -- IOSTAT --
   # -- ****** --
   #exec_command "iostat" "Report CPU and I/O statistics"

   # -- LSPATH --
   # -- ****** --
   #exec_command "lspath" "Display the status of MultiPath I/O (MPIO) capable devices"

   # -- LOCKTRACE --
   # -- ********* --
# ToDo: locktrace: this command is not supported on UP kernels
   #exec_command "locktrace -l" "List Kernel Lock Tracing current Status"

   #dec_heading_level
   #DBG "SYSTEM 998"
}

######################################################################
# kernel_info: *col-02*K* Kernel Information
######################################################################
kernel_info ()
{
  DEBUG=1  # debugging 0=OFF 1=ON
  DBG "KERNEL 001"

  #verbose_out "\n-=[ 02/${maxcoll} Kernel_info ]=-\n"
  paragraph "Kernel"
  inc_heading_level

  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
     exec_command "genkex" "Loaded Kernel Modules (EXTENDE)D"
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  fi

  #++ §AW201§ start *vmtune* -----------------------------------------
  # ToDO: 5.2/5.3 use vmo and ioo

  # §AW304§ BUG: change uname -n to $(uname -n)
  # §AW304§ BUG: uname -n will produce entry in *.err file !
  NODE=$(uname -n)

  cmd="/usr/samples/kernel/vmtune"
  if [ -x /usr/samples/kernel/vmtune ] ; then
    DBG "Kernel_Info 010 vmtune "
    AWTRACE ": vmtune **"
    exec_command "/usr/samples/kernel/vmtune" "Virtual Memory Manager Tunable Parameters"
  else
    verbose_out "\nC2H005W CMD 'vmtune' not found.";
    AWTRACE     "\nC2H005W CMD 'vmtune' not found.";
    verbose_out "C2H043I CMD '${cmd}' NOT EXECUTED!"
    AWTRACE     "C2H043I CMD '${cmd}' NOT EXECUTED!"
  fi
  #++ §AW201§ end *vmtune* -------------------------------------------

  exec_command "lssrc -a" "List Defined subsystems"
  #exec_command "chcod"    "List Capacity upgrade On Demand values"
  #exec_command "lsvpd -v" "List Vital Product Data"
  exec_command "lsrsrc"   "List Resources"

  # §AW303§ BUG: sed will convert also for *.TXT output file, which is not necessary
  # §AW303§ BUG: root  5200  4668   0   Jun 21      -  0:00 dtlogin &lt;:0&gt;        -daemon
  # §AW303§ BUG: root 18084 17434   1 11:31:24  pts/3  0:00 sed ?s/&amp;/&#92;&amp;amp;/g?s/&lt;/&#92;&amp;lt;/g?s/&gt;/&#92;&amp;gt;/g?s/&#92;&#92;/&#92;&amp;#92;/g?
  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
# ToDo: ps -ef | grep -v aioserver !! Don't show aio here !!
     exec_command "ps -lAf | grep -v aioserver" "List Processes (EXTENDED)"  # unfortunately no -H (XPG4) as in HP-UX
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  else
     exec_command "ps -Af | grep -v aioserver"  "List Processes"             # unfortunately no -H (XPG4) as in HP-UX
  fi

  #++ §AW202§ start *ps* ---------------------------------------------
  AWTRACE ": psawk (ps -Af) **"
 # case $SYSTEM in
 #   AIX) # TODO: ...
 #        # ps -Af | awk '{...}'
 #        # The error context is
 #        #                 >>> {. <<< ..}
 #        # awk: 0602-502 The statement cannot be correctly parsed. The source line is 1.
 #        ;;
 #     *)
 #  exec_command "psawk" "List Processes hierarchically" "ps -Af | awk '{...}'"
 #        ;;
 # esac
  #++ §AW202§ end *ps* -----------------------------------------------

  dec_heading_level
  DBG "KERNEL 998"
}

######################################################################
# hw_info: *col-03*H* Hardware Information
######################################################################
hw_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "HARDWARE 001"

  #verbose_out "\n-=[ 03/${maxcoll} Hardware ]=-\n"
  paragraph "Hardware"
  inc_heading_level

  # -- lscfg --
  # -- ***** --
  #exec_command "lscfg"     "Hardware Configuration"
  #exec_command "lscfg -pv" "Hardware Configuration with VPD"

  #exec_command "lsdev -C | while read i j; \
  #   do lsresource -l \$i | grep -v \"no bus resource\"; done" \
  #   "Display Bus Resources for available Devices" "lsresource -l <Name>"

  dec_heading_level
  DBG "HARDWARE 998"
}

######################################################################
# filesys_info: *col-04*F* Filesystem Information
######################################################################
filesys_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "FILESYS 001"

  #verbose_out "\n-=[ 04/${maxcoll} Filesystems ]=-\n"
  paragraph "Filesystems, Dump- and Paging-configuration"
  inc_heading_level

  # -- FILE-SYSTEMS --
  # -- ************ --
  #exec_command "lsfs -l"   "List Filesystems"
  exec_command "lsfs -q"   "List Filesystems (extended)"
  exec_command "mount"     "Mounted Filesystems"
  exec_command "df -vk"    "Filesystems and Usage"
  #exec_command bdf_collect "Total Used Local Diskspace" "df -Pk | count \$2, \$3, \$4"

 #lsfs -l | xargs lsattr -El <lv>  # e.g. lsattr -El hd3, better getlvcb, same info...

  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
     # kaiser David Akin found error"
     #exec_command "lspv | awk '{print \$1}' | while read i; \
     #do echo \"Physical Volume: \$i\"; lqueryvg -At -p \$i; echo \$SEP; done | uniq | sed '\$d'" \
     
     exec_command "lspv | awk '/active/ {print \$1}' | while read i; \
     do echo \"Physical Volume: \$i\"; lqueryvg -At -p \$i; echo \$SEP; done | uniq | sed '\$d'" 
     "Query Physical Volumes (EXTENDED)" "lqueryvg -At -p <pvol>"

     # output=$(lsfs | grep '^/' | awk '{print $1}' | cut -d/ -f3 | while read i
     output=$(lsvg -l $(lsvg -o) | grep -v 'LV NAME' | grep -v '.*:' | \
     awk '{print $1}' | while read i
     do
      echo "Logical Volume: $i"
      getlvcb -AT $i | sed 's/^[ ]*	/ -/g' | grep -v '^ $'
      echo $SEP
     done)
     exec_command "echo \"\$output\" | uniq | sed '\$d'" "Get Logical Volume Control Block (EXTENDED)" "getlvcb -AT <lvol>"
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  fi

  # -- NFS --
  # -- *** --
  exec_command "exportfs"   "Exported NFS Filesystems"          # TODO: explanation correct?
#  AWCONS "\nAW: ls /etc/exports"
  AWX=$(ls -la /etc/exports 2>/dev/null)
  rc=$?
# if [[ $rc -ne 0 ]]
# then
#   ERRMSG "\nAW lsnfsexp /etc/exports RC="$rc" AWX="$AWX
# fi
  case $rc in
    0) :  # OK
       ;;
    2) ERRMSG "\nC2H000W lsnfsexp /etc/exports RC="$rc" File NOT found"
       ;;
    *) ERRMSG "\nC2H000E lsnfsexp /etc/exports RC="$rc" AWX="$AWX
       ;;
  esac

  #exec_command "lsnfsexp"   "Exported NFS Filesystems"          # TODO: explanation correct? (same as exportfs)
 #exec_command "nfsstat -m" "Mounted Exported NFS Filesystems"  # TODO: is option correct?
  #exec_command "lsnfsmnt"   "Mounted Exported NFS Filesystems"  # TODO: same as by MYSELF mounted fs?

  # -- PAGING --
  # -- ****** --
  exec_command "lsps -a"   "Paging"
  exec_command "vmstat -s" "Kernel paging events"

  # -- SYSDUMP --
  # -- ******* --
  # §AW014§ AIX 5.3 -Lv / others -L
  if [[ $OSVER3CHAR = "530" ]]
  then
    opt="-Lv"
  else
    opt="-L"
  fi
  exec_command "sysdumpdev -l 2>&1" "List current value of dump devices" "sysdumpdev -l"
  #exec_command "/usr/lib/ras/dumpcheck -p" "Check dump resources"
  exec_command "sysdumpdev ${opt} 2>&1" "Most recent system dump" "sysdumpdev ${opt}"

  # -- ERRPT --
  # -- ***** --
  exec_command "printf '%-10s %s %2s %s %-14s %s\n' IDENTIFIER DATE/TIMESTAMP T C RESOURCE_NAME DESCRIPTION; \
     errpt | tail +2 | awk '{printf \"%-10s %s-%s-%s %s:%s %2s %s %-14s %s %s %s %s %s %s %s %s %s %s\n\",
      \$1, substr(\$2,3,2), substr(\$2,1,2), substr(\$2,9,2), substr(\$2,5,2), substr(\$2,7,2),
      \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15}'" "Error Report" "errpt | awk {...}"

  # -- REPQUOTA --  §AW0028§
  # -- ******** --
  #exec_command "repquota -a" "Display Disk Quota"  # §AW028§

  # -- DEFRAG --  §AW030§
  # -- ****** --
  output=""
  if [ "$EXTENDED" = 1 ] ; then
  AWCONS "\nEXTENDED defrag report currently not supported"
# AWCONS "\nAWTRACE EXTENDED START"
# AWTRACE "EXTENDED START"
#     mount | grep '^ ' | egrep -v "node| /proc " | awk '{print $2}' | while read i
#     do
#       output="$output-- Status of $i --\n$(defragfs -r $i)\n$SEP80\n"
#     done
#     exec_command "echo \"\$output\" | uniq | sed '\$d' | sed '\$d'" \
#      "Filesystem Fragmentation status (EXTENDED)" "defragfs -r <vol>"
# AWCONS "\nAWTRACE EXTENDED STOP"
# AWTRACE "EXTENDED STOP"
  else
     mount | grep '^ ' | egrep -v "node| /proc " | awk '{print $2}' | while read i
     do
       output="$output-- Status of $i --\n$(defragfs -q $i)\n$SEP60\n"
     done
     #exec_command "echo \"\$output\" | uniq | sed '\$d' | sed '\$d'" \
     # "Filesystem Fragmentation status" "defragfs -q <vol>"
  fi

  # TODO: ...
  # defragfs -s: Reports the fragmentation in the file system. This option causes defragfs
  #    to pass through meta data in the file system which may result in degraded performance.

  dec_heading_level
  DBG "FILESYS 998"
}

######################################################################
# disk_info: *col-05*D* Disk (Device) Information
######################################################################
disk_info ()
{
  DEBUG=1  # debugging 0=OFF 1=ON
  DBG ":---------------------------------------"
  DBG "DISKS 001"

  #verbose_out "\n-=[ 05/${maxcoll} Device-Info ]=-\n"
  paragraph "Devices"
  inc_heading_level

  exec_command "lsdev -C -H -S a" "Available Physical Devices"
  exec_command "lsdev -C -H -S d" "Defined Physical Devices"

  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
  DBG "DISKS 010 ALL Physical Devices"
      exec_command "lsdev -C | sort" "All Physical Devices (EXTENDED)"       # ??
  DBG "DISKS 011 Predefined Physical Devices"
      exec_command "lsdev -P -H" "Predefined Physical Devices (EXTENDED)"    # ??
    # exec_command "lsdev -C -H" "Customized Physical Devices (EXTENDED)"  # ????

      paragraph "Devices by Class"
      inc_heading_level
  DBG "DISKS 020 Devices by Class"
      for CLASS in $(lsdev -Pr class) ; do
       exec_command "lsdev -Cc $CLASS" "Devices of Class: $CLASS (EXTENDED)"
      done
      dec_heading_level

      paragraph "Device Attributes"
      inc_heading_level
  DBG "DISKS 030 Device Attributes"
      for DEV in $(lsdev -C | awk '{print $1}') ; do
       exec_command "lsattr -EHl $DEV" "Attributes of Device: $DEV (EXTENDED)"
      done
      dec_heading_level
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  fi

  DBG "DISKS 040 Physical Volumes"
  exec_command "lspv" "Physical Volumes"

  # §AW306§ BUG: ignore newly created devices which do not have a PVID (PVID is none)
  exec_command "lspv | grep -v none | awk '/active/{print $1}' | while read hd ; \
      do lspv \$hd; echo \$SEP90; done | uniq | sed '\$d'" "Physical Volumes per Volume Group" "lspv <hdisk>"

  # §AW306§ BUG: ignore newly created devices which do not have a PVID (PVID is none)
  exec_command "lspv | grep -v none | awk '/active/{print $1}' | while read hd ; \
      do lspv -p \$hd; echo \$SEP100; done | uniq | sed '\$d'" "Layout Physical Volumes" "lspv -p <hdisk>"

   #----------------------------------------------------------------------------
   # [AIX433] /tmp # getlvodm -w
   # getlvodm: A flag requires a parameter: w
   # Usage: getlvodm [-a LVdescript] [-B LVdesrcript] [-b LVid] [-c LVid]
   #         [-C] [-d VGdescript] [-e LVid] [-F] [-g PVid] [-h] [-j PVdescript]
   #         [-k] [-L VGdescript] [-l LVdescript] [-m LVid] [-p PVdescript]
   #         [-r LVid] [-s VGdescript] [-t VGid] [-u VGdescript] [-v VGdescript]
   #         [-w VGid] [-y LVid] [-G LVdescript]
   # [AIX433] /tmp #
   #
   # getlvodm -C ( == +/- lspv)      # TODO: ...
   # getlvodm -u | -d | -v | -L <vg> # TODO: ...
   #----------------------------------------------------------------------------

   lsvg -o | while read vg
   do
      lvs=$(\
       lsvg -l $vg | egrep -v ':$|^LV' | awk '{print $1}' | while read lv
       do
          lslv -l $lv
          echo $SEP70
       done)
      exec_command "echo \"\$lvs\" | uniq | sed '\$d'" "List Volume Distribution: $vg" "lslv -l <lvol>"
   done
#----
   h2p=$(\
      for i in $(lsdev -Csssar -thdisk -Fname)
      do
       echo $i" ---> "$(ssaxlate -l $i 2>&1)
      done)
   exec_command "echo \"\$h2p\"" "Mapping of hdisk to pdisk" \
      "lsdev -Csssar -thdisk -Fname | ssaxlate -l <dev>"

   p2h=$(\
      for i in $(lsdev -Csssar -cpdisk -Fname)
      do
       echo $i" ---> "$(ssaxlate -l $i 2>&1)
      done)
   exec_command "echo \"\$p2h\"" "Mapping of pdisk to hdisk" \
      "lsdev -Csssar -cpdisk -Fname | ssaxlate -l <dev>"

   conndata=$(\
      for pdisk in $(lsdev -Csssar -cpdisk -Fname)
      do
       for adap in $(ssaadap -l $pdisk 2>/dev/null)
       do
         ssaconn -l $pdisk -a $adap
       done
      done)
   exec_command "echo \"\$conndata\"" "SSA Connection Data" \
      "lsdev -Csssar -cpdisk -Fname | ssaadap -l <pdisk>"


#----------------------------------------------------------------------------
#   conndata=$(\
#      for adap in $(lsdev -Ctssa -Fname) $(lsdev -Ctssa160 -Fname)
#      do
#       for pdisk in $(lsdev -Csssar -cpdisk -Fname)
#       do
#         xssa=$(ssaconn -l $pdisk -a $adap 2>/dev/null )
#         if [[ -n $xssa ]]
#         then
#           Cssa="$Cssa\\n$xssa"
#         fi
#       done
#       echo "$Cssa" | sort -d +4 -5 +2 -3
#       unset Cssa
#      done)
#   exec_command "echo \"\$conndata\"" "SSA Connection Data sorted by Link" \
#      "ssaconn -l <pdisk> -a <adapter>"    # TODO: ??
#----------------------------------------------------------------------------

   dec_heading_level
  DBG "DISKS 998"
  DBG ":---------------------------------------"
}

######################################################################
# lvm_info: *col-06*L* LVM - Logical Volume Manager Information
######################################################################
lvm_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "LVM 001"

  #verbose_out "\n-=[ 06/${maxcoll} LVM-Info ]=-\n"
  paragraph "LVM"
  inc_heading_level

  exec_command "lsvg -o | lsvg -i | sed \"s/^\$/$SEP80/\"" "Volume Groups" "lsvg -o | lsvg -i"
  exec_command "lsvg -o | xargs lsvg -p" "Volume Group State"
  exec_command "lsvg -o | while read i; do \
     lsvg -l \$i; echo \$SEP80; done | uniq | sed '\$d'" "Logical Volume Groups" "lsvg -l <vg>"
  exec_command PrtLayout "Print Disk Layout"
  exec_command PrintLVM "List Volume Groups"

  output=$(lsvg -o | while read vg
  do
     echo --------------------------------
     echo "   Volume Group: $vg"
     echo --------------------------------
     lsvg -l $vg | egrep -v ":$|^LV" | while read lv rest; do lslv $lv; echo $SEP100; done | uniq | sed '$d'
  done)
  exec_command "echo \"\$output\"" "List Logical Volumes" "lslv <lvol>"  # TODO: make it nicer

  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
  DBG "LVM 010 lsvg"
     output=$(lsvg -o | while read vg
     do
      echo --------------------------------
      echo "   Volume Group: $vg"
      echo --------------------------------
      lsvg -l $vg | egrep -v ":$|^LV" | while read lv rest; \
         do lslv -m $lv | head; echo $SEP; done | uniq | sed '$d'
     done)
     exec_command "echo \"\$output\"" "List Logical/Physical Partition number (first 10 lines) (EXTENDED)" \
      "lslv -m <lv> | head"

     exec_command "lsvg -o | while read i; do \
      lsvg -M \$i; echo \$SEP; done | uniq | sed '\$d'" "List Logical Volume on Physical Volume (EXTENDED)" "lsvg -M <vg>"
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  fi

  dec_heading_level
  DBG "LVM 998"
}

######################################################################
# user_info: *col-07*U* User & Group Information
######################################################################
user_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "USER 001"

  #verbose_out "\n-=[ 07/${maxcoll} User-Info ]=-\n"
  paragraph "Users & Groups"
  inc_heading_level

  exec_command "lsuser -f -a rlogin ALL|egrep -p "rlogin=true"|egrep -p -v '(^iz|^y|^is)'" "Rlogin enabled by Systemuser" # §CP001§ add

  L40="----------------------------------------"
  exec_command "printf '%-10s %6s %-s\n' Name Id Home &&
     echo $L40 &&
      lsuser -c -a id home ALL | sed '/^#/d' |
         awk -F: '{printf \"%-10s %6s %-s\n\", \$1, \$2, \$3}'" \
     "Display User Account Attributes" "lsuser -c -a id home ALL"

  L80=${L40}""${L40}
  exec_command "printf '%-10s %6s %-6s %-8s %-s\n' Name Id Admin Registry Users &&
     echo $L80 &&
      lsgroup -c ALL | grep -v '^#' |
         awk -F: '
            NF==4 {printf \"%-10s %6s %-6s %-8s\n\", \$1, \$2, \$3, \$4}
            NF==5 {printf \"%-10s %6s %-6s %-8s %-s\n\", \$1, \$2, \$3, \$5, \$4}'" \
     "Display Group Account Attributes" "lsgroup -c ALL"

  exec_command "lsrole -f ALL | grep -v '=$'" "Display role attributes"
  # -- TCB --
  # -- *** --
  # ToDo: move this to SYSTEM ??
  AWTRACE ": tcbck -n ALL **"
  exec_command "tcbck -n ALL" "Lists the security state of the system"

  # -- PASSWD --  # §AW029§
  # -- ****** --
  exec_command "cat /etc/passwd | \
     sed 's&:.*:\([-0-9][0-9]*:[-0-9][0-9]*:\)&:x:\1&'" "/etc/passwd" "cat /etc/passwd"  # ?????

  AWTRACE ": pwdck -n ALL **"
  exec_command "pwdck -n ALL 2>&1" "Errors found in authentication" "pwdck -n ALL"
  AWTRACE ": usrck -n ALL **"
  exec_command "usrck -n ALL 2>&1" "Errors found in passwd" "usrck -n ALL"

  exec_command "cat /etc/group" "/etc/group"
  exec_command "grpck -n ALL 2>&1" "Errors found in group" "grpck -n ALL"

  # sysck -i -Nv  # TODO: ??
  # sysck: Checks the inventory information during installation and update procedures.

  dec_heading_level
  DBG "USER 998"
}

######################################################################
# network_info: *col-08*N* Network Information
######################################################################
network_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "NETWORK 001"

  #verbose_out "\n-=[ 08/${maxcoll} Network-Info ]=-\n"
  paragraph "Network Settings"
  inc_heading_level

  exec_command "netstat -in" "List of all IP addresses"
  # §AW303§ BUG: sed will convert also for *.TXT output file, which is not necessary
  # §AW303§ BUG: en0: flags=4e080863,80&lt;UP,BROADCAST,NOTRAILERS,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,PSEG,CHAIN&gt;
  exec_command "ifconfig -a" "Display information about all network interfaces"

  #++ §CP001§ start *lsdev* ------------------------------------------
  output=$(for i in $(lsdev -C -S a -F 'name'|grep en[0-9])
           do
              echo "$i:"
              entstat -d $i |egrep -i "Media|Status"
           done)
  exec_command "echo \"\$output\"" "Adapter Modes"
  #++ §CP001§ end *lsdef* --------------------------------------------

  exec_command "no -a"       "Display current network attributes in the kernel"
  exec_command "nfso -a"     "List Network File System (NFS) network variables"

  # §AW303§ BUG: sed will convert also for *.TXT output file, which is not necessary
  # §AW303§ BUG: 10.30.0.0        aixw              UHSb      0        0  en0     -   -      -   =&gt;
  exec_command "netstat -r"  "List of all routing table entries by name"
  # §AW303§ BUG: sed will convert also for *.TXT output file, which is not necessary
  # §AW303§ BUG: 10.30.0.0        10.30.8.130       UHSb      0        0  en0     -   -      -   =&gt;
  exec_command "netstat -nr" "List of all routing table entries by IP-address"

  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
     exec_command "netstat -an" "Show the state of all sockets (EXTENDED)"
     exec_command "netstat -An" "Show the address of any PCB associated with the sockets (EXTENDED)"
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  fi

  exec_command "netstat -s"  "Show statistics for each protocol"
  exec_command "netstat -sr" "Show the routing statistics"
  exec_command "netstat -v"  "Show statistics for CDLI-based communications adapters"
  exec_command "netstat -m"  "Show statistics recorded by memory management routines"

  # ToDo: ...
  # output=$(entstat -d)
  # output=$(tokstat -d)
  # output=$(atmstat -d)
  # if [ $? != 0 ] ; then
  #    exec_command "echo \"\$output\"" "Show Asynchronous Transfer Mode adapters statistics" "XXXstat -d"
  # fi

  # -- NFS --
  # -- *** --
  exec_command "nfsstat" "Show NFS statistics"

  # -- RPC --
  # -- *** --
  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
     exec_command "rpcinfo" "Display a List of Registered RPC Programs (EXTENDED)"
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  else
     exec_command "rpcinfo -p" "Display a List of Registered RPC Programs"
  fi
  exec_command "rpcinfo -m; echo \$SEP60; rpcinfo -s" "Display a List of RPC Statistics" \
     "rpcinfo -m; rpcinfo -s"

  # -- DNS --
  # -- *** --
  exec_command "lsnamsv -C 2>&1" "DNS Resolver Configuration" "lsnamsv -C"  # = /etc/resolv.conf
  exec_command "namerslv -s"     "Display all Name Server Entries"

  # -- NIS --
  # -- *** --
  exec_command "domainname"      "NIS Domain Name"
  exec_command "ypwhich"         "NIS Server currently used"
  exec_command "lsclient -l"     "NIS Client Configuration"

  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
     exec_command "nslookup $(hostname) 2>&1" "Nslookup hostname (EXTENDED)" "nslookup $(hostname)"
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  fi

  #++ §AW203§ start *ipcs* -------------------------------------------
  # cmd "ipcs" does NOT run on node aixn(5.3ML01) !
  #NODE=$(uname -n)
  #
  #case $NODE in
  #  aixn) ERRMSG "\nC2H004I CMD ipcs skipped on aixn !\n";
  #        ;;
  #     *) dummy=dummy
          exec_command "ipcs" "IPC info"
  #        ;;
  #esac
  #++ §AW203§ end *ipcs* ---------------------------------------------

  dec_heading_level
  DBG "NETWORK 998"
}

######################################################################
# printer_info: *col-09*P* Printer Information
######################################################################
printer_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "PRINER 001"

  #verbose_out "\n-=[ 09/${maxcoll} Printer-Info ]=-\n"
  paragraph "Printers"
  inc_heading_level

# Note: this may be a long running task, if remote printers do not answer

# exec_command "lpstat -s"  "Configured printers"  # TODO: ?? ( == enq -A)
  exec_command "lpq"        "AWTEST Printer"       # TODO: check
  exec_command "qchk -W -q" "Default printer"
  exec_command "qchk -W -A" "Printer Status"
# lsallq / lsque ...

  dec_heading_level
  DBG "PRINTER 998"
}

######################################################################
# quota_info: *col-10*Q* Quota Information
######################################################################
quota_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "QUOTA 001"

  #verbose_out "\n-=[ 10/${maxcoll} Quota-Info ]=-\n"
  paragraph "Disk Quota"
  inc_heading_level

#
# repquota MOVED TO col-04*F "Filesystem"  # §AW028§
#
  txt="C2H000I now part of 'Filesystem' Collector. Use option -F to enable/disable"
  echo "\n${txt}"
  AddText "\n${txt}"

  echo "<h6>$txt<h6>" >>$HTML_OUTFILE_TEMP
  echo "Cmd: $txt"    >>$TEXT_OUTFILE_TEMP

  dec_heading_level
  DBG "QUOTA 998"
}

######################################################################
# defrag_info: *col-11*d* Defragmentation Information
######################################################################
defrag_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "DEFRAG 001"

  #verbose_out "\n-=[ 11/${maxcoll} Defrag-Info ]=-\n"
  paragraph "Current Fragmentation State"
  inc_heading_level

#
# defrag_info MOVED TO col-04*F "FILESYS"  §AW030§
#
  txt="C2H000I now part of 'FILESYS' Collector. Use option -F to enable/disable"
  echo "\n${txt}"
  AddText "\n${txt}"

  echo "<h6>$txt<h6>" >>$HTML_OUTFILE_TEMP
  echo "Cmd: $txt"    >>$TEXT_OUTFILE_TEMP

  dec_heading_level
  DBG "DEFRAG 998"
}

######################################################################
# cron_info: *col-12*C* CRON Information
######################################################################
cron_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "CRON 001"

  #verbose_out "\n-=[ 12/${maxcoll} CRON-Info ]=-\n"
  paragraph "Cron and At"
  inc_heading_level

  for FILE in cron.allow cron.deny
  do
     if [ -r /var/adm/cron/$FILE ]
     then
      exec_command "cat /var/adm/cron/$FILE" "/var/adm/cron/$FILE"
   # else
   #  exec_command "echo /var/adm/cron/$FILE not found!" "$FILE"
     fi
  done

  #------------------------------------------------------------------------------------
  # ls /var/spool/cron/crontabs/* >/dev/null 2>&1
  # if [ $? -eq 0 ]
  # then
  #    echo "\n\n<B>Crontab files:</B>" >> $HTML_OUTFILE_TEMP
  #    for FILE in /var/spool/cron/crontabs/*
  #    do
  #     exec_command "cat $FILE" "Crontab for user '$(basename $FILE)'"
  #    done
  # else
  #    echo "No crontab files." >> $HTML_OUTFILE_TEMP
  # fi
  #------------------------------------------------------------------------------------

  exec_command cron_tabs "Crontab for all users" "cat /var/spool/cron/crontabs/* | grep -v '^#'"

  for FILE in at.allow at.deny
  do
     if [ -r /var/adm/cron/$FILE ]
     then
      exec_command "cat /var/adm/cron/$FILE " "/var/adm/cron/$FILE"
   # else
   #  exec_command "echo No At jobs present" "$FILE"
     fi
  done

  exec_command "at -l" 'AT Scheduler'

  dec_heading_level
  DBG "CRON 998"
}

######################################################################
# passwd_info: *col-13*p* Password & Group Information
######################################################################
passwd_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "PASSWD 001"

  #verbose_out "\n-=[ 13/${maxcoll} Passwd-Info ]=-\n"
  paragraph "Password and Group"
  inc_heading_level
#
# passwd MOVED TO col-07*U "User & Group"  # §AW029§
#
  txt="C2H000I now part of 'User & Group' Collector. Use option -U to enable/disable"
  echo "\n${txt}"
  AddText "${txt}"

  echo "<h6>$txt<h6>" >>$HTML_OUTFILE_TEMP
  echo "Cmd: $txt"    >>$TEXT_OUTFILE_TEMP

  dec_heading_level
  DBG "PASSWD 998"
}

######################################################################
# software_info: *col-14*s* Patch Statistics
######################################################################
software_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "SOFTWARE 001"

  #verbose_out "\n-=[ 14/${maxcoll} Software-Info ]=-\n"
  paragraph "Software"
  inc_heading_level

  # -- lslpp --
  # -- ***** --
  #exec_command "lslpp -l"       "Filesets installed"
  exec_command "lslpp -La"      "Display all information about Filesets"

  # -- lppchk --
  # -- ****** --
  exec_command "lppchk -v " "Verify Filesets" "lppchk -v"

  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
     #exec_command "lslpp -h all" "Display installation and update history" # §GL02§

     # -c Perform a checksum operation on the FileList items and verifies that the
     #    checksum and the file size are consistent with the SWVPD database.
     #exec_command "lppchk -c 2>&1" "Check Filesets (EXTENDED)" "lppchk -c"
     # -l Verify symbolic links for files as specified in the SWVPD database.
     #exec_command "lppchk -l 2>&1" "Verify symbolic links (SWVPD database) (EXTENDED)" "lppchk -l"
     # -wa ...
     # exec_command "lslpp -wa" "List fileset that owns this file (EXTENDED)"  # crasht; not enough memory (in eval)
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  fi

  # lppchk -f  # TODO: ? Checks that the FileList items are present and the file size matches the SWVPD database.

  # -- SUMA --
  # -- **** --
  # ToDo: implement SUMA here

  # -- EFIX --
  # -- **** --
  # ToDo: implement efix here

  dec_heading_level
  DBG "SOFTWARE 998"
}

######################################################################
# filestat_info: *col-15*f* File Statistics **5.3**
######################################################################
filestat_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG ":---------------------------------------"
  DBG "FILESYS 001"

  #verbose_out "\n-=[ 15/${maxcoll} Filestat-Info ]=-\n"
  paragraph "Files"
  inc_heading_level

  if [ "$EXTENDED" = 1 ] ; then
 AWCONS "\nAWTRACE EXTENDED START"
 AWTRACE "EXTENDED START"
     find /etc/rc.d/rc* -type f | while read i
     do
      exec_command "cat $i" "$i (EXTENDED)"
     done
 AWCONS "\nAWTRACE EXTENDED STOP"
 AWTRACE "EXTENDED STOP"
  else
     exec_command "find /etc/rc.d/rc* | xargs ls -ld" "Run Command files in /etc/rc.d"
  fi

  DBG "FILESYS 010"
  # §AW303§ BUG: sed will convert also for *.TXT output file, which is not necessary
  # §AW305§ BUG: do not display "<file> file not found" in *.err file !
  files ()
  {
     ls /etc/aliases         2>/dev/null
     ls /etc/binld.cnf       2>/dev/null
     ls /etc/bootptab        2>/dev/null
     ls /etc/dhcpcd.ini      2>/dev/null
     ls /etc/dhcprd.cnf      2>/dev/null
     ls /etc/dhcpsd.cnf      2>/dev/null
     ls /etc/dlpi.conf       2>/dev/null
     ls /etc/environment     2>/dev/null
     ls /etc/ftpusers        2>/dev/null
     ls /etc/gated.conf      2>/dev/null
     ls /etc/hostmibd.conf   2>/dev/null
     ls /etc/hosts           2>/dev/null
     ls /etc/hosts.equiv     2>/dev/null
     ls /etc/hosts.lpd       2>/dev/null
     ls /etc/inetd.conf      2>/dev/null
     ls /etc/inittab         2>/dev/null
     ls /etc/mib.defs        2>/dev/null
     ls /etc/mrouted.conf    2>/dev/null
     ls /etc/netgroup        2>/dev/null
     ls /etc/netsvc.conf     2>/dev/null
     ls /etc/ntp.conf        2>/dev/null
     ls /etc/oratab          2>/dev/null
     ls /etc/policyd.conf    2>/dev/null
     ls /etc/protocols       2>/dev/null
     ls /etc/pse.conf        2>/dev/null
     ls /etc/pse_tune.conf   2>/dev/null
     ls /etc/pxed.cnf        2>/dev/null
     ls /etc/qconfig         2>/dev/null  # defined printers
     ls /etc/filesystems     2>/dev/null
     ls /etc/rc              2>/dev/null
     ls /etc/rc.adtranz      2>/dev/null
     ls /etc/rc.bsdnet       2>/dev/null
     ls /etc/rc.licstart     2>/dev/null
     ls /etc/rc.local        2>/dev/null  # Kaiser
     ls /etc/rc.net          2>/dev/null
     ls /etc/rc.net.serial   2>/dev/null
     ls /etc/rc.oracle       2>/dev/null
     ls /etc/rc.qos          2>/dev/null
     ls /etc/rc.shutdown     2>/dev/null
     ls /etc/rc.tcpip        2>/dev/null
     ls /etc/resolv.conf     2>/dev/null
     ls /etc/rsvpd.conf      2>/dev/null
     ls /etc/sendmail.cf     2>/dev/null
     ls /etc/security/limits 2>/dev/null  # §AW025§ add /etc/security/limits to files
     ls /etc/security/user   2>/dev/null  # Kaiser
     ls /etc/services        2>/dev/null
     ls /etc/slip.hosts      2>/dev/null
     ls /etc/snmpd.conf      2>/dev/null
     ls /etc/snmpd.peers     2>/dev/null
     ls /etc/syslog.conf     2>/dev/null
     ls /etc/openssh/sshd_config 2>/dev/null  # Kaiser
     ls /etc/openssh/ssh_config 2>/dev/null   # Kaiser
     ls /etc/telnet.conf     2>/dev/null
     ls /etc/xtiso.conf      2>/dev/null
     ls /opt/ls3/ls3.sh      2>/dev/null
     ls /usr/tivoli/tsm/client/ba/bin/rc.dsmsched 2>/dev/null
     ls /usr/tivoli/tsm/server/bin/rc.adsmserv    2>/dev/null
     ls /usr/tivoli/tsm/client/ba/bin/dsm*.sys  2>/dev/null # §CP001§ add
     ls /usr/tivoli/tsm/client/ba/bin/dsm*.opt  2>/dev/null # §CP001§ add
  #++ §CP001§ start *TSM inclexcl* -----------------------------------
     grep -i inclexcl /usr/tivoli/tsm/client/ba/bin/dsm.sys |awk '{print $2}'|while read inc
          do
            ls $inc
          done
  #++ §CP001§ end *TSM inclexcl* -------------------------------------
   # ls /etc/rc2.d/*         2>/dev/null
   # ls /etc/rc3.d/*         2>/dev/null
  }

# ToDo: APACHE files: httpd.conf / .htaccess

  DBG "FILESYS 100"
  COUNT=1     # n.u... ??
  for FILE in $(files)
  do
    DBG "FILESYS 101 File: ${COUNT} ${FILE} "wc -k ${FILE}
    DBG "FILESYS 102 File: $(ls -la ${FILE}) "
   #exec_command "grep -v '^#' ${FILE} | uniq" "${FILE}"
    exec_command "egrep -v '^#|^[ 	]*$' ${FILE} | uniq" "${FILE}"  # remove comment and empty lines

    COUNT=$(expr $COUNT + 1)
  done

  #exec_command "ls -al /var/log/*" "Content of /var/log" # §CP001§ add

  writeTF # §AW309§ BUG: write temp output to final file

  dec_heading_level
  DBG "FILESYS 998"
  DBG ":---------------------------------------"
}

######################################################################
# nim_info: *col-16*n* NIM - Network Installation Management (available on NIM SERVER only
######################################################################
nim_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG ":---------------------------------------"
  DBG "NIM 001"

  #verbose_out "\n-=[ 16/${maxcoll} NIM-Info ]=-\n"
  paragraph "NIM - Network Installation Management"
  inc_heading_level

  nim_srv=$(lslpp -l bos.sysmgt.nim.master >/dev/null 2>&1)
  ns_rc=$?
  nim_cli=$(lslpp -l bos.sysmgt.nim.client >/dev/null 2>&1)
  nc_rc=$?
  #ERRMSG "NIM_SRV RC=${ns_rc}"
  #ERRMSG "NIM_CLI RC=${nc_rc}"
  if [[ $ns_rc = 0 ]]
  then
    ERRMSG "\nC2H000I This system is a NIM Server"
    AddText "\nC2H000I This system is a NIM Server"
    exec_command "lsnim -l" "Display information about NIM"
  fi
  if [[ $nc_rc = 0 ]]
  then
    ERRMSG "\nC2H000I This system is a NIM Client"
    AddText "\nC2H000I This system is a NIM Client"
# ToDo write to HTML File
  fi

  dec_heading_level
  DBG "NIM 998"
  DBG ":---------------------------------------"
}

######################################################################
# lum_info: *col-17*l* LUM - License Useage Management
######################################################################
lum_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG ":---------------------------------------"
  DBG "LUM 001"

  #verbose_out "\n-=[ 17/${maxcoll} LUM-Info ]=-\n"
  paragraph "LUM - License Use Manager"
  inc_heading_level

  # §AW305§ BUG: do not display "<file> file not found" in *.err file !
  files ()
  {
     ls /var/ifor/nodelock    2>/dev/null
     ls /var/ifor/i4ls.ini    2>/dev/null
     ls /var/ifor/i4ls.rc     2>/dev/null
     ls /etc/ncs/glb_site.txt 2>/dev/null
     ls /etc/ncs/glb_obj.txt  2>/dev/null
  }

  for FILE in $(files)
  do
     exec_command "cat ${FILE}" "${FILE}"
  done

  AWTRACE ": i4cfg -list * Installed Floating Licenses **"
  # §AW307§ BUG: check for "/var/ifor/i4cfg" Don't use if not available !
  # §AW307§ BUG: else we will see entry in *.err file !
  if [ -x /var/ifor/i4cfg ]
  then
    /var/ifor/i4cfg -list | grep -q 'active'
    rc=$?
    if (( $rc == 0 ))
    then
      AWTRACE ": i4blt -ll -n * Installed Floating Licenses **"
      exec_command "/var/ifor/i4blt -ll -n $(uname -n)" "Installed Floating Licenses"
      AWTRACE ": i4blt -s -n * Status of Floating Licenses **"
      exec_command "/var/ifor/i4blt -s -n $(uname -n)" "Status of Floating Licenses"
      AWTRACE "** "
    fi
  else
    AWTRACE ": i4cfg NOT FOUND"
  fi
  AWTRACE "** "

  exec_command "inulag -lc" "License Agreements Manager"
  exec_command "lslicense" "Display fixed and floating Licenses"

  dec_heading_level
  DBG "LUM 998"
  DBG ":---------------------------------------"
}

######################################################################
# appl_info: *col-18*a* APPLICATIONS
######################################################################
appl_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "APPL 001"

  #verbose_out "\n-=[ 18/${maxcoll} APPL-Info ]=-\n"
  paragraph "APPLICATIONS"
  inc_heading_level

  AddText "Comming soon..."

 #exec_command "<cmd>" "<text>"

 # ToDo: ...APACHE... # §AW061§
  http_srv=$(lslpp -l | grep -i http >/dev/null 2>&1)
  http_rc=$?
  #ERRMSG "HTTP_SRV RC=${http_rc}"
  if [[ $http_rc = 0 ]]
  then
    ERRMSG "\nC2H000I HTTP Server (Apache) package found"
    wx=$(which apachectl >/dev/null 2>&1)
    which_rc=$?
    if [[ $which_rc = 0 ]]
    then
      #exec_command "apachectl status" "HTTP Server status"
      AWTRACE ": HTTP Server apachectl ${http_srv} wx=${wx}"
    fi
  fi

 # ToDo: ...SAMBA... # §AW062§
  smb_srv=$(lslpp -l | grep -i samba >/dev/null 2>&1)
  smb_rc=$?
  #ERRMSG "SMB_SRV RC=${smb_rc}"
  if [[ $smb_rc = 0 ]]
  then
    ERRMSG "\nC2H000I SAMBA package found"
    wx=$(which swat >/dev/null 2>&1)
    which_rc=$?
    if [[ $which_rc = 0 ]]
    then
      AWTRACE ": SAMBA swat ${smb_srv} wx=${wx}"
    fi
  fi
  dec_heading_level
  DBG "APPL 998"
}

######################################################################
# enh_info: *col-19*e* ENHANCEMENTS
######################################################################
enh_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "ENH 001"

  #verbose_out "\n-=[ 19/${maxcoll} ENH-Info ]=-\n"
  paragraph "ENHANCEMENTS"
  inc_heading_level

 #exec_command "<cmd>" "<text>"
  AddText "Comming soon..."

  dec_heading_level
  DBG "ENH 998"
}

######################################################################
# Exp_info: *col-20*E* EXPERIMENTAL
######################################################################
Exp_info ()
{
  DEBUG=1  # debugging 0=OFF 1=ON
  DBG ":---------------------------------------"
  DBG "EXP 001"

  #verbose_out "\n-=[ 20/${maxcoll} EXP-Info ]=-\n"
  paragraph "EXPERIMENTAL"
  inc_heading_level

#++ §AW050§ start *PLUGIN*---------------------------------------------
  echo "\n== PLUGIN 0 =="
  if [[ -f $PLUGINS/c2h_plugin_0 ]]
  then
    if [[ -x $PLUGINS/c2h_plugin_0 ]]
    then
      AWTRACE "AW: Plugin 'c2h_plugin_0' has EXECUTE Bit ON."
    fi
    AWTRACE "AW: START Plugin 'c2h_plugin_0'."
    exec_command $PLUGINS/c2h_plugin_0 "Plugin 0"
    AWTRACE "AW: END   Plugin 'c2h_plugin_0'."
  else
    AWTRACE "AW: Plugin 'c2h_plugin_0' NOT Found."
    verbose_out "C2H000W Plugin 'c2h_plugin_0' NOT Found."
  fi
#++ §AW050§ start *PLUGIN*---------------------------------------------

#++ §AW050§ start *SUMA*-----------------------------------------------
#------------------------------------------
# SUMA - Servie Update Management Assistant
# available with fileset bos.suma
# needs perl.rte and perl.libext
# AIX 5.3 Base
# AIX 5.2 ML 5 or higher (or APAR IYxxxxx)
# AIX 5.1 APAR IYxxxxx
# AIX 4.3 NOT AVAILABLE
#------------------------------------------
  echo "\n== SUMA =="
  SUMA="UNKNOWN"
  if [[ $OSVER3CHAR = "530" ]] # AIX 5.3 always contains SUMA
  then
    SUMA="YES"
  else
    # AIX 5.1/5.2 may contain SUMA if fileset is installed
    lslpp -lc | grep "bos.suma"
    if [[ $? = "0" ]]
    then
      SUMA="YES"
    else
      SUMA="NO"
    fi
  fi

  if [[ $SUMA = "YES" ]]
  then
    echo "C2H000I SUMA available"
    exec_command "suma -c" "SUMA Configuration"
    exec_command "suma -l" "SUMA Tasks"
  else
    echo "C2H000I SUMA NOT available"
    AddText "C2H000I SUMA NOT available"
  fi
#++ §AW050§ end *SUMA*-------------------------------------------------

#++ §AW051§ start *efix*-----------------------------------------------
#------------------------------------------
# efix - Interim fix management (former name emergency fix)
# AIX 5.3.0 Base
# AIX 5.2.0 APAR IY40236 + IY59422 (PTF U496643)
# AIX 5.1.0 APAR IY40088
# AIX 4.3.3 APAR IY41248
#------------------------------------------
  echo "\n== EFIX =="
  efix="UNKNOWN"
#   FIX=IY12345
#   instfix -ivk $FIX
#   if [[ $? -ne 0 ]]
#   then
#     echo "Instfix RC="$?" ==> FIX (${FIX}) NOT Installed !"
#   fi
  exec_command "emgr -l 2>&1" "Filesets locked by EFIX manager"
  exec_command "emgr -P 2>&1" "Filesets locked by EFIX manager"
#++ §AW051§ end *efix*-------------------------------------------------

#++ §AW052§ start *java*-----------------------------------------------
# ToDo: Do Java checkings as PLUGIN !!
#------------------------------------------
# JAVA
#
# UNSUPPORTED
# -----------
# AIX 4.3.3
#  1.1.8    END OF SERVICE 31 Dec 2003
#  1.2.2    END OF SERVICE 30 Apr 2004
# AIX 5.1.0
#  1.1.8    END OF SERVICE 31 Dec 2003
#  1.2.2    END OF SERVICE 30 Apr 2004
#  1.3.0    END OF SERVICE 31 Dec 2002
#  1.4.1-32 END OF SERVICE  1 Mar 2005
#  1.4.1-64 END OF SERVICE  1 Mar 2005
# AIX 5.2.0
#  1.2.2    END OF SERVICE 30 Apr 2004
#  1.4.1-32 END OF SERVICE  1 Mar 2005
#  1.4.1-64 END OF SERVICE  1 Mar 2005
# AIX 5.3.0
#  1.4.1-32 END OF SERVICE  1 Mar 2005
#  1.4.1-64 END OF SERVICE  1 Mar 2005
#
# SUPPORTED
# ---------
# AIX 5.1.0 ML03
#  1.3.1-32 ==> END OF SERVICE 30 Sep 2007
#  1.3.1-64 ==> END OF SERVICE 30 Sep 2007
# AIX 5.1.0 ML06
#  1.4.2-32 ==> END OF SERVICE 30 Sep 2009
#  1.4.2-64 ==> END OF SERVICE 30 Sep 2009
#
# AIX 5.2.0 ML01
#  1.3.1-32 ==> END OF SERVICE 30 Sep 2007
#  1.3.1-64 ==> END OF SERVICE 30 Sep 2007
# AIX 5.2.0 ML03
#  1.4.2-32 ==> END OF SERVICE 30 Sep 2009
#  1.4.2-64 ==> END OF SERVICE 30 Sep 2009
#
# AIX 5.3.0 + IY58143
#  1.3.1-32 ==> END OF SERVICE 30 Sep 2007
#  1.3.1-64 ==> END OF SERVICE 30 Sep 2007
#  1.4.2-32 ==> END OF SERVICE 30 Sep 2009
#  1.4.2-64 ==> END OF SERVICE 30 Sep 2009
#
# Java131.rte.bin
# ---------------
#  1.3.1.17-32 APAR IY65310 + IY52512 + IY49074 + IY30887
#
# Java131_64.rte.bin
# ------------------
#  1.3.1.9-32 APAR IY65310 + IY52512 + IY49074 + IY30887
#
# Java14.sdk
# ----------
#  1.4.2.5-32 APAR IY72469 + IY70052 + IY54663
#
# Java14_64.sdk
# -------------
#  1.4.2.5-64 APAR IY72502 + IY70332 + IY54664
#
# Java5
# -------------
#  5.0.0.0-64 APAR IYxxxxx + IYxxxxx
#
#------------------------------------------
  echo "\n== JAVA =="

# show installed Java Filesets
  exec_command "lslpp -lc | grep -i java13" " Java 1.3.x Filesets"
  exec_command "lslpp -lc | grep -i java14" " Java 1.4.x Filesets"
  exec_command "lslpp -lc | grep -i java5"  " Java 5.0.x Filesets"

#=============================
# UNSUPPORTED / END OF SERVICE
#=============================

 # Java 1.1.8 32-Bit
 #------------------
  JAVA_118_32="NO"
  echo "\n== Java 1.1.8 32-Bit=="
  java118=$(lslpp -l Java118.rte >/dev/null 2>&1)
  java118_rc=$?
  if [[ $java118_rc = 0 ]]
  then
    JAVA_118_32="YES"
    ERRMSG "C2H804W Note: You are running an unsupported version of Java. Consider installing a newer version !"
    ERRMSG "C2H805I Java 1.1.8 End of Service was 31 December 2003 !"
  fi

 # Java 1.2.2 32-Bit
 #------------------
  JAVA_122_32="NO"
  echo "\n== Java 1.2.2 32-Bit=="
  java122=$(lslpp -l Java122.rte >/dev/null 2>&1)
  java122_rc=$?
  if [[ $java122_rc = 0 ]]
  then
    JAVA_122_32="YES"
    ERRMSG "C2H804W Note: You are running an unsupported version of Java. Consider installing a newer version !"
    ERRMSG "C2H805I Java 1.2.2 End of Service was 30 April 2004 !"
  fi

 # Java 1.3.0 32-Bit
 #------------------
  JAVA_130_32="NO"
  echo "\n== Java 1.3.0 32-Bit=="
  java130=$(lslpp -l Java130.rte >/dev/null 2>&1)
  java130_rc=$?
  if [[ $java130_rc = 0 ]]
  then
    JAVA_130_32="YES"
    ERRMSG "C2H804W Note: You are running an unsupported version of Java. Consider installing a newer version !"
    ERRMSG "C2H805I Java 1.3.0 End of Service was 31 December 2002 !"
  fi

 # Java 1.4.1 32-Bit
 #------------------
  JAVA_141_32="NO"
  echo "\n== Java 1.4.1 32-Bit=="
  java141=$(lslpp -l Java141.rte >/dev/null 2>&1)
  java141_rc=$?
  if [[ $java141_rc = 0 ]]
  then
    JAVA_141_32="YES"
    ERRMSG "C2H804W Note: You are running an unsupported version of Java. Consider installing a newer version !"
    ERRMSG "C2H805I Java 1.4.1 End of Service was 1 March 2005 !"
  fi

 # Java 1.4.1 64-Bit
 #------------------
  JAVA_141_64="NO"
  echo "\n== Java 1.4.1 64-Bit=="
  java141_64=$(lslpp -l Java141_64.rte >/dev/null 2>&1)
  java141_64_rc=$?
  if [[ $java141_64_rc = 0 ]]
  then
    JAVA_141_64="YES"
    ERRMSG "C2H804W Note: You are running an unsupported version of Java. Consider installing a newer version !"
    ERRMSG "C2H805I Java 1.4.1 End of Service was 1 March 2005 !"
  fi

#==========
# SUPPORTED
#==========

 # Java 1.3.1 32-Bit
 #------------------
  JAVA_131_32="NO"
  echo "\n== Java 1.3.1 32-Bit=="
  java131_32=$(lslpp -l Java131.rte >/dev/null 2>&1)
  java131_32_rc=$?
  if [[ $java131_32_rc = 0 ]]
  then
    JAVA_131_32="YES"
  fi

  if [[ "$JAVA_131_32" = "YES" ]]
  then
    echo "C2H802W Note: You are running an old version of Java. Consider installing Java 1.4 !"
  fi
  if [[ "$BIT64" = "YES" ]]
  then
    echo "C2H803W Note: You are running a 64-Bit Kernel. Consider installing 64-Bit Java !"
  fi

 # Java 1.3.1 64-Bit
 #------------------
  JAVA_131_64="NO"
  echo "\n== Java 1.3.1 64-Bit=="
    if [[ "$JAVA_131_64" = "YES" ]]
    then
      echo "C2H802W Note: You are running an old version of Java. Consider installing Java 1.4 !"
    fi

 # Java 1.4.2 32-Bit
 #------------------
  JAVA_142_32="NO"
  echo "\n== Java 1.4.2 32-Bit=="
  java142_32=$(lslpp -l Java14.sdk >/dev/null 2>&1)
  java142_32_rc=$?
  if [[ $java142_32_rc = 0 ]]
  then
    JAVA_142_32="YES"
  fi

  FIX=IY54663 # Java 1.4.2 32-Bit Base
  instfix -ivk $FIX 2>&1 | grep -v "not applied"
  rc=$?
  echo " "
  if [[ $rc -ne 0 ]]
  then
    echo "Instfix RC="$?" ==> FIX (${FIX}) NOT Installed !"
  else
    JAVA_142_32="YES"
    if [[ "$BIT64" = "YES" ]]
    then
      echo "C2H803W Note: You are running a 64-Bit Kernel. Consider installing 64-Bit Java !"
    fi
  fi

  FIX=IY70052 # Java 1.4.2 32-Bit Update
  instfix -ivk $FIX 2>&1 | grep -v "not applied"
  rc=$?
  echo " "
  if [[ $rc -ne 0 ]]
  then
    echo "Instfix RC="$?" ==> FIX (${FIX}) NOT Installed !"
  else
    JAVA_142_32="YES"
    if [[ "$BIT64" = "YES" ]]
    then
      echo "C2H803W Note: You are running a 64-Bit Kernel. Consider installing 64-Bit Java !"
    fi
  fi

  FIX=IY72469 # Java 1.4.2 32-Bit Update SR2
  instfix -ivk $FIX 2>&1 | grep -v "not applied"
  rc=$?
  echo " "
  if [[ $rc -ne 0 ]]
  then
    echo "Instfix RC="$?" ==> FIX (${FIX}) NOT Installed !"
  else
    JAVA_142_32="YES"
    if [[ "$BIT64" = "YES" ]]
    then
      echo "C2H803W Note: You are running a 64-Bit Kernel. Consider installing 64-Bit Java !"
    fi
  fi

  FIX=IY75003 # Java 1.4.2 32-Bit Update SR3
  instfix -ivk $FIX 2>&1 | grep -v "not applied"
  rc=$?
  echo " "
  if [[ $rc -ne 0 ]]
  then
    echo "Instfix RC="$?" ==> FIX (${FIX}) NOT Installed !"
  else
    JAVA_142_32="YES"
    if [[ "$BIT64" = "YES" ]]
    then
      echo "C2H803W Note: You are running a 64-Bit Kernel. Consider installing 64-Bit Java !"
    fi
  fi

 # Java 1.4.2 64-Bit
 #------------------
  JAVA_142_64="NO"
  echo "\n== Java 1.4.2 64-Bit=="
  java142_64=$(lslpp -l Java14_64.sdk >/dev/null 2>&1)
  java142_64_rc=$?
  if [[ $java142_64_rc = 0 ]]
  then
    JAVA_142_64="YES"
  fi

  if [[ "$BIT64" = "YES" ]]
  then
    echo "\n== Java 1.4.2 64-Bit =="

    FIX=IY54664 # Java 1.4.2 64-Bit Base
    instfix -ivk $FIX 2>&1 | grep -v "not applied"
    rc=$?
    echo " "
    if [[ $rc -ne 0 ]]
    then
      echo "Instfix RC="$?" ==> FIX (${FIX}) NOT Installed !"
    fi

    FIX=IY70332 # Java 1.4.2 64-Bit Update
    instfix -ivk $FIX 2>&1 | grep -v "not applied"
    rc=$?
    echo " "
    if [[ $rc -ne 0 ]]
    then
      echo "Instfix RC="$?" ==> FIX (${FIX}) NOT Installed !"
    fi

    FIX=IY72502 # Java 1.4.2 64-Bit Update SR2
    instfix -ivk $FIX 2>&1 | grep -v "not applied"
    rc=$?
    echo " "
    if [[ $rc -ne 0 ]]
    then
      echo "Instfix RC="$?" ==> FIX (${FIX}) NOT Installed !"
    fi

    FIX=IY75004 # Java 1.4.2 64-Bit Update 1.4.2.20 SR3
    instfix -ivk $FIX 2>&1 | grep -v "not applied"
    rc=$?
    echo " "
    if [[ $rc -ne 0 ]]
    then
      echo "Instfix RC="$?" ==> FIX (${FIX}) NOT Installed !"
    fi

  fi  # 64


 # Java 5.0.0 64-Bit
 #------------------
  JAVA_500_64="NO"
  echo "\n== Java 5.0.0 64-Bit=="
  java5_64=$(lslpp -l Java5_64.sdk >/dev/null 2>&1)
  java5_64_rc=$?
  if [[ $java5_64_rc = 0 ]]
  then
    JAVA_500_64="YES"
  fi

  if [[ "$JAVA_500_64" = "YES" ]]
  then
    echo "\n== Java 5.0.0 64-Bit =="
  fi  # Java_500_64

# Check if 32+64 => Only ONE is needed
# ------------------------------------
 if [[ "$JAVA_131_32" = "YES" && "$JAVA_131_64" = "YES" ]]
 then
   echo "C2H804W Note: You are running a 32-Bit AND 64-Bit version of the same Java release. Consider de-installing 32-Bit Java !"
 fi # 131-32+64

 if [[ "$JAVA_142_32" = "YES" && "$JAVA_142_64" = "YES" ]]
 then
   echo "C2H804W Note: You are running a 32-Bit AND 64-Bit version of the same Java release. Consider de-installing 32-Bit Java !"
 fi # 142-32+64

# show exact Java version
# -----------------------
  exec_command "java -version 2>&1" "Java"
  exec_command "java -fullversion 2>&1" "Java (fullversion)"

  AWTRACE ": JAVA_130_32=${JAVA_130_32}"  # OUTDATED
  AWTRACE ": JAVA_131_32=${JAVA_131_32}"  # OK
  AWTRACE ": JAVA_131_64=${JAVA_131_64}"  #
  AWTRACE ": JAVA_141_32=${JAVA_141_32}"  # OUTDATED
  AWTRACE ": JAVA_142_32=${JAVA_142_32}"  # OK
  AWTRACE ": JAVA_142_64=${JAVA_142_64}"  # OK

#++ §AW052§ end *java*-------------------------------------------------

#++ §AW053§ start *WLM*------------------------------------------------
  echo "\n== WLM =="
  exec_command "wlmstat 2>&1" "WLM Workload Manager"
#++ §AW053§ end *WLM*--------------------------------------------------

#++ §AW054§ start *smtctl*---------------------------------------------
  if [[ $OSVER3CHAR = "530" ]]
  then
    if [[ $POWER5 = "YES" ]]
    then
      exec_command "smtctl" "SMT Simultaneous Multi-Threading"
    else
# ToDo: call HTML_Titel
      AddText "SMT available on Power5 only"
    fi
  fi
#++ §AW054§ end *smtctl*-----------------------------------------------

#++ §AW055§ start *cpupstat*-------------------------------------------
  echo "\n== 5.3 =="
  if [[ $OSVER3CHAR = "530" ]]
  then
    exec_command "cpupstat -vi 0" "CPUPSTAT"
  fi
#++ §AW055§ end *cpupstat*---------------------------------------------

#++ §AW056§ start *mpstat*---------------------------------------------
  if [[ $OSVER3CHAR = "530" ]]
  then
    exec_command "mpstat" "MPSTAT"
  fi
#++ §AW056§ end *mpstat*-----------------------------------------------

#++ §AW057§ start *lparstat*-------------------------------------------
  if [[ $OSVER3CHAR = "530" ]]
  then
    exec_command "lparstat" "LPARSTAT"
  fi
#++ §AW057§ end *lparstat*---------------------------------------------

#++ §AW058§ start *lsslot*--------------------------------------------
  echo "\n== lsslot =="
  exec_command "lsslot -c pci"    "List all PCI hot plug slots"
  exec_command "lsslot -c pci -a" "List all available PCI hot plug slots"
  exec_command "lsslot -c phb"    "List all assigned PCI Host Bridges"
  exec_command "lsslot -c phb -a" "List all available PCI Host Bridges"
#++ §AW058§ end *lparstat*---------------------------------------------


#++ §AW059§ start *aio*-----------------------------------------------
  echo "\n== aio =="
  exec_command "lsattr -El aio0"    "ASYNC I/O"
  exec_command "lsattr -Rl aio0 -a minservers"    "ASYNC I/O minservers"
  exec_command "lsattr -Rl aio0 -a maxservers"    "ASYNC I/O maxservers"
# ToDo: ps -ef | grep aioserver !! But show aio here !!
  exec_command "ps -ef | grep aioserver" "List aioserver Processes"
#++ §AW059§ end *aio*-------------------------------------------------


#++ §AW060§ start *sdd*-----------------------------------------------
  echo "\n== sdd =="

  exec_command "lslpp -lc | grep mpio"    "SDD: lslpp mpio"
  exec_command "lslpp -lc | grep .sdd"    "SDD: lslpp .sdd"
  exec_command "lslpp -lc | grep 2105"    "SDD: lslpp 2105"
  exec_command "lslpp -lc | grep essutil" "SDD: lslpp essutil"
  exec_command "lslpp -lc | grep inmcim"  "SDD: lslpp ibmcim"

  sdd_old=$(lslpp -l | grep devices.sdd. >/dev/null 2>&1)
  sdd_rc=$?
  if [[ $sdd_rc = 0 ]]
  then
    ERRMSG "You are using SDD [ ${sdd_old} ]"
    exec_command "datapath query adapter"    "SDD: q adapter"
    exec_command "datapath query wwpn"       "SDD: q wwpn"
    exec_command "datapath query adaptstats" "SDD: q adaptstats"
    exec_command "datapath query portmap"    "SDD: q portmap"
    exec_command "datapath query essmap"     "SDD: q essmap"
    exec_command "datapath query device"     "SDD: q device"
    exec_command "datapath query devstats"   "SDD: q devstats"
  else
    AWTRACE ": SDD sdd_rc=${sdd_rc} sdd_old=${sdd_old}"
  fi

  sdd_pcm=$(lslpp -l | grep devices.sddpcm. >/dev/null 2>&1)
  pcm_rc=$?
  if [[ $pcm_rc = 0 ]]
  then
    ERRMSG "You are using SDDPCM [ ${sdd_pcm} ]"
    exec_command "pcmpath query adapter"    "SDD: q adapter"
    exec_command "pcmpath query wwpn"       "SDD: q wwpn"
    exec_command "pcmpath query adaptstats" "SDD: q adaptstats"
    exec_command "pcmpath query portmap"    "SDD: q portmap"
    exec_command "pcmpath query essmap"     "SDD: q essmap"
    exec_command "pcmpath query device"     "SDD: q device"
    exec_command "pcmpath query devstats"   "SDD: q devstats"
  else
    AWTRACE ": SDDPCM pcm_rc=${pcm_rc} sdd_pcm=${sdd_pcm}"
  fi

# Only "SDD" OR "SDDPCM" possible. Not BOTH !

    exec_command "datapath query adapter"    "SDD: q adapter"
    exec_command "pcmpath query adapter"    "SDD: q adapter"
    exec_command "lsess"    "ESS: lsess"
    exec_command "ls2105"   "ESS: ls2105"
    exec_command "lssdd"    "ESS: lssdd"
    if [ -f /usr/bin/lsvp ];
    then 
    	exec_command "lsvp -a"  "ESS: lsvp -a"
    	exec_command "lsvp -d"  "ESS: lsvp -d"
    fi
# Note: *SDDPCM* 2105=ESS / 1750=DS6000 / 2107=DS8000
#       *SDD*    2105=ESS / 2105F=ESS F models / 2105800=ESS 800 model
#       *SDD*    2145=SVC / 2062=SVCCISCO

#++ §AW060§ end *sdd*-------------------------------------------------

#++ §AW000§ start *vmo,ioo*-------------------------------------------
  vmo_ioo="NO"
  if [[ $OSVER3CHAR = "520" ]]
  then
    vmo_ioo="YES"
  fi
  if [[ $OSVER3CHAR = "530" ]]
  then
    vmo_ioo="YES"
  fi
  if [[ $vmo_ioo = "YES" ]]
  then
    echo "\n== vmo =="
    exec_command "vmo -a"   "vmo: vmo -a"
    exec_command "vmo -ra"  "vmo: vmo -ra"
    exec_command "vmo -pa"  "vmo: vmo -pa"
    exec_command "vmo -L"   "vmo: vmo -L"
    echo "\n== ioo =="
    exec_command "ioo -a"   "ioo: ioo -a"
    exec_command "ioo -ra"  "ioo: ioo -ra"
    exec_command "ioo -pa"  "ioo: ioo -pa"
    exec_command "ioo -L"  "ioo: ioo -L"
  fi
#++ §AW000§ end *vmo,ioo*---------------------------------------------

  dec_heading_level
  writeTF # §AW309§ BUG: write temp output to final file
  DBG "EXP 998"
  DBG ":---------------------------------------"
}
######################################################################
# hpo_info: *col-21*O* HPOpenView
######################################################################
hpo_info ()
{
  DEBUG=0  # debugging 0=OFF 1=ON
  DBG "HPO 001"

  #verbose_out "\n-=[ 21/${maxcoll} HPO-Info ]=-\n"
  paragraph "HP OpenView"
  inc_heading_level

  hpo=$(lslpp -l | grep -i OPC >/dev/null 2>&1)
  hpo_rc=$?
  if [[ $hpo_rc = 0 ]]
  then
#++ §CP001§ start *HP OpenView*---------------------------------------
    exec_command "lslpp -L |grep -i OPC" "Installierte HP OpenView Version"
    OPCINFO=$(lslpp -f OPC.obj | grep opcinfo)
    exec_command "cat $OPCINFO" "OPCINFO"
    OPCDCODE=$(lslpp -f OPC.obj | grep opcdcode)
    exec_command "$OPCDCODE /var/lpp/OV/conf/OpC/monitor | grep DESCRIPTION" "HP OpenView Configuration MONITOR"
    exec_command "$OPCDCODE /var/lpp/OV/conf/OpC/le | grep DESCRIPTION" "HP OpenView Configuration LOGGING"
#++ §CP001§ end *HP OpenView*-----------------------------------------
  else
    AWTRACE ": HPO hpo_rc=${hpo_rc}"
  fi

  dec_heading_level
  DBG "HPO 998"
}

######################################################################
# run_collection: ...
######################################################################
run_collection ()
{
  DEBUG=0  # debugging 0=OFF 1=ON

   #echo "\n-=[ Run-Collection ]=-\n"

# *col-01* System Information
#----------------------------

 if [ "$CFG_SYSTEM" = "yes" ] # *col-01*
 then
   DEBUG=0
   DBG "SYSTEM 000"
   sys_info      # *col-01*
   DBG "SYSTEM 999"
 else
   verbose_out "skipping SYSTEM   (CFG_SYSTEM=${CFG_SYSTEM})"
 fi # terminates CFG_SYSTEM wrapper

# *col-02* Kernel Information
#----------------------------

 if [ "$CFG_KERNEL" = "yes" ] # *col-02*
 then
   DEBUG=0
   DBG "KERNEL 000"
   kernel_info   # *col-02*
   DBG "KERNEL 999"
 else
   verbose_out "skipping KERNEL   (CFG_KERNEL=${CFG_KERNEL})"
 fi # terminates CFG_KERNEL wrapper

# *col-03* Hardware Information
#------------------------------

 if [ "$CFG_HARDWARE" = "yes" ] # *col-03*
 then
   DEBUG=0
   DBG "HARDWARE 000"
   hw_info # *col-03*
   DBG "HARDWARE 999"
 else
   verbose_out "skipping HARDWARE (CFG_HARDWARE=${CFG_HARDWARE})"
 fi # terminates CFG_HARDWARE wrapper

# *col-04* Filesystem Information
#--------------------------------

 if [ "$CFG_FILESYS" = "yes" ] # *col-04*
 then
   DEBUG=0
   DBG "FILESYS 000"
   filesys_info # *col-04*
   DBG "FILESYS 000"
 else
   verbose_out "skipping FILESYS  (CFG_FILESYS=${CFG_FILESYS})"
 fi # terminates CFG_FILESYS wrapper

# *col-22 HACMP
#---------------------------------
                                                                                
if [ "$CFG_HACMP" != "no" ]                                                     
then                                                                            
   paragraph "HACMP"                                                            
   inc_heading_level                                                            
   if [ -d /usr/sbin/cluster/utilities ];
   then                                                                         
   	exec_command "/usr/sbin/cluster/utilities/cllsclstr"                   
   	exec_command "/usr/sbin/cluster/utilities/cllscf"                       
   	exec_command "/usr/sbin/cluster/utilities/cllsserv"                     
   	exec_command "/usr/sbin/cluster/utilities/cllsnode"                     
   	exec_command "/usr/sbin/cluster/utilities/cllsnode"                     
   	for i in `/usr/sbin/cluster/utilities/cllsnode | grep NODE | sed s/://g |awk '{print $2}'`;
    	do echo This is the Resource Group information for node $i;                 
        	 exec_command "/usr/sbin/cluster/utilities/clshowres -n $i;"    
        done                                                                    
   fi                                                                             
   dec_heading_level                                                            
fi      # terminate CFG_HACMP wrapper                                           

# *col-05 Disk (Device) Information
#----------------------------------

 if [ "$CFG_DISKS" = "yes" ] # *col-05*
 then
   DEBUG=0
   DBG "DISKS 000"
   disk_info # *col-05*
   DBG "DISKS 999"
 else
   verbose_out "skipping DISKS    (CFG_DISKS=${CFG_DISKS})"
 fi # terminates CFG_DISKS wrapper
 # EMC disk Information Kaiser
 if [ ! -f /usr/lpp/Symmetrix/bin/inq ]  ;                                   
 then                                                                        
     exec_command "/usr/lpp/Symmetrix/bin/inq" "EMC Disks"                  
 fi                                                                          
 if [ ! -f /usr/sbin/powermt ] ;                                             
 then                                                                        
     exec_command "/usr/sbin/powermt display dev=all" "EMC Disk Status"     
 fi                                                                          

# *col-06 Logical Volume Manager Information
#-------------------------------------------

 if [ "$CFG_LVM" = "yes" ] # *col-06*
 then
   DEBUG=0
   DBG "LVM 000"
   lvm_info # *col-06*
   DBG "LVM 999"
 else
   verbose_out "skipping LVM      (CFG_LVM=${CFG_LVM})"
 fi # terminates CFG_LVM wrapper

# *col-07 User & Group Information
#---------------------------------

 if [ "$CFG_USERS" = "yes" ] # *col-07*
 then
   DEBUG=0
   DBG "USERS 000"
   user_info # *col-07*
   DBG "USERS 999"
 else
   verbose_out "skipping USERS    (CFG_USERS=${CFG_USERS})"
 fi # terminates CFG_USERS wrapper

# *col-08 Network Information
#----------------------------

 if [ "$CFG_NETWORK" = "yes" ] # *col-08*
 then
   DEBUG=0
   DBG "NETWORK 000"
   network_info # *col-08*
   DBG "NETWORK 999"
 else
   verbose_out "skipping NETWORK  (CFG_NETWORK=${CFG_NETWORK})"
 fi # terminate CFG_NETWORK wrapper

# *col-09 Printer Information
#----------------------------

 if [ "$CFG_PRINTER" = "yes" ] # *col-09*
 then
   DEBUG=0
   DBG "PRINTER 000"
   printer_info # *col-09*
   DBG "PRINTER 999"
 else
   verbose_out "skipping PRINTER  (CFG_LVM=${CFG_PRINTER})"
 fi # terminate CFG_PRINTER wrapper

# *col-10 Quota Information
#--------------------------

 if [ "$CFG_QUOTA" = "yes" ] # *col-10*
 then
   DEBUG=0
   DBG "QUOTA 000"
   #quota_info # *col-10*
   DBG "QUOTA 999"
 else
   verbose_out "skipping QUOTA    (CFG_LVM=${CFG_QUOTA})"
 fi # terminate CFG_QUOTA wrapper

# *col-11 Defragmentation Information
#------------------------------------

 if [ "$CFG_DEFRAG" = "yes" ] # *col-11*
 then
   DEBUG=0
   DBG "DEFRAG 000"
   defrag_info # *col-11*
   DBG "DEFRAG 999"
 else
   verbose_out "skipping QUOTA    (CFG_QUOTA=${CFG_QUOTA})"
 fi # terminate CFG_DEFRAG wrapper

# *col-12 Cron Information
#-------------------------

 if [ "$CFG_CRON" = "yes" ] # *col-12*
 then
   DEBUG=0
   DBG "CRON 000"
   cron_info # *col-12*
   DBG "CRON 999"
 else
   verbose_out "skipping CRON     (CFG_CRON=${CFG_CRON})"
 fi # terminate CFG_CRON wrapper

# *col-13 Password & Group Information
#-------------------------------------

 if [ "$CFG_PASSWD" = "yes" ] # *col-13*
 then
   DEBUG=0
   DBG "PASSWD 000"
   #passwd_info # *col-13*
   DBG "PASSWD 999"
 else
   verbose_out "skipping PASSWD   (CFG_PASSWD=${CFG_PASSWD})"
 fi # terminate CFG_PASSWD wrapper

# *col-14 Software Statistics (Patch)
#------------------------------------

 if [ "$CFG_SOFTWARE" = "yes" ] # *col-14*
 then
   DEBUG=0
   DBG "SOFTWARE 000"
   software_info # *col-14*
   DBG "SOFTWARE 999"
 else
   verbose_out "skipping SOFTWARE (CFG_SOFTWARE=${CFG_SOFTWARE})"
 fi # terminates CFG_SOFTWARE wrapper

# *col-15 Files Statistics
#-------------------------

 if [ "$CFG_FILES" = "yes" ] # *col-15*
 then
   DEBUG=0
   DBG "FILES 000"
   filestat_info # *col-15*
   DBG "FILES 999"
 else
   verbose_out "skipping FILES    (CFG_FILES=${CFG_FILES})"
 fi # terminates CFG_FILES wrapper

# *col-16 NIM Configuration
#--------------------------

 if [ "$CFG_NIM" = "yes" ] # *col-16*
 then
   DEBUG=0
   DBG ":#######################################"
   DBG "NIM 000"
   #nim_info  # *col-16*
   exec_command "lsnim -l" "Display information about NIM"
   DBG "NIM 999"
   DBG ":#######################################"
 else
   verbose_out "skipping NIM      (CFG_NIM=${CFG_NIM})"
 fi # terminates CFG_NIM wrapper

# *col-17 LUM License Configuration
#----------------------------------

 if [ "$CFG_LUM" = "yes" ] # *col-17*
 then
   DEBUG=0
   DBG ":#######################################"
   DBG "LUM 000"
   lum_info # *col-17*
   DBG "LUM 999"
   DBG ":#######################################"
 else
   verbose_out "skipping LUM      (CFG_LUM=${CFG_LUM})"
 fi # terminates CFG_LUM wrapper

# *col-18 APPLICATIONS
#---------------------

 if [ "$CFG_APPL" = "yes" ] # *col-18*
 then
   DEBUG=0
   DBG "APPL 000"
   #appl_info # *col-18*
   DBG "APPL 999"
 else
   verbose_out "skipping APPL     (CFG_APPL=${CFG_APPL})"
 fi # terminates CFG_APPL wrapper

# *col-19 ENHANCEMENTS
#---------------------

 if [ "$CFG_ENH" = "yes" ] # *col-19*
 then
   DEBUG=0
   DBG "ENH 000"
   #enh_info # *col-19*
   DBG "ENH 999"
 else
   verbose_out "skipping ENH      (CFG_ENH=${CFG_ENH})"
 fi # terminates CFG_ENH wrapper

# *col-20 EXPERIMENTAL
#---------------------

 if [ "$CFG_EXP" = "yes" ] # *col-20*
 then
   DEBUG=0
   DBG "EXP 000"
   #Exp_info # *col-20*
   DBG "EXP 999"
 else
   verbose_out "skipping EXP      (CFG_EXP=${CFG_EXP})"
 fi # terminates CFG_EXP wrapper

# *col-21 HP OpenView
#--------------------

 if [ "$CFG_HPO" = "yes" ] # *col-21*
 then
   DEBUG=0
   DBG "HPO 000"
   #hpo_info # *col-21*
   DBG "HPO 999"
 else
   verbose_out "skipping HPO     (CFG_HPO=${CFG_HPO})"
 fi # terminates CFG_HPO wrapper

}

######################################################################
# Handle_SIGINT: SIGINT 2 ctrl-c
######################################################################
Handle_SIGINT ()
{

  sig_type="SIGINT (2) ctrl-c"

  HandleInterrupt

}

######################################################################
# Handle_SIGINT: SIGTSTP ?? ctrl-z
######################################################################
Handle_SIGTSTP ()
{

  sig_type="SIGTSTP (??) ctrl-z"

  HandleInterrupt

}

######################################################################
# Handle_SIGTERM: SIGTERM 15 kill
######################################################################
Handle_SIGTERM ()
{

  sig_type="SIGTERM (15) kill"

  HandleInterrupt

}

######################################################################
# HandleInterrupt: ...
######################################################################
HandleInterrupt ()
{

 ERRMSG "\nC2H900S PROGRAM INTERRUPTED by ${sig_type}! \n"

# cleanup

 xexit 1 # §AW018§
}

######################################################################
# dummy: ...
######################################################################
dummy ()
{
  DEBUG=0  # debugging 0=OFF 1=ON

  #echo "\n-=[ DUMMY ]=-\n"
}

#::::::::::::::::::::::::::::::::::::::::::::::
# ... execution starts here ...
#::::::::::::::::::::::::::::::::::::::::::::::

# §AW017§ define trap (see /usr/include/sys/signal.h)
# trap 2=SIGINT / 13=SIGPIPE / 15=SIGTERM / 18=SIGTSTP
 trap " "               HUP
 trap "Handle_SIGINT"   2  # ctrl-c
#trap "Handle_SIGPIPE  13  # ??
 trap "Handle_SIGTERM" 15  # kill
#trap "Handle_SIGTSTP" 18  # ctrl-z

 PROCID=$$

 typeset -i HEADL=0     # Headinglevel

 InitVars         # initialize variables

# check options
#--------------
 EXTENDED=0
 VERBOSE=0
 YESNO="no"

 C2H_CMDLINE=$*  # used for later  §AW021§
# §AW308§ BUG: lower "f" missing in getopts list
 while getopts ":^aCdDeEfFhHKlLnNo:OpPQsSUvVxXyY012:" Option
 do
    case $Option in
       "^" ) YESNO="yes"   ;
         CFG_APPL="no"     ; # a   *col-18*  1
         CFG_CRON="no"     ; # C   *col-12*  2
         CFG_DEFRAG="no"   ; # d   *col-11*  3  §AW030§ => to be DELETED
         CFG_DISKS="no"    ; # D   *col-05*  4
         CFG_ENH="no"      ; # e   *col-19*  .
         CFG_EXP="no"      ; # E   *col-20*  .
         CFG_FILES="no"    ; # f   *col-15*  5
         CFG_FILESYS="no"  ; # F   *col-04*  6
         CFG_HARDWARE="no" ; # H   *col-03*  7
         CFG_HACMP="no"    ; # o   *col-22*  22  Kaiser
         CFG_KERNEL="no"   ; # K   *col-02*  8
         CFG_LUM="no"      ; # l   *col-17*  9
         CFG_LVM="no"      ; # L   *col-06* 10
         CFG_NIM="no"      ; # n   *col-16* 11
         CFG_NETWORK="no"  ; # N   *col-08* 12
         CFG_HPO="no"      ; # O   *col-21* 21  §CP001§
         CFG_PASSWD="no"   ; # p   *col-13* 13  §AW029§ => to be DELETED
         CFG_PRINTER="no"  ; # P   *col-09* 14
         CFG_QUOTA="no"    ; # Q   *col-10* 15  §AW028§ => to be DELETED
         CFG_SOFTWARE="no" ; # s   *col-14* 16
         CFG_SYSTEM="no"   ; # S   *col-01* 17
         CFG_USERS="no"    ; # U   *col-07* 18
         ;;
       a   ) CFG_APPL=$YESNO     ;; # *col-18* Applications (e.g. SAMBA)
       C   ) CFG_CRON=$YESNO     ;; # *col-12* Cron(tab)
       d   ) CFG_DEFRAG=$YESNO   ;; # *col-11* Defragfs # §AW030§ => to be DELETED
       D   ) CFG_DISKS=$YESNO    ;; # *col-05* Disks
       e   ) CFG_ENH=$YESNO      ;; # *col-19* Enhancements (e.g. ?)
       E   ) CFG_EXP=$YESNO      ;; # *col-20* Experimental (for developer use)
       f   ) CFG_FILES=$YESNO    ;; # *col-15* List various files
       F   ) CFG_FILESYS=$YESNO  ;; # *col-04* File System Info
       H   ) CFG_HARDWARE=$YESNO ;; # *col-03* Hardware Info
       K   ) CFG_KERNEL=$YESNO   ;; # *col-02* Kernel Info
       l   ) CFG_LUM=$YESNO      ;; # *col-17* License Use Manager
       L   ) CFG_LVM=$YESNO      ;; # *col-06* Logical Volume Manager
       n   ) CFG_NIM=$YESNO      ;; # *col-16* Network Installation Management
       N   ) CFG_NETWORK=$YESNO  ;; # *col-08* Network Info
       p   ) CFG_PASSWD=$YESNO   ;; # *col-13* passwd / group etc. §AW029§ => to be DELETED
       O   ) CFG_HPO=$YESNO      ;; # *col-21* HP OpenView §CP001§
       o   ) CFG_HACMP=$YESNO	 ;; # *col-22* Kaiser
       P   ) CFG_PRINTER=$YESNO  ;; # *col-09* Printer(s)
       Q   ) CFG_QUOTA=$YESNO    ;; # *col-10* Disk quota          §AW028§ => to be DELETED
       s   ) CFG_SOFTWARE=$YESNO ;; # *col-14* Installed Software
       S   ) CFG_SYSTEM=$YESNO   ;; # *col-01* System Information
       U   ) CFG_USERS=$YESNO    ;; # *col-07* User Information
       2   ) C2H_DATE="_"$(date +$OPTARG) ;;           # §AW022§
       1   ) C2H_DATE="_"$(date +%d-%b-%Y) ;;          # §AW022§
       0   ) C2H_DATE="_"$(date +%d-%b-%Y-%H%M) ;;     # §AW022§
       h   ) usage; xexit         ;; #   Usage # §AW018§
       o   ) OUTDIR=$OPTARG       ;; #   -o OUTDIR §AW020§
       v|V ) echo $VERSION; xexit ;; #   Print version # §AW018§
       x|X ) EXTENDED=1  ;; # Extra Information
       y|Y ) VERBOSE=1   ;; # show more Info on screen
       *   ) echo "Unimplemented option (${Option}) chosen! OPTARG=${OPTARG}"; usage; xexit 1 ;; # §AW018§
    esac
 done

 shift $(($OPTIND - 1))
# Decrements the argument pointer so it points to next argument.

 if (( EXTENDED == 0 )); then     # parameter  -x not used, so give info about it
    echo "\n  >> Use option '$(tput rev)[-x]$(tput sgr0)' for 'Extended' output <<$(tput bel)\n"
 else
    echo "\n  WARNING: -x for 'Extended' output currently NOT fully tested ! USE ON YOUR OWN RISK ! \n"
 fi

 set ''  # clear vars $1, $2 and so on...; or they will be missinterpreted....

 exec 2> $ERROR_LOG  # send all error messages to ERROR_LOG file

 Init_Part2

 check_basic_req  # check for some basic requirements...

######################################################################
######################################################################
# Main programm which calls above functions with their parameters
######################################################################
#######################  M A I N  ####################################
######################################################################

 line
 echo "Starting........: "$VERSION" on an ${SYSTEM} box"
 echo "Path to Cfg2Html: "$0
 echo "Path to plugins.: "$PLUGINS
 echo "Node............: "$NODE
 echo "SysModel........: "$SysModel
 echo "OSLevel.........: "$OSLEVEL_R
 echo "User............: "$USER
 echo "ProcessID.......: "$PROCID
 echo "HTML Output File: "$PWD/$HTML_OUTFILE
 echo "Text Output File: "$PWD/$TEXT_OUTFILE
 echo "Errors logged to: "$PWD/$ERROR_LOG
 echo "Started at......: "$DATEFULL
 echo "Commandline used: "$C2H_CMDLINE  # §AW021§
 echo "Problem         : If Cfg2Html hangs on Hardware, press twice ENTER"
 echo "                  or Ctrl-D. Then check or update your Diagnostics!"
 echo "WARNING.........: USE AT YOUR OWN RISK!!! :-))"
 echo "License.........: Freeware"
 line

# logger "Start of $VERSION"

 open_html
 inc_heading_level

 run_collection

 dec_heading_level
if [ `hostname -s` = "ktazd216" ]           
then                                        
        exit                                
fi                                          
{ echo "open ktazd216.crdc.kp.org           
user incoming kaiser                        
hash                                        
cd /var/adm/cfg                             
pwd                                         
site chmod 666 ${BASEFILE}.html
put ${BASEFILE}.html                           
site chmod 666 ${BASEFILE}.html                
close"                                      
} | ftp -i -n -v 2>&1 | tee /tmp/ftplog     
if [ `hostname -s` = "ktazd216" ]         
then                                      
        exit                              
fi                                        
{ echo "open ktazd216.crdc.kp.org         
user incoming kaiser                      
hash                                      
cd /var/adm/cfg/text                           
lcd /var/adm/cfg
pwd                                       
site chmod 666 ${BASEFILE}.txt              
put ${BASEFILE}.txt                         
site chmod 666 ${BASEFILE}.txt              
close"                                    
} | ftp -i -n -v 2>&1 | tee /tmp/ftplog2   
# §AW309§ BUG: if execution fails or script is interrupted, output is missing !
#close_html

# logger "End of $VERSION"

 echo "\n"
 line

 if [ "$1" != "-x" ]
 then
    xexit 0 # §AW018§
 fi

 xexit 0 # §AW018§
#>>> EOF <<<
