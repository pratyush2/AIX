#!/bin/ksh 

oslevel=oslevel -r
lslpp -l bos.alt_disk_install.rte
if [ $? = 0 ]
then
   echo "alt_disk_install fileset already installed"
   exit 1 
else
	echo "Mount ktazd216:/aix "
	/usr/sbin/mount -o ro,bg,soft,proto=tcp,retry=100 ktazd216:/aix /mnt 
	echo "Installing bos.alt_disk_install"                                  
	level=`oslevel -r |cut  -c1-2`
	maint=`oslevel -r |cut  -c6-7`
	aix=aix
	end=0_image
	middle=0_ML
	result=$aix$level$end
	result3=$aix$level$middle$maint
	echo "Installing bos.alt_disk_install from $result"
	/usr/sbin/installp -ac -d /mnt/$result bos.alt_disk_install -p -X   
	echo "Appling and maintenance of bos_alt_disk_install from $result3"
	/usr/sbin/installp -ac -d /mnt/$result3 bos.alt_disk_install -p -X
	echo "Unmounting ktazd216"                                             
	/usr/sbin/umount /mnt                                                 
fi
