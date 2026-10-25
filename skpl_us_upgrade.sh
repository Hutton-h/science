#!/bin/bash
set -Eeuo pipefail
export LANG=C

DOMAIN="s.hutton.dpdns.org"
HK_BASE="https://h.hutton.dpdns.org"
EXPECTED_IP="170.178.174.97"
SCI="/root/science"
AGG_SHA256="f887201cf3cd0af9d0f17c6c0f77a2c6babe06e3071ebfbda57a56469a72e0f8"
WORK=""

fail() { echo "错误：$*" >&2; exit 1; }
cleanup() { local rc=$?; trap - EXIT; [ -z "$WORK" ] || rm -rf "$WORK"; exit "$rc"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for cmd in curl python3 docker sha256sum pgrep; do command -v "$cmd" >/dev/null 2>&1 || fail "缺少命令：$cmd"; done
[ "$(id -u)" = 0 ] || fail "请用 root 执行"
for f in subtoken.log subport.log sbargotoken.log sbargoym.log jhsub.txt; do [ -s "$SCI/$f" ] || fail "缺少 $f；先完成美国 HTTPS 前置步骤"; done
TOKEN=$(tr -d '\r\n' < "$SCI/subtoken.log")
SUBPORT=$(tr -d '\r\n' < "$SCI/subport.log")
ARGO_TOKEN=$(cat "$SCI/sbargotoken.log")
WEB="/root/websbx/$TOKEN"
[ -d "$WEB" ] || fail "缺少美国订阅目录"
public_ip=$(curl -fsS4m10 https://api.ipify.org 2>/dev/null || curl -fsS4m10 https://icanhazip.com 2>/dev/null || true)
public_ip=$(printf '%s' "$public_ip" | tr -d '[:space:]')
[ "$public_ip" = "$EXPECTED_IP" ] || fail "本机公网 IP 不是 $EXPECTED_IP"
WORK=$(mktemp -d /root/.skpl-us-upgrade.XXXXXX)
chmod 700 "$WORK"
mkdir -p "$WORK/public" "$WORK/hk"

curl -fsS --max-time 60 -H 'Accept: application/vnd.github.raw' 'https://api.github.com/repos/Hutton-h/science/contents/agg.sh?ref=main' -o "$WORK/agg.sh" || fail "agg.sh 下载失败"
printf '%s  %s\n' "$AGG_SHA256" "$WORK/agg.sh" | sha256sum -c - >/dev/null || fail "agg.sh 摘要与已审核版本不一致，未执行"
bash -n "$WORK/agg.sh"
python3 - "$WORK/agg.sh" "$WORK/relaylib.py" <<'PY'
import pathlib,sys
text=pathlib.Path(sys.argv[1]).read_text()
marker="cat > /root/science/relaylib.py <<'PYLIB'\n"
if marker not in text: raise SystemExit("agg.sh 中找不到 relaylib.py")
body=text.split(marker,1)[1].split("\nPYLIB\n",1)[0]
if not body: raise SystemExit("relaylib.py 提取为空")
pathlib.Path(sys.argv[2]).write_text(body+"\n")
PY
python3 -m py_compile "$WORK/relaylib.py"

curl -fsS --max-time 20 "$HK_BASE/relay.txt" -o "$WORK/hk/relay.txt" || fail "香港 relay.txt 下载失败"
curl -fsS --max-time 20 "$HK_BASE/relay-manifest.json" -o "$WORK/hk/relay-manifest.json" || fail "香港 manifest 下载失败"
curl -fsS --max-time 20 "$HK_BASE/SKPL-LIFT.txt" -o "$WORK/hk/SKPL-LIFT.txt" || fail "香港直连订阅下载失败"
python3 - "$WORK" <<'PY'
import json,pathlib,sys
work=pathlib.Path(sys.argv[1]); sys.path.insert(0,str(work))
from relaylib import HK_PLAN,parse,valid
hk=work/"hk"
relay=[x.strip() for x in (hk/"relay.txt").read_text(encoding="utf-8",errors="ignore").splitlines() if x.strip()]
if not relay: raise SystemExit("香港中转订阅为空")
ports=dict(HK_PLAN); seen=set()
for line in relay:
    p=parse(line)
    if not valid(line) or p["server"]!="38.76.210.194" or p["port"] not in ports or "HK中转" not in p["name"]: raise SystemExit("香港中转订阅有无效节点或错误地址")
    if p["port"] in seen: raise SystemExit("香港中转端口重复")
    seen.add(p["port"])
manifest=json.loads((hk/"relay-manifest.json").read_text())
mapping=manifest.get("mapping",[])
if manifest.get("status") not in ("ok","degraded") or manifest.get("stale") is not False: raise SystemExit("香港 manifest 不是可用的实时状态")
if manifest.get("counts",{}).get("hk_relay")!=len(relay) or len(mapping)!=len(relay): raise SystemExit("香港 manifest 计数不一致")
for item in mapping:
    hkport=str(item.get("hk_port","")); usport=str(item.get("us_port",""))
    if hkport not in seen or ports.get(hkport)!=item.get("protocol") or not usport.isdigit(): raise SystemExit("香港 manifest 映射与订阅不一致")
direct=[x.strip() for x in (hk/"SKPL-LIFT.txt").read_text(encoding="utf-8",errors="ignore").splitlines() if x.strip()]
if not direct or any(not valid(x) or parse(x)["server"]!="38.76.210.194" or "HK中转" in parse(x)["name"] for x in direct): raise SystemExit("香港直连为空、无效或被错误改成域名")
print("升级前香港三个 HTTPS 文件内容核验通过。")
PY

snapshot() { if [ -f "$1" ]; then sha256sum "$1" | awk '{print $1}'; else echo MISSING; fi; }
PANEL_PATHS=("$SCI/subtoken.log" "$SCI/sbargotoken.log" "$SCI/sbargoym.log" "$SCI/panel_user" "$SCI/panel_pass" "/home/web/conf.d/.htpasswd_science")
for i in "${!PANEL_PATHS[@]}"; do snapshot "${PANEL_PATHS[$i]}" > "$WORK/before-$i"; done

# 不在命令行显示 Token；通过环境变量交给已审核的 agg.sh。
export HK_BASE US_IP="170.178.174.97" HK_IP="38.76.210.194" US_DOMAIN="$DOMAIN" PUBLIC_BASE="https://$DOMAIN"
export US_TOKEN="$TOKEN" AGK="$ARGO_TOKEN"
bash "$WORK/agg.sh" || fail "美国完整升级失败；旧节点配置备份位于 /root/science/backup"
unset AGK US_TOKEN
for i in "${!PANEL_PATHS[@]}"; do
  snapshot "${PANEL_PATHS[$i]}" > "$WORK/after-$i"
  cmp -s "$WORK/before-$i" "$WORK/after-$i" || fail "升级改变了必须保留的 Token、Argo 或面板凭据：${PANEL_PATHS[$i]}"
done
[ "$(tr -d '\r\n' < "$SCI/sbargoym.log")" = "sss.hutton.dpdns.org" ] || fail "固定 Argo 域名异常"

[ -x "$SCI/xray" ] || fail "缺少 Xray"
[ -x "$SCI/sing-box" ] || fail "缺少 sing-box"
"$SCI/xray" run -test -c "$SCI/xr.json" || fail "Xray 配置检查失败"
"$SCI/sing-box" check -c "$SCI/sb.json" || fail "sing-box 配置检查失败"
docker exec nginx nginx -t || fail "Docker Nginx 配置检查失败"
pgrep -f 'science/cloudflared' >/dev/null || fail "cloudflared 未运行"

python3 - "$WORK" "$SCI/jhsub.txt" <<'PY'
import pathlib,sys
work=pathlib.Path(sys.argv[1]); sys.path.insert(0,str(work))
from relaylib import parse,vmess_obj
lines=[x.strip() for x in pathlib.Path(sys.argv[2]).read_text(encoding="utf-8",errors="ignore").splitlines() if x.strip()]
argo=[]
for line in lines:
    try:
        p=parse(line); low=p["name"].lower()
        if p["proto"]!="vmess" or p["port"] not in ("443","8443") or "argo" not in low or "tls" not in low: continue
        obj=vmess_obj(line)
        if obj.get("tls")=="tls" and obj.get("host") and obj.get("sni") and obj.get("add"): argo.append(line)
    except Exception: pass
if len(argo)!=2 or {parse(x)["port"] for x in argo}!={"443","8443"}: raise SystemExit("当前美国原始订阅没有恰好两个有效的 443/8443 Argo TLS 节点")
print("当前原始订阅中的两个 Argo TLS 节点核验通过。")
PY

curl -fsS --max-time 10 "http://127.0.0.1:${SUBPORT}/${TOKEN}/jhsub.txt" -o "$WORK/backend-jhsub.txt" || fail "升级后 busybox 后端读取失败"
cmp -s "$SCI/jhsub.txt" "$WORK/backend-jhsub.txt" || fail "升级后 busybox 原订阅与本地不一致"
curl -fsS --max-time 20 "https://${DOMAIN}/jhsub.txt?t=$(date +%s)" -o "$WORK/public-jhsub.txt" || fail "升级后 HTTPS 原订阅下载失败"
cmp -s "$SCI/jhsub.txt" "$WORK/public-jhsub.txt" || fail "升级后 HTTPS 原订阅与本地不一致"
for path in /index.html /status.json; do
  code=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' "https://${DOMAIN}${path}")
  [ "$code" = 401 ] || fail "升级后 $path 未认证访问不是 401"
done

FILES=(SKPL-LIFT-manifest.json SKPL-LIFT-hiddify.txt SKPL-LIFT-singbox.json SKPL-LIFT-clash.yaml SKPL-LIFT-v2rayn.txt SKPL-LIFT-shadowrocket.txt)
for file in "${FILES[@]}"; do
  curl -fsS --max-time 25 "https://${DOMAIN}/${file}?t=$(date +%s%N)" -o "$WORK/public/$file" || fail "实际客户端文件下载失败：$file"
done

python3 - "$WORK" "$SCI" <<'PY'
import base64,collections,json,pathlib,sys
work=pathlib.Path(sys.argv[1]); sci=pathlib.Path(sys.argv[2]); pub=work/"public"
sys.path.insert(0,str(work))
from relaylib import parse,vmess_obj
manifest=json.loads((pub/"SKPL-LIFT-manifest.json").read_text())
if manifest.get("status")=="error" or not manifest.get("clients"): raise SystemExit("统一 manifest 为 error 或没有客户端")

def role(name,server):
    if "HK中转" in name: return "hk_relay"
    if "argo" in name.lower(): return "us_argo"
    if server=="38.76.210.194": return "hk_direct"
    return "us_direct"

def link_nodes(text):
    out=[]
    for line in text.splitlines():
        line=line.strip()
        if not line: continue
        p=parse(line)
        if not p["server"] or not str(p["port"]).isdigit(): raise SystemExit("分享链接中有无效节点")
        out.append(({"name":p["name"],"proto":p["proto"],"server":p["server"],"port":int(p["port"]),"role":role(p["name"],p["server"])},line))
    return out

def sing_nodes(text):
    cfg=json.loads(text); out=[]
    for obj in cfg.get("outbounds",[]):
        if not isinstance(obj,dict) or "server" not in obj or "server_port" not in obj: continue
        name=str(obj.get("tag","")); server=str(obj["server"]); proto="ss" if obj.get("type")=="shadowsocks" else str(obj.get("type",""))
        out.append(({"name":name,"proto":proto,"server":server,"port":int(obj["server_port"]),"role":role(name,server)},obj))
    return out

def scalar(text):
    try: return json.loads(text)
    except Exception: return text

def clash_nodes(text):
    out=[]; section=False; current=None; raw=None
    for line in text.splitlines():
        if line.startswith("proxies:"): section=True; continue
        if section and line and not line.startswith(" "): break
        if not section: continue
        if line.startswith("  - "):
            current={}; raw=current; out.append((None,raw)); rest=line[4:]
        elif current is not None and line.startswith("    ") and not line.startswith("      "): rest=line[4:]
        else: continue
        if ":" not in rest: continue
        key,value=rest.split(":",1); current[key.strip()]=scalar(value.strip())
    nodes=[]
    for _,obj in out:
        if not isinstance(obj,dict) or not all(k in obj for k in ("name","type","server","port")): raise SystemExit("Clash proxies 段格式异常")
        name=str(obj["name"]); server=str(obj["server"]); proto=str(obj["type"])
        nodes.append(({"name":name,"proto":proto,"server":server,"port":int(obj["port"]),"role":role(name,server)},obj))
    return nodes

manifest_nodes=manifest.get("nodes",[])
manifest_keys=[]
for n in manifest_nodes:
    manifest_keys.append((n.get("proto"),str(n.get("server")),int(n.get("port")),n.get("role")))
role_counts=collections.Counter(n.get("role") for n in manifest_nodes)
counts=manifest.get("counts",{})
if counts.get("total")!=len(manifest_nodes) or any(counts.get(r)!=role_counts.get(r,0) for r in ("hk_relay","hk_direct","us_direct","us_argo")): raise SystemExit("manifest 总节点数或分类计数不一致")
manifest_argo=[n for n in manifest_nodes if n.get("role")=="us_argo"]
if len(manifest_argo)!=2 or {int(n["port"]) for n in manifest_argo}!={443,8443}: raise SystemExit("manifest 没有恰好两个 443/8443 Argo 节点")
manifest_set=set(manifest_keys)
entries={c.get("file"):c for c in manifest["clients"]}
expected={
 "SKPL-LIFT-hiddify.txt":"hiddify",
 "SKPL-LIFT-singbox.json":"singbox",
 "SKPL-LIFT-clash.yaml":"clash",
 "SKPL-LIFT-v2rayn.txt":"v2rayn",
 "SKPL-LIFT-shadowrocket.txt":"shadowrocket"}
if set(entries)!=set(expected): raise SystemExit("manifest 客户端文件清单不等于五类实际文件")
summary=[]
for filename,kind in expected.items():
    text=(pub/filename).read_text(encoding="utf-8")
    if kind=="hiddify": nodes=link_nodes(text)
    elif kind in ("v2rayn","shadowrocket"):
        try: decoded=base64.b64decode("".join(text.split()),validate=True).decode("utf-8")
        except Exception: raise SystemExit(filename+" 不是有效 Base64 订阅")
        nodes=link_nodes(decoded)
    elif kind=="singbox": nodes=sing_nodes(text)
    else: nodes=clash_nodes(text)
    metas=[x[0] for x in nodes]
    count=len(metas)
    if count!=entries[filename].get("nodes") or count>12 or count==0: raise SystemExit(filename+" 实际节点数与 manifest 不一致或超过 12")
    actual_roles=collections.Counter(n["role"] for n in metas)
    if any(actual_roles.get(r,0)<1 for r in ("hk_relay","hk_direct","us_direct")): raise SystemExit(filename+" 缺少中转、香港直连或美国直连分类")
    argo=[(n,raw) for n,raw in nodes if n["role"]=="us_argo"]
    if len(argo)!=2 or {n["port"] for n,_ in argo}!={443,8443}: raise SystemExit(filename+" 没有恰好两个 443/8443 Argo 节点")
    for n,raw in argo:
        if n["proto"]!="vmess" or "tls" not in n["name"].lower(): raise SystemExit(filename+" Argo 类型或名称错误")
        if kind in ("hiddify","v2rayn","shadowrocket"):
            obj=vmess_obj(raw)
            if obj.get("tls")!="tls" or not obj.get("host") or not obj.get("sni") or not obj.get("add"): raise SystemExit(filename+" Argo TLS/host/sni 字段不完整")
        elif kind=="singbox":
            tls=raw.get("tls",{})
            if tls.get("enabled") is not True or not tls.get("server_name"): raise SystemExit(filename+" Argo TLS 字段不完整")
        else:
            if raw.get("tls") is not True or not raw.get("servername"): raise SystemExit(filename+" Argo TLS 字段不完整")
    for n in metas:
        key=(n["proto"],n["server"],n["port"],n["role"])
        if key not in manifest_set: raise SystemExit(filename+" 存在 manifest 中不存在的节点或错误分类")
    summary.append("%s=%d节点/Argo2"%(kind,count))

# manifest 与面板文件不得泄露订阅 Token、固定 Argo Token 或面板密码。
texts=[(pub/"SKPL-LIFT-manifest.json").read_text(encoding="utf-8",errors="ignore")]
panel=sci/"panel.html"
if panel.exists(): texts.append(panel.read_text(encoding="utf-8",errors="ignore"))
for rel in ("subtoken.log","sbargotoken.log","panel_pass"):
    p=sci/rel
    if p.exists():
        secret=p.read_text(encoding="utf-8",errors="ignore").strip()
        if secret and any(secret in text for text in texts): raise SystemExit("manifest 或面板泄露了敏感凭据")
print("实际下载核验："+"；".join(summary))
print("manifest 状态："+str(manifest.get("status")))
PY

MANIFEST_STATUS=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("status",""))' "$WORK/public/SKPL-LIFT-manifest.json")
case "$MANIFEST_STATUS" in
  ok) echo "美国配置、两个 Argo、五类实际订阅文件和 manifest 计数全部核验通过。" ;;
  degraded) echo "实际文件结构核验通过，但 manifest=degraded；请查看 manifest 的 errors，不能视为所有来源均为实时状态。" ;;
  *) fail "manifest 状态异常：$MANIFEST_STATUS" ;;
esac
echo "面板：https://$DOMAIN/index.html（需要原面板账号密码）"
echo "注意：以上不是客户端连通性测试。请最后用五类真实客户端分别更新订阅并测试香港中转、香港直连、美国直连和两个 Argo 节点。"
