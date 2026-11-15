#!/bin/bash
# Zabbix 7.0 API：注册主机 + 监控项 + 触发器 + 告警媒介 + 动作（修复版）
set -e
ZBX=http://127.0.0.1/api_jsonrpc.php
show() { python3 -c "import sys,json;d=json.load(sys.stdin);print(json.dumps(d.get('result') if 'result' in d else d.get('error'),ensure_ascii=False))"; }

TOKEN=$(curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d '{"jsonrpc":"2.0","method":"user.login","params":{"username":"Admin","password":"zabbix"},"id":1}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"])')
echo "1) LOGIN OK"

TMPL=$(curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"template.get\",\"params\":{\"output\":[\"templateid\"],\"filter\":{\"host\":[\"Linux by Zabbix agent\"]}},\"auth\":\"$TOKEN\",\"id\":2}" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"][0]["templateid"])')
echo "2) TEMPLATE=$TMPL"

# 已注册主机（lb-master/lb-backup/web1），只获取 web1 的 hostid 与 interfaceid
HID=$(curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"host.get\",\"params\":{\"output\":[\"hostid\"],\"selectInterfaces\":[\"interfaceid\"],\"filter\":{\"host\":[\"web1\"]}},\"auth\":\"$TOKEN\",\"id\":4}" \
  | python3 -c 'import sys,json;d=json.load(sys.stdin);r=d["result"][0];print(r["hostid"]+":"+r["interfaces"][0]["interfaceid"])')
WID=${HID%%:*}; IID=${HID##*:}
echo "3) web1 hostid=$WID interfaceid=$IID"

# 4) 自定义监控项 nginx.status（type 0=被动 agent，需 interfaceid）
echo -n "4) ITEM: "
curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"item.create\",\"params\":{\"name\":\"Nginx 80 端口存活数\",\"key_\":\"nginx.status\",\"hostid\":\"$WID\",\"interfaceid\":\"$IID\",\"type\":0,\"value_type\":3,\"delay\":\"30s\"},\"auth\":\"$TOKEN\",\"id\":5}" | show

# 5) 触发器：nginx.status=0 -> 严重
echo -n "5) TRIGGER: "
curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"trigger.create\",\"params\":{\"description\":\"Web1 Nginx 服务宕机\",\"priority\":4,\"expression\":\"last(/web1/nginx.status)=0\"},\"auth\":\"$TOKEN\",\"id\":6}" | show

# 6) 告警媒介：企业微信机器人（Script）
echo -n "6) MEDIATYPE: "
curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"mediatype.create\",\"params\":{\"name\":\"企业微信机器人\",\"type\":1,\"exec_path\":\"/usr/lib/zabbix/alertscripts/wechat.sh\",\"exec_params\":\"{ALERT.SENDTO}\\n{ALERT.SUBJECT}\\n{ALERT.MESSAGE}\",\"status\":0},\"auth\":\"$TOKEN\",\"id\":7}" | show

# 7) Admin 绑定媒介（webhook 占位，需替换为真实企业微信机器人地址）
UID2=$(curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"user.get\",\"params\":{\"output\":[\"userid\"],\"filter\":{\"username\":[\"Admin\"]}},\"auth\":\"$TOKEN\",\"id\":8}" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"][0]["userid"])')
MEDIA=$(curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"mediatype.get\",\"params\":{\"output\":[\"mediatypeid\"],\"filter\":{\"name\":[\"企业微信机器人\"]}},\"auth\":\"$TOKEN\",\"id\":9}" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"][0]["mediatypeid"])')
echo -n "7) USER MEDIA: "
curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"user.update\",\"params\":{\"userid\":\"$UID2\",\"medias\":[{\"mediatypeid\":\"$MEDIA\",\"sendto\":\"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=REPLACE_WITH_YOUR_WECHAT_WEBHOOK\",\"active\":0,\"severity\":\"63\",\"period\":\"1-7,00:00-24:00\"}]},\"auth\":\"$TOKEN\",\"id\":10}" | show

# 8) 动作：触发器告警 -> 通知 Admin（企业微信）
echo -n "8) ACTION: "
curl -s -X POST $ZBX -H 'Content-Type: application/json-rpc' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"action.create\",\"params\":{\"name\":\"告警通知-企业微信\",\"eventsource\":0,\"status\":0,\"filter\":{\"evaltype\":1,\"conditions\":[{\"conditiontype\":16,\"operator\":0,\"value\":\"5\"}]},\"operations\":[{\"operationtype\":0,\"opmessage\":{\"default_msg\":1,\"mediatypeid\":\"$MEDIA\"},\"opmessage_grp\":[{\"usrgrpid\":\"7\"}]}]},\"auth\":\"$TOKEN\",\"id\":11}" | show

echo "API_ALL_DONE"
