#!/bin/sh
export LANG=en_US.UTF-8
export uuid=${uuid}
export vlpt=${vlpt}
export vmpt=${vmpt}
export vwpt=${vwpt}
export hypt=${hypt}
export tupt=${tupt}
export xhpt=${xhpt}
export vxpt=${vxpt}
export anpt=${anpt}
export arpt=${arpt}
export sspt=${sspt}
export sopt=${sopt}
export reym=${reym}
export cdnym=${cdnym}
export argo=${argo}
export agn=${agn}
export agk=${agk}
export ippz=${ippz}
export warp=${warp}
export name=${name}
v46url="https://icanhazip.com"
showmode(){
echo "Science脚本项目地址：https://github.com/Hutton-h/science"
echo "---------------------------------------------------------"
echo
}
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "skpl Github项目 ：github.com/Hutton-h"
echo "Science一键无交互小钢炮脚本💣"
echo "当前版本：V25.11.20"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
hostname=$(uname -a | awk '{print $2}')
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
[ -z "$(systemd-detect-virt 2>/dev/null)" ] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
*) echo "目前脚本不支持$(uname -m)架构" && exit
esac
mkdir -p "$HOME/science"
v4v6(){
v4=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- "$v46url" 2>/dev/null) )
v6=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- "$v46url" 2>/dev/null) )
v4dq=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k https://ip.fm | sed -E 's/.*Location: ([^,]+(, [^,]+)*),.*/\1/' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- https://ip.fm | grep '<span class="has-text-grey-light">Location:' | tail -n1 | sed -E 's/.*>Location: <\/span>([^<]+)<.*/\1/' 2>/dev/null) )
v6dq=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k https://ip.fm | sed -E 's/.*Location: ([^,]+(, [^,]+)*),.*/\1/' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- https://ip.fm | grep '<span class="has-text-grey-light">Location:' | tail -n1 | sed -E 's/.*>Location: <\/span>([^<]+)<.*/\1/' 2>/dev/null) )
}
warpsx(){
warpurl=$( (command -v curl >/dev/null 2>&1 && curl -sm5 -k https://skpl-lift-warp.renky.eu.org 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget --tries=2 -qO- https://skpl-lift-warp.renky.eu.org 2>/dev/null) )
if echo "$warpurl" | grep -q skpl-lift; then
pvk=$(echo "$warpurl" | awk -F'：' '/Private_key/{print $2}' | xargs)
wpv6=$(echo "$warpurl" | awk -F'：' '/IPV6/{print $2}' | xargs)
res=$(echo "$warpurl" | awk -F'：' '/reserved/{print $2}' | xargs)
else
wpv6='2606:4700:110:8d8d:1845:c39f:2dd5:a03a'
pvk='52cuYFgCJXp0LAq7+nWJIbCXXgU9eGggOc+Hlfz5u6A'
res='[215, 69, 233]'
fi
if [ -n "$name" ]; then
sxname=$name-
echo "$sxname" > "$HOME/science/name"
echo
echo "所有节点名称前缀：$name"
fi
v4v6
if echo "$v6" | grep -q '^2a09' || echo "$v4" | grep -q '^104.28'; then
s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"';
echo "请注意：你已安装了warp"
else
if [ -z "$wap" ]; then
s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"';
else
case "$warp" in
""|sx|xs) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"' ;;
s ) s1outtag=warp-out; s2outtag=warp-out; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"' ;;
s4) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"0.0.0.0/0"' ;;
s6) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0"' ;;
x ) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"' ;;
x4) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"' ;;
x6) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0", "0.0.0.0/0"' ;;
s4x4|x4s4) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"0.0.0.0/0"' ;;
s4x6|x6s4) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"0.0.0.0/0"' ;;
s6x4|x4s6) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0"' ;;
s6x6|x6s6) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0"' ;;
sx4|x4s) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"' ;;
sx6|x6s) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0", "0.0.0.0/0"' ;;
xs4|s4x) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"0.0.0.0/0"' ;;
xs6|s6x) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0"' ;;
* ) s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"' ;;
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
case "$warp" in *s4*) sbyx='ipv4_only' ;; *) sbyx='prefer_ipv6' ;; esac
case "$warp" in *x4*) xryx='ForceIPv4' ;; *x*) xryx='ForceIPv6v4' ;; *) xryx='ForceIPv4v6' ;; esac
elif [ "$v4_ok" != true ] && [ "$v6_ok" = true ]; then
case "$warp" in *s6*) sbyx='ipv6_only' ;; *) sbyx='prefer_ipv4' ;; esac
case "$warp" in *x6*) xryx='ForceIPv6' ;; *x*) xryx='ForceIPv4v6' ;; *) xryx='ForceIPv6v4' ;; esac
fi
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
url="https://github.com/Hutton-h/science/releases/download/science/xray-$cpu"; out="$HOME/science/xray"; (command -v curl >/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/science/xray"
sbcore=$("$HOME/science/xray" version 2>/dev/null | awk '/^Xray/{print $2}')
echo "已安装Xray正式版内核：$sbcore"
fi
cat > "$HOME/science/xr.json" <<EOF
{
  "log": {
  "loglevel": "none"
  },
  "dns": {
    "servers": [
      "${xsdns}"
      ]
   },
  "inbounds": [
EOF
insuuid
if [ -n "$xhpt" ] || [ -n "$vlpt" ]; then
if [ -z "$reym" ]; then
reym=apple.com
fi
echo "$reym" > "$HOME/science/reym"
echo "Reality域名：$reym"
if [ ! -e "$HOME/science/xrk/private_key" ]; then
key_pair=$("$HOME/science/xray" x25519)
private_key=$(echo "$key_pair" | grep "PrivateKey" | awk '{print $2}')
public_key=$(echo "$key_pair" | grep "Password" | awk '{print $2}')
short_id=$(date +%s%N | sha256sum | cut -c 1-8)
echo "$private_key" > "$HOME/science/xrk/private_key"
echo "$public_key" > "$HOME/science/xrk/public_key"
echo "$short_id" > "$HOME/science/xrk/short_id"
fi
private_key_x=$(cat "$HOME/science/xrk/private_key")
public_key_x=$(cat "$HOME/science/xrk/public_key")
short_id_x=$(cat "$HOME/science/xrk/short_id")
fi
if [ -n "$xhpt" ] || [ -n "$vxpt" ] || [ -n "$vwpt" ]; then
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

if [ -n "$xhpt" ]; then
if [ -z "$xhpt" ] && [ ! -e "$HOME/science/xhpt" ]; then
xhpt=$(shuf -i 10000-65535 -n 1)
echo "$xhpt" > "$HOME/science/xhpt"
elif [ -n "$xhpt" ]; then
echo "$xhpt" > "$HOME/science/xhpt"
fi
xhpt=$(cat "$HOME/science/xhpt")
echo "Vless-xhttp-reality-v端口：$xhpt"
cat >> "$HOME/science/xr.json" <<EOF
    {
      "tag":"xhttp-reality",
      "listen": "::",
      "port": ${xhpt},
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
          "target": "${reym}:443",
          "serverNames": [
            "${reym}"
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
fi
if [ -n "$vxpt" ]; then
if [ -z "$vxpt" ] && [ ! -e "$HOME/science/vxpt" ]; then
vxpt=$(shuf -i 10000-65535 -n 1)
echo "$vxpt" > "$HOME/science/vxpt"
elif [ -n "$vxpt" ]; then
echo "$vxpt" > "$HOME/science/vxpt"
fi
vxpt=$(cat "$HOME/science/vxpt")
echo "Vless-xhttp-enc端口：$vxpt"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/science/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
cat >> "$HOME/science/xr.json" <<EOF
    {
      "tag":"vless-xhttp",
      "listen": "::",
      "port": ${vxpt},
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
fi
if [ -n "$vwpt" ]; then
if [ -z "$vwpt" ] && [ ! -e "$HOME/science/vwpt" ]; then
vwpt=$(shuf -i 10000-65535 -n 1)
echo "$vwpt" > "$HOME/science/vwpt"
elif [ -n "$vwpt" ]; then
echo "$vwpt" > "$HOME/science/vwpt"
fi
vwpt=$(cat "$HOME/science/vwpt")
echo "Vless-ws-enc端口：$vwpt"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/science/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
cat >> "$HOME/science/xr.json" <<EOF
    {
      "tag":"vless-ws",
      "listen": "::",
      "port": ${vwpt},
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
fi
if [ -n "$vlpt" ]; then
if [ -z "$vlpt" ] && [ ! -e "$HOME/science/vlpt" ]; then
vlpt=$(shuf -i 10000-65535 -n 1)
echo "$vlpt" > "$HOME/science/vlpt"
elif [ -n "$vlpt" ]; then
echo "$vlpt" > "$HOME/science/vlpt"
fi
vlpt=$(cat "$HOME/science/vlpt")
echo "Vless-tcp-reality-v端口：$vlpt"
cat >> "$HOME/science/xr.json" <<EOF
        {
            "tag":"reality-vision",
            "listen": "::",
            "port": $vlpt,
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
                    "dest": "${reym}:443",
                    "serverNames": [
                      "${reym}"
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
fi
}

installsb(){
echo
echo "=========启用Sing-box内核========="
if [ ! -e "$HOME/science/sing-box" ]; then
url="https://github.com/Hutton-h/science/releases/download/science/sing-box-$cpu"; out="$HOME/science/sing-box"; (command -v curl>/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/science/sing-box"
sbcore=$("$HOME/science/sing-box" version 2>/dev/null | awk '/version/{print $NF}')
echo "已安装Sing-box正式版内核：$sbcore"
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
command -v openssl >/dev/null 2>&1 && openssl ecparam -genkey -name prime256v1 -out "$HOME/science/private.key" >/dev/null 2>&1
command -v openssl >/dev/null 2>&1 && openssl req -new -x509 -days 36500 -key "$HOME/science/private.key" -out "$HOME/science/cert.pem" -subj "/CN=www.bing.com" >/dev/null 2>&1
if [ ! -f "$HOME/science/private.key" ]; then
url="https://github.com/Hutton-h/science/releases/download/science/private.key"; out="$HOME/science/private.key"; (command -v curl>/dev/null 2>&1 && curl -Ls -o "$out" --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -q -O "$out" --tries=2 "$url")
url="https://github.com/Hutton-h/science/releases/download/science/cert.pem"; out="$HOME/science/cert.pem"; (command -v curl>/dev/null 2>&1 && curl -Ls -o "$out" --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -q -O "$out" --tries=2 "$url")
fi
if [ -n "$hypt" ]; then
if [ -z "$hypt" ] && [ ! -e "$HOME/science/hypt" ]; then
hypt=$(shuf -i 10000-65535 -n 1)
echo "$hypt" > "$HOME/science/hypt"
elif [ -n "$hypt" ]; then
echo "$hypt" > "$HOME/science/hypt"
fi
hypt=$(cat "$HOME/science/hypt")
echo "Hysteria2端口：$hypt"
cat >> "$HOME/science/sb.json" <<EOF
    {
        "type": "hysteria2",
        "tag": "hy2-sb",
        "listen": "::",
        "listen_port": ${hypt},
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
            "certificate_path": "$HOME/science/cert.pem",
            "key_path": "$HOME/science/private.key"
        }
    },
EOF
fi
if [ -n "$tupt" ]; then
if [ -z "$tupt" ] && [ ! -e "$HOME/science/tupt" ]; then
tupt=$(shuf -i 10000-65535 -n 1)
echo "$tupt" > "$HOME/science/tupt"
elif [ -n "$tupt" ]; then
echo "$tupt" > "$HOME/science/tupt"
fi
tupt=$(cat "$HOME/science/tupt")
echo "Tuic端口：$tupt"
cat >> "$HOME/science/sb.json" <<EOF
        {
            "type":"tuic",
            "tag": "tuic5-sb",
            "listen": "::",
            "listen_port": ${tupt},
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
                "certificate_path": "$HOME/science/cert.pem",
                "key_path": "$HOME/science/private.key"
            }
        },
EOF
fi
if [ -n "$anpt" ]; then
if [ -z "$anpt" ] && [ ! -e "$HOME/science/anpt" ]; then
anpt=$(shuf -i 10000-65535 -n 1)
echo "$anpt" > "$HOME/science/anpt"
elif [ -n "$anpt" ]; then
echo "$anpt" > "$HOME/science/anpt"
fi
anpt=$(cat "$HOME/science/anpt")
echo "Anytls端口：$anpt"
cat >> "$HOME/science/sb.json" <<EOF
        {
            "type":"anytls",
            "tag":"anytls-sb",
            "listen":"::",
            "listen_port":${anpt},
            "users":[
                {
                  "password":"${uuid}"
                }
            ],
            "padding_scheme":[],
            "tls":{
                "enabled": true,
                "certificate_path": "$HOME/science/cert.pem",
                "key_path": "$HOME/science/private.key"
            }
        },
EOF
fi
if [ -n "$arpt" ]; then
if [ -z "$reym" ]; then
reym=apple.com
fi
echo "$reym" > "$HOME/science/reym"
echo "Reality域名：$reym"
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
if [ -z "$arpt" ] && [ ! -e "$HOME/science/arpt" ]; then
arpt=$(shuf -i 10000-65535 -n 1)
echo "$arpt" > "$HOME/science/arpt"
elif [ -n "$arpt" ]; then
echo "$arpt" > "$HOME/science/arpt"
fi
arpt=$(cat "$HOME/science/arpt")
echo "Any-Reality端口：$arpt"
cat >> "$HOME/science/sb.json" <<EOF
        {
            "type":"anytls",
            "tag":"anyreality-sb",
            "listen":"::",
            "listen_port":${arpt},
            "users":[
                {
                  "password":"${uuid}"
                }
            ],
            "padding_scheme":[],
            "tls": {
            "enabled": true,
            "server_name": "${reym}",
             "reality": {
              "enabled": true,
              "handshake": {
              "server": "${reym}",
              "server_port": 443
             },
             "private_key": "$private_key_s",
             "short_id": ["$short_id_s"]
            }
          }
        },
EOF
fi
if [ -n "$sspt" ]; then
if [ ! -e "$HOME/science/sskey" ]; then
sskey=$("$HOME/science/sing-box" generate rand 16 --base64)
echo "$sskey" > "$HOME/science/sskey"
fi
if [ -z "$sspt" ] && [ ! -e "$HOME/science/sspt" ]; then
sspt=$(shuf -i 10000-65535 -n 1)
echo "$sspt" > "$HOME/science/sspt"
elif [ -n "$sspt" ]; then
echo "$sspt" > "$HOME/science/sspt"
fi
sskey=$(cat "$HOME/science/sskey")
sspt=$(cat "$HOME/science/sspt")
echo "Shadowsocks-2022端口：$sspt"
cat >> "$HOME/science/sb.json" <<EOF
        {
            "type": "shadowsocks",
            "tag":"ss-2022",
            "listen": "::",
            "listen_port": $sspt,
            "method": "2022-blake3-aes-128-gcm",
            "password": "$sskey"
    },  
EOF
fi
}

xrsbvm(){
if [ -n "$vmpt" ]; then
if [ -z "$vmpt" ] && [ ! -e "$HOME/science/vmpt" ]; then
vmpt=$(shuf -i 10000-65535 -n 1)
echo "$vmpt" > "$HOME/science/vmpt"
elif [ -n "$vmpt" ]; then
echo "$vmpt" > "$HOME/science/vmpt"
fi
vmpt=$(cat "$HOME/science/vmpt")
echo "Vmess-ws端口：$vmpt"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/science/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
if [ -e "$HOME/science/xr.json" ]; then
cat >> "$HOME/science/xr.json" <<EOF
        {
            "tag": "vmess-xr",
            "listen": "::",
            "port": ${vmpt},
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
        "listen_port": ${vmpt},
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
fi
}

xrsbso(){
if [ -n "$sopt" ]; then
if [ -z "$sopt" ] && [ ! -e "$HOME/science/sopt" ]; then
sopt=$(shuf -i 10000-65535 -n 1)
echo "$sopt" > "$HOME/science/sopt"
elif [ -n "$sopt" ]; then
echo "$sopt" > "$HOME/science/sopt"
fi
sopt=$(cat "$HOME/science/sopt")
echo "Socks5端口：$sopt"
if [ -e "$HOME/science/xr.json" ]; then
cat >> "$HOME/science/xr.json" <<EOF
        {
         "tag": "socks5-xr",
         "port": ${sopt},
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
      "listen_port": ${sopt},
      "users": [
      {
      "username": "${uuid}",
      "password": "${uuid}"
      }
     ]
    },
EOF
fi
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
nohup "$HOME/science/xray" run -c "$HOME/science/xr.json" >/dev/null 2>&1 &
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
          "reserved": ${res}
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
  },
    "dns": {
    "servers": [
      {
        "type": "https",
        "server": "${xsdns}"
      }
    ],
    "strategy": "${sbdnsyx}"
  }
}
EOF
nohup "$HOME/science/sing-box" run -c "$HOME/science/sb.json" >/dev/null 2>&1 &
fi
}
ins(){
if [ -z "$hypt" ] && [ -z "$tupt" ] && [ -z "$anpt" ] && [ -z "$arpt" ] && [ -z "$sspt" ]; then
installxray
xrsbvm
xrsbso
warpsx
xrsbout
elif [ -z "$xhpt" ] && [ -z "$vlpt" ] && [ -z "$vxpt" ] && [ -z "$vwpt" ]; then
installsb
xrsbvm
xrsbso
warpsx
xrsbout
else
installsb
installxray
xrsbvm
xrsbso
warpsx
xrsbout
fi
if [ -n "$argo" ]; then
echo
echo "=========启用Cloudflared-argo内核========="
if [ ! -e "$HOME/science/cloudflared" ]; then
argocore=$({ command -v curl >/dev/null 2>&1 && curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared || wget -qO- https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared; } | grep -Eo '"[0-9.]+"' | sed -n 1p | tr -d '",')
echo "下载Cloudflared-argo最新正式版内核：$argocore"
url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu"; out="$HOME/science/cloudflared"; (command -v curl>/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/science/cloudflared"
fi
if [ "$argo" = "vmpt" ]; then argoport=$(cat "$HOME/science/vmpt" 2>/dev/null); echo "Vmess" > "$HOME/science/vlvm"; elif [ "$argo" = "vwpt" ]; then argoport=$(cat "$HOME/science/vwpt" 2>/dev/null); echo "Vless" > "$HOME/science/vlvm"; fi; echo "$argoport" > "$HOME/science/argoport.log"
if [ -n "${agn}" ] && [ -n "${agk}" ]; then
argoname='固定'
nohup "$HOME/science/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${agk}" >/dev/null 2>&1 &
echo "${agn}" > "$HOME/science/sbargoym.log"
echo "${agk}" > "$HOME/science/sbargotoken.log"
else
argoname='临时'
nohup "$HOME/science/cloudflared" tunnel --url http://localhost:$(cat $HOME/science/argoport.log) --edge-ip-version auto --no-autoupdate --protocol http2 > "$HOME/science/argo.log" 2>&1 &
fi
echo "申请Argo$argoname隧道中……请稍等"
sleep 8
if [ -n "${agn}" ] && [ -n "${agk}" ]; then
argodomain=$(cat "$HOME/science/sbargoym.log" 2>/dev/null)
else
argodomain=$(grep -a trycloudflare.com "$HOME/science/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
fi
if [ -n "${argodomain}" ]; then
echo "Argo$argoname隧道申请成功"
else
echo "Argo$argoname隧道申请失败，请稍后再试"
fi
sleep 5
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'science/(s|x)' || pgrep -f 'science/(s|x)' >/dev/null 2>&1 ; then
echo "Science脚本进程启动成功，安装完毕" && sleep 2
else
echo "Science脚本进程未启动，安装失败" && exit
fi
fi
}
sciencestatus(){
echo "=========当前三大内核运行状态========="
procs=$(find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null)
if echo "$procs" | grep -Eq 'science/s' || pgrep -f 'science/s' >/dev/null 2>&1; then
echo "Sing-box：运行中"
else
echo "Sing-box：未启用"
fi
if echo "$procs" | grep -Eq 'science/x' || pgrep -f 'science/x' >/dev/null 2>&1; then
echo "Xray：运行中"
else
echo "Xray：未启用"
fi
if echo "$procs" | grep -Eq 'science/c' || pgrep -f 'science/c' >/dev/null 2>&1; then
echo "Argo：运行中"
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
}
ipchange
rm -rf "$HOME/science/jh.txt"
uuid=$(cat "$HOME/science/uuid")
server_ip=$(cat "$HOME/science/server_ip.log")
sxname=$(cat "$HOME/science/name" 2>/dev/null)
xvvmcdnym=$(cat "$HOME/science/cdnym" 2>/dev/null)
echo "*********************************************************"
echo "*********************************************************"
echo "Science脚本输出节点配置如下："
echo
case "$server_ip" in
104.28*|\[2a09*) echo "检测到有WARP的IP作为客户端地址 (104.28或者2a09开头的IP)，请把客户端地址上的WARP的IP手动更换为VPS本地IPV4或者IPV6地址" && sleep 3 ;;
esac
echo
reym=$(cat "$HOME/science/reym" 2>/dev/null)
cfip() { echo $((RANDOM % 11 + 1)); }
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
xhpt=$(cat "$HOME/science/xhpt")
vl_xh_link="vless://$uuid@$server_ip:$xhpt?encryption=$enkey&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key_x&sid=$short_id_x&type=xhttp&path=$uuid-xh&mode=auto#${sxname}vl-xhttp-reality-$hostname"
echo "$vl_xh_link" >> "$HOME/science/jh.txt"
echo "$vl_xh_link"
echo
fi
if grep vless-xhttp "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-xhttp-enc 】支持ENC加密，节点信息如下："
vxpt=$(cat "$HOME/science/vxpt")
vl_vx_link="vless://$uuid@$server_ip:$vxpt?encryption=$enkey&flow=xtls-rprx-vision&type=xhttp&path=$uuid-vx&mode=auto#${sxname}vl-xhttp-$hostname"
echo "$vl_vx_link" >> "$HOME/science/jh.txt"
echo "$vl_vx_link"
echo
if [ -f "$HOME/science/cdnym" ]; then
echo "💣【 Vless-xhttp-ecn-cdn 】支持ENC加密，节点信息如下："
echo "注：默认地址 sk数字.skpllift.edu.pl 可自行更换优选IP域名，如是回源端口需手动修改443或者80系端口"
vl_vx_cdn_link="vless://$uuid@sk$(cfip).skpllift.edu.pl:$vxpt?encryption=$enkey&flow=xtls-rprx-vision&type=xhttp&host=$xvvmcdnym&path=$uuid-vx&mode=auto#${sxname}vl-xhttp-$hostname"
echo "$vl_vx_cdn_link" >> "$HOME/science/jh.txt"
echo "$vl_vx_cdn_link"
echo
fi
fi
if grep vless-ws "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-ws-enc 】支持ENC加密，节点信息如下："
vwpt=$(cat "$HOME/science/vwpt")
vl_vw_link="vless://$uuid@$server_ip:$vwpt?encryption=$enkey&flow=xtls-rprx-vision&type=ws&path=$uuid-vw#${sxname}vl-ws-enc-$hostname"
echo "$vl_vw_link" >> "$HOME/science/jh.txt"
echo "$vl_vw_link"
echo
if [ -f "$HOME/science/cdnym" ]; then
echo "💣【 Vless-ws-enc-cdn 】支持ENC加密，节点信息如下："
echo "注：默认地址 sk数字.skpllift.edu.pl 可自行更换优选IP域名，如是回源端口需手动修改443或者80系端口"
vl_vw_cdn_link="vless://$uuid@sk$(cfip).skpllift.edu.pl:$vwpt?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$xvvmcdnym&path=$uuid-vw#${sxname}vl-ws-enc-cdn-$hostname"
echo "$vl_vw_cdn_link" >> "$HOME/science/jh.txt"
echo "$vl_vw_cdn_link"
echo
fi
fi
if grep reality-vision "$HOME/science/xr.json" >/dev/null 2>&1; then
echo "💣【 Vless-tcp-reality-vision 】节点信息如下："
vlpt=$(cat "$HOME/science/vlpt")
vl_link="vless://$uuid@$server_ip:$vlpt?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key_x&sid=$short_id_x&type=tcp&headerType=none#${sxname}vl-reality-vision-$hostname"
echo "$vl_link" >> "$HOME/science/jh.txt"
echo "$vl_link"
echo
fi
if grep ss-2022 "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Shadowsocks-2022 】节点信息如下："
sspt=$(cat "$HOME/science/sspt")
ss_link="ss://$(echo -n "2022-blake3-aes-128-gcm:$sskey@$server_ip:$sspt" | base64 -w0)#${sxname}Shadowsocks-2022-$hostname"
echo "$ss_link" >> "$HOME/science/jh.txt"
echo "$ss_link"
echo
fi
if grep vmess-xr "$HOME/science/xr.json" >/dev/null 2>&1 || grep vmess-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Vmess-ws 】节点信息如下："
vmpt=$(cat "$HOME/science/vmpt")
vm_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vm-ws-$hostname\", \"add\": \"$server_ip\", \"port\": \"$vmpt\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"www.bing.com\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vm_link" >> "$HOME/science/jh.txt"
echo "$vm_link"
echo
if [ -f "$HOME/science/cdnym" ]; then
echo "💣【 Vmess-ws-cdn 】节点信息如下："
echo "注：默认地址 sk数字.skpllift.edu.pl 可自行更换优选IP域名，如是回源端口需手动修改443或者80系端口"
vm_cdn_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vm-ws-cdn-$hostname\", \"add\": \"sk$(cfip).skpllift.edu.pl\", \"port\": \"$vmpt\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$xvvmcdnym\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vm_cdn_link" >> "$HOME/science/jh.txt"
echo "$vm_cdn_link"
echo
fi
fi
if grep anytls-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 AnyTLS 】节点信息如下："
anpt=$(cat "$HOME/science/anpt")
an_link="anytls://$uuid@$server_ip:$anpt?insecure=1&allowInsecure=1#${sxname}anytls-$hostname"
echo "$an_link" >> "$HOME/science/jh.txt"
echo "$an_link"
echo
fi
if grep anyreality-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Any-Reality 】节点信息如下："
arpt=$(cat "$HOME/science/arpt")
ar_link="anytls://$uuid@$server_ip:$arpt?security=reality&sni=$reym&fp=chrome&pbk=$public_key_s&sid=$short_id_s&type=tcp&headerType=none#${sxname}any-reality-$hostname"
echo "$ar_link" >> "$HOME/science/jh.txt"
echo "$ar_link"
echo
fi
if grep hy2-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Hysteria2 】节点信息如下："
hypt=$(cat "$HOME/science/hypt")
hy2_link="hysteria2://$uuid@$server_ip:$hypt?security=tls&alpn=h3&insecure=1&sni=www.bing.com#${sxname}hy2-$hostname"
echo "$hy2_link" >> "$HOME/science/jh.txt"
echo "$hy2_link"
echo
fi
if grep tuic5-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Tuic 】节点信息如下："
tupt=$(cat "$HOME/science/tupt")
tuic5_link="tuic://$uuid:$uuid@$server_ip:$tupt?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=www.bing.com&allow_insecure=1&allowInsecure=1#${sxname}tuic-$hostname"
echo "$tuic5_link" >> "$HOME/science/jh.txt"
echo "$tuic5_link"
echo
fi
if grep socks5-xr "$HOME/science/xr.json" >/dev/null 2>&1 || grep socks5-sb "$HOME/science/sb.json" >/dev/null 2>&1; then
echo "💣【 Socks5 】客户端信息如下："
sopt=$(cat "$HOME/science/sopt")
echo "请配合其他应用内置代理使用，勿做节点直接使用"
echo "客户端地址：$server_ip"
echo "客户端端口：$sopt"
echo "客户端用户名：$uuid"
echo "客户端密码：$uuid"
echo
fi
argodomain=$(cat "$HOME/science/sbargoym.log" 2>/dev/null)
[ -z "$argodomain" ] && argodomain=$(grep -a trycloudflare.com "$HOME/science/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
if [ -n "$argodomain" ]; then
vlvm=$(cat $HOME/science/vlvm 2>/dev/null)
if [ "$vlvm" = "Vmess" ]; then
vmatls_link1="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-443\", \"add\": \"sk1.skpllift.edu.pl\", \"port\": \"443\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link1" >> "$HOME/science/jh.txt"
vmatls_link2="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-8443\", \"add\": \"sk2.skpllift.edu.pl\", \"port\": \"8443\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link2" >> "$HOME/science/jh.txt"
vmatls_link3="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2053\", \"add\": \"sk3.skpllift.edu.pl\", \"port\": \"2053\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link3" >> "$HOME/science/jh.txt"
vmatls_link4="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2083\", \"add\": \"sk4.skpllift.edu.pl\", \"port\": \"2083\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link4" >> "$HOME/science/jh.txt"
vmatls_link5="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2087\", \"add\": \"sk5.skpllift.edu.pl\", \"port\": \"2087\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link5" >> "$HOME/science/jh.txt"
vmatls_link6="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-tls-argo-$hostname-2096\", \"add\": \"[2606:4700::0]\", \"port\": \"2096\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"chrome\"}" | base64 -w0)"
echo "$vmatls_link6" >> "$HOME/science/jh.txt"
vma_link7="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-80\", \"add\": \"sk6.skpllift.edu.pl\", \"port\": \"80\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link7" >> "$HOME/science/jh.txt"
vma_link8="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-8080\", \"add\": \"sk7.skpllift.edu.pl\", \"port\": \"8080\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link8" >> "$HOME/science/jh.txt"
vma_link9="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-8880\", \"add\": \"sk8.skpllift.edu.pl\", \"port\": \"8880\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link9" >> "$HOME/science/jh.txt"
vma_link10="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2052\", \"add\": \"sk9.skpllift.edu.pl\", \"port\": \"2052\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link10" >> "$HOME/science/jh.txt"
vma_link11="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2082\", \"add\": \"sk10.skpllift.edu.pl\", \"port\": \"2082\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link11" >> "$HOME/science/jh.txt"
vma_link12="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2086\", \"add\": \"sk11.skpllift.edu.pl\", \"port\": \"2086\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link12" >> "$HOME/science/jh.txt"
vma_link13="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${sxname}vmess-ws-argo-$hostname-2095\", \"add\": \"[2400:cb00:2049::0]\", \"port\": \"2095\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$uuid-vm\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link13" >> "$HOME/science/jh.txt"
elif [ "$vlvm" = "Vless" ]; then
vwatls_link1="vless://$uuid@sk$(cfip).skpllift.edu.pl:443?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$argodomain&path=$uuid-vw&security=tls&sni=$argodomain&fp=chrome&insecure=0&allowInsecure=0#${sxname}vless-ws-tls-argo-enc-vision-$hostname"
echo "$vwatls_link1" >> "$HOME/science/jh.txt"
vwa_link2="vless://$uuid@sk$(cfip).skpllift.edu.pl:80?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$argodomain&path=$uuid-vw&security=none#${sxname}vless-ws-argo-enc-vision-$hostname"
echo "$vwa_link2" >> "$HOME/science/jh.txt"
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
echo "---------------------------------------------------------"
echo "$argoshow"
echo
echo "---------------------------------------------------------"
echo "聚合节点信息，请进入 $HOME/science/jh.txt 文件目录查看或者运行 cat $HOME/science/jh.txt 查看"
echo "========================================================="
echo "相关快捷方式如下：(首次安装成功后需重连SSH，science快捷方式才可生效)"
showmode
}
if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'science/(s|x)' && ! pgrep -f 'science/(s|x)' >/dev/null 2>&1; then
for P in /proc/[0-9]*; do if [ -L "$P/exe" ]; then TARGET=$(readlink -f "$P/exe" 2>/dev/null); if echo "$TARGET" | grep -qE '/science/c|/science/s|/science/x'; then PID=$(basename "$P"); kill "$PID" 2>/dev/null && echo "Killed $PID ($TARGET)" || echo "Could not kill $PID ($TARGET)"; fi; fi; done
kill -15 $(pgrep -f 'science/s' 2>/dev/null) $(pgrep -f 'science/c' 2>/dev/null) $(pgrep -f 'science/x' 2>/dev/null) >/dev/null 2>&1
v4orv6(){
if [ -z "$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1" > /etc/resolv.conf
fi
if [ -n "$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
sendip="2606:4700:d0::a29f:c001"
xendip="[2606:4700:d0::a29f:c001]"
xsdns="[2001:4860:4860::8888]"
sbdnsyx="ipv6_only"
else
sendip="162.159.192.1"
xendip="162.159.192.1"
xsdns="8.8.8.8"
sbdnsyx="ipv4_only"
fi
}
v4orv6
echo "VPS系统：$op"
echo "CPU架构：$cpu"
echo "Science脚本未安装，开始安装…………" && sleep 2
ins
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
