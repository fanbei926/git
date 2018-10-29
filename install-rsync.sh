yum install -y nfs-utils rpcbind
mkdir /data
echo "/data 10.0.0.0/24(rw,sync,all_squash)" > /etc/exports
/etc/init.d/rpcbind start
/etc/init.d/nfs start
# cat >/server/scripts/inotify.sh<<'EOF'
# #!/bin/bash
# inotifywait -mrq /data --timefmt "%F %H:%M:%S" --format "%T %w%f 事件信息：%e" -e create,moved_to,delete,close_write | \
# while read line
# do
# 	rsync az /data/ rsyncd_backup@10.0.0.128::backup --password-file=/etc/rsync.password
# done
# EOF
# sh /server/scripts/inotify.sh &
