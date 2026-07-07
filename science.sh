#!/bin/sh
export LANG=en_US.UTF-8
[ -z "${vlpt+x}" ] || vlp=yes
[ -z "${vmpt+x}" ] || { vmp=yes; vmag=yes; }
[ -z "${vwpt+x}" ] || { vwp=yes; vmag=yes; }
[ -z "${hypt+x}" ] || hyp=yes
[ -z "${tupt+x}" ] || tup=yes
[ -z "${xhpt+x}" ] || xhp=yes
[ -z "${vxpt+x}" ] || vxp=yes
[ -z "${anpt+x}" ] || anp=yes
[ -z "${sspt+x}" ] || ssp=yes
[ -z "${arpt+x}" ] || arp=yes
[ -z "${sopt+x}" ] || sop=yes
[ -z "${warp+x}" ] || wap=yes
# 一键全协议预设：all=y 自动开启8大协议+Argo+订阅
[ -z "${all+x}" ] || { vlp=yes; vmp=yes; vmag=yes; vwp=yes; vmag=yes; hyp=yes; tup=yes; xhp=yes; vxp=yes; anp=yes; ssp=yes; argo=vmpt; sub=y; vmag=yes; }
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'science/(s|x)' || pgrep -f 'science/(s|x)' >/dev/null 2>&1; then
if [ "$1" = "rep" ]; then
[ "$vwp" = yes ] || [ "$sop" = yes ] || [ "$vxp" = yes ] || [ "$ssp" = yes ] || [ "$vlp" = yes ] || [ "$vmp" = yes ] || [ "$hyp" = yes ] || [ "$tup" = yes ] || [ "$xhp" = yes ] || [ "$anp" = yes ] || [ "$arp" = yes ] || { echo "提示：rep重置协议时，请在脚本前至少设置一个协议变量哦，再见！💣"; exit; }
fi
else
[ "$1" = "del" ] || [ "$vwp" = yes ] || [ "$sop" = yes ] || [ "$vxp" = yes ] || [ "$ssp" = yes ] || [ "$vlp" = yes ] || [ "$vmp" = yes ] || [ "$hyp" = yes ] || [ "$tup" = yes ] || [ "$xhp" = yes ] || [ "$anp" = yes ] || [ "$arp" = yes ] || { echo "提示：未安装science脚本，请在脚本前至少设置一个协议变量哦，再见！💣"; exit; }
fi
export uuid=${uuid:-''}
export port_vl_re=${vlpt:-''}
export port_vm_ws=${vmpt:-''}
export port_vw=${vwpt:-''}
export port_hy2=${hypt:-''}
export port_tu=${tupt:-''}
export port_xh=${xhpt:-''}
export port_vx=${vxpt:-''}
export port_an=${anpt:-''}
export port_ar=${arpt:-''}
export port_ss=${sspt:-''}
export port_so=${sopt:-''}
export ym_vl_re=${reym:-''}
export cdnym=${cdnym:-''}
export argo=${argo:-''}
export ARGO_DOMAIN=${agn:-''}
export ARGO_AUTH=${agk:-''}
export ippz=${ippz:-''}
export warp=${warp:-''}
export name=${name:-''}
export oap=${oap:-''}
export dnym=${dnym:-''}
v46url="https://icanhazip.com"
scienceurl="https://raw.githubusercontent.com/Hutton-h/science/main/science.sh"
showmode(){
echo "Science脚本一键SSH命令生器在线网址：https://Hutton-h.github.io/science/"
echo "主脚本：bash <(curl -Ls https://raw.githubusercontent.com/Hutton-h/science/main/science.sh) 或 bash <(wget -qO- https://raw.githubusercontent.com/Hutton-h/science/main/science.sh)"
echo "显示节点信息命令：science list 【或者】 主脚本 list"
echo "重置变量组命令：自定义各种协议变量组 science rep 【或者】 自定义各种协议变量组 主脚本 rep"
echo "更新脚本命令：原已安装的自定义各种协议变量组 主脚本 rep"
echo "更新Xray或Singbox内核命令：science upx或ups 【或者】 主脚本 upx或ups"
echo "重启脚本命令：science res 【或者】 主脚本 res"
echo "卸载脚本命令：science del 【或者】 主脚本 del"
echo "部署/更新面板命令：science panel 【或者】 主脚本 panel"
echo "一键全协议命令：all=y dnym=\"域名\" bash <(curl -Ls https://raw.githubusercontent.com/Hutton-h/science/main/science.sh)"
echo "订阅面板(需开启sub=y)：http://服务器IP或域名:订阅端口/订阅Token/index.html"
echo "隐藏IP用域名变量：dnym=\"你的域名\" (需先在DNS将域名解析到服务器IP)"
echo "双栈VPS显示IPv4/IPv6节点配置命令：ippz=4或6 science list 【或者】 ippz=4或6 主脚本 list"
echo "---------------------------------------------------------"
echo
}
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "skpl Github项目 ：github.com/Hutton-h"
echo "Science一键无交互小钢炮脚本💣"
echo "当前版本：V26.5.10"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
hostname=$(uname -a | awk '{print $2}')
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
[ -z "$(systemd-detect-virt 2>/dev/null)" ] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
arm64|aarch64) cpu=arm64;;
amd64|x86_64) cpu=amd64;;
*) echo "目前脚本不支持$(uname -m)架构" && exit
esac
if [ "$1" != "del" ]; then
mkdir -p "$HOME/science"
if [ ! -f sbx_update ]; then
echo "执行必要的脚本依赖中，请稍等10秒……"
if command -v apk >/dev/null 2>&1; then
apk update >/dev/null 2>&1 && apk add --no-cache bash busybox-extras gcompat libc6-compat iptables openssl >/dev/null 2>&1
elif command -v apt >/dev/null 2>&1; then
export DEBIAN_FRONTEND=noninteractive
printf 'iptables-persistent iptables-persistent/autosave_v4 boolean true\niptables-persistent iptables-persistent/autosave_v6 boolean true\n' | debconf-set-selections
apt update >/dev/null 2>&1 && apt install -y busybox coreutils util-linux iptables iptables-persistent cron openssl unzip tar >/dev/null 2>&1
fi
touch sbx_update
fi
fi
v4v6(){
v4=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- "$v46url" 2>/dev/null) )
v6=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- "$v46url" 2>/dev/null) )
v4dq=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k https://myip.ipip.net/ | awk -F'来自于：' '{print $2}' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- https://myip.ipip.net/ | awk -F'来自于：' '{print $2}' 2>/dev/null) )
v6dq=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k https://ip.fm | sed -n 's/.*Location: //p' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- https://ip.fm | grep '<span class="has-text-grey-light">Location:' | tail -n1 | sed -E 's/.*>Location: <\/span>([^<]+)<.*/\1/' 2>/dev/null) )
}
warpsx(){
warpurl=$( (command -v curl >/dev/null 2>&1 && curl -sm5 -k https://warp.xijp.eu.org 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget --tries=2 -qO- https://warp.xijp.eu.org 2>/dev/null) )
if [ -z "$warpurl" ] || printf '%s' "$warpurl" | grep -q html; then
wpv6='2606:4700:110:8d8d:1845:c39f:2dd5:a03a'
pvk='52cuYFgCJXp0LAq7+nWJIbCXXgU9eGggOc+Hlfz5u6A='
res='[215, 69, 233]'
else
pvk=$(echo "$warpurl" | awk -F'：' '/Private_key/{print $2}' | xargs)
wpv6=$(echo "$warpurl" | awk -F'：' '/IPV6/{print $2}' | xargs)
res=$(echo "$warpurl" | awk -F'：' '/reserved/{print $2}' | xargs)
fi
if [ -n "$name" ]; then
sxname=$name-
echo "$sxname" > "$HOME/science/name"
echo
echo "所有节点名称前缀：$name"
fi
v4v6
if echo "$v6" | grep -q '^2a09' || echo "$v4" | grep -q '^104.28'; then
s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warpargo
echo; echo "请注意：你已安装了warp"
else
if [ "$wap" != yes ]; then
s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warpargo
else
case "$warp" in
""|sx|xs) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s ) s1outtag=warp-out; s2outtag=warp-out; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s4) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
s6) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0"'; wap=warp ;;
x ) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
x4) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
x6) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s4x4|x4s4) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
s4x6|x6s4) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
s6x4|x4s6) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0"'; wap=warp ;;
s6x6|x6s6) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0"'; wap=warp ;;
sx4|x4s) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
sx6|x6s) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
xs4|s4x) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
xs6|s6x) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0"'; wap=warp ;;
* ) s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warpargo ;;
esac
fi
fi
case "$warp" in *x4*) wxryx='ForceIPv4' ;; *x6*) wxryx='ForceIPv6' ;; *) wxryx='ForceIPv6v4' ;; esac
if command -v curl >/dev/null 2>&1; then
curl -s4m5 -k "$v46url" >/dev/null 2>&1 && v4_ok=true
elif command -v wget >/dev/null 2>&1; then
timeout 3 wget -4 --tries=2 -qO- "$v46url" >/dev/null 2>&1 && v4_ok=true
fi
if command -v curl >/dev/null 2>&1; then
curl -s6m5 -k "$v46url" >/dev/null 2>&1 && v6_ok=true
elif command -v wget >/dev/null 2>&1; then
timeout 3 wget -6 --tries=2 -qO- "$v46url" >/dev/null 2>&1 && v6_ok=true
fi
if [ "$v4_ok" = true ] && [ "$v6_ok" = true ]; then
case "$warp" in *s4*) sbyx='prefer_ipv4' ;; *) sbyx='prefer_ipv6' ;; esac
case "$warp" in *x4*) xryx='ForceIPv4v6' ;; *x*) xryx='ForceIPv6v4' ;; *) xryx='ForceIPv4v6' ;; esac
elif [ "$v4_ok" = true ] && [ "$v6_ok" != true ]; then
case "$warp" in *s4*|x) sbyx='ipv4_only' ;; *) sbyx='prefer_ipv6' ;; esac
case "$warp" in *x4*) xryx='ForceIPv4' ;; *x*) xryx='ForceIPv6v4' ;; *) xryx='ForceIPv4v6' ;; esac
elif [ "$v4_ok" != true ] && [ "$v6_ok" = true ]; then
case "$warp" in *s6*|x) sbyx='ipv6_only' ;; *) sbyx='prefer_ipv4' ;; esac
case "$warp" in *x6*) xryx='ForceIPv6' ;; *x*) xryx='ForceIPv4v6' ;; *) xryx='ForceIPv6v4' ;; esac
fi
}
upxray(){
case $cpu in
amd64) xray_zip="Xray-linux-64.zip" ;;
arm64) xray_zip="Xray-linux-arm64-v8a.zip" ;;
esac
url="https://github.com/XTLS/Xray-core/releases/latest/download/$xray_zip"
tmpdir=$(mktemp -d)
echo "正在从官方源下载Xray内核..."
(command -v curl >/dev/null 2>&1 && curl -Lo "$tmpdir/xray.zip" -# --retry 2 "$url") || \
(command -v wget>/dev/null 2>&1 && timeout 5 wget -O "$tmpdir/xray.zip" --tries=2 "$url") || \
{ echo "Xray下载失败，请检查网络"; rm -rf "$tmpdir"; return 1; }
unzip -o "$tmpdir/xray.zip" xray -d "$HOME/science/" >/dev/null 2>&1
rm -rf "$tmpdir"
chmod +x "$HOME/science/xray"
sbcore=$("$HOME/science/xray" version 2>/dev/null | awk '/^Xray/{print $2}')
echo "已安装Xray正式版内核：$sbcore"
}
upsingbox(){
# Get latest stable version via GitHub API, fallback to v1.13.14
sb_ver=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases?per_page=20 2>/dev/null | grep -B5 '"prerelease": false' | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
[ -z "$sb_ver" ] && sb_ver="v1.13.14"
sb_verno="${sb_ver#v}"
case $cpu in
amd64) sb_arch="amd64" ;;
arm64) sb_arch="arm64" ;;
esac
sb_file="sing-box-${sb_verno}-linux-$sb_arch.tar.gz"
url="https://github.com/SagerNet/sing-box/releases/download/$sb_ver/$sb_file"
tmpdir=$(mktemp -d)
echo "正在从官方源下载Sing-box内核 v$sb_verno..."
(command -v curl >/dev/null 2>&1 && curl -Lo "$tmpdir/sing-box.tar.gz" -# --retry 2 "$url") || \
(command -v wget>/dev/null 2>&1 && timeout 5 wget -O "$tmpdir/sing-box.tar.gz" --tries=2 "$url") || \
{ echo "Sing-box下载失败，尝试备用版本..."; sb_ver="v1.13.14"; sb_verno="1.13.14"; sb_file="sing-box-${sb_verno}-linux-$sb_arch.tar.gz"; url="https://github.com/SagerNet/sing-box/releases/download/$sb_ver/$sb_file"; (curl -Lo "$tmpdir/sing-box.tar.gz" --retry 2 "$url" || wget -O "$tmpdir/sing-box.tar.gz" --tries=2 "$url") || { echo "Sing-box下载失败"; rm -rf "$tmpdir"; return 1; }; }
tar xzf "$tmpdir/sing-box.tar.gz" -C "$tmpdir" >/dev/null 2>&1
find "$tmpdir" -name "sing-box" -type f -exec cp {} "$HOME/science/sing-box" \; 2>/dev/null
rm -rf "$tmpdir"
chmod +x "$HOME/science/sing-box"
sbcore=$("$HOME/science/sing-box" version 2>/dev/null | awk '/version/{print $NF}')
echo "已安装Sing-box正式版内核：$sbcore"
}
insuuid(){
if [ -z "$uuid" ] && [ ! -e "$HOME/science/uuid" ]; then
if [ -e "$HOME/science/sing-box" ]; then
uuid=$("$HOME/science/sing-box" generate uuid)
else
uuid=$("$HOME/science/xray" uuid)
fi
echo "$uuid" > "$HOME/science/uuid"
elif [ -n "$uuid" ]; then
echo "$uuid" > "$HOME/science/uuid"
fi
uuid=$(cat "$HOME/science/uuid")
echo "UUID密码：$uuid"
}
installxray(){
echo
echo "=========启用xray内核========="
mkdir -p "$HOME/science/xrk"
if [ ! -e "$HOME/science/xray" ]; then
upxray
fi
cat > "$HOME/science/xr.json" <<EOF
{
  "log": {
  "loglevel": "none"
  },
  "inbounds": [
EOF
insuuid
if [ -n "$xhp" ] || [ -n "$vlp" ]; then
if [ -z "$ym_vl_re" ]; then
ym_vl_re=apple.com
fi
echo "$ym_vl_re" > "$HOME/science/ym_vl_re"
echo "Reality域名：$ym_vl_re"
if [ ! -e "$HOME/science/xrk/private_key" ]; then
key_pair=$("$HOME/science/xray" x25519)
private_key=$(echo "$key_pair" | awk -F':' '/PrivateKey/ {print $2}' | xargs)
public_key=$(echo "$key_pair" | awk -F':' '/Password/ {print $2}' | xargs)
short_id=$(date +%s%N | sha256sum | cut -c 1-8)
echo "$private_key" > "$HOME/science/xrk/private_key"
echo "$public_key" > "$HOME/science/xrk/public_key"
echo "$short_id" > "$HOME/science/xrk/short_id"
fi
private_key_x=$(cat "$HOME/science/xrk/private_key")
public_key_x=$(cat "$HOME/science/xrk/public_key")
short_id_x=$(cat "$HOME/science/xrk/short_id")
fi
if [ -n "$xhp" ] || [ -n "$vxp" ] || [ -n "$vwp" ]; then
if [ ! -e "$HOME/science/xrk/dekey" ]; then
vlkey=$("$HOME/science/xray" vlessenc)
dekey=$(echo "$vlkey" | grep '"decryption":' | sed -n '2p' | cut -d' ' -f2- | tr -d '"')
enkey=$(echo "$vlkey" | grep '"encryption":' | sed -n '2p' | cut -d' ' -f2- | tr -d '"')
echo "$dekey" > "$HOME/science/xrk/dekey"
echo "$enkey" > "$HOME/science/xrk/enkey"
fi
dekey=$(cat "$HOME/science/xrk/dekey")
enkey=$(cat "$HOME/science/xrk/enkey")
fi

if [ -n "$xhp" ]; then
xhp=xhpt
if [ -z "$port_xh" ] && [ ! -e "$HOME/science/port_xh" ]; then
port_xh=$(shuf -i 10000-65535 -n 1)
echo "$port_xh" > "$HOME/science/port_xh"
elif [ -n "$port_xh" ]; then
echo "$port_xh" > "$HOME/science/port_xh"
fi
port_xh=$(cat "$HOME/science/port_xh")
echo "Vless-xhttp-reality-enc端口：$port_xh"
cat >> "$HOME/science/xr.json" <<EOF
    {
      "tag":"xhttp-reality",
      "listen": "::",
      "port": ${port_xh},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "${dekey}"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "target": "${ym_vl_re}:443",
          "serverNames": [
            "${ym_vl_re}"
          ],
          "privateKey": "$private_key_x",
          "shortIds": ["$short_id_x"]
        },
        "xhttpSettings": {
          "host": "",
          "path": "${uuid}-xh",
          "mode": "auto"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false
      }
    },
EOF
else
xhp=xhptargo
fi
if [ -n "$vxp" ]; then
vxp=vxpt
if [ -z "$port_vx" ] && [ ! -e "$HOME/science/port_vx" ]; then
port_vx=$(shuf -i 10000-65535 -n 1)
echo "$port_vx" > "$HOME/science/port_vx"
elif [ -n "$port_vx" ]; then
echo "$port_vx" > "$HOME/science/port_vx"
fi
port_vx=$(cat "$HOME/science/port_vx")
echo "Vless-xhttp-enc端口：$port_vx"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/science/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
cat >> "$HOME/science/xr.json" <<EOF
    {
      "tag":"vless-xhttp",
      "listen": "::",
      "port": ${port_vx},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "${dekey}"
      },
      "streamSettings": {
        "network": "xhttp",
        "xhttpSettings": {
          "host": "",
          "path": "${uuid}-vx",
          "mode": "auto"
        }
      },
        "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false
      }
    },
EOF
else
vxp=vxptargo
fi
if [ -n "$vwp" ]; then
vwp=vwpt
if [ -z "$port_vw" ] && [ ! -e "$HOME/science/port_vw" ]; then
port_vw=$(shuf -i 10000-65535 -n 1)
echo "$port_vw" > "$HOME/science/port_vw"
elif [ -n "$port_vw" ]; then
echo "$port_vw" > "$HOME/science/port_vw"
fi
port_vw=$(cat "$HOME/science/port_vw")
echo "Vless-ws-enc端口：$port_vw"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/science/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
cat >> "$HOME/science/xr.json" <<EOF
    {
      "tag":"vless-ws",
      "listen": "::",
      "port": ${port_vw},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "${dekey}"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${uuid}-vw"
        }
      },
        "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false
      }
    },
EOF
else
vwp=vwptargo
fi
if [ -n "$vlp" ]; then
vlp=vlpt
if [ -z "$port_vl_re" ] && [ ! -e "$HOME/science/port_vl_re" ]; then
port_vl_re=$(shuf -i 10000-65535 -n 1)
echo "$port_vl_re" > "$HOME/science/port_vl_re"
elif [ -n "$port_vl_re" ]; then
echo "$port_vl_re" > "$HOME/science/port_vl_re"
fi
port_vl_re=$(cat "$HOME/science/port_vl_re")
echo "Vless-tcp-reality-v端口：$port_vl_re"
cat >> "$HOME/science/xr.json" <<EOF
        {
            "tag":"reality-vision",
            "listen": "::",
            "port": $port_vl_re,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "fingerprint": "chrome",
                    "dest": "${ym_vl_re}:443",
                    "serverNames": [
                      "${ym_vl_re}"
                    ],
                    "privateKey": "$private_key_x",
                    "shortIds": ["$short_id_x"]
                }
            },
          "sniffing": {
          "enabled": true,
          "destOverride": ["http", "tls", "quic"],
          "metadataOnly": false
      }
    },  
EOF
else
vlp=vlptargo
fi
}

installsb(){
echo
echo "=========启用Sing-box内核========="
if [ ! -e "$HOME/science/sing-box" ]; then
upsingbox
fi
cat > "$HOME/science/sb.json" <<EOF
{
"log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
EOF
insuuid
if [ ! -f "$HOME/science/SHA256.txt" ]; then
command -v openssl >/dev/null 2>&1 && openssl ecparam -genkey -name prime256v1 -out "$HOME/science/private.key" >/dev/null 2>&1
command -v openssl >/dev/null 2>&1 && openssl req -new -x509 -days 36500 -key "$HOME/science/private.key" -out "$HOME/science/cert.crt" -subj "/CN=www.bing.com" >/dev/null 2>&1
#if [ ! -f "$HOME/science/private.key" ]; then
#url="https://github.com/Hutton-h/science/releases/download/science/private.key"; out="$HOME/science/private.key"; (command -v curl>/dev/null 2>&1 && curl -Ls -o "$out" --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -q -O "$out" --tries=2 "$url")
#url="https://github.com/Hutton-h/science/releases/download/science/cert.crt"; out="$HOME/science/cert.crt"; (command -v curl>/dev/null 2>&1 && curl -Ls -o "$out" --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -q -O "$out" --tries=2 "$url")
#echo "fc6dca8cfc4081102aa9655d0d4805c27d7266f605541d242ad66ad00a284a35" > "$HOME/science/SHA256.txt"
#else
SHA256=$(openssl x509 -in $HOME/science/cert.crt -outform DER | sha256sum | awk '{print $1}')
echo "$SHA256" > "$HOME/science/SHA256.txt"
#fi
fi
if [ -n "$hyp" ]; then
hyp=hypt
if [ -z "$port_hy2" ] && [ ! -e "$HOME/science/port_hy2" ]; then
port_hy2=$(shuf -i 10000-65535 -n 1)
echo "$port_hy2" > "$HOME/science/port_hy2"
elif [ -n "$port_hy2" ]; then
echo "$port_hy2" > "$HOME/science/port_hy2"
fi
port_hy2=$(cat "$HOME/science/port_hy2")
echo "Hysteria2端口：$port_hy2"
cat >> "$HOME/science/sb.json" <<EOF
    {
        "type": "hysteria2",
        "tag": "hy2-sb",
        "listen": "::",
        "listen_port": ${port_hy2},
        "users": [
            {
                "password": "${uuid}"
            }
        ],
        "ignore_client_bandwidth":false,
        "tls": {
            "enabled": true,
            "alpn": [
                "h3"
            ],
            "certificate_path": "$HOME/science/cert.crt",
            "key_path": "$HOME/science/private.key"
        }
    },
EOF
else
hyp=hyptargo
fi
if [ -n "$tup" ]; then
tup=tupt
if [ -z "$port_tu" ] && [ ! -e "$HOME/science/port_tu" ]; then
port_tu=$(shuf -i 10000-65535 -n 1)
echo "$port_tu" > "$HOME/science/port_tu"
elif [ -n "$port_tu" ]; then
echo "$port_tu" > "$HOME/science/port_tu"
fi
port_tu=$(cat "$HOME/science/port_tu")
echo "Tuic端口：$port_tu"
cat >> "$HOME/science/sb.json" <<EOF
        {
            "type":"tuic",
            "tag": "tuic5-sb",
            "listen": "::",
            "listen_port": ${port_tu},
            "users": [
                {
                    "uuid": "${uuid}",
                    "password": "${uuid}"
                }
            ],
            "congestion_control": "bbr",
            "tls":{
                "enabled": true,
                "alpn": [
                    "h3"
                ],
                "certificate_path": "$HOME/science/cert.crt",
                "key_path": "$HOME/science/private.key"
            }
        },
EOF
else
tup=tuptargo
fi
if [ -n "$anp" ]; then
anp=anpt
if [ -z "$port_an" ] && [ ! -e "$HOME/science/port_an" ]; then
port_an=$(shuf -i 10000-65535 -n 1)
echo "$port_an" > "$HOME/science/port_an"
elif [ -n "$port_an" ]; then
echo "$port_an" > "$HOME/science/port_an"
fi
port_an=$(cat "$HOME/science/port_an")
echo "Anytls端口：$port_an"
cat >> "$HOME/science/sb.json" <<EOF
        {
            "type":"anytls",
            "tag":"anytls-sb",
            "listen":"::",
            "listen_port":${port_an},
            "users":[
                {
                  "password":"${uuid}"
                }
            ],
            "padding_scheme":[],
            "tls":{
                "enabled": true,
                "certificate_path": "$HOME/science/cert.crt",
                "key_path": "$HOME/science/private.key"
            }
        },
EOF
else
anp=anptargo
fi
if [ -n "$arp" ]; then
arp=arpt
if [ -z "$ym_vl_re" ]; then
ym_vl_re=apple.com
fi
echo "$ym_vl_re" > "$HOME/science/ym_vl_re"
echo "Reality域名：$ym_vl_re"
mkdir -p "$HOME/science/sbk"
if [ ! -e "$HOME/science/sbk/private_key" ]; then
key_pair=$("$HOME/science/sing-box" generate reality-keypair)
private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')
short_id=$("$HOME/science/sing-box" generate rand --hex 4)
echo "$private_key" > "$HOME/science/sbk/private_key"
echo "$public_key" > "$HOME/science/sbk/public_key"
echo "$short_id" > "$HOME/science/sbk/short_id"
fi
private_key_s=$(cat "$HOME/science/sbk/private_key")
public_key_s=$(cat "$HOME/science/sbk/public_key")
short_id_s=$(cat "$HOME/science/sbk/short_id")
if [ -z "$port_ar" ] && [ ! -e "$HOME/science/port_ar" ]; then
port_ar=$(shuf -i 10000-65535 -n 1)
echo "$port_ar" > "$HOME/science/port_ar"
elif [ -n "$port_ar" ]; then
echo "$port_ar" > "$HOME/science/port_ar"
fi
port_ar=$(cat "$HOME/science/port_ar")
echo "Any-Reality端口：$port_ar"
cat >> "$HOME/science/sb.json" <<EOF
        {
            "type":"anytls",
            "tag":"anyreality-sb",
            "listen":"::",
            "listen_port":${port_ar},
            "users":[
                {
                  "password":"${uuid}"
                }
            ],
            "padding_scheme":[],
            "tls": {
            "enabled": true,
            "server_name": "${ym_vl_re}",
             "reality": {
              "enabled": true,
              "handshake": {
              "server": "${ym_vl_re}",
              "server_port": 443
             },
             "private_key": "$private_key_s",
             "short_id": ["$short_id_s"]
            }
          }
        },
EOF
else
arp=arptargo
fi
if [ -n "$ssp" ]; then
ssp=sspt
if [ ! -e "$HOME/science/sskey" ]; then
sskey=$("$HOME/science/sing-box" generate rand 16 --base64)
echo "$sskey" > "$HOME/science/sskey"
fi
if [ -z "$port_ss" ] && [ ! -e "$HOME/science/port_ss" ]; then
port_ss=$(shuf -i 10000-65535 -n 1)
echo "$port_ss" > "$HOME/science/port_ss"
elif [ -n "$port_ss" ]; then
echo "$port_ss" > "$HOME/science/port_ss"
fi
sskey=$(cat "$HOME/science/sskey")
port_ss=$(cat "$HOME/science/port_ss")
echo "Shadowsocks-2022端口：$port_ss"
cat >> "$HOME/science/sb.json" <<EOF
        {
            "type": "shadowsocks",
            "tag":"ss-2022",
            "listen": "::",
            "listen_port": $port_ss,
            "method": "2022-blake3-aes-128-gcm",
            "password": "$sskey"
    },  
EOF
else
ssp=ssptargo
fi
}

xrsbvm(){
if [ -n "$vmp" ]; then
vmp=vmpt
if [ -z "$port_vm_ws" ] && [ ! -e "$HOME/science/port_vm_ws" ]; then
port_vm_ws=$(shuf -i 10000-65535 -n 1)
echo "$port_vm_ws" > "$HOME/science/port_vm_ws"
elif [ -n "$port_vm_ws" ]; then
echo "$port_vm_ws" > "$HOME/science/port_vm_ws"
fi
port_vm_ws=$(cat "$HOME/science/port_vm_ws")
echo "Vmess-ws端口：$port_vm_ws"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/science/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
if [ -e "$HOME/science/xr.json" ]; then
cat >> "$HOME/science/xr.json" <<EOF
        {
            "tag": "vmess-xr",
            "listen": "::",
            "port": ${port_vm_ws},
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                  "path": "${uuid}-vm"
            }
        },
            "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "metadataOnly": false
            }
         }, 
EOF
else
cat >> "$HOME/science/sb.json" <<EOF
{
        "type": "vmess",
        "tag": "vmess-sb",
        "listen": "::",
        "listen_port": ${port_vm_ws},
        "users": [
            {
                "uuid": "${uuid}",
                "alterId": 0
            }
        ],
        "transport": {
            "type": "ws",
            "path": "${uuid}-vm",
            "max_early_data":2048,
            "early_data_header_name": "Sec-WebSocket-Protocol"
        }
    },
EOF
fi
else
vmp=vmptargo
fi
}

xrsbso(){
if [ -n "$sop" ]; then
sop=sopt
if [ -z "$port_so" ] && [ ! -e "$HOME/science/port_so" ]; then
port_so=$(shuf -i 10000-65535 -n 1)
echo "$port_so" > "$HOME/science/port_so"
elif [ -n "$port_so" ]; then
echo "$port_so" > "$HOME/science/port_so"
fi
port_so=$(cat "$HOME/science/port_so")
echo "Socks5端口：$port_so"
if [ -e "$HOME/science/xr.json" ]; then
cat >> "$HOME/science/xr.json" <<EOF
        {
         "tag": "socks5-xr",
         "port": ${port_so},
         "listen": "::",
         "protocol": "socks",
         "settings": {
            "auth": "password",
             "accounts": [
               {
               "user": "${uuid}",
               "pass": "${uuid}"
               }
            ],
            "udp": true
          },
            "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "metadataOnly": false
            }
         }, 
EOF
else
cat >> "$HOME/science/sb.json" <<EOF
    {
      "tag": "socks5-sb",
      "type": "socks",
      "listen": "::",
      "listen_port": ${port_so},
      "users": [
      {
      "username": "${uuid}",
      "password": "${uuid}"
      }
     ]
    },
EOF
fi
else
sop=soptargo
fi
}

xrsbout(){
if [ -e "$HOME/science/xr.json" ]; then
sed -i '${s/,\s*$//}' "$HOME/science/xr.json"
cat >> "$HOME/science/xr.json" <<EOF
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {
      "domainStrategy":"${xryx}"
     }
    },
    {
      "tag": "x-warp-out",
      "protocol": "wireguard",
      "settings": {
        "secretKey": "${pvk}",
        "address": [
          "172.16.0.2/32",
          "${wpv6}/128"
        ],
        "peers": [
          {
            "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
            "allowedIPs": [
              "0.0.0.0/0",
              "::/0"
            ],
            "endpoint": "${xendip}:2408"
          }
        ],
        "reserved": ${res}
        }
    },
    {
      "tag":"warp-out",
      "protocol":"freedom",
        "settings":{
        "domainStrategy":"${wxryx}"
       },
       "proxySettings":{
       "tag":"x-warp-out"
     }
}
  ],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "type": "field",
        "ip": [ ${xip} ],
        "network": "tcp,udp",
        "outboundTag": "${x1outtag}"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "${x2outtag}"
      }
    ]
  }
}
EOF
if pidof systemd >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/systemd/system/xr.service <<EOF
[Unit]
Description=xr service
After=network.target
[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/root/science/xray run -c /root/science/xr.json
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable xr >/dev/null 2>&1
systemctl start xr >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/init.d/xray <<EOF
#!/sbin/openrc-run
description="xr service"
command="/root/science/xray"
command_args="run -c /root/science/xr.json"
command_background=yes
pidfile="/run/xray.pid"
command_background="yes"
depend() {
need net
}
EOF
chmod +x /etc/init.d/xray >/dev/null 2>&1
rc-update add xray default >/dev/null 2>&1
rc-service xray start >/dev/null 2>&1
else
nohup "$HOME/science/xray" run -c "$HOME/science/xr.json" >/dev/null 2>&1 &
fi
fi
if [ -e "$HOME/science/sb.json" ]; then
sed -i '${s/,\s*$//}' "$HOME/science/sb.json"
cat >> "$HOME/science/sb.json" <<EOF
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "endpoints": [
    {
      "type": "wireguard",
      "tag": "warp-out",
      "address": [
        "172.16.0.2/32",
        "${wpv6}/128"
      ],
      "private_key": "${pvk}",
      "peers": [
        {
          "address": "${sendip}",
          "port": 2408,
          "public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
          "allowed_ips": [
            "0.0.0.0/0",
            "::/0"
          ],
          "reserved": $res
        }
      ]
    }
  ],
  "route": {
    "rules": [
       {
          "action": "sniff"
        },
       {
        "action": "resolve",
         "strategy": "${sbyx}"
       },
      {
        "ip_cidr": [ ${sip} ],         
        "outbound": "${s1outtag}"
      }
    ],
    "final": "${s2outtag}"
  }
}
EOF
if pidof systemd >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/systemd/system/sb.service <<EOF
[Unit]
Description=sb service
After=network.target
[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/root/science/sing-box run -c /root/science/sb.json
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable sb >/dev/null 2>&1
systemctl start sb >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/init.d/sing-box <<EOF
#!/sbin/openrc-run
description="sb service"
command="/root/science/sing-box"
command_args="run -c /root/science/sb.json"
command_background=yes
pidfile="/run/sing-box.pid"
command_background="yes"
depend() {
need net
}
EOF
chmod +x /etc/init.d/sing-box >/dev/null 2>&1
rc-update add sing-box default >/dev/null 2>&1
rc-service sing-box start >/dev/null 2>&1
else
nohup "$HOME/science/sing-box" run -c "$HOME/science/sb.json" >/dev/null 2>&1 &
fi
fi
}
ins(){
if [ "$hyp" != yes ] && [ "$tup" != yes ] && [ "$anp" != yes ] && [ "$arp" != yes ] && [ "$ssp" != yes ]; then
installxray
xrsbvm
xrsbso
warpsx
xrsbout
hyp="hyptargo"; tup="tuptargo"; anp="anptargo"; arp="arptargo"; ssp="ssptargo"
elif [ "$xhp" != yes ] && [ "$vlp" != yes ] && [ "$vxp" != yes ] && [ "$vwp" != yes ]; then
installsb
xrsbvm
xrsbso
warpsx
xrsbout
xhp="xhptargo"; vlp="vlptargo"; vxp="vxptargo"; vwp="vwptargo"
else
installsb
installxray
xrsbvm
xrsbso
warpsx
xrsbout
fi
if [ -n "$argo" ] && [ -n "$vmag" ]; then
echo
echo "=========启用Cloudflared-argo内核========="
if [ ! -e "$HOME/science/cloudflared" ]; then
argocore=$({ command -v curl >/dev/null 2>&1 && curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared || wget -qO- https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared; } | grep -Eo '"[0-9.]+"' | sed -n 1p | tr -d '",')
echo "下载Cloudflared-argo最新正式版内核：$argocore"
url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu"; out="$HOME/science/cloudflared"; (command -v curl>/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/science/cloudflared"
fi
if [ "$argo" = "vmpt" ]; then argoport=$(cat "$HOME/science/port_vm_ws" 2>/dev/null); echo "Vmess" > "$HOME/science/vlvm"; elif [ "$argo" = "vwpt" ]; then argoport=$(cat "$HOME/science/port_vw" 2>/dev/null); echo "Vless" > "$HOME/science/vlvm"; fi; echo "$argoport" > "$HOME/science/argoport.log"
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
argoname='固定'
if pidof systemd >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/systemd/system/argo.service <<EOF
[Unit]
Description=argo service
After=network.target
[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/root/science/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${ARGO_AUTH}"
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable argo >/dev/null 2>&1
systemctl start argo >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/init.d/argo <<EOF
#!/sbin/openrc-run
description="argo service"
command="/root/science/cloudflared tunnel"
command_args="--no-autoupdate --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH}"
pidfile="/run/argo.pid"
command_background="yes"
depend() {
need net
}
EOF
chmod +x /etc/init.d/argo >/dev/null 2>&1
rc-update add argo default >/dev/null 2>&1
rc-service argo start >/dev/null 2>&1
else
nohup "$HOME/science/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${ARGO_AUTH}" >/dev/null 2>&1 &
fi
echo "${ARGO_DOMAIN}" > "$HOME/science/sbargoym.log"
echo "${ARGO_AUTH}" > "$HOME/science/sbargotoken.log"
else
argoname='临时'
nohup "$HOME/science/cloudflared" tunnel --url http://localhost:$(cat $HOME/science/argoport.log) --edge-ip-version auto --no-autoupdate --protocol http2 > $HOME/science/argo.log 2>&1 &
fi
echo "申请Argo$argoname隧道中……请稍等"
sleep 15
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
argodomain=$(cat "$HOME/science/sbargoym.log" 2>/dev/null)
else
argodomain=$(grep -a trycloudflare.com "$HOME/science/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
fi
if [ -n "${argodomain}" ]; then
echo "Argo$argoname隧道申请成功"
else
echo "Argo$argoname隧道申请失败，请稍后再试"
fi
fi
sleep 5
echo
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'science/(s|x)' || pgrep -f 'science/(s|x)' >/dev/null 2>&1 ; then
[ -f ~/.bashrc ] || touch ~/.bashrc
sed -i '/science/d' ~/.bashrc
SCRIPT_PATH="$HOME/bin/science"
mkdir -p "$HOME/bin"
cp "$HOME/science/science.sh" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
echo "if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'science/(s|x)' && ! pgrep -f 'science/(s|x)' >/dev/null 2>&1; then echo '检测到系统可能中断过，或者变量格式错误？建议在SSH对话框输入 reboot 重启下服务器。现在自动执行Science脚本的节点恢复操作，请稍等……'; sleep 6; export cfip=\"${cfip}\" hyjpt=\"${hyjpt}\" cdnym=\"${cdnym}\" name=\"${name}\" ippz=\"${ippz}\" argo=\"${argo}\" uuid=\"${uuid}\" $wap=\"${warp}\" $xhp=\"${port_xh}\" $vxp=\"${port_vx}\" $ssp=\"${port_ss}\" $sop=\"${port_so}\" $anp=\"${port_an}\" $arp=\"${port_ar}\" $vlp=\"${port_vl_re}\" $vwp=\"${port_vw}\" $vmp=\"${port_vm_ws}\" $hyp=\"${port_hy2}\" $tup=\"${port_tu}\" reym=\"${ym_vl_re}\" agn=\"${ARGO_DOMAIN}\" agk=\"${ARGO_AUTH}\"; bash "$HOME/bin/science"; fi" >> ~/.bashrc
fi
sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' ~/.bashrc
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
grep -qxF 'source ~/.bashrc' ~/.bash_profile 2>/dev/null || echo 'source ~/.bashrc' >> ~/.bash_profile
. ~/.bashrc 2>/dev/null
crontab -l > /tmp/crontab.tmp 2>/dev/null
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
sed -i '/science\/sing-box/d' /tmp/crontab.tmp
sed -i '/science\/xray/d' /tmp/crontab.tmp
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -q 'science/s' || pgrep -f 'science/s' >/dev/null 2>&1 ; then
echo '@reboot sleep 10 && /bin/sh -c "nohup $HOME/science/sing-box run -c $HOME/science/sb.json >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
fi
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -q 'science/x' || pgrep -f 'science/x' >/dev/null 2>&1 ; then
echo '@reboot sleep 10 && /bin/sh -c "nohup $HOME/science/xray run -c $HOME/science/xr.json >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
fi
fi
sed -i '/science\/cloudflared/d' /tmp/crontab.tmp
if [ -n "$argo" ] && [ -n "$vmag" ]; then
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
echo '@reboot sleep 10 && /bin/sh -c "nohup $HOME/science/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token $(cat $HOME/science/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
fi
else
if command -v apk >/dev/null 2>&1; then
cat > /etc/local.d/alpinescience.start <<EOF
#!/bin/bash
sleep 10
nohup $HOME/science/cloudflared tunnel --url http://localhost:\$(cat $HOME/science/argoport.log) --edge-ip-version auto --no-autoupdate --protocol http2 > $HOME/science/argo.log 2>&1 &
sleep 10
HOME="$HOME" $HOME/bin/science list >/dev/null 2>&1
EOF
chmod +x /etc/local.d/alpinescience.start
rc-update add local default >/dev/null 2>&1
else
echo '@reboot sleep 10 && /bin/bash -c "nohup $HOME/science/cloudflared tunnel --url http://localhost:$(cat $HOME/science/argoport.log) --edge-ip-version auto --no-autoupdate --protocol http2 > $HOME/science/argo.log 2>&1 & sleep 10 && bash $HOME/bin/science list >/dev/null 2>&1"' >> /tmp/crontab.tmp
fi
fi
fi
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
echo "Science脚本进程启动成功，安装完毕" && sleep 2
else
echo "Science脚本进程未启动，安装失败" && exit
fi
# 下载合并版订阅面板（panel.html），用于busybox httpd订阅面板
panelurl="https://raw.githubusercontent.com/Hutton-h/science/main/panel.html"
echo "下载订阅面板html文件……"
(command -v curl >/dev/null 2>&1 && curl -Ls "$panelurl" -o "$HOME/science/panel.html") || (command -v wget >/dev/null 2>&1 && wget -qO "$HOME/science/panel.html" "$panelurl")
if [ -s "$HOME/science/panel.html" ]; then
echo "订阅面板下载成功"
else
echo "订阅面板下载失败，不影响节点使用，订阅面板将不可用"
fi
if [ -n "$cfip" ]; then
set -- $cfip
cdnip1="$1"
cdnip2="$2"
echo "$cdnip1" > "$HOME/science/cdnip1"
echo "$cdnip2" > "$HOME/science/cdnip2"
else
if [ -s "$HOME/science/cdnip1" ] && [ -s "$HOME/science/cdnip2" ]; then
cdnip1=$(cat "$HOME/science/cdnip1")
cdnip2=$(cat "$HOME/science/cdnip2")
else
cdnip1="sk1.skpllift.edu.pl"
cdnip2="sk6.skpllift.edu.pl"
echo "$cdnip1" > "$HOME/science/cdnip1"
echo "$cdnip2" > "$HOME/science/cdnip2"
fi
fi
}
sciencestatus(){
echo "=========当前三大内核运行状态========="
procs=$(find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null)
if echo "$procs" | grep -Eq 'science/s' || pgrep -f 'science/s' >/dev/null 2>&1; then
echo "Sing-box (版本V$("$HOME/science/sing-box" version 2>/dev/null | awk '/version/{print $NF}'))：运行中"
else
echo "Sing-box：未启用"
fi
if echo "$procs" | grep -Eq 'science/x' || pgrep -f 'science/x' >/dev/null 2>&1; then
echo "Xray (版本V$("$HOME/science/xray" version 2>/dev/null | awk '/^Xray/{print $2}'))：运行中"
else
echo "Xray：未启用"
fi
if echo "$procs" | grep -Eq 'science/c' || pgrep -f 'science/c' >/dev/null 2>&1; then
echo "Argo (版本V$("$HOME/science/cloudflared" version 2>/dev/null | awk '{print $3}'))：运行中"
else
echo "Argo：未启用"
fi
}
cip(){
ipbest(){
serip=$( (command -v curl >/dev/null 2>&1 && (curl -s4m5 -k "$v46url" 2>/dev/null || curl -s6m5 -k "$v46url" 2>/dev/null) ) || (command -v wget >/dev/null 2>&1 && (timeout 3 wget -4 -qO- --tries=2 "$v46url" 2>/dev/null || timeout 3 wget -6 -qO- --tries=2 "$v46url" 2>/dev/null) ) )
if echo "$serip" | grep -q ':'; then
server_ip="[$serip]"
echo "$server_ip" > "$HOME/science/server_ip.log"
else
server_ip="$serip"
echo "$server_ip" > "$HOME/science/server_ip.log"
fi
}
ipchange(){
v4v6
if [ -z "$v4" ]; then
vps_ipv4='无IPV4'
vps_ipv6="$v6"
location="$v6dq"
elif [ -n "$v4" ] && [ -n "$v6" ]; then
vps_ipv4="$v4"
vps_ipv6="$v6"
location="$v4dq"
else
vps_ipv4="$v4"
vps_ipv6='无IPV6'
location="$v4dq"
fi
if echo "$v6" | grep -q '^2a09'; then
w6="【WARP】"
fi
if echo "$v4" | grep -q '^104.28'; then
w4="【WARP】"
fi
echo
sciencestatus
echo
echo "=========当前服务器本地IP情况========="
echo "本地IPV4地址：$vps_ipv4 $w4"
echo "本地IPV6地址：$vps_ipv6 $w6"
echo "服务器地区：$location"
echo
sleep 2
if [ "$ippz" = "4" ]; then
if [ -z "$v4" ]; then
ipbest
else
server_ip="$v4"
echo "$server_ip" > "$HOME/science/server_ip.log"
fi
elif [ "$ippz" = "6" ]; then
if [ -z "$v6" ]; then
ipbest
else
server_ip="[$v6]"
echo "$server_ip" > "$HOME/science/server_ip.log"
fi
else
ipbest
fi
# 如果设置了域名变量dnym，用域名替代IP作为节点地址
if [ -n "$dnym" ]; then
server_ip="$dnym"
echo "$server_ip" > "$HOME/science/server_ip.log"
echo "========================================="
echo "使用自定义域名作为节点地址：$dnym"
echo "请确保域名已解析到服务器IP，否则节点无法连接"
echo "========================================="
fi
}
ipchange
rm -rf "$HOME/science/jhsub.txt"
uuid=$(cat "$HOME/science/uuid")
server_ip=$(cat "$HOME/science/server_ip.log")
sxname=$(cat "$HOME/science/name" 2>/dev/null)
xvvmcdnym=$(cat "$HOME/science/cdnym" 2>/dev/null)
cdnip1=$(cat "$HOME/science/cdnip1" 2>/dev/null)
cdnip2=$(cat "$HOME/science/cdnip2" 2>/dev/null)
echo "*********************************************************"
echo "*********************************************************"
echo "Science脚本输出节点配置如下："
echo
case "$server_ip" in
104.28*|\[2a09*) echo "检测到有WARP的IP作为客户端地址 (104.28或者2a09开头的IP)，请把客户端地址上的WARP的IP手动更换为VPS本地IPV4或者IPV6地址" && sleep 3 ;;
esac
echo
ym_vl_re=$(cat "$HOME/science/ym_vl_re" 2>/dev/null)
cfipsj() { echo $((RANDOM % 11 + 1)); }
if [ -e "$HOME/science/xray" ]; then
private_key_x=$(cat "$HOME/science/xrk/private_key" 2>/dev/null)
public_key_x=$(cat "$HOME/science/xrk/public_key" 2>/dev/null)
short_id_x=$(cat "$HOME/science/xrk/short_id" 2>/dev/null)
enkey=$(cat "$HOME/science/xrk/enkey" 2>/dev/null)
fi
if [ -e "$HOME/science/sing-box" ]; then
private_key_s=$(cat "$HOME/science/sbk/private_key" 2>/dev/null)
public_key_s=$(cat "$HOME/science/sbk/public_key" 2>/dev/null)
short_id_s=$(cat "$HOME/science/sbk/short_id" 2>/dev/null)
sskey=$(cat "$HOME/science/sskey" 2>/dev/null)
fi
if grep xhttp-reality "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-xhttp-reality-enc 】支持ENC加密，节点信息如下："
port_xh=$(cat "$HOME/science/port_xh")
vl_xh_link="vless://$uuid@$server_ip:$port_xh?encryption=$enkey&flow=xtls-rprx-vision&security=reality&sni=$ym_vl_re&fp=chrome&pbk=$public_key_x&sid=$short_id_x&type=xhttp&path=$uuid-xh&mode=auto#${sxname}vl-xhttp-reality-enc-$hostname"
echo "$vl_xh_link" >> "$HOME/science/jhsub.txt"
echo "$vl_xh_link"
echo
fi
if grep vless-xhttp "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-xhttp-enc 】支持ENC加密，节点信息如下："
port_vx=$(cat "$HOME/science/port_vx")
vl_vx_link="vless://$uuid@$server_ip:$port_vx?encryption=$enkey&flow=xtls-rprx-vision&type=xhttp&path=$uuid-vx&mode=auto#${sxname}vl-xhttp-enc-$hostname"
echo "$vl_vx_link" >> "$HOME/science/jhsub.txt"
echo "$vl_vx_link"
echo
if [ -f "$HOME/science/cdnym" ]; then
echo "💣【 Vless-xhttp-ecn-cdn 】支持ENC加密，节点信息如下："
echo "注：默认地址 sk数字.skpllift.edu.pl 可自行更换优选IP域名，如是回源端口需手动修改443或者80系端口"
vl_vx_cdn_link="vless://$uuid@sk$(cfipsj).skpllift.edu.pl:$port_vx?encryption=$enkey&flow=xtls-rprx-vision&type=xhttp&host=$xvvmcdnym&path=$uuid-vx&mode=auto#${sxname}vl-xhttp-enc-cdn-$hostname"
echo "$vl_vx_cdn_link" >> "$HOME/science/jhsub.txt"
echo "$vl_vx_cdn_link"
echo
fi
fi
if grep vless-ws "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-ws-enc 】支持ENC加密，节点信息如下："
port_vw=$(cat "$HOME/science/port_vw")
vl_vw_link="vless://$uuid@$server_ip:$port_vw?encryption=$enkey&flow=xtls-rprx-vision&type=ws&path=$uuid-vw#${sxname}vl-ws-enc-$hostname"
echo "$vl_vw_link" >> "$HOME/science/jhsub.txt"
echo "$vl_vw_link"
echo
if [ -f "$HOME/science/cdnym" ]; then
echo "💣【 Vless-ws-enc-cdn 】支持ENC加密，节点信息如下："
echo "注：默认地址 sk数字.skpllift.edu.pl 可自行更换优选IP域名，如是回源端口需手动修改443或者80系端口"
vl_vw_cdn_link="vless://$uuid@sk$(cfipsj).skpllift.edu.pl:$port_vw?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$xvvmcdnym&path=$uuid-vw#${sxname}vl-ws-enc-cdn-$hostname"
echo "$vl_vw_cdn_link" >> "$HOME/science/jhsub.txt"
echo "$vl_vw_cdn_link"
echo
fi
fi
if grep reality-vision "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-tcp-reality-vision 】节点信息如下："
port_vl_re=$(cat "$HOME/science/port_vl_re")
vl_link="vless://$uuid@$server_ip:$port_vl_re?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$ym_vl_re&fp=chrome&pbk=$public_key_x&sid=$short_id_x&type=tcp&headerType=none#${sxname}vl-reality-vision-$hostname"
echo "$vl_link" >> "$HOME/science/jhsub.txt"
echo "$vl_link"
echo
sbvlpt(){
cat <<EOF
    {
      "type": "vless",
      "tag": "${sxname}vless-$hostname",
      "server": "$server_ip",
      "server_port": $port_vl_re,
      "uuid": "$uuid",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "$ym_vl_re",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
      "reality": {
          "enabled": true,
          "public_key": "$public_key_x",
          "short_id": "$short_id_x"
        }
      }
    },
EOF
}
sbvlpt1(){
echo "\"${sxname}vless-$hostname\","
}
clvlpt(){
cat <<EOF
- name: ${sxname}vless-reality-vision-$hostname               
  type: vless
  server: $server_ip                          
  port: $port_vl_re                                
  uuid: $uuid   
  network: tcp
  udp: true
  tls: true
  flow: xtls-rprx-vision
  servername: $ym_vl_re                 
  reality-opts: 
    public-key: $public_key_x    
    short-id: $short_id_x                      
  client-fingerprint: chrome
EOF
}
clvlpt1(){
echo "- ${sxname}vless-reality-vision-$hostname"
}
fi
if grep ss-2022 "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Shadowsocks-2022 】节点信息如下："
port_ss=$(cat "$HOME/science/port_ss")
ss_link="ss://$(echo -n "2022-blake3-aes-128-gcm:$sskey@$server_ip:$port_ss" | base64 -w0)#${sxname}Shadowsocks-2022-$hostname"
echo "$ss_link" >> "$HOME/science/jhsub.txt"
echo "$ss_link"
echo
sbsspt(){
cat <<EOF
{
       "type": "shadowsocks",
       "tag": "${sxname}Shadowsocks-2022-$hostname",
       "server": "$server_ip",
       "server_port": $port_ss,
       "method": "2022-blake3-aes-128-gcm",
       "password": "$sskey",
       "udp_over_tcp": {
        "enabled": true,
        "version": 2
      }
     },
EOF
}
sbsspt1(){
echo "\"${sxname}Shadowsocks-2022-$hostname\","
}
clsspt(){
cat <<EOF
- name: "${sxname}Shadowsocks-2022-$hostname"
  type: ss
  server: $server_ip
  port: $port_ss
  cipher: 2022-blake3-aes-128-gcm
  password: "$sskey"
  udp: true
  udp-over-tcp: true
  udp-over-tcp-version: 2
EOF
}
clsspt1(){
echo "- ${sxname}Shadowsocks-2022-$hostname"
}
fi
if grep vmess-xr "$HOME/science/xr.json" >/dev/null 2>&1 || grep vmess-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Vmess-ws 】节点信息如下："
port_vm_ws=$(cat "$HOME/science/port_vm_ws")
vm_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vm-ws-$hostname\", \"add\": \"$server_ip\", \"port\": \"$port_vm_ws\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"www.bing.com\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vm_link" >> "$HOME/science/jhsub.txt"
echo "$vm_link"
echo
sbvmpt(){
cat <<EOF
{
            "server": "$server_ip",
            "server_port": $port_vm_ws,
            "tag": "${sxname}vmess-$hostname",
            "tls": {
                "enabled": false,
                "server_name": "www.bing.com",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "www.bing.com"
                    ]
                },
                "path": "$uuid-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF
}
sbvmpt1(){
echo "\"${sxname}vmess-$hostname\","
}
clvmpt(){
cat <<EOF
- name: ${sxname}vmess-ws-$hostname                         
  type: vmess
  server: $server_ip                        
  port: $port_vm_ws                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: www.bing.com                    
  ws-opts:
    path: "$uuid-vm"                             
    headers:
      Host: www.bing.com
EOF
}
clvmpt1(){
echo "- ${sxname}vmess-ws-$hostname"
}
if [ -f "$HOME/science/cdnym" ]; then
echo "💣【 Vmess-ws-cdn 】节点信息如下："
echo "注：默认地址 sk数字.skpllift.edu.pl 可自行更换优选IP域名，如是回源端口需手动修改443或者80系端口"
vm_cdn_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vm-ws-cdn-$hostname\", \"add\": \"sk$(cfipsj).skpllift.edu.pl\", \"port\": \"$port_vm_ws\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$xvvmcdnym\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vm_cdn_link" >> "$HOME/science/jhsub.txt"
echo "$vm_cdn_link"
echo
fi
fi
if grep anytls-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 AnyTLS 】节点信息如下："
port_an=$(cat "$HOME/science/port_an")
an_link="anytls://$uuid@$server_ip:$port_an?insecure=1&allowInsecure=1#${sxname}anytls-$hostname"
echo "$an_link" >> "$HOME/science/jhsub.txt"
echo "$an_link"
echo
sbanpt(){
cat <<EOF
         {
            "type": "anytls",
            "tag": "${sxname}anytls-$hostname",
            "server": "$server_ip",
            "server_port": $port_an,
            "password": "$uuid",
            "idle_session_check_interval": "30s",
            "idle_session_timeout": "30s",
            "min_idle_session": 5,
            "tls": {
                "enabled": true,
                "insecure": true,
                "server_name": "www.bing.com"
            }
         },
EOF
}
sbanpt1(){
echo "\"${sxname}anytls-$hostname\","
}
clanpt(){
cat <<EOF
- name: ${sxname}anytls-$hostname
  type: anytls
  server: $server_ip
  port: $port_an
  password: $uuid
  client-fingerprint: chrome
  udp: true
  idle-session-check-interval: 30
  idle-session-timeout: 30
  sni: www.bing.com
  skip-cert-verify: true
EOF
}
clanpt1(){
echo "- ${sxname}anytls-$hostname"
}
fi
if grep anyreality-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Any-Reality 】节点信息如下："
port_ar=$(cat "$HOME/science/port_ar")
ar_link="anytls://$uuid@$server_ip:$port_ar?security=reality&sni=$ym_vl_re&fp=chrome&pbk=$public_key_s&sid=$short_id_s&type=tcp&headerType=none#${sxname}any-reality-$hostname"
echo "$ar_link" >> "$HOME/science/jhsub.txt"
echo "$ar_link"
echo
sbarpt(){
cat <<EOF
    {
        "type": "anytls",
        "tag": "${sxname}any-reality-$hostname",
        "server": "$server_ip",
        "server_port": $port_ar,
        "password": "$uuid",
        "idle_session_check_interval": "30s",
        "idle_session_timeout": "30s",
        "min_idle_session": 5,
        "tls": {
        "enabled": true,
        "server_name": "$ym_vl_re",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
      "reality": {
          "enabled": true,
          "public_key": "$public_key_s",
          "short_id": "$short_id_s"
        }
      }
         },
EOF
}
sbarpt1(){
echo "\"${sxname}any-reality-$hostname\","
}
fi
if grep hy2-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Hysteria2 】节点信息如下："
SHA256=$(cat "$HOME/science/SHA256.txt")
port_hy2=$(cat "$HOME/science/port_hy2")
hy2_ports=$(iptables -t nat -nL --line 2>/dev/null | grep -w "$port_hy2" | awk '{print $8}' | sed 's/dpts://; s/dpt://' | tr '\n' ',' | sed 's/,$//')
if [ -n "$hy2_ports" ] || [ -n "$hyjpt" ]; then
echo "Hysteria2跳跃端口已开启：$hy2_ports"
cmhy2pt=$(echo $hy2_ports | tr ':' '-')
hyps="&mport=$cmhy2pt"
sbhy2pt=$(echo "$hy2_ports" | grep -o '[0-9]\+:[0-9]\+' | sed 's/.*/"&"/' | paste -sd,)
sbhy2ports(){
    cat <<EOF
  "server_ports": [ $sbhy2pt ],
EOF
}
else
hyps=
fi
#hy2_link="hysteria2://$uuid@$server_ip:$port_hy2?security=tls&alpn=h3&insecure=1&allowInsecure=1$hyps&sni=www.bing.com#${sxname}hy2-$hostname"
hy2_link="hysteria2://$uuid@$server_ip:$port_hy2?security=tls&alpn=h3&insecure=0&allowInsecure=0$hyps&sni=www.bing.com&pinSHA256=$SHA256#${sxname}hy2-$hostname"
echo "$hy2_link" >> "$HOME/science/jhsub.txt"
echo "$hy2_link"
echo
sbhypt(){
cat <<EOF
    {
        "type": "hysteria2",
        "tag": "${sxname}hy2-$hostname",
        "server": "$server_ip",
        "server_port": $port_hy2,
$(sbhy2ports 2>/dev/null)
        "password": "$uuid",
        "tls": {
            "enabled": true,
            "server_name": "www.bing.com",
            "insecure": true,
            "alpn": [
                "h3"
            ]
        }
    },
EOF
}
sbhypt1(){
echo "\"${sxname}hy2-$hostname\","
}
clhypt(){
cat <<EOF
- name: ${sxname}hysteria2-$hostname                            
  type: hysteria2                                      
  server: $server_ip                              
  port: $port_hy2
  ports: $cmhy2pt
  password: $uuid                          
  alpn:
    - h3
  sni: www.bing.com                               
  skip-cert-verify: true
  fast-open: true
EOF
}
clhypt1(){
echo "- ${sxname}hysteria2-$hostname"
}
fi
if grep tuic5-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Tuic 】节点信息如下："
port_tu=$(cat "$HOME/science/port_tu")
tuic5_link="tuic://$uuid:$uuid@$server_ip:$port_tu?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=www.bing.com&insecure=1&allow_insecure=1#${sxname}tuic-$hostname"
echo "$tuic5_link" >> "$HOME/science/jhsub.txt"
echo "$tuic5_link"
echo
sbtupt(){
cat <<EOF
        {
            "type":"tuic",
            "tag": "${sxname}tuic5-$hostname",
            "server": "$server_ip",
            "server_port": $port_tu,
            "uuid": "$uuid",
            "password": "$uuid",
            "congestion_control": "bbr",
            "udp_relay_mode": "native",
            "udp_over_stream": false,
            "zero_rtt_handshake": false,
            "heartbeat": "10s",
            "tls":{
                "enabled": true,
                "server_name": "www.bing.com",
                "insecure": true,
                "alpn": [
                    "h3"
                ]
            }
        },
EOF
}
sbtupt1(){
echo "\"${sxname}tuic5-$hostname\","
}
cltupt(){
cat <<EOF
- name: ${sxname}tuic5-$hostname                            
  server: $server_ip                      
  port: $port_tu                                    
  type: tuic
  uuid: $uuid       
  password: $uuid   
  alpn: [h3]
  disable-sni: true
  reduce-rtt: true
  udp-relay-mode: native
  congestion-controller: bbr
  sni: www.bing.com                                
  skip-cert-verify: true
EOF
}
cltupt1(){
echo "- ${sxname}tuic5-$hostname"
}
fi
if grep socks5-xr "$HOME/science/xr.json" >/dev/null 2>&1 || grep socks5-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Socks5 】客户端信息如下："
port_so=$(cat "$HOME/science/port_so")
echo "请配合其他应用内置代理使用，勿做节点直接使用"
echo "客户端地址：$server_ip"
echo "客户端端口：$port_so"
echo "客户端用户名：$uuid"
echo "客户端密码：$uuid"
echo
fi
argodomain=$(cat "$HOME/science/sbargoym.log" 2>/dev/null)
[ -z "$argodomain" ] && argodomain=$(grep -a trycloudflare.com "$HOME/science/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
if [ -n "$argodomain" ]; then
vlvm=$(cat $HOME/science/vlvm 2>/dev/null)
if [ "$vlvm" = "Vmess" ]; then
vmatls_link1="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-443\", \"add\": \"$cdnip1\", \"port\": \"443\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link1" >> "$HOME/science/jhsub.txt"
vmatls_link2="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-8443\", \"add\": \"sk2.skpllift.edu.pl\", \"port\": \"8443\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link2" >> "$HOME/science/jhsub.txt"
vmatls_link3="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2053\", \"add\": \"sk3.skpllift.edu.pl\", \"port\": \"2053\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link3" >> "$HOME/science/jhsub.txt"
vmatls_link4="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2083\", \"add\": \"sk4.skpllift.edu.pl\", \"port\": \"2083\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link4" >> "$HOME/science/jhsub.txt"
vmatls_link5="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2087\", \"add\": \"sk5.skpllift.edu.pl\", \"port\": \"2087\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link5" >> "$HOME/science/jhsub.txt"
vmatls_link6="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2096\", \"add\": \"[2606:4700::0]\", \"port\": \"2096\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link6" >> "$HOME/science/jhsub.txt"
vma_link7="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-80\", \"add\": \"$cdnip2\", \"port\": \"80\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link7" >> "$HOME/science/jhsub.txt"
vma_link8="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-8080\", \"add\": \"sk7.skpllift.edu.pl\", \"port\": \"8080\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link8" >> "$HOME/science/jhsub.txt"
vma_link9="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-8880\", \"add\": \"sk8.skpllift.edu.pl\", \"port\": \"8880\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link9" >> "$HOME/science/jhsub.txt"
vma_link10="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2052\", \"add\": \"sk9.skpllift.edu.pl\", \"port\": \"2052\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link10" >> "$HOME/science/jhsub.txt"
vma_link11="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2082\", \"add\": \"sk10.skpllift.edu.pl\", \"port\": \"2082\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link11" >> "$HOME/science/jhsub.txt"
vma_link12="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2086\", \"add\": \"sk11.skpllift.edu.pl\", \"port\": \"2086\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link12" >> "$HOME/science/jhsub.txt"
vma_link13="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2095\", \"add\": \"[2400:cb00:2049::0]\", \"port\": \"2095\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link13" >> "$HOME/science/jhsub.txt"
sbvmargopt(){
cat <<EOF
{
            "server": "$cdnip1",
            "server_port": 443,
            "tag": "${sxname}vmess-ws-tls-argo-$hostname-443",
            "tls": {
                "enabled": true,
                "server_name": "$argodomain",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argodomain"
                    ]
                },
                "path": "$uuid-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
{
            "server": "$cdnip2",
            "server_port": 80,
            "tag": "${sxname}vmess-ws-argo-$hostname-80",
            "tls": {
                "enabled": false,
                "server_name": "$argodomain",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argodomain"
                    ]
                },
                "path": "$uuid-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF
}
sbvmargopt1(){
echo "\"${sxname}vmess-ws-tls-argo-$hostname-443\","
echo "\"${sxname}vmess-ws-argo-$hostname-80\","
}
clvmargopt(){
cat <<EOF
- name: ${sxname}vmess-ws-tls-argo-$hostname-443                         
  type: vmess
  server: "$cdnip1"                       
  port: 443                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  network: ws
  servername: $argodomain                    
  ws-opts:
    path: "$uuid-vm"                             
    headers:
      Host: $argodomain
- name: ${sxname}vmess-ws-argo-$hostname-80                         
  type: vmess
  server: "$cdnip2"                        
  port: 80                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: $argodomain                    
  ws-opts:
    path: "$uuid-vm"                             
    headers:
      Host: $argodomain
EOF
}
clvmargopt1(){
echo "- ${sxname}vmess-ws-tls-argo-$hostname-443"
echo "- ${sxname}vmess-ws-argo-$hostname-80"
}
elif [ "$vlvm" = "Vless" ]; then
vwatls_link1="vless://$uuid@$cdnip1:443?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$argodomain&path=$uuid-vw&security=tls&sni=$argodomain&fp=chrome&insecure=0&allowInsecure=0#${sxname}vless-ws-tls-argo-enc-vision-$hostname"
echo "$vwatls_link1" >> "$HOME/science/jhsub.txt"
vwa_link2="vless://$uuid@$cdnip2:80?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$argodomain&path=$uuid-vw&security=none#${sxname}vless-ws-argo-enc-vision-$hostname"
echo "$vwa_link2" >> "$HOME/science/jhsub.txt"
fi
sbtk=$(cat "$HOME/science/sbargotoken.log" 2>/dev/null)
if [ -n "$sbtk" ]; then
nametn="Argo固定隧道token：$sbtk"
fi
argoshow=$(
echo "Argo隧道端口正在使用$vlvm-ws主协议端口：$(cat $HOME/science/argoport.log 2>/dev/null)
Argo域名：$argodomain
$nametn

1、💣443端口的$vlvm-ws-tls-argo节点(优选IP与443系端口随便换)
${vmatls_link1}${vwatls_link1}

2、💣80端口的$vlvm-ws-argo节点(优选IP与80系端口随便换)
${vma_link7}${vwa_link2}
"
)
fi

get_func() {
local f=$1
if type "$f" >/dev/null 2>&1; then
local out
out=$($f)
[ -n "$out" ] && printf "%s\n" "$out"
fi
}
sbxy="$(get_func sbvlpt; get_func sbsspt; get_func sbanpt; get_func sbarpt; get_func sbvmpt; get_func sbhypt; get_func sbtupt; get_func sbvmargopt)"
clxy="$(get_func clvlpt; get_func clsspt; get_func clanpt; get_func clvmpt; get_func clhypt; get_func cltupt; get_func clvmargopt)"
sbgz="$(get_func sbvlpt1; get_func sbsspt1; get_func sbanpt1; get_func sbarpt1; get_func sbvmpt1; get_func sbhypt1; get_func sbtupt1; get_func sbvmargopt1)"
clgz="$({ get_func clvlpt1; get_func clsspt1; get_func clanpt1; get_func clvmpt1; get_func clhypt1; get_func cltupt1; get_func clvmargopt1; } | sed '2,$s/^/    /')"
sbgz=$(printf "%s\n" "$sbgz" | sed '$ s/,$//')
cat > $HOME/science/sbox.json <<EOF
{
    "log": {
        "disabled": false,
        "level": "info",
        "timestamp": true
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "./cache.db",
            "store_fakeip": true
        },
        "clash_api": {
            "external_controller": "127.0.0.1:9090",
            "external_ui": "ui",
            "default_mode": "Rule"
        }
    },
    "dns": {
        "servers": [
            {
                "tag": "aliDns",
                "type": "https",
                "server": "dns.alidns.com",
                "path": "/dns-query",
                "domain_resolver": "local"
            },
            {
                "tag": "local",
                "type": "udp",
                "server": "223.5.5.5"
            },
            {
                "tag": "proxyDns",
                "type": "https",
                "server": "dns.google",
                "path": "/dns-query",
	              "domain_resolver": "aliDns",
                "detour": "proxy"
            },
           {
        "type": "fakeip",
        "tag": "fakeip",
        "inet4_range": "198.18.0.0/15",
        "inet6_range": "fc00::/18"
      }
        ],
        "rules": [
            {
                "rule_set": "geosite-cn",
                "clash_mode": "Rule",
                "server": "aliDns"
            },
            {
                "clash_mode": "Direct",
                "server": "local"
            },
            {
                "clash_mode": "Global",
                "server": "proxyDns"
            },
            {
        "query_type": [
          "A",
          "AAAA"
        ],
        "server": "fakeip"
      }
        ],
        "final": "proxyDns",
        "strategy": "prefer_ipv4"
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "address": [
                "172.19.0.1/30",
                "fd00::1/126"
            ],
            "auto_route": true,
            "strict_route": true
        }
    ],
    "route": {
        "rules": [
            {
	 "inbound": "tun-in",
                "action": "sniff"
            },
            {
                "type": "logical",
                "mode": "or",
                "rules": [
                    {
                        "port": 53
                    },
                    {
                        "protocol": "dns"
                    }
                ],
                "action": "hijack-dns"
            },
         {
          "clash_mode": "Global",
          "outbound": "proxy"
         },
        {
        "rule_set": "geosite-cn",
        "clash_mode": "Rule",
        "outbound": "direct"
       },
     {
    "rule_set": "geoip-cn",
    "clash_mode": "Rule",
    "outbound": "direct"
      },
     {
    "ip_is_private": true,
    "clash_mode": "Rule",
    "outbound": "direct"
    },
     {
      "clash_mode": "Direct",
      "outbound": "direct"
     }		
        ],
        "rule_set": [
            {
                "tag": "geosite-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-cn.srs",
                "download_detour": "direct"
            },
            {
                "tag": "geoip-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/cn.srs",
                "download_detour": "direct"
            }
        ],
        "final": "proxy",
        "auto_detect_interface": true,
        "default_domain_resolver": {
        "server": "aliDns"
        }
    },
  "outbounds": [
   $sbxy
        {
            "tag": "proxy",
            "type": "selector",
            "default": "auto",
            "outbounds": [
        "auto",
        $sbgz
            ]
        },
        {
            "tag": "auto",
            "type": "urltest",
            "outbounds": [
            $sbgz
            ],
            "url": "http://www.gstatic.com/generate_204",
            "interval": "10m",
            "tolerance": 50
        },
        {
            "type": "direct",
            "tag": "direct"
        }
    ]
}
EOF

cat > $HOME/science/clmi.yaml <<EOF
port: 7890
allow-lan: true
mode: rule
log-level: info
unified-delay: true
dns:
  enable: true 
  listen: "0.0.0.0:1053"
  ipv6: true
  prefer-h3: false
  respect-rules: true
  use-system-hosts: false
  cache-algorithm: "arc"
  enhanced-mode: "fake-ip"
  fake-ip-range: "198.18.0.1/16"
  fake-ip-filter:
    - "+.lan"
    - "+.local"
    - "+.msftconnecttest.com"
    - "+.msftncsi.com"
    - "localhost.ptlogin2.qq.com"
    - "localhost.sec.qq.com"
    - "+.in-addr.arpa"
    - "+.ip6.arpa"
    - "time.*.com"
    - "time.*.gov"
    - "pool.ntp.org"
    - "localhost.work.weixin.qq.com"
  default-nameserver: ["223.5.5.5", "119.29.29.29"]
  nameserver:
    - "https://1.1.1.1/dns-query"
    - "https://8.8.8.8/dns-query"
  proxy-server-nameserver:
    - "https://223.5.5.5/dns-query"
    - "https://doh.pub/dns-query"

proxies:
$clxy

proxy-groups:
- name: 负载均衡
  type: load-balance
  url: https://www.gstatic.com/generate_204
  interval: 300
  strategy: round-robin
  proxies:
    $clgz
- name: 自动选择
  type: url-test
  url: https://www.gstatic.com/generate_204
  interval: 300
  tolerance: 50
  proxies:
    $clgz 
- name: 🌍选择代理节点
  type: select
  proxies:
    - 负载均衡                                         
    - 自动选择
    - DIRECT
    $clgz
rules:
  - GEOIP,LAN,DIRECT
  - GEOSITE,CN,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,🌍选择代理节点
EOF
echo "---------------------------------------------------------"
echo "$argoshow"
echo
if [ -s $HOME/science/subport.log ]; then
showsubport=$(cat $HOME/science/subport.log)
if ps -ef 2>/dev/null | grep "$showsubport" | grep -v grep >/dev/null; then
showsubtoken=$(cat $HOME/science/subtoken.log 2>/dev/null)
subip=$(cat $HOME/science/server_ip.log 2>/dev/null)
suburl="$subip:$showsubport/$showsubtoken"
# 判断是否使用域名，调整显示标签
if [ -n "$dnym" ]; then
addrlabel="域名"
else
addrlabel="本地IP"
fi
echo "**********************************************************"
echo "Clash/Mihomo${addrlabel}订阅地址：http://$suburl/clmi.yaml"
echo "Sing-box${addrlabel}订阅地址：http://$suburl/sbox.json"
echo "聚合协议${addrlabel}订阅地址：http://$suburl/jhsub.txt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌟 订阅面板地址：http://$suburl/index.html"
echo "**********************************************************"
fi
fi
echo
echo "---------------------------------------------------------"
echo "聚合节点信息，请进入 $HOME/science/jhsub.txt 文件目录查看或者运行 cat $HOME/science/jhsub.txt 查看"
echo "========================================================="
echo "相关快捷方式如下：(首次安装成功后需重连SSH，science快捷方式才可生效；如未生效，请使用主脚本)"
showmode
}
cleandel(){
for P in /proc/[0-9]*; do if [ -L "$P/exe" ]; then TARGET=$(readlink -f "$P/exe" 2>/dev/null); if echo "$TARGET" | grep -qE '/science/c|/science/s|/science/x'; then PID=$(basename "$P"); kill "$PID" 2>/dev/null; fi; fi; done
kill -15 $(pgrep -f 'science/s' 2>/dev/null) $(pgrep -f 'science/c' 2>/dev/null) $(pgrep -f 'science/x' 2>/dev/null) $(pgrep -f 'websbx' 2>/dev/null) >/dev/null 2>&1
sed -i '/science/d' ~/.bashrc
sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' ~/.bashrc
. ~/.bashrc 2>/dev/null
crontab -l > /tmp/crontab.tmp 2>/dev/null
sed -i '/science\/sing-box/d' /tmp/crontab.tmp
sed -i '/science\/xray/d' /tmp/crontab.tmp
sed -i '/science\/cloudflared/d' /tmp/crontab.tmp
sed -i '/websbx/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
rm -rf  "$HOME/bin/science"
if pidof systemd >/dev/null 2>&1; then
for svc in xr sb argo; do
systemctl stop "$svc" >/dev/null 2>&1
systemctl disable "$svc" >/dev/null 2>&1
done
rm -rf /etc/systemd/system/{xr.service,sb.service,argo.service}
elif command -v rc-service >/dev/null 2>&1; then
for svc in sing-box xray argo; do
rc-service "$svc" stop >/dev/null 2>&1
rc-update del "$svc" default >/dev/null 2>&1
done
rm -rf /etc/init.d/{sing-box,xray,argo} /etc/local.d/alpinescience.start /etc/local.d/alpinesubsbx.start
iptables -t nat -F PREROUTING >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
rc-service iptables save >/dev/null 2>&1
rc-service ip6tables save >/dev/null 2>&1
fi
}
xrestart(){
kill -15 $(pgrep -f 'science/x' 2>/dev/null) >/dev/null 2>&1
if pidof systemd >/dev/null 2>&1; then
systemctl restart xr >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-service xray restart >/dev/null 2>&1
else
nohup $HOME/science/xray run -c $HOME/science/xr.json >/dev/null 2>&1 &
fi
}
sbrestart(){
kill -15 $(pgrep -f 'science/s' 2>/dev/null) >/dev/null 2>&1
if pidof systemd >/dev/null 2>&1; then
systemctl restart sb >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-service sing-box restart >/dev/null 2>&1
else
nohup $HOME/science/sing-box run -c $HOME/science/sb.json >/dev/null 2>&1 &
fi
}
if [ "$1" = "del" ]; then
cleandel
rm -rf sbx_update "$HOME/science" "$HOME/websbx"
echo "卸载完成"
echo "欢迎继续使用skpl的Science一键无交互小钢炮脚本💣" && sleep 2
echo
showmode
exit
elif [ "$1" = "rep" ]; then
cleandel
rm -rf "$HOME/science"/{sb.json,xr.json,sbargoym.log,sbargotoken.log,argo.log,argoport.log,cdnym,name}
echo "Science重置协议完成，开始更新相关协议变量……" && sleep 2
echo
elif [ "$1" = "list" ]; then
cip
exit
elif [ "$1" = "upx" ]; then
for P in /proc/[0-9]*; do [ -L "$P/exe" ] || continue; TARGET=$(readlink -f "$P/exe" 2>/dev/null) || continue; case "$TARGET" in *"/science/x"*) kill "$(basename "$P")" 2>/dev/null ;; esac; done
kill -15 $(pgrep -f 'science/x' 2>/dev/null) >/dev/null 2>&1
upxray && xrestart && echo "Xray内核更新完成" && sleep 2 && cip
exit
elif [ "$1" = "ups" ]; then
for P in /proc/[0-9]*; do [ -L "$P/exe" ] || continue; TARGET=$(readlink -f "$P/exe" 2>/dev/null) || continue; case "$TARGET" in *"/science/s"*) kill "$(basename "$P")" 2>/dev/null ;; esac; done
kill -15 $(pgrep -f 'science/s' 2>/dev/null) >/dev/null 2>&1
upsingbox && sbrestart && echo "Sing-box内核更新完成" && sleep 2 && cip
exit
elif [ "$1" = "res" ]; then
for P in /proc/[0-9]*; do
[ -L "$P/exe" ] || continue
TARGET=$(readlink -f "$P/exe" 2>/dev/null) || continue
case "$TARGET" in
*"/science/s"*)
kill "$(basename "$P")" 2>/dev/null
sbrestart
;;
*"/science/x"*)
kill "$(basename "$P")" 2>/dev/null
xrestart
;;
*"/science/c"*)
kill "$(basename "$P")" 2>/dev/null
kill -15 $(pgrep -f 'science/c' 2>/dev/null) >/dev/null 2>&1
if [ -e "$HOME/science/sbargotoken.log" ]; then
if pidof systemd >/dev/null 2>&1; then
systemctl restart argo >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-service argo restart >/dev/null 2>&1
else
nohup $HOME/science/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token $(cat $HOME/science/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 &
fi
else
nohup $HOME/science/cloudflared tunnel --url http://localhost:$(cat $HOME/science/argoport.log 2>/dev/null) --edge-ip-version auto --no-autoupdate --protocol http2 > $HOME/science/argo.log 2>&1 &
fi
;;
esac
done
sleep 5 && echo "重启完成" && sleep 3 && cip
exit
fi
# 部署/更新订阅面板命令
if [ "$1" = "panel" ]; then
panelurl="https://raw.githubusercontent.com/Hutton-h/science/main/panel.html"
echo "正在下载最新订阅面板……"
(command -v curl >/dev/null 2>&1 && curl -Ls "$panelurl" -o "$HOME/science/panel.html") || (command -v wget >/dev/null 2>&1 && wget -qO "$HOME/science/panel.html" "$panelurl")
if [ -s "$HOME/science/panel.html" ]; then
  echo "订阅面板下载成功！"
  if [ -s "$HOME/science/subport.log" ] && [ -s "$HOME/science/subtoken.log" ]; then
    mkdir -p "$HOME/websbx/$(cat $HOME/science/subtoken.log)"
    ln -sf "$HOME/science/panel.html" "$HOME/websbx/$(cat $HOME/science/subtoken.log)/index.html"
    echo "面板已部署到订阅目录"
    subip=$(cat $HOME/science/server_ip.log 2>/dev/null)
    subport=$(cat $HOME/science/subport.log)
    subtoken=$(cat $HOME/science/subtoken.log)
    echo "面板地址：http://$subip:$subport/$subtoken/index.html"
    # 启动状态监控cron
    (crontab -l 2>/dev/null | grep -v 'science/statusgen'; echo "*/2 * * * * $HOME/science/science.sh statusgen >/dev/null 2>&1") | crontab - 2>/dev/null
    echo "已启动每2分钟自动更新状态监控"
  else
    echo "提示：订阅功能未开启，请先运行 sub=y 的主脚本启用订阅"
  fi
else
  echo "订阅面板下载失败，请检查网络"
fi
exit
fi
# 生成状态监控JSON（供面板实时读取）
if [ "$1" = "statusgen" ]; then
mkdir -p "$HOME/websbx/$(cat $HOME/science/subtoken.log 2>/dev/null)" 2>/dev/null
wsdir="$HOME/websbx/$(cat $HOME/science/subtoken.log 2>/dev/null)"
[ -z "$wsdir" ] || [ "$wsdir" = "$HOME/websbx/" ] && exit
# 内核状态
if pgrep -f 'science/x' >/dev/null 2>&1; then xray_status="running"; else xray_status="stopped"; fi
if pgrep -f 'science/s' >/dev/null 2>&1; then sbox_status="running"; else sbox_status="stopped"; fi
if pgrep -f 'science/c' >/dev/null 2>&1; then argo_status="running"; else argo_status="stopped"; fi
# 节点数
node_count=$(grep -c '://' "$HOME/science/jhsub.txt" 2>/dev/null || echo 0)
# 流量统计 (字节)
rx_bytes=$(awk '/eth0|ens|venet/{rx+=$2}END{print rx}' /proc/net/dev 2>/dev/null || echo 0)
tx_bytes=$(awk '/eth0|ens|venet/{tx+=$10}END{print tx}' /proc/net/dev 2>/dev/null || echo 0)
# VPS信息
hostname=$(uname -n)
uptime_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null || echo 0)
mem_avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo 2>/dev/null || echo 0)
cpu_usage=$(top -bn1 | awk '/^%Cpu/{print 100-$8"%"}' 2>/dev/null || echo "N/A")
# 上次更新
last_update=$(date '+%Y-%m-%d %H:%M:%S')
# 写入JSON
cat > "$wsdir/status.json" <<EOF
{
  "hostname": "$hostname",
  "uptime": $uptime_sec,
  "memory": {"total": $mem_total, "available": $mem_avail},
  "cpu": "$cpu_usage",
  "traffic": {"rx_bytes": $rx_bytes, "tx_bytes": $tx_bytes},
  "kernels": {"xray": "$xray_status", "singbox": "$sbox_status", "argo": "$argo_status"},
  "node_count": $node_count,
  "last_update": "$last_update",
  "server_ip": "$(cat $HOME/science/server_ip.log 2>/dev/null)",
  "dnym": "${dnym:-}"
}
EOF
exit
fi
if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'science/(s|x)' && ! pgrep -f 'science/(s|x)' >/dev/null 2>&1; then
for P in /proc/[0-9]*; do if [ -L "$P/exe" ]; then TARGET=$(readlink -f "$P/exe" 2>/dev/null); if echo "$TARGET" | grep -qE '/science/c|/science/s|/science/x'; then PID=$(basename "$P"); kill "$PID" 2>/dev/null && echo "Killed $PID ($TARGET)" || echo "Could not kill $PID ($TARGET)"; fi; fi; done
kill -15 $(pgrep -f 'science/s' 2>/dev/null) $(pgrep -f 'science/c' 2>/dev/null) $(pgrep -f 'science/x' 2>/dev/null) >/dev/null 2>&1
if [ -z "$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1" > /etc/resolv.conf
fi
if [ -n "$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
sendip="2606:4700:d0::a29f:c001"
xendip="[2606:4700:d0::a29f:c001]"
else
sendip="162.159.192.1"
xendip="162.159.192.1"
fi
echo "VPS系统：$op"
echo "CPU架构：$cpu"
echo "Science脚本未安装，开始安装…………" && sleep 1
if [ -n "$oap" ]; then
setenforce 0 >/dev/null 2>&1
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
iptables -F >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
echo
echo "iptables执行开放所有端口"
fi
ins
if [ -n "$sub" ]; then
subtokenipsub(){
if [ -z "$subid" ]; then
subtoken="$(cat "$HOME/science/uuid")"
else
subtoken="$subid"
fi
rm -rf $HOME/websbx/"$(cat $HOME/science/subtoken.log 2>/dev/null)"
echo $subtoken > $HOME/science/subtoken.log
}
subportipsub(){
if [ -z "$subpt" ]; then
if [ -n "$(cat "$HOME/science/subport.log" 2>/dev/null)" ]; then
subport=$(cat $HOME/science/subport.log)
else
subport=$(shuf -i 10000-65535 -n 1)
fi
else
subport="$subpt"
fi
echo $subport > $HOME/science/subport.log
}
subtokenipsub && subportipsub
echo "请稍后…………"
kill -15 $(pgrep -f 'websbx' 2>/dev/null) >/dev/null 2>&1
mkdir -p $HOME/websbx/"$(cat $HOME/science/subtoken.log 2>/dev/null)"
# 确保panel.html已下载（备用下载，防止ins()中下载失败）
if [ ! -s "$HOME/science/panel.html" ]; then
panelurl="https://raw.githubusercontent.com/Hutton-h/science/main/panel.html"
(command -v curl >/dev/null 2>&1 && curl -Ls "$panelurl" -o "$HOME/science/panel.html") || (command -v wget >/dev/null 2>&1 && wget -qO "$HOME/science/panel.html" "$panelurl")
fi
ln -sf $HOME/science/clmi.yaml $HOME/websbx/"$(cat $HOME/science/subtoken.log 2>/dev/null)"/clmi.yaml
ln -sf $HOME/science/sbox.json $HOME/websbx/"$(cat $HOME/science/subtoken.log 2>/dev/null)"/sbox.json
ln -sf $HOME/science/jhsub.txt $HOME/websbx/"$(cat $HOME/science/subtoken.log 2>/dev/null)"/jhsub.txt
ln -sf $HOME/science/panel.html $HOME/websbx/"$(cat $HOME/science/subtoken.log 2>/dev/null)"/index.html
if command -v apk >/dev/null 2>&1; then
busybox-extras httpd -f -p "$(cat $HOME/science/subport.log 2>/dev/null)" -h $HOME/websbx > /dev/null 2>&1 &
else
busybox httpd -f -p "$(cat $HOME/science/subport.log 2>/dev/null)" -h $HOME/websbx > /dev/null 2>&1 &
fi
sleep 5
if command -v apk >/dev/null 2>&1; then
cat > /etc/local.d/alpinesubsbx.start <<EOF
#!/bin/bash
sleep 10
busybox-extras httpd -f -p \$(cat $HOME/science/subport.log 2>/dev/null) -h $HOME/websbx > /dev/null 2>&1 &
EOF
chmod +x /etc/local.d/alpinesubsbx.start
rc-update add local default >/dev/null 2>&1
else
crontab -l 2>/dev/null > /tmp/crontab.tmp
sed -i '/websbx/d' /tmp/crontab.tmp
echo '@reboot sleep 10 && /bin/bash -c "busybox httpd -f -p $(cat $HOME/science/subport.log 2>/dev/null) -h $HOME/websbx > /dev/null 2>&1 &"' >> /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
fi
echo "本地IP订阅链接已更新完成"
# 启动状态监控cron（每2分钟更新status.json供面板实时读取）
(crontab -l 2>/dev/null | grep -v 'science/statusgen'; echo "*/2 * * * * $HOME/science/science.sh statusgen >/dev/null 2>&1") | crontab - 2>/dev/null
echo "已启动面板状态监控（每2分钟更新）"
fi
if [ -n "$hyjpt" ] && [ -n "$hyp" ]; then
echo
echo "设置Hysteria2协议的跳跃端口：$hyjpt"
iptables -t nat -F PREROUTING >/dev/null 2>&1
ip6tables -t nat -F PREROUTING >/dev/null 2>&1
hyport=$(cat "$HOME/science/port_hy2")
for port in $hyjpt; do
iptables -t nat -A PREROUTING -p udp --dport "$port" -j DNAT --to-destination :$hyport
ip6tables -t nat -A PREROUTING -p udp --dport "$port" -j DNAT --to-destination :$hyport
done
netfilter-persistent save >/dev/null 2>&1
if command -v rc-service >/dev/null 2>&1 && command -v rc-update >/dev/null 2>&1; then
rc-update show default 2>/dev/null | grep -q 'iptables' || rc-update add iptables >/dev/null 2>&1
rc-update show default 2>/dev/null | grep -q 'ip6tables' || rc-update add ip6tables >/dev/null 2>&1
rc-service iptables save >/dev/null 2>&1
rc-service ip6tables save >/dev/null 2>&1
fi
fi
cip
echo
else
echo "Science脚本已安装"
echo
sciencestatus
echo
echo "相关快捷方式如下："
showmode
exit
fi
