# !/bin/ksh
#  Script Name = /usr/local/scripts/create_snaadmin.ksh
# Author = Saul Ramos
# Creation Date = 8/17/1999
# Functional Description: This script needs to be executed with root
# authority. It will create GroupID sna with GID = 1600
# and UserID snaadmin with UID=1500 to allow SNA administrators
# manage the SNA application through smitty, xsnaadmin and command line # interfaces.

#create GroupID
mkgroup -'A' id='1600' sna

#create UserID
x() {
LIST=
SET_A=
for i in  "$@"
do
	if ["$i" = "admin=true"]
	then
		SET_A="-a"
		Contirnue
	fi
	LIST="$LIST \"$i"\ ""
done
eval mkuser $SET_A $LIST
}
x id='1500' pgrp='sna' groups='staff, sna' home='/home/snaadmin' shell='bin/ksh' gecos='SNA admin account for SNA adminitrators' snaadmin

# Change file access permission for sna group.
chgrp sna /usr/bin/X11/xsnaadmin
chgrp sna /usr/bin/snaadmin
chgrp sna /usr/bin/smitsnaadmin
chgrp sna /var/sna
chgrp sna /etc/sna
chgrp sna /etc/rc.sna
chgrp sna /usr/bin/sna*
chmod 775 /etc/rc.sna
chmod 770 /etc/sna
chmod 770 /var/sna

ls -ld /usr/bin/X11/xsnaadmin
ls -ld /usr/bin/smitsnaadmin
ls -ld /usr/bin/snaadmin
ls -ld /var/sna
ls -ld /etc/sna
ls -ld /etc/rc.sna
ls -ld /usr/bin/sna*

echo "Job completed....."
