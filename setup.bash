#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Get the absolute path of the current directory (the repo root)
REPO_DIR=$(pwd)

echo "================================================================="
echo " Starting setup for Airan (Open5GS, UHD, srsRAN)"
echo "================================================================="

# 1. Update System and Install Core Dependencies
echo "[1/6] Updating system and installing dependencies..."
sudo apt update
sudo apt install -y build-essential cmake libfftw3-dev libmbedtls-dev \
    liblksctp-dev libconfig++-dev libsctp-dev libyaml-cpp-dev \
    libgtest-dev git net-tools curl wget software-properties-common gnupg \
    libzmq3-dev

# Install MongoDB (Required for Open5GS)
echo "Installing MongoDB..."
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor --yes
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# 2. Install and Configure Open5GS
echo "[2/6] Installing Open5GS..."
sudo add-apt-repository ppa:open5gs/latest -y
sudo apt update
sudo apt install -y open5gs

echo "Applying Open5GS configurations from repository..."
# Assuming the configs are in the root of your repo or a 'config' folder. 
# Adjust the source paths if they are located inside a specific subfolder in your repo.
if [ -f "$REPO_DIR/amf.yaml" ] && [ -f "$REPO_DIR/nrf.yaml" ] && [ -f "$REPO_DIR/upf.yaml" ]; then
    sudo cp "$REPO_DIR/amf.yaml" /etc/open5gs/amf.yaml
    sudo cp "$REPO_DIR/nrf.yaml" /etc/open5gs/nrf.yaml
    sudo cp "$REPO_DIR/upf.yaml" /etc/open5gs/upf.yaml
    
    echo "Restarting Open5GS services to apply new configurations..."
    sudo systemctl restart open5gs-amfd
    sudo systemctl restart open5gs-nrfd
    sudo systemctl restart open5gs-upfd
else
    echo "Warning: amf.yaml, nrf.yaml, or upf.yaml not found in $REPO_DIR!"
    echo "Please ensure they are in the correct location."
fi

# 3. Install UHD Driver
echo "[3/6] Installing UHD Drivers..."
sudo apt install -y libuhd-dev uhd-host

# 4. Handle UHD Images via User Input
echo "[4/6] Configuring UHD Images..."
UHD_IMAGES_DIR="$REPO_DIR/UHD_images"
TARGET_UHD_DIR="/usr/share/uhd/images"

# Ensure target directory exists
sudo mkdir -p "$TARGET_UHD_DIR"

if [ -d "$UHD_IMAGES_DIR" ]; then
    echo "Please select the UHD image you want to use from the UHD_images folder:"
    # Use standard bash 'select' menu
    PS3="Enter the number of your choice: "
    
    # List all files/folders inside UHD_images
    options=("$UHD_IMAGES_DIR"/*)
    select opt in "${options[@]}"; do
        if [ -n "$opt" ]; then
            echo "You selected: $(basename "$opt")"
            echo "Copying to $TARGET_UHD_DIR..."
            sudo cp -r "$opt" "$TARGET_UHD_DIR/"
            echo "UHD Image copied successfully."
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
else
    echo "Warning: Directory $UHD_IMAGES_DIR does not exist in the repository."
    echo "Skipping local UHD image setup. (You may need to run 'sudo uhd_images_downloader' manually)."
fi

# 5. Clone and Build srsRAN_4G
echo "[5/6] Building srsRAN_4G..."
cd ~
if [ ! -d "srsRAN_4G" ]; then
    git clone https://github.com/srsran/srsRAN_4G.git
fi
cd srsRAN_4G
mkdir -p build && cd build
cmake ../
make -j$(nproc)
sudo make install
sudo srsran_install_configs.sh user
sudo ldconfig

# 6. Clone and Build srsRAN_Project (5G)
echo "[6/6] Building srsRAN_Project (5G)..."
cd ~
if [ ! -d "srsRAN_Project" ]; then
    git clone https://github.com/srsran/srsRAN_Project.git
fi
cd srsRAN_Project
mkdir -p build && cd build
cmake ../
make -j$(nproc)
sudo make install
sudo ldconfig

echo "================================================================="
echo " Setup Complete! "
echo "================================================================="