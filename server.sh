#!/bin/bash
date=`date +%F`
path="/backup"
log_path="/tmp/${date}-checkerror.log"
num=`find $path -type f -name "${date}*.tar.gz" | wc -l`
retval=0
if [ -f /tmp/error.log ]
then
	mv /tmp/error.log $log_path
fi

if [ $num -eq 0 ]
then
	echo "No today backup,please,check!"
	exit 1
fi
cd $path;for i in `ls ${path}/*.log`
do
	md5sum -c $i 1>> /tmp/error.log 2>> /dev/null
	if [ $? -ne 0 ]
	then
		retval+=1	
	fi
done
echo
if [ $retval -eq 0 ]
then
	echo "All ok."
else
	echo "---------Error---------"
	cat /tmp/error.log | grep "FAILED"
fi