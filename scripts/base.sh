#!/bin/bash
# 基础配置：主机名、静态IP、SELinux permissive、防火墙放行、时区、基础工具
# 用法: bash base.sh <hostname> <ip>
set -e
HOST=$1
IP=$2
GW=192.168.10.2
echo "== base config: $HOST $IP =="

hostnamectl set-hostname "$HOST"

# 禁用源镜像残留的不可达仓库（nodesource），避免 dnf 卡死
dnf config-manager --set-disabled nodesource-nodejs nodesource-nsolid 2>/dev/null || \
  sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/nodesource*.repo 2>/dev/null || true

# 找到非 loopback 的活动网卡
IF=$(ip -o link show | awk -F': ' '{print $2}' | grep -Ev '^(lo|virbr)' | head -1)
CONN=$(nmcli -t -f NAME,DEVICE con show | grep ":$IF" | head -1 | cut -d: -f1)
[ -z "$CONN" ] && CONN=$(nmcli -t -f NAME con show | head -1)
echo "NIC=$IF CONN=$CONN"

# NAT 网关为 192.168.10.2（VMware NAT 设备）；.1 是宿主机虚拟网卡，不通外网
nmcli con mod "$CONN" ipv4.method manual ipv4.addresses "$IP/24" ipv4.gateway "$GW" ipv4.dns "$GW 114.114.114.114"
nmcli con up "$CONN" || true
ip addr show | grep "inet $IP" && echo "IP_OK: $IP"
ping -c 2 -W 3 "$GW" >/dev/null 2>&1 && echo "GW_OK: $GW" || echo "GW_WARN"

# SELinux permissive（毕设环境；生产应 enforcing）
setenforce 0 || true
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# 防火墙：保持开启，放行 http / zabbix agent / VRRP
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=http 2>/dev/null || true
firewall-cmd --permanent --add-port=10050/tcp 2>/dev/null || true
firewall-cmd --permanent --add-rich-rule='rule protocol value="vrrp" accept' 2>/dev/null || true
firewall-cmd --reload || true

timedatectl set-timezone Asia/Shanghai

dnf install -y chrony vim wget tar rsync net-tools >/dev/null 2>&1 || true
systemctl enable --now chronyd || true

echo "BASE_DONE $HOST $IP"
