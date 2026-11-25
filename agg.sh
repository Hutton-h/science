#!/bin/bash
# SKPL-LIFT 美国 VPS 节点与统一订阅部署脚本
# 配置可通过环境变量覆盖；订阅 Token 和 Argo Token 不写入公开仓库。
export LANG=en_US.UTF-8

GH_URL="${GH_URL:-https://api.github.com/repos/Hutton-h/science/contents/science.sh}"
PANEL_GH_URL="${PANEL_GH_URL:-https://api.github.com/repos/Hutton-h/science/contents/panel.html?ref=main}"
PANEL_SHA256="ae34618dc54cc97240287731bc596b05dc2bdfde52bf72241794f3e30f0e9230"
PANEL_ONLY="${PANEL_ONLY:-0}"
US_IP="${US_IP:-67.21.76.151}"
US_DOMAIN="${US_DOMAIN:-s.hutton.dpdns.org}"
US_PORT="${US_PORT:-60451}"
US_TOKEN="${US_TOKEN:-}"
AGK="${AGK:-}"

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
[ "$ip" = "$US_IP" ] || fail "该 IP 不属于美国服务器"
case "$PANEL_ONLY" in 0|1) ;; *) fail "PANEL_ONLY 只能为 0 或 1" ;; esac
[ "$PANEL_ONLY" != "1" ] || [ "${NODECHECK:-0}" != "1" ] || fail "PANEL_ONLY=1 不能与 NODECHECK=1 同时使用"

get_science() {
  curl -fsSL --max-time 60 -H "Accept: application/vnd.github.raw" "$GH_URL" -o /root/science/new.sh || fail "science.sh 下载失败"
  grep -q 'cip(){' /root/science/new.sh || fail "下载到的 science.sh 内容不正确"
  chmod +x /root/science/new.sh
}

install_panel_only() {
  local tmp installed_hash final_hash link
  tmp=$(mktemp /root/science/.panel.XXXXXX) || fail "无法创建面板临时文件"
  curl -fsSL --max-time 60 -H "Accept: application/vnd.github.raw" "$PANEL_GH_URL" -o "$tmp" || { rm -f "$tmp"; fail "panel.html 下载失败"; }
  grep -q '<title>SKPL-LIFT 订阅中心</title>' "$tmp" || { rm -f "$tmp"; fail "panel.html 内容校验失败"; }
  grep -q 'SKPL-LIFT-private.js' "$tmp" && grep -q 'family_base64' "$tmp" || { rm -f "$tmp"; fail "panel.html 缺少单节点复制或全体总订阅功能"; }
  printf '%s  %s\n' "$PANEL_SHA256" "$tmp" | sha256sum -c - >/dev/null || { rm -f "$tmp"; fail "panel.html 下载摘要与已审核版本不一致"; }
  chmod 644 "$tmp" || { rm -f "$tmp"; fail "panel.html 权限设置失败"; }
  mv -f "$tmp" /root/science/panel.html || { rm -f "$tmp"; fail "panel.html 原子安装失败"; }
  installed_hash=$(sha256sum /root/science/panel.html | awk '{print $1}')
  [ "$installed_hash" = "$PANEL_SHA256" ] || fail "panel.html 安装后 SHA256 校验失败"
  link="/root/websbx/$US_TOKEN/index.html"
  mkdir -p "/root/websbx/$US_TOKEN" || fail "无法创建面板发布目录"
  ln -sfn /root/science/panel.html "$link" || fail "index.html 软链更新失败"
  [ -L "$link" ] && [ "$(readlink "$link")" = "/root/science/panel.html" ] || fail "index.html 软链指向不正确"
  final_hash=$(sha256sum "$link" | awk '{print $1}')
  [ "$final_hash" = "$PANEL_SHA256" ] || fail "发布后的 panel.html SHA256 校验失败"
  echo "最终 panel.html SHA256：$final_hash"
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

def unique_tag(base, used):
    tag = base or "node"
    i = 2
    while tag in used:
        tag = base + "-" + str(i)
        i += 1
    used.add(tag)
    return tag

def to_singbox(line, used):
    if is_enc(line):
        return None
    p0 = parse(line)
    if not p0["server"] or not p0["port"].isdigit():
        return None
    p = parse(line)
    proto = p["proto"]
    o = {"tag":unique_tag(p["name"], used), "type":"shadowsocks" if proto == "ss" else proto, "server":p["server"], "server_port":int(p["port"])}
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
    if is_enc(line):
        return None
    p0 = parse(line)
    if not p0["server"] or not p0["port"].isdigit():
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

NODECHECK_SHA256="ec465a291d2a6357e36cba84caa07889f186b0669540b91269d197cf9231eba7"
fetch_nodecheck() {
  local tmp
  tmp=$(mktemp /root/science/.nodecheck.XXXXXX) || return 1
  curl -fsSL --max-time 60 -H "Accept: application/vnd.github.raw" "https://api.github.com/repos/Hutton-h/science/contents/nodecheck.py?ref=main" -o "$tmp" || { rm -f "$tmp"; return 1; }
  printf '%s  %s\n' "$NODECHECK_SHA256" "$tmp" | sha256sum -c - >/dev/null || { rm -f "$tmp"; return 1; }
  python3 -m py_compile "$tmp" || { rm -f "$tmp"; return 1; }
  chmod 700 "$tmp" && mv -f "$tmp" /root/science/nodecheck.py
}

# 面板节点状态：定时拨测后只发布白名单字段（id/状态/延迟/速度/时间），不含任何链接、UUID、密码。
install_nodestatus() {
  if ! fetch_nodecheck; then
    echo "提示：nodecheck.py 获取或校验失败，面板暂不显示节点状态（不影响订阅）"
    return 0
  fi
  cat > /root/science/nodestatus.py <<'PYSTAT'
#!/usr/bin/env python3
import json, os, pathlib, re, subprocess, sys
WEB = pathlib.Path("/root/websbx/__US_TOKEN__")
SUB = WEB / "SKPL-LIFT-all.txt"
OUT = WEB / "SKPL-LIFT-nodestatus.json"
RAW = pathlib.Path("/root/science/nodecheck-us.json")
ID_RE = re.compile(r"^[0-9a-f]{16}$")
STATUSES = {"ok", "fallback_ok", "failed"}

def num(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or value < 0:
        return None
    return int(value)

def main():
    if not SUB.is_file():
        sys.exit("缺少全体订阅文件")
    rc = subprocess.run([sys.executable, "/root/science/nodecheck.py", "--vantage", "us", "--roles", "all",
                         "--run-id", "panel", "--subscription", str(SUB), "--output", str(RAW)],
                        timeout=1400).returncode
    if rc != 0:
        sys.exit("拨测失败：%d" % rc)
    data = json.loads(RAW.read_text(encoding="utf-8"))
    nodes = {}
    for node in data.get("nodes", []):
        nid, status = node.get("id"), node.get("status")
        if not isinstance(nid, str) or not ID_RE.match(nid) or status not in STATUSES:
            continue
        nodes[nid] = {"status": status, "latency_ms": num(node.get("latency_ms")),
                      "speed_Bps": num(node.get("speed_Bps")),
                      "checked_at": str(node.get("checked_at") or "")[:32]}
    summary = data.get("summary", {})
    payload = {"version": 1, "vantage": "us",
               "finished_at": str(summary.get("finished_at") or "")[:32], "nodes": nodes}
    tmp = OUT.with_name(OUT.name + ".tmp")
    tmp.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    os.chmod(tmp, 0o644)
    os.replace(tmp, OUT)
    print("节点状态已发布：%d 个" % len(nodes))

if __name__ == "__main__":
    main()
PYSTAT
  sed -i "s|__US_TOKEN__|$US_TOKEN|g" /root/science/nodestatus.py
  chmod 700 /root/science/nodestatus.py
  if ! python3 -m py_compile /root/science/nodestatus.py; then
    echo "提示：nodestatus.py 语法检查失败，跳过节点状态"
    return 0
  fi
  cat > /root/science/nodestatus.sh <<'SHSTAT'
#!/bin/bash
exec 9>/root/science/nodestatus.lock
flock -n 9 || exit 0
cd /root/science || exit 1
timeout 1500 python3 /root/science/nodestatus.py > /root/science/nodestatus.log 2>&1
SHSTAT
  chmod 700 /root/science/nodestatus.sh
  (crontab -l 2>/dev/null | grep -v '/root/science/nodestatus.sh'; echo "*/30 * * * * /root/science/nodestatus.sh >/dev/null 2>&1 #science-nodestatus") | crontab - || { echo "提示：节点状态 cron 写入失败"; return 0; }
  nohup /root/science/nodestatus.sh >/dev/null 2>&1 &
  echo "节点状态拨测已启用：每 30 分钟一次，首轮已在后台开始（约数分钟）"
}

if [ "${NODECHECK:-0}" = "1" ]; then
  role=us
  fetch_nodecheck || fail "nodecheck.py 下载、摘要或语法校验失败"
  python3 /root/science/nodecheck.py --vantage "$role" --run-id "${RUN_ID:-pre-fix}" --subscription https://s.hutton.dpdns.org/SKPL-LIFT-all.txt --output "/root/science/nodecheck-$role.json" || fail "节点拨测执行失败"
  exit 0
fi

if [ "$ip" = "$US_IP" ]; then
  role=us
  if [ "$PANEL_ONLY" = "1" ]; then
    echo "识别为美国服务器：PANEL_ONLY=1，只更新聚合与面板"
  else
    echo "识别为美国服务器"
    hostnamectl set-hostname us 2>/dev/null || true
    get_science
    name="SKPL-LIFT" vlp=yes xhp=yes hyp=yes tup=yes anp=yes ssp=yes vmp=yes vmag=yes tjtp=yes vgp=yes vwp=yes arp=yes sub=y argo=vmpt agn="sss.hutton.dpdns.org" agk="$AGK" dnym="$US_DOMAIN" bash /root/science/new.sh rep || fail "美国节点重装失败"
  fi
  US_PORT=$(cat /root/science/subport.log 2>/dev/null)
  [ -n "$US_PORT" ] || fail "未找到美国实际订阅端口"
  US_TOKEN="${US_TOKEN:-$(cat /root/science/subtoken.log 2>/dev/null)}"
  [ -n "$US_TOKEN" ] || fail "未找到美国订阅 Token"

  if [ "$PANEL_ONLY" != "1" ]; then
    open_firewall us
  fi

  cat > /root/science/aggregate.py <<'PYAGG'
#!/usr/bin/env python3
import base64, hashlib, json, os, pathlib, shutil, subprocess, sys, time, urllib.request, fcntl
sys.path.insert(0, "/root/science")
from relaylib import *

WEB = pathlib.Path("/root/websbx/__US_TOKEN__")
GOOD = WEB / "last_good"
CACHE = pathlib.Path("/root/science/aggregate_cache")
STAGE = WEB / ".aggregate_stage"
BRAND = "SKPL-LIFT"
WEB.mkdir(parents=True, exist_ok=True)
GOOD.mkdir(parents=True, exist_ok=True)
CACHE.mkdir(parents=True, exist_ok=True)
shutil.rmtree(STAGE, ignore_errors=True)
STAGE.mkdir(parents=True, exist_ok=True)
lock = open("/root/science/aggregate.lock","w")
try:
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
except OSError:
    print("已有聚合任务运行，跳过")
    sys.exit(0)

def now():
    return time.strftime("%Y-%m-%d %H:%M:%S")

def atomic_path(path, content):
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content, encoding="utf-8")
    os.replace(tmp, path)

def atomic_write(name, content):
    atomic_path(WEB / name, content)

def read_json(path, default=None):
    try:
        return json.loads(pathlib.Path(path).read_text(encoding="utf-8"))
    except Exception:
        return {} if default is None else default

def manifest_base(status, errors=None):
    return {"brand":BRAND,"status":status,"stale":status != "ok",
            "updated_at":now(),"last_success":None,"errors":errors or [],
            "counts":{"us_direct":0,"us_argo":0,"total":0},
            "nodes":[],"clients":[],"formats":{},"sources":{}}

def source_state(nodes, stale=False, last_success=None, errors=None, extra=None):
    errors = errors or []
    state = {"status":"degraded" if stale or errors else "ok",
             "stale":bool(stale),"nodes":len(nodes),"last_success":last_success,
             "errors":errors}
    if extra:
        state.update(extra)
    return state

def save_cache(name, text):
    atomic_path(CACHE / name, text)
    atomic_path(CACHE / (name + ".meta.json"), json.dumps({"last_success":now()}, ensure_ascii=False))

def cached_lines(name):
    path = CACHE / name
    if not path.exists():
        return [], None
    lines = [x.strip() for x in path.read_text(encoding="utf-8", errors="ignore").splitlines() if x.strip()]
    meta = read_json(path.with_suffix(path.suffix + ".meta.json"))
    return lines, meta.get("last_success")



def is_argo_running():
    try:
        return subprocess.run(["pgrep","-f","science/cloudflared"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode == 0
    except Exception:
        return False

def select_us_argo(raw_lines):
    candidates, seen_ports = [], set()
    running = is_argo_running()
    if running:
        for line in raw_lines:
            try:
                p = parse(line)
                if p["proto"] != "vmess" or p["port"] not in ("443","8443") or p["port"] in seen_ports:
                    continue
                if "argo" not in p["name"].lower() or "tls" not in p["name"].lower():
                    continue
                obj = vmess_obj(line)
                if obj.get("tls") != "tls" or not obj.get("host") or not obj.get("sni") or not obj.get("add"):
                    continue
                candidates.append(line)
                seen_ports.add(p["port"])
                if len(candidates) == 2:
                    break
            except Exception:
                continue
    lines, last_success = cached_lines("us_argo.txt")
    if len(candidates) < 2 and lines:
        # 只有一个（或没有）备用端口时，不要覆盖双节点缓存，保留上次完整配置。
        if len(lines) >= 2:
            return lines, source_state(lines, True, last_success, ["Argo 备用节点不足 2 个，使用上次成功配置"])
        lines, last_success = candidates or lines, last_success
    if candidates:
        save_cache("us_argo.txt", "\n".join(candidates)+"\n")
        if len(candidates) < 2:
            return candidates, source_state(candidates, True, now(), ["Argo 备用节点只有 1 个"])
        return candidates, source_state(candidates, False, now())
    if lines:
        return lines, source_state(lines, True, last_success, ["Argo 当前未运行或没有 443/8443 备用节点，使用上次成功配置"])
    return [], source_state([], True, last_success, ["Argo 未运行或没有可用的 443/8443 备用节点"])

def role_of(line):
    name = parse(line)["name"]
    if "argo" in name.lower():
        return "us_argo"
    return "us_direct"

def is_reality(line):
    # VLESS/AnyTLS 带 security=reality 的节点：sing-box 核心（Hiddify 默认）不兼容新版 Xray Reality，需剔除。
    if not line.lower().startswith(("vless://", "anytls://")):
        return False
    return qget(query(line), "security").lower() == "reality"

def is_argo(line):
    return "argo" in parse(line)["name"].lower()

def select_nodes(family, allowed, hide_reality_argo=False):
    # 不再按角色分配或限制数量；仅按客户端可解析的协议过滤，并保持 family 顺序。
    return [line for line in family
            if parse(line)["proto"] in allowed and not is_enc(line)
            and not (hide_reality_argo and (is_reality(line) or is_argo(line)))]

def node_id(line):
    return hashlib.sha256(line.encode("utf-8")).hexdigest()[:16]

def node_meta(line, role):
    p = parse(line)
    return {"id":node_id(line),"name":p["name"],"proto":p["proto"],"server":p["server"],"port":int(p["port"]),"role":role}

def publish_atomic():
    shutil.rmtree(STAGE, ignore_errors=True)
    STAGE.mkdir(parents=True, exist_ok=True)
    for path in WEB.iterdir():
        if path.is_file():
            shutil.copy2(path, STAGE / path.name)
    for old in GOOD.iterdir():
        if old.is_file() and old.name not in {p.name for p in STAGE.iterdir()}:
            old.unlink()
    for path in STAGE.iterdir():
        if path.is_file():
            tmp = GOOD / (path.name + ".new")
            shutil.copy2(path, tmp)
            os.replace(tmp, GOOD / path.name)

def main():
    raw_us = [x.strip() for x in open("/root/science/jhsub.txt",encoding="utf-8",errors="ignore").read().splitlines() if x.strip()]
    # 美国 UDP 已实测可用且速度优于 TCP（HY2/TUIC），直连放行。
    us_lines = [x for x in raw_us if valid(x)]
    if not us_lines and not raw_us:
        raise RuntimeError("美国 jhsub.txt 为空")

    us_direct = []
    for line in us_lines:
        if "argo" not in parse(line)["name"].lower() and line not in us_direct:
            us_direct.append(line)

    def dedup(items):
        out = []
        for x in items:
            if x not in out:
                out.append(x)
        return out

    us_argo_raw, argo_source = select_us_argo(raw_us)
    us_argo = dedup(us_argo_raw)
    argo_source["nodes"] = len(us_argo)
    if not us_direct:
        usd_source = source_state([], False, now(), ["美国直连为空"])
    else:
        usd_source = source_state(us_direct, False, now())

    family = []
    for line in us_direct + us_argo:
        if line not in family:
            family.append(line)
    if not family:
        raise RuntimeError("没有任何可发布的有效节点")

    family_text = "\n".join(family)+"\n"
    atomic_write(BRAND+"-all.txt", family_text)
    atomic_write(BRAND+"-all-base64.txt", base64.b64encode(family_text.encode("utf-8")).decode("ascii")+"\n")
    sing, sing_count, sing_errors = sing_config(family)
    atomic_write(BRAND+"-all.json", json.dumps(sing,ensure_ascii=False,indent=2)+"\n")
    clash, clash_count, clash_errors = clash_config(family)
    atomic_write(BRAND+"-all.yaml", clash)

    definitions = [
        ("Hiddify","hiddify","txt",{"vless","vmess","trojan","ss","hysteria2","tuic","anytls"}),
        ("sing-box","singbox","json",{"vless","vmess","trojan","ss","hysteria2","tuic","anytls"}),
        ("Clash/Mihomo","clash","yaml",{"vless","vmess","trojan","ss","hysteria2","tuic","anytls"}),
        ("v2rayN","v2rayn","txt",{"vless","vmess","trojan"}),
        ("Shadowrocket","shadowrocket","txt",{"vless","vmess","trojan","ss","hysteria2","tuic"})
    ]
    clients, conversion_errors = [], sing_errors + clash_errors
    # sing-box / Mihomo 与 Hiddify 同为 sing-box/utls 系核心：Reality 不兼容新版 Xray（上游 issue #4520），Argo 实测不通，统一剔除。
    # v2rayN / Shadowrocket 为 Xray 系核心，Reality/Argo 全兼容，保留全部。
    for title, slug, ext, allowed in definitions:
        selected = select_nodes(family, allowed, hide_reality_argo=(slug in ("hiddify", "singbox", "clash")))
        if not selected:
            raise RuntimeError(title + " 没有兼容节点")
        filename = "%s-%s.%s" % (BRAND,slug,ext)
        # Hiddify 直接发 sing-box JSON（按内容识别，地址不变）：绕开 ray2sing 对 AnyTLS/HY2/TUIC 等链接的解析丢失，节点完整显示。
        if slug in ("singbox", "hiddify"):
            cfg, count, errs = sing_config(selected)
            content = json.dumps(cfg,ensure_ascii=False,indent=2)+"\n"
            fmt = "sing-box JSON"
        elif slug == "clash":
            content, count, errs = clash_config(selected)
            fmt = "Mihomo YAML"
        else:
            count, errs = len(selected), []
            plain = "\n".join(selected)+"\n"
            if slug in ("v2rayn","shadowrocket"):
                content = base64.b64encode(plain.encode()).decode()+"\n"
                fmt = "Base64 订阅"
            else:
                content = plain
                fmt = "分享链接订阅"
        atomic_write(filename,content)
        conversion_errors.extend(errs)
        clients.append({"name":title,"file":filename,"nodes":count,"format":fmt})

    errors = list(conversion_errors)
    sources = {"us_direct":usd_source,"us_argo":argo_source}
    for source in sources.values():
        errors.extend(source["errors"])
    stale = any(source["stale"] for source in sources.values())
    manifest = manifest_base("degraded" if errors or stale else "ok", errors)
    manifest["stale"] = stale
    manifest["last_success"] = now()
    manifest["counts"] = {"us_direct":len(us_direct),"us_argo":len(us_argo),"total":len(family)}
    manifest["nodes"] = [node_meta(x,role_of(x)) for x in family]
    private_nodes = {n["id"]:{"link":x} for n,x in zip(manifest["nodes"],family)}
    if len(private_nodes) != len(family):
        raise RuntimeError("节点 ID 冲突，无法生成一一对应的私密节点映射")
    manifest["clients"] = clients
    manifest["sources"] = sources
    manifest["formats"] = {
        "family_txt":{"file":BRAND+"-all.txt","nodes":len(family)},
        "family_base64":{"file":BRAND+"-all-base64.txt","nodes":len(family)},
        "family_json":{"file":BRAND+"-all.json","nodes":sing_count},
        "family_yaml":{"file":BRAND+"-all.yaml","nodes":clash_count}
    }
    atomic_write(BRAND+"-private.js",json.dumps({"version":1,"nodes":private_nodes},ensure_ascii=False,indent=2)+"\n")
    atomic_write(BRAND+"-manifest.json",json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    publish_atomic()
    print("聚合完成：美国直连 %d，Argo备用 %d；状态 %s" %
          (len(us_direct),len(us_argo),manifest["status"]))

def restore_last_good():
    for src in GOOD.iterdir():
        if not src.is_file():
            continue
        if src.name.startswith("."):
            continue
        dest = WEB / src.name
        tmp = dest.with_suffix(dest.suffix + ".tmp")
        shutil.copy2(src, tmp)
        os.replace(tmp, dest)

try:
    main()
except Exception as exc:
    previous = read_json(WEB / (BRAND+"-manifest.json"))
    if previous.get("nodes") or any(GOOD.iterdir()):
        restore_last_good()
        previous = read_json(WEB / (BRAND+"-manifest.json"))
        previous["status"] = "degraded"
        previous["stale"] = True
        previous["updated_at"] = now()
        previous["errors"] = (previous.get("errors", []) + [str(exc)])[-10:]
        atomic_write(BRAND+"-manifest.json",json.dumps(previous,ensure_ascii=False,indent=2)+"\n")
        print("聚合失败，已从上次成功版本恢复：" + str(exc), file=sys.stderr)
    else:
        manifest = manifest_base("error",[str(exc)])
        atomic_write(BRAND+"-manifest.json",json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
        print("聚合失败：" + str(exc), file=sys.stderr)
    sys.exit(1)
PYAGG
  sed -i "s|__US_TOKEN__|$US_TOKEN|g" /root/science/aggregate.py
  python3 -m py_compile /root/science/relaylib.py /root/science/aggregate.py || fail "Python 语法检查失败"
  python3 /root/science/aggregate.py || fail "聚合生成失败，详见上方错误"
  (crontab -l 2>/dev/null | grep -v 'python3 /root/science/aggregate.py'; echo "*/2 * * * * python3 /root/science/aggregate.py >> /root/science/aggregate.log 2>&1 #science-aggregate") | crontab - || fail "聚合 cron 写入失败"
  if [ "$PANEL_ONLY" = "1" ]; then
    install_panel_only
    panel_check=$(mktemp) || fail "无法创建面板验证临时文件"
    curl -fsS --max-time 20 "https://$US_DOMAIN/SKPL-LIFT-all-base64.txt" -o "$panel_check" || { rm -f "$panel_check"; fail "公开全体 Base64 总订阅下载失败"; }
    cmp -s "/root/websbx/$US_TOKEN/SKPL-LIFT-all-base64.txt" "$panel_check" || { rm -f "$panel_check"; fail "公开全体 Base64 总订阅与本地不一致"; }
    rm -f "$panel_check"
    for private_path in SKPL-LIFT-private.js last_good/SKPL-LIFT-private.js; do
      private_code=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' "https://$US_DOMAIN/$private_path")
      [ "$private_code" = 401 ] || fail "$private_path 未登录访问应返回 401，实际为 $private_code"
    done
  fi
  install_nodestatus
  PUBLIC_BASE="${PUBLIC_BASE:-https://$US_DOMAIN}"
  echo "====================================================="
  if [ "$PANEL_ONLY" = "1" ]; then
    echo "美国 PANEL_ONLY 完成：只更新聚合与面板"
    echo "未重装节点，未修改 Xray/sing-box/Argo/DNAT/Nginx/凭据，未执行真实连通性验证"
    echo "面板：$PUBLIC_BASE/index.html"
    echo "manifest：$PUBLIC_BASE/SKPL-LIFT-manifest.json"
  else
    echo "美国部署完成"
    echo "面板：$PUBLIC_BASE/index.html"
    echo "manifest：$PUBLIC_BASE/SKPL-LIFT-manifest.json"
    echo "请确认云安全组放行实际节点端口及 80/443/$US_PORT"
  fi
  echo "====================================================="
fi
