#!/bin/bash
# =============================================================================
# science 订阅分发层（独立脚本）
# 从 jhsub.txt 按「客户端 × 协议白名单矩阵」分组，生成各客户端专属 base64 订阅。
# 与主脚本 science.sh 解耦：可被 science.sh 在订阅生成后自动调用，也可手动运行。
# 说明：base64 链接集是 hiddify / v2rayN / Clash / sing-box 通用的订阅导入格式。
# =============================================================================
export LANG=C

SCI="$HOME/science"
JH="$SCI/jhsub.txt"
OUT="$SCI/sub"
mkdir -p "$OUT"

[ -f "$JH" ] || { echo "[subgen] 未找到 $JH，请先运行 science 脚本生成节点"; exit 1; }

# 识别链接协议前缀
proto() {
  case "$1" in
    vless://*)     echo vless;;
    vmess://*)     echo vmess;;
    trojan://*)    echo trojan;;
    ss://*)        echo ss;;
    hysteria2://*) echo hy2;;
    tuic://*)      echo tuic;;
    anytls://*)    echo anytls;;
    *)             echo other;;
  esac
}

# 白名单矩阵（客户端 -> 支持的协议）
# hiddify / sing-box：支持全部（含 SS-2022、Hy2、TUIC、AnyTLS）
# v2rayN（Xray 内核）：仅 vless/vmess/trojan
# Clash/Mihomo：vless/vmess/trojan/ss/hy2/tuic
HIDDIFY="vless vmess trojan ss hy2 tuic anytls"
V2RAYN="vless vmess trojan"
CLASH="vless vmess trojan ss hy2 tuic"
SINGBOX="vless vmess trojan ss hy2 tuic anytls"

# base64 编码（兼容 GNU coreutils / busybox）
b64() {
  base64 -w0 "$1" 2>/dev/null || base64 "$1" | tr -d '\n'
}

gen() {
  local name="$1" allow="$2" line p tmp n
  tmp=$(mktemp)
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    p=$(proto "$line")
    case " $allow " in
      *" $p "*) printf '%s\n' "$line" >> "$tmp" ;;
    esac
  done < "$JH"
  n=$(grep -c '://' "$tmp" 2>/dev/null || echo 0)
  b64 "$tmp" > "$OUT/$name.txt"
  rm -f "$tmp"
  echo "[subgen] $name.txt 节点数：$n"
}

gen hiddify "$HIDDIFY"
gen v2rayn  "$V2RAYN"
gen clash   "$CLASH"
gen singbox "$SINGBOX"

# all.txt = 全部节点（原样 base64），并保留明文副本供面板展示
b64 "$JH" > "$OUT/all.txt"
cp "$JH" "$OUT/all_plain.txt"
echo "[subgen] all.txt 节点数：$(grep -c '://' "$JH" 2>/dev/null || echo 0)"

echo "[subgen] 完成，输出目录：$OUT"
