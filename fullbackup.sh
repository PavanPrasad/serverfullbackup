#Script for taking full backup of server
echo "Whitelist this server IP in firewall of backup server 95.xxx.xx.xxx in-order to complete the remote copying"
csf -a 95.xxx.xx.xxx
dblist="mysqldblist"
if [ -f "$dblist" ]; then
  echo "File "$dblist" exists. Please recheck the same."
  exit
else
  echo " "
fi
echo "Enter password of the backup server 95.xxx.xx.xxx"
read P
PASS=$P
IP=`hostname -i`
mkdir -p /backup/$IP-Fullback/dbs;
mkdir -p /backup/$IP-Fullback/domains/
mkdir -p /backup/$IP-Fullback/log
echo "show databases" | mysql -uroot > mysqldblist
for i in `cat mysqldblist`; do mysqldump $i -u root > /backup/$IP-Fullback/dbs/$i.sql 2>/backup/$IP-Fullback/errors.log;echo /backup/$IP-Fullback/dbs/$i.sql; done && tar czvf /backup/$IP-Fullback/dbs.tar.gz /backup/$IP-Fullback/dbs
if [ -f /backup/$IP-Fullback/dbs.tar.gz ];
then
rm -rf /backup/$IP-Fullback/dbs
  else
  exit 1
fi
for i in `cat /etc/trueuserdomains | cut -d ":" -f2`
do
  /scripts/pkgacct $i  /backup/$IP-Fullback/domains/ 2>/backup/$IP-Fullback/errors.log
done

cp -r /var/log  /backup/$IP-Fullback/log
cp -r /backup/logbackup /backup/$IP-Fullback/log
cp -r /usr/local/apache /backup/$IP-Fullback/
cp -r `php --ini| grep Loaded | cut -d ":" -f2` /backup/$IP-Fullback/
cp -r /var/spool/cron /backup/$IP-Fullback/
cp -r /usr/local/scripts /backup/$IP-Fullback/
#cp -r /root/scripts/* scripts/

#---ssh check---#

nc -z -v -w5 95.xxx.xx.xxx 52xx
if [ "$?" -ne 0 ]; then
echo "Connection to 95.xxx.xx.xxx on port 52xx failed"
  exit 1
else
  echo "Connection to 95.xxx.xx.xxx on port 5252 succeeded"

echo "---------Copying started-------------"


remotecopy () {
expect -c "
spawn scp -rP52xx -o StrictHostKeyChecking=no /backup/$IP-Fullback root@95.xxx.xx.xxx:/BACKUP/FULLBACKUP/
expect {
              \"*assword:\" {
                             send \"$PASS\r\"
                             interact
                             }
}
"
exit
}

A=`rpm -qa | grep expect`
B=`echo $?`
if [ $B == 0 ]
then
remotecopy
else
yum -y install expect
remotecopy
fi 
exit 0
fi
