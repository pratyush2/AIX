#!/usr/bin/ksh
############################################################################### 
# Script Name:	insert_uptime.ksh
# Author:	Pat Mogilnicki 
# Creation Date:02/23/2000
#
# Description:	Get today's date then call insert_uptime.pl passing the
#		input file containing the system availability data.  This
#		data will be inserted into the USS database.
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

today=$(date +%m%d%y)			# Today's date
script_dir=/usr/local/scripts		# Where scripts are located
input_dir=/export/totalavail		# Where input files are located
input_file=$input_dir/total.$today	# Today's input file

$script_dir/insert_uptime.pl $input_file	# Call script
#rm /export/availability/*
