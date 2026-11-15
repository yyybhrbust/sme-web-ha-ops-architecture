#!/bin/bash
# 负载均衡器角色：nginx 反向代理 + keepalived 主备
# 用法: bash lb.sh master|backup
set -e
ROLE=$1
echo "== LB role: $ROLE =="

dnf install -y nginx keepalived >/dev/null 2>&1
# Zabbix agent（来自官方源 7.0 LTS el10，失败不中断）
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/10/x86_64/zabbix-release-latest.el10.noarch.rpm 2>/dev/null || true
dnf install -y zabbix-agent2 >/dev/null 2>&1 && echo "agent2 installed" || echo "agent2 skipped"

# --- Nginx 反向代理/负载均衡 ---
cat > /etc/nginx/nginx.conf <<'NGINX'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    upstream backend_servers {
        server 192.168.10.101:80 weight=1;
        server 192.168.10.102:80 weight=1;
    }
    server {
        listen 80;
        server_name 192.168.10.100;
        location / {
            proxy_pass http://backend_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
NGINX
nginx -t && systemctl enable --now nginx

# --- Keepalived ---
if [ "$ROLE" = "master" ]; then
  RID=LB_MASTER; STATE=MASTER; PRIO=100
else
  RID=LB_BACKUP; STATE=BACKUP; PRIO=90
fi
IF=$(ip -o link show | awk -F': ' '{print $2}' | grep -Ev '^(lo|virbr)' | head -1)
cat > /etc/keepalived/keepalived.conf <<KEEP
global_defs {
   router_id $RID
}
vrrp_instance VI_1 {
    state $STATE
    interface $IF
    virtual_router_id 51
    priority $PRIO
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.10.100/24
    }
}
KEEP
systemctl enable --now keepalived
sleep 2
echo "== $ROLE DONE =="
ip addr show | grep -E 'inet (192\.168\.10\.(10|20|100))' || true
