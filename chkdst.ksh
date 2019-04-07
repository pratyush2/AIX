#!/bin/ksh
#exit

# Script to check for DST Patch and/or Fudge, and Java updates.
#
# Space delimited output:
#	$1=uname info (name_release_version_id,model-type)
#	$2=time info (TIME=weekday_YYYYMMDD_HHMMDD_ZONE)
#	$3=TZ info (TZ=$TZ_REBOOT[ED | me])
#	$4=APAR info (APAR_[NO | IY7521[134]_[REBOOTED | NOTREBOOTED]])
#	$5=JRE info (JRE_UPDATED | JRE_REQUIRED)
#	$6...n=if $5=JRE_REQUIRED then JRE fileset info

# Output to grep for problems:
#	REBOOTme indicates a reboot appears to be needed, this is not
#		 a foolproof test.  A change to /etc/environment after
#		 the DST reboot will trick the test.
#	NOTREBOOTED indicates the APAR Patch IY7521[134] is present but
#		 the server has not been rebooted yet.
#	REQUIRED indicates Java should be updated.


###########################################################################
# Check for reboot since environment was changed.
###########################################################################
chk_tz(){
  OUT="$OUT TIME=$(date +"%a_%Y%m%d_%H%M%S_%Z") TZ=$TZ"
  if [[ /etc/environment -ot /dev/log ]] ; then
    OUT="${OUT}_REBOOTED"
  else
    OUT="${OUT}_REBOOTme"
  fi
}

###########################################################################
# Check for APAR Patch in 5.1, 5.2, or 5.3
###########################################################################
chk_patch(){
if [ "$OSVERSION" = "5" ] ; then
  case $OSRELEASE in
    1)  APAR="IY75214" ;;
    2)  APAR="IY75213" ;;
    3)  APAR="IY75211" ;;
    *)  OUT="$OUT UNKNOWN_V.R_5.$OSRELEASE"
        xit ;;
  esac
  PATCH="NO"
  instfix -ik $APAR >/dev/null 2>&1 && PATCH=$APAR
  OUT="$OUT APAR_$PATCH"
  if [[ $OUT = *"IY7521"* ]] ; then
    if [[ /usr/ccs/lib/libc.a -ot /dev/log ]] ; then
      OUT="${OUT}_REBOOTED"
    else
      OUT="${OUT}_NOTREBOOTED"
    fi
  fi
else
  OUT="$OUT APAR_NO_4x"
fi
}

###########################################################################
# Check for JRE patches
###########################################################################
chk_jre(){
P[1]=Java131.rte.bin    ; L[1]="1.3.1.20"
P[2]=Java13_64.rte.bin  ; L[2]="1.3.1.12"                                                                                          
P[3]=Java14.sdk         ; L[3]="1.4.2.75"
P[4]=Java14_64.sdk      ; L[4]="1.4.2.75"
P[5]=Java5.sdk          ; L[5]="5.0.0.76"
P[6]=Java5_64.sdk       ; L[6]="5.0.0.75"
JRE=
for i in 1 2 5 6 ; do
        PL=$(lslpp -lc -Ou ${P[$i]} 2>/dev/null | tail +2 | awk -F: '{print $3}')
        if [[ -n $PL && $PL != ${L[$i]} ]] ; then
                JRE="$JRE ${P[$i]} NEEDS ${L[$i]}"
        fi
done
for i in 3 4 ; do
        PL=$(lslpp -lc -Ou ${P[$i]} 2>/dev/null | tail +2 | grep "1\.4\.2" | awk -F: '{print $3}')
        if [[ -n $PL && $PL != ${L[$i]} ]] ; then
                JRE="$JRE ${P[$i]} NEEDS ${L[$i]}"
        fi
done
if [[ $JRE = *"NEEDS"* ]] ; then
  OUT="$OUT JRE_REQUIRED $JRE"
else
  OUT="$OUT JRE_UPDATED"
fi
}

###########################################################################
# Single exit point
###########################################################################
xit() {
  echo $OUT
  exit
}

###########################################################################
# MAIN Starts here
###########################################################################

TIMEZONE=$(/usr/bin/date +%Z)
OSTYPE=$(/usr/bin/uname)
OSVERSION=$(/usr/bin/uname -v)
OSRELEASE=$(/usr/bin/uname -r)

if [ "$OSTYPE" != "AIX" ] ; then
  OUT="NOT_AIX_..._EXITING_..."
  xit
fi

OUT=$(uname -nvrmM | tr " " "_")
chk_tz
chk_patch
chk_jre
xit
