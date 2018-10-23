#!/bin/bash
name=$1
ip=$2
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
hostnamectl set-hostname $name
sed -i "s#103#$2#g" /etc/sysconfig/network-scripts/ifcfg-{eth0,th1}
systemctl restart network
