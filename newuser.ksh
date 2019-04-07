#!/usr/bin/ksh

servername=$1
username="k246789"
username2="k234071"
username3="k233076"
username4="k215110"

echo "\n"
echo "You are adding user $username to $servername..."
echo "You are adding user $username2 to $servername..."
echo "You are adding user $username3 to $servername..."
echo "You are adding user $username4 to $servername..."
echo "\n"
echo "Press Enter to continue...\n"
read keypressed

echo "Check if new user exists on the system ...\n"

checkid=`/usr/local/bin/ssh $servername grep $username /etc/passwd`
checkid2=`/usr/local/bin/ssh $servername grep $username2 /etc/passwd`
checkid3=`/usr/local/bin/ssh $servername grep $username3 /etc/passwd`
checkid3=`/usr/local/bin/ssh $servername grep $username4 /etc/passwd`

if [[ $checkid = "" ]]
then
	newuserparam="id='10221' pgrp='staff' home='/home/k246789' shell='/bin/ksh' gecos='Sonnie Nguyen'"
	echo "Creating new user $username please wait ...\n"
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
	newuserparam2="id='10220' pgrp='staff' home='/home/k234071' shell='/bin/ksh' gecos='Kenneth MacDonald'"
	echo "Creating new user $username2 please wait ...\n"
	ssh $servername mkuser $newuserparam2 $username2
	echo "Creating new user passwd for $username2 ...\n"
	ssh -t $servername passwd $username2
	echo "Completed sucessfully ...\n"
else
	echo "\n"
	echo "User $username2 already exists on server $servername"
fi

if [[ $checkid3 = "" ]]
then
        newuserparam3="id='10337' pgrp='staff' home='/home/k233076' shell='/bin/ksh' gecos='Kevin Lee'"
        echo "Creating new user $username3 please wait ...\n"
        ssh $servername mkuser $newuserparam3 $username3
        echo "Creating new user passwd for $username3 ...\n"
        ssh -t $servername passwd $username3
        echo "Completed sucessfully ...\n"
else
        echo "\n"
        echo "User $username3 already exists on server $servername"
fi

if [[ $checkid3 = "" ]]
then
        newuserparam3="id='10222' pgrp='staff' home='/home/k215110' shell='/bin/ksh' gecos='George Coussa'"
        echo "Creating new user $username4 please wait ...\n"
        ssh $servername mkuser $newuserparam3 $username4
        echo "Creating new user passwd for $username4 ...\n"
        ssh -t $servername passwd $username4
        echo "Completed sucessfully ...\n"
else
        echo "\n"
        echo "User $username4 already exists on server $servername"
fi

echo "\nGood bye!!!"
echo "\n$servername"
