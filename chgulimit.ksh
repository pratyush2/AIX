id="k122775 l117381 z7074904 u242831 m549402 w950134 o553282"
for i in $id
do
ssh ktazi1504 chsec -f /etc/security/limits -s $i -a fsize=-1 
ssh ktazp1574 chsec -f /etc/security/limits -s $i -a fsize=-1 
ssh ktazi1550 chsec -f /etc/security/limits -s $i -a fsize=-1 
ssh ktazi1556 chsec -f /etc/security/limits -s $i -a fsize=-1 
ssh ktazi1544 chsec -f /etc/security/limits -s $i -a fsize=-1 
ssh ktazi1562 chsec -f /etc/security/limits -s $i -a fsize=-1 
ssh ktazi1568 chsec -f /etc/security/limits -s $i -a fsize=-1 
done
