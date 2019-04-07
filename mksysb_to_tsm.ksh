#!/bin/ksh
#
# script: mksysb_to_tsm.ksh
# purpose: confugure TSM BA env with TSM node name <hostname>_mksysb
#          and performs archive of $fs to TSM Server on ktazp1841
#          $trg_mc defines what TSM MC will be used for archived objects
# parameters: specify -delete option to delete files under $fs after archiving
# dsmc output: log file under $fs names mksysb_to_tsm.$dt
# other output: stdout
#
# sergey@tantlevskiy@kp.org
# 04/10/2005 - version 1.0
#

# global vars
dsmsys=/usr/tivoli/tsm/client/ba/bin/dsm.sys
dsmopt=/usr/tivoli/tsm/client/ba/bin/dsm.opt
alias dsmc_cmd='/usr/tivoli/tsm/client/ba/bin/dsmc'
tsmsrv=tsm1841_mksysb
# defines what interface to use on the tsm server
tsmsrvip=ktaze1841.crdc.kp.org
hst=$(hostname)
dt=$(date +%y%m%d%H%M)

# archive vars
fs=/sysbackfs
trg_mc=mc_arch_30

#################################
# function: errchk
# purpose: check rc of calling routine
# parameters: none
#################################
errchk()
{

if [[ $errno -ne 0 ]]
then
        echo E `date` $errmsg
        exit $errno
else
        echo I `date` $errmsg
fi

}
#################################
#
#################################
# function: cfg_dsmsys
# purpose: configure dsm.sys stanza for mksysb images destination
# parameters: none
#################################
cfg_dsmsys()
{

if [[ ! -s $dsmsys ]]
then
	touch $dsmsys
fi

if [[ ! -s $dsmopt ]]
then
        touch $dsmopt
fi

grep -q $tsmsrv $dsmsys
if [[ $? -eq 0 ]]
then
	return 0
fi

# ready to add new stanza to dsm.sys
add_dsmsys $tsmsrv $tsmsrvip $hst
if [[ $? -ne 0 ]]
then
	echo E `date` failed to configure $dsm.sys, terminating
	exit 1
fi

echo > /usr/tivoli/tsm/client/ba/bin/inclexcl.list

}
#################################
#
#################################
# function: cfg_tsmpwd
# purpose: initialize tsm pwd for a node
# parameters: none
#################################
cfg_tsmpwd()
{

echo xxx | dsmc_cmd q sess -se=$tsmsrv 1>/dev/null 2>&1 
if [[ $? -ne 0 ]]
then
	echo E `date` failed to connect to  $tsmsrv, terminating
	echo I `date` you will be prompted to initialize TSM password
	dsmc_cmd q sess -se=$tsmsrv
fi

echo xxx | dsmc_cmd q sess -se=$tsmsrv 1>/dev/null 2>&1 
if [[ $? -ne 0 ]]
then
        echo E `date` failed to connect to  $tsmsrv, terminating
	exit 1
fi

}
#################################
#
#################################
# function: add_dsmsys
# purpose: add new stanza to dsm.sys
# parameters: tsmsrv tsmsrvip tsmnode
#################################
add_dsmsys()
{

servername="servername $1"
tcpserveraddr="tcpserveraddr $2"
nodename="nodename $3_mksysb"
schedlogret="schedlogret 10"
errorlogret="errorlogret 10"
schedlog="schedlogn $fs/$3_mksysb.schlog"
errorlog="errorlogn $fs/$3_mksysb.errlog"
commmethod="commmethod tcpip"
tcpport="tcpport 1500"
passwordacc="passwordacc generate"
largecommbuff="largecommbuff yes"
inclexcl="inclexcl /usr/tivoli/tsm/client/ba/bin/inclexcl.list"
tcpnodelay="tcpnodelay no"
tcpwindowsize="tcpwindowsize 256"
tcpbuffsize="tcpbuffsize 32"
resourceutil="resourceutil 2"
enablelanfree="enablelanfree no"
schedmode="schedmode polling"
manageds="manageds schedule"

echo >> $dsmsys
echo \* auto-generated on $dt >> $dsmsys || return 1
echo $servername >> $dsmsys || return 1
echo $tcpserveraddr >> $dsmsys || return 1
echo $nodename >> $dsmsys || return 1
echo $schedlogret >> $dsmsys || return 1
echo $errorlogret >> $dsmsys || return 1
echo $schedlog >> $dsmsys || return 1
echo $errorlog >> $dsmsys || return 1
echo $commmethod >> $dsmsys || return 1
echo $tcpport >> $dsmsys || return 1
echo $passwordacc >> $dsmsys || return 1
echo $largecommbuff >> $dsmsys || return 1
echo $inclexcl >> $dsmsys || return 1
echo $tcpnodelay >> $dsmsys || return 1
echo $tcpwindowsize >> $dsmsys || return 1
echo $tcpbuffsize >> $dsmsys || return 1
echo $resourceutil >> $dsmsys || return 1
echo $enablelanfree >> $dsmsys || return 1
echo $schedmode >> $dsmsys || return 1
echo $manageds >> $dsmsys || return 1

return 0

}
#################################
#
#################################
do_arch()
{

if [[ $1 = "-delete" ]]
then
	deletefiles="-deletefiles"
else
	deletefiles=""
fi

echo xxx | dsmc_cmd q sess -se=$tsmsrv 1>/dev/null 2>&1 
errno=$? && errmsg="attempt to connect to the TSM Server completed with rc $errno" && errchk

find $fs -type f -mtime -10 > /tmp/mksysb_to_tsm.filelist

dsmc_cmd arch -archmc=$trg_mc -se=$tsmsrv -descr=$dt $deletefiles \
-filelist=/tmp/mksysb_to_tsm.filelist > $fs/mksysb_to_tsm.$dt

errno=$? && errmsg="mksysb to TSM archival completed with rc $errno, log file is mksysb_to_tsm.$dt" && errchk

find $fs/mksysb_to_tsm* -mtime 30 -type f -exec rm {} \;


}
#################################
# end of functions
#################################


#
# main
#

if [[ $1 = "-delete" ]]
then
	opt=$1
else
	opt=""
fi

cfg_dsmsys
cfg_tsmpwd
do_arch $opt

exit 0
