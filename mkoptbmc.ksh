mklv -y'lv_bmc' -t'jfs' rootvg 16
crfs -v jfs -a bf=true -d'lv_bmc' -m'/opt/bmc' -a nbpi='16384' -a ag='64'
mount /opt/bmc

mkgroup -'A' dbsysadm
mkuser id='10241' pgrp='dba' groups='dba,staff,db2sysadm' home='/opt/bmc' gecos='Patrol Admin Account' loginretries='0' pwdwarntime='0' histsize='0' histexpire='0' maxage='0' minage='0' minlen='0' minalpha='0' minother='0' mindiff='0' patrol

mkdir /opt/bmc/mnt
chown -R patrol.dbsysadm /opt/bmc
