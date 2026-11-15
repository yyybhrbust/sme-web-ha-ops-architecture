#!/bin/bash
# Zabbix 监控中心：mariadb + zabbix-server + zabbix-web(nginx/php-fpm) + agent + 告警脚本
set -e
echo "== Zabbix role =="

# 安装 Zabbix 官方仓库（RHEL 10：7.0 LTS）
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/10/x86_64/zabbix-release-latest.el10.noarch.rpm
dnf clean all >/dev/null 2>&1
dnf install -y zabbix-server-mysql zabbix-web-mysql zabbix-nginx-conf zabbix-agent2 mariadb-server >/dev/null 2>&1 \
  || { echo "ZABBIX_INSTALL_FAIL"; exit 1; }
systemctl enable --now mariadb

# 初始化 Zabbix 数据库
mysql <<'SQL'
create database if not exists zabbix character set utf8mb4 collate utf8mb4_bin;
create user if not exists 'zabbix'@'localhost' identified by 'Zabbix@2026';
grant all privileges on zabbix.* to 'zabbix'@'localhost';
SQL
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p'Zabbix@2026' zabbix

sed -i "s/^# DBPassword=.*/DBPassword=Zabbix@2026/" /etc/zabbix/zabbix_server.conf

# 前端 nginx 配置：80 端口
if [ -f /etc/nginx/conf.d/zabbix.conf ]; then
  sed -i 's/listen 8080;/listen 80;/' /etc/nginx/conf.d/zabbix.conf
  sed -i 's/server_name example.com;/server_name 192.168.10.200;/' /etc/nginx/conf.d/zabbix.conf
fi

# 防火墙补 10051
firewall-cmd --permanent --add-port=10051/tcp 2>/dev/null || true
firewall-cmd --reload || true

systemctl enable --now zabbix-server zabbix-agent2 php-fpm nginx

# 告警脚本（企业微信机器人 webhook）
cat > /usr/lib/zabbix/alertscripts/wechat.sh <<'WX'
#!/bin/bash
# $1=webhook url  $2=主题  $3=消息
curl -s -H 'Content-Type: application/json' \
  -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"[$2] $3\"}}" \
  "$1" > /dev/null
WX
chmod +x /usr/lib/zabbix/alertscripts/wechat.sh

echo "ZABBIX_DONE"
