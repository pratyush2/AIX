#!/bin/ksh
# Script Name: /usr/local/scripts/7331.ksh
# Author: Paul Shih
# Creation Date: 10/4/95
# Functional Description: Perform image backups for each of the RS/6000s
# specified on the "for INPUTHOST in" statement.
# Usage: Invoked via cron with no arguments.
#
# Modification History:
#
# Initials	Date	Modification Description
# --------    --------  ---------------------------------------------------
# GT	      11/27/96  Transfered host names to an external file 
############################################################################### 

LOGFILE="/tmp/sysbkup.kshlog"
tapeinventorycmd="/usr/lpp/Atape/samples/tapeutil -f/dev/smc0 inventory"
invntrymsgsent=0

  # The following code section determines the source slot number of the tape 
  # that is currently in the tape drive of an IBM 7331 Tape Stacker. 
  # The principal enabler of the code is the interaction between the tapeutil
  # utility and the IBM Tape Medium Changer Device Driver (/dev/smc0).
  # (Both the smc0 driver and the tapeutil source are part of the Atape.obj 
  # package.)

  # The presence of "Drive Address 0" information in the output of the
  # tapeutil command  with a parameter of inventory is an indication 
  # that the tape stacker is configured to be in the "Split-Sequential" (10
  # tapes for one host and the other 10 for the another host) mode. 
  # Otherwise the stacker is in the "Base-Sequential" mode.

  # Verify that the smc0 device is indeed available.
  /usr/lpp/Atape/samples/tapeutil -f/dev/smc0 element.info 1>/dev/null 2>&1
  smc0chk=$?
  if [[ "$smc0chk" = "0" ]]
  then

    $tapeinventorycmd |grep "Drive Address 0"
    driv0presentchk=$?
    if [[ "$driv0presentchk" = "0" ]]
    then

       # For stacker in "Split-Sequential" mode the slot number is determined in
       # such a manner that two parsings are done: 1) Extraction of the Source
       # Element Address line in the information stanza corresponding to Drive
       # Address 23 or 24 then parse the slot number in this line. 
       # 2) Confirmation of the slot number by checking whether the Media 
       # Present is "No" in the stanza of the said slot address.
       srcelmline=$($tapeinventorycmd |sed -n "/Drive Address 2/,/^$/"p |grep "Source Element Address")
       slotnum=${srcelmline#*... }
       tapepresentline=$($tapeinventorycmd |sed -n "/Slot Address $slotnum$/,/^$/"p |grep "Media Present")
       tapepresent=${tapepresentline#*... }
       if [[ "$tapepresent" = "No" ]]
       then
          echo "" >> $LOGFILE
          echo " *** The source slot number on the IBM 7331 Tape Stacker of the current tape in the drive is $slotnum *** " >> $LOGFILE
          echo "" >> $LOGFILE
       else
          echo "" >> $LOGFILE
          echo " *** Error Encountered while attempting to determine tape slot number!!! *** " >> $LOGFILE
          echo "" >> $LOGFILE
       fi

    else
       # For stacker in "Base-Sequential" mode the slot number is determined by
       # simply looping through all slot addresses (from 1 to 20) looking for a
       # media abscense indication (Media Present ............. No). 
       ((slotnum = 1))
       while ((slotnum <=20))
       do
          tapepresentline=$($tapeinventorycmd |sed -n "/Slot Address $slotnum$/,/^$/"p |grep "Media Present")
          tapepresent=${tapepresentline#*... }
          if [[ "$tapepresent" = "No" ]]
          then
             echo "" >> $LOGFILE
             echo " *** The source slot number on the IBM 7331 Tape Stacker of the current tape in the drive is $slotnum *** " >> $LOGFILE
             echo "" >> $LOGFILE
             break
          fi
          ((slotnum = slotnum + 1))
       done 
    fi
  else
    echo " *** Unable to proceed with tape source slot number determination due to smc0 device driver anomaly!! *** " >> $LOGFILE
    if [[ $invntrymsgsent = 0 ]]
    then
      echo "It's been unable to proceed with the determination of the IBM 7331 tape source slot number due to smc0 device driver anomaly (possibly with the smc0 device driver not in an AVAILABLE state!!****Timestamp=`date +%m%d%H%M`" |mail -s "Attention needed for Sysback/6000 Backups on `hostname`!!!" riscmsg@ussmail.crdc.kpscal.org
      invntrymsgsent=1
    fi

  fi

  # End of the code section for the determination of the tape source
  # slot number.
