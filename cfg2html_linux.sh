#!/bin/bash
#
#set -vx
#$Id: cfg2html-linux,v 1.25 2005/05/13 15:42:23 ralproth Exp $
#PATH=$PATH:/usr/sbin:/sbin:/etc:/bin:/opt/omni/bin:/opt/omni/sbin

#VER=`gawk '/Id:/ {print $3;exit;}' $0`  ## also works :)

VER="1.25-0205"
VERSION="cfg2html-linux Version $VER "

#  If you change this script, please mark your changes with for example
#  ## <username> and send your diffs from the actual version to my e-mail
#  address: cfg2html*hotmail.com or dk3hg*users.sourceforge.net

#
# use "no" to disable a collection
#
CFG_NETWORK="yes" # <-- Network security, collecting tcpd and ip filter settings
CFG_SYSTEM="yes"
CFG_CRON="yes"
CFG_HARDWARE="yes"
CFG_SOFTWARE="yes"
CFG_FILESYS="yes"
CFG_LVM="yes"
CFG_KERNEL="yes"
CFG_ENHANCEMENTS="yes"
CFG_APPLICATIONS="yes"
GIF="yes"
if [ "$OUTDIR" = "" ] ; then
   OUTDIR="/var/adm/cfg"  # §AW020§  
fi
#
#
#
usage() {
  echo "WARNING, use this script AT YOUR OWN RISK"
  echo
  echo "    Usage: `basename $0` [OPTIONS]"
  echo "    creates HTML and plain ASCII host documentation"
  echo
  echo "    -o		set directory to write or use the environment"
  echo "                  variable OUTDIR=\"/path/to/dir\" (directory must exist)"
  echo "    -v		output version information and exit"
  echo "    -h		display this help and exit"
  echo
  echo "    use the following options to disable collections:"
  echo
  echo "    -s		disable: System"
  echo "    -c		disable: Cron"
  echo "    -S		disable: Software"
  echo "    -f		disable: Filesystem"
  echo "    -l		disable: LVM"
  echo "    -k		disable: Kernel/Libaries"
  echo "    -e		disable: Enhancements"
  echo "    -n		disable: Network"
  echo "    -a		disable: Applications"
  echo "    -H		disable: Hardware"
  echo "    -x		don't create background images"
  echo
}
#
# getopt
#
#
#NO_ARGS=0
#if [ $# -eq "$NO_ARGS" ]  # Script invoked with no command-line args?
#then
#  usage
#  exit 1          # Exit and explain usage, if no argument(s) given.
#fi

while getopts ":o:xshcSflkenaHvh" Option
do
  case $Option in
    o     ) OUTDIR=$OPTARG;;
    v     ) echo $VERSION;exit;;
    h     ) usage;exit;;
    x     ) GIF="no";;
    s     ) CFG_SYSTEM="no";;
    c     ) CFG_CRON="no";;
    S     ) CFG_SOFTWARE="no";;
    f     ) CFG_FILESYS="no";;
    l     ) CFG_LVM="no";;
    k     ) CFG_KERNEL="no";;
    e     ) CFG_ENHANCEMENTS="no";;
    n     ) CFG_NETWORK="no";;
    a     ) CFG_APPLICATIONS="no";;
    H     ) CFG_HARDWARE="no";;
    *     ) echo "Unimplemented option chosen. Try -h for help!";exit 1;;   # DEFAULT
  esac
done

shift $(($OPTIND - 1))
# Decrements the argument pointer so it points to next argument.

#
# linux port
MAILTO="&#100;&#107;&#51;&#104;&#103;&#64;&#117;&#115;&#101;&#114;&#115;&#46;&#115;&#111;&#117;&#114;&#99;&#101;&#102;&#111;&#114;&#103;&#101;&#46;&#110;&#101;&#116;"
MAILTORALPH="cfg2html&#64;&#104;&#111;&#116;&#109;&#97;&#105;&#108;&#46;&#99;&#111;&#109;"
# changed/added 08.07.2003 (13:04) by Ralph Roth, HP, ASO SW


#####################################################################
# @(#)Cfg2Html (c) by ROSE SWE, Dipl.-Ing. Ralph Roth
#####################################################################

# cfg2html-linux ported (c) by Michael Meifert, SysAdm
# using debian potato, woody

# This is the "swiss army knife" for the ASE, CE, sysadmin etc.
# I wrote it to get the nessary informations to plan an update,
# to performe basic trouble shooting or performance analysis.
# As a bonus cfg2html creates a nice HTML and plain ASCII
# documentation. If you are missing something, let me know it!

# ToDo:
#  add -debug option (SR: Stefan Sommer)
#  UPS settings -> a.w.

# bug fixes....
# - some old Linux commands for example "netstat" don't work
# Known Bugs
# - If Diagnostics is bad, cfg2html is also bad :))

# History
# 28-jan-1999  initial creation, based on get_config, check_config
#              nickel, snapshoot, vi, winword and a idea from a similar
#              script i have seen onsite.
#              Maybe a little bit ASE knowledge is also included :)))

#####################################################################
# 11-Mar-2001  initial creation for debian GNU Linux i386
#              based on Cfg2Html Version 1.15.06/HP-UX by
#              by ROSE SWE, Dipl.-Ing. Ralph Roth
#              ported to Linux  by Michael Meifert

line ( ) {
#echo --=[ http://come.to/cfg2html ]=-----------------------------------------------
echo " "
}

echo -e "\n"

## test if user = root
#
if [ `id|cut -c5-11` != "0(root)" ] ; then
  if [ -x /usr/bin/banner ] ; then
    banner "Sorry"
  else
    echo;echo " S o r r y ";echo
  fi
  line
  echo -e "You must run this script as Root\n"
  exit 1
fi
#
BASEFILE=`hostname -s||uname -n`		# 26.01.2001  uname -n, fixed 0205-2006rr for OpenWRT
HTML_OUTFILE=$OUTDIR/$BASEFILE.html
HTML_OUTFILE_TEMP=/tmp/$BASEFILE.html.$$
TEXT_OUTFILE=$OUTDIR/$BASEFILE.txt
TEXT_OUTFILE_TEMP=/tmp/$BASEFILE.txt.$$
ERROR_LOG=$OUTDIR/$BASEFILE.err
if [ ! -d $OUTDIR ] ; then
  echo "can't create $HTML_OUTFILE, $OUTDIR does not exist - stop"
  exit 1
fi
touch $HTML_OUTFILE
#echo "Starting up $VERSION\r"
[ -s "$ERROR_LOG" ] && rm -f $ERROR_LOG 2> /dev/null
DATE=`date "+%Y-%m-%d"` # ISO8601 compliant date string
DATEFULL=`date "+%Y-%m-%d %H:%M:%S"` # ISO8601 compliant date and time string

exec 2> $ERROR_LOG

if [ ! -f $HTML_OUTFILE ]  ;
then
  if [ -x /usr/bin/banner ] ; then
        banner "Error"
  else
        echo "E R R O R"
  fi
  line
  echo -e "You have not the rights to create $HTML_OUTFILE! (NFS?)\n"
  exit 1
fi

logger "Start of $VERSION"
RECHNER=`hostname -f`
VERSION_=`echo $VERSION/$RECHNER|tr " " "_"`
typeset -i HEADL=0                       #Headinglevel

#
# check Linux distribution
#
distrib="unknown"

## rr, 15.12.2004 - "robertfantini"
if [ -f /etc/gentoo-release ] ; then
distrib="`head -1 /etc/redhat-release`"
GENTOO="yes"
else
GENTOO="no"
fi

if [ -f /etc/slackware-version ] ; then
	distrib="`cat /etc/slackware-version`"
	SLACKWARE="yes"
else
	SLACKWARE="no"
fi

if [ -f /etc/debian_version ] ; then
	distrib="Debian GNU/Linux Version `cat /etc/debian_version`"
	DEBIAN="yes"
else
	DEBIAN="no"
fi

if [ -f /etc/SuSE-release ] ; then
	distrib="`head -1 /etc/SuSE-release`"
	SUSE="yes"
else
	SUSE="no"
fi

if [ -f /etc/mandrake-release ] ; then
        distrib="`head -1 /etc/mandrake-release`"
        MANDRAKE="yes"
else
        MANDRAKE="no"
fi

if [ -f /etc/redhat-release ] ; then
        distrib="`head -1 /etc/redhat-release`"
        REDHAT="yes"
else
        REDHAT="no"
fi

# MiMe: for UnitedLinux
if [ -f /etc/UnitedLinux-release ] ; then
        distrib="`head -1 /etc/UnitedLinux-release`"
        UNITEDLINUX="yes"
else
        UNITEDLINUX="no"
fi

# i am looking for other distribution tests



####################################################################
# needs improvement!
# trap "echo Signal: Aborting!; rm $HTML_OUTFILE_TEMP"  2 13 15

####################################################################
#  Beginn des HTML Dokumentes mit Ueberschrift und Titel
####################################################################
#  Header of HTML file
####################################################################

open_html() {
echo -e " \
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
<HTML> <HEAD>
 <META NAME="GENERATOR" CONTENT="Selfmade-$VERSION">
 <META NAME="AUTHOR" CONTENT="Ralph Roth, Michael Meifert">
 <META NAME="CREATED" CONTENT="Ralph Roth, Michael Meifert">
 <META NAME="CHANGED" CONTENT="`id;date` ">
 <META NAME="DESCRIPTION" CONTENT="$Header: /home/CVS/cfg2html/cfg2html-linux,v 1.25 2005/05/13 15:42:23 ralproth Exp $">
 <META NAME="subject" CONTENT="$VERSION on $RECHNER by $MAILTO">
<style type="text/css">
/* (c) 2001-2006 by ROSE SWE, Ralph Roth - http://come.to/rose_swe
 * CSS for cfg2html.sh, 12.04.2001, initial creation
 */

Pre		{Font-Family: Courier-New, Courier;Font-Size: 10pt}
BODY		{FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif; FONT-SIZE: 12pt;}
A		{FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif}
A:link 		{text-decoration: none}
A:visited 	{text-decoration: none}
A:hover 	{text-decoration: underline}
A:active 	{color: red; text-decoration: none}

H1		{FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif;FONT-SIZE: 20pt}
H2		{FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif;FONT-SIZE: 14pt}
H3		{FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif;FONT-SIZE: 12pt}
DIV, P, OL, UL, SPAN, TD
		{FONT-FAMILY: Arial, Verdana, Helvetica, Sans-serif;FONT-SIZE: 11pt}

</style>

<TITLE>${RECHNER} - Documentation - $VERSION</TITLE>
</HEAD><BODY>
<BODY LINK="#0000ff" VLINK="#800080" BACKGROUND="cfg2html_back.jpg">
<H1><CENTER><FONT COLOR=blue>
<P><hr><B>$RECHNER - System Documentation</P></H1>
<hr><FONT COLOR=blue><small>Created "$DATEFULL" with " $VERSION "</font></center></B></small>
<HR><H1>Contents\n</font></H1>\n\
" >$HTML_OUTFILE

(line
if [ -x /usr/bin/banner ] ; then
  banner $RECHNER
else
  echo
  #echo "                       "$RECHNER
  echo
fi;line) > $TEXT_OUTFILE
echo -e "\n" >> $TEXT_OUTFILE
echo -e "\n" > $TEXT_OUTFILE_TEMP
}

######################################################################
#  Erhoehe Headinglevel
######################################################################
#  Increases the headling level
######################################################################

inc_heading_level() {
HEADL=HEADL+1
echo -e "<UL>\n" >> $HTML_OUTFILE
}

######################################################################
#  Erniedrige Headinglevel
######################################################################
#  Decreases the heading level
######################################################################

dec_heading_level() {
HEADL=HEADL-1
echo -e "</UL>\n" >> $HTML_OUTFILE
}

######################################################################
#  Einzelne Items in der Dokumentation
#  $1  = Ueberschrift
######################################################################
#  Creates an own paragraph, $1 = heading
######################################################################

paragraph() {
if [ "$HEADL" -eq 1 ] ; then
    echo -e "\n<HR>\n" >> $HTML_OUTFILE_TEMP
fi
#echo -e "\n<table WIDTH="90%"><tr BGCOLOR="#CCCCCC"><td>\n">>$HTML_OUTFILE_TEMP
echo "<A NAME=\"$1\">" >> $HTML_OUTFILE_TEMP
echo "<A HREF=\"#Inhalt-$1\"><H${HEADL}> $1 </H${HEADL}></A><P>" >> $HTML_OUTFILE_TEMP
#echo "<A HREF=\"#Inhalt-$1\"><H${HEADL}> $1 </H${HEADL}></A></table><P>" >> $HTML_OUTFILE_TEMP

echo "<IMG SRC="profbull.gif" WIDTH=14 HEIGHT=14>" >> $HTML_OUTFILE
echo "<A NAME=\"Inhalt-$1\"></A><A HREF=\"#$1\">$1</A>" >> $HTML_OUTFILE
echo -e "\nCollecting: " $1 " .\c"
#echo "    $1" >> $TEXT_OUTFILE
}

######################################################################
#  Einzelne Kommandos und deren Ergebnisse
#  $1  = Kommando,  $2  =  Erklaerender Text
######################################################################
#  Documents the single commands and their output
#  $1  = unix command,  $2 = text for the heading
######################################################################

exec_command() {

echo -e ".\c"

echo -e "\n---=[ $2 ]=----------------------------------------------------------------" | cut -c1-74 >> $TEXT_OUTFILE_TEMP
#echo "       - $2" >> $TEXT_OUTFILE
######the working horse##########
TMP_EXEC_COMMAND_ERR=/tmp/exec_cmd.tmp.$$
## Modified 1/13/05 by marc.korte@oracle.com, Marc Korte, TEKsystems (150 -> 250)
EXECRES=`eval $1 2> $TMP_EXEC_COMMAND_ERR | expand | cut -c 1-250`


########### test it ############
# Gert.Leerdam@getronics.com
# Convert illegal characters for HTML into escaped ones.
#CONVSTR='
#s/</\&lt;/g
#s/>/\&gt;/g
#s/\\/\&#92;/g
#'
#EXECRES=$(eval $1 2> $TMP_EXEC_COMMAND_ERR | expand | cut -c 1-150 | sed +"$CONVSTR")

if [ -z "$EXECRES" ]
then
        EXECRES="n/a"
fi
if [ -s $TMP_EXEC_COMMAND_ERR ]
then
	echo "stderr output from \"$1\":" >> $ERROR_LOG
        cat $TMP_EXEC_COMMAND_ERR | sed 's/^/    /' >> $ERROR_LOG
fi
rm -f $TMP_EXEC_COMMAND_ERR

echo -e "\n" >> $HTML_OUTFILE_TEMP
echo -e "<A NAME=\"$2\"></A> <A HREF=\"#Inhalt-$2\"><H${HEADL}> $2 </H${HEADL}></A>\n" >>$HTML_OUTFILE_TEMP
echo -e "<PRE><B>$EXECRES</B></PRE>\n"  >>$HTML_OUTFILE_TEMP
#echo "<PRE><SMALL><B>$EXECRES</B></SMALL></PRE>\n"  >>$HTML_OUTFILE_TEMP
echo -e "<LI><A NAME=\"Inhalt-$2\"></A><A HREF=\"#$2\">$2</A>\n" >> $HTML_OUTFILE
echo -e "\n$EXECRES\n" >> $TEXT_OUTFILE_TEMP
}

################# Schedule a job for killing commands which ###############
################# may hang under special conditions. <mortene@sim.no> #####
# Argument 1: regular expression to search processlist for. Be careful
# when specifiying this so you don't kill any more processes than
# those you are looking for!
# Argument 2: number of minutes to wait for process to complete.

KillOnHang() {
        TMP_KILL_OUTPUT=/tmp/kill_hang.tmp.$$
        at now + $2 minutes 1>$TMP_KILL_OUTPUT 2>&1 <<EOF
# ps -ef | grep root | grep -v grep | egrep $1 | awk '{print \$2}' | sort -n -r | xargs kill
ps -ef | egrep $1 | awk '/root/ && !/grep/ {print $2}' | sort -n -r | xargs kill
EOF
        AT_JOB_NR=`awk ' /^job/ {print $2}' $TMP_KILL_OUTPUT`
        rm -f $TMP_KILL_OUTPUT
}

# You should always match a KillOnHang() call with a matching call
# to this function immediately after the command which could hang
# has properly finished.
CancelKillOnHang() {
        at -r $AT_JOB_NR
}

################# adds a text to the output files, rar, 25.04.99 ##########

AddText() {

        echo "<p>$*</p>" >> $HTML_OUTFILE_TEMP
        echo -e "$*\n" >> $TEXT_OUTFILE_TEMP
}
######################################################################
#  Ende des Dokumentes
######################################################################
#  end of the html document
######################################################################

close_html() {

echo "<hr>" >> $HTML_OUTFILE
echo -e "</P><P>\n<hr><FONT COLOR=blue>Created "$DATEFULL" with " $VERSION " by <A
HREF="mailto:$MAILTO?subject=$VERSION_">Michael Meifert, SysAdm</A></P></font>" >> $HTML_OUTFILE_TEMP
echo -e "</P><P>\n<FONT COLOR=blue>Based on the original script by <A
HREF="mailto:$MAILTORALPH?subject=$VERSION_">Ralph Roth</A></P></font>" >> $HTML_OUTFILE_TEMP
echo -e "<hr><center>\
<A HREF="http://come.to/cfg2html">  [ Download cfg2html from external home page ] </b></A></center></P><hr></BODY></HTML>\n" >> $HTML_OUTFILE_TEMP
cat $HTML_OUTFILE_TEMP >>$HTML_OUTFILE
cat $TEXT_OUTFILE_TEMP >> $TEXT_OUTFILE
rm $HTML_OUTFILE_TEMP $TEXT_OUTFILE_TEMP
echo -e "\n\nCreated "$DATEFULL" with " $VERSION " (c) 1998-2005 by Michael Meifert, SysAdm \n" >> $TEXT_OUTFILE
echo -e "Based on the origional script (c) 1998-2005 by ROSE SWE, Ralph Roth" >> $TEXT_OUTFILE
}

my_bdf() {
# bdf summary for HPUX, Ralph_Roth@hp.com, 5-feb-2001
#                 Linux, dk3hg

df -k | awk '/\// \
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

PVDisplay ( ) {
#function used in LVM-section
# for disk in $(strings /etc/lvmtab.d/* |grep -e hd -e sc) ;
for disk in $(vgdisplay -v | awk -F\ + '/PV Name/ {print $4}');
do
        pvdisplay -v $disk;
done
}

#
######################################################################
# Hauptprogramm mit Aufruf der obigen Funktionen und deren Parametern
#############################  M A I N  ##############################
#

line
echo "Starting          "$VERSION" "
echo "Path to Cfg2Html  "$0
echo "HTML Output File  "$HTML_OUTFILE
echo "Text Output File  "$TEXT_OUTFILE
echo "Partitions        "$OUTDIR/$BASEFILE.partitions.save
echo "Errors logged to  "$ERROR_LOG
echo "Started at        "$DATEFULL
echo "WARNING           USE AT YOUR OWN RISK!!! :-))"
echo
line
logger "Start of $VERSION"
open_html
inc_heading_level

#
# CFG_SYSTEM
#
if [ "$CFG_SYSTEM" != "no" ]
then # else skip to next paragraph

paragraph "Linux System $distrib"
inc_heading_level

if [ -f /etc/cfg2html/systeminfo ] ; then
  exec_command "cat /etc/cfg2html/systeminfo" "System description"
fi

exec_command "cat /proc/cpuinfo; echo" "CPU and Model info"

HostNames() {
uname -a
echo  "DNS Domainname  = "`dnsdomainname `
echo  "NIS Domainname  = "`domainname `
echo  "Hostname (short)= "`hostname -s`
echo  "Hostname (FQDN) = "`hostname -f`
}
exec_command  HostNames "uname & hostname"
exec_command "uname -n" "Host alias"
exec_command "uname -sr" "OS, Kernel version"
[ -x /usr/bin/lsb_release ] && exec_command "/usr/bin/lsb_release -a" "Linux Standard Base Version"
for i in /etc/*-release
do
	[ -r $i ] && exec_command "cat $i" "OS Specific Release Information ($i)"
done
exec_command "uptime" "Uptime"

posixversion() {

# wie findet man das bei Linux raus?
#echo "POSIX Version:  \c"; getconf POSIX_VERSION
#echo "POSIX Version:  \c"; getconf POSIX2_VERSION
#echo "X/OPEN Version: \c"; getconf XOPEN_VERSION
echo "LANG setting:   "$LANG
}

if [ -x /usr/bin/locale ] ; then
  exec_command posixversion "POSIX Standards/Settings"
  exec_command "locale" "locale-specific information"
  export LANG="C"
  export LANG_ALL="C"
fi

if [ -x /usr/bin/vmstat ] ; then
  exec_command "vmstat 1 10" "VM-Statistics"
fi

# sysutils
[ -x /usr/bin/procinfo ] && exec_command "procinfo -a" "System status from /proc" #  15.11.2004, 14:09 modified by Ralph.Roth at hp.com  (HPS-TSG-MCPS)
exec_command "pstree -p -a " "Active Process Overview" # 090102006
#exec_command "pstree -p -a -A" "Active Process Overview" #  15.11.2004, 14:09 modified by Ralph.Roth at hp.com  (HPS-TSG-MCPS)

exec_command "last| grep boot" "reboots"
exec_command "alias"  "Alias"
exec_command "egrep -v '#|^ *$' /etc/inittab" "inittab"
[ -x /sbin/chkconfig ] && exec_command "/sbin/chkconfig" "Services Startup"
[ -x /sbin/chkconfig ] && exec_command "/sbin/chkconfig --list" "Services Runlevel" # rar, fixed 2805-2005 for FC4

if [ -d /etc/rc.config.d ] ; then
  exec_command " grep -v ^# /etc/rc.config.d/* | grep '=[0-9]'" "Runlevel Settings"
fi
exec_command "awk '!/#|^ *$/ && /initdefault/' /etc/inittab" "default runlevel"
exec_command "/sbin/runlevel" "current runlevel"

##
## we want to display the Boot Messages too
## 30Jan2003 it233 FRU
if [ -e /var/log/boot.msg ] ; then
  exec_command "grep 'Boot logging' /var/log/boot.msg" "Last Boot Date"
  exec_command "grep -v '|====' /var/log/boot.msg " "Boot Messages, last Boot"
fi

# MiMe: SUSE && UNITEDLINUX
# MiMe: until SuSE 7.3: params in /etc/rc.config and below /etc/rc.config.d/
# MiMe; since SuSE 8.0 including UL: params below /etc/sysconfig
if [ "$SUSE" = "yes" ] || [ "$UNITEDLINUX" = "yes" ] ; then
  if [ -d /etc/sysconfig ] ; then
    # MiMe:
    exec_command "find /etc/sysconfig -type f -not -path '*/scripts/*' -exec egrep -v '^#|^ *$' {} /dev/null \; | sort" "Parameter /etc/sysconfig"
  fi
  if [ -e /etc/rc.config ] ; then
    # PJC: added filters for SuSE rc_ variables
    # PJC: which were in rc.config in SuSE 6
    # PJC: and moved to /etc/rc.status in 7+
    exec_command "egrep -v -e '(^#|^ *$)' -e '^ *rc_' -e 'rc.status' /etc/rc.config | sort" "Parameter /etc/rc.config"
  fi
  if [ -d /etc/rc.config.d ] ; then
    # PJC: added filters for SuSEFirewall and indented comments
    exec_command "find /etc/rc.config.d -name '*.config' -exec egrep -v -e '(^#|^ *$)' -e '^ *true$' -e '^[[:space:] ]*#' -e '[{]|[}]' {} \; | sort" "Parameter /etc/rc.config.d"
  fi
fi

if [ -e /proc/sysvipc ] ; then
  exec_command "ipcs" "IPC Status"
  exec_command "ipcs -u" "IPC Summary"
  exec_command "ipcs -l" "IPC Limits"
fi

if [ -x /usr/sbin/pwck ] ; then
  exec_command "/usr/sbin/pwck -r && echo Okay" "integrity of password files"
fi

if [ -x /usr/sbin/grpck ] ; then
  exec_command "/usr/sbin/grpck -r && echo Okay" "integrity of group files"
fi

dec_heading_level

fi # terminates CFG_SYSTEM wrapper

#
# CFG_CRON
#
if [ "$CFG_CRON" != "no" ]
then # else skip to next paragraph
paragraph "Cron and At"
inc_heading_level

for FILE in cron.allow cron.deny
	do
		if [ -r /etc/$FILE ]
		then
		exec_command "cat /etc/$FILE" "$FILE"
		else
		exec_command "echo /etc/$FILE" "$FILE not found!"
		fi
	done

## Linux SuSE user /var/spool/cron/tabs and NOT crontabs
## 30jan2003 it233 FRU
##  SuSE has the user contabs under /var/spool/cron/tabs
##  RedHat has the user crontabs under /var/spool/cron
##  UnitedLinux uses /var/spool/cron/tabs (MiMe)
if [ "$SUSE" == "yes" ] ; then
  usercron="/var/spool/cron/tabs"
fi
if [ "$REDHAT" == "yes" ] ; then
  usercron="/var/spool/cron"
fi
if [ "$SLACKWARE" == "yes" ] ; then
  usercron="/var/spool/cron/crontabs"
fi
if [ "$DEBIAN" == "yes" ] ; then
  usercron="/var/spool/cron/crontabs"
fi
if [ "$UNITEDLINUX" == "yes" ] ; then
  usercron="/var/spool/cron/tabs"
fi
##
ls $usercron/* > /dev/null 2>&1
if [ $? -eq 0 ]
then
        echo -e "\n\n<B>Crontab files:</B>" >> $HTML_OUTFILE_TEMP
        for FILE in $usercron/*
        do
                exec_command "cat $FILE | grep -v ^#" "For user `basename $FILE`"
        done
else
        echo "No crontab files for user.<br>" >> $HTML_OUTFILE_TEMP
fi

##
## we do also a listing of utility cron files
## under /etc/cron.d 30Jan2003 it233 FRU
ls /etc/cron.d/* > /dev/null 2>&1
if [ $? -eq 0 ]
then
        echo -e "\n\n<br><B>/etc/cron.d files:</B>" >> $HTML_OUTFILE_TEMP
        for FILE in /etc/cron.d/*
        do
                exec_command "cat $FILE | grep -v ^#" "For utility `basename $FILE`"
        done
else
        echo "No /etc/cron.d files for utlities." >> $HTML_OUTFILE_TEMP
fi

if [ -f /etc/crontab ] ; then
  exec_command "echo -e 'Crontab:\n';cat /etc/crontab | egrep -v '#|^ *$'" "/etc/crontab"
fi

for FILE in at.allow at.deny

	do
		if [ -r /etc/$FILE ]
		then
			exec_command "cat /etc/$FILE " "/etc/$FILE"
		else
			exec_command "echo /etc/$FILE" "No /etc/$FILE"
		fi
	done

## workaround by Ralph for missing at
#(whereis at > /dev/null) || exec_command "at -l" "AT Scheduler"
# sorry - don't work here (Michael)
# now we try this
if [ -x /usr/bin/at ] ; then
  exec_command "at -l" "AT Scheduler"
fi

#exec_command "echo -e 'Crontab:\n';cat /etc/crontab | egrep -v '#|^ *$';echo -e '\nAT Scheduler:\n';at -l" "/etc/crontab and AT Scheduler"

dec_heading_level
fi #terminate CFG_CRON wrapper
#
# CFG_HARDWARE
#
if [ "$CFG_HARDWARE" != "no" ]
then # else skip to next paragraph

paragraph "Hardware"
inc_heading_level

RAM=`awk -F': *' '/MemTotal/ {print $2}' /proc/meminfo`
# RAM=`cat /proc/meminfo | grep MemTotal | awk -F\: '{print $2}' | awk -F\  '{print $1 " " $2}'`
exec_command "echo $RAM" "Physical Memory"

[ -x /usr/sbin/hwinfo ] && exec_command "/usr/sbin/hwinfo 2> /dev/null" "Hardware List (hwinfo)"
[ -x /usr/bin/lshw ] && exec_command "/usr/bin/lshw" "Hardware List (lshw)" ##  13.12.2004, 15:53 modified by Ralph.Roth
[ -x /usr/bin/lsdev ] && exec_command "/usr/bin/lsdev" "Hardware List (lsdev)"
[ -x /usr/bin/lshal ] && exec_command "/usr/bin/lshal" "List of Devices (lshal)"
[ -x /sbin/lsusb ] && exec_command "/sbin/lspci" "USB devices"	## SuSE? #  12.11.2004, 15:04 modified by Ralph.Roth at hp.com  (HPS-TSG-MCPS)

if [ -x /sbin/lspci ] ; then
  exec_command "/sbin/lspci -v" "PCI devices"
else
  if [ -f /proc/pci ] ; then
    exec_command "cat /proc/pci" "PCI devices"
  fi
fi

PCMCIA=`grep pcmcia /proc/devices | cut -d" " -f2`
if [ "$PCMCIA" = "pcmcia"  ] ; then
  if [ -x /sbin/cardctl ] ; then
    exec_command "/sbin/cardctl status;/sbin/cardctl config;/sbin/cardctl ident" "PCMCIA"
  fi
fi
[ -r /proc/acpi/info ] && exec_command "cat /proc/acpi/info" "ACPI" #  06.04.2006, 17:44 modified by Ralph Roth

if [ -f /etc/kbd/default.kmap.gz ] ; then
  exec_command "zcat /etc/kbd/default.kmap.gz | head -1 | sed s/#//" "Keymap"
fi
exec_command "cat /proc/ioports" "IoPorts"
exec_command "cat /proc/interrupts" "Interrupts"
if [ -f /proc/scsi/scsi ] ;then
  exec_command "find /proc/scsi" "SCSI Componments" #  22.11.2004, 16:08 modified by Ralph.Roth at hp.com  (HPS-TSG-MCPS)
  exec_command "cat /proc/scsi/scsi" "SCSI Devices"
fi

## rar, 13.02.2004
[ -x /usr/sbin/adapter_info ] && exec_command "/usr/sbin/adapter_info;/usr/sbin/adapter_info -v" "Adapterinfo/WWN"
[ -x /usr/sbin/lssd ] && exec_command "/usr/sbin/lssd" "SCSI Devicesi (lssd)"
[ -x /usr/sbin/lssg ] && exec_command "/usr/sbin/lssg" "SCSI Devicesi (lssg)"
[ -x /usr/sbin/spmgr ] && exec_command "/usr/sbin/spmgr display" "SecurePath - Manager"
[ -r /etc/CPQswsp/sppf ] && exec_command "cat /etc/CPQswsp/sppf" "SecurePath - Bindings" ### modules?? ###

if [ -e /proc/sound ] ; then
  exec_command "cat /proc/sound" "Sound Devices"
fi
if [ -e /proc/asound ] ; then
  [ -f /proc/asound/version ] && exec_command "cat /proc/asound/version" "Asound Version"
  [ -f /proc/asound/modules ] && exec_command "cat /proc/asound/modules" "Sound modules"
  [ -f /proc/asound/cards ] &&exec_command "cat /proc/asound/cards" "Sound Cards"
  [ -f /proc/asound/sndstat ] && exec_command "cat /proc/asound/sndstat" "Sound Stats"
  [ -f /proc/asound/timers ] && exec_command "cat /proc/asound/timers" "Sound Timers"
  [ -f /proc/asound/devices ] && exec_command "cat /proc/asound/devices" "Sound devices"
  [ -f /proc/asound/pcm ] && exec_command "cat /proc/asound/pcm" "Sound pcm"
fi
exec_command "cat /proc/dma" "DMA Devices"
if [ -f /proc/tty/driver/serial ] ; then
   exec_command "grep -v unknown /proc/tty/driver/serial" "Serial Devices"
fi
# test this - please report it
if [ -e /proc/rd ] ; then
  exec_command "cat /proc/rd/c*/current_status" "RAID controller"
fi

# get serial information

SETSERIAL=`which setserial`
if [ $SETSERIAL ] && [ -x $SETSERIAL ]; then
  exec_command "$SETSERIAL -a /dev/ttyS0" "Serial ttyS0"
  exec_command "$SETSERIAL -a /dev/ttyS1" "Serial ttyS1"
fi

# get IDE Disk information
HDPARM=`which hdparm`
# if hdparm is installed
if [ $HDPARM ]  && [ -x $HDPARM ]; then
  exec_command "\
if [ -e /proc/ide/hda ] ; then echo -e -n \"read from drive\"; $HDPARM -I /dev/hda;fi;\
if [ -e /proc/ide/hdb ] ; then echo; echo -e -n \"read from drive\"; $HDPARM -I /dev/hdb;fi;\
if [ -e /proc/ide/hdc ] ; then echo; echo -e -n \"read from drive\"; $HDPARM -I /dev/hdc;fi;\
if [ -e /proc/ide/hdd ] ; then echo; echo -e -n \"read from drive\"; $HDPARM -I /dev/hdd;fi;"\
 "IDE Disks"

  if [ -e /proc/ide/hda ] ; then
    if grep disk /proc/ide/hda/media > /dev/null ;then
      exec_command "$HDPARM -t -T /dev/hda" "Transfer Speed"
    fi
  fi
  if [ -e /proc/ide/hdb ] ; then
    if grep disk /proc/ide/hdb/media > /dev/null ;then
      exec_command "$HDPARM -t -T /dev/hda" "Transfer Speed"
    fi
  fi
  if [ -e /proc/ide/hdc ] ; then
    if grep disk /proc/ide/hdc/media > /dev/null ;then
      exec_command "$HDPARM -t -T /dev/hda" "Transfer Speed"
    fi
  fi
  if [ -e /proc/ide/hdd ] ; then
    if grep disk /proc/ide/hda/media > /dev/null ;then
      exec_command "$HDPARM -t -T /dev/hdd" "Transfer Speed"
    fi
  fi
else
# if hdparm not available
  exec_command "\
    if [ -e /proc/ide/hda/model ] ; then echo -e -n \"hda: \";cat /proc/ide/hda/model ;fi;\
    if [ -e /proc/ide/hdb/model ] ; then echo -e -n \"hdb: \";cat /proc/ide/hdb/model ;fi;\
    if [ -e /proc/ide/hdc/model ] ; then echo -e -n \"hdc: \";cat /proc/ide/hdc/model ;fi;\
    if [ -e /proc/ide/hdd/model ] ; then echo -e -n \"hdd: \";cat /proc/ide/hdd/model ;fi;"\
 "IDE Disks"
fi

if [ -e /proc/sys/dev/cdrom/info ] ; then
  exec_command "cat /proc/sys/dev/cdrom/info" "CDROM Drive"
fi

if [ -e /proc/ide/piix ] ; then
   exec_command "cat /proc/ide/piix" "IDE Chipset info"
fi

# Test HW Health
# MiMe
if [ -x /usr/bin/sensors ] ; then
  if [ -e /proc/sys/dev/sensors/chips ] ; then
    exec_command "/usr/bin/sensors" "Sensors"
  fi
fi

if [ -x /usr/sbin/xpinfo ]
then
  XPINFOFILE=$OUTDIR/`hostname`_xpinfo.csv
  /usr/sbin/xpinfo -d";" | grep -v "Scanning" > $XPINFOFILE

  AddText "The XP-Info configuration was additionally dumped into the file <b>$XPINFOFILE</b> for further usage"

# remarked due to enhancement request by Martin Kalmbach, 25.10.2001
#  exec_command "/usr/sbin/xpinfo|grep -v Scanning" "SureStore E Disk Array XP Mapping (xpinfo)"

  exec_command "/usr/sbin/xpinfo -r|grep -v Scanning" "SureStore E Disk Array XP Disk Mechanisms"
  exec_command "/usr/sbin/xpinfo -i|grep -v Scanning" "SureStore E Disk Array XP Identification Information"
  exec_command "/usr/sbin/xpinfo -c|grep -v Scanning" "SureStore E Disk Array XP (Continuous Access and Business Copy)"
# else
# [ -x /usr/contrib/bin/inquiry256.ksh ] && exec_command "/usr/contrib/bin/inquiry256.ksh" "SureStore E Disk Array XP256 Mapping (inquiry/obsolete)"
fi

dec_heading_level

fi # terminates CFG_HARDWARE wrapper

######################################################################

##### ToDo: check for Distribution #####

if [ "$CFG_SOFTWARE" != "no" ]
then # else skip to next paragraph

  paragraph "Software"
  inc_heading_level

  # Debian
  if [ "$DEBIAN" = "yes" ] ; then
    dpkg --get-selections | awk '!/deinstall/ {print $1}' > /tmp/cfg2html-debian.$$
    exec_command "column /tmp/cfg2html-debian.$$" "Packages installed"
    rm -f /tmp/cfg2html-debian.$$
    AddText "Hint: to reinstall this list use:"
    AddText "awk '{print \$1\"\\n\"\$2}' this_list |  dpkg --set-selections"
    exec_command "dpkg -C" "Misconfigured Packages"
#   # { changed/added 25.11.2003 (14:29) by Ralph Roth }
    if [ -x /usr/bin/deborphan ] ; then
      exec_command "deborphan" "Orphaned Packages"
      AddText "Hint: deborphan | xargs apt-get -y remove"	# rar, 16.02.04
    fi
    exec_command "dpkg -l" "Detailed list of installed Packages"
    AddText "$(dpkg --version|grep program)"
    exec_command "egrep -v '#|^ *$' /etc/apt/sources.list" "Installed from"
  fi
  # end Debian

  # SUSE
  # MiMe: --last tells date of installation
  if [ "$SUSE" = "yes" ] || [ "$UNITEDLINUX" = "yes" ] ; then
    exec_command "rpm -qa --last" "Packages installed"
  fi
  # end SUSE

  # REDHAT
  if [ "$REDHAT" = "yes" ] || [ "$MANDRAKE" = "yes" ] ; then
    exec_command "rpm -qia | grep -e Source -e Name" "Packages installed"
    exec_command "rpm -qa " "Packages installed (Short List)"
  fi
  # end REDHAT

  # SLACKWARE
  if [ "$SLACKWARE" = "yes" ] ; then
    exec_command "ls /var/log/packages " "Packages installed"
  fi
  # end SLACKWARE
  # GENTOO, rr, 15.12.2004, Rob
  if [ "$GENTOO" = "yes" ] ; then
    #exec_command "qpkg -I -v|sort" "Packages installed"
    exec_command "qpkg -I -v  --no-color |sort" "Packages installed" ## Rob Fantini, 15122004
  fi
  # end GENTOO
#### programming stuff ####
# plugin for cfg2html/linux/hpux #  22.11.2005, 16:03 modified by Ralph Roth
# $Id: programming.sh,v 1.2 2005/11/22 15:06:51 ralproth Exp $

ProgStuff()
{
 for i in libtoolize libtool automake autoconf autoheader g++ gcc make flex sed
 do
  (which $i) && (echo -n "$i: ";$i --version | head -1)
 done
}
 exec_command ProgStuff "Software Development: Programs and Versions"

  dec_heading_level

fi # terminates CFG_SOFTWARE wrapper

######################################################################
if [ "$CFG_FILESYS" != "no" ]
then # else skip to next paragraph

paragraph "Filesystems, Dump- and Swapconfiguration"
inc_heading_level

exec_command "grep -v '^#' /etc/fstab" "FileSystemTab"
exec_command "df -k" "Filesystems and Usage"
exec_command "my_bdf" "All Filesystems and Usage"
exec_command "mount" "Local Mountpoints"
#
exec_command "/sbin/fdisk -l" "Disk Partitions"

#
sfdisk -d > $OUTDIR/$BASEFILE.partitions.save
exec_command "cat $OUTDIR/$BASEFILE.partitions.save" "Disk Partitions to restore from"
AddText "To restore your partitions use the saved file: $BASEFILE.partitions.save, read the man page for sfdisk for usage. (Hint: sfdisk --force /dev/device < file.save)"

# for LVM using sed
exec_command "/sbin/fdisk -l|sed 's/8e \ Unknown/8e \ LVM/g'" "Disk Partitions"

if [ -f /etc/exports ] ; then
    exec_command "egrep -v '^#|^ *$' /etc/exports" "NFS Filesystems"
fi

exec_command "free" "used memory/swap"

dec_heading_level

fi # terminates CFG_FILESYS wrapper

###########################################################################
if [ "$CFG_LVM" != "no" ]
then # else skip to next paragraph

   paragraph "LVM"
   inc_heading_level

#  if [ -x /sbin/vgdisplay ] ; then
if [ -e /etc/lvmtab ] ; then
    vgdisplay -s > /dev/null 2>&1 #  15.11.2004, 14:11 modified by Ralph.Roth at hp.com  (HPS-TSG-MCPS)

    if [ "$?" = "0" ] ; then
      AddText "The system filelayout is configured using the LVM (Logical Volume Manager)"
      exec_command "ls -la /dev/*/group" "Volumegroup Device Files"
      # { changed/added 29.01.2004 (11:15) by Ralph Roth } - sr by winfried knobloch for mc/sg

      exec_command "cat /proc/lvm/global" "LVM global info"
      exec_command "vgdisplay -v | awk -F' +' '/PV Name/ {print \$4}'" "Available Physical Groups"
      exec_command "vgdisplay -s | awk -F\\\" '{print \$2}'" "Available Volume Groups"
      exec_command "vgdisplay -v | awk -F' +' '/LV Name/ {print \$3}'" "Available Logical Volume"
      exec_command "vgdisplay -v" "Volumegroups"
      exec_command PVDisplay "Physical Devices used for LVM"
      AddText "Note: Run vgcfgbackup on a reqular basis to backup your volume group layout"
    else
      # if vgdisplay exist, but no LV configured (dk3hg 21.02.03)
      AddText "This system seems to be configured with whole disk layout (WDL)"
    fi
  else
    AddText "This system seems to be configured with whole disk layout (WDL)"
  fi

  # MD Tools, Ralph Roth

  if [ -r /etc/raidtab ]
  then
   exec_command "cat /proc/mdstat" "Software RAID: mdstat"
   exec_command "cat /etc/raidtab" "Software RAID: raidtab"
   [ -r /proc/devices/md ] && exec_command "cat /proc/devices/md" "Software RAID: MD Devices"
  fi

  dec_heading_level

fi # terminates CFG_LVM wrapper

###########################################################################
if [ "$CFG_NETWORK" != "no" ]
then # else skip to next paragraph

  paragraph "Network Settings"
  inc_heading_level

  exec_command "/sbin/ifconfig" "LAN Interfaces"
  #exec_command "for interface in \$(lanscan|grep 'lan. '|awk '{print \$5}'|sort) ; do ifconfig \$interface; done" "LAN Interface Configuration"

  if [ $DEBIAN = "yes" ] ; then
    if [ -f /etc/network/interfaces ] ; then
      exec_command "grep -v '(^#|^$)' /etc/network/interfaces" "Netconf Settings"
    fi
  fi

  [ -x /sbin/mii-tool ] && exec_command "/sbin/mii-tool -v" "MII Status"
  [ -x /sbin/mii-diag ] && exec_command "/sbin/mii-diag -a" "MII Diagnostics"

  NETSTAT=`which netstat`
  if [ $NETSTAT ]  && [ -x $NETSTAT ]; then
    # test if netstat version 1.38, because some options differ in older versions
    # MiMe: '\' auf awk Zeile wichtig
    RESULT=`netstat -V | awk '/netstat/ {
        if ( $2 < 1.38 ) {
          print "NO"
        } else { print "OK" }
      }'`
    exec_command "netstat -r" "Routing Tables"
    exec_command "if [ "$RESULT" = "OK" ] ; then netstat -gi; fi" "Interfaces"
     ## Added 4/07/06 by krtmrrsn@yahoo.com, Marc Korte, probe and display
     ##        kernel interface bonding info.
     if [ -e /proc/net/bonding ]; then
       for BondIF in `ls -1 /proc/net/bonding`
       do
         exec_command "cat /proc/net/bonding/$BondIF" "Bonded Interfaces: $BondIF"
       done
     fi
     ## End Marc Korte kernel interface bonding addition.

    exec_command "netstat -s" "Summary statistics for each protocol"
    exec_command "netstat -i" "Kernel Interface table"
    # MiMe: iptables since 2.4.x
    # MiMe: iptable_nat realisiert dabei das Masquerading
    # MiMe: Details stehen in /proc/net/ip_conntrack
    if [ -e /proc/net/ip_masquerade ]; then
      exec_command "netstat -M" "Masqueraded sessions"
    fi
    if [ -e /proc/net/ip_conntrack ]; then
      exec_command "cat /proc/net/ip_conntrack" "Masqueraded sessions"
    fi
    exec_command "netstat -an" "list of all sockets"
  fi

  DIG=`which dig`
  if [ $DIG ] && [ -x $DIG ] ; then
    exec_command "dig `hostname -f`" "dig hostname"
  else
    NSLOOKUP=`which nslookup`
    if [ $NSLOOKUP ] && [ -x $NSLOOKUP ] ; then
      exec_command "nslookup `hostname -f`" "Nslookup hostname"
    fi
  fi

  exec_command "egrep -v '#|^ *$' /etc/hosts" "/etc/hosts"
#
  if [ -f /proc/sys/net/ipv4/ip_forward ] ; then
    FORWARD=`cat /proc/sys/net/ipv4/ip_forward`
    if [ $FORWARD = "0" ] ; then
      exec_command "echo \"IP forward disabled\"" "IP forward"
    else
      exec_command "echo \"IP forward enabled\"" "IP forward"
    fi
  fi

  if [ -r /proc/net/ip_fwnames ] ; then
    if [ -x /sbin/ipchains ] ;then
      exec_command "/sbin/ipchains -n -L forward" "ipfilter forward settings"
      exec_command "/sbin/ipchains -L -v" "ip filter settings"
    fi
  fi

  if [ -r /proc/net/ip_tables_names ] ; then
    if [ -x /sbin/iptables ] ; then
      exec_command "/sbin/iptables -L -v" "iptables list chains" ## rr, 030604 -v added
      exec_command "/sbin/iptables-save" "iptables rules" ## rr, 120704 added
    fi
  fi

  if [ -x /usr/sbin/tcpdchk ] ; then
    exec_command "/usr/sbin/tcpdchk -v" "tcpd wrapper"
    exec_command "/usr/sbin/tcpdchk -a" "tcpd warnings"
  fi

  [ -f /etc/hosts.allow ] && exec_command "egrep  -v '#|^ *$' /etc/hosts.allow" "hosts.allow"
  [ -f /etc/hosts.deny ] && exec_command "egrep  -v '#|^ *$' /etc/hosts.deny" "hosts.deny"

  #exec_command "nettl -status trace" "Nettl Status"

  if [ -f /etc/gated.conf ] ; then
      exec_command "cat /etc/gated.conf" "Gate Daemon"
  fi

  if [ -f /etc/bootptab ] ; then
      exec_command "egrep -v '(^#|^ *$)' /etc/bootptab" "BOOTP Daemon Configuration"
  fi

  if [ -r /etc/inetd.conf ]; then
    exec_command "egrep -v '#|^ *$' /etc/inetd.conf" "Internet Daemon Configuration"
  fi
  #  02.05.2005, 15:23 modified by Ralph.Roth at hp.com  (HPS-TSG-MCPS)

  # RedHat default
  ## exec_command "egrep -v '#|^ *$' /etc/inetd.conf" "Internet Daemon Configuration"
  if [ -d /etc/xinetd.d ]; then
    # mdk/rh has a /etc/xinetd.d directory with a file per service
    exec_command "cat /etc/xinetd.d/*|egrep -v '#|^ *$'" "/etc/xinetd.d/ section"
  fi

  #exec_command "cat /etc/services" "Internet Daemon Services"
  if [ -f /etc/resolv.conf ] ; then
     exec_command "egrep -v '#|^ *$' /etc/resolv.conf;echo; ( [ -f /etc/nsswitch.conf ] &&  egrep -v '#|^ *$' /etc/nsswitch.conf)" "DNS & Names"
  fi
  [ -r /etc/bind/named.boot ] && exec_command "grep -v '^;' /etc/named.boot"  "DNS/Named"

  if [ ! -f /etc/sendmail.cf ] ; then
    /usr/sbin/sendmail -bV 2> /dev/null > /dev/null && exec_command "/usr/sbin/sendmail -bV" "Sendmail/Exim Version" #  23.03.2006, 13:20 modified by Ralph Roth
  else
    exec_command "/usr/sbin/sendmail -bv -d0.1 testuser@test.host" "Sendmail Version"
  fi

  if [ -f /etc/aliases ] ; then
    exec_command "egrep -v '#|^ *$' /etc/aliases" "Email Aliases"
  fi
  #exec_command "egrep -v '^#|^$' /etc/rc.config.d/nfsconf" "NFS settings"
  exec_command "ps -ef|egrep '[Nn]fsd|[Bb]biod'" "NFSD and BIOD utilisation"

  # if portmap not available, do nothing
  RES=`ps xau | grep [Pp]ortmap`
  if [ -n "$RES" ] ; then
    exec_command "rpcinfo -p " "RPC (Portmapper)"
    # test if mountd running
    MOUNTD=`rpcinfo -p | awk '/mountd/ {print $5; exit}'`
  #  if [ "$MOUNTD"="mountd" ] ; then
    if [ -n "$MOUNTD" ] ; then
      exec_command "rpcinfo -u 127.0.0.1 100003" "NSFD responds to RPC requests"
      if [ -x /sbin/showmount ] ; then
        exec_command "/sbin/showmount -a" "Mounted NFS File Systems"
      fi
      # SUSE
      if [ -x /usr/lib/autofs/showmount ] ; then
        exec_command "/usr/lib/autofs/showmount -a" "Mounted NFS File Systems"
      fi
      if [ -f /etc/auto.master ] ;then
        exec_command "egrep -v '^#|^$' /etc/auto.master" "NFS Automounter Master Settings"
      fi
      if [ -f /etc/auto.misc ] ;then
        exec_command "egrep -v '^#|^$' /etc/auto.misc" "NFS Automounter misc Settings"
      fi
      if [ -f /proc/net/rpc/nfs ] ; then
        exec_command "nfsstat" "NFS Statistics"
      fi
    fi # mountd
  fi

  #(ypwhich 2>/dev/null>/dev/null) && \
  #    (exec_command "what /usr/lib/netsvc/yp/yp*; ypwhich" "NIS/Yellow Pages")

  # ntpq live sometimes in /usr/bin or /usr/sbin
  NTPQ=`which ntpq`
  # if [ $NTPQ ] && [ -x $NTPQ ] ; then
  if [ -n "$NTPQ" ] && [ -x "$NTPQ" ] ; then      # fixes by Ralph Roth, 180403
    exec_command "$NTPQ -p" "XNTP Time Protocol Daemon"
  fi
  [ -f /etc/ntp.conf ] && exec_command "egrep  -v '#|^ *$' /etc/ntp.conf" "ntp.conf"
  [ -f /etc/shells ] && exec_command "egrep  -v '#|^ *$'  /etc/shells" "FTP Login Shells"
  [ -f /etc/ftpusers ] && exec_command "egrep  -v '#|^ *$'  /etc/ftpusers" "FTP Rejections (/etc/ftpusers)"
  [ -f /etc/ftpaccess ] && exec_command "egrep  -v '#|^ *$'  /etc/ftpaccess" "FTP Permissions (/etc/ftpaccess)"
  [ -f /etc/syslog.conf ] && exec_command "egrep  -v '#|^ *$' /etc/syslog.conf" "syslog.conf"
  [ -f /etc/host.conf ] && exec_command "egrep  -v '#|^ *$' /etc/host.conf" "host.conf"

  ######### SNMP ############
  [ -f /etc/snmpd.conf ] && exec_command "egrep -v '#|^ *$' /etc/snmpd.conf" "Simple Network Managment Protocol (SNMP)"
  [ -f /etc/snmp/snmpd.conf ] && exec_command "egrep -v '#|^ *$' /etc/snmp/snmpd.conf" "Simple Network Managment Protocol (SNMP)"
  [ -f /etc/snmp/snmptrapd.conf ] && exec_command "egrep -v '#|^ *$' /etc/snmp/snmptrapd.conf" "SNMP Trapdaemon config"

  [ -f  /opt/compac/cma.conf ] && "egrep -v '#|^ *$' /opt/compac/cma.conf" "HP Insight Management Agents configuration"

  ## ssh
  [ -f /etc/ssh/sshd_config ] && exec_command "egrep -v '#|^ *$' /etc/ssh/sshd_config" "sshd config"
  [ -f /etc/ssh/ssh_config ] && exec_command "egrep -v '#|^ *$' /etc/ssh/ssh_config" "ssh config"

  dec_heading_level

fi # terminates CFG_NETWORK wrapper


###########################################################################
if [ "$CFG_KERNEL" != "no" ]
then # else skip to next paragraph

paragraph "Kernel, Modules and Libaries" "Kernelparameters"
inc_heading_level

if [ -f /etc/lilo.conf ] ; then
  exec_command "egrep -v '#|^ *$' /etc/lilo.conf" "Lilo Boot Manager"
  exec_command "/sbin/lilo -q" "currently mapped files"
fi

if [ -f /boot/grub/menu.lst ] ; then
  exec_command "egrep -v '#|^ *$' /boot/grub/menu.lst" "GRUB Boot Manager" # rar
fi

if [ -f /etc/palo.conf ] ; then
  exec_command "egrep -v '#|^ *$' /etc/palo.conf" "Palo Boot Manager"
fi

exec_command "ls -l /boot" "Files in /boot" # 2404-2006, ralph

exec_command "/sbin/lsmod" "Loaded Kernel Modules"
exec_command "ls -l /lib/modules" "Available Modules Trees"  # rar

if [ -f /etc/modules.conf ] ; then
  exec_command "egrep -v '#|^ *$' /etc/modules.conf" "modules.conf"
fi
if [ -f /etc/modprobe.conf ] ; then
  exec_command "egrep -v '#|^ *$' /etc/modprobe.conf" "modprobe.conf"
fi

if [ -f /etc/sysconfig/kernel ] ; then
  exec_command "egrep -v '#|^ *$' /etc/sysconfig/kernel" "Modules for the ramdisk"	# rar, SuSE only
fi

if [ "$DEBIAN" = "no" ] && [ "SLACKWARE" = "no" ] ; then
        which rpm > /dev/null  && exec_command "rpm -qa | grep -e ^k_def -e ^kernel -e k_itanium -e k_smp -e ^linux" "Kernel RPMs" # rar, SuSE+RH+Itanium2
fi

if [ "$DEBIAN" = "yes" ] ; then
  	exec_command "dpkg -l | grep -i -e Kernel-image -e Linux-image" "Kernel related DEBs"
fi
[ -x /usr/sbin/get_sebool ] && exec_command "/usr/sbin/get_sebool -a" "SELinux Settings"

who -b 2>/dev/null > /dev/null && exec_command "who -b" "System boot" #  23.03.2006, 13:18 modified by Ralph Roth
exec_command "cat /proc/cmdline" "Kernel commandline"

if [ -r  /lib/libc.so.5 ]
then
if [ -x  /lib/libc.so.5 ]
then
	exec_command "/lib/libc.so.5" "libc5 Version"  # Mandrake 9.2
else
	exec_command "strings /lib/libc.so.5 | grep \"release version\"" "libc5 Version (Strings)"
	############# needs work out!
	## rpm ## ldd
fi
fi

if [ -r  /lib/libc.so.6 ]
then
if [ -x  /lib/libc.so.6 ]
then
	exec_command "/lib/libc.so.6" "libc6 Version"  # Mandrake 9.2
else
	exec_command "strings /lib/libc.so.6 | grep \"release version\"" "libc6 Version (Strings)"
	############# needs work out!
	## rpm ## ldd
fi
fi

if [ "$DEBIAN" = "no" ] && [ "SLACKWARE" = "no" ] ; then
        which rpm > /dev/null  && exec_command "rpm -qi glibc" "libc6 Version (RPM)" # rar, SuSE+RH
fi


exec_command "/sbin/ldconfig -vN" "Run-time link bindings"

# MiMe: SuSE patched kernel params into /proc
if [ -e /proc/config.gz ] ; then
  exec_command "zcat /proc/config.gz | egrep -v '#|^ *$'" "Kernelparameter /proc/config.gz"
else
  if [ -e /usr/src/linux/.config ] ; then
    exec_command "egrep -v '#|^ *$' /usr/src/linux/.config" "Kernelsource .config"
  fi
fi

##
## we want to display special kernel configuration as well
## done in /etc/init.d/boot.local
## 31Jan2003 it233 U.Frey FRU
if [ -e /etc/init.d/boot.local ] ; then
  exec_command "egrep -v '#|^ *$' /etc/init.d/boot.local" "Additional Kernel Parameters init.d/boot.local"
fi

if [ -x /sbin/sysctl ] ; then
  exec_command "/sbin/sysctl -a" "configured kernel parameters at runtime"
fi

if [ -f "/etc/rc.config" ] ; then
   exec_command "grep ^INITRD_MODULES /etc/rc.config" "INITRD Modules"
fi

dec_heading_level

fi # terminates CFG_KERNEL wrapper
######################################################################

if [ "$CFG_ENHANCEMENTS" != "no" ]
then # else skip to next paragraph

paragraph "Systemenhancements"
inc_heading_level

if [ -e /etc/X11/XF86Config ] ; then
  exec_command "egrep -v '#|^ *$' /etc/X11/XF86Config" "XF86Config"
else
  if  [ -e /etc/XF86Config ] ; then
    exec_command "egrep -v '#|^ *$' /etc/XF86Config" "XF86Config"
  fi
fi

if [ -e /etc/X11/XF86Config-4 ] ; then
  exec_command "egrep -v '#|^ *$' /etc/X11/XF86Config-4" "XF86Config-4"
else
  if  [ -e /etc/XF86Config ] ; then
    exec_command "egrep -v '#|^ *$' /etc/XF86Config-4" "XF86Config-4"
  fi
fi

if [ -e /etc/X11/xorg.conf ] ; then
  exec_command "egrep -v '#|^ *$' /etc/X11/xorg.conf" "xorg.conf"
fi

# MiMe: für X braucht man Rechte
if [ -x /usr/X11R6/bin/xhost ] ; then
  /usr/X11R6/bin/xhost > /dev/null 2>&1
  if [ "$?" -eq "0" ] ;
  then
# Gratien D'haese
# fix for sshdX11
# old command   [ -x /usr/bin/X11/xdpyinfo ] && [ -n "$DISPLAY" ] && exec_command "/usr/bin/X11/xdpyinfo" "X11"
# this will only check if the display is 0 or 1 which is more then enough
    [ -x /usr/bin/X11/xdpyinfo ] && [ -n "$DISPLAY" ] && [ `echo $DISPLAY | cut -d: -f2 | cut -d. -f1` -le 1 ] && exec_command "/usr/bin/X11/xdpyinfo" "X11"
    [ -x /usr/bin/X11/fsinfo ] && [ -n "$FONTSERVER" ] && exec_command "/usr/bin/X11/fsinfo" "Font-Server"
  fi
fi
dec_heading_level

fi # terminates CFG_ENHANCEMENTS wrapper
###########################################################################

if [ "$CFG_APPLICATIONS" != "no" ]
then # else skip to next paragraph

paragraph "Applications and Subsystems"

### COMMON ################################################################

inc_heading_level

if [ -d /usr/local/bin ] ; then
  exec_command "ls -lisa /usr/local/bin" "Files in /usr/local/bin"
fi
if [ -d /usr/local/sbin ] ; then
  exec_command "ls -lisa /usr/local/sbin" "Files in /usr/local/sbin"
fi
if [ -d /opt ] ; then
  exec_command "ls -lisa /opt" "Files in /opt"
fi

############ Samba and Swat ########################

if [ -f /etc/inetd.conf ] ; then
  SWAT=`grep swat /etc/services /etc/inetd.conf`
fi
if [ -f /etc/xinetd.conf ] ; then
  SWAT=`grep swat /etc/services /etc/xinetd.conf`
fi

[ -n "$SWAT" ] && exec_command  "echo $SWAT" "Samba: SWAT-Port"

[ -x /usr/sbin/smbstatus ] && exec_command "/usr/sbin/smbstatus 2>/dev/null" "Samba (smbstatus)"
### Debian....
[ -x /usr/bin/smbstatus ] && exec_command "/usr/sbin/smbstatus 2>/dev/null" "Samba (smbstatus)"
[ -x /usr/bin/testparm ] && exec_command "/usr/bin/testparm -s" "Samba Configuration"
[ -f /etc/init.d/samba ] && exec_command "ps -ef | egrep '(s|n)m[b]'" "Samba Daemons"

if [ -x /usr/sbin/lpc ] ; then
  exec_command "/usr/sbin/lpc status" "Printer Spooler and Printers"
fi
[ -f /etc/printcap ] && exec_command "egrep -v '#|^ *$' /etc/printcap" "Printcap"
[ -f /etc/hosts.lpd ] && exec_command "egrep -v '#|^ *$' /etc/hosts.lpd" "hosts.lpd"

##
## we want to display HP OpenVantage Operations configurations
## 31Jan2003 it233 FRU U.Frey
if [ -e /opt/OV/bin/OpC/utils/opcdcode ] ; then
  if [ -e /opt/OV/bin/OpC/install/opcinfo ] ; then
    exec_command "cat /opt/OV/bin/OpC/install/opcinfo" "HP OpenView Info, Version"
  fi
  if [ -e /var/opt/OV/conf/OpC/monitor ] ; then
    exec_command "/opt/OV/bin/OpC/utils/opcdcode /var/opt/OV/conf/OpC/monitor | grep DESCRIPTION" "HP OpenView Configuration MONITOR"
  fi

  if [ -e /var/opt/OV/conf/OpC/le ] ; then
    exec_command "/opt/OV/bin/OpC/utils/opcdcode /var/opt/OV/conf/OpC/le | grep DESCRIPTION" "HP OpenView Configuration LOGGING"
  fi
fi

## we want to display Veritas netbackup configurations
## 31Jan2003 it233 FRU U.Frey
if [ -e /usr/openv/netbackup/bp.conf ] ; then
  if [ -e /usr/openv/netbackup/version ] ; then
    exec_command "cat /usr/openv/netbackup/version" "Veritas Netbackup Version"
  fi
  exec_command "cat /usr/openv/netbackup/bp.conf" "Veritas Netbackup Configuration"
fi

fi # terminates CFG_APPLICATIONS wrapper

###########################################################################
# { changed/added 28.01.2004 (17:56) by Ralph Roth }
if [ -r /etc/cmcluster.conf ] ; then
    dec_heading_level
    paragraph "MC/SG"
    inc_heading_level
    . ${SGCONFFILE:=/etc/cmcluster.conf}   # get env. setting, rar 12.05.2005
  PATH=$PATH:$SGSBIN:$SGLBIN
    exec_command "cat ${SGCONFFILE:=/etc/cmcluster.conf}" "Cluster Config Files"
    exec_command "what  $SGSBIN/cmcld|head; what  $SGSBIN/cmhaltpkg|head" "Real MC/SG Version"  ##  12.05.2005, 10:07 modified by Ralph.Roth at hp.com  (HPS-TSG-MCPS)
    exec_command "cmquerycl -v" "MC/SG Configuration"
    exec_command "cmviewcl -v" "MC/SG Nodes and Packages"
    exec_command "cmviewconf" "MC/SG Cluster Configuration Information"
    exec_command "cmscancl -s" "MC/SG Scancl Detailed Node Configuration"
    exec_command "netstat -in" "MC/SG Network Subnets"
    exec_command "netstat -a |fgrep hacl" "MC/SG Sockets"
    exec_command "ls -l $SGCONF" "Files in $SGCONF"
fi
dec_heading_level
##########################################################################
##
## Display Oracle configuration if applicable
## Begin Oracle Config Display
## 31jan2003 it233 FRU U.Frey

if [ -e /etc/oratab ] ; then

  paragraph "Oracle Configuration"
  inc_heading_level

  exec_command "grep -v '^#|^$|N' /etc/oratab " "Configured Oracle Databases"

  ##
  ## Display each Oracle initSID.ora File
  for  DB in `grep ':' /etc/oratab|grep -v '#'|grep -v 'N'`
       do
         Ora_Home=`echo $DB | awk -F: '{print $2}'`
         Sid=`echo $DB | awk -F: '{print $1}'`
         Init=${Ora_Home}/dbs/init${Sid}.ora
         exec_command "cat $Init" "Oracle Instance $Sid"
       done
  dec_heading_level
fi
#
# collect local files
#
if [ -f /etc/cfg2html/files ] ; then
  paragraph "Local files"
  inc_heading_level
  . /etc/cfg2html/files
  for i in $FILES
  do
    if [ -f $i ] ; then
      exec_command "egrep -v '(^#|^ *$)' $i" "File: $i"
    fi
  done
  AddText "You can customize this entry by editing /etc/cfg2html/files"
  dec_heading_level
fi

dec_heading_level

close_html
if [ `hostname -s` = "ktazd216" ]      
then                                   
        exit                           
fi                                     
{ echo "open ktazd216.crdc.kp.org      
user incoming kaiser                   
hash                                   
cd /var/adm/cfg                        
pwd                                    
site chmod 666 $HTML_OUTFILE           
put $HTML_OUTFILE                      
site chmod 666 $HTML_OUTFILE           
close"                                 
} | ftp -i -n -v 2>&1 | tee /tmp/ftplog
if [ `hostname -s` = "ktazd216" ]      
then                                   
        exit                           
fi
{ echo "open ktazd216.crdc.kp.org              
user incoming kaiser                           
hash                                           
cd /var/adm/cfg/txt                           
lcd /var/adm/cfg                               
pwd                                            
site chmod 666 $BASEFILE.linux.txt                   
put $BASEFILE.txt /var/adm/cfg/txt/$BASEFILE.linux.txt
site chmod 666 $BASEFILE.linux.txt                   
close"                                         
} | ftp -i -n -v 2>&1 | tee /tmp/ftplog2       
###########################################################################

logger "End of $VERSION"
echo -e "\n"
line

logger "End of $VERSION"
rm -f core > /dev/null

########## remove the error.log if it has size zero #######################
[ ! -s "$ERROR_LOG" ] && rm -f $ERROR_LOG 2> /dev/null

#if [ "$1" != "-x" ]
if [ "$GIF" = "no" ]
then
  exit 0
fi
echo "Creating:    JPG/GIFs"

cd $OUTDIR

# This is a shell archive.  Remove anything before this line,
# then unpack it by saving it in a file and typing "sh file".
#
# Wrapped by Guru Ralph <root@ulmx002> on Wed Sep 13 16:03:07 2000
#
# This archive contains:
#	cfg2html_back.jpg	profbull.gif
#
# Error checking via sum(1) will be performed.

LANG=""; export LANG
PATH=/bin:/usr/bin:/usr/sbin:/usr/ccs/bin:$PATH; export PATH

if sum -r </dev/null >/dev/null 2>&1
then
	sumopt='-r'
else
	sumopt=''
fi


rm -f /tmp/uud$$
(echo -e "begin 666 /tmp/uud$$\n#;VL*n#6%@x\n \nend" | uudecode) >/dev/null 2>&1
if [ X"`cat /tmp/uud$$ 2>&1`" = Xok ]
then
	unpacker () { uudecode; }
elif [ -x "/usr/bin/perl" ]
then
	unpacker () {
                      perl -ne 'if (/^begin \d\d\d (.*$)/) { open( TT, "> $1") }
                                  elsif (/^end/) { close (TT) }
                                    else { print TT unpack u, $_  }' $1;
                    }
else
	echo Compiling unpacker for non-ascii files
	pwd=`pwd`; cd /tmp
	cat >unpack$$.c <<'EOF'
#include <stdio.h>
#define C (*p++ - ' ' & 077)
main()
{
	int n;
	char buf[128], *p, a,b;

	scanf("begin %o ", &n);
	gets(buf);

	if (freopen(buf, "w", stdout) == NULL) {
		perror(buf);
		exit(1);
	}

	while (gets(p=buf) && (n=C)) {
		while (n>0) {
			a = C;
			if (n-- > 0) putchar(a << 2 | (b=C) >> 4);
			if (n-- > 0) putchar(b << 4 | (a=C) >> 2);
			if (n-- > 0) putchar(a << 6 | C);
		}
	}
	exit(0);
}
EOF
	cc -o unpack$$ unpack$$.c
	rm unpack$$.c
	cd $pwd
	unpacker () { /tmp/unpack$$ $1; }
fi
rm -f /tmp/uud$$

echo x - cfg2html_back.jpg '[non-ascii]'
unpacker <<'@eof'
begin 777 cfg2html_back.jpg
M_]C_X  02D9)1@ ! 0$ 2P!+  #_XP,.35-/(%!A;&5T=&4@;[[4?\?:B<O=X
MC\_?DM'@EM3BFM3CG=?DGMKEH=OFI-SGI]WGJ-_HK-_IK.'JK^+JLN/KM.3LX
MM>;MN>?NN^CNO>COO>GOONOOP>OPP>SQP^WQQ.[RR._SRO'TT?/WZ?O]:;K1X
M;;W3<;_4<L'5=<'6=\+6>,37><+7>\78?<79?\C:@,;:@LC;@\G;A,O;ALG<X
MALO<B,O<B,W=BLO=BLS=B\W=B\[>C<W>C<[?CL[>CL_?C]'?D,[?D-#?D<_@X
MD='@DL_@DM+@D]'AD]+@D]/AE-+AE=/AEM'AEM/AEM7BE]/AE];BF-3BF-7BX
MF=/CF=3BF=7CFM?CFMGDF]3CF]7CF]?CG-3DG-?DG=7DG=;DG=GEG=KEGM;DX
MGMCEG];EG]KEG]OEG]SFH-?EH-GEH-OFH=GEH=KFH=SFHMOFHMWGH]SFH]WFX
MH][GI-KFI-OGI-WGI=SGI=WFI=_GIMSGIMWGIM[HIM_HJ-SHJ-[HJ=[HJ=_HX
MJ=_IJMWHJN'IJ][IJ]_IJ^'IK-[IK.#IK.'IK.+JK=_JK>'IK>'JK>'KK>/JX
MKM_JKN'JKN+JK^'JK^+KK^/JK^3KL./KL>'KL>/KL>3KL>3LLN+KLN/LLN3KX
MLN7LL^/KL^3LL^7LM.7LM>3LM>7LM>?MMN3MMN7MMN?MM^;MM^?MN.3LN.;NX
MN.?MN.?NN.CNN>GNNN;NNNCNNNGON^?ON^CON^GNN^GON^GQO.COO.GMO.GOX
MO.KOO>GNO>GPO>OOONCOONCQONGNONGOONKPONOPONSPO^GPO^KPO^OOO^SOX
MP.KPP.OPP.SPP.SQP>KPP>OQP>SRP>WQPNSPPNSRPNWPPN[QP^OQP^SRP^WPX
MP^WRP^WSP^[QQ.SQQ.WRQ.[QQ.[SQ._RQ>WRQ>[RQ>_RQ?#RQ^WSQ^[RQ^_SX
MR.WSR.[SR?#SR?'SRO#SRO#TR^_TR_#UR_+TS/'TS/+USO+US_#VT/'VT//VX
MT?+WTO7WU//XU_;YVO;ZW/?[WOG\X?O]Y_W^\O__^_______7;7-_]L 0P +X
M" @*" <+"@D*#0P+#1$<$A$/#Q$B&1H4'"DD*RHH)"<G+3) -RTP/3 G)SA,X
M.3U#14A)2"LV3U5.1E1 1TA%_]L 0P$,#0T1#Q$A$A(A12XG+D5%145%145%X
M145%145%145%145%145%145%145%145%145%145%145%145%145%145%_\  X
M$0@ @ "  P$B  (1 0,1 ?_$ !D   ,! 0$               $" P0 !O_$X
M #(0  (! P(% @0& @,!      $"$0 #(1(Q!!-!46$B<3*!P=$4(Y&AX?!"X
ML5)B\23_Q  8 0$! 0$!                 0($!?_$ !T1 0 #  (# 0  X
M           !$2$Q05%A<0+_V@ , P$  A$#$0 _ /:\46N,$VZL.W8?+KYGX
ML*L.:]I(;22N7F#(-5_#A?5<,3G.Y-3>YH;0 1 F!NQZ">@[G]*Z;OAYM5R>X
M0NF8#-_UW/VJ=V\MI%U*6.K22(W&^*'#&[,7&+ [2=C3#AB45G;TJ(!/][T-X
MF,4-PZ%**"K#_$08]SM4[I)O8^&Q;-SW;9?T)!IUC0H32P!SUBD.J;RP/S")X
M/@;5(5@%JMO#D)PY#& &@'M-%;/BJ "TCE\*!)K4S;,11=37^',)I)P5.<4KX
M<.S.;ER2S'<]32W.(=; N%DUW/AM#U$#NQZ>PIK5_G*84+<&X))!'^ZFKG9VX
M)-XCERIPS'IVIU6VN#)?_CBI";5J#<+,-GWC[^*RO;:[@B$&0N\>2>I\TJRZX
M:W8J&*JP)(!( VZD?S4TYO.+YY9/P$S ^?6KH#"HPF5$F=S4[O$E$4J-:L?2X
M"8U ==MO)WI"R6[?923;TE@Q&DB<#<GMXJBN74/&E8.L9KDY;+S-!ANDY!IDX
M97T,NET.0 <$]/TH01.9KG0%0B-LSXIUTZHE78#()S%#:V)RT'/?_P!^]1M<X
M.ZOS>HW/B@I=N@9%P*-#$:0,L(A1/[^U1MWS>4I<51<(PP&#XJMZUJ2 (TF1X
M[4B\/XI%4DW:BVM-QKNK7<:28ZTUO66)< 3E?;S18DLH*R1F2>OM26Q=EB2(X
M82!@P:BK"^ !^6"Q, 9DGP(DU%KB<0SV^:I+ @B(SXH7++LJ^HZ@2)&)!I1PX
MF@"1';I5BB9E$6"I((@]:K:M%'##I5EO6GO%))8#.-Z=KB:Q;52"W4C^Q29EX
M(_,.*JQAS F?A)FE]!) P%R9WK.[W;D:"Z'4=C$#H!]9JZ%@JL5!:?5TJ4MIX
MGBU#BW=4H'0,&F0 1B>U,O#VT&9D=(^NU9+UDI=*DDA1"S_QZ"KV-36^46(TX
MY!\=OWK4QF,Q.ZLRII5&ZF0!_=J=4"C2  #G32(J60ML Q/I$?[\5#\/<OZ=X
M0RLDD;D]_P"[5EI9.;KESZ2,+.0119[C(,%FF )F,8I+S,&A5.5G&)/GP*ZPX
M+H0JY+X]);-4]&U-;M%[I56&')P/_:+<6;=D7 C<MC"N5 +>P)S[Q4+R&X+3X
MJ5N"WN  1/<BA<YO$W.9>;4T1,;"E)=*BZG$*%MW&7N(]5+>8L&ME23I VQ)X
MW)[XV\FE7AIZ5H5@K:6*E_\ MXH;/*7"H;:,I/I_Q!-5.HKD>IO/7IO4GO(;X
MBHZF& 8,>D[2.G?]*=A<-V=0"@QIGXA[46/!5X3E0Q,$;3N:Z_?-HMI5?2H8X
MZCN28  Z]<]*EQ%U@ +/I+9!7!CO\_\ 7O77%-ZU:ND#5!4TKRE]0K8XGF@ZX
M!HN;Z3D'VIKEMF80Y4#(.9FLZV2"",$;&M.K3^8Q(D1$XI/HC8UUU->D]1@UX
MR6RI! VH(UM;9N'T!LG5@CWJESB#;0@P?3J) R!WF8\5&LY2<BPH+:M+/DC)X
M&.WR%3X?B&NEEN*-1G21U\&J(4OJY#$JW0_X]L4R6%&2RB/.:J;T"H+*,1J,X
M>KS/6D=WO(X*SD#.S+.T=/YJ@YG, ]/+&"._:*[F(TJCJSQ@$SC[5!)+-P7CX
M?;XB9)^E4/,-V0L(##&-^U"Y=94W]2K.3.3@  _T"EX>X]U&Y@!<;$")%7VFX
M<'N<8+3!"20=R@ @=ZY@98.5%N('CS- 6$9B[.@DS$_M%&XB\L:V*HH(/L:FX
M+H+82,R6[1O\ZH1+:69@C;D#('6/>ICE2MG5I9,A&!!'7]:D_$7&T&W&<D$;X
M=A/?OTJ[)<0K^':X[.5B<P-@/XIAH554D9. 3$TQ+7+4@M)$PV0/E2/;4@NXX
M)Z[X!V^U0^*Z[2*Q*GTB3)  ]ZC^)5KQM,K*_21B>WCYT)%PGE'2ZN)P-P=_X
M.:(X;0X+Y8G5G?WIG9<SP%PVX!OM'1@#&^1/Z=>U%K :/5"D ;XQM_NE/#LYX
M*NX@,6$P,GKYJBVX155B #B#']%4 6^6K<H@F-^DT & ?7=$-D9G3XFIW;S7X
M%8(S DPH&('<GJ3VZ45]5O\ ^@S&,F)'FB6Y;C<38=&4*W8;%>U'\.6?FNX9X
MR9F<DU;2B"5E0-V;%#1^4PU2"#ZIG]Z6M>7&TCW"QDSU434S=M"W<92V@'27X
M48'B>_M-![86U=",==U2>VH^/E-9F+W+=M&:4MB$4  "D0DS3:&YH&EE:V1!X
M(G?Z5*Z2 BV\:1Z3V\CZ=M^U3X=2CQ_B^#6P.A+$C4XRQ+;4X6-8[5@6V#G X
M4ZB?:KI=0:PJ25,1$S[0<T>8'#Z!J88.K BNN7$LZ0VE008D1M_LTY2,)<9BX
MY4+J 'IG:3N2.I[=*'#V#:!4_ PR/K3\/?YPD#EN-UP1'BF+-ZVPW8C)^U/2X
MYR98UE L0(PL"LEZ\VC5;PK.50# ,;L>^3 Z;U?5<6W<-P0T>GO!J5U%*V$0X
MR$MP?<DDTA)X9[=VZEP-K8B<@G!^5;W:Z+GH'H4^HGJ/O6869K42P;45#" %X
M &2>F?>K*?D3IM@L56.YFEN7!;MZLL3FLQXFY^(!#3;!@QLWD?2M3(K,5)P#X
M,#,=/[\ZE5RU=\)LMQ!;@ZRLPS=^A^68FEX?AC:Q'I;$=Z-A#8ML&G2!J [>X
MU42\'+EI&G&HF9'BB1[2N7REM6M!3F%!Z@;F!L.W>GM(+P#!=)."OFBEJTJ@X
MY,[1$'YUP>+G+T2"?4>U/B_5&LBWAB-71>O\5FN<05 :TJG4< ]1W\>.M447X
M->0%MF5*XW\45M6K8 (]1V&!/SJ?2=X!7#6ET@JS8 B0,]?%+^'704U29U"<X
M9ZXJNE@P "Q\]ZSCA7O!=0^ ;^>I)[U4E:WPQ4:XP!DG:*G<N,FNW;E2( @=X
M>I_BJ&ZEL+KDF0)B?G1U%"6N1JG "S./[FB_"6W_ "&YT+'4")JBHH^(A??[X
MTJ<1;NVFN*2=(DB(([5![EUM'*=@0)8C GL!V'<[THNFTK;4>E@[= IFIL)#X
M 3(]*X_4_I@>](R&^BZS (A@!.9Z4>>EH+J=Q,KJ WC>HME'#:5DB!L*<@MKX
MT J9W(W'?&:#M=-R5]2KN6S(CH>E2O:KC7%T3G2)V ZF.Y[].E5,A1[JHG,NX
MMH62")G5]_I0O77LVE>Y:TZOA1VAR.\ 8^==?M.YMNOQV^W3S4C;>Z^JXS.^X
MQ+9-(I)LPNVN(A7#+B-).#\ZK=N%$: \K$GOG,>8[TB<*3B)JL%4$*&&TGM3X
M%B^V:UQ#<\EQ^6QV.2H]Z8\/<O2K*#ZB3 W/2?8;59;-L$RT >":%VY:12&;X
M3'IDB8\'L8I?A*S2FSKMA&:5'I.)I;MPH"JD:E41(DL?L!O3L+C%2MP*!!!!X
M^+&T=:<A&NQ$L!D45.TQNAF=5#@03&]%K=RZ2 (#(%(B3&\?WM7!TOLZ6K?,X
MT_%!]"#RQI$XRT3I8,H& P,@_I33.SI9Y6H :L015"RI;) 2!_D#/_E2;6;:X
MQI==4Q'I([8W$T+?#/;N<QIESZB<:IH?#6V6X2Q71HP#/3N*5>'6!K?"B!.<X
M>*HQ#JVO4H7J2-OIUI6LJ;2J#IM01 R(/]_>@C?NM:)12%*A="Z029W)\ ?OX
M5.'XHW)# +<CH!#?KL:%ZQBW$X&G/;I06P9!%7*3;4>;T,EX!3G6#U_L8\4+X
MM_2&C3K4#!W)/;ZGY4;=KEHZAHD[@QFF 5KC'3)&\XGV-1=!>(=^'9FU2H^"X
M<'M\JS.K/>#VRPTB QP3Y/V[5J#H;A0""1TR,?6CK#)@!1GIO'7V_P!TNBK=X
MZQJT@ $2/>HCA7=%U_ @QT'D^Y[TEL7>?S3.<$3TK02%+E]*H,ANWFG!R7%AX
M$S$G2-1@">IJ:W7O%T*P&!"L,?J*+7["*$=FD&<@DCW&]5UVPBL-.D[%9,T1X
MF O+8_#DE;4R4@9^]%>'JY6X;LLXT@D:9W'M[5R\4BW1;#,I8 @E<&=MZ7X*X
MCMUNT;6(PW3O7,Q2T6TA6G3,2!)W_BEOO<55<@,=7J!)SVGQ/3:I<*SC\NX2X
MRG8GH:5V7T9;CF\1EK). X$^_P!:%\<T,FDGU1)V ';R3U[8K22 I 59&X!SX
M_%'5I(@?%UTS%+6D;/Y-D*_1H4;U=[RVAZ@B8F22V.\5)#<+C4L6]C.\^](;X
35VYK4[,TM R8V'L.U3Z1-</_V4;U                                X
                                                             X
end
@eof
set `sum $sumopt <cfg2html_back.jpg`; if test $1 -ne 6004
then
	echo ERROR: cfg2html_back.jpg checksum is $1 should be 6004
fi

chmod 644 cfg2html_back.jpg

echo x - profbull.gif '[non-ascii]'
unpacker <<'@eof'
begin 777 profbull.gif
M1TE&.#EA#0 - /9! /__ '.#@X.4E)2DI'N+BV)S>XN<G,7-S7N+6F)S<WN+X
ME%IJ<UIS<YRLK,7-*:R]O:RTO6I[@____]7>6IRDK'.#B[2]B[2]O?;V]JRTX
M,:2LK)2<I*RTM+W%E.[V(.[N[FI[>ZR]@X.+@[W-2K3%Q:RT.8N<4I2DE+2]X
M.7.+BVI[<^;F&)RDI(.4G+2]M(N4G&)[>][FYJ2L>Z2L2G.#8O;V*6I[:H.+X
ME%)J:J2TM*2LM'.#>[W%8M[>6KW%M-[F$,W5<P                      X
M                                                            X
M                                                            X
M                                                            X
M                                                 "'Y! D& $$ X
M+      -  T   >(@$&"01,6(3(C@X,3+@\Z% 8"(HH])!</$ T#-P0P@SX'X
M,1@'FBT$ 2I!0!<'$A('D (* 0DE'0\'&!\0 Y$!!0D('3D<'!J] J<,"P@6X
M&@TL [T*!!$X"R8\!@,;&[(5 2 +"X(G+P+)*;\)"32",Q74 ;\,# 6**#L1X
/P 4,-HJ#,B 8F$%1(  [                                        X
                                                             X
end
@eof
set `sum $sumopt <profbull.gif`; if test $1 -ne 10255
then
	echo ERROR: profbull.gif checksum is $1 should be 10255
fi

chmod 644 profbull.gif

rm -f /tmp/unpack$$
exit 0
line

####################################################################
