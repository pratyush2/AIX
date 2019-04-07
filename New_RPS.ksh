# Get Empty slot
lsslot -c pci | grep "Empty" | awk '{print $1":"$NF}' > Slot_HWPS.out

# FCS
# ##This is the old code## mFCS=`lsslot -c pci | grep fcs | awk '{print $10}'`
#mFCS=`lsslot -c pci | grep fcs | awk '{print $10}'`
# ##This is the new code## mFCS=`lsslot -c pci -F ':' | awk -F ':' '{print $3}'`
mFCS=`lsslot -c pci -F ':' | grep fcs | awk -F ':' '{print $3}'`

for mFCSX in `echo $mFCS`
do
  mDES=`lsdev -Cc adapter | awk -v aVAR="$mFCSX" '$1 == aVAR {print $4, $5, $6, $7, $8}'`
  mSLOT=`lscfg -vl $mFCSX | awk -F"." '/Location Code/ {print $NF}'`
  mWWN=`lscfg -vl $mFCSX | awk -F"." '/Network Address/ {print $NF}'`
  echo "$mSLOT:$mDES:$mWWN" >> Slot_HWPS.out
done

# Network
mENT=`lsdev -Cc adapter |grep "ent" | grep -v "Logical" | awk '{print $1}'`
for mENTX in `echo $mENT`
do
  lscfg -vl $mENTX | grep $mENTX | awk '{print $2":"$3,$4,$5,$6}' >> Slot_HWPS.out
done
# Disk
for SAS in $(lscfg -v  | grep sissas | awk '{print $1}')
do
lscfg -v | grep -w $SAS  | awk '{print  $2": SAS Adapter"}'
sissasraidmgr -L -j1 -l $SAS | grep hdisk | awk '/Available/ {print ":"$1":"$NF}'
done >> Slot_HWPS.out

