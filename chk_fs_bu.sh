#!/bin/ksh

######
#
#   chk_fs_bu.sh: Checks all mount points for + file returns
#		  from rbls against mount point. If true, echos...
#   JMK SCH 11/11/97
#   Bill Metzger, SCH 01/20/1998 Revised to lookfor backed up files and assume
#				 the filesystem was backed up if any are found.
#	(Unsupported)
#
######
DFFILE=/tmp/df_fsys.out
MAILFILE=/tmp/fsys_chk.ml
>${MAILFILE}

# Parse teh df -k report and look for all the mounted filesystems.
# The report is in the following format:
#
# Filesystem    1024-blocks      Free %Used    Iused %Iused Mounted on
# /dev/hd4            16384      7660   54%     1422    18% /
# /dev/hd2          1007616    200180   81%    28760    12% /usr
# /dev/hd9var         49152     42208   15%      223     2% /var
# /dev/hd3            32768     29784   10%      221     3% /tmp
# /dev/hd1             8192      7612    8%       79     4% /home
# /dev/logslv        237568    191836   20%       29     1% /logs
# /dev/lv00           16384     15724    5%       17     1% /reports
# /dev/sysbacklv     7667712   3834424   50%       74     1% /sysbackfsb
#
# Select the right-most column, and pass its value (i.e., /home) into the
# do loop below.
#
MISSED_FILESYSTEMS=0
for FSYS in    `df -k			| \
		grep -v "Filesystem"	| \
		grep -v "/tmp"		| \
		grep -v "/temp"		| \
		grep -v "/oracle_link"	| \
		tr '\11' ' '		| \
		tr -s ' ' ' '		| \
		cut -f7 -d' '`
do
	# Ask REELbackup how many files it's backed up in the named filesystem
	# (in FSYS).
	#
	BACKED_UP_FILES=`/usr/local/bin/rbls ${FSYS}	| \
			 grep \#	| \
			 wc -l`
	
	# If no files in FSYS have been backed up, say so!
	#
	if [ ${BACKED_UP_FILES} -eq 0 ]
	then
		MISSED_FILESYSTEMS=1
		echo "`date '+%D'` - Filesystem '${FSYS}' on `uname -n` doesn't appear to be in the backup list." >> ${MAILFILE}
	fi
done

# If unbacked up filesystems were found, send mail.
#
if [ ${MISSED_FILESYSTEMS} -ne 0 ]
then
	cat ${MAILFILE} | mail reelmsg@ussmail.crdc.kpscal.org
#	rm  ${MAILFILE}
fi
# -----------------------------------------------------------
# Added by Kevin Lee (USS) to capture file system list 
# can be later collect by ktazp34 getfile script then it will
# be put in ktazp20:/reports/filesystem directory
# -----------------------------------------------------------
rm ${DFFILE}
touch ${DFFILE}
echo "`hostname`" >${DFFILE}
df -k >>${DFFILE}

