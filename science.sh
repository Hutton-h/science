#!/bin/bash
export LANG=en_US.UTF-8

# 中断处理：Ctrl+C 时清理临时文件
cleanup_on_exit() {
    echo ""
    echo "脚本被中断，正在退出..."
    exit 1
}
trap cleanup_on_exit INT TERM

# 生成不冲突的随机端口：避免与其他已生成端口重复、与系统已监听端口冲突、落入 hyjpt 跳跃段
gen_port() {
    local p i range_lo range_hi
    for i in 1 2 3 4 5 6 7 8 9 10; do
        p=$(shuf -i 10000-65535 -n 1)
        # 与其他协议端口文件冲突
        if grep -h . "$HOME/science/port_"* 2>/dev/null | grep -qx "$p"; then continue; fi
        # 与系统已监听端口冲突
        if command -v ss >/dev/null 2>&1 && ss -Hlntu 2>/dev/null | grep -Eq ":$p " 2>/dev/null; then continue; fi
        # 避免落入 hyjpt 跳跃段（UDP 协议端口会被 DNAT 劫持）
        if [ -n "$hyjpt" ]; then
            range_lo=${hyjpt%%:*}; range_hi=${hyjpt##*:}
            if [ "$range_lo" -le "$p" ] 2>/dev/null && [ "$p" -le "$range_hi" ] 2>/dev/null; then continue; fi
        fi
        echo "$p"; return 0
    done
    echo "$p"
}

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
[ -z "${tjpt+x}" ] || tjp=yes
[ -z "${tjgpt+x}" ] || tjgp=yes
[ -z "${tjtpt+x}" ] || tjtp=yes
[ -z "${xupt+x}" ] || xup=yes
[ -z "${xcpt+x}" ] || xcp=yes
[ -z "${vgpt+x}" ] || vgp=yes
[ -z "${vhupt+x}" ] || vhup=yes
[ -z "${vmgpt+x}" ] || vmgp=yes
[ -z "${vmhupt+x}" ] || vmhup=yes
# 一键全协议预设：all=y 自动开启全部协议+Hysteria2端口跳跃+SOCKS5+订阅（Argo需额外指定agn和agk）
[ -z "${all+x}" ] || { vlp=yes; vmp=yes; vmag=yes; vwp=yes; hyp=yes; hyjpt="10000:20000"; tup=yes; xhp=yes; vxp=yes; anp=yes; arp=yes; ssp=yes; sop=yes; tjp=yes; tjgp=yes; tjtp=yes; xup=yes; xcp=yes; vgp=yes; vhup=yes; vmgp=yes; vmhup=yes; sub=y; vmag=yes; }
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'science/(s|x)' || pgrep -f 'science/(s|x)' >/dev/null 2>&1; then
if [ "$1" = "rep" ]; then
[ "$xcp" = yes ] || [ "$xup" = yes ] || [ "$tjp" = yes ] || [ "$tjgp" = yes ] || [ "$tjtp" = yes ] || [ "$vgp" = yes ] || [ "$vhup" = yes ] || [ "$vmgp" = yes ] || [ "$vmhup" = yes ] || [ "$vwp" = yes ] || [ "$sop" = yes ] || [ "$vxp" = yes ] || [ "$ssp" = yes ] || [ "$vlp" = yes ] || [ "$vmp" = yes ] || [ "$hyp" = yes ] || [ "$tup" = yes ] || [ "$xhp" = yes ] || [ "$anp" = yes ] || [ "$arp" = yes ] || { echo "提示：rep重置协议时，请在脚本前至少设置一个协议变量哦，再见！💣"; exit; }
fi
else
[ "$1" = "del" ] || [ "$1" = "panel" ] || [ "$1" = "statusgen" ] || [ "$1" = "list" ] || [ "$xcp" = yes ] || [ "$xup" = yes ] || [ "$tjp" = yes ] || [ "$tjgp" = yes ] || [ "$tjtp" = yes ] || [ "$vgp" = yes ] || [ "$vhup" = yes ] || [ "$vmgp" = yes ] || [ "$vmhup" = yes ] || [ "$vwp" = yes ] || [ "$sop" = yes ] || [ "$vxp" = yes ] || [ "$ssp" = yes ] || [ "$vlp" = yes ] || [ "$vmp" = yes ] || [ "$hyp" = yes ] || [ "$tup" = yes ] || [ "$xhp" = yes ] || [ "$anp" = yes ] || [ "$arp" = yes ] || { echo "提示：未安装science脚本，请在脚本前至少设置一个协议变量哦，再见！💣"; exit; }
fi
fi
[ -z "${vlpt+x}" ] || vlp=yes
[ -z "${vmpt+x}" ] || { vmp=yes; vmag=yes; }
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
export port_tj=${tjpt:-''}
export port_tjg=${tjgpt:-''}
export port_tjt=${tjtpt:-''}
export port_vg=${vgpt:-''}
export port_vhu=${vhupt:-''}
export port_vmg=${vmgpt:-''}
export port_vmhu=${vmhupt:-''}
export port_xu=${xupt:-''}
export port_xc=${xcpt:-''}
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
[ -z "$dnym" ] && [ -s "$HOME/science/dnym.log" ] && dnym=$(head -1 "$HOME/science/dnym.log")
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
echo "一键全协议+Argo：all=y dnym=\"域名\" argo=vmpt agn=\"CF域名\" agk=\"ey开头的token\" bash <(curl -Ls https://raw.githubusercontent.com/Hutton-h/science/main/science.sh)"
echo "（all=y 自动开启协议：VLESS-Reality/XHTTP-Reality/XHTTP-ENC/VLESS-gRPC/VLESS-httpupgrade/Hysteria2(端口跳跃)/Tuic/SS-2022/VMess-WS/VMess-gRPC/VMess-httpupgrade/SOCKS5/Trojan-ws/Trojan-grpc/Trojan-tcp/Xhttp-tls-UDP/Xhttp-tls-TCP）"
echo "申请本地IP域名证书脚本：bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/acme-yg/main/acme.sh)"
echo "订阅面板(需开启sub=y)：http://服务器IP或域名:订阅端口/订阅Token/index.html"
echo "隐藏IP用域名变量：dnym=\"你的域名\" (需先在DNS将域名解析到服务器IP)"
echo "双栈VPS显示IPv4/IPv6节点配置命令：ippz=4或6 science list 【或者】 ippz=4或6 主脚本 list"
echo "---------------------------------------------------------"
echo
}
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "skpl Github项目 ：github.com/Hutton-h"
echo "Science一键无交互小钢炮脚本💣"
echo "当前版本：V26.7.16"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
hostname=$(uname -a | awk '{print $2}')
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
[ -z "$(systemd-detect-virt 2>/dev/null)" ] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
arm64|aarch64) cpu=arm64;;
amd64|x86_64) cpu=amd64;;
*) echo "目前脚本不支持$(uname -m)架构" && exit
esac
if [ "$1" != "del" ] && [ "$1" != "panel" ] && [ "$1" != "statusgen" ]; then
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
v4=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v curl >/dev/null 2>&1 && curl -s4m5 -k https://api.ipify.org 2>/dev/null) || (command -v curl >/dev/null 2>&1 && curl -s4m5 -k https://ip.sb 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- "$v46url" 2>/dev/null) )
v6=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v curl >/dev/null 2>&1 && curl -s6m5 -k https://ifconfig.co 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- "$v46url" 2>/dev/null) )
# IP检测失败时兜底：优先已保存的 server_ip.log，其次本机网卡 IP（hostname -I）
[ -z "$v4" ] && [ -s "$HOME/science/server_ip.log" ] && v4=$(head -1 "$HOME/science/server_ip.log")
[ -z "$v4" ] && v4=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$v6" ] && [ -s "$HOME/science/server_ip.log" ] && grep -q ':' "$HOME/science/server_ip.log" && v6=$(grep ':' "$HOME/science/server_ip.log" | head -1 | tr -d '[]')
[ -z "$v6" ] && v6=$(hostname -I 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i ~ /:/) print $i}' | head -1)
v4dq=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k https://ip.fm | sed -n 's/.*Location: //p' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- https://ip.fm | grep '<span class="has-text-grey-light">Location:' | tail -n1 | sed -E 's/.*>Location: <\/span>([^<]+)<.*/\1/' 2>/dev/null) )
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
s4) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s6) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0"'; sip='"::/0"'; wap=warp ;;
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
port_xh=$(gen_port)
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
port_vx=$(gen_port)
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
if [ -n "$xup" ]; then
xup=xupt
if [ -z "$port_xu" ] && [ ! -e "$HOME/science/port_xu" ]; then
port_xu=$(gen_port)
echo "$port_xu" > "$HOME/science/port_xu"
elif [ -n "$port_xu" ]; then
echo "$port_xu" > "$HOME/science/port_xu"
fi
port_xu=$(cat "$HOME/science/port_xu")
echo "Vless-xhttp-tls-UDP端口：$port_xu"
cat >> "$HOME/science/xr.json" <<EOF
{
  "tag": "xhttp-h3",
  "listen": "::",
  "port": ${port_xu},
  "protocol": "vless",
  "settings": {
    "clients": [
      {
        "id": "${uuid}",
        "flow": ""
      }
    ],
    "decryption": "none"
  },
  "streamSettings": {
    "network": "xhttp",
    "security": "tls",
    "xhttpSettings": {
    "mode": "auto",
    "path": "${uuid}-xu"
    },
    "tlsSettings": {
      "alpn": [
        "h3"
      ],
      "certificates": [
        {
          "certificateFile": "$certificateHTA",
          "keyFile": "$keyHTA"
        }
      ]
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
xup=xuptargo
fi
if [ -n "$xcp" ]; then
xcp=xcpt
if [ -z "$port_xc" ] && [ ! -e "$HOME/science/port_xc" ]; then
port_xc=$(gen_port)
echo "$port_xc" > "$HOME/science/port_xc"
elif [ -n "$port_xc" ]; then
echo "$port_xc" > "$HOME/science/port_xc"
fi
port_xc=$(cat "$HOME/science/port_xc")
echo "Vless-xhttp-tls-TCP/UDP端口：$port_xc"
cat >> "$HOME/science/xr.json" <<EOF
{
  "tag": "xhttp-h23",
  "listen": "::",
  "port": ${port_xc},
  "protocol": "vless",
  "settings": {
    "clients": [
      {
        "id": "${uuid}",
        "flow": ""
      }
    ],
    "decryption": "none"
  },
  "streamSettings": {
    "network": "xhttp",
    "security": "tls",
    "xhttpSettings": {
    "mode": "auto",
    "path": "${uuid}-xc"
    },
    "tlsSettings": {
     "alpn": [
      "h2","http/1.1"
       ],
      "certificates": [
        {
          "certificateFile": "$certificateHTA",
          "keyFile": "$keyHTA"
        }
      ]
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
xcp=xcptargo
fi
if [ -n "$vwp" ]; then
vwp=vwpt
if [ -z "$port_vw" ] && [ ! -e "$HOME/science/port_vw" ]; then
port_vw=$(gen_port)
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
port_vl_re=$(gen_port)
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
if [ -n "$vgp" ]; then
vgp=vgpt
if [ -z "$port_vg" ] && [ ! -e "$HOME/science/port_vg" ]; then
port_vg=$(gen_port)
echo "$port_vg" > "$HOME/science/port_vg"
elif [ -n "$port_vg" ]; then
echo "$port_vg" > "$HOME/science/port_vg"
fi
port_vg=$(cat "$HOME/science/port_vg")
echo "Vless-grpc-reality端口：$port_vg"
cat >> "$HOME/science/xr.json" <<EOF
        {
            "tag":"vless-grpc-reality",
            "listen": "::",
            "port": $port_vg,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}",
                        "flow": ""
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "security": "reality",
                "realitySettings": {
                    "fingerprint": "chrome",
                    "dest": "${ym_vl_re}:443",
                    "serverNames": [
                      "${ym_vl_re}"
                    ],
                    "privateKey": "$private_key_x",
                    "shortIds": ["$short_id_x"]
                },
                "grpcSettings": {
                    "serviceName": "${uuid}-vg"
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
vgp=vgptargo
fi
if [ -n "$vhup" ]; then
vhup=vhupt
if [ -z "$port_vhu" ] && [ ! -e "$HOME/science/port_vhu" ]; then
port_vhu=$(gen_port)
echo "$port_vhu" > "$HOME/science/port_vhu"
elif [ -n "$port_vhu" ]; then
echo "$port_vhu" > "$HOME/science/port_vhu"
fi
port_vhu=$(cat "$HOME/science/port_vhu")
echo "Vless-httpupgrade端口：$port_vhu"
cat >> "$HOME/science/xr.json" <<EOF
        {
            "tag":"vless-httpupgrade",
            "listen": "::",
            "port": $port_vhu,
            "protocol": "vless",
            "settings": {
                "clients": [{"id": "${uuid}", "flow": ""}],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "httpupgrade",
                "security": "tls",
                "httpupgradeSettings": {"path": "/${uuid}-vhu"},
                "tlsSettings": {
                    "certificates": [{"certificateFile": "$certificateHTA", "keyFile": "$keyHTA"}]
                }
            },
            "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"], "metadataOnly": false}
        },
EOF
else
vhup=vhuptargo
fi
if [ -n "$vmgp" ]; then
vmgp=vmgpt
if [ -z "$port_vmg" ] && [ ! -e "$HOME/science/port_vmg" ]; then
port_vmg=$(gen_port)
echo "$port_vmg" > "$HOME/science/port_vmg"
elif [ -n "$port_vmg" ]; then
echo "$port_vmg" > "$HOME/science/port_vmg"
fi
port_vmg=$(cat "$HOME/science/port_vmg")
echo "Vmess-grpc端口：$port_vmg"
cat >> "$HOME/science/xr.json" <<EOF
        {
            "tag":"vmess-grpc",
            "listen": "::",
            "port": $port_vmg,
            "protocol": "vmess",
            "settings": {
                "clients": [{"id": "${uuid}"}]
            },
            "streamSettings": {
                "network": "grpc",
                "security": "tls",
                "grpcSettings": {"serviceName": "${uuid}-vmg"},
                "tlsSettings": {
                    "alpn": ["h2"],
                    "certificates": [{"certificateFile": "$certificateHTA", "keyFile": "$keyHTA"}]
                }
            },
            "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"], "metadataOnly": false}
        },
EOF
else
vmgp=vmgptargo
fi
if [ -n "$vmhup" ]; then
vmhup=vmhupt
if [ -z "$port_vmhu" ] && [ ! -e "$HOME/science/port_vmhu" ]; then
port_vmhu=$(gen_port)
echo "$port_vmhu" > "$HOME/science/port_vmhu"
elif [ -n "$port_vmhu" ]; then
echo "$port_vmhu" > "$HOME/science/port_vmhu"
fi
port_vmhu=$(cat "$HOME/science/port_vmhu")
echo "Vmess-httpupgrade端口：$port_vmhu"
cat >> "$HOME/science/xr.json" <<EOF
        {
            "tag":"vmess-httpupgrade",
            "listen": "::",
            "port": $port_vmhu,
            "protocol": "vmess",
            "settings": {
                "clients": [{"id": "${uuid}"}]
            },
            "streamSettings": {
                "network": "httpupgrade",
                "security": "tls",
                "httpupgradeSettings": {"path": "/${uuid}-vmhu"},
                "tlsSettings": {
                    "certificates": [{"certificateFile": "$certificateHTA", "keyFile": "$keyHTA"}]
                }
            },
            "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"], "metadataOnly": false}
        },
EOF
else
vmhup=vmhuptargo
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
if [ -n "$tjp" ]; then
tjp=tjpt
if [ -z "$port_tj" ] && [ ! -e "$HOME/science/port_tj" ]; then
port_tj=$(gen_port)
echo "$port_tj" > "$HOME/science/port_tj"
elif [ -n "$port_tj" ]; then
echo "$port_tj" > "$HOME/science/port_tj"
fi
port_tj=$(cat "$HOME/science/port_tj")
echo "Trojan-WS端口：$port_tj"
cat >> "$HOME/science/sb.json" <<EOF
    {
        "type": "trojan",
        "tag": "trojan-ws-sb",
        "listen": "::",
        "listen_port": ${port_tj},
        "users": [
            {
                "password": "${uuid}"
            }
        ],
        "tls": {
            "enabled": true,
            "certificate_path": "$certificateHTA",
            "key_path": "$keyHTA"
        },
        "transport": {
            "type": "ws",
            "path": "/${uuid}-tj"
        }
    },
EOF
else
tjp=tjptargo
fi
if [ -n "$tjgp" ]; then
tjgp=tjgpt
if [ -z "$port_tjg" ] && [ ! -e "$HOME/science/port_tjg" ]; then
port_tjg=$(gen_port)
echo "$port_tjg" > "$HOME/science/port_tjg"
elif [ -n "$port_tjg" ]; then
echo "$port_tjg" > "$HOME/science/port_tjg"
fi
port_tjg=$(cat "$HOME/science/port_tjg")
echo "Trojan-gRPC端口：$port_tjg"
cat >> "$HOME/science/sb.json" <<EOF
    {
        "type": "trojan",
        "tag": "trojan-grpc-sb",
        "listen": "::",
        "listen_port": ${port_tjg},
        "users": [
            {
                "password": "${uuid}"
            }
        ],
        "tls": {
            "enabled": true,
            "certificate_path": "$certificateHTA",
            "key_path": "$keyHTA"
        },
        "transport": {
            "type": "grpc",
            "service_name": "${uuid}-tjg"
        }
    },
EOF
else
tjgp=tjgptargo
fi
if [ -n "$tjtp" ]; then
tjtp=tjtpt
if [ -z "$port_tjt" ] && [ ! -e "$HOME/science/port_tjt" ]; then
port_tjt=$(gen_port)
echo "$port_tjt" > "$HOME/science/port_tjt"
elif [ -n "$port_tjt" ]; then
echo "$port_tjt" > "$HOME/science/port_tjt"
fi
port_tjt=$(cat "$HOME/science/port_tjt")
echo "Trojan-TCP端口：$port_tjt"
cat >> "$HOME/science/sb.json" <<EOF
    {
        "type": "trojan",
        "tag": "trojan-tcp-sb",
        "listen": "::",
        "listen_port": ${port_tjt},
        "users": [
            {
                "password": "${uuid}"
            }
        ],
        "tls": {
            "enabled": true,
            "certificate_path": "$certificateHTA",
            "key_path": "$keyHTA"
        }
    },
EOF
else
tjtp=tjtptargo
fi
if [ -n "$tup" ]; then
tup=tupt
if [ -z "$port_tu" ] && [ ! -e "$HOME/science/port_tu" ]; then
port_tu=$(gen_port)
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
                "certificate_path": "$certificateHTA",
                "key_path": "$keyHTA"
            }
        },
EOF
else
tup=tuptargo
fi
if [ -n "$anp" ]; then
anp=anpt
if [ -z "$port_an" ] && [ ! -e "$HOME/science/port_an" ]; then
port_an=$(gen_port)
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
                "certificate_path": "$certificateHTA",
                "key_path": "$keyHTA"
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
port_ar=$(gen_port)
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
port_ss=$(gen_port)
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
xrsbhy2(){
if [ -n "$hyp" ]; then
hyp=hypt
if [ -z "$port_hy2" ] && [ ! -e "$HOME/science/port_hy2" ]; then
port_hy2=$(gen_port)
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
            "certificate_path": "$certificateHTA",
            "key_path": "$keyHTA"
        }
    },
EOF
else
hyp=hyptargo
fi
}
xrsbvm(){
if [ -n "$vmp" ]; then
vmp=vmpt
if [ -z "$port_vm_ws" ] && [ ! -e "$HOME/science/port_vm_ws" ]; then
port_vm_ws=$(gen_port)
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
port_so=$(gen_port)
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
       "streamSettings":{
       "sockopt":{
         "dialerProxy":"x-warp-out"
       }
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
if [ -x "$HOME/science/xray" ]; then
  if ! "$HOME/science/xray" run -test -c "$HOME/science/xr.json" >/dev/null 2>&1; then
    echo "⚠️ xr.json 配置校验失败，安装中止（rep 已备份可回退）"
    exit 1
  fi
  echo "√ xr.json 配置校验通过"
fi
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
if [ -x "$HOME/science/sing-box" ]; then
  if ! "$HOME/science/sing-box" check -c "$HOME/science/sb.json" >/dev/null 2>&1; then
    echo "⚠️ sb.json 配置校验失败，安装中止（rep 已备份可回退）"
    exit 1
  fi
  echo "√ sb.json 配置校验通过"
fi
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
if [ "$tjp" != yes ] && [ "$tjgp" != yes ] && [ "$tjtp" != yes ] && [ "$tup" != yes ] && [ "$anp" != yes ] && [ "$arp" != yes ] && [ "$ssp" != yes ] && [ "$hyp" != yes ] && [ "$vmp" != yes ]; then
installxray
xrsbhy2
xrsbvm
xrsbso
warpsx
xrsbout
tjp="tjptargo"; tjgp="tjgptargo"; tjtp="tjtptargo"; tup="tuptargo"; anp="anptargo"; arp="arptargo"; ssp="ssptargo"
elif [ "$xhp" != yes ] && [ "$vlp" != yes ] && [ "$vgp" != yes ] && [ "$vhup" != yes ] && [ "$vmgp" != yes ] && [ "$vmhup" != yes ] && [ "$vxp" != yes ] && [ "$vwp" != yes ] && [ "$xup" != yes ] && [ "$xcp" != yes ]; then
installsb
xrsbhy2
xrsbvm
xrsbso
warpsx
xrsbout
xhp="xhptargo"; vlp="vlptargo"; vgp="vgptargo"; vhup="vhuptargo"; vmgp="vmgptargo"; vmhup="vmhuptargo"; vxp="vxptargo"; vwp="vwptargo"; xup="xuptargo"; xcp="xcptargo"
else
installsb
installxray
xrsbhy2
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
# 未传 agn/agk 时，沿用上次保存的 Argo 固定隧道配置（rep/更新后不丢失）
if [ -z "${ARGO_AUTH}" ] && [ -s "$HOME/science/sbargotoken.log" ]; then
  ARGO_AUTH=$(cat "$HOME/science/sbargotoken.log")
  [ -s "$HOME/science/sbargoym.log" ] && ARGO_DOMAIN=$(cat "$HOME/science/sbargoym.log")
fi
if [ "$argo" = "vmpt" ]; then argoport=$(cat "$HOME/science/port_vm_ws" 2>/dev/null); echo "Vmess" > "$HOME/science/vlvm"; elif [ "$argo" = "vwpt" ]; then argoport=$(cat "$HOME/science/port_vw" 2>/dev/null); echo "Vless" > "$HOME/science/vlvm"; fi; echo "$argoport" > "$HOME/science/argoport.log"
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
argoname='固定'
# 支持多隧道：逗号分隔多个 token
argo_tokens=$(echo "${ARGO_AUTH}" | tr ',' '\n')
argo_count=0
echo "${ARGO_AUTH}" > "$HOME/science/sbargotoken.log"
for atk in $argo_tokens; do
  [ -z "$atk" ] && continue
  argo_count=$((argo_count + 1))
  svc_name="argo"
  [ $argo_count -gt 1 ] && svc_name="argo${argo_count}"
  if pidof systemd >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
    cat > "/etc/systemd/system/${svc_name}.service" << EOF
[Unit]
Description=${svc_name} service
After=network.target
[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/root/science/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${atk}"
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable "${svc_name}" >/dev/null 2>&1
    systemctl start "${svc_name}" >/dev/null 2>&1
  elif command -v rc-service >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
    cat > "/etc/init.d/${svc_name}" << EOF
#!/sbin/openrc-run
description="${svc_name} service"
command="/root/science/cloudflared tunnel"
command_args="--no-autoupdate --edge-ip-version auto --protocol http2 run --token ${atk}"
pidfile="/run/${svc_name}.pid"
command_background="yes"
depend() {
need net
}
EOF
    chmod +x "/etc/init.d/${svc_name}" >/dev/null 2>&1
    rc-update add "${svc_name}" default >/dev/null 2>&1
    rc-service "${svc_name}" start >/dev/null 2>&1
  else
    nohup "$HOME/science/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${atk}" >/dev/null 2>&1 &
  fi
done
echo "${ARGO_DOMAIN}" > "$HOME/science/sbargoym.log"
echo "启动 ${argo_count} 个Argo固定隧道"
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
# ====== 始终创建快捷命令 science（与进程状态无关） ======
[ -f ~/.bashrc ] || touch ~/.bashrc
sed -i '/science/d' ~/.bashrc
SCRIPT_PATH="$HOME/bin/science"
mkdir -p "$HOME/bin"
# 始终刷新已安装脚本（下载失败时保留旧版，不覆盖）
sctmp="$HOME/science/science.sh.tmp"
(command -v curl >/dev/null 2>&1 && curl -Ls "$scienceurl" -o "$sctmp") || (command -v wget >/dev/null 2>&1 && wget -qO "$sctmp" "$scienceurl")
if [ -s "$sctmp" ]; then mv "$sctmp" "$HOME/science/science.sh"; fi
rm -f "$sctmp"
chmod +x "$HOME/science/science.sh"
cp "$HOME/science/science.sh" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' ~/.bashrc
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
grep -qxF 'source ~/.bashrc' ~/.bash_profile 2>/dev/null || echo 'source ~/.bashrc' >> ~/.bash_profile
. ~/.bashrc 2>/dev/null
echo "快捷命令 science 已就绪 (重新登录SSH后生效，或执行 source ~/.bashrc)"

# ====== 进程检测：仅当进程运行时才配置自启动恢复 ======
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'science/(s|x)' || pgrep -f 'science/(s|x)' >/dev/null 2>&1 ; then
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
echo "if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'science/(s|x)' && ! pgrep -f 'science/(s|x)' >/dev/null 2>&1; then echo '检测到系统可能中断过，或者变量格式错误？建议在SSH对话框输入 reboot 重启下服务器。现在自动执行Science脚本的节点恢复操作，请稍等……'; sleep 6; export alns=\"${alns}\" cfip=\"${cfip}\" hyjpt=\"${hyjpt}\" cdnym=\"${cdnym}\" name=\"${name}\" ippz=\"${ippz}\" argo=\"${argo}\" uuid=\"${uuid}\" $wap=\"${warp}\" $xhp=\"${port_xh}\" $xup=\"${port_xu}\" $vxp=\"${port_vx}\" $ssp=\"${port_ss}\" $sop=\"${port_so}\" $anp=\"${port_an}\" $arp=\"${port_ar}\" $vlp=\"${port_vl_re}\" $vwp=\"${port_vw}\" $vmp=\"${port_vm_ws}\" $hyp=\"${port_hy2}\" $tup=\"${port_tu}\" $xcp=\"${port_xc}\" $tjp=\"${port_tj}\" $tjgp=\"${port_tjg}\" $tjtp=\"${port_tjt}\" $vgp=\"${port_vg}\" $vhup=\"${port_vhu}\" $vmgp=\"${port_vmg}\" $vmhup=\"${port_vmhu}\" reym=\"${ym_vl_re}\" agn=\"${ARGO_DOMAIN}\" agk=\"${ARGO_AUTH}\"; bash "$HOME/bin/science"; fi" >> ~/.bashrc
fi
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
  echo '@reboot sleep 10 && /bin/sh -c "for atk in $(cat $HOME/science/sbargotoken.log 2>/dev/null | tr ',' ' '); do [ -n \"\$atk\" ] && nohup $HOME/science/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token \"\$atk\" >/dev/null 2>&1 &; done"' >> /tmp/crontab.tmp
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
panelurl="https://api.github.com/repos/Hutton-h/science/contents/panel.html"
echo "下载订阅面板html文件……"
(command -v curl >/dev/null 2>&1 && curl -Ls -H "Accept: application/vnd.github.raw" "$panelurl" -o "$HOME/science/panel.html") || (command -v wget >/dev/null 2>&1 && wget -qO "$HOME/science/panel.html" --header="Accept: application/vnd.github.raw" "$panelurl")
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
cdnip1="www.shopify.com"
cdnip2="www.wto.org"
echo "$cdnip1" > "$HOME/science/cdnip1"
echo "$cdnip2" > "$HOME/science/cdnip2"
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
# IP检测失败时兜底：优先已保存的 server_ip.log，其次本机网卡 IP（hostname -I）
[ -z "$serip" ] && [ -s "$HOME/science/server_ip.log" ] && serip=$(head -1 "$HOME/science/server_ip.log")
[ -z "$serip" ] && serip=$(hostname -I 2>/dev/null | awk '{print $1}')
serip=$(echo "$serip" | tr -d '[]')
if echo "$serip" | grep -q ':'; then
server_ip="[$serip]"
echo "$serip" > "$HOME/science/server_ip.log"
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
server_ip="$v6"
echo "$v6" > "$HOME/science/server_ip.log"
fi
else
ipbest
fi
# 如果设置了域名变量dnym，用域名替代IP作为节点地址
if [ -n "$dnym" ]; then
server_ip="$dnym"
echo "$server_ip" > "$HOME/science/server_ip.log"
echo "$dnym" > "$HOME/science/dnym.log"
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
if echo "$server_ip" | grep -q ':' && ! echo "$server_ip" | grep -q '^\['; then
server_ip="[$server_ip]"
fi
raw_ip=$(echo "$server_ip" | tr -d '[]')
sxname=$(cat "$HOME/science/name" 2>/dev/null)
xvvmcdnym=$(cat "$HOME/science/cdnym" 2>/dev/null)
cdnip1=$(cat "$HOME/science/cdnip1" 2>/dev/null)
cdnip2=$(cat "$HOME/science/cdnip2" 2>/dev/null)
cdnips="$cdnip1,$cdnip2"
if grep -q 'science/private.key' "$HOME/science/sb.json" >/dev/null 2>&1 || grep -q 'science/private.key' "$HOME/science/xr.json" >/dev/null 2>&1; then
sni=www.bing.com
add=$server_ip
jhins=1
msins=true
else
sni=$(cat /root/ygkkkca/ca.log 2>/dev/null)
add=$(cat /root/ygkkkca/ca.log 2>/dev/null)
jhins=0
msins=false
fi
echo "*********************************************************"
echo "*********************************************************"
echo "Science脚本输出节点配置如下："
echo
case "$server_ip" in
104.28*|\[2a09*) echo "检测到有WARP的IP作为客户端地址 (104.28或者2a09开头的IP)，请把客户端地址上的WARP的IP手动更换为VPS本地IPV4或者IPV6地址" && sleep 3 ;;
esac
echo
ym_vl_re=$(cat "$HOME/science/ym_vl_re" 2>/dev/null)
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
sbxhpt(){
cat <<EOF
    {
      "type": "vless",
      "tag": "${sxname}vl-xhttp-reality-enc-$hostname",
      "server": "$server_ip",
      "server_port": $port_xh,
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
      },
      "transport": {
        "type": "http",
        "host": "$ym_vl_re",
        "path": "/$uuid-xh"
      }
    },
EOF
}
sbxhpt1(){
echo "\"${sxname}vl-xhttp-reality-enc-$hostname\","
}
clxhpt(){
cat <<EOF
- name: ${sxname}vl-xhttp-reality-enc-$hostname
  type: vless
  server: $server_ip
  port: $port_xh
  uuid: $uuid
  encryption: none
  network: xhttp
  udp: true
  flow: xtls-rprx-vision
  tls: true
  servername: $ym_vl_re
  reality-opts:
    public-key: $public_key_x
    short-id: $short_id_x
  client-fingerprint: chrome
  xhttp-opts:
    path: /$uuid-xh
    mode: auto
EOF
}
clxhpt1(){
echo "- ${sxname}vl-xhttp-reality-enc-$hostname"
}
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
echo "可自行更换优选IP域名，如是回源端口需手动修改443或者80系端口"
vl_vx_cdn_link="vless://$uuid@$cdnip1:$port_vx?encryption=$enkey&flow=xtls-rprx-vision&type=xhttp&host=$xvvmcdnym&path=$uuid-vx&mode=auto#${sxname}vl-xhttp-enc-cdn-$hostname"
echo "$vl_vx_cdn_link" >> "$HOME/science/jhsub.txt"
echo "$vl_vx_cdn_link"
echo
fi
fi
sbvxpt(){
cat <<EOF
    {
      "type": "vless",
      "tag": "${sxname}vl-xhttp-enc-$hostname",
      "server": "$server_ip",
      "server_port": $port_vx,
      "uuid": "$uuid",
      "flow": "xtls-rprx-vision",
      "transport": {
        "type": "http",
        "host": "$server_ip",
        "path": "/$uuid-vx"
      }
    },
EOF
}
sbvxpt1(){
echo "\"${sxname}vl-xhttp-enc-$hostname\","
}
clvxpt(){
cat <<EOF
- name: ${sxname}vl-xhttp-enc-$hostname
  type: vless
  server: $server_ip
  port: $port_vx
  uuid: $uuid
  encryption: none
  network: xhttp
  udp: true
  flow: xtls-rprx-vision
  xhttp-opts:
    path: /$uuid-vx
    mode: auto
EOF
}
clvxpt1(){
echo "- ${sxname}vl-xhttp-enc-$hostname"
}
if grep vless-ws "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-ws-enc 】支持ENC加密，节点信息如下："
port_vw=$(cat "$HOME/science/port_vw")
vl_vw_link="vless://$uuid@$server_ip:$port_vw?encryption=$enkey&flow=xtls-rprx-vision&type=ws&path=$uuid-vw#${sxname}vl-ws-enc-$hostname"
echo "$vl_vw_link" >> "$HOME/science/jhsub.txt"
echo "$vl_vw_link"
echo
if [ -f "$HOME/science/cdnym" ]; then
echo "💣【 Vless-ws-enc-cdn 】支持ENC加密，节点信息如下："
echo "已自动使用全部优选IP生成多条CDN节点"
for cdnip in $(echo "$cdnips" | tr ',' ' '); do
[ -z "$cdnip" ] && continue
vl_vw_cdn_link="vless://$uuid@$cdnip:$port_vw?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$xvvmcdnym&path=$uuid-vw#${sxname}vl-ws-enc-cdn-$cdnip"
echo "$vl_vw_cdn_link" >> "$HOME/science/jhsub.txt"
echo "$vl_vw_cdn_link"
done
echo
fi
fi
if grep xhttp-h23 "$HOME/science/xr.json" >/dev/null 2>&1; then
port_xc=$(cat "$HOME/science/port_xc")
xhttpclmh(){
clxcpt(){
cat <<EOF
- name: ${sxname}Xhttp-TCP-$hostname
  type: vless
  server: $add
  port: $port_xc
  uuid: $uuid
  udp: true
  tls: true
  network: xhttp
  servername: $sni
  client-fingerprint: chrome
  skip-cert-verify: $msins
  xhttp-opts:
    path: "$uuid-xc"
    mode: auto
EOF
}
clxcpt1(){
echo "- ${sxname}Xhttp-TCP-$hostname"
}
}
if ! grep -A 26 'xhttp-h23' "$HOME/science/xr.json" | grep -q 'ygkkkca' >/dev/null 2>&1; then
sha=$(cat "$HOME/science/SHA256.txt")
echo "💣【 Vless-xhttp-tls-TCP 】节点信息如下："
vl_xc2_link="vless://$uuid@$add:$port_xc?encryption=none&security=tls&sni=$sni&insecure=0&allowInsecure=0&hpkp=$sha&pcs=$sha&type=xhttp&path=$uuid-xc&mode=auto#${sxname}Vless-xhttp-tls-TCP-$hostname"
echo "$vl_xc2_link" >> "$HOME/science/jhsub.txt"
echo "$vl_xc2_link"
xhttpclmh
else
if [ "$sni" != "$(printf '%s' "$server_ip" | tr -d '[]')" ]; then
case "$port_xc" in
443|2053|2083|2087|2096|8443)
echo "💣【 Vless-xhttp-tls-CDN-TCP 】节点信息如下："
echo "可自行更换优选IP域名"
vl_xc2_link="vless://$uuid@$cdnip1:$port_xc?encryption=none&security=tls&sni=$sni&insecure=0&allowInsecure=0&type=xhttp&path=$uuid-xc&mode=auto#${sxname}Vless-xhttp-tls-CDN-TCP-$hostname"
echo "$vl_xc2_link" >> "$HOME/science/jhsub.txt"
echo "$vl_xc2_link"
echo
echo "💣【 Vless-xhttp-tls-CDN-UDP 】节点信息如下："
echo "可自行更换优选IP域名"
vl_xc3_link="vless://$uuid@$cdnip2:$port_xc?encryption=none&security=tls&sni=$sni&alpn=h3&insecure=0&allowInsecure=0&type=xhttp&path=$uuid-xc&mode=auto#${sxname}Vless-xhttp-tls-CDN-UDP-$hostname"
echo "$vl_xc3_link" >> "$HOME/science/jhsub.txt"
echo "$vl_xc3_link"
echo
clxcpt(){
cat <<EOF
- name: ${sxname}Xhttp-CDN-TCP-$hostname
  type: vless
  server: $cdnip1
  port: $port_xc
  uuid: $uuid
  udp: true
  tls: true
  network: xhttp
  servername: $sni
  client-fingerprint: chrome
  skip-cert-verify: $msins
  xhttp-opts:
    path: "$uuid-xc"
    mode: auto

- name: ${sxname}Xhttp-CDN-UDP-$hostname
  type: vless
  server: $cdnip2
  port: $port_xc
  uuid: $uuid
  udp: true
  tls: true
  network: xhttp
  alpn:
    - h3
  servername: $sni
  client-fingerprint: chrome
  skip-cert-verify: $msins
  xhttp-opts:
    path: "$uuid-xc"
    mode: auto
EOF
}
clxcpt1(){
echo "- ${sxname}Xhttp-CDN-TCP-$hostname"
echo "- ${sxname}Xhttp-CDN-UDP-$hostname"
}
;;
*)
echo "💣【 Vless-xhttp-tls-TCP 】节点信息如下："
vl_xc1_link="vless://$uuid@$add:$port_xc?encryption=none&security=tls&sni=$sni&insecure=0&allowInsecure=0&type=xhttp&path=$uuid-xc&mode=auto#${sxname}Vless-xhttp-tls-TCP-$hostname"
echo "$vl_xc1_link" >> "$HOME/science/jhsub.txt"
echo "$vl_xc1_link"
xhttpclmh
;;
esac
else
echo "💣【 Vless-xhttp-tls-TCP 】节点信息如下："
vl_xc1_link="vless://$uuid@$add:$port_xc?encryption=none&security=tls&sni=$sni&insecure=0&allowInsecure=0&type=xhttp&path=$uuid-xc&mode=auto#${sxname}Vless-xhttp-tls-TCP-$hostname"
echo "$vl_xc1_link" >> "$HOME/science/jhsub.txt"
echo "$vl_xc1_link"
xhttpclmh
fi
fi
echo
fi
if grep xhttp-h3 "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-xhttp-tls-UDP 】节点信息如下："
port_xu=$(cat "$HOME/science/port_xu")
if ! grep -A 26 'xhttp-h3' "$HOME/science/xr.json" | grep -q 'ygkkkca' >/dev/null 2>&1; then
sha=$(cat "$HOME/science/SHA256.txt")
fi
vl_xu_link="vless://$uuid@$add:$port_xu?encryption=none&security=tls&sni=$sni&alpn=h3&insecure=0&allowInsecure=0&hpkp=$sha&pcs=$sha&type=xhttp&path=$uuid-xu&mode=auto#${sxname}Vless-xhttp-tls-UDP-$hostname"
echo "$vl_xu_link" >> "$HOME/science/jhsub.txt"
echo "$vl_xu_link"
echo
cludpxcpt(){
cat <<EOF
- name: ${sxname}Xhttp-UDP-$hostname
  type: vless
  server: $add
  port: $port_xu
  uuid: $uuid
  udp: true
  tls: true
  network: xhttp
  alpn:
    - h3
  servername: $sni
  client-fingerprint: chrome
  skip-cert-verify: $msins
  xhttp-opts:
    path: "$uuid-xu"
    mode: auto
EOF
}
cludpxcpt1(){
echo "- ${sxname}Xhttp-UDP-$hostname"
}
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
if grep vless-grpc-reality "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-grpc-reality 】节点信息如下："
port_vg=$(cat "$HOME/science/port_vg")
vg_link="vless://$uuid@$server_ip:$port_vg?encryption=none&security=reality&sni=$ym_vl_re&fp=chrome&pbk=$public_key_x&sid=$short_id_x&type=grpc&serviceName=$uuid-vg#${sxname}vl-grpc-reality-$hostname"
echo "$vg_link" >> "$HOME/science/jhsub.txt"
echo "$vg_link"
echo
sbvgpt(){
cat <<EOF
    {
      "type": "vless",
      "tag": "${sxname}vl-grpc-reality-$hostname",
      "server": "$server_ip",
      "server_port": $port_vg,
      "uuid": "$uuid",
      "flow": "",
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
      },
      "transport": {
        "type": "grpc",
        "service_name": "$uuid-vg"
      }
    },
EOF
}
sbvgpt1(){
echo "\"${sxname}vl-grpc-reality-$hostname\","
}
clvgpt(){
cat <<EOF
- name: ${sxname}vl-grpc-reality-$hostname
  type: vless
  server: $server_ip
  port: $port_vg
  uuid: $uuid
  network: grpc
  udp: true
  tls: true
  servername: $ym_vl_re
  reality-opts:
    public-key: $public_key_x
    short-id: $short_id_x
  client-fingerprint: chrome
  grpc-opts:
    grpc-service-name: $uuid-vg
EOF
}
clvgpt1(){
echo "- ${sxname}vl-grpc-reality-$hostname"
}
fi
if grep vless-httpupgrade "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-httpupgrade 】节点信息如下："
port_vhu=$(cat "$HOME/science/port_vhu")
vhu_link="vless://$uuid@$add:$port_vhu?encryption=none&security=tls&sni=$sni&insecure=$jhins&allowInsecure=$jhins&type=httpupgrade&host=$sni&path=/$uuid-vhu#${sxname}vl-httpupgrade-$hostname"
echo "$vhu_link" >> "$HOME/science/jhsub.txt"
echo "$vhu_link"
echo
sbvhup(){
cat <<EOF
    {
      "type": "vless",
      "tag": "${sxname}vl-httpupgrade-$hostname",
      "server": "$add",
      "server_port": $port_vhu,
      "uuid": "$uuid",
      "tls": {
        "enabled": true,
        "insecure": $msins,
        "server_name": "$sni"
      },
      "transport": {
        "type": "httpupgrade",
        "path": "/$uuid-vhu",
        "host": "$sni"
      }
    },
EOF
}
sbvhup1(){
echo "\"${sxname}vl-httpupgrade-$hostname\","
}
clvhup(){
cat <<EOF
- name: ${sxname}vl-httpupgrade-$hostname
  type: vless
  server: $add
  port: $port_vhu
  uuid: $uuid
  network: httpupgrade
  udp: true
  tls: true
  servername: $sni
  skip-cert-verify: $msins
  httpupgrade-opts:
    path: /$uuid-vhu
    headers:
      Host: $sni
EOF
}
clvhup1(){
echo "- ${sxname}vl-httpupgrade-$hostname"
}
fi
if grep vmess-grpc "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vmess-grpc 】节点信息如下："
port_vmg=$(cat "$HOME/science/port_vmg")
vmg_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-grpc-$hostname\", \"add\": \"$add\", \"port\": \"$port_vmg\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"grpc\", \"type\": \"none\", \"host\": \"$sni\", \"path\": \"$uuid-vmg\", \"tls\": \"tls\", \"sni\": \"$sni\"}" | base64 -w0)"
echo "$vmg_link" >> "$HOME/science/jhsub.txt"
echo "$vmg_link"
echo
sbvmgp(){
cat <<EOF
    {
      "type": "vmess",
      "tag": "${sxname}vmess-grpc-$hostname",
      "server": "$add",
      "server_port": $port_vmg,
      "uuid": "$uuid",
      "security": "auto",
      "tls": {
        "enabled": true,
        "insecure": $msins,
        "server_name": "$sni"
      },
      "transport": {
        "type": "grpc",
        "service_name": "$uuid-vmg"
      }
    },
EOF
}
sbvmgp1(){
echo "\"${sxname}vmess-grpc-$hostname\","
}
clvmgp(){
cat <<EOF
- name: ${sxname}vmess-grpc-$hostname
  type: vmess
  server: $add
  port: $port_vmg
  uuid: $uuid
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  servername: $sni
  skip-cert-verify: $msins
  network: grpc
  grpc-opts:
    grpc-service-name: $uuid-vmg
EOF
}
clvmgp1(){
echo "- ${sxname}vmess-grpc-$hostname"
}
fi
if grep vmess-httpupgrade "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vmess-httpupgrade 】节点信息如下："
port_vmhu=$(cat "$HOME/science/port_vmhu")
vmhu_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-httpupgrade-$hostname\", \"add\": \"$add\", \"port\": \"$port_vmhu\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"httpupgrade\", \"type\": \"none\", \"host\": \"$sni\", \"path\": \"/$uuid-vmhu\", \"tls\": \"tls\", \"sni\": \"$sni\"}" | base64 -w0)"
echo "$vmhu_link" >> "$HOME/science/jhsub.txt"
echo "$vmhu_link"
echo
sbvmhup(){
cat <<EOF
    {
      "type": "vmess",
      "tag": "${sxname}vmess-httpupgrade-$hostname",
      "server": "$add",
      "server_port": $port_vmhu,
      "uuid": "$uuid",
      "security": "auto",
      "tls": {
        "enabled": true,
        "insecure": $msins,
        "server_name": "$sni"
      },
      "transport": {
        "type": "httpupgrade",
        "path": "/$uuid-vmhu",
        "host": "$sni"
      }
    },
EOF
}
sbvmhup1(){
echo "\"${sxname}vmess-httpupgrade-$hostname\","
}
clvmhup(){
cat <<EOF
- name: ${sxname}vmess-httpupgrade-$hostname
  type: vmess
  server: $add
  port: $port_vmhu
  uuid: $uuid
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  servername: $sni
  skip-cert-verify: $msins
  network: httpupgrade
  httpupgrade-opts:
    path: /$uuid-vmhu
    headers:
      Host: $sni
EOF
}
clvmhup1(){
echo "- ${sxname}vmess-httpupgrade-$hostname"
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
            "security": "