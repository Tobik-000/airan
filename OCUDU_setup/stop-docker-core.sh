#!/usr/bin/env bash
set -euo pipefail

ocudu_dir=${OCUDU_DIR:-$HOME/ocudu}
docker compose -f "$ocudu_dir/docker/docker-compose.yml" stop 5gc
