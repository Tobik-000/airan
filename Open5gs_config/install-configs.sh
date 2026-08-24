#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
configs=(nrf scp amf smf upf ausf udm udr pcf nssf bsf)
services=(
  open5gs-nrfd open5gs-scpd open5gs-amfd open5gs-smfd open5gs-upfd
  open5gs-ausfd open5gs-udmd open5gs-udrd open5gs-pcfd open5gs-nssfd
  open5gs-bsfd
)

for name in "${configs[@]}"; do
  [[ -f "$config_dir/$name.yaml" ]] || {
    echo "Missing $config_dir/$name.yaml" >&2
    exit 1
  }
done

backup_dir="/var/backups/airan-open5gs/$(date +%Y%m%d-%H%M%S)"
install -d -m 0700 "$backup_dir"
for name in "${configs[@]}"; do
  [[ ! -f "/etc/open5gs/$name.yaml" ]] ||
    cp -a "/etc/open5gs/$name.yaml" "$backup_dir/"
  install -o root -g root -m 0644 "$config_dir/$name.yaml" "/etc/open5gs/$name.yaml"
done

install -o root -g root -m 0755 "$config_dir/setup-network.sh" \
  /usr/local/libexec/airan-open5gs-network
install -o root -g root -m 0644 "$config_dir/airan-open5gs-network.service" \
  /etc/systemd/system/airan-open5gs-network.service
install -o root -g root -m 0644 /dev/stdin /etc/sysctl.d/99-airan-open5gs.conf <<'EOF'
net.ipv4.ip_forward=1
EOF
if [[ ! -f /etc/default/airan-open5gs-network ]]; then
  install -o root -g root -m 0644 /dev/stdin /etc/default/airan-open5gs-network <<'EOF'
AIRAN_UPLINK_IFACE=
AIRAN_ALLOW_PRIVATE_NETWORKS=0
EOF
fi

systemctl daemon-reload
systemctl enable --now airan-open5gs-network.service
systemctl restart "${services[@]}"

echo "Open5GS configuration installed. Previous files: $backup_dir"
echo "Provision subscriber credentials privately before attaching a UE."
