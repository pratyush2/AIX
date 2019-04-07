#!/bin/ksh
unixtype=`uname`
ossids="U936470 k236552 Q248385 z091552 d111579 d111498 d111536 d111718 c002170 m765211 D845358 k228840 k215110 d111527 z700603 u518785 k235615 k233076 k246789 D102145 k234071 z105919 e353860 s861768 d111638 d242652 z700464 k245755 k228556 D110801 L719803 T416866 Z615826 A177083 o210487 t567289 u367488 u528750 a177083 h029023 q789878 q351266 w823518 Q717265 Q183487 F596352 L221594 f954912 k226615 a508868 d613569"
for id in $ossids
do
if [ $unixtype = "AIX" ]
then
	lsuser $id >/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
		/usr/bin/mkuser  pgrp=staff groups=staff home=/home/$id shell=/bin/ksh gecos='OSS userid' pwdwarntime=0 loginretries=0 histexpire=0 histsize=0 minage=0 maxage=0 maxexpired=-1 minalpha=0 minother=0 maxrepeats=8 mindiff=0 rlogin=true $id
		/usr/local/bin/setpwd.aix -c -u $id  -p kaiser
		echo "user added $id"
	else
		echo "User exist $id"
	fi
elif [ $unixtype = "SunOS" ]
then
	/usr/bin/listusers -l $id >/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
		/usr/sbin/useradd -m -d /export/home/$id  -c "OSS userid" -s /bin/ksh $id
       		/usr/local/bin/setpwd.sol $id kaiser
		echo "user added $id"
	else
		echo "User exist $id"
	fi
elif [ $unixtype = "Linux" ]
then
	grep $id /etc/passwd >/dev/null 2>/dev/null
	if [ $? -ne 0 ];then
        	/usr/sbin/useradd -d /home/$id -s /bin/ksh -c "OSS userid" $id
		/usr/local/bin/setpwd.lin $id kaiser
		echo "user added $id"
	else
		echo "User exist $id"
	fi
fi
done
if [ $unixtype = "AIX" ]
then                    
	lsuser storman1 >/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then            
		/usr/bin/mkgroup -'A' storman
		/usr/bin/mkuser  pgrp=storman groups=staff home=/home/storman1 shell=/bin/ksh gecos='Storage Management user account' pwdwarntime=0 loginretries=  histexpire=0 histsize=0 minage=0 maxage=0 maxexpired=-1 minalpha=0 minother=0 maxrepeats=8 mindiff=0 rlogin=true storman1 
		echo "User storman1 added"
	else
		echo "User storman1 exist"
	fi
	lsuser ossadmin >/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
		/usr/bin/mkuser  pgrp='staff' groups='staff' home='/home/ossadmin' shell='/bin/ksh' gecos='ossadmin userid' ossadmin
		/usr/local/bin/setpwd.aix -c -u ossadmin -p Ets0ss
		/usr/local/bin/setpwd.aix -c -u storman1 -p si00kp             
		mkdir /home/ossadmin/.ssh >/dev/null 2>&1            
		chown ossadmin /home/ossadmin/.ssh >/dev/null 2>&1   
		chmod 700 /home/ossadmin/.ssh >/dev/null 2>&1        
		echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAz7soxqIK0FAq2bCebHN1XLr4ACU+JKqIusVcQbldHZUSGk0aGb2ritxAlT1EiaPZXcWku8soPmrVHs2AXEdh1PRNiP0C63XkPszCxRPN4hk/CjYFrewHbYMkVrSPwtfWffnq5nyqzHsLbswPZspTXtiHhI5N9/zZ0ifSZNxTSl8= ossadmin@ktazd216" >/home/ossadmin/.ssh/authorized_keys
		echo "StrictHostKeyChecking no" >/home/ossadmin/.ssh/config
		chown ossadmin /home/ossadmin/.ssh/*     
		chmod 644 /home/ossadmin/.ssh/*          
		cp /etc/sudoers /etc/sudoers.ossadmin
		grep "User_Alias OSS=" /etc/sudoers >/dev/null 2>&1
		if [ $? = 0 ]
		then
			echo "Seem to already have sudo entries for ossadmin"
		else
			echo "User_Alias OSS=ossadmin" >>/etc/sudoers
			echo "Cmnd_Alias OSS=/tmp/ossadmin.script, /tmp/ossadmin.cmd" >>/etc/sudoers
			echo "OSS        ROBMSTR=NOPASSWD:OSS, !SU, !SHELLS, !SSH, !REST" >>/etc/sudoers
		fi
		echo "User ossadmin added"
	else	 
		echo "User ossadmin exists"
	fi
	lsuser secadmin >/dev/null 2>/dev/null 
	if [ $? -ne 0 ]; then                  
		/usr/bin/mkuser  admin=true pgrp='security' groups='security' admgroups='security' su='false' home='/home/secadmin' pwdwarntime='0' loginretries='0' histexpire='0' histsize='0' minage='0' maxage='0' maxexpired='-1' minalpha='0' minother='0' maxrepeats='8' mindiff='0'    shell='/bin/ksh' gecos='Security Administration' roles='ManageAllUsers,ManageBasicPasswds,ManageAllPasswds,ManageRoles' secadmin
		/usr/local/bin/setpwd.aix -c  -u secadmin -p SecAdmin
		mkdir /home/secadmin/.ssh >/dev/null 2>&1            
		chown secadmin /home/secadmin/.ssh >/dev/null 2>&1   
		chmod 700 /home/secadmin/.ssh >/dev/null 2>&1        
		echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAubrW0hXdrwRMBmim5COcN2uGky07FFt9M0CPOy3YWdnwf8v/U9QWs9cE8Xcz/1EhPUbc+xitlNC2zrDJFUPox51IO8Wr/nDDnGHM4m6teE70b5qEUG7sqXEn1PP2px6w1pw3xfx9A/GlumfLd2t4j1YAjejXpcHsBJJvZXN+0Mc= secadmin@ktazp1423" >/home/secadmin/.ssh/authorized_keys
		echo "StrictHostKeyChecking no" >/home/secadmin/.ssh/config
		chgrp security /usr/local/bin/setpwd.aix                        
		chmod 4754 /usr/local/bin/setpwd.aix                            
		echo "User secadmin added"
	else
		echo "User secadmin exist"
	fi
elif [ $unixtype = "SunOS" ]                                                    
then                                                                            
	/usr/bin/listusers -l storman1 >/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
		/usr/sbin/groupadd storman
        	/usr/sbin/useradd   -m -k '/etc/skel' -G 'storman'  -d '/export/home/storman1' -s '/bin/ksh' -c 'Storage Management userid' storman1
        	/usr/local/bin/setpwd.sol -u storman1 -p si00kp
		echo "User storman1 added"
	else
		echo "User storman1 exist"
	fi
elif [ $unixtype = "Linux" ]                                                    
then                                                                            
	grep storman1 /etc/passwd >/dev/null 2>/dev/null 
	if [ $? -ne 0 ];then                        
		/usr/sbin/groupadd storman
        	/usr/sbin/useradd   -m -k '/etc/skel' -G 'storman' -d '/home/storman1' -s '/bin/ksh' -c 'Storage Management userid' storman1 
        	/usr/local/bin/setpwd.lin -u storman1 -p si00kp
		echo "User storman1 added"
	else
		echo "User storman1 exist"
	fi
	grep ossadmin /etc/passwd >/dev/null 2>/dev/null
	if [ $? -ne 0 ];then                            
		/usr/sbin/useradd -m -d /export/home/ossadmin -c "OSS Administration" -s /bin/ksh  ossadmin
		/usr/local/bin/setpwd.sol ossadmin  Ets0ss                
		mkdir /export/home/ossadmin/.ssh >/dev/null 2>&1          
		mkdir /export/home/ossadmin/.ssh2 >/dev/null 2>&1         
		chown ossadmin /export/home/ossadmin/.ssh >/dev/null 2>&1 
		mkdir /export/home/ossadmin/.ssh2 >/dev/null 2>&1         
		chown ossadmin /export/home/ossadmin/.ssh2 >/dev/null 2>&1
		chmod 700 /export/home/ossadmin/.ssh >/dev/null 2>&1      
		chmod 700 /export/home/ossadmin/.ssh2 >/dev/null 2>&1     
		echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAz7soxqIK0FAq2bCebHN1XLr4ACU+JKqIusVcQbldHZUSGk0aGb2ritxAlT1EiaPZXcWku8soPmrVHs2AXEdh1PRNiP0C63XkPszCxRPN4hk/CjYFrewHbYMkVrSPwtfWffnq5nyqzHsLbswPZspTXtiHhI5N9/zZ0ifSZNxTSl8= ossadmin@ktazd216" >/export/home/ossadmin/.ssh/authorized_keys
		chown ossadmin /export/home/ossadmin/.ssh/authorized_keys >/dev/null 2>&1
		chmod 700 /export/home/ossadmin/.ssh/authorized_keys  >/dev/null 2>&1
		echo "StrictHostKeyChecking no" >/export/home/ossadmin/.ssh/config
		chown ossadmin /export/home/ossadmin/.ssh/config >/dev/null 2>&1
		chmod 700 /export/home/ossadmin/.ssh/config >/dev/null 2>&1
        	cp /tmp/COMDSAKEY /export/home/ossadmin/.ssh2/COMDSAKEY
        	echo "Key COMDSAKEY" >/export/home/ossadmin/.ssh2/authorization
        	mkdir /export/home/ossadmin/.ssh2
        	chown ossadmin /export/home/ossadmin/.ssh2
        	chmod 700 /export/home/ossadmin/.ssh2
        	chown ossadmin /export/home/ossadmin/.ssh2/COMDSAKEY
        	chown ossadmin /export/home/ossadmin/.ssh2/authorization
        	cp /etc/sudoers /etc/sudoers.ossadmin
		grep "User_Alias OSS=" /etc/sudoers >/dev/null 2>&1
		if [ $? = 0  
		then 
			echo "Seem to already have sudo entries for ossadmin"
		else
        		echo "User_Alias OSS=ossadmin" >>/etc/sudoers                           
        		echo "Cmnd_Alias OSS=/tmp/ossadmin.script, /tmp/ossadmin.cmd" >>/etc/sudoers
        		echo "OSS        ROBMSTR=NOPASSWD:OSS, !SU, !SHELLS, !SSH, !REST" >>/etc/sudoers
		fi
		echo "User ossadmin added"
	else
		echo "User ossadmin exist"
	fi
fi

storids="k252581 k233254 K252549 k134742 k241434 p132830 w342245 d101593 I920571 i600299 k013364 h139325 I772425 Q891615 B731322 U457538 W440113 Y150598 B446037 P536513 S646935"
for id in $storids                                                              
do                                                                              
if [ $unixtype = "AIX" ]                                                        
then                                                                            
	lsuser $id >/dev/null 2>/dev/null 
	if [ $? -ne 0 ]; then             
        	/usr/bin/mkuser  pgrp=staff groups=staff home=/home/$id shell=/bin/ksh gecos='Storage Management ' pwdwarntime=0 loginretries=0 histexpire=0 histsize=0 minage=0 maxage=0 maxexpired=-1 minalpha=0 minother=0 maxrepeats=8 mindiff=0 rlogin=true $id 
        	/usr/local/bin/setpwd.aix -u $id -p kaiser
		echo "User $id added"
	else
		echo "User $id exist"
	fi
elif [ $unixtype = "SunOS" ]                                                    
then                                                                            
	/usr/bin/listusers -l $id >/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
        	/usr/sbin/useradd   -m -k '/etc/skel' -d '/export/home/$id' -s '/bin/ksh' -c 'Storage Management userid' $id 
        	/usr/local/bin/setpwd.sol -u $id -p kaiser
		echo "User $id added"
	else
		echo "User $id exist"
	fi
elif [ $unixtype = "Linux" ]                                                    
then                                                                            
	grep storman1 /etc/passwd >/dev/null 2>/dev/null  
	if [ $? -ne 0 ];then                              
        	/usr/sbin/useradd   -m -k '/etc/skel' -d '/home/$id' -s  '/bin/ksh' -c 'Storage Management userid' $id
        	/usr/local/bin/setpwd.lin -u $id -p kaiser
		echo "User $id added"
	else
		echo "User $id exist"
	fi
fi
done
perfids="d111725 k241270 k238994 k224131"                             
for id in $perfids                                                            
do                                                                            
if [ $unixtype = "AIX" ]                                                      
then                                                                          
	lsuser $id >/dev/null 2>/dev/null 
	if [ $? -ne 0 ]; then             
        	/usr/bin/mkuser  pgrp=staff groups=staff home=/home/$id shell=/bin/ksh gecos='Performance Management ' pwdwarntime=0 loginretries=0 histexpire=0 histsize=0 minage=0 maxage=0 maxexpired=-1 minalpha=0 minother=0 maxrepeats=8 mindiff=0 rlogin=true $id
        	/usr/local/bin/setpwd.aix -u $id -p kaiser
		echo "User $id added"
	else
		echo "User $id exist"
	fi
elif [ $unixtype = "SunOS" ]                                                  
then                                                                          
	/usr/bin/listusers -l $id >/dev/null 2>/dev/null 
	if [ $? -ne 0 ]; then                            
        	/usr/sbin/useradd   -m -k '/etc/skel' -d '/export/home/$id' -s '/bin/ksh' -c 'Storage Management userid' $id
        	/usr/local/bin/setpwd.sol -u $id -p kaiser
		echo "User $id added"
	else
		echo "User $id exist"
	fi
elif [ $unixtype = "Linux" ]                                                  
then                                                                          
	grep $id /etc/passwd >/dev/null 2>/dev/null 
	if [ $? -ne 0 ];then                             
        	/usr/sbin/useradd   -m -k '/etc/skel' -d '/home/$id' -s '/bin/kin' -c 'Storage Management userid' $id 
        	/usr/local/bin/setpwd.lin -u $id -p kaiser
		echo "user $id added"
	else
		echo "User $id exist"
	fi
fi                                                                            
done                                                                          
# The following are a list of users being defined
# 'Jonthan Kim OSS' A177083                     
# 'Joe DeFulgentiis, ETS OSS' L719803           
# 'Joanne Tom, ETS OSS' D110801                 
# 'Ryan Dang, ETS OSS' T416866                  
# 'Robert Gonzalez, ETS OSS' Z61582             
# 'Ed Lillie 909-739-6561' U936470              
# 'Joey Menefee 909-270-2501' k236552           
# 'Gordon Chan 808-432-8178' Q248385            
# 'Pat Huber 301-680-1609' d111579              
# 'Steve Briggs 301-680-1725' d111498           
# 'Ray Engle 301-680-1606' d111536              
# 'Daniel Temoche 301-680-1746' d111718         
# 'Ray Suehrstedt 303-344-7502' c002170         
# 'Judy Smith 626-564-5163' m765211             
# 'Don Abell 626-564-7977' D845358              
# 'Saul Ramos 626-564-7769' k228840           
# 'George Coussa 626-564-7396' k215110        
# 'Rich Dobrzanski 301-680-1699' d111527      
# 'Ken Spurgat 925-926-3403' z700603          
# 'Alaa Elbeheiry 301-680-1719' u518785       
# 'Laura Caceres 909-270-1883' k235615        
# 'Kevin Lee 626-564-7643' k233076            
# 'Sonnie Nguyen 626-564-3401' k246789        
# 'Fernando Lamarca 808-432-8179' D102145     
# 'Ken MacDonald 626-564-3819' k234071        
# 'Reginald Brown 909-739-6582' z105919       
# 'Sanjeev Srivasta 951 739-6537' u528750
# 'Dung Huynh 626-564-3124' e353860           
# 'Steve Jones 301-680-1434' s861768          
# 'Jerome Milligan 301-680-1806' d111638      
# 'Robert Hsu 626-564-7664' k21585            
# 'Warren McCausland 925-926-3532' z700464        
# 'Hal Chang 626-564-7548' k228556                
# 'Lily Boterenbrood OSS' T000690                 
# 'Gary Tolman OSS' z091552                       
# 'Barbara.K.Galligan OES 951-544-6147' o210487   
# 'Camillo.M.Alcantara OES' t567289               
# 'John.B.Allgire OES 253-709-7960' s137269       
# 'Louis.Sandoval Storage' u367488                
# 'Camillo.M.Alcantara OES' t567289               
# 'John.B.Allgire OES 253-709-7960' s137269       
# 'Brian Ikeda, Storage Management' k252581       
# 'Margurite King, Storage Management' k233254    
# 'XXXXXXXXXXXXX' K252549                         
# 'Kenneth Grant, Storage Management k134742      
# 'Leon Lagmay, Storage Management' k241434       
# 'Andre Humphrey, Storage Management' p132830    
# 'Brian Bickett, Storage Management' w342245                      
# 'Alberta Ho, Storage Management' d101593                         
# 'Italo Michelass, Storage Management' I920571                     
# 'Fred Rosalino, Storage Management' i600299                      
# 'John Negrete, Storage Management' k013364                      
# 'Edmund Chan, Storage Managemen' h139325                         
# 'Joe Dawes, Storage Management' I772425                          
# 'Michael Belostotski, Storage Management' Q891615                
# 'XXXXXXXXXXXXX Storage Management' B731322                       
# 'XXXXXXXXXXXXX Storage Management' U457538                       
# 'XXXXXXXXXXXXX Storage Management' W440113                       
# 'XXXXXXXXXXXXX Storage Management' Y150598                       
# 'Barry Vigraham Storage Management' B446037                      
# 'XXXXXXXXXXXXX Storage Management' P536513                       
# 'XXXXXXXXXXXXX Storage Management' S646935                       
# 'Trinh Chung 8-338-7237 Performance Group' d111725               
# 'Gil Oh Performance Group' k241270                               
# 'Ron Tan Performance Group' k238994                              
# 'Sung Kang Performance Group' k224131
# 'Jonathan.Y.Kim 951-270-1847' a177083
# 'James Scheuer OSS 951-549-7004' h029023
# 'Sara McBride NOPS ETS OSS QAPM UNIX' q789878
# 'Pratap Kumar Guduru 1' w823518
# 'Thanh Q Truong 10' q351266
# 'Surya Singopranoto' Q717265
# 'Michael Cardoza' Q183487
# 'Imran Adhami' F596532
# 'Dave Byron' L221594
# 'Donavon Lerman' k226615
# 'Rich Weingarten' a508868
# 'Koroush "Corey" Bakhshpour' f954912
# 'Randy Harvey' d613569
