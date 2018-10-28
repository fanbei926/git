#!/bin/bash
yum install -y rpcbind nfs-tools
mkdir -p /data
chown nfsnobody:nfsnobody /data
echo "/data 172.16.1.0/24(rw,sync,all_squash)" > /etc/exports
cd /tmp/;unzip /tmp/sersync_installdir_64bit.zip
mkdir /application
mv /tmp/sersync_installdir_64bit/sersync/ /application/
sed -i 's#createFile start="false"#createFile start="true"#g;s#modify start="false"#modify start="true"#g;s#localpath watch="/opt/tongbu"#localpath watch="/data"#g;s#remote ip="127.0.0.1" name="tongbu1"#remote ip="172.16.1.99" name="backup"#g;s#commonParams params="-artuz"#commonParams params="-az"#g;s#auth start="false" users="root" passwordfile="/etc/rsync.pas"#auth start="false" users="rsync" passwordfile="/etc/rsync.password"#g' /application/sersync/conf/confxml.xml
