#!/bin/bash
export LANG=en_US.UTF-8
# Science 一键申请IP证书脚本（自动停/启 nginx，全程无交互）
# 用法：bash <(curl -Ls https://raw.githubusercontent.com/Hutton-h/science/main/getcert.sh)
IP="${1:-$(curl -s4m5 -k https://icanhazip.com 2>/dev/null)}"
[ -z "$IP" ] && IP="$(curl -s6m5 -k https://icanhazip.com 2>/dev/null)"
echo "=========================================="
echo "Science 一键IP证书申请"
echo "目标IP：$IP"
echo "=========================================="

# 1. 安装 acme.sh（如未安装）
if [ ! -f /root/.acme.sh/acme.sh ]; then
  echo "安装 acme.sh……"
  curl -Ls https://get.acme.sh | sh
fi

# 2. 释放80端口（自动识别 docker / systemd / service 的 nginx）
echo "释放80端口……"
RESTART=""
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^nginx$'; then
  docker stop nginx >/dev/null 2>&1
  RESTART="docker start nginx"
elif command -v systemctl >/dev/null 2>&1 && systemctl is-active nginx >/dev/null 2>&1; then
  systemctl stop nginx >/dev/null 2>&1
  RESTART="systemctl start nginx"
elif command -v service >/dev/null 2>&1 && service nginx status >/dev/null 2>&1; then
  service nginx stop >/dev/null 2>&1
  RESTART="service nginx start"
else
  pkill nginx >/dev/null 2>&1
  RESTART=""
fi
sleep 2

# 3. 申请IP证书
echo "申请IP证书中（约10-30秒）……"
/root/.acme.sh/acme.sh --issue --standalone -d "$IP" --keylength ec-256 --server letsencrypt >/tmp/acme_issue.log 2>&1

# 4. 安装证书到 /root/ygkkkca
mkdir -p /root/ygkkkca
CERTDIR="/root/.acme.sh/${IP}_ecc"
if [ -f "$CERTDIR/fullchain.cer" ] && [ -f "$CERTDIR/$IP.key" ]; then
  cp "$CERTDIR/fullchain.cer" /root/ygkkkca/cert.crt
  cp "$CERTDIR/$IP.key" /root/ygkkkca/private.key
  echo "$IP" > /root/ygkkkca/ca.log
  echo "✅ 证书申请成功！已安装到 /root/ygkkkca/"
else
  echo "❌ 证书申请失败，日志如下："
  tail -20 /tmp/acme_issue.log
fi

# 5. 恢复 nginx
if [ -n "$RESTART" ]; then
  echo "恢复 nginx……"
  eval "$RESTART" >/dev/null 2>&1
fi
echo "=========================================="
echo "证书处理完毕。若申请成功，接下来运行："
echo "all=y alns=y bash <(curl -Ls https://raw.githubusercontent.com/Hutton-h/science/main/science.sh) rep"
echo "=========================================="
