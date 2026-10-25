#!/bin/bash
set -Eeuo pipefail
export LANG=C

DOMAIN="h.hutton.dpdns.org"
EXPECTED_IP="38.76.210.194"
US_IP="170.178.174.97"
US_BASE="https://s.hutton.dpdns.org"
SCI="/root/science"
TOKEN=""
SUBPORT=""
WORK=""
TRANSACTION=0
COMMITTED=0
NGINX_STOPPED=0
CONF="/home/web/conf.d/${DOMAIN}.conf"
CERT="/home/web/certs/${DOMAIN}_cert.pem"
KEY="/home/web/certs/${DOMAIN}_key.pem"
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
      echo "严重：Nginx 回滚后检查失败，请执行 docker exec nginx nginx -t" >&2
      rc=1
    fi
    [ "$rc" -ne 0 ] && echo "HTTPS 配置未完成，已尝试恢复原配置；中转核验结果请查看上方。" >&2
  fi
  [ -z "$WORK" ] || rm -rf "$WORK"
  if [ "$rc" -eq 0 ] && [ "$COMMITTED" != 1 ]; then rc=1; fi
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cmd in docker curl python3 openssl sha256sum flock crontab timeout iptables; do command -v "$cmd" >/dev/null 2>&1 || fail "缺少命令：$cmd"; done
[ "$(id -u)" = 0 ] || fail "请用 root 执行"
for f in relaylib.py discover_relay.py publish_relay.py hk_relay.sh; do [ -s "$SCI/$f" ] || fail "缺少现有中转组件 $f；不要用完整 agg.sh 重装香港"; done
[ -s "$SCI/subtoken.log" ] && [ -s "$SCI/subport.log" ] || fail "缺少香港订阅 Token/端口"
TOKEN=$(tr -d '\r\n' < "$SCI/subtoken.log")
SUBPORT=$(tr -d '\r\n' < "$SCI/subport.log")
[[ "$TOKEN" =~ ^[A-Za-z0-9_-]+$ ]] || fail "订阅 Token 格式异常"
[[ "$SUBPORT" =~ ^[0-9]+$ ]] && [ "$SUBPORT" -ge 1 ] && [ "$SUBPORT" -le 65535 ] || fail "订阅端口异常"
WEB="/root/websbx/$TOKEN"
[ -d "$WEB" ] && [ -s "$WEB/SKPL-LIFT.txt" ] || fail "缺少香港订阅目录或直连订阅文件"
python3 -m py_compile "$SCI/relaylib.py" "$SCI/discover_relay.py" "$SCI/publish_relay.py"
bash -n "$SCI/hk_relay.sh"

public_ip=$(curl -fsS4m10 https://api.ipify.org 2>/dev/null || curl -fsS4m10 https://icanhazip.com 2>/dev/null || true)
public_ip=$(printf '%s' "$public_ip" | tr -d '[:space:]')
[ "$public_ip" = "$EXPECTED_IP" ] || fail "本机公网 IP 不是 $EXPECTED_IP，请在正确的香港 VPS 执行"

dns_json=$(curl -fsS --max-time 15 -H 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=${DOMAIN}&type=A" 2>/dev/null || curl -fsS --max-time 15 "https://dns.google/resolve?name=${DOMAIN}&type=A" 2>/dev/null || true)
[ -n "$dns_json" ] || fail "公共 DNS 查询失败"
dns_ips=$(python3 -c 'import json,sys; d=json.load(sys.stdin); print("\n".join(x.get("data","") for x in d.get("Answer",[]) if x.get("type")==1))' <<<"$dns_json") || fail "DNS 返回格式异常"
printf '%s\n' "$dns_ips" | grep -Fxq "$EXPECTED_IP" || fail "$DOMAIN 的公共 DNS 未解析到 $EXPECTED_IP；禁止使用 /etc/hosts 绕过"

docker ps --format '{{.Names}}' | grep -Fxq nginx || fail "Docker nginx 未运行"
[ "$(docker inspect -f '{{.HostConfig.NetworkMode}}' nginx)" = host ] || fail "kejilion nginx 必须是 host 网络"
mounts=$(docker inspect -f '{{range .Mounts}}{{printf "%s|%s\n" .Source .Destination}}{{end}}' nginx)
printf '%s\n' "$mounts" | grep -Fxq '/home/web/conf.d|/etc/nginx/conf.d' || fail "nginx 缺少 conf.d 挂载"
printf '%s\n' "$mounts" | grep -Fxq '/home/web/certs|/etc/nginx/certs' || fail "nginx 缺少 certs 挂载"
docker exec nginx nginx -t >/dev/null 2>&1 || fail "现有 Nginx 配置已损坏，未作修改"
[ -d /home/web ] || fail "未找到 kejilion 的 /home/web"
mkdir -p /home/web/conf.d /home/web/certs /etc/letsencrypt
for d in /home/web /home/web/conf.d /home/web/certs; do [ -d "$d" ] && [ ! -L "$d" ] || fail "目录不安全：$d"; done
for p in "$CONF" "$CERT" "$KEY"; do [ ! -L "$p" ] || fail "目标不能是符号链接：$p"; [ ! -e "$p" ] || [ -f "$p" ] || fail "目标不是普通文件：$p"; done

WORK=$(mktemp -d /home/web/.skpl-hk-https.XXXXXX)
chmod 700 "$WORK"
mkdir -p "$WORK/backup" "$WORK/present"
curl -fsS --max-time 20 "$US_BASE/jhsub.txt" -o "$WORK/us.txt" || fail "无法通过有效 HTTPS 拉取美国原订阅；先完成美国步骤"
python3 - "$WORK/us.txt" "$SCI" <<'PY'
import pathlib, sys
sys.path.insert(0, sys.argv[2])
from relaylib import discover, valid
lines=[x.strip() for x in pathlib.Path(sys.argv[1]).read_text(encoding="utf-8",errors="ignore").splitlines() if x.strip()]
if not any(valid(x) for x in lines): raise SystemExit("美国原订阅没有有效直连节点")
if not discover(lines): raise SystemExit("美国原订阅没有发现任何香港中转所需协议")
PY

# 只更新现有恢复脚本的两个值，不执行香港节点重装。
python3 - "$SCI/hk_relay.sh" "$WORK/hk_relay.new" "$US_IP" "$US_BASE" <<'PY'
import pathlib,re,sys
src=pathlib.Path(sys.argv[1]).read_text()
src,n1=re.subn(r'^US_IP=.*$', 'US_IP="'+sys.argv[3]+'"', src, flags=re.M)
src,n2=re.subn(r'^US_BASE=.*$', 'US_BASE="'+sys.argv[4]+'"', src, flags=re.M)
if (n1,n2)!=(1,1): raise SystemExit("hk_relay.sh 中 US_IP/US_BASE 结构异常")
pathlib.Path(sys.argv[2]).write_text(src)
PY
bash -n "$WORK/hk_relay.new"
chmod 700 "$WORK/hk_relay.new"
cp "$SCI/hk_relay.sh" "$WORK/hk_relay.before"
mv -f "$WORK/hk_relay.new" "$SCI/hk_relay.sh"
"$SCI/hk_relay.sh" || fail "中转刷新脚本失败，详见 $SCI/hk_relay.log"

iptables -t nat -S PREROUTING > "$WORK/prerouting.txt"
python3 - "$WORK/us.txt" "$WORK/prerouting.txt" "$SCI" "$WEB" "$US_IP" <<'PY'
import json,pathlib,shlex,sys
sys.path.insert(0,sys.argv[3])
from relaylib import HK_PLAN,discover,parse,relay_line,valid
us_path,rules_path,sci,web,us_ip=sys.argv[1:]
web=pathlib.Path(web); sci=pathlib.Path(sci)
lines=[x.strip() for x in pathlib.Path(us_path).read_text(encoding="utf-8",errors="ignore").splitlines() if x.strip() and valid(x.strip())]
ports=discover(lines)
expected={hk:ports[kw] for hk,kw in HK_PLAN if kw in ports}
if not expected: raise SystemExit("没有预期中转映射")
seen={}
for raw in pathlib.Path(rules_path).read_text().splitlines():
    p=shlex.split(raw)
    if "-A" not in p or p[p.index("-A")+1] != "PREROUTING" or "--dport" not in p or "-j" not in p: continue
    if p[p.index("-j")+1] != "DNAT" or "--to-destination" not in p: continue
    hk=p[p.index("--dport")+1]; proto=p[p.index("-p")+1] if "-p" in p else ""
    if hk not in dict(HK_PLAN) or proto not in ("tcp","udp"): continue
    key=(hk,proto)
    if key in seen: raise SystemExit("检测到重复 DNAT："+hk+"/"+proto)
    seen[key]=p[p.index("--to-destination")+1]
for hk,us in expected.items():
    for proto in ("tcp","udp"):
        if seen.get((hk,proto)) != us_ip+":"+us: raise SystemExit("实际 DNAT 缺失或目标错误："+hk+"/"+proto)
for (hk,proto),target in seen.items():
    if hk not in expected or target != us_ip+":"+expected[hk]: raise SystemExit("检测到残留错误 DNAT："+hk+"/"+proto)
state={}
for raw in (sci/"hk_relay.rules").read_text().splitlines():
    p=raw.split()
    if len(p)!=3 or p[0]!="dnat": raise SystemExit("hk_relay.rules 格式异常")
    if p[1] in state: raise SystemExit("hk_relay.rules 有重复映射")
    state[p[1]]=p[2]
if state != expected: raise SystemExit("hk_relay.rules 与美国实时订阅不一致")
expected_lines=[]; expected_map=[]
for hk,kw in HK_PLAN:
    if hk not in expected: continue
    us=expected[hk]
    src=next((x for x in lines if kw in parse(x)["name"].lower() and parse(x)["port"]==us),None)
    if not src: raise SystemExit("找不到中转源节点："+kw)
    expected_lines.append(relay_line(src,hk))
    expected_map.append({"protocol":kw,"hk_port":int(hk),"us_port":int(us)})
relay=[x.strip() for x in (web/"relay.txt").read_text(encoding="utf-8",errors="ignore").splitlines() if x.strip()]
if relay != expected_lines: raise SystemExit("relay.txt 与实际成功映射不一致")
for line in relay:
    p=parse(line)
    if p["server"]!="38.76.210.194" or "HK中转" not in p["name"]: raise SystemExit("中转订阅地址或分类错误")
manifest=json.loads((web/"relay-manifest.json").read_text())
if manifest.get("mapping")!=expected_map or manifest.get("counts",{}).get("hk_relay")!=len(relay): raise SystemExit("relay-manifest.json 映射或计数不一致")
if manifest.get("stale") is not False or manifest.get("status")!=("ok" if len(relay)==11 else "degraded"): raise SystemExit("中转健康状态异常")
direct=[x.strip() for x in (web/"SKPL-LIFT.txt").read_text(encoding="utf-8",errors="ignore").splitlines() if x.strip()]
if not direct or any(not valid(x) or parse(x)["server"]!="38.76.210.194" or "HK中转" in parse(x)["name"] for x in direct): raise SystemExit("香港直连为空、无效或服务器地址被改成域名")
print("真实 TCP/UDP DNAT、映射、中转订阅和香港直连锁定核验通过：%d 条中转，%d 条直连。"%(len(relay),len(direct)))
PY

cron_tmp=$(mktemp)
{ { crontab -l 2>/dev/null || true; } | grep -v '/root/science/hk_relay.sh' || true; echo '*/2 * * * * /root/science/hk_relay.sh >/dev/null 2>&1 #science-hk-relay'; } > "$cron_tmp"
crontab "$cron_tmp"
rm -f "$cron_tmp"

# 先核对本机 busybox；127.0.0.1 仅供本机 Docker Nginx 回源，不是公开 HTTP 方案。
for name in relay.txt relay-manifest.json SKPL-LIFT.txt; do
  curl -fsS --max-time 8 "http://127.0.0.1:${SUBPORT}/${TOKEN}/${name}" -o "$WORK/backend-$name" || fail "busybox 无法读取 $name"
  cmp -s "$WEB/$name" "$WORK/backend-$name" || fail "busybox 返回的 $name 与磁盘不一致"
done

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q '^Status: active'; then
  ufw allow 80/tcp >/dev/null; ufw allow 443/tcp >/dev/null
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
  if ! { openssl x509 -in "$cert" -pubkey -noout >"$a" 2>/dev/null && openssl pkey -pubin -in "$a" -outform DER >"$b" 2>/dev/null && openssl pkey -in "$key" -pubout -outform DER >"$c" 2>/dev/null; }; then rm -f "$a" "$b" "$c"; return 1; fi
  cmp -s "$b" "$c"; local rc=$?; rm -f "$a" "$b" "$c"; return "$rc"
}
atomic_copy() { local src="$1" dst="$2" mode="$3" tmp; tmp=$(mktemp "$(dirname "$dst")/.skpl-publish.XXXXXX"); cp "$src" "$tmp"; chmod "$mode" "$tmp"; mv -f "$tmp" "$dst"; }

[ ! -L /home/web/certs/.kpanel-certificate.lock ] || fail "证书锁路径不安全"
exec 9>/home/web/certs/.kpanel-certificate.lock
flock -w 30 9 || fail "另一个证书任务正在运行"
PATHS=("$CONF" "$CERT" "$KEY")
for i in "${!PATHS[@]}"; do if [ -e "${PATHS[$i]}" ]; then cp -a "${PATHS[$i]}" "$WORK/backup/$i"; : > "$WORK/present/$i"; fi; done
TRANSACTION=1
LIVE_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
LIVE_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
if cert_pair_valid "$CERT" "$KEY" "$DOMAIN"; then
  echo "复用现有有效证书"
elif [ -e "/home/web/certs/${DOMAIN}.custom" ]; then
  fail "检测到失效的自定义证书，未覆盖"
else
  if ! cert_pair_valid "$LIVE_CERT" "$LIVE_KEY" "$DOMAIN"; then
    docker pull certbot/certbot >/dev/null
    docker stop nginx >/dev/null
    NGINX_STOPPED=1
    if ! timeout 300 docker run --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone --cert-name "$DOMAIN" -d "$DOMAIN" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa; then fail "Certbot 申请失败；请检查 80 端口和公共 DNS"; fi
    docker start nginx >/dev/null
    NGINX_STOPPED=0
    cert_pair_valid "$LIVE_CERT" "$LIVE_KEY" "$DOMAIN" || fail "新证书未通过校验"
  fi
  atomic_copy "$LIVE_CERT" "$CERT" 644
  atomic_copy "$LIVE_KEY" "$KEY" 600
fi

cat > "$WORK/nginx.conf" <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    location = /relay.txt { return 301 https://\$host\$request_uri; }
    location = /relay-manifest.json { return 301 https://\$host\$request_uri; }
    location = /SKPL-LIFT.txt { return 301 https://\$host\$request_uri; }
    location / { return 404; }
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN;
    ssl_certificate /etc/nginx/certs/${DOMAIN}_cert.pem;
    ssl_certificate_key /etc/nginx/certs/${DOMAIN}_key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    auth_basic off;
    location = /relay.txt {
        rewrite ^/(.*)\$ /${TOKEN}/\$1 break;
        proxy_pass http://127.0.0.1:${SUBPORT};
        proxy_set_header Host \$host;
    }
    location = /relay-manifest.json {
        rewrite ^/(.*)\$ /${TOKEN}/\$1 break;
        proxy_pass http://127.0.0.1:${SUBPORT};
        proxy_set_header Host \$host;
    }
    location = /SKPL-LIFT.txt {
        rewrite ^/(.*)\$ /${TOKEN}/\$1 break;
        proxy_pass http://127.0.0.1:${SUBPORT};
        proxy_set_header Host \$host;
    }
    location / { return 404; }
}
NGINX
atomic_copy "$WORK/nginx.conf" "$CONF" 644
docker exec nginx nginx -t
docker exec nginx nginx -s reload
sleep 2
for name in relay.txt relay-manifest.json SKPL-LIFT.txt; do
  curl -fsS --max-time 20 "https://${DOMAIN}/${name}" -o "$WORK/public-$name" || fail "HTTPS 下载 $name 失败"
  cmp -s "$WEB/$name" "$WORK/public-$name" || fail "HTTPS $name 与本地实际发布文件不一致"
  code=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' "http://${DOMAIN}/${name}")
  [ "$code" = 301 ] || fail "HTTP $name 应跳转 HTTPS，实际状态 $code"
done
for path in / /index.html /status.json /jhsub.txt /not-found; do
  code=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' "https://${DOMAIN}${path}")
  [ "$code" = 404 ] || fail "香港非白名单路径应返回 404，实际为 $code"
done
for name in relay.txt SKPL-LIFT.txt; do
  code=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' "https://${DOMAIN}/${TOKEN}/${name}")
  [ "$code" = 404 ] || fail "带订阅 Token 的路径未隐藏"
done

COMMITTED=1
TRANSACTION=0
configure_renewal() {
  local renewal=/root/auto_cert_renewal.sh digest tmp cron_tmp current=3a63b9e0c1557fae9e18983a8eee284476a946a811c11b3076535aab1432e0d0
  cron_tmp=$(mktemp); { crontab -l 2>/dev/null || true; } | grep -v '#science-panel-renew' > "$cron_tmp" || true
  crontab "$cron_tmp" || { rm -f "$cron_tmp"; return 1; }; rm -f "$cron_tmp"
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
        chmod 700 "$tmp"; mv -f "$tmp" "$renewal" ;;
      *) echo "提示：自定义续签脚本已保留未改，其安全性未验证。"; return 2 ;;
    esac
  else
    tmp=$(mktemp /root/.auto_cert_renewal.XXXXXX)
    curl -fsS --max-time 40 -H 'Accept: application/vnd.github.raw' 'https://api.github.com/repos/kejilion/sh/contents/auto_cert_renewal.sh?ref=main' -o "$tmp" || { rm -f "$tmp"; return 1; }
    [ "$(sha256sum "$tmp" | awk '{print $1}')" = "$current" ] || { rm -f "$tmp"; return 1; }
    chmod 700 "$tmp"; mv -f "$tmp" "$renewal"
  fi
  grep -q '.kpanel-certificate.lock' "$renewal" && grep -q 'flock' "$renewal" || return 1
  if ! { crontab -l 2>/dev/null || true; } | grep -q 'auto_cert_renewal.sh'; then
    cron_tmp=$(mktemp); { { crontab -l 2>/dev/null || true; }; echo '0 0 * * * ~/auto_cert_renewal.sh'; } > "$cron_tmp"
    crontab "$cron_tmp" || { rm -f "$cron_tmp"; return 1; }; rm -f "$cron_tmp"
  fi
}
if configure_renewal; then echo "kejilion 官方续签策略已核验"; else rc=$?; [ "$rc" = 2 ] || fail "HTTPS 已就绪，但官方续签脚本未能安全安装/升级"; fi

echo "香港恢复核验通过：真实 DNAT 和三个 HTTPS 文件均已核对，其余路径及 Token 路径为 404。"
echo "这仍不代表美国落地节点已连通；继续执行美国统一步骤。"
