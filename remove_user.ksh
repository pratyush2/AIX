#!/bin/ksh
unixtype=`uname`
#		        Scott Bennet K244139
#			Barbara Magallon k137315
#			Vachi Kontian 626-564-7538' k155021
#			Calvin Anton 626-564-7422'  D150000
#			Frank Schiavo, ETS OSS' K242652
#			Jazz Arhi 626-405-7542' k142802
#			Scott Bennet 626-564-5478' K244139
#			Jerry Thomas 626-564-7042' k241437
#			John Stone 626-564-5676' k146805
#			Robert Stratiff 626-564-7539' k203887
#			Robert Hsu 626-564-7664' k215851
#			Stan Ellington, Storage Management' k232156
#			Greg Oldham, Storage Management' k211668    
#			Chester Stockton, Storage Management' k236827
#			Julie Harlow 301-680-1727' d111564
#			Mai Pham k245755
#			Babu Rahman k243694
#			Philli[p Lee k200165
#			Greg Stanley k243414
#			Mai Pham mppham
#			Sikandar Mohamed smohamed
#			Sandra Birgerson sbirgers
#			Steve Gilley k407506
#			David Lew k249359
#			Sikandar Mohamed g828231
#			Mai Pham mpham
#			David Lew p369641
#			Patrick Colony f411772
#			Steve Gilley K206219
#			Andy Garcia k329717
#			Don Abell k208727
#			babu	babu
#			coursvc courier
#			babu brahman
#			Don Abell dabell
#			Phillip Lee plee
#			storman2			
#			Chip Gauther k088700
#			Kate Ho k155027
#			Loubna Noir  ,D770085
#			Dragana Cvetkovic  ,D335359
#			David Adamchik  ,t349564
#			Brian Blakeley  ,y407474
#			Gary Vannest   ,t634245
#			Ho Nguyen, c588170
#userid="k245755 k245755 k243694 k200165 k243414 mppham smohamed sbirgers k407506 k249359 g828231 mpham p369641 f411772 K206219 k329717 k208727 K244139 k137315 k155021 D150000 K242652 k142802 K244139 k241437 k146805  k203887 k215851 k232156 k236827 d111564 babu coursvc brahman dabell plee storman2 k088700 k155027 D770085 t349564 y407474 t634245"
userid="c588170"
for id in $userid 
do
if [ $unixtype = "AIX" ]
then                    
	/usr/bin/rm -R /home/$id
	/usr/sbin/rmuser -p $id
elif [ $unixtype = "SunOS" ]
then
	/usr/sbin/userdel -r $id
	/usr/sbin/userdel $id
elif [ $unixtype = "Linux" ]
then
	/usr/sbin/userdel -r $id
	/usr/sbin/userdel $id
fi
done
exit 0
