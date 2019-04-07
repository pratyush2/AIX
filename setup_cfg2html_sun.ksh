#!/bin/ksh
grep ossadmin /etc/passwd >/dev/null 2>&1
if [ $? = 0 ]
then
	echo "userid ossadmin exist on `hostname`"
else
	useradd -m -d /export/home/ossadmin -u 30507 -g 3 -c "OSS Administration" -s /bin/ksh -e 09/01/07  ossadmin
fi
/usr/local/bin/setpwd.sol ossadmin  Ets0ss
mkdir /export/home/ossadmin/.ssh >/dev/null 2>&1
chown ossadmin /export/home/ossadmin/.ssh >/dev/null 2>&1
chmod 700 /export/home/ossadmin/.ssh >/dev/null 2>&1
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAz7soxqIK0FAq2bCebHN1XLr4ACU+JKqIusVcQbldHZUSGk0aGb2ritxAlT1EiaPZXcWku8soPmrVHs2AXEdh1PRNiP0C63XkPszCxRPN4hk/CjYFrewHbYMkVrSPwtfWffnq5nyqzHsLbswPZspTXtiHhI5N9/zZ0ifSZNxTSl8= ossadmin@ktazd216" >/export/home/ossadmin/.ssh/authorized_keys
chown ossadmin /export/home/ossadmin/.ssh/authorized_keys  >/dev/null 2>&1 
chmod 700 /export/home/ossadmin/.ssh/authorized_keys  >/dev/null 2>&1      
echo "StrictHostKeyChecking no" >/export/home/ossadmin/.ssh/config
chown ossadmin /export/home/ossadmin/.ssh/config >/dev/null 2>&1 
chmod 700 /export/home/ossadmin/.ssh/config >/dev/null 2>&1      
if [ -d /export/home/ossadmin/.ssh ]
then
	cp /tmp/COMDSAKEY /export/home/ossadmin/.ssh/COMDSAKEY
else
	mkdir /export/home/ossadmin/.ssh
	chown ossadmin /export/home/ossadmin/.ssh
	chmod 700 /export/home/ossadmin/.ssh
	cp /tmp/COMDSAKEY /export/home/ossadmin/.ssh/COMDSAKEY                 
        chown ossadmin /export/home/ossadmin/.ssh/COMDSAKEY
fi
if [ -f /export/home/ossadmin/.ssh/authorization ]
then                                                           
       echo "COMDSAKEY" >>/export/home/ossadmin/.ssh/authorization 
else                                                           
	echo "COMDSAKEY" >/export/home/ossadmin/.ssh/authorization
        chown ossadmin /export/home/ossadmin/.ssh/authorization     	
fi
grep "User_Alias OSS=" /etc/sudoers >/dev/null 2>&1
if [ $? = 0 ]
then
	echo "Seem to already have sudo entries for ossadmin"
else
	cp /etc/sudoers /etc/sudoers.ossadmin
	echo "User_Alias OSS=ossadmin" >>/etc/sudoers
	echo "Cmnd_Alias OSS=/usr/local/scripts/ossadmin.script, /usr/local/scripts/ossadmin.cmd" >>/etc/sudoers
	echo "OSS        ROBMSTR=NOPASSWD:OSS, !SU, !SHELLS, !SSH, !REST" >>/etc/sudoers
fi
touch /usr/local/scripts/ossadmin.script               
chown ossadmin /usr/local/scripts/ossadmin.script
chmod 700 /usr/local/scripts/ossadmin.script           
touch /usr/local/scripts/ossadmin.cmd                   
chown ossadmin /usr/local/scripts/ossadmin.cmd    
chmod 700 /usr/local/scripts/ossadmin.cmd               
