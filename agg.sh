#!/bin/bash
export LANG=en_US.UTF-8
# =====================================================
# SKPL-LIFT 全家桶聚合订阅一键脚本
# 用法：bash <(curl -Ls https://raw.githubusercontent.com/Hutton-h/science/main/agg.sh)
# 自动识别服务器：美国=生成全家桶订阅，香港=改主机名+放行提示
# =====================================================
GH_URL="https://api.github.com/repos/Hutton-h/science/contents/science.sh"
US_IP="170.178.174.97"
HK_IP="38.76.210.194"
US_TOKEN="94d31555-6a48-4b87-b241-6c78c94fc1ce"
HK_TOKEN="d5b2e4ef-e81a-4cdc-a24d-7fa77c7c9516"
HK_PORT="53163"
US_DOMAIN="s.hutton.dpdns.org"
US_PORT="60451"
AGK="eyJhIjoiYjE3ZmQ4NzczZWFhNWIxY2E2ZDNiZTYyYzJmZTE2NjMiLCJ0IjoiM2IzY2M4Y2YtOWZmNC00MjkxLTlkMzQtYTQwZmU3NzZmYzU1IiwicyI6Ik9URmlOelkyWldFdE16YzRZaTAwTURFeExUazJOall0TVRJMU5USmxPV1ZsTlRka04yRTBOV0V5WlRZdE9URXlPUzAwWkRrNUxXRmtORGd0WmpVd05XVXhaVE5pTkRndyJ9"

mkdir -p /root/science
ip=$(curl -s4m5 -k https://icanhazip.com 2>/dev/null)
[ -z "$ip" ] && ip=$(curl -s4m5 -k https://api.ipify.org 2>/dev/null)
[ -z "$ip" ] && [ -s /root/science/server_ip.log ] && ip=$(cat /root/science/server_ip.log)
[ -z "$ip" ] && ip=$(hostname -I 2>/dev/null | awk '{print $1}')
echo "本机公网IP：$ip"

get_science() {
  curl -sL -H "Accept: application/vnd.github.raw" "$GH_URL" -o /root/science/new.sh
  chmod +x /root/science/new.sh
}

open_firewall() {
  iptables -P INPUT ACCEPT >/dev/null 2>&1
  iptables -P FORWARD ACCEPT >/dev/null 2>&1
  iptables -P OUTPUT ACCEPT >/dev/null 2>&1
  iptables -F INPUT >/dev/null 2>&1
  iptables -F FORWARD >/dev/null 2>&1
  command -v ufw >/dev/null 2>&1 && ufw disable >/dev/null 2>&1
  command -v systemctl >/dev/null 2>&1 && { systemctl stop firewalld >/dev/null 2>&1; systemctl disable firewalld >/dev/null 2>&1; }
  netfilter-persistent save >/dev/null 2>&1
  echo "[√] 系统防火墙已开放所有端口"
}

if [ "$ip" = "$US_IP" ]; then
  echo "识别为【美国】服务器"
  hostnamectl set-hostname us 2>/dev/null
  open_firewall
  echo "正在用最新脚本重新生成节点（主机名 us）……"
  get_science
  name="SKPL-LIFT" vlp=yes xhp=yes hyp=yes tup=yes anp=yes ssp=yes vmp=yes vmag=yes tjtp=yes vgp=yes vwp=yes arp=yes sub=y argo=vmpt agn="sss.hutton.dpdns.org" agk="$AGK" dnym="s.hutton.dpdns.org" bash /root/science/new.sh rep

  cat > /root/science/aggregate.py <<'PYEOF'
#!/usr/bin/env python3
import json, re, subprocess, os, base64
US_TOKEN = "94d31555-6a48-4b87-b241-6c78c94fc1ce"
HK_TOKEN = "d5b2e4ef-e81a-4cdc-a24d-7fa77c7c9516"
HK_BASE  = "http://38.76.210.194:53163/" + HK_TOKEN
WEB      = "/root/websbx/" + US_TOKEN
US_HOST  = "s.hutton.dpdns.org"
HK_IP    = "38.76.210.194"
NODE_TYPES = {"vless","vmess","trojan","hysteria2","tuic","anytls","shadowsocks","socks","wireguard"}
# 中转端口映射：美国端口 -> 香港转发端口
MAP = {"48504":"8443","20632":"8444","47601":"8445","60316":"8446","50334":"8447","25919":"8448","23409":"8449","33657":"8450","35397":"8451","18392":"8452","14774":"8453"}
# 美国直连择优保留（按名称关键词）
US_DIRECT_KEYS = ["vl-reality-vision-us","hy2-us","anytls-us","vm-ws-us","vl-xhttp-reality-enc-us"]

def fetch(name):
    subprocess.run(["curl","-s","--max-time","10", HK_BASE+"/"+name, "-o","/tmp/hk_"+name], check=False)
    return os.path.isfile("/tmp/hk_"+name) and os.path.getsize("/tmp/hk_"+name) > 0

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
            raw = b64d(line[5:].split("#")[0])
            if "@" in raw:
                hp = raw.split("@")[1]
                host, port = hp.rsplit(":",1)
                return ("", host, port, "ss")
        except: pass
        return ("","","","ss")
    m = re.search(r"#([^#]*)$", line)
    name = m.group(1) if m else ""
    m2 = re.search(r"@\[?([^:\]]+)\]?:(\d+)", line)
    add = m2.group(1) if m2 else ""
    port = m2.group(2) if m2 else ""
    proto = line.split("://")[0] if "://" in line else ""
    return (name, add, port, proto)

def relay_line(line, us_port, hk_port):
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
            raw = b64d(line[5:].split("#")[0])
            raw = raw.replace("@%s:%s" % (US_HOST, us_port), "@%s:%s" % (HK_IP, hk_port), 1)
            nmx = re.search(r"#(.*)$", line)
            return "ss://" + base64.b64encode(raw.encode()).decode() + (("#HK中转-"+nmx.group(1)) if nmx else "#HK中转-ss")
        except: return None
    nl = line.replace("@%s:%s" % (US_HOST, us_port), "@%s:%s" % (HK_IP, hk_port), 1)
    nl = re.sub(r"#([^#]*)$", lambda x: "#HK中转-" + x.group(1), nl)
    return nl

# ---- 分类美国节点 ----
us_lines = [l.strip() for l in open("/root/science/jhsub.txt").read().splitlines() if l.strip()]
us_direct, argo_all, relay_src = [], [], {}
for line in us_lines:
    name, add, port, proto = parse(line)
    low = name.lower()
    if "argo" in low:
        argo_all.append(line)
        continue
    if "cdn" in low or "cdn" in line.lower(): continue
    if port in MAP: relay_src[port] = line
    if any(k in name for k in US_DIRECT_KEYS): us_direct.append(line)
# 全家桶不含 Argo 隧道（优选域名不适合订阅；保底用 science 美国本地订阅）
argo = []

# ---- 生成香港中转节点（美国全部直连端口，多一些）----
relay = []
for us_port in sorted(MAP, key=lambda x:int(MAP[x])):
    line = relay_src.get(us_port)
    if not line: continue
    nl = relay_line(line, us_port, MAP[us_port])
    if nl: relay.append(nl)

# ---- 拉取香港直连 ----
hk_txt = open("/tmp/hk_SKPL-LIFT.txt").read().strip() if fetch("SKPL-LIFT.txt") else ""
hk_lines = [l.strip() for l in hk_txt.splitlines() if l.strip()] if hk_txt else []

# ---- txt ----
open(WEB+"/SKPL-LIFT-all.txt","w").write("\n".join(us_direct + relay + argo + hk_lines) + "\n")

# ---- json ----
fetch("SKPL-LIFT.json")
def strip_jsonc(text):
    out = []
    i, n = 0, len(text)
    in_str = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == '\\' and i+1 < n:
                out.append(text[i+1]); i += 2; continue
            if c == '"': in_str = False
            i += 1; continue
        if c == '"':
            in_str = True; out.append(c); i += 1; continue
        if c == '/' and i+1 < n and text[i+1] == '/':
            j = text.find('\n', i)
            i = n if j == -1 else j
            out.append('\n'); continue
        if c == '/' and i+1 < n and text[i+1] == '*':
            j = text.find('*/', i+2)
            i = n if j == -1 else j+2
            continue
        out.append(c); i += 1
    return ''.join(out)
us = None
try:
    us = json.loads(strip_jsonc(open("/root/science/sbox.json").read()))
    keep, seen = [], set()
    for o in us["outbounds"]:
        if o.get("type") not in NODE_TYPES: continue
        if str(o.get("server_port","")) in ("20632","47601","60316","25919"):
            keep.append(o); seen.add(o.get("tag"))
    for o in us["outbounds"]:
        if o.get("type") not in NODE_TYPES: continue
        p = str(o.get("server_port",""))
        if p in MAP:
            o2 = dict(o); o2["server"] = HK_IP; o2["server_port"] = int(MAP[p])
            o2["tag"] = "hk中转-" + o.get("tag","")
            if o2["tag"] not in seen: keep.append(o2); seen.add(o2["tag"])
    n = 0
    for o in us["outbounds"]:
        if o.get("type")=="vmess" and str(o.get("server_port","")) in ("443","80"):
            keep.append(o); n+=1
            if n>=2: break
    if os.path.exists("/tmp/hk_SKPL-LIFT.json"):
        hk = json.load(open("/tmp/hk_SKPL-LIFT.json"))
        for o in hk["outbounds"]:
            if o.get("type") not in NODE_TYPES: continue
            if o.get("tag") in seen: o = dict(o); o["tag"] = "hk-" + o["tag"]
            seen.add(o["tag"]); keep.append(o)
    us["outbounds"] = keep
    open(WEB+"/SKPL-LIFT-all.json","w").write(json.dumps(us, indent=2))
except Exception as e:
    print("警告：json 全家桶生成跳过（%s）—— hiddify 请改用 txt 订阅" % e)

# ---- yaml（按名称筛选：美国直连 + 隧道 + 香港直连；暂不含中转）----
fetch("SKPL-LIFT.yaml")
usy = open("/root/science/clmi.yaml").read()
hky = open("/tmp/hk_SKPL-LIFT.yaml").read() if os.path.exists("/tmp/hk_SKPL-LIFT.yaml") else ""
sel_names = set()
m = re.search(r"proxies:\n(.*?)\nproxy-groups:", usy, re.S)
if m:
    for ln in m.group(1).split("\n"):
        mm = re.search(r"^\s*- name: (.+?)\s*$", ln)
        if not mm: continue
        n0 = mm.group(1); low = n0.lower()
        if "cdn" in low: continue
        if any(k in n0 for k in US_DIRECT_KEYS) or "argo" in low: sel_names.add(n0)
m2 = re.search(r"proxies:\n(.*?)\nproxy-groups:", hky, re.S)
if m2:
    for ln in m2.group(1).split("\n"):
        mm = re.search(r"^\s*- name: (.+?)\s*$", ln)
        if mm and "cdn" not in mm.group(1).lower(): sel_names.add(mm.group(1))
m3 = re.search(r"proxies:\n(.*?)\nproxy-groups:", usy, re.S)
if m3:
    keep_lines = []
    for ln in m3.group(1).split("\n"):
        mm = re.search(r"^\s*- name: (.+?)\s*$", ln)
        if mm and mm.group(1) in sel_names: keep_lines.append(ln)
    usy = usy.replace(m3.group(1), "\n".join(keep_lines) + "\n", 1)
def fix_groups(y):
    for gm in re.finditer(r"- name: (.+?)\n(?:.*\n)*?  proxies:\n(    - .+\n)+", y):
        block = gm.group(0)
        members = re.findall(r"^    - (.+?)$", block, re.M)
        keep = [x for x in members if x in sel_names or x in ("DIRECT","负载均衡","自动选择")]
        newm = "".join("    - "+x+"\n" for x in keep)
        y = y.replace(block, re.sub(r"(    - .+\n)+", newm, block), 1)
    return y
open(WEB+"/SKPL-LIFT-all.yaml","w").write(fix_groups(usy))

print("全家桶已筛选：美国直连 %d + 香港中转 %d + 隧道 %d + 香港直连 %d" % (len(us_direct), len(relay), len(argo), len(hk_lines)))
PYEOF
  python3 /root/science/aggregate.py
  (crontab -l 2>/dev/null | grep -v 'aggregate.py' ; echo "*/2 * * * * python3 /root/science/aggregate.py >/dev/null 2>&1") | crontab - 2>/dev/null
  echo "====================================================="
  echo "✅ 美国服务器配置完成！客户端只导入一个订阅："
  echo "  hiddify/sing-box -> http://$US_DOMAIN:$US_PORT/$US_TOKEN/SKPL-LIFT-all.json"
  echo "  Clash/Stash      -> http://$US_DOMAIN:$US_PORT/$US_TOKEN/SKPL-LIFT-all.yaml"
  echo "  v2rayN           -> http://$US_DOMAIN:$US_PORT/$US_TOKEN/SKPL-LIFT-all.txt"
  echo "⚠️ 还需到云控制台安全组放行：TCP/UDP 10000-65535、TCP 80,443,60451"
  echo "====================================================="
elif [ "$ip" = "$HK_IP" ]; then
  echo "识别为【香港】服务器"
  hostnamectl set-hostname hk 2>/dev/null
  open_firewall
  echo "正在用最新脚本重新生成节点（主机名 hk）……"
  get_science
  name="SKPL-LIFT" vlp=yes xhp=yes hyp=yes anp=yes vmp=yes sub=y bash /root/science/new.sh rep
  # ===== 香港中转：转发美国节点端口 =====
  echo "正在配置香港中转转发（香港 8443-8453 → 美国）……"
  echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf && sysctl -p
  US_IP="170.178.174.97"
  iptables -t nat -F PREROUTING >/dev/null 2>&1
  iptables -t nat -C POSTROUTING -j MASQUERADE 2>/dev/null && iptables -t nat -D POSTROUTING -j MASQUERADE >/dev/null 2>&1
  for hk_port in 8443 8444 8445 8446 8447 8448 8449 8450 8451 8452 8453; do
    case $hk_port in
      8443) us_port=48504;; 8444) us_port=20632;; 8445) us_port=47601;;
      8446) us_port=60316;; 8447) us_port=50334;; 8448) us_port=25919;;
      8449) us_port=23409;; 8450) us_port=33657;; 8451) us_port=35397;;
      8452) us_port=18392;; 8453) us_port=14774;;
    esac
    iptables -t nat -A PREROUTING -p tcp --dport $hk_port -j DNAT --to-destination $US_IP:$us_port
    iptables -t nat -A PREROUTING -p udp  --dport $hk_port -j DNAT --to-destination $US_IP:$us_port
    iptables -I INPUT -p tcp --dport $hk_port -j ACCEPT
    iptables -I INPUT -p udp  --dport $hk_port -j ACCEPT
  done
  iptables -t nat -A POSTROUTING -j MASQUERADE
  iptables -A FORWARD -j ACCEPT
  netfilter-persistent save >/dev/null 2>&1
  echo "====================================================="
  echo "✅ 香港服务器配置完成（含中转转发 8443-8453）"
  echo "⚠️ 还需到云控制台安全组放行：TCP/UDP 10000-65535、TCP 53163、TCP/UDP 8443-8453"
  echo "====================================================="
else
  echo "⚠️ 无法识别该服务器 IP（美国=$US_IP，香港=$HK_IP），脚本中止"
fi
