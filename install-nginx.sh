#!/bin/bash
function nginx_install () {
    yum install -y pcre-devel openssl-devel  gcc-c++ &> /dev/null                #安装nginx依赖
    #判断用户是否存在
    [ `cat /etc/passwd | grep "$user1" | wc -l` -gt 0 ] && {
        echo "User $user1 has create."
    } || {
        useradd -M -s /sbin/nologin $user1                              #不存在就创建www用户
        retval=$?
    }
    #判断文件是否存在
    [ ! -f /tmp/${nginx_ver}.tar.gz ] && {
        cd /tmp/ && wget http://nginx.org/download/${nginx_ver}.tar.gz &> /dev/null
        echo "${nginx_ver}.tar.gz file dose not exit."
    }
    tar zxf /tmp/${nginx_ver}.tar.gz -C /tmp/
    [ ! -d /tmp/$nginx_ver/ ] && {
        echo "tar has error,directory does not exit.Please check."
        exit 1
    }
    #判断编译是否成功
    cd /tmp/$nginx_ver/;./configure --prefix=${path}/$nginx_ver --user=$user1 \
    --group=$user1 --with-http_ssl_module --with-http_stub_status_module &> /dev/null;make &> /dev/null && make install &> /dev/null
    [ $? -ne 0 ] && {
        echo "Confiure error!"
        exit 2
    }
    [ -f ${path}/nginx ] && {
        rm -fr ${path}/nginx
    }
    ln -s ${path}/$nginx_ver ${path}/nginx                          #创建文件夹软链接
    [ -f /usr/sbin/nginx ] && {
        rm -fr /usr/sbin/nginx
    }
    ln -s ${path}/nginx/sbin/nginx /usr/sbin/nginx                  #创建nginx命令软链接
    #配置nginx.conf
    cat >${path}/nginx/conf/nginx.conf<<'EOF'
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
    [ -d ${path}/nginx/conf/extra ] && {
        echo "extra folder exits."
    } || {
        mkdir -p ${path}/nginx/conf/extra
    }
    [ -d ${path}/nginx/html/blog ] && {
        echo "blog folder exits."
    } || {
        mkdir -p ${path}/nginx/html/blog
    }
    cat >${path}/nginx/conf/extra/blog.conf<<'EOF'
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
    return 0
}

function mysql_install () {
    #安装mysql
	yum install -y libaio-devel &> /dev/null
     [ ! -f /tmp/${mysql_ver}-linux-glibc2.12-x86_64.tar.gz ] && {
         cd /tmp/ && wget https://dev.mysql.com/get/Downloads/MySQL-5.6/${mysql_ver}-linux-glibc2.12-x86_64.tar.gz &> /dev/null
         echo "${mysql_ver}-linux-glibc2.12-x86_64.tar.gz file dose not exit."
     }
     tar zxf /tmp/${mysql_ver}-linux-glibc2.12-x86_64.tar.gz -C /tmp/
     mv /tmp/${mysql_ver}-linux-glibc2.12-x86_64 ${path}/${mysql_ver}   #移动文件夹
     [ -f ${path}/mysql ] && {                                          #软链接存在就删除
         rm -fr ${path}/mysql
     }
     ln -s ${path}/${mysql_ver}/ ${path}/mysql
     #创建mysql用户
     [ `cat /etc/passwd | grep "$user2" | wc -l` -gt 0 ] && {
         echo "$user2 has create."
     } || {
         useradd -M -s /sbin/nologin $user2                             #不存在就创建用户
     }
     chown -R $user2:$user2 ${path}/mysql/data/
     #初始化mysql
     ${path}/mysql/scripts/mysql_install_db --user=$user2 --group=$user2 \
     --datadir=${path}/mysql/data/ --basedir=${path}/mysql &> /dev/null
     [ $? -ne 0 ] && { #初始化mysql是否成功
         echo "Install mysql has error.Please check."
         exit 3
     }
     \cp -a ${path}/mysql/support-files/mysql.server /etc/init.d/mysqld
     \cp -a ${path}/mysql/my.cnf /etc/my.cnf
     sed -i.ori "s#/usr/local#${path}#g" ${path}/mysql/bin/mysqld_safe /etc/init.d/mysqld #替换mysqld_safe mysqld脚本中的路径
     ln -sf ${path}/mysql/bin/* /usr/sbin/
     #新建数据库
     /etc/init.d/mysqld start
     mysqladmin -uroot password "$mysql_passwd"
     cat >>/etc/my.cnf<<EOF
     [client]
     user = root
     password = $mysql_passwd
EOF
     mysql -e "create database ${db_name};"
     mysql -e "grant all privileges on ${db_name}.* to $db_user@'localhost' identified by '${db_passwd}'"
}

function php_install () {
    dd if=/dev/zero of=/tmp/php-swap bs=1M count=1024
    mkswap /tmp/php-swap
    swapon /tmp/php-swap
    #安装php
    [ ! -f /tmp/libiconv-1.14.tar.gz ] && { #安装依赖
        cd /tmp/ && wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
        echo "libiconv-1.14.tar.gz file dose not exit."
    }
    yum install -y zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel \
    freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel libmcrypt-devel mhash mcrypt &> /dev/null
    安装php依赖libiconv
    tar zxf /tmp/libiconv-1.14.tar.gz -C /tmp/
    sed -i -e '/gets is a security/d' /tmp/libiconv-1.14/srclib/stdio.in.h
    cd /tmp/libiconv-1.14;./configure --prefix=/usr/local/libiconv &> /dev/null ;make &> /dev/null && make install &> /dev/null #编译libiconv-1.14
    [ $? -ne 0 ] && {
        echo "Confiure error!"
        exit 2
    }
    [ ! -f /tmp/${php_ver}.tar.gz ] && {    #不存在安装文件就使用wget下载
        cd /tmp/ && wget http://jp2.php.net/distributions/${php_ver}.tar.gz &> /dev/null
        echo "${php_ver}.tar.gz file dose not exit."
    }
    tar zxf /tmp/${php_ver}.tar.gz -C /tmp/
    ln -s ${path}/mysql/lib/libmysqlclient.so.18  /usr/lib64/
    cd /tmp/${php_ver}/;touch ext/phar/phar.phar;./configure --prefix=${path}/${php_ver} --with-mysql=${path}/${mysql_ver} \
    --with-pdo-mysql=mysqlnd --with-iconv-dir=/usr/local/libiconv --with-freetype-dir --with-jpeg-dir \
    --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath \
    --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-fpm \
    --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl \
    --enable-sockets --with-xmlrpc --enable-soap --enable-short-tags --enable-static --with-xsl --with-fpm-user=$user1 \
    --with-fpm-group=$user1 --enable-ftp --enable-opcache=no &> /dev/null ;make &> /dev/null && make install &> /dev/null
    [ $? -ne 0 ] && {
        echo "Confiure error!"
        exit 2
    }
    swapoff /tmp/php-swap
    rm -fr /tmp/php-swap
    [ -f ${path}/php ] && {
        rm -fr ${path}/php
    }
    ln -s ${path}/${php_ver} ${path}/php
    cd /tmp/${php_ver}/;\cp -a php.ini-production ${path}/php/lib/ #配置php
    cd ${path}/php/etc/;\cp php-fpm.conf.default php-fpm.conf
    ln -s ${path}/php/sbin/php-fpm /usr/sbin/      #创建php-fpm命令软链接
    cat >${path}/nginx/html/blog/index.php<<'EOF'  #创建一个测试页面
    <?php
        phpinfo();
    ?>
EOF
    php-fpm                                             #运行php-fpm
    #安装wordpress
    [ ! -f /tmp/latest.tar.gz ] && {
        wget -O /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
        echo "wordpress.tar.gz file dose not exit."
    }
    tar zxf /tmp/wordpress.tar.gz -C ${path}/nginx/html/blog/
    chown -R $user1:$user1 ${path}/nginx/html/blog/wordpress/
}

#脚本入口
while true 
do
    cat <<EOF
     1.Install LNMP
     2.exit
EOF
    read -t 30 -p "Please select your choice:" i
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo &> /dev/null
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo &> /dev/null
    a=$i #输入的参数
    user1="www" #www用户
    user2="mysql" #mysql用户
    nginx_ver="nginx-1.12.2" #nginx版本
    mysql_ver="mysql-5.6.42" #mysql版本
    mysql_passwd="oldboy123"
    db_name="wordpress"
    db_user="wordpress"
    db_passwd="wordpress"
    php_ver="php-5.6.38"
    path="/application"
    
    if [ ! $a ] #没输入参数，要求重新输入参数
    then
        echo "Please input your numbers,retry."
        continue
    fi
    expr $a + 2 &> /dev/null #判断输入的是否为整数
    if [ $? -ne 0 ]
    then
        echo "Please input numbers,retry."
        continue
    fi
    case $a in #对输入进行判断
            1)
            echo "1. Begin install nginx..........."
            nginx_install
            [ $? -ne 0 ] && {
                echo "Install nginx has error!"
                exit 5
            }
            echo "2. Begin install mysql..........."
            mysql_install
            [ $? -ne 0 ] && {
                echo "Install mysql has error!"
                exit 5
            }
            echo "3. Begin install php..........."
            php_install
            [ $? -ne 0 ] && {
                echo "Install php has error!"
                exit 5
            }
            ;;
            2)
            echo "Bye!"
            exit 0
            ;;
            *)
            echo "Usage $0: {1|2}"
            continue
    esac
done