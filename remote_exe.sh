#!/bin/bash
function Exe_command () {
#执行远程命令
while true
do
	read -p "Please enter your command : " com
	if [ ! "$com" ]
	then
		echo "You put nothing.retry."
		continue
	fi
	remote_command=$com
	$ssh_con "$remote_command"
	if [ $? -ne 0 ]
	then
		echo "Execute remote ssh command has error,please check."
		continue
	fi
	echo "Execute success."
	read -p "Do you want to retry?[Y/N] " com
	if [ "$com" = 'Y' ]
	then
		continue
	else
		echo "Return main."
		sleep 2
		main
	fi
done
}
function Generate_sshkey () {
#免密执行ssh命令
	if [ -f /root/.ssh/id_rsa ]
	then
		rm -fr /root/.ssh/id_rsa*
	fi
	#创建公钥
	ssh-keygen -N "" -t rsa -f /root/.ssh/id_rsa &> /dev/null
	#传输公钥
	sshpass -p${remote_password} ssh-copy-id -i /root/.ssh/id_rsa.pub "${remote_user}@${remote_ip} -o \
	StrictHostKeyChecking=no -p ${remote_port}" &> /dev/null
	if [ $? -ne 0 ]
	then
		"SSH configure has error,please check."
		exit 1
	fi
	echo "SSH configure has create."
	$ssh_con "$remote_command"
	if [ $? -ne 0 ]
	then
		"Remote ssh command has error,please check."
		exit 1
	fi
	sleep 2
	main
}
function Transfer_file () {
#scp远程拷贝文件
	while true
	do
		read -p "Please enter local configure file's path : " com
		if [ ! "$com" ]
		then
			continue
		fi
		if [ -d "$com" ]
		then
			echo "It's folder,please enter file."
			continue
		fi
		if [ -f "$com" ]
		then
			while true
			do
				echo "Please enter remote configure file's path."
				read -p "(If you enter nothing ,it will be the same with your local file.) : " com1
				if [ ! "$com1" ]
				then
					echo "Note : the same with local file."
					com1=$com
					break
				fi
				temp=`$ssh_con "[ -f $com1 ] && echo 'yes' || echo 'no'"`
				if [[ "$temp" = 'no' ]]
				then
					echo "Remote server does not have this file."
					continue
				elif [[ "$temp" = 'yes' ]]
				then
					echo "Remote server have this file."
					break
				else
					echo "Execute error."
					exit 1
				fi
			done
		
			echo "Now backup this file."
			$ssh_con "cp $com ${com}.bak"
			echo "Now start copy."
			scp -P $remote_port $com ${remote_user}@${remote_ip}:$com1
			if [ $? -ne 0 ]
			then
				echo "Execute error."
				exit 1	
			fi
			echo "Execute success,now return."
			sleep 2
			main
		else
			echo "Can not find this file."
			continue
		fi
	done
}
function Reload_service () {
#一般性重启服务
	while true
	do
		read -p "Do you want to reload the service ?[Y/N]" com
		if [ "$com" = 'Y' ]
		then
			while true
			do
				read -p "Please enter service name : " service
				if [ ! "$service" ]
				then
					continue
				fi
				$ssh_con "/etc/init.d/${service} reload"
				if [ $? -ne 0 ]
				then
					echo "Execute error."
					continue
				else
					echo "Execute success."
					break
				fi
			done
		else
			break
		fi
	done
	echo "Now return."
	sleep 2
	main
}
function main () {
	remote_ip="118.24.114.83"
	remote_port="114"
	remote_user="root"
	remote_password="fanfan926"
	remote_command="hostname"
	ssh_con="ssh ${remote_user}@${remote_ip} -p ${remote_port}"

	clear
	while true
	do
	cat << EOF
 1.Generate ssh key.
 2.Execute command.
 3.Transfer file.
 4.Reload service.
 5.Exit.
EOF
		read -p "Please enter your choice : " i
		case "$i" in
			1)
			Generate_sshkey
			;;
			2)
			Exe_command
			;;
			3)
			Transfer_file
			;;
			4)
			Reload_service
			;;
			5)
			echo "Bye."
			exit 0
			;;
			*)
			echo "Usage $0 : {1|2|3|4|5}"
			continue
		esac
	done
}
main