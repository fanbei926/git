yum install -y pcre-devel openssl-devel
useradd -M -s /sbin/nologin www
cd /tmp/ && wget http://nginx.org/download/nginx-1.12.2.tar.gz
tar zxf /tmp/nginx-1.12.2.tar.gz -C /tmp/
cd /tmp/nginx-1.12.2/;./configure --prefix=/application/nginx-1.12.2 --user=www --group=www --with-http_ssl_module --with-http_stub_status_module && make && make install
ln -sf /application/nginx-1.12.2 /application/nginx
ln -sf /application/nginx/sbin/nginx /usr/sbin/nginx
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
        server {
            listen       80;
            server_name  www.etiantian.org;
            location / {
                root   html/www;
                index  index.html index.htm;
            }
        }
    }
EOF
mkdir -p /application/nginx/conf/extra /application/nginx/html/blog
wget https://wordpress.org/latest.tar.gz
tar zxf /tmp/latest.tar.gz -C /application/nginx/html/blog/
wget http://jp2.php.net/distributions/php-5.6.38.tar.gz
wget https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz
tar zxf /tmp/mysql-5.6.42-linux-glibc2.12-x86_64.tar.gz -C /tmp/
mv /tmp/mysql-5.6.42-linux-glibc2.12-x86_64 /application/mysql-5.6.42
ln -sf /application/mysql-5.6.42/ /application/mysql
useradd -M -s /sbin/nologin mysql
/application/mysql/scripts/mysql_install_db --user=mysql --group=mysql --datadir=/application/mysql/data/ --basedir=/application/mysql
cp /application/mysql/support-files/mysql.server /etc/init.d/mysqld
\cp /application/mysql/my.cnf /etc/my.cnf
sed -i.ori 's#/usr/local#/application#g' /application/mysql/bin/mysqld_safe /etc/init.d/mysqld
ln -sf /application/mysql/bin/* /usr/sbin/
mysqladmin -uroot password 'oldboy123'
