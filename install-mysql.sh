#!/bin/bash
mkdir -p /application
#wget https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz
tar zxf /tmp/mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz -C /tmp/
mv /tmp/mysql-5.6.42-linux-glibc2.12-x86_64 /application/mysql-5.6.42
ln -sf /application/mysql-5.6.42/ /application/mysql
#创建mysql用户
useradd -M -s /sbin/nologin mysql
chown -R mysql:mysql /application/mysql/data/
#初始化mysql
/application/mysql/scripts/mysql_install_db --user=mysql --group=mysql --datadir=/application/mysql/data/ --basedir=/application/mysql
cp /application/mysql/support-files/mysql.server /etc/init.d/mysqld
\cp /application/mysql/my.cnf /etc/my.cnf
sed -i.ori 's#/usr/local#/application#g' /application/mysql/bin/mysqld_safe /etc/init.d/mysqld
ln -sf /application/mysql/bin/* /usr/sbin/
#新建数据库
/etc/init.d/mysqld start
mysqladmin -uroot password 'oldboy123'
mysql -uroot -poldboy123 -e "create database zrlog;"
mysql -uroot -poldboy123 -e "grant all privileges on zrlog.* to 'zrlog'@'localhost' identified by 'zrlog'"
mysql -uroot -poldboy123 -e "create database wordpress;"
mysql -uroot -poldboy123 -e "grant all privileges on wordpress.* to 'wordpress'@'localhost' identified by 'wordpress'"
