#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

source_image=${1:-}
target=/usr/share/uhd/images/usrp_b210_fpga.bin

[[ -f "$source_image" ]] || {
  echo "Usage: sudo ./install-uhd-image.sh <board-specific usrp_b210_fpga.bin>" >&2
  exit 2
}

if [[ -f "$target" ]]; then
  cp -a "$target" "$target.backup-$(date +%Y%m%d-%H%M%S)"
fi
install -o root -g root -m 0644 "$source_image" "$target"
echo "Installed $source_image as $target"
echo "Run uhd_usrp_probe --args=type=b200 to verify the attached board."
