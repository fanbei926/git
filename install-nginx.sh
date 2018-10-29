#!/bin/bash
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
#安装nginx
yum install -y pcre-devel openssl-devel
useradd -M -s /sbin/nologin www
#cd /tmp/ && wget http://nginx.org/download/nginx-1.12.2.tar.gz
tar zxf /tmp/nginx-1.12.2.tar.gz -C /tmp/
cd /tmp/nginx-1.12.2/;./configure --prefix=/application/nginx-1.12.2 --user=www --group=www --with-http_ssl_module --with-http_stub_status_module && make && make install
ln -sf /application/nginx-1.12.2 /application/nginx
ln -sf /application/nginx/sbin/nginx /usr/sbin/nginx
#配置nginx.conf
cat >/application/nginx/conf/nginx.conf<<'EOF'
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    
    include extra/blog.conf;
}
EOF
#配置额外的blog.conf
mkdir -p /application/nginx/conf/extra /application/nginx/html/blog
cat >/application/nginx/conf/extra/blog.conf<<'EOF'
server {
    listen       80;
    server_name  blog.etiantian.org;
    root   html/blog;
    index  index.php index.html index.htm;
    location ~* .*\.(php|php5)?$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi.conf;
    }
}
EOF

#安装mysql
#cd /tmp/;wget https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz
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
mysql -uroot -poldboy123 -e "create database wordpress;"
mysql -uroot -poldboy123 -e "grant all privileges on wordpress.* to 'wordpress'@'localhost' identified by 'wordpress'"

#安装php
#cd /tmp/;wget http://jp2.php.net/distributions/php-5.6.38.tar.gz
#cd /tmp/;wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
yum install -y zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel libmcrypt-devel mhash mcrypt
安装php依赖libiconv
tar zxf /tmp/libiconv-1.14.tar.gz -C /tmp/
cd /tmp/libiconv-1.14;./configure --prefix=/usr/local/libiconv && make && make install
tar zxf /tmp/php-5.6.38.tar.gz -C /tmp/
ln -s /application/mysql/lib/libmysqlclient.so.18  /usr/lib64/
cd /tmp/php-5.6.38/;touch ext/phar/phar.phar;./configure --prefix=/application/php5.6.38 --with-mysql=/application/mysql-5.6.42 --with-pdo-mysql=mysqlnd --with-iconv-dir=/usr/local/libiconv --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-fpm --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --enable-short-tags --enable-static --with-xsl --with-fpm-user=www --with-fpm-group=www --enable-ftp --enable-opcache=no && make && make install
ln -sf /application/php5.6.38 /application/php
cd /tmp/php-5.6.38/;cp php.ini-production /application/php/lib/
cd /application/php/etc/;cp php-fpm.conf.default php-fpm.conf
ln -sf /application/php/sbin/php-fpm /usr/sbin/
php-fpm
cat >/application/nginx/html/blog/index.php<<'EOF'
<?php
    phpinfo();
?>
EOF

#安装wordpress
#cd /tmp/;wget https://wordpress.org/latest.tar.gz
tar zxf /tmp/wordpress-4.9.8.tar.gz -C /application/nginx/html/blog/

chown -R www:www /application/nginx/html/blog/wordpress/

yum install -y rpcbind nfs-utils
mkdir -p /application/nginx/html/blog/wordpress/wp-content/uploads
mount -t nfs 172.16.1.99:/data /application/nginx/html/blog/wordpress/wp-content/uploads/
#启动nginx
nginx
