#!/bin/bash
# Zabbix 告警脚本：企业微信机器人
# 参数：$1=webhook url  $2=主题  $3=消息
curl -s -H 'Content-Type: application/json' \
  -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"[$2] $3\"}}" \
  "$1" > /dev/null
