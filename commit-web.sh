#!/bin/bash
project_name='html-test'
filename=`date +%F`_`echo $RANDOM | md5sum | cut -c 1-5`
host=10.0.0.16

yum install -y sshpass
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
sshpass -p123456 ssh-copy-id -i /root/.ssh/id_rsa.pub root@${host} "-o StrictHostKeyChecking=no"

cd /var/lib/jenkins/workspace/${project_name}/
tar zcf /opt/${filename}.tar.gz ./*
ssh root@${host} "mkdir -p /usr/share/nginx/${filename}"
scp /opt/${filename}.tar.gz root@${host}:/usr/share/nginx/${filename}
ssh root@${host} "cd /usr/share/nginx/${filename} && tar zxf x.tar.gz && rm -fr x.tar.gz && ln -sf /usr/share/nginx/${filename}/ /usr/share/nginx/html"
