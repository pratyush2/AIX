#!/usr/bin/ksh
############################################################################### 
# Script Name:	insert_backup.ksh
# Author:	Pat Mogilnicki 
# Creation Date:02/23/2000
#
# Description:	Get today's CD/DVD images created and update oracle backup table
#		Input file is created on ktazp95 and ktazp131 and stored 
#	       in /var/adm/cfg on ktazd216 with the name backup_extract_xxx.txt	
#
# Usage: 	Called from root's crontab each day.
#
# Modification History:
#
# Initials	Date	Modification Description
# --------    --------  ---------------------------------------------------
#
#
############################################################################### 

script_dir=/usr/local/scripts		# Where scripts are located
input_dir=/var/adm/cfg   		# Where input files are located
input_file1=$input_dir/backup_extract.ktazp95.txt	# Today's input file
input_file2=$input_dir/backup_extract.ktazp131.txt 

$script_dir/insert_backup.pl $input_file1	# Call script
$script_dir/insert_backup.pl $input_file2       # Call script
