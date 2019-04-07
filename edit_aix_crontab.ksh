#!/bin/ksh
################################################
### Edit root crontab and add cfg2html_sun.sh###
################################################
grep cfg2html_sun.sh /var/spool/cron/crontabs/root
if [ $? = 0 ] ; then
cp /var/spool/cron/crontabs/root /var/spool/cron/crontabs/root.081806
cat - << EOF | ed /var/spool/cron/crontabs/root
/cfg2html_sun.sh/
d
.
w
q
EOF
else
	echo "No cfg2html_sun.sh found in root cron"
	exit 1
fi
exit 0
