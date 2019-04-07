#!/usr/bin/ksh -x

#This script will enable system accounting.

#nulladm command to ensure that each file has the correct access permissions.
/usr/sbin/acct/nulladm wtmp pacct

#Add the startup script to /etc/rc.local
echo "#Startup accounting process" >> /etc/rc.local
echo "/usr/sbin/su - adm -c \"/usr/sbin/acct/startup\"" >> /etc/rc.local

#Create required directories
su - adm -c " cd /var/adm/acct;mkdir nite fiscal sum"
cd /var/adm/acct

#Add crontab entries
cd /var/spool/cron/crontabs
cp root root.`date +%m%d%y`
echo "0 2 * * 4 /usr/sbin/acct/dodisk" >> root
echo "5 * * * * /usr/sbin/acct/ckpacct" >> root
echo "0 4 * * 1-6 /usr/sbin/acct/runacct 2>/var/adm/acct/nite/accterr" >> root
echo "15 5 1 * * /usr/sbin/acct/monacct" >> root

# Submitt the edited cron file, type;
/usr/bin/crontab /var/spool/cron/crontabs/root

exit 0
