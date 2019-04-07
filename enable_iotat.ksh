#!/usr/bin/ksh
#
#
# the hostname!! I only parse for the node name.

    hosts=`/usr/bin/grep -v '^#' temp_host.lis`

    for host in $hosts ; do
        echo "            Doing  " $host
#       ssh $host         /usr/sbin/lsattr -E -l sys0 -a iostat |grep false
#       stat1=$?
#       echo "$stat1"
        ssh $host 'chdev -l sys0 -a iostat=true'
#       stat1=$?
#       echo "$stat1"
#       if (($stat1 == 0 & $stat2 == 0)) then
#           echo $host " iostat error"
#       fi
    done # host loop
