#!/bin/bash
#安装nginx
yum install -y pcre-devel openssl-devel
useradd -M -s /sbin/nologin www
#cd /tmp/ && wget http://nginx.org/download/nginx-1.12.2.tar.gz
tar zxf /tmp/nginx-1.12.2.tar.gz -C /tmp/
cd /tmp/nginx-1.12.2/;./configure --prefix=/application/nginx-1.12.2 --user=www --group=www --with-http_ssl_module --with-http_stub_status_module && make && make install
ln -sf /application/nginx-1.12.2 /application/nginx
ln -sf /application/nginx/sbin/nginx /usr/sbin/nginx
#配置nginx.conf反向代理功能
cat >/application/nginx/conf/nginx.conf<<'EOF'
worker_processes  1;
events {
    worker_connections  1024;
}
http {
	upstream php {
		server 10.0.0.130:80;
		server 10.0.0.131:80;
	}
	upstream tomcat {
		server 10.0.0.132:8080;
		server 10.0.0.133:8080;
	}
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    listen      10.0.0.128:80;
    server_name  www.etiantian.org;
    root   html;
    index  index.html index.htm;
    
	location ~* .*\.(php|php5)?$ {
	    proxy_pass http://php;
		proxy_set_header host $host;
		proxy_set_header X-Forwarded-For $remote_addr;
    }

    location ~ .*\.(jsp|jspx|do)?$ {
		proxy_pass http://tomcat;
		proxy_set_header host $host;
		proxy_set_header X-Forwarded-For $remote_addr;
	}
	location ~ .*\.(js|css|ico|png|jpg|eot|svg|ttf|woff) {
		proxy_pass http://tomcat;
		root /application/tomcat/webapps/ROOT;
	}
}
EOF

yum install -y keepalived
mkdir -p /server/scripts
cat >/server/scripts/check_web.sh<<'EOF'
#!/bin/bash
nginx=`ps -ef | grep -c [n]ginx`
if [ nginx -lt 2 ]
then
	/etc/init.d/keepalived stop
fi
EOF
cat >etc/keepalived/keepalived.conf<<'EOF'
! Configuration File for keepalived

global_defs {
   router_id lb01
}
vrrp_script check_web {
	script "/server/scripts/check_web.sh"
	interval 2
	weight 2
}
vrrp_instance group01 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 150
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.0.0.31 dev eth1 label: eth1:1
    }
    track_script {
    	check_web
    }
}
EOF