#!/bin/ksh
########################################################################
# 
#       Program Name:   get_aval_bcvs
# 
#       Description:   Created LIST OF AVAILABLE SYMMETRIX BCVS 
# 
#      Requirements:    
# 
#      SccsID: %A% %H% %T%
# 
########################################################################
#       Revision History:
# 
#       Date      Name    Description of Updates:
#       ---------------------------------------------------------
#       1/27/99   Errick Gibson    Update comments
#       
########################################################################
#       
# Usage:  get_avail_bcvs <SYMMETRIX ID> 
#                SYMMETRIX_ID = SYMMETRIX ID TO BE REFERENCED
#                
########################################################################
#hostlist=/home/storman1/gibsone/bin/RFC_HOSTS
hostlist=/home/storman1/RFC_HOSTS
tmpfile1=/home/storman1/TEMPFILE1
rm $tmpfile1
HBA1=fcs0
HBA2=fcs1
HBA3=fcs2
HBA4=fcs3
HBA5=fcs4
HBA6=fcs5
rm $tmpfile1





 for SVRLIST in $(< $hostlist)
do
#GET HOST OSLEVEL AND NAME INFO

 echo  RFC HOST INFO FOR $SVRLIST >> $hostfile
  hostfile=/home/storman1/gibsone/data/SAN_MIC_RPL/${SVRLIST}_MIC.txt
  rm $hostfile
  rm $tmpfile1
   echo "HOSTNAME" >> $hostfile 
   ssh ${SVRLIST}.crdc.kp.org hostname >> $hostfile 
  echo "OS LEVEL" >> $hostfile
  ssh ${SVRLIST}.crdc.kp.org oslevel -r >> $hostfile 
  
#GET HBA INFO
echo "HBA INFORMATION" >> $hostfile
echo "------------------------------------------" >> $hostfile
  ssh ${SVRLIST}.crdc.kp.org lscfg -vl $HBA1  >> $hostfile
  ssh ${SVRLIST}.crdc.kp.org lscfg -vl $HBA2  >> $hostfile
  ssh ${SVRLIST}.crdc.kp.org lscfg -vl $HBA3  >> $hostfile
  ssh ${SVRLIST}.crdc.kp.org lscfg -vl $HBA4  >> $hostfile
  ssh ${SVRLIST}.crdc.kp.org lscfg -vl $HBA5  >> $hostfile
  ssh ${SVRLIST}.crdc.kp.org lscfg -vl $HBA6  >> $hostfile


#GET POWERPATH LEVEL
echo "POWERPATH INFORMATION" >> $hostfile
echo "------------------------------------------" >> $hostfile
ssh ${SVRLIST}.crdc.kp.org lslpp -L | grep EMC*  >> $hostfile

 ssh ${SVRLIST}.crdc.kp.org /usr/local/bin/sudo powermt version  >> $hostfile
 ssh ${SVRLIST}.crdc.kp.org /usr/local/bin/sudo powermt display  >> $hostfile
 ssh ${SVRLIST}.crdc.kp.org /usr/local/bin/sudo powermt display dev=all >> $hostfile

#ssh ktazp438.crdc.kp.org /usr/local/bin/sudo powermt display dev=all >> $hostfile
#GET ODM LEVEL
 
echo "ODM  INFORMATION" >> $hostfile
echo "------------------------------------------" >> $hostfile
 ssh ${SVRLIST}.crdc.kp.org lslpp -L | grep Symm  >> $hostfile

 echo "FIBRE CHANNEL DRIVER REVISION INFORMATION" >> $hostfile
echo "------------------------------------------" >> $hostfile
 ssh ${SVRLIST}.crdc.kp.org lslpp -l | grep devices.pci.df  >> $hostfile
 ssh ${SVRLIST}.crdc.kp.org lslpp -l | grep devices.fcp.disk  >> $hostfile

 
  echo "PHYSICAL VOLUME AND VG INFO" >> $hostfile
  ssh ${SVRLIST}.crdc.kp.org lspv  >> $hostfile
   
 

done
 
