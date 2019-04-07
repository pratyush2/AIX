#!/bin/ksh
# SCRIPT MARKER BEGIN, MUST BE LINE 2.
# @(#)chk_rp.ksh v2.1.4
#
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corporation 1992, 1993
#
# All Rights Reserved
#
#
# This code is provided "AS IS." IBM® makes no warranties, express or implied,
# including but not limited to the implied warranties of merchantability and
# fitness for a particular purpose, regarding the function or performance of this code.
# IBM shall not be liable for any damages arising out of your use of this code,
# even if they have been advised of the possibility of such damages.
#
#
# Original Author: Justin Sharrad
# Date  : 8/22/2014
# Caretaker Since Sept 2014: Rich Dobrzanski
# If you update the master script, run upd_rp to generate a new version & checksum file
#
# 2014.09.03 1.1.4 RAD corrected attribute and value retrieval, change LANG=C at perl call.
#        .04 1.1.5 RAD a dreaded update code update.
#        .05 1.1.6 RAD preserve use of options (-printcsv) when re-invoked for an update.
# 2015.01.21 1.1.7 RAD Added header row for csv file.
#                      Condensed case statement.
#                      Removed device name from Unable to Open message.
#                      Inserted EMC Array last 4 digits and LUN ID into the csv file.
#                      For Pseudo devices (non-path) replaced N/A with Pseudo.
# 2015.01.21 1.1.8 RAD export PATH to insulate from possible issues with root's PATH.
#                      changed highlight for Unable to open to yellow.
# 2015.02.17 1.1.9 RAD reorg'd so all functions are first, then everything else.
#                      added s/n, date, uptime, boottime
#                      added reserve default report for VIOS.
#                      added -noupdate command line option.
# 2015.03.12 1.2.0 RAD added warn=9 back in for Unable to open, lost along the way.
#                      deal with CLARiiON IDs.
#                      grab the entire SYMM Array ID.
#                      fixed alignment of IOS version on VIOS.
# 2015.03.26 1.2.1 RAD LVM disks in non-conc VGs with no|no_reserve set warn=2 and red.
#                      detect GPFS disks, classify as shared, use the nsd moniker.
#                      green=correct, red=incorrect, blue=dontcare, yellow=cantopen
#                      LVM disks not in a VG, warn=0 and blue.
#                      Bypass lquerypv for type when VIOS.
#                      When HACMP HB is defined, it should be no_reserve.
#                      Modified stdout report of path devices.
#                      Dont check for update after we just self updated.
# 2015.04.10 1.2.2 RAD added determination when a VG is HA Shared and Concurrent Capable
#                      but not varied-on report the VG as conc-ina.
#                      This happens when cluster services are stopped.
# 2015.08.25 2.0.1 RAD Separated collection from reporting.
#                      Create the .csv file, then report from its content.
#                      warn 0-99=green, 100-199 blue, 200-299=red, 300-399=yellow
#                      Moved warn field to #3
# 2015.10.09 2.0.1 RAD Integrated awk reporting function into this script.
#                      Removed stripping of color escape sequences as they are no
#                      longer present in the csv file.
# 2015.10.12 2.0.1 RAD Added creation of script /tmp/rp_remediate.ksh from within
#                      the report function.
#                      report function now ignores input lines starting with #.
#                      Added usage blurb.
# 2015.10.14 2.0.1 RAD Added -LPM option code.
# 2015.10.15 2.0.1 RAD Fixed warning of path devices when VIO or LPM.
# 2015.11.** 2.0.1 RAD Moved full serverinfo to the end, to make screenshot collection easier.
# 2015.12.02 2.0.1 RAD Changed trap exit code to 4 and exit code on /tmp < 10MB to 10.
#                      Added TERM to trapped signals.
# 2016.01.14 2.0.2 RAD Added -alert (see usage)
#                      Added -lpm synonym to -LPM
#                      Fixed error when lsattr was used on non-existent Shared VGs.
#                      Added 10MB free check on /var when -alert option is used.
#                      Clarified the Powerpath attribute section.
#                      When reserve_enable=no and proper the Class device policy defaults
#                      are treated as blue(n/a or don't care).
# 2016.03.04 2.0.3 RAD Fixed assessment of caavg_private VGs.
#                      Changed empty lines between serverinfo, powerpath device, summary,
#                      and remediate clause to lines with a single space to preserve
#                      a paragraph as "grep -p" see things.
#                      Added Issues count in serverinfo.
#                      Fixed Summary count of pseudo devices unable to open.
# 2016.03.07 2.0.4 RAD 2.0.3 introduced unwanted spaces in column 1 of the PP device section,
#                      this update corrects the output.
# 2016.05.05 2.0.5 RAD Added (CAA Repository) identification.
#                      Per IBM UNIX CC request: Renamed and reordered Summary cols
#                      Wrong and CantOpen to Warning and Error.
#                      Header now reads: Correct OK Warning Error ...
#                      Treat single_path HB detections as Warnings instead of Errors.
#                      Changed Paths row in Summary for Avail and Defined from n/a to -.
#                      Added the disclaimer.
# 2016.05.31 2.0.6 RAD Added support to neuter use of the -alert cmd line option.
#                      Changed HB identification to accommodate leading r in the name.
# 2016.06.23 2.0.7 RAD Fixed issue where commands were added to the remediation script
#                      for the device defaults when the current setting was moot(blue).
#                      Added -updateonly flag that will cause the script to just check
#                      and update if needed, no scan is performed.
#                      Added -? and -help, any command line garbage is ignored.
#                      Include powerpath device and default value in the Issues count.
# 2016.06.24 2.0.8 RAD Fixed bug with -updateonly where after the update -noupdate took
#                      precedence and caused a scan to be performed. Now it exits after
#                      the update is complete.
#                      Also during an update, redirect set command stdout/err to null
#                      to help avoid plastering the session with a colorized environment.
# 2016.08.17 2.1.0 RAD Added LPM trigger via the config file.
#                      Added a command line method (-nolpm) to neuter the config.
#                      All command line options are coerced to lowercase.
# 2016.08.26           Corrected remediation script when reserve_enable=no but s/b none, and
#                      to contain ERROR comments when the reserve attribute is missing from
#                      the class/subclass/type ODM entry.
#                      Did the same when the new value is unknown for the devices, this is most likely
#                      due to the attribute missing as well.
#                      Deal with multiple ODM entries for the same reserve attribute.
#                      Reworked summary section for reserve_enable and the class defaults.
# 2016.09.02           Change report of inactive VGs with disks set wrong to Warning instead of Error.
# 2016.09.29 2.1.1 RAD Reworked detection of GPFS disks due to some NSDs have the same 1st 4bytes
#                      as disks in use by the AIX LVM.
#                      In the report section changed VG= to moniker= when a VG is not detected.
# 2016.10.17 2.1.2 RAD Fixed issue where only the Symmetrix ODM fileset version was reported,
#                      now all EMC.\*.fcp.rte ODM filesets are reported as (abbrev. name=version).
#                      Worked around issue in acquiring GPFS NSD disks which caused data collection
#                      to hang indefinitely.
# 2016.11.21 2.1.3 RAD Fixed bug where corrective value for reserve_enable was empty.
# 2016.11.30 2.1.4 RAD Fixed bug where multiple options were processed improperly.

##################################################
# usage function:
usage() {
  print ""
  print "Usage: chk${DEV}_rpt.ksh [-printcsv] [-noupdate|-updateonly] [-lpm|-nolpm] [-alert]"
  print "             or"
  print "       chk${DEV}_rpt.ksh -report [-printcsv]"
  print "  -printcsv will print the .csv file to stdout after the normal output"
  print "  -noupdate bypasses the update processing"
  print "  -report will provide the report and server info only based on a previously"
  print "          collected /tmp/rp_scan.csv file"
  print "          this option implies -noupdate AND ignores -LPM, -alert, -updateonly"
  print "          NOTE: this will re-generate the remediation script if needed."
  print "  -lpm will force treatment of the LPAR as being LPM enabled"
  print "       NO-OP if the LPAR is a VIO server"
  print "       NO-OP if used with -report"
  print "  -nolpm will ignore the config file LPM setting"
  print "  -alert updates additional persistent files to enable a log monitor"
  print "         to detect FAILs and create a Remedy ticket."
  print "         /var/log/reserve.log is a running log of -alert usage."
  print "         /var/log/reserve.mon will contain only the last result."
  print "         A copy of the /tmp/rp_scan.csv file is placed in /var/log."
  print "         A copy of the /tmp/rp_remediate.ksh is placed in /var/log."
  print "  -updateonly causes the script to just check and update if needed,"
  print "              no scan is performed whether or not an update occurred."
  print "  -? | -help provides this usage text."
  print "  NOTE: if both -noupdate and -updateonly are specified, the last one wins."
  print "        The same is true for -lpm and -nolpm."
  print ""
}
##################################################

##################################################
# cleanup function:
# remove temporary files on exit
cleanup() {
  [ $done -ne 1 ] && echo "Script interrupted, \c"
  echo "Cleaning up temporary files...\c"
  rm -f $powerdevfile
  rm -f $powermtfile
  rm -f $lspvfile
  rm -f $tmpfile
  rm -f $vgstatefile
  print "Done"
} #END cleanup
##################################################

##################################################
# chk4update function:
# check jump server master script version
chk4update() {
  getver() {
    echo "open ussweb.crdc.kp.org 80"
    sleep 1
    echo "GET /justin/chk${DEV}_rp_latest"
    sleep 2
  } #END getver
  newver=$(getver | telnet | grep ^v)
  newver_sum=$(echo $newver | awk '{print $2}')
  newver_num=$(echo $newver | awk '{print $1}' | cut -c2- | sed 's/\.//g')
  version_num=$(echo $version | cut -c2- | sed 's/\.//g')
  if [ "$newver_num" -gt "$version_num" ]; then
    print "chk${DEV}_rp.ksh update available! - Downloading $newver"
    return 1
  else
    print "chk${DEV}_rp.ksh is up to date"
    return 0
  fi
} #END chk4update
##################################################

##################################################
# get_update function:
# download new script version as available
get_update() {
  download() {
    echo "open ussweb.crdc.kp.org 80"
    sleep 3
    echo "GET /justin/chk${DEV}_rp.ksh"
    sleep 3
  }
  download | telnet > $0.tmp.$$
  set $(cat -n $0.tmp.$$ | grep ".......# SCRIPT MARKER .*, MUST BE" | awk '{print $1}') >/dev/null 2>&1
  first=$(($1 - 1)) last=$(eval echo \$$#)
  head -$last $0.tmp.$$ | tail +$first > $0.$$
  rm -f $0.tmp.$$
  chksum=$(sum $0.$$ | awk '{print $1}')
  if [ $chksum -ne $newver_sum ]; then
    print "Failed to update!"
    rm -f $0.$$
    return 1
  fi
  cat > $0_update << EOF
#!/bin/ksh
chmod 700 "$0.$$"
mv "$0" "$0_bak"
mv "$0.$$" "$0"
if [ \$? -eq 0 ]; then
  echo "Complete, restarting..."
  sleep 5
  rm \$0
  if [[ "$CLO" = *"-updateonly"* ]] ; then
    echo "Update only complete."
  else
    exec $0 $CLO
  fi
else
  echo "Failed to update!"
fi
EOF

  echo "Download complete, updating..."
  exec ksh $0_update
} #END get_update
##################################################

##################################################
# prt_hdr function:
# pull first 4 bytes off disk to determine its use
prt_hdr() {
  shared=0
  invg=0
  conc=0
  hdr=
  pvlocked=
  grep -w $1 $lspvfile | read junk junk volgrp vgtype
  [[ $vgtype = *"locked"* ]] && pvlocked=1
  aixdevstate=$(lsdev -l $1 -F status)
  if [[ "$aixdevstate" = "Available" ]] ; then
    if [[ "$vio" = 0 && "$LPM" = 0 ]] ; then
      echo "$NSDLIST" | grep -q -w "$1" 2>/dev/null
      if [[ "$?" = 1 ]] ; then
        lquerypv -h /dev/$1 0 4 | read junk hdr junk
      else
        hdr="GPFS_NSD"
      fi
    elif [[ "$vio" = 1 ]] ; then
      hdr="VIOSDISK"
    elif [[ "$LPM" = 1 ]] ; then
      hdr="LPM_LPAR"
    fi
  else
    hdr="DEFINED"
  fi
  [ -z "$hdr" ] && hdr="MAYBELVM" #Unable to OPEN device
  access=T CAA_REPO=""
  case $hdr in
    00000000)
      disktype="Empty"
      ;;
    GPFS_NSD)
      shared=1
      disktype="GPFS"
      vgtype="moniker"
      ;;
    C9C2D4C1)
      disktype="AIX LVM"
      if [ "$volgrp" != "None" ] ; then
        invg=1
        grep -w "^$volgrp" $vgstatefile | read junk vgtype
        if [[ "$volgrp" = "caavg_private" ]] ; then
          CAA_REPO=1
          disktype="$disktype (CAA Repository)"
        fi
      fi
      [[ "$vgtype" = "conc"* ]] && conc=1
      ;;
    MAYBELVM | DEFINED)
      access=F 
      warn=300
      if [[ -n "$volgrp" ]] ; then
        lsattr -El $volgrp >/dev/null 2>&1
        if [ "$?" = "0" ] ; then
          disktype="AIX LVM (Assumed)"
          vgtype="inactive"
          invg=1
        else
          #disktype="VG moniker" vgtype="N/A"
          disktype="Unknown" vgtype="moniker"
        fi
      else
        disktype="Unknown" volgrp="Unknown"
      fi
      ;;
    00820101)
      shared=1 disktype="Oracle ASM";;
    00220000)
      shared=1 disktype="Oracle Vote";;
    00820000)
      shared=1 disktype="Oracle OCR";;
    VIOSDISK)
      disktype="VIOS Disk";;
    LPM_LPAR)
      disktype="LPM Enabled";;
    *)
      disktype="Unknown";;
  esac
  [ -n "$vgtype" ] && sep="/" || sep=
  [ "$pvlocked" -eq 1 ] && vgtype="$vgtype${sep}locked"
  [[ "$i" = "$HBDISK" || "r$i" = "$HBDISK" ]] && HBmsg=" (HA HeartBeat)" || HBmsg=
  disktype="$disktype$HBmsg"
  [ "$shared" -eq 1 ] && perms=$(ls -l /dev/r$1 | awk '{print $1,$3,$4}')
} #END prt_hdr
##################################################

##################################################
# get_res function:
# retrieve reserve policy/lock from ODM
# flag potential incorrect setting in red
get_res() {
  lsattr -El $1 -F "attribute value" 2>/dev/null | grep "^reserve_" | read resv res
  case $res in
    no|no_reserve)
      if [ "$shared" -eq 1 -o "$vio" -eq 1 -o "$conc" -eq 1 -o "$i" = "$HBDISK" -o "$LPM" -eq 1 -o "$CAA_REPO" -eq 1 ]; then
        warn=0
      elif [ "$disktype" = "Empty" -o "$disktype" = "Unknown" -o "$invg" = "0" ] ; then
        warn=100
      else
        warn=202
        [ "$vgtype" = "inactive" ] && warn=300
      fi;;
    yes|single_path)
      if [ "$shared" -eq 1 -o "$vio" -eq 1 -o "$conc" -eq 1 -o "$LPM" -eq 1 -o "$CAA_REPO" -eq 1 ]; then
        warn=200
        [ "$vgtype" = "inactive" ] && warn=300
      elif [ "$disktype" = "Empty" -o "$disktype" = "Unknown" -o "$invg" = "0" ] ; then
        warn=100
      elif [ "$i" = "$HBDISK" ] ; then
        warn=300
      else
        warn=0
      fi;;
    *)
      warn=200
      res="Attribute not found!";;
  esac
} #END get_res
##################################################

##################################################
getserial() {
sn=$(lscfg -vpl sysplanar0 |grep -p "System:" |grep "Machine/Cabinet")
if [[ $? -eq 0 ]]; then
    sn=${sn##*.}
else
    sn=$(lscfg -vpl sysplanar0 |grep -p "System VPD:" |grep "Machine/Cabinet")
    if [[ $? -eq 0 ]]; then
        sn=${sn##*.}
    else
        sn=$(lsattr -El sys0 -a systemid -F value | cut -c3-)
        if [[ $? -eq 0 ]]; then
            sn="n/a"
        fi
    fi
fi
if [[ -z "$sn" ]] ; then sn="n/a" ; fi
print "$sn"
} #END getserial
##################################################

##################################################
get_reserve_default() {
cat $powermtfile | tr "=" " " | awk '/Pseudo/||/fscsi/ {print $3}' | while read x ; do
   odmget -q"name=$x" CuDv | grep PdDvLn
done | sort | uniq -c | awk -F\" '{print $2}' | tr "/" " " | while read c s t ; do
   lsattr -D -c $c -s $s -t $t | egrep "^reserve_[policy|lock]" |\
     awk '{A=$1;V=$2};END {print NR,A,V}' | read attrcount attrname value
   (( attrcount == 0 )) && attrname="*MISSING*"  value="*ERROR*"
   (( attrcount > 1 )) && attrname="*MULTIPLE*" value="*ERROR*"
   warn=0
   case $value in
      no|no_reserve   ) [[ "$vio" != 1 && "$LPM" != 1 ]] && warn=200
                        [[ "$dflt_warn" = 100 ]] && warn=100;;
      yes|single_path ) [[ "$vio" = 1 || "$LPM" = 1 ]] && warn=200
                        [[ "$dflt_warn" = 100 ]] && warn=100;;
      *               ) warn=200;
   esac
   print "ZZZ,PP,$host,$warn,$c/$s/$t,$attrname,$value" >> $tmpfile
done
} #END get_reserve_default
##################################################

##################################################
get_vgstate() {
lspv | tee $lspvfile | awk '{print $3}' | grep -wv None | sort -u | while read vgname ; do
  vginfo=$(lsvg $vgname 2>/dev/null)
  if [[ -z "$vginfo" ]] ; then
    vgstate="inactive"
    lsattr -El $vgname >/dev/null 2>&1 || vgstate="not_a_vg"
    echo "$CCLIST" | grep -w $vgname >/dev/null && vgstate="conc-ina"
    print "$vgname $vgstate"
    continue
  fi
  vgmode=$(print "$vginfo" | grep "^VG Mode:" | awk '{print $3}')
  if [[ "$vgmode" != "Concurrent" ]] ; then
    print "$vgname active"
    continue
  fi
  vgperm=$(print "$vginfo" | grep "^VG PERMISSION:" | awk '{print $3}')
  [ "$vgperm" = "read/write" ] && vgperm="r/w" || vgperm="pasv"
  print "$vgname conc-$vgperm"
done
print "None N/A"
} #END get_vgstate
##################################################

##################################################
# Display human readable report from the .csv file.
report() {
grep -v "^#" $outfile | cut -d, -f2- | awk -F, '
BEGIN {
# vt200 sequences
# 0 normal , 1 bold , 7 reverse
# 30+# for fgcolor
# 40+# for bgcolor
# 0 blk, 1 red, 2 green, 3 yel, 4 blue, 5 mag, 6 cyan, 7 white
# foreground colors
    fg["red"]=sprintf("%s","\033[1;31m")
  fg["green"]=sprintf("%s","\033[1;32m")
 fg["yellow"]=sprintf("%s","\033[1;33m")
   fg["blue"]=sprintf("%s","\033[1;34m")
fg["magenta"]=sprintf("%s","\033[1;35m")
       normal=sprintf("%s","\033[0m")
      blackbg=sprintf("%s","\033[0;40m")
      whitebg=sprintf("%s","\033[0;47m")
  "tput rev" | getline reverse
SCRIPTFILE="/tmp/rp_remediate.ksh"
system("/usr/bin/rm -f "SCRIPTFILE)
chg["yes"]="no"
chg["no"]="yes"
chg["single_path"]="no_reserve"
chg["no_reserve"]="single_path"
"whence chdef" | getline CHDEF
} #END BEGIN

# Pseudo device info
/^PS,/ { 
  if ( $2 == "Server" ) { next } #skip header
  color=getcolor($3)
  ++total["pseudo"]
  ++pseudo[color]
  if ( length($5) > 0 ) { ++pseudo[$5] }
  PSEUDO=$4
  print ""
  if ( length($6$7) > 0 ) {
    arraymsg="(Array: "$6" ID: "$7")"
  }
  else {
    arraymsg=fg["yellow"]"(Unknown)"normal
  }
  print PSEUDO" "arraymsg" reserve="fg[color]""$13""normal
  if ( $8 == "F" ) {
    print fg["yellow"]"Unable to open (State: "$5")"normal
    ++pseudo["yellow"]
  }
  else {
    if ( $5 != "Available" ) {
      print fg["yellow"]"(State: "$5")"normal
      ++pseudo["yellow"]
    }
  }
  VGTYPE=$11
  LBL="VG"
  if ( VGTYPE == "moniker" ) { LBL=VGTYPE ; VGTYPE="" }
  print "disktype="$9"   "LBL"="$10"  "VGTYPE
  if ( length($12) ) { print $12 }
  if ( $3 > 199 && $3 < 300 ) {
    writecmd(getcmd(PSEUDO,chg[$13]))
  }
} #END PS

# Path device info
/^PA,/ {
  if ( $2 == "Server" ) { next } #skip header
  color=getcolor($3)
  ++total["path"]
  ++path[color]
  PATH=$7
  printf "  Path %2s %-10s %-10s %-30s\n",$5,$6,PATH,fg[color]""$9""normal
  if ( $3 > 199 && $3 < 300 ) {
    writecmd(getcmd(PATH,chg[$9]))
  }
} #END PA

/^HD,/ {
  if ( $2 == "Server" ) { next } #skip header
  SERVER=$2
  SERIAL=$3
  AIX=$4
  VIO=$5
  if (VIO == "N/A") { VIO="No" }
  LPM=$12
  EMCPP=$6
  EMCODM=$7
  DATE=$8
  BOOTED=$9
  UPTIME=$10
  SCRIPT=$11
} #END HD

/^PP,/ {
  FMT="%-30s %-24s %s\n"
  DFLT=""
  if ( PP++ == 0 ) {
    PPpost=sprintf("%s\n","   PowerPath related device attributes, values, and defaults")
    PPpost=PPpost""sprintf(FMT,"Device","Attribute","Value")
  }
  if ( $4 != "powerpath0" ) { DFLT=" default" }
  ATTR=$5 ; VAL=$6
  INVALID=0
  if ( VAL == "*ERROR*" ) { INVALID=1 }
  PPpost=PPpost""sprintf(FMT,$4,ATTR""DFLT,fg[getcolor($3)]""VAL""normal)
  ++power[getcolor($3)]
  if ( $3 < 200 || $3 >= 300 ) { next } # next on green,blue,yellow
  if ( $3 > 0 && $4 == "powerpath0" ) {
    correction="no"
    if ( VAL != "none" ) { correction="none" }
    writecmd("chdev -P -l powerpath0 -a reserve_enable="correction)
    next
  }
  writecmd("### Change default setting for "$4" ###")
  split($4,cst,"/")
  if ( INVALID != 0 ) {
    if ( ATTR == "*MISSING*" ) { MSG="is missing the reserve related attribute" }
    if ( ATTR == "*MULTIPLE*" ) { MSG="has multiple reserve related attributes" }
    writecmd("### ERROR: ODM for "$4" "MSG" !!")
    writecmd("### To show this use the following command:")
    writecmd("lsattr -D -c "cst[1]" -s "cst[2]" -t "cst[3])
    next
  }
  if ( length(CHDEF) ) {
    writecmd("chdef -a "ATTR"="chg[VAL]" -c "cst[1]" -s "cst[2]" -t "cst[3])
  }
  else {
    print "odmchange -o PdAt -q\"uniquetype="$4" and attribute="ATTR"\" << EOF"COMMANDS >> SCRIPTFILE
    print "PdAt:" >> SCRIPTFILE
    print "\tdeflt = \""chg[VAL]"\"" >> SCRIPTFILE
    print "EOF"COMMANDS >> SCRIPTFILE
  }
} #END PP

function getcmd(dev,pol) {
  if (length(pol) == 0) { return "# ERROR: chdev for "dev" not possible since new value cannot be determined." }
  if (match(pol,"_")) { ATTR="reserve_policy" } else { ATTR="reserve_lock" }
  #NOTE: &&\\\n results in &&\ followed immediately by a newline, there MUST BE NO WHITESPACE
  return "[[ \"$(lsattr -El "dev" -a "ATTR" -F value)\" != \""pol"\" ]] &&\\\n   chdev -P -l "dev" -a "ATTR"="pol
} #END getcmd

function writecmd(x) {
  if ( COMMANDS++ < 1 ) { print "#!/usr/bin/ksh -x\nexit 1" > SCRIPTFILE }
  print x >> SCRIPTFILE
} #END writecmd

END {
  serverinfo()
  if (length(PPpost) > 0) { print " " ; printf PPpost ; print " " } #The 2 print spaces preserves the paragraph
  if (total["pseudo"]+total["path"] > 0) { summary() }
  if ( COMMANDS > 0 ) {
    print " " #The print space preserves the paragraph
    print "Script /tmp/rp_remediate.ksh was created with commands to"
    print "change the reserve setting for ALL devices reported in RED."
    print "Due diligence is required before execution of that script."
  }
  print "" #This ends the paragraph
} #END END

function summary() {
  print  "                           S U M M A R Y"
  print  "                |--------Reservation Policy---------|------Device-----|"
  printf "       %9s%9s%9s%9s%9s%9s%9s\n","Total","Correct","OK","Warning","Error","Avail","Defined"
  printf "Pseudo "
  printf "%9s",total["pseudo"]+0
  g="green"     ; if ( pseudo[g]+0 > 0 ) { c=g } else { c="red" }          ; printf "%s%9s",fg[c],pseudo[g]+0
  g="blue"      ; if ( pseudo[g]+0 > 0 ) { c=g } else { c="green" }        ; printf "%s%9s",fg[c],pseudo[g]+0
  g="yellow"    ; if ( pseudo[g]+0 > 0 ) { c=g } else { c="green" }        ; printf "%s%9s",fg[c],pseudo[g]+0
  g="red"       ; if ( pseudo[g]+0 > 0 ) { c=g } else { c="green" }        ; printf "%s%9s",fg[c],pseudo[g]+0
  g="Available" ; if ( pseudo[g] == total["pseudo"] ) { c="green" } else { c="yellow" } ; printf "%s%9s",fg[c],pseudo[g]+0
  g="Defined"   ; if ( pseudo[g]+0 > 0 ) { c="yellow" } else { c="green" } ; printf "%s%9s",fg[c],pseudo[g]+0
  print normal
  printf "  Path "
  printf "%9s",total["path"]+0
  g="green"  ; if ( path[g]+0 > 0 ) { c=g } else { c="red" }   ; printf "%s%9s",fg[c],path[g]+0
  g="blue"   ; if ( path[g]+0 > 0 ) { c=g } else { c="green" } ; printf "%s%9s",fg[c],path[g]+0
  g="yellow" ; if ( path[g]+0 > 0 ) { c=g } else { c="green" } ; printf "%s%9s",fg[c],path[g]+0
  g="red"    ; if ( path[g]+0 > 0 ) { c=g } else { c="green" } ; printf "%s%9s",fg[c],path[g]+0
  printf "%s%9s%9s",normal,"-","-"
  print normal
} #END summary

function getcolor(warn,x) {
       if ( warn == "" ) { x="magenta" }
  else if ( warn < 0   ) { x="magenta" }
  else if ( warn < 100 ) { x="green" }
  else if ( warn < 200 ) { x="blue" }
  else if ( warn < 300 ) { x="red" }
  else if ( warn < 400 ) { x="yellow" }
  else                   { x="magenta" }
  return x
} #END getcolor

function serverinfo() {
  print ""
  FORMAT="%-9s: %s\n"
  printf FORMAT,"Host",SERVER
  printf FORMAT,"Serial",SERIAL
  printf FORMAT,"AIX",AIX
  printf FORMAT,"Script",SCRIPT
  printf FORMAT,"VIO",VIO
  printf FORMAT,"LPM",LPM
  printf FORMAT,"Collected",DATE
  printf FORMAT,"Booted",BOOTED
  printf FORMAT,"Uptime",UPTIME
  printf FORMAT,"EMC PP",EMCPP
  printf FORMAT,"EMC ODM",EMCODM
  issue_err=path["red"]+pseudo["red"]+power["red"]+0
  issue_warn=path["yellow"]+pseudo["yellow"]+power["yellow"]+0
  printf FORMAT,"Issues",issue_err+issue_warn" E: "issue_err" W: "issue_warn
} #END serverinfo
' #END of awk
} #END report ksh function

# function called before exit when -alert option is used
alert() {
  RLOG=/var/log/reserve.log
  RMON=/var/log/reserve.mon
  RCSV=/var/log/rp_scan.csv
  PNOW=$(perl -e 'print time;') DNOW=$(date +%Y%m%d:%H%M%S)
  stamp="$PNOW $DNOW"
  mkdir /var/log >/dev/null 2>&1
  /usr/bin/cp -p $outfile $RCSV
  # FAIL
  if [[ -e /tmp/rp_remediate.ksh ]] ; then
    logANDpost FAIL
    /usr/bin/cp -p /tmp/rp_remediate.ksh /var/log/rp_remediate.ksh
    exit 200
  fi
  # PASS
  logANDpost PASS
  exit 0
} #END alert

# only called from within the alert function.
logANDpost() {
  echo "$stamp $1" | tee -a $RLOG > $RMON
}

##################################################
# MAIN Main main
##################################################
CLO="$* -noupdate"
DEV=
export PATH=/usr/bin:/usr/sbin:/usr/es/sbin/cluster/utilities:
version=$(what $0 | awk '/v/{print $2}')
tmpfile="/tmp/rp_scan.$$"
outfile="/tmp/rp_scan.csv"
powerdevfile="/tmp/powerdev.$$"
powermtfile="/tmp/powermt.$$"
lspvfile="/tmp/lspv.$$"
vgstatefile="/tmp/vgstate.$$"

white=$(echo "\033[1;37m")
yellow=$(echo "\033[1;33m") yellowbg=$(echo "\033[1;43m")
green=$(echo "\033[1;32m") greenbg=$(echo "\033[1;42m")
blue=$(echo "\033[1;34m") bluebg=$(echo "\033[1;44m")
red=$(echo "\033[1;31m") redbg=$(echo "\033[1;41m")
reverse=$(tput rev)
normal=$(echo "\033[0m")
LPM=0
warn=0
done=0
trap 'cleanup;exit 4' INT TERM

clear
echo $(basename $0) $version
typeset -l OPTIONS="$@" alertmm lpmconf
grep -w "^LPM" /etc/chk_rp.conf 2>/dev/null | read junk lpmconf junk
if [[ "$lpmconf" = "enabled" ]] ; then
  echo "LPAR may use LPM specified per /etc/chk_rp.conf"
  LPM=1
fi
for i in $OPTIONS ; do
  case $i in
    "-printcsv")   printcsv=1;;
    "-noupdate")   noupdate=1 updateonly= ;;
    "-report")     report=1 noupdate=1;;
    "-lpm")        if [[ "$LPM" = 0 ]] ; then
                     LPM=1
                     echo "LPM treatment enabled via cmd line option"
                   fi;;
    "-nolpm")      if [[ "$LPM" = 1 ]] ; then
                     LPM=0
                     echo "LPM treatment disabled via cmd line option"
                   fi;;
    "-alert")      alert=1
                   grep -w "^alert_maintmode" /etc/chk_rp.conf 2>/dev/null | read junk alertmm junk
                   if [[ "$alertmm" = "enabled" ]] ; then
                     alert=
                     echo "Alert option disabled per /etc/chk_rp.conf"
                   fi ;;
    "-updateonly") updateonly=1 noupdate= ;;
    "-?"|"-help" ) usageERR=1 noupdate=1 updateonly= ; break ;;
    * )            [[ -n "$i" ]] && badopts="$badopts $i" ;;
  esac
done

#noupdate=1 #used to FORCE -noupdate

if [[ -n "$report" ]] ; then
  if [[ ! -f $outfile ]] ; then
    echo "$outfile does not exist!"
    exit 2
  fi
  report
  [ "$printcsv" = 1 ] && cat $outfile
  done=1
  cleanup
  exit 0
fi
if [[ -z "$noupdate" ]] ; then
  echo "Checking for update..."
  chk4update || get_update
else
  echo "Bypassing update check."
fi
if [[ -n "$updateonly" ]] ; then
  echo "Update only completed."
  done=1
  cleanup
  exit 0
fi

if [[ -n "$usageERR" ]] ; then usage ; exit 3 ; fi
if [[ -n "$badopts" ]] ; then
  echo "Command line garbage ignored:$badopts"
fi

rm -f $outfile
host=$(uname -n)
tmpfree=$(df -k /tmp | awk '/\/dev/{print $3}')
if [ "$tmpfree" -lt 10240 ]; then
  print "Aborting, please verify that free space in /tmp is > 10MB"
  print "ZZZ,ERROR,$host,Not enough space in /tmp" > $outfile
  exit 10
fi
varfree=$(df -k /var | awk '/\/dev/{print $3}')
if [[ "$varfree" -lt 10240 && "$alert" = 1 ]]; then
  print "Aborting, please verify that free space in /var is > 10MB"
  print "ZZZ,ERROR,$host,Not enough space in /var" > $outfile
  exit 10
fi

# collect some data & store in tmp files
print "Collecting data, please wait..."
lsdev -Ccdisk -tpower -F name > $powerdevfile
whence cllsif >/dev/null && HACMP=1 || HACMP=0
if [ "$HACMP" = "1" ] ; then
  NODENAME=$(get_local_nodename)
  if [ -n "$NODENAME" ] ; then
    HBDISK=$(cllsif | grep " diskhb .* $NODENAME " | awk '{split($7,arr,"/");print arr[3]}')
    HBDISK=${HBDISK#r} #remove potential leading r
  fi
  clshowres | grep "^Volume Groups" | while read junk junk svgs ; do SVGLIST="$SVGLIST $svgs" ; done
  for vg in $SVGLIST ; do
    conccap=$(lsattr -El $vg -a conc_capable -F value 2>/dev/null)
    [[ "$conccap" = "y" ]] && CCLIST="$CCLIST $vg"
  done
fi
get_vgstate > $vgstatefile
# for GPFS , collect NSD data
# get lspv line for each Powerpath device.
lspvpp=$(for d in $(cat $powerdevfile) ; do grep -w $d $lspvfile ; done)
# get each Powerpath device used by GPFS
LSNSD=/usr/lpp/mmfs/bin/mmlsnsd
if [[ -x "$LSNSD" ]] ; then
  NSDLIST=$(/usr/lpp/mmfs/bin/mmlsnsd | tail +4 | grep -v "^$" | awk '{print $2}' | while read x ; do
    echo "$lspvpp" | grep -w $x | awk '{print $1}'
  done)
fi

# print host info
booted=$(istat /var/adm/ras/SRCKeyID | awk -F"\t" '/modified:/{print $2}')
date=$(date)
uptime=$(perl -e '@a=stat("/var/adm/ras/SRCKeyID"); $t=time()-$a[9]; printf "%dd %dh %dm %ds\n",$t/86400,$t%86400/3600,$t%3600/60,$t%60;')
emcpp=$(lslpp -Lqc EMCpower.base 2>/dev/null | awk -F: '{print $3}')
# get space delimited list of abbreviated fileset name=version
emcodm=$(lslpp -Lqc EMC.\*.fcp.rte 2>/dev/null | awk -F: '
  {split($2,a,".")
   if (NR>1) {printf " "}
   printf a[2]"="$3
  }
')
lpmmsg="No"
if [[ -f /usr/ios/cli/ioscli ]]; then
  ioslevel=$(/usr/ios/cli/ioscli ioslevel)
  vio=1
  viomsg="$ioslevel"
else
  vio=0
  viomsg="No"
  ioslevel="N/A"
  (( LPM == 1 )) && lpmmsg="Yes"
fi
oslevel=$(uname -rv | awk '{print $2$1}')
oslevel=$([ "$oslevel" -lt 53 ] && oslevel -r 2>/dev/null || oslevel -s 2>/dev/null)
serial=$(getserial)
teaser="\nHost     : $host\nSerial   : $serial\nAIX      : $oslevel"
print "ZZZ,HD,Server,Serial,OSlevel,VIOlevel,EMCPPlevel,EMCODMlevel,date,booted,uptime,scriptversion,LPM" >> $tmpfile
if [ -z "$emcpp" ]; then
  emcpp="Not Installed"
else
  print "Executing: powermt display dev=all ..."
  powermt display dev=all > $powermtfile 2>/dev/null
fi
if [ -z "$emcodm" ]; then
  emcodm="Not Installed"
fi
print "ZZZ,HD,$host,$serial,$oslevel,$ioslevel,$emcpp,$emcodm,$date,$booted,$uptime,$version,$lpmmsg" >> $tmpfile
if [[ "$emcodm" != "Not Installed" ]] ; then
  res_ena=$(lsattr -El powerpath0 -a reserve_enable -F value 2>/dev/null)
  warn=0
  case "$res_ena" in
    yes ) warn=200;;
    ""  ) res_ena="N/A";;
    none) [[ "$vio" = 1 || "$LPM" = 1 ]] && warn=200;;
    no  ) [[ "$vio" != 1 && "$LPM" != 1 ]] && warn=200;;
    *   ) res_ena="Unknown" warn=200;;
  esac
  if [[ "$res_ena" = "no" && "$warn" = 0 ]] ; then dflt_warn=100 ; fi
  print "ZZZ,PP,$host,$warn,powerpath0,reserve_enable,$res_ena" >> $tmpfile
  get_reserve_default
fi #endif emcodm != NotInstalled

#exit #FOR DEBUG general header report


##################################################
# LOOP through power devices
##################################################
cat $powerdevfile | wc -l | read powercount
if (( powercount > 0 )) ; then
  print "$teaser"
  print "$powercount power devices found."
  print "ZZZ,PS,Server,Warning,Pseudo,AIXdevState,Array,LUNID,Accessible,Usage,Name,State,Perms,Policy" >> $tmpfile
  print "ZZZ,PA,Server,Warning,Pseudo,HBA,Adapter,Path,AIXdevState,Policy" >> $tmpfile
fi
count=0
for i in $(cat $powerdevfile); do
  ppent=$(grep -wp $i $powermtfile)
  print "$ppent" | awk -F= '
    /Symmetrix ID/ {a=$2;getline;l=$2}
    /CLARiiON ID/ {split($2,arr," ");a=arr[1];getline;split($2,arr," ");l=arr[2]" "arr[3]}
    END {print a,l}
  ' | read emcarray emcvolid
  prt_hdr $i
  get_res $i
  powres=$res
  res=
  print "ZZZ,PS,$host,$warn,$i,$aixdevstate,$emcarray,$emcvolid,$access,$disktype,$volgrp,$vgtype,$perms,$powres" >> $tmpfile
  high=$warn
  warn=0
  k=0
  print "$ppent" | awk '/ hdisk[0-9]/{print $1,$2,$3}' | while read emchba aixadap j ; do
    aixdevstate=$(lsdev -l $j -F status)
    get_res $j
    [[ "$res" != "$powres" && "$vio" = 0 && "$LPM" = 0 ]] && warn=200
    print "ZZZ,PA,$host,$warn,$i,$emchba,$aixadap,$j,$aixdevstate,$res" >> $tmpfile
    (( warn > high )) && high=$warn
    warn=0
  done #END while on path devices for a single pseudo device

  #Progress bar while collecting data
  let count+=1
  if (( high < 100 )) ; then dot=$greenbg
  elif (( high < 200 )) ; then dot=$bluebg
  elif (( high < 300 )) ; then dot=$redbg
  else dot=$yellowbg
  fi
  printf $white$dot"*"$normal
  if (( count % 10 == 0 )) ; then
    (( count % 50 == 0 )) && print $count || printf $((count % 100))
  fi
  #END progress bar code

done #END for loop on pseudo devices
(( count > 0 )) && print " $count"
sleep 1

cat $tmpfile > $outfile
report
[ "$printcsv" = 1 ] && cat $outfile
done=1
cleanup

# the alert function is a one-way trip with script exits.
[[ -n "$alert" ]] && alert

[[ -e /tmp/rp_remediate.ksh ]] && exit 200
exit 0
# SCRIPT MARKER END, MUST BE LAST LINE.
