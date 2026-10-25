#!/bin/bash
# 本机订阅分发：按客户端协议筛选，每个客户端最多 12 个节点，并生成 manifest。
export LANG=C
command -v python3 >/dev/null 2>&1 || { echo "[subgen] 需要 python3"; exit 1; }
python3 - "$HOME" <<'PYEOF'
import base64, json, os, pathlib, sys, time, urllib.parse

home = sys.argv[1]
sci = pathlib.Path(home) / "science"
out = sci / "sub"
out.mkdir(parents=True, exist_ok=True)
source = sci / "jhsub.txt"
if not source.exists() or source.stat().st_size == 0:
    print("[subgen] jhsub.txt 不存在或为空，保留现有文件")
    sys.exit(0)
name_file = sci / "name"
brand = name_file.read_text(encoding="utf-8", errors="ignore").strip().rstrip("-") if name_file.exists() else "jhsub"
brand = brand or "jhsub"
raw_lines = [x.strip() for x in source.read_text(encoding="utf-8", errors="ignore").splitlines() if x.strip()]


def parse(line):
    scheme = line.split("://",1)[0].lower() if "://" in line else ""
    try:
        if scheme == "vmess":
            obj = json.loads(base64.urlsafe_b64decode(line[8:] + "="*((4-len(line[8:])%4)%4)))
            return {"name":obj.get("ps",""),"proto":"vmess","server":obj.get("add",""),"port":int(obj.get("port",0))}
        u = urllib.parse.urlsplit(line)
        if scheme == "ss":
            body = line[5:].split("#",1)[0]
            if "@" not in body:
                body = base64.urlsafe_b64decode(body + "="*((4-len(body)%4)%4)).decode("utf-8","ignore")
            userinfo, hp = body.rsplit("@",1)
            host, port = hp.rsplit(":",1)
            return {"name":urllib.parse.unquote(u.fragment),"proto":"ss","server":host.strip("[]"),"port":int(port)}
        return {"name":urllib.parse.unquote(u.fragment),"proto":scheme,"server":u.hostname or "","port":u.port or 0}
    except Exception:
        return {"name":"","proto":scheme,"server":"","port":0}


def valid(line):
    p = parse(line)
    return bool(p["server"] and 1 <= p["port"] <= 65535 and "argo" not in p["name"].lower() and "cdn" not in p["name"].lower())


def atomic(path, content):
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content, encoding="utf-8")
    os.replace(tmp, path)


lines = [x for x in raw_lines if valid(x)]
clients_def = [
    ("Hiddify", "hiddify", {"vless","vmess","trojan","ss","hysteria2","tuic","anytls"}),
    ("v2rayN", "v2rayn", {"vless","vmess","trojan"}),
    ("Clash/Mihomo", "clash", {"vless","vmess","trojan","ss","hysteria2","tuic"}),
    ("sing-box", "singbox", {"vless","vmess","trojan","ss","hysteria2","tuic","anytls"}),
]
clients = []
for title, slug, allowed in clients_def:
    selected = [x for x in lines if parse(x)["proto"] in allowed][:12]
    if not selected:
        continue
    text = base64.b64encode(("\n".join(selected)+"\n").encode()).decode() + "\n"
    filename = "%s-%s.txt" % (brand, slug)
    atomic(out / filename, text)
    clients.append({"name":title,"file":filename,"nodes":len(selected),"format":"Base64 订阅"})

all_text = base64.b64encode(("\n".join(raw_lines)+"\n").encode()).decode() + "\n"
atomic(out / (brand + "-all.txt"), all_text)
nodes = []
for line in lines:
    p = parse(line)
    p["role"] = "hk_direct" if p["name"].lower().endswith("-hk") else "us_direct"
    nodes.append(p)
manifest = {
    "brand":brand,
    "status":"ok" if lines else "error",
    "generated_at":time.strftime("%Y-%m-%d %H:%M:%S"),
    "errors":[] if lines else ["本机没有有效节点"],
    "counts":{"us_direct":sum(n["role"] == "us_direct" for n in nodes),
              "hk_relay":0,
              "hk_direct":sum(n["role"] == "hk_direct" for n in nodes),
              "total":len(nodes)},
    "nodes":nodes,
    "clients":clients,
    "formats":{"local_backup_base64":{"file":brand+"-all.txt","nodes":len(raw_lines),"includes_argo":True}}
}
atomic(out / (brand + "-manifest.json"), json.dumps(manifest, ensure_ascii=False, indent=2)+"\n")
print("[subgen] 本机节点：%d；客户端：%s" % (len(nodes), ", ".join("%s=%d" % (c["name"],c["nodes"]) for c in clients)))
PYEOF
