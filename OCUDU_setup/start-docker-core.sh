#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/version.env"

ocudu_dir=${OCUDU_DIR:-$HOME/ocudu}
subscriber_file="$script_dir/subscriber_db.csv"
compose_override="$script_dir/docker-compose.core.yml"

[[ -d "$ocudu_dir/.git" ]] || {
  echo "Install OCUDU first with $script_dir/install-ocudu.sh" >&2
  exit 1
}
[[ $(git -C "$ocudu_dir" rev-parse HEAD) == "$OCUDU_COMMIT" ]] || {
  echo "OCUDU checkout is not at the validated commit." >&2
  exit 1
}
[[ -f "$subscriber_file" ]] || {
  echo "Create private $subscriber_file from subscriber_db.csv.example." >&2
  exit 1
}
subscriber_mode=$(stat -c '%a' "$subscriber_file")
if ((8#$subscriber_mode & 077)); then
  echo "$subscriber_file must not be readable by group or other users." >&2
  echo "Run: chmod 600 $subscriber_file" >&2
  exit 1
fi

build_context=$(mktemp -d "$ocudu_dir/.airan-open5gs.XXXXXX")
trap 'rm -rf "$build_context"' EXIT
cp -a "$ocudu_dir/docker/open5gs/." "$build_context/"
rm -f "$build_context/subscriber_db.csv"
install -m 0644 "$script_dir/setup_tun.py" "$build_context/setup_tun.py"

AIRAN_OPEN5GS_CONTEXT="$build_context" \
AIRAN_SUBSCRIBER_DB="$subscriber_file" \
OPEN_5GS_ENV_FILE="$script_dir/open5gs.env" \
  docker compose \
    -f "$ocudu_dir/docker/docker-compose.yml" \
    -f "$compose_override" \
    up -d --build 5gc
