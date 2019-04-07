#!/usr/bin/ksh
for line in `cat /tmp/hostlist`                      
 do                                                     
	start=none
	stop=none
 	rhost_long=`echo $line |cut -f 1 -d .`               
	if [ -f /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt ]; then
		if grep "$rhost_long: running mksysb ... to file" /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt > /dev/null 
		then
				start=`grep "$rhost_long: running mksysb ... to file" /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt | cut -c1-14` > /dev/null
		fi
		if grep "$rhost_long: mksysb completed to" /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt > /dev/null
		then
				stop=`grep "$rhost_long: mksysb completed to" /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt | cut -c1-14`
		fi
	fi
	if [ $stop = "none" ] 
	then
		junk=non
	else		
		echo "$rhost_long $start $stop"
	fi
 done
exit 0
