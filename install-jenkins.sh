#!/bin/bash
java_version="jdk-8u191"
jenkins_version="jenkins-2.99-1.1"
file="${java_version}-linux-x64.tar.gz"
java_path="jdk1.8.0_191"
path="/application"

read -p "You must use 'source' to execute this file." $1
echo "Start install ..."

[ -f /tmp/$file ] && {
	echo "tar OK ..."
	tar xf /tmp/$file -C /tmp/
} || {
	echo "The $file does not exit."
	sleep 1
	exit 1
}
[ -d $path ] && {
	echo "The $path has exit."
} || {
	echo "Create this $path"
	mkdir /application
}

echo "Install ${java_version}"
mv /tmp/${java_path}/ $path
ln -s /application/${java_path}/ $path/jdk
ln -s /${path}/jdk/bin/java /usr/bin/java
cat >>/etc/profile<<'EOF'
JAVA_HOME=/application/jdk
PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$JAVA_HOME/lib/tools.jar
EOF
source /etc/profile


echo "Now download jenkins ...."
rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat/${jenkins_version}.noarch.rpm
if [ $? -ne 0 ]
then
	echo "Download jenkins has error.Exit..."
	sleep 1
	exit 2
fi

echo "Configure the jenkins ..."
sed -i.ori 's#JENKINS_USER="jenkins"#JENKINS_USER="root"#g' /etc/sysconfig/jenkins


echo "Install plugins ..."
[ -f /tmp/plugins.tar.gz ] && {
	tar zxf /tmp/plugins.tar.gz -C /tmp/
	mv /tmp/plugins/* /var/lib/jenkins/plugins/
} || {
	echo "The plugins does not exit."
	sleep 1
#	exit 1
}

echo "Start jenkins ..."
systemctl start jenkins

echo "Gen ssh public key ..."
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
cat /var/lib/jenkins/secrets/initialAdminPassword
