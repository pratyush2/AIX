#!/bin/ksh
#
#set -vx
############################################################################
#
# 12/29/08	Jim Scheuer
#	Added check for Logical Domain and Zones.
#	Corrected syntax errors.
#	Corrected file paths.
#	Remove old RCS/CVS entries.
#	Removed code that was commented out along with the comments.
#	Removed sar from script since data was from midnight to 2 AM.
#	Corrected syntax errors in "if" statements
#	Added checks so that non-applicable errors are not recorded.
#	Corrected logic for SVM (DiskSuite)
#	Removed invalid web and author references.
# 01/07/09	Jim Scheuer
#	Added short version of powermt display.
#	Modified title for command powermt display dev=all.
#	Both above changes:  CHG000002464174
# 03/09/09	Jim Scheuer
#	Added version collection to support the Server Currency Project.
# 07/14/09	Jim Scheuer
#	Modified options for vxdisk and vxprint commands.
#	Added Veritas Cluster status
# 08/14/09	Jim Scheuer
#	Incorporated crontab/at section into code; eliminated plugin.
#	Added VxVM vxprint -htr; eliminated plugin
# 12/18/09	Jim Scheuer
#	Change VERSION format.
#	Test and create output directory /var/adm/cfg if needed.
#	Check if newer version of script is available and download.
#	Get build data: ABCID and NUID
#	Get VCS configuration files.
#
# 1/4/10	Jim Scheuer
#	Added check to see if mount for version update succeeded.
# 02/18/10	Randy Harvey
#	Changed FTP password for incoming user on ktazd216.
#	Updated VERSION to 3.7
#
# 3/15/10	Jim Scheuer
#	Added check for vxfentab
#	Modify source path for UID, SERIALNUMBER, and ABCID and move old files
#	to new source path.
# **************** UPDATE VERSION DATE **************************
#
#VERSION="Cfg2Html -SUN- 12/18/09"
VERSION='V3.8'
VERSIONchk='yes'

print "$VERSION"

PATH=$PATH:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/local/gnu/bin:/usr/ccs/bin:/local/X11/bin:/usr/openwin/bin:/usr/dt/bin:/usr/proc/bin:/usr/ucb:/local/misc/openv/netbackup/bin:/usr/SFW/bin:/usr/SFW/sbin:/opt/SFW/bin:/opt/SFW/sbin
export PATH
#
# use "no" to disable a collection
#
CFG_SYSTEM="yes"
CFG_KERNEL="yes"
CFG_HARDWARE="yes"
CFG_FILESYS="yes"
CFG_DISKS="yes"
CFG_NETWORK="yes"
CFG_PRINTER="yes"
CFG_CRON="yes"
CFG_PASSWD="yes"
CFG_SOFTWARE="yes"
CFG_FILES="yes"
CFG_APPLICATIONS="yes"
CFG_DISKSUITE="yes"
CFG_VXVA="yes"
CFG_VXVM="yes"
CFG_VXVCS="yes"
CFG_VXFS="yes"
CFG_SAP="yes"
CFG_LDM="yes"
CFG_ZONES="yes"
GIF="yes"
#
### Make sure we have a directory for the output and mounting.
OUTDIR="/var/adm/cfg"
MNTDIR="$OUTDIR/sunfiles"
if [ ! -e "$MNTDIR" ]; then
    mkdir -p "$MNTDIR"
fi
#
#
#
usage() {
   echo "  Usage: `basename $0` [OPTION]"
   echo "  creates HTML and plain ASCII host documentation"
   echo
   echo "  -o		set directory to write or use the environment"
   echo "		variable OUTDIR=\"/path/to/dir\" (directory must"
   echo "		exist"
   echo "  -v		output version information and exit"
   echo "  -h		display this help and exit"
   echo "  -V		disable check for new version of script"
   echo
   echo "  use the following options to disable collections:"
   echo
   echo "  -s		disable: System"
   echo "  -k		disable: Kernel"
   echo "  -H		disable: Hardware"
   echo "  -f		disable: Filesystems"
   echo "  -d		disable: Disks"
   echo "  -n		disable: Network"
   echo "  -P		disable: Printers"
   echo "  -c		disable: Cron"
   echo "  -p		disable: Passwords"
   echo "  -S		disable: Software"
   echo "  -F		disable: Files"
   echo "  -a		disable: Applications"
   echo "  -D		disable: DiskSuite"
   echo "  -L		disable: Logical Domain Manager"
   echo "  -z		disable: Zones"
   echo "  -x		don't create background images"
   echo
}
#
# getopt
#
#
while getopts ":o:skhHfdnPcpSFaDxvV" Option
do
   case $Option in
      o     ) OUTDIR=$OPTARG;;
      v     ) exit;;
      h     ) usage;exit;;
      V     ) VERSIONchk='no';;
      x     ) GIF="no";;
      s     ) CFG_SYSTEM="no";;
      c     ) CFG_CRON="no";;
      S     ) CFG_SOFTWARE="no";;
      f     ) CFG_FILESYS="no";;
      d     ) CFG_DISKS="no";;
      k     ) CFG_KERNEL="no";;
      F     ) CFG_FILES="no";;
      n     ) CFG_NETWORK="no";;
      a     ) CFG_APPLICATIONS="no";;
      p     ) CFG_PASSWD="no";;
      P     ) CFG_PRINTER="no";;
      H     ) CFG_HARDWARE="no";;
      L     ) CFG_LDM="no";;
      *     ) echo "Unimplemented option chosen.";exit 1;;   # DEFAULT
   esac
done

shift $(($OPTIND - 1))
# Decrements the argument pointer so it points to next argument.
#
# Check to see if a later version of the script is available.
#
if [ "$VERSIONchk" = 'yes' ]; then
    umount -f $MNTDIR > /dev/null 2>&1
    mount -F nfs -o ro nab-sunfiles.crdc.kp.org:/export/jumpstart/KPfiles \
        $MNTDIR &
    sleep 15
    if [ -e $MNTDIR/cfg2html_sun.sh ]; then
        NEWVERSION=`$MNTDIR/cfg2html_sun.sh -v | sed 's/$//'`
        if [[ $NEWVERSION > $VERSION ]]; then
            print "*** Getting newer version of cfg2html_sun.sh . . ."
            /usr/bin/cp /$MNTDIR/cfg2html_sun.sh /usr/local/scripts
            umount $MNTDIR
            /usr/local/scripts/cfg2html_sun.sh -V
            exit 0
        fi
        umount $MNTDIR
    else
        PID=`ps -ef | grep nab-sunfiles | grep -v grep | awk '{print $2}'`
        kill -TERM $PID
        print "@@@ ERROR: mount of $MNTDIR failed.  No version update received."
    fi
fi

CFG_HOME="/usr/local/scripts"
PLUGINS=$CFG_HOME
HTML_OUTFILE=$OUTDIR/`hostname`.html
HTML_OUTFILE_TEMP=/tmp/`hostname`.html.$$
TEXT_OUTFILE=$OUTDIR/`hostname`.txt
TEXT_OUTFILE_TEMP=/tmp/`hostname`.txt.$$
ERROR_LOG=$OUTDIR/`hostname`.err
touch $HTML_OUTFILE
[ -s "$ERROR_LOG" ] && rm -f $ERROR_LOG 2> /dev/null
DATE=`date "+%Y-%m-%d"` # ISO8601 compliant date string
DATEFULL=`date "+%Y-%m-%d %H:%M:%S"` # ISO8601 compliant date and time string
IPADDRESS=`cut -d"#" -f1 /etc/hosts | awk '{for (i=2; i<=NF; i++) if ("'$HOSTNAME'" == $i) {print $1; exit} }'`
ANTPROS=`psrinfo | awk 'END {print NR}'`
SPEED=`psrinfo -v | awk '/MHz/{print $(NF-1); exit }'`
CPU=`uname -p`
TYPE=`uname -i`
LC_TIME="" date +"%a %b %e %Y   %H:%M"
CURRDATE=`LC_TIME="" date +"%b %e %Y"`
#Let the cache expire since this script runes every night
EXPIRE_CACHE=`LC_TIME="" date "+%a, %d %b %Y "`"23:00 GMT"

# Convert illegal characters for HTML into escaped ones.
# Convert '&' first! (Peter Bisset [pbisset@emergency.qld.gov.au])
CONVSTR='
s/&/\&amp;/g
s/</\&lt;/g
s/>/\&gt;/g
s/\\/\&#92;/g
'

line ( ) {
   #echo --=[ http://come.to/cfg2html ]=-----------------------------------------------
	echo " "
}

echo "\n"

#########################################################
#    Check that you are running the script as root user
#########################################################
if [ `id|cut -c5-11` != "0(root)" ] ; then
   banner "Sorry"
   line
   echo "You must run this script as Root\n"
   exit 1
fi

exec 2> $ERROR_LOG

if [ ! -f $HTML_OUTFILE ] ; then
   banner "Error"
   line
   echo "You have not the rights to create $HTML_OUTFILE! (NFS?)\n"
   exit 1
fi

COMPUTER_NAME=`hostname`
VERSION_=`uname -r`
typeset -i HEADL=0                       #Headinglevel

osrev=`uname -r`

if [ "$osrev" -lt 2 ] ; then
   banner "Sorry"
   line
   echo "$0: Requires Solaris 2.6 or better!\n"
   exit 1
fi

####################################################################
#  Header of HTML file
####################################################################

open_html() {
   echo " \
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
<HTML> <HEAD>
 <META NAME="GENERATOR" CONTENT="Selfmade-$RCCS-vi Solaris 2.x">
 <META NAME="AUTHOR" CONTENT="James.I.Scheuer@kp.org">
 <META NAME="CREATED" CONTENT="Jim Scheuer">
 <META NAME="CHANGED" CONTENT="`id` %A%">
 <META NAME="DESCRIPTION" CONTENT="$Header: /home/CVS/cfg2html_sun/cfg2html_sun.sh,v 1.10 2004/06/03 14:33:40 ralproth Exp $DATE root Exp $">
 <META NAME="subject" CONTENT="$VERSION on $COMPUTER_NAME by t505414@online.no">
<TITLE>${COMPUTER_NAME} - Documentation - $VERSION</TITLE>
</HEAD><BODY>
<BODY LINK="#0000ff" VLINK="#800080" BACKGROUND="cfg2html_back.jpg">
<H1><CENTER><FONT COLOR=blue>
<P><hr><B>$COMPUTER_NAME - SunOS "`uname -r`" System Documentation</P></H1>
<hr><FONT COLOR=blue><small>Created "$DATEFULL" with " $VERSION "</font></center></B></small>
<HR><H1>Contents\n</font></H1>\n\
" >$HTML_OUTFILE

   #(line;banner $COMPUTER_NAME;line) > $TEXT_OUTFILE
   echo "\n" > $TEXT_OUTFILE
   echo "\n" > $TEXT_OUTFILE_TEMP
}

######################################################################
#  Increases the heading level
######################################################################

inc_heading_level() {
   HEADL=HEADL+1
   ##
   ## no we want to have it otherways
   ## it233 U.Frey
   ##echo "<UL>\n" >> $HTML_OUTFILE
   echo "<UL type='square'>\n" >> $HTML_OUTFILE        # !!!!!
}

######################################################################
#  Decreases the heading level
######################################################################

dec_heading_level() {
   HEADL=HEADL-1
   echo "</UL>\n" >> $HTML_OUTFILE
}

######################################################################
#  Creates an own paragraph, $1 = heading
######################################################################

paragraph() {
   if [ "$HEADL" -eq 1 ] ; then
      echo "\n<HR>\n" >> $HTML_OUTFILE_TEMP
   fi
   echo "<A NAME=\"$1\">" >> $HTML_OUTFILE_TEMP
   echo "<A HREF=\"#Inhalt-$1\"><H${HEADL}> $1 </H${HEADL}></A><P>" >> $HTML_OUTFILE_TEMP

   echo "<A NAME=\"Inhalt-$1\"></A><A HREF=\"#$1\">$1</A>" >> $HTML_OUTFILE
   echo "\nCollecting: " $1 " .\c"
   #echo "    $1" >> $TEXT_OUTFILE
}

######################################################################
#  Documents the single commands and their output
#  $1  = unix command,  $2 = text for the heading
######################################################################

exec_command() {
   if [ -z "$3" ] ; then	# if string 3 is zero
      TiTel="$1"
   else
      TiTel="$3"
   fi


   echo ".\c"

   echo "\n---=[ $2 ]=----------------------------------------------------------------" | cut -c1-74 >> $TEXT_OUTFILE_TEMP
   #echo "       - $2" >> $TEXT_OUTFILE
   ######the working horse##########
   TMP_EXEC_COMMAND_ERR=/tmp/exec_cmd.tmp.$$
   EXECRES=`eval $1 2> $TMP_EXEC_COMMAND_ERR | expand | cut -c 1-150 | sed "$CONVSTR"`
   if [ -z "$EXECRES" ] ; then
      EXECRES="n/a"
   fi
   if [ -s $TMP_EXEC_COMMAND_ERR ] ; then
      echo "stderr output from \"$1\":" >> $ERROR_LOG
      cat $TMP_EXEC_COMMAND_ERR | sed 's/^/    /' >> $ERROR_LOG
   fi
   rm -f $TMP_EXEC_COMMAND_ERR

   echo "\n" >> $HTML_OUTFILE_TEMP
   echo "<A NAME=\"$2\"></A> <A HREF=\"#Inhalt-$2\" title=\"$TiTel\"><H${HEADL}> $2 </H${HEADL}></A>\n" >>$HTML_OUTFILE_TEMP
   echo "<PRE><B>$EXECRES</B></PRE>\n"  >>$HTML_OUTFILE_TEMP
   echo "<meta http-equiv=\"expires\" content=\"${EXPIRE_CACHE}\">">>$HTML_OUTFILE_TEMP
   # echo "<PRE><SMALL><B>$EXECRES</B></SMALL></PRE>\n"  >>$HTML_OUTFILE_TEMP
   echo "<LI><A NAME=\"Inhalt-$2\"></A><A HREF=\"#$2\" title=\"$TiTel\">$2</A>\n" >> $HTML_OUTFILE
   echo "\n$EXECRES\n" >> $TEXT_OUTFILE_TEMP
}

################# Schedule a job for killing commands which ###############
################# may hang under special conditions. <mortene@sim.no> #####
# Argument 1: regular expression to search processlist for. Be careful
# when specifiying this so you don't kill any more processes than
# those you are looking for!
# Argument 2: number of minutes to wait for process to complete.
######################################################################

KillOnHang() {
   TMP_KILL_OUTPUT=/tmp/kill_hang.tmp.$$
   at now + $2 minutes 1>$TMP_KILL_OUTPUT 2>&1 <<EOF
   ps -ef | grep root | grep -v grep | egrep $1 | awk '{print \$2}' | sort -n -r | xargs kill
EOF
   AT_JOB_NR=`egrep '^job' $TMP_KILL_OUTPUT | awk '{print \$2}'`
   rm -f $TMP_KILL_OUTPUT
}

######################################################################
# You should always match a KillOnHang() call with a matching call
# to this function immediately after the command which could hang
# has properly finished.
CancelKillOnHang() {
   at -r $AT_JOB_NR
}

################# adds a text to the output files, rar, 25.04.99 ##########

AddText() {
   echo "<p>$*</p>" >> $HTML_OUTFILE_TEMP
   echo "$*\n" >> $TEXT_OUTFILE_TEMP
}

######################################################################
#  end of the html document
######################################################################

close_html() {
   echo "<hr>" >> $HTML_OUTFILE
   echo "</P><P>\n<hr><FONT COLOR=blue>Created "$DATEFULL" with " $VERSION " </A></P></font>" >> $HTML_OUTFILE_TEMP
   echo "</P><P>\n<FONT COLOR=blue>Based on the original script by <A HREF=/quot mailto:cfg2html&#64;&#104;&#111;&#116;&#109;&#97;&#105;&#108;&#46;&#99;&#111;&#109?subject=$VERSION_/quot >Ralph Roth</A></P></font>" >> $HTML_OUTFILE_TEMP
   cat $HTML_OUTFILE_TEMP >>$HTML_OUTFILE
   cat $TEXT_OUTFILE_TEMP >> $TEXT_OUTFILE
   rm $HTML_OUTFILE_TEMP $TEXT_OUTFILE_TEMP
      echo "\n\nCreated "$DATEFULL" with " $VERSION " \n" >> $TEXT_OUTFILE
}

######################################################################
#######################  M A I N  ####################################
######################################################################
line
##
##
## Bug corrected on display output files, no $PWD
## must be used here
## 30Jan2003 it233 U.Frey
echo "Starting          "$VERSION" on a "`uname -rsi`" box"
echo "Path to cfg2html  "$0
echo "Path to plugins   "$PLUGINS
echo "HTML Output File  "$HTML_OUTFILE
echo "Text Output File  "$TEXT_OUTFILE
echo "Errors logged to  "$ERROR_LOG
echo "Started at        "$DATEFULL
echo "Problem           If cfg2html hangs on Hardware, press twice ENTER"
echo "                  or Crtl-D. Then check or update your Diagnostics!"
echo "WARNING           USE AT YOUR OWN RISK!!! :-))"
#echo "License      Freeware"
line

logger "Start of $VERSION"
open_html
inc_heading_level

######################################################################
if [ "$CFG_SYSTEM" != "no" ] ; then

   paragraph "Solaris/System"
   inc_heading_level

   exec_command "echo $VERSION" "CFG2HTML Version"
   exec_command "hostname" "Hostname"
#
# Move files in old location to new location.
   if [ -f /SERIAL_NUMBER ]; then
       mv /SERIAL_NUMBER /var/adm
   fi
   if [ -f /NUID ]; then
       mv /NUID /var/adm
   fi
   if [ -f /ABCID ]; then
       mv /ABCID /var/adm
   fi
   exec_command "cat /var/adm/SERIAL_NUMBER" "Serial Number"
   exec_command "cat /var/adm/NUID" "NUID of Build Engineer"
   exec_command "cat /var/adm/ABCID" "ABCID"
   exec_command "uname -sr" "OS version"
   exec_command "cat /etc/release" "Release version"
   exec_command "uname -mi" "Hardware type"
   exec_command "date" "System Date"
   exec_command "prtconf | awk '/^Memory size:/ { print $3 }'" "Memory size"
   exec_command "echo 'CPU's:' $ANTPROS of type $CPU $SPEED MHz" "CPU's"
   exec_command "uptime" "Uptime and load"
   if [ -f /etc/ppserv.settings ]
   then
       exec_command "echo 'UAM - Symark installed'" "UAM - Symark"
   else
       exec_command "echo 'NOT INSTALLED'" "UAM - Symark"
   fi

   dec_heading_level

fi

###########################################################################
#	Kernel Information
###########################################################################
if [ "$CFG_KERNEL" != "no" ] ; then

   paragraph "Kernel"
   inc_heading_level

   exec_command "modinfo" "Loaded kernel modules"
   exec_command "sysdef -D" "System peripheral device driver"
   if [ -e "/etc/system" ] ; then
      exec_command "cat /etc/system" "Parameter in /etc/system"
      exec_command "ls -l /etc/system*" "Boot types of /etc/system"
   fi

   dec_heading_level

fi

######################################################################
#	Harware Information
###########################################################################
if [ "$CFG_HARDWARE" != "no" ] ; then

   paragraph "Hardware"
   inc_heading_level

   exec_command "/usr/platform/`uname -i`/sbin/prtdiag -v" "Hardware (prtdiag)"
   exec_command "prtconf -v" "Hardware (prtconf)"
   if [ -e /usr/sbin/fcinfo ]; then
      exec_command "/usr/sbin/fcinfo hba-port -l" "HBA (fcinfo hba-port -l)"
   fi
   if [ -e /usr/sbin/lpfc/lputil ]; then
      exec_command "/usr/sbin/lpfc/lputil rev lpfc0" "HBA (lputil rev lpfc0)"
      exec_command "/usr/sbin/lpfc/lputil rev lpfc1" "HBA (lputil rev lpfc1)"
   fi
   #exec_command "sysinfo -class Device" "Devices"

   dec_heading_level

fi

######################################################################
#	Filesystem Information
###########################################################################
if [ "$CFG_FILESYS" != "no" ] ; then

   paragraph "Filesystems, dump and swap configuration"
   inc_heading_level

   ##
   ## we want to display the boot types
   ## of vfstab too
   ## 30Jan2003 it233 U.Frey
   if [ -e "/etc/vfstab" ] ; then
      exec_command "ls -l /etc/vfstab*" "Boot types of /etc/vfstab"
   fi

   exec_command "df -k" "Filesystems and usage"

   if [ -f /etc/exports ] ; then
      exec_command "cat /etc/exports|grep -v '^#'" "NFS filesystems"
   fi
   exec_command "swap -l" "Swap"

   exec_command "vmstat -s" "Kernel paging events"
   dec_heading_level
fi

###########################################################################
if [ "$CFG_DISKS" != "no" ] ; then

   paragraph "Disks"
   inc_heading_level

   disklist () {
   if [ -d "/opt/IBMdpo" ] ; then
     format <<-EOF | grep "^ *[0-9][0-9]*\. " | awk '{ print $2 }' | grep -v vpath
EOF
   else
     format <<-EOF | grep "^ *[0-9][0-9]*\. " | awk '{ print $2 }'
EOF
   fi
   }

   verdisk () {
      format -d $1 <<-EOF | sed '1,/format> /d' | sed 's/format> //g'
      verify
      inquiry
      quit
EOF
   }

   for i in `disklist`
   do
      exec_command "verdisk $i 2>&1" "Disk $i"
   done

   dec_heading_level

#####################
### EMC Powerpath ###
#####################

   if [ -e "/opt/EMCpower/bin/powermt" ] ; then

      paragraph "EMC"
      inc_heading_level

      EMCver=`pkginfo -l EMCpower | grep -i version:`
      exec_command "echo $EMCver" "EMCpower version"

      ##
      ## if there are EMC Disks display them with inq
      ## 30Jan2003 it233 U.Frey
      if [ -e "/opt/emc/SInquiry/V4.1/bin/inq" ] ; then
	 exec_command "/opt/emc/SInquiry/V4.1/bin/inq" "EMC disks inquire"
      fi
      ##
      ## if EMCpower is installed display the powermt output
      ## 30Jan2003 it233 U.Frey
      if [ -e "/opt/EMCpower/bin/powermt" ] ; then
         exec_command "/opt/EMCpower/bin/powermt display" "State of PowerPath hba(s)"
	 exec_command "/opt/EMCpower/bin/powermt display dev=all" "Detail of PowerPath hba(s)"
      fi

      dec_heading_level
   fi
fi

###########################################################################
if [ "$CFG_DISKSUITE" != "no" ] ; then

  paragraph "Solstice DiskSuite"
  inc_heading_level
  # Modify for use in old version of SDS
  if [ -e "/usr/opt/SUNWmd/sbin/metadb" ] ; then
	  pathsds="/usr/opt/SUNWmd/sbin"
  fi
  if [ -e "/usr/sbin/metadb" ] ; then
	  pathsds="/usr/sbin"
  fi

  if [ -e "$pathsds/metadb" ] ; then
      $pathsds/metadb -i > /dev/null 2>&1
      if [ $? -eq 0 ] ; then
          exec_command "$pathsds/metadb -i" "Status SDS metadb"

          DSVER=`pkginfo -l SUNWmdu | grep -i version:`
          exec_command "echo $DSVER" "DiskSuite version" "pkginfo -l SUNWmdu"
  
          for i in metadb metastat ; do
              exec_command "$pathsds/$i" "$i"
          done

          exec_command "$pathsds/metastat -t" "Status SDS devices"
      fi
  fi

  dec_heading_level
fi

###########################################################################
if [ "$CFG_NETWORK" != "no" ] ; then

   paragraph "Network Settings"
   inc_heading_level

   exec_command "ifconfig -a" "ifconfig"
   exec_command "netstat -an" "list of all sockets"
   exec_command "netstat -in" "list of all IP addresses"
   exec_command "netstat -rvn" "list of all routing table entries"
   exec_command "cat /etc/resolv.conf" "resolv.conf"
   exec_command "ypwhich 2>&1" "ypwhich"
   exec_command "domainname" "domainname"
   exec_command "nslookup `hostname`" "nslookup hostname"

   dec_heading_level
fi

###########################################################################
if [ "$CFG_PRINTER" != "no" ] ; then

   paragraph "Printers"
   inc_heading_level

   exec_command "lpstat -s" "Configured printers"
   exec_command "lpstat -d" "Default printer"
   exec_command "lpstat -t" "Status printers"

   dec_heading_level
fi

###########################################################################
if [ "$CFG_CRON" != "no" ] ; then

   paragraph "cron and at"
   inc_heading_level

   paragraph "Crontab Scheduler"
   CRON_PATH=/var/spool/cron/crontabs
   inc_heading_level
   for i in `ls $CRON_PATH`; do
      exec_command "cat $CRON_PATH/$i | grep -v ^#" "Crontab for $i"
   done ;
   dec_heading_level

   exec_command "at -l" "AT Scheduler"

   dec_heading_level

fi

###########################################################################
if [ "$CFG_PASSWD" != "no" ] ; then

   paragraph "Passwords and group consistency"
   inc_heading_level

   exec_command "cat /etc/passwd | sed 's&:.*:\([-0-9][0-9]*:[-0-9][0-9]*:\)&:x:\1&'" "/etc/passwd"
   exec_command "pwck 2>&1" "Errors found in passwd"
   exec_command "cat /etc/group" "/etc/group"
   exec_command "grpck 2>&1" "Errors found in group"

   dec_heading_level

fi

######################################################################
#  patch statistics
######################################################################
if [ "$CFG_SOFTWARE" != "no" ] ; then

   paragraph "Software"
   inc_heading_level

   #list_pkg () {
   #pkginfo -l | awk '/^ *PKGINST:/{print}
		     #/^ *NAME:/{print}
		     #/^ *CATEGORY:/{print}
		     #/^ *VERSION:/{print}
		     #/^$/{print}' |
   #sed '/^ *PKGINST:/{s/^ *PKGINST: *//; s/$/;/;}
	#/^ *NAME:/{s/^ *NAME: *//; s/$/;/;}
	#/^ *CATEGORY:/{s/^ *CATEGORY: *//; s/,.*//; s/$/;/;}
	#/^ *VERSION:/{s/^ *VERSION: *//;}' |
   #sed -n '/./{
	   #h
	   #:top
	   #n
	   #/./H
	   #/./b top
	   #g
	   #s/\n//g
	   #p
	   #}' |
   #sed 's/^\([^;]*\);\([^;]*\);\([^;]*\);\([^;]*\)$/\3;\1;\4; \2 ;/'
   #}

   #exec_command "list_pkg | sed 's/ ;$//' | tr ';' '\011' | expand -t1,12,26,60" "Filesets installed "

   exec_command "pkginfo " "Filesets installed "
   exec_command "showrev -p" "Patches installed "

   dec_heading_level

fi

######################################################################
#  files statistics
######################################################################
if [ "$CFG_FILES" != "no" ] ; then

   paragraph "Files"
   inc_heading_level
   exec_command "cat /etc/inittab" "/etc/inittab"
   exec_command "cat /etc/aliases" "/etc/aliases" 
   exec_command "cat /etc/hosts" "/etc/hosts" 
   if [ -f '/etc/inet/ntp.conf' ]; then
       exec_command "cat /etc/inet/ntp.conf" "/etc/inet/ntp.conf"
   else
       exec_command "cat /etc/ntp.conf" "/etc/ntp.conf" 
   fi
   exec_command "cat /etc/pam.conf" "/etc/pam.conf"
   exec_command "cat /etc/resolv.conf" "/etc/resolv.conf" 
   exec_command "cat /etc/syslog.conf" "/etc/syslog.conf"
   exec_command "cat /etc/printers.conf" "/etc/printers.conf"
   exec_command "cat /etc/nsswitch.conf" "/etc/nsswitch.conf" 
   exec_command "cat /etc/nfssec.conf" "/etc/nfssec.conf"
   exec_command "cat /etc/nscd.conf" "/etc/nscd.conf" 
   exec_command "cat /etc/inetd.conf" "/etc/inetd.conf"
   exec_command "cat /etc/services" "/etc/services"
   ps -ef | grep ssh | grep local > /dev/null 2>&1
   if [ $? -eq 0 ]; then
       exec_command "cat /usr/local/etc/ssh_config" "/usr/local/etc/ssh_config"
       exec_command "cat /usr/local/etc/sshd_config" "/usr/local/etc/sshd_config"
   else
       exec_command "cat /etc/ssh/ssh_config" "/etc/ssh/ssh_config"
       exec_command "cat /etc/ssh/sshd_config" "/etc/ssh/sshd_config"
   fi
   files()
   {
      ls /etc/rc2.d/*
      ls /etc/rc3.d/*
   }
   COUNT=1
   for FILE in `files`
   do
      exec_command "cat ${FILE}" "${FILE}"
      COUNT=`expr $COUNT + 1`
   done

   dec_heading_level

fi

##########################################################################
if [ "$CFG_APPLICATIONS" != "no" ] ; then

#  paragraph "Applications and subsystems"

   ## we want to display HP OpenVantage Operations configurations
   ## 31Jan2003 it233 FRU U.Frey
   if [ -e /opt/OV/bin/OpC/utils/opcdcode ] ; then

      paragraph "HP Openview"
      inc_heading_level
      if [ -e /opt/OV/bin/OpC/install/opcinfo ] ; then
	 exec_command "cat /opt/OV/bin/OpC/install/opcinfo" "HP Openview info, Version"
      fi

      if [ -e /var/opt/OV/conf/OpC/monitor ] ; then
	 exec_command "/opt/OV/bin/OpC/utils/opcdcode /var/opt/OV/conf/OpC/monitor | grep DESCRIPTION" "HP Openview Configuration Monitor"
      fi

      if [ -e /var/opt/OV/conf/OpC/le ] ; then
	 exec_command "/opt/OV/bin/OpC/utils/opcdcode /var/opt/OV/conf/OpC/le | grep DESCRIPTION" "HP Openview Configuration Logging"
      fi

      dec_heading_level

   fi

#-------------------------
   ## we want to display Veritas netbackup configurations
   ## 31Jan2003 it233 FRU U.Frey
   if [ -e /usr/openv/netbackup/bp.conf ] ; then

      paragraph "Veritas Netbackup"
      inc_heading_level
      if [ -e /usr/openv/netbackup/version ] ; then
	 exec_command "cat /usr/openv/netbackup/version" "Veritas Netbackup version"
      fi
      exec_command "cat /usr/openv/netbackup/bp.conf" "Veritas Netbackup configuration"

      dec_heading_level

   fi

   ### VXVM ##################################################################
   if [ "$CFG_VXVM" != "no" ] ; then

      paragraph "VxVM"
      inc_heading_level

      pkginfo VRTSvxvm > /dev/null 2>&1
      if [ $? -eq 0 ]; then
	 VXVMVER=`pkginfo -l VRTSvxvm | grep -i version: | awk '{ print $2 }'`
	 exec_command "echo $VXVMVER" "VxVM version" "pkginfo -l VRTSvxvm"
	 exec_command "vxdisk -o alldgs list" "vxdisk -o alldgs list"
	 for i in `vxdg list |awk '{print ($1)}'|grep -v NAME` ; do
	    exec_command "vxdg list $i" "$i"
	 done
         exec_command "vxprint -htr" "vxprint -htr"
	 exec_command "vxdg free" "vxdg free"
         
         if [ -f /etc/vx/elm/* ] ; then
           exec_command "vxlicense -p" "vxlicense -p" # for <3.5 only
           for i in `ls /etc/vx/elm/*` ; do
	     exec_command "cat $i" "license file $i"
	   done
         fi
         if [ -f /etc/vx/licenses/lic/* ] ; then
              # for >3.5 only
              if [ -f /opt/VRTSvlic/bin/vxlicrep ] ; then
                  exec_command "/opt/VRTSvlic/bin/vxlicrep" "VXVM licensing"
              else
	          exec_command "vxlicrep" "VXVM licensing" 
              fi
         fi
     fi

      dec_heading_level
   fi

  ### VXVCS ##################################################################
   if [ "$CFG_VXVCS" != "no" ] ; then

      paragraph "VxVCS"
      inc_heading_level

      if [ -e /opt/VRTSvcs/bin/hastatus ]; then
         exec_command "/opt/VRTSvcs/bin/hastatus -sum" "hastatus -sum"
         exec_command "cat /etc/gabtab" "VCS /etc/gabtab"
         exec_command "cat /etc/llttab" "VCS /etc/llttab"
         exec_command "cat /etc/VRTSvcs/conf/config/main.cf" "VCS main.cf"
         exec_command "cat /etc/vxfentab" "vxfentab"
      fi

      dec_heading_level
   fi

   ### VXFS ##################################################################
   if [ "$CFG_VXFS" != "no" ] ; then

      paragraph "VxFS"
      inc_heading_level

      pkginfo VRTSvxfs > /dev/null 2>&1
      if [ $? -eq 0 ] ; then
	 VXFSVER=`pkginfo -l VRTSvxfs | grep -i version: | awk '{ print $2 }'`
	 exec_command "echo $VXFSVER" "VxFS version" "pkginfo -l VRTSvxfs"
      fi

      dec_heading_level
   fi
   ### Oracle ####################################
   if [ -f /etc/oratab ] ; then

       paragraph "Oracle"
       inc_heading_level
   #
   ###
       exec_command "cat /etc/oratab | grep -v '^#|^$|N'" "Configured Oracle databases"
       ##
       ## we want each Sid displayed with title
       for  DB in `grep ':' /etc/oratab|grep -v '#'|grep -v 'N'`
	  do
	    Ora_Home=`echo $DB | awk -F: '{print $2}'`
	    Sid=`echo $DB | awk -F: '{print $1}'`
	    Init=${Ora_Home}/dbs/init${Sid}.ora
	    exec_command "cat $Init" "Oracle Instance $Sid"
	  done
       dec_heading_level
   fi

   ###########################################################################
   if [ "$(grep 'informix' /etc/passwd)" != "" ] ; then

      paragraph "Informix"
      inc_heading_level
      exec_command "su - informix -c \"onstat -l\"" "Configured Informix databases"
      dec_heading_level
   fi

   ###########################################################################
   if [ "$CFG_SAP" = "yes" ] ; then

      if [ -d /usr/sap ] ; then
	 paragraph "SAP R3"
	 inc_heading_level
	 exec_command $PLUGINS/get_sap.sh "SAP R3 configuration"

	 [ -f /etc/sapconf ] && exec_command "cat /etc/sapconf" "Local configured SAP R3 instances"
	 dec_heading_level
      fi
   fi

   #######################################################################
   # Logical Domain Manager
   #######################################################################
   if [ "$CFG_LDM" = "yes" ] ; then

      paragraph "Logical Domain Manager"
      inc_heading_level

      pkginfo SUNWldm > /dev/null 2>&1
      if [ $? -eq 0 ]; then
         LDMVER=`pkginfo -l SUNWldm | grep -i version: | awk '{ print $2 }'`
         exec_command "echo $LDMVER" "LDM version"
         exec_command "/opt/SUNWldm/bin/ldm list-domain" "LDM list"
         exec_command "/opt/SUNWldm/bin/ldm list-domain -l" "LDM full list"
     fi

     dec_heading_level
   fi

   #######################################################################
   # Zones
   #######################################################################
   if [ "$CFG_ZONES" = "yes" ] ; then
      paragraph "ZONES"
      inc_heading_level

      /usr/sbin/pooladm > /dev/null 2>&1
      if [ $? -eq 0 ]; then
         exec_command "/usr/sbin/pooladm" "Resource Pool"
      else
         exec_command "echo 'n/a'" "Resource Pool"
      fi
      exec_command "/usr/sbin/zoneadm list -cv" "Zone status"

      dec_heading_level
   fi

   ########################################################################
   paragraph "Software Versions"
   inc_heading_level
   if [ -d /usr/Tivoli/lcf ]; then
      tivendpt=`find /usr/Tivoli/lcf -name "LCF*.SIG"`
      tivendpt=`echo $tivendpt | sed 's/.*LCF//' | sed 's/\.SIG//'`
      exec_command "echo $tivendpt" "Tivoli Endpoint Version"
   fi
   exec_command "ssh -V 2>&1" "SSH Version"
   exec_command "sudo -V 2>&1" "SUDO Version"
   pkginfo -q SMCntp
   if [ "$?" -eq 0 ]; then
      exec_command "pkginfo -l SMCntp | grep VERSION:" "NTP Version"
   else
      exec_command "pkginfo -l SUNWntpu | grep VERSION:" "NTP Version"
   fi
   exec_command "perl -v" "PERL Version"
   exec_command "lsof -v 2>&1" "LSOF Version"
   exec_command "java -version 2>&1" "JAVA Version"
   exec_command "top -version 2>&1" "TOP Version"
   exec_command "pkginfo -l VRTSvcs | grep VERSION:" "Veritas Cluster Service"
   exec_command "pkginfo -l SUNWsc | grep VERSION:" "Sun Cluster Version"
   exec_command "pkginfo -l TIVsmCba | grep VERSION:" "TSM Version"

fi # terminates CFG_APPLICATIONS wrapper

close_html
if [ `hostname` = "ktazd216" ]         
then                                      
        exit                              
fi                                        
{ echo "open ktazd216.crdc.kp.org         
user incoming \$1DB3fac7                      
hash                                      
cd /var/adm/cfg                           
pwd                                       
quote site chmod 666 $HTML_OUTFILE              
put $HTML_OUTFILE                         
quote site chmod 666 $HTML_OUTFILE              
close"                                    
} | ftp -i -n -v 2>&1 | tee /tmp/ftplog   
if [ `hostname` = "ktazd216" ]           
then                                        
        exit                                
fi                                          
{ echo "open ktazd216.crdc.kp.org           
user incoming \$1DB3fac7                        
hash                                        
cd /var/adm/cfg/txt                        
lcd /var/adm/cfg                            
pwd                                         
quote site chmod 666 /var/adm/cfg/txt/`hostname`.sun.txt                
put /var/adm/cfg/`hostname`.txt /var/adm/cfg/txt/`hostname`.sun.txt                           
quote site chmod 666 /var/adm/cfg/txt/`hostname`.sun.txt                
close"                                      
} | ftp -i -n -v 2>&1 | tee /tmp/ftplog2    
###########################################################################

logger "End of $VERSION"
echo "\n"
line

rm -f core > /dev/null

########## remove the error.log if it has size zero #######################
[ ! -s "$ERROR_LOG" ] && rm -f $ERROR_LOG 2> /dev/null

if [ "$1" != "-x" ] ;then
   exit 0
fi
