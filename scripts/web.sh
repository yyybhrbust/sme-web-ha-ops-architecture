#!/bin/bash
# Web1 业务服务器：nginx + php-fpm + mariadb(业务库) + zabbix-agent2 + 备份自动化
set -e
echo "== Web1 role =="

# Zabbix 官方源（7.0 LTS el10）后再装 agent
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/10/x86_64/zabbix-release-latest.el10.noarch.rpm 2>/dev/null || true
dnf install -y nginx php-fpm mariadb-server zabbix-agent2 rsync >/dev/null 2>&1
systemctl enable --now nginx php-fpm mariadb

echo "Welcome to Web1 - 192.168.10.101" > /usr/share/nginx/html/index.html

# 业务数据库（毕设演示用）
mysql <<'SQL'
create database if not exists appdb character set utf8mb4;
create user if not exists 'app'@'localhost' identified by 'App@2026';
grant all privileges on appdb.* to 'app'@'localhost';
SQL

# Zabbix agent 指向监控中心
sed -i 's/^Server=.*/Server=192.168.10.200/' /etc/zabbix/zabbix_agent2.conf
sed -i 's/^ServerActive=.*/ServerActive=192.168.10.200/' /etc/zabbix/zabbix_agent2.conf
sed -i 's/^Hostname=.*/Hostname=web1/' /etc/zabbix/zabbix_agent2.conf
echo 'UserParameter=nginx.status,ss -tln | grep -c ":80 "' > /etc/zabbix/zabbix_agent2.d/nginx.conf
systemctl enable --now zabbix-agent2

# 备份脚本 + 定时任务 + 远程同步（LB-Master 作备份机）
mkdir -p /backup /scripts
cat > /scripts/backup.sh <<'BACK'
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M)
tar -czf /backup/web_$DATE.tar.gz /usr/share/nginx/html
mysqldump -uapp -p'App@2026' appdb > /backup/appdb_$DATE.sql 2>/dev/null
find /backup -name 'web_*' -mtime +7 -delete
find /backup -name 'appdb_*' -mtime +7 -delete
rsync -avz --delete /backup/ root@192.168.10.10:/backup/ >> /var/log/backup.log 2>&1
echo "[$(date)] backup done" >> /var/log/backup.log
BACK
chmod +x /scripts/backup.sh

[ -f /root/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519 -q
(crontab -l 2>/dev/null | grep -v backup.sh; echo "0 2 * * * /bin/bash /scripts/backup.sh > /dev/null 2>&1") | crontab -

echo "WEB1_DONE"
