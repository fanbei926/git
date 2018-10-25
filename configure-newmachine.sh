#!/bin/bash
echo "---------------------Auto Config Start---------------------"

echo "------------Disable iptables & SELINUX------------"
/etc/init.d/iptables stop
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
echo "------------Configure Yum repos------------"
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
yum clean all
yum makecache

echo "------------Configure chkconfig------------"
chkconfig | egrep -v "sshd|crond|network|rsyslog|sysstat" | awk '{print "chkconfig",$1,"--level 234 off"}' | bash

echo "------------Add oldboy user------------"
user=`grep -c 'oldboy' /etc/passwd`
if [ $user -eq 0 ]
then
	useradd -m -s /bin/bash oldboy
	echo "oldboy  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
else
	echo "------User exits------"
fi

echo "------------Configure system time & update it------------"
echo "Update system time by Jerry at 2018-10-25" >> /var/spool/cron/root
echo "*/5 * * * * /usr/sbin/ntpdate ntp1.aliyun.com > /dev/null 2>&1" >> /var/spool/cron/root
echo "TZ='Asia/Shanghai'; export TZ" >> /etc/profile
source /etc/profile
sed -i.ori 's#ZONE="America/New_York"#ZONE="Asia/Shanghai"#g' /etc/sysconfig/clock
rm -fr /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "------------Configure /etc/security/limits.conf------------"
echo '*               -       nofile          65535' >> /etc/security/limits.conf

echo "------------Configure /etc/sysctl.conf------------"
cat >>/etc/sysctl.conf<<EOF
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.ip_local_port_range = 4000    65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384
#以下参数是对iptables防火墙的优化，防火墙不开会提示，可以忽略不理。
net.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_tcp_timeout_established = 180
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
EOF
sysctl -p

echo "------------Configure /etc/ssh/sshd_config------------"
sed -i.ori 's/#UseDNS yes/UseDNS no/g;s/^GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
