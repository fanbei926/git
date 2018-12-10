#!/bin/bash
function python_install () {
	echo "start install python....."
	if [ -d $path ]
	then
	    echo "$path has exit."
	else
	    echo "create $path"
	    mkdir -p $path
	fi
	tar xf /tmp/${python_ver}.tar.xz -C /tmp/

	cd /tmp/${python_ver};./configure;make && make install
	if [ $? -ne 0 ]
	then
		echo "make install error."
	fi
	[ -f /tmp/${api}.zip ] && {
		unzip /tmp/${api}.zip -d /tmp/
		cd /tmp/${api};python3 setup.py install
	}
}
function redis_install () {
	echo "start install redis....."
	if [ -d $path ]
	then
	    echo "$path has exit."
	else
	    echo "create $path"
	    mkdir -p $path
	fi
	tar zxf /tmp/${redis_ver}.tar.gz -C /tmp/
	mv /tmp/${redis_ver} ${path}/${redis_ver}   #移动文件夹
	[ -f ${path}/redis ] && {                                          #软链接存在就删除
	    rm -fr ${path}/redis
	}
	ln -s ${path}/${redis_ver}/ ${path}/redis
	cd ${path}/redis;make
	if [ $? -ne 0 ]
	then
		echo "make install error."
	fi
	
	echo "PATH=${path}/redis/src/:$PATH" >> /etc/profile
	source /etc/profile
}

function gen_configure () {
	if [ -d ${path}/redis/$1 ]
	then
	    echo "${path}/redis/$1 has exit."
	else
	    echo "create ${path}/redis/$1"
	    mkdir -p ${path}/redis/$1
	fi
	cat >${path}/redis/$1/redis.conf<<EOF
	daemonize yes
	pidfile ${path}/redis/$1/redis.pid
	logfile ${path}/redis/$1/redis.log
	loglevel notice
	port $1
	dir ${path}/redis/$1
	dbfilename dump.rdb
	protected-mode no
	#cluster-enabled yes
	#cluster-config-file nodes.conf
	#cluster-node-timeout 5000
	appendonly yes
	bind $2 127.0.0.1
EOF
}
function master () {
	redis_install
	gen_configure $master_port $ip
	${path}/redis/src/redis-server ${path}/redis/${master_port}/redis.conf
}
function slave () {
	redis_install
	gen_configure $slave_port $ip
	${path}/redis/src/redis-server ${path}/redis/${slave_port}/redis.conf
	${path}/redis/src/redis-cli -p ${slave_port} SLAVEOF $master_ip $master_port
}
function sentinel () {
	if [ -d ${path}/redis/$1 ]
	then
	    echo "${path}/redis/$1 has exit."
	else
	    echo "create ${path}/redis/$1"
	    mkdir -p ${path}/redis/$1
	fi
	cat >${path}/redis/$1/sentinel.conf<<EOF
	daemonize yes
	loglevel notice
	logfile ${path}/redis/$1/sentinel.log
	protected-mode no
	port $1
	dir ${path}/redis/$1
	sentinel monitor mymaster $master_ip $master_port $quorum
	sentinel down-after-milliseconds mymaster 1500
	sentinel failover-timeout mymaster 10000
EOF

	${path}/redis/src/redis-sentinel ${path}/redis/$1/sentinel.conf
}

function main () {
	redis_ver="redis-4.0.2"
	python_ver="Python-3.5.2"
	path="/application"
	master_port="6379"
	slave_port="6380"
	snetinel_port="26380"
	master_ip="10.0.0.107"
	quorum="2"
	ip=`ip a | grep "eth[0|1]" | awk -F"[ /]+" 'NR==2{print $3}'`
	api="redis-py-master"

	while true
    do
		clear
        cat <<EOF
    1.install master_redis.
    2.install slave_redis.
    3.install sentinel.
    4.install python3
    5.exit
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
            sentinel $snetinel_port
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
			python_install
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
            break
            ;;
            *)
            echo "Usage $0 : {1|2|3|4|5}"
            continue
        esac
    done   
}
main
