#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

source /etc/os-release
if [[ ${ID:-} != ubuntu ]]; then
  echo "This package installer supports Ubuntu only." >&2
  exit 1
fi

apt-get update
apt-get install -y curl gnupg software-properties-common ca-certificates \
  iproute2 iptables kmod procps

install -d -m 0755 /usr/share/keyrings
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc |
  gpg --dearmor --yes -o /usr/share/keyrings/mongodb-server-8.0.gpg

cat > /etc/apt/sources.list.d/mongodb-org-8.0.list <<EOF
deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu ${VERSION_CODENAME}/mongodb-org/8.0 multiverse
EOF

add-apt-repository ppa:open5gs/latest -y
apt-get update
open5gs_version=$(apt-cache madison open5gs | awk '$3 ~ /^2\.8\.0([~+.-]|$)/ { print $3; exit }')
if [[ -z "$open5gs_version" ]]; then
  echo "Open5GS 2.8.0 is unavailable from the configured repositories." >&2
  exit 1
fi

apt-get install -y mongodb-org "open5gs=$open5gs_version"
systemctl enable --now mongod

mapfile -t open5gs_packages < <(
  dpkg-query -W -f='${Package}\n' 'open5gs*' 2>/dev/null | sort -u
)
((${#open5gs_packages[@]} == 0)) || apt-mark hold "${open5gs_packages[@]}"

# This deployment is 5GC-only. Disable package-default EPC and SEPP services.
systemctl disable --now open5gs-mmed open5gs-sgwcd open5gs-sgwud \
  open5gs-hssd open5gs-pcrfd open5gs-seppd 2>/dev/null || true
