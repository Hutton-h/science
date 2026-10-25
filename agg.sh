#!/bin/bash
# SKPL-LIFT 双 VPS 节点、香港中转与统一订阅部署脚本
# 配置可通过环境变量覆盖；订阅 Token 和 Argo Token 不写入公开仓库。
export LANG=en_US.UTF-8

GH_URL="${GH_URL:-https://api.github.com/repos/Hutton-h/science/contents/science.sh}"
US_IP="${US_IP:-170.178.174.97}"
HK_IP="${HK_IP:-38.76.210.194}"
US_DOMAIN="${US_DOMAIN:-s.hutton.dpdns.org}"
US_PORT="${US_PORT:-60451}"
HK_PORT="${HK_PORT:-53163}"
US_TOKEN="${US_TOKEN:-}"
HK_TOKEN="${HK_TOKEN:-}"
AGK="${AGK:-}"
# 跨机订阅默认使用香港现有 busybox 地址；如香港配置 HTTPS，可改为 https://域名（不要再带 Token）。
HK_BASE="${HK_BASE:-}"

fail() { echo "错误：$*" >&2; exit 1; }
mkdir -p /root/science /root/websbx

is_ipv4() {
  echo "$1" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

detect_ip() {
  local ipv addr
  ipv=$(curl -fsS4m8 https://api.ipify.org 2>/dev/null)
  [ -z "$ipv" ] && ipv=$(curl -fsS4m8 https://icanhazip.com 2>/dev/null)
  if ! is_ipv4 "$ipv" && [ -s /root/science/server_ip.log ]; then
    addr=$(head -1 /root/science/server_ip.log | tr -d '[]')
    is_ipv4 "$addr" && ipv="$addr"
  fi
  if ! is_ipv4 "$ipv"; then
    addr=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.*src \([0-9.]*\).*/\1/p' | head -1)
    is_ipv4 "$addr" && ipv="$addr"
  fi
  if ! is_ipv4 "$ipv"; then
    for addr in $(hostname -I 2>/dev/null); do
      case "$addr" in
        10.*|127.*|192.168.*|169.254.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|100.6[4-9].*|100.[7-9][0-9].*|100.1[0-1][0-9].*|100.12[0-7].*) continue ;;
      esac
      if is_ipv4 "$addr"; then ipv="$addr"; break; fi
    done
  fi
  is_ipv4 "$ipv" && echo "$ipv"
}

ip=$(detect_ip)
echo "本机公网 IP：${ip:-未识别}"
[ -n "$ip" ] || fail "无法识别公网 IP"
[ "$ip" = "$US_IP" ] || [ "$ip" = "$HK_IP" ] || fail "该 IP 不属于美国或香港服务器"

get_science() {
  curl -fsSL --max-time 60 -H "Accept: application/vnd.github.raw" "$GH_URL" -o /root/science/new.sh || fail "science.sh 下载失败"
  grep -q 'cip(){' /root/science/new.sh || fail "下载到的 science.sh 内容不正确"
  chmod +x /root/science/new.sh
}

open_firewall() {
  local role="$1" p proto
  # 不再关闭 UFW/firewalld，也不清空现有规则，只放行实际使用的端口。
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q '^Status: active'; then
    ufw allow 80/tcp >/dev/null 2>&1
    ufw allow 443/tcp >/dev/null 2>&1
    for p in $(cat /root/science/port_* /root/science/subport.log 2>/dev/null); do
      echo "$p" | grep -Eq '^[0-9]+$' || continue
      ufw allow "$p"/tcp >/dev/null 2>&1
      ufw allow "$p"/udp >/dev/null 2>&1
    done
    [ "$role" = hk ] && ufw allow 8443:8453/tcp >/dev/null 2>&1 && ufw allow 8443:8453/udp >/dev/null 2>&1
  elif command -v iptables >/dev/null 2>&1; then
    for p in 80 443; do
      iptables -C INPUT -p tcp --dport "$p" -j ACCEPT >/dev/null 2>&1 || iptables -A INPUT -p tcp --dport "$p" -j ACCEPT >/dev/null 2>&1
    done
    for p in $(cat /root/science/port_* /root/science/subport.log 2>/dev/null); do
      echo "$p" | grep -Eq '^[0-9]+$' || continue
      for proto in tcp udp; do
        iptables -C INPUT -p "$proto" --dport "$p" -j ACCEPT >/dev/null 2>&1 || iptables -A INPUT -p "$proto" --dport "$p" -j ACCEPT >/dev/null 2>&1
      done
    done
    if [ "$role" = hk ]; then
      for proto in tcp udp; do
        iptables -C INPUT -p "$proto" --dport 8443:8453 -j ACCEPT >/dev/null 2>&1 || iptables -A INPUT -p "$proto" --dport 8443:8453 -j ACCEPT >/dev/null 2>&1
      done
    fi
  else
    echo "提示：未找到 ufw/iptables，请检查系统防火墙及云安全组"
  fi
}

# 双机共用的解析、筛选和客户端转换库。
cat > /root/science/relaylib.py <<'PYLIB'
import base64, json, re, urllib.parse

HK_PLAN = [("8443","vl-xhttp-reality-enc"),("8444","vl-reality-vision"),("8445","hy2"),
           ("8446","anytls"),("8447","trojan"),("8448","vm-ws"),("8449","shadowsocks"),
           ("8450","vl-grpc"),("8451","vl-ws-enc"),("8452","tuic"),("8453","any-reality")]
US_DIRECT_KEYS = ["vl-reality-vision","hy2","anytls","vm-ws","vl-xhttp-reality-enc"]
HK_IP = "38.76.210.194"


def b64d(text):
    text = text.strip()
    return base64.urlsafe_b64decode(text + "=" * ((4-len(text)%4)%4)).decode("utf-8", "ignore")


def vmess_obj(line):
    return json.loads(b64d(line.split("://",1)[1]))


def ss_parts(line):
    body_frag = line[5:]
    body, _, frag = body_frag.partition("#")
    query = ""
    if "?" in body:
        body, query = body.split("?",1)
    if "@" in body:
        userinfo, hostport = body.rsplit("@",1)
        try:
            auth = b64d(userinfo)
        except Exception:
            auth = urllib.parse.unquote(userinfo)
        if ":" not in auth:
            raise ValueError("SS userinfo 无效")
    else:
        decoded = b64d(body)
        auth, hostport = decoded.rsplit("@",1)
    method, password = auth.split(":",1)
    host, port = hostport.rsplit(":",1)
    return method, password, host.strip("[]"), port, query, urllib.parse.unquote(frag)


def parse(line):
    line = line.strip()
    scheme = line.split("://",1)[0].lower() if "://" in line else ""
    if scheme == "vmess":
        try:
            obj = vmess_obj(line)
            return {"name":obj.get("ps",""),"server":obj.get("add",""),"port":str(obj.get("port","")),"proto":"vmess"}
        except Exception:
            return {"name":"","server":"","port":"","proto":"vmess"}
    if scheme == "ss":
        try:
            method, password, host, port, query, name = ss_parts(line)
            return {"name":name,"server":host,"port":port,"proto":"ss"}
        except Exception:
            return {"name":"","server":"","port":"","proto":"ss"}
    try:
        u = urllib.parse.urlsplit(line)
        return {"name":urllib.parse.unquote(u.fragment),"server":u.hostname or "","port":str(u.port or ""),"proto":scheme}
    except Exception:
        return {"name":"","server":"","port":"","proto":scheme}


def valid(line):
    if "://" not in line:
        return False
    p = parse(line)
    low = p["name"].lower()
    if not p["server"] or not p["port"].isdigit() or not 1 <= int(p["port"]) <= 65535:
        return False
    return "argo" not in low and "cdn" not in low


def query(line):
    return urllib.parse.parse_qs(urllib.parse.urlsplit(line).query, keep_blank_values=True)


def qget(q, key, default=""):
    for k, values in q.items():
        if k.lower() == key.lower() and values:
            return values[0]
    return default


def is_enc(line):
    if not line.lower().startswith("vless://"):
        return False
    return qget(query(line), "encryption").lower() not in ("", "none")


def discover(lines):
    result = {}
    for line in lines:
        if not valid(line):
            continue
        name = parse(line)["name"].lower()
        for hk, kw in HK_PLAN:
            if kw in name:
                result.setdefault(kw, parse(line)["port"])
                break
    return result


def relay_line(line, hk_port):
    if not valid(line):
        return None
    p = parse(line)
    new_name = urllib.parse.quote("HK中转-" + p["name"], safe="")
    if p["proto"] == "vmess":
        obj = vmess_obj(line)
        obj["add"] = HK_IP
        obj["port"] = int(hk_port)
        obj["ps"] = "HK中转-" + obj.get("ps","")
        return "vmess://" + base64.b64encode(json.dumps(obj, ensure_ascii=False).encode()).decode()
    if p["proto"] == "ss":
        method, password, host, port, qs, name = ss_parts(line)
        auth = base64.urlsafe_b64encode((method+":"+password).encode()).decode().rstrip("=")
        return "ss://" + auth + "@" + HK_IP + ":" + str(hk_port) + (("?"+qs) if qs else "") + "#" + new_name
    u = urllib.parse.urlsplit(line)
    userinfo = u.netloc.rsplit("@",1)[0]
    return urllib.parse.urlunsplit((u.scheme, userinfo+"@"+HK_IP+":"+str(hk_port), u.path, u.query, new_name))


def unique_tag(base, used):
    tag = base or "node"
    i = 2
    while tag in used:
        tag = base + "-" + str(i)
        i += 1
    used.add(tag)
    return tag


def to_singbox(line, used):
    if is_enc(line) or not valid(line):
        return None
    p = parse(line)
    proto = p["proto"]
    o = {"tag":unique_tag(p["name"], used), "type":proto, "server":p["server"], "server_port":int(p["port"])}
    q = query(line)
    insecure = qget(q,"insecure") in ("1","true") or qget(q,"allowInsecure") in ("1","true") or bool(qget(q,"pinSHA256"))
    if proto == "vless":
        o["uuid"] = u_user(line)
        flow = qget(q,"flow")
        if flow: o["flow"] = flow
        sec = qget(q,"security")
        if sec in ("reality","tls"):
            o["tls"] = {"enabled":True,"server_name":qget(q,"sni"),"insecure":insecure}
            fp = qget(q,"fp")
            if fp: o["tls"]["utls"] = {"enabled":True,"fingerprint":fp}
            if sec == "reality":
                o["tls"]["reality"] = {"enabled":True,"public_key":qget(q,"pbk"),"short_id":qget(q,"sid")}
        net = qget(q,"type")
        if net == "ws":
            o["transport"] = {"type":"ws","path":qget(q,"path").lstrip("/"),"headers":{"Host":qget(q,"host")}}
        elif net == "grpc":
            o["transport"] = {"type":"grpc","service_name":qget(q,"serviceName")}
        elif net == "xhttp":
            o["transport"] = {"type":"http","path":"/"+qget(q,"path").lstrip("/")}
            if qget(q,"host"): o["transport"]["host"] = qget(q,"host")
        elif net == "httpupgrade":
            o["transport"] = {"type":"httpupgrade","path":"/"+qget(q,"path").lstrip("/"),"host":qget(q,"host")}
    elif proto == "vmess":
        obj = vmess_obj(line)
        o["uuid"] = obj.get("id","")
        o["security"] = obj.get("scy","auto")
        if obj.get("tls") == "tls":
            o["tls"] = {"enabled":True,"server_name":obj.get("sni") or obj.get("host",""),"insecure":insecure}
        if obj.get("net") == "ws":
            o["transport"] = {"type":"ws","path":obj.get("path","").lstrip("/"),"headers":{"Host":obj.get("host","")}}
        elif obj.get("net") == "grpc":
            o["transport"] = {"type":"grpc","service_name":obj.get("path","")}
        elif obj.get("net") == "httpupgrade":
            o["transport"] = {"type":"httpupgrade","path":obj.get("path",""),"host":obj.get("host","")}
    elif proto == "trojan":
        o["password"] = u_user(line)
        o["tls"] = {"enabled":True,"server_name":qget(q,"sni"),"insecure":insecure}
        if qget(q,"type") == "ws":
            o["transport"] = {"type":"ws","path":qget(q,"path").lstrip("/"),"headers":{"Host":qget(q,"host")}}
        elif qget(q,"type") == "grpc":
            o["transport"] = {"type":"grpc","service_name":qget(q,"serviceName")}
    elif proto == "ss":
        method, password, host, port, qs, name = ss_parts(line)
        o["method"] = method
        o["password"] = password
    elif proto == "hysteria2":
        o["password"] = u_user(line)
        o["tls"] = {"enabled":True,"server_name":qget(q,"sni"),"insecure":insecure,"alpn":["h3"]}
        if qget(q,"mport"): o["server_ports"] = [qget(q,"mport")]
    elif proto == "tuic":
        o["uuid"], o["password"] = u_user_pass(line)
        o["congestion_control"] = qget(q,"congestion_control","bbr")
        o["udp_relay_mode"] = qget(q,"udp_relay_mode","native")
        o["tls"] = {"enabled":True,"server_name":qget(q,"sni"),"insecure":insecure,"alpn":["h3"]}
    elif proto == "anytls":
        o["password"] = u_user(line)
        o["tls"] = {"enabled":True,"server_name":qget(q,"sni"),"insecure":insecure}
        if qget(q,"security") == "reality":
            o["tls"]["reality"] = {"enabled":True,"public_key":qget(q,"pbk"),"short_id":qget(q,"sid")}
            o["tls"]["utls"] = {"enabled":True,"fingerprint":qget(q,"fp","chrome")}
    else:
        return None
    return o


def u_user(line):
    return urllib.parse.urlsplit(line).netloc.rsplit("@",1)[0].split(":",1)[0]


def u_user_pass(line):
    auth = urllib.parse.urlsplit(line).netloc.rsplit("@",1)[0]
    return tuple(auth.split(":",1)) if ":" in auth else (auth,"")


def to_clash(line, used):
    if is_enc(line) or not valid(line):
        return None
    p = parse(line)
    proto = p["proto"]
    if proto == "anytls" and qget(query(line),"security") == "reality":
        return None
    o = {"name":unique_tag(p["name"],used),"type":proto,"server":p["server"],"port":int(p["port"])}
    q = query(line)
    insecure = qget(q,"insecure") in ("1","true") or qget(q,"allowInsecure") in ("1","true") or bool(qget(q,"pinSHA256"))
    if insecure: o["skip-cert-verify"] = True
    if proto == "vless":
        o["uuid"] = u_user(line)
        if qget(q,"flow"): o["flow"] = qget(q,"flow")
        sec = qget(q,"security")
        if sec in ("reality","tls"):
            o["tls"] = True
            o["servername"] = qget(q,"sni")
            o["client-fingerprint"] = qget(q,"fp","chrome")
            if sec == "reality":
                o["reality-opts"] = {"public-key":qget(q,"pbk"),"short-id":qget(q,"sid")}
        net = qget(q,"type")
        if net == "ws":
            o["network"] = "ws"; o["ws-opts"] = {"path":qget(q,"path"),"headers":{"Host":qget(q,"host")}}
        elif net == "grpc":
            o["network"] = "grpc"; o["grpc-opts"] = {"grpc-service-name":qget(q,"serviceName")}
        elif net == "xhttp":
            o["network"] = "xhttp"; o["xhttp-opts"] = {"path":qget(q,"path"),"mode":qget(q,"mode","auto")}
        elif net == "httpupgrade":
            o["network"] = "httpupgrade"; o["httpupgrade-opts"] = {"path":qget(q,"path"),"headers":{"Host":qget(q,"host")}}
        elif net == "tcp":
            o["network"] = "tcp"
    elif proto == "vmess":
        obj = vmess_obj(line)
        o.update({"uuid":obj.get("id",""),"alterId":int(obj.get("aid",0) or 0),"cipher":obj.get("scy","auto")})
        if obj.get("tls") == "tls":
            o["tls"] = True; o["servername"] = obj.get("sni") or obj.get("host","")
        if obj.get("net") == "ws":
            o["network"] = "ws"; o["ws-opts"] = {"path":obj.get("path",""),"headers":{"Host":obj.get("host","")}}
        elif obj.get("net") == "grpc":
            o["network"] = "grpc"; o["grpc-opts"] = {"grpc-service-name":obj.get("path","")}
        elif obj.get("net") == "httpupgrade":
            o["network"] = "httpupgrade"; o["httpupgrade-opts"] = {"path":obj.get("path",""),"headers":{"Host":obj.get("host","")}}
    elif proto == "trojan":
        o["password"] = u_user(line); o["sni"] = qget(q,"sni")
        if qget(q,"type") == "ws":
            o["network"] = "ws"; o["ws-opts"] = {"path":qget(q,"path"),"headers":{"Host":qget(q,"host")}}
        elif qget(q,"type") == "grpc":
            o["network"] = "grpc"; o["grpc-opts"] = {"grpc-service-name":qget(q,"serviceName")}
    elif proto == "ss":
        method, password, host, port, qs, name = ss_parts(line)
        o["cipher"] = method; o["password"] = password
    elif proto == "hysteria2":
        o["password"] = u_user(line); o["sni"] = qget(q,"sni"); o["alpn"] = ["h3"]
        if qget(q,"mport"): o["ports"] = qget(q,"mport")
    elif proto == "tuic":
        o["uuid"], o["password"] = u_user_pass(line)
        o["sni"] = qget(q,"sni"); o["alpn"] = ["h3"]
        o["congestion-controller"] = qget(q,"congestion_control","bbr")
        o["udp-relay-mode"] = qget(q,"udp_relay_mode","native")
    elif proto == "anytls":
        o["password"] = u_user(line); o["sni"] = qget(q,"sni")
    else:
        return None
    return o


def sing_config(lines):
    used, nodes, errors = set(), [], []
    for line in lines:
        try:
            o = to_singbox(line, used)
            if o: nodes.append(o)
            elif not is_enc(line): errors.append("sing-box 无法转换：" + parse(line)["name"])
        except Exception as e:
            errors.append("sing-box 转换失败：" + parse(line)["name"] + "（" + str(e) + "）")
    tags = [o["tag"] for o in nodes]
    cfg = {"log":{"level":"info","timestamp":True},"outbounds":[],
           "route":{"auto_detect_interface":True,"final":"proxy","rules":[{"ip_is_private":True,"action":"route","outbound":"direct"}]}}
    cfg["outbounds"] = nodes + [
        {"type":"selector","tag":"proxy","default":"auto" if tags else "direct","outbounds":(["auto"]+tags) if tags else ["direct"]},
        {"type":"urltest","tag":"auto","outbounds":tags or ["direct"],"url":"https://www.gstatic.com/generate_204","interval":"10m"},
        {"type":"direct","tag":"direct"}]
    return cfg, len(nodes), errors


def yaml_dump(v, indent=0):
    sp = " " * indent
    if isinstance(v, dict):
        if not v: return sp + "{}"
        out = []
        for k, val in v.items():
            if isinstance(val, (dict,list)) and val:
                out.append(sp + str(k) + ":\n" + yaml_dump(val, indent+2))
            else:
                out.append(sp + str(k) + ": " + yaml_scalar(val))
        return "\n".join(out)
    if isinstance(v, list):
        if not v: return sp + "[]"
        out = []
        for item in v:
            if isinstance(item, (dict,list)) and item:
                body = yaml_dump(item, indent+2)
                out.append(sp + "- " + body.lstrip())
            else:
                out.append(sp + "- " + yaml_scalar(item))
        return "\n".join(out)
    return sp + yaml_scalar(v)


def yaml_scalar(v):
    if v is True: return "true"
    if v is False: return "false"
    if v is None: return "null"
    if isinstance(v, (int,float)): return str(v)
    return json.dumps(str(v), ensure_ascii=False)


def clash_config(lines):
    used, nodes, errors = set(), [], []
    for line in lines:
        try:
            o = to_clash(line, used)
            if o: nodes.append(o)
            elif not is_enc(line) and not (parse(line)["proto"] == "anytls" and qget(query(line),"security") == "reality"):
                errors.append("Mihomo 无法转换：" + parse(line)["name"])
        except Exception as e:
            errors.append("Mihomo 转换失败：" + parse(line)["name"] + "（" + str(e) + "）")
    names = [o["name"] for o in nodes]
    cfg = {"port":7890,"allow-lan":True,"mode":"rule","log-level":"info","proxies":nodes,
           "proxy-groups":[
             {"name":"自动选择","type":"url-test","url":"https://www.gstatic.com/generate_204","interval":300,"proxies":names},
             {"name":"手动选择","type":"select","proxies":(["自动选择"]+names) if names else ["DIRECT"]}
           ],
           "rules":["GEOIP,CN,DIRECT","MATCH,手动选择"]}
    return yaml_dump(cfg) + "\n", len(nodes), errors
PYLIB

cat > /root/science/discover_relay.py <<'PYDISC'
#!/usr/bin/env python3
import sys
sys.path.insert(0, "/root/science")
from relaylib import HK_PLAN, discover
lines = [x.strip() for x in open(sys.argv[1], encoding="utf-8", errors="ignore") if x.strip()]
ports = discover(lines)
for hk, kw in HK_PLAN:
    if kw in ports:
        print(hk, ports[kw])
PYDISC

if [ "$ip" = "$US_IP" ]; then
  role=us
  echo "识别为美国服务器"
  hostnamectl set-hostname us 2>/dev/null || true
  get_science
  name="SKPL-LIFT" vlp=yes xhp=yes hyp=yes tup=yes anp=yes ssp=yes vmp=yes vmag=yes tjtp=yes vgp=yes vwp=yes arp=yes sub=y argo=vmpt agn="sss.hutton.dpdns.org" agk="$AGK" dnym="$US_DOMAIN" bash /root/science/new.sh rep || fail "美国节点重装失败"
  US_TOKEN="${US_TOKEN:-$(cat /root/science/subtoken.log 2>/dev/null)}"
  [ -n "$US_TOKEN" ] || fail "未找到美国订阅 Token"
  HK_TOKEN="${HK_TOKEN:-$(cat /root/science/hk_token.log 2>/dev/null)}"
  [ -n "$HK_TOKEN" ] || fail "请通过 HK_TOKEN 指定香港订阅 Token（读取香港 /root/science/subtoken.log）"
  echo "$HK_TOKEN" > /root/science/hk_token.log
  chmod 600 /root/science/hk_token.log
  if [ -z "$HK_BASE" ] && [ "${ALLOW_INSECURE_HTTP:-0}" = "1" ]; then
    HK_BASE="http://$HK_IP:$HK_PORT/$HK_TOKEN"
    echo "警告：本次使用明文 HTTP 拉取香港订阅，请尽快改为有效 HTTPS 地址"
  fi
  [ -n "$HK_BASE" ] || fail "请设置 HK_BASE=https://香港域名或地址/香港Token（不要把 Token 写入公开脚本）；禁止默认明文 HTTP"
  case "$HK_BASE" in
    https://*) ;;
    http://*) [ "${ALLOW_INSECURE_HTTP:-0}" = "1" ] || fail "HK_BASE 为 HTTP 时必须显式设置 ALLOW_INSECURE_HTTP=1，建议改用 HTTPS" ;;
    *) fail "HK_BASE 必须是 HTTPS URL（现有 busybox 地址如需兼容，须显式允许 HTTP）" ;;
  esac
  open_firewall us

  cat > /root/science/aggregate.py <<'PYAGG'
#!/usr/bin/env python3
import base64, json, os, sys, time, urllib.request, fcntl
sys.path.insert(0, "/root/science")
from relaylib import *

WEB = "/root/websbx/__US_TOKEN__"
HK_BASE = "__HK_BASE__"
BRAND = "SKPL-LIFT"
MAX_NODE = 12
os.makedirs(WEB, exist_ok=True)
lock = open("/root/science/aggregate.lock","w")
try:
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
except OSError:
    print("已有聚合任务运行，跳过")
    sys.exit(0)


def atomic_write(name, content):
    path = os.path.join(WEB, name)
    tmp = path + ".tmp"
    with open(tmp,"w",encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp,path)


def manifest_base(status, errors=None):
    return {"brand":BRAND,"status":status,"generated_at":time.strftime("%Y-%m-%d %H:%M:%S"),
            "errors":errors or [],"counts":{"us_direct":0,"hk_relay":0,"hk_direct":0,"total":0},
            "nodes":[],"clients":[],"formats":{}}


def fetch_hk():
    url = HK_BASE.rstrip("/") + "/SKPL-LIFT.txt"
    req = urllib.request.Request(url, headers={"User-Agent":"science-aggregate/3"})
    with urllib.request.urlopen(req, timeout=20) as r:
        if r.status != 200:
            raise RuntimeError("香港订阅 HTTP " + str(r.status))
        text = r.read().decode("utf-8","ignore")
    if "://" not in text:
        raise RuntimeError("香港订阅不是有效节点文件")
    return text


def node_meta(line, role):
    p = parse(line)
    return {"name":p["name"],"proto":p["proto"],"server":p["server"],"port":int(p["port"]),"role":role}


def select_nodes(family, allowed):
    return [x for x in family if parse(x)["proto"] in allowed and not is_enc(x)][:MAX_NODE]


def main():
    errors = []
    us_lines = [x.strip() for x in open("/root/science/jhsub.txt",encoding="utf-8",errors="ignore") if x.strip() and valid(x.strip())]
    if not us_lines:
        raise RuntimeError("美国 jhsub.txt 没有有效节点")
    ports = discover(us_lines)
    us_direct = []
    relay_src = {}
    for line in us_lines:
        name = parse(line)["name"].lower()
        if any(k in name for k in US_DIRECT_KEYS) and line not in us_direct:
            us_direct.append(line)
        for hk, kw in HK_PLAN:
            if kw in name and ports.get(kw) == parse(line)["port"]:
                relay_src.setdefault(kw,line)
                break
    missing = [kw for hk,kw in HK_PLAN if kw not in ports]
    if missing:
        raise RuntimeError("美国中转映射不完整：" + ", ".join(missing))
    if len(us_direct) < 5:
        raise RuntimeError("美国直连候选不足 5 个，当前 %d 个" % len(us_direct))

    hk_text = fetch_hk()
    hk_direct = []
    for line in hk_text.splitlines():
        line = line.strip()
        if valid(line) and parse(line)["server"] == HK_IP and line not in hk_direct:
            hk_direct.append(line)
    if len(hk_direct) < 5:
        raise RuntimeError("香港直连有效节点不足 5 个；请检查香港地址、订阅源和 HK_BASE，当前 %d 个" % len(hk_direct))

    relay = []
    for hk, kw in HK_PLAN:
        line = relay_line(relay_src[kw], hk)
        if not line or parse(line)["server"] != HK_IP or parse(line)["port"] != hk:
            raise RuntimeError("中转地址重写失败：" + kw)
        relay.append(line)

    family = relay + hk_direct + us_direct
    atomic_write(BRAND+"-all.txt", "\n".join(family)+"\n")

    sing, sing_count, sing_errors = sing_config(family)
    atomic_write(BRAND+"-all.json", json.dumps(sing,ensure_ascii=False,indent=2)+"\n")
    clash, clash_count, clash_errors = clash_config(family)
    atomic_write(BRAND+"-all.yaml", clash)
    errors.extend(sing_errors + clash_errors)

    definitions = [
        ("Hiddify","hiddify","txt",{"vless","vmess","trojan","ss","hysteria2","tuic","anytls"}),
        ("sing-box","singbox","json",{"vless","vmess","trojan","ss","hysteria2","tuic","anytls"}),
        ("Clash/Mihomo","clash","yaml",{"vless","vmess","trojan","ss","hysteria2","tuic","anytls"}),
        ("v2rayN","v2rayn","txt",{"vless","vmess","trojan"}),
        ("Shadowrocket","shadowrocket","txt",{"vless","vmess","trojan","ss","hysteria2","tuic"})
    ]
    clients = []
    for title, slug, ext, allowed in definitions:
        selected = select_nodes(family, allowed)
        if not selected:
            raise RuntimeError(title + " 没有可用节点")
        filename = "%s-%s.%s" % (BRAND,slug,ext)
        if slug == "singbox":
            cfg, count, errs = sing_config(selected)
            content = json.dumps(cfg,ensure_ascii=False,indent=2)+"\n"
            fmt = "sing-box JSON"
        elif slug == "clash":
            content, count, errs = clash_config(selected)
            fmt = "Mihomo YAML"
        else:
            count = len(selected)
            errs = []
            plain = "\n".join(selected)+"\n"
            if slug in ("v2rayn","shadowrocket"):
                content = base64.b64encode(plain.encode()).decode()+"\n"
                fmt = "Base64 订阅"
            else:
                content = plain
                fmt = "分享链接订阅"
        atomic_write(filename,content)
        errors.extend(errs)
        clients.append({"name":title,"file":filename,"nodes":count,"format":fmt})
        if count > MAX_NODE:
            raise RuntimeError(title + " 超过 12 个节点")

    nodes = [node_meta(x,"hk_relay") for x in relay] + [node_meta(x,"hk_direct") for x in hk_direct] + [node_meta(x,"us_direct") for x in us_direct]
    manifest = manifest_base("error" if errors else "ok", errors)
    manifest["counts"] = {"us_direct":len(us_direct),"hk_relay":len(relay),"hk_direct":len(hk_direct),"total":len(family)}
    manifest["nodes"] = nodes
    manifest["clients"] = clients
    manifest["formats"] = {
        "family_txt":{"file":BRAND+"-all.txt","nodes":len(family)},
        "family_json":{"file":BRAND+"-all.json","nodes":sing_count},
        "family_yaml":{"file":BRAND+"-all.yaml","nodes":clash_count}
    }
    atomic_write(BRAND+"-manifest.json",json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    print("聚合完成：美国直连 %d，香港中转 %d，香港直连 %d，客户端转换警告 %d" % (len(us_direct),len(relay),len(hk_direct),len(errors)))

try:
    main()
except Exception as exc:
    manifest = manifest_base("error",[str(exc)])
    atomic_write(BRAND+"-manifest.json",json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    print("聚合失败：" + str(exc), file=sys.stderr)
    sys.exit(1)
PYAGG
  sed -i "s|__US_TOKEN__|$US_TOKEN|g; s|__HK_BASE__|$HK_BASE|g" /root/science/aggregate.py
  python3 -m py_compile /root/science/relaylib.py /root/science/discover_relay.py /root/science/aggregate.py || fail "Python 语法检查失败"
  python3 /root/science/aggregate.py || fail "聚合生成失败，详见上方错误"
  (crontab -l 2>/dev/null | grep -v 'python3 /root/science/aggregate.py'; echo "*/2 * * * * python3 /root/science/aggregate.py >> /root/science/aggregate.log 2>&1 #science-aggregate") | crontab - || fail "聚合 cron 写入失败"
  echo "====================================================="
  echo "美国部署完成"
  echo "面板：https://$US_DOMAIN/index.html"
  echo "manifest：https://$US_DOMAIN/SKPL-LIFT-manifest.json"
  echo "请确认云安全组放行实际节点端口及 80/443/$US_PORT"
  echo "====================================================="

elif [ "$ip" = "$HK_IP" ]; then
  role=hk
  echo "识别为香港服务器"
  hostnamectl set-hostname hk 2>/dev/null || true
  get_science
  name="SKPL-LIFT" vlp=yes xhp=yes hyp=yes anp=yes vmp=yes sub=y bash /root/science/new.sh rep || fail "香港节点重装失败"
  HK_TOKEN="${HK_TOKEN:-$(cat /root/science/subtoken.log 2>/dev/null)}"
  [ -n "$HK_TOKEN" ] || fail "未找到香港订阅 Token"
  open_firewall hk
  grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
  sysctl -w net.ipv4.ip_forward=1 >/dev/null || fail "无法开启 IP 转发"

  cat > /root/science/hk_relay.sh <<'PYRELAY'
#!/bin/bash
export LANG=en_US.UTF-8
US_IP="__US_IP__"
US_DOMAIN="__US_DOMAIN__"
RULES=/root/science/hk_relay.rules
LOG=/root/science/hk_relay.log
LOCK=/root/science/hk_relay.lock
exec 9>"$LOCK"
flock -n 9 || exit 0
log() { echo "$(date '+%F %T') $*" >> "$LOG"; }
tmp=$(mktemp /tmp/us_jhsub.XXXXXX) || exit 1
trap 'rm -f "$tmp"' EXIT
if ! curl -fsS --max-time 20 "https://$US_DOMAIN/jhsub.txt" -o "$tmp" || ! grep -q '://' "$tmp"; then
  log "美国订阅拉取或内容校验失败，保留现有中转规则"
  exit 1
fi
map=$(python3 /root/science/discover_relay.py "$tmp") || { log "端口发现失败"; exit 1; }
count=$(printf '%s\n' "$map" | grep -c '^84')
[ "$count" -eq 11 ] || { log "仅发现 $count/11 条映射，保留现有规则"; exit 1; }

# 先备份现有规则，再更新；任何一步失败都恢复备份，避免留下半套中转。
backup_rules=$(mktemp) || exit 1
new_rules=$(mktemp) || { rm -f "$backup_rules"; exit 1; }
masq_added=0

capture_rules() {
  : > "$backup_rules"
  [ -f "$RULES" ] && grep '^dnat ' "$RULES" > "$backup_rules" 2>/dev/null || true
  iptables -t nat -S PREROUTING 2>/dev/null | while read -r line; do
    case "$line" in
      *"--to-destination $US_IP:"*)
        for hk in 8443 8444 8445 8446 8447 8448 8449 8450 8451 8452 8453; do
          case "$line" in
            *"--dport $hk "*)
              us=${line##*:}; us=${us%% *}
              grep -qx "dnat $hk $us" "$backup_rules" 2>/dev/null || echo "dnat $hk $us" >> "$backup_rules"
              break ;;
          esac
        done ;;
    esac
  done
}

clear_relays() {
  iptables -t nat -S PREROUTING 2>/dev/null | while read -r line; do
    case "$line" in
      *"--to-destination $US_IP:"*)
        for hk in 8443 8444 8445 8446 8447 8448 8449 8450 8451 8452 8453; do
          case "$line" in
            *"--dport $hk "*)
              iptables -t nat -D PREROUTING ${line#-A PREROUTING } >/dev/null 2>&1 || true
              break ;;
          esac
        done ;;
    esac
  done
}

rollback() {
  local reason="$1" kind hk us
  clear_relays
  while read -r kind hk us; do
    [ "$kind" = dnat ] || continue
    iptables -t nat -A PREROUTING -p tcp --dport "$hk" -j DNAT --to-destination "$US_IP:$us" >/dev/null 2>&1 || true
    iptables -t nat -A PREROUTING -p udp --dport "$hk" -j DNAT --to-destination "$US_IP:$us" >/dev/null 2>&1 || true
  done < "$backup_rules"
  [ "$masq_added" -eq 1 ] && iptables -t nat -D POSTROUTING -d "$US_IP" -j MASQUERADE >/dev/null 2>&1 || true
  rm -f "$backup_rules" "$new_rules"
  log "$reason；已恢复更新前规则"
  exit 1
}

capture_rules
clear_relays
for hk in 8443 8444 8445 8446 8447 8448 8449 8450 8451 8452 8453; do
  us=$(printf '%s\n' "$map" | awk -v p="$hk" '$1==p{print $2;exit}')
  case "$us" in ''|*[!0-9]*) rollback "端口映射无效" ;; esac
  [ "$us" -ge 1 ] && [ "$us" -le 65535 ] || rollback "端口超出范围"
  iptables -t nat -A PREROUTING -p tcp --dport "$hk" -j DNAT --to-destination "$US_IP:$us" && \
  iptables -t nat -A PREROUTING -p udp --dport "$hk" -j DNAT --to-destination "$US_IP:$us" || rollback "DNAT 写入失败"
  echo "dnat $hk $us" >> "$new_rules"
done
[ "$(wc -l < "$new_rules")" -eq 11 ] || rollback "DNAT 数量不足"

out_if=$(ip -4 route get "$US_IP" 2>/dev/null | sed -n 's/.*dev \([^ ]*\).*/\1/p' | head -1)
[ -n "$out_if" ] || rollback "无法确定到美国的出口接口"
if ! iptables -t nat -C POSTROUTING -o "$out_if" -d "$US_IP" -j MASQUERADE >/dev/null 2>&1; then
  iptables -t nat -A POSTROUTING -o "$out_if" -d "$US_IP" -j MASQUERADE && masq_added=1 || rollback "MASQUERADE 写入失败"
fi
iptables -C FORWARD -d "$US_IP" -j ACCEPT >/dev/null 2>&1 || iptables -A FORWARD -d "$US_IP" -j ACCEPT || rollback "FORWARD 放行失败"
iptables -C FORWARD -s "$US_IP" -j ACCEPT >/dev/null 2>&1 || iptables -A FORWARD -s "$US_IP" -j ACCEPT || rollback "FORWARD 回程放行失败"
if command -v netfilter-persistent >/dev/null 2>&1; then
  netfilter-persistent save || rollback "规则持久化失败"
elif command -v rc-service >/dev/null 2>&1; then
  rc-update show default 2>/dev/null | grep -q iptables || rc-update add iptables >/dev/null 2>&1
  rc-service iptables save || rollback "规则持久化失败"
else
  log "警告：未找到规则持久化工具，重启后需由 cron 重建"
fi
mv "$new_rules" "$RULES"
rm -f "$backup_rules"
log "中转刷新成功：$count 条，出口 $out_if"
PYRELAY
  sed -i "s|__US_IP__|$US_IP|g; s|__US_DOMAIN__|$US_DOMAIN|g" /root/science/hk_relay.sh
  chmod +x /root/science/hk_relay.sh
  bash -n /root/science/hk_relay.sh || fail "中转脚本语法错误"
  /root/science/hk_relay.sh || fail "香港中转配置失败，详见 /root/science/hk_relay.log"
  (crontab -l 2>/dev/null | grep -v '/root/science/hk_relay.sh'; echo "*/2 * * * * /root/science/hk_relay.sh >/dev/null 2>&1 #science-hk-relay") | crontab - || fail "中转 cron 写入失败"
  echo "====================================================="
  echo "香港部署完成：11 条中转规则，端口跟随美国每 2 分钟刷新"
  echo "请确认云安全组放行 8443-8453、实际节点端口及 $HK_PORT"
  echo "====================================================="
fi
