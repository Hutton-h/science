#!/bin/bash
# =============================================================================
# SKPL-LIFT 双 VPS 聚合订阅 + 香港中转一键脚本
# 用法：bash <(curl -Ls https://raw.githubusercontent.com/Hutton-h/science/main/agg.sh)
# 自动识别服务器：美国=生成全家桶订阅；香港=配置 DNAT 中转（并定时刷新）
# =============================================================================
export LANG=en_US.UTF-8

# ==================== 顶部配置（单一事实源，勿在其他位置重复硬编码） ====================
GH_URL="https://api.github.com/repos/Hutton-h/science/contents/science.sh"
US_IP="170.178.174.97"
HK_IP="38.76.210.194"
US_TOKEN="94d31555-6a48-4b87-b241-6c78c94fc1ce"
HK_TOKEN="d5b2e4ef-e81a-4cdc-a24d-7fa77c7c9516"
US_DOMAIN="s.hutton.dpdns.org"
US_PORT="60451"
HK_PORT="53163"
AGK="eyJhIjoiYjE3ZmQ4NzczZWFhNWIxY2E2ZDNiZTYyYzJmZTE2NjMiLCJ0IjoiM2IzY2M4Y2YtOWZmNC00MjkxLTlkMzQtYTQwZmU3NzZmYzU1IiwicyI6Ik9URmlOelkyWldFdE16YzRZaTAwTURFeExUazJOall0TVRJMU5USmxPV1ZsTlRka04yRTBOV0V5WlRZdE9URXlPUzAwWkRrNUxXRmtORGd0WmpVd05XVXhaVE5pTkRndyJ9"

# 香港转发端口 -> 美国协议关键词（美国实际端口每次从美国 jhsub.txt 自动发现）
HK_PLAN="8443 vl-xhttp-reality-enc|8444 vl-reality-vision|8445 hy2|8446 anytls|8447 trojan|8448 vm-ws|8449 shadowsocks|8450 vl-grpc|8451 vl-ws-enc|8452 tuic|8453 any-reality"
# 美国直连择优保留（按协议关键词）
US_DIRECT_KEYS="vl-reality-vision hy2 anytls vm-ws vl-xhttp-reality-enc"

mkdir -p /root/science /root/websbx

# ==================== 公网 IP 识别（仅接受合法 IP，域名兜底不采用） ====================
detect_ip() {
  local ipv
  ipv=$(curl -s4m5 -k https://icanhazip.com 2>/dev/null)
  [ -z "$ipv" ] && ipv=$(curl -s4m5 -k https://api.ipify.org 2>/dev/null)
  if [ -z "$ipv" ] && [ -s /root/science/server_ip.log ]; then
    head -1 /root/science/server_ip.log | grep -qE '^[0-9.]+$' && ipv=$(head -1 /root/science/server_ip.log)
  fi
  if [ -z "$ipv" ]; then
    ipv=$(hostname -I 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9.]+$' | head -1)
  fi
  echo "$ipv"
}
ip=$(detect_ip)
echo "本机公网IP：$ip"
[ -z "$ip" ] && { echo "⚠️ 无法识别该服务器公网 IP，脚本中止"; exit 1; }

# ==================== 获取最新 science.sh ====================
get_science() {
  curl -sL -H "Accept: application/vnd.github.raw" "$GH_URL" -o /root/science/new.sh || { echo "science.sh 下载失败"; exit 1; }
  chmod +x /root/science/new.sh
}

# ==================== 防火墙：最小放行，不改变默认策略、不清空已有规则 ====================
open_firewall() {
  command -v ufw >/dev/null 2>&1 && ufw disable >/dev/null 2>&1
  command -v systemctl >/dev/null 2>&1 && { systemctl stop firewalld >/dev/null 2>&1; systemctl disable firewalld >/dev/null 2>&1; }
  # 幂等放行常用端口
  for p in 80 443 "$US_PORT" "$HK_PORT" 8443 8444 8445 8446 8447 8448 8449 8450 8451 8452 8453; do
    iptables -C INPUT -p tcp --dport "$p" -j ACCEPT >/dev/null 2>&1 || iptables -A INPUT -p tcp --dport "$p" -j ACCEPT >/dev/null 2>&1
    iptables -C INPUT -p udp --dport "$p" -j ACCEPT >/dev/null 2>&1 || iptables -A INPUT -p udp --dport "$p" -j ACCEPT >/dev/null 2>&1
  done
  # 放行节点随机端口段（10000-65535），保证各协议可直连
  iptables -C INPUT -p tcp --dport 10000:65535 -j ACCEPT >/dev/null 2>&1 || iptables -A INPUT -p tcp --dport 10000:65535 -j ACCEPT >/dev/null 2>&1
  iptables -C INPUT -p udp --dport 10000:65535 -j ACCEPT >/dev/null 2>&1 || iptables -A INPUT -p udp --dport 10000:65535 -j ACCEPT >/dev/null 2>&1
  echo "[√] 防火墙已放行常用与节点端口"
}

# ==================== 统一端口发现脚本（美国聚合与香港 DNAT 使用同一算法，避免双机不一致） ====================
cat > /root/science/discover_relay.py <<'PYEOF'
#!/usr/bin/env python3
# 从美国 jhsub.txt 解析出 香港端口->美国端口 映射
import sys, base64, re, json
HK_PLAN = [("8443","vl-xhttp-reality-enc"),("8444","vl-reality-vision"),("8445","hy2"),
           ("8446","anytls"),("8447","trojan"),("8448","vm-ws"),("8449","shadowsocks"),
           ("8450","vl-grpc"),("8451","vl-ws-enc"),("8452","tuic"),("8453","any-reality")]
def b64d(s):
    s = s.strip()
    return base64.b64decode(s + "="*((4-len(s)%4)%4)).decode("utf-8","ignore")
def parse(line):
    low = line.lower()
    if low.startswith("vmess://"):
        try:
            obj = json.loads(b64d(line[8:]))
            return (obj.get("ps",""), obj.get("add",""), str(obj.get("port","")), "vmess")
        except: return ("","","","vmess")
    if low.startswith("ss://"):
        try:
            body = line[5:].split("#")[0]
            # 兼容旧式整段 base64 与 SIP002（仅 userinfo 编码）
            raw = b64d(body)
            if "@" not in raw:
                head, _, tail = body.partition("@")
                raw = b64d(head) + "@" + tail
            hp = raw.split("@")[1]
            host, port = hp.rsplit(":",1)
            m = re.search(r"#([^#]*)$", line)
            return (m.group(1) if m else "", host, port, "ss")
        except: return ("","","","ss")
    m = re.search(r"#([^#]*)$", line)
    name = m.group(1) if m else ""
    m2 = re.search(r"@\[?([^:\]]+)\]?:(\d+)", line)
    return (name, m2.group(1) if m2 else "", m2.group(2) if m2 else "", line.split("://")[0] if "://" in line else "")
def discover(lines):
    """统一算法：关键词->首个有效端口；排除 Argo/CDN/空地址，保证双机一致"""
    port_of = {}
    for line in lines:
        name, add, port, proto = parse(line)
        low = name.lower()
        if not port or not add: continue
        if "argo" in low or "cdn" in low: continue
        for hk, kw in HK_PLAN:
            if kw in low:
                port_of.setdefault(kw, port)
                break
    return port_of
if __name__ == "__main__":
    lines = [l.strip() for l in open(sys.argv[1], encoding="utf-8", errors="ignore").read().splitlines() if l.strip()]
    port_of = discover(lines)
    for hk, kw in HK_PLAN:
        if kw in port_of:
            print("%s %s" % (hk, port_of[kw]))
PYEOF

# ================================================================
# 美国分支：生成全家桶聚合订阅 + 各客户端独立订阅 + manifest
# ================================================================
if [ "$ip" = "$US_IP" ]; then
  echo "识别为【美国】服务器"
  hostnamectl set-hostname us 2>/dev/null
  open_firewall
  echo "正在用最新脚本重新生成节点（主机名 us）……"
  get_science
  name="SKPL-LIFT" vlp=yes xhp=yes hyp=yes tup=yes anp=yes ssp=yes vmp=yes vmag=yes tjtp=yes vgp=yes vwp=yes arp=yes sub=y argo=vmpt agn="sss.hutton.dpdns.org" agk="$AGK" dnym="$US_DOMAIN" bash /root/science/new.sh rep
  [ $? -ne 0 ] && { echo "美国节点重装失败，请检查上方输出"; exit 1; }

  # 生成聚合生成器
  cat > /root/science/aggregate.py <<'PYEOF'
#!/usr/bin/env python3
# SKPL-LIFT 全家桶聚合生成器（唯一权威数据源）
# 输出：SKPL-LIFT-all.txt/json/yaml、各客户端独立订阅、SKPL-LIFT-manifest.json
import json, re, subprocess, os, sys, base64, copy, fcntl, urllib.parse, time

US_TOKEN = "94d31555-6a48-4b87-b241-6c78c94fc1ce"
HK_TOKEN = "d5b2e4ef-e81a-4cdc-a24d-7fa77c7c9516"
BASE     = "https://s.hutton.dpdns.org"          # nginx 已对 yaml/json/txt 关闭认证
WEB      = "/root/websbx/" + US_TOKEN
US_HOST  = "s.hutton.dpdns.org"
HK_IP    = "38.76.210.194"
BRAND    = "SKPL-LIFT"
MAX_NODE = 12                                       # 每个客户端实际导入不超过 12
HK_PLAN = [("8443","vl-xhttp-reality-enc"),("8444","vl-reality-vision"),("8445","hy2"),
           ("8446","anytls"),("8447","trojan"),("8448","vm-ws"),("8449","shadowsocks"),
           ("8450","vl-grpc"),("8451","vl-ws-enc"),("8452","tuic"),("8453","any-reality")]
US_DIRECT_KEYS = ["vl-reality-vision","hy2","anytls","vm-ws","vl-xhttp-reality-enc"]
NODE_TYPES = {"vless","vmess","trojan","hysteria2","tuic","anytls","shadowsocks","socks","wireguard"}
HIDDIFY_P = {"vless","vmess","trojan","ss","hy2","tuic","anytls"}
V2RAYN_P  = {"vless","vmess","trojan"}
CLASH_P   = {"vless","vmess","trojan","ss","hy2","tuic"}
SHADOW_P  = {"vless","vmess","trojan","ss","hy2","tuic","anytls"}

LOCK = "/root/science/aggregate.lock"
fl = open(LOCK, "w")
try:
    fcntl.flock(fl, fcntl.LOCK_EX | fcntl.LOCK_NB)
except IOError:
    print("aggregate already running, skip"); sys.exit(0)

def b64d(s):
    s = s.strip()
    return base64.b64decode(s + "="*((4-len(s)%4)%4)).decode("utf-8","ignore")

def parse(line):
    low = line.lower()
    if low.startswith("vmess://"):
        try:
            obj = json.loads(b64d(line[8:]))
            return (obj.get("ps",""), obj.get("add",""), str(obj.get("port","")), "vmess")
        except: return ("","","","vmess")
    if low.startswith("ss://"):
        try:
            body = line[5:].split("#")[0]
            raw = b64d(body)
            if "@" not in raw:
                head, _, tail = body.partition("@")
                raw = b64d(head) + "@" + tail
            hp = raw.split("@")[1]
            host, port = hp.rsplit(":",1)
            m = re.search(r"#([^#]*)$", line)
            return (m.group(1) if m else "", host, port, "ss")
        except: return ("","","","ss")
    m = re.search(r"#([^#]*)$", line)
    name = m.group(1) if m else ""
    m2 = re.search(r"@\[?([^:\]]+)\]?:(\d+)", line)
    return (name, m2.group(1) if m2 else "", m2.group(2) if m2 else "", line.split("://")[0] if "://" in line else "")

def discover(lines):
    port_of = {}
    for line in lines:
        name, add, port, proto = parse(line)
        low = name.lower()
        if not port or not add: continue
        if "argo" in low or "cdn" in low: continue
        for hk, kw in HK_PLAN:
            if kw in low:
                port_of.setdefault(kw, port)
                break
    return port_of

def http_fetch(url):
    """HTTPS 拉取；校验 HTTP 状态；失败返回 None，绝不复用旧文件"""
    import urllib.request
    try:
        req = urllib.request.Request(url, headers={"User-Agent":"curl/8"})
        with urllib.request.urlopen(req, timeout=15) as r:
            if r.status != 200: return None
            body = r.read().decode("utf-8","ignore")
            return body if body.strip() else None
    except Exception as e:
        print("fetch failed:", url, e); return None

def relay_line(line, hk_port):
    """结构化重写：vmess/ss 解析后重建；其余替换 地址:端口 并校验"""
    low = line.lower()
    if low.startswith("vmess://"):
        try:
            obj = json.loads(b64d(line[8:]))
            obj["add"] = HK_IP; obj["port"] = int(hk_port)
            obj["ps"] = "HK中转-" + obj.get("ps","")
            return "vmess://" + base64.b64encode(json.dumps(obj).encode()).decode()
        except: return None
    if low.startswith("ss://"):
        try:
            body = line[5:].split("#")[0]
            raw = b64d(body)
            if "@" not in raw:
                head, _, tail = body.partition("@")
                raw = b64d(head) + "@" + tail
            hp = raw.split("@")[1]
            host, port = hp.rsplit(":",1)
            newraw = raw.replace(host+":"+port, HK_IP+":"+str(hk_port), 1)
            nmx = re.search(r"#(.*)$", line)
            return "ss://" + base64.b64encode(newraw.encode()).decode() + (("#HK中转-"+nmx.group(1)) if nmx else "#HK中转-ss")
        except: return None
    # vless/trojan/hy2/tuic/anytls：替换 @host:port
    m = re.search(r"@\[?([^:\]]+)\]?:(\d+)", line)
    if not m: return None
    host, port = m.group(1), m.group(2)
    nl = line.replace("@%s:%s" % (host, port), "@%s:%s" % (HK_IP, hk_port), 1)
    # 校验替换是否生效
    if ("@%s:%s" % (HK_IP, hk_port)) not in nl: return None
    nl = re.sub(r"#([^#]*)$", lambda x: "#HK中转-" + x.group(1), nl)
    return nl

def urlenc(s):
    return urllib.parse.quote(s, safe="")

def to_clash(line):
    """分享链接 -> Mihomo/Clash proxy 结构（结构化转换，不用逐行正则拼接）"""
    name, add, port, proto = parse(line)
    low = line.lower()
    if not add or not port: return None
    p = {"name": name, "server": add, "port": int(port), "type": proto}
    if ":" in add and not add.startswith("["):
        p["server"] = '"%s"' % add
    try:
        if proto == "vless":
            p["uuid"] = re.search(r"vless://([^@]+)@", low).group(1)
            q = urllib.parse.parse_qs(re.search(r"\?([^#]*)", low).group(1) if "?" in low else "")
            enc = q.get("encryption",[""])[0]
            flow = q.get("flow",[""])[0]
            p["flow"] = flow if flow else None
            if q.get("security",[""])[0] == "reality":
                p["tls"] = True; p["servername"] = q.get("sni",[""])[0]
                p["reality-opts"] = {"public-key": q.get("pbk",[""])[0], "short-id": q.get("sid",[""])[0]}
                p["client-fingerprint"] = q.get("fp",["chrome"])[0]
            elif q.get("security",[""])[0] == "tls":
                p["tls"] = True; p["servername"] = q.get("sni",[""])[0]
            network = q.get("type",[""])[0]
            if network == "ws":
                p["network"] = "ws"
                p["ws-opts"] = {"path": q.get("path",[""])[0], "headers": {"Host": q.get("host",[""])[0]}}
            elif network == "grpc":
                p["network"] = "grpc"; p["grpc-opts"] = {"grpc-service-name": q.get("serviceName",[""])[0]}
            elif network == "xhttp":
                p["network"] = "xhttp"
                p["xhttp-opts"] = {"path": q.get("path",[""])[0], "mode": q.get("mode",["auto"])[0]}
            elif network == "httpupgrade":
                p["network"] = "httpupgrade"; p["httpupgrade-opts"] = {"path": q.get("path",[""])[0], "host": q.get("host",[""])[0]}
            elif network == "tcp":
                p["network"] = "tcp"
        elif proto == "vmess":
            try:
                obj = json.loads(b64d(line[8:]))
            except Exception:
                return None
            p["uuid"] = obj.get("id","")
            if obj.get("tls") == "tls":
                p["tls"] = True
            net = obj.get("net","")
            if net == "ws":
                p["network"] = "ws"
                p["ws-opts"] = {"path": obj.get("path",""), "headers": {"Host": obj.get("host","")}}
            elif net == "grpc":
                p["network"] = "grpc"; p["grpc-opts"] = {"grpc-service-name": obj.get("path","")}
        elif proto == "trojan":
            p["password"] = re.search(r"trojan://([^@]+)@", low).group(1)
            q = urllib.parse.parse_qs(re.search(r"\?([^#]*)", low).group(1) if "?" in low else "")
            p["sni"] = q.get("sni",[""])[0]; p["skip-cert-verify"] = q.get("insecure",["0"])[0] == "1"
            if q.get("type",[""])[0] == "ws":
                p["network"] = "ws"; p["ws-opts"] = {"path": q.get("path",[""])[0], "headers": {"Host": q.get("host",[""])[0]}}
            elif q.get("type",[""])[0] == "grpc":
                p["network"] = "grpc"; p["grpc-opts"] = {"grpc-service-name": q.get("serviceName",[""])[0]}
        elif proto == "ss":
            body = line[5:].split("#")[0]
            raw = b64d(body)
            if "@" not in raw:
                head, _, tail = body.partition("@")
                raw = b64d(head) + "@" + tail
            method, passwd = raw.split("@")[0].split(":",1)
            p["cipher"] = method; p["password"] = passwd
        elif proto == "hysteria2":
            p["password"] = re.search(r"hysteria2://([^@]+)@", low).group(1)
            q = urllib.parse.parse_qs(re.search(r"\?([^#]*)", low).group(1) if "?" in low else "")
            p["sni"] = q.get("sni",[""])[0]
            p["skip-cert-verify"] = q.get("insecure",["0"])[0] == "1"
            if q.get("mport",[""])[0]:
                p["ports"] = q.get("mport",[""])[0]
        elif proto == "tuic":
            p["uuid"] = re.search(r"tuic://([^:]+):", low).group(1)
            p["password"] = re.search(r"tuic://[^:]+:([^@]+)@", low).group(1)
            q = urllib.parse.parse_qs(re.search(r"\?([^#]*)", low).group(1) if "?" in low else "")
            p["sni"] = q.get("sni",[""])[0]
        elif proto == "anytls":
            p["password"] = re.search(r"anytls://([^@]+)@", low).group(1)
            q = urllib.parse.parse_qs(re.search(r"\?([^#]*)", low).group(1) if "?" in low else "")
            p["sni"] = q.get("sni",[""])[0]
    except Exception as e:
        print("clash convert skip:", line[:60], e); return None
    # 去掉 None 字段
    p = {k: v for k, v in p.items() if v is not None and v != ""}
    return p

def dump_yaml(proxies):
    lines = ["port: 7890", "allow-lan: true", "mode: rule", "log-level: info", "unified-delay: true", "proxies:"]
    for p in proxies:
        lines.append("  - name: %s" % p["name"].replace('"', "'"))
        lines.append("    type: %s" % p["type"])
        lines.append("    server: %s" % p["server"])
        lines.append("    port: %d" % p["port"])
        for k, v in p.items():
            if k in ("name","type","server","port"): continue
            if isinstance(v, dict):
                lines.append("    %s:" % k)
                for k2, v2 in v.items():
                    if isinstance(v2, dict):
                        lines.append("      %s:" % k2)
                        for k3, v3 in v2.items():
                            lines.append("        %s: %s" % (k3, yaml_scalar(v3)))
                    else:
                        lines.append("      %s: %s" % (k2, yaml_scalar(v2)))
            else:
                lines.append("    %s: %s" % (k, yaml_scalar(v)))
    names = [p["name"] for p in proxies]
    lines.append("proxy-groups:")
    lines.append("  - name: 自动选择")
    lines.append("    type: url-test")
    lines.append("    url: http://www.gstatic.com/generate_204")
    lines.append("    interval: 300")
    lines.append("    proxies: %s" % names)
    lines.append("  - name: 手动选择")
    lines.append("    type: select")
    lines.append("    proxies:")
    lines.append("      - 自动选择")
    for n in names:
        lines.append("      - %s" % n)
    lines.append("  - name: 直连")
    lines.append("    type: select")
    lines.append("    proxies:")
    lines.append("      - DIRECT")
    lines.append("rules:")
    lines.append("  - GEOIP,CN,DIRECT")
    lines.append("  - MATCH,手动选择")
    return "\n".join(lines) + "\n"

def yaml_scalar(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        if v.startswith('"') or v in ("true","false"):
            return '"%s"' % v.strip('"')
        return v
    return str(v)

def atomic_write(path, content):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, path)

# ---------------- 主流程 ----------------
os.makedirs(WEB, exist_ok=True)
us_lines = [l.strip() for l in open("/root/science/jhsub.txt", encoding="utf-8", errors="ignore").read().splitlines() if l.strip()]
port_of = discover(us_lines)

# 拉取香港直连（HTTPS，失败则跳过该部分并记录，不复用旧文件）
hk_txt = http_fetch("%s/%s/SKPL-LIFT.txt" % (BASE, HK_TOKEN))
hk_lines = []
if hk_txt:
    for l in hk_txt.splitlines():
        l = l.strip()
        if not l: continue
        name, add, port, proto = parse(l)
        low = name.lower()
        if not add or not port: continue
        if "argo" in low or "cdn" in low: continue
        hk_lines.append(l)
hk_json = http_fetch("%s/%s/SKPL-LIFT.json" % (BASE, HK_TOKEN))

# 分类美国节点（排除 Argo/CDN/空地址）
us_direct = []
relay_src = {}   # kw -> 源分享链接
for line in us_lines:
    name, add, port, proto = parse(line)
    low = name.lower()
    if not add or not port: continue
    if "argo" in low or "cdn" in low: continue
    for hk, kw in HK_PLAN:
        if kw in low and port_of.get(kw) == port:
            relay_src.setdefault(kw, line)
            break
    if any(k in low for k in US_DIRECT_KEYS):
        if line not in us_direct: us_direct.append(line)

# 香港中转（按统一映射，地址必须被重写为 HK_IP）
relay = []
for hk, kw in HK_PLAN:
    src = relay_src.get(kw)
    if not src: continue
    nl = relay_line(src, hk)
    if nl: relay.append(nl)
    else: print("relay failed for kw:", kw)

# 全家桶顺序：香港中转 -> 香港直连 -> 美国直连
family = relay + hk_lines + us_direct

# ---------- TXT ----------
txt = "\n".join(family) + "\n" if family else ""
atomic_write(WEB + "/SKPL-LIFT-all.txt", txt)

# ---------- JSON（基于美国 sbox.json，保留 selector/urltest/direct/route/dns，剔除 Argo 与空端口） ----------
cfg = None
try:
    us_sbox = open("/root/science/sbox.json", encoding="utf-8").read()
    # 兼容 JSONC 注释
    us_sbox = re.sub(r"(?m)^\s*//.*$", "", us_sbox)
    us_json = json.loads(us_sbox)
    cfg = copy.deepcopy(us_json)
    outs = cfg.get("outbounds", [])
    proxy_outs = []
    other_outs = []
    for o in outs:
        tag = o.get("tag","").lower()
        if "argo" in tag: continue
        if o.get("type") in NODE_TYPES and o.get("server_port"):
            proxy_outs.append(o)
        else:
            other_outs.append(o)
    # 香港直连 outbounds（从香港 sbox.json 提取）
    hk_outs = []
    if hk_json:
        try:
            hk_cfg = json.loads(re.sub(r"(?m)^\s*//.*$", "", hk_json))
            for o in hk_cfg.get("outbounds", []):
                tag = o.get("tag","").lower()
                if "argo" in tag or o.get("type") not in NODE_TYPES or not o.get("server_port"): continue
                if o.get("type") == "vless":
                    hk_outs.append(o)
        except Exception as e:
            print("hk json parse failed:", e)
    # 香港中转 outbounds：复制美国对应协议 outbound，改 server/port
    relay_outs = []
    for o in proxy_outs:
        tag_low = o.get("tag","").lower()
        for hk, kw in HK_PLAN:
            if kw in tag_low and port_of.get(kw):
                ro = copy.deepcopy(o)
                ro["server"] = HK_IP
                ro["server_port"] = int(hk)
                ro["tag"] = "HK中转-" + o.get("tag","")
                relay_outs.append(ro)
                break
    new_outs = other_outs + proxy_outs + relay_outs + hk_outs
    # 修正 selector/urltest 引用（只保留实际存在的 tag）
    tags = {o.get("tag") for o in new_outs}
    for o in new_outs:
        if o.get("type") in ("selector","urltest"):
            o["outbounds"] = [t for t in o.get("outbounds",[]) if t in tags] or (["direct"] if "direct" in tags else [])
    cfg["outbounds"] = new_outs
    # route.final / dns detour 校验：指向不存在的 tag 则回退 direct
    all_tags = tags
    if cfg.get("route",{}).get("final") not in all_tags:
        cfg.setdefault("route",{})["final"] = "direct" if "direct" in all_tags else None
    for d in cfg.get("dns",{}).get("servers",[]):
        if d.get("detour") not in all_tags:
            d["detour"] = "direct" if "direct" in all_tags else None
    atomic_write(WEB + "/SKPL-LIFT-all.json", json.dumps(cfg, ensure_ascii=False, indent=2) + "\n")
except Exception as e:
    print("json aggregate failed:", e)

# ---------- YAML（从全家桶分享链接结构化转换） ----------
proxies = []
for line in family:
    cp = to_clash(line)
    if cp: proxies.append(cp)
if proxies:
    atomic_write(WEB + "/SKPL-LIFT-all.yaml", dump_yaml(proxies))

# ---------- 各客户端独立订阅（每客户端 ≤12，以中转优先） ----------
def proto_of(line):
    return parse(line)[3]
subs = {}
for allow_name, allow_set, ext in (("hiddify", HIDDIFY_P, "txt"), ("singbox", HIDDIFY_P, "txt"),
                                   ("v2rayn", V2RAYN_P, "txt"), ("clash", CLASH_P, "yaml"),
                                   ("shadowrocket", SHADOW_P, "txt")):
    items = [l for l in family if proto_of(l) in allow_set][:MAX_NODE]
    fname = "%s-%s.%s" % (BRAND, allow_name, ext)
    if ext == "yaml":
        cps = []
        for l in items:
            cp = to_clash(l)
            if cp: cps.append(cp)
        content = dump_yaml(cps) if cps else ""
    else:
        content = "\n".join(items) + "\n" if items else ""
    atomic_write(WEB + "/" + fname, content)
    subs[fname] = len(items)

# ---------- manifest.json（面板唯一数据源） ----------
manifest = {
  "brand": BRAND,
  "generated_at": time.strftime("%Y-%m-%d %H:%M:%S"),
  "server_ip": US_IP,
  "status": "ok",
  "counts": {
     "us_direct": len(us_direct),
     "hk_relay": len(relay),
     "hk_direct": len(hk_lines),
     "total": len(family)
  },
  "files": {
     "family_txt": "SKPL-LIFT-all.txt",
     "family_json": "SKPL-LIFT-all.json",
     "family_yaml": "SKPL-LIFT-all.yaml",
  },
  "clients": [{"name": n, "file": f, "nodes": c} for n, f, c in
              (("Hiddify","SKPL-LIFT-hiddify.txt",subs.get("SKPL-LIFT-hiddify.txt",0)),
               ("sing-box","SKPL-LIFT-singbox.txt",subs.get("SKPL-LIFT-singbox.txt",0)),
               ("Clash/Mihomo","SKPL-LIFT-clash.yaml",subs.get("SKPL-LIFT-clash.yaml",0)),
               ("v2rayN","SKPL-LIFT-v2rayn.txt",subs.get("SKPL-LIFT-v2rayn.txt",0)),
               ("Shadowrocket","SKPL-LIFT-shadowrocket.txt",subs.get("SKPL-LIFT-shadowrocket.txt",0)))]
}
atomic_write(WEB + "/SKPL-LIFT-manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
print("aggregate done: total=%d us=%d relay=%d hk=%d" % (len(family), len(us_direct), len(relay), len(hk_lines)))
PYEOF

  chmod +x /root/science/aggregate.py
  if ! python3 /root/science/aggregate.py; then
    echo "⚠️ 聚合生成失败，请检查 /root/science/aggregate.py 输出"
    exit 1
  fi
  # 每 2 分钟刷新聚合（带锁，日志落盘，便于排查）
  cat > /root/science/hk_relay.sh <<'RLEOF'
#!/bin/bash
# 占位：美国端无需中转；仅用于 cron 占位
RLEOF
  chmod +x /root/science/hk_relay.sh
  (crontab -l 2>/dev/null | grep -v '^[^*].*aggregate.py' | grep -v 'aggregate.py' ; echo "*/2 * * * * python3 /root/science/aggregate.py >> /root/science/aggregate.log 2>&1") | crontab - 2>/dev/null
  echo "====================================================="
  echo "✅ 美国服务器配置完成！面板与订阅已生成"
  echo "  面板：https://$US_DOMAIN/index.html"
  echo "  全家桶 TXT：https://$US_DOMAIN/$US_TOKEN/SKPL-LIFT-all.txt"
  echo "  全家桶 JSON：https://$US_DOMAIN/$US_TOKEN/SKPL-LIFT-all.json"
  echo "  全家桶 YAML：https://$US_DOMAIN/$US_TOKEN/SKPL-LIFT-all.yaml"
  echo "  各客户端订阅见面板（每客户端不超过 12 个节点）"
  echo "⚠️ 需到云控制台安全组放行：TCP/UDP 10000-65535、TCP 80/443/60451"
  echo "====================================================="

# ================================================================
# 香港分支：配置 DNAT 中转（并定时刷新，跟随美国端口变化）
# ================================================================
elif [ "$ip" = "$HK_IP" ]; then
  echo "识别为【香港】服务器"
  hostnamectl set-hostname hk 2>/dev/null
  open_firewall
  echo "正在用最新脚本重新生成节点（主机名 hk）……"
  get_science
  name="SKPL-LIFT" vlp=yes xhp=yes hyp=yes anp=yes vmp=yes sub=y bash /root/science/new.sh rep
  [ $? -ne 0 ] && { echo "香港节点重装失败，请检查上方输出"; exit 1; }
  # 开启内核转发
  grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf 2>/dev/null || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
  sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1

  # 生成中转刷新脚本：按最新美国 jhsub.txt 发现端口并重建 DNAT（先精确清理旧的）
  cat > /root/science/hk_relay.sh <<'RLEOF'
#!/bin/bash
export LANG=en_US.UTF-8
HK_IP="38.76.210.194"
US_IP="170.178.174.97"
US_DOMAIN="s.hutton.dpdns.org"
US_TOKEN="94d31555-6a48-4b87-b241-6c78c94fc1ce"
LOG="/root/science/hk_relay.log"
LOCK="/root/science/hk_relay.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0
# 1) 拉取美国订阅（HTTPS）
curl -s --max-time 15 "https://$US_DOMAIN/$US_TOKEN/jhsub.txt" -o /tmp/us_jhsub.txt
if [ ! -s /tmp/us_jhsub.txt ]; then
  echo "$(date '+%F %T') 拉取美国订阅失败，跳过本轮刷新" >> /root/science/hk_relay.log
  exit 0
fi
# 2) 精确清理旧规则（按上次记录），不清空他人规则
if [ -f "$LOG" ]; then
  while read -r proto port target; do
    [ -z "$port" ] && continue
    if [ "$proto" = "accept" ]; then
      iptables -t nat -D PREROUTING -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1
      iptables -I INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1
      iptables -I INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1
      iptables -D INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1
      iptables -D INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1
    else
      iptables -t nat -D PREROUTING -p tcp --dport "$port" -j DNAT --to-destination $US_IP:$target >/dev/null 2>&1
      iptables -t nat -D PREROUTING -p udp --dport "$port" -j DNAT --to-destination $US_IP:$target >/dev/null 2>&1
    fi
  done < "$LOG"
  rm -f "$LOG"
fi
# 3) 用统一算法发现端口并重建规则
map=$(python3 /root/science/discover_relay.py /tmp/us_jhsub.txt)
n=0
missing=""
for hk_port in 8443 8444 8445 8446 8447 8448 8449 8450 8451 8452 8453; do
  us_port=$(echo "$map" | awk -v hk="$hk_port" '$1==hk{print $2; exit}')
  if [ -z "$us_port" ]; then
    missing="$missing $hk_port"
    continue
  fi
  echo "  中转 $hk_port → 美国 $us_port"
  iptables -t nat -A PREROUTING -p tcp --dport "$hk_port" -j DNAT --to-destination $US_IP:$us_port
  iptables -t nat -A PREROUTING -p udp --dport "$hk_port" -j DNAT --to-destination $US_IP:$us_port
  echo "dnat $hk_port $us_port" >> "$LOG"
  iptables -I INPUT -p tcp --dport "$hk_port" -j ACCEPT >/dev/null 2>&1
  iptables -I INPUT -p udp --dport "$hk_port" -j ACCEPT >/dev/null 2>&1
  n=$((n+1))
done
if [ -n "$missing" ]; then
  echo "$(date '+%F %T') 未能发现的端口：$missing" >> /root/science/hk_relay.log
fi
# 4) 全局 MASQUERADE（仅对出口为美国的流量做源地址伪装）
iptables -t nat -C POSTROUTING -o eth0 -d "$US_IP" -j MASQUERADE >/dev/null 2>&1 || iptables -t nat -A POSTROUTING -o eth0 -d "$US_IP" -j MASQUERADE >/dev/null 2>&1
iptables -t nat -C POSTROUTING -o ens3 -d "$US_IP" -j MASQUERADE >/dev/null 2>&1 || iptables -t nat -A POSTROUTING -o ens3 -d "$US_IP" -j MASQUERADE >/dev/null 2>&1
iptables -C FORWARD -j ACCEPT >/dev/null 2>&1 || iptables -A FORWARD -j ACCEPT >/dev/null 2>&1
# 5) 持久化
if command -v netfilter-persistent >/dev/null 2>&1; then
  netfilter-persistent save >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
  rc-update show default 2>/dev/null | grep -q 'iptables' || rc-update add iptables >/dev/null 2>&1
  rc-service iptables save >/dev/null 2>&1
else
  echo "⚠️ 未找到 netfilter-persistent，重启后 DNAT 可能丢失，建议安装 iptables-persistent"
fi
echo "$(date '+%F %T') 中转刷新完成，共 $n 条" >> /root/science/hk_relay.log
RLEOF
  chmod +x /root/science/hk_relay.sh
  bash /root/science/hk_relay.sh
  # 每 2 分钟跟随美国端口变化刷新（与聚合端保持同步）
  (crontab -l 2>/dev/null | grep -v 'hk_relay.sh'; echo "*/2 * * * * /root/science/hk_relay.sh >/dev/null 2>&1") | crontab - 2>/dev/null
  echo "====================================================="
  echo "✅ 香港服务器配置完成（含中转转发 8443-8453，自动跟随美国端口）"
  echo "⚠️ 需到云控制台安全组放行：TCP/UDP 10000-65535、TCP 53163、TCP/UDP 8443-8453"
  echo "====================================================="
else
  echo "⚠️ 无法识别该服务器 IP（美国=$US_IP，香港=$HK_IP），脚本中止"
  exit 1
fi
