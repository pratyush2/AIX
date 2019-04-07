#!/bin/ksh
# query_hosts_template.ksh
#
# This script reads a file containing hostnames and queries the systems
# based on information passed on the secure shell command line (ssh).  The
# information returned is written to an output file with hosts that are 
# unreachable written to an error file.  Input, output and error files
# are all written to the current directory.  $0 (script name) has the
# file extension stripped off.  Edit the /usr/local/bin/ssh line for 
# what you want to query on each host.
#
# Run the script as root.  
# USAGE:	./query_hosts_template input_file
# 
# Input file:	Specified on command line or defaults to $0.in
#		ie. query_hosts_template.in
#
# Ouput file:	$0.out ie. query_hosts_template.out
#
# Error file:	$0.err ie. query_hosts_template.err
#
script_name=${0##*/}            # Calling script name - remove path
script_name=${script_name%.*}   # Remove file extension from script name     

input_file=${1:-$script_name.in}  # Specified input file or default name

if ! [[ -e $input_file ]]; then   # Input file exists?
   print "*** Input file doesn't exist: $input_file"
   exit
fi

exec 3< $input_file

while read -u3 the_host ; do

   print "Processing $the_host"
   tmpvar=$(/usr/local/bin/ssh $the_host mkuser -a "id='30783' home='/home/k235615' shell='/bin/ksh' gecos='Laura Caceres' k235615" ) # *** Change Here ****
   if (( $? != 0 )); then
	print "Cannot connect to $the_host" >> $script_name.err
	continue	
   fi

   print "$the_host: $tmpvar" >> $script_name.out  # Write to output file

done 
exec 3<&-				# Close file used for reading
