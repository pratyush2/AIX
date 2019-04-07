#!/bin/ksh

# Quick script to determine if the system has the appropriate APAR for
# the Daylight Savings Time.  If it does not, this script will apply the
# alternate patch using the chtz command.


###############################################
# Get the basic information and set variables #
###############################################

TIMEZONE=$(/usr/bin/date +%Z)
OSTYPE=$(/usr/bin/uname)
OSVERSION=$(/usr/bin/uname -v)
OSRELEASE=$(/usr/bin/uname -r)
HAVE_APAR=$(echo 1)

##########################################################################
# Function to back up the /etc/environment file and change the time zone #
##########################################################################

change_tz(){
  if [[ -f /etc/environment.bak ]] ; then
    echo "!!!  ERROR  !!!"
    echo "File /etc/environment.bak is present.  Exiting script."
    echo "Rename /etc/environment.bak and rerun script."
    echo "!!!  ERROR  !!!"
    exit
  else
    echo "Backing up /etc/environment file to /etc/environment.bak ..."
    /usr/bin/cp /etc/environment /etc/environment.bak
  fi
  case $TIMEZONE in
    PST)  chtz PST8PDT,M3.2.0,M11.1.0 ;;
    EST)  chtz EST5EDT,M3.2.0,M11.1.0 ;;
    CST)  chtz CST6CDT,M3.2.0,M11.1.0 ;;
    HST)  echo "\n\n!!! HAWAII DOES NOT OBSERVE DST !!!\n\n" 
          exit ;;
    MST)  chtz MST7MDT,M3.2.0,M11.1.0 ;;
    *  )  echo "\n\n!!!  ERROR!  NO TIMEZONE !!!\n\n"
          exit ;;
  esac
}

####################
# Do the deed here #
####################

if [ "$OSTYPE" != "AIX" ] ; then
  echo "NOT AIX ... EXITING ..."
  exit
fi

df -k / /tmp /home

if [ "$OSVERSION" = "4" ] ; then
  echo "AIX v4.x ..."
  echo "Applying the chtz patch ..."
  change_tz
  echo "Patch has been applied.  Reboot for the change to take effect."
  diff /etc/environment /etc/environment.bak
elif [ "$OSVERSION" = "5" ] ; then
  case $OSRELEASE in
    1)  HAVE_APAR=$(instfix -ik IY75214 > /dev/null 2>&1 || echo 0) ;;
    2)  HAVE_APAR=$(instfix -ik IY75213 > /dev/null 2>&1 || echo 0) ;;
    3)  HAVE_APAR=$(instfix -ik IY75211 > /dev/null 2>&1 || echo 0) ;;
    *)  echo "\n\n!!!  ERROR!  UNKNOWN RELEASE LEVEL !!!\n\n"
        exit ;;
  esac
  if [ "$HAVE_APAR" = "0" ] ; then
    echo "Applying the chtz patch ..."
    change_tz
    echo "Patch has been applied.  Reboot for the change to take effect."
    diff /etc/environment /etc/environment.bak
  else
    echo "\n\nAPAR already present.  The chtz patch is not needed.\n\n"
  fi
fi

