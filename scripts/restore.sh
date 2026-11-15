#!/bin/bash
# 从最新备份恢复网站目录（灾难恢复演练第 3 步）
LATEST=$(ls -t /backup/web_*.tar.gz | head -1)
echo "restoring: $LATEST"
tar -xzf "$LATEST" -C /
echo "--- after restore ---"
ls -l /usr/share/nginx/html/
