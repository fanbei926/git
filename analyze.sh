#!/bin/bash
logdate=`date -d "yesterday" +%F`
log_path="/application/nginx/logs/$logdate-www_access.log"

maketime=`date +%F_%H:%M`

total_visit=`wc -l ${log_path} | awk '{print $1}'`

total_bandwidth=`awk -v total=0 '{total+=$10}END{print total/1024}' ${log_path}`

total_unique=`awk '{ip[$1]++}END{print asort(ip)}' ${log_path}`

ip_pv=`awk '{ip[$1]++}END{for (k in ip){print ip[k],k}}' ${log_path} | sort -rn | head -20`

url_num=`awk '{url[$7]++}END{for (k in url){print url[k],k}}' ${log_path} | sort -rn | head -20`

#referer=`awk -v domain=$domain '$11 !~ /http:\/\/[^/]*'"$domain"'/{url[$11]++}END{for (k in url){print url[k],k}}' ${log_path} | sort -rn | head -20`

notfound=`awk '$9~/404/ {url[$7]++}END{for (k in url){print url[k],k}}' ${log_path} | sort -rn | head -20`


echo "概况"
echo "报告生成时间：${maketime}"
echo
echo "总访问量:${total_visit}"
echo "总带宽:${total_bandwidth}K"
echo
echo "独立访客:${total_unique}"
echo -e "访问IP统计:\n${ip_pv}\n"
echo -e "访问url统计:\n${url_num}\n"
echo -e "404统计:\n${notfound}"