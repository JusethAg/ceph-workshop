#!/bin/bash
value=$( grep -ic "entry" /etc/hosts )
if [ $value -eq 0 ]; then
	echo "
	################ ceph-cookbook host entry ############
	192.168.100.101 ceph-node1
	192.168.100.102 ceph-node2
	192.168.100.103 ceph-node3
	######################################################
	" | sed -e 's/^[ \t]*//' >> /etc/hosts
	# reference https://www.cyberciti.biz/tips/delete-leading-spaces-from-front-of-each-word.html
fi

if [ -e /etc/redhat-release ]; then

	# Disable YUM fastestmirror plugin
	sed -i 's/.*enabled=.*/enabled=0/g' /etc/yum/pluginconf.d/fastestmirror.conf
	# Using baseurl instead of a mirrorlist
	sed -e 's/^mirrorlist=/#mirrorlist=/' \
    	-e 's/#baseurl=/baseurl=/' \
    	-i /etc/yum.repos.d/CentOS-Base.repo
	# References
	# https://serverascode.com/2014/03/29/squid-cache-yum.html
	# https://unix.stackexchange.com/questions/398609/how-do-i-stick-with-one-version-on-centos-7-via-yum-update

	# Enable SSH Password Authetication
	sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
	systemctl restart sshd

	# Firewall rules
	systemctl restart firewalld
	systemctl enable firewalld
	firewall-cmd --zone=public --add-port=6789/tcp --permanent
	firewall-cmd --zone=public --add-port=6800-7100/tcp --permanent
	firewall-cmd --reload

	# Configuring NTP
	yum install ntp ntpdate -y
	ntpdate pool.ntp.org
	systemctl restart ntpdate.service
	systemctl restart ntpd.service
	systemctl enable ntpdate.service
	systemctl enable ntpd.service

	# Installing dependencies
	yum install git python3 -y
	python3 -m pip install --upgrade pip
	# ansible 2.8 is required (2.8.0 has a bug, using latest 2.8.7)
	# it's installed with pip since yum provides 2.6 and epel-release provides 2.9
	python3 -m pip install ansible==2.8.7
	python3 -m pip install netaddr

	#if [ -e /etc/rc.d/init.d/ceph ]; then
	#	service ceph restart mon > /dev/null 2> /dev/null
	#fi

fi
