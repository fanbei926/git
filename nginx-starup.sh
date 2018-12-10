#!/bin/bash
# chkconfig: 2345 20 80
# description: nginxd start stop restart reload
. /etc/init.d/functions
pid_file="/application/nginx-1.12.2/logs/nginx.pid"

function start () {
    nginx &> /dev/null
    retval=$?
    if [[ $retval = 0 ]]; then
        action "Start success" /bin/true
    else
        action "Start fail" /bin/false
    fi
}
function stop () {
    nginx -s stop &> /dev/null
    retval=$?
    if [[ $retval = 0 ]]; then
        action "Stop success" /bin/true
    else
        action "Stop fail" /bin/false
    fi
}
function reload () {
    nginx -s reload &> /dev/null
    retval=$?
    if [[ $retval = 0 ]]; then
        action "Reload success" /bin/true
    else
        action "Reload fail" /bin/false
    fi
}


case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        sleep 1
        start
    ;;
    reload)
        reload
    ;;
    *)
    echo "Usage $0 : {start|stop|restart|reload}"
    exit 1
esac