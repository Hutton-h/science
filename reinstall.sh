#!/bin/bash
set -Eeuo pipefail
export LANG=C

SCI=/root/science
US_IP=170.178.174.97
HK_IP=38.76.210.194
US_DOMAIN=s.hutton.dpdns.org
HK_DOMAIN=h.hutton.dpdns.org
ARGO_DOMAIN=sss.hutton.dpdns.org
AGG_URL='https://api.github.com/repos/Hutton-h/science/contents/agg.sh?ref=main'
AGG_SHA256=337af5695189c64e27ab8056ebea88ecdb800853deefbb05a20c08f2f51e46fd
VERIFY_ONLY="${VERIFY_ONLY:-0}"
ROLE=""
DOMAIN=""
WORK=""
BACKUP=""
INSTALL_OK=0
ALLOW_ROLLBACK=0
CRON_CHANGED=0

fail() { echo "错误：$*" >&2; exit 1; }

restore_files() {
  [ -n "$BACKUP" ] && [ -f "$BACKUP/paths" ] || return 0
  local src saved
  while IFS= read -r src; do
    saved="$BACKUP/files$src"
    [ -e "$saved" ] || continue
    if [ -d "$saved" ]; then
      mkdir -p "$src"
      cp -a "$saved/." "$src/"
    else
      mkdir -p "$(dirname "$src")"
      cp -a "$saved" "$src"
    fi
  done < "$BACKUP/paths"
}

cleanup() {
  local rc=$? role="$ROLE"
  trap - EXIT
  set +e
  if [ "$ALLOW_ROLLBACK" = 1 ] && [ "$INSTALL_OK" = 0 ] && [ -n "$BACKUP" ] && [ -f "$BACKUP/paths" ]; then
    echo "正在恢复重建前配置……" >&2
    restore_files || rc=1
    if command -v systemctl >/dev/null 2>&1; then
      systemctl restart xr sb >/dev/null 2>&1 || true
      systemctl restart argo >/dev/null 2>&1 || true
    else
      rc-service xray restart >/dev/null 2>&1 || true
      rc-service sing-box restart >/dev/null 2>&1 || true
      rc-service argo restart >/dev/null 2>&1 || true
    fi
    if [ "$role" = hk ] && [ -x "$SCI/hk_relay.sh" ]; then "$SCI/hk_relay.sh" >/dev/null 2>&1 || true; fi
    if [ "$role" = us ] && [ -f "$SCI/aggregate.py" ]; then python3 "$SCI/aggregate.py" >/dev/null 2>&1 || true; fi
    echo "已执行回滚，备份位于：$BACKUP" >&2
  fi
  if [ "$CRON_CHANGED" = 1 ] && [ -n "$BACKUP" ] && [ -f "$BACKUP/crontab.before" ]; then
    crontab "$BACKUP/crontab.before" >/dev/null 2>&1 || rc=1
    if [ "$INSTALL_OK" = 1 ]; then
      if [ "$role" = us ]; then
        (crontab -l 2>/dev/null | grep -v 'python3 /root/science/aggregate.py'; echo '*/2 * * * * python3 /root/science/aggregate.py >> /root/science/aggregate.log 2>&1 #science-aggregate') | crontab - || rc=1
      else
        (crontab -l 2>/dev/null | grep -v '/root/science/hk_relay.sh'; echo '*/2 * * * * /root/science/hk_relay.sh >/dev/null 2>&1 #science-hk-relay') | crontab - || rc=1
      fi
    fi
  fi
  [ -z "$WORK" ] || rm -rf "$WORK"
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cmd in curl python3 docker sha256sum crontab iptables ss; do command -v "$cmd" >/dev/null 2>&1 || fail "缺少命令：$cmd"; done
[ "$(id -u)" = 0 ] || fail "请用 root 执行"
case "$VERIFY_ONLY" in 0|1) ;; *) fail "VERIFY_ONLY 只能为 0 或 1" ;; esac
[ -d "$SCI" ] || fail "未找到现有 $SCI；这是保留配置的重建脚本，不是首次安装脚本"

ip=$(curl -fsS4m10 https://api.ipify.org 2>/dev/null || curl -fsS4m10 https://icanhazip.com 2>/dev/null || true)
ip=$(printf '%s' "$ip" | tr -d '[:space:]')
if [ -z "$ip" ] && [ -s "$SCI/server_ip.log" ]; then ip=$(head -1 "$SCI/server_ip.log" | tr -d '[]'); fi
case "$ip" in
  "$US_IP") ROLE=us; DOMAIN="$US_DOMAIN" ;;
  "$HK_IP") ROLE=hk; DOMAIN="$HK_DOMAIN" ;;
  *) fail "本机公网 IP 不是已登记的美国或香港 VPS：${ip:-空}" ;;
esac

check_dns() {
  local domain="$1" expected="$2" json
  json=$(curl -fsS --max-time 15 -H 'accept: application/dns-json' "https://1.1.1.1/dns-query?name=${domain}&type=A") || fail "$domain 公共 DoH 查询失败"
  DOMAIN="$domain" EXPECTED="$expected" python3 -c 'import json,os,sys; d=json.load(sys.stdin); ips=[x.get("data") for x in d.get("Answer",[]) if x.get("type")==1]; print(os.environ["DOMAIN"],"->",",".join(ips)); sys.exit(0 if os.environ["EXPECTED"] in ips else 1)' <<<"$json" || fail "$domain 公共 DNS 未解析到 $expected"
}
check_dns "$US_DOMAIN" "$US_IP"
check_dns "$HK_DOMAIN" "$HK_IP"
if [ "$ROLE" = us ]; then
  argo_ips=$(curl -fsS --max-time 15 -H 'accept: application/dns-json' "https://1.1.1.1/dns-query?name=${ARGO_DOMAIN}&type=A" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(" ".join(x.get("data","") for x in d.get("Answer",[]) if x.get("type")==1))')
  [ -n "$argo_ips" ] || fail "$ARGO_DOMAIN 未解析到 Cloudflare Tunnel"
fi

docker ps --format '{{.Names}}' | grep -Fxq nginx || fail "kejilion Docker nginx 未运行"
[ "$(docker inspect -f '{{.HostConfig.NetworkMode}}' nginx)" = host ] || fail "Docker nginx 不是 host 网络"
docker exec nginx nginx -t >/dev/null 2>&1 || fail "现有 Docker Nginx 配置检查失败"

for f in subtoken.log subport.log uuid; do [ -s "$SCI/$f" ] || fail "缺少 $SCI/$f，不能保留原配置重建"; done
if [ "$ROLE" = us ]; then
  for f in sbargotoken.log sbargoym.log port_vm_ws; do [ -s "$SCI/$f" ] || fail "缺少 Argo 保留配置 $f"; done
  curl -fsS --max-time 20 "https://$US_DOMAIN/jhsub.txt" -o /dev/null || fail "重建前美国 HTTPS 原订阅不可用"
else
  for f in relaylib.py discover_relay.py publish_relay.py hk_relay.sh; do [ -s "$SCI/$f" ] || fail "缺少香港中转组件 $f"; done
  for f in relay.txt relay-manifest.json SKPL-LIFT.txt; do curl -fsS --max-time 20 "https://$HK_DOMAIN/$f" -o /dev/null || fail "重建前香港 HTTPS $f 不可用"; done
fi

TOKEN=$(tr -d '\r\n' < "$SCI/subtoken.log")
SUBPORT=$(tr -d '\r\n' < "$SCI/subport.log")
[[ "$TOKEN" =~ ^[A-Za-z0-9_-]+$ ]] || fail "订阅 Token 格式异常"
[[ "$SUBPORT" =~ ^[0-9]+$ ]] || fail "订阅端口格式异常"
WEB="/root/websbx/$TOKEN"
[ -d "$WEB" ] || fail "缺少订阅发布目录"

fingerprint() {
  # 只核验必须保留的凭据/端口/面板与 Nginx 配置；重装会合法更新 *.sh/*.py/xr.json/sb.json 等生成物。
  {
    for f in "$SCI/uuid" "$SCI/subtoken.log" "$SCI/subport.log" "$SCI"/port_* "$SCI/sbargotoken.log" "$SCI/sbargoym.log" "$SCI/panel_user" "$SCI/panel_pass" "/home/web/conf.d/$DOMAIN.conf" "/home/web/certs/${DOMAIN}_cert.pem" "/home/web/certs/${DOMAIN}_key.pem" /home/web/conf.d/.htpasswd_science; do
      if [ -f "$f" ]; then sha256sum "$f"; else echo "MISSING $f"; fi
    done
  } | sha256sum | awk '{print $1}'
}

BACKUP="$SCI/backup/reinstall-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP/files"
chmod 700 "$BACKUP"
: > "$BACKUP/paths"
for f in "$SCI"/*.json "$SCI"/*.log "$SCI"/port_* "$SCI"/*.sh "$SCI/name" "$SCI/uuid" "$SCI/cert.crt" "$SCI/private.key" "$SCI/SHA256.txt" "$SCI/xrk" "$SCI/sbk" "/home/web/conf.d/$DOMAIN.conf" "/home/web/certs/${DOMAIN}_cert.pem" "/home/web/certs/${DOMAIN}_key.pem" /home/web/conf.d/.htpasswd_science; do
  if [ -e "$f" ]; then
    mkdir -p "$(dirname "$BACKUP/files$f")"
    cp -a "$f" "$BACKUP/files$f"
    printf '%s\n' "$f" >> "$BACKUP/paths"
  fi
done
BEFORE_FINGERPRINT=$(fingerprint)
printf '%s\n' "$BEFORE_FINGERPRINT" > "$BACKUP/fingerprint.before"
crontab -l 2>/dev/null > "$BACKUP/crontab.before" || : > "$BACKUP/crontab.before"
WORK=$(mktemp -d /tmp/science-reinstall.XXXXXX)
chmod 700 "$WORK"
curl -fsSL --max-time 60 -H 'Accept: application/vnd.github.raw' "$AGG_URL" -o "$WORK/agg.sh" || fail "agg.sh 下载失败"
printf '%s  %s\n' "$AGG_SHA256" "$WORK/agg.sh" | sha256sum -c - >/dev/null || fail "agg.sh 摘要与已审核版本不一致"
bash -n "$WORK/agg.sh" || fail "agg.sh 语法检查失败"

if [ "$VERIFY_ONLY" != 1 ]; then
  ALLOW_ROLLBACK=1
  if [ "$ROLE" = us ]; then
    CRON_CHANGED=1
    (crontab -l 2>/dev/null | grep -v 'python3 /root/science/aggregate.py') | crontab - || fail "暂停聚合 cron 失败"
    echo "开始美国保留配置重建；UUID、端口、Token 和 Argo 配置保持不变"
    AGK=$(cat "$SCI/sbargotoken.log")
    export AGK HK_BASE="https://$HK_DOMAIN" US_TOKEN="$TOKEN"
    bash "$WORK/agg.sh" || fail "美国重建失败，开始回滚"
    unset AGK US_TOKEN
  else
    CRON_CHANGED=1
    (crontab -l 2>/dev/null | grep -v '/root/science/hk_relay.sh') | crontab - || fail "暂停香港中转 cron 失败"
    echo "开始香港保留配置重建；UUID、端口和订阅 Token 保持不变"
    export US_BASE="https://$US_DOMAIN"
    bash "$WORK/agg.sh" || fail "香港重建失败，开始回滚"
    unset US_BASE
  fi
else
  echo "VERIFY_ONLY=1：不重建节点，只执行配置、发布和真实拨测验复"
fi

[ -x "$SCI/xray" ] || fail "缺少 Xray"
[ -x "$SCI/sing-box" ] || fail "缺少 sing-box"
"$SCI/xray" run -test -c "$SCI/xr.json" || fail "Xray 配置检查失败"
"$SCI/sing-box" check -c "$SCI/sb.json" || fail "sing-box 配置检查失败"
docker exec nginx nginx -t || fail "Docker Nginx 配置检查失败"
AFTER_FINGERPRINT=$(fingerprint)
[ "$AFTER_FINGERPRINT" = "$BEFORE_FINGERPRINT" ] || fail "UUID、端口、Token、面板或 Nginx 凭据发生变化"

if [ "$ROLE" = us ]; then
  curl -fsS --max-time 20 "https://$US_DOMAIN/jhsub.txt" -o "$WORK/public-jhsub.txt" || fail "重建后美国 HTTPS 原订阅下载失败"
  cmp -s "$SCI/jhsub.txt" "$WORK/public-jhsub.txt" || fail "重建后美国 HTTPS 原订阅与本地不一致"
  pgrep -f 'science/cloudflared' >/dev/null || fail "cloudflared 未运行"
  ARGO_PORT=$(cat "$SCI/port_vm_ws")
  ss -H -lnt "sport = :$ARGO_PORT" | grep -q . || fail "Argo 当前回源端口没有 VMess 监听"
  UUID=$(cat "$SCI/uuid")
  code=$(curl -sS --max-time 20 -o /dev/null -w '%{http_code}' "https://$ARGO_DOMAIN/${UUID}-vm")
  case "$code" in 400|426) ;; *) fail "Argo 回源检查应返回 400/426，实际为 $code" ;; esac
  for f in SKPL-LIFT-private.js last_good/SKPL-LIFT-private.js; do
    code=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' "https://$US_DOMAIN/$f")
    [ "$code" = 401 ] || fail "$f 未登录访问应返回 401，实际为 $code"
  done
  [ -f "$WEB/SKPL-LIFT-all-base64.txt" ] || fail "缺少全体 Base64 总订阅"
  curl -fsS --max-time 20 "https://$US_DOMAIN/SKPL-LIFT-all-base64.txt" -o "$WORK/all-base64.txt" || fail "全体 Base64 总订阅下载失败"
  cmp -s "$WEB/SKPL-LIFT-all-base64.txt" "$WORK/all-base64.txt" || fail "全体 Base64 总订阅与本地不一致"
  [ -f "$WEB/SKPL-LIFT-private.js" ] || fail "缺少单节点复制数据"
  grep -q 'SKPL-LIFT-private.js' "$SCI/panel.html" && grep -q 'family_base64' "$SCI/panel.html" || fail "面板不是包含单节点复制和全体总订阅的版本"
else
  curl -fsS --max-time 20 "https://$US_DOMAIN/jhsub.txt" -o "$WORK/us.txt" || fail "无法读取美国原订阅"
  python3 "$SCI/discover_relay.py" "$WORK/us.txt" > "$WORK/mapping.txt" || fail "美国端口映射发现失败"
  iptables -t nat -S PREROUTING > "$WORK/prerouting.txt"
  python3 - "$WORK/mapping.txt" "$WORK/prerouting.txt" "$US_IP" <<'PY'
import shlex,sys
expected={}
for line in open(sys.argv[1]):
    p=line.split()
    if len(p)==2: expected[p[0]]=p[1]
if not expected: raise SystemExit("没有预期中转映射")
seen={}
for raw in open(sys.argv[2]):
    p=shlex.split(raw)
    if "--dport" not in p or "-j" not in p or p[p.index("-j")+1]!="DNAT" or "--to-destination" not in p: continue
    hk=p[p.index("--dport")+1]
    if hk not in {str(x) for x in range(8443,8454)}: continue
    proto=p[p.index("-p")+1] if "-p" in p else ""
    if proto not in ("tcp","udp"): continue
    key=(hk,proto)
    if key in seen: raise SystemExit("检测到重复 DNAT：%s/%s"%key)
    seen[key]=p[p.index("--to-destination")+1]
for hk,us in expected.items():
    for proto in ("tcp","udp"):
        if seen.get((hk,proto))!=sys.argv[3]+":"+us: raise SystemExit("实际 DNAT 缺失或目标错误：%s/%s"%(hk,proto))
for (hk,proto),target in seen.items():
    if hk not in expected or target!=sys.argv[3]+":"+expected[hk]: raise SystemExit("检测到残留错误 DNAT：%s/%s"%(hk,proto))
print("实际 TCP/UDP DNAT 核验通过：%d 条映射"%len(expected))
PY
  for f in relay.txt relay-manifest.json SKPL-LIFT.txt; do
    curl -fsS --max-time 20 "https://$HK_DOMAIN/$f" -o "$WORK/public-$f" || fail "重建后香港 HTTPS $f 下载失败"
    cmp -s "$WEB/$f" "$WORK/public-$f" || fail "重建后香港 HTTPS $f 与本地不一致"
  done
  for path in / /index.html /status.json; do
    code=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' "https://$HK_DOMAIN$path")
    [ "$code" = 404 ] || fail "香港非白名单路径 $path 应返回 404，实际为 $code"
  done
fi

INSTALL_OK=1
echo "配置与发布检查通过，开始真实逐节点拨测；备份位于：$BACKUP"
set +e
RUN_ID=post-reinstall NODECHECK=1 bash "$WORK/agg.sh"
node_rc=$?
set -e
[ "$node_rc" = 0 ] || fail "重建已完成，但真实拨测执行失败，请检查 /root/science/nodecheck-$ROLE.json"
python3 - "$SCI/nodecheck-$ROLE.json" <<'PY'
import json,sys
p=sys.argv[1]
d=json.load(open(p))
s=d.get("summary",{})
print("真实拨测：total=%s ok=%s fallback_ok=%s failed=%s"%(s.get("total"),s.get("ok"),s.get("fallback_ok"),s.get("failed")))
if s.get("failed"):
    print("以下节点未通过（不代表需要再次重装）：")
    for n in d.get("nodes",[]):
        if n.get("status")=="failed": print("- %s (%s:%s) %s"%(n.get("name"),n.get("proto"),n.get("port"),n.get("error")))
    sys.exit(3)
print("本次所有被测节点均通过真实 HTTPS 拨测")
PY
probe_rc=$?
if [ "$probe_rc" != 0 ]; then
  echo "重建完成，但仍有节点未通过真实拨测；请把 /root/science/nodecheck-$ROLE.json 发来，不要连续重装。" >&2
  exit "$probe_rc"
fi
echo "本机负责的重建与拨测检查完成：$ROLE"
