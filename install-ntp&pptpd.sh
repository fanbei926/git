#!/bin/bash
yum install -y pptpd ppp
sed '$a localip 10.0.0.108 \
remoteip 172.16.1.200-220' /etc/pptpd.conf
echo "oldboy          *       123456                  *" >> /etc/ppp/chap-secrets

yum install -y ntp
systemctl stop chronyd.service
systemctl disable chronyd.service
sed -i 's#restrict 127.0.0.1#restrict 172.16.1.0/24 10.0.0.0/24g' /etc/ntp.conf
sed -i '21,24d' /etc/ntp.conf
sed -i '21i server ntp1.aliyun.com iburst \
server ntp2.aliyun.com iburst \
server ntp3.aliyun.com iburst \
server ntp4.aliyun.com iburst' /etc/ntp.conf