#!/usr/bin/ksh
################################################################################
#
# Written by : Kevin Lee - USS, Associate System Programmer 
# Modifed by : Donald Abell 
# Date   : 09/28/99
# Modified: 02/03/2000
# Last Modified: 09/12/2006
# Description: This scripts run weekly to collect the server and client list
#              and also checking for the result of the alt_disk backups
################################################################################
# Define the new log file name.
LOGFILE=/data/WEB/docs_private/uds_internal/pp/sysback/logs/clntsrv3.kshlog    
# Kill any [old] processes     
if [ -f $LOGFILE ]; then       
        fuser -k $LOGFILE      
fi                             
# Empty the log file.          
cat /dev/null > $LOGFILE       

logfile=/usr/local/scripts/sysback/mksysbresult.out
htfile=/usr/local/scripts/sysback/mksysbresult.html
pfile=/usr/local/scripts/sysback/mksysbpingable.out

userid=ossadmin
password=Ets0ss
part0='<tr>'
part1='<td>'
part2='</td>'
part3='</tr><tr>'
part4='<td><a href="/uds_internal/pp/sysback/logs/' 
part5='"&TYPE=Log>mksysb Log</a></td>'       
part6='"&TYPE=Log>error Log</a></td>'
part7='"&TYPE=Log>archive Log</a></td>'
part8='<td>'
part9='</td>'
part10='">Restore Image</a></td>'	

((scount=0))  # backup success counter mksysb
((fcount=0))  # backup fail counter mksysb
((tcount=0))  # backup server total
((ucount=0))  # unknown system counter

rm $logfile $htfile $pfile 
sleep 3
touch $logfile $htfile  $pfile 
sleep 3

# create the html file header
print "<HTML>" >> $htfile
print "<HEAD>" >> $htfile
print "<TITLE>Alt_Disk Client Result List For AIX/UNIX Servers</TITLE>" >> $htfile 
print "</HEAD>" >> $htfile
print "<BODY BGCOLOR=#FEFEEF TEXT=#000000 LINK=#0000FF VLINK=#000080 ALINK=#FF0000>" >> $htfile
print "<H1><FONT face=verdana,arial,helvetica size=+1>mksysb BACKUP Client Result List</FONT></H1>" >> $htfile
print "<p><FONT face="arial,helvetica" size=2>DATE: `date` </FONT>" >> $htfile
print "<br><FONT face=arial,helvetica size=2>Generated by ktazd216:$0 </FONT>" >> $htfile
print "<HR>" >> $htfile
#
#
#
/usr/local/scripts/sysback/servsftp4 ktazd216  ktazd216  ossadmin ets0ss >>$LOGFILE
/usr/local/scripts/sysback/servsftp4 ktazp131  ktazp131  ossadmin ets0ss >>$LOGFILE
/usr/local/scripts/sysback/servsftp4 ktazp1560 ktazp1560 ossadmin ets0ss >>$LOGFILE
/usr/local/scripts/sysback/servsftp4 ktazp8001 ktazp8001 ossadmin ets0ss >>$LOGFILE
/usr/local/scripts/sysback/servsftp4 ktazp95   ktazp95   ossadmin ets0ss >>$LOGFILE
/usr/local/scripts/sysback/servsftp4 ktazd2750 ktazd2750 ossadmin ets0ss >>$LOGFILE
/usr/local/scripts/sysback/servsftp4 ktazp2776 ktazp2776 ossadmin ets0ss >>$LOGFILE
/usr/local/scripts/sysback/servsftp4 ktazd2750 ktazd2750 ossadmin ets0ss >>$LO
ILE                                                                           
/usr/local/scripts/sysback/servsftp4 fig       fig       ossadmin ets0ss >>$LOGFILE
for line in `cat /usr/local/scripts/cfgtable`                      
 do                                                     
	client=`echo $line |cut -f 1 -d .`
 	rhost_long=`echo $line |cut -f 1 -d .`               
	status=unknown
	server=unknown
	logs=unknown
	errors=unknown
	date=unknown
	if [ -f /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.err.txt ]; then
		logs="$rhost_long.mksysb.log.txt"
		errors="$rhost_long.mksysb.err.txt"
		if grep "$rhost_long: mksysb completed to $rhost_long.mksysb successfull." /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt > /dev/null 
		then
			status="mksysb_good"
			echo "/usr/tivoli/tsm/client/ba/bin/dsmc retr -replace=yes  /export/nim/mksysb/$rhost_long.*" >/data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.restore_mksysb.ksh
			if [ -f /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt ]
			then
				logs="$rhost_long.mksysb.log.txt"
				server=`grep "$rhost_long: running mksysb ... to file" /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt | awk '{print $11}'` > /dev/null
				date=`grep "$rhost_long: running mksysb ... to file" /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt | cut -c1-14`
				((scount=scount+1))
			fi
		fi
	fi
	if [ -f /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.err.txt ] 
	then
		logs="$rhost_long.mksysb.log.txt"
		errors="$rhost_long.mksysb.err.txt"
		if grep "$rhost_long: ERROR mksysb did not complete to $rhost_long.mksysb successfully." /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.err.txt > /dev/null
		then                       
                	status="mksysb_fail"     
		        if [ -f /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt ]; then 
				logs="$rhost_long.mksysb.log.txt"
				server=`grep "$rhost_long: running mksysb ... to file" /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt | awk '{print $11}'` > /dev/null
				date=`grep "$rhost_long: running mksysb ... to file" /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.log.txt | cut -c1-14` 
				((fcount=fcount+1))
        		fi                         
		else
			if grep "ERROR nfs mount issue" /data/WEB/docs_private/uds_internal/pp/sysback/logs/$rhost_long.mksysb.err.txt > /dev/null
			then
				status="NFS mount issue"
			fi
		fi
	fi
	echo "$part0" >>$logfile
       	echo "$part1$client$part2" >>$logfile
	echo "$part1$status$part2" >>$logfile
	echo "$part1$server$part2" >>$logfile
	echo "$part4$logs$part5" >>$logfile
	echo "$part4$errors$part6" >>$logfile
	echo "$part4$rhost_long.tsmarch2.txt$part7" >>$logfile
	echo "$part1$date$part2" >>$logfile
	if [ "$status" = "mksysb_good" ] 
	then
		echo "$part4$rhost_long.restore_mksysb.ksh$part10" >>$logfile	
	else
		echo "$part1$status$part2" >>$logfile
	fi
       	echo "$part3" >>$logfile
  	if [ "$status" = "unknown" ]
	then
		((ucount=ucount+1))
  	fi
 done
((tcount=scount+fcount+ucount))
# combine the logfile and html file together
print "<div ALIGN=RIGHT><FONT face=verdana,arial,helvetica size=2><b>Total mksysb backup completed: $scount</b></FONT></div>" >> $htfile
print "<div ALIGN=RIGHT><FONT face=verdana,arial,helvetica size=2><b>Total mksysb backup failed: $fcount</b></FONT></div>" >> $htfile
print "<div ALIGN=RIGHT><FONT face=verdana,arial,helvetica size=2><b>Total backup unknown: $ucount</b></FONT></div>" >> $htfile
print "<div ALIGN=RIGHT><FONT face=verdana,arial,helvetica size=2><b>Total backup check: $tcount</b></FONT></div>" >> $htfile
print "<HR>" >> $htfile
print "<table border=2 cellspacing=2 cellpadding=2>" >>$htfile  
print "<tr><b>" >>$htfile                                       
print "<td><b>CLIENT</b></td>" >>$htfile
print "<td><b>STATUS</b></td>" >>$htfile
print "<td><b>SERVER</b></td>" >>$htfile
print "<td><b>LOG</b></td>" >>$htfile
print "<td><b>ERROR_LOG</b></td>" >>$htfile
print "<td><b>ARCHIVE_LOG</b></td>" >>$htfile
print "<td><b>DATE</b></td>" >>$htfile
print "<td><b>RESTORE</b></td>" >>$htfile
cat $logfile >> $htfile
print "</tr>" >> $htfile
print "</table>" >> $htfile
print "</BODY>" >> $htfile
print "</HTML>" >> $htfile
#
#
cp /usr/local/scripts/sysback/mksysbresult.html /data/WEB/docs_private/uds_internal/pp/sysback/mksysbresult.html
exit 0