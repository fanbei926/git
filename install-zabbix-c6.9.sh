#!/bin/bash
rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/6/x86_64/zabbix-release-3.4-1.el6.noarch.rpm
rpm -ivh http://repo.webtatic.com/yum/el6/latest.rpm
rpm -ivh https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql57-community-el6/mysql57-community-release-el6-10.noarch.rpm
yum -y install httpd php56w php56w-gd php56w-mysqlnd php56w-bcmath php56w-mbstring php56w-xml php56w-ldap mysql-community-server
sed -i.ori 's#max_execution_time = 30#max_execution_time = 300#;s#max_input_time = 60#max_input_time = 300#;s#post_max_size = 8M#post_max_size = 16M#;910a date.timezone = Asia/Shanghai' /etc/php.ini
yum install zabbix zabbix-agent zabbix-get zabbix-sender zabbix-server zabbix-server-mysql zabbix-web zabbix-web-mysql -y
cp -R /usr/share/zabbix/ /var/www/html/
chmod -R 755 /etc/zabbix/web
chown -R apache.apache /etc/zabbix/web
echo "ServerName 127.0.0.1:80">>/etc/httpd/conf/httpd.conf
sed -i 's#;always_populate_raw_post_data = -1#always_populate_raw_post_data = -1#g' /etc/php.ini
sed -i 's#Listen 80#Listen 1999#g' /etc/httpd/conf/httpd.conf
/etc/init.d/mysqld start
passwd=`awk '/password/{print $NF}' /var/log/mysqld.log | awk 'NR==1{print $0}'`
mysqladmin -uroot -p"$passwd" password "Oldboy@123"
mysql -uroot -p'Oldboy@123' -e 'create database zabbix character set utf8 collate utf8_bin;'
mysql -uroot -p'Oldboy@123' -e "grant all privileges on zabbix.* to 'zabbix'@'localhost' identified by 'Zabbix@123'"
zcat /usr/share/doc/zabbix-server-mysql-3.4.14/create.sql.gz | mysql -uzabbix -p'Zabbix@123' zabbix
/etc/init.d/httpd start
/etc/init.d/zabbix-server start
