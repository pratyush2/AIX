#!/usr/bin/ksh
############################################################################### 
# Script Name:	insert_hmc.ksh
# Author:	Don Abell
# Creation Date:09/17/2004
#
# Description:	update hmc table
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
input_file1=$input_dir/ssdc_HMC.txt	# input file


$script_dir/insert_hmc.pl $input_file1	# Call script

