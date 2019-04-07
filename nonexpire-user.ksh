#!/bin/ksh
# Script Name:                  /usr/local/scripts/nonexpire-user.ksh
# Author:                       Russell Teeter 
# Creation Date:                10/14/2003
# Functional Description:       This script will set a user to not expire.
# Usage:                        nonexpire-user.ksh
#
#
# Modification History:
#
# Initials      Date    	Modification Description
# --------    --------  ---------------------------------------------------
# RST         10/14/03  Created Script
#
#
############################################################################### 


	echo "Please enter your name of user that should not expire:"
	read user
	/usr/bin/chuser pwdwarntime=0 loginretries=0 histexpire=0 histsize=0 minage=0 maxage=0 maxexpired=-1 minalpha=0 minother=0 maxrepeats=8 mindiff=0 $user
	echo "$user is set to no longer expire."
