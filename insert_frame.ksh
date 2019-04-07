#!/usr/bin/ksh
############################################################################### 
# Script Name:	insert_frame.ksh
# Author:	Don Abell
# Creation Date:09/17/2004
#
# Description:	update frame table
#
#
# Modification History:
#
# Initials	Date	Modification Description
# --------    --------  ---------------------------------------------------
#
#
############################################################################### 

script_dir=/usr/local/scripts		# Where scripts are located
input_dir=/tmp  		# Where input files are located
input_file1=$input_dir/ssdc_FRAME.txt	# input file


$script_dir/insert_frame.pl $input_file1	# Call script

