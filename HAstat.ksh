#!/usr/bin/ksh

# Modification History
# 200608xx Created
# 20060901 Fixed Date problem
# 20060911 Filter out paragraphs that do not have verification
#          Added log file
#
file=/var/adm/cfg/hacmp/HAstat
echo "$(date) HAstat.ksh started" >> $file.log

{
grep -v "^#" /usr/local/scripts/HAstat.list > /usr/local/scripts/HAstat.list.filtered
export WCOLL=/usr/local/scripts/HAstat.list.filtered
export DSH_REMOTE_CMD=/usr/local/bin/ssh
DAY="$(date +"%a %b") $(date +%e)"
YEAR=$(date +%Y)
# version 2 
/opt/csm/bin/dsh -v lslpp -lcq -Or cluster\*server.rte \| cut -d: -f3,7 \;grep -i \"^${DAY}.*${YEAR}.* error\" /var/hacmp/log/clutils.log
#/opt/csm/bin/dsh -v /usr/local/bin/sudo /usr/local/scripts/ossadmin.cmd ./haclvstat.ksh
} 2>$file.stderr | /opt/csm/bin/dshbak -c >$file.full

grep -p verification $file.full > $file
echo "$(date) HAstat.ksh finished" >> $file.log

{
echo "\nRun at $(date)"
echo $(grep HOSTS $file.full | wc -l) " clusters checked."
echo $(grep verifi $file.full | wc -l) " clusters reported."
echo $(grep verifi $file.full | grep -v " 0 " | wc -l) " clusters reported errors."
grep verifi $file.full | grep -v " 0 "
} >> $file.summary

exit 0
