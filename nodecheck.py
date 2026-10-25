#!/usr/bin/env python3
import argparse
import atexit
import concurrent.futures
import datetime
import hashlib
import json
import os
import pathlib
import re
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse
import urllib.request

try:
    import relaylib
except ImportError:
    raise SystemExit("缺少 relaylib.py；请先由 agg.sh 写出现有解析库")

XRAY = "/root/science/xray"
SINGBOX = "/root/science/sing-box"
CURL = "curl"
PRIMARY_URL = "https://speed.cloudflare.com/__down?bytes=1000000"
FALLBACK_URL = "https://www.gstatic.com/generate_204"
ROLE_ORDER = ("hk_relay", "hk_direct", "us_direct", "us_argo")
DEFAULT_ROLES = {
    "us": ("hk_direct", "us_argo"),
    "hk": ("hk_relay", "us_direct", "us_argo"),
}
RESULT_FIELDS = (
    "id", "name", "proto", "server", "port", "role", "status",
    "http_code", "latency_ms", "speed_Bps", "curl_exit", "core",
    "error", "checked_at", "vantage",
)
SHARE_SCHEMES = "vless|vmess|trojan|ss|hysteria2|hy2|tuic|anytls"
UUID_RE = re.compile(
    r"(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b"
)
LINK_RE = re.compile(r"(?i)\b(?:" + SHARE_SCHEMES + r")://[^\s]+")
USERINFO_RE = re.compile(r"(?i)(://)[^/@\s]+@")
QUERY_SECRET_RE = re.compile(
    r"(?i)(\b(?:token|password|passwd|pwd|uuid|secret|auth|key)=)[^&#\s]+"
)
LONG_TOKEN_RE = re.compile(r"(?<![A-Za-z0-9])[A-Za-z0-9_-]{32,}(?![A-Za-z0-9])")


class ProbeError(Exception):
    pass


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat(
        timespec="seconds"
    ).replace("+00:00", "Z")


def redact(value, limit=240):
    text = str(value or "")
    text = "".join(ch if ch >= " " and ch != "\x7f" else " " for ch in text)
    text = LINK_RE.sub("<redacted-link>", text)
    text = USERINFO_RE.sub(r"\1<redacted>@", text)
    text = UUID_RE.sub("<redacted-uuid>", text)
    text = QUERY_SECRET_RE.sub(r"\1<redacted>", text)
    text = LONG_TOKEN_RE.sub("<redacted-token>", text)
    return text[:limit]


def clean_run_id(value):
    result = re.sub(r"[^A-Za-z0-9._-]", "-", str(value or "pre-fix"))
    return result[:64] or "pre-fix"


def role_of(line, parsed=None):
    p = parsed or relaylib.parse(line)
    name = p.get("name", "")
    if "HK中转" in name:
        return "hk_relay"
    if "argo" in name.lower():
        return "us_argo"
    if p.get("server") == getattr(relaylib, "HK_IP", "38.76.210.194"):
        return "hk_direct"
    return "us_direct"


def make_node(line):
    parsed = relaylib.parse(line)
    return {
        "line": line,
        "parsed": parsed,
        "id": hashlib.sha256(line.encode("utf-8")).hexdigest()[:16],
        "role": role_of(line, parsed),
    }


def load_subscription(source):
    if "://" in source:
        if urllib.parse.urlsplit(source).scheme.lower() != "https":
            raise ProbeError("subscription_requires_https")
        request = urllib.request.Request(
            source, headers={"User-Agent": "nodecheck/1"}
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read(8 * 1024 * 1024 + 1)
    else:
        with open(source, "rb") as handle:
            data = handle.read(8 * 1024 * 1024 + 1)
    if len(data) > 8 * 1024 * 1024:
        raise ProbeError("subscription_too_large")
    text = data.decode("utf-8", "ignore")
    nodes = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "://" not in line:
            continue
        nodes.append(make_node(line))
    return nodes


def parse_roles(value, vantage):
    if value is None:
        return DEFAULT_ROLES[vantage]
    requested = {item.strip().lower() for item in value.split(",") if item.strip()}
    if "all" in requested:
        return ROLE_ORDER
    if not requested or not requested.issubset(set(ROLE_ORDER)):
        raise ProbeError("invalid_roles")
    return tuple(role for role in ROLE_ORDER if role in requested)


def public_result(result):
    cleaned = {}
    for key in RESULT_FIELDS:
        value = result.get(key)
        if key in {
            "name", "proto", "server", "role", "status", "core",
            "error", "checked_at", "vantage",
        }:
            value = redact(value)
        cleaned[key] = value
    return cleaned


def base_result(node, vantage):
    parsed = node["parsed"]
    port = parsed.get("port", "")
    return {
        "id": node["id"],
        "name": redact(parsed.get("name", ""), 160),
        "proto": redact(parsed.get("proto", ""), 40),
        "server": redact(parsed.get("server", ""), 253),
        "port": int(port) if str(port).isdigit() else None,
        "role": node["role"],
        "status": "failed",
        "http_code": None,
        "latency_ms": None,
        "speed_Bps": None,
        "curl_exit": None,
        "core": None,
        "error": "not_run",
        "checked_at": utc_now(),
        "vantage": vantage,
    }


def qvalue(query, key, default=""):
    return relaylib.qget(query, key, default)


def normalized_path(value):
    value = value or "/"
    return value if value.startswith("/") else "/" + value


def xray_transport(network, query):
    if network in ("raw", "tcp"):
        settings = {}
        header_type = qvalue(query, "headerType", "none") or "none"
        header = {"type": header_type}
        if header_type.lower() == "http":
            request = {"path": [normalized_path(qvalue(query, "path"))]}
            host = qvalue(query, "host")
            if host:
                request["headers"] = {"Host": [host]}
            header["request"] = request
        settings["header"] = header
        return ("rawSettings" if network == "raw" else "tcpSettings"), settings
    if network == "xhttp":
        settings = {
            "path": normalized_path(qvalue(query, "path")),
            "mode": qvalue(query, "mode", "auto") or "auto",
        }
        host = qvalue(query, "host")
        if host:
            settings["host"] = host
        return "xhttpSettings", settings
    if network == "ws":
        settings = {"path": normalized_path(qvalue(query, "path"))}
        host = qvalue(query, "host")
        if host:
            settings["headers"] = {"Host": host}
        return "wsSettings", settings
    if network == "grpc":
        settings = {"serviceName": qvalue(query, "serviceName")}
        authority = qvalue(query, "authority")
        if authority:
            settings["authority"] = authority
        if qvalue(query, "mode").lower() == "multi":
            settings["multiMode"] = True
        return "grpcSettings", settings
    if network == "httpupgrade":
        settings = {"path": normalized_path(qvalue(query, "path"))}
        host = qvalue(query, "host")
        if host:
            settings["host"] = host
        return "httpupgradeSettings", settings
    raise ProbeError("unsupported_xray_transport")


def vless_xray_outbound(line):
    parsed = relaylib.parse(line)
    if parsed.get("proto") != "vless" or not parsed.get("server"):
        raise ProbeError("invalid_vless_link")
    if not str(parsed.get("port", "")).isdigit():
        raise ProbeError("invalid_vless_port")
    split = urllib.parse.urlsplit(line)
    query = relaylib.query(line)
    user = {
        "id": urllib.parse.unquote(split.username or ""),
        "encryption": qvalue(query, "encryption", "none") or "none",
    }
    flow = qvalue(query, "flow")
    if flow:
        user["flow"] = flow
    network = qvalue(query, "type", "tcp").lower() or "tcp"
    transport_key, transport = xray_transport(network, query)
    security = qvalue(query, "security", "none").lower() or "none"
    stream = {
        "network": network,
        "security": security if security in ("tls", "reality") else "none",
        transport_key: transport,
    }
    insecure = (
        qvalue(query, "insecure").lower() in ("1", "true")
        or qvalue(query, "allowInsecure").lower() in ("1", "true")
    )
    sni = qvalue(query, "sni") or qvalue(query, "servername")
    alpn = [item for item in qvalue(query, "alpn").split(",") if item]
    if security == "tls":
        tls = {"allowInsecure": insecure}
        if sni:
            tls["serverName"] = sni
        fingerprint = qvalue(query, "fp")
        if fingerprint:
            tls["fingerprint"] = fingerprint
        if alpn:
            tls["alpn"] = alpn
        stream["tlsSettings"] = tls
    elif security == "reality":
        stream["realitySettings"] = {
            "serverName": sni,
            "fingerprint": qvalue(query, "fp", "chrome") or "chrome",
            "publicKey": qvalue(query, "pbk"),
            "shortId": qvalue(query, "sid"),
            "spiderX": normalized_path(qvalue(query, "spx", "/")),
        }
    return {
        "tag": "proxy",
        "protocol": "vless",
        "settings": {
            "vnext": [{
                "address": parsed["server"],
                "port": int(parsed["port"]),
                "users": [user],
            }]
        },
        "streamSettings": stream,
    }


def core_for(line):
    return "xray" if relaylib.is_enc(line) else "sing-box"


def make_config(line, local_port):
    core = core_for(line)
    if core == "xray":
        outbound = vless_xray_outbound(line)
        return core, {
            "log": {"loglevel": "warning"},
            "inbounds": [{
                "listen": "127.0.0.1",
                "port": local_port,
                "protocol": "http",
                "settings": {},
            }],
            "outbounds": [outbound],
        }
    outbound = relaylib.to_singbox(line, set())
    if not outbound:
        raise ProbeError("singbox_conversion_unsupported")
    outbound["tag"] = "proxy"
    return core, {
        "log": {"level": "warn", "timestamp": False},
        "inbounds": [{
            "type": "mixed",
            "tag": "local",
            "listen": "127.0.0.1",
            "listen_port": local_port,
        }],
        "outbounds": [outbound, {"type": "direct", "tag": "direct"}],
        "route": {"auto_detect_interface": True, "final": "proxy"},
    }


def core_command(core, config_path):
    executable = XRAY if core == "xray" else SINGBOX
    return [executable, "run", "-c", config_path]


def write_private_json(path, value):
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        json.dump(value, handle, ensure_ascii=False, separators=(",", ":"))


_PROCESS_LOCK = threading.Lock()
_PROCESSES = set()


def track_process(process):
    with _PROCESS_LOCK:
        _PROCESSES.add(process)


def untrack_process(process):
    with _PROCESS_LOCK:
        _PROCESSES.discard(process)


def stop_process(process):
    if process is None:
        return
    try:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=3)
    except (OSError, subprocess.SubprocessError):
        pass


def stop_all_processes():
    with _PROCESS_LOCK:
        processes = list(_PROCESSES)
    for process in processes:
        stop_process(process)


atexit.register(stop_all_processes)


def free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def core_log_category(path):
    try:
        with open(path, "rb") as handle:
            handle.seek(0, os.SEEK_END)
            size = handle.tell()
            handle.seek(max(0, size - 65536), os.SEEK_SET)
            text = handle.read(65536).decode("utf-8", "ignore").lower()
    except OSError:
        return ""
    categories = (
        (("permission denied", "operation not permitted"), "core_permission_denied"),
        (("no such file", "not found"), "core_file_not_found"),
        (("failed to parse", "invalid config", "json:", "unknown field"), "core_config_invalid"),
        (("certificate", "tls handshake", "tls:"), "core_tls_error"),
        (("reality",), "core_reality_error"),
        (("timeout", "deadline exceeded"), "core_timeout"),
        (("connection refused",), "core_connection_refused"),
        (("network unreachable", "no route to host"), "core_network_unreachable"),
        (("unauthorized", "authentication"), "core_auth_failed"),
    )
    for needles, category in categories:
        if any(needle in text for needle in needles):
            return category
    return ""


def wait_for_port(process, port, log_path, timeout=8):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        returncode = process.poll()
        if returncode is not None:
            category = core_log_category(log_path)
            raise ProbeError(
                "core_exit_%s%s" % (
                    returncode, ":" + category if category else ""
                )
            )
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.4):
                return
        except OSError:
            time.sleep(0.1)
    category = core_log_category(log_path)
    raise ProbeError("core_listen_timeout" + ((":" + category) if category else ""))


def empty_curl_result(exit_code):
    return {
        "http_code": 0,
        "latency_ms": None,
        "speed_Bps": None,
        "curl_exit": exit_code,
    }


def run_curl(port, url, max_time):
    command = [
        CURL,
        "--disable",
        "--silent",
        "--show-error",
        "--output", os.devnull,
        "--proxy", "http://127.0.0.1:%d" % port,
        "--connect-timeout", "8",
        "--max-time", str(max_time),
        "--write-out", "%{http_code}|%{time_total}|%{speed_download}",
        url,
    ]
    try:
        completed = subprocess.run(
            command,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=max_time + 5,
            check=False,
        )
    except subprocess.TimeoutExpired:
        result = empty_curl_result(124)
        result["latency_ms"] = max_time * 1000
        return result
    except FileNotFoundError:
        raise ProbeError("curl_not_found")
    except PermissionError:
        raise ProbeError("curl_permission_denied")
    except OSError:
        raise ProbeError("curl_spawn_failed")
    result = empty_curl_result(completed.returncode)
    try:
        last_line = completed.stdout.strip().splitlines()[-1]
        http_code, total, speed = last_line.rsplit("|", 2)
        result.update({
            "http_code": int(http_code),
            "latency_ms": max(0, int(round(float(total) * 1000))),
            "speed_Bps": max(0, int(round(float(speed)))),
        })
    except (ValueError, IndexError):
        pass
    return result


def probe_succeeded(result, expected_http):
    return result["curl_exit"] == 0 and result["http_code"] == expected_http


def probe_description(result):
    if result["curl_exit"] == 0:
        return "http_%s" % result["http_code"]
    return "curl_%s_http_%s" % (result["curl_exit"], result["http_code"])


def apply_curl_metrics(result, metrics):
    for key in ("http_code", "latency_ms", "speed_Bps", "curl_exit"):
        result[key] = metrics[key]


def check_node(node, vantage, run_id):
    result = base_result(node, vantage)
    process = None
    log_handle = None
    try:
        with tempfile.TemporaryDirectory(prefix="nodecheck-" + node["id"] + "-") as work:
            config_path = os.path.join(work, "config.json")
            log_path = os.path.join(work, "core.log")
            try:
                core, config = make_config(node["line"], free_port())
                result["core"] = core
                write_private_json(config_path, config)
                port = config["inbounds"][0]["port"] if core == "xray" else config["inbounds"][0]["listen_port"]
                log_handle = open(log_path, "w", encoding="utf-8")
                try:
                    process = subprocess.Popen(
                        core_command(core, config_path),
                        stdin=subprocess.DEVNULL,
                        stdout=log_handle,
                        stderr=subprocess.STDOUT,
                        cwd=work,
                    )
                except FileNotFoundError:
                    raise ProbeError("core_not_found")
                except PermissionError:
                    raise ProbeError("core_permission_denied")
                except OSError:
                    raise ProbeError("core_spawn_failed")
                track_process(process)
                wait_for_port(process, port, log_path)
                primary = run_curl(port, PRIMARY_URL, 30)
                if probe_succeeded(primary, 200):
                    apply_curl_metrics(result, primary)
                    result["status"] = "ok"
                    result["error"] = ""
                else:
                    fallback = run_curl(port, FALLBACK_URL, 15)
                    apply_curl_metrics(result, fallback)
                    primary_description = probe_description(primary)
                    if probe_succeeded(fallback, 204):
                        result["status"] = "fallback_ok"
                        result["error"] = "primary_%s;fallback_http_204" % primary_description
                    else:
                        result["status"] = "failed"
                        result["error"] = "primary_%s;fallback_%s" % (
                            primary_description, probe_description(fallback)
                        )
                        category = core_log_category(log_path)
                        if category:
                            result["error"] += ";" + category
            finally:
                if process is not None:
                    stop_process(process)
                    untrack_process(process)
                if log_handle is not None:
                    log_handle.close()
    except ProbeError as exc:
        result["error"] = str(exc)
    except Exception as exc:
        result["error"] = "internal_" + type(exc).__name__
    result["checked_at"] = utc_now()
    result = public_result(result)
    emit_result(result, run_id)
    return result


def emit(hypothesis_id, location, message, result, run_id):
    url = os.environ.get("DEBUG_SERVER_URL", "").strip()
    session_id = os.environ.get("DEBUG_SESSION_ID", "").strip()
    if not url or not session_id:
        return
    payload = {
        "sessionId": session_id,
        "runId": clean_run_id(run_id),
        "hypothesisId": hypothesis_id,
        "location": location,
        "msg": message,
        "data": dict(result),
    }
    try:
        request = urllib.request.Request(
            url,
            data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=1.5):
            pass
    except Exception:
        pass


def emit_result(result, run_id):
    point = "D"
    if result["role"] == "us_argo":
        point = "A"
    elif result["proto"].lower() in ("trojan", "hysteria2", "hy2"):
        point = "B"
    elif result["role"] == "hk_relay":
        point = "C"

    # #region debug-point A
    if point == "A":
        emit("A", "nodecheck.py:check_node", "[DEBUG] Argo 拨测结果", result, run_id)
    # #endregion

    # #region debug-point B
    if point == "B":
        emit("B", "nodecheck.py:check_node", "[DEBUG] Trojan/Hy2 拨测结果", result, run_id)
    # #endregion

    # #region debug-point C
    if point == "C":
        emit("C", "nodecheck.py:check_node", "[DEBUG] 香港中转拨测结果", result, run_id)
    # #endregion

    # #region debug-point D
    if point == "D":
        emit("D", "nodecheck.py:check_node", "[DEBUG] 节点性能拨测结果", result, run_id)
    # #endregion


def run_nodes(nodes, vantage, run_id, workers):
    results = [None] * len(nodes)
    executor = concurrent.futures.ThreadPoolExecutor(max_workers=workers)
    futures = {}
    try:
        for index, node in enumerate(nodes):
            future = executor.submit(check_node, node, vantage, run_id)
            futures[future] = index
        for future in concurrent.futures.as_completed(futures):
            index = futures[future]
            result = future.result()
            results[index] = result
            print(
                "%s %s/%s %s %s" % (
                    result["id"], result["role"], result["proto"],
                    result["status"], result["error"],
                ),
                flush=True,
            )
    except BaseException:
        stop_all_processes()
        for future in futures:
            future.cancel()
        raise
    finally:
        executor.shutdown(wait=True)
        stop_all_processes()
    return results


def write_output(path, payload):
    destination = pathlib.Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(
        prefix="." + destination.name + ".", dir=str(destination.parent)
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def install_signal_handlers():
    def interrupted(signum, frame):
        raise KeyboardInterrupt(signum)

    if threading.current_thread() is not threading.main_thread():
        return
    for name in ("SIGINT", "SIGTERM"):
        try:
            signal.signal(getattr(signal, name), interrupted)
        except (AttributeError, OSError, ValueError):
            pass


def positive_int(value):
    try:
        number = int(value)
    except ValueError:
        raise argparse.ArgumentTypeError("必须是整数")
    if number < 1 or number > 32:
        raise argparse.ArgumentTypeError("必须在 1 到 32 之间")
    return number


def build_parser():
    parser = argparse.ArgumentParser(description="逐节点真实协议代理拨测（不发布订阅）")
    parser.add_argument("--subscription", required=True, help="原始分享链接本地路径或 HTTPS URL")
    parser.add_argument("--output", required=True, help="脱敏 JSON 输出路径")
    parser.add_argument("--vantage", required=True, choices=("us", "hk"))
    parser.add_argument("--roles", help="all 或逗号分隔的 hk_relay,hk_direct,us_direct,us_argo")
    parser.add_argument("--workers", type=positive_int, default=3)
    parser.add_argument("--run-id", default="pre-fix")
    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    run_id = clean_run_id(args.run_id)
    try:
        roles = parse_roles(args.roles, args.vantage)
        nodes = load_subscription(args.subscription)
    except Exception as exc:
        print("订阅读取或角色参数失败：" + type(exc).__name__, file=sys.stderr)
        return 2
    selected = [node for node in nodes if node["role"] in roles]
    started_at = utc_now()
    started = time.monotonic()
    install_signal_handlers()
    try:
        results = run_nodes(selected, args.vantage, run_id, args.workers)
    except KeyboardInterrupt:
        stop_all_processes()
        print("拨测中断，已清理核心进程", file=sys.stderr)
        return 130
    except Exception as exc:
        stop_all_processes()
        print("拨测执行失败：" + type(exc).__name__, file=sys.stderr)
        return 2
    counts = {
        status: sum(1 for result in results if result["status"] == status)
        for status in ("ok", "fallback_ok", "failed")
    }
    if not results:
        status = "empty"
    elif counts["failed"] == 0 and counts["fallback_ok"] == 0:
        status = "ok"
    elif counts["ok"] + counts["fallback_ok"]:
        status = "degraded"
    else:
        status = "error"
    payload = {
        "summary": {
            "run_id": run_id,
            "vantage": args.vantage,
            "roles": list(roles),
            "status": status,
            "discovered": len(nodes),
            "total": len(results),
            "ok": counts["ok"],
            "fallback_ok": counts["fallback_ok"],
            "failed": counts["failed"],
            "started_at": started_at,
            "finished_at": utc_now(),
            "duration_ms": int(round((time.monotonic() - started) * 1000)),
        },
        "nodes": results,
    }
    try:
        write_output(args.output, payload)
    except Exception as exc:
        print("结果写入失败：" + type(exc).__name__, file=sys.stderr)
        return 2
    print(
        "拨测完成：total=%d ok=%d fallback_ok=%d failed=%d" % (
            len(results), counts["ok"], counts["fallback_ok"], counts["failed"]
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
