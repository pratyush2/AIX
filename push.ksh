# Script Name:          Push file to Remote server
# Author:               Sonnie Nguyen
# Modified By:		Donavon Lerman
# Creation Date:        10/11/2006
# Modified Date:	06/06/07
# Description:          Using a hostfile list to push file remote system

PN=`basename "$0"`

Usage () {
   echo >&2 "$PN - This script will push file to remote server.

     usage: $PN command [arg ...]
              arg is a file contain a list of remote servers.

              Ex.
              # $PN hostname.dat

              example format:
              ktazd216
              ktazd217"
   exit 1
}

[ $# -lt 1 ] && Usage

for line in `cat $1`
do
	LOCALDIR="/usr/local/scripts"
	PUSHFILE="cfg2html_aix.sh"
	RHOST=`echo $line | cut -f1 -d" "`
	RDIR="/usr/local/scripts/"
	PRG="/usr/bin/scp"
	CMD="$PRG $LOCALDIR/$PUSHFILE $RHOST"
	

   
	# echo >&2 "HOST: $RHOST"
	# echo >&2 "LOCALDIR: $LOCALDIR"
	# echo >&2 "PUSHFILE: $PUSHFILE"
	# echo >&2 "RHOST: $RHOST"
	# echo >&2 "RDIR: $RDIR"
	# echo >&2 "PRG: $PRG"
	# echo >&2 "CMD: $CMD"
	# echo >&2 "\:$RDIR"
	 
	# echo >&2 /usr/bin/scp $LOCALDIR/cfg2html_aix.sh $RHOST\:/usr/local/scripts/.
	# `/usr/bin/scp $LOCALDIR/cfg2html_aix.sh $RHOST\:/usr/local/scripts/.`
	echo "+-----------------------------------+"
	echo "host: $RHOST"
	/usr/bin/scp $LOCALDIR/cfg2html_aix.sh $RHOST:/usr/local/scripts/.


	# exit 1

   # /usr/bin/ssh $RHOST /tmp/get_info.ksh

done
exit 0
