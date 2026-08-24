#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

usage() {
  cat <<'EOF'
Usage: ./setup.bash <target>

Targets:
  ocudu        Install the pinned OCUDU gNB build.
  srsue        Install the pinned srsRAN 4G build used for srsUE.
  native-core  Install MongoDB/Open5GS and deploy the native core profile.
  gnb-host     Install OCUDU and the native Open5GS core.
  ue-host      Install srsUE for the UE machine.

Subscriber credentials are never installed by this script. Provision them
privately after deployment as described in Open5gs_config/README.md.
EOF
}

target=${1:-}
case "$target" in
  ocudu)
    "$repo_dir/OCUDU_setup/install-ocudu.sh"
    ;;
  srsue)
    "$repo_dir/srsRAN_config/install-srsue.sh"
    ;;
  native-core)
    sudo "$repo_dir/Open5gs_config/install-packages-ubuntu.sh"
    sudo "$repo_dir/Open5gs_config/install-configs.sh"
    ;;
  gnb-host)
    "$repo_dir/OCUDU_setup/install-ocudu.sh"
    sudo "$repo_dir/Open5gs_config/install-packages-ubuntu.sh"
    sudo "$repo_dir/Open5gs_config/install-configs.sh"
    ;;
  ue-host)
    "$repo_dir/srsRAN_config/install-srsue.sh"
    ;;
  *)
    usage
    [[ -z "$target" ]] || exit 2
    ;;
esac
