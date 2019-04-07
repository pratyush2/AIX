#!/bin/ksh
systemtype=`uname`                        
host=`hostname`
if [ $systemtype = "SunOS" ]                
then                                      
        echo "System $host is SUN \n"           
fi
if [ $systemtype = "AIX" ]   
then
	echo "System $host is AIX \n"
fi
if [ $systemtype = "Linux" ]
then
	echo "System $host is Linux \n"
fi                                        
