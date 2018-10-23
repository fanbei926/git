#!/bin/bash
yum install -y sshpass
sshpass -p123456 ssh-copy-id -i /root/.ssh/id_rsa.pub root@10.0.0.106 "-o StrictHostKeyChecking=no"

cd /var/lib/jenkins/workspace/html-test/
tar zcf /opt/x.tar.gz ./*
ssh root@10.0.0.106 "mkdir -p /usr/share/nginx/test"
scp /opt/x.tar.gz root@10.0.0.106:/usr/share/nginx/test
ssh root@10.0.0.106 "cd /usr/share/nginx/test && tar zxf x.tar.gz && rm -fr x.tar.gz && ln -sf /usr/share/nginx/test/ /usr/share/nginx/html"
