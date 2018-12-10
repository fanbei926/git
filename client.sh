#!/bin/bash
date=`date +%F_%H:%M`
src_file="etc/"
src_ip=`ifconfig | awk -F"[ :]+" 'NR==2{print $4}'`
back_path=/test
file_name=${date}-${src_ip}
des_path="backup"
des_ip="118.24.114.83"
rsy_user="rsyncd_backup"
rsy_pass_file="/etc/rsync.password"

if [ ! -d $back_path ]
then
	echo "Create $back_path."
	mkdir -p $back_path
fi
echo "Start tar these files and md5sum."
cd /;tar zcf ${back_path}/${file_name}.tar.gz $src_file &> /dev/null && cd ${back_path};md5sum ${file_name}.tar.gz > ${back_path}/${file_name}.log 2> /dev/null
if [ $? -ne 0 ]
then
	echo "tar or md5 has error"
	exit 1
fi
echo "Delete more then 7 days files."
find ${back_path} -type f -mtime +7 -exec rm -fr {} \;
echo "Start rsync."
rsync -az ${back_path}/* ${rsy_user}@${des_ip}::${des_path} --password-file=${rsy_pass_file}
if [ $? -ne 0 ]
then
	echo "rsync has error"
	exit 1
fi