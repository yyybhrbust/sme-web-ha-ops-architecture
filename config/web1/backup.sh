#!/bin/bash
# Web1 业务服务器定时备份脚本（网站目录 + 业务库，RSYNC 同步至远程备份机）
DATE=$(date +%Y%m%d-%H%M)

# 1) 打包网站目录
tar -czf /backup/web_$DATE.tar.gz /usr/share/nginx/html
# 2) 备份业务数据库
mysqldump -uapp -p'App@2026' appdb > /backup/appdb_$DATE.sql 2>/dev/null
# 3) 清理 7 天前的过期备份
find /backup -name 'web_*'   -mtime +7 -delete
find /backup -name 'appdb_*' -mtime +7 -delete
# 4) 首次执行时预置远程备份机主机密钥（避免 Host key verification failed）
grep -q '192.168.10.10' /root/.ssh/known_hosts 2>/dev/null || \
  ssh-keyscan -t ed25519 192.168.10.10 2>/dev/null >> /root/.ssh/known_hosts
# 5) 同步到远程备份机（LB-Master）
rsync -avz --delete /backup/ root@192.168.10.10:/backup/ >> /var/log/backup.log 2>&1
echo "[$(date)] backup done" >> /var/log/backup.log
