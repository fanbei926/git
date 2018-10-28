rpm -ivh https://mirrors.aliyun.com/zabbix/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm

yum install -y  zabbix-server-mysql zabbix-web-mysql zabbix-agent zabbix-get httpd php mariadb-server

sed -i.bak 's@# php_value date.timezone Europe/Riga@php_value date.timezone Asia/Shanghai@g' /etc/httpd/conf.d/zabbix.conf

systemctl start mariadb.service

mysqladmin -uroot password 'oldboy123'

mysql -uroot -poldboy123 -e 'create database zabbix character set utf8 collate utf8_bin;'

mysql -uroot -poldboy123 -e "grant all privileges on zabbix.* to 'zabbix'@'localhost' identified by 'zabbix'"

zcat /usr/share/doc/zabbix-server-mysql-3.2.11/create.sql.gz | mysql -uzabbix -pzabbix zabbix

sed -i.bak 's@# DBPassword=@DBPassword=zabbix@g' /etc/zabbix/zabbix_server.conf

systemctl start httpd zabbix-server zabbix-agent

yum -y install wqy-microhei-fonts

\cp /usr/share/fonts/wqy-microhei/wqy-microhei.ttc /usr/share/fonts/dejavu/DejaVuSans.ttf
