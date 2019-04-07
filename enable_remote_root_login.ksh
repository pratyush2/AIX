#!/bin/ksh
if [ -f /etc/rc.openssh ]; then
	if [ -f /etc/openssh/sshd_config.save ]; then
		cp /etc/openssh/sshd_config.save /etc/openssh/sshd_config
		/etc/rc.openssh stop
		ps -ef >/tmp/ps.out1
	 	ps -ef|grep sshd|grep -v grep|awk '{print $2}'|xargs kill
		ps -ef >/tmp/ps.out2
		/etc/rc.openssh start
		/usr/bin/chuser rlogin=true root
	fi
else
	if [ -f /etc/sshd_config.save ]; then
		cp /etc/sshd_config.save /etc/sshd_config
		cp /etc/ssh/sshd_config.save /etc/ssh/sshd_config
		stopsrc -s sshd
		startsrc -s sshd
		/usr/bin/chuser rlogin=true root
	fi
fi
