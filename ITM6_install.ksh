#!/bin/ksh
#==============================================================
#  Author:  Chung Trinh     
#  Date:    07/16/2007
#  Script:  ITM6_install.ksh
#  extracted from OS_addition.ksh
#===================================================================
READENV="Production"

   echo "Perf_report installation"
mount -o ro,bg,soft,intr,proto=tcp,retry=100 ktazp2989.crdc.kp.org:/usr/Tivoli/media/itm/v61/product/base_FP1/agent_install/aix /mnt
mkdir -p /opt/IBM/ITM
/mnt/install.sh -q -h /opt/IBM/ITM -p /mnt/silent_install.txt
export CANDLEHOME=/opt/IBM/ITM
   if [ "$READENV" = "Production" ]; then
      INSTYPE="prod"
   else
      INSTYPE="dev"
   fi
   echo $READENV
   echo $INSTYPE
/opt/IBM/ITM/bin/itmcmd config -A -p /mnt/aix_"$INSTYPE"_silent_config.txt ux
/opt/IBM/ITM/bin/itmcmd config -A -p /mnt/aix_"$INSTYPE"_silent_config.txt ul
/opt/IBM/ITM/bin/itmcmd config -A -p /mnt/aix_"$INSTYPE"_silent_config.txt um
/opt/IBM/ITM/bin/itmcmd agent start ux
unmount /mnt
