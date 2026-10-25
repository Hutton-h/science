#!/bin/bash
set -Eeuo pipefail
export LANG=C

DOMAIN="s.hutton.dpdns.org"
EXPECTED_IP="170.178.174.97"
SCI="/root/science"
TOKEN=""
SUBPORT=""
WORK=""
TRANSACTION=0
COMMITTED=0
NGINX_STOPPED=0
GENERATED_PW=0
PANEL_USER=""
PANEL_PW=""
CONF="/home/web/conf.d/${DOMAIN}.conf"
CERT="/home/web/certs/${DOMAIN}_cert.pem"
KEY="/home/web/certs/${DOMAIN}_key.pem"
HTPASSWD="/home/web/conf.d/.htpasswd_science"
PATHS=()

fail() { echo "错误：$*" >&2; exit 1; }

restore_one() {
  local path="$1" index="$2" tmp
  if [ -f "$WORK/present/$index" ]; then
    tmp="${path}.rollback.$$"
    cp -a "$WORK/backup/$index" "$tmp" && mv -f "$tmp" "$path"
  else
    rm -f "$path"
  fi
}

cleanup() {
  local rc=$? i
  trap - EXIT
  set +e
  if [ "$NGINX_STOPPED" = 1 ]; then
    docker start nginx >/dev/null 2>&1 || { echo "严重：请立即执行 docker start nginx" >&2; rc=1; }
    NGINX_STOPPED=0
  fi
  if [ "$TRANSACTION" = 1 ] && [ "$COMMITTED" = 0 ]; then
    for i in "${!PATHS[@]}"; do restore_one "${PATHS[$i]}" "$i" || rc=1; done
    if ! { docker exec nginx nginx -t >/dev/null 2>&1 && docker exec nginx nginx -s reload >/dev/null 2>&1; }; then
      echo "严重：配置已尝试回滚，请执行 docker exec nginx nginx -t 检查" >&2
      rc=1
    fi
    [ "$rc" -ne 0 ] && echo "未完成：已恢复原 Nginx/证书/凭据文件。" >&2
  fi
  [ -z "$WORK" ] || rm -rf "$WORK"
  if [ "$rc" -eq 0 ] && [ "$COMMITTED" != 1 ]; then rc=1; fi
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cmd in docker curl python3 openssl sha256sum flock crontab timeout; do command -v "$cmd" >/dev/null 2>&1 || fail "缺少命令：$cmd"; done
[ "$(id -u)" = 0 ] || fail "请用 root 执行"
[ -d /home/web ] || fail "未找到 kejilion 的 /home/web"
mkdir -p /home/web/conf.d /home/web/certs /etc/letsencrypt
for d in /home/web /home/web/conf.d /home/web/certs; do [ -d "$d" ] && [ ! -L "$d" ] || fail "目录不安全：$d"; done
for p in "$CONF" "$CERT" "$KEY" "$HTPASSWD" "$SCI/panel_user" "$SCI/panel_pass"; do
  [ ! -L "$p" ] || fail "目标不能是符号链接：$p"
  [ ! -e "$p" ] || [ -f "$p" ] || fail "目标不是普通文件：$p"
done

docker ps --format '{{.Names}}' | grep -Fxq nginx || fail "Docker nginx 未运行；请先启动 kejilion 的 nginx 容器"
[ "$(docker inspect -f '{{.HostConfig.NetworkMode}}' nginx)" = host ] || fail "kejilion nginx 必须是 host 网络"
mounts=$(docker inspect -f '{{range .Mounts}}{{printf "%s|%s\n" .Source .Destination}}{{end}}' nginx)
printf '%s\n' "$mounts" | grep -Fxq '/home/web/conf.d|/etc/nginx/conf.d' || fail "nginx 缺少 conf.d 挂载"
printf '%s\n' "$mounts" | grep -Fxq '/home/web/certs|/etc/nginx/certs' || fail "nginx 缺少 certs 挂载"
docker exec nginx nginx -t >/dev/null 2>&1 || fail "现有 Nginx 配置已损坏，未作修改"

public_ip=$(curl -fsS4m10 https://api.ipify.org 2>/dev/null || curl -fsS4m10 https://icanhazip.com 2>/dev/null || true)
public_ip=$(printf '%s' "$public_ip" | tr -d '[:space:]')
[ "$public_ip" = "$EXPECTED_IP" ] || fail "本机公网 IP 不是 $EXPECTED_IP，请在正确的美国 VPS 执行"

dns_json=$(curl -fsS --max-time 15 -H 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=${DOMAIN}&type=A" 2>/dev/null || curl -fsS --max-time 15 "https://dns.google/resolve?name=${DOMAIN}&type=A" 2>/dev/null || true)
[ -n "$dns_json" ] || fail "公共 DNS 查询失败"
dns_ips=$(python3 -c 'import json,sys; d=json.load(sys.stdin); print("\n".join(x.get("data","") for x in d.get("Answer",[]) if x.get("type")==1))' <<<"$dns_json") || fail "DNS 返回格式异常"
printf '%s\n' "$dns_ips" | grep -Fxq "$EXPECTED_IP" || fail "$DOMAIN 的公共 DNS 未解析到 $EXPECTED_IP；禁止使用 /etc/hosts 绕过"

[ -s "$SCI/subtoken.log" ] || fail "缺少原订阅 Token"
[ -s "$SCI/subport.log" ] || fail "缺少原订阅端口"
[ -s "$SCI/jhsub.txt" ] || fail "缺少 $SCI/jhsub.txt"
[ -s "$SCI/sbargotoken.log" ] || fail "缺少固定 Argo Token，未作修改"
TOKEN=$(tr -d '\r\n' < "$SCI/subtoken.log")
SUBPORT=$(tr -d '\r\n' < "$SCI/subport.log")
[[ "$TOKEN" =~ ^[A-Za-z0-9_-]+$ ]] || fail "订阅 Token 格式异常"
[[ "$SUBPORT" =~ ^[0-9]+$ ]] && [ "$SUBPORT" -ge 1 ] && [ "$SUBPORT" -le 65535 ] || fail "订阅端口异常"
[ -s "/root/websbx/$TOKEN/jhsub.txt" ] || fail "订阅目录中没有 jhsub.txt"
cmp -s "$SCI/jhsub.txt" "/root/websbx/$TOKEN/jhsub.txt" || fail "本地发布文件与原订阅不一致"

backend=$(mktemp)
if ! curl -fsS --max-time 8 "http://127.0.0.1:${SUBPORT}/${TOKEN}/jhsub.txt" -o "$backend"; then
  rm -f "$backend"
  if command -v busybox-extras >/dev/null 2>&1; then HTTPD=busybox-extras; else HTTPD=busybox; fi
  command -v "$HTTPD" >/dev/null 2>&1 || fail "busybox 后端未运行且找不到 $HTTPD"
  nohup "$HTTPD" httpd -f -p "0.0.0.0:${SUBPORT}" -h /root/websbx >/root/science/busybox-httpd.log 2>&1 &
  sleep 2
  backend=$(mktemp)
  curl -fsS --max-time 8 "http://127.0.0.1:${SUBPORT}/${TOKEN}/jhsub.txt" -o "$backend" || fail "busybox 后端仍不可读"
fi
cmp -s "$SCI/jhsub.txt" "$backend" || fail "busybox 返回内容与原订阅不一致"
rm -f "$backend"

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q '^Status: active'; then
  ufw allow 80/tcp >/dev/null
  ufw allow 443/tcp >/dev/null
elif command -v iptables >/dev/null 2>&1; then
  for p in 80 443; do iptables -C INPUT -p tcp --dport "$p" -j ACCEPT >/dev/null 2>&1 || iptables -A INPUT -p tcp --dport "$p" -j ACCEPT; done
fi

cert_pair_valid() {
  local cert="$1" key="$2" host="$3" start a b c
  [ -f "$cert" ] && [ -f "$key" ] || return 1
  openssl x509 -in "$cert" -noout -checkend 0 >/dev/null 2>&1 || return 1
  openssl pkey -in "$key" -noout -passin pass: >/dev/null 2>&1 || return 1
  start=$(openssl x509 -in "$cert" -noout -startdate 2>/dev/null) || return 1
  start=$(date -u -d "${start#notBefore=}" +%s 2>/dev/null) || return 1
  [ "$start" -le "$(date -u +%s)" ] || return 1
  openssl x509 -in "$cert" -noout -checkhost "$host" 2>/dev/null | grep -q 'does match' || return 1
  a=$(mktemp); b=$(mktemp); c=$(mktemp)
  if ! { openssl x509 -in "$cert" -pubkey -noout >"$a" 2>/dev/null && openssl pkey -pubin -in "$a" -outform DER >"$b" 2>/dev/null && openssl pkey -in "$key" -pubout -outform DER >"$c" 2>/dev/null; }; then
    rm -f "$a" "$b" "$c"; return 1
  fi
  cmp -s "$b" "$c"; local rc=$?
  rm -f "$a" "$b" "$c"
  return "$rc"
}

atomic_copy() {
  local src="$1" dst="$2" mode="$3" tmp
  tmp=$(mktemp "$(dirname "$dst")/.skpl-publish.XXXXXX")
  cp "$src" "$tmp"
  chmod "$mode" "$tmp"
  mv -f "$tmp" "$dst"
}

WORK=$(mktemp -d /home/web/.skpl-us-https.XXXXXX)
chmod 700 "$WORK"
mkdir -p "$WORK/backup" "$WORK/present"
[ ! -L /home/web/certs/.kpanel-certificate.lock ] || fail "证书锁路径不安全"
exec 9>/home/web/certs/.kpanel-certificate.lock
flock -w 30 9 || fail "另一个证书任务正在运行"
PATHS=("$CONF" "$CERT" "$KEY" "$HTPASSWD" "$SCI/panel_user" "$SCI/panel_pass")
for i in "${!PATHS[@]}"; do
  if [ -e "${PATHS[$i]}" ]; then cp -a "${PATHS[$i]}" "$WORK/backup/$i"; : > "$WORK/present/$i"; fi
done
TRANSACTION=1

LIVE_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
LIVE_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
if cert_pair_valid "$CERT" "$KEY" "$DOMAIN"; then
  echo "复用现有有效证书"
elif [ -e "/home/web/certs/${DOMAIN}.custom" ]; then
  fail "检测到失效的自定义证书，未覆盖；请通过 kejilion 更新该证书"
else
  if ! cert_pair_valid "$LIVE_CERT" "$LIVE_KEY" "$DOMAIN"; then
    echo "预拉取 certbot/certbot，并使用 kejilion standalone + ECDSA 申请"
    docker pull certbot/certbot >/dev/null
    docker stop nginx >/dev/null
    NGINX_STOPPED=1
    if ! timeout 300 docker run --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone --cert-name "$DOMAIN" -d "$DOMAIN" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa; then
      fail "Certbot 申请失败；请检查 80 端口和公共 DNS"
    fi
    docker start nginx >/dev/null
    NGINX_STOPPED=0
    cert_pair_valid "$LIVE_CERT" "$LIVE_KEY" "$DOMAIN" || fail "Certbot 输出未通过域名/有效期/公私钥校验"
  fi
  atomic_copy "$LIVE_CERT" "$CERT" 644
  atomic_copy "$LIVE_KEY" "$KEY" 600
fi

if [ ! -s "$HTPASSWD" ]; then
  if [ -s "$SCI/panel_user" ] && [ -s "$SCI/panel_pass" ]; then
    PANEL_USER=$(tr -d '\r\n' < "$SCI/panel_user")
    PANEL_PW=$(tr -d '\r\n' < "$SCI/panel_pass")
  else
    PANEL_USER="admin"
    [ ! -s "$SCI/panel_user" ] || PANEL_USER=$(tr -d '\r\n' < "$SCI/panel_user")
    PANEL_PW=$(openssl rand -hex 12)
    GENERATED_PW=1
    printf '%s\n' "$PANEL_USER" > "$WORK/panel_user"
    printf '%s\n' "$PANEL_PW" > "$WORK/panel_pass"
    atomic_copy "$WORK/panel_user" "$SCI/panel_user" 600
    atomic_copy "$WORK/panel_pass" "$SCI/panel_pass" 600
  fi
  [[ "$PANEL_USER" =~ ^[A-Za-z0-9_.-]+$ ]] && [ -n "$PANEL_PW" ] || fail "已有面板凭据格式异常"
  PW_HASH=$(printf '%s' "$PANEL_PW" | openssl passwd -apr1 -stdin)
  printf '%s:%s\n' "$PANEL_USER" "$PW_HASH" > "$WORK/htpasswd"
  atomic_copy "$WORK/htpasswd" "$HTPASSWD" 600
else
  echo "复用现有面板 htpasswd，不覆盖原账号密码"
fi

cat > "$WORK/nginx.conf" <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN;
    ssl_certificate /etc/nginx/certs/${DOMAIN}_cert.pem;
    ssl_certificate_key /etc/nginx/certs/${DOMAIN}_key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    location ~ ^/(?:[^/]+/)?status\.json\$ {
        auth_basic "Science Panel";
        auth_basic_user_file /etc/nginx/conf.d/.htpasswd_science;
        rewrite ^/(.*)\$ /${TOKEN}/\$1 break;
        proxy_pass http://127.0.0.1:${SUBPORT};
        proxy_set_header Host \$host;
    }
    location ~ \.(?:yaml|json|txt)\$ {
        auth_basic off;
        rewrite ^/(.*)\$ /${TOKEN}/\$1 break;
        proxy_pass http://127.0.0.1:${SUBPORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    location / {
        auth_basic "Science Panel";
        auth_basic_user_file /etc/nginx/conf.d/.htpasswd_science;
        rewrite ^/(.*)\$ /${TOKEN}/\$1 break;
        proxy_pass http://127.0.0.1:${SUBPORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX
atomic_copy "$WORK/nginx.conf" "$CONF" 644
docker exec nginx nginx -t
docker exec nginx nginx -s reload
sleep 2

https_out=$(mktemp)
curl -fsS --max-time 20 "https://${DOMAIN}/jhsub.txt" -o "$https_out" || fail "HTTPS 原订阅下载失败"
cmp -s "$SCI/jhsub.txt" "$https_out" || fail "HTTPS 原订阅内容与本地不一致"
rm -f "$https_out"
for path in /index.html /status.json; do
  code=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' "https://${DOMAIN}${path}")
  [ "$code" = 401 ] || fail "$path 未认证访问应返回 401，实际为 $code"
done

COMMITTED=1
TRANSACTION=0

# 仅安装/升级可识别摘要的 kejilion 官方续签脚本；自定义脚本保留但不宣称已验证。
configure_renewal() {
  local renewal=/root/auto_cert_renewal.sh digest tmp cron_tmp
  local current=3a63b9e0c1557fae9e18983a8eee284476a946a811c11b3076535aab1432e0d0
  cron_tmp=$(mktemp)
  { crontab -l 2>/dev/null || true; } | grep -v '#science-panel-renew' > "$cron_tmp" || true
  crontab "$cron_tmp" || { rm -f "$cron_tmp"; return 1; }
  rm -f "$cron_tmp"
  if [ -e "$renewal" ]; then
    [ -f "$renewal" ] && [ ! -L "$renewal" ] || return 1
    digest=$(sha256sum "$renewal" | awk '{print $1}')
    case "$digest" in
      "$current") ;;
      ffc714440b503d5f8ee082006f31cc0b59b1c3fd8a1d015257a6cf5944153e83|b117c82fe949d23c745902f633bd343cd13d8a929bb17dd51534fb12af46669d|90ec47433699bc981c5a146b9853ab1ed220540abbb553bd373e87c42615c7d1)
        pgrep -f -- "$renewal" >/dev/null 2>&1 && return 1
        tmp=$(mktemp /root/.auto_cert_renewal.XXXXXX)
        curl -fsS --max-time 40 -H 'Accept: application/vnd.github.raw' 'https://api.github.com/repos/kejilion/sh/contents/auto_cert_renewal.sh?ref=main' -o "$tmp" || { rm -f "$tmp"; return 1; }
        [ "$(sha256sum "$tmp" | awk '{print $1}')" = "$current" ] || { rm -f "$tmp"; return 1; }
        chmod 700 "$tmp"
        mv -f "$tmp" "$renewal"
        ;;
      *) echo "提示：检测到自定义续签脚本，已保留未改；其续签安全性未验证。"; return 2 ;;
    esac
  else
    tmp=$(mktemp /root/.auto_cert_renewal.XXXXXX)
    curl -fsS --max-time 40 -H 'Accept: application/vnd.github.raw' 'https://api.github.com/repos/kejilion/sh/contents/auto_cert_renewal.sh?ref=main' -o "$tmp" || { rm -f "$tmp"; return 1; }
    [ "$(sha256sum "$tmp" | awk '{print $1}')" = "$current" ] || { rm -f "$tmp"; return 1; }
    chmod 700 "$tmp"
    mv -f "$tmp" "$renewal"
  fi
  grep -q '.kpanel-certificate.lock' "$renewal" && grep -q 'flock' "$renewal" || return 1
  if ! { crontab -l 2>/dev/null || true; } | grep -q 'auto_cert_renewal.sh'; then
    cron_tmp=$(mktemp)
    { { crontab -l 2>/dev/null || true; }; echo '0 0 * * * ~/auto_cert_renewal.sh'; } > "$cron_tmp"
    crontab "$cron_tmp" || { rm -f "$cron_tmp"; return 1; }
    rm -f "$cron_tmp"
  fi
}

if configure_renewal; then
  echo "kejilion 官方续签策略已核验；旧 science-panel-renew 已移除"
else
  renewal_rc=$?
  [ "$renewal_rc" = 2 ] || fail "HTTPS 已就绪，但官方续签脚本未能安全安装/升级；请勿手动覆盖自定义脚本"
fi

[ "$GENERATED_PW" = 0 ] || { echo "新面板账号：$PANEL_USER"; echo "新面板密码：$PANEL_PW"; }
echo "美国 HTTPS 前置核验通过：https://$DOMAIN/jhsub.txt 内容与本地一致，/index.html 和 /status.json 未认证均为 401。"
echo "这只是订阅入口与配置验证，不代表节点已经连通。"
