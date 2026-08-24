#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/version.env"

ocudu_dir=${OCUDU_DIR:-$HOME/ocudu}
build_jobs=${BUILD_JOBS:-$(nproc)}

if [[ ! -d "$ocudu_dir/.git" ]]; then
  git clone "$OCUDU_REPOSITORY" "$ocudu_dir"
fi

if [[ -n $(git -C "$ocudu_dir" status --short --untracked-files=no) ]]; then
  echo "Refusing to change a modified OCUDU checkout: $ocudu_dir" >&2
  exit 1
fi

git -C "$ocudu_dir" fetch origin --prune --tags
git -C "$ocudu_dir" checkout --detach "$OCUDU_COMMIT"

sudo "$ocudu_dir/docker/scripts/install_dependencies.sh" build
sudo apt-get update
sudo apt-get install -y libzmq3-dev libuhd-dev uhd-host \
  libboost-program-options-dev
sudo uhd_images_downloader
cmake -S "$ocudu_dir" -B "$ocudu_dir/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_EXPORT=ON \
  -DENABLE_UHD=ON \
  -DENABLE_ZEROMQ=ON
cmake --build "$ocudu_dir/build" --parallel "$build_jobs"
sudo cmake --install "$ocudu_dir/build"
sudo ldconfig

gnb --version
