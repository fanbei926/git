#!/bin/bash
ip=`hostname -I | awk '{print $1}'`
#安装JDK
tar zxf /tmp/jdk-8u191-linux-x64.tar.gz -C /tmp/
mkdir /application
mv /tmp/jdk1.8.0_191/ /application/
ln -sf /application/jdk1.8.0_191/ /application/jdk
ln -sf /application/jdk1.8.0_191/bin/java /usr/bin/java
cat >>/etc/profile<<'EOF'
JAVA_HOME=/application/jdk
PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$JAVA_HOME/lib/tools.jar
EOF

#安装Tomcat
#cd /tmp/;wget http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.5.34/bin/apache-tomcat-8.5.34.tar.gz
cd /tmp/;tar zxf /tmp/apache-tomcat-8.5.34.tar.gz -C /application/
ln -sf /application/apache-tomcat-8.5.34/ /application/tomcat
mv /tmp/zrlog.war /application/tomcat/webapps/
/application/tomcat/bin/startup.sh

# #安装mysql
# #wget https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz
# tar zxf /tmp/mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz -C /tmp/
# mv /tmp/mysql-5.6.42-linux-glibc2.12-x86_64 /application/mysql-5.6.42
# ln -sf /application/mysql-5.6.42/ /application/mysql
# #创建mysql用户
# useradd -M -s /sbin/nologin mysql
# chown -R mysql:mysql /application/mysql/data/
# #初始化mysql
# /application/mysql/scripts/mysql_install_db --user=mysql --group=mysql --datadir=/application/mysql/data/ --basedir=/application/mysql
# cp /application/mysql/support-files/mysql.server /etc/init.d/mysqld
# \cp /application/mysql/my.cnf /etc/my.cnf
# sed -i.ori 's#/usr/local#/application#g' /application/mysql/bin/mysqld_safe /etc/init.d/mysqld
# ln -sf /application/mysql/bin/* /usr/sbin/
# #新建数据库
# /etc/init.d/mysqld start
# mysqladmin -uroot password 'oldboy123'
# mysql -uroot -poldboy123 -e "create database zrlog;"
# mysql -uroot -poldboy123 -e "grant all privileges on zrlog.* to 'zrlog'@'localhost' identified by 'zrlog'"

yum install -y rpcbind nfs-utils