#!/bin/bash
#fun:		Change the repo and instal git
#auth:		Jerry
#date:		2018.10.21
#version:	1.0
#aliyun源
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
#epel源
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
#安装git
yum install -y git
#
mkdir -p /server/scripts
#
mkdir /git
#创建密钥对
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
