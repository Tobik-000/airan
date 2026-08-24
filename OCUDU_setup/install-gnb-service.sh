#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
config=${1:-$repo_dir/srsRAN_config/gNB/cots_ue.yml}
gnb_bin=$(command -v gnb)

[[ -f "$config" ]] || {
  echo "gNB configuration not found: $config" >&2
  exit 1
}
config=$(realpath -e "$config")

cat > /etc/systemd/system/ocudu-gnb.service <<EOF
[Unit]
Description=OCUDU gNB
After=network.target open5gs-amfd.service open5gs-upfd.service
Wants=open5gs-amfd.service open5gs-upfd.service

[Service]
Type=simple
Environment=HOME=/root
Environment=XDG_CONFIG_HOME=/root/.config
WorkingDirectory=$repo_dir
ExecStart=$gnb_bin -c "$config"
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ocudu-gnb.service
echo "Installed ocudu-gnb.service with configuration $config"
