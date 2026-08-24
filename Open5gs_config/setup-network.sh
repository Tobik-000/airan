#!/usr/bin/env bash
set -euo pipefail

modprobe tun
ip link show ogstun >/dev/null 2>&1 || ip tuntap add name ogstun mode tun
ip address replace 10.45.0.1/16 dev ogstun
ip link set ogstun up
sysctl -w net.ipv4.ip_forward=1 >/dev/null

uplink=${AIRAN_UPLINK_IFACE:-}
if [[ -z "$uplink" ]]; then
  while read -r destination via gateway dev interface rest; do
    if [[ $destination == default && $dev == dev ]]; then
      uplink=$interface
      break
    fi
  done < <(ip -4 route show default)
fi
[[ -n "$uplink" ]] || {
  echo "No IPv4 uplink found. Set AIRAN_UPLINK_IFACE." >&2
  exit 1
}

for destination in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
  while iptables -C FORWARD -i ogstun -d "$destination" -j REJECT 2>/dev/null; do
    iptables -D FORWARD -i ogstun -d "$destination" -j REJECT
  done
  if [[ ${AIRAN_ALLOW_PRIVATE_NETWORKS:-0} != 1 ]]; then
    iptables -C FORWARD -i ogstun -d "$destination" -j REJECT 2>/dev/null ||
      iptables -I FORWARD 1 -i ogstun -d "$destination" -j REJECT
  fi
done

while iptables -C INPUT -i ogstun -d 10.45.0.1 -j ACCEPT 2>/dev/null; do
  iptables -D INPUT -i ogstun -d 10.45.0.1 -j ACCEPT
done
iptables -C INPUT -i ogstun -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null ||
  iptables -I INPUT 1 -i ogstun -p icmp --icmp-type echo-request -j ACCEPT
for protocol in tcp udp; do
  iptables -C INPUT -i ogstun -p "$protocol" --dport 5201 -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 1 -i ogstun -p "$protocol" --dport 5201 -j ACCEPT
done
iptables -C INPUT -i ogstun -j REJECT 2>/dev/null ||
  iptables -A INPUT -i ogstun -j REJECT

iptables -t nat -C POSTROUTING -s 10.45.0.0/16 -o "$uplink" -j MASQUERADE 2>/dev/null ||
  iptables -t nat -A POSTROUTING -s 10.45.0.0/16 -o "$uplink" -j MASQUERADE
iptables -C FORWARD -i ogstun -o "$uplink" -j ACCEPT 2>/dev/null ||
  iptables -A FORWARD -i ogstun -o "$uplink" -j ACCEPT
iptables -C FORWARD -i "$uplink" -o ogstun -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null ||
  iptables -A FORWARD -i "$uplink" -o ogstun -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
