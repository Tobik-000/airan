#!/usr/bin/env bash
set -euo pipefail

repository=https://github.com/srsran/srsRAN_4G.git
commit=6bcbd9e5bf8686aa7085202cd847c5ddd64a9c16
source_dir=${SRSRAN_4G_DIR:-$HOME/srsRAN_4G}
build_jobs=${BUILD_JOBS:-$(nproc)}

sudo apt-get update
sudo apt-get install -y build-essential cmake libfftw3-dev libmbedtls-dev \
  libboost-program-options-dev libsctp-dev libconfig++-dev libzmq3-dev \
  libuhd-dev uhd-host
sudo uhd_images_downloader

if [[ ! -d "$source_dir/.git" ]]; then
  git clone "$repository" "$source_dir"
fi

if [[ -n $(git -C "$source_dir" status --short --untracked-files=no) ]]; then
  echo "Refusing to change a modified srsRAN 4G checkout: $source_dir" >&2
  exit 1
fi

git -C "$source_dir" fetch origin --prune --tags
git -C "$source_dir" checkout --detach "$commit"
cmake -S "$source_dir" -B "$source_dir/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_WERROR=OFF
cmake --build "$source_dir/build" --parallel "$build_jobs"
sudo cmake --install "$source_dir/build"
sudo ldconfig
srsran_install_configs.sh user || true
srsue --version
