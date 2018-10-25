#!/bin/bash
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
mysql -uroot -poldboy123 -e "create database wordpress;"
mysql -uroot -poldboy123 -e "grant all privileges on wordpress.* to 'wordpress'@'localhost' identified by 'wordpress'"

#安装php
#wget http://jp2.php.net/distributions/php-5.6.38.tar.gz
#wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
yum install -y zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel libmcrypt-devel mhash mcrypt
#安装php依赖libiconv
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
#wget https://wordpress.org/latest.tar.gz
tar zxf /tmp/wordpress-4.9.8.tar.gz -C /application/nginx/html/blog/
#配置wordpress的wp-config.php文件
cat >/application/nginx/html/blog/wordpress/wp-config.php<<'EOF'
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'wordpress');

/** MySQL database password */
define('DB_PASSWORD', 'wordpress');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8mb4');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'IRYO1I4L*d4RN@Xh(0:;s<J$Op1o2rXPh)YKHg=9N%.K|Z7#0L-b7TW2%2wlF|BJ');
define('SECURE_AUTH_KEY',  'U6x?y?xmM(J|u2t4Whht+#[Xz,8g^N$6w5;U[vu].L&|V@koZSx[U^v,r(|}p1&;');
define('LOGGED_IN_KEY',    'mLkunfXtwJ0d-8m/Q).DQqTE$dGA ts4h_pin[AE$D9fKYBT}xkdt3Fq!mPHB2*f');
define('NONCE_KEY',        'sP:3LWNASTWP[,/]Ox$@bpU^K!7M!M<h=2z1;HuPb~hBe> 2zoz`lq^<;B%y5OT=');
define('AUTH_SALT',        'jm.XH)2G7P4`Y-^#8v[HU(cr9zBPakH2;>!.4SVo2i;~jjov]Pn%.sgZ6fa)h.I`');
define('SECURE_AUTH_SALT', '>D(=9-rQ{vcS$Vv<MTy-W11A~A-wl0Zh(K|vt(aTfV<;]k*?5$~/x)(<yh7V/brp');
define('LOGGED_IN_SALT',   'NBuV%#IOZ91l}Kv!ODwRzP9pg!?MBoh|!|Ydmc?s}:}&5C`a_el7oYlp8XJ=A,$h');
define('NONCE_SALT',       'TW9I*T]P@+1eemIv JR^jwN<M6z4/hlu1?EoJWx8?4${wKX^! }LI*r-<xtYrV|I');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
EOF

#启动nginx
nginx
