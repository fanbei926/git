#!/bin/bash
tar zxf /tmp/jdk-8u181-linux-x64.tar.gz -C /tmp/jdk1.8.0_181
mkdir /application
mv /tmp/jdk1.8.0_181/ /application/
ln -sf /application/jdk1.8.0_181/ /application/jdk
ln -sf /application/jdk1.8.0_181/bin/java /usr/bin/java
cat >>/etc/profile<<'EOF'
JAVA_HOME=/application/jdk
PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$JAVA_HOME/lib/tools.jar
EOF
rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat/jenkins-2.99-1.1.noarch.rpm

tar zxf /tmp/plugins.tar.gz
mv /tmp/plugins/* /var/lib/jenkins/plugins/
sed -i.ori 's#JENKINS_USER="jenkins"#JENKINS_USER="root"#g' /etc/sysconfig/jenkins
systemctl start jenkins
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
cat /var/lib/jenkins/secrets/initialAdminPassword
