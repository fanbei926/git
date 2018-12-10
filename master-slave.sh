#!/bin/bash
function mysql_install () {
    #安装mysql
    echo "start install mysql....."
    if [ -d $path ]
    then
        echo "$path has exit."
    else
        echo "create $path"
        mkdir -p $path
    fi
    echo "install libaio-devel"
	yum install -y libaio-devel &> /dev/null
     [ ! -f /tmp/${mysql_ver}-linux-glibc2.12-x86_64.tar.gz ] && {
         cd /tmp/ && wget https://dev.mysql.com/get/Downloads/MySQL-5.6/${mysql_ver}-linux-glibc2.12-x86_64.tar.gz &> /dev/null
         echo "${mysql_ver}-linux-glibc2.12-x86_64.tar.gz file has down."
     }
     tar zxf /tmp/${mysql_ver}-linux-glibc2.12-x86_64.tar.gz -C /tmp/
     mv /tmp/${mysql_ver}-linux-glibc2.12-x86_64 ${path}/${mysql_ver}   #移动文件夹
     [ -f ${path}/mysql ] && {                                          #软链接存在就删除
         rm -fr ${path}/mysql
     }
     ln -s ${path}/${mysql_ver}/ ${path}/mysql
     #创建mysql用户
     [ `cat /etc/passwd | grep "$user" | wc -l` -gt 0 ] && {
         echo "$user has create."
     } || {
         useradd -M -s /sbin/nologin $user                            #不存在就创建用户
     }
     chown -R $user:$user ${path}/mysql/data/
     #初始化mysql
     echo "init mysql"
     ${path}/mysql/scripts/mysql_install_db --user=$user --group=$user \
     --datadir=${path}/mysql/data/ --basedir=${path}/mysql &> /dev/null
     [ $? -ne 0 ] && { #初始化mysql是否成功
         echo "Install mysql has error.Please check."
         exit 3
     }
     \cp -a ${path}/mysql/support-files/mysql.server /etc/init.d/mysqld
     \cp /application/mysql/support-files/my-default.cnf /etc/my.cnf
     sed -i.ori "s#/usr/local#${path}#g" ${path}/mysql/bin/mysqld_safe /etc/init.d/mysqld #替换mysqld_safe mysqld脚本中的路径
     
     echo "PATH=${path}/mysql/bin:$PATH" >> /etc/profile
     source /etc/profile
     #新建数据库
     echo "start mysql"
     /etc/init.d/mysqld start
     mysqladmin -uroot password "$mysql_passwd" &> /dev/null
     echo "start configure"
     cat >/etc/my.cnf<<EOF
[mysqld]
#基本
basedir = ${path}/mysql/
datadir = ${path}/mysql/data/
log-error = /var/log/mysql.log
pid_file = ${path}/mysql/data/mysql.pid
socket = /tmp/mysql.sock
skip-name-resolve
port = $mysql_port
server-id = $server_id
character_set_server=utf8
#binlog
log-bin = ${path}/mysql/data/mysql-bin
binlog_format = row
binlog_cache_size = 2M
sync_binlog = 1
expire_logs_days = 7
#replicate-do-db
#replicate-do-table
#replicate-wild-do-table
#replicate-ignore-db
#replicate-ignore-table
replicate-wild-ignore-table=mysql.%
replicate-wild-ignore-table=test.%
#临时表
key_buffer_size = 8M
#安全
wait_timeout = 60
interactive_timeout = 7200
max_connect_errors = 20
#qc查询
query_cache_limit = 50M
query_cache_size = 64M
query_cache_type = 1
#连接
max_connections = 1024
back_log = 128
max_allowed_packet = 32M
thread_cache_size = 8
#innodb表
innodb_buffer_pool_size = 700M
innodb_flush_log_at_trx_commit = 1
innodb_thread_concurrency = 0
innodb_log_file_size = 32M
innodb_log_files_in_group = 3
#表操作、读取
read_buffer_size = 1M
read_rnd_buffer_size = 1M
sort_buffer_size = 2M
join_buffer_size = 2M
bulk_insert_buffer_size = 8M
#gtid
gtid-mode = on
enforce-gtid-consistency = true
log-slave-updates = 1
relay_log_purge = 0


[client]
user = root
password = $mysql_passwd
socket = /tmp/mysql.sock
EOF
    echo "restart mysql"
    /etc/init.d/mysqld restart
}
function master () {
    mysql_install
    mysql -e "grant replication slave on *.* to ${repl_user}@'${repl_ip}' identified by '${repl_passwd}';"   
}
function slave () {
    mysql_install
    mysql -e "CHANGE MASTER TO MASTER_HOST='$master_ip',MASTER_USER='$repl_user',MASTER_PASSWORD='$repl_passwd',MASTER_PORT=${mysql_port},MASTER_AUTO_POSITION=1;"
    mysql -e "start slave;"
}
function master_semisync () {
    mi_sync_master SONAME 'semisync_master.so';"
    mysql -e "SET GLOBAL rpl_semi_sync_master_enabled = 1;"
    echo "master_semisynysql -e "INSTALL PLUGIN rpl_semc has done."
    sleep 1
}
function slave_semisync () {
    mysql -e "stop slave;"
    mysql -e "INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';"
    mysql -e "SET GLOBAL rpl_semi_sync_slave_enabled = 1;"
    mysql -e "start slave;"
    echo "slave_semisync has done."
    sleep 1
}
function delaysync () {
    mysql -e "stop slave;"
    mysql -e "CHANGE MASTER TO MASTER_DELAY = $delay_time;"
    mysql -e "start slave;"
    echo "slave delay has done."
    sleep 1
}
main () {
    mysql_ver="mysql-5.6.42" #mysql版本
    mysql_passwd="oldboy123"
    mysql_port="3306"
    master_ip="10.0.0.107"
    slave_ip="10.0.0.100"
    user="mysql"
    repl_ip=`echo $slave_ip | awk -F '.' '{print $1"."$2"."$3".%"}'`
    repl_user="repl"
    repl_passwd="123"
    master_server_id=`echo $master_ip | awk -F '.' '{print $NF}'`
    #slave_server_id=`echo $slave_ip | awk -F '.' '{print $NF}'`
    server_id=`ip a | grep "eth[0|1]" | awk -F"[ /]+" 'NR==2{print $3}' | awk -F'.' '{print $NF}'`
    delay_time="300"
    path="/application"

    while true
    do
		clear
        cat <<EOF
    1.install master_mysql-server.
    2.install slave_mysql-server.
    3.start master_semisync mode.
    4.start slave_semisync mode.
    5.start delaysync mode.
    6.exit
EOF
        read -p "Please input your choice: " i
        if [ ! $i ]
        then
            echo "You put nothing,Please retry."
            continue
        fi
        expr $i + 2 &> /dev/null
        if [ $? -ne 0 ]
        then
            echo "Please input number,Please retry."
            continue
        fi
        case $i in
            1)
            master
            if [ $? -eq 0 ]
            then
                echo "install complete.now return."
                sleep 1
                continue
            else
                echo "error.quit..now"
                break
            fi
            ;;
            2)
            slave
            if [ $? -eq 0 ]
            then
                echo "install complete.now return."
                sleep 1
                continue
            else
                echo "error.quit..now"
                break
            fi
            ;;
            3)
            master_semisync
            if [ $? -eq 0 ]
            then
                echo "install complete.now return."
                sleep 1
                continue
            else
                echo "error.quit..now"
                break
            fi
            ;;
            4)
            slave_semisync
            if [ $? -eq 0 ]
            then
                echo "install complete.now return."
                sleep 1
                continue
            else
                echo "error.quit..now"
                break
            fi
            ;;
            5)
            delaysync
            if [ $? -eq 0 ]
            then
                echo "install complete.now return."
                sleep 1
                continue
            else
                echo "error.quit..now"
                break
            fi
            ;;
            6)
            break
            ;;
            *)
            echo "Usage $0 : {1|2|3|4|5|6}"
            continue
        esac
    done   
}
main