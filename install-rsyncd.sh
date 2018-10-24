#!/bin/bash
echo '------------------Auto Config Start------------------'
echo '------------------Change Hostname'
#更改hostname
if [ ! $1 ] || [ ! $2 ]
then
	echo '-----------------------Use default items'
	name='default'
	ip='100'
else
	echo "-----------------------Hostname:$1 IP:$2"
	name=$1
	ip=$2
fi
hostname $name
sed -i "s#localhost.localdomain#$name#g" /etc/sysconfig/network
echo '------------------Change IP'
#更改系统IP
sed -i "s#200#$ip#g" /etc/sysconfig/network-scripts/ifcfg-{eth0,eth1}
echo '------------------Create Rsync User'
#创建用户
user=`cat /etc/passwd | grep rsync | wc -l`
if [ $user -eq 0 ]
then
	useradd -s /sbin/nologin -M rsync
else
	echo '-----------------------User exits'
fi
if [ -d /backup ]
then
	echo '-----------------------/backup exits'
else
	mkdir -p /backup
fi
chown -R rsync:rsync /backup
echo '------------------Create rsyncd.conf'
#创建rsyncd.conf
cat >/etc/rsyncd.conf<<'EOF'
uid = rsync
gid = rsync
use chroot = no
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock
log file = /var/log/rsyncd.log
read only = false
list = false
timeout = 300
max connections = 20
auth users = rsyncd_backup
secrets file = /etc/rsync.password
hosts allow = 172.16.1.0/24
#hosts deny = 
[backup]
comment = backup for test
path = /backup
EOF
echo '------------------Create rsync.password'
#创建rsync.password文件
echo "rsyncd_backup:oldboy123" > /etc/rsync.password
chmod 600 /etc/rsync.password
echo '------------------Start rsyncd daemon'
#开始rsync daemon模式
ps=`ps -ef | egrep -c "\brsync --daemon\b"`
if [ $ps -gt 0 ]
then
	echo '-----------------------rsync --daemon exits. Restart....'
	echo `ps -ef | egrep "\brsync --daemon\b"`
	kill `ps -ef | egrep "\brsync --daemon\b" | awk '{print $2}'`
fi
sleep 5
rsync --daemon
