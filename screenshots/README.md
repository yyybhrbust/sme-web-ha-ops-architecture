# 验证截图目录

本目录 22 张 PNG 均为 **2026-11-15 在真实运行环境中采集**（VMware Workstation + RHEL 10 + 4 台虚拟机）。

| 文件 | 内容 | 采集位置 |
| :--- | :--- | :--- |
| `01-vms_running.png` | 四台虚拟机运行状态（vmrun list） | 宿主机 |
| `04-1_subscription.png` | RHEL 10 订阅状态与软件仓库 | lb-master |
| `05-1_base_config.png` | 主机名 / 静态 IP / SELinux / 防火墙 / 时区 | web1 |
| `06-2_keepalived_arp.png` | Keepalived 免费 ARP（VIP 通告）日志 | lb-master |
| `06-3_keepalived_conf.png` | Keepalived 主备配置（priority 100 / 90） | lb-master |
| `07-1_web_page.png` | Web1 业务页面与站点目录 | web1 |
| `07-2_backup_crontab.png` | 备份脚本 / Crontab / 备份产物 | web1 |
| `08-3_zabbix_db.png` | Zabbix 数据库初始化（204 张表） | zabbix |
| `09-1_zabbix_dashboard.png` | Zabbix 全局视图仪表盘（0 告警） | 浏览器 |
| `09-2_zabbix_hosts.png` | 主机列表：lb-master / lb-backup / web1 全部 ZBX 绿 | 浏览器 |
| `09-3_zabbix_latest.png` | 最新数据（监控项采集值） | 浏览器 |
| `09-4_zabbix_actions.png` | 告警动作「告警通知-企业微信」 | 浏览器 |
| `09-5_zabbix_media.png` | 报警媒介「企业微信机器人」 | 浏览器 |
| `09-6_service_ports.png` | Zabbix 服务状态与监听端口 | zabbix |
| `10-1_lb_access.png` | 通过 VIP 访问业务（负载均衡生效） | lb-backup |
| `10-2a_vip_on_master.png` | 切换前：VIP 绑定在 LB-Master | lb-master |
| `10-2b_vip_master_down.png` | 主节点故障：VIP 漂移至 LB-Backup，业务不中断 | lb-backup |
| `10-2c_vip_back_to_master.png` | 主节点恢复：VIP 自动抢占回 LB-Master | lb-master |
| `10-6a_backup_web1.png` | web1 本地备份与定时任务 | web1 |
| `10-6b_backup_remote.png` | lb-master 远程备份机（rsync 同步结果，两端一致） | lb-master |
| `10-7_dr_drill.png` | 灾难恢复演练：删站 403 → 恢复后 200 | web1 |
| `10-8_ab_result.png` | ApacheBench 压测：2000 请求 / 0 失败 / 1558.82 req/s | web1 |

> 说明：`04-*`～`10-8_*` 中的命令行为**真实 SSH 执行的命令与原始输出**，为便于放入报告渲染为终端窗口样式；`09-1`～`09-5` 为浏览器真实截图。
