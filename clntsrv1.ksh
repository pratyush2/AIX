#!/usr/bin/ksh
################################################################################
#
# Written by : Kevin Lee - USS, Associate System Programmer 
# Date   : 09/28/99
# Modified: 02/03/2000
# Last Modified: 02/12/2001
# Description: This scripts run weekly to collect the server and client list
#              and also checking for the result of the backup
################################################################################
# Define the new log file name.
LOGFILE=/data/WEB/docs_private/uds_internal/pp/sysback/logs/clntsrv.kshlog    
# Kill any [old] processes     
if [ -f $LOGFILE ]; then       
        fuser -k $LOGFILE      
fi                             
# Empty the log file.          
cat /dev/null > $LOGFILE       

orgfile=/usr/local/scripts/cfgtable
logfile=/usr/local/scripts/sysback/result.out
htfile=/usr/local/scripts/sysback/result.html
ffile=/usr/local/scripts/sysback/failed.out
htffile=/usr/local/scripts/sysback/failed.html
pfile=/usr/local/scripts/sysback/nonpingable.out

userid=ossadmin
password=Ets0ss
part0='<tr>'
part1='<td>'
part2='</td>'
part3='</tr><tr>'
part4='<td><a href="/uds_internal/pp/sysback/logs/'
part5='">View Log</a></td>'

((scount=0))  # backup success counter
((fcount=0))  # backup fail counter
((ncount=0))  # client does not setup for backup
((tcount=0))  # backup server total

rm $logfile $htfile $ffile $htffile $pfile 
sleep 3
touch $logfile $htfile $ffile $htffile $pfile 
sleep 3

# create the html file header
print "<HTML>" >> $htfile
print "<HEAD>" >> $htfile
print "<TITLE>Sysback Server/Client and Result List For AIX/UNIX Servers</TITLE>" >> $htfile 
print "</HEAD>" >> $htfile
print "<BODY BGCOLOR=#FEFEEF TEXT=#000000 LINK=#0000FF VLINK=#000080 ALINK=#FF0000>" >> $htfile
print "<H1><FONT face=verdana,arial,helvetica size=+1>SYSBACK Client/Server and Result List</FONT></H1>" >> $htfile
print "<p><FONT face="arial,helvetica" size=2>DATE: `date` </FONT>" >> $htfile
print "<br><FONT face=arial,helvetica size=2>Generated by ktazd216:$0 </FONT>" >> $htfile
print "<HR>" >> $htfile
#
#
# Create the "failed" html header
print "<HTML>" >> $htffile
print "<HEAD>" >> $htffile
print "<TITLE>Sysback Client/Server and Result For AIX/UNIX Servers</TITLE>" >> $htffile
print "</HEAD>" >> $htffile
print "<BODY BGCOLOR=#FEFEEF TEXT=#000000 LINK=#0000FF VLINK=#000080 ALINK=#FF0000>" >> $htffile
print "<H1><FONT face=verdana,arial,helvetica size=+1>SYSBACK FAILED BACKUP AND PROBLEM LOG LIST</FONT></H1>" >> $htffile
print "<H3><FONT face=verdana,arial,helvetica size=-1>DATE: `date` </FONT></H3>" >> $htffile
print "<HR>" >> $htffile
#
#((number=1))
for line in `cat /usr/local/scripts/cfgtable`
 do 
	if [[ -z $line ]]; then
		break 
	else
		client=`echo $line`
		rhost_long=`echo $line`
		rhost=`echo $line | cut -f1 -d.`
		first=`echo "$line" | /usr/bin/cut -c 1` # cut the first char
		echo "$first"
		if [[ $first != "#" ]]; then
	         # if not comment go-on		
		 ping -c 2 -i 5 $client
		 if [[ $? = 0 ]]; then
		  /usr/local/scripts/sysback/servsftp  $rhost $rhost_long $userid $password 
		 else
			echo "$client" >>pfile
		 fi
		fi
        fi
 done
cd /data/WEB/docs_private/uds_internal/pp/sysback/logs  
ls ktaz1b*.servers >/tmp/server.list                    
ls ktaz2b*.servers >>/tmp/server.list                   
ls ktazd*.servers >>/tmp/server.list                    
ls ktazi*.servers >>/tmp/server.list                    
ls ktazp*.servers >>/tmp/server.list                    
ls ktazq*.servers >>/tmp/server.list                    
ls ktazs*.servers >>/tmp/server.list                    
exit 0
