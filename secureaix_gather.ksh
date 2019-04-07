#!/bin/ksh                                                                      
if grep "sendmail" /var/spool/cron/crontabs/root > /dev/null                    
then                                                                            
        X11="Y"                                                                 
else                                                                            
        X11="N"                                                                 
fi                                                                              
if grep "auth.info" /etc/syslog.conf >  /dev/null                               
then                                                                            
        X10="Y"                                                                 
else                                                                            
        X10="N"                                                                 
fi                                                                              
if grep "umask 022" /etc/security/.profile > /dev/null 
then
       X9="Y"                                                                  
else                                                                           
       X9="N"                                                                  
fi                                                                             
if grep "TIMEOUT=" /etc/profile > /dev/null
then 
       X8="Y"                                                                  
else                                                                           
       X8="N"                                                                  
fi                                                                             
if grep "guest:" /etc/passwd > /dev/null                                        
then                                                                            
        X7="N"                                                                  
else                                                                            
        X7="Y"                                                                  
fi                                                                              
maxage=`lssec -f /etc/security/user -s default -a maxage |awk '{print $2}'`     
if [ $maxage = "maxage=8" ]; then                                               
        X6="Y"                                                                  
else                                                                            
        X6="N"                                                                  
fi                                                                              
if grep "#telnet" /etc/inetd.conf > /dev/null
then
        X5="Y"                                                                  
else                                                                            
        X5="N"                                                                  
fi                                                                              
if grep "#ftp     stream" /etc/inetd.conf  > /dev/null
then
        X4="Y"                                                                  
else                                                                   
        X4="N"                                                         
fi                                                                     
rlogin=`lsuser -a rlogin root |awk '{print $2}'`                       
if [ $rlogin = "rlogin=false" ]; then                                  
        X3="N"                                                         
else                                                                   
        X3="Y"                                                         
fi                                                                     
if lslpp -l freeware.tcp_wrappers.rte > /dev/null                      
then                                                                   
        X2="Y"                                                         
else                                                                   
        X2="N"                                                         
fi                                                                     
rcmds=`ls -la /usr/bin/rsh |awk '{print $1}'`                          
if [ $rcmds = "-r-sr-xr-x" ]; then                                     
        X1="N"                                                         
else                                                                   
        X1="Y"                                                         
fi                                                                     
echo "`hostname`:$X1:$X2:$X3:$X4:$X5:$X6:$X7:$X8:$X9:$X10:$X11" >/tmp/`hostname`.security_attrib.txt
