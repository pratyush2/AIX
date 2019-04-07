#!/usr/bin/ksh

servername=$1
username="k246789"
username2="k234071"

echo "\n"
echo "You are adding user $username to $servername..."
echo "You are adding user $username2 to $servername..."
echo "\n"
echo "Press Enter to continue...\n"
read keypressed

echo "Check if new user exists on the system ...\n"

checkid=`/usr/local/bin/ssh $servername grep $username /etc/passwd`
checkid2=`/usr/local/bin/ssh $servername grep $username2 /etc/passwd`

if [[ $checkid = "" ]]
then
	newuserparam="id='10221' pgrp='staff' home='/home/k246789' shell='/bin/ksh' gecos='Sonnie Nguyen'"
	echo "Creating new user $username please wait ...\n"
	#ssh $servername mkuser id='10219' pgrp='staff' home='/home/k246789' shell='/bin/ksh' $username
	ssh $servername mkuser $newuserparam $username
	echo "Creating new user passwd for $username ...\n"
	ssh -t $servername passwd $username
	echo "Completed sucessfully ...\n"

else
	echo "\n"
	echo "User $username already exists on server $servername"
fi

if [[ $checkid2 = "" ]]
then
	newuserparam2="id='10223' pgrp='staff' home='/home/k234071' shell='/bin/ksh' gecos='Kenneth MacDonald'"
	echo "Creating new user $username2 please wait ...\n"
	#ssh $servername mkuser id='10221' pgrp='staff' home='/home/k234071' shell='/bin/ksh' $username2
	ssh $servername mkuser $newuserparam2 $username2
	echo "Creating new user passwd for $username2 ...\n"
	ssh -t $servername passwd $username2
	echo "Completed sucessfully ...\n"
else
	echo "\n"
	echo "User $username2 already exists on server $servername"
fi

echo "\nGood bye!!!"
echo "\n"
