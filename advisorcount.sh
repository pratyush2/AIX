#!/bin/ksh
# @(#)/usr/local/scripts/advisorcount.sh
# @(#)v1.10 01/12/2007
#
# Generate a report of both the status and advisor information on
# Websphere Load Balancer servers (WSLB 5.x).
#
# usage: advisorcount.sh [-v]
#
# Notes:
# Screen output is normally suppressed. Use the "-v" option as necessary.
# The -v option provides a verbose mode with screen output.
# 
# Change History:
# 01/12/07 v1.10 dbl	SunOS/ND4.0.2 update and bug fix:
#			1) Added support for SunOS 5.8 with ND 4.0.2.x (tested
#			   on SunOS 5.8 with ND 4.0.2.38). Note: this script is 
#			   only for AIX with WSLB 5.0.2.x and SunOS 5.8 with
#			   WSND 4.0.2.x. Other combinations have not been
#			   tested.
#			2) bug fix: corrected condition where a present but
#			   null $LOG would not have the first line of
#			   asterisks printed.
#			3) Added six asterisks to startsession() and
#			   endsession() log entries for clarity
# 12/11/06 v1.01 dbl	Speed improvement and code fixes:
# 			1) Script only picks up the first octet for dotted
#			   addresses (xxx.xxx.xxx.xxx). Corrected for the
#			   condition where the address is on the line before
#			   the metric data from dscontrol.
# 		 	2) Script only picks up the first octet for dotted
#			   addresses (xxx.xxx.xxx.xxx). Corrected for the
#			   condition where the address is on the same line as
#			   the metric data from dscontrol.
# 			3) Load balancers with many clusters/servers takes
#			   more than 15 minutes to process. Shortened the
#			   run time to ~ 2 minutes. Converted to a single-pass
#			   process.
#			4) Corrected excessive Java CPU utilization (due to 
#			   previous run-time method and duration).
# 			5) Avoid duplicate scripts in memory. If the script is
#			   already running, exit.
# 12/01/06 v1.00 dbl	General Release
# 11/13/06 v0.94 dbl	Minor code fix:
#			1) Library issue in AIX 5.2 ML2 with [[...==...]]
#			construct. Changed to [[...=...]].
# 11/09/06 v0.93 dbl	Recoding as follows:
#			1) Dropping the summed output file. Capacity planning
#			   will use the "server" output file and use post-
#			   processing in SAS to aggregate the counts by
#			   cluster and port.
#			2) Moving the date field to the beginning of each line.
#			3) Dynamically capture the cluster information instead
#			   of reading the config file.
#			4) Adding a check for the dscontrol file.
#			5) Report servers in a cluster whether they have a
#			   host.domain or just a host entry in the 
#			   dscontrol serv rep <cluster>:<port>:  output.
#			   This is needed due to an limitation in the 
#			   DNS resolver that limits us to 6 domains. Anything
#			   beyond that requires a fully qualified name in the
#			   WSLB cluster config. file.
#			6) Read the correct field when a WAS server uses
#			   a host.domain name in the above output.
#			7) Set $DATE just before metrics are read from memory.
#			8) Made some code improvements.
# 11/02/06 v0.92 dbl	Recoding as follows:
#			1) Separate output streams. One stream for summed data
#			   (by cluster). The second stream for advisor data on
#			   each WAS server.
#			2) Renamed the output file(s) to support separate ouput
#			   streams. (i.e. ktazd1483.061101 becomes
#			   ktazd1483clusters.061101. The server stream becomes
#			   ktazd1483servers.061101
#			3) Converted some inline code to functions.
# 11/02/06 v0.91 dbl	Recoding as follows:
#			1) Each port for each cluster will be output on a
#			   separate line.
#			2) Adding a field in the output file to support the
#			   port number.
#			3) Adding more WSLB version checks to address config.
#			   and exec. files being in different locations.
#			4) Adding more error detection and logging logic.
#			5) Added -v command line variable to suppress screen
#			   output unless desired.
# 11/01/06 v0.90 dbl	Recoded as follows:
#			1) Moved to standard location: /usr/local/scripts.
#			2) Renamed from advisorcounts.sh to advisorcount.sh
#			3) Added variables to improve future flexibility
#			4) Separated variables to eliminate "overloading"
#			   (reusing) variables for different purposes.
#			5) Added a log. maximum $logsize=512 Kbytes. Excess
#			   size is rolled to a $LOG.old, overwriting any 
#			   previous $LOG.old.
#			6) Clusters will report all ports on a single line.
#			   The advisorcounts.sh script will read the WSLB
#			   "config" file (dynamically) and glean the cluster
#			   associations each time it is run to ensure that
#			   any WSLB "permanent" changes are captured without
#			   having to hardcode the cluster info into the script.
#			7) FOR v0.91 (NEXT VERSION): Each port for each cluster
#			   will be output on a separate line.
# 10/24/06 dbl		Added additional clusters on ktazp1542 and 1543.
#			Recoded a few things to help with the cluster expansion.
# 04/08/03 saul 	added new clusters to this report; irpf,ehs,aud, and lat
# 8/7/02   kwl		fix sumcount.awk and modified the script to add new
#			cluster auth
# 7/30/02  fs		added rul, cc , wfm2, wfm3.  changed cmt1 to cmt2 for
#			consistency
# 8/15/01  tyw		added cmt and cmt1

##### VARIABLE DECLARATIONS #####
# Integers #
integer cps					#Server connections/sec
integer kbps					#Server KBytes/sec
integer total					#Server total connections
integer active					#Server active connections
integer fined					#Server finishing connections
integer comp					#Server completed connections
integer num					#reusable counting variable
integer verbose					#screen ouput: 0=no, 1=yes
integer field					#for awk script field selection
integer dupval					#for duplicate script detection
integer errorval=0				#error logging
integer warningval=0				#warning logging
integer old=7					#days of output files to retain
integer loglevel=1				#Log verbosity: 0=off, 1=0n
integer logsize=512				#max. $log size in Kbytes.

# Directories #
OUTDIR=/var/tmp					#output file directory
LOGDIR=/var/tmp					#log file directory
LBBINDIR=""					#WSLB binaries
LBCFGDIR=""					#WSLB configuration files
SCRIPTDIR=/usr/local/scripts			#shell script(s) location
TMPDIR=/tmp					#Temporary directory
BIN=/usr/bin					#binary files (i.e. awk)

# Files and everything else #
SV=""						#used for awk statement
FN=""						#used for cleanup
EXT=`date +"%y%m%d"`				#output file extension (yymmdd)
HOST=`hostname`					#for output file extension
FILE=ndadvisor					#output file name
OUTPUT=${FILE}_${HOST}.${EXT}			#individual WAS server metrics
LOG=$LOGDIR/advisorcount.log			#log file
CFILE=advisorcount.clusters			#Cluster names (tmp)
COUNTFILE=advisorcount.count			#WSLB advisor values file
TMPFILE=advisorcount.tmp			#Temp file for formating CFILE
DATE=`date +"%Y%m%d%H%M"`			#Y2K formatted date for output
LBVER=""					#WSLB Version
LINE=""						#Used for reading from files
LASTLINE=""					#Used for formatting CFILE
CATLINE=""					#Used for formatting CFILE

##### FUNCTIONS #####
checkdup() {				#check if script is already running
if [[ `uname -r` = 5.8 ]]; then
  dupval=4				#SunOS (can have 3 lines in ps -ef)
else
  dupval=2				#AIX   (has 1 line in ps -ef)
fi
if [[ `ps -ef|grep 'advisorcount.sh'|grep -v grep|wc -l` -ge $dupval ]]; then
  sleep 15				#see if the condition resolves itself
  if [[ `ps -ef|grep 'advisorcount.sh'|grep -v grep|wc -l` -ge $dupval ]]; then
    errorval=errorval+1			#log an error if 2 scripts are running
    if [[ $verbose -eq 1 ]]; then
      print "ERROR: advisorcount.sh script found running in memory. Exiting..."
    fi
    if [[ $loglevel -ge 1 ]]; then
      print "ERROR: advisorcount.sh script found running in memory. Exiting..." >> $LOG
    fi
    exit 1				#if so, exit immediately
  fi
fi
}

checklbver() {
if [[ `uname -r` = "5.8" ]]; then				#SunOS ONLY
  if [[ ! -f $BIN/ndcontrol ]]; then #chk for binary before getting version
    errorval=errorval+1
    if [[ $verbose -eq 1 ]]; then
      print "Sun0S 5.8 detected."
      print "WSLB "$BIN"/ndcontrol file not found. Exiting."
    fi
    if [[ $loglevel -ge 1 ]]; then
      print "Sun0S 5.8 detected." >> $LOG
      print "WSLB "$BIN"/ndcontrol file not found. Exiting." >> $LOG
    fi
    cleanup
    endsession
  fi
  LBVER=`ndcontrol ex rep|grep Version|awk '{print $4}'`	#WSND version
  if [[ $verbose -eq 1 ]]; then
    print "WSND Version: "$LBVER
  fi
  LBVER=`print $LBVER|cut -d . -f 1-3`			#WSLB release level
  if [[ $LBVER = "04.00.02" ]]; then			#Right version
    LBBINDIR=/opt/nd/servers/bin			#Set WSLB paths
    LBCFGDIR=/opt/nd/servers/configurations/dispatcher
  else							#Wrong version - exit
    errorval=errorval+1
    if [[ $verbose -eq 1 ]]; then
      print "Sun0S 5.8 detected."
      print "WebSphere Network Dispatcher Version 4.0.2.x not found. Exiting."
    fi
    if [[ $loglevel -ge 1 ]]; then
      print "Sun0S 5.8 detected." >> $LOG
      print "WebSphere Network Dispatcher Version 4.0.2.x not found. Exiting." >> $LOG
    fi
    cleanup
    endsession
  fi
elif [[ `uname` = "AIX" ]]; then				#AIX ONLY
    if [[ ! -f $BIN/dscontrol ]]; then	#chk for binary before getting version
      errorval=errorval+1
      if [[ $verbose -eq 1 ]]; then
        print "AIX detected."
        print "WSLB "$BIN"/dscontrol file not found. Exiting."
      fi
      if [[ $loglevel -ge 1 ]]; then
        print "AIX detected." >> $LOG
        print "WSLB "$BIN"/dscontrol file not found. Exiting." >> $LOG
      fi
      cleanup
      endsession
    fi
    LBVER=`dscontrol ex rep|grep Version|awk '{print $4}'`	#WSLB version
    if [[ $verbose -eq 1 ]]; then
      print "WSLB Version: "$LBVER
    fi
    LBVER=`print $LBVER|cut -d . -f 1-3`			#WSLB release level
    if [[ $LBVER = "05.00.02" ]]; then				#Right version
      LBBINDIR=/opt/ibm/edge/lb/servers/bin			#Set WSLB paths
      LBCFGDIR=/opt/ibm/edge/lb/servers/configurations/dispatcher
    else						#Wrong version - exit
      errorval=errorval+1
      if [[ $verbose -eq 1 ]]; then
        print "AIX detected."
        print "WebSphere Load Balancer Version 5.0.2.x not found. Exiting."
      fi
      if [[ $loglevel -ge 1 ]]; then
        print "AIX detected." >> $LOG
        print "WebSphere Load Balancer Version 5.0.2.x not found. Exiting." >> $LOG
      fi
      cleanup
      endsession
    fi
else								#Unknown OS
  errorval=errorval+1
  if [[ $verbose -eq 1 ]]; then
    print "Unknown Operating System detected. Exiting."
  fi
  if [[ $loglevel -ge 1 ]]; then
    print "Unknown Operating System detected. Exiting." >> $LOG
  fi
  cleanup
  endsession
fi
}

cleanup() {
# cleanup temporary files
if [[ -f $TMPDIR/$CFILE ]]; then		#Cluster names file
  rm -f $TMPDIR/$CFILE
fi
if [[ -f $TMPDIR/$TMPFILE ]]; then		#Cluster names file
  rm -f $TMPDIR/$TMPFILE
fi
}

deleteobsolete() {
# delete output files ($OUTDIR/$FILE_${HOST}.*) older than $old days
if [[ $verbose -eq 1 ]]; then
  print "Cleaning up old output files..."
fi
cd $OUTDIR
num=`ls $FILE_${HOST}servers.* 2>/dev/null| wc -l 2>/dev/null`	#server files
while (($num > $old)); do					#delete extras
  FN=`ls -t $FILE_${HOST}servers.* | tail -1`
  rm -r $FN
  num=num-1
done
if [[ $verbose -eq 1 ]]; then
  print "Done."
fi
}

endsession() {				#Log session end, return exit code
if [[ $verbose -eq 1 ]]; then
  print "Errors: "$errorval"     "Warnings: "$warningval"
  print
fi
if [[ $loglevel -ge 1 ]]; then
  print "Session ended: "`date` >> $LOG
  print "Errors: "$errorval"     "Warnings: "$warningval" >> $LOG
  print '**********************************************' >> $LOG
fi
if [[ $errorval -ge 1 || $warningval -ge 1 ]]; then
  if [[ $verbose -eq 1 ]]; then
    print "See "$LOG" for error and warning detail."
    print
  fi
  exit 1
fi
}

formatdata() {					#Format CFILE for reading
> $TMPDIR/$TMPFILE				#create temp file
if [[ ! -s $TMPDIR/$CFILE ]]; then		#input file with data not found
  errorval=errorval+1
  if [[ $verbose -eq 1 ]]; then
    print "ERROR: "$TMPDIR/$CFILE" not found. Exiting..."
  fi
  if [[ $loglevel -ge 1 ]]; then
    print "ERROR: "$TMPDIR/$CFILE" not found. Exiting..." >> $LOG
  fi
  cleanup					#exit gracefully
  endsession
fi
if [[ ! -f $TMPDIR/$TMPFILE ]]; then		#cannot create temp file
  errorval=errorval+1
  if [[ $verbose -eq 1 ]]; then
    print "ERROR: Cannot create: "$TMPDIR/$TMPFILE". Exiting..."
  fi
  if [[ $loglevel -ge 1 ]]; then
    print "ERROR: Cannot create: "$TMPDIR/$TMPFILE". Exiting..." >> $LOG
  fi
  cleanup					#exit gracefully
  endsession
fi
while read LINE; do
  if [[ -n `print $LINE|grep Cluster` ]]; then
    print $LINE >> $TMPDIR/$TMPFILE		#output cluster and port
						#split server line found
  elif [[ -z `print $LINE|awk '{FS = "|"; print $3}'` ]]; then
    if [[ -z `print $LINE|awk '{FS = "|"; print $2}'\
|awk '{FS = "."; print $2}'|grep -i "^[a-z]"` ]]; then
						#dotted-decimal address
      LINE=`print $LINE|awk '{FS = "|"; print $2}'|cut -d . -f 1-4`
    else						#output hostname only
      LINE=`print $LINE|awk '{FS = "|"; print $2}'|cut -d . -f 1`
    fi
    LASTLINE=$LINE				#save to append to next line
  elif [[ `print $LINE|awk '{FS = "|"; print $2}'` = " " ]]; then
						#drop empty first field
    CATLINE=`print $LINE|awk '{FS = "|"; print $3 $4 $5 $6 $7 $8 $9}'`
    print $LASTLINE $CATLINE >> $TMPDIR/$TMPFILE	#output joined lines
  else
    if [[ -z `print $LINE|awk '{FS = "|"; print $2}'\
|awk '{FS = "."; print $2}'|grep -i "^[a-z]"` ]]; then
						#dotted-decimal address
      SERVER=`print $LINE|awk '{FS = "|"; print $2}'|cut -d . -f 1-4`
    else						#output hostname only
      SERVER=`print $LINE|awk '{FS = "|"; print $2}'|cut -d . -f 1`
    fi
      LINE=`print $LINE|awk '{FS = "|"; print $3 $4 $5 $6 $7 $8 $9}'`
    print $SERVER $LINE >> $TMPDIR/$TMPFILE	#normal server line found
  fi
done < $TMPDIR/$CFILE		
LINE=""
LASTLINE=""
CATLINE=""
sleep 1 			#Copy formatted data back to original file
cat $TMPDIR/$TMPFILE > $TMPDIR/$CFILE
}

getdata() {				#Read cluster metrics from memory
if [[ $verbose -eq 1 ]]; then
  print "Reading Cluster metrics from Load Balancer memory..."
fi
					#Get metrics, strip unneeded lines
if [[ $LBVER = "04.00.02" ]]; then				#WSND 4.0.2
  ndcontrol server report ::: |grep -v "\---" | grep -v Server > $TMPDIR/$CFILE
else								#WSLB 5.0.2
  dscontrol server report ::: |grep -v "\---" | grep -v Server > $TMPDIR/$CFILE
fi
}

getvars() { 					#Get any command line variables
verbose=0
if [[ -n $1 ]]; then
  if [[ $1 = "-v" ]]; then
    verbose=1
    print
  else
    errorval=errorval+1
    if [[ $loglevel -ge 1 ]]; then
      print "Invalid command line variable. Exiting." >> $LOG
    fi
    print "Usage: advisorcount.sh [-v]"
    print
    print "The -v option enables screen output when run from the command line."
    print
    cleanup
    endsession
  fi
fi
}

outputcounts() {			#Output advisor counts to $OUTPUT file
if [[ $verbose -eq 1 ]]; then
  print "Writing Cluster Advisor metrics..."
fi
if [[ ! -s $TMPDIR/$CFILE ]]; then		#input file with data not found
  errorval=errorval+1
  if [[ $verbose -eq 1 ]]; then
    print "ERROR: "$TMPDIR/$CFILE" not found. Exiting..."
  fi
  if [[ $loglevel -ge 1 ]]; then
    print "ERROR: "$TMPDIR/$CFILE" not found. Exiting..." >> $LOG
  fi
  cleanup
  endsession
fi
while read LINE; do					#output metrics
  if [[ -n `print $LINE|grep Cluster` ]]; then		#get CLUSTER and PORT
    CLUSTER=`print $LINE|awk '{print $2}'`
    PORT=`print $LINE|awk '{print $4}'`
  else							#get Server and Metrics
    SERVER=`print $LINE|awk '{print $1}'`
    cps=`print $LINE|awk '{print $2}'`
    kbps=`print $LINE|awk '{print $3}'`
    total=`print $LINE|awk '{print $4}'`
    active=`print $LINE|awk '{print $5}'`
    fined=`print $LINE|awk  '{print $6}'`
    comp=`print $LINE|awk '{print $7}'`
  							#output data
    print $DATE","$HOST","$CLUSTER","$PORT","$SERVER","$cps","\
$kbps","$total","$active","$fined","$comp >> $OUTDIR/$OUTPUT
  fi
done < $TMPDIR/$CFILE
}

startsession() {				#logs start of the session
if [[ $loglevel -ge 1 ]]; then
  if [[ -s $LOG ]]; then			#$LOG is extant and not empty
    if [[ `du -k $LOG|awk '{print $1}'` -ge $logsize ]]; then	#start new $LOG
      mv -f $LOG $LOG.old
    fi
  fi
  if [[ ! -f $LOG || ! -s $LOG ]]; then		#$LOG is nonextant or empty
    print '**********************************************' > $LOG
  fi
  print "Session started: "`date` >> $LOG
fi
}

#####################
##### MAIN LOOP #####
#####################

### Log session start
startsession

### Input command line variables
getvars $1

### Check for duplicate script running
checkdup

### Cleanup temporary files if a previous session was aborted
cleanup

### Check WSLB Version
checklbver

### GET WSLB cluster metric data from Host Memory
DATE=`date +"%Y%m%d%H%M"`		#Set $DATE just before metrics are read
getdata

### Format the Cluster Metric Data file
formatdata

### Output advisor counts by cluster,port,server
outputcounts

### housekeeping; delete obsolete output files (>$old)
deleteobsolete

### cleanup temporary files
cleanup

### Log session end; return exit code
endsession
