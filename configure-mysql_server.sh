#!/bin/bash
mysql -uroot -poldboy123 -e "create database zabbixtest;"
mysql -uroot -poldboy123 -e "grant all privileges on zabbixtest.* to 'zabbixtest'@'localhost' identified by '123456'"
mkdir -p /server/scripts
cat >/server/scripts/check_mysql.sh<<'EOF'
#!/bin/bash
#function:		Check mysql status for zabbix
#auth:			Jerry
#date:			2018.10.11
#version:		1.0

mysql_user='zabbixtest'
mysql_password='123456'
mysql_host='127.0.0.1'
mysql_port='3306'
mysqladmin_path='/application/mysql/bin/'
mysql_conn="${mysqladmin_path}mysqladmin -u${mysql_user} -p${mysql_password} -h${mysql_host} -P${mysql_port}"

case $1 in
	Uptime)
		result=`${mysql_conn} status 2>/dev/null | awk -F"[ :]+" '{print $2}'`
	echo $result
	;;
	Slow_queries)
		result=`${mysql_conn} status 2>/dev/null | awk -F"[ :]+" '{print $9}'`
	echo $result
	;;
	Questions)
		result=`${mysql_conn} status 2>/dev/null | awk -F"[ :]+" '{print $6}'`
	echo $result
	;;
	Com_update)
		result=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_update[ ]/{print $3}'`
	echo $result
	;;
	Com_select)
		result=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_select[ ]/{print $3}'`
	echo $result
	;;
	Com_rollback)
		result=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_rollback[ ]/{print $3}'`
	echo $result
	;;
	Com_insert)
		result=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_insert[ ]/{print $3}'`
	echo $result
	;;
	Com_delete)
		result=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_delete[ ]/{print $3}'`
	echo $result
	;;
	Com_commit)
		result=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_commit[ ]/{print $3}'`
	echo $result
	;;
	Com_begin)
		result=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_begin[ ]/{print $3}'`
	echo $result
	;;
	Bytes_sent)
		result=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Bytes_sent[ ]/{print $3}'`
	echo $result
	;;
	Bytes_received)
		result=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Bytes_received[ ]/{print $3}'`
	echo $result
	;;
esac
EOF
chmod +x /server/scripts/check_mysql.sh
cat >/etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf<<'EOF'
# For all the following commands HOME should be set to the directory that has .my.cnf file with password information.

# Flexible parameter to grab global variables. On the frontend side, use keys like mysql.status[Com_insert].
# Key syntax is mysql.status[variable].
UserParameter=mysql.status[*],/server/scripts/check_mysql.sh $1

# Flexible parameter to determine database or table size. On the frontend side, use keys like mysql.size[zabbix,history,data].
# Key syntax is mysql.size[<database>,<table>,<type>].
# Database may be a database name or "all". Default is "all".
# Table may be a table name or "all". Default is "all".
# Type may be "data", "index", "free" or "both". Both is a sum of data and index. Default is "both".
# Database is mandatory if a table is specified. Type may be specified always.
# Returns value in bytes.
# 'sum' on data_length or index_length alone needed when we are getting this information for whole database instead of a single table
UserParameter=mysql.size[*],bash -c 'echo "select sum($(case "$3" in both|"") echo "data_length+index_length";; data|index) echo "$3_length";; free) echo "data_free";; esac)) from information_schema.tables$([[ "$1" = "all" || ! "$1" ]] || echo " where table_schema=\"$1\"")$([[ "$2" = "all" || ! "$2" ]] || echo "and table_name=\"$2\"");" | HOME=/var/lib/zabbix mysql -N'

UserParameter=mysql.ping,mysqladmin -uzabbixtest -p123456 -P3306 -h127.0.0.1 ping 2>/dev/null | grep -c alive
UserParameter=mysql.version,mysql -V
EOF
/etc/init.d/zabbix-agent restart
