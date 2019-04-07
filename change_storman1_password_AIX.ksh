#!/bin/ksh
# add storman1 acct if not therer, set password and paramters
# change storman1 password and set paramters 
lsuser storman1 >/dev/null 2>&1
if [ $? = 0 ]
then
		echo "Found storman1 account"
		/usr/bin/chuser rlogin=false pwdwarntime=30 loginretries=5 histexpire=0 histsize=0 minage=0 maxage=17 maxexpired=1 minalpha=5 minother=1 maxrepeats=3 mindiff=3 storman1
		/usr/bin/chuser account_locked=false storman1
		/usr/bin/chsec -f /etc/security/lastlog -a "unsuccessful_login_count=0" -s  'storman1'
		/usr/local/bin/setpwd.aix -c -u storman1 -p si00kp
else
		echo "did not find storman1 account"
		/usr/bin/mkuser  pgrp=staff groups=staff home=/home/storman1 shell=/bin/ksh pwdwarntime=30 rlogin=false  loginretries=5 histexpire=0 histsize=0 minage=0 maxage=17 maxexpired=1 minalpha=5 minother=1 maxrepeats=3 mindiff=3 gecos='Storage Management user account' storman1
		/usr/local/bin/setpwd.aix -c -u storman1 -p si00kp
		
fi
STORIDS="D111466 D111487 k252581 k233254 K252549 k134742 k241434 p132830 k232156 k200392 k211668 k236827 w342245 d101593 D111593 I920571 i600299 k013364 y868222 h139325 I772425 Q891615 B731322 A301960 U457538"
for id in $STORIDS
do
	lsuser ^$id >/dev/null 2>&1
	if [ $? = 0 ]; then
		continue
	fi
/usr/bin/mkuser  pgrp=staff groups=staff home=/home/$id shell=/bin/ksh gecos='Storage Management ' $id 
/usr/local/bin/setpwd.aix -u $id -p kaiser
done
exit 0
