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
echo "本机公网IP：$ip"

get_science() {
  curl -sL -H "Accept: application/vnd.github.raw" "$GH_URL" -o /root/science/new.sh
  chmod +x /root/science/new.sh
}

if [ "$ip" = "$US_IP" ]; then
  echo "识别为【美国】服务器"
  hostnamectl set-hostname us 2>/dev/null
  echo "正在用最新脚本重新生成节点（主机名 us）……"
  get_science
  name="SKPL-LIFT" vlp=yes xhp=yes hyp=yes tup=yes anp=yes ssp=yes vmp=yes vmag=yes tjtp=yes vgp=yes vwp=yes arp=yes sub=y argo=vmpt agn="sss.hutton.dpdns.org" agk="$AGK" dnym="s.hutton.dpdns.org" bash /root/science/new.sh rep

  cat > /root/science/aggregate.py <<'PYEOF'
#!/usr/bin/env python3
import json, re, subprocess, os
US_TOKEN = "94d31555-6a48-4b87-b241-6c78c94fc1ce"
HK_TOKEN = "d5b2e4ef-e81a-4cdc-a24d-7fa77c7c9516"
HK_BASE  = "http://38.76.210.194:53163/" + HK_TOKEN
WEB      = "/root/websbx/" + US_TOKEN
NODE_TYPES = {"vless","vmess","trojan","hysteria2","tuic","anytls","shadowsocks","socks","wireguard"}
def fetch(name):
    subprocess.run(["curl","-s","--max-time","10", HK_BASE+"/"+name, "-o","/tmp/hk_"+name], check=False)
    return os.path.isfile("/tmp/hk_"+name) and os.path.getsize("/tmp/hk_"+name) > 0
us_txt = open("/root/science/jhsub.txt").read().strip()
hk_txt = open("/tmp/hk_SKPL-LIFT.txt").read().strip() if fetch("SKPL-LIFT.txt") else ""
open(WEB+"/SKPL-LIFT-all.txt","w").write(us_txt + "\n" + hk_txt + "\n")
# ===== 中转节点：复制美国节点，地址改香港IP、端口改转发口 =====
import base64
HK_IP = "38.76.210.194"
US_HOST = "s.hutton.dpdns.org"
MAP = {"48504":"8443","20632":"8444","47601":"8445","60316":"8446","50334":"8447","25919":"8448","23409":"8449","33657":"8450","35397":"8451","18392":"8452","14774":"8453"}
relay_lines = []
for line in us_txt.splitlines():
    line = line.strip()
    if not line: continue
    m = re.search(r"@%s:(\d+)" % re.escape(US_HOST), line)
    if m and m.group(1) in MAP:
        nl = line.replace("@%s:%s" % (US_HOST, m.group(1)), "@%s:%s" % (HK_IP, MAP[m.group(1)]), 1)
        nl = re.sub(r"#([^#]*)$", lambda x: "#HK中转-" + x.group(1), nl)
        relay_lines.append(nl)
    elif line.startswith("vmess://"):
        try:
            b64 = line[8:].strip()
            obj = json.loads(base64.b64decode(b64 + "="*((4-len(b64)%4)%4)))
            if obj.get("add") == US_HOST and str(obj.get("port")) in MAP:
                obj["add"] = HK_IP
                obj["port"] = int(MAP[str(obj["port"])])
                obj["ps"] = "HK中转-" + obj.get("ps","")
                relay_lines.append("vmess://" + base64.b64encode(json.dumps(obj).encode()).decode())
        except Exception:
            pass
if relay_lines:
    with open(WEB+"/SKPL-LIFT-all.txt","a") as f:
        f.write("\n" + "\n".join(relay_lines) + "\n")
if fetch("SKPL-LIFT.json"):
    us = json.load(open("/root/science/sbox.json"))
    hk = json.load(open("/tmp/hk_SKPL-LIFT.json"))
    tags = {o.get("tag") for o in us["outbounds"]}
    for o in hk["outbounds"]:
        if o.get("type") not in NODE_TYPES: continue
        if o.get("tag") in tags:
            o = dict(o); o["tag"] = "hk-" + o["tag"]
        tags.add(o["tag"]); us["outbounds"].append(o)
    open(WEB+"/SKPL-LIFT-all.json","w").write(json.dumps(us, indent=2))
if fetch("SKPL-LIFT.yaml"):
    usy = open("/root/science/clmi.yaml").read()
    hky = open("/tmp/hk_SKPL-LIFT.yaml").read()
    m = re.search(r"proxies:\n(.*?)\nproxy-groups:", hky, re.S)
    if m:
        hk_def = m.group(1).rstrip("\n")
        names  = re.findall(r"^\s*- name: (.+?)\s*$", hk_def, re.M)
        usy = usy.replace("proxies:\n", "proxies:\n" + hk_def + "\n", 1)
        if names:
            blk = "".join("    - "+n+"\n" for n in names)
            usy = usy.replace("  proxies:\n", "  proxies:\n" + blk)
    open(WEB+"/SKPL-LIFT-all.yaml","w").write(usy)
print("全家桶三格式已生成")
PYEOF
  python3 /root/science/aggregate.py
  (crontab -l 2>/dev/null | grep -v 'aggregate.py' ; echo "*/10 * * * * python3 /root/science/aggregate.py >/dev/null 2>&1") | crontab - 2>/dev/null
  echo "====================================================="
  echo "✅ 美国服务器配置完成！客户端只导入一个订阅："
  echo "  hiddify/sing-box -> http://$US_DOMAIN:$US_PORT/$US_TOKEN/SKPL-LIFT-all.json"
  echo "  Clash/Stash      -> http://$US_DOMAIN:$US_PORT/$US_TOKEN/SKPL-LIFT-all.yaml"
  echo "  v2rayN           -> http://$US_DOMAIN:$US_PORT/$US_TOKEN/SKPL-LIFT-all.txt"
  echo "====================================================="
elif [ "$ip" = "$HK_IP" ]; then
  echo "识别为【香港】服务器"
  hostnamectl set-hostname hk 2>/dev/null
  echo "正在用最新脚本重新生成节点（主机名 hk）……"
  get_science
  name="SKPL-LIFT" vlp=yes xhp=yes hyp=yes anp=yes vmp=yes sub=y bash /root/science/new.sh rep
  echo "====================================================="
  echo "✅ 香港服务器配置完成"
  echo "请在云控制台安全组放行 TCP $HK_PORT（供美国拉取订阅）"
  echo "====================================================="
else
  echo "⚠️ 无法识别该服务器 IP（美国=$US_IP，香港=$HK_IP），脚本中止"
fi
