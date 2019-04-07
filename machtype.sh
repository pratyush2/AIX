#!/bin/ksh
# Determine machine type
# Jim O'Quinn  2/28/93
# AIX Software Support
# This does not represent my employer, use at own risk.....
# Changed to report newer machines and unknown ids. /Fred
# More new machines. /David

MachType=`uname -m | cut -c9-10`
case $MachType
in
  02)  nMachType="7015/930";;
  10)  nMachType="7013/530 or 7016/720 or 7016/730";;
  11|14)  nMachType="7013/540";;
  18)  nMachType="7013/53H";;
  1C)  nMachType="7013/550";;
  20)  nMachType="7015/930";;
  2E)  nMachType="7015/950 or 7015/950E";;
  30)  nMachType="7013/520 or 7018/740 or 7018/741";;
  31)  nMachType="7012/320";;
  34)  nMachType="7013/52H";;
  35)  nMachType="7012/32H or 7012/320E";;
  37)  nMachType="7012/340 or 7012/34H";;
  38)  nMachType="7012/350";;
  41)  nMachType="7011/220 or 7011/22W or 7011/22G or 7011/230";;
  42)  nMachType="7006/41T or 7006/41W";;
  43)  nMachType="7008/M20";;
  45)  nMachType="7011/220 or 7011/M20 or 7011/230 or 7011/23W";;
  46)  nMachType="7011/250";;
  47)  nMachType="7011/230";;
  48)  nMachType="7009/C10";;
  49)  nMachType="7011/250";;
  4C)  nMachType="604/43P";;
  4D)  nMachType="601/40P";;
  57)  nMachType="7012/390 or 7012/3BT or 7030/3BT or 7032/3AT or 7011/390";;
  58)  nMachType="7012/380 or 7012/3AT or 7030/3BT";;
  59)  nMachType="3CT or 39H";;
  5C)  nMachType="7013/560";;
  63)  nMachType="7015/970 or 7015/97B";;
  64)  nMachType="7015/980 or 7015/98B";;
  66)  nMachType="7013/580 or 7013/58F or 7015/580";;
  67)  nMachType="7013/570 or 7013/770 or 7013/771 or 7013/R10 or 7015/570";;
  70)  nMachType="7013/590";;
  71)  nMachType="7013/58H";;
  72)  nMachType="7013/59H or 7013/R12 or 7013/58H";;
  75)  nMachType="7012/370 or 7012/375 or 7012/37T";;
  76)  nMachType="7012/360 or 7012/365 or 7012/36T";;
  77)  nMachType="7012/315 or 7012/350 or 7012/355 or 7012/510 or 7012/55H or 7012/55L";;
  78)  nMachType="7012/315 or 7013/510";;
  79)  nMachType="7013/590";;
  80)  nMachType="7015/990";;
  82)  nMachType="7015/R00 or 7015/R24";;
  90)  nMachType="IBM C20";;
  91)  nMachType="604/42T";;
  A0)  nMachType="7013/J30 or 7013/R30";;
  A3)  nMachType="7013/R30";;
  A6)  nMachType="7012/G30";;
  C4)  nMachType="F40";;
  E0)  nMachType="603/MOTOROLA PowerStack";;
  *)  nMachType="Unknown($MachType)"
esac
echo "Machine type: "$nMachType""
