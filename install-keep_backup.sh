#!/bin/bash
#安装nginx
yum install -y pcre-devel openssl-devel
useradd -M -s /sbin/nologin www
#cd /tmp/ && wget http://nginx.org/download/nginx-1.12.2.tar.gz
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
    upstream php {
        server 10.0.0.100:80;
        server 10.0.0.101:80;
    }
    upstream tomcat {
        server 10.0.0.102:8080;
        server 10.0.0.103:8080;
    }
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen  10.0.0.110:80;
        server_name blog.etiantian.com;
        location / {
                root html/blog/wordpress;
                index index.php;
                proxy_pass http://php;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_redirect default;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
    server {
        listen       10.0.0.110:8080;
        server_name  blog.zrlog.com:8080;
        location / {
                proxy_pass http://tomcat;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_redirect default;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
        location ~ .*\.(js|css|ico|png|jpg|eot|svg|ttf|woff) {
                proxy_pass http://tomcat;
                root /application/tomcat/webapps/zrlog;
        }
    }
}
EOF


yum install -y keepalived

cat >/etc/keepalived/keepalived.conf<<'EOF'
! Configuration File for keepalived

global_defs {
   router_id lb02
}

vrrp_instance group01 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 110
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.0.0.110/24 dev eth0 label eth0:1
    }
}
EOF
mkdir -p /server/scripts/ 
cat >>/server/scripts/check_web.sh<<EOF
!#/bin/bash
nginx=`ps -ef | grep [n]ginx | wc -l`
if [ $nginx -lt 2 ]
then
/etc/init.d/keepalived stop
fi
EOF
