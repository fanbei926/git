#!/bin/bash
function Check_service () {
while true
do
  read -t 30 -p "Please input service name: " name
  if [ ! $name ]
  then
      echo "You input nothing,please retry."
      continue
  fi
  result=`ps -ef | egrep "\b$name\b" | grep -v "grep" | wc -l`
  if [ $result -eq 0 ]
  then
      echo "Can not find this service,please retry."
      continue
  else
      user=`ps -ef | egrep "\b$name\b" | grep -v "grep" | awk 'NR==1{print $1}'`
      echo "This service has $result processes."
      echo -n "Pid: "
      for pid in `ps -ef | egrep "\b$name\b" | grep -v "grep" | awk '{print $2}'`
      do
              echo -n "$pid "
      done
      echo
      echo "User: $user"
      echo -n "Port: "
      for port in `ss -antup4 | grep $name | awk -F"[ :]+" '{print $6}' | sort -rnk 1 | uniq`
      do
         echo -n "$port "
      done
      echo
  fi
  read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
  sleep 1
  main
done
}
function Check_url () {
while true
do
    read -t 30 -p "Please input URL: " url
    if [ ! $url ]
    then
            echo "You input nothing.Please retry."
            continue
    fi
    httpcode=`curl --connect-timeout 10 -m 20 -o /dev/null -s -w %{http_code} $url`
    if [ $httpcode -ge 200 ] && [ $httpcode -lt 300 ]
    then
            echo "$url is OK."
    else
            echo "Bad url: $url."
    fi
    read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
    sleep 1
    main
done
}
function Check_mem () {
  memTotal=`free | awk 'NR==2{print $2}'`
  memUsed=`free | awk 'NR==3{print $3}'`
  memFree=`free | awk 'NR==3{print $4}'`
  memUsedPre=`awk "BEGIN{print $memUsed/$memTotal*100}"`
  swapTotal=`free | awk 'NR==4{print $2}'`
  swapUsed=`free | awk 'NR==4{print $3}'`
  swapFree=`free | awk 'NR==4{print $4}'`
  
  echo "----------Memory Info----------"
  echo -e "Total Memory:\t$memTotal"
  echo -e "\tUsed Memory:\t$memUsed"
  echo -e "\tFree Memory:\t$memFree"
  echo -e "\tUsedMemPrecent:\t${memUsedPre}%"
  echo "-----------Swap Info-----------"
  echo -e "Total Swap:\t$swapTotal"
  echo -e "\tUsed Swap:\t$swapUsed"
  echo -e "\tFree Swap:\t$swapFree"
  
  if [[ $memUsedPre > 80 ]]
  then
          echo "Warning: memory aviable is too low..."
          echo -n "Now is "
          printf '%0.2f\n' $memUsedPre
  fi
  read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
  sleep 1
  main
}
function Check_io () {
for disk in `iostat -xd 1 1 | grep -o '^[a-z]d[a-z].'`
do
    echo "--------Disk $disk Info--------"
    i=`iostat -xk 2 2 | grep $disk | sed -n '$p'`
    echo -n "每秒进行merge的读操作数目: "
    echo `echo $i | awk '{print $2}'`
    echo -n "每秒进行merge的写操作数目: "
    echo `echo $i | awk '{print $3}'`
    echo -n "每秒完成的读I/O设备次数: "
    echo `echo $i | awk '{print $4}'`
    echo -n "每秒完成的写I/O设备次数: "
    echo `echo $i | awk '{print $5}'`
    echo -n "每秒读K字节数: "
    echo `echo $i | awk '{print $6}'`
    echo -n "每秒写K字节数: "
    echo `echo $i | awk '{print $7}'`
    echo -n "平均每次设备进行I/O操作的数据大小: "
    echo `echo $i | awk '{print $8}'`
    echo -n "平均I/O队列长度: "
    echo `echo $i | awk '{print $9}'`
    echo -n "平均每次I/O操作等待时间: "
    echo `echo $i | awk '{print $13}'`
    echo -n "I/O消耗的CPU百分比: "
    echo `echo $i | awk '{print $14}'`
done
read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
sleep 1
main
}
function Check_cpu () {
echo "--------CPU Info--------"
i=`iostat -c 2 2 |  sed -n '7p'`
echo -n "用户空间占用CPU百分比: "
echo `echo $i | awk '{print $1}'`
echo -n "内核空间占用CPU百分比: "
echo `echo $i | awk '{print $3}'`
echo -n "用户进程空间内改变过优先级的进程占用CPU百分比: "
echo `echo $i | awk '{print $2}'`
echo -n "空闲CPU百分比: "
echo `echo $i | awk '{print $6}'`
echo -n "等待I/O的CPU时间百分比: "
echo `echo $i | awk '{print $4}'`
echo -n "虚拟机占用CPU百分比: "
echo `echo $i | awk '{print $5}'`
read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
sleep 1
main
}
function Check_net () {
for interface in `ifconfig | egrep -o '^[a-z0-9]+'| grep -v "lo" | uniq`
do
    echo "--------Interface $interface Info--------"
    i=`cat /proc/net/dev | grep "$interface"`
    re_old=`echo $i | awk '{print $2}'`
    tr_old=`echo $i | awk '{print $10}'`
    sleep 10
    i=`cat /proc/net/dev | grep "$interface"`
    re_new=`echo $i | awk '{print $2}'`
    tr_new=`echo $i | awk '{print $10}'`

    re_speed=`awk "BEGIN{print ($re_new-$re_old)/10/1024}"`
    tr_speed=`awk "BEGIN{print ($re_new-$re_old)/10/1024}"`

    echo "接收速度（kb/s）: $re_speed"
    echo "发送速度（kb/s）: $tr_speed"
done
read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
sleep 1
main
}
function Check_tcp () {
ss -an | sed -n '2,$ p' | awk -F"[ :]+" '{STATE[$1]++} END{for(a in STATE) print STATE[a],a}'
read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
sleep 1
main
}
function Check_mysql () {
  local mysql_host="127.0.0.1"
  local mysql_port="3306"
  mysql_conn="mysqladmin -h $mysql_host -P $mysql_port"
  ping_test=`$mysql_conn ping 2> /dev/null | grep -o 'alive' | wc -l`
  if [ "ping_test" -eq 0 ]
  then
	echo "Connect mysql server has error,please check."
	sleep 1
	main
  fi
  uptime=`${mysql_conn} status 2>/dev/null | awk -F"[ :]+" '{print $2}'`
  echo "Uptime: $uptime"
  questions=`${mysql_conn} status 2>/dev/null | awk -F"[ :]+" '{print $6}'`
  echo "Questions: $questions"
  slow_queries=`${mysql_conn} status 2>/dev/null | awk -F"[ :]+" '{print $9}'`
  echo "Slow_queries: $slow_queries"
  com_select=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_select[ ]/{print $3}'`
  echo "Com_select: $com_select"
  com_update=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_update[ ]/{print $3}'`
  echo "Com_update: $com_update"
  com_insert=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_insert[ ]/{print $3}'`
  echo "Com_insert: $com_insert"
  com_delete=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_delete[ ]/{print $3}'`
  echo "Com_delete: $com_delete"
  com_commit=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_commit[ ]/{print $3}'`
  echo "Com_commit: $com_commit"
  com_begin=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Com_begin[ ]/{print $3}'`
  echo "Com_begin: $com_begin"
  bytes_sent=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Bytes_sent[ ]/{print $3}'`
  echo "Bytes_sent: $bytes_sent"
  bytes_received=`${mysql_conn} extended-status 2>/dev/null | awk -F"[ |]+" '/Bytes_received[ ]/{print $3}'`
  echo "Bytes_received: $bytes_received"
  read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
  sleep 1
  main
}
function Check_nginx () {
  curl -s http://127.0.0.1:81/status &> /dev/null
  if [ $? -ne 0 ]
  then
    echo "Please check your url or nginx's config.Now will return ..."
    sleep 1
    main
  fi
  echo "--------Nginx status--------"
  curl -s http://127.0.0.1:81/status
  read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
  sleep 1
  main
}
function Check_php () {
  curl -s http://127.0.0.1:82/status &> /dev/null
  if [ $? -ne 0 ]
  then
    echo "Please check your url or nginx's config.Now will return ..."
    sleep 1
    main
  fi
  echo "--------PHP status--------"
  curl -s http://127.0.0.1:82/status
  read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
  sleep 1
  main
}
function Check_port () {
	while true
	do
		read -t 30 -p "Please input URL or IP: " url
		if [ ! "$url" ]
		then
				echo "You input nothing.Please retry."
				continue
		fi
		read -t 30 -p "Please input port: " port
		if [ ! "$port" ]
		then
				echo "You input nothing.Please retry."
				continue
		else
			expr 2 + $port &> /dev/null
			if [ $? -ne 0 ]
			then
				echo "Please input number.Please retry."
				continue
			fi
		fi
		nc -v -w 5 $url -z $port &> /dev/null
		if [ "$result" -eq 0 ]
		then
				echo "$url is OK, and $port is open."
		else
				echo "Bad url: $url,or port: $port"
		fi
		read -t 30 -p "ENTER PRESS ANY KEY TO RETURN..."
		sleep 1
		main
	done
}
function main () {
while true
    do
      clear
      cat <<EOF
      1. Check service.
      2. Check url.
      3. Check mem.
      4. Check io.
      5. Check cpu.
      6. Check net.
      7. Check tcp.
      8. Check mysql.
      9. Check nginx.
      10.Check php.
      11.Check port.
      12.Exit
EOF
    read -t 30 -p "Please input your choice: " a
    if [ ! $a ]
    then
        echo "You input nothing,please retry."
        sleep 1
        continue
    fi
    expr 2 + $a &> /dev/null
    if [ $? -ne 0 ]
    then
        echo "Please input number,retry."
        sleep 1
        continue
    fi
        case "$a" in
          1)
          Check_service
          ;;
          2)
          Check_url
          ;;
          3)
          Check_mem
          ;;
          4)
          Check_io
          ;;
          5)
          Check_cpu
          ;;
          6)
          Check_net
          ;;
          7)
          Check_tcp
          ;;
          8)
          Check_mysql
          ;;
          9)
          Check_nginx
          ;;
          10)
          Check_php
          ;;
		  11)
          Check_port
          ;;
          12)
          exit 0
          ;;
          *)
          echo "Usage $0 : {1|2|3|4|5|6|7|8|9|10|11}"
          sleep 1
          continue
    esac
done
}
main